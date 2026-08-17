import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import 'message.dart' show StatusType;

/// Shape of a [Progress].
enum ProgressType {
  /// A horizontal bar.
  line,

  /// A ring.
  circle,

  /// A ring with an open gap arc.
  dashboard,
}

/// Placement of the gap in a dashboard ring [Progress].
enum GapPlacement {
  /// Gap at the top.
  top,

  /// Gap at the bottom (default).
  bottom,

  /// Gap on the left.
  left,

  /// Gap on the right.
  right,
}

/// Mode of filling individual step segments in a step-style [Progress].
enum ProgressStepFill {
  /// Step segments fill smoothly and gradually as a fraction (default).
  gradually,

  /// Step segments fill immediately as a full block as soon as reached.
  immediately,
}

/// Detailed step configuration for [Progress.steps].
///
/// Specify the number of step segments [count], pixel spacing [gap],
/// fill mode [fill], and custom per-step radius builder [stepRadius].
///
/// ```dart
/// ProgressSteps(
///   5,
///   gap: 7,
///   fill: ProgressStepFill.immediately,
///   stepRadius: (isFirst, percent) {
///     if (isFirst == true) return const ProgressBorderRadius.horizontal(left: 6);
///     if (isFirst == false) return const ProgressBorderRadius.horizontal(right: 6);
///     return ProgressBorderRadius.zero;
///   },
/// )
/// ```
@immutable
class ProgressSteps {
  /// Creates a step configuration with [count] and optional parameters.
  const ProgressSteps(
    this.count, {
    this.gap = 2.0,
    this.fill = ProgressStepFill.gradually,
    this.stepRadius,
    this.onStepChange,
  }) : assert(count > 0, 'count must be positive');

  /// Convenience constructor for count with default settings.
  const ProgressSteps.count(int count) : this(count);

  /// Total number of step segments.
  final int count;

  /// Pixel gap between step segments (in logical pixels).
  final double gap;

  /// How step segments fill ([ProgressStepFill.gradually] or [ProgressStepFill.immediately]).
  final ProgressStepFill fill;

  /// Optional builder function to calculate per-step corner radius.
  ///
  /// Parameters:
  /// - `isFirst`: `true` for first step, `false` for last step, `null` for middle steps.
  /// - `percent`: completion fraction of this individual step (0.0 to 1.0).
  final ProgressBorderRadius Function(bool? isFirst, double percent)?
      stepRadius;

  /// Callback fired when active step changes.
  ///
  /// Parameters:
  /// - `currentStep`: number of completed/active steps reached (0 to [count]).
  /// - `totalSteps`: total step count ([count]).
  final void Function(int currentStep, int totalSteps)? onStepChange;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressSteps &&
          runtimeType == other.runtimeType &&
          count == other.count &&
          gap == other.gap &&
          fill == other.fill &&
          stepRadius == other.stepRadius &&
          onStepChange == other.onStepChange;

  @override
  int get hashCode => Object.hash(count, gap, fill, stepRadius, onStepChange);
}

/// Corner radius configuration for line [Progress] bars.
///
/// Can be specified as a uniform radius `borderRadius: 8.0`, per-corner
/// `ProgressBorderRadius(topLeft: 8, bottomLeft: 8)`, or Flutter [BorderRadius].
@immutable
class ProgressBorderRadius {
  /// Creates a border radius configuration with optional per-corner radii.
  const ProgressBorderRadius({
    this.topLeft,
    this.bottomLeft,
    this.topRight,
    this.bottomRight,
  });

  /// Creates a border radius with distinct left and right radii.
  const ProgressBorderRadius.horizontal({
    double left = 0,
    double right = 0,
  })  : topLeft = left,
        bottomLeft = left,
        topRight = right,
        bottomRight = right;

  /// Creates a uniform border radius for all corners.
  const ProgressBorderRadius.all(double radius)
      : topLeft = radius,
        bottomLeft = radius,
        topRight = radius,
        bottomRight = radius;

  /// Constant zero radius (square corners).
  static const ProgressBorderRadius zero = ProgressBorderRadius.all(0);

  /// Radius for top-left corner.
  final double? topLeft;

  /// Radius for bottom-left corner.
  final double? bottomLeft;

  /// Radius for top-right corner.
  final double? topRight;

  /// Radius for bottom-right corner.
  final double? bottomRight;

  /// Converts to Flutter [BorderRadius].
  BorderRadius toBorderRadius() => BorderRadius.only(
        topLeft: Radius.circular(topLeft ?? 0),
        bottomLeft: Radius.circular(bottomLeft ?? 0),
        topRight: Radius.circular(topRight ?? 0),
        bottomRight: Radius.circular(bottomRight ?? 0),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressBorderRadius &&
          runtimeType == other.runtimeType &&
          topLeft == other.topLeft &&
          bottomLeft == other.bottomLeft &&
          topRight == other.topRight &&
          bottomRight == other.bottomRight;

  @override
  int get hashCode => Object.hash(topLeft, bottomLeft, topRight, bottomRight);
}

/// A percentage range for [Progress.rangeColors].
///
/// [from] marks the inclusive start of the range (0–1 scale).
/// [to] marks the exclusive end; when `null` the range extends to 1.0 (100 %).
///
/// ```dart
/// ProgressRange(0.0, to: 0.3) // 0–30 %
/// ProgressRange(0.3, to: 0.7) // 30–70 %
/// ProgressRange(0.7)           // 70–100 %
/// ```
class ProgressRange {
  /// Creates a range starting at [from].
  ///
  /// If [to] is omitted the range extends to the end (100 %).
  const ProgressRange(this.from, {this.to})
      : assert(from >= 0 && from <= 1, 'from must be between 0 and 1');

  /// Inclusive start of the range (0–1).
  final double from;

  /// Exclusive end of the range (0–1). `null` means "until the end".
  final double? to;
}

/// Type of info label placement in [Progress] (outside track or inside track).
enum PercentInfoType {
  /// Info label rendered outside the progress track (default).
  outer,

  /// Info label rendered inside the progress track.
  inner,
}

/// Horizontal alignment of the info label in [Progress].
enum PercentInfoAlign {
  /// Align to start (left in LTR, right in RTL).
  start,

  /// Align to center.
  center,

  /// Align to end (right in LTR, left in RTL).
  end,

  /// Info label rides along with the moving tip of the bar.
  follow,
}

/// Placement and alignment configuration of percentage info in [Progress].
class PercentPosition {
  /// Creates a [PercentPosition].
  const PercentPosition({
    this.type = PercentInfoType.outer,
    this.align = PercentInfoAlign.end,
  });

  /// Convenience constructor for inner positioning.
  const PercentPosition.inner({
    this.align = PercentInfoAlign.center,
  }) : type = PercentInfoType.inner;

  /// Convenience constructor for outer positioning.
  const PercentPosition.outer({
    this.align = PercentInfoAlign.end,
  }) : type = PercentInfoType.outer;

  /// Outer or inner position type.
  final PercentInfoType type;

  /// Start, center, or end alignment.
  final PercentInfoAlign align;
}

/// Per-component design tokens for [Progress].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [ProgressToken(...)])`, or per instance via [Progress.token].
@immutable
class ProgressToken {
  /// Creates a [ProgressToken].
  const ProgressToken({
    this.defaultColor,
    this.remainingColor,
    this.lineHeight,
    this.circleSize,
  });

  /// Filled track color (`defaultColor`).
  final Color? defaultColor;

  /// Unfilled track color (`remainingColor`).
  final Color? remainingColor;

  /// Line height / stroke width for line (`lineHeight`).
  final double? lineHeight;

  /// Diameter of the ring (`circleSize`).
  final double? circleSize;

  _ResolvedProgressToken _resolve(Token t) => _ResolvedProgressToken(
        defaultColor: defaultColor ?? t.primary.base,
        remainingColor: remainingColor ?? t.colorFillSecondary,
        lineHeight: lineHeight ?? 8,
        circleSize: circleSize ?? 120,
      );
}

@immutable
class _ResolvedProgressToken {
  const _ResolvedProgressToken({
    required this.defaultColor,
    required this.remainingColor,
    required this.lineHeight,
    required this.circleSize,
  });

  final Color defaultColor;
  final Color remainingColor;
  final double lineHeight;
  final double circleSize;
}

/// A progress indicator for a task whose completion is known, as a bar or a
/// ring — matching `Progress`.
///
/// ```dart
/// Progress(percent: 0.6)
/// Progress(percent: 1, status: StatusType.success)
/// Progress(type: ProgressType.circle, percent: 0.75)
/// Progress(type: ProgressType.dashboard, percent: 0.85)
/// Progress(percent: 0.7, gradient: LinearGradient(colors: [Colors.blue, Colors.green]))
/// Progress(percent: 0.6, steps: 5)
/// ```
class Progress extends StatefulWidget {
  /// Creates a [Progress].
  const Progress({
    super.key,
    required this.percent,
    this.type = ProgressType.line,
    this.status,
    this.showInfo = true,
    this.strokeWidth,
    this.size,
    this.color,
    this.trailColor,
    this.gradient,
    this.strokeColor,
    this.rangeColors,
    this.steps,
    this.borderRadius,
    this.strokeLinecap,
    this.gapDegree = 75,
    this.gapPlacement = GapPlacement.bottom,
    this.percentPosition,
    this.format,
    this.direction,
    this.onDone,
    this.onProgressChange,
    this.child,
    this.token,
  }) : assert(percent >= 0 && percent <= 1, 'percent must be between 0 and 1');

  /// Completion from 0 to 1.
  final double percent;

  /// Bar, ring or dashboard ring.
  final ProgressType type;

  /// Overrides the colour with a status.
  final StatusType? status;

  /// Whether to show the percentage or custom label.
  final bool showInfo;

  /// Thickness of the track.
  final double? strokeWidth;

  /// How large to draw it. Null takes [SoftSize.middle].
  ///
  /// Examples:
  /// - `SoftSize.small` — a preset
  /// - `ControlSize.fixed(20)` — a diameter, or a line height
  /// - `ControlSize.raw(200, 10)` — an explicit width and height
  final ControlSize? size;

  /// Overrides the fill colour outright.
  final Color? color;

  /// Overrides the unfilled track colour.
  final Color? trailColor;

  /// Background gradient fill (overrides [color]).
  final Gradient? gradient;

  /// Optional list of colors for individual step segments or line colors.
  final List<Color>? strokeColor;

  /// Discrete color ranges mapped to their fill colour.
  ///
  /// Each key is a [ProgressRange] that defines [from] (inclusive start)
  /// and optional [to] (exclusive end, defaults to 1.0).  The bar colour
  /// is resolved by finding the range that contains the current [percent].
  /// Takes priority over [color] but **not** over [gradient].
  ///
  /// ```dart
  /// rangeColors: {
  ///   ProgressRange(0.0, to: 0.3): Colors.red,    // 0–30 %
  ///   ProgressRange(0.3, to: 0.7): Colors.orange, // 30–70 %
  ///   ProgressRange(0.7):          Colors.green,  // 70–100 %
  /// }
  /// ```
  final Map<ProgressRange, Color>? rangeColors;

  /// Step configuration ([ProgressSteps]).
  ///
  /// Examples:
  /// - `ProgressSteps(5)` (5 steps with default gap)
  /// - `ProgressSteps(5, gap: 7)` (5 steps with 7px gap)
  final ProgressSteps? steps;

  /// Custom corner radius for line progress bar ([ProgressBorderRadius]).
  ///
  /// Examples:
  /// - `ProgressBorderRadius.all(4)`
  /// - `ProgressBorderRadius(topLeft: 8, bottomLeft: 8)`
  final ProgressBorderRadius? borderRadius;

  /// The shape of the progress bar cap (`round` or `square`).
  ///
  /// Defaults to `round` for standard progress, and `square` when [steps] is set.
  final StrokeCap? strokeLinecap;

  /// The gap angle in degrees for [ProgressType.dashboard] (default 75).
  final double gapDegree;

  /// Placement of the gap for [ProgressType.dashboard] (top, bottom, left, right).
  final GapPlacement gapPlacement;

  /// Position and alignment of the percentage label ([PercentPosition]).
  final PercentPosition? percentPosition;

  /// Builds the label shown in place of the default percentage.
  ///
  /// Rendered inside a [DefaultTextStyle] carrying the label's colour and
  /// size for its position, so a bare `Text` needs no styling of its own.
  final Widget Function(double percent)? format;

  /// Layout directionality for progress bar and text placement.
  ///
  /// Defaults to ambient [Directionality], or [TextDirection.ltr] if unprovided.
  final TextDirection? direction;

  /// Callback fired when progress completes (reaches 100%).
  final VoidCallback? onDone;

  /// Callback fired when progress percentage value changes.
  ///
  /// Parameter:
  /// - `percent`: updated completion fraction (0.0 to 1.0).
  final void Function(double percent)? onProgressChange;

  /// Content shown in place of the percentage label: in the middle of a ring
  /// for [ProgressType.circle] and [ProgressType.dashboard], where the label
  /// would sit for [ProgressType.line].
  ///
  /// This is how a ring wraps something — a step's marker, an icon, a count:
  ///
  /// ```dart
  /// Progress(type: ProgressType.circle, percent: 0.6, child: Icon(Icons.done))
  /// ```
  final Widget? child;

  /// Per-instance token overrides.
  final ProgressToken? token;

  /// A copy with the given fields replaced. A field left out keeps its
  /// current value; passing null does not clear one.
  Progress copyWith({
    Key? key,
    double? percent,
    ProgressType? type,
    StatusType? status,
    bool? showInfo,
    double? strokeWidth,
    ControlSize? size,
    Color? color,
    Color? trailColor,
    Gradient? gradient,
    List<Color>? strokeColor,
    Map<ProgressRange, Color>? rangeColors,
    ProgressSteps? steps,
    ProgressBorderRadius? borderRadius,
    StrokeCap? strokeLinecap,
    double? gapDegree,
    GapPlacement? gapPlacement,
    PercentPosition? percentPosition,
    Widget Function(double percent)? format,
    TextDirection? direction,
    VoidCallback? onDone,
    void Function(double percent)? onProgressChange,
    Widget? child,
    ProgressToken? token,
  }) =>
      Progress(
        key: key ?? this.key,
        percent: percent ?? this.percent,
        type: type ?? this.type,
        status: status ?? this.status,
        showInfo: showInfo ?? this.showInfo,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        size: size ?? this.size,
        color: color ?? this.color,
        trailColor: trailColor ?? this.trailColor,
        gradient: gradient ?? this.gradient,
        strokeColor: strokeColor ?? this.strokeColor,
        rangeColors: rangeColors ?? this.rangeColors,
        steps: steps ?? this.steps,
        borderRadius: borderRadius ?? this.borderRadius,
        strokeLinecap: strokeLinecap ?? this.strokeLinecap,
        gapDegree: gapDegree ?? this.gapDegree,
        gapPlacement: gapPlacement ?? this.gapPlacement,
        percentPosition: percentPosition ?? this.percentPosition,
        format: format ?? this.format,
        direction: direction ?? this.direction,
        onDone: onDone ?? this.onDone,
        onProgressChange: onProgressChange ?? this.onProgressChange,
        token: token ?? this.token,
        child: child ?? this.child,
      );

  @override
  State<Progress> createState() => _ProgressState();
}

class _ProgressState extends State<Progress> {
  bool _doneFired = false;
  double? _lastPercent;
  int? _lastStep;
  late double _oldPercent;

  @override
  void initState() {
    super.initState();
    _oldPercent = widget.percent;
    _lastPercent = widget.percent;
    _checkStepChange(initial: true);
    if (widget.percent >= 0.9999) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _triggerDone();
        }
      });
    }
  }

  @override
  void didUpdateWidget(Progress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.percent != oldWidget.percent) {
      _oldPercent = oldWidget.percent;
      _notifyProgressChange();
      _checkStepChange();
    }
    if (widget.percent < 0.9999) {
      _doneFired = false;
    }
  }

  void _notifyProgressChange() {
    if (widget.percent != _lastPercent) {
      _lastPercent = widget.percent;
      final p = widget.percent;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onProgressChange?.call(p);
        }
      });
    }
  }

  void _checkStepChange({bool initial = false}) {
    if (widget.steps?.onStepChange != null) {
      final count = widget.steps!.count;
      final currentStep = (widget.percent * count).floor().clamp(0, count);
      if (initial) {
        _lastStep = currentStep;
      } else if (currentStep != _lastStep) {
        _lastStep = currentStep;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.steps!.onStepChange!(currentStep, count);
          }
        });
      }
    }
  }

  void _triggerDone() {
    if (!_doneFired && widget.percent >= 0.9999 && widget.onDone != null) {
      _doneFired = true;
      widget.onDone!.call();
    }
  }

  StrokeCap get _effectiveCap =>
      widget.strokeLinecap ??
      (widget.steps != null ? StrokeCap.butt : StrokeCap.round);

  StatusType _effectiveStatus(double p) =>
      widget.status ?? (p >= 0.9999 ? StatusType.success : StatusType.info);

  bool _isComplete(double p) {
    final s = _effectiveStatus(p);
    return p >= 0.9999 && (s == StatusType.success || s == StatusType.error);
  }

  Color _fill(Token token, double p) {
    if (widget.color != null) return widget.color!;
    if (widget.rangeColors != null && widget.rangeColors!.isNotEmpty) {
      return _resolveRangeColor(p);
    }
    return switch (_effectiveStatus(p)) {
      StatusType.success => token.success.base,
      StatusType.error => token.error.base,
      StatusType.warning => token.warning.base,
      _ => token.primary.base,
    };
  }

  /// Resolves the color from [rangeColors] for the given percent [p].
  ///
  /// Iterates ranges sorted by [ProgressRange.from]. If [to] is omitted,
  /// the range extends up to the next range's [from] (or 1.0 for the last entry).
  Color _resolveRangeColor(double p) {
    final entries = widget.rangeColors!.entries.toList()
      ..sort((a, b) => a.key.from.compareTo(b.key.from));

    for (var i = 0; i < entries.length; i++) {
      final range = entries[i].key;
      final isLastInList = i == entries.length - 1;
      final effectiveTo =
          range.to ?? (isLastInList ? 1.0 : entries[i + 1].key.from);

      final isUpperInclusive = isLastInList || effectiveTo >= 1.0;
      if (p >= range.from &&
          (isUpperInclusive ? p <= effectiveTo : p < effectiveTo)) {
        return entries[i].value;
      }
    }
    return entries.first.value;
  }

  /// The label for [p]: the caller's own widget, or the default percentage.
  Widget _label(double p) =>
      widget.format?.call(p) ?? Text('${(p * 100).round()}%');

  _ProgressResolvedSize _resolveSize(Token token, _ResolvedProgressToken r) {
    final effectiveSize = widget.size ?? SoftSize.middle;
    return switch (effectiveSize) {
      SoftSize.small => const _ProgressResolvedSize(width: 80, height: 6),
      SoftSize.middle =>
        _ProgressResolvedSize(width: r.circleSize, height: r.lineHeight),
      SoftSize.large => const _ProgressResolvedSize(width: 160, height: 12),
      ExplicitSquareSize(:final dimension) =>
        _ProgressResolvedSize(width: dimension, height: dimension),
      ExplicitSize(:final width, :final height) => _ProgressResolvedSize(
          width: width,
          height: height,
          hasFixedStepWidth: widget.steps != null && width > 0,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<ProgressToken>(context) ??
            const ProgressToken())
        ._resolve(token);

    final dir = widget.direction ??
        Directionality.maybeOf(context) ??
        TextDirection.ltr;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _oldPercent, end: widget.percent),
      duration: token.motionDurationMid,
      curve: token.motionEaseInOutCirc,
      onEnd: _triggerDone,
      builder: (context, p, child) {
        return widget.type == ProgressType.line
            ? _line(token, r, p, dir)
            : _circle(token, r, p);
      },
    );
  }

  Widget _line(
    Token token,
    _ResolvedProgressToken r,
    double currentPercent,
    TextDirection dir,
  ) {
    final isRtl = dir == TextDirection.rtl;
    final resSize = _resolveSize(token, r);
    final pos = widget.percentPosition ?? const PercentPosition();
    final isInner = pos.type == PercentInfoType.inner;
    final stroke = widget.strokeWidth ??
        (isInner
            ? (resSize.height < 18 ? 18.0 : resSize.height)
            : resSize.height);
    final fill = _fill(token, currentPercent);
    final cap = _effectiveCap;

    final customRadius = widget.borderRadius?.toBorderRadius();
    final defaultRadius = cap == StrokeCap.round
        ? BorderRadius.circular(stroke)
        : BorderRadius.zero;
    final fallbackRadius = customRadius ?? defaultRadius;

    Widget bar;
    if (widget.steps != null && widget.steps!.count > 1) {
      final stepCount = widget.steps!.count;
      final stepGap = widget.steps!.gap;
      final stepFillMode = widget.steps!.fill;
      final stepRadiusFn = widget.steps!.stepRadius;
      final rawStepProgress = currentPercent * stepCount;

      final stepItems = List.generate(stepCount, (i) {
        final double stepProgress = stepFillMode == ProgressStepFill.immediately
            ? (rawStepProgress >= i + 1 || (rawStepProgress - i) >= 0.999
                ? 1.0
                : 0.0)
            : (rawStepProgress - i).clamp(0.0, 1.0);
        final stepActiveColor =
            (widget.strokeColor != null && widget.strokeColor!.isNotEmpty)
                ? widget.strokeColor![i % widget.strokeColor!.length]
                : fill;

        Widget stepContent = SizedBox.expand(
          child: ColoredBox(
            color: widget.trailColor ?? r.remainingColor,
          ),
        );

        if (stepProgress > 0) {
          stepContent = Stack(
            fit: StackFit.expand,
            children: [
              stepContent,
              FractionallySizedBox(
                alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                widthFactor: stepProgress,
                child: SizedBox.expand(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.gradient == null ? stepActiveColor : null,
                      gradient: widget.gradient,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final BorderRadius stepBorderRadius;
        if (stepRadiusFn != null) {
          final bool? isFirst =
              (i == 0) ? true : ((i == stepCount - 1) ? false : null);
          stepBorderRadius =
              stepRadiusFn(isFirst, stepProgress).toBorderRadius();
        } else {
          stepBorderRadius = fallbackRadius;
        }

        final Widget clippedStep = Padding(
          padding: EdgeInsets.only(
            right: isRtl ? 0 : (i == stepCount - 1 ? 0 : stepGap),
            left: isRtl ? (i == stepCount - 1 ? 0 : stepGap) : 0,
          ),
          child: ClipRRect(
            borderRadius: stepBorderRadius,
            child: SizedBox(
              width: resSize.hasFixedStepWidth ? resSize.width : null,
              height: stroke,
              child: stepContent,
            ),
          ),
        );

        return resSize.hasFixedStepWidth
            ? clippedStep
            : Expanded(child: clippedStep);
      });

      bar = Row(
        textDirection: dir,
        mainAxisSize:
            resSize.hasFixedStepWidth ? MainAxisSize.min : MainAxisSize.max,
        children: stepItems,
      );
    } else {
      bar = ClipRRect(
        borderRadius: fallbackRadius,
        child: Container(
          height: stroke,
          color: widget.trailColor ?? r.remainingColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment:
                      isRtl ? Alignment.centerRight : Alignment.centerLeft,
                  widthFactor: currentPercent,
                  child: SizedBox.expand(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.gradient == null ? fill : null,
                        gradient: widget.gradient,
                        borderRadius: fallbackRadius,
                      ),
                    ),
                  ),
                ),
              ),
              if (isInner && widget.showInfo)
                pos.align == PercentInfoAlign.follow
                    ? Positioned.fill(
                        child: LayoutBuilder(
                          builder: (_, constraints) {
                            final fullWidth = constraints.maxWidth;
                            final fillWidth = fullWidth * currentPercent;
                            const pad = 8.0;
                            const estInfoWidth = 36.0;
                            // Starts at left edge (pad) like 'start', then
                            // follows the tip once the fill is wide enough.
                            final leadingPad = (fillWidth - estInfoWidth - pad)
                                .clamp(pad, fullWidth - estInfoWidth - pad);
                            return Padding(
                              padding: EdgeInsets.only(
                                left: isRtl ? 0 : leadingPad,
                                right: isRtl ? leadingPad : 0,
                              ),
                              child: Align(
                                alignment: isRtl
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: _buildFollowInnerInfoWidget(
                                  token,
                                  currentPercent,
                                  isRtl,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildInnerInfoWidget(
                            token,
                            currentPercent,
                            pos.align,
                            isRtl,
                          ),
                        ),
                      ),
            ],
          ),
        ),
      );
    }

    final explicit = widget.size;
    final hasCustomWidth =
        explicit is ExplicitSize && !resSize.hasFixedStepWidth;
    final barWidget = hasCustomWidth
        ? SizedBox(width: explicit.width, child: bar)
        : (resSize.hasFixedStepWidth ? bar : Expanded(child: bar));

    if (!widget.showInfo || isInner) {
      return Row(
        textDirection: dir,
        mainAxisSize: (hasCustomWidth || resSize.hasFixedStepWidth)
            ? MainAxisSize.min
            : MainAxisSize.max,
        children: [barWidget],
      );
    }

    final infoWidget = _buildOuterInfoWidget(token, currentPercent, isRtl);

    if (pos.align == PercentInfoAlign.start) {
      return Row(
        textDirection: dir,
        mainAxisSize: (hasCustomWidth || resSize.hasFixedStepWidth)
            ? MainAxisSize.min
            : MainAxisSize.max,
        children: [
          infoWidget,
          SizedBox(width: token.sizeXS),
          barWidget,
        ],
      );
    }

    if (pos.align == PercentInfoAlign.center) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            textDirection: dir,
            mainAxisSize: (hasCustomWidth || resSize.hasFixedStepWidth)
                ? MainAxisSize.min
                : MainAxisSize.max,
            children: [barWidget],
          ),
          SizedBox(height: token.sizeXXS),
          infoWidget,
        ],
      );
    }

    if (pos.align == PercentInfoAlign.follow) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: dir,
            mainAxisSize: (hasCustomWidth || resSize.hasFixedStepWidth)
                ? MainAxisSize.min
                : MainAxisSize.max,
            children: [barWidget],
          ),
          SizedBox(height: token.sizeXXS),
          // Starts at left edge, then follows the tip.
          LayoutBuilder(
            builder: (_, constraints) {
              final fullWidth = constraints.maxWidth;
              final fillWidth = fullWidth * currentPercent;
              const estInfoWidth = 36.0;
              final leadingPad = (fillWidth - estInfoWidth)
                  .clamp(0.0, fullWidth - estInfoWidth);
              return Padding(
                padding: EdgeInsets.only(
                  left: isRtl ? 0 : leadingPad,
                  right: isRtl ? leadingPad : 0,
                ),
                child: Align(
                  alignment:
                      isRtl ? Alignment.centerRight : Alignment.centerLeft,
                  child: infoWidget,
                ),
              );
            },
          ),
        ],
      );
    }

    return Row(
      textDirection: dir,
      mainAxisSize: (hasCustomWidth || resSize.hasFixedStepWidth)
          ? MainAxisSize.min
          : MainAxisSize.max,
      children: [
        barWidget,
        SizedBox(width: token.sizeXS),
        infoWidget,
      ],
    );
  }

  Alignment _resolveInnerAlignment(
    PercentInfoAlign align,
    double p,
    bool isRtl,
  ) {
    switch (align) {
      case PercentInfoAlign.start:
        return isRtl ? Alignment.centerRight : Alignment.centerLeft;
      case PercentInfoAlign.center:
        return Alignment.center;
      case PercentInfoAlign.end:
        return isRtl ? Alignment.centerLeft : Alignment.centerRight;
      case PercentInfoAlign.follow:
        final factor = isRtl ? (1.0 - 2 * p) : (2 * p - 1.0);
        return Alignment(factor.clamp(-1.0, 1.0), 0.0);
    }
  }

  Widget _buildInnerInfoWidget(
    Token token,
    double p,
    PercentInfoAlign align,
    bool isRtl,
  ) {
    if (widget.child != null) return widget.child!;
    final showBadge = widget.format == null && _isComplete(p);
    final textAlignment = _resolveInnerAlignment(align, p, isRtl);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: textAlignment,
        children: [
          // ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: showBadge
          ? KeyedSubtree(
              key: const ValueKey('badge'),
              child: Align(
                alignment: textAlignment,
                child: StatusIcon(type: _effectiveStatus(p), token: token),
              ),
            )
          : KeyedSubtree(
              key: const ValueKey('text'),
              child: Align(
                alignment: textAlignment,
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: const Color(0xFFFFFFFF),
                    fontSize: token.fontSizeSM,
                    fontWeight: FontWeight.w600,
                    fontFamily: token.fontFamily,
                    fontFamilyFallback: token.fontFamilyFallback,
                    height: 1.0,
                    decoration: TextDecoration.none,
                  ),
                  child: _label(p),
                ),
              ),
            ),
    );
  }

  /// Inner info widget for [PercentInfoAlign.follow].
  /// Both children use [ConstrainedBox] with the same [minWidth] so they
  /// occupy identical space, preventing horizontal shift on swap.
  Widget _buildFollowInnerInfoWidget(Token token, double p, bool isRtl) {
    if (widget.child != null) return widget.child!;
    final showBadge = widget.format == null && _isComplete(p);
    final edgeAlign = isRtl ? Alignment.centerRight : Alignment.centerLeft;
    const minInfoWidth = 36.0;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: edgeAlign,
        children: [
          if (currentChild != null) currentChild,
        ],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: showBadge
          ? KeyedSubtree(
              key: const ValueKey('badge'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: minInfoWidth),
                child: SizedBox.square(
                  dimension: token.fontSizeSM,
                  child: FittedBox(
                    child: StatusIcon(type: _effectiveStatus(p), token: token),
                  ),
                ),
              ),
            )
          : KeyedSubtree(
              key: const ValueKey('text'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: minInfoWidth),
                child: DefaultTextStyle(
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    color: const Color(0xFFFFFFFF),
                    fontSize: token.fontSizeSM,
                    fontWeight: FontWeight.w600,
                    fontFamily: token.fontFamily,
                    fontFamilyFallback: token.fontFamilyFallback,
                    height: 1.0,
                    decoration: TextDecoration.none,
                  ),
                  child: _label(p),
                ),
              ),
            ),
    );
  }

  Widget _buildOuterInfoWidget(
    Token token,
    double currentPercent,
    bool isRtl,
  ) {
    if (widget.child != null) return widget.child!;
    final showBadge = widget.format == null && _isComplete(currentPercent);
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 36,
        maxHeight: token.fontSizeLG,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
          children: [
            // ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: showBadge
            ? KeyedSubtree(
                key: const ValueKey('badge'),
                child: Align(
                  alignment:
                      isRtl ? Alignment.centerRight : Alignment.centerLeft,
                  child: _lineBadge(token, currentPercent),
                ),
              )
            : KeyedSubtree(
                key: const ValueKey('text'),
                child: Align(
                  alignment:
                      isRtl ? Alignment.centerRight : Alignment.centerLeft,
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: token.colorText,
                      fontSize: token.fontSize,
                      fontFamily: token.fontFamily,
                      fontFamilyFallback: token.fontFamilyFallback,
                      height: 1.0,
                      decoration: TextDecoration.none,
                    ),
                    child: _label(currentPercent),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _circle(Token token, _ResolvedProgressToken r, double currentPercent) {
    final effectiveSize = widget.size ?? SoftSize.middle;
    final resSize = _resolveSize(token, r);
    final defaultStroke = effectiveSize == SoftSize.small ? 4.0 : 6.0;
    final stroke = widget.strokeWidth ??
        (effectiveSize is ExplicitSquareSize
            ? effectiveSize.dimension * 0.1
            : defaultStroke);
    final fill = _fill(token, currentPercent);
    final sz = resSize.width;
    final cap = _effectiveCap;

    return SizedBox(
      width: sz,
      height: sz,
      child: CustomPaint(
        painter: _CirclePainter(
          percent: currentPercent,
          fill: fill,
          trail: widget.trailColor ?? r.remainingColor,
          strokeWidth: stroke,
          gradient: widget.gradient,
          strokeColor: widget.strokeColor,
          steps: widget.steps,
          type: widget.type,
          gapDegree: widget.gapDegree,
          gapPlacement: widget.gapPlacement,
          strokeLinecap: cap,
        ),
        // The child owns the middle of the ring; the percentage label only
        // gets it when there is no child.
        child: widget.child != null
            ? Center(child: widget.child)
            : (widget.showInfo
                ? Center(child: _circleInfo(token, fill, currentPercent))
                : null),
      ),
    );
  }

  Widget _lineBadge(Token token, double p) {
    return StatusIcon(type: _effectiveStatus(p), token: token);
  }

  Widget _circleInfo(Token token, Color fill, double p) {
    final showBadge = widget.format == null && _isComplete(p);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: showBadge
          ? KeyedSubtree(
              key: const ValueKey('complete'),
              child: CustomPaint(
                size: Size.square(token.fontSizeXL + 4),
                painter: _ResultGlyphPainter(
                  success: _effectiveStatus(p) == StatusType.success,
                  color: fill,
                ),
              ),
            )
          : KeyedSubtree(
              key: const ValueKey('text'),
              child: DefaultTextStyle(
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: token.colorText,
                  fontSize: widget.size == SoftSize.small
                      ? token.fontSizeSM
                      : token.fontSizeLG,
                  fontFamily: token.fontFamily,
                  fontFamilyFallback: token.fontFamilyFallback,
                  decoration: TextDecoration.none,
                ),
                child: _label(p),
              ),
            ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  _CirclePainter({
    required this.percent,
    required this.fill,
    required this.trail,
    required this.strokeWidth,
    this.gradient,
    this.strokeColor,
    this.steps,
    required this.type,
    required this.gapDegree,
    required this.gapPlacement,
    required this.strokeLinecap,
  });

  final double percent;
  final Color fill;
  final Color trail;
  final double strokeWidth;
  final Gradient? gradient;
  final List<Color>? strokeColor;
  final ProgressSteps? steps;
  final ProgressType type;
  final double gapDegree;
  final GapPlacement gapPlacement;
  final StrokeCap strokeLinecap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.width - strokeWidth) / 2;
    if (radius <= 0) return;
    final circleRect = Rect.fromCircle(center: center, radius: radius);

    final isDashboard = type == ProgressType.dashboard;
    final gapRad = isDashboard ? (gapDegree * math.pi / 180) : 0.0;
    final totalAngle = (math.pi * 2) - gapRad;

    final centerAngle = switch (gapPlacement) {
      GapPlacement.top => -math.pi / 2,
      GapPlacement.left => math.pi,
      GapPlacement.right => 0.0,
      GapPlacement.bottom => math.pi / 2,
    };

    final startAngle = isDashboard ? (centerAngle + gapRad / 2) : -math.pi / 2;

    if (steps != null && steps!.count > 1) {
      _paintSteps(canvas, circleRect, startAngle, totalAngle);
    } else {
      _paintContinuous(canvas, circleRect, startAngle, totalAngle);
    }
  }

  void _paintSteps(
    Canvas canvas,
    Rect circleRect,
    double startAngle,
    double totalAngle,
  ) {
    final count = steps!.count;
    final gap = steps!.gap;
    final stepAngle = totalAngle / count;
    final radius = circleRect.width / 2;
    final gapAngle = gap <= 0 ? 0.0 : math.min(stepAngle * 0.45, gap / radius);
    final arcAngle = stepAngle - gapAngle;

    final rawStepProgress = percent * count;

    for (int i = 0; i < count; i++) {
      final stepStart = startAngle + i * stepAngle + gapAngle / 2;

      final trailPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = strokeLinecap
        ..color = trail;

      canvas.drawArc(circleRect, stepStart, arcAngle, false, trailPaint);

      final double stepProgress = (steps?.fill == ProgressStepFill.immediately)
          ? (rawStepProgress >= i + 1 || (rawStepProgress - i) >= 0.999
              ? 1.0
              : 0.0)
          : (rawStepProgress - i).clamp(0.0, 1.0);

      if (stepProgress > 0) {
        final stepActiveColor = (strokeColor != null && strokeColor!.isNotEmpty)
            ? strokeColor![i % strokeColor!.length]
            : fill;

        final activePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = strokeLinecap;

        if (gradient != null) {
          activePaint.shader = gradient!.createShader(circleRect);
        } else {
          activePaint.color = stepActiveColor;
        }

        final activeSweep = arcAngle * stepProgress;
        canvas.drawArc(circleRect, stepStart, activeSweep, false, activePaint);
      }
    }
  }

  void _paintContinuous(
    Canvas canvas,
    Rect circleRect,
    double startAngle,
    double totalAngle,
  ) {
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeLinecap
      ..color = trail;

    canvas.drawArc(circleRect, startAngle, totalAngle, false, base);

    if (percent > 0.001) {
      final sweepAngle = totalAngle * percent;
      if (sweepAngle > 0.001) {
        final fillPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = strokeLinecap;

        if (gradient != null) {
          fillPaint.shader = gradient!.createShader(circleRect);
        } else {
          fillPaint.color = fill;
        }

        canvas.drawArc(
          circleRect,
          startAngle,
          sweepAngle,
          false,
          fillPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CirclePainter old) =>
      old.percent != percent ||
      old.fill != fill ||
      old.trail != trail ||
      old.strokeWidth != strokeWidth ||
      old.gradient != gradient ||
      old.strokeColor != strokeColor ||
      old.steps != steps ||
      old.type != type ||
      old.gapDegree != gapDegree ||
      old.gapPlacement != gapPlacement ||
      old.strokeLinecap != strokeLinecap;
}

class _ResultGlyphPainter extends CustomPainter {
  _ResultGlyphPainter({required this.success, required this.color});

  final bool success;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(2.0, size.width * 0.11)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (success) {
      canvas.drawPath(
        Path()
          ..moveTo(size.width * 0.2, size.height * 0.55)
          ..lineTo(size.width * 0.42, size.height * 0.72)
          ..lineTo(size.width * 0.8, size.height * 0.3),
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(size.width * 0.25, size.height * 0.25),
        Offset(size.width * 0.75, size.height * 0.75),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * 0.75, size.height * 0.25),
        Offset(size.width * 0.25, size.height * 0.75),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ResultGlyphPainter old) =>
      old.success != success || old.color != color;
}

class _ProgressResolvedSize {
  const _ProgressResolvedSize({
    required this.width,
    required this.height,
    this.hasFixedStepWidth = false,
  });

  final double width;
  final double height;
  final bool hasFixedStepWidth;
}
