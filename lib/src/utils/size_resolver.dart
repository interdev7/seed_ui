import 'dart:math' as math;
import '../theme/design_token.dart';

/// Turns a [ControlSize] — a preset or an explicit measurement — into the
/// concrete pixel dimensions a component lays itself out with.
extension ControlSizeResolver on ControlSize {
  /// Resolves the control size into a 1-dimensional length (e.g. diameter,
  /// height, or max dimension), using the provided preset values.
  ///
  /// A circle has one measurement, so either bare number names it: a width of
  /// 60 and a height of 60 are the same 60-wide circle.
  double resolve1D({
    required double small,
    required double middle,
    required double large,
  }) =>
      switch (this) {
        SoftSize.small => small,
        SoftSize.middle => middle,
        SoftSize.large => large,
        ExplicitHeight(:final height) => height,
        ExplicitWidth(:final width) => width,
        ExplicitBox(:final width, :final height) => math.max(width, height),
      };

  /// Resolves the control size into a height, using the provided presets.
  ///
  /// Unlike [resolve1D], a two-dimensional size gives its **height** rather
  /// than its larger side: a field asked for 200 by 36 is 36 tall and 200
  /// wide, not 200 tall. A width-only size names no height at all, so it
  /// takes the standard preset and spends its number on [explicitWidth].
  double resolveHeight({
    required double small,
    required double middle,
    required double large,
  }) =>
      switch (this) {
        ExplicitBox(:final height) => height,
        ExplicitWidth() => middle,
        _ => resolve1D(small: small, middle: middle, large: large),
      };

  /// The width this size names, or null when it names none.
  ///
  /// A preset and a bare height say nothing about width, so a control that
  /// sizes its own is left to do so.
  double? get explicitWidth => switch (this) {
        ExplicitWidth(:final width) => width,
        ExplicitBox(:final width) => width,
        _ => null,
      };
}
