import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';

/// The state a standalone [Badge] reports.
///
/// Used with [Badge.status], which draws a small dot and, given [Badge.text],
/// a label beside it — the shape a status line usually takes in a table.
enum BadgeStatus {
  /// Grey. Nothing is happening.
  neutral,

  /// Green — finished, or healthy.
  success,

  /// Blue, with a ring that pulses outward — work still under way.
  processing,

  /// Amber — needs attention.
  warning,

  /// Red — a failure.
  error,
}

/// Which end of its container a [Ribbon] is pinned to.
enum RibbonPlacement {
  /// The leading end — left in a left-to-right layout.
  start,

  /// The trailing end — right in a left-to-right layout. The default.
  end,
}

/// Per-component design tokens for [Badge].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [BadgeToken(...)])`, or per instance via [Badge.token].
@immutable
class BadgeToken {
  /// Creates a [BadgeToken].
  const BadgeToken({
    this.indicatorHeight,
    this.indicatorHeightSM,
    this.dotSize,
    this.statusSize,
    this.fontSize,
    this.bg,
    this.textColor,
    this.ringColor,
  });

  /// Height of the count pill (`indicatorHeight`).
  final double? indicatorHeight;

  /// Height of the count pill at [SoftSize.small] (`indicatorHeightSM`).
  final double? indicatorHeightSM;

  /// Diameter of the standalone dot (`dotSize`).
  final double? dotSize;

  /// Diameter of the status dot (`statusSize`).
  final double? statusSize;

  /// Size of the digits inside the pill (`fontSize`).
  final double? fontSize;

  /// Fill behind the count (`bg`).
  final Color? bg;

  /// Colour of the digits (`textColor`).
  final Color? textColor;

  /// The ring separating the badge from what it sits on (`ringColor`).
  final Color? ringColor;

  _ResolvedBadgeToken _resolve(Token t) => _ResolvedBadgeToken(
        indicatorHeight: indicatorHeight ?? 20,
        indicatorHeightSM: indicatorHeightSM ?? 14,
        dotSize: dotSize ?? 6,
        statusSize: statusSize ?? 6,
        fontSize: fontSize ?? t.fontSizeSM,
        bg: bg ?? t.error.base,
        textColor: textColor ?? const Color(0xFFFFFFFF),
        ringColor: ringColor ?? t.colorBgContainer,
      );
}

@immutable
class _ResolvedBadgeToken {
  const _ResolvedBadgeToken({
    required this.indicatorHeight,
    required this.indicatorHeightSM,
    required this.dotSize,
    required this.statusSize,
    required this.fontSize,
    required this.bg,
    required this.textColor,
    required this.ringColor,
  });

  final double indicatorHeight;
  final double indicatorHeightSM;
  final double dotSize;
  final double statusSize;
  final double fontSize;
  final Color bg;
  final Color textColor;
  final Color ringColor;
}

/// A count or dot pinned to the corner of what it describes.
///
/// ```dart
/// Badge(count: 12, child: const Avatar(child: Text('U')))
/// Badge(dot: true, child: const Icon(Icons.notifications))
/// Badge(status: BadgeStatus.processing, text: const Text('Running'))
/// ```
///
/// With a [child] the badge is pinned to its top trailing corner; without one
/// it stands on its own, which is what a table cell usually wants.
///
/// A count of zero is hidden unless [showZero] says otherwise, so a badge can
/// be left in place while the thing it counts empties out. Anything above
/// [overflowCount] reads as `99+`.
///
/// For a label across a container's corner, see [Ribbon].
class Badge extends StatelessWidget {
  /// Creates a [Badge].
  const Badge({
    super.key,
    this.child,
    this.count,
    this.content,
    this.dot = false,
    this.status,
    this.text,
    this.showZero = false,
    this.overflowCount = 99,
    this.color,
    this.offset = Offset.zero,
    this.size = SoftSize.middle,
    this.title,
    this.token,
  });

  /// What the badge is attached to. Null makes it standalone.
  final Widget? child;

  /// The number to show. Null draws nothing unless [dot] or [status] is set.
  final int? count;

  /// Arbitrary content in place of [count] — an icon, or a word like `new`.
  ///
  /// Takes precedence over [count], and is exempt from [overflowCount] and
  /// [showZero]: whatever it is, it is not a number the badge can reason about.
  final Widget? content;

  /// Draws a bare dot rather than a count.
  final bool dot;

  /// Draws a status dot instead of a count. See [BadgeStatus].
  final BadgeStatus? status;

  /// The label beside a [status] dot.
  final Widget? text;

  /// Whether a [count] of zero is drawn rather than hidden.
  final bool showZero;

  /// The largest number drawn in full; past it the badge reads `99+`.
  final int overflowCount;

  /// Overrides the fill — for [status] as much as for a count.
  final Color? color;

  /// Nudges the badge from the corner it is pinned to. Ignored standalone.
  final Offset offset;

  /// [SoftSize.small] gives a shorter pill. [SoftSize.large] reads as
  /// [SoftSize.middle]; a badge has only the two heights.
  final SoftSize size;

  /// A description of the count for assistive technology.
  ///
  /// Without one the digits are announced as they are drawn, which says `99+`
  /// where `over ninety-nine unread` was meant.
  final String? title;

  /// Per-instance token overrides.
  final BadgeToken? token;

  /// Whether there is anything at all to draw in the corner.
  bool get _hasIndicator {
    if (status != null) return true;
    if (dot) return true;
    if (content != null) return true;
    if (count == null) return false;
    return count != 0 || showZero;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (token ??
            ConfigProvider.componentOf<BadgeToken>(context) ??
            const BadgeToken())
        ._resolve(t);

    if (status != null) return _buildStatus(t, r);

    final indicator = _hasIndicator ? _buildIndicator(t, r) : null;

    if (child == null) return indicator ?? const SizedBox.shrink();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child!,
        if (indicator != null)
          Positioned(
            top: offset.dy,
            right: -offset.dx,
            // Half of the badge hangs off the corner, which is what keeps it
            // reading as attached to the child rather than stacked on it.
            child: FractionalTranslation(
              translation: const Offset(0.5, -0.5),
              child: indicator,
            ),
          ),
      ],
    );
  }

  Widget _buildStatus(Token t, _ResolvedBadgeToken r) {
    final fill = color ?? _statusColor(t, status!);
    final dot = status == BadgeStatus.processing
        ? _ProcessingDot(size: r.statusSize, color: fill)
        : _Dot(size: r.statusSize, color: fill);
    if (text == null) return dot;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        SizedBox(width: t.sizeXS),
        DefaultTextStyle.merge(
          style: TextStyle(color: t.colorText, fontSize: t.fontSize),
          child: text!,
        ),
      ],
    );
  }

  static Color _statusColor(Token t, BadgeStatus status) => switch (status) {
        BadgeStatus.neutral => t.colorTextTertiary,
        BadgeStatus.success => t.success.base,
        BadgeStatus.processing => t.primary.base,
        BadgeStatus.warning => t.warning.base,
        BadgeStatus.error => t.error.base,
      };

  Widget _buildIndicator(Token t, _ResolvedBadgeToken r) {
    final fill = color ?? r.bg;
    final ring = BoxDecoration(
      color: fill,
      shape: BoxShape.circle,
      border: Border.all(color: r.ringColor, width: t.lineWidth),
    );

    if (dot && content == null) {
      return Semantics(
        label: title,
        container: title != null,
        child: Container(
          width: r.dotSize + t.lineWidth * 2,
          height: r.dotSize + t.lineWidth * 2,
          decoration: ring,
        ),
      );
    }

    final height =
        size == SoftSize.small ? r.indicatorHeightSM : r.indicatorHeight;
    final label = content ??
        Text(
          count! > overflowCount ? '$overflowCount+' : '$count',
          style: TextStyle(
            color: r.textColor,
            fontSize: r.fontSize,
            fontWeight: FontWeight.w400,
            height: 1,
          ),
        );

    return Semantics(
      label: title,
      container: title != null,
      // The digits are already spoken by the label when one is given.
      excludeSemantics: title != null,
      child: Container(
        height: height,
        constraints: BoxConstraints(minWidth: height),
        padding: EdgeInsets.symmetric(horizontal: t.sizeXS - 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: r.ringColor, width: t.lineWidth),
        ),
        child: label,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// A dot with a ring that grows out of it and fades, over and over.
///
/// The ring is drawn outside the dot's own box, so a processing badge takes no
/// more room in a row than a still one and nothing shifts when the status
/// changes.
class _ProcessingDot extends StatefulWidget {
  const _ProcessingDot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<_ProcessingDot> createState() => _ProcessingDotState();
}

class _ProcessingDotState extends State<_ProcessingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _Dot(size: widget.size, color: widget.color)),
          Positioned.fill(
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.5, end: 0).animate(_c),
              child: ScaleTransition(
                scale: Tween<double>(begin: 1, end: 2.4).animate(_c),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.color),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-component design tokens for [Ribbon].
@immutable
class RibbonToken {
  /// Creates a [RibbonToken].
  const RibbonToken({this.height, this.fontSize, this.bg, this.textColor});

  /// Height of the band (`height`).
  final double? height;

  /// Size of the text on the band (`fontSize`).
  final double? fontSize;

  /// Fill of the band (`bg`).
  final Color? bg;

  /// Colour of the text on the band (`textColor`).
  final Color? textColor;

  _ResolvedRibbonToken _resolve(Token t) => _ResolvedRibbonToken(
        height: height ?? 22,
        fontSize: fontSize ?? t.fontSize,
        bg: bg ?? t.primary.base,
        textColor: textColor ?? const Color(0xFFFFFFFF),
      );
}

@immutable
class _ResolvedRibbonToken {
  const _ResolvedRibbonToken({
    required this.height,
    required this.fontSize,
    required this.bg,
    required this.textColor,
  });

  final double height;
  final double fontSize;
  final Color bg;
  final Color textColor;
}

/// A label banded across the top corner of what it describes.
///
/// ```dart
/// Ribbon(
///   text: const Text('Hot'),
///   child: Card(child: const Text('...')),
/// )
/// ```
///
/// Kept apart from [Badge] rather than folded in as a constructor: the two
/// share an idea but not a single property. A ribbon has no count, no overflow
/// and no dot; a badge has no placement and no corner fold.
class Ribbon extends StatelessWidget {
  /// Creates a [Ribbon].
  const Ribbon({
    super.key,
    required this.child,
    this.text,
    this.color,
    this.placement = RibbonPlacement.end,
    this.token,
  });

  /// What the ribbon is draped over.
  final Widget child;

  /// What the band says.
  final Widget? text;

  /// Overrides the band's fill. The fold beneath it is darkened to match.
  final Color? color;

  /// Which corner the band runs off. Defaults to [RibbonPlacement.end].
  final RibbonPlacement placement;

  /// Per-instance token overrides.
  final RibbonToken? token;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (token ??
            ConfigProvider.componentOf<RibbonToken>(context) ??
            const RibbonToken())
        ._resolve(t);
    final fill = color ?? r.bg;
    final atEnd = placement == RibbonPlacement.end;
    final corner = Radius.circular(t.borderRadiusSM);

    final band = Container(
      height: r.height,
      padding: EdgeInsets.symmetric(horizontal: t.sizeXS),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.only(
          topLeft: corner,
          bottomLeft: atEnd ? corner : Radius.zero,
          topRight: corner,
          bottomRight: atEnd ? Radius.zero : corner,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: r.textColor, fontSize: r.fontSize, height: 1),
        child: text ?? const SizedBox.shrink(),
      ),
    );

    // The fold: a small triangle tucked under the band's outer end, dark
    // enough to read as the band turning the corner rather than a second
    // shape. Half the height, which is what keeps it a fold and not a tail.
    final fold = CustomPaint(
      size: Size(t.sizeXS, r.height / 2),
      painter: _RibbonFoldPainter(color: fill, atEnd: atEnd),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: t.sizeXS,
          left: atEnd ? null : -t.sizeXS,
          right: atEnd ? -t.sizeXS : null,
          child: Column(
            crossAxisAlignment:
                atEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [band, fold],
          ),
        ),
      ],
    );
  }
}

class _RibbonFoldPainter extends CustomPainter {
  const _RibbonFoldPainter({required this.color, required this.atEnd});

  final Color color;
  final bool atEnd;

  @override
  void paint(Canvas canvas, Size size) {
    // A quarter of the way to black reads as shadow on every hue we ship,
    // where a fixed grey would go muddy on the darker ones.
    final shade = Color.lerp(color, const Color(0xFF000000), 0.25) ?? color;
    final path = Path();
    if (atEnd) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(0, size.height)
        ..close();
    } else {
      path
        ..moveTo(size.width, 0)
        ..lineTo(0, 0)
        ..lineTo(size.width, size.height)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = shade);
  }

  @override
  bool shouldRepaint(_RibbonFoldPainter old) =>
      old.color != color || old.atEnd != atEnd;
}
