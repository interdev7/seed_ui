import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';

/// How a [Button] is filled and bordered.
enum ButtonVariant {
  /// Solid colour fill. The most prominent.
  solid,

  /// Neutral fill with a coloured or grey outline.
  outlined,

  /// Dashed outline, for adding an item to a list or form.
  dashed,

  /// Tinted fill with a matching border, active but low-key.
  filled,

  /// No chrome until hovered, when a faint fill appears.
  text,

  /// Coloured label with no chrome, for navigation styled as a link.
  link,
}

/// The colour family a [Button] draws from.
enum ButtonColor {
  /// The neutral button, drawn from the theme's greys.
  defaultColor,

  /// The theme's primary accent.
  primary,

  /// Red — a destructive action.
  danger,

  /// Green — a confirming action.
  success,

  /// Amber — an action that needs care.
  warning
}

/// Control height preset for a [Button].

/// Outline shape of a [Button].
enum ButtonShape {
  /// Rounded rectangle, radius scaled to the size.
  defaultShape,

  /// A circle, for icon-only buttons.
  circle,

  /// Fully rounded ends.
  round,
}

/// Per-component design tokens for [Button].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(button: ButtonToken(...)))`,
/// or per instance via [Button.token].
@immutable
class ButtonToken {
  /// Creates a [ButtonToken].
  const ButtonToken({
    this.borderRadius,
    this.borderRadiusSM,
    this.borderRadiusLG,
    this.controlHeight,
    this.controlHeightSM,
    this.controlHeightLG,
    this.fontSize,
    this.fontSizeSM,
    this.fontSizeLG,
    this.paddingInline,
    this.paddingInlineSM,
    this.paddingInlineLG,
  });

  /// Corner radius for standard button.
  final double? borderRadius;

  /// Corner radius for small button.
  final double? borderRadiusSM;

  /// Corner radius for large button.
  final double? borderRadiusLG;

  /// Height for standard button.
  final double? controlHeight;

  /// Height for small button.
  final double? controlHeightSM;

  /// Height for large button.
  final double? controlHeightLG;

  /// Font size for standard button.
  final double? fontSize;

  /// Font size for small button.
  final double? fontSizeSM;

  /// Font size for large button.
  final double? fontSizeLG;

  /// Horizontal padding for standard button.
  final double? paddingInline;

  /// Horizontal padding for small button.
  final double? paddingInlineSM;

  /// Horizontal padding for large button.
  final double? paddingInlineLG;

  _ResolvedButtonToken _resolve(Token t) => _ResolvedButtonToken(
        borderRadius: borderRadius ?? t.borderRadius,
        borderRadiusSM: borderRadiusSM ?? t.borderRadiusSM,
        borderRadiusLG: borderRadiusLG ?? t.borderRadiusLG,
        controlHeight: controlHeight ?? t.controlHeight,
        controlHeightSM: controlHeightSM ?? t.controlHeightSM,
        controlHeightLG: controlHeightLG ?? t.controlHeightLG,
        fontSize: fontSize ?? t.fontSize,
        fontSizeSM: fontSizeSM ?? t.fontSizeSM,
        fontSizeLG: fontSizeLG ?? t.fontSizeLG,
        paddingInline: paddingInline ?? t.sizeSM,
        paddingInlineSM: paddingInlineSM ?? t.sizeXS,
        paddingInlineLG: paddingInlineLG ?? t.size,
      );
}

@immutable
class _ResolvedButtonToken {
  const _ResolvedButtonToken({
    required this.borderRadius,
    required this.borderRadiusSM,
    required this.borderRadiusLG,
    required this.controlHeight,
    required this.controlHeightSM,
    required this.controlHeightLG,
    required this.fontSize,
    required this.fontSizeSM,
    required this.fontSizeLG,
    required this.paddingInline,
    required this.paddingInlineSM,
    required this.paddingInlineLG,
  });

  final double borderRadius;
  final double borderRadiusSM;
  final double borderRadiusLG;
  final double controlHeight;
  final double controlHeightSM;
  final double controlHeightLG;
  final double fontSize;
  final double fontSizeSM;
  final double fontSizeLG;
  final double paddingInline;
  final double paddingInlineSM;
  final double paddingInlineLG;
}

/// Defaults for every [Button] under a `ConfigProvider`.
///
/// Not tokens — those are numbers and colours, and live in [ButtonToken].
/// These are the button's own props, applied wherever a button does not name
/// one for itself: a kit where every button is round and filled says so once.
///
/// ```dart
/// ConfigProvider(
///   defaults: const ComponentDefaults(
///     button: ButtonDefaults(shape: ButtonShape.round),
///   ),
///   child: ...,
/// )
/// ```
@immutable
class ButtonDefaults {
  /// Creates a [ButtonDefaults].
  const ButtonDefaults({this.variant, this.color, this.shape});

  /// How buttons are filled and bordered.
  final ButtonVariant? variant;

  /// Which palette buttons draw from.
  final ButtonColor? color;

  /// The outline shape buttons take.
  final ButtonShape? shape;
}

/// A pressable button with hover, press, loading and disabled states.
///
/// Its look is a [variant] (how it is filled) crossed with a [color] (which
/// palette it draws from), :
///
/// ```dart
/// Button(
///   variant: ButtonVariant.solid,
///   color: ButtonColor.primary,
///   onPressed: () {},
///   child: const Text('Save'),
/// )
/// ```
///
/// Set [icon] without a [child] for a compact icon-only button.
class Button extends StatefulWidget {
  /// Creates a [Button].
  const Button({
    super.key,
    this.child,
    this.onPressed,
    this.variant,
    this.color,
    this.size,
    this.shape,
    this.icon,
    this.loading = false,
    this.block = false,
    this.disabled,
    this.gradient,
    this.token,
  });

  /// Optional background gradient override.
  final Gradient? gradient;

  /// The label. Omit it, with [icon] set, for an icon-only button.
  final Widget? child;

  /// Called when the button is tapped. A null handler disables the button.
  final VoidCallback? onPressed;

  /// How the button is filled and bordered.
  final ButtonVariant? variant;

  /// Which palette the button draws from.
  final ButtonColor? color;

  /// Which control height to use.
  final SoftSize? size;

  /// The outline shape. Use [ButtonShape.circle] for icon-only buttons.
  final ButtonShape? shape;

  /// Leading icon, tinted and sized to match the label.
  final Widget? icon;

  /// Replaces [icon] with a spinner and blocks taps.
  final bool loading;

  /// Stretches the button to the full width of its parent.
  final bool block;

  /// Greys the button out and blocks taps.
  final bool? disabled;

  /// Per-instance token overrides.
  final ButtonToken? token;

  bool get _iconOnly => child == null && (icon != null || loading);

  @override
  State<Button> createState() => _SoftButtonState();
}

class _SoftButtonState extends State<Button> {
  /// The defaults set for buttons in this subtree, if any.
  ButtonDefaults? get _defaults =>
      ConfigProvider.defaultsOf<ButtonDefaults>(context);

  /// Each of the three follows the same order: what this button says, then
  /// what the subtree says, then the kit's own default.
  ButtonVariant get _variant =>
      widget.variant ?? _defaults?.variant ?? ButtonVariant.outlined;

  ButtonColor get _color =>
      widget.color ?? _defaults?.color ?? ButtonColor.defaultColor;

  ButtonShape get _shape =>
      widget.shape ?? _defaults?.shape ?? ButtonShape.defaultShape;

  /// Whether this button is disabled: its own word, else the one set for the
  /// subtree, else no.
  bool get _disabled =>
      widget.disabled ?? ConfigProvider.componentDisabledOf(context) ?? false;

  /// Whether the button answers to a press at all.
  bool get _enabled =>
      !_disabled && !widget.loading && widget.onPressed != null;

  /// The size in force: this widget's own, else the one set for the
  /// subtree, else the standard preset.
  SoftSize get _size =>
      widget.size ?? ConfigProvider.componentSizeOf(context) ?? SoftSize.middle;

  bool _hovered = false;
  bool _pressed = false;

  double _height(_ResolvedButtonToken r) => switch (_size) {
        SoftSize.small => r.controlHeightSM,
        SoftSize.middle => r.controlHeight,
        SoftSize.large => r.controlHeightLG,
      };

  double _fontSize(_ResolvedButtonToken r) => switch (_size) {
        SoftSize.small => r.fontSizeSM,
        SoftSize.middle => r.fontSize,
        SoftSize.large => r.fontSizeLG,
      };

  BorderRadius _radius(_ResolvedButtonToken r) => switch (_shape) {
        ButtonShape.circle ||
        ButtonShape.round =>
          BorderRadius.circular(_height(r) / 2),
        ButtonShape.defaultShape => BorderRadius.circular(
            switch (_size) {
              SoftSize.small => r.borderRadiusSM,
              SoftSize.middle => r.borderRadius,
              SoftSize.large => r.borderRadiusLG,
            },
          ),
      };

  bool get _isDefault => _color == ButtonColor.defaultColor;

  /// The palette the button's accents come from. Default colour borrows the
  /// primary for its hover/pressed accents, the way the default
  /// button turns blue on hover.
  ColorGroup _group(Token token) => switch (_color) {
        ButtonColor.primary || ButtonColor.defaultColor => token.primary,
        ButtonColor.danger => token.error,
        ButtonColor.success => token.success,
        ButtonColor.warning => token.warning,
      };

  Color _stateful(ColorGroup g) {
    if (_pressed) return g.active;
    if (_hovered) return g.hover;
    return g.base;
  }

  _ButtonStyle _resolveStyle(Token token) {
    final g = _group(token);
    final active = _hovered || _pressed;

    if (!_enabled) {
      final flat =
          _variant == ButtonVariant.text || _variant == ButtonVariant.link;
      final noBorder = flat ||
          _variant == ButtonVariant.solid ||
          _variant == ButtonVariant.filled;
      return _ButtonStyle(
        // Composited rather than left translucent. The disabled fill is 4% of
        // black; a button that becomes enabled animates it to an opaque colour,
        // and the midpoint of that lerp is a half-transparent mid-grey — the
        // flash you see when a wizard's Back button wakes up. Laid on the
        // surface first, the whole animation stays light.
        background: flat
            ? null
            : Color.alphaBlend(token.colorFillTertiary, token.colorBgContainer),
        border: noBorder ? null : token.colorBorder,
        foreground: token.colorTextQuaternary,
        dashed: _variant == ButtonVariant.dashed,
      );
    }

    if (widget.gradient != null && _isDefault) {
      return const _ButtonStyle(
        background: null,
        border: null,
        foreground: Color(0xFFFFFFFF),
        shadow: true,
      );
    }

    switch (_variant) {
      case ButtonVariant.solid:
        final bg = _isDefault
            ? token.colorText
                .withValues(alpha: _pressed ? 0.75 : (_hovered ? 0.85 : 1))
            : _stateful(g);
        return _ButtonStyle(
          background: bg,
          border: null,
          foreground:
              _isDefault ? token.colorBgContainer : const Color(0xFFFFFFFF),
          shadow: true,
        );
      case ButtonVariant.outlined:
      case ButtonVariant.dashed:
        final accented = !_isDefault || active;
        return _ButtonStyle(
          background: token.colorBgContainer,
          border: accented ? _stateful(g) : token.colorBorder,
          foreground: accented ? _stateful(g) : token.colorText,
          dashed: _variant == ButtonVariant.dashed,
          shadow: true,
        );
      case ButtonVariant.filled:
        return _ButtonStyle(
          background: _isDefault
              ? (active ? token.colorFillSecondary : token.colorFillTertiary)
              : (active ? g.bgHover : g.bg),
          border: null,
          foreground: _isDefault ? token.colorText : g.text,
        );
      case ButtonVariant.text:
        return _ButtonStyle(
          background:
              active ? (_isDefault ? token.colorFillSecondary : g.bg) : null,
          border: null,
          foreground: _isDefault ? token.colorText : _stateful(g),
        );
      case ButtonVariant.link:
        return _ButtonStyle(
          background: null,
          border: null,
          foreground: _stateful(g),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<ButtonToken>(context) ??
            const ButtonToken())
        ._resolve(token);
    final style = _resolveStyle(token);
    final height = _height(r);
    final fontSize = _fontSize(r);
    final foreground = style.foreground;

    final leading = widget.loading
        ? Spinner(size: fontSize, color: foreground)
        : widget.icon != null
            ? IconTheme.merge(
                data: IconThemeData(color: foreground, size: fontSize),
                child: widget.icon!,
              )
            : null;

    final content = DefaultTextStyle(
      style: TextStyle(
        color: foreground,
        fontSize: fontSize,
        fontFamily: token.fontFamily,
        fontFamilyFallback: token.fontFamilyFallback,
        fontWeight: FontWeight.w400,
        decoration: TextDecoration.none,
        // Pin the line box to the font size and split its leading evenly.
        // Left to the font's own metrics, a fallback face with lopsided
        // ascent/descent — Noto Color Emoji on Android, say — inflates the box
        // upwards and pushes the glyphs below the button's centre.
        height: 1,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      textAlign: TextAlign.center,
      child: Row(
        mainAxisSize: widget.block ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) leading,
          if (leading != null && widget.child != null)
            SizedBox(width: token.sizeXS),
          if (widget.child != null) Flexible(child: widget.child!),
        ],
      ),
    );

    final horizontalPadding = widget._iconOnly
        ? 0.0
        : switch (_size) {
            SoftSize.small => r.paddingInlineSM,
            SoftSize.middle => r.paddingInline,
            SoftSize.large => r.paddingInlineLG,
          };

    Widget button = AnimatedContainer(
      duration: token.motionDurationMid,
      curve: token.motionEaseInOut,
      height: height,
      width: widget._iconOnly ? height : null,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: widget.gradient == null ? style.background : null,
        gradient: widget.gradient,
        borderRadius: _shape == ButtonShape.circle ? null : _radius(r),
        shape:
            _shape == ButtonShape.circle ? BoxShape.circle : BoxShape.rectangle,
        border: style.border == null || style.dashed
            ? null
            : Border.all(
                color: style.border!,
                width: token.lineWidth,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
      ),
      child: Center(widthFactor: widget.block ? null : 1, child: content),
    );

    if (style.dashed && style.border != null) {
      button = CustomPaint(
        foregroundPainter: DashedBorderPainter(
          color: style.border!,
          radius: _radius(r),
          strokeWidth: token.lineWidth,
        ),
        child: button,
      );
    }

    return MouseRegion(
      cursor:
          _enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        onTap: _enabled ? widget.onPressed : null,
        child: widget.block
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}

class _ButtonStyle {
  const _ButtonStyle({
    required this.background,
    required this.border,
    required this.foreground,
    this.dashed = false,
    this.shadow = false,
  });

  final Color? background;
  final Color? border;
  final Color foreground;
  final bool dashed;
  final bool shadow;
}
