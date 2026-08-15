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

  @override
  State<Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<Expandable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.expanded ? 1 : 0,
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
    return AnimatedBuilder(
      animation: animation,
      // The child is built once and reused across frames, not rebuilt per tick.
      child: widget.child,
      builder: (context, child) {
        final factor = animation.value.clamp(0.0, 1.0);
        if (factor >= 1) return child!;
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: factor,
            child: child,
          ),
        );
      },
    );
  }
}
