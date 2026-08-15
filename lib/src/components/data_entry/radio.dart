import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';

/// How a [RadioGroup] renders its options.
enum RadioOptionType {
  /// A dot beside a label. The default.
  radio,

  /// Connected buttons, like a segmented control.
  button,
}

/// Fill treatment for button-style options.
enum RadioButtonStyle {
  /// Selected button shows a coloured outline and label.
  outline,

  /// Selected button is filled with the primary colour.
  solid,
}

/// Height preset for button-style options.

/// Per-component design tokens for [Radio].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [RadioToken(...)])`, or per instance via [Radio.token].
@immutable
class RadioToken {
  /// Creates a [RadioToken].
  const RadioToken({
    this.radioSize,
    this.dotSize,
    this.dotColor,
    this.colorBorder,
    this.colorPrimary,
    this.buttonBg,
    this.buttonCheckedBg,
    this.buttonColor,
    this.fontSize,
  });

  /// Outer diameter of the radio dot (`radioSize`).
  final double? radioSize;

  /// Inner dot diameter when checked (`dotSize`).
  final double? dotSize;

  /// Inner dot color when checked (`dotColor`).
  final Color? dotColor;

  /// Border color when unchecked (`colorBorder`).
  final Color? colorBorder;

  /// Primary color when checked (`colorPrimary`).
  final Color? colorPrimary;

  /// Background color for button style (`buttonBg`).
  final Color? buttonBg;

  /// Checked background color for button style (`buttonCheckedBg`).
  final Color? buttonCheckedBg;

  /// Text color for button style (`buttonColor`).
  final Color? buttonColor;

  /// Label font size (`fontSize`).
  final double? fontSize;

  _ResolvedRadioToken _resolve(Token t) => _ResolvedRadioToken(
        radioSize: radioSize ?? 16,
        dotSize: dotSize ?? 8,
        dotColor: dotColor ?? t.primary.base,
        colorBorder: colorBorder ?? t.colorBorder,
        colorPrimary: colorPrimary ?? t.primary.base,
        buttonBg: buttonBg ?? t.colorBgContainer,
        buttonCheckedBg: buttonCheckedBg ?? t.primary.base,
        buttonColor: buttonColor ?? t.colorText,
        fontSize: fontSize ?? t.fontSize,
      );
}

@immutable
class _ResolvedRadioToken {
  const _ResolvedRadioToken({
    required this.radioSize,
    required this.dotSize,
    required this.dotColor,
    required this.colorBorder,
    required this.colorPrimary,
    required this.buttonBg,
    required this.buttonCheckedBg,
    required this.buttonColor,
    required this.fontSize,
  });

  final double radioSize;
  final double dotSize;
  final Color dotColor;
  final Color colorBorder;
  final Color colorPrimary;
  final Color buttonBg;
  final Color buttonCheckedBg;
  final Color buttonColor;
  final double fontSize;
}

/// A radio button for one choice among a group. Usually driven by a
/// [RadioGroup]; use it directly only for a standalone two-state control.
///
/// ```dart
/// Radio<String>(
///   value: 'a',
///   groupValue: _picked,
///   onChanged: (v) => setState(() => _picked = v),
///   child: const Text('Option A'),
/// )
/// ```
class Radio<T> extends StatefulWidget {
  /// Creates a [Radio].
  const Radio({
    super.key,
    required this.value,
    required this.groupValue,
    this.onChanged,
    this.child,
    this.disabled = false,
    this.token,
  });

  /// This button's value.
  final T value;

  /// The group's selected value; this button is filled when they are equal.
  final T? groupValue;

  /// Called with [value] when this button is chosen. Null disables it.
  final ValueChanged<T>? onChanged;

  /// The label beside the dot.
  final Widget? child;

  /// Greys the button out and blocks selection.
  final bool disabled;

  /// Per-instance token overrides.
  final RadioToken? token;

  bool get _selected => value == groupValue;

  @override
  State<Radio<T>> createState() => _SoftRadioState<T>();
}

class _SoftRadioState<T> extends State<Radio<T>> {
  bool _hovered = false;

  bool get _enabled => !widget.disabled && widget.onChanged != null;

  void _select() {
    if (_enabled && !widget._selected) widget.onChanged!(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<RadioToken>(context) ??
            const RadioToken())
        ._resolve(token);
    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _select,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioDot(
              selected: widget._selected,
              enabled: _enabled,
              hovered: _hovered && _enabled,
              token: token,
              componentToken: r,
            ),
            if (widget.child != null) ...[
              SizedBox(width: token.sizeXS),
              DefaultTextStyle.merge(
                style: TextStyle(
                  color: _enabled ? token.colorText : token.colorTextQuaternary,
                  fontSize: r.fontSize,
                  fontFamily: token.fontFamily,
                  fontFamilyFallback: token.fontFamilyFallback,
                  decoration: TextDecoration.none,
                ),
                child: widget.child!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The 16×16 dot of a radio button, without the label.
class RadioDot extends StatelessWidget {
  /// Creates a [RadioDot].
  const RadioDot({
    super.key,
    required this.selected,
    required this.enabled,
    required this.token,
    // ignore: library_private_types_in_public_api
    this.componentToken,
    this.hovered = false,
  });

  /// Whether the dot reads as chosen.
  final bool selected;

  /// Whether the dot is interactive, or greyed out.
  final bool enabled;

  /// Whether the pointer is currently over the dot.
  final bool hovered;

  /// The resolved theme the dot's colours are read from.
  final Token token;

  /// Pre-resolved component tokens, when the parent has already resolved them.
  // ignore: library_private_types_in_public_api
  final _ResolvedRadioToken? componentToken;

  @override
  Widget build(BuildContext context) {
    final r = componentToken ??
        (ConfigProvider.componentOf<RadioToken>(context) ?? const RadioToken())
            ._resolve(token);
    final border = !enabled
        ? token.colorBorder
        : (selected || hovered)
            ? r.colorPrimary
            : r.colorBorder;

    final borderWidth =
        selected ? ((r.radioSize - r.dotSize) / 2) : token.lineWidth;

    return AnimatedContainer(
      duration: token.motionDurationFast,
      curve: token.motionEaseInOut,
      width: r.radioSize,
      height: r.radioSize,
      decoration: BoxDecoration(
        color: enabled ? token.colorBgContainer : token.colorFillTertiary,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected && enabled ? r.colorPrimary : border,
          width: borderWidth,
        ),
      ),
    );
  }
}

/// One option in a [RadioGroup].
@immutable
class RadioOption<T> {
  /// Creates a [RadioOption].
  const RadioOption({
    required this.value,
    this.label,
    this.disabled = false,
  });

  /// The value this option contributes to the group's selection.
  final T value;

  /// The label widget. Wrap a string in a [Text] yourself.
  final Widget? label;

  /// Whether this single option is greyed out.
  final bool disabled;
}

/// A set of radio buttons selecting one value from a list.
///
/// ```dart
/// RadioGroup<String>(
///   value: _picked,
///   options: const [
///     RadioOption(value: 'a', label: 'Option A'),
///     RadioOption(value: 'b', label: 'Option B'),
///   ],
///   onChanged: (v) => setState(() => _picked = v),
/// )
/// ```
///
/// Set [optionType] to [RadioOptionType.button] to render the options as
/// connected buttons instead of dots.
class RadioGroup<T> extends StatelessWidget {
  /// Creates a [RadioGroup].
  const RadioGroup({
    super.key,
    required this.value,
    required this.options,
    this.onChanged,
    this.disabled = false,
    this.direction = Axis.horizontal,
    this.spacing = 16,
    this.runSpacing = 8,
    this.optionType = RadioOptionType.radio,
    this.buttonStyle = RadioButtonStyle.outline,
    this.size = SoftSize.middle,
    this.block = false,
  });

  /// The selected value.
  final T? value;

  /// The options, in order.
  final List<RadioOption<T>> options;

  /// Called with the newly chosen value.
  final ValueChanged<T>? onChanged;

  /// Greys the whole group out.
  final bool disabled;

  /// Whether dot-style options run in a row (wrapping) or a column. Ignored
  /// for [RadioOptionType.button], which is always a row.
  final Axis direction;

  /// Gap between options along the run, in logical pixels.
  final double spacing;

  /// Gap between wrapped rows of options, in logical pixels.
  final double runSpacing;

  /// Dots or connected buttons.
  final RadioOptionType optionType;

  /// Fill treatment for the selected button. Only used with
  /// [RadioOptionType.button].
  final RadioButtonStyle buttonStyle;

  /// Height preset for button-style options.
  final SoftSize size;

  /// Stretch button-style options to fill the width equally.
  final bool block;

  void _select(T v) {
    if (v != value) onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    if (optionType == RadioOptionType.button) {
      return _buildButtons(context);
    }
    return _buildDots();
  }

  Widget _buildDots() {
    final dots = [
      for (final option in options)
        Radio<T>(
          value: option.value,
          groupValue: value,
          disabled: disabled || option.disabled || onChanged == null,
          onChanged: onChanged,
          child: option.label ?? const SizedBox.shrink(),
        ),
    ];

    if (direction == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < dots.length; i++) ...[
            if (i > 0) SizedBox(height: runSpacing),
            dots[i],
          ],
        ],
      );
    }
    return Wrap(spacing: spacing, runSpacing: runSpacing, children: dots);
  }

  Widget _buildButtons(BuildContext context) {
    final token = context.softToken;
    final selectedIndex = options.indexWhere((o) => o.value == value);

    _RadioButton<T> button(int i, _ButtonRole role) => _RadioButton<T>(
          option: options[i],
          role: role,
          selected: i == selectedIndex,
          first: i == 0,
          last: i == options.length - 1,
          enabled: !disabled && !options[i].disabled && onChanged != null,
          style: buttonStyle,
          size: size,
          block: block,
          token: token,
          onTap: () => _select(options[i].value),
        );

    Row row(List<Widget> children) => Row(
          mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
          children: children,
        );

    // Two identical layers, like CSS `margin-left: -1px; z-index: 1`: the base
    // row draws every button with grey dividers; the top row re-draws only the
    // selected button's accent border, so it overlaps both neighbours and the
    // outline is continuous. The others in the top row are invisible spacers
    // that keep the two rows aligned.
    return Stack(
      children: [
        row([
          for (var i = 0; i < options.length; i++) button(i, _ButtonRole.base),
        ]),
        if (selectedIndex >= 0)
          // Decorative top layer: its invisible spacers duplicate the labels,
          // so keep it out of hit-testing and the semantics tree.
          ExcludeSemantics(
            child: IgnorePointer(
              child: row([
                for (var i = 0; i < options.length; i++)
                  button(
                    i,
                    i == selectedIndex
                        ? _ButtonRole.overlay
                        : _ButtonRole.ghost,
                  ),
              ]),
            ),
          ),
      ],
    );
  }
}

/// Which layer a button is drawn in — see the button layer stack.
enum _ButtonRole { base, overlay, ghost }

class _RadioButton<T> extends StatefulWidget {
  const _RadioButton({
    required this.option,
    required this.role,
    required this.selected,
    required this.first,
    required this.last,
    required this.enabled,
    required this.style,
    required this.size,
    required this.block,
    required this.token,
    required this.onTap,
  });

  final RadioOption<T> option;
  final _ButtonRole role;
  final bool selected;
  final bool first;
  final bool last;
  final bool enabled;
  final RadioButtonStyle style;
  final SoftSize size;
  final bool block;
  final Token token;
  final VoidCallback onTap;

  @override
  State<_RadioButton<T>> createState() => _RadioButtonState<T>();
}

class _RadioButtonState<T> extends State<_RadioButton<T>> {
  bool _hovered = false;

  double get _height => switch (widget.size) {
        SoftSize.small => widget.token.controlHeightSM,
        SoftSize.middle => widget.token.controlHeight,
        SoftSize.large => widget.token.controlHeightLG,
      };

  double get _fontSize => switch (widget.size) {
        SoftSize.large => widget.token.fontSizeLG,
        _ => widget.token.fontSize,
      };

  @override
  Widget build(BuildContext context) {
    final token = widget.token;
    final solid = widget.style == RadioButtonStyle.solid;
    final accent =
        widget.enabled ? token.primary.base : token.colorTextQuaternary;
    final overlay = widget.role == _ButtonRole.overlay;

    final Color bg;
    final Color fg;
    if (overlay) {
      // The top layer contributes only the accent outline, over the base fill.
      bg = const Color(0x00000000);
      fg = accent;
    } else if (widget.selected && solid) {
      bg = _hovered ? token.primary.hover : accent;
      fg = const Color(0xFFFFFFFF);
    } else if (widget.selected) {
      bg = widget.enabled ? token.colorBgContainer : token.colorFillTertiary;
      fg = _hovered ? token.primary.hover : accent;
    } else if (_hovered) {
      // Unselected + hovered: only text color changes to primary.hover
      bg = widget.enabled ? token.colorBgContainer : token.colorFillTertiary;
      fg = token.primary.hover;
    } else {
      bg = widget.enabled ? token.colorBgContainer : token.colorFillTertiary;
      fg = widget.enabled ? token.colorText : token.colorTextQuaternary;
    }

    // Uniform border so the rounded end corners are legal: grey in the base
    // layer, accent in the overlay.
    final borderColor = overlay ? token.primary.hover : token.colorBorder;
    final r = Radius.circular(token.borderRadius);
    final borderRadius = BorderRadius.only(
      topLeft: widget.first ? r : Radius.zero,
      bottomLeft: widget.first ? r : Radius.zero,
      topRight: widget.last ? r : Radius.zero,
      bottomRight: widget.last ? r : Radius.zero,
    );

    Widget content = AnimatedContainer(
      duration: token.motionDurationFast,
      curve: token.motionEaseInOut,
      height: _height,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: token.size),
      decoration: BoxDecoration(
        color: bg,
        // Centre the stroke on each edge so two adjacent buttons' borders land
        // on the same line and read as a single 1px divider — the same width
        // as the top, bottom and end edges.
        border: Border.all(
          color: borderColor,
          width: token.lineWidth,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
        borderRadius: borderRadius,
      ),
      child: Opacity(
        // Only the base layer shows its label; the overlay just reserves the
        // same width so the two rows stay aligned.
        opacity: widget.role == _ButtonRole.base ? 1 : 0,
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: fg,
            fontSize: _fontSize,
            fontFamily: token.fontFamily,
            fontFamilyFallback: token.fontFamilyFallback,
            decoration: TextDecoration.none,
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: fg, size: _fontSize),
            child: widget.option.label ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );

    if (widget.role == _ButtonRole.ghost) {
      content = Opacity(opacity: 0, child: content);
    } else if (widget.role == _ButtonRole.base) {
      content = MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) {
          if (widget.enabled) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (widget.enabled) setState(() => _hovered = false);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled && !widget.selected ? widget.onTap : null,
          child: content,
        ),
      );
    }

    return widget.block ? Expanded(child: content) : content;
  }
}
