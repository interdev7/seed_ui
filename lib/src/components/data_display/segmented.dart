import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../l10n/seed_localizations.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';

/// Layout axis for a [Segmented].
enum SegmentedDirection {
  /// Options run left to right.
  horizontal,

  /// Options stack top to bottom.
  vertical
}

/// Which end of an overflowing [Segmented] an arrow steps towards.
enum SegmentedArrow {
  /// Back towards the start of the run — leftwards, or upwards in a column.
  previous,

  /// On towards the end.
  next,
}

/// Builds one of the two arrows a scrolling [Segmented] offers.
///
/// One builder for both, told apart by [arrow], rather than a pair: the two
/// are one thing pointing opposite ways, and a pair would have them written
/// twice and free to drift apart. Where they really differ, a `switch` inside
/// is one line. It is the shape `EmptyBuilder` already has.
///
/// Call [step] when the arrow is pressed; the kit places what you return.
typedef SegmentedArrowBuilder = Widget Function(
  BuildContext context,
  SegmentedArrow arrow,
  VoidCallback step,
);

/// Drives an overflowing [Segmented] from outside the build.
///
/// Scrolling only. Which segment is *selected* already has an owner — `value`
/// and `onChanged` — and a controller that could also select would make two
/// owners of one truth, which disagree sooner or later. This moves the run;
/// it never changes the answer.
///
/// ```dart
/// final segments = SegmentedController();
/// ...
/// Segmented<int>(controller: segments, value: v, options: o, onChanged: f)
/// ...
/// segments.next();
/// ```
///
/// It is a [ChangeNotifier] and reports [canStepBack] and [canStepOn], so a
/// button of your own elsewhere on the page knows when to grey itself out.
class SegmentedController extends ChangeNotifier {
  /// Creates a [SegmentedController].
  SegmentedController();

  void Function(bool forward)? _step;
  void Function(bool toEnd)? _jump;
  void Function(int index)? _reveal;
  bool _canStepBack = false;
  bool _canStepOn = false;

  /// Whether anything is hidden behind the start of the run.
  bool get canStepBack => _canStepBack;

  /// Whether anything is hidden past its end.
  bool get canStepOn => _canStepOn;

  /// Brings one more segment into view at the end.
  void next() => _step?.call(true);

  /// Brings one more into view at the start.
  void previous() => _step?.call(false);

  /// Runs back to the first segment.
  void toStart() => _jump?.call(false);

  /// Runs on to the last.
  void toEnd() => _jump?.call(true);

  /// Brings the segment at [index] into view, moving as little as possible.
  ///
  /// A no-op where it is already in view, and where the run does not scroll.
  void scrollTo(int index) => _reveal?.call(index);

  void _attach({
    required void Function(bool) step,
    required void Function(bool) jump,
    required void Function(int) reveal,
  }) {
    _step = step;
    _jump = jump;
    _reveal = reveal;
  }

  void _detach() {
    _step = null;
    _jump = null;
    _reveal = null;
  }

  /// Told by the control after every layout.
  void _report(bool back, bool on) {
    if (back == _canStepBack && on == _canStepOn) return;
    _canStepBack = back;
    _canStepOn = on;
    notifyListeners();
  }
}

/// One option in a [Segmented].
@immutable
class SegmentedOption<T> {
  /// Creates a [SegmentedOption].
  const SegmentedOption({
    required this.value,
    this.label,
    this.icon,
    this.child,
    this.disabled = false,
  }) : assert(
          label != null || icon != null || child != null,
          'a segment needs a label, an icon, or a custom child',
        );

  /// The value reported when this segment is selected.
  final T value;

  /// Text shown in the segment.
  final String? label;

  /// Icon shown before the label, or alone.
  final Widget? icon;

  /// Custom content, replacing [label] and [icon] entirely.
  ///
  /// It receives no automatic colouring, so style it yourself if it should
  /// dim when unselected.
  final Widget? child;

  /// Whether this individual segment is unselectable.
  final bool disabled;
}

/// Per-component design tokens for [Segmented].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(segmented: SegmentedToken(...)))`,
/// or per instance via [Segmented.token].
@immutable
class SegmentedToken {
  /// Creates a [SegmentedToken].
  const SegmentedToken({
    this.trackBg,
    this.trackPadding,
    this.itemColor,
    this.itemHoverColor,
    this.itemHoverBg,
    this.itemSelectedBg,
    this.itemSelectedColor,
    this.borderRadius,
    this.borderRadiusSM,
    this.borderRadiusLG,
    this.arrowBg,
    this.arrowHoverBg,
    this.arrowColor,
  });

  /// Track background color (`trackBg`).
  final Color? trackBg;

  /// Track inner padding (`trackPadding`).
  final double? trackPadding;

  /// Unselected item text color (`itemColor`).
  final Color? itemColor;

  /// Item hover text color (`itemHoverColor`).
  final Color? itemHoverColor;

  /// Fill behind an unselected segment while the pointer is over it
  /// (`itemHoverBg`).
  final Color? itemHoverBg;

  /// Selected thumb background color (`itemSelectedBg`).
  final Color? itemSelectedBg;

  /// Selected item text color (`itemSelectedColor`).
  final Color? itemSelectedColor;

  /// Corner radius for standard control (`borderRadius`).
  final double? borderRadius;

  /// Corner radius for small control (`borderRadiusSM`).
  final double? borderRadiusSM;

  /// Corner radius for large control (`borderRadiusLG`).
  final double? borderRadiusLG;

  /// Fill behind a scroll button. Translucent, so the segment it covers is
  /// still legible underneath.
  final Color? arrowBg;

  /// Fill behind a scroll button under the pointer.
  final Color? arrowHoverBg;

  /// Colour of a scroll button's caret.
  final Color? arrowColor;

  _ResolvedSegmentedToken _resolve(Token t) => _ResolvedSegmentedToken(
        // The layout background, not a translucent fill. A fill lightens the
        // track in a dark theme, which leaves the elevated thumb *darker* than
        // the groove it sits in — the elevation reads inverted, and the only
        // thing separating the two is the shadow.
        trackBg: trackBg ?? t.colorBgLayout,
        trackPadding: trackPadding ?? t.sizeXXS / 2,
        itemColor: itemColor ?? t.colorTextSecondary,
        itemHoverColor: itemHoverColor ?? t.colorText,
        itemHoverBg: itemHoverBg ?? t.colorFillSecondary,
        itemSelectedBg: itemSelectedBg ?? t.colorBgElevated,
        itemSelectedColor: itemSelectedColor ?? t.colorText,
        borderRadius: borderRadius ?? t.borderRadius,
        borderRadiusSM: borderRadiusSM ?? t.borderRadiusSM,
        borderRadiusLG: borderRadiusLG ?? t.borderRadiusLG,
        // The elevated surface rather than the track's own: a button that
        // matched the groove would vanish into it. Translucent, so the segment
        // sliding under it stays readable.
        arrowBg: arrowBg ?? t.colorBgElevated.withValues(alpha: 0.9),
        arrowHoverBg: arrowHoverBg ?? t.colorBgElevated,
        arrowColor: arrowColor ?? t.colorText,
      );
}

@immutable
class _ResolvedSegmentedToken {
  const _ResolvedSegmentedToken({
    required this.trackBg,
    required this.trackPadding,
    required this.itemColor,
    required this.itemHoverColor,
    required this.itemHoverBg,
    required this.itemSelectedBg,
    required this.itemSelectedColor,
    required this.borderRadius,
    required this.borderRadiusSM,
    required this.borderRadiusLG,
    required this.arrowBg,
    required this.arrowHoverBg,
    required this.arrowColor,
  });

  final Color trackBg;
  final double trackPadding;
  final Color itemColor;
  final Color itemHoverColor;
  final Color itemHoverBg;
  final Color itemSelectedBg;
  final Color itemSelectedColor;
  final double borderRadius;
  final double borderRadiusSM;
  final double borderRadiusLG;
  final Color arrowBg;
  final Color arrowHoverBg;
  final Color arrowColor;
}

/// Defaults for every [Segmented] under a `ConfigProvider`.
///
/// House style for segmented controls.
@immutable
class SegmentedDefaults {
  /// Creates a [SegmentedDefaults].
  const SegmentedDefaults({
    this.direction,
    this.size,
    this.disabled,
    this.scrollButtons,
  });

  /// Which way the segments run.
  final Axis? direction;

  /// Whether an overflowing run offers arrows to step through it.
  final bool? scrollButtons;

  /// Which control height a [Segmented] takes, unless it names one.
  ///
  /// Nearer than `ConfigProvider.componentSize`, so this wins where both
  /// are set: small buttons on an otherwise normal screen.
  final SoftSize? size;

  /// Whether a [Segmented] is disabled, unless it says otherwise.
  ///
  /// Nearer than `ConfigProvider.componentDisabled`, and beaten in turn by
  /// the widget's own word.
  final bool? disabled;
}

/// A single-select control laid out as a strip of segments, with a thumb that
/// slides to the chosen one — for switching between a few mutually exclusive
/// options in place.
///
/// ```dart
/// Segmented<String>(
///   value: _view,
///   options: const [
///     SegmentedOption(value: 'list', label: 'List'),
///     SegmentedOption(value: 'grid', label: 'Grid'),
///   ],
///   onChanged: (v) => setState(() => _view = v),
/// )
/// ```
///
/// Segments size to their content, so long labels are never clipped. Set
/// [block] to stretch them to fill the width equally, or [direction] to stack
/// them vertically. For more than a handful of options, or navigation between
/// views, prefer tabs.
class Segmented<T> extends StatefulWidget {
  /// Creates a [Segmented].
  const Segmented({
    super.key,
    required this.value,
    required this.options,
    this.onChanged,
    this.size,
    this.direction,
    this.block = false,
    this.scrollButtons,
    this.arrowBuilder,
    this.controller,
    this.disabled,
    this.trackColor,
    this.thumbColor,
    this.token,
  });

  /// The selected value. Must match one option's value.
  final T value;

  /// The segments, in order.
  final List<SegmentedOption<T>> options;

  /// Called with the new value when a segment is chosen. Null disables the
  /// whole control.
  final ValueChanged<T>? onChanged;

  /// Which height preset to use.
  final SoftSize? size;

  /// Whether the segments run in a row or a column.
  final Axis? direction;

  /// Stretch the segments to fill the available space equally.
  final bool block;

  /// Builds the arrows yourself. Null draws the kit's.
  ///
  /// The kit still places what you return, at the end it steps towards; the
  /// placement is the fiddly part and not worth handing over.
  final SegmentedArrowBuilder? arrowBuilder;

  /// Drives the run's scrolling from outside the build.
  ///
  /// Scrolling only: which segment is selected stays with [value] and
  /// [onChanged].
  final SegmentedController? controller;

  /// Whether a run too big for its space offers arrows to step through it.
  ///
  /// They appear only on the side that has something hidden, and go again when
  /// it does not — a run that fits shows none. Defaults to yes: segments that
  /// scroll with nothing to say so look like all the segments there are.
  final bool? scrollButtons;

  /// Greys the whole control out and blocks selection.
  final bool? disabled;

  /// Overrides the track (background) colour.
  final Color? trackColor;

  /// Overrides the sliding thumb's colour.
  final Color? thumbColor;

  /// Per-instance token overrides.
  final SegmentedToken? token;

  @override
  State<Segmented<T>> createState() => _SoftSegmentedState<T>();
}

class _SoftSegmentedState<T> extends State<Segmented<T>> {
  /// The defaults set for this component in the subtree, if any.
  SegmentedDefaults? get _defaults =>
      ConfigProvider.defaultsOf<SegmentedDefaults>(context);

  /// This widget's word, then the subtree's, then the kit's.
  Axis get _direction =>
      widget.direction ?? _defaults?.direction ?? Axis.horizontal;

  /// Whether this control is disabled: its own word, else the one set
  /// for the subtree, else no.
  bool get _disabled =>
      widget.disabled ??
      _defaults?.disabled ??
      ConfigProvider.componentDisabledOf(context) ??
      false;

  /// The size in force: this widget's own, else the one set for the
  /// subtree, else the standard preset.
  SoftSize get _size =>
      widget.size ??
      _defaults?.size ??
      ConfigProvider.componentSizeOf(context) ??
      SoftSize.middle;

  final GlobalKey _stackKey = GlobalKey();
  final Map<int, GlobalKey> _segmentKeys = {};
  final ScrollController _scroll = ScrollController();
  // Kept so a step can clear a button of whatever size, including one the
  // caller built.
  final GlobalKey _backArrowKey = GlobalKey();
  final GlobalKey _onArrowKey = GlobalKey();
  Rect? _thumbRect;
  int? _hoveredIndex;

  /// Whether anything is hidden behind each end of the viewport.
  bool _canStepBack = false;
  bool _canStepOn = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_syncArrows);
    widget.controller?._attach(step: _step, jump: _jump, reveal: _reveal);
  }

  @override
  void didUpdateWidget(Segmented<T> old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      old.controller?._detach();
      widget.controller?._attach(step: _step, jump: _jump, reveal: _reveal);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _scroll
      ..removeListener(_syncArrows)
      ..dispose();
    super.dispose();
  }

  bool get _scrollButtons =>
      widget.scrollButtons ?? _defaults?.scrollButtons ?? true;

  /// Turns the arrows on and off as the run scrolls.
  ///
  /// Read from the position rather than from a count of segments: a run whose
  /// content fits has no extent to scroll and so neither arrow, whatever the
  /// options say.
  void _syncArrows() {
    if (!mounted) return;
    final has = _scroll.hasClients;
    final back = has && _scroll.offset > _scroll.position.minScrollExtent + 0.5;
    final on = has && _scroll.offset < _scroll.position.maxScrollExtent - 0.5;
    widget.controller?._report(back, on);
    if (back != _canStepBack || on != _canStepOn) {
      setState(() {
        _canStepBack = back;
        _canStepOn = on;
      });
    }
  }

  /// Runs to one end of the scroll.
  void _jump(bool toEnd) {
    if (!_scroll.hasClients) return;
    final token = context.softToken;
    _scroll.animateTo(
      toEnd
          ? _scroll.position.maxScrollExtent
          : _scroll.position.minScrollExtent,
      duration: token.motionDurationMid,
      curve: token.motionEaseInOut,
    );
  }

  /// Brings one segment into view, moving as little as it takes.
  void _reveal(int index) {
    if (!_scroll.hasClients) return;
    if (index < 0 || index >= widget.options.length) return;
    final span = _spanOf(index);
    if (span == null) return;
    final position = _scroll.position;
    final start = position.pixels;
    final end = start + position.viewportDimension;
    final backInset = _canStepBack ? _arrowExtentOf(_backArrowKey) : 0.0;
    final onInset = _canStepOn ? _arrowExtentOf(_onArrowKey) : 0.0;

    double? target;
    if (span.$2 > end - onInset) {
      target = span.$2 - position.viewportDimension + onInset;
    } else if (span.$1 < start + backInset) {
      target = span.$1 - backInset;
    }
    if (target == null) return;
    final token = context.softToken;
    _scroll.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: token.motionDurationMid,
      curve: token.motionEaseInOut,
    );
  }

  /// Where segment [index] begins and ends along the scroll, or null while the
  /// geometry is not there to say.
  (double, double)? _spanOf(int index) {
    final strip = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final box =
        _segmentKeys[index]?.currentContext?.findRenderObject() as RenderBox?;
    if (strip == null || box == null || !strip.hasSize || !box.hasSize) {
      return null;
    }
    final from = _offsetOf(box, strip);
    return (from, from + (_vertical ? box.size.height : box.size.width));
  }

  /// How far across a laid-out arrow measures, or the kit's own size while it
  /// has not been laid out yet.
  double _arrowExtentOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return _arrowExtent(context.softToken);
    return _vertical ? box.size.height : box.size.width;
  }

  /// How wide one scroll button is.
  ///
  /// Shared by the button and by the arithmetic that steps the run, because a
  /// step has to clear the button: they sit *over* the ends, so a segment
  /// brought exactly to the edge would arrive underneath one.
  double _arrowExtent(Token t) => t.fontSize * 2;

  /// How far along the scroll a segment begins.
  ///
  /// Not simply its offset inside the strip: a run that reads right to left
  /// starts at the far end, where an offset of zero shows the content's right
  /// edge, and a segment's distance is measured from there.
  double _offsetOf(RenderBox segment, RenderBox strip) {
    final origin = segment.localToGlobal(Offset.zero, ancestor: strip);
    if (_vertical) return origin.dy;
    if (Directionality.of(context) == TextDirection.ltr) return origin.dx;
    return strip.size.width - (origin.dx + segment.size.width);
  }

  /// Brings exactly one more segment into view at one end.
  ///
  /// One at a time rather than a page: the arrow is there because a segment is
  /// half-hidden, and the thing to do about that is to show it.
  void _step(bool forward) {
    if (!_scroll.hasClients) return;
    final strip = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (strip == null || !strip.hasSize) return;

    final position = _scroll.position;
    // The buttons sit over the ends, so a step has to clear one — and it is
    // measured rather than assumed, since a caller's own arrow may be any
    // size at all.
    final inset = _arrowExtentOf(forward ? _onArrowKey : _backArrowKey);
    final start = position.pixels;
    final end = start + position.viewportDimension;

    double? target;
    for (var i = 0; i < widget.options.length; i++) {
      final box =
          _segmentKeys[i]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final from = _offsetOf(box, strip);
      final to = from + (_vertical ? box.size.height : box.size.width);
      if (forward) {
        // The first segment whose far edge is past the viewport's, less the
        // button it would otherwise land under.
        if (to > end - inset + 0.5) {
          target = to - position.viewportDimension + inset;
          break;
        }
      } else if (from < start + inset - 0.5) {
        // The last one whose near edge is behind the viewport's, again with
        // room for the button.
        target = from - inset;
      }
    }
    if (target == null) return;

    var to = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    // A segment wider than the viewport cannot be framed, and the arithmetic
    // above would then aim backwards. Fall back to a viewport's worth.
    if (forward && to <= start + 0.5) {
      to = math.min(
          position.maxScrollExtent, start + position.viewportDimension);
    } else if (!forward && to >= start - 0.5) {
      to = math.max(
          position.minScrollExtent, start - position.viewportDimension);
    }

    final token = context.softToken;
    _scroll.animateTo(
      to,
      duration: token.motionDurationMid,
      curve: token.motionEaseInOut,
    );
  }

  bool get _enabled => !_disabled && widget.onChanged != null;
  bool get _vertical => _direction == Axis.vertical;

  int get _selectedIndex {
    final i = widget.options.indexWhere((o) => o.value == widget.value);
    return i < 0 ? 0 : i;
  }

  GlobalKey _keyFor(int i) => _segmentKeys.putIfAbsent(i, GlobalKey.new);

  double _height(Token token) => switch (_size) {
        SoftSize.small => token.controlHeightSM,
        SoftSize.middle => token.controlHeight,
        SoftSize.large => token.controlHeightLG,
      };

  double _radius(_ResolvedSegmentedToken r) => switch (_size) {
        SoftSize.small => r.borderRadiusSM,
        SoftSize.middle => r.borderRadius,
        SoftSize.large => r.borderRadiusLG,
      };

  double _fontSize(Token token) => switch (_size) {
        SoftSize.small => token.fontSizeSM,
        SoftSize.middle => token.fontSize,
        SoftSize.large => token.fontSizeLG,
      };

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<SegmentedToken>(context) ??
            const SegmentedToken())
        ._resolve(token);
    // Positions depend on the laid-out sizes, so measure after the frame and
    // let AnimatedPositioned slide the thumb to the selected segment's rect.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

    final segmentWidgets = [
      for (var i = 0; i < widget.options.length; i++)
        _buildSegment(token, r, i, widget.options[i], i == _selectedIndex),
    ];

    final rect = _thumbRect;
    final control = Container(
      padding: EdgeInsets.all(r.trackPadding),
      decoration: BoxDecoration(
        color: widget.trackColor ?? r.trackBg,
        borderRadius: BorderRadius.circular(_radius(r)),
      ),
      child: _withArrows(
        token,
        r,
        _maybeScrollable(
          Stack(
            key: _stackKey,
            children: [
              // The thumb slides behind the labels once measured. It is positioned
              // in the Stack's own coordinates, so the rect is measured relative to
              // the Stack — not the padded Container.
              if (rect != null)
                AnimatedPositioned(
                  duration: token.motionDurationMid,
                  curve: token.motionEaseInOut,
                  left: rect.left,
                  top: rect.top,
                  width: rect.width,
                  height: rect.height,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _enabled
                          ? (widget.thumbColor ?? r.itemSelectedBg)
                          : (widget.thumbColor ?? r.itemSelectedBg)
                              .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(_radius(r)),
                      boxShadow: _enabled ? token.boxShadowSecondary : null,
                    ),
                  ),
                ),
              _strip(segmentWidgets),
            ],
          ),
        ),
      ),
    );

    if (block) return control;

    // the segmented control is `inline-flex`: it is as wide as its
    // options and no wider. A parent that hands down a tight width — a stretch
    // Column, a wide page — would otherwise blow the track across the screen.
    // `block: true` is how you ask for the full width.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      // IntrinsicWidth asks the strip how wide it wants to be and then honours
      // the incoming constraint: room enough, and the control is exactly its
      // options wide; not enough, and it is clamped, which is what gives the
      // scroll view below something to scroll inside.
      child: _vertical ? control : IntrinsicWidth(child: control),
    );
  }

  /// Lays the arrows over the ends of an overflowing run.
  ///
  /// Over, not beside: a button that took space of its own would narrow the
  /// viewport the moment it appeared, hiding another segment and so keeping
  /// itself needed. Each sits on the end it steps towards and goes when that
  /// end has nothing left to show.
  Widget _withArrows(
    Token token,
    _ResolvedSegmentedToken r,
    Widget child,
  ) {
    if (block || !_scrollButtons) return child;
    final words = SeedLocalizations.of(context);

    Widget place({required bool forward, required Widget arrow}) {
      final keyed = KeyedSubtree(
        key: forward ? _onArrowKey : _backArrowKey,
        child: arrow,
      );
      // A column's ends are its top and bottom; a row's follow the reading
      // direction, which is why one is directional and the other is not.
      return _vertical
          ? Positioned(
              left: 0,
              right: 0,
              top: forward ? null : 0,
              bottom: forward ? 0 : null,
              child: keyed,
            )
          : PositionedDirectional(
              start: forward ? null : 0,
              end: forward ? 0 : null,
              top: 0,
              bottom: 0,
              child: keyed,
            );
    }

    Widget arrowFor(bool forward) {
      void step() => _step(forward);
      final which = forward ? SegmentedArrow.next : SegmentedArrow.previous;
      final custom = widget.arrowBuilder;
      if (custom != null) return custom(context, which, step);
      return _ScrollArrow(
        forward: forward,
        vertical: _vertical,
        token: token,
        resolved: r,
        radius: _radius(r),
        extent: _arrowExtent(token),
        label: forward ? words.next : words.previous,
        onPressed: step,
      );
    }

    return Stack(
      children: [
        child,
        if (_canStepBack) place(forward: false, arrow: arrowFor(false)),
        if (_canStepOn) place(forward: true, arrow: arrowFor(true)),
      ],
    );
  }

  /// Lets a horizontal run scroll rather than overflow.
  ///
  /// A content-sized control cannot always have the width it asks for — a
  /// phone is narrower than six segments. Overflowing paints the debug stripes
  /// and hides the segments past the edge, so the run scrolls instead. With
  /// room to spare the viewport is exactly the content's width and there is
  /// nothing to scroll, so this costs the common case nothing.
  Widget _maybeScrollable(Widget child) {
    if (block) return child;
    if (_vertical) {
      // No test for a bounded height first: a SingleChildScrollView shrinks to
      // its child where the main axis is unbounded rather than complaining, so
      // a column left to grow grows, has no extent to scroll, offers no arrows
      // and does not take the page's drag. All of which was measured before
      // the guard that used to be here was removed.
      return SingleChildScrollView(
        controller: _scroll,
        physics: const ClampingScrollPhysics(),
        child: child,
      );
    }
    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      // The thumb is measured against the strip's own coordinates, so it
      // travels with the content instead of floating over the viewport.
      physics: const ClampingScrollPhysics(),
      child: child,
    );
  }

  /// Lays the segments out along the chosen axis. Equal-size layouts wrap the
  /// row/column in an Intrinsic box — the safe place for it, unlike around the
  /// whole Stack, which trips a rendering assertion.
  Widget _strip(List<Widget> segments) {
    if (_vertical) {
      // A column of equal-width segments; IntrinsicWidth bounds the cross axis
      // so `stretch` is legal.
      return IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: segments,
        ),
      );
    }
    if (block) {
      // Equal-width segments filling the width. IntrinsicHeight keeps them all
      // the height of the tallest, which matters when one carries an icon and
      // another does not.
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: segments,
        ),
      );
    }
    // Content-sized single-line segments are all one control-height tall, so
    // they line up without any Intrinsic box.
    return Row(mainAxisSize: MainAxisSize.min, children: segments);
  }

  bool get block => widget.block;

  void _measure() {
    // Whether either end has something hidden is a fact about the laid-out
    // run, so it is settled here with the thumb rather than guessed at during
    // build. This also covers a resize and a change of options, both of which
    // reach this the same way.
    _syncArrows();
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final segBox = _segmentKeys[_selectedIndex]
        ?.currentContext
        ?.findRenderObject() as RenderBox?;
    if (stackBox == null || segBox == null || !segBox.hasSize) return;
    final origin = segBox.localToGlobal(Offset.zero, ancestor: stackBox);
    final rect = origin & segBox.size;
    if (rect != _thumbRect && mounted) setState(() => _thumbRect = rect);
  }

  Widget _buildSegment(
    Token token,
    _ResolvedSegmentedToken r,
    int index,
    SegmentedOption<T> option,
    bool selected,
  ) {
    final enabled = _enabled && !option.disabled;
    final color = !enabled
        ? token.colorTextQuaternary
        : selected
            ? r.itemSelectedColor
            : r.itemColor;
    final hovered = _hoveredIndex == index && enabled && !selected;

    final label = option.label == null
        ? null
        : Text(
            option.label!,
            textAlign: TextAlign.center,
            // A segment is one line, always. Content-sized ones are as wide as
            // their label and never need more; a block one shares the width
            // equally and cuts what will not fit, which keeps the run one
            // control tall however long a label is. Wrapping instead made the
            // whole strip grow a second line to suit its longest word.
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: _fontSize(token),
              fontFamily: token.fontFamily,
              fontFamilyFallback: token.fontFamilyFallback,
              height: 1.2,
              decoration: TextDecoration.none,
            ),
          );

    final content = option.child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (option.icon != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: color, size: _fontSize(token)),
                child: option.icon!,
              ),
              if (label != null) SizedBox(width: token.sizeXXS),
            ],
            if (label != null)
              // In block mode the row is width-bounded, and Flexible is what
              // lets the label shrink below its natural width so the ellipsis
              // has somewhere to happen. Elsewhere the row is unbounded and
              // Flexible would be illegal, so the label goes in directly.
              block ? Flexible(child: label) : label,
          ],
        );

    final segment = KeyedSubtree(
      key: _keyFor(index),
      child: MouseRegion(
        cursor: enabled && !selected
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: enabled ? (_) => _setHovered(index) : null,
        onExit: enabled ? (_) => _setHovered(null) : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled && !selected
              ? () => widget.onChanged!(option.value)
              : null,
          child: AnimatedContainer(
            duration: token.motionDurationFast,
            curve: token.motionEaseInOut,
            constraints: BoxConstraints(minHeight: _height(token)),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(
              horizontal: token.sizeSM,
              vertical: token.sizeXXS / 2,
            ),
            decoration: BoxDecoration(
              // A faint highlight while hovering an unselected segment.
              color: hovered ? r.itemHoverBg : null,
              borderRadius: BorderRadius.circular(_radius(r)),
            ),
            child: content,
          ),
        ),
      ),
    );

    // Block mode stretches each segment to an equal share of the main axis.
    if (!block) return segment;
    return Expanded(child: segment);
  }

  void _setHovered(int? index) {
    if (_hoveredIndex != index && mounted) {
      setState(() => _hoveredIndex = index);
    }
  }
}

/// One of the two buttons that step an overflowing [Segmented] along.
class _ScrollArrow extends StatefulWidget {
  const _ScrollArrow({
    required this.forward,
    required this.vertical,
    required this.token,
    required this.resolved,
    required this.radius,
    required this.extent,
    required this.label,
    required this.onPressed,
  });

  final bool forward;
  final bool vertical;
  final Token token;
  final _ResolvedSegmentedToken resolved;
  final double radius;
  final double extent;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_ScrollArrow> createState() => _ScrollArrowState();
}

class _ScrollArrowState extends State<_ScrollArrow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    final glyph = t.fontSize;
    // ChevronPainter points right, so every other direction is a turn from
    // there. A row that reads right to left travels the other way, which the
    // caret has to follow — a column has no such question.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final turn = widget.vertical
        ? (widget.forward ? math.pi / 2 : -math.pi / 2)
        : ((widget.forward != rtl) ? 0.0 : math.pi);

    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: t.motionDurationFast,
            curve: t.motionEaseOut,
            width: widget.vertical ? null : widget.extent,
            height: widget.vertical ? widget.extent : null,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.resolved.arrowHoverBg
                  : widget.resolved.arrowBg,
              borderRadius: BorderRadius.circular(widget.radius),
            ),
            child: Transform.rotate(
              angle: turn,
              child: CustomPaint(
                size: Size.square(glyph),
                painter: ChevronPainter(widget.resolved.arrowColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
