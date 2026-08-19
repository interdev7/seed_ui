// reorderable_list.dart
import 'package:flutter/widgets.dart';

import '../../icons/icons.dart' show HolderPainter;
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';

/// Per-component design tokens for [SortableList] — the lift shadow, corner
/// rounding and colours a dragged row takes on.
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme.
@immutable
class SortableListToken {
  /// Creates a [SortableListToken].
  const SortableListToken({
    this.liftShadow,
    this.liftRadius,
    this.backgroundColor,
  });

  /// Shadow cast by the lifted item.
  final List<BoxShadow>? liftShadow;

  /// Corner radius of the lifted item's shadow.
  final double? liftRadius;

  /// Background color of the lifted item's container.
  /// When null, the item's own background shows through.
  final Color? backgroundColor;

  _ResolvedSortableListToken _resolve(Token t) => _ResolvedSortableListToken(
        liftShadow: liftShadow ?? t.boxShadow,
        liftRadius: liftRadius ?? t.borderRadius,
        backgroundColor: backgroundColor,
      );
}

@immutable
class _ResolvedSortableListToken {
  const _ResolvedSortableListToken({
    required this.liftShadow,
    required this.liftRadius,
    required this.backgroundColor,
  });

  final List<BoxShadow> liftShadow;
  final double liftRadius;
  final Color? backgroundColor;
}

/// A list whose items can be dragged to reorder, with the others sliding
/// smoothly out of the way in both directions.
///
/// Built on Flutter's [SliverReorderableList], so the make-room animation is
/// handled for you. Works [Axis.vertical] or [Axis.horizontal].
///
/// ```dart
/// SortableList(
///   onReorder: (from, to) => setState(() {
///     data.insert(to, data.removeAt(from));
///   }),
///   children: [
///     for (final d in data) MyRow(key: ValueKey(d.id), ...),
///   ],
/// )
/// ```
///
/// Every child **must** carry a unique [Key] so items keep their identity across
/// reorders. A grip handle starts the drag by default; set [showHandle] to false
/// to drag a whole item after a long-press instead, or pass your own [handle].
///
/// The lifted (dragged) item's look is customisable via [SortableListToken]
/// (shadow, radius, background) or by passing a custom [liftBuilder].
class SortableList extends StatelessWidget {
  /// Creates a [SortableList].
  const SortableList({
    super.key,
    required this.children,
    required this.onReorder,
    this.direction = Axis.vertical,
    this.showHandle = true,
    this.handle,
    this.gap = 0,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = true,
    this.physics,
    this.controller,
    this.liftBuilder,
    this.token,
  });

  /// The items, each with a unique [Key].
  final List<Widget> children;

  /// Called with the item's original and final index after a reorder. The
  /// indices are already adjusted, so `data.insert(to, data.removeAt(from))`
  /// applies the move directly.
  final void Function(int from, int to) onReorder;

  /// Whether the list runs down the page or across it.
  final Axis direction;

  /// Shows a drag handle that starts the drag. When false, an item is dragged
  /// after a long-press anywhere on it.
  final bool showHandle;

  /// A custom drag handle, replacing the default grip. Only used when
  /// [showHandle] is true.
  final Widget? handle;

  /// Space between items.
  final double gap;

  /// Padding around the whole list.
  final EdgeInsets padding;

  /// Shrink-wraps the list to its content (the default, for embedding in a
  /// column/row). Set false for a full, independently scrolling list.
  final bool shrinkWrap;

  /// Scroll physics. Defaults to non-scrolling when [shrinkWrap] is true.
  final ScrollPhysics? physics;

  /// Optional external scroll controller.
  final ScrollController? controller;

  /// Full control over the lifted item's appearance. When null, a shadow-only
  /// lift from [SortableListToken] is used.
  ///
  /// The [child] passed here is the **raw item** from [children], without
  /// any handle, padding or spacing wrappers — so you can apply shadows,
  /// backgrounds and animations directly to the item itself.
  final Widget Function(
    BuildContext context,
    Widget child,
    Animation<double> animation,
  )? liftBuilder;

  /// Per-instance token overrides.
  final SortableListToken? token;

  bool get _vertical => direction == Axis.vertical;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final resolved = (token ??
            ConfigProvider.componentOf<SortableListToken>(context) ??
            const SortableListToken())
        ._resolve(t);

    return CustomScrollView(
      scrollDirection: direction,
      shrinkWrap: shrinkWrap,
      controller: controller,
      physics:
          physics ?? (shrinkWrap ? const NeverScrollableScrollPhysics() : null),
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverReorderableList(
            itemCount: children.length,
            onReorderItem: onReorder,
            proxyDecorator: (_, index, animation) => _buildLift(
              context,
              children[index],
              index,
              animation,
              resolved,
            ),
            itemBuilder: (context, i) => _item(context, t, i, resolved),
          ),
        ),
      ],
    );
  }

  Widget _item(
    BuildContext context,
    Token t,
    int index,
    _ResolvedSortableListToken resolved,
  ) {
    final child = children[index];
    final key = child.key ?? ValueKey('sortable_$index');

    Widget content = child;
    if (showHandle) {
      final grip = handle ??
          Padding(
            padding: EdgeInsets.all(t.sizeXXS),
            child: CustomPaint(
              size: Size.square(t.fontSize),
              painter: HolderPainter(t.colorTextTertiary),
            ),
          );
      final draggableHandle = MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: ReorderableDragStartListener(index: index, child: grip),
      );
      content = _vertical
          ? Row(children: [draggableHandle, Expanded(child: child)])
          : Column(children: [draggableHandle, Expanded(child: child)]);
    } else {
      content = ReorderableDelayedDragStartListener(index: index, child: child);
    }

    // Spacing between items (not after the last one).
    if (gap > 0 && index != children.length - 1) {
      content = Padding(
        // After each item in turn, which across the page means the end of the
        // row rather than its right.
        padding: _vertical
            ? EdgeInsets.only(bottom: gap)
            : EdgeInsetsDirectional.only(end: gap),
        child: content,
      );
    }

    return KeyedSubtree(key: key, child: content);
  }

  /// Builds the lifted item appearance.
  ///
  /// If [liftBuilder] is provided, it gets the raw child and full control.
  /// Otherwise, uses [SortableListToken] for shadow/radius/background.
  Widget _buildLift(
    BuildContext context,
    Widget child,
    int index,
    Animation<double> animation,
    _ResolvedSortableListToken resolved,
  ) {
    if (liftBuilder != null) {
      return liftBuilder!(context, child, animation);
    }

    return _defaultLift(context, child, animation, resolved);
  }

  /// Default lift: wraps the raw child with shadow (and optional background).
  Widget _defaultLift(
    BuildContext context,
    Widget child,
    Animation<double> animation,
    _ResolvedSortableListToken resolved,
  ) {
    final shadow = resolved.liftShadow;
    final radius = resolved.liftRadius;
    final bg = resolved.backgroundColor;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final e = Curves.easeOut.transform(animation.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [for (final s in shadow) s.scale(e)],
          ),
          child: child,
        );
      },
    );
  }
}
