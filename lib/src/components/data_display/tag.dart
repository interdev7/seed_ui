import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../theme/palette.dart';

/// A preset colour for a [Tag], mapping to the theme's status palettes.
enum TagColor {
  /// The neutral tag, drawn from the theme's greys.
  defaultColor,

  /// The theme's primary accent.
  primary,

  /// Green — a completed or healthy state.
  success,

  /// Blue — work that is still under way.
  processing,

  /// Amber — something that needs attention.
  warning,

  /// Red — a failure.
  error
}

/// How a [Tag] is filled and bordered.
enum TagVariant {
  /// Tinted fill, no border.
  filled,

  /// Solid colour fill with white text.
  solid,

  /// Transparent fill with a coloured outline (the default).
  outlined,
}

/// Per-component design tokens for [Tag].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(tag: TagToken(...)))`, or per instance via [Tag.token].
@immutable
class TagToken {
  /// Creates a [TagToken].
  const TagToken({
    this.defaultBg,
    this.defaultColor,
    this.fontSize,
    this.lineHeight,
    this.borderRadius,
  });

  /// Default background color (`defaultBg`).
  final Color? defaultBg;

  /// Default text color (`defaultColor`).
  final Color? defaultColor;

  /// Font size (`fontSize`).
  final double? fontSize;

  /// Line height multiplier (`lineHeight`).
  final double? lineHeight;

  /// Corner radius (`borderRadius`).
  final double? borderRadius;

  _ResolvedTagToken _resolve(Token t) => _ResolvedTagToken(
        defaultBg: defaultBg ?? t.colorFillQuaternary,
        defaultColor: defaultColor ?? t.colorText,
        fontSize: fontSize ?? t.fontSizeSM,
        lineHeight: lineHeight ?? 1.5,
        borderRadius: borderRadius ?? t.borderRadiusSM,
      );
}

@immutable
class _ResolvedTagToken {
  const _ResolvedTagToken({
    required this.defaultBg,
    required this.defaultColor,
    required this.fontSize,
    required this.lineHeight,
    required this.borderRadius,
  });

  final Color defaultBg;
  final Color defaultColor;
  final double fontSize;
  final double lineHeight;
  final double borderRadius;
}

/// Defaults for every [Tag] under a `ConfigProvider`.
///
/// The tag's own props, not its [TagToken] numbers.
@immutable
class TagDefaults {
  /// Creates a [TagDefaults].
  const TagDefaults({this.variant, this.closable});

  /// How tags are filled and bordered.
  final TagVariant? variant;

  /// Whether tags carry a close button.
  final bool? closable;
}

/// A small label for categorising or marking content.
///
/// ```dart
/// Tag(color: TagColor.success, child: const Text('Done'))
/// Tag(customColor: const Color(0xFF722ED1), variant: TagVariant.solid,
///     child: const Text('purple'))
/// ```
///
/// Cross a [color] preset (or any [customColor]) with a [variant]. Set
/// [closable] with [onClose] for a close button. For a toggleable filter chip,
/// see [CheckableTag].
class Tag extends StatelessWidget {
  /// Creates a [Tag].
  const Tag({
    super.key,
    this.child,
    this.color,
    this.customColor,
    this.variant,
    this.icon,
    this.closable,
    this.onClose,
    this.closeIcon,
    this.gradient,
    this.token,
  });

  /// Optional background gradient override.
  final Gradient? gradient;

  /// The tag's content.
  final Widget? child;

  /// A preset status colour. Ignored when [customColor] is set.
  final TagColor? color;

  /// Any colour, expanded into a palette. Takes precedence over [color].
  final Color? customColor;

  /// How the tag is filled and bordered.
  final TagVariant? variant;

  /// Optional leading icon.
  final Widget? icon;

  /// Shows a close button.
  final bool? closable;

  /// Called when the close button is tapped.
  final VoidCallback? onClose;

  /// Replaces the default close glyph.
  final Widget? closeIcon;

  /// Per-instance token overrides.
  final TagToken? token;

  /// Each follows the same order: this tag's word, then the subtree's, then
  /// the kit's own default.
  TagVariant _variantIn(BuildContext context) =>
      variant ??
      ConfigProvider.defaultsOf<TagDefaults>(context)?.variant ??
      TagVariant.outlined;

  bool _closableIn(BuildContext context) =>
      closable ??
      ConfigProvider.defaultsOf<TagDefaults>(context)?.closable ??
      false;

  _TagStyle _style(BuildContext context, Token t) {
    final variant = _variantIn(context);
    if (gradient != null && color == null && customColor == null) {
      return const _TagStyle(
        bg: Color(0x00000000),
        border: Color(0x00000000),
        text: Color(0xFFFFFFFF),
      );
    }
    const white = Color(0xFFFFFFFF);
    const transparent = Color(0x00000000);

    // Resolve the three shades a coloured tag draws from: a light tint, an
    // outline and a strong (text / solid-fill) colour.
    Color tint, outline, strong;
    if (customColor != null) {
      final p = generate(
        customColor!,
        dark: t.isDark,
        background: t.colorBgContainer,
      );
      tint = p[0];
      outline = p[2];
      strong = p[5];
    } else {
      final g = switch (color) {
        TagColor.primary => t.primary,
        TagColor.success => t.success,
        TagColor.processing => t.info,
        TagColor.warning => t.warning,
        TagColor.error => t.error,
        _ => null,
      };
      if (g == null) {
        // Neutral (default) colour.
        return switch (variant) {
          TagVariant.outlined => _TagStyle(
              bg: transparent,
              border: t.colorBorder,
              text: t.colorText,
            ),
          TagVariant.filled => _TagStyle(
              bg: t.colorFillTertiary,
              border: transparent,
              text: t.colorText,
            ),
          TagVariant.solid => _TagStyle(
              bg: t.colorTextSecondary,
              border: transparent,
              text: white,
            ),
        };
      }
      tint = g.bg;
      outline = g.border;
      strong = g.base;
    }

    return switch (variant) {
      TagVariant.outlined =>
        _TagStyle(bg: transparent, border: outline, text: strong),
      TagVariant.filled =>
        _TagStyle(bg: tint, border: transparent, text: strong),
      TagVariant.solid =>
        _TagStyle(bg: strong, border: transparent, text: white),
    };
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (this.token ??
            ConfigProvider.componentOf<TagToken>(context) ??
            const TagToken())
        ._resolve(token);
    final style = _style(context, token);
    final fontSize = r.fontSize;

    return Container(
      // Padding-inline 7-8px, no vertical padding — the ~20px line box
      // gives the tag its height. A border is always present (transparent when
      // there is none) so every variant is the same height.
      padding: EdgeInsets.symmetric(horizontal: token.sizeXS - 1),
      decoration: BoxDecoration(
        color: gradient == null ? style.bg : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(r.borderRadius),
        border: Border.all(
          color: gradient == null ? style.border : const Color(0x00000000),
          width: token.lineWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconTheme.merge(
              data: IconThemeData(color: style.text, size: fontSize),
              child: icon!,
            ),
            SizedBox(width: token.sizeXXS),
          ],
          DefaultTextStyle.merge(
            style: TextStyle(
              color: style.text,
              fontSize: fontSize,
              height: r.lineHeight,
              leadingDistribution: TextLeadingDistribution.even,
              fontFamily: token.fontFamily,
              fontFamilyFallback: token.fontFamilyFallback,
              decoration: TextDecoration.none,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
          if (_closableIn(context)) ...[
            SizedBox(width: token.sizeXXS),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onClose,
                child: closeIcon ??
                    CustomPaint(
                      size: const Size.square(12),
                      painter:
                          CrossPainter(style.text, strokeWidth: 1.1, inset: 3),
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TagStyle {
  const _TagStyle({required this.bg, required this.border, required this.text});
  final Color bg;
  final Color border;
  final Color text;
}

/// A toggleable [Tag], selected or not. Useful
/// as a filter chip.
///
/// ```dart
/// CheckableTag(
///   checked: _on,
///   onChanged: (v) => setState(() => _on = v),
///   child: const Text('Movies'),
/// )
/// ```
class CheckableTag extends StatefulWidget {
  /// Creates a [CheckableTag].
  const CheckableTag({
    super.key,
    required this.checked,
    this.onChanged,
    this.child,
  });

  /// Whether the tag is selected.
  final bool checked;

  /// Called with the new state when tapped. Null disables the tag.
  final ValueChanged<bool>? onChanged;

  /// The tag's content.
  final Widget? child;

  @override
  State<CheckableTag> createState() => _CheckableTagState();
}

class _CheckableTagState extends State<CheckableTag> {
  bool _hovered = false;

  bool get _enabled => widget.onChanged != null;

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    // Like a text button: an unchecked tag has no resting fill, only a faint
    // one on hover; checked is the solid primary colour.
    final bg = widget.checked
        ? (_hovered && _enabled ? token.primary.hover : token.primary.base)
        : (_hovered && _enabled
            ? token.colorFillTertiary
            : const Color(0x00000000));
    final fg = widget.checked
        ? const Color(0xFFFFFFFF)
        : (_enabled ? token.colorText : token.colorTextQuaternary);

    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _enabled ? () => widget.onChanged!(!widget.checked) : null,
        child: AnimatedContainer(
          duration: token.motionDurationFast,
          padding: EdgeInsets.symmetric(horizontal: token.sizeXS - 1),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(token.borderRadiusSM),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: fg,
              fontSize: token.fontSizeSM,
              height: 20 / 12,
              leadingDistribution: TextLeadingDistribution.even,
              fontFamily: token.fontFamily,
              fontFamilyFallback: token.fontFamilyFallback,
              decoration: TextDecoration.none,
            ),
            child: widget.child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

/// One option in a [CheckableTagGroup].
@immutable
class CheckableTagOption<T> {
  /// Creates a [CheckableTagOption].
  const CheckableTagOption({
    required this.value,
    this.label,
    this.disabled = false,
  });

  /// The value this option contributes to the selection.
  final T value;

  /// The tag's content. Falls back to `Text('$value')`.
  final Widget? label;

  /// Greys the option out and blocks toggling it.
  final bool disabled;
}

/// A set of [CheckableTag]s selecting one or several values.
///
/// ```dart
/// CheckableTagGroup<String>(
///   multiple: true,
///   value: _picked,
///   options: const [
///     CheckableTagOption(value: 'movies', label: Text('Movies')),
///     CheckableTagOption(value: 'books', label: Text('Books')),
///   ],
///   onChanged: (v) => setState(() => _picked = v),
/// )
/// ```
class CheckableTagGroup<T> extends StatefulWidget {
  /// Creates a [CheckableTagGroup].
  const CheckableTagGroup({
    super.key,
    required this.options,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.disabled,
    this.multiple = false,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  /// The options, in order.
  final List<CheckableTagOption<T>> options;

  /// The checked values. Null makes the group uncontrolled (see
  /// [defaultValue]).
  final List<T>? value;

  /// Initial checked values for an uncontrolled group.
  final List<T>? defaultValue;

  /// Called with the full new selection whenever a tag toggles.
  final ValueChanged<List<T>>? onChanged;

  /// Greys the whole group out and blocks toggling.
  final bool? disabled;

  /// Whether several tags can be checked at once. When false, checking one
  /// unchecks the rest.
  final bool multiple;

  /// Gap between tags along the run, in logical pixels.
  final double spacing;

  /// Gap between wrapped rows of tags, in logical pixels.
  final double runSpacing;

  @override
  State<CheckableTagGroup<T>> createState() => _CheckableTagGroupState<T>();
}

class _CheckableTagGroupState<T> extends State<CheckableTagGroup<T>> {
  /// Whether this control is disabled: its own word, else the one set
  /// for the subtree, else no.
  bool get _disabled =>
      widget.disabled ?? ConfigProvider.componentDisabledOf(context) ?? false;

  List<T>? _internal;

  List<T> get _current =>
      widget.value ?? _internal ?? widget.defaultValue ?? const [];

  void _toggle(T value) {
    final current = _current;
    final List<T> next;
    if (widget.multiple) {
      next = List<T>.of(current);
      current.contains(value) ? next.remove(value) : next.add(value);
    } else {
      next = current.contains(value) ? <T>[] : <T>[value];
    }
    if (widget.value == null) setState(() => _internal = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return Wrap(
      spacing: widget.spacing,
      runSpacing: widget.runSpacing,
      children: [
        for (final option in widget.options)
          CheckableTag(
            checked: current.contains(option.value),
            onChanged: _disabled || option.disabled
                ? null
                : (_) => _toggle(option.value),
            child: option.label ?? Text('${option.value}'),
          ),
      ],
    );
  }
}
