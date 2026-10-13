import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/size_resolver.dart';
import '../data_display/tooltip.dart';

/// Per-component design tokens for [Rate].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(rate: RateToken(...)))`, or per instance via
/// [Rate.token].
@immutable
class RateToken {
  /// Creates a [RateToken].
  const RateToken({
    this.starColor,
    this.starBg,
    this.gap,
    this.hoverScale,
  });

  /// A lit star.
  final Color? starColor;

  /// A star not yet reached.
  final Color? starBg;

  /// Space between two stars.
  final double? gap;

  /// How much larger the star under the pointer grows.
  final double? hoverScale;

  _ResolvedRateToken _resolve(Token t) => _ResolvedRateToken(
        starColor: starColor ?? const Color(0xFFFADB14),
        starBg: starBg ?? t.colorFillSecondary,
        gap: gap ?? t.sizeXS,
        hoverScale: hoverScale ?? 1.1,
      );

  /// This one with [other]'s fields laid over it, one field at a time.
  RateToken merge(RateToken other) => RateToken(
        starColor: other.starColor ?? starColor,
        starBg: other.starBg ?? starBg,
        gap: other.gap ?? gap,
        hoverScale: other.hoverScale ?? hoverScale,
      );
}

@immutable
class _ResolvedRateToken {
  const _ResolvedRateToken({
    required this.starColor,
    required this.starBg,
    required this.gap,
    required this.hoverScale,
  });

  final Color starColor;
  final Color starBg;
  final double gap;
  final double hoverScale;
}

/// Defaults for every [Rate] under a `ConfigProvider`.
@immutable
class RateDefaults {
  /// Creates a [RateDefaults].
  const RateDefaults({this.allowHalf, this.allowClear});

  /// Whether a rating may stop at half a star.
  final bool? allowHalf;

  /// Whether choosing the rating already given takes it back.
  final bool? allowClear;

  /// This one with [other]'s fields laid over it, one field at a time.
  RateDefaults merge(RateDefaults other) => RateDefaults(
        allowHalf: other.allowHalf ?? allowHalf,
        allowClear: other.allowClear ?? allowClear,
      );
}

/// A rating in stars: how a reader marks a film, a meal, an answer.
///
/// ```dart
/// Rate(
///   value: stars,
///   onChanged: (v) => setState(() => stars = v),
///   semanticsLabel: 'Rating',
/// )
/// ```
///
/// A tap on a star gives that many; with [allowHalf], a tap on a star's
/// first half gives half of it. The pointer resting on a star shows what a
/// tap would give before it is given. The arrow keys move the rating by a
/// star, or by half of one.
class Rate extends StatefulWidget {
  /// Creates a [Rate].
  const Rate({
    super.key,
    this.count = 5,
    this.value,
    this.defaultValue = 0,
    this.onChanged,
    this.onHoverChanged,
    this.allowHalf,
    this.allowClear,
    this.disabled = false,
    this.readOnly = false,
    this.character,
    this.tooltips,
    this.size,
    this.autofocus = false,
    this.focusNode,
    this.semanticsLabel,
    this.token,
  }) : assert(count > 0, 'a Rate needs at least one star');

  /// How many stars.
  final int count;

  /// The rating, held from outside. Null lets the stars keep their own,
  /// starting from [defaultValue].
  final double? value;

  /// The rating the stars start with, when [value] is null.
  final double defaultValue;

  /// Called with the new rating when a star is chosen or a key moves it.
  final ValueChanged<double>? onChanged;

  /// Called with what a tap would give as the pointer moves over the stars,
  /// and with null as it leaves them.
  final ValueChanged<double?>? onHoverChanged;

  /// Whether a rating may stop at half a star. Defaults to no.
  final bool? allowHalf;

  /// Whether choosing the rating already given takes it back to nothing.
  /// Defaults to yes.
  final bool? allowClear;

  /// Greys the stars out; they take nothing.
  final bool disabled;

  /// Shows the rating without letting it be changed, in full colour.
  final bool readOnly;

  /// What each star is drawn as, in place of a star: a heart, a letter. Called
  /// with the star's index; the colour comes from an `IconTheme` and a
  /// `DefaultTextStyle` around it, so an `Icon` or a `Text` takes it.
  final Widget Function(int index)? character;

  /// A word for each star, shown while the pointer rests on it: "terrible",
  /// "bad", "normal", "good", "wonderful".
  final List<String>? tooltips;

  /// How big a star is: [SoftSize.small], [SoftSize.middle] (the default),
  /// [SoftSize.large], or a measurement of your own.
  final ControlSize? size;

  /// Whether the stars take the focus as they appear.
  final bool autofocus;

  /// The stars' focus, for moving it from outside.
  final FocusNode? focusNode;

  /// What a screen reader calls the rating: "Rating", "How was your stay".
  final String? semanticsLabel;

  /// Per-instance token overrides.
  final RateToken? token;

  @override
  State<Rate> createState() => _RateState();
}

class _RateState extends State<Rate> {
  late double _own = widget.defaultValue;
  double? _hover;
  bool _focused = false;

  double get _value => (widget.value ?? _own).clamp(0, widget.count.toDouble());

  RateDefaults? get _defaults =>
      ConfigProvider.defaultsOf<RateDefaults>(context);
  bool get _half => widget.allowHalf ?? _defaults?.allowHalf ?? false;
  bool get _clearable => widget.allowClear ?? _defaults?.allowClear ?? true;
  bool get _takes => !widget.disabled && !widget.readOnly;

  void _set(double next) {
    if (!_takes) return;
    final clamped = next.clamp(0, widget.count.toDouble()).toDouble();
    if (widget.value == null) setState(() => _own = clamped);
    widget.onChanged?.call(clamped);
  }

  void _choose(double v) {
    _set(_clearable && v == _value ? 0 : v);
    // The rating now stands where the pointer is; showing it again as a
    // preview would hide that a second tap clears it.
    _setHover(null);
  }

  void _setHover(double? v) {
    if (v == _hover) return;
    setState(() => _hover = v);
    widget.onHoverChanged?.call(v);
  }

  double get _step => _half ? 0.5 : 1;

  /// What the pointer at [x] across a star of width [w] would give.
  double _at(int index, double x, double w, bool rtl) {
    final along = rtl ? w - x : x;
    if (_half && along < w / 2) return index + 0.5;
    return index + 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<RateToken>(context) ??
            const RateToken())
        ._resolve(t);
    final side = (widget.size ??
            ConfigProvider.componentSizeOf(context) ??
            SoftSize.middle)
        .resolve1D(
      small: t.fontSizeLG,
      middle: t.fontSizeXL,
      large: t.controlHeightSM,
    );
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final shown = _takes ? (_hover ?? _value) : _value;
    final hoveredIndex = _hover == null ? null : _hover!.ceil() - 1;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    Widget glyph(int i, Color color) => IconTheme.merge(
          data: IconThemeData(color: color, size: side),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: color,
              fontSize: side,
              height: 1,
              fontFamily: t.fontFamily,
              fontFamilyFallback: t.fontFamilyFallback,
              decoration: TextDecoration.none,
            ),
            child: SizedBox.square(
              dimension: side,
              child: Center(
                child: widget.character?.call(i) ??
                    CustomPaint(
                      size: Size.square(side),
                      painter: _StarPainter(color),
                    ),
              ),
            ),
          ),
        );

    Widget star(int i) {
      // How much of this star is lit: all of it, half, or none.
      final lit = (shown - i).clamp(0.0, 1.0);
      Widget body = Stack(
        children: [
          glyph(i, r.starBg),
          if (lit > 0)
            ClipRect(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: lit,
                child: glyph(i, r.starColor),
              ),
            ),
        ],
      );
      body = AnimatedScale(
        scale: _takes && hoveredIndex == i ? r.hoverScale : 1,
        duration: still ? Duration.zero : t.motionDurationMid,
        child: body,
      );
      if (_takes) {
        body = MouseRegion(
          cursor: SystemMouseCursors.click,
          // On arriving as well as on moving: a pointer that comes to rest
          // on a star without moving inside it still shows what it would
          // give.
          onEnter: (e) => _setHover(_at(i, e.localPosition.dx, side, rtl)),
          onHover: (e) => _setHover(_at(i, e.localPosition.dx, side, rtl)),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _choose(_at(i, d.localPosition.dx, side, rtl)),
            child: body,
          ),
        );
      }
      final tip = widget.tooltips;
      if (tip != null && i < tip.length && !widget.disabled) {
        body = Tooltip(message: Text(tip[i]), child: body);
      }
      return Padding(
        padding: EdgeInsetsDirectional.only(
          end: i < widget.count - 1 ? r.gap : 0,
        ),
        child: body,
      );
    }

    final stars = MouseRegion(
      onExit: (_) => _setHover(null),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < widget.count; i++) star(i)],
      ),
    );

    final locale = context.seedLocale;
    String say(double v) => locale.figures(
          '${v == v.roundToDouble() ? v.toInt() : v} / ${widget.count}',
        );
    final up = (_value + _step).clamp(0, widget.count.toDouble()).toDouble();
    final down = (_value - _step).clamp(0, widget.count.toDouble()).toDouble();
    final more =
        rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
    final less =
        rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;

    return Semantics(
      container: true,
      slider: true,
      enabled: !widget.disabled,
      readOnly: widget.readOnly,
      label: widget.semanticsLabel,
      value: say(_value),
      increasedValue: _takes ? say(up) : null,
      decreasedValue: _takes ? say(down) : null,
      onIncrease: _takes ? () => _set(up) : null,
      onDecrease: _takes ? () => _set(down) : null,
      child: FocusableActionDetector(
        enabled: _takes,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        shortcuts: {
          SingleActivator(more): const _RateIntent(1),
          const SingleActivator(LogicalKeyboardKey.arrowUp):
              const _RateIntent(1),
          SingleActivator(less): const _RateIntent(-1),
          const SingleActivator(LogicalKeyboardKey.arrowDown):
              const _RateIntent(-1),
          const SingleActivator(LogicalKeyboardKey.home): const _RateIntent(0),
          const SingleActivator(LogicalKeyboardKey.end): const _RateIntent(2),
        },
        actions: {
          _RateIntent: CallbackAction<_RateIntent>(
            onInvoke: (intent) {
              _set(switch (intent.step) {
                1 => up,
                -1 => down,
                0 => 0,
                _ => widget.count.toDouble(),
              });
              return null;
            },
          ),
        },
        child: ExcludeSemantics(
          child: Opacity(
            opacity: widget.disabled ? 0.5 : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(t.borderRadiusSM),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: t.primary.base.withValues(alpha: 0.12),
                          blurRadius: 0,
                          spreadRadius: t.focusRingWidth,
                        ),
                      ]
                    : null,
              ),
              child: stars,
            ),
          ),
        ),
      ),
    );
  }
}

/// What a key asks of a [Rate]: a step up (1) or down (-1), to nothing (0),
/// or to every star (2).
class _RateIntent extends Intent {
  const _RateIntent(this.step);

  final int step;
}

/// A five-pointed star filling its box, its points slightly rounded.
class _StarPainter extends CustomPainter {
  _StarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final inner = outer * 0.48;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : inner;
      // From the top point, clockwise.
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = c +
          Offset(
            radius * math.cos(angle),
            radius * math.sin(angle) + outer * 0.06,
          );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..strokeJoin = StrokeJoin.round,
    );
    // A thin stroke of the same colour rounds the points a little.
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = outer * 0.12
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}
