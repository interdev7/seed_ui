import 'dart:ui' show PointMode;

import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import 'message.dart' show StatusType;

/// Per-component design tokens for [Result].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(result: ResultToken(...)))`,
/// or per instance via [Result.token].
@immutable
class ResultToken {
  /// Creates a [ResultToken].
  const ResultToken({
    this.titleFontSize,
    this.subtitleFontSize,
    this.iconSize,
    this.padding,
  });

  /// Title font size (`titleFontSize`).
  final double? titleFontSize;

  /// Subtitle font size (`subtitleFontSize`).
  final double? subtitleFontSize;

  /// Icon size (`iconSize`).
  final double? iconSize;

  /// Container padding (`padding`).
  final EdgeInsets? padding;

  _ResolvedResultToken _resolve(Token t) => _ResolvedResultToken(
        titleFontSize: titleFontSize ?? t.fontSizeXL + 4,
        subtitleFontSize: subtitleFontSize ?? t.fontSize,
        iconSize: iconSize ?? 72,
        padding: padding ??
            EdgeInsets.symmetric(horizontal: t.sizeLG, vertical: t.sizeXL),
      );
}

@immutable
class _ResolvedResultToken {
  const _ResolvedResultToken({
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.iconSize,
    required this.padding,
  });

  final double titleFontSize;
  final double subtitleFontSize;
  final double iconSize;
  final EdgeInsets padding;
}

/// A full-width status page for the outcome of an operation — a completed
/// purchase, a 404, a permission error.
///
/// ```dart
/// Result(
///   status: StatusType.success,
///   title: const Text('Payment received'),
///   subTitle: const Text('Order 2017182818828182881 is being processed.'),
///   extra: [Button(color: ButtonColor.primary, onPressed: home, child: const Text('Home'))],
/// )
/// ```
///
/// For a compact inline notice use a [Alert] instead.
class Result extends StatelessWidget {
  /// Creates a [Result].
  const Result({
    super.key,
    required this.title,
    this.subTitle,
    this.status = StatusType.info,
    this.icon,
    this.extra,
    this.child,
    this.token,
  });

  /// The headline stating the outcome.
  ///
  /// Rendered inside a [DefaultTextStyle] carrying the title's size and
  /// weight, so a bare `Text('Payment received')` needs no styling.
  final Widget title;

  /// Optional supporting line below the title, in its own dimmer style.
  final Widget? subTitle;

  /// Which status icon and colour to use.
  final StatusType status;

  /// Replaces the status icon.
  final Widget? icon;

  /// Action buttons shown below the text, centred in a row.
  final List<Widget>? extra;

  /// Extra content between the text and the actions — a details panel, say.
  final Widget? child;

  /// Per-instance token overrides.
  final ResultToken? token;

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (this.token ??
            ConfigProvider.componentOf<ResultToken>(context) ??
            const ResultToken())
        ._resolve(token);
    return Container(
      width: double.infinity,
      padding: r.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon ??
              CustomPaint(
                size: Size.square(r.iconSize),
                painter: _ResultIconPainter(status: status, token: token),
              ),
          SizedBox(height: token.sizeLG),
          DefaultTextStyle(
            textAlign: TextAlign.center,
            style: TextStyle(
              color: token.colorText,
              fontSize: r.titleFontSize,
              fontFamily: token.fontFamily,
              fontFamilyFallback: token.fontFamilyFallback,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
            child: title,
          ),
          if (subTitle != null) ...[
            SizedBox(height: token.sizeXS),
            DefaultTextStyle(
              textAlign: TextAlign.center,
              style: TextStyle(
                color: token.colorTextSecondary,
                fontSize: r.subtitleFontSize,
                fontFamily: token.fontFamily,
                fontFamilyFallback: token.fontFamilyFallback,
                height: token.lineHeight,
                decoration: TextDecoration.none,
              ),
              child: subTitle!,
            ),
          ],
          if (child != null) ...[
            SizedBox(height: token.sizeLG),
            child!,
          ],
          if (extra != null && extra!.isNotEmpty) ...[
            SizedBox(height: token.sizeLG),
            Wrap(
              spacing: token.sizeXS,
              runSpacing: token.sizeXS,
              alignment: WrapAlignment.center,
              children: extra!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultIconPainter extends CustomPainter {
  _ResultIconPainter({required this.status, required this.token});

  final StatusType status;
  final Token token;

  Color get _color => switch (status) {
        StatusType.success => token.success.base,
        StatusType.error => token.error.base,
        StatusType.warning => token.warning.base,
        _ => token.info.base,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    // A soft tinted disc behind a bold glyph.
    canvas.drawCircle(
      center,
      r,
      Paint()..color = _color.withValues(alpha: 0.12),
    );

    final stroke = Paint()
      ..color = _color
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (status) {
      case StatusType.success:
        canvas.drawPath(
          Path()
            ..moveTo(size.width * 0.3, size.height * 0.52)
            ..lineTo(size.width * 0.45, size.height * 0.66)
            ..lineTo(size.width * 0.72, size.height * 0.36),
          stroke,
        );
      case StatusType.error:
        canvas.drawLine(
          Offset(size.width * 0.35, size.height * 0.35),
          Offset(size.width * 0.65, size.height * 0.65),
          stroke,
        );
        canvas.drawLine(
          Offset(size.width * 0.65, size.height * 0.35),
          Offset(size.width * 0.35, size.height * 0.65),
          stroke,
        );
      default:
        // '!' for warning, 'i' for info — a bar plus a dot, order swapped.
        final isInfo = status == StatusType.info;
        final barTop = isInfo ? size.height * 0.44 : size.height * 0.28;
        final barBottom = isInfo ? size.height * 0.7 : size.height * 0.56;
        final dotY = isInfo ? size.height * 0.3 : size.height * 0.72;
        canvas.drawLine(Offset(r, barTop), Offset(r, barBottom), stroke);
        canvas.drawPoints(
          PointMode.points,
          [Offset(r, dotY)],
          stroke..strokeWidth = size.width * 0.09,
        );
    }
  }

  @override
  bool shouldRepaint(_ResultIconPainter old) =>
      old.status != status || old.token != token;
}
