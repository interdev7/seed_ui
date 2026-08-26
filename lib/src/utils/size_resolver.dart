import 'dart:math' as math;
import '../theme/design_token.dart';

/// Turns a [ControlSize] — a preset or an explicit measurement — into the
/// concrete pixel dimensions a component lays itself out with.
extension ControlSizeResolver on ControlSize {
  /// Resolves the control size into a 1-dimensional length (e.g. diameter,
  /// height, or max dimension), using the provided preset values.
  double resolve1D({
    required double small,
    required double middle,
    required double large,
  }) {
    final size = this;
    if (size is SoftSize) {
      return switch (size) {
        SoftSize.small => small,
        SoftSize.middle => middle,
        SoftSize.large => large,
      };
    }
    if (size is ExplicitSquareSize) {
      return size.dimension;
    }
    if (size is ExplicitSize) {
      return math.max(size.width, size.height);
    }
    return middle;
  }

  /// Resolves the control size into a height, using the provided presets.
  ///
  /// Unlike [resolve1D], a two-dimensional size gives its **height** rather
  /// than its larger side: a field asked for 200 by 36 is 36 tall and 200
  /// wide, not 200 tall.
  double resolveHeight({
    required double small,
    required double middle,
    required double large,
  }) {
    final size = this;
    if (size is ExplicitSize) return size.height;
    return resolve1D(small: small, middle: middle, large: large);
  }

  /// The width a two-dimensional size names, or null when it names none.
  ///
  /// A preset and a bare dimension say nothing about width, so a control that
  /// sizes its own is left to do so.
  double? get explicitWidth {
    final size = this;
    return size is ExplicitSize ? size.width : null;
  }
}
