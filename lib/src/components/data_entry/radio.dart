import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/size_resolver.dart';
import '../general/compact.dart';

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
/// Defaults for every [Radio] under a `ConfigProvider`.
///
/// The widget's own props, not its numbers — those are [RadioToken].
@immutable
class RadioDefaults {
  /// Creates a [RadioDefaults].
  const RadioDefaults({
    this.disabled,
  });

  /// Whether radios are barred, unless one says otherwise.
  final bool? disabled;
}

/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(radio: RadioToken(...)))`,
/// or per instance via [Radio.token].
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
    this.disabled,
    this.token,
    this.focusNode,
    this.autofocus = false,
  });

  /// A focus node of your own, for a button whose focus you drive yourself.
  ///
  /// Left null the button keeps one. Either way it takes its turn in the tab
  /// order and answers Space and Enter.
  final FocusNode? focusNode;

  /// Whether the button takes focus as soon as it is built.
  final bool autofocus;

  /// This button's value.
  final T value;

  /// The group's selected value; this button is filled when they are equal.
  final T? groupValue;

  /// Called with [value] when this button is chosen. Null disables it.
  final ValueChanged<T>? onChanged;

  /// The label beside the dot.
  final Widget? child;

  /// Greys the button out and blocks selection.
  final bool? disabled;

  /// Per-instance token overrides.
  final RadioToken? token;

  bool get _selected => value == groupValue;

  @override
  State<Radio<T>> createState() => _SoftRadioState<T>();
}

class _SoftRadioState<T> extends State<Radio<T>> {
  /// Whether this control is disabled: its own word, else the one set
  /// for the subtree, else no.
  bool get _disabled =>
      widget.disabled ??
      ConfigProvider.defaultsOf<RadioDefaults>(context)?.disabled ??
      ConfigProvider.componentDisabledOf(context) ??
      false;

  bool _hovered = false;

  /// Whether the focus should be seen: only where it arrived by keyboard.
  bool _focusVisible = false;

  bool get _enabled => !_disabled && widget.onChanged != null;

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
    return FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: _enabled,
      onShowFocusHighlight: (visible) {
        if (_focusVisible != visible) setState(() => _focusVisible = visible);
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _select();
            return null;
          },
        ),
      },
      child: Semantics(
        // One of a set, so the reader is told it is a choice among others as
        // well as whether it is the one taken.
        inMutuallyExclusiveGroup: true,
        checked: widget._selected,
        enabled: _enabled,
        onTap: _enabled ? _select : null,
        child: MouseRegion(
          cursor:
              _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _select,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioDot(
                  focused: _focusVisible,
                  selected: widget._selected,
                  enabled: _enabled,
                  hovered: _hovered && _enabled,
                  token: token,
                  componentToken: r,
                ),
                if (widget.child != null) ...[
                  SizedBox(width: token.sizeXS),
                  // Flexible, so words longer than the room they are in give
                  // way rather than running off the end of the row: a label
                  // takes the width its words want, and in a narrow column that
                  // is more than there is.
                  Flexible(
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        color: _enabled
                            ? token.colorText
                            : token.colorTextQuaternary,
                        fontSize: r.fontSize,
                        fontFamily: token.fontFamily,
                        fontFamilyFallback: token.fontFamilyFallback,
                        decoration: TextDecoration.none,
                      ),
                      child: widget.child!,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
    this.focused = false,
  });

  /// Whether the dot reads as chosen.
  final bool selected;

  /// Whether the dot is interactive, or greyed out.
  final bool enabled;

  /// Whether the pointer is currently over the dot.
  final bool hovered;

  /// Whether the dot wears the halo that says the keyboard is on it.
  final bool focused;

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
        // Around the dot rather than the label: the words beside it are not
        // the control.
        boxShadow: focused && enabled
            ? [
                BoxShadow(
                  color: r.colorPrimary.withValues(alpha: 0.12),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : null,
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

/// Defaults for every [RadioGroup] under a `ConfigProvider`.
///
/// House style for radio groups.
@immutable
class RadioGroupDefaults {
  /// Creates a [RadioGroupDefaults].
  const RadioGroupDefaults({
    this.direction,
    this.optionType,
    this.buttonStyle,
    this.size,
    this.disabled,
  });

  /// Which way the options run.
  final Axis? direction;

  /// Whether options are dots or buttons.
  final RadioOptionType? optionType;

  /// How button-style options are filled.
  final RadioButtonStyle? buttonStyle;

  /// Which control height a [RadioGroup] takes, unless it names one.
  ///
  /// Nearer than `ConfigProvider.componentSize`, so this wins where both
  /// are set: small buttons on an otherwise normal screen.
  final ControlSize? size;

  /// Whether a [RadioGroup] is disabled, unless it says otherwise.
  ///
  /// Nearer than `ConfigProvider.componentDisabled`, and beaten in turn by
  /// the widget's own word.
  final bool? disabled;
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
class RadioGroup<T> extends StatefulWidget {
  /// Creates a [RadioGroup].
  const RadioGroup({
    super.key,
    this.value,
    this.defaultValue,
    required this.options,
    this.onChanged,
    this.disabled,
    this.direction,
    this.spacing = 16,
    this.runSpacing = 8,
    this.optionType,
    this.buttonStyle,
    this.size,
    this.block = false,
  });

  /// The selected value. Null leaves the group to keep its own (see
  /// [defaultValue]).
  final T? value;

  /// What an uncontrolled group starts on. Defaults to nothing chosen.
  final T? defaultValue;

  /// The options, in order.
  final List<RadioOption<T>> options;

  /// Called with the newly chosen value.
  ///
  /// Null on a controlled one — given a value of its own — makes it inert:
  /// nothing can change what it shows, so nothing does. An uncontrolled one
  /// keeps its own state and changes whether or not anybody is listening.
  final ValueChanged<T>? onChanged;

  /// Greys the whole group out.
  final bool? disabled;

  /// Whether dot-style options run in a row (wrapping) or a column. Ignored
  /// for [RadioOptionType.button], which is always a row.
  final Axis? direction;

  /// Gap between options along the run, in logical pixels.
  final double spacing;

  /// Gap between wrapped rows of options, in logical pixels.
  final double runSpacing;

  /// Dots or connected buttons.
  final RadioOptionType? optionType;

  /// Fill treatment for the selected button. Only used with
  /// [RadioOptionType.button].
  final RadioButtonStyle? buttonStyle;

  /// Height preset for button-style options.
  final ControlSize? size;

  /// Stretch button-style options to fill the width equally.
  final bool block;

  @override
  State<RadioGroup<T>> createState() => _RadioGroupState<T>();
}

class _RadioGroupState<T> extends State<RadioGroup<T>> {
  T? _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.defaultValue;
  }

  /// What is chosen: the value handed in, else the one the group has been
  /// keeping, else where it started.
  T? get _current => widget.value ?? _internal ?? widget.defaultValue;

  /// Whether this control is disabled: its own word, else the one set for
  /// the subtree, else no.
  bool get _disabled =>
      widget.disabled ??
      ConfigProvider.defaultsOf<RadioGroupDefaults>(context)?.disabled ??
      ConfigProvider.componentDisabledOf(context) ??
      false;

  /// A group nobody is listening to is inert only while somebody else is
  /// driving it. An uncontrolled one has its own choice to change.
  bool get _enabled =>
      !_disabled && (widget.onChanged != null || widget.value == null);

  void _select(T v) {
    if (v == _current) return;
    // Kept in step whether or not somebody else is driving this: it is only
    // the fallback for `value`, and a stale one would show through the moment
    // `value` went null again.
    setState(() => _internal = v);
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    if (_optionType == RadioOptionType.button) {
      return _buildButtons(context);
    }
    return _buildDots(context);
  }

  Widget _buildDots(BuildContext context) {
    final current = _current;
    final dots = [
      for (final option in widget.options)
        Radio<T>(
          value: option.value,
          groupValue: current,
          disabled: !_enabled || option.disabled,
          onChanged: _select,
          child: option.label ?? const SizedBox.shrink(),
        ),
    ];

    if (_direction == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < dots.length; i++) ...[
            if (i > 0) SizedBox(height: widget.runSpacing),
            dots[i],
          ],
        ],
      );
    }
    return Wrap(
        spacing: widget.spacing, runSpacing: widget.runSpacing, children: dots);
  }

  Widget _buildButtons(BuildContext context) {
    final token = context.softToken;
    final resolvedSize = widget.size ??
        ConfigProvider.defaultsOf<RadioGroupDefaults>(context)?.size ??
        ConfigProvider.componentSizeOf(context) ??
        SoftSize.middle;
    final selectedIndex = widget.options.indexWhere((o) => o.value == _current);

    // The whole run's corners, asked of [CompactSlot]: all four where the
    // group stands on its own, and only the outer ones where it has been
    // joined to a neighbour in a [Compact]. The buttons then divide them
    // between the two ends.
    final corners = CompactSlot.radiusOf(context, token.borderRadius);

    BorderRadiusDirectional radiusAt(int i) {
      // Start and end, not left and right: a run that reads the other way puts
      // its first button on the right, and the round corners must follow it
      // there. Square where two buttons meet, whichever way that is.
      final keepsStart = i == 0;
      final keepsEnd = i == widget.options.length - 1;
      return BorderRadiusDirectional.only(
        topStart: keepsStart ? corners.topStart : Radius.zero,
        bottomStart: keepsStart ? corners.bottomStart : Radius.zero,
        topEnd: keepsEnd ? corners.topEnd : Radius.zero,
        bottomEnd: keepsEnd ? corners.bottomEnd : Radius.zero,
      );
    }

    _RadioButton<T> button(int i, _ButtonRole role) => _RadioButton<T>(
          option: widget.options[i],
          role: role,
          selected: i == selectedIndex,
          radius: radiusAt(i),
          // Every button after the first is laid a line back onto the one
          // before it, so the two borders that meet draw a single divider.
          overlap: i == 0 ? 0 : token.lineWidth,
          enabled: _enabled && !widget.options[i].disabled,
          style: _buttonStyle,
          size: resolvedSize,
          block: widget.block,
          token: token,
          onTap: () => _select(widget.options[i].value),
        );

    Row row(List<Widget> children) => Row(
          mainAxisSize: widget.block ? MainAxisSize.max : MainAxisSize.min,
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
          for (var i = 0; i < widget.options.length; i++)
            button(i, _ButtonRole.base),
        ]),
        if (selectedIndex >= 0)
          // Decorative top layer: its invisible spacers duplicate the labels,
          // so keep it out of hit-testing and the semantics tree.
          ExcludeSemantics(
            child: IgnorePointer(
              child: row([
                for (var i = 0; i < widget.options.length; i++)
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

  /// This widget's word, then the subtree's, then the kit's.
  Axis get _direction =>
      widget.direction ??
      ConfigProvider.defaultsOf<RadioGroupDefaults>(context)?.direction ??
      Axis.horizontal;

  /// This widget's word, then the subtree's, then the kit's.
  RadioOptionType get _optionType =>
      widget.optionType ??
      ConfigProvider.defaultsOf<RadioGroupDefaults>(context)?.optionType ??
      RadioOptionType.radio;

  /// This widget's word, then the subtree's, then the kit's.
  RadioButtonStyle get _buttonStyle =>
      widget.buttonStyle ??
      ConfigProvider.defaultsOf<RadioGroupDefaults>(context)?.buttonStyle ??
      RadioButtonStyle.outline;
}

/// Which layer a button is drawn in — see the button layer stack.
enum _ButtonRole { base, overlay, ghost }

class _RadioButton<T> extends StatefulWidget {
  const _RadioButton({
    required this.option,
    required this.role,
    required this.selected,
    required this.radius,
    required this.overlap,
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

  /// The corners this button draws — worked out by the group, which alone
  /// knows both where the button stands in the run and whether the run
  /// itself has been joined to something.
  final BorderRadiusDirectional radius;

  /// How far this button is laid back onto the one before it.
  final double overlap;
  final bool enabled;
  final RadioButtonStyle style;
  final ControlSize size;
  final bool block;
  final Token token;
  final VoidCallback onTap;

  @override
  State<_RadioButton<T>> createState() => _RadioButtonState<T>();
}

class _RadioButtonState<T> extends State<_RadioButton<T>> {
  bool _hovered = false;

  double get _height => widget.size.resolveHeight(
        small: widget.token.controlHeightSM,
        middle: widget.token.controlHeight,
        large: widget.token.controlHeightLG,
      );

  /// Type has no height to take, so it follows the preset the button's own
  /// height is nearest to.
  double get _fontSize => switch (widget.size.nearestPreset(
        small: widget.token.controlHeightSM,
        middle: widget.token.controlHeight,
        large: widget.token.controlHeightLG,
      )) {
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

    Widget content = AnimatedContainer(
      duration: token.motionDurationFast,
      curve: token.motionEaseInOut,
      height: _height,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: token.size),
      decoration: BoxDecoration(
        color: bg,
        // Inside, as every other bordered control in the kit draws it: a
        // stroke centred on the edge stands half a line outside the box, and
        // the run came out a pixel taller than a button beside it. The
        // divider is a single line because the buttons overlap, not because
        // their borders hang over the join.
        border: Border.all(color: borderColor, width: token.lineWidth),
        borderRadius: widget.radius,
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

    if (widget.overlap > 0) {
      content = CompactOverlap(
        by: widget.overlap,
        direction: Axis.horizontal,
        child: content,
      );
    }

    // The flex goes outside the overlap, for the reason a `Compact` puts it
    // there: `Expanded` speaks only to the row directly above it.
    return widget.block ? Expanded(child: content) : content;
  }
}
