import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Derives a ten-shade palette from a single base color.
///
/// Index 0 is the lightest shade and index 9 the darkest; index 5 is always
/// the base color itself. Shades are produced by walking hue, saturation and
/// value in fixed steps, which keeps every generated palette internally
/// consistent regardless of the input color.
const int _hueStep = 2;
const double _saturationStep = 0.16;
const double _saturationStep2 = 0.05;
const double _brightnessStep1 = 0.05;
const double _brightnessStep2 = 0.15;
const int _lightColorCount = 5;
const int _darkColorCount = 4;

/// Recipe for the dark palette: each entry is a (shade index, blend percent)
/// pair describing how much of that shade to mix into the page background.
const List<List<int>> _darkColorMap = [
  [7, 15],
  [6, 25],
  [5, 30],
  [5, 45],
  [5, 65],
  [5, 85],
  [4, 90],
  [3, 95],
  [2, 97],
  [1, 98],
];

class _Hsv {
  const _Hsv(this.h, this.s, this.v);
  final double h;
  final double s;
  final double v;
}

_Hsv _toHsv(Color color) {
  final hsl = HSVColor.fromColor(color);
  return _Hsv(hsl.hue, hsl.saturation, hsl.value);
}

Color _fromHsv(_Hsv hsv) =>
    HSVColor.fromAHSV(1, hsv.h % 360, hsv.s.clamp(0, 1), hsv.v.clamp(0, 1))
        .toColor();

double _getHue(_Hsv hsv, int i, {required bool light}) {
  // Warm hues rotate one way and cool hues the other, so lighter shades stay
  // perceptually adjacent to the base instead of drifting across the wheel.
  final double hue = hsv.h >= 60 && hsv.h <= 240
      ? (light ? hsv.h - _hueStep * i : hsv.h + _hueStep * i)
      : (light ? hsv.h + _hueStep * i : hsv.h - _hueStep * i);
  var result = hue % 360;
  if (result < 0) result += 360;
  return result;
}

double _getSaturation(_Hsv hsv, int i, {required bool light}) {
  if (hsv.h == 0 && hsv.s == 0) return hsv.s; // greys must stay grey
  double saturation;
  if (light) {
    saturation = hsv.s - _saturationStep * i;
  } else if (i == _darkColorCount) {
    saturation = hsv.s + _saturationStep;
  } else {
    saturation = hsv.s + _saturationStep2 * i;
  }
  if (light && i == _lightColorCount && saturation > 0.1) saturation = 0.1;
  if (saturation < 0.06) saturation = 0.06;
  return double.parse(saturation.clamp(0.0, 1.0).toStringAsFixed(2));
}

double _getValue(_Hsv hsv, int i, {required bool light}) {
  final double value =
      light ? hsv.v + _brightnessStep1 * i : hsv.v - _brightnessStep2 * i;
  return double.parse(value.clamp(0.0, 1.0).toStringAsFixed(2));
}

/// Builds the ten shades of [color].
///
/// `generate(color)[5]` is [color] itself. When [dark] is true the shades are
/// blended into [background] (defaulting to a near-black surface) so they read
/// correctly on a dark page.
List<Color> generate(Color color, {bool dark = false, Color? background}) {
  final patterns = <Color>[];

  for (var i = _lightColorCount; i > 0; i -= 1) {
    final hsv = _toHsv(color);
    patterns.add(
      _fromHsv(
        _Hsv(
          _getHue(hsv, i, light: true),
          _getSaturation(hsv, i, light: true),
          _getValue(hsv, i, light: true),
        ),
      ),
    );
  }
  patterns.add(color);
  for (var i = 1; i <= _darkColorCount; i += 1) {
    final hsv = _toHsv(color);
    patterns.add(
      _fromHsv(
        _Hsv(
          _getHue(hsv, i, light: false),
          _getSaturation(hsv, i, light: false),
          _getValue(hsv, i, light: false),
        ),
      ),
    );
  }

  if (!dark) return patterns;

  final bg = background ?? const Color(0xFF141414);
  return [
    for (final map in _darkColorMap)
      Color.lerp(bg, patterns[map[0] - 1], map[1] / 100)!,
  ];
}

/// The ink to write on a [fill]: black or white, whichever reads on it.
///
/// Worked out rather than asked for, so a brand colour the kit has never seen
/// gets legible words without anybody saying so. White on the default blue;
/// black on a yellow, a lime or a pale pink, where white would be a smear.
///
/// The rule is Flutter's own — the threshold `ThemeData.estimateBrightnessForColor`
/// uses — rather than a bare contrast ratio. Contrast alone puts black on the
/// default blue, which is legible arithmetic and not what anyone draws: at
/// mid luminance the two inks score alike, and the tie has to be broken the
/// way the eye breaks it.
///
/// The dark ink is a shade off true black: black at full strength on a
/// coloured fill reads as a hole.
///
/// ```dart
/// Container(
///   color: brand,
///   child: Text('Pay', style: TextStyle(color: inkOn(brand))),
/// )
/// ```
Color inkOn(Color fill) {
  final luminance = _relativeLuminance(fill);
  final measure = (luminance + 0.05) * (luminance + 0.05);
  return measure > 0.15 ? _inkDark : _inkLight;
}

/// The dark ink, a shade off true black.
const Color _inkDark = Color(0xFF141414);

/// The light ink.
const Color _inkLight = Color(0xFFFFFFFF);

/// Relative luminance, per WCAG 2.1.
double _relativeLuminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// Applies [opacity] to [color], clamped to a valid alpha.
Color alphaOn(Color color, double opacity) =>
    color.withValues(alpha: math.min(1, opacity));
