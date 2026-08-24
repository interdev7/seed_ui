import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import 'message.dart' show StatusType;

/// Per-component design tokens for [Alert].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(alert: AlertToken(...)))`,
/// or per instance via [Alert.token].
@immutable
class AlertToken {
  /// Creates an [AlertToken].
  const AlertToken({
    this.withDescriptionIconSize,
    this.withDescriptionPadding,
    this.padding,
    this.borderRadius,
    this.fontSize,
  });

  /// Icon size when description is present (`withDescriptionIconSize`).
  final double? withDescriptionIconSize;

  /// Padding when description is present (`withDescriptionPadding`).
  final EdgeInsets? withDescriptionPadding;

  /// Default alert padding (`padding`).
  final EdgeInsets? padding;

  /// Corner radius (`borderRadius`).
  final double? borderRadius;

  /// Headline font size (`fontSize`).
  final double? fontSize;

  _ResolvedAlertToken _resolve(Token t) => _ResolvedAlertToken(
        withDescriptionIconSize: withDescriptionIconSize ?? 24,
        withDescriptionPadding: withDescriptionPadding ??
            EdgeInsets.symmetric(horizontal: t.size, vertical: t.sizeSM),
        padding:
            padding ?? EdgeInsets.symmetric(horizontal: t.sizeSM, vertical: 8),
        borderRadius: borderRadius ?? t.borderRadiusLG,
        fontSize: fontSize ?? t.fontSize,
      );
}

@immutable
class _ResolvedAlertToken {
  const _ResolvedAlertToken({
    required this.withDescriptionIconSize,
    required this.withDescriptionPadding,
    required this.padding,
    required this.borderRadius,
    required this.fontSize,
  });

  final double withDescriptionIconSize;
  final EdgeInsets withDescriptionPadding;
  final EdgeInsets padding;
  final double borderRadius;
  final double fontSize;
}

/// An inline banner conveying a status message, shown in the page flow rather
/// than floating over it.
///
/// Use it for a persistent notice tied to a region of the UI — a form error, a
/// feature announcement. For transient feedback reach for `message`; for a
/// banner that interrupts, a `Modal`.
///
/// ```dart
/// Alert(
///   type: StatusType.success,
///   message: const Text('Saved'),
///   description: const Text('Your changes are live.'),
///   showIcon: true,
///   closable: true,
/// )
/// ```
///
/// [message] and [description] are widgets, and the alert supplies their text
/// styling through [DefaultTextStyle] — plain [Text] children inherit the right
/// size and colour, while richer content (links, spans, a column) is free to
/// override it.
class Alert extends StatefulWidget {
  /// Creates an [Alert].
  const Alert({
    super.key,
    required this.message,
    this.description,
    this.type = StatusType.info,
    this.showIcon = false,
    this.closable = false,
    this.icon,
    this.action,
    this.banner = false,
    this.onClose,
    this.gradient,
    this.token,
  });

  /// Background gradient override.
  final Gradient? gradient;

  /// The headline. Rendered larger when a [description] is present, matching
  /// the `alert-title`.
  final Widget message;

  /// Optional detail below the message.
  final Widget? description;

  /// Which status colours and icon to use. [StatusType.loading] is treated
  /// as info.
  final StatusType type;

  /// Whether to show the leading status icon.
  final bool showIcon;

  /// Whether to show a close button that dismisses the alert.
  final bool closable;

  /// Replaces the status icon when [showIcon] is true.
  final Widget? icon;

  /// A trailing widget, typically a button, aligned to the message's end.
  final Widget? action;

  /// Renders as a full-width banner: square corners, no border. Suits a notice
  /// pinned to the top of a page.
  final bool banner;

  /// Called after the alert is dismissed by its close button.
  final VoidCallback? onClose;

  /// Per-instance token overrides.
  final AlertToken? token;

  @override
  State<Alert> createState() => _SoftAlertState();
}

class _SoftAlertState extends State<Alert> {
  bool _closed = false;

  ColorGroup _group(Token token) => switch (widget.type) {
        StatusType.success => token.success,
        StatusType.warning => token.warning,
        StatusType.error => token.error,
        _ => token.info,
      };

  @override
  Widget build(BuildContext context) {
    if (_closed) return const SizedBox.shrink();
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<AlertToken>(context) ??
            const AlertToken())
        ._resolve(token);
    final group = _group(token);
    final hasDescription = widget.description != null;

    // A banner spans the page with no border and square corners; the default
    // form is an inset card with a tinted border.
    final decoration = BoxDecoration(
      color: widget.gradient == null ? group.bg : null,
      gradient: widget.gradient,
      borderRadius:
          widget.banner ? null : BorderRadius.circular(r.borderRadius),
      border: widget.banner || widget.gradient != null
          ? null
          : Border.all(color: group.border, width: token.lineWidth),
    );

    return Container(
      width: double.infinity,
      padding: hasDescription ? r.withDescriptionPadding : r.padding,
      decoration: decoration,
      child: Row(
        crossAxisAlignment: hasDescription
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (widget.showIcon) ...[
            // The icon aligns to the message baseline; nudge it down beside a
            // taller two-line body.
            Padding(
              padding: EdgeInsets.only(top: hasDescription ? 2 : 0),
              child: _icon(token, r),
            ),
            // the kit widens the icon gutter to marginSM beside a description.
            SizedBox(width: hasDescription ? token.sizeSM : token.sizeXS),
          ],
          Expanded(child: _body(token, r)),
          if (widget.action != null) ...[
            SizedBox(width: token.sizeXS),
            widget.action!,
          ],
          if (widget.closable) ...[
            SizedBox(width: token.sizeXS),
            _CloseButton(
              token: token,
              onTap: () {
                setState(() => _closed = true);
                widget.onClose?.call();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _icon(Token token, _ResolvedAlertToken r) {
    final size = widget.description != null
        ? r.withDescriptionIconSize
        : token.fontSizeLG;
    return widget.icon ??
        SizedBox(
          width: size,
          height: size,
          child: StatusIcon(type: widget.type, token: token),
        );
  }

  Widget _body(Token token, _ResolvedAlertToken r) {
    final description = widget.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle(
          style: TextStyle(
            color: token.colorText,
            // the kit grows the title to fontSizeLG once a description is under
            // it, and leaves it at the body size otherwise.
            fontSize: description != null ? token.fontSizeLG : r.fontSize,
            fontFamily: token.fontFamily,
            fontFamilyFallback: token.fontFamilyFallback,
            height: token.lineHeight,
            leadingDistribution: TextLeadingDistribution.even,
            decoration: TextDecoration.none,
          ),
          child: widget.message,
        ),
        if (description != null) ...[
          SizedBox(height: token.sizeXS),
          DefaultTextStyle(
            style: TextStyle(
              color: token.colorText,
              fontSize: token.fontSize,
              fontFamily: token.fontFamily,
              fontFamilyFallback: token.fontFamilyFallback,
              height: token.lineHeight,
              leadingDistribution: TextLeadingDistribution.even,
              decoration: TextDecoration.none,
            ),
            child: description,
          ),
        ],
      ],
    );
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.token, required this.onTap});

  final Token token;
  final VoidCallback onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final token = widget.token;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 22,
          height: 22,
          child: CustomPaint(
            painter: CrossPainter(
              _hovered ? token.colorText : token.colorTextTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
