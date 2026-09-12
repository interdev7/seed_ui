import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../data_display/tooltip.dart';

/// A stretch of a slider's scale, coloured.
///
/// For the part of a scale that means something in itself — a safe heart
/// rate, a budget already spent, the hours a shop is open. A mark names a
/// point; a zone names a run.
@immutable
class SliderZone {
  /// Creates a zone between [from] and [to], whichever way round they come.
  const SliderZone(this.from, this.to, {this.color});

  /// Where the stretch begins. Put in order with [to], so a zone written
  /// backwards means the same stretch.
  final double from;

  /// And where it ends.
  final double to;

  /// What it is coloured. Null takes the theme's own fill, which is quiet
  /// enough to sit under a track without fighting it.
  final Color? color;

  /// The lower end.
  double get low => from < to ? from : to;

  /// The upper end.
  double get high => from < to ? to : from;

  @override
  bool operator ==(Object other) =>
      other is SliderZone &&
      other.from == from &&
      other.to == to &&
      other.color == color;

  @override
  int get hashCode => Object.hash(from, to, color);
}

/// Which side of the rail a mark's label is written on.
///
/// Named by the flow rather than by the screen: across a row `before` is
/// above the rail and `after` below it; down a column they are the leading
/// and trailing sides, which swap over when the page reads the other way.
/// Four sides — top, bottom, left, right — would leave two of them meaning
/// nothing on any given slider, and an API that can say something impossible
/// will eventually be asked to.
enum SliderMarkSide {
  /// Before the rail in the flow: above it across a row.
  before,

  /// After it, which is where a mark goes unless it says otherwise.
  after,
}

/// Draws a mark.
///
/// [child] is what the slider would have drawn — the label, styled and all,
/// or for a mark with no words a box the size of the band, standing where its
/// dot is. Wrap it and the mark keeps every state for nothing; wrap it in a
/// menu or a popover and the mark becomes something to press. [active] is
/// whether the handle has reached this mark.
typedef SliderMarkBuilder = Widget Function(
  BuildContext context,
  SliderMark mark,
  bool active,
  Widget child,
);

/// A labelled point on a [Slider]'s scale.
@immutable
class SliderMark {
  /// Creates a [SliderMark] at [value], written with [label].
  const SliderMark(
    this.value,
    this.label, {
    this.style,
    this.markBuilder,
    this.side = SliderMarkSide.after,
    this.hidden = false,
    this.disabled = false,
  });

  /// A mark with no words: a stop on the scale, drawn as a dot.
  ///
  /// Worth having apart from [Slider.dots], which dots every step: a stop
  /// that is not every step, and may be [disabled], has nothing to say but
  /// still has to be there.
  const SliderMark.dot(
    this.value, {
    this.hidden = false,
    this.disabled = false,
  })  : label = null,
        style = null,
        markBuilder = null,
        side = SliderMarkSide.after;

  /// Where on the scale it sits. Must lie within the slider's own range.
  final double value;

  /// What is written by it, or null for a mark with no words.
  ///
  /// A plain string rather than a widget: nearly every mark is one, and a
  /// widget for the rest is what [labelBuilder] is for. That is the shape the
  /// kit uses wherever a caller may want either.
  final String? label;

  /// Overrides the label's style for this mark alone.
  ///
  /// The defaults live in [SliderToken]; this is for the odd mark that has to
  /// stand out from the rest.
  final TextStyle? style;

  /// Draws this mark instead, given what the slider would have drawn.
  ///
  /// Called `markBuilder` rather than `labelBuilder` because a mark with no
  /// words has no label to build — and is exactly the mark somebody wants to
  /// hang a menu or a popover on.
  final SliderMarkBuilder? markBuilder;

  /// Which side of the rail the label is written on.
  final SliderMarkSide side;

  /// Whether the mark is left undrawn.
  ///
  /// It keeps its place in the list, as a hidden column keeps its place among
  /// a table's columns: a mark shown and hidden again is the same mark, and a
  /// list that had to be rebuilt to hide one would lose whatever else it was
  /// keyed by.
  final bool hidden;

  /// Whether the handle may not rest here.
  ///
  /// This bites where the marks are the only places to rest — a slider with
  /// no [Slider.step] — and there it means exactly what it says: the handle
  /// passes this stop by. Given a step, the handle stops at steps rather than
  /// at marks, and a disabled mark is only greyed.
  final bool disabled;

  /// This mark with some of it changed.
  SliderMark copyWith({
    double? value,
    String? label,
    TextStyle? style,
    SliderMarkBuilder? markBuilder,
    SliderMarkSide? side,
    bool? hidden,
    bool? disabled,
  }) =>
      SliderMark(
        value ?? this.value,
        label ?? this.label,
        style: style ?? this.style,
        markBuilder: markBuilder ?? this.markBuilder,
        side: side ?? this.side,
        hidden: hidden ?? this.hidden,
        disabled: disabled ?? this.disabled,
      );

  @override
  bool operator ==(Object other) =>
      other is SliderMark &&
      other.value == value &&
      other.label == label &&
      other.style == style &&
      other.markBuilder == markBuilder &&
      other.side == side &&
      other.hidden == hidden &&
      other.disabled == disabled;

  @override
  int get hashCode => Object.hash(
        value,
        label,
        style,
        markBuilder,
        side,
        hidden,
        disabled,
      );
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
    this.markColor,
    this.markDisabledColor,
    this.markFontSize,
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

  /// What a mark's words are written in (`markColor`).
  final Color? markColor;

  /// And a mark the handle may not rest on (`markDisabledColor`).
  final Color? markDisabledColor;

  /// How big a mark's words are (`markFontSize`).
  final double? markFontSize;

  /// A mark's dot once it has (`dotActiveBorderColor`).
  final Color? dotActiveBorderColor;

  _ResolvedSliderToken _resolve(Token t) {
    // The handle is a quarter of the large control height, so it grows with
    // the theme's own scale rather than carrying a number of its own.
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
      markColor: markColor ?? t.colorText,
      markDisabledColor: markDisabledColor ?? t.colorTextQuaternary,
      markFontSize: markFontSize ?? t.fontSize,
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
    required this.markColor,
    required this.markDisabledColor,
    required this.markFontSize,
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

  /// What a mark's words are written in.
  final Color markColor;

  /// And a mark the handle may not rest on.
  final Color markDisabledColor;

  /// How big a mark's words are.
  final double markFontSize;
}

/// Defaults for every [Slider] under a `ConfigProvider`.
///
/// House style for sliders.
@immutable
class SliderDefaults {
  /// Creates a [SliderDefaults].
  const SliderDefaults({
    this.dots,
    this.included,
    this.disabled,
  });

  /// Whether the marks are drawn as dots.
  final bool? dots;

  /// Whether the track fills up to the handle.
  final bool? included;

  /// Whether a [Slider] is disabled, unless it says otherwise.
  ///
  /// Nearer than `ConfigProvider.componentDisabled`, and beaten in turn by
  /// the widget's own word.
  final bool? disabled;
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
    this.value,
    this.defaultValue,
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
    this.zones = const [],
    this.bounds,
    this.snapToMarks = false,
    this.tooltip,
    this.token,
  })  : assert(min < max, 'min must be less than max'),
        assert(step == null || step > 0, 'step must be positive');

  /// Where the handle stands. Null leaves the slider to keep its own place
  /// (see [defaultValue]).
  final double? value;

  /// Where an uncontrolled handle starts. Defaults to [min].
  final double? defaultValue;

  /// Called as the handle moves.
  ///
  /// Null on a controlled slider — one given a [value] — makes it read-only:
  /// nothing can move the handle, so nothing does. An uncontrolled slider
  /// keeps its own place and moves whether or not anybody is listening.
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
  /// back rather than forcing a side.
  final bool reverse;

  /// What to show above the handle while it is being moved.
  ///
  /// Returning null shows nothing. Left null the value is shown as it stands.
  final String? Function(double value)? tooltip;

  /// Stretches of the scale that mean something in themselves — a safe heart
  /// rate, a budget already spent, the hours a shop is open.
  ///
  /// Drawn on the rail and under the track: a zone colours the scale, and the
  /// track is the answer. A slider that is mostly zones is one to turn
  /// [included] off for.
  final List<SliderZone> zones;

  /// How far the handle may go, where that is less than the whole scale.
  ///
  /// The scale still shows what it showed — a day is still twenty-four hours
  /// long — and the handle simply cannot be put outside the part of it on
  /// offer. Narrowing [min] and [max] would hide the rest of the day, which
  /// is not the same thing to say.
  final (double, double)? bounds;

  /// Whether the handle rests on the marks as well as on the steps.
  ///
  /// With no [step] the marks are already the only stops there are; with one,
  /// they were nothing but writing. Asked for, whichever of the two is nearer
  /// to the finger wins.
  final bool snapToMarks;

  /// Per-instance token overrides.
  final SliderToken? token;

  @override
  State<Slider> createState() => _SliderState();
}

class _SliderState extends State<Slider> {
  double? _internal;

  /// Where the handle is: where it was put, else where it has moved itself
  /// to, else where it started.
  double get _current =>
      widget.value ?? _internal ?? widget.defaultValue ?? widget.min;

  /// Kept in step whether or not somebody else is driving this: it is only
  /// the fallback for `value`, and a stale one would show through the moment
  /// `value` went null again.
  void _emit(double next) {
    setState(() => _internal = next);
    widget.onChanged?.call(next);
  }

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
      widget.disabled ??
      _defaults?.disabled ??
      ConfigProvider.componentDisabledOf(context) ??
      false;

  @override
  Widget build(BuildContext context) {
    return _SliderCore(
      values: [_current],
      // A slider nobody is listening to still moves while it keeps its own
      // place; one somebody else is driving has nothing to move for.
      onChanged: widget.onChanged == null && widget.value != null
          ? null
          : (values) => _emit(values.first),
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
      zones: widget.zones,
      bounds: widget.bounds,
      snapToMarks: widget.snapToMarks,
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
    this.values,
    this.defaultValues,
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
    this.draggableTrack = false,
    this.zones = const [],
    this.bounds,
    this.snapToMarks = false,
    this.tooltip,
    this.token,
  })  : assert(min < max, 'min must be less than max'),
        assert(step == null || step > 0, 'step must be positive');

  /// Whether the span between the handles may be taken hold of and moved as
  /// one.
  ///
  /// Only strictly between them: the handles keep their own drag, or a span
  /// would have two dead spots at its ends. Pushed against an end of the
  /// scale the span keeps its length and simply stops.
  final bool draggableTrack;

  /// Where the two handles stand, low then high. Null leaves the slider to
  /// keep its own span (see [defaultValues]).
  final (double, double)? values;

  /// Where an uncontrolled pair of handles starts. Defaults to the whole
  /// scale, [min] to [max].
  final (double, double)? defaultValues;

  /// Called as either handle moves.
  ///
  /// Null on a controlled one — given a value of its own — makes it inert:
  /// nothing can change what it shows, so nothing does. An uncontrolled one
  /// keeps its own state and changes whether or not anybody is listening.
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

  /// Stretches of the scale that mean something in themselves — a safe heart
  /// rate, a budget already spent, the hours a shop is open.
  ///
  /// Drawn on the rail and under the track: a zone colours the scale, and the
  /// track is the answer. A slider that is mostly zones is one to turn
  /// [included] off for.
  final List<SliderZone> zones;

  /// How far the handle may go, where that is less than the whole scale.
  ///
  /// The scale still shows what it showed — a day is still twenty-four hours
  /// long — and the handle simply cannot be put outside the part of it on
  /// offer. Narrowing [min] and [max] would hide the rest of the day, which
  /// is not the same thing to say.
  final (double, double)? bounds;

  /// Whether the handle rests on the marks as well as on the steps.
  ///
  /// With no [step] the marks are already the only stops there are; with one,
  /// they were nothing but writing. Asked for, whichever of the two is nearer
  /// to the finger wins.
  final bool snapToMarks;

  /// Per-instance token overrides.
  final SliderToken? token;

  @override
  State<RangeSlider> createState() => _RangeSliderState();
}

class _RangeSliderState extends State<RangeSlider> {
  (double, double)? _internal;

  /// Where the handles are: where they were put, else where they have moved
  /// themselves to, else where they started.
  (double, double) get _current =>
      widget.values ??
      _internal ??
      widget.defaultValues ??
      (widget.min, widget.max);

  /// Kept in step whether or not somebody else is driving this: it is only
  /// the fallback for `values`, and a stale one would show through the moment
  /// `values` went null again.
  void _emit((double, double) next) {
    setState(() => _internal = next);
    widget.onChanged?.call(next);
  }

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
      widget.disabled ??
      ConfigProvider.defaultsOf<SliderDefaults>(context)?.disabled ??
      ConfigProvider.componentDisabledOf(context) ??
      false;

  @override
  Widget build(BuildContext context) {
    final (low, high) = _current;
    return _SliderCore(
      values: [low, high],
      // A slider nobody is listening to still moves while it keeps its own
      // span; one somebody else is driving has nothing to move for.
      onChanged: widget.onChanged == null && widget.values != null
          ? null
          : (v) => _emit(_pair(v)),
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
      zones: widget.zones,
      bounds: widget.bounds,
      snapToMarks: widget.snapToMarks,
      fillFromStart: false,
      draggableTrack: widget.draggableTrack,
    );
  }

  /// Handles are reported low first however they were dragged, so a handle
  /// pushed past its neighbour does not swap the pair round.
  (double, double) _pair(List<double> values) {
    final sorted = [...values]..sort();
    return (sorted.first, sorted.last);
  }
}

/// Defaults for every [MultiRangeSlider] under a `ConfigProvider`.
@immutable
class MultiRangeSliderDefaults {
  /// Creates a [MultiRangeSliderDefaults].
  const MultiRangeSliderDefaults({this.draggableTrack, this.disabled});

  /// Whether the span may be moved as one.
  final bool? draggableTrack;

  /// Whether the slider is barred.
  final bool? disabled;
}

/// A slider whose handles may be put in and taken out.
///
/// ```dart
/// MultiRangeSlider(
///   values: _bands,
///   minCount: 2,
///   maxCount: 5,
///   onChanged: (v) => setState(() => _bands = v),
/// )
/// ```
///
/// Its own component rather than a flag on [RangeSlider]: a pair of handles
/// is a `(double, double)` and this is a list, and a list of two is not the
/// same promise as a pair. A control that had to be both would hand back a
/// type its caller has to check.
///
/// **A tap puts a handle in; a tap on a handle takes it out.** A tap on a
/// handle has nothing else to mean — it is already where it is being asked to
/// go — and it is the one gesture a slider does not otherwise use.
class MultiRangeSlider extends StatefulWidget {
  /// Creates a [MultiRangeSlider].
  const MultiRangeSlider({
    super.key,
    this.values,
    this.defaultValues,
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
    this.draggableTrack = false,
    this.minCount = 2,
    this.maxCount,
    this.zones = const [],
    this.bounds,
    this.snapToMarks = false,
    this.tooltip,
    this.token,
  })  : assert(min < max, 'min must be less than max'),
        assert(step == null || step > 0, 'step must be positive'),
        assert(minCount >= 2, 'a range needs two handles at the least'),
        assert(
          maxCount == null || maxCount >= minCount,
          'maxCount must leave room for minCount',
        );

  /// Where the handles stand, in order. Null leaves the slider to keep its
  /// own (see [defaultValues]).
  final List<double>? values;

  /// Where an uncontrolled run of handles starts. Defaults to one at each end
  /// of the scale, which is the fewest a range may have.
  final List<double>? defaultValues;

  /// Called as a handle moves, goes in, or comes out — always with the whole
  /// list, in order.
  ///
  /// Null on a controlled one — given a value of its own — makes it inert:
  /// nothing can change what it shows, so nothing does. An uncontrolled one
  /// keeps its own state and changes whether or not anybody is listening.
  final ValueChanged<List<double>>? onChanged;

  /// Called once a drag ends, or a handle goes in or comes out.
  final ValueChanged<List<double>>? onChangeComplete;

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

  /// Whether the spans between the handles are filled.
  final bool? included;

  /// Greys the slider out and blocks dragging.
  final bool? disabled;

  /// Runs the scale down the page.
  final bool vertical;

  /// Starts the scale at the far end. See [Slider.reverse].
  final bool reverse;

  /// Whether the span may be taken hold of and moved as one.
  final bool draggableTrack;

  /// How few handles there may be. Two at the least: one handle is a
  /// [Slider], and a range with one end is not a range.
  final int minCount;

  /// How many there may be, or null for no ceiling.
  final int? maxCount;

  /// What to show above a handle while it is being moved.
  final String? Function(double value)? tooltip;

  /// Stretches of the scale that mean something in themselves — a safe heart
  /// rate, a budget already spent, the hours a shop is open.
  ///
  /// Drawn on the rail and under the track: a zone colours the scale, and the
  /// track is the answer. A slider that is mostly zones is one to turn
  /// [included] off for.
  final List<SliderZone> zones;

  /// How far the handle may go, where that is less than the whole scale.
  ///
  /// The scale still shows what it showed — a day is still twenty-four hours
  /// long — and the handle simply cannot be put outside the part of it on
  /// offer. Narrowing [min] and [max] would hide the rest of the day, which
  /// is not the same thing to say.
  final (double, double)? bounds;

  /// Whether the handle rests on the marks as well as on the steps.
  ///
  /// With no [step] the marks are already the only stops there are; with one,
  /// they were nothing but writing. Asked for, whichever of the two is nearer
  /// to the finger wins.
  final bool snapToMarks;

  /// Per-instance token overrides.
  final SliderToken? token;

  @override
  State<MultiRangeSlider> createState() => _MultiRangeSliderState();
}

class _MultiRangeSliderState extends State<MultiRangeSlider> {
  MultiRangeSliderDefaults? get _defaults =>
      ConfigProvider.defaultsOf<MultiRangeSliderDefaults>(context);

  SliderDefaults? get _sliderDefaults =>
      ConfigProvider.defaultsOf<SliderDefaults>(context);

  bool get _dots => widget.dots ?? _sliderDefaults?.dots ?? false;

  bool get _included => widget.included ?? _sliderDefaults?.included ?? true;

  bool get _draggableTrack =>
      widget.draggableTrack || (_defaults?.draggableTrack ?? false);

  bool get _disabled =>
      widget.disabled ??
      _defaults?.disabled ??
      _sliderDefaults?.disabled ??
      ConfigProvider.componentDisabledOf(context) ??
      false;

  /// The handles in order, however they were dragged or added.
  ///
  /// Sorted on the way out rather than left as they fell: a handle pushed
  /// past its neighbour would otherwise change what "the third band" means
  /// halfway through a drag.
  List<double> _sorted(List<double> values) => [...values]..sort();

  List<double>? _internal;

  /// Where the handles are: where they were put, else where they have moved
  /// themselves to, else where they started.
  List<double> get _current =>
      widget.values ??
      _internal ??
      widget.defaultValues ??
      [widget.min, widget.max];

  /// Kept in step whether or not somebody else is driving this: it is only
  /// the fallback for `values`, and a stale one would show through the moment
  /// `values` went null again.
  void _emit(List<double> next) {
    setState(() => _internal = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return _SliderCore(
      values: _sorted(_current),
      // A slider nobody is listening to still moves while it keeps its own
      // handles; one somebody else is driving has nothing to move for.
      onChanged: widget.onChanged == null && widget.values != null
          ? null
          : (v) => _emit(_sorted(v)),
      onChangeComplete: widget.onChangeComplete == null
          ? null
          : (v) => widget.onChangeComplete!(_sorted(v)),
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
      zones: widget.zones,
      bounds: widget.bounds,
      snapToMarks: widget.snapToMarks,
      fillFromStart: false,
      draggableTrack: _draggableTrack,
      editable: true,
      minCount: widget.minCount,
      maxCount: widget.maxCount,
    );
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
    this.zones = const [],
    this.bounds,
    this.snapToMarks = false,
    this.draggableTrack = false,
    this.editable = false,
    this.minCount,
    this.maxCount,
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

  /// Stretches of the scale that mean something in themselves.
  final List<SliderZone> zones;

  /// How far the handle may go, where that is less than the whole scale.
  final (double, double)? bounds;

  /// Whether the handle rests on the marks as well as on the steps.
  final bool snapToMarks;

  /// Whether the filled span may be taken hold of and moved as one.
  final bool draggableTrack;

  /// Whether handles may be put in and taken out.
  final bool editable;

  /// How few and how many handles there may be, where they are editable.
  final int? minCount;
  final int? maxCount;

  @override
  State<_SliderCore> createState() => _SliderCoreState();
}

class _SliderCoreState extends State<_SliderCore> {
  bool _hovered = false;
  int? _dragging;
  int? _focused;

  /// The whole span, taken hold of between the handles.
  ///
  /// Where a drag begins matters: on a handle it moves that one, and on the
  /// filled span between them it moves every handle together. Kept as the
  /// values the drag began with, so the span keeps its length however far it
  /// is pushed against an end — reckoning from the last frame would shrink it
  /// a step at a time.
  List<double>? _trackFrom;
  double? _trackAt;

  /// The groove's own size, kept from the last layout so a drag that begins
  /// can work out which handle it began nearest to.
  Size _size = Size.zero;

  bool get _enabled => !widget.disabled && widget.onChanged != null;

  /// Whether the scale runs from the far end.
  ///
  /// A right-to-left layout already turns the scale round, so `reverse` flips
  /// it back rather than forcing a side — the only rule under which `reverse`
  /// means the same thing in both reading directions.
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
      var stopped = (widget.min + steps * step).clamp(widget.min, widget.max);
      // The marks as well as the steps, where they were asked for: whichever
      // is nearer to where the finger actually is. Without a step the marks
      // are the only stops there are and this is already how it works; with
      // one they were nothing but writing.
      if (widget.snapToMarks) {
        for (final mark in widget.marks) {
          if (mark.hidden || mark.disabled) continue;
          if ((mark.value - raw).abs() < (stopped - raw).abs()) {
            stopped = mark.value;
          }
        }
      }
      return _held(stopped);
    }

    // A null step means the marks are the only places to rest, with the ends
    // of the scale always among them.
    // A mark the handle may not rest on is no stop at all — which is what
    // `disabled` means where the marks are the only stops there are.
    final stops = <double>[
      widget.min,
      widget.max,
      for (final mark in widget.marks)
        if (!mark.disabled) mark.value,
    ]..sort();
    var best = stops.first;
    for (final stop in stops) {
      if ((stop - raw).abs() < (best - raw).abs()) best = stop;
    }
    return _held(best);
  }

  /// [value] kept inside [_SliderCore.bounds], where there are any.
  ///
  /// The scale still shows what it showed — a day is still twenty-four hours
  /// long — and the handle simply cannot be put outside the part of it that
  /// is on offer. Narrowing `min` and `max` instead would hide the rest of
  /// the day, which is not the same thing to say.
  double _held(double value) {
    final bounds = widget.bounds;
    if (bounds == null) return value;
    final low = bounds.$1 < bounds.$2 ? bounds.$1 : bounds.$2;
    final high = bounds.$1 < bounds.$2 ? bounds.$2 : bounds.$1;
    return value.clamp(low, high);
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
            zones: [
              for (final zone in widget.zones)
                (
                  from: _fractionOf(zone.low),
                  to: _fractionOf(zone.high),
                  color: zone.color ?? t.colorFillSecondary,
                ),
            ],
            dotFractions: _dotFractions(),
            activeDots: _activeDots(),
            token: r,
            vertical: widget.vertical,
            included: widget.included,
            fillFromStart: widget.fillFromStart,
            enabled: _enabled,
            hovered: _hovered || _dragging != null,
            dragging: _dragging,
            dropping: _dropping,
          ),
        );

        // The bubble rides inside the slider's own stack rather than in an
        // overlay: it has to follow a handle that moves every frame, and an
        // overlay entry would have to be torn down and rebuilt for each one.
        // The cost is that an ancestor which clips will clip it too.
        // A mark with no words is a dot on the rail, and the dot is what
        // somebody presses. Its target belongs there and nowhere else: put in
        // the band beside the rail, as a label's is, it sat under an invisible
        // patch of nothing while the thing you could see stayed dead.
        //
        // Only where the caller has given the mark something to do. A plain
        // mark still takes no pointer from the rail, which is what keeps a
        // tap on the scale moving the handle.
        final onRail = [
          for (final mark in widget.marks)
            if (!mark.hidden && mark.label == null && mark.markBuilder != null)
              mark,
        ];

        final label = _bubbleLabel();
        final body = label == null && onRail.isEmpty
            ? painted
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  painted,
                  for (final mark in onRail)
                    Positioned(
                      left: widget.vertical
                          ? 0
                          : _alongFor(_fractionOf(mark.value), size.width),
                      top: widget.vertical
                          ? _alongFor(_fractionOf(mark.value), size.height)
                          : 0,
                      child: FractionalTranslation(
                        translation: widget.vertical
                            ? const Offset(0, -0.5)
                            : const Offset(-0.5, 0),
                        child: Builder(
                          builder: (context) => _markLabel(context, t, r, mark),
                        ),
                      ),
                    ),
                  if (label != null)
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
              // On the way up, not on the way down. A press is not yet a
              // tap: pressed and then dragged, a slider that acted at once
              // had already moved the nearest handle under the finger — and a
              // span about to be taken hold of was no longer under the press
              // by the time the drag began.
              onTapUp: (details) => _tap(details.localPosition, size),
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
    // Between the handles rather than on one: the whole span moves. A handle
    // always wins, though — asked of the handles themselves and not of the
    // value under the press.
    //
    // Asking by value looked right for two handles, whose ends are the span's
    // ends, and was wrong the moment a third stood inside it: an added handle
    // is strictly within the span, so the track took every drag meant for it.
    if (widget.draggableTrack &&
        widget.values.length > 1 &&
        _handleAt(details.localPosition, _size) == null) {
      final at = _valueAt(_fractionFor(details.localPosition, _size));
      final sorted = [...widget.values]..sort();
      if (at > sorted.first && at < sorted.last) {
        setState(() {
          _trackFrom = [...widget.values];
          _trackAt = at;
          _dragging = null;
        });
        return;
      }
    }
    setState(() => _dragging = _nearestTo(details.localPosition));
  }

  void _dragUpdate(Offset local, Size size) {
    final from = _trackFrom;
    if (from != null) {
      _moveTrack(_valueAt(_fractionFor(local, size)), from);
      return;
    }
    final fraction = _fractionFor(local, size);
    _moveNearest(fraction, complete: false);
    if (!widget.editable) return;
    final index = _dragging;
    if (index == null) return;
    // Asked of where the handle has just been put, not of `widget.values`:
    // the owner has been handed the new list but has not rebuilt with it
    // yet, so reading the widget here answers about the move before this one.
    //
    // Nothing is decided until the finger lifts, so a handle brought onto a
    // neighbour and taken off it again simply stays.
    final meets = _meetsNeighbour(index, _valueAt(fraction), size);
    if (meets != _dropping) setState(() => _dropping = meets);
  }

  /// Slides every handle by however far the span has been pushed.
  ///
  /// Clamped as one: the shift is cut back until no handle would leave the
  /// scale, so the span keeps its length instead of the leading handle
  /// stopping while the trailing one goes on.
  void _moveTrack(double to, List<double> from) {
    var shift = to - _trackAt!;
    final low = from.reduce((a, b) => a < b ? a : b);
    final high = from.reduce((a, b) => a > b ? a : b);
    final floor = _held(widget.min);
    final ceiling = _held(widget.max);
    if (low + shift < floor) shift = floor - low;
    if (high + shift > ceiling) shift = ceiling - high;
    if (shift == 0) return;
    final next = [for (final v in from) v + shift];
    widget.onChanged?.call(next);
  }

  void _dragEnd() {
    if (_dropping) {
      final index = _dragging;
      setState(() {
        _dropping = false;
        _dragging = null;
      });
      if (index != null && widget.values.length > (widget.minCount ?? 2)) {
        final next = [...widget.values]..removeAt(index);
        widget.onChanged?.call(next);
        widget.onChangeComplete?.call(next);
      }
      return;
    }
    if (_trackFrom != null) {
      widget.onChangeComplete?.call([...widget.values]);
      setState(() {
        _trackFrom = null;
        _trackAt = null;
      });
      return;
    }
    if (_dragging == null) return;
    widget.onChangeComplete?.call([...widget.values]);
    setState(() => _dragging = null);
  }

  /// What a tap does: put a handle in, take one out, or move the nearest.
  ///
  /// Only where the nodes are editable does a tap add or remove; everywhere
  /// else it does what it always did, which is move the handle already
  /// nearest to where it landed.
  void _tap(Offset local, Size size) {
    if (!_enabled) return;
    final fraction = _fractionFor(local, size);
    if (!widget.editable) {
      _moveNearest(fraction, complete: true);
      return;
    }
    final value = _valueAt(fraction);
    final values = widget.values;

    // A tap on a handle does nothing: it is already where it is being asked
    // to go. Taking one out is a drag — see [_dropping].
    if (_handleAt(local, size) != null) return;
    if (values.length >= (widget.maxCount ?? values.length + 1)) return;
    final next = [...values, value]..sort();
    widget.onChanged?.call(next);
    widget.onChangeComplete?.call(next);
  }

  /// Whether the handle being dragged has been brought onto a neighbour, and
  /// goes when the finger lifts.
  ///
  /// Dragging one handle onto another is the only way out of this that
  /// nothing else wants.
  ///
  /// A second tap would make a handle a switch — press it twice and you are
  /// back where you started — and registering a double tap holds the first
  /// one back behind its window, so putting a handle in would wait 300ms for
  /// a tap that is usually not coming. A press held fires on a timer, takes
  /// the drag out of the running, and carries a handle off under the finger
  /// of anybody who paused before moving it. Pulling a handle away from the
  /// rail is not available at all: a one-axis drag recogniser reports nothing
  /// about the other axis, and a pan would lose the arena to any page the
  /// slider is scrolled inside.
  ///
  /// Two handles left standing on the same value is what this costs. For a
  /// control whose handles are the edges between bands, two edges in one
  /// place is a band of nothing — so the trade is the right way round.
  bool _dropping = false;

  /// Whether the handle at [index], put at [me], now covers another.
  bool _meetsNeighbour(int index, double me, Size size) {
    final values = widget.values;
    if (values.length <= (widget.minCount ?? 2)) return false;
    // When the two discs actually cover one another, not when their values
    // are equal. Half a step on a scale of a hundred is two pixels of rail:
    // a catch nobody can hit is a gesture nobody finds, and the whole way out
    // of an added handle was through it.
    //
    // Half a step is kept as the floor, so a coarse scale whose steps are
    // wider than a handle still merges when there is nothing between them.
    final length = widget.vertical ? size.height : size.width;
    final span = widget.max - widget.min;
    final overlap = length <= 0 ? 0.0 : _handleReach * 2 / length * span;
    final reach =
        [overlap, (widget.step ?? 0.0001) / 2].reduce((a, b) => a > b ? a : b);
    for (var i = 0; i < values.length; i++) {
      if (i == index) continue;
      if ((values[i] - me).abs() <= reach) return true;
    }
    return false;
  }

  /// Which handle is under [local], where one is.
  ///
  /// Reckoned in the groove's own length rather than in pixels of the screen,
  /// so the target is the same size whatever the slider was given room for.
  int? _handleAt(Offset local, Size size) {
    final along = _fractionFor(local, size);
    final length = widget.vertical ? size.height : size.width;
    if (length <= 0) return null;
    // Half a handle either side, which is the handle.
    final reach = (_handleReach / length).clamp(0.0, 1.0);
    int? best;
    var away = double.infinity;
    for (var i = 0; i < widget.values.length; i++) {
      final gap = (_fractionOf(widget.values[i]) - along).abs();
      if (gap <= reach && gap < away) {
        away = gap;
        best = i;
      }
    }
    return best;
  }

  /// How far from a handle's middle still counts as the handle.
  double get _handleReach {
    final r = (widget.token ??
            ConfigProvider.componentOf<SliderToken>(context) ??
            const SliderToken())
        ._resolve(context.softToken);
    return r.handleSizeHover / 2 + r.handleLineWidthHover;
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
    return [
      for (final m in widget.marks)
        if (!m.hidden) _fractionOf(m.value),
    ];
  }

  /// Which of those dots the handle has reached.
  List<bool> _activeDots() {
    final values = widget.dots && widget.step != null
        ? [
            for (var v = widget.min; v <= widget.max; v += widget.step!) v,
          ]
        : [
            for (final m in widget.marks)
              if (!m.hidden) m.value
          ];
    final low = widget.fillFromStart
        ? widget.min
        : widget.values.reduce((a, b) => a < b ? a : b);
    final high = widget.values.reduce((a, b) => a > b ? a : b);
    return [for (final v in values) v >= low && v <= high];
  }

  /// Whether the handle has reached [value].
  bool _reached(double value) {
    final low = widget.fillFromStart
        ? widget.min
        : widget.values.reduce((a, b) => a < b ? a : b);
    final high = widget.values.reduce((a, b) => a > b ? a : b);
    return value >= low && value <= high;
  }

  /// One mark's label, styled and then handed to whoever draws it.
  Widget _markLabel(
      BuildContext context, Token t, _ResolvedSliderToken r, SliderMark mark) {
    final base = TextStyle(
      color: mark.disabled ? r.markDisabledColor : r.markColor,
      fontSize: r.markFontSize,
      fontFamily: t.fontFamily,
      fontFamilyFallback: t.fontFamilyFallback,
      decoration: TextDecoration.none,
    ).merge(mark.style);
    // A mark with no words still needs something to be: a box the size of
    // the band, where its dot is. Wrapped in a menu or a popover it is what
    // the pointer finds; left alone it is nothing at all. Without it a
    // wordless mark could be drawn on and never touched.
    final drawn = mark.label == null
        ? SizedBox(width: r.dotSize * 3, height: r.markFontSize * t.lineHeight)
        : DefaultTextStyle.merge(style: base, child: Text(mark.label!));
    final build = mark.markBuilder;
    if (build == null) return drawn;
    return build(context, mark, _reached(mark.value), drawn);
  }

  Widget _withMarks(
    Token t,
    _ResolvedSliderToken r,
    Widget groove,
    double thickness,
  ) {
    final shown = [
      for (final m in widget.marks)
        if (!m.hidden) m
    ];
    final before = [
      for (final m in shown)
        if (m.side == SliderMarkSide.before) m,
    ];
    final after = [
      for (final m in shown)
        if (m.side == SliderMarkSide.after) m,
    ];

    /// One side's labels, each shifted to the point it names.
    ///
    /// Shifted rather than positioned. A stack of positioned children has no
    /// size of its own, so the band had to be told a height — and anything
    /// taller than the number it was told hung out of it: drawn, since the
    /// stack does not clip, and dead to the pointer, since a hit outside a box
    /// is no hit. A popover on a mark worked in its top half and nowhere else.
    ///
    /// Left unpositioned, the children size the stack to the biggest of them,
    /// which is the band's height across a row and its width down a column.
    /// A `Transform` moves them afterwards without touching that, and carries
    /// hit testing with it.
    ///
    /// It also does away with the silent copy that used to be laid out beside
    /// them to give the band a size: a duplicate of every label, kept out of
    /// the semantics tree by hand so a screen reader would not read the marks
    /// twice over.
    Widget band(List<SliderMark> marks) => LayoutBuilder(
          builder: (context, constraints) {
            final extent =
                widget.vertical ? constraints.maxHeight : constraints.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final mark in marks)
                  Transform.translate(
                    offset: widget.vertical
                        ? Offset(0, _alongFor(_fractionOf(mark.value), extent))
                        : Offset(_alongFor(_fractionOf(mark.value), extent), 0),
                    child: FractionalTranslation(
                      // Half its own size back, so a label is centred on the
                      // point it names rather than starting there.
                      translation: widget.vertical
                          ? const Offset(0, -0.5)
                          : const Offset(-0.5, 0),
                      child: _markLabel(context, t, r, mark),
                    ),
                  ),
              ],
            );
          },
        );

    if (widget.vertical) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (before.isNotEmpty) ...[
            band(before),
            SizedBox(width: t.sizeXS),
          ],
          SizedBox(width: thickness, child: groove),
          if (after.isNotEmpty) ...[
            SizedBox(width: t.sizeXS),
            band(after),
          ],
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (before.isNotEmpty) ...[
          // The rail's width, not the widest label's: the marks are laid out
          // by fraction along it.
          SizedBox(width: double.infinity, child: band(before)),
          SizedBox(height: t.sizeXXS),
        ],
        SizedBox(height: thickness, child: groove),
        if (after.isNotEmpty) ...[
          SizedBox(height: t.sizeXXS),
          SizedBox(width: double.infinity, child: band(after)),
        ],
      ],
    );
  }
}

class _SliderPainter extends CustomPainter {
  const _SliderPainter({
    required this.fractions,
    required this.zones,
    required this.dotFractions,
    required this.activeDots,
    required this.token,
    required this.vertical,
    required this.included,
    required this.fillFromStart,
    required this.enabled,
    required this.hovered,
    required this.dragging,
    required this.dropping,
  });

  final List<double> fractions;

  /// Where each zone runs, as fractions along the groove, and what it is
  /// coloured.
  final List<({double from, double to, Color color})> zones;

  final List<double> dotFractions;
  final List<bool> activeDots;
  final _ResolvedSliderToken token;
  final bool vertical;
  final bool included;
  final bool fillFromStart;
  final bool enabled;
  final bool hovered;
  final int? dragging;

  /// Whether the handle being dragged has been pulled clear and will go when
  /// the finger lifts. Drawn faint, so letting go is never a surprise.
  final bool dropping;

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

    // Under the track, over the rail. A zone colours the scale; the track is
    // the answer, and an answer drawn under what it is measured against would
    // be the wrong way round. A slider that is all zones is one to turn
    // `included` off for.
    for (final zone in zones) {
      canvas.drawLine(
        _at(zone.from, size),
        _at(zone.to, size),
        Paint()
          ..color = zone.color
          ..strokeCap = StrokeCap.butt
          ..strokeWidth = token.railSize,
      );
    }

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
      var colour = !enabled
          ? token.handleColorDisabled
          : (dragging == i || hovered
              ? token.handleActiveColor
              : token.handleColor);
      // On its way out: drawn faint, so a handle about to be let go of says
      // so before the finger lifts rather than after.
      final leaving = dropping && dragging == i;
      if (leaving) colour = colour.withValues(alpha: 0.3);
      canvas
        // The ring is drawn outside the disc, the way a focus shadow sits,
        // so the handle keeps the diameter its token names.
        ..drawCircle(
          centre,
          diameter / 2 + ring,
          Paint()..color = colour,
        )
        ..drawCircle(
          centre,
          diameter / 2,
          Paint()
            ..color = leaving
                ? const Color(0xFFFFFFFF).withValues(alpha: 0.3)
                : const Color(0xFFFFFFFF),
        );
    }
  }

  @override
  bool shouldRepaint(_SliderPainter old) =>
      !_sameNumbers(old.fractions, fractions) ||
      !_sameNumbers(old.dotFractions, dotFractions) ||
      old.zones.length != zones.length ||
      !_sameZones(old.zones, zones) ||
      old.enabled != enabled ||
      old.hovered != hovered ||
      old.dragging != dragging ||
      old.dropping != dropping ||
      old.included != included ||
      old.vertical != vertical;

  static bool _sameZones(
    List<({double from, double to, Color color})> a,
    List<({double from, double to, Color color})> b,
  ) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

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
