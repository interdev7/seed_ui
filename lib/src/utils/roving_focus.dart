import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Which way a step goes along a run of choices.
enum RovingStep {
  /// Towards the option before this one.
  back,

  /// Towards the option after it.
  on,

  /// To the first that can be chosen.
  first,

  /// To the last that can be chosen.
  last,
}

/// Makes a run of choices — a segmented control, a bar of tabs, a row of
/// pages — one stop in the tab order, moved along with the arrow keys.
///
/// One stop, not one per option: a bar of fourteen tabs that took fourteen
/// tabs to walk past is a bar nobody walks past. Inside it the arrows do the
/// moving, which is what a reader expects of anything laid out in a row.
///
/// The arrows are read by the direction of the run and by the direction of
/// the words: along a row that reads right to left, the key pointing left
/// steps *on*, since that is where the next option is.
class RovingGroup extends StatelessWidget {
  /// Creates a [RovingGroup].
  const RovingGroup({
    super.key,
    required this.direction,
    required this.onStep,
    required this.child,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.onFocusVisible,
  });

  /// Which way the run is laid out.
  final Axis direction;

  /// Called with the step the key asked for.
  final ValueChanged<RovingStep> onStep;

  /// A focus node of your own; left null the group keeps one.
  final FocusNode? focusNode;

  /// Whether the group takes focus as soon as it is built.
  final bool autofocus;

  /// Whether the group is a stop at all: one that can choose nothing is not.
  final bool enabled;

  /// Told when the focus should be *seen* — that is, when it arrived by
  /// keyboard rather than by a tap.
  final ValueChanged<bool>? onFocusVisible;

  /// The run itself.
  final Widget child;

  Map<ShortcutActivator, Intent> _shortcuts(BuildContext context) {
    final ltr = Directionality.maybeOf(context) != TextDirection.rtl;
    final back = direction == Axis.vertical
        ? LogicalKeyboardKey.arrowUp
        : (ltr ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight);
    final on = direction == Axis.vertical
        ? LogicalKeyboardKey.arrowDown
        : (ltr ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft);
    return {
      SingleActivator(back): const _RovingIntent(RovingStep.back),
      SingleActivator(on): const _RovingIntent(RovingStep.on),
      const SingleActivator(LogicalKeyboardKey.home):
          const _RovingIntent(RovingStep.first),
      const SingleActivator(LogicalKeyboardKey.end):
          const _RovingIntent(RovingStep.last),
    };
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      onShowFocusHighlight: onFocusVisible,
      shortcuts: _shortcuts(context),
      actions: <Type, Action<Intent>>{
        _RovingIntent: CallbackAction<_RovingIntent>(
          onInvoke: (intent) {
            onStep(intent.step);
            return null;
          },
        ),
      },
      // Explicit children: the group is a stop for the keyboard, not a
      // thing with a name of its own. Left to itself its node would stand
      // over the options and take the reading of whichever of them spoke.
      child: Semantics(explicitChildNodes: true, child: child),
    );
  }
}

/// What an arrow key means inside a [RovingGroup].
@immutable
class _RovingIntent extends Intent {
  const _RovingIntent(this.step);

  final RovingStep step;
}

/// The index a [RovingStep] lands on, skipping what cannot be chosen.
///
/// Returns null where there is nowhere to go: at the end of a run the
/// selection stays where it is rather than wrapping round, so holding an
/// arrow down does not cycle for ever past the last option.
int? rovingTarget({
  required RovingStep step,
  required int from,
  required int count,
  required bool Function(int index) selectable,
}) {
  if (count == 0) return null;
  int? scan(int start, int delta) {
    for (var i = start; i >= 0 && i < count; i += delta) {
      if (selectable(i)) return i;
    }
    return null;
  }

  return switch (step) {
    RovingStep.back => scan(from - 1, -1),
    RovingStep.on => scan(from + 1, 1),
    RovingStep.first => scan(0, 1),
    RovingStep.last => scan(count - 1, -1),
  };
}
