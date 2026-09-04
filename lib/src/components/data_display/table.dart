import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart'
    show
        CacheExtentStyle,
        ClipRectLayer,
        LayerHandle,
        RenderAbstractViewport,
        ViewportOffset;
import 'package:flutter/widgets.dart' hide Table, TableRow;
// Flutter's own Table does the column arithmetic: it measures every cell in a
// column and gives them all the widest one's width, which is the behaviour a
// caller expects from a table and the reason none of this is written by hand.
// Ours takes the plain name, so Flutter's wears the prefix.
import 'package:flutter/widgets.dart' as flutter show Table, TableRow;

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/expandable.dart';
import '../../utils/popover.dart' show PopoverPlacement;
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
    this.checkStrictly = false,
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

  /// Whether a row of a tree is picked on its own rather than with its own.
  ///
  /// Left false, picking a row picks everything under it — however deep, and
  /// whether or not those rows are on show — and a row with some but not all
  /// of its own picked stands half-picked. Which is what a box on a branch
  /// usually means: the branch is a shorthand for what is under it.
  ///
  /// Told true, every row answers for itself alone. Nothing to do with a
  /// table that is not a tree.
  final bool checkStrictly;

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

/// Keeping the heading in view while the page scrolls past the table.
///
/// For a table whose rows are part of the page — one with a `scroll.y` of its
/// own already keeps its heading, since the rows scroll inside it.
///
/// ```dart
/// Table<User>(sticky: const TableSticky(), columns: columns, data: users)
/// ```
@immutable
class TableSticky {
  /// Creates a [TableSticky].
  const TableSticky({this.offsetHeader = 0});

  /// How far below the top of the page the heading comes to rest, for a page
  /// with a bar of its own standing there.
  final double offsetHeader;
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
    this.builder,
    this.children,
    this.indentSize,
    this.expanded,
    this.defaultExpanded,
    this.onChanged,
    this.expandable,
    this.byRowTap = false,
    this.panelHeight,
    this.showColumn = true,
    this.columnWidth,
    this.fixed,
  }) : assert(
          builder != null || children != null,
          'A row that opens has to have something to open into: name a '
          'builder for a panel, or children for rows.',
        );

  /// What is drawn under an opened row.
  ///
  /// One of this and [children] has to be named: a row that opens has to have
  /// something to open into, whether that is a panel of its own or rows of
  /// its own.
  final Widget Function(BuildContext context, T record, int index)? builder;

  /// The rows standing under a row, where the data is a tree.
  ///
  /// Named instead of [builder], a row opens into rows rather than into a
  /// panel: its own children slide in beneath it, indented, each with a mark
  /// of its own if it has children in turn. Nothing is nested in the layout —
  /// the tree is flattened to the rows on show, so a table of trees is the
  /// same table with more rows in it.
  ///
  /// ```dart
  /// TableExpandable<Person>(children: (p) => p.reports)
  /// ```
  ///
  /// The mark stands in the first column, before the cell's own content,
  /// rather than in a column of its own: a tree says where a row sits by
  /// where it starts, and a column of marks off to the side would say it
  /// twice.
  final List<T>? Function(T record)? children;

  /// How far each step down the tree is indented, in pixels.
  ///
  /// [TableToken.indentSize] where nothing is said.
  final double? indentSize;

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

  /// How tall an opened panel is, where you can say.
  ///
  /// Worth saying on a table with a `scroll.y`. A lazy body finds a row by
  /// reckoning where it starts, and a panel of whatever height its content
  /// happens to be cannot be reckoned with — so a table that opens rows
  /// builds every one of them unless the panel's height is named, and with
  /// it named the rows stay lazy.
  ///
  /// Left null the panel is as tall as what is in it, and the table builds
  /// all its rows. Which is the right trade for a few dozen; for a few
  /// hundred, name a height or page them.
  final double? panelHeight;

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

/// What a filter panel of your own is handed.
///
/// Everything it needs to do its work and nothing else: what is chosen, a way
/// to change that, and the three things it can do about it.
@immutable
class TableFilterControls {
  /// Creates a [TableFilterControls].
  const TableFilterControls({
    required this.chosen,
    required this.choose,
    required this.apply,
    required this.clear,
    required this.close,
  });

  /// What the panel has settled on so far, which is what was in force when it
  /// opened until [choose] says otherwise.
  final List<Object?> chosen;

  /// Changes what is chosen without narrowing anything yet — the panel's own
  /// working answer, kept for it so it survives a rebuild.
  final ValueChanged<List<Object?>> choose;

  /// Narrows the table by what is chosen, and shuts the panel.
  final VoidCallback apply;

  /// Gives every row back, and shuts the panel.
  final VoidCallback clear;

  /// Shuts the panel and leaves the table as it was.
  final VoidCallback close;
}

/// A filter panel of your own, in place of the menu of [TableColumn.filters].
///
/// A pair rather than a bare builder because where the panel hangs is the
/// panel's business as much as what is in it: the funnel it grows from stands
/// at the far end of the heading, so a panel wide enough to be useful would
/// sit off to the right of its own column if it were left to align its left
/// edge with the mark.
@immutable
class TableFilterPanel {
  /// Creates a [TableFilterPanel].
  const TableFilterPanel({required this.builder, this.placement});

  /// Draws the panel, handed what is chosen and what it can do about it.
  final Widget Function(BuildContext context, TableFilterControls panel)
      builder;

  /// Where the panel hangs from the mark that opens it.
  ///
  /// Hung by the heading's trailing edge where nothing is said — bottomRight
  /// in a left-to-right layout and bottomLeft in a mirrored one — which puts
  /// the panel under the column rather than off to the side of it. It still
  /// flips to stay on screen.
  final PopoverPlacement? placement;
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
/// Table(scroll: const TableScroll(y: 320), ...)     // a body that scrolls
/// Table(scroll: const TableScroll(x: 1200), ...)    // wider than its box
/// Table(scroll: const TableScroll.toContent(), ...) // as wide as it needs
/// ```
@immutable
class TableScroll {
  /// Creates a [TableScroll].
  const TableScroll({this.x, this.y})
      : assert(x == null || x > 0, 'a width to scroll across must be positive'),
        assert(y == null || y > 0, 'a height to scroll down must be positive');

  /// A table as wide as its columns need, scrolling sideways where that is
  /// wider than its box.
  ///
  /// The columns take the width of what is in them rather than a share of the
  /// box, so nothing is squeezed to fit and nothing is stretched to fill.
  /// Give [y] as well for a table that scrolls both ways.
  const TableScroll.toContent({this.y}) : x = double.infinity;

  /// The width to lay the table out at, however narrow its box.
  ///
  /// Null keeps it to the room it is given. A number wider than that is what
  /// puts a scrollbar under it, and [double.infinity] asks for the width the
  /// columns themselves want — which is what [TableScroll.toContent] writes.
  final double? x;

  /// The height of the scrolling body.
  ///
  /// Set this and the heading stops travelling with the rows: it sits above
  /// them and stays.
  final double? y;

  /// Whether the width is the columns' own rather than a number.
  bool get isToContent => x == double.infinity;
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

/// What every column of a [Table] falls back to.
///
/// Saying the same thing on each of ten columns is ten places to change it
/// and ten to get it wrong; this says it once. A column that names the field
/// itself wins — these are the answers for the columns that stay quiet.
///
/// ```dart
/// Table(
///   columnDefaults: const TableColumnDefaults(
///     align: TableAlign.center,
///     ellipsis: true,
///   ),
///   columns: columns,
///   data: rows,
/// )
/// ```
///
/// Only what reads as a house style is here — where the cells sit, whether
/// they cut off, how wide they are, which edge they are held at. What a
/// column *is* — its value, its title, what it sorts and filters by — is the
/// column's own business and belongs nowhere else.
@immutable
class TableColumnDefaults {
  /// Creates a [TableColumnDefaults].
  const TableColumnDefaults({
    this.width,
    this.flex,
    this.align,
    this.headerAlign,
    this.fixed,
    this.ellipsis,
  });

  /// What [TableColumn.width] falls back to.
  final double? width;

  /// What [TableColumn.flex] falls back to.
  final int? flex;

  /// What [TableColumn.align] falls back to.
  final TableAlign? align;

  /// What [TableColumn.headerAlign] falls back to.
  final TableAlign? headerAlign;

  /// What [TableColumn.fixed] falls back to.
  final TableColumnFixed? fixed;

  /// What [TableColumn.ellipsis] falls back to.
  final bool? ellipsis;
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
    this.sortPriority,
    this.filters,
    this.onFilter,
    this.filterMultiple = true,
    this.filterSearch = false,
    this.filterSearchMatch,
    this.filterPanel,
    this.filterIcon,
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
          sortPriority == null || sortable || sorter != null,
          'A priority says how a column takes part in a sort of several, so '
          'the column has to sort at all.',
        ),
        assert(
          !sortable || value != null || sorter != null,
          'A sortable column needs a value to compare, or a sorter that says '
          'how to compare the rows itself.',
        ),
        assert(
          filterPanel == null || value != null || onFilter != null,
          'A panel of your own still has to say what a choice means: give the '
          'column a value to match, or an onFilter.',
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

  /// How much this column has to say when several columns are sorted at once.
  ///
  /// A column that names one takes part in a sort of several: tapping its
  /// heading adds it to what is already in force rather than replacing it,
  /// and the higher number is compared first. A column that names none sorts
  /// alone — tapping it puts the table in order by that column and no other,
  /// which is what most tables mean by sorting.
  ///
  /// ```dart
  /// TableColumn(title: const Text('City'), sortable: true, sortPriority: 2, ...)
  /// TableColumn(title: const Text('Age'),  sortable: true, sortPriority: 1, ...)
  /// ```
  final int? sortPriority;

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

  /// Draws the filter panel yourself, in place of the menu of [filters].
  ///
  /// Naming one makes the column filterable, [filters] or no: a panel that
  /// asks for a word to search by has no list of choices to offer. Its builder
  /// is handed a [TableFilterControls] — what is chosen, a way to change that,
  /// and apply, clear and close — and its [TableFilterPanel.placement] says
  /// where it hangs.
  ///
  /// ```dart
  /// filterPanel: TableFilterPanel(
  ///   builder: (context, panel) => Input(
  ///     defaultValue: panel.chosen.firstOrNull as String?,
  ///     onChanged: (typed) => panel.choose([if (typed.isNotEmpty) typed]),
  ///     onSubmitted: (_) => panel.apply(),
  ///   ),
  /// )
  /// ```
  final TableFilterPanel? filterPanel;

  /// Draws the mark at the head of the column, in place of the funnel.
  ///
  /// Told whether the column is narrowing anything, since that is the one
  /// thing the mark has to say.
  final Widget Function(BuildContext context, bool narrowing)? filterIcon;

  /// This column with the table's answers filled in where it stayed quiet.
  ///
  /// A copy rather than a lookup at every reading: one place decides, and
  /// everything downstream is handed a column that already knows.
  TableColumn<T> _withDefaults(TableColumnDefaults d) => TableColumn<T>(
        value: value,
        builder: builder,
        title: title,
        width: width ?? d.width,
        flex: flex ?? d.flex,
        align: align ?? d.align,
        headerAlign: headerAlign ?? d.headerAlign,
        fixed: fixed ?? d.fixed,
        ellipsis: ellipsis || (d.ellipsis ?? false),
        sortable: sortable,
        sorter: sorter,
        sortPriority: sortPriority,
        filters: filters,
        onFilter: onFilter,
        filterMultiple: filterMultiple,
        filterSearch: filterSearch,
        filterSearchMatch: filterSearchMatch,
        filterPanel: filterPanel,
        filterIcon: filterIcon,
        // A group holds no cells of its own, so what falls to it falls to its
        // leaves: a width or an alignment named once reaches all the way down.
        children:
            children?.map((c) => c._withDefaults(d)).toList(growable: false),
        summary: summary,
        span: span,
      );

  /// Whether this column filters at all.
  bool get filtersRows => filters != null || filterPanel != null;

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
    this.rowSortedBg,
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
    this.dragShadow,
    this.indentSize,
    this.pinnedShadowColor,
    this.pinnedShadowExtent,
    this.headerHoverBg,
    this.headerMarkActiveColor,
    this.headerMarkColor,
    this.headerMarkHoverColor,
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

  /// Fill behind the cells of a column the table is sorted by.
  ///
  /// The same fill the hand leaves, since the two say the same thing: this
  /// column is the one doing something. A hand over the row does not make it
  /// darker again — there is nothing more to say.
  final Color? rowSortedBg;

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

  /// The shadow under a row or a heading being carried.
  ///
  /// What is in the hand is lifted off the table, and the shadow is the whole
  /// of how that is said — the rotation and the scale are too slight to say
  /// it on their own.
  final List<BoxShadow>? dragShadow;

  /// How far each step down a tree of rows is indented.
  final double? indentSize;

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

  /// What it darkens to while the pointer is on the heading.
  ///
  /// A mark that is only offered says so quietly; under the hand it says the
  /// heading will answer. The one in force keeps its own colour — the hand
  /// has nothing to add to a column already sorted by.
  final Color? headerMarkHoverColor;

  /// How tall the pair of carets stands, all told.
  ///
  /// The reference sets a font size on the two glyphs rather than a size on
  /// each triangle, so this is the mark's own size and the carets are worked
  /// out from it.
  final double? sortCaretSize;

  /// How big the funnel at the head of a filtered column is.
  final double? filterIconSize;

  /// How tall a filter menu grows before its choices scroll.
  final double? filterMenuMaxHeight;

  /// How wide the field that narrows a filter menu is.
  final double? filterSearchWidth;

  /// How big the mark that opens a row is.
  ///
  /// A checkbox's size, which is what the reference scales it to: a column of
  /// boxes and a column of marks that open should agree.
  final double? expandIconSize;

  /// Fill behind the panel under an opened row.
  final Color? expandedBg;

  /// Fill behind anything held in place: a column at an edge, or a heading
  /// held in view while the page scrolls past.
  ///
  /// It has to be opaque. A held column stands over the ones sliding under
  /// it and a held heading over its own rows, while a row is only as opaque
  /// as its own fill — which is nothing until the pointer is on it.
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
        rowSortedBg: rowSortedBg ?? t.colorFillQuaternary,
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
        dragShadow: dragShadow ?? t.boxShadowSecondary,
        indentSize: indentSize ?? t.sizeMD,
        pinnedShadowColor: pinnedShadowColor ?? t.colorSplit,
        pinnedShadowExtent: pinnedShadowExtent ?? t.sizeSM,
        headerHoverBg: headerHoverBg ?? t.colorFillSecondary,
        headerMarkActiveColor: headerMarkActiveColor ?? t.primary.base,
        headerMarkColor: headerMarkColor ?? t.colorTextQuaternary,
        headerMarkHoverColor: headerMarkHoverColor ?? t.colorTextTertiary,
        // A step above the funnel beside it: two small triangles read as
        // less than one solid shape of the same height, so matching the
        // numbers made the sorter look the smaller of the two.
        sortCaretSize: sortCaretSize ?? t.fontSize,
        filterIconSize: filterIconSize ?? t.sizeSM,
        filterMenuMaxHeight: filterMenuMaxHeight ?? 264,
        filterHoverBg: filterHoverBg ?? t.colorFill,
        filterSearchWidth: filterSearchWidth ?? 140,
        selectionColumnWidth: selectionColumnWidth ?? t.controlHeightSM,
        expandIconSize: expandIconSize ?? t.size,
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
    required this.rowSortedBg,
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
    required this.dragShadow,
    required this.indentSize,
    required this.pinnedShadowColor,
    required this.pinnedShadowExtent,
    required this.headerHoverBg,
    required this.headerMarkActiveColor,
    required this.headerMarkColor,
    required this.headerMarkHoverColor,
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
  final Color rowSortedBg;
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
  final List<BoxShadow> dragShadow;
  final double indentSize;
  final Color pinnedShadowColor;
  final double pinnedShadowExtent;
  final Color headerHoverBg;
  final Color headerMarkActiveColor;
  final Color headerMarkColor;
  final Color headerMarkHoverColor;
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
    this.columnDefaults,
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
    this.sticky,
    this.columnsDraggable = false,
    this.onColumnsReordered,
    this.rowsDraggable = false,
    this.onRowsReordered,
    this.token,
  });

  /// The columns, in the order they are drawn.
  final List<TableColumn<T>> columns;

  /// What every column falls back to where it says nothing itself.
  ///
  /// A house style said once rather than on each column in turn. A column
  /// that names the field wins.
  final TableColumnDefaults? columnDefaults;

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

  /// Which columns the table is sorted by, and which way (controlled).
  ///
  /// A list, since several columns can be in force at once — see
  /// [TableColumn.sortPriority]. Compared in the order they stand here, which
  /// the table keeps in priority order.
  ///
  /// Left null the table keeps its own, starting from [defaultSort]. Give it
  /// a value and the table shows what it is told and nothing else — pair it
  /// with [onSortChanged] or the heading will not answer.
  final List<TableSort>? sort;

  /// What it is sorted by to begin with (uncontrolled).
  final List<TableSort>? defaultSort;

  /// Called when a heading is tapped, with what the sort has become.
  ///
  /// Empty where the rows have gone back to the order they came in.
  final ValueChanged<List<TableSort>>? onSortChanged;

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

  /// Lets a heading be picked up and dropped on another column's place.
  ///
  /// The table does the moving itself and keeps the order it was left in;
  /// [onColumnsReordered] is word of what happened rather than the thing that
  /// makes it happen. A sort and a filter go on naming a column by where it
  /// was listed, so moving one about does not point them at its neighbour.
  final bool columnsDraggable;

  /// Lets a row be picked up and dropped into another row's place.
  ///
  /// As with [columnsDraggable], the table does the moving and keeps the
  /// order it is left in; [onRowsReordered] is word of what happened. The
  /// order it changes is the one the rows came in, so a sort still has the
  /// last word — sorting a table you can also arrange by hand is asking for
  /// two answers to one question.
  ///
  /// Every row is held to one height, as pinning holds them: a row sliding
  /// aside has to know how far, and that is a height.
  final bool rowsDraggable;

  /// Called when a row is dragged into another's place, with where it came
  /// from and where it went to among the rows as they were given.
  final void Function(int from, int to)? onRowsReordered;

  /// Called when a heading is dragged into another column's place.
  ///
  /// Given the places a column came from and went to, counting among
  /// [columns]. The move has already been made — this is for whatever else
  /// you want to do about it.
  ///
  final void Function(int from, int to)? onColumnsReordered;

  /// Keeps the heading in view while the page scrolls past the table.
  ///
  /// Null — the usual — is a heading that goes with its rows. A table with a
  /// `scroll.y` of its own keeps its heading already, so this is for the
  /// other kind: rows that are part of the page.
  final TableSticky? sticky;

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
  /// The stretch of rows the pointer is on: one row for an ordinary cell,
  /// and every row a merged one covers.
  ///
  /// A stretch rather than a row, because what lights up is decided by the
  /// *cell* under the pointer and not by the row it happens to sit in. Point
  /// at a merged cell and everything it covers lights; point at a row beside
  /// it and only that row lights, along with the merged cell standing over
  /// it — which is on that row too.
  final ValueNotifier<({int from, int to})?> _hovered =
      ValueNotifier<({int from, int to})?>(null);

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
            // A content width leaves the columns to their own devices; a
            // named one has them share what was named.
            _ when widget.scroll?.isToContent ?? false =>
              const IntrinsicColumnWidth(),
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
        // A tree carries its mark in the first column, so there is no column
        // of chevrons to add.
        if (!_isTree && (widget.expandable?.showColumn ?? false)) _expandColumn,
        // Drawn in the order a drag has left them, which is not the order
        // they are named in: [_leaves] keeps that, so a sort and a filter go
        // on meaning the column they were given.
        ..._inOwnOrder.expand((c) => c.leaves),
      ];

  /// The columns as given, with the box and chevron columns in front: the
  /// heading is drawn from this, since a group only exists here.
  List<TableColumn<T>> get _columnTree => [
        if (widget.selection != null) _selectionColumn,
        if (!_isTree && (widget.expandable?.showColumn ?? false)) _expandColumn,
        ..._inOwnOrder,
      ];

  /// The order the columns are *drawn* in, which a drag can change.
  ///
  /// Only the drawing. A sort and a filter go on naming a column by where it
  /// was listed, so moving one about does not silently point them at its
  /// neighbour.
  List<int>? _ownColumnOrder;

  /// How many columns the table put in front of the ones it was given.
  int get _serviceColumns =>
      (widget.selection != null ? 1 : 0) +
      ((widget.expandable?.showColumn ?? false) ? 1 : 0);

  /// Where a heading was picked up from, and where it is hovering now — both
  /// counting among [Table.columns], and both null while nothing is carried.
  ///
  /// The columns are drawn as though the drop had already happened, so the
  /// neighbours move aside and the place the carried one is going is the
  /// place it is already standing in. A mark on a neighbour can only say
  /// *which* column; moving them says it outright.
  int? _dragFrom;
  int? _dragOver;

  /// Marks the heading so the finger's position can be read against it. Kept
  /// here rather than made in `build`: a key made afresh every time is a new
  /// key every time, and points at nothing that lasts.
  final GlobalKey _headingAnchor = GlobalKey();

  /// The rows' own order, as places among the ones given, and the drag that
  /// is changing it.
  List<int>? _ownRowOrder;
  int? _dragRowFrom;
  int? _dragRowOver;
  final GlobalKey _bodyAnchor = GlobalKey();

  List<int> get _rowOrder => [
        if (_ownRowOrder?.length == widget.data.length)
          ..._ownRowOrder!
        else
          for (var i = 0; i < widget.data.length; i++) i,
      ];

  /// The rows as they stand before anything is narrowed or sorted: the order
  /// they came in, as a drag has left it.
  List<T> get _given => widget.rowsDraggable || _ownRowOrder != null
      ? [for (final i in _rowOrder) widget.data[i]]
      : widget.data;

  /// Moves a row and tells whoever asked.
  void _moveRow(int from, int to) {
    final order = _rowOrder;
    if (from == to ||
        from < 0 ||
        from >= order.length ||
        to < 0 ||
        to >= order.length) {
      _endRowDrag();
      return;
    }
    setState(() {
      final moved = order.removeAt(from);
      order.insert(to, moved);
      _ownRowOrder = order;
      _orderRevision++;
      _dragRowFrom = null;
      _dragRowOver = null;
    });
    widget.onRowsReordered?.call(from, to);
  }

  void _endRowDrag() {
    if (_dragRowFrom == null && _dragRowOver == null) return;
    setState(() {
      _dragRowFrom = null;
      _dragRowOver = null;
    });
  }

  /// How far each row has slid out of the way while one is being carried.
  List<double> _rowShifts(int count, double height) {
    final shifts = List<double>.filled(count, 0);
    final from = _dragRowFrom;
    final to = _dragRowOver;
    if (from == null || to == null || from == to) return shifts;
    if (from >= count || to >= count) return shifts;

    if (to > from) {
      for (var i = from + 1; i <= to; i++) {
        shifts[i] = -height;
      }
      shifts[from] = height * (to - from);
    } else {
      for (var i = to; i < from; i++) {
        shifts[i] = height;
      }
      shifts[from] = -height * (from - to);
    }
    return shifts;
  }

  /// Bumped whenever the order is committed.
  ///
  /// It goes into the key of every sliding cell, so the drop hands each one a
  /// fresh element that starts at nought instead of an old one carrying the
  /// offset it had. Kept as they were, the cells animated *again* on the
  /// drop — arriving from opposite sides at places they were already in.
  int _orderRevision = 0;

  /// The order the columns are drawn in, as a list of places among the ones
  /// given.
  List<int> get _order => [
        if (_ownColumnOrder?.length == _asGiven.length)
          ..._ownColumnOrder!
        else
          for (var i = 0; i < _asGiven.length; i++) i,
      ];

  /// The columns as given, with the table's own answers filled in where one
  /// stayed quiet — and worked out once a build rather than at each reading,
  /// since a column is compared by identity all over the table.
  List<TableColumn<T>> get _asGiven {
    final defaults = widget.columnDefaults;
    if (defaults == null) return widget.columns;
    if (_defaultedFrom == widget.columns && _defaultedBy == defaults) {
      return _defaulted!;
    }
    _defaultedFrom = widget.columns;
    _defaultedBy = defaults;
    return _defaulted = widget.columns
        .map((c) => c._withDefaults(defaults))
        .toList(growable: false);
  }

  List<TableColumn<T>>? _defaulted;
  List<TableColumn<T>>? _defaultedFrom;
  TableColumnDefaults? _defaultedBy;

  List<TableColumn<T>> get _inOwnOrder => [for (final i in _order) _asGiven[i]];

  /// A cell carried along by a drag, sliding rather than jumping.
  ///
  /// The layout does not change while a heading is being carried — only what
  /// is painted moves — so when the drop commits the order the offsets fall
  /// to nought against a layout that already matches, and nothing jumps.
  /// [slot] names this cell among all of them — a `Table` flattens its rows
  /// before checking, so two cells cannot share a key even in different rows.
  Widget _slid(Widget cell, double by, String slot, Token t) =>
      TweenAnimationBuilder<double>(
        // Keyed by the order it belongs to as well as the place: a committed
        // order is a new element, which starts where it is meant to be rather
        // than travelling there.
        key: ValueKey<String>('$_orderRevision:$slot'),
        tween: Tween<double>(end: by),
        duration: t.motionDurationMid,
        curve: t.motionEaseInOut,
        builder: (context, at, child) => Transform.translate(
          // The shifts are reckoned from the leading edge, as the columns
          // are; which way that is on the screen the page decides.
          offset: Offset(
            Directionality.of(context) == TextDirection.rtl ? -at : at,
            0,
          ),
          child: child,
        ),
        child: cell,
      );

  /// How far each column has slid out of the way, in pixels, while a heading
  /// is being carried.
  ///
  /// Counted over the columns as they are drawn, service columns included, so
  /// the answer can be handed straight to a cell. Reordering the layout under
  /// the hand would work too, but it jumps; sliding is the same information
  /// arriving at a speed the eye can follow.
  List<double> _columnShifts(List<double> widths) {
    final shifts = List<double>.filled(widths.length, 0);
    final from = _dragFrom;
    final to = _dragOver;
    if (from == null || to == null || from == to) return shifts;

    final service = _serviceColumns;
    final held = service + from;
    final onto = service + to;
    if (held >= widths.length || onto >= widths.length) return shifts;

    // The carried column goes the whole way; everything it steps over closes
    // the gap it left, by exactly its width.
    var travelled = 0.0;
    if (onto > held) {
      for (var i = held + 1; i <= onto; i++) {
        shifts[i] = -widths[held];
        travelled += widths[i];
      }
    } else {
      for (var i = onto; i < held; i++) {
        shifts[i] = widths[held];
        travelled -= widths[i];
      }
    }
    shifts[held] = travelled;
    return shifts;
  }

  /// Where a column stands to the eye while a heading is being carried.
  ///
  /// The layout keeps the order it has and only the painting moves, so the
  /// place a column is drawn at and the place it appears to hold come apart
  /// mid-drag. Anything that belongs *between* two columns — the rule — has
  /// to go by the second of these, or the column that happens to be last in
  /// the layout drops its rule while standing in the middle.
  int _visualColumn(int place) {
    final from = _dragFrom;
    final to = _dragOver;
    if (from == null || to == null || from == to) return place;
    final service = _serviceColumns;
    final held = service + from;
    final onto = service + to;
    if (place == held) return onto;
    if (held < onto && place > held && place <= onto) return place - 1;
    if (onto < held && place >= onto && place < held) return place + 1;
    return place;
  }

  /// Moves a column and tells whoever asked.
  ///
  /// The table does the moving: a caller made to do it would have to keep an
  /// order of its own, and that order would disagree with the table's the
  /// moment a column was added. The callback is left as word of what happened.
  void _moveColumn(int from, int to) {
    final order = _order;
    if (from == to ||
        from < 0 ||
        from >= order.length ||
        to < 0 ||
        to >= order.length) {
      setState(() {
        _dragFrom = null;
        _dragOver = null;
      });
      return;
    }
    setState(() {
      final moved = order.removeAt(from);
      order.insert(to, moved);
      _ownColumnOrder = order;
      _orderRevision++;
      _dragFrom = null;
      _dragOver = null;
      // The heading the hand left is no longer under it.
      _hoveredHeading.value = null;
    });
    widget.onColumnsReordered?.call(from, to);
  }

  /// The columns that hold cells: the ones given, with any group replaced by
  /// what stands under it.
  ///
  /// A sort and a filter are keyed by a column's place among these, since a
  /// group has nothing to sort or narrow.
  List<TableColumn<T>> get _leaves => _asGiven.expand((c) => c.leaves).toList();

  /// Whether a lazy body can carry the panels as well as the rows.
  ///
  /// It can once the panel's height is named: a row is then found by counting
  /// how many ordinary rows and how many panels stand before it, which is a
  /// count and not a measurement.
  bool get _panelsFit =>
      widget.expandable == null || widget.expandable!.panelHeight != null;

  /// The body of a lazy table, row by row: either one of the rows given, or
  /// the panel belonging to the row before it.
  ///
  /// Kept as a list because the viewport asks by place, and a place has to
  /// say which of the two it is.
  List<({int row, bool panel})> get _lazyRun {
    final rows = _rows;
    final expandable = widget.expandable;
    if (expandable == null || expandable.panelHeight == null) {
      return [for (var i = 0; i < rows.length; i++) (row: i, panel: false)];
    }
    return [
      for (var i = 0; i < rows.length; i++) ...[
        (row: i, panel: false),
        if (_isExpanded(rows[i]) && _canExpand(rows[i])) (row: i, panel: true),
      ],
    ];
  }

  /// Where every body cell starts, and how much of the grid it covers.
  ///
  /// One entry per row, from the column a cell starts in to what it takes.
  /// A place absent from its row's entry is covered by something above or
  /// beside it, and nothing is built for it.
  ///
  /// Worked out for every row at once and kept, rather than for the rows on
  /// screen: asking a column what it spans is a function call, and a cell is
  /// a widget — the lazy body is about not building the widgets, and the
  /// answer has to be exact or a cell reaching in from above the screen would
  /// be missed.
  List<Map<int, ({int across, int down})>>? _bodySpans;
  Object? _bodySpansFor;
  int _deepestSpan = 1;

  List<Map<int, ({int across, int down})>> _spansOfBody(
    List<TableColumn<T>> columns,
  ) {
    final rows = _rows;
    final asked = Object.hash(
      identityHashCode(rows),
      columns.length,
      _orderRevision,
    );
    final kept = _bodySpans;
    if (kept != null && _bodySpansFor == asked) return kept;

    final plan = [
      for (var i = 0; i < rows.length; i++) <int, ({int across, int down})>{},
    ];
    final taken = <int, Set<int>>{};
    var deepest = 1;

    for (var y = 0; y < rows.length; y++) {
      var x = 0;
      while (x < columns.length) {
        if (taken[y]?.contains(x) ?? false) {
          x++;
          continue;
        }
        final asked =
            columns[x].span?.call(context, rows[y], y) ?? const TableCellSpan();
        final across = math.min(asked.columns, columns.length - x);
        final down = math.min(asked.rows, rows.length - y);
        if (down > deepest) deepest = down;
        for (var dy = 0; dy < down; dy++) {
          for (var dx = 0; dx < across; dx++) {
            if (dy == 0 && dx == 0) continue;
            (taken[y + dy] ??= {}).add(x + dx);
          }
        }
        plan[y][x] = (across: across, down: down);
        x += across;
      }
    }

    _deepestSpan = deepest;
    _bodySpansFor = asked;
    return _bodySpans = plan;
  }

  /// Where every heading cell stands, and how much of the grid it covers.
  ///
  /// A group's title reaches across the columns under it; a column heading
  /// nothing reaches down the whole depth beside it. Worked out here, where
  /// the tree of columns is, and handed to the viewport, which only lays out
  /// what it is told.
  List<({int x, int y, int across, int down, TableColumn<T> column})>
      _headingPlan(int depth) {
    final plan =
        <({int x, int y, int across, int down, TableColumn<T> column})>[];
    var at = 0;

    void walk(List<TableColumn<T>> of, int level) {
      for (final column in of) {
        if (column.isGroup) {
          plan.add((
            x: at,
            y: level,
            across: column.headingSpan,
            down: 1,
            column: column,
          ));
          walk(column.children!, level + 1);
        } else {
          // Nothing under it, so it stands the rest of the way down.
          plan.add((
            x: at,
            y: level,
            across: 1,
            down: depth - level,
            column: column,
          ));
          at += 1;
        }
      }
    }

    walk(_columnTree, 0);
    return plan;
  }

  /// How deep the heading stands.
  int get _headingDepth => _columnTree.map((c) => c.depth).reduce(math.max);

  /// Whether any column heads others, so the heading needs more than one row.
  bool get _hasGroups => _asGiven.any((c) => c.isGroup);

  /// Whether any column adds something up, so there is a row to draw for it.
  bool get _hasSummary => _leaves.any((c) => c.summary != null);

  /// Whether any cell covers its neighbours, so the body is drawn row by row
  /// rather than as a grid.
  bool get _hasSpans => _leaves.any((c) => c.span != null);

  /// Whether the heading is held in view while the page scrolls past.
  ///
  /// Not where the rows scroll inside a height of their own: there the
  /// heading already stays where it is, and holding it again would only take
  /// it away from its own rows.
  bool get _isSticky => widget.sticky != null && !_detached && _showHeader;

  /// How tall the heading stands, where that has to be known before it is
  /// laid out.
  ///
  /// A held heading needs its height in advance — the space it leaves behind
  /// has to be reserved before it is drawn over the rows — so a sticky table
  /// holds its heading to one row's height per level, as a lazy body holds
  /// its rows.
  double _headingHeight(_ResolvedTableToken r, Token t) {
    final deep = _hasGroups ? _asGiven.map((c) => c.depth).reduce(math.max) : 1;
    return _lazyRowHeight(r, t) * deep;
  }

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
      _asGiven.any((c) => c.fixed != null) || widget.selection?.fixed != null;

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
  double? _exactHeight(Token t) =>
      _hasPinned || widget.rowsDraggable ? _rowHeight(t) : null;

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
    // Filled in by the branch that measures the columns, and empty
    // everywhere else — a cell asks for its own place and gets nought where
    // nothing is being carried.
    var shifts = const <double>[];
    double shiftAt(int place) =>
        place >= 0 && place < shifts.length ? shifts[place] : 0;
    // Every band draws the rows in the order they are shown, and the title
    // and summary are handed the same order.
    final rows = _rows;

    // A column that can be carried takes its rule with it. The grid draws the
    // rules between its columns itself, at the places the columns stand — and
    // the cells slide over them, so a carried column left its rule behind and
    // the gap it opened had none. Hung on the cell instead, the rule travels
    // with what it divides. Only where a drag can happen: everywhere else the
    // grid's own rules are one line rather than one per cell.
    final ruleRides = _bordered && widget.columnsDraggable;
    // The last column carries no rule, and last is where a column *appears*
    // to stand: mid-drag the layout's last column can be sitting in the
    // middle, and it took its blank edge there with it.
    Widget ruled(Widget cell, int place, int of) => ruleRides
        ? DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: BorderDirectional(
                end: _visualColumn(place) == of - 1 ? BorderSide.none : rule,
              ),
            ),
            child: cell,
          )
        : cell;

    flutter.TableRow headingRow(List<TableColumn<T>> columns) =>
        flutter.TableRow(
          decoration: BoxDecoration(
            color: r.headerBg,
            border: Border(bottom: rule),
          ),
          children: [
            for (var i = 0; i < columns.length; i++)
              _slid(
                ruled(
                  _headingCell(
                    _cell(
                      _heading(columns[i], _leaves.indexOf(columns[i]), r, t),
                      columns[i],
                      columns[i].headerAlign ??
                          columns[i].align ??
                          TableAlign.start,
                      r,
                      t,
                    ),
                    columns[i],
                    _leaves.indexOf(columns[i]),
                    i,
                    r,
                    t,
                  ),
                  i,
                  columns.length,
                ),
                shiftAt(i),
                'h$i',
                t,
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
                for (var x = 0; x < columns.length; x++)
                  _slid(
                    ruled(_rowCell(i, columns[x], r, t), x, columns.length),
                    shiftAt(x),
                    'r${i}c$x',
                    t,
                  ),
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
          border: _bordered && !ruleRides
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
          // Now the widths are known, so a carried heading can be told how
          // far each column has to slide out of its way.
          shifts = _columnShifts(measured.columns);

          final head = _showHeader
              ? _dropOnHeading(
                  _hasGroups
                      ? _groupedHeading(
                          _columnTree, measured.columns, r, t, rule)
                      : grid(columns, [headingRow(columns)], widths: widths),
                  measured.columns,
                )
              : null;
          final children = <Widget>[
            if (head != null && !_isSticky) head,
          ];

          // Keyed by the row it belongs to. Without that, closing the upper
          // of two open panels handed the lower one the upper's element the
          // moment the upper was let go of — and with it an animation that
          // had just finished closing, so the lower one shut and opened again
          // under the hand.
          Widget panelFor(int i) => Expandable(
                key: ValueKey<String>('panel$i'),
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
                      child: widget.expandable!.builder!(context, rows[i], i),
                    ),
                  ),
                ),
              );

          // A tree joins the two: its rows are let in and out one at a time,
          // and a row of a grid cannot grow out of nothing — the grid holds
          // every row to one height. Laid out by hand, each row is its own
          // box and can be revealed like anything else in the kit.
          if (_hasSpans || widget.rowsDraggable || _isTree) {
            // Laid out by hand: a cell reaching across two columns cannot be
            // a cell of the grid, so there is no grid to run. A body with a
            // cell reaching *down* comes back as one placed block, and there
            // is nowhere between its rows to put a panel.
            final laid =
                _spannedRows(columns, measured.columns, rows, r, t, rule);
            if (laid.length == rows.length) {
              final height = _lazyRowHeight(r, t);
              final rowShifts = _rowShifts(rows.length, height);
              final body = <Widget>[];
              for (var i = 0; i < rows.length; i++) {
                body.add(
                  _revealed(
                    _draggableRow(
                      _slidDown(laid[i], rowShifts[i], 'row$i', t),
                      rows[i],
                      i,
                      r,
                      t,
                    ),
                    rows[i],
                  ),
                );
                if (_hasPanel(rows[i])) body.add(panelFor(i));
              }
              children.add(_dropOnBody(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: body,
                ),
                height,
                rows.length,
              ));
            } else {
              for (var i = 0; i < laid.length; i++) {
                children
                    .add(_revealed(laid[i], i < rows.length ? rows[i] : null));
              }
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

          final laidOut = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
          if (head == null || !_isSticky) return laidOut;
          return _Sticky(
            // A ground under it: the heading's own fill is a two per cent
            // wash, and held over the rows it let them be read straight
            // through — the same as a column held at an edge.
            heading: ColoredBox(color: r.pinnedBg, child: head),
            headingHeight: _headingHeight(r, t),
            body: laidOut,
            offset: widget.sticky!.offsetHeader,
          );
        },
      );
    }

    Widget table;
    if ((widget.expandable != null && !(_detached && _panelsFit)) ||
        (_hasGroups && !_detached) ||
        (_hasSummary && !_detached) ||
        (_hasSpans && !_detached) ||
        _isSticky ||
        (widget.columnsDraggable && !_detached) ||
        (widget.rowsDraggable && !_detached)) {
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
        height: widget.scroll!.y! +
            (_showHeader ? _lazyRowHeight(r, t) * _headingDepth : 0) +
            (_hasSummary ? _lazyRowHeight(r, t) : 0),
        child: _dropRowsOnRows(
          _dropOnRows(_handOn(_lazyBody(r, t, rule))),
        ),
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
        // Stretched to the width it is given, except where that width is the
        // columns' own: inside a sideways scroll there is no width to fill,
        // and stretching to it asks the table to be infinitely wide.
        crossAxisAlignment: (widget.scroll?.isToContent ?? false)
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.stretch,
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

    // A named width still goes inside a sideways scroll, which is what gives
    // the table that width to be laid out at. A content width cannot: there
    // is no number to lay out at, and a body that scrolls down would be
    // handed an unbounded width to expand into.
    if (_across != null &&
        !_hasPinned &&
        !(_detached && widget.scroll!.isToContent)) {
      // One scroll view around the heading and the rows together, rather than
      // one each kept in step by hand: laid out side by side inside the same
      // viewport they cannot drift apart, because there is only one offset.
      //
      // Not where a column is pinned, though: there the scrolling belongs to
      // the middle pane alone, and wrapping the lot would carry the pinned
      // ones off with it — which is exactly what it did before this guard.
      body = _across1D(
        // Asked for the columns' own width, the table is simply not given
        // one: inside a scroll view with no width to fill, Flutter's own
        // `Table` gives every column its widest cell, which is the whole of
        // what a content width means.
        widget.scroll!.isToContent
            ? body
            : SizedBox(
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
  List<TableSort>? _ownSort;
  bool _startedSort = false;

  /// The sorts in force, in the order they are compared.
  List<TableSort> get _sorts {
    if (widget.sort != null) return _inPriority(widget.sort!);
    if (!_startedSort) {
      _startedSort = true;
      _ownSort = widget.defaultSort;
    }
    return _inPriority(_ownSort ?? const []);
  }

  /// The same list, most telling column first.
  ///
  /// The order is worked out here rather than trusted from outside: a caller
  /// naming the sorts in any order still has them compared by what the
  /// columns say, so a priority means one thing everywhere.
  List<TableSort> _inPriority(List<TableSort> of) {
    final leaves = _leaves;
    int priorityOf(TableSort sort) =>
        sort.column >= 0 && sort.column < leaves.length
            ? leaves[sort.column].sortPriority ?? 0
            : 0;
    return [...of]..sort((a, b) => priorityOf(b).compareTo(priorityOf(a)));
  }

  /// Which way one column is sorted, or null where it is not.
  TableSortOrder? _orderOf(int column) {
    for (final sort in _sorts) {
      if (sort.column == column) return sort.order;
    }
    return null;
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

  bool _canExpand(T record) {
    final expandable = widget.expandable;
    if (expandable == null) return false;
    // In a tree it is the data that decides: a row with nothing under it has
    // nothing to open, whatever else is said.
    if (_isTree && !_hasChildren(record)) return false;
    return expandable.expandable?.call(record) ?? true;
  }

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
  bool _hasPanel(T record) =>
      !_isTree && (_isExpanded(record) || _closing.contains(record));

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
    void take(T of) {
      if (!_canSelect(of)) return;
      if (!next.contains(of)) next.add(of);
    }

    if (on) {
      take(record);
    } else {
      next.remove(record);
    }

    if (_picksTogether) {
      // What is under it goes with it, however deep and whether or not it is
      // on show: a box on a branch is a shorthand for what is inside.
      for (final under in _descendants(record)) {
        if (on) {
          take(under);
        } else {
          next.remove(under);
        }
      }
      // And every row above it is picked only while all of its own are, so a
      // branch never claims more than it holds.
      final parents = _parents;
      var above = parents[record];
      while (above != null) {
        final under = _descendants(above).where(_canSelect);
        final whole = under.isNotEmpty && under.every(next.contains);
        if (whole && _canSelect(above)) {
          if (!next.contains(above)) next.add(above);
        } else {
          next.remove(above);
        }
        above = parents[above];
      }
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
    final sorts = _sorts;
    final filters = _filters;
    final asked = Object.hash(
      identityHashCode(widget.data),
      Object.hashAll(_rowOrder),
      Object.hashAll(sorts),
      Object.hashAll([
        for (final entry in filters.entries) ...[
          entry.key,
          Object.hashAll(entry.value),
        ],
      ]),
    );
    if (_rowsAsked == asked && _rowsCache != null) return _rowsCache!;

    _rowsAsked = asked;
    return _rowsCache = _sorted(_filtered(_given, filters), sorts);
  }

  /// The rows on show: a page of [_narrowed], or every one of them where the
  /// table is not paged.
  ///
  /// Everything that draws works from this, so a row's index is its place on
  /// the page — and picking, opening and tapping all mean the row the reader
  /// is looking at.
  List<T> get _rows => _grown(_paged);

  List<T> get _paged {
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

  /// Whether the rows are a tree rather than a list.
  bool get _isTree => widget.expandable?.children != null;

  /// The rows on show with the children of every opened row let in after it.
  ///
  /// The tree is flattened rather than nested: a table of trees is the same
  /// table with more rows in it, so everything that reckons by rows — the
  /// lazy body, the hover, a drag — goes on reckoning the same way.
  ///
  /// Narrowing, sorting and paging happen to the rows that were given, before
  /// this: a page is a page of what was handed over, and a child follows its
  /// parent wherever the parent lands.
  List<T> _grown(List<T> rows) {
    if (!_isTree) return rows;
    final children = widget.expandable!.children!;
    final out = <T>[];
    final depths = <T, int>{};
    final settling = <T, bool>{};
    // [showing] is whether this row is on its way in rather than on its way
    // out: a row under a parent being let go of is still drawn, so it has
    // something to shrink away from.
    void walk(List<T> run, int depth, {required bool showing}) {
      for (final record in run) {
        out.add(record);
        depths[record] = depth;
        settling[record] = showing;
        final open = _isExpanded(record);
        if (!open && !_closing.contains(record)) continue;
        final under = children(record);
        if (under == null || under.isEmpty) continue;
        walk(under, depth + 1, showing: showing && open);
      }
    }

    walk(rows, 0, showing: true);
    _depths = depths;
    _settling = settling;
    return out;
  }

  /// Whether each row on show is standing or on its way out, which is what
  /// the reveal around it is told.
  Map<T, bool> _settling = const {};

  /// How deep in the tree each row on show stands, filled in as they are.
  Map<T, int> _depths = const {};

  /// Whether picking a row picks what is under it.
  bool get _picksTogether =>
      _isTree && !(widget.selection?.checkStrictly ?? false);

  /// Every row under this one, however deep — on show or not.
  ///
  /// Over the data as it was given rather than over the rows on show: a
  /// branch that is picked while shut picks what is inside it, or a box would
  /// mean one thing open and another closed.
  List<T> _descendants(T record) {
    final children = widget.expandable?.children;
    if (children == null) return const [];
    final out = <T>[];
    void walk(T of) {
      for (final child in children(of) ?? const <Never>[]) {
        out.add(child);
        walk(child);
      }
    }

    walk(record);
    return out;
  }

  /// Which row each row stands under, worked out from the data as given.
  Map<T, T> get _parents {
    final children = widget.expandable?.children;
    if (children == null) return const {};
    if (_parentsOf == widget.data && _parentsCache != null) {
      return _parentsCache!;
    }
    final out = <T, T>{};
    void walk(List<T> run) {
      for (final record in run) {
        final under = children(record) ?? const [];
        for (final child in under) {
          out[child] = record;
        }
        walk(under);
      }
    }

    walk(widget.data);
    _parentsOf = widget.data;
    return _parentsCache = out;
  }

  Map<T, T>? _parentsCache;
  List<T>? _parentsOf;

  /// Whether some of what is under this row is picked, but not the row.
  bool _isHalfSelected(T record) {
    if (!_picksTogether || _isSelected(record)) return false;
    for (final under in _descendants(record)) {
      if (_isSelected(under)) return true;
    }
    return false;
  }

  /// Whether this row has rows of its own to show.
  bool _hasChildren(T record) {
    final children = widget.expandable?.children;
    if (children == null) return false;
    final under = children(record);
    return under != null && under.isNotEmpty;
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

  /// The rows in the order the sorts ask for, or as they are where none does.
  ///
  /// Each sort in turn, most telling first, and the first that can tell them
  /// apart decides; the index breaks a tie nothing else could, so a sort is
  /// stable however many columns take part.
  List<T> _sorted(List<T> rows, List<TableSort> sorts) {
    final leaves = _leaves;
    final live = [
      for (final sort in sorts)
        if (sort.column >= 0 &&
            sort.column < leaves.length &&
            leaves[sort.column].sorts)
          sort,
    ];
    if (live.isEmpty) return rows;

    // Kept beside the row rather than read inside the comparison: a sort asks
    // for the same value again and again.
    final keyed = [
      for (var i = 0; i < rows.length; i++)
        (
          i,
          rows[i],
          [
            for (final sort in live)
              leaves[sort.column].sorter == null
                  ? leaves[sort.column].value!(rows[i])
                  : null,
          ],
        ),
    ]..sort((a, b) {
        for (var s = 0; s < live.length; s++) {
          final sort = live[s];
          final column = leaves[sort.column];
          final ascending = sort.order == TableSortOrder.ascending;
          final sorter = column.sorter;
          final by = sorter != null
              ? (ascending ? sorter(a.$2, b.$2) : sorter(b.$2, a.$2))
              : _compare(a.$3[s], b.$3[s], ascending: ascending);
          if (by != 0) return by;
        }
        // Dart's sort is not stable past a handful of rows, so the index is
        // what keeps ties in the order they arrived.
        return a.$1.compareTo(b.$1);
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
  ///
  /// A column that names a [TableColumn.sortPriority] joins what is already
  /// in force; one that names none sorts alone and clears the rest, since a
  /// table sorted by a column that has nothing to say about ties is sorted by
  /// that column and no other.
  void _cycleSort(int column) {
    final leaves = _leaves;
    final joins = column < leaves.length && leaves[column].sortPriority != null;
    final was = _sorts;
    final order = _orderOf(column);
    final next = order == null
        ? TableSortOrder.ascending
        : order == TableSortOrder.ascending
            ? TableSortOrder.descending
            : null;

    // Reported in the order they are compared, not in the order they were
    // tapped: what comes back is what is in force, and a priority means one
    // thing everywhere.
    final sorts = _inPriority([
      if (joins)
        for (final sort in was)
          if (sort.column != column) sort,
      if (next != null) TableSort(column, next),
    ]);
    if (widget.sort == null) setState(() => _ownSort = sorts);
    widget.onSortChanged?.call(sorts);
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
    bool sorted = false,
  }) {
    final rows = _rows;
    final picked = widget.selection != null &&
        index >= 0 &&
        index < rows.length &&
        _isSelected(rows[index]);
    // A picked row is picked whatever its columns are up to: the fill says
    // what will happen to the row, and that outranks what a column is doing.
    if (picked) return hovered ? r.rowSelectedHoverBg : r.rowSelectedBg;
    if (hovered) return r.rowHoverBg;
    return sorted ? r.rowSortedBg : const Color(0x00000000);
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
                indeterminate: _isHalfSelected(record),
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
              // Beginning where it already stands, not at shut. A mark built
              // afresh — which is what a row becomes when the panel above it
              // is let go of and the grid closes up — would otherwise draw
              // itself a plus and then open, on a row nobody had touched.
              // A change still animates: the builder carries on from the
              // value it is at, whatever it was told to begin from.
              tween: Tween<double>(
                begin: open ? 1 : 0,
                end: open ? 1 : 0,
              ),
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
        child: _rowCell(y, column, r, t, covering: span.down),
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
              border: BorderDirectional(
                bottom: rule,
                end: !last && _bordered ? rule : BorderSide.none,
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
              // Not draggable: a leaf inside a group cannot be carried out of
              // it, and a group's own title spans several places at once.
              -1,
              r,
              t,
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
                border: BorderDirectional(
                  bottom: rule,
                  end: !last && _bordered ? rule : BorderSide.none,
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
          // The same breath the carets take: a word ending against the mark
          // reads as one thing, and an aligned heading ends right there.
          SizedBox(width: t.sizeXXS),
          _funnel(column, index, r, t),
        ],
      );
    }

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
        // Listening on its own, so a pointer arriving at the heading darkens
        // the marks without rebuilding the cell around them.
        ValueListenableBuilder<int?>(
          valueListenable: _hoveredHeading,
          builder: (context, hovered, _) => _Carets(
            order: _orderOf(index),
            active: r.headerMarkActiveColor,
            idle: hovered == index ? r.headerMarkHoverColor : r.headerMarkColor,
            size: r.sortCaretSize,
            duration: t.motionDurationMid,
          ),
        ),
        // The carets and the funnel are two marks, not one: they take the
        // same breath between them that the word takes before them.
        if (column.filtersRows) ...[
          SizedBox(width: t.sizeXXS),
          _funnel(column, index, r, t),
        ],
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
      // Hung by the trailing edge, not the leading one: the mark stands at
      // the far end of the heading, so aligning the near edges would throw
      // the panel out past its own column. A mirrored layout swaps which edge
      // that is.
      placement: column.filterPanel?.placement ??
          (Directionality.of(context) == TextDirection.rtl
              ? PopoverPlacement.bottomLeft
              : PopoverPlacement.bottomRight),
      content: (context, close) => column.filterPanel != null
          ? _OwnFilterPanel(
              build: column.filterPanel!.builder,
              chosen: _filters[index] ?? const [],
              onApply: (chosen) {
                _applyFilter(index, chosen);
                close();
              },
              onClose: close,
            )
          : _filterMenu(column, index, close, r, t),
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
                  child: column.filterIcon != null
                      ? column.filterIcon!(context, narrowing)
                      : CustomPaint(
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
  /// [named] is where the column was listed among the leaves — what a sort
  /// and a filter mean by it. [place] is where it is drawn, which a drag
  /// moves and which a column of boxes in front shifts along. Keeping them
  /// apart is the whole of what stops one being used for the other.
  Widget _headingCell(
    Widget cell,
    TableColumn<T> column,
    int named,
    int place,
    _ResolvedTableToken r,
    Token t,
  ) {
    if (!column.sorts && !widget.columnsDraggable) return cell;
    if (!column.sorts) return _draggableHeading(cell, place, r, t);
    // A column the table is sorted by keeps the fill, hand or no hand: it is
    // the one doing something, so it is the one marked. Which also means the
    // fill arrives with a `defaultSort`, before anybody has touched it.
    final sorted = _orderOf(named) != null;
    final answering = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _hoveredHeading.value = named,
      onExit: (_) {
        if (_hoveredHeading.value == named) _hoveredHeading.value = null;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _cycleSort(named),
        child: ValueListenableBuilder<int?>(
          valueListenable: _hoveredHeading,
          builder: (context, hovered, child) => ColoredBox(
            color: sorted || hovered == named
                ? r.headerHoverBg
                : const Color(0x00000000),
            child: child,
          ),
          child: cell,
        ),
      ),
    );
    return _draggableHeading(answering, place, r, t);
  }

  /// A heading that can be picked up and dropped on another column's place.
  ///
  /// What is shown while it is carried is a lifted copy of the heading, and
  /// the column it would land on takes the fill a heading takes under the
  /// pointer — the same answer a heading gives to everything else.
  Widget _draggableHeading(
    Widget cell,
    int place,
    _ResolvedTableToken r,
    Token t,
  ) {
    // Counted among the columns given, so the boxes and chevrons in front are
    // neither dragged nor dropped on.
    final index = place - _serviceColumns;
    if (!widget.columnsDraggable || index < 0 || index >= _asGiven.length) {
      return cell;
    }

    // Only picking up lives on the column. Where it would land is worked out
    // from where the finger is, against the layout — which does not move —
    // rather than from whichever cell happens to lie under it: the cells
    // slide, so a target on each of them chased the finger and the two
    // columns swapped back and forth without the hand moving at all.
    return Draggable<int>(
      data: index,
      axis: Axis.horizontal,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => setState(() {
        _dragFrom = index;
        _dragOver = index;
      }),
      onDraggableCanceled: (_, __) => _endDrag(),
      onDragEnd: (_) => _endDrag(),
      // Carried under the finger with a ground of its own — the cell is only
      // as opaque as its fill, which is nothing — and a width of its own,
      // since what it is carried over gives it none and a heading holds an
      // `Expanded`. Lifted a little and tilted, so it reads as picked up
      // rather than pasted over.
      // Carried in the overlay, which knows nothing of the table it came
      // from: without being told, a mirrored row was drawn the other way
      // round the moment it left the page.
      feedback: Directionality(
        textDirection: Directionality.of(context),
        child: Transform.rotate(
          angle: 0.02,
          child: Transform.scale(
            scale: 1.04,
            child: IntrinsicWidth(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: r.pinnedBg,
                  borderRadius: BorderRadius.circular(r.borderRadius),
                  boxShadow: r.dragShadow,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: t.sizeXXS),
                  child: cell,
                ),
              ),
            ),
          ),
        ),
      ),
      // The column it came from stays where it is, faded: a gap opening where
      // it stood would move every other column under the hand.
      childWhenDragging: Opacity(opacity: 0.35, child: cell),
      child: MouseRegion(cursor: SystemMouseCursors.grab, child: cell),
    );
  }

  /// Lets go of whatever was being carried.
  void _endDrag() {
    if (_dragFrom == null && _dragOver == null) return;
    setState(() {
      _dragFrom = null;
      _dragOver = null;
    });
    _hoveredHeading.value = null;
  }

  /// A row carried along by a drag, sliding down or up rather than jumping.
  Widget _slidDown(Widget row, double by, String slot, Token t) =>
      TweenAnimationBuilder<double>(
        key: ValueKey<String>('$_orderRevision:$slot'),
        tween: Tween<double>(end: by),
        duration: t.motionDurationMid,
        curve: t.motionEaseInOut,
        builder: (context, at, child) =>
            Transform.translate(offset: Offset(0, at), child: child),
        child: row,
      );

  /// A row that can be picked up and dropped into another's place.
  ///
  /// Only the picking up lives on the row; where it would land is worked out
  /// from where the finger is, against a body whose layout does not move.
  Widget _draggableRow(
    Widget row,
    T record,
    int index,
    _ResolvedTableToken r,
    Token t,
  ) {
    if (!widget.rowsDraggable) return row;
    return Draggable<int>(
      data: index,
      axis: Axis.vertical,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => setState(() {
        _dragRowFrom = index;
        _dragRowOver = index;
      }),
      onDraggableCanceled: (_, __) => _endRowDrag(),
      onDragEnd: (_) => _endRowDrag(),
      // Carried in the overlay, which knows nothing of the table it came
      // from: without being told, a mirrored row was drawn the other way
      // round the moment it left the page.
      feedback: Directionality(
        textDirection: Directionality.of(context),
        child: Transform.rotate(
          angle: 0.006,
          child: Transform.scale(
            scale: 1.02,
            child: IntrinsicWidth(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: r.pinnedBg,
                  borderRadius: BorderRadius.circular(r.borderRadius),
                  boxShadow: r.dragShadow,
                ),
                child: row,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: row),
      child: MouseRegion(cursor: SystemMouseCursors.grab, child: row),
    );
  }

  /// The body as one place to drop on, read by the finger's height.
  Widget _dropOnBody(Widget body, double rowHeight, int count) {
    if (!widget.rowsDraggable) return body;

    int? rowAt(Offset global) {
      final box = _bodyAnchor.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize || rowHeight <= 0) return null;
      final y = box.globalToLocal(global).dy;
      return (y ~/ rowHeight).clamp(0, count - 1);
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => true,
      onMove: (details) {
        final over = rowAt(details.offset);
        if (over == null || over == _dragRowOver) return;
        setState(() => _dragRowOver = over);
      },
      onAcceptWithDetails: (details) =>
          _moveRow(details.data, _dragRowOver ?? details.data),
      onLeave: (_) {
        if (_dragRowOver == null) return;
        setState(() => _dragRowOver = null);
      },
      builder: (context, _, __) => KeyedSubtree(key: _bodyAnchor, child: body),
    );
  }

  /// The lazy body as one place to drop a heading on.
  ///
  /// Which column is under the finger is asked of the viewport, which laid
  /// the columns out and is the only thing that knows where a held one came
  /// to rest. Asking the cells instead would chase them as they slide.
  Widget _dropOnRows(Widget rows) {
    if (!widget.columnsDraggable) return rows;

    int? placeAt(Offset global) {
      final box = _headingAnchor.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return null;
      final viewport = _viewportOf(box);
      if (viewport == null) return null;
      final at = viewport.columnAtLocal(box.globalToLocal(global).dx);
      return at == null ? null : at - _serviceColumns;
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => true,
      onMove: (details) {
        final over = placeAt(details.offset);
        if (over == null || over < 0 || over == _dragOver) return;
        setState(() => _dragOver = over);
      },
      onAcceptWithDetails: (details) =>
          _moveColumn(details.data, _dragOver ?? details.data),
      onLeave: (_) {
        if (_dragOver == null) return;
        setState(() => _dragOver = null);
      },
      builder: (context, _, __) =>
          KeyedSubtree(key: _headingAnchor, child: rows),
    );
  }

  /// The lazy body as one place to drop a row into.
  Widget _dropRowsOnRows(Widget rows) {
    if (!widget.rowsDraggable) return rows;

    int? rowAt(Offset global) {
      final box = _bodyAnchor.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return null;
      final viewport = _viewportOf(box);
      return viewport?.rowAtLocal(box.globalToLocal(global).dy);
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => true,
      onMove: (details) {
        final over = rowAt(details.offset);
        if (over == null || over == _dragRowOver) return;
        setState(() => _dragRowOver = over);
      },
      onAcceptWithDetails: (details) =>
          _moveRow(details.data, _dragRowOver ?? details.data),
      onLeave: (_) {
        if (_dragRowOver == null) return;
        setState(() => _dragRowOver = null);
      },
      builder: (context, _, __) => KeyedSubtree(key: _bodyAnchor, child: rows),
    );
  }

  /// The viewport under [box], where the columns were laid out.
  _RenderRows? _viewportOf(RenderObject box) {
    _RenderRows? found;
    void look(RenderObject node) {
      if (found != null) return;
      if (node is _RenderRows) {
        found = node;
        return;
      }
      node.visitChildren(look);
    }

    look(box);
    return found;
  }

  /// The heading as one place to drop on, which reads the finger's position
  /// against the columns rather than asking whatever lies under it.
  Widget _dropOnHeading(Widget heading, List<double> widths) {
    if (!widget.columnsDraggable) return heading;

    int? placeAt(Offset global) {
      final box = _headingAnchor.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return null;
      var x = box.globalToLocal(global).dx;
      // Counted from the leading edge, which is the right of the box on a
      // page that reads the other way.
      if (Directionality.of(context) == TextDirection.rtl) {
        x = box.size.width - x;
      }
      for (var i = 0; i < widths.length; i++) {
        x -= widths[i];
        if (x < 0) return i - _serviceColumns;
      }
      return widths.length - 1 - _serviceColumns;
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => true,
      onMove: (details) {
        final over = placeAt(details.offset);
        if (over == null || over < 0 || over == _dragOver) return;
        setState(() => _dragOver = over);
      },
      onAcceptWithDetails: (details) =>
          _moveColumn(details.data, _dragOver ?? details.data),
      // Only what it is over, not what it was picked up from: leaving the
      // table is not letting go of it. Cleared together, a hand that wandered
      // off and came back had nothing left to move the neighbours for.
      onLeave: (_) {
        if (_dragOver == null) return;
        setState(() => _dragOver = null);
      },
      builder: (context, _, __) =>
          KeyedSubtree(key: _headingAnchor, child: heading),
    );
  }

  /// One cell of the lazy body: a heading when it is the top row, a data cell
  /// otherwise.
  Widget? _lazyCell(
    ChildVicinity at,
    List<TableColumn<T>> columns,
    _ResolvedTableToken r,
    Token t,
    BorderSide rule,
  ) {
    final depth = _showHeader ? _headingDepth : 0;
    var covering = 1;
    var spanning = 1;
    final column = columns[at.xIndex];
    final run = _lazyRun;
    final heading = at.yIndex < depth;
    final summary = _hasSummary && at.yIndex == run.length + depth;
    final place = at.yIndex - depth;
    // A panel is one cell across the whole table, so only its leading place
    // holds anything.
    if (!heading &&
        !summary &&
        place >= 0 &&
        place < run.length &&
        run[place].panel) {
      if (at.xIndex != 0) return null;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: r.expandedBg,
          border: Border(bottom: rule),
        ),
        child: Padding(
          padding: _cellPadding(r, t),
          child: widget.expandable!.builder!(
            context,
            _rows[run[place].row],
            run[place].row,
          ),
        ),
      );
    }
    final index = place >= 0 && place < run.length ? run[place].row : place;
    final last = index == _rows.length - 1;

    // A place covered by a cell above or beside it is asked for and given
    // nothing, which is how the grid comes to have the hole that cell fills.
    // Asked before the rules are worked out, since a merged cell's rule
    // stands after the columns it took.
    if (_hasSpans && !heading && !summary && index >= 0) {
      final plan = _spansOfBody(columns);
      if (index < plan.length) {
        final start = plan[index][at.xIndex];
        if (start == null) return null;
        covering = start.down;
        spanning = start.across;
      }
    }

    // Directional, so the rule between two columns falls on the side the
    // next column is on rather than always on the right.
    final border = BorderDirectional(
      bottom: heading || !last ? rule : BorderSide.none,
      // After the columns the cell actually took, not after its own place:
      // a rule through the middle of a merged cell is a rule through a cell.
      end: _bordered && at.xIndex + spanning < columns.length
          ? rule
          : BorderSide.none,
    );

    if (heading) {
      // Only the cell that starts something is built; the places it covers
      // are asked for and given nothing, which is how the grid comes to have
      // the hole a spanning cell fills.
      final plan = _headingPlan(depth).where(
        (cell) => cell.x == at.xIndex && cell.y == at.yIndex,
      );
      if (plan.isEmpty) return null;
      final headed = plan.first.column;
      if (headed.isGroup) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Color.alphaBlend(r.headerBg, r.pinnedBg),
            border: BorderDirectional(
              bottom: rule,
              end: _bordered && at.xIndex + plan.first.across < columns.length
                  ? rule
                  : BorderSide.none,
            ),
          ),
          child: _cell(
            DefaultTextStyle.merge(
              style: TextStyle(
                color: r.headerColor,
                fontWeight: t.fontWeightStrong,
              ),
              child: headed.title ?? const SizedBox.shrink(),
            ),
            headed,
            headed.headerAlign ?? TableAlign.center,
            r,
            t,
          ),
        );
      }
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
            // Named by where it was listed, not by where it is drawn: a
            // column of boxes in front shifts every place along by one, and
            // a sort keyed by the place named the column beside it.
            _heading(column, _leaves.indexOf(column), r, t),
            column,
            column.headerAlign ?? column.align ?? TableAlign.start,
            r,
            t,
          ),
          column,
          _leaves.indexOf(column),
          at.xIndex,
          r,
          t,
        ),
      );
    }

    if (summary) {
      return DecoratedBox(
        decoration: BoxDecoration(
          // Opaque, and its own rule above it: the rows run under it, and a
          // row is only as opaque as its fill.
          color: column.fixed == null
              ? r.summaryBg
              : Color.alphaBlend(r.summaryBg, r.pinnedBg),
          border: BorderDirectional(
            top: rule,
            end: _bordered && at.xIndex != columns.length - 1
                ? rule
                : BorderSide.none,
          ),
        ),
        child: _padded(
          column.summary?.call(context, _rows) ?? const SizedBox.shrink(),
          column,
          column.align ?? TableAlign.start,
          r,
          t,
        ),
      );
    }

    final record = _rows[index];

    /// What is painted behind this cell: the row's own fill, and under it the
    /// ground a held column stands on.
    ///
    /// Composed rather than stacked. The ground used to be painted inside the
    /// cell and the row's fill outside it, so the opaque ground covered the
    /// fill and a held column neither lit up under the pointer nor showed
    /// that its row was picked.
    Color ground(Color fill) =>
        column.fixed == null ? fill : Color.alphaBlend(fill, r.pinnedBg);

    Widget cell = DecoratedBox(
      decoration: BoxDecoration(border: border),
      child: _padded(
        column.builder?.call(context, record, index) ?? _text(column, record),
        column,
        column.align ?? TableAlign.start,
        r,
        t,
      ),
    );
    if (widget.rowsDraggable) {
      // Picked up by any of its cells: a lazy body has no row of its own to
      // take hold of, only the cells standing in it.
      cell = Draggable<int>(
        data: index,
        axis: Axis.vertical,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () => setState(() {
          _dragRowFrom = index;
          _dragRowOver = index;
        }),
        onDraggableCanceled: (_, __) => _endRowDrag(),
        onDragEnd: (_) => _endRowDrag(),
        feedback: const SizedBox.shrink(),
        childWhenDragging: Opacity(opacity: 0.35, child: cell),
        child: MouseRegion(cursor: SystemMouseCursors.grab, child: cell),
      );
    }
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
    if (!_hoverable) {
      return ColoredBox(
        color: ground(_rowFill(index, hovered: false, r: r)),
        child: cell,
      );
    }
    return MouseRegion(
      onEnter: (_) => _hovered.value = (from: index, to: index + covering),
      onExit: (_) {
        if (_hovered.value?.from == index) _hovered.value = null;
      },
      child: ValueListenableBuilder<({int from, int to})?>(
        valueListenable: _hovered,
        builder: (context, hovered, child) => ColoredBox(
          color: ground(
            _rowFill(
              index,
              hovered: hovered != null &&
                  hovered.from < index + covering &&
                  index < hovered.to,
              r: r,
            ),
          ),
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
    // Rows and panels together, in the order they are drawn: the viewport
    // asks by place, and a place has to say which of the two it is.
    final run = _lazyRun;
    final columns = _ordered;
    final style = _bodyStyle(r, t);
    final inline = _cellPadding(r, t).horizontal;
    final scaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // A width of `infinity` is the ask for the columns' own: `resolve`
        // shares slack only when the room is finite, so an infinite room is
        // exactly a table that takes what it needs and no more.
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
            headerRows: _showHeader ? _headingDepth : 0,
            headerPlan: _showHeader
                ? [
                    for (final cell in _headingPlan(_headingDepth))
                      (
                        x: cell.x,
                        y: cell.y,
                        across: cell.across,
                        down: cell.down,
                      ),
                  ]
                : const [],
            shifts: _columnShifts(widths.columns),
            rowShifts: _rowShifts(_rows.length, _lazyRowHeight(r, t)),
            panelRows: [
              for (var i = 0; i < run.length; i++)
                if (run[i].panel) i,
            ],
            panelHeight: widget.expandable?.panelHeight ?? 0,
            bodySpans: _hasSpans ? _spansOfBody(columns) : const [],
            deepestSpan: _deepestSpan,
            // The row that adds up is held at the foot as the heading is held
            // at the head: one row, out of the run that scrolls.
            footerRows: _hasSummary ? 1 : 0,
            pinning: [for (final c in columns) c.fixed],
            shadeColor: r.pinnedShadowColor,
            shadeExtent: r.pinnedShadowExtent,
            verticalDetails: const ScrollableDetails.vertical(),
            // Leading is the right in a mirrored page, so the rows run the
            // other way and a finger moving right takes the table forwards.
            horizontalDetails: ScrollableDetails.horizontal(
              reverse: Directionality.of(context) == TextDirection.rtl,
            ),
            delegate: TwoDimensionalChildBuilderDelegate(
              // Nothing in a cell wants keeping alive, and the default wraps
              // every one of them in an AutomaticKeepAlive and a selection
              // listener — two elements and two notifications a cell, for a
              // state no cell has.
              addAutomaticKeepAlives: false,
              maxXIndex: columns.length - 1,
              maxYIndex: run.length -
                  1 +
                  (_showHeader ? _headingDepth : 0) +
                  (_hasSummary ? 1 : 0),
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
  /// [covering] is how many rows this cell stands over — more than one where
  /// it spans downwards. A merged cell belongs to every row it covers, so it
  /// lights up for any of them: lit for its first row alone, the rest of the
  /// line went dark under the pointer while the merged cell stayed pale.
  Widget _rowCell(
    int index,
    TableColumn<T> column,
    _ResolvedTableToken r,
    Token t, {
    int covering = 1,
  }) {
    final record = _rows[index];
    var content =
        column.builder?.call(context, record, index) ?? _text(column, record);
    // In a tree the first column carries the row's place: how far in it
    // starts, and the mark that opens it. Before the cell's padding, so the
    // indent is measured from where the words would have begun.
    if (_isTree && identical(column, _leaves.first)) {
      content = _treeMark(record, content, r, t);
    }
    Widget cell = _cell(
      content,
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
    // A column the table is sorted by is marked down its whole length, not
    // only at its head: the heading says which column is doing something and
    // the fill says how far that reaches.
    final sorted = _orderOf(_leaves.indexOf(column)) != null;
    if (!_hoverable) {
      return sorted ? ColoredBox(color: r.rowSortedBg, child: cell) : cell;
    }
    return MouseRegion(
      onEnter: (_) => _hovered.value = (from: index, to: index + covering),
      onExit: (_) {
        if (_hovered.value?.from == index) _hovered.value = null;
      },
      // Only this row's cells are listening, so a pointer crossing the table
      // rebuilds two rows rather than all of them.
      child: ValueListenableBuilder<({int from, int to})?>(
        valueListenable: _hovered,
        builder: (context, hovered, child) => ColoredBox(
          color: _rowFill(
            index,
            hovered: hovered != null &&
                hovered.from < index + covering &&
                index < hovered.to,
            sorted: sorted,
            r: r,
          ),
          child: child,
        ),
        child: cell,
      ),
    );
  }

  /// A row of a tree, wrapped in the reveal that lets it in and out.
  ///
  /// Only the rows that arrive and leave: a top-level row is always there, so
  /// wrapping it would put a second layout box round every row of every tree
  /// for nothing.
  Widget _revealed(Widget row, T? record) {
    if (!_isTree || record == null) return row;
    if ((_depths[record] ?? 0) == 0) return row;
    return Expandable(
      // Keyed by the row, so a row let in beside another does not inherit
      // the other's reveal and arrive already open.
      key: ObjectKey(record),
      expanded: _settling[record] ?? true,
      destroyWhenCollapsed: true,
      // It is added at the moment its parent opens, so it has to start shut
      // and grow — otherwise it arrives at full height with no reveal.
      animateOnMount: true,
      child: row,
    );
  }

  /// A row of a tree, indented by how deep it stands and led by its mark.
  ///
  /// A row with nothing under it keeps the space the mark would have taken,
  /// so the words of a childless row line up with the words of its siblings
  /// rather than sliding back under their marks.
  Widget _treeMark(
    T record,
    Widget content,
    _ResolvedTableToken r,
    Token t,
  ) {
    final expandable = widget.expandable!;
    final depth = _depths[record] ?? 0;
    final indent = expandable.indentSize ?? r.indentSize;
    final open = _isExpanded(record);
    final has = _hasChildren(record) && _canExpand(record);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (depth > 0) SizedBox(width: indent * depth),
        SizedBox(
          width: r.expandIconSize,
          child: has
              ? MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _toggleExpanded(record),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: open ? 1 : 0,
                        end: open ? 1 : 0,
                      ),
                      duration: t.motionDurationMid,
                      curve: t.motionEaseInOut,
                      builder: (context, shut, _) => CustomPaint(
                        size: Size.square(r.expandIconSize),
                        painter: _ExpandIconPainter(
                          bar: r.headerColor,
                          border: r.borderColor,
                          radius: t.borderRadiusSM,
                          open: shut,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        SizedBox(width: t.sizeXS),
        Flexible(child: content),
      ],
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
    required this.duration,
  });

  final TableSortOrder? order;
  final Color active;
  final Color idle;

  /// How long the idle colour takes to change, which is the only thing that
  /// changes: the one in force is in force either way.
  final Duration duration;

  /// How tall the pair stands, all told — the mark's own size, as the
  /// reference sets a font size on the two glyphs rather than a size on each
  /// triangle. The carets are worked out from it, so one number moves both.
  final double size;

  double get _caret => size * 0.4;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: idle),
        duration: duration,
        builder: (context, shade, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: Size(size * 0.62, _caret),
              painter: _CaretPainter(
                order == TableSortOrder.ascending ? active : shade ?? idle,
                up: true,
              ),
            ),
            SizedBox(height: size * 0.16),
            CustomPaint(
              size: Size(size * 0.62, _caret),
              painter: _CaretPainter(
                order == TableSortOrder.descending ? active : shade ?? idle,
                up: false,
              ),
            ),
          ],
        ),
      );
}

/// A filter panel of the caller's own, with the working answer kept for it.
///
/// The panel is theirs to draw; what is chosen has to outlive their rebuilds,
/// and a widget of its own is where that lives — as with the menu, a
/// `StatefulBuilder` closing over a local would lose it the moment the
/// overlay above rebuilt.
class _OwnFilterPanel extends StatefulWidget {
  const _OwnFilterPanel({
    required this.build,
    required this.chosen,
    required this.onApply,
    required this.onClose,
  });

  final Widget Function(BuildContext context, TableFilterControls panel) build;
  final List<Object?> chosen;
  final ValueChanged<List<Object?>> onApply;
  final VoidCallback onClose;

  @override
  State<_OwnFilterPanel> createState() => _OwnFilterPanelState();
}

class _OwnFilterPanelState extends State<_OwnFilterPanel> {
  late List<Object?> _chosen = [...widget.chosen];

  @override
  Widget build(BuildContext context) => DropdownPanel(
        child: IntrinsicWidth(
          child: widget.build(
            context,
            TableFilterControls(
              chosen: _chosen,
              choose: (next) => setState(() => _chosen = [...next]),
              apply: () => widget.onApply(_chosen),
              clear: () => widget.onApply(const []),
              close: widget.onClose,
            ),
          ),
        ),
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
/// Holds a table's heading in view while the page scrolls past it.
///
/// The heading keeps its place in the layout — it is only *drawn* lower down,
/// so nothing moves and no space is taken twice. Which is also why it is
/// drawn last, over the rows: a heading translated within a column would be
/// painted before them and disappear underneath.
class _Sticky extends StatefulWidget {
  const _Sticky({
    required this.heading,
    required this.headingHeight,
    required this.body,
    required this.offset,
  });

  final Widget heading;
  final double headingHeight;
  final Widget body;
  final double offset;

  @override
  State<_Sticky> createState() => _StickyState();
}

class _StickyState extends State<_Sticky> {
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next == _position) return;
    _position?.removeListener(_onScroll);
    _position = next?..addListener(_onScroll);
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  /// How far the heading has to come down to stay in view.
  ///
  /// Nought while the table's top is still on screen, then the distance it
  /// has gone above — and never so far that the heading leaves the rows it
  /// belongs to.
  double get _shift {
    final position = _position;
    final box = context.findRenderObject();
    if (position == null || box is! RenderBox || !box.hasSize) return 0;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return 0;
    final reveal = viewport.getOffsetToReveal(box, 0).offset;
    final past = position.pixels - reveal + widget.offset;
    return past.clamp(
        0.0, math.max(0.0, box.size.height - widget.headingHeight));
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The heading's place, kept empty: the heading itself is drawn
              // over everything below.
              SizedBox(height: widget.headingHeight),
              widget.body,
            ],
          ),
          Transform.translate(
            offset: Offset(0, _shift),
            child:
                SizedBox(height: widget.headingHeight, child: widget.heading),
          ),
        ],
      );
}

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
    required this.headerPlan,
    required this.shifts,
    required this.rowShifts,
    required this.bodySpans,
    required this.deepestSpan,
    required this.panelRows,
    required this.panelHeight,
    required this.footerRows,
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

  /// Where every heading cell stands and how much it covers.
  final List<({int x, int y, int across, int down})> headerPlan;

  /// How far each column is slid aside while a heading is carried.
  final List<double> shifts;

  /// And how far each row is, while a row is carried.
  final List<double> rowShifts;

  /// Where every body cell starts and how much it covers.
  final List<Map<int, ({int across, int down})>> bodySpans;

  /// How far the deepest of them reaches, which is how far back the walk
  /// has to begin to catch one reaching in from above the screen.
  final int deepestSpan;

  /// Which body rows are panels rather than rows, and how tall one stands.
  final List<int> panelRows;
  final double panelHeight;

  /// How many rows are held at the foot — the row that adds up, or none.
  final int footerRows;

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
        headerPlan: headerPlan,
        shifts: shifts,
        rowShifts: rowShifts,
        bodySpans: bodySpans,
        deepestSpan: deepestSpan,
        panelRows: panelRows,
        panelHeight: panelHeight,
        footerRows: footerRows,
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
    required this.headerPlan,
    required this.shifts,
    required this.rowShifts,
    required this.bodySpans,
    required this.deepestSpan,
    required this.panelRows,
    required this.panelHeight,
    required this.footerRows,
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

  /// How many rows are held at the foot — the row that adds up, or none.
  final int footerRows;

  /// Which columns are held at an edge, in the order they are drawn.
  final List<({int x, int y, int across, int down})> headerPlan;

  /// How far each column is slid aside while a heading is carried.
  final List<double> shifts;

  /// And how far each row is, while a row is carried.
  final List<double> rowShifts;

  /// Where every body cell starts and how much it covers.
  final List<Map<int, ({int across, int down})>> bodySpans;

  /// How far the deepest of them reaches, which is how far back the walk
  /// has to begin to catch one reaching in from above the screen.
  final int deepestSpan;

  /// Which body rows are panels rather than rows, and how tall one stands.
  final List<int> panelRows;
  final double panelHeight;
  final List<TableColumnFixed?> pinning;
  final Color shadeColor;
  final double shadeExtent;

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) =>
      _RenderRows(
        widths: widths,
        rowHeight: rowHeight,
        headerRows: headerRows,
        headerPlan: headerPlan,
        shifts: shifts,
        rowShifts: rowShifts,
        bodySpans: bodySpans,
        deepestSpan: deepestSpan,
        panelRows: panelRows,
        panelHeight: panelHeight,
        footerRows: footerRows,
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
      ..headerPlan = headerPlan
      ..shifts = shifts
      ..rowShifts = rowShifts
      ..setBodySpans(bodySpans, deepestSpan)
      ..setPanels(panelRows, panelHeight)
      ..footerRows = footerRows
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
    required List<({int x, int y, int across, int down})> headerPlan,
    required List<double> shifts,
    required List<double> rowShifts,
    required List<Map<int, ({int across, int down})>> bodySpans,
    required int deepestSpan,
    required List<int> panelRows,
    required double panelHeight,
    required int footerRows,
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
        _headerPlan = headerPlan,
        _shifts = shifts,
        _rowShifts = rowShifts,
        _bodySpans = bodySpans,
        _deepestSpan = deepestSpan,
        _panelRows = panelRows,
        _panelHeight = panelHeight,
        _footerRows = footerRows,
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

  int _footerRows;
  set footerRows(int value) {
    if (_footerRows == value) return;
    _footerRows = value;
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
  double _footerHeight = 0;

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

  void _place(
    int column,
    int row,
    double dx,
    double dy, {
    int across = 1,
    int down = 1,
    double? height,
  }) {
    final child = buildOrObtainChildFor(
      ChildVicinity(xIndex: column, yIndex: row),
    );
    if (child == null) return;
    var width = 0.0;
    for (var i = 0; i < across && column + i < _columnCount; i++) {
      width += _widths[column + i];
    }
    child.layout(
      BoxConstraints.tightFor(
        width: width,
        height: height ?? _rowHeight * down,
      ),
    );
    parentDataOf(child).layoutOffset = Offset(dx, dy);
  }

  /// Whether the page reads the other way, which the horizontal axis says.
  ///
  /// The whole layout is worked out from the leading edge — column nought at
  /// nought, the scroll carrying it away — and mirrored on the way out, in
  /// the two places that turn that reckoning into pixels: where a cell is put
  /// and where a held column's shade is drawn. Reckoning it twice, once each
  /// way round, would be two of everything to keep in step.
  bool get _mirrored => horizontalAxisDirection == AxisDirection.left;

  /// A span of [width] starting at [dx] from the leading edge, in pixels.
  double _mirror(double dx, double width) =>
      _mirrored ? viewportDimension.width - dx - width : dx;

  /// How far each column has been slid aside while a heading is carried.
  ///
  /// Only what is painted moves; the layout keeps the order it has, so the
  /// drop commits against a table already standing where it will stand.
  List<double> _shifts = const [];
  set shifts(List<double> value) {
    if (_shifts.length == value.length) {
      var same = true;
      for (var i = 0; i < value.length; i++) {
        if (_shifts[i] != value[i]) {
          same = false;
          break;
        }
      }
      if (same) return;
    }
    _shifts = value;
    markNeedsLayout();
  }

  double _shiftOf(int column) => column < _shifts.length ? _shifts[column] : 0;

  /// Which body rows are panels, in order, and how tall one stands.
  ///
  /// A lazy body finds a row by reckoning where it starts, and it can go on
  /// doing that with panels among the rows so long as their height is known:
  /// the rows before a given one are so many ordinary ones and so many
  /// panels, which is a count rather than a measurement.
  List<int> _panelRows = const [];
  double _panelHeight = 0;
  void setPanels(List<int> rows, double height) {
    if (_panelHeight == height &&
        _panelRows.length == rows.length &&
        () {
          for (var i = 0; i < rows.length; i++) {
            if (_panelRows[i] != rows[i]) return false;
          }
          return true;
        }()) {
      return;
    }
    _panelRows = rows;
    _panelHeight = height;
    markNeedsLayout();
  }

  /// How many panels stand before body row [row].
  int _panelsBefore(int row) {
    var low = 0;
    var high = _panelRows.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_panelRows[mid] < row) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  bool _isPanel(int row) =>
      _panelRows.isNotEmpty &&
      _panelsBefore(row) < _panelRows.length &&
      _panelRows[_panelsBefore(row)] == row;

  /// Where body row [row] starts, measured down the run of rows.
  double _startOfRow(int row) {
    final panels = _panelsBefore(row);
    return (row - panels) * _rowHeight + panels * _panelHeight;
  }

  /// How tall body row [row] stands.
  double _heightOfRow(int row) => _isPanel(row) ? _panelHeight : _rowHeight;

  /// The whole run of body rows.
  double _runOfRows(int count) =>
      (count - _panelRows.length) * _rowHeight +
      _panelRows.length * _panelHeight;

  /// Which body row is at [offset] down the run.
  int _rowAtOffset(double offset, int count) {
    if (count <= 0) return 0;
    if (_panelRows.isEmpty) {
      return (offset ~/ _rowHeight).clamp(0, count - 1);
    }
    var low = 0;
    var high = count - 1;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_startOfRow(mid) + _heightOfRow(mid) <= offset) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  /// Where every body cell starts and how much it covers, or empty where
  /// nothing spans.
  List<Map<int, ({int across, int down})>> _bodySpans = const [];
  int _deepestSpan = 1;
  void setBodySpans(
    List<Map<int, ({int across, int down})>> value,
    int deepest,
  ) {
    if (identical(_bodySpans, value) && _deepestSpan == deepest) return;
    _bodySpans = value;
    _deepestSpan = deepest;
    markNeedsLayout();
  }

  /// How far each row has been slid aside while one is being carried.
  List<double> _rowShifts = const [];
  set rowShifts(List<double> value) {
    if (_rowShifts.length == value.length) {
      var same = true;
      for (var i = 0; i < value.length; i++) {
        if (_rowShifts[i] != value[i]) {
          same = false;
          break;
        }
      }
      if (same) return;
    }
    _rowShifts = value;
    markNeedsLayout();
  }

  double _rowShiftOf(int row) =>
      row >= 0 && row < _rowShifts.length ? _rowShifts[row] : 0;

  /// Which row is drawn over [y], counting from the viewport's leading edge —
  /// what a drag asks when it wants to know where a carried row would land.
  int? rowAtLocal(double y) {
    if (_rowHeight <= 0) return null;
    final rows =
        (delegate as TwoDimensionalChildBuilderDelegate).maxYIndex! + 1;
    final bodyRows = rows - _headerRows - _footerRows;
    if (bodyRows <= 0) return null;
    final at = (y - _headerHeight + verticalOffset.pixels) ~/ _rowHeight;
    return at.clamp(0, bodyRows - 1);
  }

  /// Which column is drawn over [x], counting from the viewport's leading
  /// edge — what a drag asks when it wants to know where it would land.
  ///
  /// Asked of the layout rather than of whatever cell lies under the finger:
  /// the cells slide, so asking them chases the answer.
  int? columnAtLocal(double x) {
    if (_widths.isEmpty) return null;
    // Asked in pixels, answered from the leading edge.
    if (_mirrored) x = viewportDimension.width - x;
    final across = horizontalOffset.pixels;
    for (var i = 0; i < _columnCount; i++) {
      final natural = _startOf(i) - across;
      final at = switch (_pinning[i]) {
        TableColumnFixed.start => math.max(natural, _restStart(i)),
        TableColumnFixed.end => math.min(
            natural,
            viewportDimension.width - _trail + _restEndBefore(i),
          ),
        null => natural,
      };
      if (x >= at && x < at + _widths[i]) return i;
    }
    return null;
  }

  /// Where each heading cell stands and how much it covers.
  ///
  /// A group's title reaches across the columns under it and a column heading
  /// nothing reaches down the whole depth, neither of which a grid of one
  /// cell per crossing can say. The plan is worked out where the columns are
  /// known — in the widget — and the viewport lays out what it is given.
  List<({int x, int y, int across, int down})> _headerPlan = const [];
  set headerPlan(List<({int x, int y, int across, int down})> value) {
    if (_headerPlan.length == value.length &&
        () {
          for (var i = 0; i < value.length; i++) {
            if (_headerPlan[i] != value[i]) return false;
          }
          return true;
        }()) {
      return;
    }
    _headerPlan = value;
    markNeedsLayout();
  }

  @override
  void layoutChildSequence() {
    final size = viewportDimension;
    final rows =
        (delegate as TwoDimensionalChildBuilderDelegate).maxYIndex! + 1;
    final bodyRows = rows - _headerRows - _footerRows;

    // Every column held at an edge, wherever it stands among the others.
    _lead = 0;
    _trail = 0;
    for (var i = 0; i < _columnCount; i++) {
      if (_pinning[i] == TableColumnFixed.start) _lead += _widths[i];
      if (_pinning[i] == TableColumnFixed.end) _trail += _widths[i];
    }
    _headerHeight = _headerRows * _rowHeight;
    _footerHeight = _footerRows * _rowHeight;

    final total = _extent(0, _columnCount);
    final freeWidth = math.max(0.0, size.width - _lead - _trail);
    _maxAcross = math.max(0.0, total - _lead - _trail - freeWidth);
    horizontalOffset.applyContentDimensions(0, _maxAcross);

    final bodyHeight =
        math.max(0.0, size.height - _headerHeight - _footerHeight);
    verticalOffset.applyContentDimensions(
      0,
      math.max(0, _runOfRows(bodyRows) - bodyHeight),
    );

    final across = horizontalOffset.pixels;
    final down = verticalOffset.pixels;

    // The cache extent is the base class's, and it is worth having: a row
    // built one frame before it is needed is a row that does not have to be
    // built while the finger is moving.
    _firstRow = bodyRows == 0
        ? 0
        : _rowAtOffset(
            math.max(0, down - _cache(bodyHeight)),
            bodyRows,
          );
    _lastRow = bodyRows == 0
        ? -1
        : _rowAtOffset(down + bodyHeight + _cache(bodyHeight), bodyRows);

    /// Where a column is drawn: its own place, carried by the scroll, unless
    /// it is held at an edge and the scroll would take it past its rest.
    double placeOf(int i) {
      final natural = _startOf(i) - across + _shiftOf(i);
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

    void band(int row, double dy, {double? height, int across = 1}) {
      if (across > 1) {
        // A panel is one cell across the whole table, so there is nothing to
        // walk: it starts at the leading edge and takes every column.
        _place(0, row, placeOf(0), dy, across: across, height: height);
        return;
      }
      for (var i = _firstColumn; i <= _lastColumn; i++) {
        if (_pinning[i] == null) {
          final at = placeOf(i);
          if (at + _widths[i] <= -_cache(freeWidth) ||
              at >= size.width + _cache(freeWidth)) {
            continue;
          }
        }
        _place(i, row, placeOf(i), dy, height: height);
      }
    }

    if (_bodySpans.isEmpty) {
      for (var y = _firstRow; y <= _lastRow; y++) {
        band(
          y + _headerRows,
          _headerHeight + _startOfRow(y) - down + _rowShiftOf(y),
          height: _heightOfRow(y),
          across: _isPanel(y) ? _columnCount : 1,
        );
      }
    } else {
      // A cell that starts above the screen can still reach into it, so the
      // walk begins as far back as the deepest span goes and no further —
      // which is why the plan is worked out for every row rather than for
      // the ones on show.
      final from = math.max(0, _firstRow - _deepestSpan + 1);
      for (var y = from; y <= _lastRow && y < _bodySpans.length; y++) {
        for (final start in _bodySpans[y].entries) {
          if (y + start.value.down <= _firstRow) continue;
          final i = start.key;
          if (_pinning[i] == null) {
            final at = placeOf(i);
            var width = 0.0;
            for (var k = 0;
                k < start.value.across && i + k < _columnCount;
                k++) {
              width += _widths[i + k];
            }
            if (at + width <= -_cache(freeWidth) ||
                at >= size.width + _cache(freeWidth)) {
              continue;
            }
          }
          _place(
            i,
            y + _headerRows,
            placeOf(i),
            _headerHeight + y * _rowHeight - down + _rowShiftOf(y),
            across: start.value.across,
            down: start.value.down,
          );
        }
      }
    }
    if (_footerRows > 0) {
      band(rows - 1, size.height - _footerHeight);
    }
    if (_headerRows > 0) {
      if (_headerPlan.isEmpty) {
        band(0, 0);
      } else {
        // A heading of several rows, laid out from the plan: only the cells
        // that start something are placed, and each takes the width of the
        // columns it reaches across and the height of the rows it reaches
        // down.
        for (final cell in _headerPlan) {
          final at = placeOf(cell.x);
          if (_pinning[cell.x] == null) {
            // The same reckoning the other bands use, over the width the cell
            // actually takes: a title reaching across three columns is on
            // screen while any of the three is.
            var width = 0.0;
            for (var i = 0; i < cell.across && cell.x + i < _columnCount; i++) {
              width += _widths[cell.x + i];
            }
            if (at + width <= -_cache(freeWidth) ||
                at >= size.width + _cache(freeWidth)) {
              continue;
            }
          }
          _place(
            cell.x,
            cell.y,
            at,
            cell.y * _rowHeight,
            across: cell.across,
            down: cell.down,
          );
        }
      }
    }
  }

  // One clip layer per band, kept between frames: pushing six new layers on
  // every scrolled pixel is a cost paid for nothing.
  final List<LayerHandle<ClipRectLayer>> _clips = [
    for (var i = 0; i < 9; i++) LayerHandle<ClipRectLayer>(),
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
    final footBounds = Rect.fromLTWH(
      0,
      size.height - _footerHeight,
      size.width,
      _footerHeight,
    );
    final footRow = (delegate as TwoDimensionalChildBuilderDelegate).maxYIndex!;

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
    // The row that adds up, held at the foot and painted over the rows that
    // run under it, exactly as the heading is painted over the ones above.
    if (_footerRows > 0) {
      for (var i = 0; i < order.length; i++) {
        _paintBand(
          context,
          offset,
          _clips[i + 6],
          footBounds,
          held: order[i],
          fromRow: footRow,
          toRow: footRow,
        );
      }
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

    final rect = Rect.fromLTWH(
      _mirror(local.left, local.width),
      local.top,
      local.width,
      local.height,
    ).shift(offset);
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
          // Away from the column it belongs to, whichever side that is on.
          begin: atStart == !_mirrored
              ? Alignment.centerLeft
              : Alignment.centerRight,
          end: atStart == !_mirrored
              ? Alignment.centerRight
              : Alignment.centerLeft,
          colors: [colour, colour.withAlpha(0)],
        ).createShader(rect),
    );
  }

  /// How far the loose columns can be run, kept from the last layout so the
  /// paint knows whether there is anything left ahead to cast over.
  double _maxAcross = 0;
}
