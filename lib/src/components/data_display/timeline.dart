import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../icons/icons.dart' show Spinner;
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/expandable.dart';
import '../../utils/rail.dart';

/// Where the axis and content sit relative to each other.
enum TimelineMode {
  /// Axis on the left, content on the right (the default).
  left,

  /// Axis on the right, content on the left.
  right,

  /// Axis centred, content alternating side to side.
  alternate,
}

/// Which side an item's content takes in [TimelineMode.alternate].
enum TimelineItemPosition {
  /// The content sits to the left of the axis.
  left,

  /// The content sits to the right of the axis.
  right
}

/// Whether the axis runs down the page or across it.
enum TimelineOrientation {
  /// The axis runs top to bottom.
  vertical,

  /// The axis runs left to right.
  horizontal
}

/// Variant style for the timeline dots.
enum TimelineVariant {
  /// Outlined dots (default).
  outlined,

  /// Filled dots.
  filled,
}

/// Per-component design tokens for [Timeline] — its own token table.
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [TimelineToken(...)])`, or per instance via [Timeline.token].
@immutable
class TimelineToken {
  /// Creates a [TimelineToken].
  const TimelineToken({
    this.tailColor,
    this.tailWidth,
    this.dotBg,
    this.dotBorderWidth,
    this.dotSize,
    this.itemPaddingBottom,
    this.itemPaddingEnd,
    this.railInset,
  });

  /// Colour of the connecting line (`tailColor`).
  final Color? tailColor;

  /// Thickness of the connecting line (`tailWidth`).
  final double? tailWidth;

  /// Fill behind a default dot (`dotBg`).
  final Color? dotBg;

  /// Ring thickness of a default dot (`dotBorderWidth`).
  final double? dotBorderWidth;

  /// Diameter of a default dot (`dotSize`).
  final double? dotSize;

  /// Gaps the connecting line keeps on either side of a dot.
  ///
  /// Null on every side — the default, and the look — runs the
  /// line right up to the dot, so the axis reads as one unbroken thread. A gap
  /// turns it into a separator instead, as [Steps] draws its rail. The sides
  /// are named for the run they belong to: `top`/`bottom` above and below a dot
  /// on a vertical axis, `left`/`right` either side of one across the page.
  ///
  /// This is the gap at the *dot*; [Timeline.linePadding] is the one at the
  /// item's outer ends.
  ///
  /// ```dart
  /// Timeline(items: items, token: const TimelineToken(
  ///   railInset: RailInsets.vertical(top: 4, bottom: 4),
  /// ))
  /// ```
  final RailInsets? railInset;

  /// Space below each item (`itemPaddingBottom`) - for vertical orientation.
  final double? itemPaddingBottom;

  /// Space to the right of each item (`itemPaddingEnd`) - for horizontal orientation.
  final double? itemPaddingEnd;

  _ResolvedTimelineToken _resolve(Token t) => _ResolvedTimelineToken(
        tailColor: tailColor ?? t.colorSplit,
        tailWidth: tailWidth ?? 2,
        dotBg: dotBg ?? t.colorBgContainer,
        dotBorderWidth: dotBorderWidth ?? 2,
        dotSize: dotSize ?? 10,
        itemPaddingBottom: itemPaddingBottom ?? 20,
        itemPaddingEnd: itemPaddingEnd ?? 16,
        railInset: railInset ?? RailInsets.zero,
        defaultColor: t.primary.base,
      );
}

@immutable
class _ResolvedTimelineToken {
  const _ResolvedTimelineToken({
    required this.tailColor,
    required this.tailWidth,
    required this.dotBg,
    required this.dotBorderWidth,
    required this.dotSize,
    required this.itemPaddingBottom,
    required this.itemPaddingEnd,
    required this.railInset,
    required this.defaultColor,
  });

  final Color tailColor;
  final double tailWidth;
  final Color dotBg;
  final double dotBorderWidth;
  final double dotSize;
  final double itemPaddingBottom;
  final double itemPaddingEnd;
  final RailInsets railInset;
  final Color defaultColor;
}

/// Anything that can sit in [Timeline.items]: a single [TimelineItem], or a
/// [TimelineGroupItem] standing for a run of them.
///
/// Sealed, so the two are the only cases and the timeline can lay every entry
/// out exhaustively.
@immutable
sealed class TimelineEntry {
  /// Creates a [TimelineEntry].
  const TimelineEntry();
}

/// One node on a [Timeline] — a dot on the axis and its [content].
@immutable
class TimelineItem extends TimelineEntry {
  /// Creates a [TimelineItem].
  const TimelineItem({
    this.color,
    this.dot,
    this.label,
    this.title,
    this.description,
    this.content,
    this.position,
    this.loading = false,
    this.height,
    this.width,
    this.dashed = false,
    this.contentOpacity,
    this.dotVariant,
  });

  /// Dot colour. Null uses the theme's primary.
  final Color? color;

  /// A custom node replacing the default ring dot.
  final Widget? dot;

  /// Content shown on the opposite side of the axis from [content].
  final Widget? label;

  /// Headline of the item's body (Chakra UI's `Timeline.Title`).
  ///
  /// Rendered above [description] and [content] in the item's own emphasis, so
  /// a node reads as a titled entry without composing a Column by hand.
  final Widget? title;

  /// Supporting line under [title] (Chakra UI's `Timeline.Description`),
  /// rendered smaller and in the secondary text colour.
  final Widget? description;

  /// The item's body (the `children` / `content`).
  ///
  /// Stands alone, or sits below [title] and [description] as the free-form
  /// part of Chakra UI's `Timeline.Content`.
  final Widget? content;

  /// Forces the content's side in [TimelineMode.alternate].
  final TimelineItemPosition? position;

  /// Sets loading state for this item.
  final bool loading;

  /// Fixes a vertical item's length — the connecting line below it — matching
  /// the `styles.root.height`. Null lets the item size to its content.
  final double? height;

  /// The horizontal counterpart of [height]: sets a horizontal item's minimum
  /// length (the connecting line to its right), lengthening it past the content
  /// without ever clipping it. Null sizes to content.
  final double? width;

  /// Dashes this item's connecting line.
  final bool dashed;

  /// Opacity applied to this item's content.
  final double? contentOpacity;

  /// This dot's own variant, filled or outlined, in place of the run's
  /// [Timeline.variant] — for the one node that has to stand out.
  final TimelineVariant? dotVariant;
}

/// Opens and closes a [TimelineGroupItem] from outside the timeline.
///
/// ```dart
/// final group = TimelineGroupController();
/// ...
/// Button(onPressed: group.toggle, child: const Text('Show all'));
/// Timeline(items: [TimelineGroupItem(controller: group, items: [...])]);
/// ```
///
/// Dispose it with the widget that owns it. A [TimelineGroupItem] without a
/// controller keeps its own state and needs no disposal.
class TimelineGroupController extends ChangeNotifier {
  /// Creates a [TimelineGroupController].
  TimelineGroupController({bool expanded = false}) : _expanded = expanded;

  bool _expanded;

  /// Whether the group's hidden nodes are revealed.
  bool get expanded => _expanded;

  /// Reveals the hidden nodes.
  void open() => _set(true);

  /// Hides them again.
  void close() => _set(false);

  /// Flips the current state.
  void toggle() => _set(!_expanded);

  void _set(bool value) {
    if (value == _expanded) return;
    _expanded = value;
    notifyListeners();
  }
}

/// A run of nodes on the same axis that collapses down to its first few.
///
/// Drop one into [Timeline.items] like any other item. The first
/// [collapsedCount] nodes always show; the rest slide open and closed along the
/// axis, driven either by [controller] or by the group's own state.
///
/// ```dart
/// TimelineGroupItem(
///   controller: controller,
///   items: [
///     TimelineItem(title: Text('Deploy started')),
///     TimelineItem(title: Text('Image built')),
///     TimelineItem(title: Text('Health checks passed')),
///   ],
/// )
/// ```
///
/// The group draws no node of its own — [items] supply every dot — so the axis
/// reads as one continuous line whether the group is open or shut.
@immutable
class TimelineGroupItem extends TimelineEntry {
  /// Creates a [TimelineGroupItem].
  const TimelineGroupItem({
    required this.items,
    this.controller,
    this.initiallyExpanded = false,
    this.collapsedCount = 1,
  }) : assert(collapsedCount >= 0, 'collapsedCount cannot be negative');

  /// The nodes in the group, in order.
  final List<TimelineItem> items;

  /// Drives the group from outside. Null lets the group manage itself.
  final TimelineGroupController? controller;

  /// Starting state when no [controller] is given.
  final bool initiallyExpanded;

  /// How many leading nodes stay visible while collapsed.
  final int collapsedCount;
}

/// A vertical list of events.
///
/// ```dart
/// Timeline(items: [
///   TimelineItem(content: Text('Create a services site 2015-09-01')),
///   TimelineItem(content: Text('Solve initial network problems 2015-09-01')),
///   TimelineItem(color: Colors.red, content: Text('Technical testing 2015-09-01')),
/// ])
/// ```
///
/// [mode] moves the axis (left, right, or centred with alternating content).
/// [pending] appends a loading node; [reverse] flips the order.
/// [variant] controls the dot style (outlined or filled).
/// [titleSpan] sets the space between the dot and the content, in pixels.
class Timeline extends StatelessWidget {
  /// Creates a [Timeline].
  const Timeline({
    super.key,
    required this.items,
    this.mode = TimelineMode.left,
    this.orientation = TimelineOrientation.vertical,
    this.pending,
    this.pendingDot,
    this.reverse = false,
    this.linePadding,
    this.token,
    this.variant = TimelineVariant.outlined,
    this.titleSpan,
  });

  /// The entries, in order — plain nodes and collapsible groups alike.
  final List<TimelineEntry> items;

  /// How the axis and content are laid out.
  final TimelineMode mode;

  /// Orientation of the timeline (vertical or horizontal).
  final TimelineOrientation orientation;

  /// A trailing "in progress" node. Its widget is the node's content.
  final Widget? pending;

  /// The pending node's dot. Defaults to a spinner.
  final Widget? pendingDot;

  /// Reverses the order (the pending node moves to the top).
  final bool reverse;

  /// Insets on each item's connecting line: `top` opens a gap at the item's top
  /// end of the line, `bottom` at its bottom end. Null keeps the line fully
  /// joined (no gaps).
  final EdgeInsets? linePadding;

  /// Per-instance token overrides.
  final TimelineToken? token;

  /// Variant style for the dots (outlined or filled).
  final TimelineVariant variant;

  /// Distance from the dot to the content, in logical pixels. Null keeps the
  /// default of 12.
  final double? titleSpan;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (token ??
            ConfigProvider.componentOf<TimelineToken>(context) ??
            const TimelineToken())
        ._resolve(t);

    // Build the ordered list of nodes, appending a pending one if asked.
    // A group contributes its own children rather than a node of its own; the
    // ones past `collapsedCount` are tagged so they can be revealed together.
    final nodes = <_Node>[
      for (final entry in items)
        ...switch (entry) {
          TimelineGroupItem(:final items, :final collapsedCount) => [
              for (var i = 0; i < items.length; i++)
                _Node(
                  item: items[i],
                  dashedTail: items[i].dashed,
                  // Everything past the visible head shares the group, so the
                  // run reveals and hides as one.
                  group: i >= collapsedCount ? entry : null,
                ),
            ],
          TimelineItem() => [_Node(item: entry, dashedTail: entry.dashed)],
        },
      if (pending != null)
        _Node(
          item: TimelineItem(
            dot: pendingDot ?? _spinner(r),
            content: pending,
            loading: true,
          ),
          pending: true,
        ),
    ];
    if (reverse) {
      final reversed = nodes.reversed.toList();
      nodes
        ..clear()
        ..addAll(reversed);
    }

    // The segment joining the last real node to the pending one is dashed.
    if (pending != null) {
      final pendingIndex = nodes.indexWhere((n) => n.pending);
      final dashedAbove = reverse ? pendingIndex : pendingIndex - 1;
      if (dashedAbove >= 0 && dashedAbove < nodes.length) {
        nodes[dashedAbove] = nodes[dashedAbove].copyWith(dashedTail: true);
      }
    }

    final twoSided = mode == TimelineMode.alternate ||
        nodes.any((n) => n.item.label != null);

    if (orientation == TimelineOrientation.horizontal) {
      return _buildHorizontal(context, t, r, nodes, twoSided);
    }

    return _buildVertical(context, t, r, nodes, twoSided);
  }

  Widget _buildVertical(
    BuildContext context,
    Token t,
    _ResolvedTimelineToken r,
    List<_Node> nodes,
    bool twoSided,
  ) {
    final rows = <Widget>[
      for (var i = 0; i < nodes.length; i++)
        _buildVerticalRow(
          context,
          t,
          r,
          nodes[i],
          i,
          i == nodes.length - 1,
          twoSided,
          i > 0 && nodes[i - 1].dashedTail,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: _withGroups(
        nodes,
        rows,
        horizontal: false,
        wrap: (children) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  /// Folds each run of grouped rows into a single collapsible section, leaving
  /// ungrouped rows exactly where they were.
  List<Widget> _withGroups(
    List<_Node> nodes,
    List<Widget> rows, {
    required bool horizontal,
    required Widget Function(List<Widget>) wrap,
  }) {
    if (!nodes.any((n) => n.group != null)) return rows;

    final out = <Widget>[];
    var i = 0;
    while (i < nodes.length) {
      final group = nodes[i].group;
      if (group == null) {
        out.add(rows[i]);
        i++;
        continue;
      }
      final start = i;
      while (i < nodes.length && identical(nodes[i].group, group)) {
        i++;
      }
      out.add(
        _TimelineGroupSection(
          group: group,
          horizontal: horizontal,
          child: wrap(rows.sublist(start, i)),
        ),
      );
    }
    return out;
  }

  Widget _buildHorizontal(
    BuildContext context,
    Token t,
    _ResolvedTimelineToken r,
    List<_Node> nodes,
    bool twoSided,
  ) {
    final rows = <Widget>[
      for (var i = 0; i < nodes.length; i++)
        _buildHorizontalRow(
          context,
          t,
          r,
          nodes[i],
          i,
          i == nodes.length - 1,
          twoSided,
          i > 0 && nodes[i - 1].dashedTail,
        ),
    ];

    // IntrinsicHeight sizes the row to the tallest item's natural height, so
    // the axis centres and content hugs — no fixed height needed and no big
    // empty band.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: _withGroups(
          nodes,
          rows,
          horizontal: true,
          wrap: (children) => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _spinner(_ResolvedTimelineToken r) =>
      Spinner(size: r.dotSize + 4, color: r.defaultColor);

  /// Wraps [child] in an [Opacity] when [value] is set.
  Widget _opacity(double? value, Widget child) =>
      value == null ? child : Opacity(opacity: value, child: child);

  /// Composes an item's body out of [TimelineItem.title],
  /// [TimelineItem.description] and [TimelineItem.content], any of which may be
  /// absent. Returns null when the item has no body at all.
  Widget? _buildContent(Token t, TimelineItem item) {
    if (item.title == null &&
        item.description == null &&
        item.content == null) {
      return null;
    }

    final titled = item.title != null || item.description != null;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.title != null)
          DefaultTextStyle(
            style: TextStyle(
              color: t.colorText,
              fontSize: t.fontSize,
              fontWeight: FontWeight.w600,
              height: t.lineHeight,
              leadingDistribution: TextLeadingDistribution.even,
            ),
            child: item.title!,
          ),
        if (item.description != null)
          Padding(
            padding: EdgeInsets.only(top: item.title != null ? t.sizeXXS : 0),
            child: DefaultTextStyle(
              style: TextStyle(
                color: t.colorTextSecondary,
                fontSize: t.fontSizeSM,
                height: t.lineHeight,
                leadingDistribution: TextLeadingDistribution.even,
              ),
              child: item.description!,
            ),
          ),
        if (item.content != null)
          Padding(
            padding: EdgeInsets.only(top: titled ? t.sizeXS : 0),
            child: item.content!,
          ),
      ],
    );

    return _opacity(
      item.contentOpacity,
      DefaultTextStyle(
        style: TextStyle(
          color: t.colorText,
          fontSize: t.fontSize,
          height: t.lineHeight,
          leadingDistribution: TextLeadingDistribution.even,
        ),
        child: body,
      ),
    );
  }

  Widget _buildVerticalRow(
    BuildContext context,
    Token t,
    _ResolvedTimelineToken r,
    _Node node,
    int index,
    bool isLast,
    bool twoSided,
    bool dashedTop,
  ) {
    final item = node.item;
    final gap = titleSpan ?? 12;

    // Decide which side the content and label take.
    late final bool contentOnLeft;
    switch (mode) {
      case TimelineMode.left:
        contentOnLeft = false;
      case TimelineMode.right:
        contentOnLeft = true;
      case TimelineMode.alternate:
        contentOnLeft = (item.position ??
                (index.isEven
                    ? TimelineItemPosition.left
                    : TimelineItemPosition.right)) ==
            TimelineItemPosition.left;
    }

    final content = _buildContent(t, item);
    final label = item.label == null
        ? null
        : DefaultTextStyle(
            style: TextStyle(
              color: t.colorTextSecondary,
              fontSize: t.fontSize,
              height: t.lineHeight,
              leadingDistribution: TextLeadingDistribution.even,
            ),
            child: item.label!,
          );

    final leftChild = contentOnLeft ? content : label;
    final rightChild = contentOnLeft ? label : content;

    final axis = _AxisVertical(
      token: r,
      color: item.color ?? r.defaultColor,
      dot: item.dot,
      isFirst: index == 0,
      isLast: isLast,
      dashedBottom: node.dashedTail,
      dashedTop: dashedTop,
      linePadding: linePadding ?? EdgeInsets.zero,
      variant: item.dotVariant ?? variant,
      loading: item.loading,
      defaultColor: r.defaultColor,
    );

    // Pad the content away from the axis and add the inter-item gap below it.
    Widget? pad(Widget? child, {required bool left}) {
      if (child == null) return null;
      return Padding(
        padding: EdgeInsets.only(
          left: left ? 0 : gap,
          right: left ? gap : 0,
          bottom: r.itemPaddingBottom,
        ),
        child: Align(
          alignment: left ? Alignment.topRight : Alignment.topLeft,
          child: child,
        ),
      );
    }

    final children = <Widget>[];
    if (twoSided) {
      children.add(
        Expanded(
          child: pad(leftChild, left: true) ?? const SizedBox.shrink(),
        ),
      );
      children.add(axis);
      children.add(
        Expanded(
          child: pad(rightChild, left: false) ?? const SizedBox.shrink(),
        ),
      );
    } else if (mode == TimelineMode.right) {
      children.add(
        Expanded(
          child: pad(content, left: true) ?? const SizedBox.shrink(),
        ),
      );
      children.add(axis);
    } else {
      children.add(axis);
      children.add(
        Expanded(
          child: pad(content, left: false) ?? const SizedBox.shrink(),
        ),
      );
    }

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    // A fixed height stretches the line to fill it (styles.root.height);
    // otherwise the row hugs its content.
    return item.height != null
        ? SizedBox(height: item.height, child: row)
        : IntrinsicHeight(child: row);
  }

  Widget _buildHorizontalRow(
    BuildContext context,
    Token t,
    _ResolvedTimelineToken r,
    _Node node,
    int index,
    bool isLast,
    bool twoSided,
    bool dashedLeft,
  ) {
    final item = node.item;
    final gap = titleSpan ?? 12;

    // For horizontal, we need to decide top/bottom instead of left/right
    late final bool contentOnTop;
    switch (mode) {
      case TimelineMode.left:
        contentOnTop = false; // content below axis
      case TimelineMode.right:
        contentOnTop = true; // content above axis
      case TimelineMode.alternate:
        contentOnTop = (item.position ??
                (index.isEven
                    ? TimelineItemPosition.left
                    : TimelineItemPosition.right)) ==
            TimelineItemPosition.left;
    }

    final content = _buildContent(t, item);
    final label = item.label == null
        ? null
        : DefaultTextStyle(
            style: TextStyle(
              color: t.colorTextSecondary,
              fontSize: t.fontSize,
              height: t.lineHeight,
              leadingDistribution: TextLeadingDistribution.even,
            ),
            child: item.label!,
          );

    final topChild = contentOnTop ? content : label;
    final bottomChild = contentOnTop ? label : content;

    final axis = _AxisHorizontal(
      token: r,
      color: item.color ?? r.defaultColor,
      dot: item.dot,
      isFirst: index == 0,
      isLast: isLast,
      dashedRight: node.dashedTail,
      dashedLeft: dashedLeft,
      linePadding: linePadding ?? EdgeInsets.zero,
      variant: item.dotVariant ?? variant,
      loading: item.loading,
      defaultColor: r.defaultColor,
    );

    // The inter-item gap is split evenly on both sides so the content stays
    // centred under the dot — an asymmetric (right-only) gap would push the
    // dot off the text's centre.
    final side = r.itemPaddingEnd / 2;
    Widget? pad(Widget? child, {required bool top}) {
      if (child == null) return null;
      return Padding(
        padding: EdgeInsets.only(
          top: top ? 0 : gap,
          bottom: top ? gap : 0,
          left: side,
          right: side,
        ),
        child: Align(
          alignment: top ? Alignment.bottomCenter : Alignment.topCenter,
          child: child,
        ),
      );
    }

    final children = <Widget>[];
    if (twoSided) {
      children.add(
        Expanded(
          child: pad(topChild, top: true) ?? const SizedBox.shrink(),
        ),
      );
      children.add(axis);
      children.add(
        Expanded(
          child: pad(bottomChild, top: false) ?? const SizedBox.shrink(),
        ),
      );
    } else if (mode == TimelineMode.right) {
      children.add(
        Expanded(
          child: pad(content, top: true) ?? const SizedBox.shrink(),
        ),
      );
      children.add(axis);
    } else {
      children.add(axis);
      children.add(
        Expanded(
          child: pad(content, top: false) ?? const SizedBox.shrink(),
        ),
      );
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    // `width` sets a minimum item width — it lengthens the line past the content
    // but never clips it. Without it, a floor keeps dots from crowding when
    // content is very narrow. The content stays centred within the item.
    final minWidth = item.width ?? (r.dotSize + r.itemPaddingEnd * 2);
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: IntrinsicWidth(child: column),
    );
  }
}

/// Reveals a group's collapsible nodes along the axis.
///
/// Vertically this is the shared [Expandable]; horizontally it is the same
/// idea on the other axis, since [Expandable] only animates height.
class _TimelineGroupSection extends StatefulWidget {
  const _TimelineGroupSection({
    required this.group,
    required this.horizontal,
    required this.child,
  });

  final TimelineGroupItem group;
  final bool horizontal;
  final Widget child;

  @override
  State<_TimelineGroupSection> createState() => _TimelineGroupSectionState();
}

class _TimelineGroupSectionState extends State<_TimelineGroupSection> {
  /// Used only when the group brought no controller of its own.
  late final TimelineGroupController _fallback =
      TimelineGroupController(expanded: widget.group.initiallyExpanded);

  TimelineGroupController get _controller =>
      widget.group.controller ?? _fallback;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(_TimelineGroupSection old) {
    super.didUpdateWidget(old);
    final previous = old.group.controller ?? _fallback;
    if (!identical(previous, _controller)) {
      previous.removeListener(_onChange);
      _controller.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _fallback.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final expanded = _controller.expanded;
    if (!widget.horizontal) {
      return Expandable(expanded: expanded, child: widget.child);
    }

    final t = context.softToken;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: expanded ? 1 : 0),
      duration: t.motionDurationMid,
      curve: t.motionEaseInOut,
      child: widget.child,
      builder: (context, factor, child) => factor >= 1
          ? child!
          : ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: factor,
                child: child,
              ),
            ),
    );
  }
}

/// Vertical axis: dot-and-line cell in the middle of a row.
class _AxisVertical extends StatelessWidget {
  const _AxisVertical({
    required this.token,
    required this.color,
    required this.dot,
    required this.isFirst,
    required this.isLast,
    required this.dashedTop,
    required this.dashedBottom,
    required this.linePadding,
    required this.variant,
    required this.loading,
    required this.defaultColor,
  });

  final _ResolvedTimelineToken token;
  final Color color;
  final Widget? dot;
  final bool isFirst;
  final bool isLast;
  final bool dashedTop;
  final bool dashedBottom;
  final EdgeInsets linePadding;
  final TimelineVariant variant;
  final bool loading;
  final Color defaultColor;

  @override
  Widget build(BuildContext context) {
    final size = token.dotSize;
    Widget? dotWidget = dot;

    if (dotWidget == null) {
      if (loading) {
        dotWidget = Spinner(size: size + 4, color: color);
      } else {
        final isFilled = variant == TimelineVariant.filled;
        dotWidget = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isFilled ? color : token.dotBg,
            shape: BoxShape.circle,
            border: isFilled
                ? null
                : Border.all(color: color, width: token.dotBorderWidth),
          ),
        );
      }
    }

    // Centre the dot in a band as tall as the first text line, so its centre
    // lands on the middle of that line regardless of the dot's own size (a ring
    // and a taller custom icon both align). The content text uses even leading
    // (see _buildVerticalRow) so its glyph centres on the same line.
    final t = context.softToken;
    final lineH = t.fontSize * t.lineHeight;
    final dotCenterY = lineH / 2;
    // Measured from the dot's edge, so the gap you see is the gap you asked
    // for whatever size the dot is — and never past the run it eats into: a
    // gap wider than the line above the dot would ask for a line of negative
    // length.
    double gap(double? inset) => inset == null || inset == 0
        ? 0.0
        : math.min(size / 2 + inset, dotCenterY);
    final gapAbove = gap(token.railInset.top);
    final gapBelow = gap(token.railInset.bottom);

    return SizedBox(
      width: 24,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: RailPainter(
                axis: Axis.vertical,
                thickness: token.tailWidth,
                startInset: linePadding.top,
                endInset: linePadding.bottom,
                segments: [
                  // Above the dot, then below it: two runs meeting at the dot
                  // so each can be dashed on its own. `railInset` pulls each
                  // one back from the dot's edge, turning the thread into a
                  // separator; at zero they meet under the dot as before.
                  if (!isFirst && dotCenterY - gapAbove > 0)
                    RailSegment(
                      start: 0,
                      end: dotCenterY - gapAbove,
                      color: token.tailColor,
                      dashed: dashedTop,
                    ),
                  if (!isLast)
                    RailSegment(
                      start: dotCenterY + gapBelow,
                      end: double.infinity,
                      color: token.tailColor,
                      dashed: dashedBottom,
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: lineH,
            child: Center(child: dotWidget),
          ),
        ],
      ),
    );
  }
}

/// Horizontal axis: dot-and-line cell in the middle of a column.
class _AxisHorizontal extends StatelessWidget {
  const _AxisHorizontal({
    required this.token,
    required this.color,
    required this.dot,
    required this.isFirst,
    required this.isLast,
    required this.dashedLeft,
    required this.dashedRight,
    required this.linePadding,
    required this.variant,
    required this.loading,
    required this.defaultColor,
  });

  final _ResolvedTimelineToken token;
  final Color color;
  final Widget? dot;
  final bool isFirst;
  final bool isLast;
  final bool dashedLeft;
  final bool dashedRight;
  final EdgeInsets linePadding;
  final TimelineVariant variant;
  final bool loading;
  final Color defaultColor;

  @override
  Widget build(BuildContext context) {
    final size = token.dotSize;
    Widget? dotWidget = dot;

    if (dotWidget == null) {
      if (loading) {
        dotWidget = Spinner(size: size + 4, color: color);
      } else {
        final isFilled = variant == TimelineVariant.filled;
        dotWidget = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isFilled ? color : token.dotBg,
            shape: BoxShape.circle,
            border: isFilled
                ? null
                : Border.all(color: color, width: token.dotBorderWidth),
          ),
        );
      }
    }

    return SizedBox(
      height: 24,
      child: Stack(
        children: [
          // The two runs meet where the dot is — the cell's centre — and the
          // cell is stretched by its parent, so its width is only known here.
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final centre = constraints.maxWidth / 2;
                double gap(double? inset) => inset == null || inset == 0
                    ? 0.0
                    : math.min(size / 2 + inset, centre);
                final gapLeft = gap(token.railInset.left);
                final gapRight = gap(token.railInset.right);
                return CustomPaint(
                  painter: RailPainter(
                    axis: Axis.horizontal,
                    thickness: token.tailWidth,
                    startInset: linePadding.left,
                    endInset: linePadding.right,
                    segments: [
                      if ((!isFirst || dashedLeft) && centre - gapLeft > 0)
                        RailSegment(
                          start: 0,
                          end: centre - gapLeft,
                          color: token.tailColor,
                          dashed: dashedLeft,
                        ),
                      if (!isLast || dashedRight)
                        RailSegment(
                          start: centre + gapRight,
                          end: double.infinity,
                          color: token.tailColor,
                          dashed: dashedRight,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(child: dotWidget),
          ),
        ],
      ),
    );
  }
}

/// A node plus its rendering flags.
@immutable
class _Node {
  const _Node({
    required this.item,
    this.pending = false,
    this.dashedTail = false,
    this.group,
  });

  final TimelineItem item;
  final bool pending;
  final bool dashedTail;

  /// Set when the node is one of a group's collapsible ones.
  final TimelineGroupItem? group;

  _Node copyWith({bool? dashedTail}) => _Node(
        item: item,
        pending: pending,
        dashedTail: dashedTail ?? this.dashedTail,
        group: group,
      );
}
