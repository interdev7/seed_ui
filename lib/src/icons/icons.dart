import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/widgets.dart';

import '../components/feedback/message.dart' show StatusType;
import '../theme/design_token.dart';

/// Status glyph drawn as a filled circle, or a spinner for
/// [StatusType.loading]. Shared by message, notification, alert, modal,
/// result and progress.
class StatusIcon extends StatelessWidget {
  /// Creates a [StatusIcon].
  const StatusIcon({super.key, required this.type, required this.token});

  /// Which status to draw.
  final StatusType type;

  /// Tokens supplying the status colors and the glyph size.
  final Token token;

  @override
  Widget build(BuildContext context) {
    final size = token.fontSizeLG;
    if (type == StatusType.loading) {
      return Spinner(size: size, color: token.primary.base);
    }
    return CustomPaint(
      size: Size.square(size),
      painter: StatusIconPainter(type: type, token: token),
    );
  }
}

/// Paints a filled status disc with a white glyph.
class StatusIconPainter extends CustomPainter {
  /// Creates a [StatusIconPainter].
  StatusIconPainter({required this.type, required this.token});

  /// Which status disc to paint, and so which colour and glyph.
  final StatusType type;

  /// The resolved theme the status colours are read from.
  final Token token;

  Color get _color => switch (type) {
        StatusType.success => token.success.base,
        StatusType.error => token.error.base,
        StatusType.warning => token.warning.base,
        _ => token.info.base,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    canvas.drawCircle(center, r, Paint()..color = _color);

    final stroke = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = math.max(1.4, size.width * 0.09)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (type) {
      case StatusType.success:
        canvas.drawPath(
          Path()
            ..moveTo(size.width * 0.28, size.height * 0.52)
            ..lineTo(size.width * 0.44, size.height * 0.68)
            ..lineTo(size.width * 0.73, size.height * 0.35),
          stroke,
        );
      case StatusType.error:
        canvas.drawLine(
          Offset(size.width * 0.32, size.height * 0.32),
          Offset(size.width * 0.68, size.height * 0.68),
          stroke,
        );
        canvas.drawLine(
          Offset(size.width * 0.68, size.height * 0.32),
          Offset(size.width * 0.32, size.height * 0.68),
          stroke,
        );
      default:
        // Warning and info are a bar plus a dot; only their order differs,
        // giving '!' and 'i' respectively.
        final isInfo = type == StatusType.info;
        final barTop = isInfo ? size.height * 0.45 : size.height * 0.26;
        final barBottom = isInfo ? size.height * 0.72 : size.height * 0.56;
        final dotY = isInfo ? size.height * 0.3 : size.height * 0.72;
        canvas.drawLine(Offset(r, barTop), Offset(r, barBottom), stroke);
        canvas.drawPoints(
          PointMode.points,
          [Offset(r, dotY)],
          stroke..strokeWidth = math.max(1.8, size.width * 0.13),
        );
    }
  }

  @override
  bool shouldRepaint(StatusIconPainter old) =>
      old.type != type || old.token != token;
}

/// A tick (or a dash, when [indeterminate]) sized to the paint box. Used by the
/// checkbox and progress. Give the [CustomPaint] the size you want.
class CheckPainter extends CustomPainter {
  /// Creates a [CheckPainter].
  CheckPainter({
    required this.color,
    this.checked = true,
    this.indeterminate = false,
    this.strokeWidth,
  });

  /// Colour of the glyph.
  final Color color;

  /// Whether to draw the tick. Ignored when [indeterminate].
  final bool checked;

  /// Draw a centre dash instead of a tick.
  final bool indeterminate;

  /// Stroke width; defaults to a size-relative value.
  final double? strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = strokeWidth ?? math.max(1.6, size.width * 0.12);
    final paint = Paint()
      ..color = color
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (indeterminate) {
      canvas.drawLine(
        Offset(size.width * 0.28, size.height / 2),
        Offset(size.width * 0.72, size.height / 2),
        paint,
      );
      return;
    }
    if (!checked) return;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.24, size.height * 0.52)
        ..lineTo(size.width * 0.42, size.height * 0.70)
        ..lineTo(size.width * 0.76, size.height * 0.32),
      paint,
    );
  }

  @override
  bool shouldRepaint(CheckPainter old) =>
      old.color != color ||
      old.checked != checked ||
      old.indeterminate != indeterminate ||
      old.strokeWidth != strokeWidth;
}

/// The close cross ("×"), sized to the paint box. Shared by the dismiss buttons
/// of notification, modal, drawer and alert.
class CrossPainter extends CustomPainter {
  /// Creates a [CrossPainter].
  CrossPainter(this.color, {this.strokeWidth = 1.2, this.inset = 7});

  /// The stroke colour.
  final Color color;

  /// Stroke thickness, in logical pixels.
  final double strokeWidth;

  /// Distance from each edge to the stroke, in logical pixels.
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(inset, inset),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(CrossPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.inset != inset;
}

/// A chevron ("›"), sized to the paint box and pointing right. Rotate it to
/// repoint (the Collapse expand icon turns it a quarter-turn when open).
class ChevronPainter extends CustomPainter {
  /// Creates a [ChevronPainter].
  ChevronPainter(this.color, {this.strokeWidth = 1.4});

  /// The stroke colour.
  final Color color;

  /// Stroke thickness, in logical pixels.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.36, size.height * 0.22)
        ..lineTo(size.width * 0.68, size.height * 0.5)
        ..lineTo(size.width * 0.36, size.height * 0.78),
      paint,
    );
  }

  @override
  bool shouldRepaint(ChevronPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// A drag-handle grip — two columns of three dots, sized to the paint box.
/// Marks a draggable row.
class HolderPainter extends CustomPainter {
  /// Creates a [HolderPainter].
  HolderPainter(this.color);

  /// The colour of the six dots.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final r = size.width * 0.09;
    final xs = [size.width * 0.32, size.width * 0.68];
    final ys = [size.height * 0.24, size.height * 0.5, size.height * 0.76];
    for (final x in xs) {
      for (final y in ys) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(HolderPainter old) => old.color != color;
}

/// An indeterminate circular progress indicator.
///
/// Spins continuously, so a widget test containing one can never settle — use
/// explicit `pump` calls rather than `pumpAndSettle`.
class Spinner extends StatefulWidget {
  /// Creates a [Spinner].
  const Spinner({super.key, required this.size, required this.color});

  /// Width and height of the indicator, in logical pixels.
  final double size;

  /// Colour of the rotating arc. The track behind it uses the same colour at
  /// reduced opacity.
  final Color color;

  @override
  State<Spinner> createState() => _SoftSpinnerState();
}

class _SoftSpinnerState extends State<Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _SpinnerPainter(widget.color),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.12;
    final rect = Offset.zero & size;

    canvas.drawArc(
      rect.deflate(paint.strokeWidth / 2),
      0,
      math.pi * 2,
      false,
      paint..color = color.withValues(alpha: 0.2),
    );
    canvas.drawArc(
      rect.deflate(paint.strokeWidth / 2),
      -math.pi / 2,
      math.pi * 1.2,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) => old.color != color;
}

/// Draws a dashed rounded-rect border, which [BoxDecoration] cannot. Used by
/// the dashed button variant.
class DashedBorderPainter extends CustomPainter {
  /// Creates a [DashedBorderPainter].
  DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    this.dash = 4,
    this.gap = 3,
  });

  /// The stroke colour of the dashes.
  final Color color;

  /// Corner rounding the dashed outline follows.
  final BorderRadius radius;

  /// Stroke thickness, in logical pixels.
  final double strokeWidth;

  /// Length of each dash, in logical pixels.
  final double dash;

  /// Empty space between dashes, in logical pixels.
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = radius.toRRect(Offset.zero & size).deflate(strokeWidth / 2);
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}

/// A circular filled icon with a cross inside, commonly used for clear buttons.
class ClearIconPainter extends CustomPainter {
  /// Creates a [ClearIconPainter].
  ClearIconPainter(this.color);

  /// The fill colour of the disc.
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    canvas.drawCircle(Offset(r, r), r, Paint()..color = color);
    final stroke = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.34),
      Offset(size.width * 0.66, size.height * 0.66),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.66, size.height * 0.34),
      Offset(size.width * 0.34, size.height * 0.66),
      stroke,
    );
  }

  @override
  bool shouldRepaint(ClearIconPainter old) => old.color != color;
}

/// A simple search magnifying glass icon.
class SearchIconPainter extends CustomPainter {
  /// Creates a [SearchIconPainter].
  SearchIconPainter(this.color);

  /// The stroke colour of the glass.
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(const Offset(6, 6), 4.5, paint);
    canvas.drawLine(const Offset(9.5, 9.5), const Offset(13, 13), paint);
  }

  @override
  bool shouldRepaint(SearchIconPainter old) => old.color != color;
}

/// A fixed-size search magnifier, ready to drop into a row.
class SearchIcon extends StatelessWidget {
  /// Creates a [SearchIcon].
  const SearchIcon({super.key, required this.color});

  /// The stroke colour of the glass.
  final Color color;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(14, 14),
      painter: SearchIconPainter(color),
    );
  }
}

/// A document icon representing a leaf node in a Tree.
class TreeLeafIconPainter extends CustomPainter {
  /// Creates a [TreeLeafIconPainter].
  TreeLeafIconPainter(this.color);

  /// The fill colour of the document glyph.
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..moveTo(3, 1)
      ..lineTo(9, 1)
      ..lineTo(13, 5)
      ..lineTo(13, 15)
      ..lineTo(3, 15)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(const Offset(9, 1), const Offset(9, 5), paint);
    canvas.drawLine(const Offset(9, 5), const Offset(13, 5), paint);
  }

  @override
  bool shouldRepaint(TreeLeafIconPainter old) => old.color != color;
}

/// Paints a head-and-shoulders silhouette — the fallback glyph for an avatar
/// with no image or text.
class UserIconPainter extends CustomPainter {
  /// Creates a [UserIconPainter].
  UserIconPainter(this.color);

  /// The fill colour of the silhouette.
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final r = size.width / 2;
    canvas.drawCircle(Offset(r, r * 0.7), r * 0.4, paint);
    final path = Path()
      ..moveTo(r * 0.2, size.height)
      ..quadraticBezierTo(r * 0.2, r * 1.3, r, r * 1.3)
      ..quadraticBezierTo(r * 1.8, r * 1.3, r * 1.8, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(UserIconPainter old) => old.color != color;
}

/// A fixed-size user silhouette, ready to drop into an avatar.
class UserIcon extends StatelessWidget {
  /// Creates a [UserIcon].
  const UserIcon(
      {super.key, this.color = const Color(0xFFFFFFFF), this.size = 14});

  /// The fill colour of the silhouette.
  final Color color;

  /// The side length of the square the glyph is painted into.
  final double size;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: UserIconPainter(color),
    );
  }
}

/// A plus sign, sized to its paint box.
class PlusPainter extends CustomPainter {
  /// Creates a [PlusPainter].
  PlusPainter(this.color);

  /// The stroke colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(1.4, size.width * 0.07)
      ..strokeCap = StrokeCap.round;
    final c = size.center(Offset.zero);
    final r = size.width * 0.3;
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), paint);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), paint);
  }

  @override
  bool shouldRepaint(PlusPainter old) => old.color != color;
}

/// A paperclip — the mark a plain file row carries in place of a preview.
///
/// Drawn rather than imported: an SVG would mean a parser, and a font would
/// mean an asset. Two strokes and two arcs read as a clip at sixteen pixels,
/// which is the only size this is used at.
class PaperclipPainter extends CustomPainter {
  /// Creates a [PaperclipPainter].
  PaperclipPainter(this.color);

  /// The stroke colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(1.2, w * 0.09)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Down the inner side, round the bottom, back up, then over the top and
    // down the outer side — the path a clip's wire actually takes.
    final path = Path()
      ..moveTo(w * 0.64, h * 0.34)
      ..lineTo(w * 0.64, h * 0.70)
      ..arcToPoint(
        Offset(w * 0.36, h * 0.70),
        radius: Radius.circular(w * 0.14),
      )
      ..lineTo(w * 0.36, h * 0.30)
      ..arcToPoint(
        Offset(w * 0.78, h * 0.30),
        radius: Radius.circular(w * 0.21),
      )
      ..lineTo(w * 0.78, h * 0.64);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(PaperclipPainter old) => old.color != color;
}

/// A downward arrow onto a baseline — download.
class DownloadPainter extends CustomPainter {
  /// Creates a [DownloadPainter].
  DownloadPainter(this.color);

  /// The stroke colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final c = size.center(Offset.zero);
    final h = size.height * 0.3;
    canvas.drawLine(
        Offset(c.dx, c.dy - h), Offset(c.dx, c.dy + h * 0.4), paint);
    canvas.drawLine(
      Offset(c.dx - h * 0.5, c.dy - h * 0.1),
      Offset(c.dx, c.dy + h * 0.4),
      paint,
    );
    canvas.drawLine(
      Offset(c.dx + h * 0.5, c.dy - h * 0.1),
      Offset(c.dx, c.dy + h * 0.4),
      paint,
    );
    canvas.drawLine(
      Offset(c.dx - h * 0.7, c.dy + h),
      Offset(c.dx + h * 0.7, c.dy + h),
      paint,
    );
  }

  @override
  bool shouldRepaint(DownloadPainter old) => old.color != color;
}

/// A circular arrow — retry.
class RetryPainter extends CustomPainter {
  /// Creates a [RetryPainter].
  RetryPainter(this.color);

  /// The stroke colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final c = size.center(Offset.zero);
    final radius = size.width * 0.28;
    // An arc left open at the top right, with an arrowhead closing it, so the
    // glyph reads as a loop rather than a full circle.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: radius),
      -0.6,
      5.2,
      false,
      paint,
    );
    final tip = Offset(c.dx + radius, c.dy - radius * 0.55);
    canvas.drawLine(tip, tip.translate(-radius * 0.5, 0.2), paint);
    canvas.drawLine(tip, tip.translate(0.2, radius * 0.5), paint);
  }

  @override
  bool shouldRepaint(RetryPainter old) => old.color != color;
}
