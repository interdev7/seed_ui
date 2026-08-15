import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';

/// Which illustration an [Empty] draws.
enum EmptyImage {
  /// The standard empty-state drawing.
  standard,

  /// A smaller, simpler outline.
  simple,
}

/// Per-component design tokens for [Empty].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [EmptyToken(...)])`, or per instance via [Empty.token].
@immutable
class EmptyToken {
  /// Creates an [EmptyToken].
  const EmptyToken({
    this.imageHeight,
    this.colorTextDescription,
    this.fontSize,
  });

  /// Height of the illustration (`imageHeight`).
  final double? imageHeight;

  /// Description text color (`colorTextDescription`).
  final Color? colorTextDescription;

  /// Description font size (`fontSize`).
  final double? fontSize;

  _ResolvedEmptyToken _resolve(Token t) => _ResolvedEmptyToken(
        imageHeight: imageHeight ?? 41,
        colorTextDescription: colorTextDescription ?? t.colorTextTertiary,
        fontSize: fontSize ?? t.fontSize,
      );
}

@immutable
class _ResolvedEmptyToken {
  const _ResolvedEmptyToken({
    required this.imageHeight,
    required this.colorTextDescription,
    required this.fontSize,
  });

  final double imageHeight;
  final Color colorTextDescription;
  final double fontSize;
}

/// An empty-state placeholder. Shows an illustration,
/// a description and optional actions when there is nothing to display.
///
/// It is the default content the kit shows for "no data" states (for example a
/// [Select] with no matching options). Override that globally with
/// [ConfigProvider]'s `renderEmpty`, or per component with its own
/// `notFoundContent`.
///
/// ```dart
/// Empty(
///   description: const Text('No results'),
///   child: Button(onPressed: create, child: const Text('Create')),
/// )
/// ```
class Empty extends StatelessWidget {
  /// Creates an [Empty].
  const Empty({
    super.key,
    this.image = EmptyImage.standard,
    this.imageWidget,
    this.description,
    this.child,
    this.token,
  });

  /// Which built-in illustration to draw. Ignored when [imageWidget] is set.
  final EmptyImage image;

  /// A custom illustration, replacing the built-in one.
  final Widget? imageWidget;

  /// Text under the illustration. Null shows the default "No data"; pass
  /// `SizedBox.shrink()` to hide it entirely.
  final Widget? description;

  /// Optional actions below the description, such as a create button.
  final Widget? child;

  /// Per-instance token overrides.
  final EmptyToken? token;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (token ??
            ConfigProvider.componentOf<EmptyToken>(context) ??
            const EmptyToken())
        ._resolve(t);
    final simple = image == EmptyImage.simple;
    final art = imageWidget ??
        CustomPaint(
          size: Size(64, r.imageHeight),
          painter: _EmptyPainter(token: t, simple: simple),
        );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: t.size),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          art,
          SizedBox(height: t.sizeXS),
          DefaultTextStyle.merge(
            style: TextStyle(
              color: r.colorTextDescription,
              fontSize: r.fontSize,
              fontFamily: t.fontFamily,
              fontFamilyFallback: t.fontFamilyFallback,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
            child: description ?? const Text('No data'),
          ),
          if (child != null) ...[
            SizedBox(height: t.size),
            child!,
          ],
        ],
      ),
    );
  }
}

/// Draws the empty-state illustration: an ellipse "shadow" under a simple
/// outlined container, echoing the default and simple images.
class _EmptyPainter extends CustomPainter {
  _EmptyPainter({required this.token, required this.simple});

  final Token token;
  final bool simple;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke =
        token.isDark ? const Color(0xFF434343) : const Color(0xFFD9D9D9);
    final fill =
        token.isDark ? const Color(0xFF1F1F1F) : const Color(0xFFFAFAFA);
    final shadow =
        token.isDark ? const Color(0xFF303030) : const Color(0xFFF5F5F5);

    // Ground shadow.
    canvas.drawOval(
      Rect.fromLTWH(w * 0.12, h * 0.82, w * 0.76, h * 0.16),
      Paint()..color = shadow,
    );

    final line = Paint()
      ..color = stroke
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final area = Paint()..color = fill;

    if (simple) {
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.18, w * 0.6, h * 0.5),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, area);
      canvas.drawRRect(rrect, line);
      return;
    }

    // A simple open box/tray: a trapezoid lid over a rounded body.
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.34, w * 0.68, h * 0.42),
      const Radius.circular(5),
    );
    canvas.drawRRect(body, area);
    canvas.drawRRect(body, line);

    final lid = Path()
      ..moveTo(w * 0.16, h * 0.42)
      ..lineTo(w * 0.3, h * 0.16)
      ..lineTo(w * 0.7, h * 0.16)
      ..lineTo(w * 0.84, h * 0.42);
    canvas.drawPath(lid, line);
    canvas.drawLine(Offset(w * 0.4, h * 0.42), Offset(w * 0.6, h * 0.42), line);
  }

  @override
  bool shouldRepaint(_EmptyPainter old) =>
      old.token != token || old.simple != simple;
}
