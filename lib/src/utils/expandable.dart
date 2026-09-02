import 'package:flutter/widgets.dart';

import '../theme/config_provider.dart';

/// Animates a child open and closed along the vertical axis — the show/hide
/// shared by `Collapse` panels and `Tree` node children.
///
/// Both directions animate (a size reveal). When [destroyWhenCollapsed] is set
/// the child is removed from the tree *after* the close animation finishes
/// (Tree unmounts collapsed subtrees); otherwise it stays mounted at zero
/// height, matching the default of keeping collapsed content around
/// (Collapse).
///
/// [duration] and [curve] are the shared animation knobs and default to the
/// theme's mid duration and in-out ease, so every caller animates consistently.
class Expandable extends StatefulWidget {
  /// Creates an [Expandable].
  const Expandable({
    super.key,
    required this.expanded,
    required this.child,
    this.duration,
    this.curve,
    this.destroyWhenCollapsed = false,
    this.animateOnMount = false,
  });

  /// Whether the child is shown.
  final bool expanded;

  /// The content to reveal.
  final Widget child;

  /// Animation duration. Defaults to the theme's mid duration.
  final Duration? duration;

  /// Animation curve. Defaults to the theme's in-out ease.
  final Curve? curve;

  /// Removes the child from the tree once fully collapsed (after the close
  /// animation), instead of keeping it mounted at zero height.
  final bool destroyWhenCollapsed;

  /// Starts shut and opens, even when [expanded] is already set on the first
  /// build.
  ///
  /// For callers that add the widget at the moment the thing opens — a
  /// `Table` panel appears only once its row is opened, so without this it
  /// would arrive at full height with no reveal at all. Callers that mount
  /// every panel up front (`Collapse`, `Tree`) want the default: a panel
  /// already open when the page is built should not animate itself in.
  final bool animateOnMount;

  @override
  State<Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<Expandable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.expanded && !widget.animateOnMount ? 1 : 0,
    duration: widget.duration ?? _fallbackDuration,
  )..addStatusListener((_) {
      // Re-evaluate whether the child should stay mounted once the animation
      // settles (so a destroyed subtree drops after the close finishes).
      if (mounted) setState(() {});
    });

  // Used only until the first build reads the theme; the real duration is
  // applied in build/didUpdateWidget.
  static const _fallbackDuration = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    if (widget.expanded && widget.animateOnMount) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(Expandable old) {
    super.didUpdateWidget(old);
    if (old.expanded != widget.expanded) {
      _controller.animateTo(widget.expanded ? 1 : 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _mounted =>
      widget.expanded ||
      _controller.isAnimating ||
      !widget.destroyWhenCollapsed;

  static const _empty = SizedBox(width: double.infinity, height: 0);

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    _controller.duration = widget.duration ?? t.motionDurationMid;
    final curve = widget.curve ?? t.motionEaseInOut;

    if (!_mounted) return _empty;

    final animation = CurvedAnimation(parent: _controller, curve: curve);
    // The width is read once per layout rather than per tick, and handed to
    // the reveal: `Align` passes loose constraints, so a child that hugs its
    // content — a line of text, a row of buttons — came out narrow and
    // centred for the length of the animation and then snapped to full width
    // and the leading edge on the last frame. Measured, a panel's text sat at
    // 328.8 and 142.5 wide throughout the reveal, then jumped to 116 and 568.
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: animation,
        // Built once and reused across frames, not rebuilt per tick.
        child: widget.child,
        builder: (context, child) {
          final factor = animation.value.clamp(0.0, 1.0);
          if (factor >= 1) return child!;
          return ClipRect(
            child: Align(
              // Start, not centre: this is a reveal down the page, and
              // nothing about it should move the content sideways.
              alignment: AlignmentDirectional.topStart,
              heightFactor: factor,
              child: constraints.hasBoundedWidth
                  ? SizedBox(width: constraints.maxWidth, child: child)
                  : child,
            ),
          );
        },
      ),
    );
  }
}
