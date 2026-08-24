import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../data_display/tooltip.dart';

/// A labelled point on a [Slider]'s scale.
@immutable
class SliderMark {
  /// Creates a [SliderMark] at [value].
  const SliderMark(this.value, this.label, {this.style});

  /// Where on the scale it sits. Must lie within the slider's own range.
  final double value;

  /// What is written under it.
  final Widget label;

  /// Overrides the label's style for this mark alone.
  final TextStyle? style;
}

/// Per-component design tokens for [Slider] and [RangeSlider].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(slider: SliderToken(...)))`, or per instance via `token`.
@immutable
class SliderToken {
  /// Creates a [SliderToken].
  const SliderToken({
    this.railSize,
    this.handleSize,
    this.handleSizeHover,
    this.dotSize,
    this.handleLineWidth,
    this.handleLineWidthHover,
    this.railBg,
    this.railHoverBg,
    this.trackBg,
    this.trackHoverBg,
    this.handleColor,
    this.handleActiveColor,
    this.handleColorDisabled,
    this.trackBgDisabled,
    this.dotBorderColor,
    this.dotActiveBorderColor,
  });

  /// Thickness of the groove (`railSize`).
  final double? railSize;

  /// Diameter of the handle at rest (`handleSize`).
  final double? handleSize;

  /// Diameter of the handle under the pointer (`handleSizeHover`).
  final double? handleSizeHover;

  /// Diameter of a mark's dot (`dotSize`).
  final double? dotSize;

  /// Thickness of the ring around a handle (`handleLineWidth`).
  final double? handleLineWidth;

  /// Thickness of that ring under the pointer (`handleLineWidthHover`).
  final double? handleLineWidthHover;

  /// The groove behind the track (`railBg`).
  final Color? railBg;

  /// The groove while the pointer is over the slider (`railHoverBg`).
  final Color? railHoverBg;

  /// The filled part of the groove (`trackBg`).
  final Color? trackBg;

  /// That fill under the pointer (`trackHoverBg`).
  final Color? trackHoverBg;

  /// The handle's ring at rest (`handleColor`).
  final Color? handleColor;

  /// The handle's ring while it is being moved (`handleActiveColor`).
  final Color? handleActiveColor;

  /// The handle's ring when the slider is disabled (`handleColorDisabled`).
  final Color? handleColorDisabled;

  /// The filled groove when the slider is disabled (`trackBgDisabled`).
  final Color? trackBgDisabled;

  /// A mark's dot before the handle reaches it (`dotBorderColor`).
  final Color? dotBorderColor;

  /// A mark's dot once it has (`dotActiveBorderColor`).
  final Color? dotActiveBorderColor;

  _ResolvedSliderToken _resolve(Token t) {
    // The handle is a quarter of the large control, as it is in Ant Design,
    // so it grows with the theme's own scale rather than a number of its own.
    final size = t.controlHeightLG / 4;
    return _ResolvedSliderToken(
      railSize: railSize ?? 4,
      handleSize: handleSize ?? size,
      handleSizeHover: handleSizeHover ?? t.controlHeightSM / 2,
      dotSize: dotSize ?? 8,
      handleLineWidth: handleLineWidth ?? t.lineWidth + 1,
      handleLineWidthHover: handleLineWidthHover ?? t.lineWidth + 1.5,
      railBg: railBg ?? t.colorFillTertiary,
      railHoverBg: railHoverBg ?? t.colorFillSecondary,
      trackBg: trackBg ?? t.primary.border,
      trackHoverBg: trackHoverBg ?? t.primary.borderHover,
      handleColor: handleColor ?? t.primary.border,
      handleActiveColor: handleActiveColor ?? t.primary.base,
      handleColorDisabled: handleColorDisabled ?? t.colorTextQuaternary,
      trackBgDisabled: trackBgDisabled ?? t.colorFill,
      dotBorderColor: dotBorderColor ?? t.colorBorderSecondary,
      dotActiveBorderColor: dotActiveBorderColor ?? t.primary.border,
    );
  }
}

@immutable
class _ResolvedSliderToken {
  const _ResolvedSliderToken({
    required this.railSize,
    required this.handleSize,
    required this.handleSizeHover,
    required this.dotSize,
    required this.handleLineWidth,
    required this.handleLineWidthHover,
    required this.railBg,
    required this.railHoverBg,
    required this.trackBg,
    required this.trackHoverBg,
    required this.handleColor,
    required this.handleActiveColor,
    required this.handleColorDisabled,
    required this.trackBgDisabled,
    required this.dotBorderColor,
    required this.dotActiveBorderColor,
  });

  final double railSize;
  final double handleSize;
  final double handleSizeHover;
  final double dotSize;
  final double handleLineWidth;
  final double handleLineWidthHover;
  final Color railBg;
  final Color railHoverBg;
  final Color trackBg;
  final Color trackHoverBg;
  final Color handleColor;
  final Color handleActiveColor;
  final Color handleColorDisabled;
  final Color trackBgDisabled;
  final Color dotBorderColor;
  final Color dotActiveBorderColor;
}

/// Defaults for every [Slider] under a `ConfigProvider`.
///
/// House style for sliders.
@immutable
class SliderDefaults {
  /// Creates a [SliderDefaults].
  const SliderDefaults({this.dots, this.included});

  /// Whether the marks are drawn as dots.
  final bool? dots;

  /// Whether the track fills up to the handle.
  final bool? included;
}

/// A groove with a handle, for choosing a number by dragging.
///
/// ```dart
/// Slider(value: _volume, onChanged: (v) => setState(() => _volume = v))
/// ```
///
/// [min] and [max] bound the scale and [step] is how finely it moves; a null
/// step with [marks] lets the handle rest only on the marks themselves.
///
/// For two handles and the span between them, see [RangeSlider].
class Slider extends StatefulWidget {
  /// Creates a [Slider].
  const Slider({
    super.key,
    required this.value,
    this.onChanged,
    this.onChangeComplete,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.marks = const [],
    this.dots,
    this.included,
    this.disabled,
    this.vertical = false,
    this.reverse = false,
    this.tooltip,
    this.token,
  })  : assert(min < max, 'min must be less than max'),
        assert(step == null || step > 0, 'step must be positive');

  /// Where the handle stands.
  final double value;

  /// Called as the handle moves. Null, with no [onChangeComplete], makes the
  /// slider read-only.
  final ValueChanged<double>? onChanged;

  /// Called once the drag ends, with the value it came to rest at.
  final ValueChanged<double>? onChangeComplete;

  /// The bottom of the scale.
  final double min;

  /// The top of the scale.
  final double max;

  /// How far one move takes the handle. Null makes the handle rest only on
  /// [marks] — and on [min] and [max] — rather than anywhere between.
  final double? step;

  /// Points written along the scale.
  final List<SliderMark> marks;

  /// Whether every step is dotted, not only the marked ones.
  final bool? dots;

  /// Whether the groove is filled up to the handle, or only marked at it.
  ///
  /// False leaves the groove plain and greys the marks the handle has passed —
  /// for a slider that names a point rather than an amount.
  final bool? included;

  /// Greys the slider out and blocks dragging.
  final bool? disabled;

  /// Runs the scale down the page instead of across it.
  final bool vertical;

  /// Starts the scale at the far end.
  ///
  /// Reading right to left already turns the scale round, so this flips it
  /// back — the same rule Ant Design applies.
  final bool reverse;

  /// What to show above the handle while it is being moved.
  ///
  /// Returning null shows nothing. Left null the value is shown as it stands.
  final String? Function(double value)? tooltip;

  /// Per-instance token overrides.
  final SliderToken? token;

  @override
  State<Slider> createState() => _SliderState();
}

class _SliderState extends State<Slider> {
  /// The defaults set for this component in the subtree, if any.
  SliderDefaults? get _defaults =>
      ConfigProvider.defaultsOf<SliderDefaults>(context);

  /// This widget's word, then the subtree's, then the kit's.
  bool get _dots => widget.dots ?? _defaults?.dots ?? false;

  /// This widget's word, then the subtree's, then the kit's.
  bool get _included => widget.included ?? _defaults?.included ?? true;

  /// Whether this control is disabled: its own word, else the one set
  /// for the subtree, else no.
  bool get _disabled =>
      widget.disabled ?? ConfigProvider.componentDisabledOf(context) ?? false;

  @override
  Widget build(BuildContext context) {
    return _SliderCore(
      values: [widget.value],
      onChanged: widget.onChanged == null
          ? null
          : (values) => widget.onChanged!(values.first),
      onChangeComplete: widget.onChangeComplete == null
          ? null
          : (values) => widget.onChangeComplete!(values.first),
      min: widget.min,
      max: widget.max,
      step: widget.step,
      marks: widget.marks,
      dots: _dots,
      included: _included,
      disabled: _disabled,
      vertical: widget.vertical,
      reverse: widget.reverse,
      tooltip: widget.tooltip,
      token: widget.token,
      // A single handle fills from the bottom of the scale; a pair fills
      // between the two.
      fillFromStart: true,
    );
  }
}

/// A groove with two handles, for choosing a span.
///
/// ```dart
/// RangeSlider(
///   values: _price,
///   onChanged: (v) => setState(() => _price = v),
/// )
/// ```
///
/// Kept apart from [Slider] rather than folded in behind a flag: the two
/// differ in the type of the thing they carry, and a single widget would have
/// to take a value that is sometimes a number and sometimes a pair.
class RangeSlider extends StatefulWidget {
  /// Creates a [RangeSlider].
  const RangeSlider({
    super.key,
    required this.values,
    this.onChanged,
    this.onChangeComplete,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.marks = const [],
    this.dots,
    this.included,
    this.disabled,
    this.vertical = false,
    this.reverse = false,
    this.tooltip,
    this.token,
  })  : assert(min < max, 'min must be less than max'),
        assert(step == null || step > 0, 'step must be positive');

  /// Where the two handles stand, low then high.
  final (double, double) values;

  /// Called as either handle moves.
  final ValueChanged<(double, double)>? onChanged;

  /// Called once the drag ends.
  final ValueChanged<(double, double)>? onChangeComplete;

  /// The bottom of the scale.
  final double min;

  /// The top of the scale.
  final double max;

  /// How far one move takes a handle. See [Slider.step].
  final double? step;

  /// Points written along the scale.
  final List<SliderMark> marks;

  /// Whether every step is dotted.
  final bool? dots;

  /// Whether the span between the handles is filled.
  final bool? included;

  /// Greys the slider out and blocks dragging.
  final bool? disabled;

  /// Runs the scale down the page.
  final bool vertical;

  /// Starts the scale at the far end. See [Slider.reverse].
  final bool reverse;

  /// What to show above a handle while it is being moved.
  final String? Function(double value)? tooltip;

  /// Per-instance token overrides.
  final SliderToken? token;

  @override
  State<RangeSlider> createState() => _RangeSliderState();
}

class _RangeSliderState extends State<RangeSlider> {
  /// The defaults set for this component in the subtree, if any.
  SliderDefaults? get _defaults =>
      ConfigProvider.defaultsOf<SliderDefaults>(context);

  /// This widget's word, then the subtree's, then the kit's.
  bool get _dots => widget.dots ?? _defaults?.dots ?? false;

  /// This widget's word, then the subtree's, then the kit's.
  bool get _included => widget.included ?? _defaults?.included ?? true;

  /// Whether this control is disabled: its own word, else the one set
  /// for the subtree, else no.
  bool get _disabled =>
      widget.disabled ?? ConfigProvider.componentDisabledOf(context) ?? false;

  @override
  Widget build(BuildContext context) {
    final (low, high) = widget.values;
    return _SliderCore(
      values: [low, high],
      onChanged:
          widget.onChanged == null ? null : (v) => widget.onChanged!(_pair(v)),
      onChangeComplete: widget.onChangeComplete == null
          ? null
          : (v) => widget.onChangeComplete!(_pair(v)),
      min: widget.min,
      max: widget.max,
      step: widget.step,
      marks: widget.marks,
      dots: _dots,
      included: _included,
      disabled: _disabled,
      vertical: widget.vertical,
      reverse: widget.reverse,
      tooltip: widget.tooltip,
      token: widget.token,
      fillFromStart: false,
    );
  }

  /// Handles are reported low first however they were dragged, so a handle
  /// pushed past its neighbour does not swap the pair round.
  (double, double) _pair(List<double> values) {
    final sorted = [...values]..sort();
    return (sorted.first, sorted.last);
  }
}

/// The geometry both sliders are drawn with.
class _SliderCore extends StatefulWidget {
  const _SliderCore({
    required this.values,
    required this.onChanged,
    required this.onChangeComplete,
    required this.min,
    required this.max,
    required this.step,
    required this.marks,
    required this.dots,
    required this.included,
    required this.disabled,
    required this.vertical,
    required this.reverse,
    required this.tooltip,
    required this.token,
    required this.fillFromStart,
  });

  final List<double> values;
  final ValueChanged<List<double>>? onChanged;
  final ValueChanged<List<double>>? onChangeComplete;
  final double min;
  final double max;
  final double? step;
  final List<SliderMark> marks;
  final bool dots;
  final bool included;
  final bool disabled;
  final bool vertical;
  final bool reverse;
  final String? Function(double value)? tooltip;
  final SliderToken? token;
  final bool fillFromStart;

  @override
  State<_SliderCore> createState() => _SliderCoreState();
}

class _SliderCoreState extends State<_SliderCore> {
  bool _hovered = false;
  int? _dragging;
  int? _focused;

  /// The groove's own size, kept from the last layout so a drag that begins
  /// can work out which handle it began nearest to.
  Size _size = Size.zero;

  bool get _enabled => !widget.disabled && widget.onChanged != null;

  /// Whether the scale runs from the far end.
  ///
  /// A right-to-left layout already turns the scale round, so `reverse` flips
  /// it back rather than forcing a side — the rule Ant Design applies, and the
  /// only one under which `reverse` means the same thing in both languages.
  bool get _reversed {
    if (widget.vertical) return widget.reverse;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return rtl != widget.reverse;
  }

  /// Where [value] sits along the groove, from 0 at the start to 1 at the end.
  double _fractionOf(double value) {
    final span = widget.max - widget.min;
    final raw = span == 0 ? 0.0 : (value - widget.min) / span;
    return _reversed ? 1 - raw : raw;
  }

  /// The value a point [fraction] of the way along the groove stands for,
  /// pulled onto the nearest step or mark.
  double _valueAt(double fraction) {
    final along = (_reversed ? 1 - fraction : fraction).clamp(0.0, 1.0);
    final raw = widget.min + along * (widget.max - widget.min);

    final step = widget.step;
    if (step != null) {
      final steps = ((raw - widget.min) / step).round();
      return (widget.min + steps * step).clamp(widget.min, widget.max);
    }

    // A null step means the marks are the only places to rest, with the ends
    // of the scale always among them.
    final stops = <double>[
      widget.min,
      widget.max,
      for (final mark in widget.marks) mark.value,
    ]..sort();
    var best = stops.first;
    for (final stop in stops) {
      if ((stop - raw).abs() < (best - raw).abs()) best = stop;
    }
    return best;
  }

  void _moveNearest(double fraction, {required bool complete}) {
    if (!_enabled) return;
    final value = _valueAt(fraction);

    // The handle that moves is the one already nearest, so a tap on the
    // groove picks up the closer of a pair rather than always the first.
    var index = _dragging ?? 0;
    if (_dragging == null && widget.values.length > 1) {
      var best = double.infinity;
      for (var i = 0; i < widget.values.length; i++) {
        final away = (widget.values[i] - value).abs();
        if (away < best) {
          best = away;
          index = i;
        }
      }
    }

    final next = [...widget.values];
    next[index] = value;
    widget.onChanged?.call(next);
    if (complete) widget.onChangeComplete?.call(next);
  }

  double _fractionFor(Offset local, Size size) {
    final along = widget.vertical
        // Down the page the scale starts at the bottom, as a measure does.
        ? 1 - (local.dy / size.height)
        : local.dx / size.width;
    return along.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<SliderToken>(context) ??
            const SliderToken())
        ._resolve(t);

    final thickness = r.handleSizeHover + r.handleLineWidthHover * 2;
    final groove = LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          widget.vertical ? thickness : constraints.maxWidth,
          widget.vertical ? constraints.maxHeight : thickness,
        );
        _size = size;

        final painted = CustomPaint(
          size: size,
          painter: _SliderPainter(
            fractions: widget.values.map(_fractionOf).toList(),
            dotFractions: _dotFractions(),
            activeDots: _activeDots(),
            token: r,
            vertical: widget.vertical,
            included: widget.included,
            fillFromStart: widget.fillFromStart,
            enabled: _enabled,
            hovered: _hovered || _dragging != null,
            dragging: _dragging,
          ),
        );

        // The bubble rides inside the slider's own stack rather than in an
        // overlay: it has to follow a handle that moves every frame, and an
        // overlay entry would have to be torn down and rebuilt for each one.
        // The cost is that an ancestor which clips will clip it too.
        final label = _bubbleLabel();
        final body = label == null
            ? painted
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  painted,
                  Positioned(
                    left: widget.vertical ? null : _bubbleAlong(size),
                    right: widget.vertical ? size.width : null,
                    top: widget.vertical ? _bubbleAlong(size) : null,
                    bottom: widget.vertical ? null : size.height,
                    child: FractionalTranslation(
                      translation: widget.vertical
                          ? const Offset(0, -0.5)
                          : const Offset(-0.5, 0),
                      child: _Bubble(label: label, token: t),
                    ),
                  ),
                ],
              );

        return Focus(
          canRequestFocus: _enabled,
          onKeyEvent: (_, event) => _onKey(_focused ?? 0, event),
          child: MouseRegion(
            cursor:
                _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
            onEnter: (_) => _setHovered(true),
            onExit: (_) => _setHovered(false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onTapDown: (details) => _moveNearest(
                _fractionFor(details.localPosition, size),
                complete: true,
              ),
              onHorizontalDragStart: widget.vertical ? null : _dragStart,
              onHorizontalDragUpdate: widget.vertical
                  ? null
                  : (d) => _dragUpdate(d.localPosition, size),
              onHorizontalDragEnd: widget.vertical ? null : (_) => _dragEnd(),
              onVerticalDragStart: widget.vertical ? _dragStart : null,
              onVerticalDragUpdate: widget.vertical
                  ? (d) => _dragUpdate(d.localPosition, size)
                  : null,
              onVerticalDragEnd: widget.vertical ? (_) => _dragEnd() : null,
              child: body,
            ),
          ),
        );
      },
    );

    if (widget.marks.isEmpty) {
      return widget.vertical
          ? SizedBox(width: thickness, child: groove)
          : SizedBox(height: thickness, child: groove);
    }
    return _withMarks(t, r, groove, thickness);
  }

  /// What the bubble says, or null when there is nothing to show.
  ///
  /// Only while a handle is actually being moved: a bubble that lingered would
  /// sit over whatever the slider is labelled with.
  String? _bubbleLabel() {
    final index = _dragging;
    if (index == null) return null;
    final value = widget.values[index];
    return widget.tooltip == null ? _plain(value) : widget.tooltip!(value);
  }

  /// A value written without a trailing zero it does not need.
  String _plain(double value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';

  /// How far along the groove a point [fraction] of the way sits, in pixels
  /// from the top or the left of a groove [extent] long.
  ///
  /// Down the page the scale starts at the bottom, as a measure does, so the
  /// fraction counts back from the far end. Everything placed along the
  /// groove goes through here: the painter, the bubble and the marks each
  /// worked this out for themselves once, and the marks had it upside down.
  double _alongFor(double fraction, double extent) =>
      widget.vertical ? (1 - fraction) * extent : fraction * extent;

  /// Where the bubble sits along the groove.
  double _bubbleAlong(Size size) => _alongFor(
        _fractionOf(widget.values[_dragging ?? 0]),
        widget.vertical ? size.height : size.width,
      );

  void _dragStart(DragStartDetails details) {
    if (!_enabled) return;
    setState(() => _dragging = _nearestTo(details.localPosition));
  }

  void _dragUpdate(Offset local, Size size) =>
      _moveNearest(_fractionFor(local, size), complete: false);

  void _dragEnd() {
    if (_dragging == null) return;
    widget.onChangeComplete?.call([...widget.values]);
    setState(() => _dragging = null);
  }

  /// Which handle a drag beginning at [local] takes hold of.
  ///
  /// Decided once, at the start: held to for the whole drag so a handle pushed
  /// past its neighbour keeps moving with the finger rather than being handed
  /// over halfway.
  int _nearestTo(Offset local) {
    if (widget.values.length == 1) return 0;
    final at = _valueAt(_fractionFor(local, _size));
    var index = 0;
    var best = double.infinity;
    for (var i = 0; i < widget.values.length; i++) {
      final away = (widget.values[i] - at).abs();
      if (away < best) {
        best = away;
        index = i;
      }
    }
    return index;
  }

  /// Moves a handle one step along, the way the scale runs.
  ///
  /// Towards the end of the scale for the forward keys, which is leftwards on
  /// a mirrored one: the arrow that points along the groove is the one that
  /// advances it, whichever key that turns out to be.
  void _nudge(int index, {required bool forward}) {
    if (!_enabled) return;
    final step = widget.step ?? (widget.max - widget.min) / 100;
    final direction = forward ? 1 : -1;
    final next = [...widget.values];
    next[index] =
        (next[index] + step * direction).clamp(widget.min, widget.max);
    widget.onChanged?.call(next);
    widget.onChangeComplete?.call(next);
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final along = widget.vertical
        ? {LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowDown}
        : {LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight};
    if (!along.contains(key)) return KeyEventResult.ignored;

    final towardsEnd = widget.vertical
        ? key == LogicalKeyboardKey.arrowUp
        : key == LogicalKeyboardKey.arrowRight;
    // The key that points along the groove advances the value; a reversed or
    // mirrored scale runs the other way, so the same key means the opposite.
    _nudge(index, forward: _reversed ? !towardsEnd : towardsEnd);
    return KeyEventResult.handled;
  }

  void _setHovered(bool value) {
    if (_hovered != value && mounted) setState(() => _hovered = value);
  }

  /// Where a dot is drawn, as fractions along the groove.
  List<double> _dotFractions() {
    if (widget.dots && widget.step != null) {
      final out = <double>[];
      for (var v = widget.min; v <= widget.max; v += widget.step!) {
        out.add(_fractionOf(v));
      }
      return out;
    }
    return widget.marks.map((m) => _fractionOf(m.value)).toList();
  }

  /// Which of those dots the handle has reached.
  List<bool> _activeDots() {
    final values = widget.dots && widget.step != null
        ? [
            for (var v = widget.min; v <= widget.max; v += widget.step!) v,
          ]
        : widget.marks.map((m) => m.value).toList();
    final low = widget.fillFromStart
        ? widget.min
        : widget.values.reduce((a, b) => a < b ? a : b);
    final high = widget.values.reduce((a, b) => a > b ? a : b);
    return [for (final v in values) v >= low && v <= high];
  }

  Widget _withMarks(
    Token t,
    _ResolvedSliderToken r,
    Widget groove,
    double thickness,
  ) {
    // Laid out by fraction rather than stacked by hand, so a label sits under
    // the point it names whatever the scale's range happens to be.
    final marked = LayoutBuilder(
      builder: (context, constraints) {
        final extent =
            widget.vertical ? constraints.maxHeight : constraints.maxWidth;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final mark in widget.marks)
              Positioned(
                left: widget.vertical
                    ? 0
                    : _alongFor(_fractionOf(mark.value), extent),
                top: widget.vertical
                    ? _alongFor(_fractionOf(mark.value), extent)
                    : 0,
                child: FractionalTranslation(
                  translation: widget.vertical
                      ? const Offset(0, -0.5)
                      : const Offset(-0.5, 0),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      color: t.colorText,
                      fontSize: t.fontSize,
                      fontFamily: t.fontFamily,
                      fontFamilyFallback: t.fontFamilyFallback,
                      decoration: TextDecoration.none,
                    ).merge(mark.style),
                    child: mark.label,
                  ),
                ),
              ),
          ],
        );
      },
    );

    if (widget.vertical) {
      // As wide as the groove, the gap and the widest label together — not as
      // wide as the groove alone, which left the labels with nowhere to go and
      // overflowed by exactly the gap between them.
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: thickness, child: groove),
          SizedBox(width: t.sizeXS),
          Stack(
            children: [
              // A silent copy, laid out but never seen. The labels themselves
              // are positioned, and a stack of nothing but positioned children
              // has no width of its own; this is what gives it one, measured
              // from the labels rather than guessed at.
              // Kept out of the semantics tree and out of hit testing: it is
              // a duplicate of every label, and a screen reader would read the
              // marks twice over.
              ExcludeSemantics(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final mark in widget.marks)
                          DefaultTextStyle.merge(
                            style: TextStyle(
                              fontSize: t.fontSize,
                              fontFamily: t.fontFamily,
                              fontFamilyFallback: t.fontFamilyFallback,
                              decoration: TextDecoration.none,
                            ).merge(mark.style),
                            child: mark.label,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: marked),
            ],
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: thickness, child: groove),
        SizedBox(height: t.sizeXXS),
        SizedBox(height: t.controlHeightSM, child: marked),
      ],
    );
  }
}

class _SliderPainter extends CustomPainter {
  const _SliderPainter({
    required this.fractions,
    required this.dotFractions,
    required this.activeDots,
    required this.token,
    required this.vertical,
    required this.included,
    required this.fillFromStart,
    required this.enabled,
    required this.hovered,
    required this.dragging,
  });

  final List<double> fractions;
  final List<double> dotFractions;
  final List<bool> activeDots;
  final _ResolvedSliderToken token;
  final bool vertical;
  final bool included;
  final bool fillFromStart;
  final bool enabled;
  final bool hovered;
  final int? dragging;

  /// The point a fraction of the way along the groove.
  Offset _at(double fraction, Size size) => vertical
      ? Offset(size.width / 2, (1 - fraction) * size.height)
      : Offset(fraction * size.width, size.height / 2);

  @override
  void paint(Canvas canvas, Size size) {
    final rail = Paint()
      ..color =
          enabled ? (hovered ? token.railHoverBg : token.railBg) : token.railBg
      ..strokeCap = StrokeCap.round
      ..strokeWidth = token.railSize;

    final start = _at(0, size);
    final end = _at(1, size);
    canvas.drawLine(start, end, rail);

    if (included) {
      final low =
          fillFromStart ? 0.0 : fractions.reduce((a, b) => a < b ? a : b);
      final high = fillFromStart
          ? fractions.first
          : fractions.reduce((a, b) => a > b ? a : b);
      final track = Paint()
        ..color = enabled
            ? (hovered ? token.trackHoverBg : token.trackBg)
            : token.trackBgDisabled
        ..strokeCap = StrokeCap.round
        ..strokeWidth = token.railSize;
      canvas.drawLine(_at(low, size), _at(high, size), track);
    }

    for (var i = 0; i < dotFractions.length; i++) {
      final centre = _at(dotFractions[i], size);
      final on = i < activeDots.length && activeDots[i];
      canvas
        ..drawCircle(
          centre,
          token.dotSize / 2,
          Paint()..color = const Color(0xFFFFFFFF),
        )
        ..drawCircle(
          centre,
          token.dotSize / 2,
          Paint()
            ..color = on ? token.dotActiveBorderColor : token.dotBorderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = token.handleLineWidth,
        );
    }

    for (var i = 0; i < fractions.length; i++) {
      final centre = _at(fractions[i], size);
      final active = hovered || dragging == i;
      final diameter = active ? token.handleSizeHover : token.handleSize;
      final ring = active ? token.handleLineWidthHover : token.handleLineWidth;
      final colour = !enabled
          ? token.handleColorDisabled
          : (dragging == i || hovered
              ? token.handleActiveColor
              : token.handleColor);
      canvas
        // The ring is drawn outside the disc, as Ant Design's box-shadow is,
        // so the handle keeps the diameter its token names.
        ..drawCircle(
          centre,
          diameter / 2 + ring,
          Paint()..color = colour,
        )
        ..drawCircle(
          centre,
          diameter / 2,
          Paint()..color = const Color(0xFFFFFFFF),
        );
    }
  }

  @override
  bool shouldRepaint(_SliderPainter old) =>
      !_sameNumbers(old.fractions, fractions) ||
      !_sameNumbers(old.dotFractions, dotFractions) ||
      old.enabled != enabled ||
      old.hovered != hovered ||
      old.dragging != dragging ||
      old.included != included ||
      old.vertical != vertical;

  static bool _sameNumbers(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The value shown above a handle while it is being moved.
///
/// Dressed as the kit's tooltip is — the same spotlight fill, radius and type
/// — so a slider's bubble and a tooltip look like one another.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.label, required this.token});

  final String label;
  final Token token;

  @override
  Widget build(BuildContext context) {
    final resolved = ConfigProvider.componentOf<TooltipToken>(context) ??
        const TooltipToken();
    return Padding(
      padding: EdgeInsets.only(bottom: token.sizeXXS),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: token.sizeXS,
          vertical: token.sizeXXS,
        ),
        decoration: BoxDecoration(
          color: resolved.colorBg ?? token.colorBgSpotlight,
          borderRadius: BorderRadius.circular(
            resolved.borderRadius ?? token.borderRadius,
          ),
          boxShadow: token.boxShadowSecondary,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: resolved.colorText ?? const Color(0xFFFFFFFF),
            fontSize: resolved.fontSize ?? token.fontSize,
            fontFamily: token.fontFamily,
            fontFamilyFallback: token.fontFamilyFallback,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
