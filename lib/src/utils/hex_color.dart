import 'dart:ui' show Color;

/// Reads a CSS-style hex string into a [Color].
///
/// Accepts `#rgb`, `#rgba`, `#rrggbb` and `#rrggbbaa`, with or without the
/// leading `#`, in either case. A string with no alpha is fully opaque.
///
/// ```dart
/// parseHexColor('#fff')       // opaque white
/// parseHexColor('1677ff')     // the kit's blue
/// parseHexColor('#ff000080')  // half-transparent red
/// ```
///
/// **Alpha goes last**, as CSS writes it — not first, as `Color(0xAARRGGBB)`
/// does. The two orders look alike and mean different things, so a string is
/// read the way a string is normally written, and an `int` you already have
/// stays an `int`: pass `Color(0xFF1677FF)` rather than a string for that.
///
/// Throws [FormatException] on anything else, naming what it got — a colour
/// that silently came out black would be found much later, on screen.
Color parseHexColor(String value) {
  final digits = value.startsWith('#') ? value.substring(1) : value;

  if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(digits)) {
    throw FormatException(
      'Not a hex colour: "$value". Expected #rgb, #rgba, #rrggbb or '
      '#rrggbbaa.',
      value,
    );
  }

  // The short forms double each digit: #1a2 is #11aa22.
  final full = switch (digits.length) {
    3 || 4 => digits.split('').map((d) => '$d$d').join(),
    6 || 8 => digits,
    _ => throw FormatException(
        'A hex colour has 3, 4, 6 or 8 digits; "$value" has '
        '${digits.length}.',
        value,
      ),
  };

  // Move the alpha from the end, where CSS puts it, to the front, where
  // Color wants it.
  final rgb = full.substring(0, 6);
  final alpha = full.length == 8 ? full.substring(6, 8) : 'ff';
  return Color(int.parse('$alpha$rgb', radix: 16));
}
