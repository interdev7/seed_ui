import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart' hide Table, TableRow;
// Flutter's own Table does the column arithmetic: it measures every cell in a
// column and gives them all the widest one's width, which is the behaviour a
// caller expects from a table and the reason none of this is written by hand.
// Ours takes the plain name, so Flutter's wears the prefix.
import 'package:flutter/widgets.dart' as flutter show Table, TableRow;

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../theme/palette.dart';
import '../../utils/size_resolver.dart';
import '../feedback/spin.dart';
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
  })  : assert(
          width == null || flex == null,
          'Give a column a width or a flex, not both: one is a number of '
          'pixels and the other a share of what is left over.',
        ),
        assert(
          value != null || builder != null,
          'A column needs a value to read, a builder to draw with, or both.',
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
  });

  /// Fill behind the heading row.
  final Color? headerBg;

  /// Colour of the heading text.
  final Color? headerColor;

  /// Fill behind the row under the pointer.
  final Color? rowHoverBg;

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

  _ResolvedTableToken _resolve(Token t) => _ResolvedTableToken(
        headerBg: headerBg ?? t.colorFillQuaternary,
        headerColor: headerColor ?? t.colorText,
        rowHoverBg: rowHoverBg ?? t.colorFillQuaternary,
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
        // showing through columns that are mostly transparent. antd lays a
        // strip over the scrolling rows instead, and so does this.
        pinnedShadowColor: pinnedShadowColor ??
            alphaOn(const Color(0xFF000000), t.isDark ? 0.32 : 0.15),
        pinnedShadowExtent: pinnedShadowExtent ?? t.sizeLG,
      );
}

@immutable
class _ResolvedTableToken {
  const _ResolvedTableToken({
    required this.headerBg,
    required this.headerColor,
    required this.rowHoverBg,
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
  });

  final Color headerBg;
  final Color headerColor;
  final Color rowHoverBg;
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
  List<TableColumn<T>> _pinnedTo(TableColumnFixed side) =>
      widget.columns.where((c) => c.fixed == side).toList();

  /// The columns that scroll.
  List<TableColumn<T>> get _loose =>
      widget.columns.where((c) => c.fixed == null).toList();

  bool get _hasPinned => widget.columns.any((c) => c.fixed != null);

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
    flutter.TableRow headingRow(List<TableColumn<T>> columns) =>
        flutter.TableRow(
          decoration: BoxDecoration(
            color: r.headerBg,
            border: Border(bottom: rule),
          ),
          children: [
            for (final column in columns)
              _cell(
                DefaultTextStyle.merge(
                  style: TextStyle(
                    color: r.headerColor,
                    fontWeight: t.fontWeightStrong,
                  ),
                  child: column.title ?? const SizedBox.shrink(),
                ),
                column,
                column.headerAlign ?? column.align ?? TableAlign.start,
                r,
                t,
              ),
          ],
        );

    List<flutter.TableRow> dataRowsOf(List<TableColumn<T>> columns) => [
          for (var i = 0; i < widget.data.length; i++)
            flutter.TableRow(
              decoration: BoxDecoration(
                // Every row but the last carries the rule below it, so the
                // table does not end on a line hanging under nothing.
                border:
                    i == widget.data.length - 1 ? null : Border(bottom: rule),
              ),
              children: [
                for (final column in columns) _rowCell(i, column, r, t),
              ],
            ),
        ];

    flutter.Table grid(
      List<TableColumn<T>> columns,
      List<flutter.TableRow> of,
    ) =>
        flutter.Table(
          columnWidths: _widthsFor(columns, r),
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
          ? _across1D(sized, t, _headingX, bar: false)
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

    Widget table;
    if (!_hasPinned) {
      final all = <flutter.TableRow>[
        if (_showHeader) headingRow(widget.columns),
        ...dataRowsOf(widget.columns),
      ];
      table = _detached
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_showHeader) grid(widget.columns, [all.first]),
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
                          widget.columns,
                          _showHeader ? all.skip(1).toList() : all,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : grid(widget.columns, all);
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
              child: widget.header!(context, widget.data),
            ),
          table,
          if (widget.footer != null)
            Container(
              padding: _cellPadding(r, t),
              decoration: BoxDecoration(
                color: r.footerBg,
                border: Border(top: rule),
              ),
              child: widget.footer!(context, widget.data),
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
          width: math.max(_across!, _leastWidth(widget.columns, r)),
          child: body,
        ),
        t,
        _rowsX,
      );
    }

    if (_bordered) {
      body = DecoratedBox(
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

    return Spin(spinning: widget.loading, child: body);
  }

  Widget _defaultEmpty(BuildContext context, EmptySlot slot) => const Empty();

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
    ScrollController controller, {
    bool bar = true,
  }) =>
      ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            ...ScrollConfiguration.of(context).dragDevices,
            PointerDeviceKind.mouse,
          },
          scrollbars: false,
        ),
        // RawScrollbar and not Material's: the kit draws its own chrome from
        // its own tokens.
        child: RawScrollbar(
          controller: controller,
          // Only while it is being scrolled. A bar standing across the foot
          // of every wide table is a line the design did not ask for; the
          // shadow on a pinned column is what says there is more to see.
          thumbVisibility: false,
          // The track is never drawn, bar or no bar.
          trackVisibility: false,
          thumbColor: t.colorFill,
          thickness: t.sizeXS,
          radius: Radius.circular(t.sizeXS),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: controller,
            child: child,
          ),
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
    final record = widget.data[index];
    Widget cell = _cell(
      column.builder?.call(context, record, index) ?? _text(column, record),
      column,
      column.align ?? TableAlign.start,
      r,
      t,
    );
    if (widget.onRowTap != null) {
      cell = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onRowTap!(record, index),
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
          color: hovered == index ? r.rowHoverBg : const Color(0x00000000),
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
