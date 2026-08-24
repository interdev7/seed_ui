import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../icons/icons.dart' show CheckPainter, CrossPainter, ChevronPainter;
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/rail.dart';
import '../feedback/progress.dart';

/// How much wider than its marker a progress ring sits — the room a run
/// reserves when [Steps.percent] or [Steps.progress] is in play.
const double stepsRingPadding = 12;

/// Where a step stands.
enum StepStatus {
  /// Not reached yet.
  wait,

  /// The step being worked on.
  process,

  /// Done.
  finish,

  /// Done badly: the process stopped here.
  error,
}

/// How a [Steps] draws itself.
enum StepsType {
  /// Numbered markers with titles and content.
  standard,

  /// Small dots instead of numbered markers.
  dot,

  /// A compact run of dots and titles, for tight spaces such as a popover.
  inline,

  /// Tappable blocks separated by arrows, the current one underlined.
  navigation,

  /// Each step in its own panel.
  panel,
}

/// Which type scale a run lands on once its `size` is resolved. There are
/// two web-standard scales — default and small; the third follows the kit's
/// own [SoftSize].
enum _Scale {
  small,
  middle,
  large;

  double title(Token t) => switch (this) {
        _Scale.small => t.fontSize,
        _Scale.middle => t.fontSizeLG,
        _Scale.large => t.fontSizeXL,
      };

  double content(Token t) => switch (this) {
        _Scale.small => t.fontSizeSM,
        _Scale.middle => t.fontSize,
        _Scale.large => t.fontSizeLG,
      };

  /// Padding inside a [StepsType.navigation] block.
  EdgeInsets blockPadding(Token t) => switch (this) {
        _Scale.small =>
          EdgeInsets.symmetric(horizontal: t.sizeXS, vertical: t.sizeXS),
        _Scale.middle =>
          EdgeInsets.symmetric(horizontal: t.sizeXS, vertical: t.sizeSM),
        _Scale.large =>
          EdgeInsets.symmetric(horizontal: t.sizeSM, vertical: t.size),
      };

  double padding(Token t) => switch (this) {
        _Scale.small => t.sizeXS,
        _Scale.middle => t.size,
        _Scale.large => t.sizeLG,
      };

  /// A run sized by a bare number takes the scale its marker is nearest to,
  /// so the type keeps up with the circle it sits beside.
  static _Scale forMarker(double marker) => marker <= 26
      ? _Scale.small
      : (marker >= 38 ? _Scale.large : _Scale.middle);

  static _Scale of(ControlSize size) => switch (size) {
        SoftSize.small => _Scale.small,
        SoftSize.middle => _Scale.middle,
        SoftSize.large => _Scale.large,
        ExplicitSquareSize(:final dimension) => forMarker(dimension),
        ExplicitSize(:final height) => forMarker(height),
      };
}

/// What a horizontal run does when its steps will not fit.
enum StepsOverflow {
  /// Keeps every step and scrolls sideways — the default.
  scroll,

  /// Folds steps away until the rest fit, as [Steps.maxCount] does by hand:
  /// the first, the last, the one in play and its nearest neighbours stay, and
  /// each hidden stretch becomes an ellipsis.
  fold,
}

/// Whether markers are filled or outlined.
enum StepsVariant {
  /// Markers are solid, filled with their status colour.
  filled,

  /// Markers are hollow, drawn as a ring in their status colour.
  outlined
}

/// Which way the steps run.
enum StepsOrientation {
  /// Steps run left to right, rails between them.
  horizontal,

  /// Steps stack top to bottom, rails down the side.
  vertical
}

/// Whether a title sits beside its marker or under it.
enum StepTitlePlacement {
  /// The title sits beside its marker.
  horizontal,

  /// The title sits under its marker.
  vertical
}

/// One step.
@immutable
class StepItem {
  /// Creates a [StepItem].
  const StepItem({
    this.title,
    this.subTitle,
    this.content,
    this.icon,
    this.status,
    this.disabled = false,
  });

  /// The step's name.
  final Widget? title;

  /// A short aside next to the title — a duration, a count.
  final Widget? subTitle;

  /// Supporting text under the title.
  final Widget? content;

  /// Replaces the marker's number.
  final Widget? icon;

  /// Forces this step's status. Null derives it from [Steps.current].
  final StepStatus? status;

  /// Blocks tapping this step.
  final bool disabled;
}

/// Drives a [Steps] from outside the widget — the wizard's "next" and "back".
///
/// ```dart
/// final steps = StepsController();
/// ...
/// Button(onPressed: steps.next, child: const Text('Next'));
/// Steps(controller: steps, items: [...]);
/// ```
///
/// Dispose it with the widget that owns it. A [Steps] driven by `current` and
/// `onChange`, or left to itself, needs no controller at all.
class StepsController extends ChangeNotifier {
  /// Creates a [StepsController].
  StepsController({int current = 0}) : _current = current;

  int _current;

  /// How many steps the attached [Steps] has, so [next] knows where to stop.
  int _length = 0;

  /// The step being worked on, counting from zero.
  int get current => _current;

  set current(int value) => goTo(value);

  /// Moves on, stopping at the last step.
  void next() => goTo(_current + 1);

  /// Goes back, stopping at the first.
  void previous() => goTo(_current - 1);

  /// Jumps to [index], clamped to the steps that exist.
  void goTo(int index) {
    final limit = _length > 0 ? _length - 1 : index;
    final clamped = index.clamp(0, limit < 0 ? 0 : limit);
    if (clamped == _current) return;
    _current = clamped;
    notifyListeners();
  }
}

/// Per-component design tokens for [Steps] — its own token table.
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(steps: StepsToken(...)))`,
/// or per instance via [Steps.token].
@immutable
class StepsToken {
  /// Creates a [StepsToken].
  const StepsToken({
    this.iconSize,
    this.iconSizeSM,
    this.iconSizeLG,
    this.dotSize,
    this.dotCurrentSize,
    this.railThickness,
    this.itemGap,
    this.railInset,
    this.contentMaxWidth,
    this.panelPadding,
    this.panelRadius,
    this.panelArrowWidth,
    this.panelMinWidth,
    this.panelWidth,
    this.panelHeight,
    this.itemMinWidth,
    this.itemWidth,
    this.itemHeight,
    this.railLength,
    this.railMinLength,
    this.arrowColor,
  });

  /// Diameter of a numbered marker (`iconSize`).
  final double? iconSize;

  /// Its small-size counterpart (`iconSizeSM`).
  final double? iconSizeSM;

  /// Its large-size counterpart — the kit's own third size.
  final double? iconSizeLG;

  /// Diameter of a dot marker (`dotSize`).
  final double? dotSize;

  /// Diameter of the current step's dot (`dotCurrentSize`).
  final double? dotCurrentSize;

  /// Thickness of the rail between markers.
  final double? railThickness;

  /// Space between a marker and its title, and between steps.
  final double? itemGap;

  /// Gaps the rail keeps from the markers, one per end.
  ///
  /// The rail is a separator, not a connector: it never touches a marker. A
  /// side left null takes the gap — a wide one along a horizontal
  /// run, a narrow one down a vertical one, where the markers already sit close
  /// together — so `RailInsets.horizontal(left: 0)` changes that end alone.
  ///
  /// ```dart
  /// Steps(items: items, token: const StepsToken(railInset: RailInsets.all(8)))
  /// ```
  final RailInsets? railInset;

  /// Cap on a step's text column (`descriptionMaxWidth`). Null lets it fill.
  final double? contentMaxWidth;

  /// Padding inside a [StepsType.panel] panel.
  final EdgeInsets? panelPadding;

  /// Corner radius of the panel group.
  final double? panelRadius;

  /// How far a panel's arrow points into its neighbour.
  final double? panelArrowWidth;

  /// The narrowest a panel may be squeezed to, whatever its text. A strip
  /// that cannot fit its panels at this width scrolls instead of crushing
  /// them. Null leaves the panels to their own text.
  final double? panelMinWidth;

  /// A [StepsType.navigation] block's width outright, in place of the width
  /// its text asks for.
  final double? itemWidth;

  /// A [StepsType.navigation] block's height outright.
  final double? itemHeight;

  /// A panel's width outright, in place of the width its text asks for.
  final double? panelWidth;

  /// A panel's height outright, in place of the height its text asks for.
  final double? panelHeight;

  /// How long the rail between two steps is drawn.
  ///
  /// Null lets it take whatever the text leaves — the steps share the width
  /// (or the height, down a vertical run) and the rail fills the gap. Give it
  /// a length and the rails become fixed instead: every step is as wide as its
  /// own text, and the run scrolls when the sum outgrows the room.
  ///
  /// This is the line itself, not the gaps at its ends — those are
  /// [StepsToken.railInset].
  final double? railLength;

  /// The shortest a rail may be drawn before the layout stops giving its room
  /// to the text. Under this a line reads as a dash rather than a connection.
  final double? railMinLength;

  /// The narrowest a step may be squeezed to in a horizontal run before the
  /// run scrolls rather than shredding its titles. Null derives it from the
  /// marker, the gaps and five characters' worth of title — see
  /// [StepsToken.panelMinWidth] for the panel run's own floor.
  final double? itemMinWidth;

  /// Colour of the arrow between navigation and panel steps (`navArrowColor`).
  final Color? arrowColor;

  _ResolvedStepsToken _resolve(Token t, ControlSize size) {
    final scale = _Scale.of(size);
    final small = scale == _Scale.small;
    // A bare number *is* the marker's diameter; a preset names one.
    final marker = switch (size) {
      SoftSize.small => iconSizeSM ?? 24,
      SoftSize.middle => iconSize ?? 32,
      SoftSize.large => iconSizeLG ?? 40,
      ExplicitSquareSize(:final dimension) => dimension,
      ExplicitSize(:final height) => height,
    };
    return _ResolvedStepsToken(
      iconSize: marker,
      dotSize: dotSize ?? 8,
      dotCurrentSize: dotCurrentSize ?? 10,
      railThickness: railThickness ?? t.lineWidth,
      itemGap: itemGap ?? t.sizeSM,
      railInset: railInset ?? const RailInsets(),
      railInsetHorizontal: t.size,
      railInsetVertical: t.sizeXXS * 1.5,
      contentMaxWidth: contentMaxWidth,
      // The kit tightens a small panel run: `paddingSM` becomes
      // `paddingXS`, and the corners take the small radius.
      panelPadding: panelPadding ?? EdgeInsets.all(scale.padding(t)),
      panelRadius: panelRadius ?? (small ? t.borderRadiusSM : t.borderRadius),
      panelArrowWidth: panelArrowWidth ?? (small ? 12.0 : 16.0),
      panelMinWidth: panelMinWidth ?? (small ? 120.0 : 160.0),
      panelWidth: panelWidth,
      panelHeight: panelHeight,
      itemMinWidth: itemMinWidth,
      itemWidth: itemWidth,
      itemHeight: itemHeight,
      railLength: railLength,
      railMinLength: railMinLength ?? t.size * 2,
      arrowColor: arrowColor ?? t.colorTextQuaternary,
      scale: scale,
    );
  }
}

@immutable
class _ResolvedStepsToken {
  const _ResolvedStepsToken({
    required this.iconSize,
    required this.dotSize,
    required this.dotCurrentSize,
    required this.railThickness,
    required this.itemGap,
    required this.railInset,
    required this.railInsetHorizontal,
    required this.railInsetVertical,
    required this.contentMaxWidth,
    required this.panelPadding,
    required this.panelRadius,
    required this.panelArrowWidth,
    required this.panelMinWidth,
    required this.panelWidth,
    required this.panelHeight,
    required this.itemMinWidth,
    required this.itemWidth,
    required this.itemHeight,
    required this.railLength,
    required this.railMinLength,
    required this.arrowColor,
    required this.scale,
  });

  final double iconSize;
  final double dotSize;
  final double dotCurrentSize;
  final double railThickness;
  final double itemGap;

  /// What the caller asked for; a null side falls back to the two below.
  final RailInsets railInset;

  /// the gaps, per axis, for the sides the caller left alone.
  final double railInsetHorizontal;
  final double railInsetVertical;

  /// The gap at the end a rail starts from.
  double leadingInset(Axis axis) => railInset.leading(
        axis,
        axis == Axis.horizontal ? railInsetHorizontal : railInsetVertical,
      );

  /// The gap at the end it runs towards.
  double trailingInset(Axis axis) => railInset.trailing(
        axis,
        axis == Axis.horizontal ? railInsetHorizontal : railInsetVertical,
      );
  final double? contentMaxWidth;
  final EdgeInsets panelPadding;
  final double panelRadius;
  final double panelArrowWidth;
  final double panelMinWidth;
  final double? panelWidth;
  final double? panelHeight;
  final double? itemMinWidth;
  final double? itemWidth;
  final double? itemHeight;
  final double? railLength;
  final double railMinLength;
  final Color arrowColor;

  /// Which type scale the run's `size` landed on.
  final _Scale scale;
}

/// What a run actually draws: the steps as given, or the folded list `maxCount`
/// leaves behind, with an ellipsis standing in for each hidden stretch.
@immutable
class _Shown {
  const _Shown({
    required this.items,
    required this.origins,
    required this.current,
  });

  /// The steps as drawn, ellipsis markers included.
  final List<StepItem> items;

  /// Where each drawn step came from in the caller's list; -1 for an ellipsis.
  final List<int> origins;

  /// The current step's place in [items].
  final int current;

  /// Folds [items] down to [maxCount], following the rules.
  static _Shown of(List<StepItem> items, int current, int? maxCount) {
    // the kit ignores a maxCount below three: first, current and last already
    // take three slots, and a run that cannot show those says nothing.
    if (maxCount == null || maxCount < 3 || items.length <= maxCount) {
      return _Shown(
        items: items,
        origins: [for (var i = 0; i < items.length; i++) i],
        current: current.clamp(0, items.isEmpty ? 0 : items.length - 1),
      );
    }

    final kept = _kept(items.length, current, maxCount);

    final shownItems = <StepItem>[];
    final origins = <int>[];
    for (var i = 0; i < kept.length; i++) {
      final index = kept[i];
      if (index != null) {
        shownItems.add(items[index]);
        origins.add(index);
        continue;
      }
      // The gap between the two steps either side of it.
      final from = kept[i - 1]! + 1;
      final to = kept[i + 1]!;
      shownItems.add(_ellipsis(items, from, to, current));
      origins.add(-1);
    }

    final at = origins.indexOf(current.clamp(0, items.length - 1));
    return _Shown(
      items: shownItems,
      origins: origins,
      current: at >= 0 ? at : current,
    );
  }

  /// Which real steps survive the fold, with a null wherever the ones between
  /// two survivors were dropped.
  ///
  /// The first, the last and the one in play are always kept. The slots left
  /// over go to their neighbours, taken in the order — one step
  /// either side of the current, then one in from each end, then the same
  /// again a step further out.
  static List<int?> _kept(int total, int current, int maxCount) {
    final safeCurrent = current.clamp(0, total - 1);
    var bestIndexes = <int>{0, safeCurrent, total - 1};

    List<int?> buildOut(Set<int> idxs) {
      final sorted = idxs.toList()..sort();
      final out = <int?>[];
      for (var i = 0; i < sorted.length; i++) {
        if (i > 0 && sorted[i] - sorted[i - 1] > 1) out.add(null);
        out.add(sorted[i]);
      }
      return out;
    }

    for (var distance = 1; distance < total; distance++) {
      for (final candidate in [
        safeCurrent - distance,
        safeCurrent + distance,
        distance,
        total - 1 - distance,
      ]) {
        if (candidate >= 0 &&
            candidate < total &&
            !bestIndexes.contains(candidate)) {
          final testSet = Set<int>.from(bestIndexes)..add(candidate);
          if (buildOut(testSet).length <= maxCount) {
            bestIndexes = testSet;
          }
        }
      }
    }

    return buildOut(bestIndexes);
  }

  /// The marker standing in for the steps in `[from, to)`.
  ///
  /// It carries the hidden stretch's own state, so the run still reads true:
  /// red if anything in there failed, otherwise finished when the whole
  /// stretch is behind the current step.
  static StepItem _ellipsis(
    List<StepItem> items,
    int from,
    int to,
    int current,
  ) {
    final hidden = items.sublist(from, to);
    final failed = hidden.any((item) => item.status == StepStatus.error);
    return StepItem(
      icon: const _EllipsisGlyph(),
      status: failed
          ? StepStatus.error
          : (to - 1 < current ? StepStatus.finish : StepStatus.wait),
      disabled: true,
    );
  }
}

/// Three dots, in whatever colour the marker gives its glyphs.
class _EllipsisGlyph extends StatelessWidget {
  const _EllipsisGlyph();

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 16;
    return CustomPaint(
      size: Size(size, size),
      painter: _EllipsisPainter(theme.color ?? const Color(0xFF000000)),
    );
  }
}

class _EllipsisPainter extends CustomPainter {
  const _EllipsisPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Three dots that read as three dots: wide enough apart to tell apart,
    // fat enough not to vanish beside a marker.
    final radius = size.width / 10;
    final paint = Paint()..color = color;
    final centre = size.height / 2;
    final step = size.width / 3.2;
    for (var i = -1; i <= 1; i++) {
      canvas.drawCircle(
        Offset(size.width / 2 + i * step, centre),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EllipsisPainter old) => old.color != color;
}

/// Defaults for every [Steps] under a `ConfigProvider`.
///
/// House style for step runs.
@immutable
class StepsDefaults {
  /// Creates a [StepsDefaults].
  const StepsDefaults(
      {this.orientation,
      this.type,
      this.variant,
      this.responsive,
      this.overflow});

  /// Which way the run goes.
  final StepsOrientation? orientation;

  /// Which shape the markers take.
  final StepsType? type;

  /// How the markers are filled.
  final StepsVariant? variant;

  /// Whether a narrow screen turns the run upright.
  final bool? responsive;

  /// What happens when the run will not fit.
  final StepsOverflow? overflow;
}

/// A progress indicator for a task with stages.
///
/// ```dart
/// Steps(
///   current: _step,
///   onChange: (index) => setState(() => _step = index),
///   items: const [
///     StepItem(title: Text('Cart'), content: Text('3 items')),
///     StepItem(title: Text('Payment')),
///     StepItem(title: Text('Done')),
///   ],
/// )
/// ```
///
/// Where [Timeline] records events that happened, this measures a journey: the
/// rail behind the current step is drawn in the accent, ahead of it in the
/// split colour, and each marker takes its look from its status.
///
/// The step in play comes from [current] (controlled), [defaultCurrent]
/// (uncontrolled) or a [StepsController]. [items] can override any step's
/// status of their own.
class Steps extends StatefulWidget {
  /// Creates a [Steps].
  const Steps({
    super.key,
    required this.items,
    this.current,
    this.defaultCurrent = 0,
    this.controller,
    this.onChange,
    this.initial = 0,
    this.orientation,
    this.type,
    this.variant,
    this.size,
    this.status = StepStatus.process,
    this.titlePlacement,
    this.percent,
    this.progress,
    this.responsive,
    this.maxCount,
    this.overflow,
    this.token,
  }) : assert(
          percent == null || (percent >= 0 && percent <= 1),
          'percent is a fraction between 0 and 1',
        );

  /// The steps, in order.
  final List<StepItem> items;

  /// The step being worked on, counting from zero. Null leaves the widget to
  /// manage its own, from [defaultCurrent] or a [controller].
  final int? current;

  /// Starting step when [current] and [controller] are both absent.
  final int defaultCurrent;

  /// Drives the current step from outside.
  final StepsController? controller;

  /// Called with the step a tap landed on. Null makes the steps inert.
  final ValueChanged<int>? onChange;

  /// Number the first step from here.
  final int initial;

  /// Which way the steps run.
  final StepsOrientation? orientation;

  /// How the steps are drawn.
  final StepsType? type;

  /// Filled or outlined markers.
  final StepsVariant? variant;

  /// How big the run is drawn.
  ///
  /// A [SoftSize] picks a preset — `small` is the small run,
  /// `middle` its default, `large` the kit's third step. A number sets the
  /// marker's diameter outright (`ControlSize.fixed(48)`), and the type scale
  /// follows the marker it sits beside.
  final ControlSize? size;

  /// Status of the current step — set [StepStatus.error] to stop the run here.
  final StepStatus status;

  /// Title beside the marker or under it. Null picks per type: under it for
  /// [StepsType.dot], beside it otherwise.
  final StepTitlePlacement? titlePlacement;

  /// Progress of the current step, 0..1, drawn as a ring around its marker.
  /// Only meaningful for [StepsType.standard].
  final double? percent;

  /// The ring itself, when the default one is not what you want: any
  /// [Progress] serves as a template — its type, colours, stroke and gap are
  /// kept, while [percent] (when given) and the marker are filled in.
  ///
  /// ```dart
  /// Steps(
  ///   current: 1,
  ///   percent: 0.6,
  ///   progress: Progress(
  ///     percent: 0,
  ///     type: ProgressType.dashboard,
  ///     color: Colors.deepPurple,
  ///   ),
  ///   items: items,
  /// )
  /// ```
  final Progress? progress;

  /// Falls back to a vertical run when the space is too narrow for a
  /// horizontal one.
  final bool? responsive;

  /// The most steps to show at once.
  ///
  /// A longer run is folded: the first step, the last, the one in play and its
  /// neighbours stay, and each stretch of hidden steps becomes a single
  /// ellipsis marker. Below three it is ignored, since first,
  /// current and last already take three slots.
  ///
  /// The steps you are given back never change: [onChange] and the controller
  /// speak in the indexes of [items], not of what is on screen.
  final int? maxCount;

  /// What to do when the steps will not fit the room they are given.
  ///
  /// [StepsOverflow.scroll] keeps them all and scrolls. [StepsOverflow.fold]
  /// works [maxCount] out from the room instead, so the run always fits and
  /// never scrolls — an explicit [maxCount] still wins.
  final StepsOverflow? overflow;

  /// Per-instance token overrides.
  final StepsToken? token;

  /// Below this width a responsive horizontal run turns vertical.
  static const double responsiveBreakpoint = 532;

  @override
  State<Steps> createState() => _StepsState();
}

class _StepsState extends State<Steps> {
  /// The defaults set for this component in the subtree, if any.
  StepsDefaults? get _defaults =>
      ConfigProvider.defaultsOf<StepsDefaults>(context);

  /// This widget's word, then the subtree's, then the kit's.
  StepsOrientation get _orientation =>
      widget.orientation ??
      _defaults?.orientation ??
      StepsOrientation.horizontal;

  /// This widget's word, then the subtree's, then the kit's.
  StepsType get _type => widget.type ?? _defaults?.type ?? StepsType.standard;

  /// This widget's word, then the subtree's, then the kit's.
  StepsVariant get _variant =>
      widget.variant ?? _defaults?.variant ?? StepsVariant.filled;

  /// This widget's word, then the subtree's, then the kit's.
  bool get _responsive => widget.responsive ?? _defaults?.responsive ?? true;

  /// This widget's word, then the subtree's, then the kit's.
  StepsOverflow get _overflow =>
      widget.overflow ?? _defaults?.overflow ?? StepsOverflow.scroll;

  /// The size in force: this widget's own, else the one set for the
  /// subtree, else the standard preset.
  ControlSize get _size =>
      widget.size ?? ConfigProvider.componentSizeOf(context) ?? SoftSize.middle;

  late int _uncontrolled = widget.defaultCurrent;

  @override
  void initState() {
    super.initState();
    widget.controller
      ?..addListener(_onController)
      .._length = widget.items.length;
  }

  @override
  void didUpdateWidget(Steps old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onController);
      widget.controller?.addListener(_onController);
    }
    widget.controller?._length = widget.items.length;
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  /// Controlled value wins, then the controller, then our own. Always an index
  /// into [Steps.items] — what the caller gave us, not what is on screen.
  int get _current =>
      widget.current ?? widget.controller?.current ?? _uncontrolled;

  /// What is actually drawn: every step, or the folded run under `maxCount`.
  late _Shown _shown;

  /// The steps as drawn, ellipsis markers and all.
  List<StepItem> get items => _shown.items;

  /// The number a step wears: its own place in the caller's list, not its
  /// place on screen — a folded run that numbered by position would put a 4 in
  /// the circle above a title reading "Step 9".
  int numberOf(int index) {
    final origin = _shown.origins[index];
    return (origin < 0 ? index : origin) + widget.initial + 1;
  }

  /// Where the current step sits in that list.
  int get _shownCurrent => _shown.current;

  bool get _interactive => widget.onChange != null || widget.controller != null;

  void _select(int index) {
    final origin = _shown.origins[index];
    // An ellipsis stands for steps rather than being one.
    if (origin < 0 || widget.items[origin].disabled) return;
    widget.controller?.goTo(origin);
    if (widget.current == null && widget.controller == null) {
      setState(() => _uncontrolled = origin);
    }
    widget.onChange?.call(origin);
  }

  /// A step's status: its own if it named one, otherwise where it sits
  /// relative to the current step.
  StepStatus _statusOf(int index) {
    final own = items[index].status;
    if (own != null) return own;
    if (index < _shownCurrent) return StepStatus.finish;
    if (index == _shownCurrent) return widget.status;
    return StepStatus.wait;
  }

  /// How many steps a run of this size can hold before they stop reading as
  /// steps — the cap [StepsOverflow.fold] folds to.
  ///
  /// Derived from the room and the least a step may take, so it answers the
  /// question actually being asked: how many fit. Never below three, which is
  /// what first, current and last need.
  int? _autoCap(
    BoxConstraints constraints,
    Token t,
    _ResolvedStepsToken r,
    StepsOrientation orientation,
  ) {
    if (_overflow != StepsOverflow.fold) return null;

    final marker = _type == StepsType.dot ? r.dotCurrentSize : r.iconSize;
    final text = _headerFloor(t, widget.items);

    if (orientation == StepsOrientation.horizontal) {
      if (!constraints.hasBoundedWidth) return null;
      final floor = switch (_type) {
        StepsType.panel => r.panelWidth ?? r.panelMinWidth,
        StepsType.navigation => r.iconSize + r.itemGap + text + t.sizeXS * 2,
        // A rail long enough to read as one, plus its gaps.
        _ => marker +
            r.itemGap +
            text +
            r.railMinLength +
            r.leadingInset(Axis.horizontal) +
            r.trailingInset(Axis.horizontal),
      };
      return math.max(3, constraints.maxWidth ~/ floor);
    }

    // Down the page a step is at least its marker and the gap under it; the
    // text usually makes it taller, so this errs on showing more rather than
    // folding a run that would have fitted.
    if (!constraints.hasBoundedHeight) return null;
    final floor =
        math.max(marker, scaleOf(r).title(t) * t.lineHeight) + r.itemGap * 2;
    return math.max(3, constraints.maxHeight ~/ floor);
  }

  _Scale scaleOf(_ResolvedStepsToken r) =>
      _type == StepsType.inline ? _Scale.small : r.scale;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<StepsToken>(context) ??
            const StepsToken())
        ._resolve(t, _size);

    final palette = _Palette(t, _variant);

    Widget build(StepsOrientation orientation) => switch (_type) {
          StepsType.panel => _PanelRun(
              state: this,
              t: t,
              r: r,
              palette: palette,
              orientation: orientation,
            ),
          StepsType.navigation => _NavigationRun(
              state: this,
              t: t,
              r: r,
              palette: palette,
              orientation: orientation,
            ),

          // `inline` is the dot run in miniature: same rails, smaller dots,
          // muted one-line titles and no content — The kit hides it.
          _ => _RailRun(
              state: this,
              t: t,
              r: r,
              palette: palette,
              orientation: orientation,
              scale: _type == StepsType.inline ? _Scale.small : r.scale,
              direction: Directionality.of(context),
            ),
        };

    // The fold has to be worked out where the room is known, so the whole run
    // is built inside a LayoutBuilder — including the runs that never turn
    // vertical, which still need the width to count what fits.
    return LayoutBuilder(
      builder: (context, constraints) {
        final stands = _responsive &&
            _orientation == StepsOrientation.horizontal &&
            _type != StepsType.inline &&
            _type != StepsType.panel &&
            _type != StepsType.navigation &&
            constraints.maxWidth < Steps.responsiveBreakpoint;

        final orientation = stands ? StepsOrientation.vertical : _orientation;

        _shown = _Shown.of(
          widget.items,
          _current,
          widget.maxCount ?? _autoCap(constraints, t, r, orientation),
        );

        return build(orientation);
      },
    );
  }
}

/// The colours a status takes, in one place so every type agrees.
class _Palette {
  _Palette(this.t, this.variant);

  final Token t;
  final StepsVariant variant;

  bool get _outlined => variant == StepsVariant.outlined;

  /// Lays a fill on the surface instead of leaving it translucent.
  ///
  /// The neutral fills are a few per cent of black. Animating one of those to
  /// an opaque tint runs the midpoint through a half-transparent dark grey,
  /// which reads as a flash; composited first, both ends are light and the
  /// change is a fade between two tints.
  Color opaque(Color fill) => Color.alphaBlend(fill, t.colorBgContainer);

  Color markerFill(StepStatus s) => switch (s) {
        StepStatus.wait =>
          _outlined ? const Color(0x00000000) : opaque(t.colorFillQuaternary),
        StepStatus.process =>
          _outlined ? const Color(0x00000000) : t.primary.base,
        StepStatus.finish => _outlined ? const Color(0x00000000) : t.primary.bg,
        StepStatus.error => _outlined ? const Color(0x00000000) : t.error.base,
      };

  Color? markerBorder(StepStatus s) => !_outlined
      ? null
      : switch (s) {
          StepStatus.wait => t.colorBorder,
          StepStatus.process => t.primary.base,
          StepStatus.finish => t.primary.base,
          StepStatus.error => t.error.base,
        };

  /// Colour of the number, tick or cross inside the marker.
  Color markerInk(StepStatus s) => switch (s) {
        StepStatus.wait => t.colorTextTertiary,
        StepStatus.process =>
          _outlined ? t.primary.base : const Color(0xFFFFFFFF),
        StepStatus.finish => t.primary.base,
        StepStatus.error => _outlined ? t.error.base : const Color(0xFFFFFFFF),
      };

  Color dot(StepStatus s) => switch (s) {
        StepStatus.wait => t.colorSplit,
        StepStatus.process || StepStatus.finish => t.primary.base,
        StepStatus.error => t.error.base,
      };

  /// Hover fill of a marker. The kit lifts a filled marker to the accent's
  /// hover tint — an error one to its own — and leaves an outlined one clear.
  Color markerFillHover(StepStatus s) => _outlined
      ? const Color(0x00000000)
      : switch (s) {
          StepStatus.error => opaque(t.error.bgHover),
          _ => opaque(t.primary.bgHover),
        };

  Color? markerBorderHover(StepStatus s) => !_outlined
      ? null
      : switch (s) {
          StepStatus.error => t.error.hover,
          _ => t.primary.hover,
        };

  Color markerInkHover(StepStatus s) => switch (s) {
        StepStatus.error => _outlined ? t.error.hover : t.error.base,
        _ => _outlined ? t.primary.hover : t.primary.base,
      };

  /// Hover colour of a step's title and content — the error status keeps to
  /// its own family rather than turning blue.
  Color textHover(StepStatus s) =>
      s == StepStatus.error ? t.error.hover : t.primary.hover;

  Color title(StepStatus s) => switch (s) {
        StepStatus.wait => t.colorTextTertiary,
        StepStatus.process || StepStatus.finish => t.colorText,
        StepStatus.error => t.error.base,
      };

  Color content(StepStatus s) => switch (s) {
        StepStatus.wait => t.colorTextTertiary,
        StepStatus.process || StepStatus.finish => t.colorText,
        StepStatus.error => t.error.base,
      };

  /// The rail leading *into* a step: travelled once the step is done.
  Color rail(StepStatus s) =>
      s == StepStatus.finish ? t.primary.base : t.colorSplit;
}

/// The marker: a numbered or icon circle, or a dot.
class _Marker extends StatelessWidget {
  const _Marker({
    required this.t,
    required this.r,
    required this.palette,
    required this.status,
    required this.item,
    required this.number,
    required this.dot,
    this.percent,
    this.progress,
    this.hovered = false,
  });

  final Token t;
  final _ResolvedStepsToken r;
  final _Palette palette;
  final StepStatus status;
  final StepItem item;
  final int number;
  final bool dot;
  final double? percent;

  /// Template for the ring; see [Steps.progress].
  final Progress? progress;

  /// Whether the pointer is over the step. The control answers it on the marker
  /// too — a filled one lifts to the hover tint, an outlined one takes the
  /// hover outline.
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    if (dot) {
      final size = status == StepStatus.process ? r.dotCurrentSize : r.dotSize;

      // An icon is not a dot: squeezed into a dot's slot it comes out as a
      // smudge on the rail — an ellipsis marker especially, which is three
      // dots of its own. It gets a slot it can be read in.
      if (item.icon != null) {
        final box = r.dotCurrentSize * 2.2;
        return SizedBox(
          width: box,
          height: r.dotCurrentSize,
          child: Center(
            child: IconTheme.merge(
              data: IconThemeData(
                color: hovered
                    ? palette.markerInkHover(status)
                    : palette.dot(status),
                size: r.dotCurrentSize * 1.6,
              ),
              child: item.icon!,
            ),
          ),
        );
      }

      // The slot is the dot's own size, not the current step's: a wider slot
      // would centre a smaller dot inside it and leave the rails a pixel short
      // of every marker but one.
      return SizedBox(
        width: size,
        height: r.dotCurrentSize,
        child: Center(
          child: item.icon ??
              AnimatedContainer(
                duration: t.motionDurationMid,
                curve: t.motionEaseInOut,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: hovered
                      ? palette.markerInkHover(status)
                      : palette.dot(status),
                  shape: BoxShape.circle,
                ),
              ),
        ),
      );
    }

    final ink =
        hovered ? palette.markerInkHover(status) : palette.markerInk(status);
    final border = hovered
        ? palette.markerBorderHover(status)
        : palette.markerBorder(status);
    final fill =
        hovered ? palette.markerFillHover(status) : palette.markerFill(status);

    // The glyph's colour eases with the circle behind it; the kit transitions
    // both rather than snapping.
    Widget easeInk(Widget Function(Color ink) build) => TweenAnimationBuilder(
          tween: ColorTween(end: ink),
          duration: t.motionDurationMid,
          curve: t.motionEaseInOut,
          builder: (context, value, _) => build(value ?? ink),
        );

    Widget glyph;
    if (item.icon != null) {
      glyph = IconTheme.merge(
        data: IconThemeData(color: ink, size: r.iconSize * 0.55),
        child: item.icon!,
      );
    } else if (status == StepStatus.finish) {
      glyph = easeInk(
        (c) => CustomPaint(
          size: Size.square(r.iconSize * 0.45),
          painter: CheckPainter(color: c),
        ),
      );
    } else if (status == StepStatus.error) {
      glyph = easeInk(
        (c) => CustomPaint(
          size: Size.square(r.iconSize * 0.4),
          painter: CrossPainter(c),
        ),
      );
    } else {
      glyph = easeInk(
        (c) => Text(
          context.seedLocale.figures('$number'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: c,
            fontSize: r.iconSize * 0.44,
            fontFamily: t.fontFamily,
            fontFamilyFallback: t.fontFamilyFallback,
            // A line box exactly as tall as the glyph, with what is left over
            // split evenly above and below — otherwise the font's own metrics
            // push the digit off the circle's centre.
            height: 1,
            leadingDistribution: TextLeadingDistribution.even,
            decoration: TextDecoration.none,
          ),
        ),
      );
    }

    final marker = AnimatedContainer(
      duration: t.motionDurationMid,
      curve: t.motionEaseInOut,
      width: r.iconSize,
      height: r.iconSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: border == null
            ? null
            : Border.all(color: border, width: t.lineWidth),
      ),
      child: glyph,
    );

    // `percent` turns the current marker into a progress ring.
    // The ring is the kit's own Progress, so everything it can do — a
    // dashboard gap, a gradient, steps — is available here through
    // [Steps.progress], with the marker riding in the middle as its child.
    final value = percent ?? progress?.percent;
    if (value == null || status != StepStatus.process) return marker;
    // Checked here rather than in the constructor: reading a field off the
    // template would cost every call site its const.
    assert(
      progress == null || progress!.type != ProgressType.line,
      'the ring goes round a marker: use a circle or a dashboard',
    );
    final ringBox = r.iconSize + stepsRingPadding;
    final template = progress ??
        Progress(
          percent: value,
          type: ProgressType.circle,
          showInfo: false,
          color: t.primary.base,
          trailColor: t.colorSplit,
        );
    return template.copyWith(
      percent: value,
      // A line has no middle to sit in and no width to take here; the assert
      // above says so in debug, and this keeps a release build standing.
      type: template.type == ProgressType.line
          ? ProgressType.circle
          : template.type,
      // The template's own choices win; these only fill the gaps.
      size: template.size ?? ControlSize.fixed(ringBox),
      strokeWidth: template.strokeWidth ?? 3,
      child: marker,
    );
  }
}

/// Which part of a step's text to build.
///
/// The kit splits a step into a *header* — the title and subtitle, on the
/// marker's line — and the content below it. A horizontal run needs them apart:
/// the rail starts after the header, and the content flows on underneath
/// without moving it.
enum _StepTextPart { all, header, content }

/// The text column of a step: title, subtitle, content.
class _StepText extends StatelessWidget {
  const _StepText({
    required this.t,
    required this.r,
    required this.palette,
    required this.item,
    required this.status,
    required this.scale,
    required this.centred,
    this.inline = false,
    this.hovered = false,
    this.colorOverride,
    this.part = _StepTextPart.all,
  });

  final Token t;
  final _ResolvedStepsToken r;
  final _Palette palette;
  final StepItem item;
  final StepStatus status;
  final _Scale scale;
  final bool centred;

  /// Inline steps show a muted one-line title and no content at all.
  final bool inline;

  /// Paints every line in one colour — a solid panel needs its text to read
  /// against the fill, whatever the status would otherwise say.
  final Color? colorOverride;

  /// Which part to build.
  final _StepTextPart part;

  /// Whether the pointer is over the step. The control answers a hover on a
  /// clickable step by recolouring its title and content — the marker keeps
  /// its own colours, which carry the status.
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final titleSize = scale.title(t);
    final titleColour = colorOverride ??
        (hovered
            ? t.primary.hover
            : (inline ? t.colorTextSecondary : palette.title(status)));
    final contentColour =
        colorOverride ?? (hovered ? t.primary.hover : palette.content(status));

    final column = Column(
      crossAxisAlignment:
          centred ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (part != _StepTextPart.content &&
            (item.title != null || item.subTitle != null))
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (item.title != null)
                Flexible(
                  // The kit transitions a step's text rather than snapping
                  // it, so a hover reads as a lift and not a flicker.
                  child: AnimatedDefaultTextStyle(
                    duration: t.motionDurationSlow,
                    curve: t.motionEaseInOut,
                    style: TextStyle(
                      color: titleColour,
                      fontSize: titleSize,
                      fontFamily: t.fontFamily,
                      fontFamilyFallback: t.fontFamilyFallback,
                      height: t.lineHeight,
                      leadingDistribution: TextLeadingDistribution.even,
                      decoration: TextDecoration.none,
                    ),
                    child: item.title!,
                  ),
                ),
              if (item.subTitle != null) ...[
                SizedBox(width: t.sizeXS),
                AnimatedDefaultTextStyle(
                  duration: t.motionDurationSlow,
                  curve: t.motionEaseInOut,
                  style: TextStyle(
                    color: colorOverride ?? t.colorTextTertiary,
                    fontSize: t.fontSize,
                    fontFamily: t.fontFamily,
                    fontFamilyFallback: t.fontFamilyFallback,
                    height: t.lineHeight,
                    leadingDistribution: TextLeadingDistribution.even,
                    decoration: TextDecoration.none,
                  ),
                  child: item.subTitle!,
                ),
              ],
            ],
          ),
        if (item.content != null && !inline && part != _StepTextPart.header)
          Padding(
            padding: EdgeInsets.only(
              top: part == _StepTextPart.content ? 0 : t.sizeXXS,
            ),
            child: AnimatedDefaultTextStyle(
              duration: t.motionDurationSlow,
              curve: t.motionEaseInOut,
              style: TextStyle(
                color: contentColour,
                fontSize: scale.content(t),
                fontFamily: t.fontFamily,
                fontFamilyFallback: t.fontFamilyFallback,
                height: t.lineHeight,
                leadingDistribution: TextLeadingDistribution.even,
                decoration: TextDecoration.none,
              ),
              child: item.content!,
            ),
          ),
      ],
    );

    final maxWidth = r.contentMaxWidth;
    return maxWidth == null
        ? column
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: column,
          );
  }
}

/// Makes a step tappable, with hover feedback, when the run is interactive.
class _Tappable extends StatefulWidget {
  const _Tappable({
    required this.enabled,
    required this.onTap,
    required this.builder,
    this.onHoverChanged,
  });

  final bool enabled;
  final VoidCallback onTap;
  final Widget Function(bool hovered) builder;

  /// Told when the pointer arrives and leaves, for a parent that paints the
  /// hover itself.
  final ValueChanged<bool>? onHoverChanged;

  @override
  State<_Tappable> createState() => _TappableState();
}

class _TappableState extends State<_Tappable> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.builder(false);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        widget.onHoverChanged?.call(true);
      },
      onExit: (_) {
        setState(() => _hovered = false);
        widget.onHoverChanged?.call(false);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(_hovered),
      ),
    );
  }
}

/// The rail layouts: [StepsType.standard] and [StepsType.dot].
///
/// One marker per step with the rail running between them — down the side when
/// vertical, across the top when horizontal.
/// Room a step's header needs before its text starts breaking badly: five
/// characters' worth of title, and as much again for a subtitle where any step
/// carries one. A subtitle cannot shrink, so a floor that ignored it would let
/// it push the title clean out of the row.
double _headerFloor(Token t, List<StepItem> items) {
  final characters = t.fontSize * 5;
  final subtitled = items.any((i) => i.subTitle != null);
  return characters + (subtitled ? characters + t.sizeXS : 0);
}

class _RailRun extends StatelessWidget {
  const _RailRun({
    required this.state,
    required this.t,
    required this.r,
    required this.palette,
    required this.orientation,
    required this.scale,
    required this.direction,
  });

  final _StepsState state;
  final Token t;
  final _ResolvedStepsToken r;
  final _Palette palette;
  final StepsOrientation orientation;
  final _Scale scale;

  /// Which way the run reads. Carried rather than looked up, because the parts
  /// that need it are built outside any build method of their own.
  final TextDirection direction;

  bool get _inline => state.widget.type == StepsType.inline;

  bool get _dot => state.widget.type == StepsType.dot || _inline;

  /// Under the marker for dots, beside it otherwise — unless the caller said.
  /// Where a step's text sits. The caller decides, or the type does — and
  /// where neither has, a horizontal run decides by the room it has: text
  /// beside the marker while it fits, stacked under it when it does not.
  StepTitlePlacement _placementOf({bool stacked = false}) =>
      state.widget.titlePlacement ??
      ((_dot || stacked)
          ? StepTitlePlacement.vertical
          : StepTitlePlacement.horizontal);

  /// Whether a run of this width has to stack its text under the markers.
  /// Decided once for the whole run: half the steps stacked and half beside
  /// would read as two different components.
  bool _stacksAt(double maxWidth) {
    if (state.widget.titlePlacement != null || _dot || _inline) return false;
    final beside =
        _markerExtent + r.itemGap + _headerFloor(t, state.items) + _minRail;
    return maxWidth / state.items.length < beside;
  }

  /// What a stacked step needs: its text has the full step width, but the
  /// header row still wants the marker and a readable rail either side.
  double get _stackedFloor =>
      r.itemMinWidth ??
      math.max(_headerFloor(t, state.items), _markerExtent + _minRail);

  /// Whether the current marker wears a progress ring — which needs room the
  /// bare marker does not. Reserved for every step of the run, not just the
  /// one wearing it, so the rails stay on one axis.
  bool get _ringed =>
      state.widget.percent != null || state.widget.progress != null;

  double get _markerExtent => _dot
      ? r.dotCurrentSize
      : (_ringed ? r.iconSize + stepsRingPadding : r.iconSize);

  /// Inline steps sit shoulder to shoulder, so their rails run edge to edge —
  /// The kit zeroes the gap for exactly this type.
  /// The gap where a horizontal rail starts, and where it ends. Inline steps
  /// sit shoulder to shoulder, so The kit zeroes both for that type.
  double get _railGapLeading => _inline ? 0 : r.leadingInset(Axis.horizontal);
  double get _railGapTrailing => _inline ? 0 : r.trailingInset(Axis.horizontal);

  /// The slot a rail is drawn in.
  ///
  /// Left to itself the rail is the give in the layout — the steps take what
  /// they need and it fills the rest. A token that names a `railLength` makes
  /// it the *shortest* the line may be: the step is then sized so the rail is
  /// at least that long, and it still stretches to reach the next marker when
  /// the step's own text is wider or taller. A rail that stops short of a
  /// marker is a broken rail, whatever the token says.
  ///
  /// [gaps] is the inset the painter keeps at the ends; the length is the line
  /// you see, so the slot carries the gaps on top of it. A run between two
  /// dots is drawn as two halves, one per step, so each takes half.
  Widget _railSlot({
    required Axis axis,
    required Widget child,
    required double gaps,
    bool half = false,
  }) {
    final fixed = _fixedRail;
    if (fixed == null) {
      // Still the give in the layout, but never squeezed below the gaps it
      // must keep plus the least line that still reads as one. Left to take
      // only the leftover, a rail beside a short step had its whole slot eaten
      // by the insets and vanished — every inset past a small one looked the
      // same because there was nothing left to look at. The SizedBox is what
      // the intrinsic pass measures, so the step grows to fit its own rail.
      final floor = (gaps + r.railMinLength).clamp(0.0, double.infinity);
      return Expanded(
        child: SizedBox(
          width: axis == Axis.horizontal ? floor : null,
          height: axis == Axis.vertical ? floor : null,
          child: child,
        ),
      );
    }
    final length = (half ? fixed / 2 : fixed) + gaps;
    // Expanded so it can still grow; the SizedBox is what the intrinsic pass
    // measures, which is how the step comes out wide enough in the first place.
    return Expanded(
      child: SizedBox(
        width: axis == Axis.horizontal ? length : null,
        height: axis == Axis.vertical ? length : null,
        child: child,
      ),
    );
  }

  /// A fixed rail length, when the token names one. Null means the rail takes
  /// whatever the steps leave it.
  double? get _fixedRail => r.railLength;

  /// The narrowest a step may be squeezed to before the run gives up sharing
  /// the width. Derived rather than fixed: the marker, the gap, five
  /// characters' worth of title and the least rail that still reads as a line.
  double get _stepFloor =>
      r.itemMinWidth ??
      (_markerExtent + r.itemGap + _headerFloor(t, state.items) + _minRail);

  @override
  Widget build(BuildContext context) {
    final items = state.items;
    if (orientation == StepsOrientation.vertical) {
      final column = Column(
        // Not `stretch`: that would hand every step the full width and make
        // the whole row hoverable, three columns away from the text.
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++)
            // With a named rail length the step is as tall as the taller of
            // its text and its axis — marker plus rail — and the rail takes
            // up whatever slack the text leaves, so it always reaches down to
            // the next marker.
            _fixedRail == null
                ? _verticalStep(i)
                : IntrinsicHeight(child: _verticalStep(i)),
        ],
      );

      // Folding never goes below three steps, and three may still be more than
      // a short box can hold. The promise of the mode is that the layout does
      // not break, so what is left over scrolls rather than overflowing.
      if (state.widget.overflow != StepsOverflow.fold) return column;
      return SingleChildScrollView(child: column);
    }

    // The run fills the width it is given and shares it out equally — no step
    // is wider than another just because its title is longer.
    Row row({bool stacked = false}) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(child: _horizontalStep(i, stacked: stacked)),
          ],
        );

    // With the rails fixed the steps no longer share the width — each is as
    // wide as its own text — so the row shrink-wraps and scrolls if the sum
    // outgrows the room.
    if (_fixedRail != null) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Each step is as wide as the wider of its header — marker, title
            // and the rail at its named length — and its content. The rail is
            // the part that gives, so it stretches to reach the next marker
            // wherever the content is the wider of the two.
            for (var i = 0; i < items.length; i++)
              IntrinsicWidth(child: _horizontalStep(i)),
          ],
        ),
      );
    }

    // `inline` is the miniature: one-line titles, no content, meant for a
    // popover. It is never the thing that overflows, and a floor would send
    // it scrolling where it fits perfectly well.
    if (_inline) return row();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) return row();

        // Three answers to a narrowing run, in order of how much they cost the
        // reader: share the width with the text beside each marker; stack the
        // text under the markers, which needs no marker column; and only then
        // stop sharing and scroll.
        final stacked = _stacksAt(constraints.maxWidth);
        final floor = stacked ? _stackedFloor : _stepFloor;
        final natural = floor * items.length;
        if (natural <= constraints.maxWidth) return row(stacked: stacked);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: natural, child: row(stacked: stacked)),
        );
      },
    );
  }

  Widget _step(int index, Widget Function(bool hovered) child) {
    final item = state.items[index];
    final enabled = state._interactive && !item.disabled;
    return Semantics(
      button: enabled,
      selected: index == state._shownCurrent,
      child: Opacity(
        opacity: item.disabled ? 0.45 : 1,
        child: _Tappable(
          enabled: enabled,
          onTap: () => state._select(index),
          builder: child,
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Vertical
  // --------------------------------------------------------------------------

  Widget _verticalStep(int index) {
    final items = state.items;
    final item = items[index];
    final status = state._statusOf(index);
    final isLast = index == items.length - 1;

    // The kit leaves the step in play alone on hover (`:not(-active)`),
    // because its colours are the point.
    final answersHover = index != state._shownCurrent;
    Widget marker(bool hovered) => _Marker(
          t: t,
          r: r,
          palette: palette,
          status: status,
          item: item,
          number: state.numberOf(index),
          dot: _dot,
          percent: state.widget.percent,
          progress: state.widget.progress,
          hovered: hovered && answersHover,
        );

    // The kit gives a vertical step a heading band as tall as the taller of
    // the marker and the title line, and centres the marker in it. Both then
    // share an axis however big the type is.
    final titleLine = scale.title(t) * t.lineHeight;
    final headerHeight = math.max(_markerExtent, titleLine);

    // The rail hangs from just under the marker to the next one. It starts at
    // the marker's own edge, not the band's, so the gap stays what the token
    // says whatever the type does.
    final belowMarker = (headerHeight - _markerExtent) / 2;

    Widget axis(bool hovered) => SizedBox(
          width: _markerExtent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: headerHeight,
                child: Center(child: marker(hovered)),
              ),
              if (!isLast)
                _railSlot(
                  axis: Axis.vertical,
                  gaps: r.leadingInset(Axis.vertical) +
                      r.trailingInset(Axis.vertical) -
                      belowMarker,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: RailPainter(
                      axis: Axis.vertical,
                      thickness: r.railThickness,
                      minLength: r.railMinLength,
                      startInset: r.leadingInset(Axis.vertical) - belowMarker,
                      endInset: r.trailingInset(Axis.vertical),
                      segments: [
                        RailSegment(
                          start: 0,
                          end: double.infinity,
                          color: palette.rail(status),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );

    return _step(
      index,
      // `Align` keeps the hit area to the marker and its text: a vertical run
      // is as wide as its parent, and hovering empty space three columns away
      // must not light the step up.
      (hovered) => Align(
        alignment: Alignment.centerLeft,
        widthFactor: 1,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              axis(hovered),
              SizedBox(width: r.itemGap),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The same band, so the title meets the marker's centre.
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: headerHeight),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1,
                        child: _StepText(
                          t: t,
                          r: r,
                          palette: palette,
                          item: item,
                          status: status,
                          scale: scale,
                          centred: false,
                          inline: _inline,
                          hovered: hovered,
                          part: _StepTextPart.header,
                        ),
                      ),
                    ),
                    if (item.content != null && !_inline)
                      Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1,
                        child: _StepText(
                          t: t,
                          r: r,
                          palette: palette,
                          item: item,
                          status: status,
                          scale: scale,
                          centred: false,
                          inline: _inline,
                          hovered: hovered,
                          part: _StepTextPart.content,
                        ),
                      ),
                    SizedBox(height: isLast ? 0 : t.sizeLG),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Horizontal
  // --------------------------------------------------------------------------

  Widget _horizontalStep(int index, {bool stacked = false}) {
    final placement = _placementOf(stacked: stacked);
    final items = state.items;
    final item = items[index];
    final status = state._statusOf(index);
    final isLast = index == items.length - 1;

    final answersHover = index != state._shownCurrent;
    Widget marker(bool hovered) => _Marker(
          t: t,
          r: r,
          palette: palette,
          status: status,
          item: item,
          number: state.numberOf(index),
          dot: _dot,
          percent: state.widget.percent,
          progress: state.widget.progress,
          hovered: hovered && answersHover,
        );

    Widget text(bool hovered, {_StepTextPart part = _StepTextPart.all}) =>
        _StepText(
          t: t,
          r: r,
          palette: palette,
          item: item,
          status: status,
          scale: scale,
          centred: placement == StepTitlePlacement.vertical,
          inline: _inline,
          hovered: hovered,
          part: part,
        );

    // `leadingGap` keeps the rail clear of the marker it starts beside, and
    // `trailingGap` of the one it runs towards.
    // The painter insets from the box's left and right; the row hands the two
    // halves over in reading order. Reading right to left the two disagree, so
    // the gap meant for the marker turns inward and opens a break in the
    // middle of the line while the ends run flush into the markers — the very
    // void the halves are split to avoid.
    final railsMirrored = direction == TextDirection.rtl;

    Widget rail({
      required Color color,
      required double leadingGap,
      required double trailingGap,
    }) =>
        CustomPaint(
          // Without a size a childless CustomPaint collapses to nothing; the
          // rail is meant to take whatever width its slot hands it.
          size: Size.infinite,
          painter: RailPainter(
            axis: Axis.horizontal,
            thickness: r.railThickness,
            minLength: r.railMinLength,
            startInset: railsMirrored ? trailingGap : leadingGap,
            endInset: railsMirrored ? leadingGap : trailingGap,
            segments: [
              RailSegment(start: 0, end: double.infinity, color: color),
            ],
          ),
        );

    if (placement == StepTitlePlacement.vertical) {
      // Marker centred over its own title, with the rail passing behind it.
      return _step(
        index,
        (hovered) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _markerExtent,
              child: Row(
                children: [
                  _railSlot(
                    axis: Axis.horizontal,
                    half: true,
                    gaps: _railGapTrailing,
                    child: index == 0
                        ? const SizedBox.shrink()
                        // The painter owns the whole band and centres the line
                        // in it on the pixel grid; a one-pixel box centred by
                        // the layout would land on a half pixel and be drawn
                        // as two half-strength lines.
                        : rail(
                            // Coloured by the step it comes *from*.
                            color: palette.rail(state._statusOf(index - 1)),
                            // The run between two markers is drawn as two
                            // halves, one per step. Only the outer ends —
                            // the ones meeting a marker — get the gap; an
                            // inner one would leave a void in the middle.
                            leadingGap: 0,
                            trailingGap: _railGapTrailing,
                          ),
                  ),
                  marker(hovered),
                  _railSlot(
                    axis: Axis.horizontal,
                    half: true,
                    gaps: _railGapLeading,
                    child: isLast
                        ? const SizedBox.shrink()
                        : rail(
                            color: palette.rail(status),
                            leadingGap: _railGapLeading,
                            trailingGap: 0,
                          ),
                  ),
                ],
              ),
            ),
            SizedBox(height: t.sizeXS),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: t.sizeXS),
              child: text(hovered),
            ),
          ],
        ),
      );
    }

    // Marker, title beside it, the rail running on from the *title* — and the
    // content on the next line, under the title. The kit puts the rail in
    // the header row for exactly this reason: a long description must not push
    // the line towards the next step.
    // The title is measured against the room the step has, which only a
    // LayoutBuilder knows — except with the rails fixed, where the step sizes
    // to its own content and there is no room to measure against. Then it is
    // skipped: an intrinsic pass cannot run a LayoutBuilder's callback, and
    // that is exactly the pass sizing these steps.
    return _step(
      index,
      (hovered) => _fixedRail != null
          ? _horizontalBody(index, hovered, double.infinity)
          : LayoutBuilder(
              builder: (context, constraints) =>
                  _horizontalBody(index, hovered, constraints.maxWidth),
            ),
    );
  }

  Widget _horizontalBody(int index, bool hovered, double maxWidth) {
    final items = state.items;
    final item = items[index];
    final status = state._statusOf(index);
    final isLast = index == items.length - 1;
    final answersHover = index != state._shownCurrent;

    Widget marker(bool hovered) => _Marker(
          t: t,
          r: r,
          palette: palette,
          status: status,
          item: item,
          number: state.numberOf(index),
          dot: _dot,
          percent: state.widget.percent,
          progress: state.widget.progress,
          hovered: hovered && answersHover,
        );

    Widget text(bool hovered, {_StepTextPart part = _StepTextPart.all}) =>
        _StepText(
          t: t,
          r: r,
          palette: palette,
          item: item,
          status: status,
          scale: scale,
          centred: false,
          inline: _inline,
          hovered: hovered,
          part: part,
        );

    // See the other rail helper: the painter insets by side, the row orders by
    // reading direction, and the two have to be reconciled.
    final railsMirrored = direction == TextDirection.rtl;

    Widget rail({
      required Color color,
      required double leadingGap,
      required double trailingGap,
    }) =>
        CustomPaint(
          size: Size.infinite,
          painter: RailPainter(
            axis: Axis.horizontal,
            thickness: r.railThickness,
            minLength: r.railMinLength,
            startInset: railsMirrored ? trailingGap : leadingGap,
            endInset: railsMirrored ? leadingGap : trailingGap,
            segments: [
              RailSegment(start: 0, end: double.infinity, color: color),
            ],
          ),
        );

    final reserved = _markerExtent + r.itemGap + _minRail;
    final titleWidth = maxWidth - reserved;

    // the header is `align-items: center`, which centres the
    // marker on the title — fine while every title is one line. Let one
    // of them wrap and each step centres on its own height, and the run
    // becomes a staircase: markers and rails at a different y per step.
    // So the header is a band of its own, as tall as the taller of the
    // marker and *one* line of title, with the marker and the rail
    // centred in it. A title that wraps grows downwards from there, and
    // the axis holds across the whole run.
    final titleLine = scale.title(t) * t.lineHeight;
    final band = math.max(_markerExtent, titleLine);
    final titleOffset = math.max(0.0, (band - titleLine) / 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: band, child: Center(child: marker(hovered))),
            SizedBox(width: r.itemGap),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isLast
                    ? maxWidth - _markerExtent - r.itemGap
                    : (titleWidth < 0 ? 0 : titleWidth),
              ),
              child: Padding(
                padding: EdgeInsets.only(top: titleOffset),
                child: text(hovered, part: _StepTextPart.header),
              ),
            ),
            if (!isLast)
              _railSlot(
                axis: Axis.horizontal,
                gaps: _railGapLeading + _railGapTrailing,
                child: SizedBox(
                  height: band,
                  child: rail(
                    color: palette.rail(status),
                    leadingGap: _railGapLeading,
                    trailingGap: _railGapTrailing,
                  ),
                ),
              ),
          ],
        ),
        if (item.content != null)
          Padding(
            // Lines up under the title, clear of the marker.
            padding: EdgeInsets.only(
              left: _markerExtent + r.itemGap,
              top: t.sizeXXS,
              right: r.itemGap,
            ),
            child: text(hovered, part: _StepTextPart.content),
          ),
      ],
    );
  }

  /// The least a rail may shrink to and still read as a line between steps.
  double get _minRail => _railGapLeading + _railGapTrailing + r.railMinLength;
}

/// [StepsType.navigation]: tappable blocks split by a chevron, the current one
/// underlined.
class _NavigationRun extends StatelessWidget {
  const _NavigationRun({
    required this.state,
    required this.t,
    required this.r,
    required this.palette,
    required this.orientation,
  });

  final _StepsState state;
  final Token t;
  final _ResolvedStepsToken r;
  final _Palette palette;
  final StepsOrientation orientation;

  @override
  Widget build(BuildContext context) {
    final items = state.items;
    final blocks = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      blocks.add(
        orientation == StepsOrientation.horizontal
            ? Expanded(child: _block(i))
            : _block(i),
      );
      if (i < items.length - 1) blocks.add(_arrow());
    }

    if (orientation == StepsOrientation.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: blocks,
      );
    }

    final row = IntrinsicHeight(
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: blocks),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // How wide the strip wants to be is a question about its blocks — the
        // longest title, the floor, or a width the caller named — so the
        // intrinsic pass answers it rather than a guess at a number. Inside
        // the scroll view the width is unbounded, so the row comes out at its
        // natural size; the minimum then stretches it to the viewport where
        // there is room to spare, and a named width is left alone.
        if (!constraints.hasBoundedWidth) return row;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: r.itemWidth != null ? 0 : constraints.maxWidth,
            ),
            child: IntrinsicWidth(child: row),
          ),
        );
      },
    );
  }

  Widget _arrow() => Padding(
        padding: EdgeInsets.symmetric(horizontal: t.sizeXS),
        child: Center(
          child: RotatedBox(
            quarterTurns: orientation == StepsOrientation.horizontal ? 0 : 1,
            child: CustomPaint(
              size: const Size(12, 12),
              painter: ChevronPainter(r.arrowColor),
            ),
          ),
        ),
      );

  Widget _block(int index) {
    final item = state.items[index];
    final status = state._statusOf(index);
    final selected = index == state._shownCurrent;

    return _Tappable(
      enabled: state._interactive && !item.disabled,
      onTap: () => state._select(index),
      builder: (hovered) => Opacity(
        opacity: item.disabled ? 0.45 : 1,
        // What a block asks for: its own text — or the width and height the
        // caller named. Outside the AnimatedContainer on purpose: constraints
        // there are animated, and a BoxConstraintsTween cannot lerp between a
        // finite width and an unbounded one, so naming a width at runtime
        // would throw.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: r.itemWidth ?? 0,
            maxWidth: r.itemWidth ?? double.infinity,
            minHeight: r.itemHeight ?? 0,
            maxHeight: r.itemHeight ?? double.infinity,
          ),
          child: AnimatedContainer(
            duration: t.motionDurationMid,
            curve: t.motionEaseInOut,
            padding: r.scale.blockPadding(t),
            decoration: BoxDecoration(
              color: hovered
                  ? palette.opaque(t.colorFillQuaternary)
                  : t.colorBgContainer,
              borderRadius: BorderRadius.circular(t.borderRadius),
              // The current block is underlined rather than filled — the run
              // reads as navigation, not as a set of buttons.
              border: Border(
                bottom: BorderSide(
                  color: selected ? t.primary.base : const Color(0x00000000),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Marker(
                  t: t,
                  r: r,
                  palette: palette,
                  status: status,
                  item: item,
                  number: state.numberOf(index),
                  dot: false,
                ),
                SizedBox(width: r.itemGap),
                Flexible(
                  child: _StepText(
                    t: t,
                    r: r,
                    palette: palette,
                    item: item,
                    status: status,
                    scale: r.scale,
                    centred: false,
                    hovered: hovered,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [StepsType.panel]: the steps as a strip of arrow-shaped panels.
///
/// Each panel points at the next one, and its neighbour is notched to receive
/// the point, whose path is a plain `M 0 0 L 100 50
/// L 0 100`. The marker is dropped here: the panel itself carries the state,
/// through its fill.
///
/// The kit strokes every panel *and* the arrow between them, so an outlined
/// run comes out with doubled seams. Here the whole strip is painted in one
/// pass: every fill once, every line once. Doubling has nowhere to come from.
class _PanelRun extends StatelessWidget {
  const _PanelRun({
    required this.state,
    required this.t,
    required this.r,
    required this.palette,
    required this.orientation,
  });

  final _StepsState state;
  final Token t;
  final _ResolvedStepsToken r;
  final _Palette palette;
  final StepsOrientation orientation;

  bool get _outlined => state.widget.variant == StepsVariant.outlined;
  bool get _horizontal => orientation == StepsOrientation.horizontal;

  /// The kit derives a panel's fill and outline from the *marker's* colours
  /// for that status, which is why a run reads at a glance: the step in play is
  /// solid, a failed one is tinted red, the ones ahead stay grey.
  Color _fill(int index, bool hovered) {
    final status = state._statusOf(index);
    final current = index == state._shownCurrent;

    if (_outlined) {
      final base = switch (status) {
        StepStatus.process => t.primary.bg,
        StepStatus.finish => t.colorBgContainer,
        StepStatus.error => t.colorBgContainer,
        StepStatus.wait => t.colorBgContainer,
      };
      return hovered && !current ? palette.opaque(t.colorFillQuaternary) : base;
    }

    if (current && status == StepStatus.process) return t.primary.base;
    final base = switch (status) {
      StepStatus.finish => t.primary.bg,
      StepStatus.error => t.error.bg,
      StepStatus.wait => palette.opaque(t.colorFillQuaternary),
      StepStatus.process => t.primary.base,
    };
    return hovered ? Color.alphaBlend(t.colorFillQuaternary, base) : base;
  }

  /// The outline of a panel, in the same status colour.
  Color? _stroke(int index) {
    if (!_outlined) return null;
    return switch (state._statusOf(index)) {
      StepStatus.process || StepStatus.finish => t.primary.base,
      StepStatus.error => t.error.base,
      StepStatus.wait => t.colorBorder,
    };
  }

  /// The colour of the join between panel [index] and the next.
  ///
  /// Drawn once, so it has to pick a side: the selected panel wins, because its
  /// outline is what the eye follows. Otherwise the panel behind the point owns
  /// it, the way an arrow belongs to the thing it comes out of.
  Color? _seam(int index) {
    if (!_outlined) return null;
    final ahead = index + 1;
    if (ahead == state._shownCurrent) return _stroke(ahead);
    return _stroke(index);
  }

  /// White on a solid panel; otherwise the status speaks for itself.
  Color? _ink(int index) {
    final status = state._statusOf(index);
    final current = index == state._shownCurrent;

    if (!_outlined) {
      if (current && status == StepStatus.process) {
        return const Color(0xFFFFFFFF);
      }
      return switch (status) {
        StepStatus.finish => t.primary.text,
        StepStatus.error => t.error.base,
        StepStatus.wait => t.colorTextTertiary,
        StepStatus.process => const Color(0xFFFFFFFF),
      };
    }

    return switch (status) {
      StepStatus.process || StepStatus.finish => t.primary.base,
      StepStatus.error => t.error.base,
      StepStatus.wait => t.colorTextTertiary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final items = state.items;
    final horizontal = _horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final strip = _HoverIndex(
          builder: (context, hovered, setHovered) => Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PanelStripPainter(
                    axis: horizontal ? Axis.horizontal : Axis.vertical,
                    direction: Directionality.of(context),
                    count: items.length,
                    arrow: r.panelArrowWidth,
                    radius: r.panelRadius,
                    fills: [
                      for (var i = 0; i < items.length; i++)
                        _fill(i, hovered == i),
                    ],
                    strokes: [
                      for (var i = 0; i < items.length; i++) _stroke(i),
                    ],
                    seams: [
                      for (var i = 0; i < items.length - 1; i++) _seam(i),
                    ],
                    strokeWidth: t.lineWidth,
                  ),
                ),
              ),
              if (horizontal)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _panelContent(
                            i,
                            hovered: hovered == i,
                            onHover: (over) => setHovered(over ? i : null),
                            // Panels after the first are notched on their
                            // leading edge; their text starts clear of it.
                            leading: i == 0 ? 0 : r.panelArrowWidth,
                          ),
                        ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _panelContent(
                        i,
                        hovered: hovered == i,
                        onHover: (over) => setHovered(over ? i : null),
                        leading: i == 0 ? 0 : r.panelArrowWidth,
                      ),
                  ],
                ),
            ],
          ),
        );

        if (!horizontal) {
          // A vertical strip is the same set of panels turned a quarter, so
          // they keep the shape they have across the page: as wide as the
          // widest of them and no wider. Left to itself a Column takes every
          // pixel its parent offers — a stretch parent would blow one panel
          // across the screen and leave its arrow pointing down a canyon.
          return Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: r.panelWidth ??
                    math.min(r.panelMinWidth, constraints.maxWidth),
                maxWidth: r.panelWidth ?? constraints.maxWidth,
              ),
              child: IntrinsicWidth(child: strip),
            ),
          );
        }

        // How much room the strip wants is a question about its contents —
        // the longest title, the longest line of content, the floor, or a
        // width the caller named — so the intrinsic pass answers it rather
        // than a guess at a number. Inside the scroll view the width is
        // unbounded, so the strip comes out at its natural size; the minimum
        // then stretches it to the viewport where there is room to spare.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            // A caller who named a width meant it: the strip keeps to it and
            // leaves the rest of the row empty, rather than being stretched to
            // the viewport with the panels' text boxes stranded inside.
            constraints: BoxConstraints(
              minWidth: r.panelWidth != null ? 0 : constraints.maxWidth,
            ),
            child: IntrinsicWidth(child: strip),
          ),
        );
      },
    );
  }

  Widget _panelContent(
    int index, {
    required bool hovered,
    required ValueChanged<bool> onHover,
    required double leading,
  }) {
    final item = state.items[index];
    final status = state._statusOf(index);

    return _Tappable(
      enabled: state._interactive && !item.disabled,
      onTap: () => state._select(index),
      onHoverChanged: onHover,
      builder: (_) => Opacity(
        opacity: item.disabled ? 0.45 : 1,
        // What a panel asks for. Left alone that is what its own text needs,
        // never below the floor; a named width or height is taken instead.
        // These are the numbers the intrinsic pass reads, which is how the
        // strip works out how much room it wants altogether.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: r.panelWidth ?? r.panelMinWidth,
            maxWidth: r.panelWidth ?? double.infinity,
            minHeight: r.panelHeight ?? 0,
            maxHeight: r.panelHeight ?? double.infinity,
          ),
          child: Padding(
            padding: r.panelPadding.add(
              _horizontal
                  ? EdgeInsets.only(left: leading)
                  : EdgeInsets.only(top: leading),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StepText(
                t: t,
                r: r,
                palette: palette,
                item: item,
                status: status,
                scale: r.scale,
                centred: false,
                colorOverride: _ink(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tracks which of a run's children the pointer is over, so a strip painted in
/// one pass can still answer per panel.
class _HoverIndex extends StatefulWidget {
  const _HoverIndex({required this.builder});

  final Widget Function(
    BuildContext context,
    int? hovered,
    ValueChanged<int?> setHovered,
  ) builder;

  @override
  State<_HoverIndex> createState() => _HoverIndexState();
}

class _HoverIndexState extends State<_HoverIndex> {
  int? _hovered;

  @override
  Widget build(BuildContext context) => widget.builder(
        context,
        _hovered,
        (index) {
          if (index == _hovered) return;
          setState(() => _hovered = index);
        },
      );
}

/// Paints the whole panel strip: every fill once, every line once.
///
/// A panel strokes its own top, bottom and outer end. The chevron between two
/// panels is a seam, drawn separately and exactly once, so it can take the
/// colour that matters — the selected panel's, when it is one of the pair.
/// Letting both neighbours stroke it is what produces doubled seams, so only
/// one of them does.
class _PanelStripPainter extends CustomPainter {
  const _PanelStripPainter({
    required this.axis,
    required this.direction,
    required this.count,
    required this.arrow,
    required this.radius,
    required this.fills,
    required this.strokes,
    required this.seams,
    required this.strokeWidth,
  });

  /// Which way the run reads.
  ///
  /// A horizontal strip that reads right to left is the same shape mirrored:
  /// every panel points the way the eye travels, and the first is drawn at the
  /// right. Reflecting the canvas does both at once — the shapes and their
  /// order — and matches the row of content above it, which mirrors itself.
  final TextDirection direction;

  /// Which way the strip runs. A vertical strip is the same shape turned a
  /// quarter: its panels point down into the next.
  final Axis axis;

  final int count;
  final double arrow;
  final double radius;
  final List<Color> fills;
  final List<Color?> strokes;

  /// Colour of each join, `count - 1` of them.
  final List<Color?> seams;

  final double strokeWidth;

  /// The strip is built as if it ran left to right, then transposed for a
  /// vertical one — a point stays a point, a rounded corner stays round.
  Size _logical(Size size) =>
      axis == Axis.horizontal ? size : Size(size.height, size.width);

  static final Matrix4 _transpose = Matrix4.identity()
    ..setEntry(0, 0, 0)
    ..setEntry(1, 1, 0)
    ..setEntry(0, 1, 1)
    ..setEntry(1, 0, 1);

  Path _oriented(Path path) =>
      axis == Axis.horizontal ? path : path.transform(_transpose.storage);

  double _left(int index, Size size) => size.width / count * index;

  /// The closed outline of a panel: a box pointed on its trailing edge and
  /// notched on its leading one, squared into a rounded corner at the ends.
  Path _fillPath(int index, Size size) {
    final h = size.height;
    final left = _left(index, size);
    final right = _left(index + 1, size);
    final first = index == 0;
    final last = index == count - 1;
    final path = Path();

    if (first) {
      path.moveTo(left + radius, 0);
    } else {
      path.moveTo(left, 0);
    }

    if (last) {
      path.lineTo(right - radius, 0);
      path.arcToPoint(Offset(right, radius), radius: Radius.circular(radius));
      path.lineTo(right, h - radius);
      path.arcToPoint(
        Offset(right - radius, h),
        radius: Radius.circular(radius),
      );
    } else {
      path.lineTo(right, 0);
      path.lineTo(right + arrow, h / 2);
      path.lineTo(right, h);
    }

    if (first) {
      path.lineTo(left + radius, h);
      path.arcToPoint(
        Offset(left, h - radius),
        radius: Radius.circular(radius),
      );
      path.lineTo(left, radius);
      path.arcToPoint(
        Offset(left + radius, 0),
        radius: Radius.circular(radius),
      );
    } else {
      path.lineTo(left, h);
      path.lineTo(left + arrow, h / 2);
    }
    path.close();
    return path;
  }

  /// A panel's own edges: top, bottom, and the rounded end if it has one. The
  /// chevrons at either side belong to the seams.
  Path _edgePath(int index, Size size) {
    final h = size.height;
    final left = _left(index, size);
    final right = _left(index + 1, size);
    final first = index == 0;
    final last = index == count - 1;
    final path = Path();

    final topFrom = first ? left + radius : left;
    final topTo = last ? right - radius : right;
    path.moveTo(topFrom, 0);
    path.lineTo(topTo, 0);
    if (last) {
      path.arcToPoint(Offset(right, radius), radius: Radius.circular(radius));
      path.lineTo(right, h - radius);
      path.arcToPoint(
        Offset(right - radius, h),
        radius: Radius.circular(radius),
      );
      path.lineTo(first ? left + radius : left, h);
    } else {
      path.moveTo(topFrom, h);
      path.lineTo(right, h);
    }

    if (first) {
      // The rounded leading end, drawn as its own run.
      path.moveTo(left + radius, h);
      // Same sweep as the fill draws for this corner: the other one has its
      // centre *on* the corner and bulges outward, which reads as a kink.
      path.arcToPoint(
        Offset(left, h - radius),
        radius: Radius.circular(radius),
      );
      path.lineTo(left, radius);
      path.arcToPoint(
        Offset(left + radius, 0),
        radius: Radius.circular(radius),
      );
    }
    return path;
  }

  /// The chevron between panel [index] and the one after it.
  Path _seamPath(int index, Size size) {
    final h = size.height;
    final x = _left(index + 1, size);
    return Path()
      ..moveTo(x, 0)
      ..lineTo(x + arrow, h / 2)
      ..lineTo(x, h);
  }

  Paint _pen(Color colour) => Paint()
    ..color = colour
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final logical = _logical(size);
    final mirrored = axis == Axis.horizontal && direction == TextDirection.rtl;
    if (mirrored) {
      canvas
        ..save()
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }

    // Fills in order, so each point laps over the notch of the panel behind it.
    for (var i = 0; i < count; i++) {
      canvas.drawPath(
        _oriented(_fillPath(i, logical)),
        Paint()..color = fills[i],
      );
    }

    for (var i = 0; i < count; i++) {
      final colour = strokes[i];
      if (colour != null) {
        canvas.drawPath(_oriented(_edgePath(i, logical)), _pen(colour));
      }
    }

    for (var i = 0; i < seams.length; i++) {
      final colour = seams[i];
      if (colour != null) {
        canvas.drawPath(_oriented(_seamPath(i, logical)), _pen(colour));
      }
    }

    if (mirrored) canvas.restore();
  }

  @override
  bool shouldRepaint(_PanelStripPainter old) =>
      old.axis != axis ||
      old.direction != direction ||
      old.count != count ||
      old.arrow != arrow ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      Iterable<int>.generate(fills.length).any(
        (i) => old.fills[i] != fills[i] || old.strokes[i] != strokes[i],
      ) ||
      Iterable<int>.generate(seams.length).any((i) => old.seams[i] != seams[i]);
}
