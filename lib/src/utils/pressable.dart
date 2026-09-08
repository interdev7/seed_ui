import 'package:flutter/widgets.dart';

import '../theme/config_provider.dart';

/// A small thing that answers a press — a close cross, a link, a step's dot.
///
/// The kit's [Button] carries its own focus and its own halo. Everything
/// smaller than a button was a bare gesture detector, and there are enough of
/// them that writing the same fifteen lines at each would guarantee they drift
/// apart. This is those fifteen lines, once: a stop in the tab order, `Space`
/// and `Enter`, a ring while the keyboard is on it, and the semantics to say
/// it is a button at all.
///
/// The ring is drawn *over* the child rather than around it, so a target
/// sitting tight against its neighbours — the cross in a tag, the actions in a
/// notification — does not grow when it takes the focus and shove them along.
class Pressable extends StatefulWidget {
  /// Creates a [Pressable].
  const Pressable({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticsLabel,
    this.radius,
    this.enabled = true,
  });

  /// What the press does. A null one is not a stop on the way round: tabbing
  /// should not pause on what does nothing.
  final VoidCallback? onPressed;

  /// What is pressed.
  final Widget child;

  /// What a screen reader calls it, for a target drawn as a glyph — a cross
  /// says nothing out loud.
  final String? semanticsLabel;

  /// The corners the ring follows. Square where it is not given.
  final double? radius;

  /// Whether the press is offered at all.
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  /// Whether the focus should be seen: only where it arrived by keyboard. A
  /// target clicked with a mouse is focused too, and a ring around that is
  /// noise.
  bool _focusVisible = false;

  bool get _live => widget.enabled && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    return FocusableActionDetector(
      enabled: _live,
      onShowFocusHighlight: (visible) {
        if (_focusVisible != visible) setState(() => _focusVisible = visible);
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        enabled: _live,
        label: widget.semanticsLabel,
        onTap: _live ? widget.onPressed : null,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: _focusVisible
                ? Border.all(
                    color: token.primary.base,
                    width: token.lineWidth,
                  )
                : null,
            borderRadius: widget.radius == null
                ? null
                : BorderRadius.circular(widget.radius!),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
