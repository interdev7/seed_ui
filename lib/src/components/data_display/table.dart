import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart'
    show CacheExtentStyle, ClipRectLayer, LayerHandle, ViewportOffset;
import 'package:flutter/widgets.dart' hide Table, TableRow;
// Flutter's own Table does the column arithmetic: it measures every cell in a
// column and gives them all the widest one's width, which is the behaviour a
// caller expects from a table and the reason none of this is written by hand.
// Ours takes the plain name, so Flutter's wears the prefix.
import 'package:flutter/widgets.dart' as flutter show Table, TableRow;

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/expandable.dart';
import '../../utils/size_resolver.dart';
import '../data_entry/checkbox.dart';
import '../data_entry/input.dart';
import '../data_entry/radio.dart';
import '../feedback/spin.dart';
import '../general/button.dart';
import '../navigation/dropdown.dart';
import '../navigation/pagination.dart';
import 'empty.dart';

/// Which edge a column's content is drawn against.
enum TableAlign {
  /// Against the leading edge — the left of a run that reads left to right.
  start,

  /// Centred.
  center,

  /// Against the trailing edge, where a number usually wants to be.
  end,
}

/// Which way a column is sorted.
///
/// Not sorted at all is a [TableSort] of `null` rather than a third case
/// here: a column with no order is not sorted by, and saying so twice would
/// let the two disagree.
enum TableSortOrder {
  /// Least first.
  ascending,

  /// Greatest first.
  descending;

  /// The other one.
  TableSortOrder get opposite => this == ascending ? descending : ascending;
}

/// Which column a table is sorted by, and which way.
@immutable
class TableSort {
  /// Creates a [TableSort].
  const TableSort(this.column, this.order);

  /// The column's place in [Table.columns].
  ///
  /// Its place rather than a name of its own: a column's identity is where it
  /// was listed, and a table with a name for every column would be a name to
  /// keep in step with nothing asking for it.
  final int column;

  /// Which way that column is sorted.
  final TableSortOrder order;

  @override
  bool operator ==(Object other) =>
      other is TableSort && other.column == column && other.order == order;

  @override
  int get hashCode => Object.hash(column, order);

  @override
  String toString() => 'TableSort($column, ${order.name})';
}

/// Whether rows are picked one at a time or many.
enum TableSelectionMode {
  /// A box against every row, and one at the head that takes the lot.
  checkbox,

  /// A dot against every row, and only ever one row picked.
  radio,
}

/// Picking rows out of a table.
///
/// A column of boxes goes in front of the others, and the heading carries one
/// that takes every row on show — every row the filters left, that is, not
/// every row that was handed over.
///
/// ```dart
/// Table<User>(
///   selection: TableSelection(onChanged: (rows) => setState(() => picked = rows)),
///   columns: columns,
///   data: users,
/// )
/// ```
///
/// A row is itself, not a key: what comes back are the records, and two rows
/// that compare equal are one row as far as picking goes. Give records a
/// `==` of their own where that matters.
@immutable
class TableSelection<T> {
  /// Creates a [TableSelection].
  const TableSelection({
    this.mode = TableSelectionMode.checkbox,
    this.selected,
    this.defaultSelected,
    this.onChanged,
    this.selectable,
    this.showSelectAll = true,
    this.columnWidth,
    this.fixed,
  });

  /// One row at a time, or many.
  final TableSelectionMode mode;

  /// The rows picked (controlled).
  ///
  /// Left null the table keeps its own, starting from [defaultSelected].
  final List<T>? selected;

  /// The rows picked to begin with (uncontrolled).
  final List<T>? defaultSelected;

  /// Called with the rows picked, whenever that changes.
  final ValueChanged<List<T>>? onChanged;

  /// Which rows may be picked at all. Every row, where nothing is said.
  ///
  /// A row that may not be picked shows a box that cannot be ticked, and the
  /// heading's box passes it over — so a table whose pickable rows are all
  /// picked reads as full, however many rows are barred.
  final bool Function(T record)? selectable;

  /// Whether the heading carries a box that takes every row on show.
  ///
  /// Never in [TableSelectionMode.radio]: taking every row is not something a
  /// column of dots can mean.
  final bool showSelectAll;

  /// How wide the column of boxes is.
  final double? columnWidth;

  /// Pins that column, as any other column is pinned.
  final TableColumnFixed? fixed;
}

/// Where a table's pager stands, and which edge it is drawn against.
///
/// A table takes a list of these, so a long one can carry a pager at both
/// ends: `position: [TablePaginationPosition.topEnd,
/// TablePaginationPosition.bottomEnd]`.
enum TablePaginationPosition {
  /// Above the table, against the leading edge.
  topStart,

  /// Above it, centred.
  topCenter,

  /// Above it, against the trailing edge.
  topEnd,

  /// Under the table, against the leading edge.
  bottomStart,

  /// Under it, centred.
  bottomCenter,

  /// Under it, against the trailing edge — the usual place.
  bottomEnd,

  /// Nowhere: the rows are still paged, but nothing is drawn to page them.
  ///
  /// For a table paged from somewhere else on the screen.
  none;

  /// Whether this one stands above the table.
  bool get isTop => this == topStart || this == topCenter || this == topEnd;

  /// Whether it stands under it.
  bool get isBottom =>
      this == bottomStart || this == bottomCenter || this == bottomEnd;

  /// Which edge it is drawn against.
  MainAxisAlignment get alignment => switch (this) {
        topStart || bottomStart => MainAxisAlignment.start,
        topCenter || bottomCenter => MainAxisAlignment.center,
        topEnd || bottomEnd => MainAxisAlignment.end,
        none => MainAxisAlignment.end,
      };
}

/// Showing a table's rows a page at a time.
///
/// The pager is the kit's own [Pagination], so everything it can be told —
/// its size, a quick jumper, a page-size changer — is told the same way, and
/// a theme's `PaginationDefaults` reaches it as it reaches any other.
///
/// ```dart
/// Table<User>(
///   pagination: const TablePagination(defaultPageSize: 20),
///   columns: columns,
///   data: users,
/// )
/// ```
///
/// Paging happens after narrowing and sorting, so a page is a page of what
/// the filters left, in the order the sort asked for.
@immutable
class TablePagination {
  /// Creates a [TablePagination].
  const TablePagination({
    this.page,
    this.defaultPage = 1,
    this.pageSize,
    this.defaultPageSize = 10,
    this.total,
    this.onChanged,
    this.position = const [TablePaginationPosition.bottomEnd],
    this.size,
    this.simple,
    this.showSizeChanger,
    this.pageSizeOptions = const [10, 20, 50, 100],
    this.showQuickJumper,
    this.showTotal,
    this.hideOnSinglePage,
  });

  /// Which page is being shown, counting from one (controlled).
  final int? page;

  /// Which page is shown to begin with (uncontrolled).
  final int defaultPage;

  /// How many rows a page holds (controlled).
  final int? pageSize;

  /// How many it holds to begin with (uncontrolled).
  final int defaultPageSize;

  /// How many rows there are in all, where the table cannot know.
  ///
  /// Left null the table counts what it was handed — every row after the
  /// filters — and takes the page out of it itself. That is the usual case:
  /// the rows are all here and paging them is a matter of showing some.
  ///
  /// Give a number and the arrangement turns around: the rows handed over are
  /// taken to be **one page already**, drawn as they came, and this is what
  /// the pager counts. For a table paged by a server, where each page is a
  /// request:
  ///
  /// ```dart
  /// Table<Post>(
  ///   data: page,                       // just this page's rows
  ///   pagination: TablePagination(
  ///     page: current,
  ///     pageSize: 10,
  ///     total: 100,                     // what the server says there is
  ///     onChanged: (p, size) => fetch(p, size),
  ///   ),
  ///   columns: columns,
  /// )
  /// ```
  ///
  /// Sorting and narrowing still work on what is here, which is one page —
  /// so a table paged this way usually leaves both to the server too.
  final int? total;

  /// Called with the page and the page size whenever either changes.
  final void Function(int page, int pageSize)? onChanged;

  /// Where the pager stands, and which edge it is drawn against.
  ///
  /// A list, so a long table can carry one at both ends. Defaults to a single
  /// pager under the table against the trailing edge.
  final List<TablePaginationPosition> position;

  /// The pager's own size preset.
  final SoftSize? size;

  /// A pager stripped to the page it is on and the two arrows.
  final PaginationSimple? simple;

  /// Whether the reader can change how many rows a page holds.
  final bool? showSizeChanger;

  /// The sizes offered when they can.
  final List<int> pageSizeOptions;

  /// Whether the reader can type a page number.
  final bool? showQuickJumper;

  /// Draws a word or two about how many rows there are in all.
  final Widget Function(int total, int from, int to)? showTotal;

  /// Whether the pager goes away when everything fits on one page.
  final bool? hideOnSinglePage;
}

/// Opening a row to show more under it.
///
/// A column of chevrons goes in front of the others, and the row that is
/// opened has a panel of your own drawing under it, across the whole table.
///
/// ```dart
/// Table<User>(
///   expandable: TableExpandable(builder: (context, user, i) => Text(user.bio)),
///   columns: columns,
///   data: users,
/// )
/// ```
///
/// A row is itself, not a key — as with [TableSelection].
@immutable
class TableExpandable<T> {
  /// Creates a [TableExpandable].
  const TableExpandable({
    required this.builder,
    this.expanded,
    this.defaultExpanded,
    this.onChanged,
    this.expandable,
    this.byRowTap = false,
    this.showColumn = true,
    this.columnWidth,
    this.fixed,
  });

  /// What is drawn under an opened row.
  final Widget Function(BuildContext context, T record, int index) builder;

  /// The rows standing open (controlled).
  final List<T>? expanded;

  /// The rows standing open to begin with (uncontrolled).
  final List<T>? defaultExpanded;

  /// Called with the rows standing open, whenever that changes.
  final ValueChanged<List<T>>? onChanged;

  /// Which rows can be opened at all. Every row, where nothing is said.
  ///
  /// A row that cannot shows no chevron — an arrow that does nothing is worse
  /// than none — and tapping it opens nothing.
  final bool Function(T record)? expandable;

  /// Whether a tap anywhere on the row opens it, as well as the chevron.
  final bool byRowTap;

  /// Whether the chevrons get a column of their own.
  ///
  /// Off where [byRowTap] is doing the work, or where the row draws its own
  /// way of opening.
  final bool showColumn;

  /// How wide that column is.
  final double? columnWidth;

  /// Pins it, as any other column is pinned.
  final TableColumnFixed? fixed;
}

/// How many places a cell takes up.
///
/// A cell that spans covers its neighbours, and those neighbours are simply
/// not drawn — the table works out which ones, rather than asking every cell
/// to say it is covered.
@immutable
class TableCellSpan {
  /// Creates a [TableCellSpan].
  const TableCellSpan({this.columns = 1, this.rows = 1})
      : assert(columns >= 1, 'A cell covers at least its own column.'),
        assert(rows >= 1, 'A cell covers at least its own row.');

  /// How many columns it covers, counting its own.
  final int columns;

  /// How many rows it covers, counting its own.
  final int rows;

  /// Whether this is the ordinary one place.
  bool get isSingle => columns == 1 && rows == 1;

  @override
  bool operator ==(Object other) =>
      other is TableCellSpan && other.columns == columns && other.rows == rows;

  @override
  int get hashCode => Object.hash(columns, rows);

  @override
  String toString() => 'TableCellSpan(columns: $columns, rows: $rows)';
}

/// One choice in a column's filter menu.
@immutable
class TableFilter {
  /// Creates a [TableFilter].
  const TableFilter(this.label, this.value);

  /// What the reader sees against the checkbox.
  final String label;

  /// What the column is asked about, and what [Table.onFiltersChanged]
  /// reports.
  ///
  /// Compared with the column's value where nothing else was said, so a
  /// filter over a city is `TableFilter('Galway', 'Galway')`.
  final Object? value;

  @override
  bool operator ==(Object other) =>
      other is TableFilter && other.label == label && other.value == value;

  @override
  int get hashCode => Object.hash(label, value);
}

/// How much room a [Table] gives itself, and which way it scrolls.
///
/// ```dart
/// Table(scroll: const TableScroll(y: 320), ...)   // a body that scrolls
/// Table(scroll: const TableScroll(x: 1200), ...)  // wider than its box
/// ```
@immutable
class TableScroll {
  /// Creates a [TableScroll].
  const TableScroll({this.x, this.y})
      : assert(x == null || x > 0, 'a width to scroll across must be positive'),
        assert(y == null || y > 0, 'a height to scroll down must be positive');

  /// The width to lay the table out at, however narrow its box.
  ///
  /// Null keeps it to the room it is given. A number wider than that is what
  /// puts a scrollbar under it.
  final double? x;

  /// The height of the scrolling body.
  ///
  /// Set this and the heading stops travelling with the rows: it sits above
  /// them and stays.
  final double? y;
}

/// Which part of a pane is being built.
enum _Band {
  /// The heading alone, for when it has to stay put.
  heading,

  /// The rows alone.
  rows,

  /// Both together, for when nothing has been separated.
  both,
}

/// Which edge a column is pinned to, if any.
enum TableColumnFixed {
  /// Against the leading edge, where the rows begin.
  start,

  /// Against the trailing edge.
  end,
}

/// One column of a [Table].
///
/// [T] is the type of a row. A column says how to draw a cell from one, which
/// is all a table needs of it — there is no key into a map to get wrong,
/// because Dart already knows what a row is.
@immutable
class TableColumn<T> {
  /// Creates a [TableColumn].
  const TableColumn({
    this.value,
    this.builder,
    this.title,
    this.width,
    this.flex,
    this.align,
    this.headerAlign,
    this.fixed,
    this.ellipsis = false,
    this.sortable = false,
    this.sorter,
    this.filters,
    this.onFilter,
    this.filterMultiple = true,
    this.filterSearch = false,
    this.filterSearchMatch,
    this.children,
    this.summary,
    this.span,
  })  : assert(
          children == null || span == null,
          'A group heads other columns and has no cell of its own to span.',
        ),
        assert(
          children == null || summary == null,
          'A group heads other columns and has no cell of its own to sum up. '
          'Put the summary on one of the columns under it.',
        ),
        assert(
          children == null || children.length != 0,
          'A group with no columns under it heads nothing. Leave children off '
          'instead.',
        ),
        assert(
          children == null || (value == null && builder == null),
          'A group heads other columns; it has no cells of its own, so it '
          'reads no value and draws no cell.',
        ),
        assert(
          width == null || flex == null,
          'Give a column a width or a flex, not both: one is a number of '
          'pixels and the other a share of what is left over.',
        ),
        assert(
          value != null || builder != null || children != null,
          'A column needs a value to read, a builder to draw with, or columns '
          'to head.',
        ),
        assert(
          !sortable || value != null || sorter != null,
          'A sortable column needs a value to compare, or a sorter that says '
          'how to compare the rows itself.',
        ),
        assert(
          filters == null || filters.length != 0,
          'A column with an empty list of filters offers a menu with nothing '
          'in it. Leave filters off instead.',
        ),
        assert(
          filters == null || value != null || onFilter != null,
          'A filtered column needs a value to match, or an onFilter that says '
          'what a choice means itself.',
        ),
        assert(
          (!filterSearch && filterSearchMatch == null) || filters != null,
          'Searching a filter menu needs a menu to search: give the column '
          'filters, or leave the search off.',
        ),
        assert(
          fixed == null || width != null,
          'A pinned column needs a width: it is laid out apart from the '
          'columns that scroll, so a share of what is left means nothing.',
        );

  /// What this column reads out of a row.
  ///
  /// Enough on its own: a cell with no [builder] is that value as text, which
  /// is what most columns are.
  ///
  /// ```dart
  /// TableColumn(title: const Text('Name'), value: (u) => u.name)
  /// ```
  ///
  /// It is also the number a sort compares and a filter matches, so a column
  /// that names one gets those for nothing when they arrive.
  final Object? Function(T record)? value;

  /// Draws one cell, where text will not do.
  ///
  /// Given a [value] as well, this decides how it looks and the value still
  /// stands for the cell — a `Tag` that sorts by the word inside it.
  final Widget Function(BuildContext context, T record, int index)? builder;

  /// What stands at the head of the column.
  final Widget? title;

  /// Lets the heading be tapped to sort the table by this column.
  ///
  /// The [value] is what is compared, which is why most columns need nothing
  /// else said. Tapping cycles ascending, descending, and back to the order
  /// the rows came in.
  final bool sortable;

  /// How two rows compare, where the [value] will not do.
  ///
  /// Naming one makes the column sortable, so [sortable] need not be set as
  /// well. Use it where the value is not what the reader is sorting by — a
  /// date shown as `12 Mar` sorts by the date, not by the word.
  final int Function(T a, T b)? sorter;

  /// The columns this one heads, where it heads any.
  ///
  /// A column with children is a group: it has a title spanning what is under
  /// it and no cells of its own. Groups nest as deep as you like, and only
  /// the leaves — the columns with no children — hold cells.
  ///
  /// ```dart
  /// TableColumn(
  ///   title: const Text('Name'),
  ///   children: [
  ///     TableColumn(title: const Text('First'), value: (u) => u.first),
  ///     TableColumn(title: const Text('Last'), value: (u) => u.last),
  ///   ],
  /// )
  /// ```
  final List<TableColumn<T>>? children;

  /// What this column adds up, drawn in a row under the rest.
  ///
  /// Given the rows on show — a page of them, where the table is paged, and
  /// what the filters left. A column that says nothing leaves its place in
  /// that row empty, and a table where no column says anything draws no such
  /// row at all.
  ///
  /// ```dart
  /// TableColumn(
  ///   title: const Text('Age'),
  ///   value: (u) => u.age,
  ///   summary: (context, rows) => Text('total'),
  /// )
  /// ```
  final Widget Function(BuildContext context, List<T> rows)? summary;

  /// How many places this column's cell takes up in a given row.
  ///
  /// A cell that covers its neighbours makes them disappear: the table works
  /// out which cells are covered and draws nothing for them, so there is no
  /// need to return a nought from anywhere.
  ///
  /// ```dart
  /// // The first row's name runs across two columns.
  /// span: (context, user, i) =>
  ///     i == 0 ? const TableCellSpan(columns: 2) : const TableCellSpan(),
  /// ```
  ///
  /// A table whose cells span is drawn row by row rather than as a grid, so
  /// it is not lazy — as with rows that open.
  final TableCellSpan Function(BuildContext context, T record, int index)? span;

  /// Whether this column heads others rather than holding cells.
  bool get isGroup => children != null;

  /// This column, or every leaf under it.
  Iterable<TableColumn<T>> get leaves =>
      children == null ? [this] : children!.expand((c) => c.leaves);

  /// How many leaves stand under this one, which is how many columns its
  /// heading reaches across.
  int get headingSpan => leaves.length;

  /// How many rows of heading stand under this one.
  int get depth =>
      children == null ? 1 : 1 + children!.map((c) => c.depth).reduce(math.max);

  /// Whether this column sorts at all.
  bool get sorts => sortable || sorter != null;

  /// What the column can be filtered down to, one entry per choice.
  ///
  /// Naming any puts a funnel at the head of the column, opening a menu of
  /// them. Nothing chosen is every row: a filter narrows, and a filter that
  /// has been asked for nothing narrows nothing.
  final List<TableFilter>? filters;

  /// Whether a row belongs under one of the choices.
  ///
  /// Left out, a row belongs where its [value] equals the choice's, which is
  /// what most columns mean. Give one where it is not — a range, a substring,
  /// a field the column does not show.
  ///
  /// ```dart
  /// onFilter: (choice, user) => user.name.startsWith(choice! as String)
  /// ```
  final bool Function(Object? value, T record)? onFilter;

  /// Whether more than one choice can be in force at once.
  ///
  /// Off, the menu behaves as a set of radios and a choice replaces the one
  /// before it.
  final bool filterMultiple;

  /// Puts a field above the choices for narrowing the menu itself.
  ///
  /// Worth it once there are more choices than a reader will scan. What is
  /// typed is matched against each choice's [TableFilter.label], ignoring
  /// case and the spaces around it.
  final bool filterSearch;

  /// How a typed word and a choice are matched, where the label will not do.
  ///
  /// Naming one puts the field there, so [filterSearch] need not be set as
  /// well — the same shape as [sorter] against [sortable].
  final bool Function(String query, TableFilter choice)? filterSearchMatch;

  /// Whether this column filters at all.
  bool get filtersRows => filters != null;

  /// Whether its menu can be searched.
  bool get filterSearches => filterSearch || filterSearchMatch != null;

  /// A width in logical pixels.
  ///
  /// Null lets the column take the width of its widest cell, which is what a
  /// table is expected to do and needs saying nowhere.
  final double? width;

  /// A share of the width left over once the fixed columns have taken theirs.
  ///
  /// Two columns of `flex: 1` and `flex: 2` split the remainder one part to
  /// two.
  final int? flex;

  /// Which edge the cells are drawn against. Defaults to the leading one.
  final TableAlign? align;

  /// Which edge the heading is drawn against. Defaults to [align].
  final TableAlign? headerAlign;

  /// Pins the column to one edge, so the rest scroll past it.
  ///
  /// A pinned column needs a [width]: it is laid out apart from the columns
  /// that scroll, and a share of a width it cannot see is no use to it.
  ///
  /// Pinning anything makes every row exactly one height — the panes are laid
  /// out separately, and only a height they all know keeps their rows level.
  final TableColumnFixed? fixed;

  /// Cuts a cell's text with an ellipsis rather than letting it wrap.
  final bool ellipsis;
}

/// Per-component design tokens for [Table].
///
/// Every field is an override; a null one falls back to a value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(table: TableToken(...)))`, or per instance via
/// [Table.token].
@immutable
class TableToken {
  /// Creates a [TableToken].
  const TableToken({
    this.headerBg,
    this.headerColor,
    this.rowHoverBg,
    this.rowSelectedBg,
    this.rowSelectedHoverBg,
    this.borderColor,
    this.cellPaddingBlock,
    this.cellPaddingBlockSM,
    this.cellPaddingBlockLG,
    this.cellPaddingInline,
    this.cellPaddingInlineSM,
    this.cellPaddingInlineLG,
    this.footerBg,
    this.borderRadius,
    this.fontSize,
    this.columnMinWidth,
    this.pinnedShadowColor,
    this.pinnedShadowExtent,
    this.headerHoverBg,
    this.headerMarkActiveColor,
    this.headerMarkColor,
    this.sortCaretSize,
    this.filterIconSize,
    this.filterMenuMaxHeight,
    this.filterHoverBg,
    this.filterSearchWidth,
    this.selectionColumnWidth,
    this.expandIconSize,
    this.expandedBg,
    this.summaryBg,
    this.pinnedBg,
  });

  /// Fill behind the heading row.
  final Color? headerBg;

  /// Colour of the heading text.
  final Color? headerColor;

  /// Fill behind the row under the pointer.
  final Color? rowHoverBg;

  /// Fill behind a row that has been picked.
  final Color? rowSelectedBg;

  /// Fill behind a picked row under the pointer, a step stronger so the
  /// pointer still shows where it is.
  final Color? rowSelectedHoverBg;

  /// Colour of the rules between rows, and of the outline when bordered.
  final Color? borderColor;

  /// Space above and below a cell's content, at each size preset.
  final double? cellPaddingBlock;

  /// The compact preset's.
  final double? cellPaddingBlockSM;

  /// The roomy preset's.
  final double? cellPaddingBlockLG;

  /// Space either side of a cell's content, at each size preset.
  final double? cellPaddingInline;

  /// The compact preset's.
  final double? cellPaddingInlineSM;

  /// The roomy preset's.
  final double? cellPaddingInlineLG;

  /// Fill behind the footer.
  final Color? footerBg;

  /// Corner radius of the table's outline.
  final double? borderRadius;

  /// Size of the text in a cell.
  final double? fontSize;

  /// The narrowest a column will be squeezed to when it is sharing a width.
  ///
  /// Only columns that named neither a width nor a flex, and only in a
  /// scrolling table — the ones taking a share of what there is. Past this
  /// the table grows wider and scrolls rather than squeezing them further:
  /// fifteen columns sharing eight hundred pixels are thirty-seven pixels
  /// each, which is not a column anybody can read.
  final double? columnMinWidth;

  /// Colour of the shade a pinned column casts over the rows going past it,
  /// at its darkest against the column's edge.
  ///
  /// Cast only while there is something behind it to cast over, so a run
  /// scrolled back to its start shows none.
  final Color? pinnedShadowColor;

  /// How far that shade reaches over the rows before it has faded out.
  final double? pinnedShadowExtent;

  /// Fill behind a sortable heading under the pointer.
  ///
  /// Only a heading that sorts takes one: a heading that does nothing has no
  /// business lighting up under the hand.
  final Color? headerHoverBg;

  /// Colour of a mark in a heading that is in force — the caret standing for
  /// the order a column is sorted in, or a funnel that is narrowing the rows.
  final Color? headerMarkActiveColor;

  /// Colour of one that is merely offered.
  final Color? headerMarkColor;

  /// How tall each of the two carets is.
  final double? sortCaretSize;

  /// How big the funnel at the head of a filtered column is.
  final double? filterIconSize;

  /// How tall a filter menu grows before its choices scroll.
  final double? filterMenuMaxHeight;

  /// How wide the field that narrows a filter menu is.
  final double? filterSearchWidth;

  /// How big the chevron that opens a row is.
  final double? expandIconSize;

  /// Fill behind the panel under an opened row.
  final Color? expandedBg;

  /// Fill behind a column held at an edge.
  ///
  /// It has to be opaque: a held column stands over the ones sliding under
  /// it, and a row is only as opaque as its own fill, which is nothing until
  /// the pointer is on it.
  final Color? pinnedBg;

  /// Fill behind the row that adds the columns up.
  ///
  /// The body's own ground by default, not a tint: the rule above it is what
  /// sets it apart, and a fill would make it read as a second heading.
  final Color? summaryBg;

  /// How much room the box itself takes in the column of boxes.
  ///
  /// The column is this plus the padding a cell carries either side, so a
  /// compact table's is narrower without anything being said twice.
  final double? selectionColumnWidth;

  /// Fill behind the funnel itself under the pointer.
  ///
  /// A step stronger than [headerHoverBg], or the mark would not be told
  /// apart from the heading it stands in.
  final Color? filterHoverBg;

  _ResolvedTableToken _resolve(Token t) => _ResolvedTableToken(
        headerBg: headerBg ?? t.colorFillQuaternary,
        headerColor: headerColor ?? t.colorText,
        rowHoverBg: rowHoverBg ?? t.colorFillQuaternary,
        rowSelectedBg: rowSelectedBg ?? t.primary.bg,
        rowSelectedHoverBg: rowSelectedHoverBg ?? t.primary.bgHover,
        borderColor: borderColor ?? t.colorSplit,
        // A step at every preset, on both axes. An earlier pair had the
        // standard and the roomy one land on the same number, so `large`
        // and `middle` drew identical rows.
        cellPaddingBlock: cellPaddingBlock ?? t.sizeSM,
        cellPaddingBlockSM: cellPaddingBlockSM ?? t.sizeXS,
        cellPaddingBlockLG: cellPaddingBlockLG ?? t.size,
        cellPaddingInline: cellPaddingInline ?? t.size,
        cellPaddingInlineSM: cellPaddingInlineSM ?? t.sizeXS,
        cellPaddingInlineLG: cellPaddingInlineLG ?? t.sizeMD,
        footerBg: footerBg ?? t.colorFillQuaternary,
        borderRadius: borderRadius ?? t.borderRadiusLG,
        fontSize: fontSize ?? t.fontSize,
        columnMinWidth: columnMinWidth ?? t.controlHeightLG * 2.5,
        // Not a `BoxShadow`: a shadow is painted behind the box that casts
        // it, and the pinned pane's neighbour is drawn after it, so the whole
        // cast landed under the pane instead of over the rows — a grey smear
        // showing through columns that are mostly transparent. A strip laid
        // over the scrolling rows has nothing to show through.
        // The same shade the reference casts: `colorSplit` at the column's
        // edge, falling away over about ten pixels. Ours was black at fifteen
        // per cent over twenty-four — measured, an alpha of 34 fading to
        // nothing a full twenty-four pixels out, where the reference is a
        // narrow edge you notice rather than a band you read.
        pinnedShadowColor: pinnedShadowColor ?? t.colorSplit,
        pinnedShadowExtent: pinnedShadowExtent ?? t.sizeSM,
        headerHoverBg: headerHoverBg ?? t.colorFillSecondary,
        headerMarkActiveColor: headerMarkActiveColor ?? t.primary.base,
        headerMarkColor: headerMarkColor ?? t.colorTextQuaternary,
        sortCaretSize: sortCaretSize ?? t.sizeXXS,
        filterIconSize: filterIconSize ?? t.sizeSM,
        filterMenuMaxHeight: filterMenuMaxHeight ?? 264,
        filterHoverBg: filterHoverBg ?? t.colorFill,
        filterSearchWidth: filterSearchWidth ?? 140,
        selectionColumnWidth: selectionColumnWidth ?? t.controlHeightSM,
        expandIconSize: expandIconSize ?? t.sizeMD,
        expandedBg: expandedBg ?? t.colorFillQuaternary,
        summaryBg: summaryBg ?? t.colorBgContainer,
        pinnedBg: pinnedBg ?? t.colorBgContainer,
      );
}

@immutable
class _ResolvedTableToken {
  const _ResolvedTableToken({
    required this.headerBg,
    required this.headerColor,
    required this.rowHoverBg,
    required this.rowSelectedBg,
    required this.rowSelectedHoverBg,
    required this.borderColor,
    required this.cellPaddingBlock,
    required this.cellPaddingBlockSM,
    required this.cellPaddingBlockLG,
    required this.cellPaddingInline,
    required this.cellPaddingInlineSM,
    required this.cellPaddingInlineLG,
    required this.footerBg,
    required this.borderRadius,
    required this.fontSize,
    required this.columnMinWidth,
    required this.pinnedShadowColor,
    required this.pinnedShadowExtent,
    required this.headerHoverBg,
    required this.headerMarkActiveColor,
    required this.headerMarkColor,
    required this.sortCaretSize,
    required this.filterIconSize,
    required this.filterMenuMaxHeight,
    required this.filterHoverBg,
    required this.filterSearchWidth,
    required this.selectionColumnWidth,
    required this.expandIconSize,
    required this.expandedBg,
    required this.summaryBg,
    required this.pinnedBg,
  });

  final Color headerBg;
  final Color headerColor;
  final Color rowHoverBg;
  final Color rowSelectedBg;
  final Color rowSelectedHoverBg;
  final Color borderColor;
  final double cellPaddingBlock;
  final double cellPaddingBlockSM;
  final double cellPaddingBlockLG;
  final double cellPaddingInline;
  final double cellPaddingInlineSM;
  final double cellPaddingInlineLG;
  final Color footerBg;
  final double borderRadius;
  final double fontSize;
  final double columnMinWidth;
  final Color pinnedShadowColor;
  final double pinnedShadowExtent;
  final Color headerHoverBg;
  final Color headerMarkActiveColor;
  final Color headerMarkColor;
  final double sortCaretSize;
  final double filterIconSize;
  final double filterMenuMaxHeight;
  final Color filterHoverBg;
  final double filterSearchWidth;
  final double selectionColumnWidth;
  final double expandIconSize;
  final Color expandedBg;
  final Color summaryBg;
  final Color pinnedBg;
}

/// Defaults for every [Table] under a `ConfigProvider`.
///
/// Not tokens — those are numbers and colours, and live in [TableToken].
/// These are the table's own props, applied wherever one does not name them.
@immutable
class TableDefaults {
  /// Creates a [TableDefaults].
  const TableDefaults({
    this.size,
    this.bordered,
    this.showHeader,
    this.rowHoverable,
  });

  /// How much room a row takes.
  final ControlSize? size;

  /// Whether tables are drawn with an outline and rules between columns.
  final bool? bordered;

  /// Whether the heading row is shown.
  final bool? showHeader;

  /// Whether a row lights up under the pointer.
  final bool? rowHoverable;
}

/// Rows and columns, with a heading.
///
/// A column says how to draw a cell and, if it likes, how wide to be. Say
/// nothing about width and the column takes the width of its widest cell,
/// which is what a table is expected to do:
///
/// ```dart
/// Table<User>(
///   data: users,
///   columns: [
///     TableColumn(title: const Text('Name'), builder: (_, u, __) => Text(u.name)),
///     TableColumn(
///       title: const Text('Age'),
///       align: TableAlign.end,
///       builder: (_, u, __) => Text('${u.age}'),
///     ),
///   ],
/// )
/// ```
///
/// The name is Flutter's own, so a file that uses both wants
/// `import 'package:flutter/widgets.dart' hide Table;`. The kit takes the
/// plain name because that is the one people look for.
class Table<T> extends StatefulWidget {
  /// Creates a [Table].
  const Table({
    super.key,
    required this.columns,
    required this.data,
    this.size,
    this.bordered,
    this.showHeader,
    this.rowHoverable,
    this.scroll,
    this.header,
    this.footer,
    this.empty,
    this.loading = false,
    this.onRowTap,
    this.sort,
    this.defaultSort,
    this.onSortChanged,
    this.filters,
    this.defaultFilters,
    this.onFiltersChanged,
    this.selection,
    this.expandable,
    this.pagination,
    this.token,
  });

  /// The columns, in the order they are drawn.
  final List<TableColumn<T>> columns;

  /// The rows.
  final List<T> data;

  /// How much room a row takes: a preset, or a height of your own.
  final ControlSize? size;

  /// Draws an outline around the table and rules between its columns.
  final bool? bordered;

  /// Whether the heading row is shown.
  final bool? showHeader;

  /// Whether a row lights up under the pointer.
  final bool? rowHoverable;

  /// How much room the table gives itself, and which way it scrolls.
  ///
  /// A scrolling table lays its columns out to a width it knows in advance,
  /// so a column that named neither a width nor a flex takes an equal share
  /// rather than fitting its content: the heading and the rows are two tables
  /// once the heading stops moving, and only a width they both work out the
  /// same way keeps them in step. It is the trade `tableLayout: fixed` makes
  /// for the same reason.
  final TableScroll? scroll;

  /// Drawn above the table, inside its outline.
  final Widget Function(BuildContext context, List<T> rows)? header;

  /// Drawn below it.
  final Widget Function(BuildContext context, List<T> rows)? footer;

  /// What stands in for the rows when there are none.
  ///
  /// Null falls back to the kit's `Empty`, and so to whatever
  /// `ConfigProvider.emptyBuilder` says for [EmptySlot.table].
  final Widget? empty;

  /// Covers the table with a spinner while something is being fetched.
  final bool loading;

  /// Called when a row is tapped.
  final void Function(T record, int index)? onRowTap;

  /// Which column the table is sorted by, and which way (controlled).
  ///
  /// Left null the table keeps its own, starting from [defaultSort]. Give it
  /// a value and the table shows what it is told and nothing else — pair it
  /// with [onSortChanged] or the heading will not answer.
  final TableSort? sort;

  /// What it is sorted by to begin with (uncontrolled).
  final TableSort? defaultSort;

  /// Called when a heading is tapped, with what the sort has become.
  ///
  /// Null where the rows have gone back to the order they came in.
  final ValueChanged<TableSort?>? onSortChanged;

  /// Which choices are in force, per column (controlled).
  ///
  /// Keyed by the column's place in [columns], as [TableSort] is. A column
  /// absent from the map, or present with nothing chosen, is not narrowing
  /// anything.
  final Map<int, List<Object?>>? filters;

  /// What is chosen to begin with (uncontrolled).
  final Map<int, List<Object?>>? defaultFilters;

  /// Called when a filter menu is applied or reset, with what is in force.
  final ValueChanged<Map<int, List<Object?>>>? onFiltersChanged;

  /// Picking rows out of the table, and what to do about it.
  ///
  /// Null — the usual — is a table nobody is picking from, and no column of
  /// boxes in front of the others.
  final TableSelection<T>? selection;

  /// Opening a row to show more under it.
  ///
  /// Null — the usual — is a table whose rows do not open.
  final TableExpandable<T>? expandable;

  /// Showing the rows a page at a time.
  ///
  /// Null — the usual — is every row at once.
  final TablePagination? pagination;

  /// Per-instance token overrides.
  final TableToken? token;

  @override
  State<Table<T>> createState() => _TableState<T>();
}

class _TableState<T> extends State<Table<T>> {
  /// Which row the pointer is over.
  ///
  /// A notifier and not a field behind setState: the fill used to live on the
  /// row's decoration, which only the whole table can redraw, so every twitch
  /// of the pointer rebuilt every row. Measured at five hundred rows that was
  /// ninety milliseconds a move. It lives in the cell now, and only the two
  /// rows that changed listen.
  final ValueNotifier<int?> _hovered = ValueNotifier<int?>(null);

  /// Which heading the pointer is over, or null.
  final ValueNotifier<int?> _hoveredHeading = ValueNotifier<int?>(null);

  /// Which funnel the pointer is over, or null. Its own, because the funnel
  /// answers the hand apart from the heading it stands in.
  final ValueNotifier<int?> _hoveredFunnel = ValueNotifier<int?>(null);

  /// The rows' offset across, and the heading's, kept together.
  ///
  /// Two of them because a heading that stays put vertically while travelling
  /// horizontally is a second viewport, and one controller cannot drive two.
  /// They agree because they are laid out over the same width — when they were
  /// not, each clamped to its own extent and a two-hundred-pixel drag moved
  /// one of them a hundred and eighty.
  final ScrollController _rowsX = ScrollController();
  final ScrollController _headingX = ScrollController();
  bool _syncing = false;

  /// How far across the rows have gone, for whatever wants to know without
  /// rebuilding the table to find out.
  final ValueNotifier<double> _acrossOffset = ValueNotifier<double>(0);

  /// Bumped once the scroll knows how much there is of it.
  ///
  /// How far there is left to go is only answerable after a layout, and a
  /// shadow at the far end depends on it — without this the trailing column
  /// went unshaded until something else happened to move.
  final ValueNotifier<int> _measured = ValueNotifier<int>(0);
  bool _knowsItsLength = false;

  /// Whatever a shadow needs to know: where the rows are, and how far they go.
  Listenable get _acrossGeometry =>
      Listenable.merge([_acrossOffset, _measured]);

  void _noteLength() {
    if (_knowsItsLength) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _knowsItsLength) return;
      if (_rowsX.hasClients && _rowsX.position.hasContentDimensions) {
        _knowsItsLength = true;
        _measured.value++;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _rowsX.addListener(() {
      if (_rowsX.hasClients) _acrossOffset.value = _rowsX.offset;
    });
    _rowsX.addListener(() => _keepTogether(_rowsX, _headingX));
    _headingX.addListener(() => _keepTogether(_headingX, _rowsX));
  }

  /// Moves [to] to wherever [from] is.
  ///
  /// [_syncing] guards a loop rather than a pixel, which is why no test moves
  /// without it: while the two agree, the half-pixel check below already stops
  /// the echo. Should they ever fail to — one clamping where the other does
  /// not — they would answer each other for ever, and that is a hang, not an
  /// error anybody could read.
  void _keepTogether(ScrollController from, ScrollController to) {
    if (_syncing || !from.hasClients || !to.hasClients) return;
    if ((to.offset - from.offset).abs() < 0.5) return;
    _syncing = true;
    to.jumpTo(
      from.offset.clamp(
        to.position.minScrollExtent,
        to.position.maxScrollExtent,
      ),
    );
    _syncing = false;
  }

  @override
  void dispose() {
    _rowsX.dispose();
    _headingX.dispose();
    _hovered.dispose();
    _hoveredHeading.dispose();
    _hoveredFunnel.dispose();
    for (final closer in _closers) {
      closer.cancel();
    }
    _acrossOffset.dispose();
    _measured.dispose();
    super.dispose();
  }

  TableDefaults? get _defaults =>
      ConfigProvider.defaultsOf<TableDefaults>(context);

  ControlSize get _size =>
      widget.size ??
      _defaults?.size ??
      ConfigProvider.componentSizeOf(context) ??
      SoftSize.middle;

  bool get _bordered => widget.bordered ?? _defaults?.bordered ?? false;

  bool get _showHeader => widget.showHeader ?? _defaults?.showHeader ?? true;

  bool get _hoverable => widget.rowHoverable ?? _defaults?.rowHoverable ?? true;

  /// Whether the heading has been lifted out of the run of rows.
  bool get _detached => widget.scroll?.y != null;

  /// The width to lay the table out at, wider than its box if need be.
  double? get _across => widget.scroll?.x;

  /// The narrowest these columns can be laid out in.
  ///
  /// Every column has a width of its own or the floor, so this is exact rather
  /// than a guess — and knowing it is what keeps a table from being laid out
  /// narrower than its own columns.
  double _leastWidth(List<TableColumn<T>> columns, _ResolvedTableToken r) =>
      columns.fold(0, (sum, c) => sum + (c.width ?? r.columnMinWidth));

  /// The preset a size belongs to, so a height of your own still picks the
  /// padding of the preset it is nearest — as a `Button` does.
  SoftSize _preset(_ResolvedTableToken r, Token t) {
    final size = _size;
    if (size is SoftSize) return size;
    final height = _rowHeight(t);
    final byDistance = <(SoftSize, double)>[
      (SoftSize.small, (height - t.controlHeightSM).abs()),
      (SoftSize.middle, (height - t.controlHeight).abs()),
      (SoftSize.large, (height - t.controlHeightLG).abs()),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return byDistance.first.$1;
  }

  double _rowHeight(Token t) => _size.resolveHeight(
        small: t.controlHeightSM,
        middle: t.controlHeight,
        large: t.controlHeightLG,
      );

  /// A row height asked for by name, or null where a preset was.
  ///
  /// A preset says how much padding a cell carries and lets the content
  /// decide the rest; a number says how tall the row is, and is honoured as a
  /// floor so a cell that needs more still gets it.
  double? _askedRowHeight(Token t) => _size is SoftSize ? null : _rowHeight(t);

  EdgeInsets _cellPadding(_ResolvedTableToken r, Token t) {
    final block = switch (_preset(r, t)) {
      SoftSize.small => r.cellPaddingBlockSM,
      SoftSize.middle => r.cellPaddingBlock,
      SoftSize.large => r.cellPaddingBlockLG,
    };
    final inline = switch (_preset(r, t)) {
      SoftSize.small => r.cellPaddingInlineSM,
      SoftSize.middle => r.cellPaddingInline,
      SoftSize.large => r.cellPaddingInlineLG,
    };
    // A height asked for by name already says how tall the row is, so the
    // padding that would have decided it steps aside; anything else would
    // add to the number rather than honour it.
    return EdgeInsets.symmetric(
      vertical: _uniformHeight(t) == null ? block : 0,
      horizontal: inline,
    );
  }

  /// How each column is measured.
  ///
  /// A column that names neither a width nor a flex takes the width of its
  /// widest cell — Flutter's own intrinsic measurement, which is what makes
  /// the common case need saying nothing at all.
  Map<int, TableColumnWidth> _widthsFor(
    List<TableColumn<T>> columns,
    _ResolvedTableToken r,
  ) =>
      {
        for (var i = 0; i < columns.length; i++)
          i: switch (columns[i]) {
            TableColumn(:final width?) => FixedColumnWidth(width),
            TableColumn(:final flex?) => FlexColumnWidth(flex.toDouble()),
            // Once the heading has stopped travelling with the rows they are
            // two tables, and an intrinsic width would measure a different
            // thing in each — the title in one, the cells in the other. An
            // equal share is what they can both work out alike.
            // A share, but never squeezed past what a column can be read at:
            // the table grows and scrolls instead.
            _ when _detached || _across != null => MaxColumnWidth(
                FixedColumnWidth(r.columnMinWidth),
                const FlexColumnWidth(),
              ),
            // flex: 1, and not a bare intrinsic width. Left to itself
            // Flutter shares any slack equally between *every* column, which
            // quietly inflates a column that asked for an exact width — 100
            // became 267 in a 600-wide table. Marking the automatic ones as
            // the flexible ones sends the leftover to them alone, so a width
            // means the width.
            _ => const IntrinsicColumnWidth(flex: 1),
          },
      };

  /// The columns pinned to one edge, in the order they were given.
  /// The columns as drawn: the column of boxes, where rows are being picked,
  /// and then the ones that were given.
  ///
  /// Only the drawing goes through this. A sort and a filter are keyed by a
  /// column's place in [Table.columns], and the box column is not one of
  /// those — `indexOf` gives it -1, which is no column at all, so it neither
  /// sorts nor filters and nothing had to be told to skip it.
  List<TableColumn<T>> get _columns => [
        if (widget.selection != null) _selectionColumn,
        if (widget.expandable?.showColumn ?? false) _expandColumn,
        ..._leaves,
      ];

  /// The columns as given, with the box and chevron columns in front: the
  /// heading is drawn from this, since a group only exists here.
  List<TableColumn<T>> get _columnTree => [
        if (widget.selection != null) _selectionColumn,
        if (widget.expandable?.showColumn ?? false) _expandColumn,
        ...widget.columns,
      ];

  /// The columns that hold cells: the ones given, with any group replaced by
  /// what stands under it.
  ///
  /// A sort and a filter are keyed by a column's place among these, since a
  /// group has nothing to sort or narrow.
  List<TableColumn<T>> get _leaves =>
      widget.columns.expand((c) => c.leaves).toList();

  /// Whether any column heads others, so the heading needs more than one row.
  bool get _hasGroups => widget.columns.any((c) => c.isGroup);

  /// Whether any column adds something up, so there is a row to draw for it.
  bool get _hasSummary => _leaves.any((c) => c.summary != null);

  /// Whether any cell covers its neighbours, so the body is drawn row by row
  /// rather than as a grid.
  bool get _hasSpans => _leaves.any((c) => c.span != null);

  List<TableColumn<T>> _pinnedTo(TableColumnFixed side) =>
      _columns.where((c) => c.fixed == side).toList();

  /// The columns that scroll.
  List<TableColumn<T>> get _loose =>
      _columns.where((c) => c.fixed == null).toList();

  /// Asked of what was given, plus the box column's own pinning — not of
  /// [_columns]. Building that column needs the cell padding, which needs to
  /// know whether anything is pinned: going through [_columns] here was a
  /// stack overflow the first time a table was drawn with a selection.
  bool get _hasPinned =>
      widget.columns.any((c) => c.fixed != null) ||
      widget.selection?.fixed != null;

  double _pinnedWidth(TableColumnFixed side) =>
      _pinnedTo(side).fold(0, (sum, c) => sum + c.width!);

  /// The height every row is held to exactly, or null where it is not.
  ///
  /// Pinning turns one table into three laid out apart from each other, and
  /// separate tables work out their own row heights: measured side by side,
  /// one wrapping cell put two of them a hundred and forty pixels out of
  /// step. A height they all know is what keeps their rows level — and it has
  /// to be exact, not a floor. Tried as a floor first, and a cell that wrapped
  /// past it put the panes eight pixels out again.
  double? _exactHeight(Token t) => _hasPinned ? _rowHeight(t) : null;

  /// The height every row of a lazy body is laid out at.
  ///
  /// A body that finds a row by multiplying needs one height for all of them,
  /// and it has to be the height the row would have taken anyway: laid out at
  /// the preset's control height with the cell's padding still on, the text
  /// had nowhere to go and came out cut in half.
  double _lazyRowHeight(_ResolvedTableToken r, Token t) =>
      _uniformHeight(t) ??
      _cellPadding(r, t).vertical +
          _TableWidths.lineHeight(
            _bodyStyle(r, t),
            MediaQuery.textScalerOf(context),
            Directionality.of(context),
          );

  /// The style a cell's text is drawn in, and so the style it is measured in.
  TextStyle _bodyStyle(_ResolvedTableToken r, Token t) =>
      DefaultTextStyle.of(context).style.copyWith(
            fontSize: r.fontSize,
            fontFamily: t.fontFamily,
            fontFamilyFallback: t.fontFamilyFallback,
            fontWeight: t.fontWeight,
          );

  /// The height a row will not go under, or null where content decides.
  double? _uniformHeight(Token t) => _exactHeight(t) ?? _askedRowHeight(t);

  Alignment _alignment(TableAlign align) => switch (align) {
        TableAlign.start => AlignmentDirectional.centerStart.resolve(
            Directionality.of(context),
          ),
        TableAlign.center => Alignment.center,
        TableAlign.end => AlignmentDirectional.centerEnd.resolve(
            Directionality.of(context),
          ),
      };

  TextAlign _textAlign(TableAlign align) => switch (align) {
        TableAlign.start => TextAlign.start,
        TableAlign.center => TextAlign.center,
        TableAlign.end => TextAlign.end,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<TableToken>(context) ??
            const TableToken())
        ._resolve(t);

    final rule = BorderSide(color: r.borderColor, width: t.lineWidth);
    // Every band draws the rows in the order they are shown, and the title
    // and summary are handed the same order.
    final rows = _rows;
    flutter.TableRow headingRow(List<TableColumn<T>> columns) =>
        flutter.TableRow(
          decoration: BoxDecoration(
            color: r.headerBg,
            border: Border(bottom: rule),
          ),
          children: [
            for (final column in columns)
              _headingCell(
                _cell(
                  _heading(column, _leaves.indexOf(column), r, t),
                  column,
                  column.headerAlign ?? column.align ?? TableAlign.start,
                  r,
                  t,
                ),
                column,
                _leaves.indexOf(column),
                r,
              ),
          ],
        );

    List<flutter.TableRow> dataRowsOf(List<TableColumn<T>> columns) => [
          for (var i = 0; i < rows.length; i++)
            flutter.TableRow(
              decoration: BoxDecoration(
                // Every row but the last carries the rule below it, so the
                // table does not end on a line hanging under nothing.
                border: i == rows.length - 1 ? null : Border(bottom: rule),
              ),
              children: [
                for (final column in columns) _rowCell(i, column, r, t),
              ],
            ),
        ];

    flutter.Table grid(
      List<TableColumn<T>> columns,
      List<flutter.TableRow> of, {
      Map<int, TableColumnWidth>? widths,
    }) =>
        flutter.Table(
          columnWidths: widths ?? _widthsFor(columns, r),
          // Every cell in a row is as tall as the tallest, which is what
          // keeps a row a row when one cell wraps and its neighbours do not.
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: _bordered
              ? TableBorder(
                  verticalInside: rule,
                  horizontalInside: BorderSide.none,
                )
              : null,
          children: of,
        );

    /// One band of the table — a heading, a run of rows, or both together.
    /// One band of the table — a heading, a run of rows, or both together.
    Widget band(List<TableColumn<T>> columns, {required _Band which}) {
      final of = <flutter.TableRow>[
        if (_showHeader && which != _Band.rows) headingRow(columns),
        if (which != _Band.heading) ...dataRowsOf(columns),
      ];
      return grid(columns, of);
    }

    final startPinned = _pinnedTo(TableColumnFixed.start);
    final endPinned = _pinnedTo(TableColumnFixed.end);
    final loose = _loose;

    // Only what is left after the pinned columns. No allowance for the
    // sharing columns' floors: MaxColumnWidth already grows the table past
    // this when it has to, and measured, adding one changed nothing.
    final middleWidth = _across == null
        ? null
        : _across! -
            _pinnedWidth(TableColumnFixed.start) -
            _pinnedWidth(TableColumnFixed.end);

    /// The columns that scroll, laid out at the width left for them.
    Widget scrolling(_Band which) {
      final middle = band(loose, which: which);
      if (middleWidth == null) return middle;
      // The width asked for, or what the columns need, whichever is more. A
      // table laid out narrower than its own columns overflows its box, and
      // the scroll then only runs as far as the box: fifteen columns wanting
      // fifteen hundred pixels inside a declared eleven hundred left four
      // hundred that could not be reached at all.
      final sized = SizedBox(
        width: math.max(middleWidth, _leastWidth(loose, r)),
        child: middle,
      );
      // Each band scrolls itself; the two are kept together. Only the rows
      // wear the bar — two bars for one table would be one too many.
      return which == _Band.heading
          ? _across1D(sized, t, _headingX)
          : _across1D(sized, t, _rowsX);
    }

    // A pinned pane casts over what has gone behind it, and only then: at
    // rest against its own end there is nothing there to shade. Listening to
    // the offset rather than rebuilding on it — the pane is passed through as
    // a child, so it is the shadow that is redrawn and not the columns.
    _noteLength();
    Widget shaded(
      Widget middle, {
      required bool fromStart,
      required bool fromEnd,
    }) =>
        AnimatedBuilder(
          animation: _acrossGeometry,
          builder: (context, child) {
            final offset = _acrossOffset.value;
            // hasContentDimensions as well as hasClients: a position exists
            // before it has been told how much there is to scroll, and asking
            // it then throws.
            final max =
                _rowsX.hasClients && _rowsX.position.hasContentDimensions
                    ? _rowsX.position.maxScrollExtent
                    : 0.0;

            Widget strip({required bool atStart}) => PositionedDirectional(
                  start: atStart ? 0 : null,
                  end: atStart ? null : 0,
                  top: 0,
                  bottom: 0,
                  width: r.pinnedShadowExtent,
                  // Inside the Positioned, not around it: a parent data
                  // widget has to sit directly under its Stack.
                  child: IgnorePointer(
                      child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: atStart
                            ? AlignmentDirectional.centerStart
                            : AlignmentDirectional.centerEnd,
                        end: atStart
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        colors: [
                          r.pinnedShadowColor,
                          r.pinnedShadowColor.withAlpha(0),
                        ],
                      ),
                    ),
                  )),
                );

            return Stack(
              children: [
                child!,
                // A shade only where a column is standing over rows that have
                // gone behind it: at rest against its own end there is
                // nothing there to cast over.
                if (fromStart && offset > 0.5) strip(atStart: true),
                if (fromEnd && offset < max - 0.5) strip(atStart: false),
              ],
            );
          },
          // Listening to the offset rather than rebuilding on it — the pane
          // is passed through as a child, so it is the shade that is redrawn
          // and not the columns.
          child: middle,
        );

    // The rule between two panes, drawn as the pane's own inner edge rather
    // than as a strip between them: a strip would have to be stretched to the
    // pane's height, and asking for that inside a scroll view is asking for
    // an infinite one. Inside a pane the table draws its own rules; between
    // them there was nothing, so a pinned column ran into its neighbour with
    // no line at all.
    Widget seamed(Widget pane, {required bool atStart}) => DecoratedBox(
          decoration: BoxDecoration(
            border: BorderDirectional(
              end: atStart ? rule : BorderSide.none,
              start: atStart ? BorderSide.none : rule,
            ),
          ),
          child: pane,
        );

    /// A row of panes: pinned, scrolling, pinned.
    Widget panes(_Band which) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (startPinned.isNotEmpty)
              _bordered
                  ? seamed(band(startPinned, which: which), atStart: true)
                  : band(startPinned, which: which),
            Expanded(
              child: shaded(
                scrolling(which),
                fromStart: startPinned.isNotEmpty,
                fromEnd: endPinned.isNotEmpty,
              ),
            ),
            if (endPinned.isNotEmpty)
              _bordered
                  ? seamed(band(endPinned, which: which), atStart: false)
                  : band(endPinned, which: which),
          ],
        );

    /// A table whose rows open, drawn as a run of grids with the panels
    /// between them.
    ///
    /// Flutter's `Table` has no way of spanning a row across every column, so
    /// a panel cannot be a row of the grid — it has to sit between two grids.
    /// Which is only safe if the grids agree on their widths, so the columns
    /// are measured once and every grid is told the same numbers, rather than
    /// each working out its own from the rows it happens to hold.
    Widget opening(List<TableColumn<T>> columns) {
      final style = _bodyStyle(r, t);
      final inline = _cellPadding(r, t).horizontal;
      final scaler = MediaQuery.textScalerOf(context);
      return LayoutBuilder(
        builder: (context, constraints) {
          final available = math.max(
            constraints.hasBoundedWidth ? constraints.maxWidth : 0.0,
            _across ?? 0.0,
          );
          final measured = _resolveWidths(
            columns,
            available,
            r,
            t,
            style,
            inline,
            scaler,
          );
          final widths = <int, TableColumnWidth>{
            for (var i = 0; i < columns.length; i++)
              i: FixedColumnWidth(measured.columns[i]),
          };

          final children = <Widget>[
            if (_showHeader)
              if (_hasGroups)
                _groupedHeading(_columnTree, measured.columns, r, t, rule)
              else
                grid(columns, [headingRow(columns)], widths: widths),
          ];

          Widget panelFor(int i) => Expandable(
                expanded: _isExpanded(rows[i]),
                destroyWhenCollapsed: true,
                // The panel is added at the moment its row opens, so it has
                // to start shut and grow — otherwise it arrives at full
                // height with no reveal at all.
                animateOnMount: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: r.expandedBg,
                    border: Border(bottom: rule),
                  ),
                  // Never shorter than a row, and free to be taller. A row
                  // whose height was named carries no vertical padding — the
                  // height itself stands in for it — so a panel padded the
                  // same way collapsed to the height of its text.
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: _uniformHeight(t) ?? 0,
                    ),
                    child: Padding(
                      padding: _cellPadding(r, t),
                      child: widget.expandable!.builder(context, rows[i], i),
                    ),
                  ),
                ),
              );

          if (_hasSpans) {
            // Laid out by hand: a cell reaching across two columns cannot be
            // a cell of the grid, so there is no grid to run. A body with a
            // cell reaching *down* comes back as one placed block, and there
            // is nowhere between its rows to put a panel.
            final laid =
                _spannedRows(columns, measured.columns, rows, r, t, rule);
            if (laid.length == rows.length) {
              for (var i = 0; i < rows.length; i++) {
                children.add(laid[i]);
                if (_hasPanel(rows[i])) children.add(panelFor(i));
              }
            } else {
              children.addAll(laid);
              for (var i = 0; i < rows.length; i++) {
                if (_hasPanel(rows[i])) children.add(panelFor(i));
              }
            }
          } else {
            final data = dataRowsOf(columns);
            var run = <flutter.TableRow>[];
            void flush() {
              if (run.isEmpty) return;
              children.add(grid(columns, run, widths: widths));
              run = [];
            }

            for (var i = 0; i < rows.length; i++) {
              run.add(data[i]);
              if (!_hasPanel(rows[i])) continue;
              flush();
              // The same reveal a `Collapse` panel uses, so a table opens the
              // way everything else in the kit opens.
              children.add(panelFor(i));
            }
            flush();
          }
          if (_hasSummary) {
            children.add(
              _summaryRow(columns, measured.columns, rows, r, t, rule),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        },
      );
    }

    Widget table;
    if (widget.expandable != null || _hasGroups || _hasSummary || _hasSpans) {
      // Rows that open are drawn as grids with panels between them, and a
      // heading of more than one row is drawn by hand — a `Table` cannot span
      // a cell across its columns, so a group's title cannot be a cell of the
      // grid. Both want one measured set of widths rather than each part
      // working out its own. A height of its own simply scrolls the lot: a
      // panel is whatever height its content is, and a lazy body can only
      // find a row by multiplying.
      table = _detached
          ? SizedBox(
              height: widget.scroll!.y,
              child: _handOn(
                SingleChildScrollView(
                  child: RepaintBoundary(child: opening(_columns)),
                ),
              ),
            )
          : opening(_columns);
    } else if (_detached && widget.data.isNotEmpty) {
      // A height of its own is what makes the rows worth building lazily, and
      // it is also what a lazy body needs: a row is found by multiplying, so
      // every row has to be one height. A table with no height of its own
      // keeps the grid below, where a cell that wraps still grows its row.
      table = SizedBox(
        // `scroll.y` is the height of the rows, not of the table, and the
        // heading stands above them. One viewport now holds both, so the
        // heading's row is added back on rather than eating into the body.
        height: widget.scroll!.y! + (_showHeader ? _lazyRowHeight(r, t) : 0),
        child: _handOn(_lazyBody(r, t, rule)),
      );
    } else if (!_hasPinned) {
      final all = <flutter.TableRow>[
        if (_showHeader) headingRow(_columns),
        ...dataRowsOf(_columns),
      ];
      table = _detached
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_showHeader) grid(_columns, [all.first]),
                // The rows scroll; the heading, being outside this, does not.
                SizedBox(
                  height: widget.scroll!.y,
                  child: _handOn(
                    SingleChildScrollView(
                      // Its own layer, so a scroll re-offers the rows rather
                      // than painting them again: measured over twenty ticks,
                      // five hundred and seventeen milliseconds became three
                      // hundred and ninety-eight.
                      child: RepaintBoundary(
                        child: grid(
                          _columns,
                          _showHeader ? all.skip(1).toList() : all,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : grid(_columns, all);
    } else if (_detached) {
      // Two viewports here, one for the heading and one for the rows, kept in
      // step by hand — the only arrangement where that is unavoidable, since
      // the heading must stay put vertically while travelling horizontally
      // with rows that are inside a different scroll.
      table = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showHeader) panes(_Band.heading),
          SizedBox(
            height: widget.scroll!.y,
            child: _handOn(
              SingleChildScrollView(
                child: RepaintBoundary(child: panes(_Band.rows)),
              ),
            ),
          ),
        ],
      );
    } else {
      // One viewport: the heading rides with its own rows inside each pane.
      table = panes(_Band.both);
    }

    if (widget.data.isEmpty) {
      table = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The heading alone: the columns are still worth showing, and the
          // panes still line up because they always did.
          if (_showHeader) panes(_Band.heading),
          Padding(
            padding: EdgeInsets.symmetric(vertical: t.sizeXL),
            child: widget.empty ??
                (ConfigProvider.emptyBuilderOf(context) ?? _defaultEmpty)(
                  context,
                  EmptySlot.table,
                ),
          ),
        ],
      );
    }

    Widget body = DefaultTextStyle.merge(
      style: TextStyle(
        fontSize: r.fontSize,
        color: t.colorText,
        fontFamily: t.fontFamily,
        fontFamilyFallback: t.fontFamilyFallback,
        fontWeight: t.fontWeight,
        decoration: TextDecoration.none,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.header != null)
            Container(
              padding: _cellPadding(r, t),
              decoration: BoxDecoration(border: Border(bottom: rule)),
              child: widget.header!(context, rows),
            ),
          table,
          if (widget.footer != null)
            Container(
              padding: _cellPadding(r, t),
              decoration: BoxDecoration(
                color: r.footerBg,
                border: Border(top: rule),
              ),
              child: widget.footer!(context, rows),
            ),
        ],
      ),
    );

    if (_across != null && !_hasPinned) {
      // One scroll view around the heading and the rows together, rather than
      // one each kept in step by hand: laid out side by side inside the same
      // viewport they cannot drift apart, because there is only one offset.
      //
      // Not where a column is pinned, though: there the scrolling belongs to
      // the middle pane alone, and wrapping the lot would carry the pinned
      // ones off with it — which is exactly what it did before this guard.
      body = _across1D(
        SizedBox(
          width: math.max(_across!, _leastWidth(_columns, r)),
          child: body,
        ),
        t,
        _rowsX,
      );
    }

    // The outline goes on before the pager does, so the pager stands outside
    // it: a pager is about the table rather than part of it, and drawn inside
    // the frame it left the last row with nothing under it — the row's own
    // rule is the one the outline stands in for.
    if (_bordered) {
      body = DecoratedBox(
        // In front of the rows, not behind them. A row with a fill of its own
        // — the heading, the row that adds up — is opaque right to the edge,
        // and painted straight over a frame drawn behind it: measured at the
        // left edge, a body row showed the rule at alpha 15 while the summary
        // beside it came out pure white.
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(color: r.borderColor, width: t.lineWidth),
          borderRadius: BorderRadius.circular(r.borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r.borderRadius),
          child: body,
        ),
      );
    }

    if (widget.pagination != null) {
      final where = widget.pagination!.position;
      final above = where.where((p) => p.isTop);
      final below = where.where((p) => p.isBottom);
      if (above.isNotEmpty || below.isNotEmpty) {
        body = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final at in above) _pager(t, at),
            Flexible(child: body),
            for (final at in below) _pager(t, at),
          ],
        );
      }
    }

    return Spin(spinning: widget.loading, child: body);
  }

  /// What the last width reckoning was asked, and what it answered.
  ///
  /// Measuring is exact and therefore proportional to the data: five hundred
  /// rows of fifteen columns is seven and a half thousand strings, and at
  /// fifteen microseconds each that is a hundred and seventeen milliseconds
  /// every time anything above the table calls `setState` — a tap on a row,
  /// measured. The answer only changes when the question does.
  _TableWidths? _widths;
  Object? _widthsAsked;

  /// The sort the table keeps for itself while nobody is controlling it.
  TableSort? _ownSort;
  bool _startedSort = false;

  /// The sort in force: the one given, or the one the table is keeping.
  TableSort? get _sort {
    if (widget.sort != null) return widget.sort;
    if (!_startedSort) {
      _startedSort = true;
      _ownSort = widget.defaultSort;
    }
    return _ownSort;
  }

  /// The choices the table keeps for itself while nobody is controlling them.
  Map<int, List<Object?>>? _ownFilters;
  bool _startedFilters = false;

  /// The choices in force.
  Map<int, List<Object?>> get _filters {
    if (widget.filters != null) return widget.filters!;
    if (!_startedFilters) {
      _startedFilters = true;
      _ownFilters = widget.defaultFilters;
    }
    return _ownFilters ?? const {};
  }

  /// What a filter menu makes of the choices when it is applied.
  void _applyFilter(int column, List<Object?> chosen) {
    final next = {
      for (final entry in _filters.entries)
        if (entry.key != column && entry.value.isNotEmpty)
          entry.key: entry.value,
      if (chosen.isNotEmpty) column: chosen,
    };
    if (widget.filters == null) setState(() => _ownFilters = next);
    widget.onFiltersChanged?.call(next);
  }

  /// The page and page size the table keeps while nobody controls them.
  int? _ownPage;
  int? _ownPageSize;
  bool _startedPaging = false;

  void _startPaging() {
    if (_startedPaging) return;
    _startedPaging = true;
    _ownPage = widget.pagination!.defaultPage;
    _ownPageSize = widget.pagination!.defaultPageSize;
  }

  int get _pageSize {
    final paging = widget.pagination!;
    if (paging.pageSize != null) return paging.pageSize!;
    _startPaging();
    return _ownPageSize!;
  }

  /// Which page is shown, held inside what there is to show.
  ///
  /// Clamped rather than reset: narrowing a table until the page you were on
  /// no longer exists should land you on the last one, not throw you back to
  /// the first, and never on a page with nothing on it.
  int get _page {
    final paging = widget.pagination!;
    final counted = paging.total ?? _narrowed.length;
    int asked;
    if (paging.page != null) {
      asked = paging.page!;
    } else {
      _startPaging();
      asked = _ownPage!;
    }
    final pages = math.max(1, (counted / _pageSize).ceil());
    return asked.clamp(1, pages);
  }

  void _goToPage(int page, int size) {
    final paging = widget.pagination!;
    if (paging.page == null || paging.pageSize == null) {
      setState(() {
        if (paging.page == null) _ownPage = page;
        if (paging.pageSize == null) _ownPageSize = size;
      });
    }
    paging.onChanged?.call(page, size);
  }

  /// The rows the table keeps open while nobody is controlling them.
  List<T>? _ownExpanded;
  bool _startedExpanded = false;

  /// The rows standing open.
  List<T> get _expanded {
    final expandable = widget.expandable;
    if (expandable == null) return const [];
    if (expandable.expanded != null) return expandable.expanded!;
    if (!_startedExpanded) {
      _startedExpanded = true;
      _ownExpanded = expandable.defaultExpanded;
    }
    return _ownExpanded ?? const [];
  }

  bool _isExpanded(T record) => _expanded.contains(record);

  bool _canExpand(T record) =>
      widget.expandable?.expandable?.call(record) ?? true;

  /// Rows whose panel is on its way shut.
  ///
  /// A panel that is simply dropped from the tree cannot animate closed, so a
  /// row stays here — and its panel stays built at a shrinking height — until
  /// the motion is over.
  final Set<T> _closing = {};
  final List<Timer> _closers = [];

  void _toggleExpanded(T record) {
    final expandable = widget.expandable!;
    if (!_canExpand(record)) return;
    final next = [..._expanded];
    final shutting = next.remove(record);
    if (!shutting) next.add(record);
    if (expandable.expanded == null) {
      setState(() => _ownExpanded = next);
    }
    expandable.onChanged?.call(next);
    if (shutting) _holdWhileClosing(record);
  }

  void _holdWhileClosing(T record) {
    setState(() => _closing.add(record));
    final over = context.softToken.motionDurationMid;
    _closers.add(Timer(over, () {
      if (!mounted) return;
      setState(() => _closing.remove(record));
    }));
  }

  /// The rows a panel is drawn for: the ones open, and the ones closing.
  bool _hasPanel(T record) => _isExpanded(record) || _closing.contains(record);

  /// The rows the table keeps picked while nobody is controlling them.
  List<T>? _ownSelected;
  bool _startedSelection = false;

  /// The rows picked.
  List<T> get _selected {
    final selection = widget.selection;
    if (selection == null) return const [];
    if (selection.selected != null) return selection.selected!;
    if (!_startedSelection) {
      _startedSelection = true;
      _ownSelected = selection.defaultSelected;
    }
    return _ownSelected ?? const [];
  }

  bool _isSelected(T record) => _selected.contains(record);

  bool _canSelect(T record) =>
      widget.selection?.selectable?.call(record) ?? true;

  void _select(List<T> next) {
    if (widget.selection!.selected == null) {
      setState(() => _ownSelected = next);
    }
    widget.selection!.onChanged?.call(next);
  }

  /// Picking one row, or letting it go.
  void _toggleRow(T record, {required bool on}) {
    final selection = widget.selection!;
    if (selection.mode == TableSelectionMode.radio) {
      _select(on ? [record] : const []);
      return;
    }
    final next = [..._selected];
    if (on) {
      if (!next.contains(record)) next.add(record);
    } else {
      next.remove(record);
    }
    _select(next);
  }

  /// The rows the heading's box answers for: the ones on show that may be
  /// picked at all. Not every row handed over — a filter narrowing the table
  /// narrows what "all" means, which is what it means everywhere else.
  List<T> get _selectableOnShow => [
        for (final record in _rows)
          if (_canSelect(record)) record
      ];

  /// Whether every such row is picked, none of them, or some.
  ({bool all, bool some}) get _selectionState {
    final available = _selectableOnShow;
    if (available.isEmpty) return (all: false, some: false);
    var picked = 0;
    for (final record in available) {
      if (_isSelected(record)) picked++;
    }
    return (all: picked == available.length, some: picked > 0);
  }

  void _toggleAll({required bool on}) {
    final available = _selectableOnShow;
    if (on) {
      // What was already picked but is not on show stays picked: a filter
      // hides rows, it does not un-pick them.
      final next = [..._selected];
      for (final record in available) {
        if (!next.contains(record)) next.add(record);
      }
      _select(next);
    } else {
      _select([
        for (final record in _selected)
          if (!available.contains(record)) record,
      ]);
    }
  }

  /// The rows in the order they are shown.
  ///
  /// Sorted once per data and sort rather than per build, and stable: rows
  /// that compare equal stay in the order they were given, so sorting by a
  /// column with ties does not shuffle the rest.
  List<T>? _rowsCache;
  Object? _rowsAsked;

  List<T> get _narrowed {
    final sort = _sort;
    final filters = _filters;
    final asked = Object.hash(
      identityHashCode(widget.data),
      sort,
      Object.hashAll([
        for (final entry in filters.entries) ...[
          entry.key,
          Object.hashAll(entry.value),
        ],
      ]),
    );
    if (_rowsAsked == asked && _rowsCache != null) return _rowsCache!;

    _rowsAsked = asked;
    return _rowsCache = _sorted(_filtered(widget.data, filters), sort);
  }

  /// The rows on show: a page of [_narrowed], or every one of them where the
  /// table is not paged.
  ///
  /// Everything that draws works from this, so a row's index is its place on
  /// the page — and picking, opening and tapping all mean the row the reader
  /// is looking at.
  List<T> get _rows {
    if (widget.pagination == null) return _narrowed;
    // A total the caller named means the rows here are already one page —
    // taken out by whatever knows the rest — so there is nothing to slice.
    if (widget.pagination!.total != null) return _narrowed;
    final rows = _narrowed;
    final size = _pageSize;
    final from = (_page - 1) * size;
    if (from >= rows.length) return const [];
    return rows.sublist(from, math.min(from + size, rows.length));
  }

  /// The rows that belong under every filter in force.
  ///
  /// Every one of them: a row shown is a row that answered each column being
  /// narrowed, which is what narrowing twice means. Within one column the
  /// choices are alternatives, so a row belongs if it answers any of them.
  List<T> _filtered(List<T> rows, Map<int, List<Object?>> filters) {
    var kept = rows;
    for (final entry in filters.entries) {
      if (entry.value.isEmpty) continue;
      final leaves = _leaves;
      if (entry.key < 0 || entry.key >= leaves.length) continue;
      final column = leaves[entry.key];
      if (!column.filtersRows) continue;
      final belongs = column.onFilter ??
          (Object? choice, T record) => column.value?.call(record) == choice;
      kept = [
        for (final record in kept)
          if (entry.value.any((choice) => belongs(choice, record))) record,
      ];
    }
    return kept;
  }

  /// The rows in the order the sort asks for, or as they are where none does.
  List<T> _sorted(List<T> rows, TableSort? sort) {
    final leaves = _leaves;
    if (sort == null || sort.column < 0 || sort.column >= leaves.length) {
      return rows;
    }
    final column = leaves[sort.column];
    if (!column.sorts) return rows;

    final ascending = sort.order == TableSortOrder.ascending;
    final sorter = column.sorter;

    // Kept beside the row rather than read inside the comparison: a sort asks
    // for the same value again and again, and the index is what breaks a tie
    // — Dart's sort is not stable, and twenty rows of one value came out
    // shuffled without it.
    final keyed = [
      for (var i = 0; i < rows.length; i++)
        (i, rows[i], sorter == null ? column.value!(rows[i]) : null),
    ]..sort((a, b) {
        final by = sorter != null
            ? (ascending ? sorter(a.$2, b.$2) : sorter(b.$2, a.$2))
            : _compare(a.$3, b.$3, ascending: ascending);
        return by != 0 ? by : a.$1.compareTo(b.$1);
      });

    return [for (final row in keyed) row.$2];
  }

  /// Comparing two of the values a column reads.
  ///
  /// A row with nothing in the column goes last whichever way round, so the
  /// direction is applied to the comparison and not to that rule — turned
  /// round with everything else, a blank cell rose to the top of a descending
  /// sort, which is not what a blank cell means.
  ///
  /// A value that cannot be compared leaves the rows where they are rather
  /// than throwing: a column of mixed types is a mistake, but not one worth a
  /// crash in the middle of a table.
  static int _compare(Object? a, Object? b, {required bool ascending}) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    if (a is! Comparable || b is! Comparable) return 0;
    final int by;
    try {
      by = Comparable.compare(a, b);
    } on TypeError {
      return 0;
    }
    return ascending ? by : -by;
  }

  /// What a tap on a sortable heading makes of the sort.
  ///
  /// Ascending, then descending, then back to the order the rows came in,
  /// which is what a reader expects of a third tap: somewhere to put the
  /// rows back without reaching for anything else.
  void _cycleSort(int column) {
    final was = _sort;
    final next = was == null || was.column != column
        ? TableSort(column, TableSortOrder.ascending)
        : was.order == TableSortOrder.ascending
            ? TableSort(column, TableSortOrder.descending)
            : null;
    if (widget.sort == null) setState(() => _ownSort = next);
    widget.onSortChanged?.call(next);
  }

  /// The rows the cached widths were measured from, kept to be compared
  /// against the next lot.
  List<T>? _measuredRows;

  /// Whether the rows are the rows that were measured.
  ///
  /// Element by element, not by the list's identity: `data: [...]` written
  /// inline is a new list on every build and would never match, which is most
  /// of the callers. A comparison costs a few microseconds where measuring
  /// the same rows costs a hundred and seventeen milliseconds, so it is worth
  /// making even when it fails.
  bool _sameRows() {
    final was = _measuredRows;
    if (was == null || was.length != widget.data.length) return false;
    for (var i = 0; i < was.length; i++) {
      if (was[i] != widget.data[i]) return false;
    }
    return true;
  }

  /// The rest of the question: everything but the rows.
  ///
  /// The columns cannot be compared by identity either — a `columns:` list is
  /// usually built fresh on every build, closures and all — so what is
  /// compared is the shape of them, which is what the widths are worked out
  /// from.
  Object _ask(
    List<TableColumn<T>> columns,
    double available,
    TextStyle style,
    double inlinePadding,
    TextScaler scaler,
  ) =>
      Object.hash(
        available,
        style,
        inlinePadding,
        scaler,
        Object.hashAll([
          for (final column in columns) ...[
            column.width,
            column.flex,
            column.fixed,
            column.ellipsis,
            switch (column.title) { Text(:final data) => data, _ => null },
          ],
        ]),
      );

  /// The columns in the order the lazy body wants them: pinned to the start,
  /// then the ones that travel, then pinned to the end.
  ///
  /// What is painted behind a row.
  ///
  /// A row that has been picked is tinted whether or not the pointer is on
  /// it — otherwise a picked row looks exactly like every other one, and the
  /// tick in front of it is the only thing saying so.
  Color _rowFill(
    int index, {
    required bool hovered,
    required _ResolvedTableToken r,
  }) {
    final rows = _rows;
    final picked = widget.selection != null &&
        index >= 0 &&
        index < rows.length &&
        _isSelected(rows[index]);
    if (picked) return hovered ? r.rowSelectedHoverBg : r.rowSelectedBg;
    return hovered ? r.rowHoverBg : const Color(0x00000000);
  }

  /// The token, resolved wherever it is wanted rather than only in `build`.
  _ResolvedTableToken get _token => (widget.token ??
          ConfigProvider.componentOf<TableToken>(context) ??
          const TableToken())
      ._resolve(context.softToken);

  /// The column of boxes, built as any other column is.
  TableColumn<T> get _selectionColumn {
    final selection = widget.selection!;
    return TableColumn<T>(
      align: TableAlign.center,
      headerAlign: TableAlign.center,
      // Wide enough for a box *and* the padding the cell will put either
      // side of it: measured against the preset's padding rather than named
      // as a number, since a compact table pads less and a roomy one more.
      width: selection.columnWidth ??
          _cellPadding(_token, context.softToken).horizontal +
              _token.selectionColumnWidth,
      fixed: selection.fixed,
      title:
          selection.mode == TableSelectionMode.radio || !selection.showSelectAll
              // Nothing at the head: taking every row is not something a column
              // of dots can mean, and a heading box that does nothing is worse
              // than none.
              ? const SizedBox.shrink()
              : Builder(
                  builder: (context) {
                    final state = _selectionState;
                    return Checkbox(
                      checked: state.all,
                      indeterminate: state.some && !state.all,
                      disabled: _selectableOnShow.isEmpty,
                      onChanged: (on) => _toggleAll(on: on),
                    );
                  },
                ),
      builder: (context, record, index) {
        final can = _canSelect(record);
        return selection.mode == TableSelectionMode.radio
            ? Radio<bool>(
                value: true,
                groupValue: _isSelected(record),
                disabled: !can,
                onChanged: (_) => _toggleRow(record, on: true),
              )
            : Checkbox(
                checked: _isSelected(record),
                disabled: !can,
                onChanged: (on) => _toggleRow(record, on: on),
              );
      },
    );
  }

  /// The column of chevrons, built as any other column is.
  TableColumn<T> get _expandColumn {
    final expandable = widget.expandable!;
    return TableColumn<T>(
      align: TableAlign.center,
      headerAlign: TableAlign.center,
      width: expandable.columnWidth ??
          _cellPadding(_token, context.softToken).horizontal +
              _token.expandIconSize,
      fixed: expandable.fixed,
      title: const SizedBox.shrink(),
      builder: (context, record, index) {
        // A row that cannot be opened shows nothing: an arrow that does not
        // move is worse than no arrow.
        if (!_canExpand(record)) return const SizedBox.shrink();
        final open = _isExpanded(record);
        final t = context.softToken;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _toggleExpanded(record),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: open ? 1 : 0),
              duration: t.motionDurationMid,
              curve: t.motionEaseInOut,
              builder: (context, shut, _) => CustomPaint(
                size: Size.square(_token.expandIconSize),
                painter: _ExpandIconPainter(
                  bar: _token.headerColor,
                  border: _token.borderColor,
                  radius: t.borderRadiusSM,
                  open: shut,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// A pinned column is the first or the last x index and nothing else — that
  /// is the whole of what pinning is, once one viewport owns both axes.
  /// The columns in the order they were given, box and chevron first.
  ///
  /// Held columns are no longer taken out and stacked at the edges: a column
  /// keeps its place among the others and stops when the scroll would carry
  /// it past its rest, so a loose column can stand between two held ones and
  /// slide under them.
  List<TableColumn<T>> get _ordered => _columns;

  /// What a heading asks for, where it can be asked without building it.
  ///
  /// A `Text` is measured like any other string. Anything else is a widget
  /// whose width nothing here can guess, and a column headed by one has to
  /// name a [TableColumn.width] if its heading is the widest thing in it.
  List<double?> _headingWidths(
    List<TableColumn<T>> columns,
    TextStyle style,
    double inlinePadding,
  ) =>
      [
        for (final column in columns)
          switch (column.title) {
            Text(:final data?) => _TableWidths.measure(
                  data,
                  style,
                  MediaQuery.textScalerOf(context),
                  Directionality.of(context),
                ) +
                inlinePadding,
            _ => null,
          },
      ];

  /// One cell of a body laid out by hand, with the rules it carries.
  ///
  /// The rules go on the cell rather than on the row: a cell reaching down
  /// two rows must not have a line drawn through the middle of it, and a row
  /// that carried its own rule drew exactly that.
  Widget _spanCell(
    int y,
    int x,
    TableColumn<T> column,
    ({int across, int down}) span,
    int columnCount,
    int rowCount,
    _ResolvedTableToken r,
    Token t,
    BorderSide rule,
  ) =>
      DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(
            end: x + span.across >= columnCount || !_bordered
                ? BorderSide.none
                : rule,
            // Under the last row this cell covers, and not under the last row
            // of the table — there the outline stands in for it.
            bottom: y + span.down >= rowCount
                ? BorderSide.none
                : Border(bottom: rule).bottom,
          ),
        ),
        child: _rowCell(y, column, r, t),
      );

  /// The body drawn by hand, where a cell may cover its neighbours.
  ///
  /// A `Table` maps a row's children onto its columns one for one, so a cell
  /// reaching across two of them cannot be a cell of the grid. Rows are laid
  /// out against the measured widths instead — the same widths the heading
  /// and the summary are given, which is what keeps them lined up.
  ///
  /// Which cells are covered is worked out here rather than asked of the
  /// caller: a cell that spans marks the places it takes, and a place already
  /// taken is drawn as nothing at all.
  ///
  /// A cell reaching *down* needs to know how tall a row is before it can be
  /// laid out over two of them, so a table with one holds every row to one
  /// height — as a lazy body does, and for the same reason. Spanning columns
  /// alone leaves the rows to their content.
  List<Widget> _spannedRows(
    List<TableColumn<T>> columns,
    List<double> widths,
    List<T> rows,
    _ResolvedTableToken r,
    Token t,
    BorderSide rule,
  ) {
    // Worked out first, because whether any cell reaches down decides how the
    // whole body is laid out.
    final taken = <int, Set<int>>{};
    final placed = <(
      int y,
      int x,
      TableColumn<T> column,
      ({int across, int down}) span
    )>[];
    var reachesDown = false;

    for (var y = 0; y < rows.length; y++) {
      var x = 0;
      while (x < columns.length) {
        if (taken[y]?.contains(x) ?? false) {
          x++;
          continue;
        }
        final column = columns[x];
        final asked =
            column.span?.call(context, rows[y], y) ?? const TableCellSpan();
        // Never past the last column or the last row: a span asking for more
        // than there is takes what there is.
        final across = math.min(asked.columns, columns.length - x);
        final down = math.min(asked.rows, rows.length - y);
        if (down > 1) reachesDown = true;

        for (var dy = 0; dy < down; dy++) {
          for (var dx = 0; dx < across; dx++) {
            if (dy == 0 && dx == 0) continue;
            (taken[y + dy] ??= {}).add(x + dx);
          }
        }
        placed.add((y, x, column, (across: across, down: down)));
        x += across;
      }
    }

    double widthAt(int x, int across) {
      var total = 0.0;
      for (var i = 0; i < across; i++) {
        total += widths[x + i];
      }
      return total;
    }

    double startAt(int x) {
      var total = 0.0;
      for (var i = 0; i < x; i++) {
        total += widths[i];
      }
      return total;
    }

    if (!reachesDown) {
      // Nothing reaches down, so the rows can be rows and keep the heights
      // their content asks for.
      return [
        for (var y = 0; y < rows.length; y++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final cell in placed.where((c) => c.$1 == y))
                  SizedBox(
                    width: widthAt(cell.$2, cell.$4.across),
                    child: _spanCell(
                      cell.$1,
                      cell.$2,
                      cell.$3,
                      cell.$4,
                      columns.length,
                      rows.length,
                      r,
                      t,
                      rule,
                    ),
                  ),
              ],
            ),
          ),
      ];
    }

    // A cell standing over two rows has to be placed, not laid in a row, and
    // placing it needs a height known before the fact.
    final height = _lazyRowHeight(r, t);
    return [
      SizedBox(
        height: height * rows.length,
        child: Stack(
          children: [
            for (final cell in placed)
              Positioned(
                left: startAt(cell.$2),
                top: height * cell.$1,
                width: widthAt(cell.$2, cell.$4.across),
                height: height * cell.$4.down,
                child: _spanCell(
                  cell.$1,
                  cell.$2,
                  cell.$3,
                  cell.$4,
                  columns.length,
                  rows.length,
                  r,
                  t,
                  rule,
                ),
              ),
          ],
        ),
      ),
    ];
  }

  /// The row that adds the columns up, drawn under the rest.  /// The row that adds the columns up, drawn under the rest.
  ///
  /// Laid out by hand against the same measured widths the body is given,
  /// like the heading of a grouped table — and for the same reason, since a
  /// summary that spans columns cannot be a row of the grid either.
  Widget _summaryRow(
    List<TableColumn<T>> columns,
    List<double> widths,
    List<T> rows,
    _ResolvedTableToken r,
    Token t,
    BorderSide rule,
  ) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: r.summaryBg,
          border: Border(top: rule),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < columns.length; i++)
                SizedBox(
                  width: widths[i],
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: BorderDirectional(
                        end: i == columns.length - 1 || !_bordered
                            ? BorderSide.none
                            : rule,
                      ),
                    ),
                    child: _cell(
                      columns[i].summary?.call(context, rows) ??
                          const SizedBox.shrink(),
                      columns[i],
                      columns[i].align ?? TableAlign.start,
                      r,
                      t,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  /// A heading of more than one row, where columns are grouped.
  ///
  /// Flutter's `Table` maps a row's children onto its columns one for one, so
  /// a title spanning several of them cannot be a cell of the grid. The
  /// heading is laid out by hand instead, against the same measured widths the
  /// body is given — which is what keeps the two lined up.
  ///
  /// Built as a tree rather than as a run of rows: a group is its title above
  /// a row of what it heads, and a column that heads nothing is one cell
  /// stretched to whatever height its neighbours came to. That is what lets a
  /// plain column stand the full depth of the heading beside a group, without
  /// spanning anything downwards by hand.
  Widget _groupedHeading(
    List<TableColumn<T>> columns,
    List<double> widths,
    _ResolvedTableToken r,
    Token t,
    BorderSide rule,
  ) {
    var at = 0;

    double widthOf(TableColumn<T> column) {
      var total = 0.0;
      for (var i = 0; i < column.headingSpan; i++) {
        total += widths[at + i];
      }
      return total;
    }

    Widget node(TableColumn<T> column) {
      final width = widthOf(column);
      final last = at + column.headingSpan >= widths.length;

      if (!column.isGroup) {
        final index = _leaves.indexOf(column);
        at += 1;
        return SizedBox(
          width: width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: rule,
                right: !last && _bordered ? rule : BorderSide.none,
              ),
            ),
            child: _headingCell(
              _cell(
                _heading(column, index, r, t),
                column,
                column.headerAlign ?? column.align ?? TableAlign.start,
                r,
                t,
              ),
              column,
              index,
              r,
            ),
          ),
        );
      }

      // A group's own title first, ruled off from what it heads, then that
      // row of columns under it.
      final children = column.children!;
      return SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: rule,
                  right: !last && _bordered ? rule : BorderSide.none,
                ),
              ),
              child: _cell(
                DefaultTextStyle.merge(
                  style: TextStyle(
                    color: r.headerColor,
                    fontWeight: t.fontWeightStrong,
                  ),
                  child: column.title ?? const SizedBox.shrink(),
                ),
                column,
                column.headerAlign ?? TableAlign.center,
                r,
                t,
              ),
            ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final child in children) node(child)],
              ),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(color: r.headerBg),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final column in columns) node(column)],
        ),
      ),
    );
  }

  /// The heading's content: its title, and where the column sorts, the pair
  /// of carets at the far edge of the cell.
  Widget _heading(
    TableColumn<T> column,
    int index,
    _ResolvedTableToken r,
    Token t,
  ) {
    final title = DefaultTextStyle.merge(
      style: TextStyle(color: r.headerColor, fontWeight: t.fontWeightStrong),
      child: column.title ?? const SizedBox.shrink(),
    );
    if (!column.sorts && !column.filtersRows) return title;
    if (!column.sorts) {
      return Row(
        children: [
          Expanded(
            child: Align(
              alignment: _alignment(
                column.headerAlign ?? column.align ?? TableAlign.start,
              ),
              child: title,
            ),
          ),
          _funnel(column, index, r, t),
        ],
      );
    }

    final sort = _sort;
    // The carets stand at the cell's trailing edge rather than beside the
    // word: a column of headings whose carets each sat at the end of a word
    // of its own length is a ragged edge.
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: _alignment(
              column.headerAlign ?? column.align ?? TableAlign.start,
            ),
            child: title,
          ),
        ),
        SizedBox(width: t.sizeXXS),
        _Carets(
          order: sort?.column == index ? sort!.order : null,
          active: r.headerMarkActiveColor,
          idle: r.headerMarkColor,
          size: r.sortCaretSize,
        ),
        if (column.filtersRows) _funnel(column, index, r, t),
      ],
    );
  }

  /// The funnel at the head of a column that can be narrowed, and the menu it
  /// opens.
  Widget _funnel(
    TableColumn<T> column,
    int index,
    _ResolvedTableToken r,
    Token t,
  ) {
    final narrowing = (_filters[index] ?? const []).isNotEmpty;
    return Dropdown<Object?>(
      // A click, not a hover: a menu with checkboxes and two words to end it
      // is not something to open by passing over it.
      trigger: const [DropdownTrigger.click],
      content: (context, close) => _filterMenu(column, index, close, r, t),
      // Its own detector under the heading's: the innermost recognizer takes
      // the tap, so opening the menu does not also sort the column.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: ValueListenableBuilder<int?>(
          valueListenable: _hoveredFunnel,
          builder: (context, hovered, child) {
            final over = hovered == index;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => _hoveredFunnel.value = index,
              onExit: (_) {
                if (_hoveredFunnel.value == index) {
                  _hoveredFunnel.value = null;
                }
              },
              // The funnel takes a ground of its own under the hand, rounded
              // and a step stronger than the heading it sits in. Sharing the
              // heading's would leave the two answering as one, when tapping
              // the mark and tapping the heading do different things.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: over ? r.filterHoverBg : const Color(0x00000000),
                  borderRadius: BorderRadius.circular(t.borderRadiusSM),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: t.sizeXXS,
                    vertical: t.sizeXXS / 2,
                  ),
                  child: CustomPaint(
                    size: Size.square(r.filterIconSize),
                    painter: _FunnelPainter(
                      narrowing
                          ? r.headerMarkActiveColor
                          : over
                              ? r.headerColor
                              : r.headerMarkColor,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The menu itself: the choices, and the two words that end it.
  Widget _filterMenu(
    TableColumn<T> column,
    int index,
    VoidCallback close,
    _ResolvedTableToken r,
    Token t,
  ) =>
      _FilterMenu<T>(
        column: column,
        chosen: _filters[index] ?? const [],
        onApply: (chosen) {
          _applyFilter(index, chosen);
          close();
        },
        r: r,
      );

  /// A heading cell that answers the pointer, where its column sorts.
  ///
  /// The whole cell, padding and all: a heading you have to hit exactly is a
  /// heading you miss.
  Widget _headingCell(
    Widget cell,
    TableColumn<T> column,
    int index,
    _ResolvedTableToken r,
  ) {
    if (!column.sorts) return cell;
    // A column the table is sorted by keeps the fill, hand or no hand: it is
    // the one doing something, so it is the one marked. Which also means the
    // fill arrives with a `defaultSort`, before anybody has touched it.
    final sorted = _sort?.column == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _hoveredHeading.value = index,
      onExit: (_) {
        if (_hoveredHeading.value == index) _hoveredHeading.value = null;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _cycleSort(index),
        child: ValueListenableBuilder<int?>(
          valueListenable: _hoveredHeading,
          builder: (context, hovered, child) => ColoredBox(
            color: sorted || hovered == index
                ? r.headerHoverBg
                : const Color(0x00000000),
            child: child,
          ),
          child: cell,
        ),
      ),
    );
  }

  /// One cell of the lazy body:  /// One cell of the lazy body: a heading when it is the top row, a data cell
  /// otherwise.
  Widget _lazyCell(
    ChildVicinity at,
    List<TableColumn<T>> columns,
    _ResolvedTableToken r,
    Token t,
    BorderSide rule,
  ) {
    final column = columns[at.xIndex];
    final heading = _showHeader && at.yIndex == 0;
    final index = at.yIndex - (_showHeader ? 1 : 0);
    final last = index == _rows.length - 1;

    final border = Border(
      bottom: heading || !last ? rule : BorderSide.none,
      right:
          _bordered && at.xIndex != columns.length - 1 ? rule : BorderSide.none,
    );

    if (heading) {
      return DecoratedBox(
        decoration: BoxDecoration(
          // The heading's own fill is a two per cent wash, so a held column's
          // heading was see-through and the others could be watched
          // travelling behind it. Composited over the held ground rather than
          // stacked in a second box: one opaque colour, laid on once.
          color: column.fixed == null
              ? r.headerBg
              : Color.alphaBlend(r.headerBg, r.pinnedBg),
          border: border,
        ),
        child: _headingCell(
          _padded(
            _heading(column, at.xIndex, r, t),
            column,
            column.headerAlign ?? column.align ?? TableAlign.start,
            r,
            t,
          ),
          column,
          at.xIndex,
          r,
        ),
      );
    }

    final record = _rows[index];
    Widget cell = DecoratedBox(
      decoration: BoxDecoration(
        // A held column stands over the ones sliding under it, so it needs a
        // ground of its own — the rows themselves are only as opaque as their
        // fill, which is nothing at all until the pointer is on them.
        color: column.fixed == null ? null : r.pinnedBg,
        border: border,
      ),
      child: _padded(
        column.builder?.call(context, record, index) ?? _text(column, record),
        column,
        column.align ?? TableAlign.start,
        r,
        t,
      ),
    );
    final opens = widget.expandable?.byRowTap ?? false;
    if (widget.onRowTap != null || opens) {
      cell = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onRowTap?.call(record, index);
          if (opens) _toggleExpanded(record);
        },
        child: cell,
      );
    }
    if (!_hoverable) return cell;
    return MouseRegion(
      onEnter: (_) => _hovered.value = index,
      onExit: (_) {
        if (_hovered.value == index) _hovered.value = null;
      },
      child: ValueListenableBuilder<int?>(
        valueListenable: _hovered,
        builder: (context, hovered, child) => ColoredBox(
          color: _rowFill(index, hovered: hovered == index, r: r),
          child: child,
        ),
        child: cell,
      ),
    );
  }

  /// The body of a table that scrolls, built as it comes into view.
  ///
  /// Only the rows on screen are built. Five hundred rows of fifteen columns
  /// is seven and a half thousand cells, and building them to show forty was
  /// the whole of the cost.
  /// The widths every column is drawn at, worked out once and kept.
  _TableWidths _resolveWidths(
    List<TableColumn<T>> columns,
    double available,
    _ResolvedTableToken r,
    Token t,
    TextStyle style,
    double inline,
    TextScaler scaler,
  ) {
    final asked = _ask(columns, available, style, inline, scaler);
    final widths = _widthsAsked == asked && _widths != null && _sameRows()
        ? _widths!
        : _widths = _TableWidths.resolve<T>(
            columns: columns,
            data: widget.data,
            available: available,
            bodyStyle: style,
            inlinePadding: inline,
            minWidth: r.columnMinWidth,
            textScaler: scaler,
            textDirection: Directionality.of(context),
            headerNatural: _headingWidths(
              columns,
              style.copyWith(fontWeight: t.fontWeightStrong),
              inline,
            ),
            builderNatural: List<double?>.filled(columns.length, null),
          );
    _widthsAsked = asked;
    _measuredRows = widget.data;
    return widths;
  }

  Widget _lazyBody(_ResolvedTableToken r, Token t, BorderSide rule) {
    final columns = _ordered;
    final style = _bodyStyle(r, t);
    final inline = _cellPadding(r, t).horizontal;
    final scaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = math.max(
          constraints.hasBoundedWidth ? constraints.maxWidth : 0.0,
          _across ?? 0.0,
        );
        final widths = _resolveWidths(
          columns,
          available,
          r,
          t,
          style,
          inline,
          scaler,
        );

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              ...ScrollConfiguration.of(context).dragDevices,
              PointerDeviceKind.mouse,
            },
            scrollbars: false,
          ),
          child: _Rows(
            widths: widths.columns,
            rowHeight: _lazyRowHeight(r, t),
            headerRows: _showHeader ? 1 : 0,
            pinning: [for (final c in columns) c.fixed],
            shadeColor: r.pinnedShadowColor,
            shadeExtent: r.pinnedShadowExtent,
            verticalDetails: const ScrollableDetails.vertical(),
            horizontalDetails: const ScrollableDetails.horizontal(),
            delegate: TwoDimensionalChildBuilderDelegate(
              // Nothing in a cell wants keeping alive, and the default wraps
              // every one of them in an AutomaticKeepAlive and a selection
              // listener — two elements and two notifications a cell, for a
              // state no cell has.
              addAutomaticKeepAlives: false,
              maxXIndex: columns.length - 1,
              maxYIndex: _rows.length - 1 + (_showHeader ? 1 : 0),
              builder: (context, vicinity) =>
                  _lazyCell(vicinity, columns, r, t, rule),
            ),
          ),
        );
      },
    );
  }

  Widget _defaultEmpty(BuildContext context, EmptySlot slot) => const Empty();

  /// The pager, where the table is paged.
  ///
  /// The kit's own [Pagination], so a theme's `PaginationDefaults` reaches it
  /// as it reaches any other and nothing here restyles it.
  Widget _pager(Token t, TablePaginationPosition at) {
    final paging = widget.pagination!;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.size),
      child: Pagination(
        total: paging.total ?? _narrowed.length,
        current: _page,
        pageSize: _pageSize,
        onChange: _goToPage,
        onShowSizeChange: _goToPage,
        align: at.alignment,
        size: paging.size,
        simple: paging.simple,
        showSizeChanger: paging.showSizeChanger,
        pageSizeOptions: paging.pageSizeOptions,
        showQuickJumper: paging.showQuickJumper,
        showTotal: paging.showTotal,
        hideOnSinglePage: paging.hideOnSinglePage,
      ),
    );
  }

  /// Hands what the rows cannot use back to the page they sit on.
  ///
  /// A scroll view inside another does not chain: reaching its own end, it
  /// simply stops, and the page under it stays where it is. Measured, a table
  /// with a height of its own froze the page for as long as the pointer was
  /// over it — thirteen drags and the page had not moved a pixel. What the
  /// rows cannot use is passed on.
  Widget _handOn(Widget rows) => NotificationListener<OverscrollNotification>(
        onNotification: (notification) {
          if (notification.depth != 0) return false;
          if (notification.metrics.axis != Axis.vertical) return false;
          final page = Scrollable.maybeOf(context);
          if (page == null) return false;
          final position = page.position;
          if (position.axis != Axis.vertical) return false;
          position.moveTo(
            (position.pixels + notification.overscroll).clamp(
              position.minScrollExtent,
              position.maxScrollExtent,
            ),
          );
          return true;
        },
        child: rows,
      );

  /// A scroll view that can actually be scrolled sideways.
  ///
  /// Two things stand in the way of that, both of them Flutter's defaults and
  /// neither of them obvious. `dragDevices` leaves the mouse out, so a scroll
  /// view cannot be dragged with one at all; and `buildScrollbar` returns the
  /// child untouched on the horizontal axis, so there is no bar to drag
  /// either. On the web that left a table that scrolls sideways with no way
  /// to do it — the wheel only goes down.
  Widget _across1D(
    Widget child,
    Token t,
    ScrollController controller,
  ) =>
      ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            ...ScrollConfiguration.of(context).dragDevices,
            PointerDeviceKind.mouse,
          },
          // No bar across the foot of a wide table, not even while it is
          // being scrolled: it is a line the design did not ask for, and it
          // sits over the last row. What says there is more to see is the
          // shade a pinned column casts, and the rows moving under the hand.
          scrollbars: false,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: controller,
          child: child,
        ),
      );

  /// One cell of a data row, with the row's hover and tap on it.
  ///
  /// The gesture goes on the cell rather than the row because Flutter's Table
  /// takes only [flutter.TableRow]s, which are not widgets and cannot listen
  /// for anything themselves.
  Widget _rowCell(
    int index,
    TableColumn<T> column,
    _ResolvedTableToken r,
    Token t,
  ) {
    final record = _rows[index];
    Widget cell = _cell(
      column.builder?.call(context, record, index) ?? _text(column, record),
      column,
      column.align ?? TableAlign.start,
      r,
      t,
    );
    final opens = widget.expandable?.byRowTap ?? false;
    if (widget.onRowTap != null || opens) {
      cell = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onRowTap?.call(record, index);
          if (opens) _toggleExpanded(record);
        },
        child: cell,
      );
    }
    if (!_hoverable) return cell;
    return MouseRegion(
      onEnter: (_) => _hovered.value = index,
      onExit: (_) {
        if (_hovered.value == index) _hovered.value = null;
      },
      // Only this row's cells are listening, so a pointer crossing the table
      // rebuilds two rows rather than all of them.
      child: ValueListenableBuilder<int?>(
        valueListenable: _hovered,
        builder: (context, hovered, child) => ColoredBox(
          color: _rowFill(index, hovered: hovered == index, r: r),
          child: child,
        ),
        child: cell,
      ),
    );
  }

  /// A column with no builder draws its value, and an absent one draws
  /// nothing rather than the word "null".
  Widget _text(TableColumn<T> column, T record) {
    final value = column.value?.call(record);
    return value == null ? const SizedBox.shrink() : Text('$value');
  }

  Widget _cell(
    Widget child,
    TableColumn<T> column,
    TableAlign align,
    _ResolvedTableToken r,
    Token t,
  ) {
    final exact = _exactHeight(t);
    if (exact != null) {
      // Held to it, not merely kept above it: a cell that needs more is cut
      // rather than allowed to shove its row's neighbours out of line.
      return SizedBox(
        height: exact,
        child: ClipRect(child: _padded(child, column, align, r, t)),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: _uniformHeight(t) ?? 0),
      child: _padded(child, column, align, r, t),
    );
  }

  Widget _padded(
    Widget child,
    TableColumn<T> column,
    TableAlign align,
    _ResolvedTableToken r,
    Token t,
  ) {
    return Padding(
      padding: _cellPadding(r, t),
      child: Align(
        alignment: _alignment(align),
        child: DefaultTextStyle.merge(
          textAlign: _textAlign(align),
          overflow: column.ellipsis ? TextOverflow.ellipsis : null,
          maxLines: column.ellipsis ? 1 : null,
          child: child,
        ),
      ),
    );
  }
}

/// What each column is wide, worked out without laying a single cell out.
///
/// A lazy table cannot ask its columns to negotiate: the rows that would do
/// the negotiating have not been built, and building them all is the cost
/// being removed. So the widths are settled first, from the text itself —
/// a [TextPainter] measures a string for the price of laying out that string,
/// and never touches the widget tree.
///
/// A column that names a [TableColumn.width] is that wide and is not
/// measured. A column with a [TableColumn.value] is measured over every row,
/// so its width is exact however many rows there are. A column that draws
/// with a [TableColumn.builder] and names no value cannot be measured this
/// way — nothing here can guess how wide a `Tag` is — and takes
/// [builderNatural] for that column, which the viewport fills in from the
/// cells it has actually built.
@immutable
class _TableWidths {
  const _TableWidths._(this.columns, this.total);

  /// One width per column, in the order they were given.
  final List<double> columns;

  /// What they add up to.
  final double total;

  static _TableWidths resolve<T>({
    required List<TableColumn<T>> columns,
    required List<T> data,
    required double available,
    required TextStyle bodyStyle,
    required double inlinePadding,
    required double minWidth,
    required TextScaler textScaler,
    required TextDirection textDirection,
    required List<double?> headerNatural,
    required List<double?> builderNatural,
  }) {
    final natural = List<double>.filled(columns.length, 0);
    final auto = <int>[];
    final flexed = <int>[];

    for (var i = 0; i < columns.length; i++) {
      final column = columns[i];
      if (column.width != null) {
        natural[i] = column.width!;
        continue;
      }
      if (column.flex != null) {
        flexed.add(i);
        // A flexed column still has a floor, or a share of nothing leaves it
        // at nothing.
        natural[i] = minWidth;
        continue;
      }
      auto.add(i);
      var widest = headerNatural[i] ?? 0;
      if (column.value != null) {
        for (final record in data) {
          final value = column.value!(record);
          if (value == null) continue;
          widest = math.max(
            widest,
            measure('$value', bodyStyle, textScaler, textDirection),
          );
        }
        widest += inlinePadding;
      } else {
        // Nothing to read, so the cells that were built have the say. Until
        // one has been, the column asks for its floor rather than nothing.
        widest =
            math.max(widest + inlinePadding, builderNatural[i] ?? minWidth);
      }
      natural[i] = widest;
    }

    // What is left over goes to the flexed columns first — that is what a
    // share is — and then, if there is still room, to the columns that sized
    // themselves, which is how a table fills its box rather than huddling at
    // one edge.
    final fixedTotal = natural.fold<double>(0, (sum, w) => sum + w);
    var slack = available.isFinite ? available - fixedTotal : 0.0;
    if (slack > 0 && flexed.isNotEmpty) {
      final parts = flexed.fold<int>(0, (sum, i) => sum + columns[i].flex!);
      for (final i in flexed) {
        natural[i] += slack * columns[i].flex! / parts;
      }
      slack = 0;
    }
    if (slack > 0 && auto.isNotEmpty) {
      final share = slack / auto.length;
      for (final i in auto) {
        natural[i] += share;
      }
    }

    return _TableWidths._(
      natural,
      natural.fold<double>(0, (sum, w) => sum + w),
    );
  }

  /// The height a line of this text takes, measured rather than reckoned:
  /// the arithmetic came out two pixels over what the engine actually lays
  /// out, and two pixels is a row that does not line up with a still one.
  static double lineHeight(
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      // Ascender and descender both, so the line is the line whatever is in
      // the cell.
      text: TextSpan(text: 'Ag', style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }

  /// The width one string wants, which is the width of the string.
  static double measure(
    String text,
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

/// The pair of carets at the head of a sortable column.
///
/// Both are always drawn: one caret alone would say the column is sorted
/// that way, and a column that merely can be sorted has to say so too. The
/// one standing for the order in force is the one coloured.
class _Carets extends StatelessWidget {
  const _Carets({
    required this.order,
    required this.active,
    required this.idle,
    required this.size,
  });

  final TableSortOrder? order;
  final Color active;
  final Color idle;
  final double size;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size(size * 1.6, size),
            painter: _CaretPainter(
              order == TableSortOrder.ascending ? active : idle,
              up: true,
            ),
          ),
          SizedBox(height: size * 0.3),
          CustomPaint(
            size: Size(size * 1.6, size),
            painter: _CaretPainter(
              order == TableSortOrder.descending ? active : idle,
              up: false,
            ),
          ),
        ],
      );
}

/// The menu a funnel opens: the choices, and the two words that end it.
///
/// A widget of its own rather than a `StatefulBuilder` closing over locals:
/// what has been ticked and what has been typed have to outlive a rebuild of
/// the overlay above, and locals do not — measured, a word typed into the
/// field was gone by the frame after it.
class _FilterMenu<T> extends StatefulWidget {
  const _FilterMenu({
    required this.column,
    required this.chosen,
    required this.onApply,
    required this.r,
  });

  final TableColumn<T> column;
  final List<Object?> chosen;
  final ValueChanged<List<Object?>> onApply;
  final _ResolvedTableToken r;

  @override
  State<_FilterMenu<T>> createState() => _FilterMenuState<T>();
}

class _FilterMenuState<T> extends State<_FilterMenu<T>> {
  late final Set<Object?> _chosen = {...widget.chosen};
  String _query = '';

  /// Whether a choice survives what has been typed.
  ///
  /// Case and the spaces around the word are ignored, because nobody typing
  /// into a menu means either of them.
  bool _matches(TableFilter choice) {
    final typed = _query.trim();
    if (typed.isEmpty) return true;
    final match = widget.column.filterSearchMatch;
    if (match != null) return match(typed, choice);
    return choice.label.toLowerCase().contains(typed.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = widget.r;
    final column = widget.column;
    final words = context.seedLocale;

    // Chosen but out of sight is still chosen: narrowing the menu must not
    // quietly drop a choice the reader has already made.
    final shown = [
      for (final filter in column.filters!)
        if (_matches(filter)) filter,
    ];

    // `Dropdown.content` is handed straight to the overlay — that is what it
    // is for, so a caller can draw its own surface. Ours wants the usual one,
    // and wants to be as wide as its widest choice: the popover offers loose
    // constraints, and without a panel and an intrinsic width the menu had no
    // ground of its own and took the whole width of the screen.
    return DropdownPanel(
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (column.filterSearches)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: r.borderColor,
                      width: t.lineWidth,
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(t.sizeXS),
                  child: SizedBox(
                    width: r.filterSearchWidth,
                    child: Input(
                      size: SoftSize.small,
                      placeholder: words.search,
                      onChanged: (typed) => setState(() => _query = typed),
                    ),
                  ),
                ),
              ),
            // A long list of choices scrolls rather than growing past the
            // screen.
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: r.filterMenuMaxHeight),
                child: SingleChildScrollView(
                  child: Padding(
                    // The same geometry as any other menu in the kit, taken
                    // from `DropdownMenuList` rather than picked: sizeXXS
                    // round the list, sizeSM either side of a row. A menu
                    // that reads as its own kind of thing is one the reader
                    // has to learn twice.
                    padding: EdgeInsets.all(t.sizeXXS),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final filter in shown)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: t.sizeSM,
                              vertical: t.sizeXXS,
                            ),
                            child: Checkbox(
                              checked: _chosen.contains(filter.value),
                              label: Text(filter.label),
                              onChanged: (on) => setState(() {
                                // One at a time where the column says so, and
                                // the choice replaces the one before it
                                // rather than joining it.
                                if (!column.filterMultiple) _chosen.clear();
                                if (on) {
                                  _chosen.add(filter.value);
                                } else {
                                  _chosen.remove(filter.value);
                                }
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // A rule across the whole block of buttons — the panel clips it
            // to its own corners — then sizeXS either side and
            // sizeXS - lineWidth above and below, so the rule does not add to
            // the height.
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: r.borderColor, width: t.lineWidth),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: t.sizeXS,
                  vertical: t.sizeXS - t.lineWidth,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Button(
                      variant: ButtonVariant.text,
                      size: SoftSize.small,
                      onPressed: _chosen.isEmpty
                          ? null
                          : () => widget.onApply(const []),
                      child: Text(words.reset),
                    ),
                    SizedBox(width: t.sizeXS),
                    Button(
                      variant: ButtonVariant.solid,
                      color: ButtonColor.primary,
                      size: SoftSize.small,
                      onPressed: () => widget.onApply(_chosen.toList()),
                      child: Text(words.ok),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A funnel: the mark at the head of a column that can be narrowed.
/// A plus inside a rounded square, which becomes a minus as the row opens.
///
/// [open] runs from nought to one, and the upright of the plus goes with it —
/// so the mark says what a tap will do rather than which way the row points.
class _ExpandIconPainter extends CustomPainter {
  const _ExpandIconPainter({
    required this.bar,
    required this.border,
    required this.radius,
    required this.open,
  });

  final Color bar;
  final Color border;
  final double radius;
  final double open;

  @override
  void paint(Canvas canvas, Size size) {
    final square = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.drawRRect(
      square,
      Paint()
        ..color = border
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    final paint = Paint()
      ..color = bar
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final c = size.center(Offset.zero);
    final arm = size.width * 0.26;
    // The crossbar stays; the upright shrinks away, so the mark reads as a
    // minus once the row is open.
    canvas.drawLine(Offset(c.dx - arm, c.dy), Offset(c.dx + arm, c.dy), paint);
    final up = arm * (1 - open);
    if (up > 0.1) {
      canvas.drawLine(Offset(c.dx, c.dy - up), Offset(c.dx, c.dy + up), paint);
    }
  }

  @override
  bool shouldRepaint(_ExpandIconPainter old) =>
      old.open != open || old.bar != bar || old.border != border;
}

class _FunnelPainter extends CustomPainter {
  const _FunnelPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.06, h * 0.16)
      ..lineTo(w * 0.94, h * 0.16)
      ..lineTo(w * 0.58, h * 0.54)
      ..lineTo(w * 0.58, h * 0.94)
      ..lineTo(w * 0.42, h * 0.82)
      ..lineTo(w * 0.42, h * 0.54)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FunnelPainter old) => old.color != color;
}

class _CaretPainter extends CustomPainter {
  const _CaretPainter(this.color, {required this.up});

  final Color color;
  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (up) {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CaretPainter old) => old.color != color || old.up != up;
}

/// The rows of a scrolling table, built as they come into view.
///
/// Both axes belong to one viewport rather than to a scroll view each: a
/// pinned column and a heading that stays put are questions about where a
/// cell sits, and a viewport that owns both answers them by laying the cell
/// out there. The heading is row zero, held at the top; the pinned columns
/// are the first and last x indices, held at the edges.
class _Rows extends TwoDimensionalScrollView {
  const _Rows({
    required this.widths,
    required this.rowHeight,
    required this.headerRows,
    required this.pinning,
    required this.shadeColor,
    required this.shadeExtent,
    required super.delegate,
    required super.verticalDetails,
    required super.horizontalDetails,
  }) // One recognizer per axis, rather than the pan that would follow a
  // finger diagonally. A pan asks the arena for more movement before it
  // will claim a drag, so inside a scrolling page the page's own vertical
  // drag won every time: measured, a hundred and thirty pixels of a
  // hundred and fifty went to the page and the rows did not move at all.
  // A trackpad is unaffected — a scroll is a pointer signal, not a drag.
  : super(diagonalDragBehavior: DiagonalDragBehavior.none);

  final List<double> widths;
  final double rowHeight;
  final int headerRows;

  /// Which columns are held at an edge, in the order they are drawn.
  final List<TableColumnFixed?> pinning;
  final Color shadeColor;
  final double shadeExtent;

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) =>
      _RowsViewport(
        widths: widths,
        rowHeight: rowHeight,
        headerRows: headerRows,
        pinning: pinning,
        shadeColor: shadeColor,
        shadeExtent: shadeExtent,
        horizontalOffset: horizontalOffset,
        horizontalAxisDirection: horizontalDetails.direction,
        verticalOffset: verticalOffset,
        verticalAxisDirection: verticalDetails.direction,
        delegate: delegate as TwoDimensionalChildBuilderDelegate,
        mainAxis: mainAxis,
      );
}

class _RowsViewport extends TwoDimensionalViewport {
  const _RowsViewport({
    required this.widths,
    required this.rowHeight,
    required this.headerRows,
    required this.pinning,
    required this.shadeColor,
    required this.shadeExtent,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required TwoDimensionalChildBuilderDelegate super.delegate,
    required super.mainAxis,
  });

  final List<double> widths;
  final double rowHeight;
  final int headerRows;

  /// Which columns are held at an edge, in the order they are drawn.
  final List<TableColumnFixed?> pinning;
  final Color shadeColor;
  final double shadeExtent;

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) =>
      _RenderRows(
        widths: widths,
        rowHeight: rowHeight,
        headerRows: headerRows,
        pinning: pinning,
        shadeColor: shadeColor,
        shadeExtent: shadeExtent,
        horizontalOffset: horizontalOffset,
        horizontalAxisDirection: horizontalAxisDirection,
        verticalOffset: verticalOffset,
        verticalAxisDirection: verticalAxisDirection,
        delegate: delegate as TwoDimensionalChildBuilderDelegate,
        mainAxis: mainAxis,
        childManager: context as TwoDimensionalChildManager,
      );

  @override
  void updateRenderObject(BuildContext context, _RenderRows renderObject) {
    renderObject
      ..widths = widths
      ..rowHeight = rowHeight
      ..headerRows = headerRows
      ..pinning = pinning
      ..shadeColor = shadeColor
      ..shadeExtent = shadeExtent
      ..horizontalOffset = horizontalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..verticalOffset = verticalOffset
      ..verticalAxisDirection = verticalAxisDirection
      ..delegate = delegate
      ..mainAxis = mainAxis;
  }
}

class _RenderRows extends RenderTwoDimensionalViewport {
  _RenderRows({
    required List<double> widths,
    required double rowHeight,
    required int headerRows,
    required List<TableColumnFixed?> pinning,
    required Color shadeColor,
    required double shadeExtent,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required TwoDimensionalChildBuilderDelegate super.delegate,
    required super.mainAxis,
    required super.childManager,
  })  : _widths = widths,
        _rowHeight = rowHeight,
        _headerRows = headerRows,
        _pinning = pinning,
        _shadeColor = shadeColor,
        _shadeExtent = shadeExtent {
    _measureColumns();
  }

  List<double> _widths;

  bool _sameWidths(List<double> other) {
    if (other.length != _widths.length) return false;
    for (var i = 0; i < other.length; i++) {
      if (other[i] != _widths[i]) return false;
    }
    return true;
  }

  set widths(List<double> value) {
    if (_sameWidths(value)) return;
    _widths = value;
    _measureColumns();
    markNeedsLayout();
  }

  double _rowHeight;
  set rowHeight(double value) {
    if (_rowHeight == value) return;
    _rowHeight = value;
    markNeedsLayout();
  }

  int _headerRows;
  set headerRows(int value) {
    if (_headerRows == value) return;
    _headerRows = value;
    markNeedsLayout();
  }

  List<TableColumnFixed?> _pinning;
  set pinning(List<TableColumnFixed?> value) {
    if (listEquals(_pinning, value)) return;
    _pinning = value;
    markNeedsLayout();
  }

  /// Where a column held at the leading edge comes to rest: behind the ones
  /// held before it, in the order they were given.
  ///
  /// A column keeps its place among the others and only stops when the scroll
  /// would carry it past this — which is what lets a loose column stand
  /// between two pinned ones and slide under them.
  double _restStart(int column) {
    var at = 0.0;
    for (var i = 0; i < column; i++) {
      if (_pinning[i] == TableColumnFixed.start) at += _widths[i];
    }
    return at;
  }

  /// The same at the trailing edge: how far in from the far side a column
  /// held there comes to rest, counting the ones held after it.
  double _restEndBefore(int column) {
    var at = 0.0;
    for (var i = 0; i < column; i++) {
      if (_pinning[i] == TableColumnFixed.end) at += _widths[i];
    }
    return at;
  }

  Color _shadeColor;
  set shadeColor(Color value) {
    if (_shadeColor == value) return;
    _shadeColor = value;
    markNeedsPaint();
  }

  double _shadeExtent;
  set shadeExtent(double value) {
    if (_shadeExtent == value) return;
    _shadeExtent = value;
    markNeedsPaint();
  }

  // What the last layout settled on, so the paint that follows knows which
  // cells belong to which band without working any of it out again.
  int _firstRow = 0;
  int _lastRow = -1;
  int _firstColumn = 0;
  int _lastColumn = -1;
  double _lead = 0;
  double _trail = 0;
  double _headerHeight = 0;

  int get _columnCount => _widths.length;

  /// The base class's cache extent, read without the deprecated getter: rows
  /// built one frame before they are wanted are rows nobody waits for.
  double _cache(double mainAxisExtent) => switch (scrollCacheExtent.style) {
        CacheExtentStyle.pixel => scrollCacheExtent.value,
        CacheExtentStyle.viewport => scrollCacheExtent.value * mainAxisExtent,
      };

  /// Where each column starts, worked out once when the widths change.
  ///
  /// Walking the widths per cell made the layout quadratic in the columns,
  /// and a table wide enough to want virtualising is exactly the one with
  /// enough columns for that to tell.
  List<double> _starts = const [];

  void _measureColumns() {
    final starts = List<double>.filled(_widths.length + 1, 0);
    for (var i = 0; i < _widths.length; i++) {
      starts[i + 1] = starts[i] + _widths[i];
    }
    _starts = starts;
  }

  /// Where a column starts, measured from the first column.
  double _startOf(int column) => _starts[column];

  double _extent(int from, int to) => _starts[to] - _starts[from];

  void _place(int column, int row, double dx, double dy) {
    final child = buildOrObtainChildFor(
      ChildVicinity(xIndex: column, yIndex: row),
    );
    if (child == null) return;
    child.layout(
      BoxConstraints.tightFor(width: _widths[column], height: _rowHeight),
    );
    parentDataOf(child).layoutOffset = Offset(dx, dy);
  }

  @override
  void layoutChildSequence() {
    final size = viewportDimension;
    final rows =
        (delegate as TwoDimensionalChildBuilderDelegate).maxYIndex! + 1;
    final bodyRows = rows - _headerRows;

    // Every column held at an edge, wherever it stands among the others.
    _lead = 0;
    _trail = 0;
    for (var i = 0; i < _columnCount; i++) {
      if (_pinning[i] == TableColumnFixed.start) _lead += _widths[i];
      if (_pinning[i] == TableColumnFixed.end) _trail += _widths[i];
    }
    _headerHeight = _headerRows * _rowHeight;

    final total = _extent(0, _columnCount);
    final freeWidth = math.max(0.0, size.width - _lead - _trail);
    _maxAcross = math.max(0.0, total - _lead - _trail - freeWidth);
    horizontalOffset.applyContentDimensions(0, _maxAcross);

    final bodyHeight = math.max(0.0, size.height - _headerHeight);
    verticalOffset.applyContentDimensions(
      0,
      math.max(0, bodyRows * _rowHeight - bodyHeight),
    );

    final across = horizontalOffset.pixels;
    final down = verticalOffset.pixels;

    // The cache extent is the base class's, and it is worth having: a row
    // built one frame before it is needed is a row that does not have to be
    // built while the finger is moving.
    _firstRow = bodyRows == 0
        ? 0
        : ((down - _cache(bodyHeight)) / _rowHeight)
            .floor()
            .clamp(0, bodyRows - 1);
    _lastRow = bodyRows == 0
        ? -1
        : ((down + bodyHeight + _cache(bodyHeight)) / _rowHeight)
                .ceil()
                .clamp(0, bodyRows) -
            1;

    /// Where a column is drawn: its own place, carried by the scroll, unless
    /// it is held at an edge and the scroll would take it past its rest.
    double placeOf(int i) {
      final natural = _startOf(i) - across;
      return switch (_pinning[i]) {
        TableColumnFixed.start => math.max(natural, _restStart(i)),
        TableColumnFixed.end =>
          math.min(natural, size.width - _trail + _restEndBefore(i)),
        null => natural,
      };
    }

    // A pinned column is always in view; a loose one only while its place is.
    _firstColumn = _columnCount;
    _lastColumn = -1;
    for (var i = 0; i < _columnCount; i++) {
      final at = placeOf(i);
      if (_pinning[i] == null &&
          (at + _widths[i] <= -_cache(freeWidth) ||
              at >= size.width + _cache(freeWidth))) {
        continue;
      }
      if (i < _firstColumn) _firstColumn = i;
      _lastColumn = i;
    }
    if (_lastColumn < _firstColumn) {
      _firstColumn = 0;
      _lastColumn = -1;
    }

    void band(int row, double dy) {
      for (var i = _firstColumn; i <= _lastColumn; i++) {
        if (_pinning[i] == null) {
          final at = placeOf(i);
          if (at + _widths[i] <= -_cache(freeWidth) ||
              at >= size.width + _cache(freeWidth)) {
            continue;
          }
        }
        _place(i, row, placeOf(i), dy);
      }
    }

    for (var y = _firstRow; y <= _lastRow; y++) {
      band(y + _headerRows, _headerHeight + y * _rowHeight - down);
    }
    if (_headerRows > 0) band(0, 0);
  }

  // One clip layer per band, kept between frames: pushing six new layers on
  // every scrolled pixel is a cost paid for nothing.
  final List<LayerHandle<ClipRectLayer>> _clips = [
    for (var i = 0; i < 6; i++) LayerHandle<ClipRectLayer>(),
  ];

  @override
  void dispose() {
    for (final clip in _clips) {
      clip.layer = null;
    }
    super.dispose();
  }

  /// Paints one rectangle of cells, clipped to the band it belongs to.
  ///
  /// The band is what makes a column pinned. Children are painted in the
  /// order of their [ChildVicinity], which puts the heading — row zero —
  /// first, under everything; and a column held at an edge would be painted
  /// under the columns running past it. Bands settle both, and the clip is
  /// what keeps a travelling cell out of a pinned one's ground.
  void _paintBand(
    PaintingContext context,
    Offset offset,
    LayerHandle<ClipRectLayer> clip,
    Rect bounds, {
    required TableColumnFixed? held,
    required int fromRow,
    required int toRow,
  }) {
    if (_lastColumn < _firstColumn || fromRow > toRow || bounds.isEmpty) {
      clip.layer = null;
      return;
    }
    clip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      bounds,
      (innerContext, innerOffset) {
        // Column by column, each one's shade laid down before the next
        // column's cells: a held column that has caught up covers the shade
        // of the one it came to rest behind, which is what makes the handover
        // a covering rather than a jump.
        for (var x = _firstColumn; x <= _lastColumn; x++) {
          if (_pinning[x] != held) continue;
          for (var y = fromRow; y <= toRow; y++) {
            final child = getChildFor(ChildVicinity(xIndex: x, yIndex: y));
            if (child == null) continue;
            final data = parentDataOf(child);
            if (!data.isVisible) continue;
            innerContext.paintChild(child, innerOffset + data.paintOffset!);
          }
          if (held != null) {
            _castFor(innerContext, innerOffset, x, bounds, held: held);
          }
        }
      },
      oldLayer: clip.layer,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null) return;
    final size = viewportDimension;
    final body = math.max(0.0, size.height - _headerHeight);
    final firstRow = _firstRow + _headerRows;
    final lastRow = _lastRow + _headerRows;
    final bodyBounds = Rect.fromLTWH(0, _headerHeight, size.width, body);
    final headBounds = Rect.fromLTWH(0, 0, size.width, _headerHeight);

    // The columns that travel, then the ones held at either edge over them,
    // then the heading over the lot. A held column keeps its place among the
    // others until the scroll would carry it past its rest, so it cannot be
    // painted by a band of its own the way a pane could — it is picked out by
    // how it is held, wherever it stands.
    const order = [null, TableColumnFixed.start, TableColumnFixed.end];
    for (var i = 0; i < order.length; i++) {
      _paintBand(
        context,
        offset,
        _clips[i],
        bodyBounds,
        held: order[i],
        fromRow: firstRow,
        toRow: lastRow,
      );
    }
    for (var i = 0; i < order.length; i++) {
      _paintBand(
        context,
        offset,
        _clips[i + 3],
        headBounds,
        held: order[i],
        fromRow: 0,
        toRow: _headerRows - 1,
      );
    }
  }

  /// The shade one held column casts over what has gone behind it.
  ///
  /// Drawn at that column's own trailing edge and moving with it, the way the
  /// reference hangs it off the cell itself rather than off the band: a shade
  /// belonging to the band jumped from one column's edge to the next the
  /// moment the second came to rest.
  ///
  /// Its strength comes from how far the column has been held — nought where
  /// the scroll has only just caught it, full a shade's width later. So it
  /// arrives with the scroll rather than switching on, and follows the hand
  /// instead of a clock.
  void _castFor(
    PaintingContext context,
    Offset offset,
    int column,
    Rect bounds, {
    required TableColumnFixed held,
  }) {
    final across = horizontalOffset.pixels;
    final natural = _startOf(column) - across;
    final atStart = held == TableColumnFixed.start;
    final rest = atStart
        ? _restStart(column)
        : viewportDimension.width - _trail + _restEndBefore(column);
    final heldBy = atStart ? rest - natural : natural - rest;
    if (heldBy <= 0) return;

    final strength = (heldBy / _shadeExtent).clamp(0.0, 1.0);
    final edge = atStart ? rest + _widths[column] : rest;
    final local = Rect.fromLTWH(
      atStart ? edge : edge - _shadeExtent,
      bounds.top,
      _shadeExtent,
      bounds.height,
    );
    if (local.isEmpty) return;

    final rect = local.shift(offset);
    final colour = Color.from(
      alpha: _shadeColor.a * strength,
      red: _shadeColor.r,
      green: _shadeColor.g,
      blue: _shadeColor.b,
      colorSpace: _shadeColor.colorSpace,
    );
    context.canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: atStart ? Alignment.centerLeft : Alignment.centerRight,
          end: atStart ? Alignment.centerRight : Alignment.centerLeft,
          colors: [colour, colour.withAlpha(0)],
        ).createShader(rect),
    );
  }

  /// How far the loose columns can be run, kept from the last layout so the
  /// paint knows whether there is anything left ahead to cast over.
  double _maxAcross = 0;
}
