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
}
