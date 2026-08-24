import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';

/// Per-component design tokens for [Checkbox].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(checkbox: CheckboxToken(...)))`,
/// or per instance via [Checkbox.token].
@immutable
class CheckboxToken {
  /// Creates a [CheckboxToken].
  const CheckboxToken({
    this.boxSize,
    this.borderRadius,
    this.colorPrimary,
    this.colorBorder,
    this.colorBgContainer,
    this.fontSize,
  });

  /// Width and height of the checkbox box (`boxSize`).
  final double? boxSize;

  /// Corner radius of the checkbox box (`borderRadius`).
  final double? borderRadius;

  /// Primary fill/border color when checked (`colorPrimary`).
  final Color? colorPrimary;

  /// Border color when unchecked (`colorBorder`).
  final Color? colorBorder;

  /// Background fill when unchecked (`colorBgContainer`).
  final Color? colorBgContainer;

  /// Label font size (`fontSize`).
  final double? fontSize;

  _ResolvedCheckboxToken _resolve(Token t) => _ResolvedCheckboxToken(
        boxSize: boxSize ?? 16,
        borderRadius: borderRadius ?? t.borderRadiusSM,
        colorPrimary: colorPrimary ?? t.primary.base,
        colorBorder: colorBorder ?? t.colorBorder,
        colorBgContainer: colorBgContainer ?? t.colorBgContainer,
        fontSize: fontSize ?? t.fontSize,
      );
}

@immutable
class _ResolvedCheckboxToken {
  const _ResolvedCheckboxToken({
    required this.boxSize,
    required this.borderRadius,
    required this.colorPrimary,
    required this.colorBorder,
    required this.colorBgContainer,
    required this.fontSize,
  });

  final double boxSize;
  final double borderRadius;
  final Color colorPrimary;
  final Color colorBorder;
  final Color colorBgContainer;
  final double fontSize;
}

/// A checkbox for an independent boolean choice, usually confirmed later by a
/// form submit.
///
/// ```dart
/// Checkbox(
///   value: _agree,
///   onChanged: (v) => setState(() => _agree = v),
///   label: const Text('I agree'),
/// )
/// ```
///
/// For a setting that takes effect immediately, prefer a [Switch] instead.
/// For picking several values from a list, see [CheckboxGroup].
class Checkbox extends StatefulWidget {
  /// Creates a [Checkbox].
  const Checkbox({
    super.key,
    required this.checked,
    this.onChanged,
    this.label,
    this.disabled,
    this.indeterminate = false,
    this.token,
  });

  /// Whether the box is ticked.
  final bool checked;

  /// Called with the new state when toggled. Null disables the checkbox.
  final ValueChanged<bool>? onChanged;

  /// The label widget beside the box.
  final Widget? label;

  /// Greys the checkbox out and blocks toggling.
  final bool? disabled;

  /// Shows a dash rather than a tick — the "some but not all" state of a
  /// parent checkbox. Toggling still reports the opposite of [checked].
  final bool indeterminate;

  /// Per-instance token overrides.
  final CheckboxToken? token;

  @override
  State<Checkbox> createState() => _SoftCheckboxState();
}

class _SoftCheckboxState extends State<Checkbox> {
  bool _hovered = false;

  /// Whether this control is disabled: its own word, else the one set for the
  /// subtree, else no.
  bool get _disabled =>
      widget.disabled ?? ConfigProvider.componentDisabledOf(context) ?? false;

  bool get _enabled => !_disabled && widget.onChanged != null;

  void _toggle() {
    if (_enabled) widget.onChanged!(!widget.checked);
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<CheckboxToken>(context) ??
            const CheckboxToken())
        ._resolve(token);
    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CheckboxBox(
              value: widget.checked,
              indeterminate: widget.indeterminate,
              enabled: _enabled,
              hovered: _hovered && _enabled,
              token: token,
              componentToken: r,
            ),
            if (widget.label != null) ...[
              SizedBox(width: token.sizeXS),
              DefaultTextStyle.merge(
                style: TextStyle(
                  color: _enabled ? token.colorText : token.colorTextQuaternary,
                  fontSize: r.fontSize,
                  fontFamily: token.fontFamily,
                  fontFamilyFallback: token.fontFamilyFallback,
                  decoration: TextDecoration.none,
                ),
                child: widget.label!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The 16×16 box of a checkbox, without the label — reused by
/// [CheckboxGroup]'s options.
class CheckboxBox extends StatelessWidget {
  /// Creates a [CheckboxBox].
  const CheckboxBox({
    super.key,
    required this.value,
    required this.enabled,
    required this.token,
    // ignore: library_private_types_in_public_api
    this.componentToken,
    this.indeterminate = false,
    this.hovered = false,
  });

  /// Whether the box reads as checked.
  final bool value;

  /// Whether the box shows the mixed (dash) glyph instead of a tick.
  final bool indeterminate;

  /// Whether the box is interactive, or greyed out.
  final bool enabled;

  /// Whether the pointer is currently over the box.
  final bool hovered;

  /// The resolved theme the box's colours are read from.
  final Token token;

  /// Pre-resolved component tokens, when the parent has already resolved them.
  // ignore: library_private_types_in_public_api
  final _ResolvedCheckboxToken? componentToken;

  @override
  Widget build(BuildContext context) {
    final r = componentToken ??
        (ConfigProvider.componentOf<CheckboxToken>(context) ??
                const CheckboxToken())
            ._resolve(token);
    final active = value || indeterminate;
    final border = !enabled
        ? token.colorBorder
        : (active || hovered)
            ? r.colorPrimary
            : r.colorBorder;
    final fill = value && !indeterminate
        ? (enabled ? r.colorPrimary : token.colorTextQuaternary)
        : (enabled ? r.colorBgContainer : token.colorFillTertiary);

    return AnimatedContainer(
      duration: token.motionDurationFast,
      curve: token.motionEaseInOut,
      width: r.boxSize,
      height: r.boxSize,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(r.borderRadius),
        border: Border.all(color: border, width: token.lineWidth),
      ),
      child: CustomPaint(
        painter: CheckPainter(
          checked: value && !indeterminate,
          indeterminate: indeterminate,
          color: value && !indeterminate
              ? const Color(0xFFFFFFFF)
              : r.colorPrimary,
          strokeWidth: 1.8,
        ),
      ),
    );
  }
}

/// One option in a [CheckboxGroup].
@immutable
class CheckboxOption<T> {
  /// Creates a [CheckboxOption].
  const CheckboxOption({
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

/// Defaults for every [CheckboxGroup] under a `ConfigProvider`.
///
/// House style for checkbox groups.
@immutable
class CheckboxGroupDefaults {
  /// Creates a [CheckboxGroupDefaults].
  const CheckboxGroupDefaults({this.direction});

  /// Which way the boxes run.
  final Axis? direction;
}

/// A set of checkboxes selecting several values from a list.
///
/// ```dart
/// CheckboxGroup<String>(
///   value: _picked,
///   options: const [
///     CheckboxOption(value: 'a', label: 'Apple'),
///     CheckboxOption(value: 'b', label: 'Banana'),
///   ],
///   onChanged: (v) => setState(() => _picked = v),
/// )
/// ```
class CheckboxGroup<T> extends StatelessWidget {
  /// Creates a [CheckboxGroup].
  const CheckboxGroup({
    super.key,
    required this.value,
    required this.options,
    this.onChanged,
    this.disabled,
    this.direction,
    this.spacing = 16,
    this.runSpacing = 8,
  });

  /// The currently selected values.
  final List<T> value;

  /// The options, in order.
  final List<CheckboxOption<T>> options;

  /// Called with the full new selection whenever an option toggles.
  final ValueChanged<List<T>>? onChanged;

  /// Greys the whole group out.
  final bool? disabled;

  /// Whether this control is disabled: its own word, else the one set for
  /// the subtree, else no.
  bool _disabledIn(BuildContext context) =>
      disabled ?? ConfigProvider.componentDisabledOf(context) ?? false;

  /// Whether the options run in a row (wrapping) or a column.
  final Axis? direction;

  /// Gap between options along the run, in logical pixels.
  final double spacing;

  /// Gap between wrapped rows of options, in logical pixels.
  final double runSpacing;

  void _toggle(T optionValue, bool checked) {
    final next = List<T>.of(value);
    if (checked) {
      if (!next.contains(optionValue)) next.add(optionValue);
    } else {
      next.remove(optionValue);
    }
    onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final boxes = [
      for (final option in options)
        Checkbox(
          checked: value.contains(option.value),
          disabled:
              _disabledIn(context) || option.disabled || onChanged == null,
          onChanged: (checked) => _toggle(option.value, checked),
          label: option.label,
        ),
    ];

    if (_directionIn(context) == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < boxes.length; i++) ...[
            if (i > 0) SizedBox(height: runSpacing),
            boxes[i],
          ],
        ],
      );
    }
    return Wrap(spacing: spacing, runSpacing: runSpacing, children: boxes);
  }

  /// This widget's word, then the subtree's, then the kit's.
  Axis _directionIn(BuildContext context) =>
      direction ??
      ConfigProvider.defaultsOf<CheckboxGroupDefaults>(context)?.direction ??
      Axis.horizontal;
}
