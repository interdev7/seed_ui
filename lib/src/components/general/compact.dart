import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';

/// Where a control stands in a [Compact] group.
enum CompactPosition {
  /// At the start of the run: keeps the corners on its leading side.
  first,

  /// Between two others: square on both joined sides.
  middle,

  /// At the end of the run: keeps the corners on its trailing side.
  last,

  /// The only one there: keeps all of its corners, as though the group were
  /// not there at all.
  only,
}

/// What a control reads to find out that it has been joined to its
/// neighbours, and on which sides.
///
/// One of these stands over each child of a [Compact], which is why a control
/// asks for it by context rather than being handed it: the control may be
/// nested — a `Button` inside a `Dropdown` inside the group — and looking up
/// finds the slot wherever it happens to sit.
///
/// A control of your own can join in by reading it and squaring the corners
/// it names.
class CompactSlot extends InheritedWidget {
  /// Creates a [CompactSlot].
  const CompactSlot({
    super.key,
    required this.position,
    required this.direction,
    required super.child,
  });

  /// Where this control stands among the others.
  final CompactPosition position;

  /// Which way the group runs.
  final Axis direction;

  /// The slot this context stands in, or null where it stands in no group.
  static CompactSlot? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CompactSlot>();

  /// The corners a control should draw, given the ones it would draw alone.
  ///
  /// Handed back whole where there is no group, so a control that asks this
  /// instead of building its own radius looks exactly as it always did
  /// everywhere else.
  ///
  /// Named by start and end rather than left and right, and so resolved when
  /// the control is painted rather than when it is built: the run itself is
  /// laid out by the reading direction, so a group that reads the other way
  /// keeps its round corners on the outside without anything having to be
  /// rebuilt — and a control that animates its decoration does not morph its
  /// corners on the way.
  static BorderRadiusDirectional radiusOf(BuildContext context, double radius) {
    final slot = maybeOf(context);
    final round = Radius.circular(radius);
    if (slot == null || slot.position == CompactPosition.only) {
      return BorderRadiusDirectional.all(round);
    }
    final rows = slot.direction == Axis.horizontal;
    final keepsStart = slot.position == CompactPosition.first;
    final keepsEnd = slot.position == CompactPosition.last;
    // Across a row the ends of the run are its start and end corners; down a
    // column they are the top and the bottom, both corners of each.
    return BorderRadiusDirectional.only(
      topStart: keepsStart ? round : Radius.zero,
      bottomStart: (rows ? keepsStart : keepsEnd) ? round : Radius.zero,
      topEnd: (rows ? keepsEnd : keepsStart) ? round : Radius.zero,
      bottomEnd: keepsEnd ? round : Radius.zero,
    );
  }

  @override
  bool updateShouldNotify(CompactSlot old) =>
      position != old.position || direction != old.direction;
}

/// Joins a run of controls into one: square where they meet, rounded only at
/// the ends, and a single line between neighbours rather than two.
///
/// ```dart
/// Compact(
///   children: [
///     Button(onPressed: save, child: const Text('Save')),
///     Dropdown(menu: more, child: Button(icon: const Icon(Icons.more_horiz))),
///   ],
/// )
/// ```
///
/// The corners are the control's own business — a group cannot reach inside a
/// widget somebody else built — so each control asks [CompactSlot] what to
/// draw. The kit's own bordered controls do; a widget that does not simply
/// stands in the run unjoined, which is the worst that can happen to it.
class Compact extends StatelessWidget {
  /// Creates a [Compact].
  const Compact({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
    this.block = false,
  });

  /// The controls, in the order they are joined.
  final List<Widget> children;

  /// Which way the run goes.
  final Axis direction;

  /// Whether the run takes the whole width it is given, sharing it equally.
  final bool block;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final t = context.softToken;

    return Flex(
      direction: direction,
      mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
      // Across a row the controls are centred rather than stretched: a row
      // is often given unbounded height — inside a `Wrap`, or a `Column`
      // that has not been told a height — and stretching into that is an
      // infinity. They line up anyway, every control of a size taking the
      // same height. Down a column the cross axis is the width, which a
      // column is nearly always given, and a ragged edge there would be the
      // one thing a joined run must not have.
      crossAxisAlignment: direction == Axis.vertical
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < children.length; i++)
          _place(
            children[i],
            position: children.length == 1
                ? CompactPosition.only
                : i == 0
                    ? CompactPosition.first
                    : i == children.length - 1
                        ? CompactPosition.last
                        : CompactPosition.middle,
            // Every one after the first is pulled back by the width of a line,
            // so the two borders that meet draw one line rather than two. The
            // borders themselves are left whole: a control that drops a side
            // has a gap in its ring the moment it takes focus.
            overlap: i == 0 ? 0 : t.lineWidth,
          ),
      ],
    );
  }

  /// Wraps one child in its slot, keeping any flex it came with on the
  /// outside.
  ///
  /// A caller may well hand in `Expanded(child: Input(...))` — a field that
  /// takes what is left of the row. `Expanded` speaks only to the `Flex`
  /// directly above it, so the wrapping goes *inside* it and the flex is put
  /// back on the outside; wrapping over it would leave the `Expanded` talking
  /// to a render object that has never heard of flex.
  Widget _place(
    Widget child, {
    required CompactPosition position,
    required double overlap,
  }) {
    var inner = child;
    int? flex;
    FlexFit? fit;
    if (child is Flexible) {
      inner = child.child;
      flex = child.flex;
      fit = child.fit;
    }
    Widget wrapped = CompactSlot(
      position: position,
      direction: direction,
      child: overlap == 0
          ? inner
          : CompactOverlap(by: overlap, direction: direction, child: inner),
    );
    if (flex != null) {
      wrapped = Flexible(flex: flex, fit: fit!, child: wrapped);
    } else if (block) {
      // Nothing said how the room should be shared, and the run was told to
      // take all of it: share it equally.
      wrapped = Expanded(child: wrapped);
    }
    return wrapped;
  }
}

/// Pulls a control back onto its neighbour by the width of a line.
///
/// Shared with any control that lays a run out itself — a run of radio
/// buttons does — so that every seam in the kit is closed the same way. Not
/// exported: a caller joins controls with [Compact].
///
/// In the layout, not merely in the painting: a `Transform` would leave the
/// run as wide as it was and put a hairline of nothing at the far end. The
/// child keeps its whole border — a control that dropped a side would have a
/// gap in its ring the moment it took focus — and the two that meet draw one
/// line, since the later one is painted over the earlier.
class CompactOverlap extends SingleChildRenderObjectWidget {
  /// Creates a [CompactOverlap].
  const CompactOverlap({
    super.key,
    required this.by,
    required this.direction,
    required super.child,
  });

  /// How far back to pull the child — the width of one line.
  final double by;

  /// Which way the run goes.
  final Axis direction;

  /// Whether the neighbour this child overlaps lies before it on the screen.
  ///
  /// Down a column it always does. Across a row it is on the left where the
  /// words run that way and on the right where they do not — and the child,
  /// being a line wider than the room it takes, then needs no shifting at
  /// all: it spills over the neighbour by itself.
  ///
  /// Read here, and only here, because a render object has no reading
  /// direction of its own; a run laid out the other way needs nothing from
  /// its caller.
  bool _before(BuildContext context) =>
      direction == Axis.vertical ||
      Directionality.maybeOf(context) != TextDirection.rtl;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCompactOverlap(
        by: by,
        direction: direction,
        before: _before(context),
      );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderCompactOverlap)
      ..by = by
      ..direction = direction
      ..before = _before(context);
  }
}

class _RenderCompactOverlap extends RenderShiftedBox {
  _RenderCompactOverlap({
    required double by,
    required Axis direction,
    required bool before,
  })  : _by = by,
        _direction = direction,
        _before = before,
        super(null);

  double _by;
  set by(double value) {
    if (_by == value) return;
    _by = value;
    markNeedsLayout();
  }

  Axis _direction;
  set direction(Axis value) {
    if (_direction == value) return;
    _direction = value;
    markNeedsLayout();
  }

  bool _before;
  set before(bool value) {
    if (_before == value) return;
    _before = value;
    markNeedsLayout();
  }

  bool get _rows => _direction == Axis.horizontal;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    // The child is laid out a line *wider* than the room given, then placed a
    // line back: it ends where it would have, and starts on top of what came
    // before it.
    final inner = _rows
        ? constraints.copyWith(
            minWidth: constraints.hasTightWidth
                ? constraints.maxWidth + _by
                : constraints.minWidth,
            maxWidth: constraints.maxWidth.isFinite
                ? constraints.maxWidth + _by
                : constraints.maxWidth,
          )
        : constraints.copyWith(
            minHeight: constraints.hasTightHeight
                ? constraints.maxHeight + _by
                : constraints.minHeight,
            maxHeight: constraints.maxHeight.isFinite
                ? constraints.maxHeight + _by
                : constraints.maxHeight,
          );
    child.layout(inner, parentUsesSize: true);
    // Only where the neighbour lies before this child: laid out a line wider,
    // it has to be pulled back to reach the neighbour. Where the neighbour
    // lies after it, the extra line already spills that way and shifting as
    // well would carry it a whole line too far.
    final back = _before ? _by : 0.0;
    (child.parentData! as BoxParentData).offset =
        _rows ? Offset(-back, 0) : Offset(0, -back);
    size = constraints.constrain(
      _rows
          ? Size(child.size.width - _by, child.size.height)
          : Size(child.size.width, child.size.height - _by),
    );
  }

  // A run asked for its intrinsic size must not count the overlap twice: the
  // child is a line wider than the room it ends up taking.
  @override
  double computeMinIntrinsicWidth(double height) =>
      super.computeMinIntrinsicWidth(height) - (_rows ? _by : 0);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      super.computeMaxIntrinsicWidth(height) - (_rows ? _by : 0);

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width) - (_rows ? 0 : _by);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width) - (_rows ? 0 : _by);
}
