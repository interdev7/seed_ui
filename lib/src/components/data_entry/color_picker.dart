import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/popover.dart';
import '../../utils/size_resolver.dart';
import '../data_display/segmented.dart';
import 'input.dart';
import 'input_number.dart';

/// How a [ColorPicker] writes a colour out in its fields.
enum ColorFormat {
  /// `#1677FF`.
  hex,

  /// Red, green and blue, each 0–255.
  rgb,

  /// Hue in degrees, saturation and brightness in per cent.
  hsb,
}

/// A titled run of ready colours offered under a [ColorPicker]'s panel: the
/// brand's, the last few used.
@immutable
class ColorPreset {
  /// Creates a [ColorPreset].
  const ColorPreset({required this.label, required this.colors});

  /// The heading over the colours.
  final String label;

  /// The colours, in order.
  final List<Color> colors;
}

/// Per-component design tokens for [ColorPicker] and [ColorPickerPanel].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(colorPicker: ColorPickerToken(...)))`, or per instance via
/// a widget's `token`.
@immutable
class ColorPickerToken {
  /// Creates a [ColorPickerToken].
  const ColorPickerToken({
    this.panelWidth,
    this.saturationHeight,
    this.sliderHeight,
    this.handleSize,
    this.presetSize,
    this.gap,
    this.borderRadius,
    this.checkerColor,
    this.checkerSize,
    this.panelBg,
    this.handleShadow,
  });

  /// How wide the panel is.
  final double? panelWidth;

  /// How tall the square where a shade is picked is.
  final double? saturationHeight;

  /// How thick the hue and opacity strips are.
  final double? sliderHeight;

  /// How big the round handle on the square and the strips is.
  final double? handleSize;

  /// How big a ready colour's swatch is.
  final double? presetSize;

  /// Space between the parts of the panel.
  final double? gap;

  /// The corners of the square, the swatches and the trigger.
  final double? borderRadius;

  /// The darker squares of the pattern shown through a clear colour.
  final Color? checkerColor;

  /// How big a square of that pattern is.
  final double? checkerSize;

  /// The panel's fill.
  final Color? panelBg;

  /// The shadow under a handle, so it stands off any colour it is on.
  final List<BoxShadow>? handleShadow;

  _ResolvedColorPickerToken _resolve(Token t) => _ResolvedColorPickerToken(
        handleShadow: handleShadow ??
            [
              BoxShadow(
                color: t.colorTextQuaternary,
                blurRadius: t.lineWidth * 2,
              ),
            ],
        panelWidth: panelWidth ?? t.controlHeight * 7,
        saturationHeight: saturationHeight ?? t.controlHeight * 5,
        sliderHeight: sliderHeight ?? t.sizeXS,
        handleSize: handleSize ?? t.size,
        presetSize: presetSize ?? t.fontSizeXL,
        gap: gap ?? t.sizeSM,
        borderRadius: borderRadius ?? t.borderRadiusSM,
        checkerColor: checkerColor ?? t.colorFillSecondary,
        checkerSize: checkerSize ?? t.sizeXXS,
        panelBg: panelBg ?? t.colorBgElevated,
      );

  /// This one with [other]'s fields laid over it, one field at a time.
  ColorPickerToken merge(ColorPickerToken other) => ColorPickerToken(
        handleShadow: other.handleShadow ?? handleShadow,
        panelWidth: other.panelWidth ?? panelWidth,
        saturationHeight: other.saturationHeight ?? saturationHeight,
        sliderHeight: other.sliderHeight ?? sliderHeight,
        handleSize: other.handleSize ?? handleSize,
        presetSize: other.presetSize ?? presetSize,
        gap: other.gap ?? gap,
        borderRadius: other.borderRadius ?? borderRadius,
        checkerColor: other.checkerColor ?? checkerColor,
        checkerSize: other.checkerSize ?? checkerSize,
        panelBg: other.panelBg ?? panelBg,
      );
}

@immutable
class _ResolvedColorPickerToken {
  const _ResolvedColorPickerToken({
    required this.panelWidth,
    required this.saturationHeight,
    required this.sliderHeight,
    required this.handleSize,
    required this.presetSize,
    required this.gap,
    required this.borderRadius,
    required this.checkerColor,
    required this.checkerSize,
    required this.panelBg,
    required this.handleShadow,
  });

  final double panelWidth;
  final double saturationHeight;
  final double sliderHeight;
  final double handleSize;
  final double presetSize;
  final double gap;
  final double borderRadius;
  final Color checkerColor;
  final double checkerSize;
  final Color panelBg;
  final List<BoxShadow> handleShadow;
}

/// Defaults for every [ColorPicker] and [ColorPickerPanel] under a
/// `ConfigProvider`.
@immutable
class ColorPickerDefaults {
  /// Creates a [ColorPickerDefaults].
  const ColorPickerDefaults({this.format, this.disabledAlpha, this.canCopy});

  /// How colours are written out at first.
  final ColorFormat? format;

  /// Whether colours are kept opaque, with no opacity strip.
  final bool? disabledAlpha;

  /// Whether the panel offers to copy the colour as it is written.
  final bool? canCopy;

  /// This one with [other]'s fields laid over it, one field at a time.
  ColorPickerDefaults merge(ColorPickerDefaults other) => ColorPickerDefaults(
        format: other.format ?? format,
        disabledAlpha: other.disabledAlpha ?? disabledAlpha,
        canCopy: other.canCopy ?? canCopy,
      );
}

/// `#RRGGBB`, or `#RRGGBBAA` for a colour that is not opaque.
String _toHex(Color color, {bool alpha = true}) {
  String two(double v) =>
      (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  final rgb = '${two(color.r)}${two(color.g)}${two(color.b)}';
  final a = alpha && color.a < 1 ? two(color.a) : '';
  return '#${(rgb + a).toUpperCase()}';
}

/// The colour [text] writes — `#RGB`, `#RRGGBB` or `#RRGGBBAA`, the `#`
/// optional — or null when it writes none.
Color? _fromHex(String text) {
  var hex = text.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) return null;
  if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
  if (hex.length == 6) hex = '${hex}ff';
  if (hex.length != 8) return null;
  final v = int.parse(hex, radix: 16);
  return Color.fromARGB(
      v & 0xff, (v >> 24) & 0xff, (v >> 16) & 0xff, (v >> 8) & 0xff);
}

/// A colour, chosen from a square of shades, a strip of hues and a strip of
/// opacity, typed in, or taken from ready ones.
///
/// ```dart
/// ColorPicker(
///   value: brand,
///   onChanged: (c) => setState(() => brand = c),
///   showText: true,
/// )
/// ```
///
/// The field is a swatch of the colour; a tap on it opens the panel under it.
/// For the panel alone, standing in a page, use [ColorPickerPanel].
class ColorPicker extends StatefulWidget {
  /// Creates a [ColorPicker].
  const ColorPicker({
    super.key,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.onChangeComplete,
    this.format,
    this.onFormatChanged,
    this.disabledAlpha,
    this.allowClear = false,
    this.canCopy,
    this.onCopy,
    this.copyIconBuilder,
    this.presets,
    this.showText = false,
    this.size,
    this.disabled = false,
    this.open,
    this.onOpenChanged,
    this.placement = PopoverPlacement.bottomLeft,
    this.child,
    this.semanticsLabel,
    this.token,
  });

  /// The colour, held from outside. Null with [defaultValue] null is no
  /// colour at all.
  final Color? value;

  /// The colour the picker starts with, when [value] is null.
  final Color? defaultValue;

  /// Called with the colour on every change, while a handle is still being
  /// dragged; with null when the colour is cleared.
  final ValueChanged<Color?>? onChanged;

  /// Called with the colour once a change is done: a handle let go, a field
  /// left, a ready colour taken.
  final ValueChanged<Color?>? onChangeComplete;

  /// How the panel writes the colour out. Null lets the panel keep its own,
  /// starting from [ColorFormat.hex].
  final ColorFormat? format;

  /// Called when the reader switches the way the colour is written.
  final ValueChanged<ColorFormat>? onFormatChanged;

  /// Whether the colour is kept opaque, with no opacity strip or field.
  /// Defaults to no.
  final bool? disabledAlpha;

  /// Whether the panel offers to clear the colour to none.
  final bool allowClear;

  /// Whether the panel offers to copy the colour, written as the fields
  /// write it. Defaults to no.
  final bool? canCopy;

  /// Called with the text put on the clipboard, once it is there: to say so
  /// in a message of your own, to count it.
  final ValueChanged<String>? onCopy;

  /// Draws the copy button's icon, told whether the colour was just copied.
  /// The colour comes from an `IconTheme` around it — the tertiary text
  /// colour, the success colour once copied — so an `Icon` takes it:
  ///
  /// ```dart
  /// copyIconBuilder: (context, copied) =>
  ///     Icon(copied ? Icons.check : Icons.content_copy),
  /// ```
  final Widget Function(BuildContext context, bool copied)? copyIconBuilder;

  /// Ready colours offered under the panel.
  final List<ColorPreset>? presets;

  /// Whether the colour's hex stands beside the swatch.
  final bool showText;

  /// How tall the field is: [SoftSize.small], [SoftSize.middle] (the
  /// default), [SoftSize.large], or a measurement of your own.
  final ControlSize? size;

  /// Greys the field out; it does not open.
  final bool disabled;

  /// Holds the panel open or shut from outside. Null lets a tap decide.
  final bool? open;

  /// Called when the panel wants to open or shut.
  final ValueChanged<bool>? onOpenChanged;

  /// Where the panel opens.
  final PopoverPlacement placement;

  /// A trigger of your own in place of the swatch: a button, a chip. A tap
  /// on it opens the panel.
  final Widget? child;

  /// What a screen reader calls the field: "Brand colour".
  final String? semanticsLabel;

  /// Per-instance token overrides, for the field and its panel.
  final ColorPickerToken? token;

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color? _own = widget.defaultValue;
  final PopoverController _popover = PopoverController();
  final GlobalKey _anchor = GlobalKey();
  final ValueNotifier<int> _revision = ValueNotifier(0);
  bool _shown = false;

  Color? get _color => widget.value ?? _own;

  @override
  void didUpdateWidget(ColorPicker old) {
    super.didUpdateWidget(old);
    final open = widget.open;
    if (open != null && open != _shown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) open ? _show() : _hide();
      });
    }
    if (_shown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _shown) _revision.value++;
      });
    }
  }

  @override
  void dispose() {
    _popover.dispose();
    _revision.dispose();
    super.dispose();
  }

  void _request(bool open) {
    if (widget.disabled) return;
    widget.onOpenChanged?.call(open);
    if (widget.open == null) open ? _show() : _hide();
  }

  void _show() {
    if (_shown) return;
    final box = _anchor.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    setState(() => _shown = true);
    _popover.open(
      placement: widget.placement,
      anchorRect: box.localToGlobal(Offset.zero) & box.size,
      gap: context.softToken.sizeXXS,
      onDismiss: () => _request(false),
      anchorContext: context,
      onScrollDismiss: () => _request(false),
      builder: (context) => ValueListenableBuilder<int>(
        valueListenable: _revision,
        builder: (context, _, __) => ColorPickerPanel(
          value: _color,
          onChanged: _change,
          onChangeComplete: widget.onChangeComplete,
          format: widget.format,
          onFormatChanged: widget.onFormatChanged,
          disabledAlpha: widget.disabledAlpha,
          allowClear: widget.allowClear,
          canCopy: widget.canCopy,
          onCopy: widget.onCopy,
          copyIconBuilder: widget.copyIconBuilder,
          presets: widget.presets,
          token: widget.token,
        ),
      ),
    );
  }

  void _hide() {
    if (!_shown) return;
    _popover.close();
    if (mounted) setState(() => _shown = false);
  }

  void _change(Color? color) {
    if (widget.value == null) setState(() => _own = color);
    widget.onChanged?.call(color);
    _revision.value++;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<ColorPickerToken>(context) ??
            const ColorPickerToken())
        ._resolve(t);
    final height = (widget.size ??
            ConfigProvider.componentSizeOf(context) ??
            SoftSize.middle)
        .resolveHeight(
      small: t.controlHeightSM,
      middle: t.controlHeight,
      large: t.controlHeightLG,
    );
    final color = _color;
    final words = color == null ? context.seedLocale.noColor : _toHex(color);

    final Widget trigger = widget.child ??
        Container(
          height: height,
          padding: EdgeInsets.all(t.sizeXXS - t.lineWidth),
          decoration: BoxDecoration(
            color: widget.disabled ? t.colorFillTertiary : t.colorBgContainer,
            borderRadius: BorderRadius.circular(r.borderRadius + t.sizeXXS),
            border: Border.all(
              color: _shown ? t.primary.base : t.colorBorder,
              width: t.lineWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Swatch(
                color: color,
                size: height - t.sizeXXS * 2,
                token: r,
              ),
              if (widget.showText) ...[
                SizedBox(width: t.sizeXS),
                Text(
                  words,
                  style: TextStyle(
                    color:
                        widget.disabled ? t.colorTextQuaternary : t.colorText,
                    fontSize: t.fontSize,
                    fontFamily: t.fontFamily,
                    fontFamilyFallback: t.fontFamilyFallback,
                    decoration: TextDecoration.none,
                  ),
                ),
                SizedBox(width: t.sizeXS - t.sizeXXS),
              ],
            ],
          ),
        );

    return Semantics(
      button: true,
      enabled: !widget.disabled,
      expanded: _shown,
      label: widget.semanticsLabel,
      value: words,
      onTap: widget.disabled ? null : () => _request(!_shown),
      child: FocusableActionDetector(
        enabled: !widget.disabled,
        mouseCursor: widget.disabled
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _request(!_shown);
              return null;
            },
          ),
        },
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTap: widget.disabled ? null : () => _request(!_shown),
          child: KeyedSubtree(
            key: _anchor,
            child: ExcludeSemantics(child: trigger),
          ),
        ),
      ),
    );
  }
}

/// The panel of a [ColorPicker], standing on its own: in a page, a drawer,
/// a card.
///
/// ```dart
/// ColorPickerPanel(
///   value: colour,
///   onChanged: (c) => setState(() => colour = c),
/// )
/// ```
class ColorPickerPanel extends StatefulWidget {
  /// Creates a [ColorPickerPanel].
  const ColorPickerPanel({
    super.key,
    required this.value,
    this.onChanged,
    this.onChangeComplete,
    this.format,
    this.onFormatChanged,
    this.disabledAlpha,
    this.allowClear = false,
    this.canCopy,
    this.onCopy,
    this.copyIconBuilder,
    this.presets,
    this.token,
  });

  /// The colour shown; null is no colour.
  final Color? value;

  /// Called with the colour on every change, while a handle is still being
  /// dragged; with null when the colour is cleared.
  final ValueChanged<Color?>? onChanged;

  /// Called with the colour once a change is done.
  final ValueChanged<Color?>? onChangeComplete;

  /// How the colour is written out. Null lets the panel keep its own.
  final ColorFormat? format;

  /// Called when the reader switches the way the colour is written.
  final ValueChanged<ColorFormat>? onFormatChanged;

  /// Whether the colour is kept opaque, with no opacity strip or field.
  final bool? disabledAlpha;

  /// Whether the panel offers to clear the colour to none.
  final bool allowClear;

  /// Whether the panel offers to copy the colour, written as the fields
  /// write it: `#1677FF`, `rgb(22, 119, 255)`, `hsb(215, 91%, 100%)`.
  /// Defaults to no.
  final bool? canCopy;

  /// Called with the text put on the clipboard, once it is there: to say so
  /// in a message of your own, to count it.
  final ValueChanged<String>? onCopy;

  /// Draws the copy button's icon, told whether the colour was just copied.
  /// The colour comes from an `IconTheme` around it — the tertiary text
  /// colour, the success colour once copied — so an `Icon` takes it:
  ///
  /// ```dart
  /// copyIconBuilder: (context, copied) =>
  ///     Icon(copied ? Icons.check : Icons.content_copy),
  /// ```
  final Widget Function(BuildContext context, bool copied)? copyIconBuilder;

  /// Ready colours offered under the panel.
  final List<ColorPreset>? presets;

  /// Per-instance token overrides.
  final ColorPickerToken? token;

  @override
  State<ColorPickerPanel> createState() => _ColorPickerPanelState();
}

class _ColorPickerPanelState extends State<ColorPickerPanel> {
  /// The colour as hue, saturation and value, so a grey or a black keeps the
  /// hue it was dragged to: a colour alone has none to give back.
  late HSVColor _hsv = _fromColor(widget.value);
  late ColorFormat _ownFormat = ConfigProvider.defaultsOf<ColorPickerDefaults>(
        context,
      )?.format ??
      ColorFormat.hex;

  ColorFormat get _format => widget.format ?? _ownFormat;
  bool get _noAlpha =>
      widget.disabledAlpha ??
      ConfigProvider.defaultsOf<ColorPickerDefaults>(context)?.disabledAlpha ??
      false;

  bool get _canCopy =>
      widget.canCopy ??
      ConfigProvider.defaultsOf<ColorPickerDefaults>(context)?.canCopy ??
      false;

  /// The colour as the fields write it, ready to paste where it is wanted.
  String _written(HSVColor hsv) {
    final c = hsv.toColor();
    final see = c.a < 1;
    int byte(double v) => (v * 255).round();
    String part(double v) => '${(v * 100).round()}%';
    final alpha = (c.a * 100).round() / 100;
    return switch (_format) {
      ColorFormat.hex => _toHex(c),
      ColorFormat.rgb => see
          ? 'rgba(${byte(c.r)}, ${byte(c.g)}, ${byte(c.b)}, $alpha)'
          : 'rgb(${byte(c.r)}, ${byte(c.g)}, ${byte(c.b)})',
      ColorFormat.hsb => see
          ? 'hsba(${hsv.hue.round()}, ${part(hsv.saturation)}, '
              '${part(hsv.value)}, $alpha)'
          : 'hsb(${hsv.hue.round()}, ${part(hsv.saturation)}, '
              '${part(hsv.value)})',
    };
  }

  static HSVColor _fromColor(Color? c) =>
      HSVColor.fromColor(c ?? const Color(0xFF1677FF));

  @override
  void didUpdateWidget(ColorPickerPanel old) {
    super.didUpdateWidget(old);
    final value = widget.value;
    if (value != null && value != _hsv.toColor()) {
      final next = HSVColor.fromColor(value);
      // A grey from outside keeps the hue the strip stood at.
      _hsv = next.saturation == 0 || next.value == 0
          ? next.withHue(_hsv.hue)
          : next;
    }
  }

  void _set(HSVColor hsv, {bool done = false}) {
    final next = _noAlpha ? hsv.withAlpha(1) : hsv;
    setState(() => _hsv = next);
    widget.onChanged?.call(next.toColor());
    if (done) widget.onChangeComplete?.call(next.toColor());
  }

  void _done() => widget.onChangeComplete?.call(_hsv.toColor());

  void _take(Color? color) {
    if (color == null) {
      widget.onChanged?.call(null);
      widget.onChangeComplete?.call(null);
      setState(() {});
      return;
    }
    _set(HSVColor.fromColor(color), done: true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<ColorPickerToken>(context) ??
            const ColorPickerToken())
        ._resolve(t);
    final locale = context.seedLocale;
    final hsv = _hsv;
    final color = hsv.toColor();
    final none = widget.value == null;
    String percent(double v) => locale.figures('${(v * 100).round()}%');

    final square = _Area(
      hsv: hsv,
      token: r,
      semanticsLabel: locale.colorSaturation,
      onChanged: (s, v) => _set(hsv.withSaturation(s).withValue(v)),
      onDone: _done,
    );

    final hue = _Strip(
      value: hsv.hue / 360,
      token: r,
      thumb: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
      semanticsLabel: locale.colorHue,
      describe: (v) => locale.figures('${(v * 360).round()}°'),
      paint: (rect) => LinearGradient(
        colors: [
          for (var h = 0; h <= 360; h += 60)
            HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
        ],
      ),
      onChanged: (v) => _set(hsv.withHue((v * 360).clamp(0, 360))),
      onDone: _done,
    );

    final alpha = _noAlpha
        ? null
        : _Strip(
            value: hsv.alpha,
            token: r,
            thumb: color,
            checker: true,
            semanticsLabel: locale.colorAlpha,
            describe: percent,
            paint: (rect) => LinearGradient(
              colors: [color.withValues(alpha: 0), color.withValues(alpha: 1)],
            ),
            onChanged: (v) => _set(hsv.withAlpha(v)),
            onDone: _done,
          );

    const fieldSize = SoftSize.small;
    Widget number(
      String label,
      num value,
      num max,
      void Function(num) onSet, {
      String? suffix,
    }) =>
        Expanded(
          child: InputNumber(
            value: value,
            min: 0,
            max: max,
            controls: false,
            size: fieldSize,
            semanticsLabel: label,
            suffix: suffix == null ? null : Text(suffix),
            onChanged: (v) {
              if (v != null) onSet(v);
            },
            onSubmitted: (_) => _done(),
          ),
        );

    final fields = switch (_format) {
      ColorFormat.hex => [
          Expanded(
            child: _HexField(
              color: color,
              onColor: (c) =>
                  _set(HSVColor.fromColor(c).withAlpha(hsv.alpha), done: true),
            ),
          ),
        ],
      ColorFormat.rgb => [
          for (final (i, label) in const ['R', 'G', 'B'].indexed) ...[
            if (i > 0) SizedBox(width: t.sizeXXS),
            number(
              label,
              ([color.r, color.g, color.b][i] * 255).round(),
              255,
              (v) {
                final c = color;
                final parts = [c.r, c.g, c.b]..[i] = v / 255;
                _set(
                  HSVColor.fromColor(
                    Color.from(
                      alpha: c.a,
                      red: parts[0],
                      green: parts[1],
                      blue: parts[2],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ColorFormat.hsb => [
          number('H', hsv.hue.round(), 360,
              (v) => _set(hsv.withHue(v.toDouble()))),
          SizedBox(width: t.sizeXXS),
          number(
            'S',
            (hsv.saturation * 100).round(),
            100,
            (v) => _set(hsv.withSaturation(v / 100)),
            suffix: '%',
          ),
          SizedBox(width: t.sizeXXS),
          number(
            'B',
            (hsv.value * 100).round(),
            100,
            (v) => _set(hsv.withValue(v / 100)),
            suffix: '%',
          ),
        ],
    };

    final presets = widget.presets ?? const <ColorPreset>[];

    return Container(
      width: r.panelWidth + r.gap * 2,
      padding: EdgeInsets.all(r.gap),
      decoration: BoxDecoration(
        color: r.panelBg,
        borderRadius: BorderRadius.circular(t.borderRadiusLG),
        boxShadow: t.boxShadowSecondary,
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: t.colorText,
          fontSize: t.fontSizeSM,
          fontFamily: t.fontFamily,
          fontFamilyFallback: t.fontFamilyFallback,
          decoration: TextDecoration.none,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            square,
            SizedBox(height: r.gap),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      hue,
                      if (alpha != null) ...[
                        SizedBox(height: r.gap / 2),
                        alpha,
                      ],
                    ],
                  ),
                ),
                SizedBox(width: r.gap / 2),
                _Swatch(
                    color: none ? null : color,
                    size: r.presetSize + t.sizeXXS * 2,
                    token: r),
              ],
            ),
            SizedBox(height: r.gap),
            Row(
              children: [
                Segmented<ColorFormat>(
                  size: SoftSize.small,
                  value: _format,
                  options: const [
                    SegmentedOption(value: ColorFormat.hex, label: 'HEX'),
                    SegmentedOption(value: ColorFormat.rgb, label: 'RGB'),
                    SegmentedOption(value: ColorFormat.hsb, label: 'HSB'),
                  ],
                  onChanged: (f) {
                    if (widget.format == null) setState(() => _ownFormat = f);
                    widget.onFormatChanged?.call(f);
                  },
                ),
                if (widget.allowClear) ...[
                  const Spacer(),
                  _PresetSwatch(
                    color: null,
                    token: r,
                    chosen: none,
                    label: locale.noColor,
                    onTap: () => _take(null),
                  ),
                ],
              ],
            ),
            SizedBox(height: r.gap / 2),
            Row(
              children: [
                ...fields,
                if (!_noAlpha) ...[
                  SizedBox(width: t.sizeXXS),
                  SizedBox(
                    width: t.controlHeight * 2,
                    child: InputNumber(
                      value: (hsv.alpha * 100).round(),
                      min: 0,
                      max: 100,
                      controls: false,
                      size: fieldSize,
                      semanticsLabel: locale.colorAlpha,
                      suffix: const Text('%'),
                      onChanged: (v) {
                        if (v != null) _set(hsv.withAlpha(v / 100));
                      },
                      onSubmitted: (_) => _done(),
                    ),
                  ),
                ],
                if (_canCopy && !none) ...[
                  SizedBox(width: t.sizeXXS),
                  _CopyButton(
                    text: _written(hsv),
                    onCopy: widget.onCopy,
                    iconBuilder: widget.copyIconBuilder,
                  ),
                ],
              ],
            ),
            for (final preset in presets) ...[
              SizedBox(height: r.gap),
              Text(
                preset.label,
                style: TextStyle(color: t.colorTextTertiary),
              ),
              SizedBox(height: t.sizeXXS),
              Wrap(
                spacing: t.sizeXXS * 1.5,
                runSpacing: t.sizeXXS * 1.5,
                children: [
                  for (final c in preset.colors)
                    _PresetSwatch(
                      color: c,
                      token: r,
                      chosen: !none && c.toARGB32() == color.toARGB32(),
                      label: _toHex(c),
                      onTap: () => _take(c),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The hex field: the colour as `RRGGBB`, taken as soon as it writes one.
class _HexField extends StatefulWidget {
  const _HexField({required this.color, required this.onColor});

  final Color color;
  final ValueChanged<Color> onColor;

  @override
  State<_HexField> createState() => _HexFieldState();
}

class _HexFieldState extends State<_HexField> {
  late final TextEditingController _controller =
      TextEditingController(text: _hex(widget.color));
  final FocusNode _focus = FocusNode();

  static String _hex(Color c) => _toHex(c, alpha: false).substring(1);

  @override
  void didUpdateWidget(_HexField old) {
    super.didUpdateWidget(old);
    // Rewritten from the colour unless the reader is in the middle of typing
    // it: a half-typed hex is not a colour yet, and must not be replaced.
    final next = _hex(widget.color);
    if (!_focus.hasFocus && _controller.text.toUpperCase() != next) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Input(
        controller: _controller,
        focusNode: _focus,
        size: SoftSize.small,
        semanticsLabel: 'HEX',
        prefix: const Text('#'),
        autocorrect: false,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
          LengthLimitingTextInputFormatter(6),
        ],
        onChanged: (text) {
          if (text.length != 6 && text.length != 3) return;
          final c = _fromHex(text);
          if (c != null) widget.onColor(c);
        },
      );
}

/// The square where a shade is picked: saturation along it, brightness up
/// it, in the hue of the strip.
class _Area extends StatefulWidget {
  const _Area({
    required this.hsv,
    required this.token,
    required this.semanticsLabel,
    required this.onChanged,
    required this.onDone,
  });

  final HSVColor hsv;
  final _ResolvedColorPickerToken token;
  final String semanticsLabel;
  final void Function(double saturation, double value) onChanged;
  final VoidCallback onDone;

  @override
  State<_Area> createState() => _AreaState();
}

class _AreaState extends State<_Area> {
  bool _focused = false;

  void _at(Offset p, Size size) => widget.onChanged(
        (p.dx / size.width).clamp(0.0, 1.0),
        (1 - p.dy / size.height).clamp(0.0, 1.0),
      );

  void _nudge(double ds, double dv) {
    widget.onChanged(
      (widget.hsv.saturation + ds).clamp(0.0, 1.0),
      (widget.hsv.value + dv).clamp(0.0, 1.0),
    );
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = widget.token;
    final hsv = widget.hsv;
    final locale = context.seedLocale;
    final ltr = Directionality.maybeOf(context) != TextDirection.rtl;
    const step = 0.01;
    return Semantics(
      label: widget.semanticsLabel,
      value: locale.figures(
        '${(hsv.saturation * 100).round()}%, ${(hsv.value * 100).round()}%',
      ),
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.precise,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        shortcuts: {
          SingleActivator(
            ltr ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft,
          ): const _Nudge(step, 0),
          SingleActivator(
            ltr ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight,
          ): const _Nudge(-step, 0),
          const SingleActivator(LogicalKeyboardKey.arrowUp):
              const _Nudge(0, step),
          const SingleActivator(LogicalKeyboardKey.arrowDown):
              const _Nudge(0, -step),
        },
        actions: {
          _Nudge: CallbackAction<_Nudge>(
            onInvoke: (n) {
              _nudge(n.across, n.up);
              return null;
            },
          ),
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, r.saturationHeight);
            return GestureDetector(
              excludeFromSemantics: true,
              onPanDown: (d) => _at(d.localPosition, size),
              onPanUpdate: (d) => _at(d.localPosition, size),
              onPanEnd: (_) => widget.onDone(),
              onPanCancel: widget.onDone,
              child: SizedBox.fromSize(
                size: size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(r.borderRadius),
                          boxShadow: _focused
                              ? [
                                  BoxShadow(
                                    color:
                                        t.primary.base.withValues(alpha: 0.12),
                                    blurRadius: 0,
                                    spreadRadius: t.focusRingWidth,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(r.borderRadius),
                          child: CustomPaint(
                            painter: _AreaPainter(hsv.hue),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: hsv.saturation * size.width - r.handleSize / 2,
                      top: (1 - hsv.value) * size.height - r.handleSize / 2,
                      child: _Handle(
                        size: r.handleSize,
                        color: hsv.withAlpha(1).toColor(),
                        shadow: r.handleShadow,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Nudge extends Intent {
  const _Nudge(this.across, this.up);

  final double across;
  final double up;
}

class _AreaPainter extends CustomPainter {
  _AreaPainter(this.hue);

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas
      ..drawRect(
          rect, Paint()..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor())
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
          ).createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0xFF000000)],
          ).createShader(rect),
      );
  }

  @override
  bool shouldRepaint(_AreaPainter old) => old.hue != hue;
}

/// A strip with a handle along it: the hue, or the opacity.
class _Strip extends StatefulWidget {
  const _Strip({
    required this.value,
    required this.token,
    required this.thumb,
    required this.semanticsLabel,
    required this.describe,
    required this.paint,
    required this.onChanged,
    required this.onDone,
    this.checker = false,
  });

  final double value;
  final _ResolvedColorPickerToken token;
  final Color thumb;
  final String semanticsLabel;
  final String Function(double value) describe;
  final Gradient Function(Rect rect) paint;
  final ValueChanged<double> onChanged;
  final VoidCallback onDone;

  /// Whether the clear pattern shows through, for the opacity strip.
  final bool checker;

  @override
  State<_Strip> createState() => _StripState();
}

class _StripState extends State<_Strip> {
  bool _focused = false;

  void _step(double by) {
    widget.onChanged((widget.value + by).clamp(0.0, 1.0));
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = widget.token;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final up = (widget.value + 0.01).clamp(0.0, 1.0);
    final down = (widget.value - 0.01).clamp(0.0, 1.0);
    return Semantics(
      slider: true,
      label: widget.semanticsLabel,
      value: widget.describe(widget.value),
      increasedValue: widget.describe(up),
      decreasedValue: widget.describe(down),
      onIncrease: () => _step(0.01),
      onDecrease: () => _step(-0.01),
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        shortcuts: {
          SingleActivator(
            rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight,
          ): const _Nudge(0.01, 0),
          const SingleActivator(LogicalKeyboardKey.arrowUp):
              const _Nudge(0.01, 0),
          SingleActivator(
            rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft,
          ): const _Nudge(-0.01, 0),
          const SingleActivator(LogicalKeyboardKey.arrowDown):
              const _Nudge(-0.01, 0),
        },
        actions: {
          _Nudge: CallbackAction<_Nudge>(
            onInvoke: (n) {
              _step(n.across);
              return null;
            },
          ),
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            // The handle stands inside the strip at both ends, so its centre
            // travels the strip less the handle's own width.
            final travel = math.max(1.0, width - r.handleSize);
            double at(double x) =>
                ((x - r.handleSize / 2) / travel).clamp(0.0, 1.0);
            final along = rtl ? 1 - widget.value : widget.value;
            return GestureDetector(
              excludeFromSemantics: true,
              onHorizontalDragDown: (d) {
                final v = at(d.localPosition.dx);
                widget.onChanged(rtl ? 1 - v : v);
              },
              onHorizontalDragUpdate: (d) {
                final v = at(d.localPosition.dx);
                widget.onChanged(rtl ? 1 - v : v);
              },
              onHorizontalDragEnd: (_) => widget.onDone(),
              onHorizontalDragCancel: widget.onDone,
              child: SizedBox(
                height: r.handleSize,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      child: Container(
                        height: r.sliderHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(r.sliderHeight),
                          boxShadow: _focused
                              ? [
                                  BoxShadow(
                                    color:
                                        t.primary.base.withValues(alpha: 0.12),
                                    blurRadius: 0,
                                    spreadRadius: t.focusRingWidth,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(r.sliderHeight),
                          child: CustomPaint(
                            painter: _StripPainter(
                              gradient: widget.paint,
                              checker: widget.checker
                                  ? (r.checkerColor, r.checkerSize)
                                  : null,
                              rtl: rtl,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: along * travel,
                      child: _Handle(
                        size: r.handleSize,
                        color: widget.thumb,
                        shadow: r.handleShadow,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StripPainter extends CustomPainter {
  _StripPainter(
      {required this.gradient, required this.checker, required this.rtl});

  final Gradient Function(Rect rect) gradient;
  final (Color, double)? checker;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final pattern = checker;
    if (pattern != null) _paintChecker(canvas, rect, pattern.$1, pattern.$2);
    if (rtl) {
      canvas
        ..save()
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    canvas.drawRect(rect, Paint()..shader = gradient(rect).createShader(rect));
    if (rtl) canvas.restore();
  }

  @override
  bool shouldRepaint(_StripPainter old) => true;
}

void _paintChecker(Canvas canvas, Rect rect, Color color, double cell) {
  canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFFFF));
  final paint = Paint()..color = color;
  for (var y = rect.top; y < rect.bottom; y += cell) {
    for (var x = rect.left; x < rect.right; x += cell) {
      final odd =
          (((x - rect.left) / cell).round() + ((y - rect.top) / cell).round())
              .isOdd;
      if (odd) canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), paint);
    }
  }
}

/// The round handle on the square and the strips: the colour it stands on,
/// in a white ring.
class _Handle extends StatelessWidget {
  const _Handle({
    required this.size,
    required this.color,
    required this.shadow,
  });

  final double size;
  final Color color;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFFFFFFF),
            width: context.softToken.lineWidth * 2,
          ),
          boxShadow: shadow,
        ),
      );
}

/// A colour in a rounded square, the clear pattern showing through; no
/// colour at all is a white square struck through in red.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.size, required this.token});

  final Color? color;
  final double size;
  final _ResolvedColorPickerToken token;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(token.borderRadius),
          child: CustomPaint(
            painter: _SwatchPainter(
              color: color,
              checker: token.checkerColor,
              cell: token.checkerSize,
              strike: context.softToken.error.base,
              line: context.softToken.lineWidth,
            ),
          ),
        ),
      );
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter({
    required this.color,
    required this.checker,
    required this.cell,
    required this.strike,
    required this.line,
  });

  final Color? color;
  final Color checker;
  final double cell;
  final Color strike;
  final double line;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final c = color;
    if (c == null) {
      canvas
        ..drawRect(rect, Paint()..color = const Color(0xFFFFFFFF))
        ..drawLine(
          rect.bottomLeft,
          rect.topRight,
          Paint()
            ..color = strike
            ..strokeWidth = line * 2,
        );
      return;
    }
    if (c.a < 1) _paintChecker(canvas, rect, checker, cell);
    canvas.drawRect(rect, Paint()..color = c);
  }

  @override
  bool shouldRepaint(_SwatchPainter old) =>
      old.color != color || old.checker != checker || old.strike != strike;
}

/// A ready colour to take, ringed while it is the colour — or, with no
/// colour, the swatch that clears it to none.
class _PresetSwatch extends StatelessWidget {
  const _PresetSwatch({
    required this.color,
    required this.token,
    required this.chosen,
    required this.label,
    required this.onTap,
  });

  final Color? color;
  final _ResolvedColorPickerToken token;
  final bool chosen;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    // The clear swatch is white: without a line round it, it is not there.
    final rest =
        color == null ? t.colorBorder : t.colorBorder.withValues(alpha: 0);
    return Semantics(
      button: true,
      selected: chosen,
      label: label,
      onTap: onTap,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          excludeFromSemantics: true,
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(t.lineWidth * 2),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(token.borderRadius + t.lineWidth * 2),
              border: Border.all(
                color: chosen ? t.primary.base : rest,
                width: t.lineWidth,
              ),
            ),
            child: _Swatch(color: color, size: token.presetSize, token: token),
          ),
        ),
      ),
    );
  }
}

/// A small button that copies [text], and shows a tick for a moment after.
class _CopyButton extends StatefulWidget {
  const _CopyButton({
    required this.text,
    this.onCopy,
    this.iconBuilder,
  });

  final String text;
  final ValueChanged<String>? onCopy;
  final Widget Function(BuildContext context, bool copied)? iconBuilder;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;
  bool _hovered = false;
  Timer? _back;

  @override
  void dispose() {
    _back?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    widget.onCopy?.call(widget.text);
    setState(() => _copied = true);
    _back?.cancel();
    // Long enough to be seen, short enough to copy again.
    _back = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final locale = context.seedLocale;
    final side = t.controlHeightSM;
    final ink = _copied ? t.success.base : t.colorTextTertiary;
    return Semantics(
      button: true,
      // Said out loud as it changes: a copy makes no sound of its own.
      liveRegion: _copied,
      label: _copied ? locale.copied : locale.copy,
      onTap: _copy,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _copy();
              return null;
            },
          ),
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            excludeFromSemantics: true,
            behavior: HitTestBehavior.opaque,
            onTap: _copy,
            child: Container(
              width: side,
              height: side,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _hovered
                    ? t.colorFillSecondary
                    : t.colorFillSecondary.withValues(alpha: 0),
                borderRadius: BorderRadius.circular(t.borderRadiusSM),
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: ink, size: t.fontSize),
                child: widget.iconBuilder?.call(context, _copied) ??
                    SizedBox.square(
                      dimension: t.fontSize,
                      child: CustomPaint(
                        painter: _copied
                            ? CheckPainter(color: ink)
                            : _CopyGlyph(ink, t.lineWidth * 1.4),
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two sheets, one over the other: the sign for a copy.
class _CopyGlyph extends CustomPainter {
  _CopyGlyph(this.color, this.stroke);

  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round;
    final r = Radius.circular(w * 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.32, h * 0.08, w * 0.6, h * 0.66), r),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.2, h * 0.28)
        ..lineTo(w * 0.08, h * 0.28)
        ..lineTo(w * 0.08, h * 0.92)
        ..lineTo(w * 0.6, h * 0.92)
        ..lineTo(w * 0.6, h * 0.82),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CopyGlyph old) =>
      old.color != color || old.stroke != stroke;
}
