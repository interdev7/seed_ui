import 'package:flutter/widgets.dart';

import '../../l10n/seed_localizations.dart';
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

    // Standalone there is nothing to hang a vanishing badge off, and an empty
    // one must take no room at all, so it simply is not built.
    if (child == null) {
      return _hasIndicator
          ? _buildIndicator(t, r, context.seedLocale)
          : const SizedBox.shrink();
    }

    // Pinned to a child it is kept mounted and scaled away instead: a count
    // reaching zero should retreat into the corner it came from rather than
    // blink out. Nothing is built for a badge that never had anything to say.
    final indicator = count != null || dot || content != null
        ? _Vanishing(
            visible: _hasIndicator,
            duration: t.motionDurationSlow,
            // An overshoot on the way in, so the badge arrives with a small
            // pop rather than easing politely into place.
            curve: const Cubic(0.12, 0.4, 0.29, 1.46),
            reverseCurve: t.motionEaseInOut,
            child: _buildIndicator(t, r, context.seedLocale),
          )
        : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child!,
        if (indicator != null)
          PositionedDirectional(
            top: offset.dy,
            // The trailing corner, not the right one: in a right-to-left
            // layout the badge belongs on the left of what it marks.
            end: -offset.dx,
            // Half of the badge hangs off the corner, which is what keeps it
            // reading as attached to the child rather than stacked on it.
            // Outwards, so the direction decides the sign: a fixed half-width
            // to the right would push the badge into the child in a
            // right-to-left layout instead of off it.
            child: FractionalTranslation(
              translation: Offset(
                Directionality.of(context) == TextDirection.rtl ? -0.5 : 0.5,
                -0.5,
              ),
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

  Widget _buildIndicator(
    Token t,
    _ResolvedBadgeToken r,
    SeedLocalizations l,
  ) {
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
    final style = TextStyle(
      color: r.textColor,
      fontSize: r.fontSize,
      fontWeight: FontWeight.w400,
      // No forced line height. Latin figures sit squarely in a box of exactly
      // the font size, having neither ascender nor descender, but Arabic-Indic
      // ones are fitted to their own metrics and a box squeezed to the font
      // size pushes them up out of centre. The font is left to say how tall a
      // line is, and the reel is measured against that.
    );
    // Content stands alone: it is offered without a count as readily as with
    // one, so there may be no number here to render at all.
    final n = count;
    final text =
        n == null ? null : (n > overflowCount ? '$overflowCount+' : '$n');
    // Only a plain integer rolls. Past the overflow the badge says `99+`,
    // which is not a number going anywhere.
    final rolls =
        text != null && text.codeUnits.every((c) => c >= 0x30 && c <= 0x39);
    final label = content ??
        (rolls
            ? _ScrollNumber(count: n!, text: text, style: style)
            : Text(l.figures(text ?? ''), style: style));

    return Semantics(
      label: title,
      container: title != null,
      // The digits are already spoken by the label when one is given.
      excludeSemantics: title != null,
      // The padding eases rather than appearing whole the moment a second
      // character does — that step is what made the badge hop as the count
      // passed nine. Animating the pill's own box instead would clip it: a box
      // that animates its size lays the child out at the final size and cuts
      // away what does not fit yet, so the new figure and the rounded end came
      // in shaved. Nothing is clipped here. The figures ease inside, the
      // padding eases around them, and between them they carry the width.
      child: AnimatedContainer(
        duration: t.motionDurationMid,
        curve: t.motionEaseInOut,
        height: height,
        constraints: BoxConstraints(minWidth: height),
        // A single character keeps the pill a circle. Padding is what turns
        // it into a lozenge, so it is added only once there is a second
        // character needing the room.
        padding: content != null || (text?.length ?? 0) > 1
            ? EdgeInsets.symmetric(horizontal: t.sizeXS - 2)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(height / 2),
          // The ring sits outside the pill rather than being a border, which
          // would eat into the height the tokens name and leave the badge
          // shorter than it asked to be.
          boxShadow: [
            BoxShadow(color: r.ringColor, spreadRadius: t.lineWidth),
          ],
        ),
        // Centred with a factor of one rather than through the container's
        // alignment: a container told to align its child takes all the width
        // it is offered, which left a standalone badge as wide as its row.
        child: Center(widthFactor: 1, heightFactor: 1, child: label),
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
    // Which physical side the band runs off. [placement] names a reading end,
    // and the two agree only in a left-to-right layout — so this is worked out
    // once, and everything below is placed physically against it. Mixing the
    // two is what broke the ribbon when the direction turned: the corners were
    // physical while the column's own alignment was directional, so they
    // disagreed and the band came apart.
    final onRight = (placement == RibbonPlacement.end) !=
        (Directionality.of(context) == TextDirection.rtl);
    final corner = Radius.circular(t.borderRadiusSM);

    final band = Container(
      height: r.height,
      padding: EdgeInsets.symmetric(horizontal: t.sizeXS),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        // Square where the band meets the fold; rounded everywhere else.
        borderRadius: BorderRadius.only(
          topLeft: corner,
          topRight: corner,
          bottomLeft: onRight ? corner : Radius.zero,
          bottomRight: onRight ? Radius.zero : corner,
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
      painter: _RibbonFoldPainter(color: fill, onRight: onRight),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: t.sizeXS,
          left: onRight ? null : -t.sizeXS,
          right: onRight ? -t.sizeXS : null,
          // Each primitive is given the kind of value it expects. The stack
          // offset, the corners and the fold's own shape are physical, since
          // they are worked out from [onRight]; this alignment is directional,
          // because CrossAxisAlignment already means leading and trailing, and
          // that is exactly what [placement] names. Handing it a physical side
          // is what sent the fold to the opposite end from its band.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: placement == RibbonPlacement.end
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [band, fold],
          ),
        ),
      ],
    );
  }
}

class _RibbonFoldPainter extends CustomPainter {
  const _RibbonFoldPainter({required this.color, required this.onRight});

  final Color color;

  /// Whether the band runs off the right of what it is draped over.
  final bool onRight;

  @override
  void paint(Canvas canvas, Size size) {
    // A quarter of the way to black reads as shadow on every hue we ship,
    // where a fixed grey would go muddy on the darker ones.
    final shade = Color.lerp(color, const Color(0xFF000000), 0.25) ?? color;
    final path = Path();
    if (onRight) {
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
      old.color != color || old.onRight != onRight;
}

/// A count whose digits roll into place rather than being swapped out.
///
/// Each place is its own reel, so 39 to 40 rolls the units from 9 round to 0
/// while the tens move 3 to 4 — the two travel together, as a counter does.
class _ScrollNumber extends StatefulWidget {
  const _ScrollNumber({
    required this.count,
    required this.text,
    required this.style,
  });

  /// The number itself, which says which way the reels turn.
  final int count;

  /// What is actually drawn. Not always the number: past the overflow it
  /// carries a `+`, and that character does not roll.
  final String text;

  final TextStyle style;

  @override
  State<_ScrollNumber> createState() => _ScrollNumberState();
}

class _ScrollNumberState extends State<_ScrollNumber> {
  /// Up for a count that grew, down for one that shrank. Held rather than
  /// derived on the spot because a rebuild for any other reason — a theme
  /// change mid-roll — must not reverse a reel that is already turning.
  int _direction = 1;

  @override
  void didUpdateWidget(_ScrollNumber old) {
    super.didUpdateWidget(old);
    if (widget.count != old.count) {
      _direction = widget.count > old.count ? 1 : -1;
    }
  }

  /// The box every reel is given: the widest and tallest of the ten glyphs
  /// this language actually writes its numbers with.
  ///
  /// Measured from those glyphs rather than from `0`–`9`, because they are not
  /// always the same characters. Arabic writes `٠`–`٩`, whose advance widths
  /// and vertical extents are its own: a cell sized to the Latin figures
  /// leaves them off-centre in it, and a line box assumed to be exactly the
  /// font size — true of Latin digits, which have no descenders — clips them.
  ///
  /// Reels sit in a row, so a reel sized to whatever digit it happens to be
  /// showing would change width as it turns and shove its neighbours sideways.
  /// A fixed cell makes each place independent, which is what a counter is.
  ({double width, double height}) _metrics(
    BuildContext context,
    TextStyle style,
    SeedLocalizations l,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    var width = 0.0;
    var height = 0.0;
    for (var d = 0; d <= 9; d++) {
      final painter = TextPainter(
        text: TextSpan(text: l.digit(d), style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      if (painter.width > width) width = painter.width;
      if (painter.height > height) height = painter.height;
      painter.dispose();
    }
    return (width: width, height: height);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final l = context.seedLocale;
    final m = _metrics(context, widget.style, l);

    // Only the figures. The pill's padding eases separately, in the badge, so
    // that nothing here has to be clipped while the width changes.
    return AnimatedSize(
      duration: t.motionDurationMid,
      curve: t.motionEaseInOut,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, ch) in widget.text.characters.indexed)
            if (_digit(ch) case final d?)
              _Reel(
                // Keyed by place, counted from the right: the units must stay
                // the same reel when a number grows a digit, or 9 to 10 would
                // hand the units reel's 9 to the tens and roll both wrongly.
                key: ValueKey(widget.text.length - i),
                digit: d,
                direction: _direction,
                slot: m.height,
                cell: m.width,
                digits: l,
                style: widget.style,
              )
            else
              Text(ch, style: widget.style),
        ],
      ),
    );
  }

  static int? _digit(String ch) {
    final c = ch.codeUnitAt(0);
    return c >= 0x30 && c <= 0x39 ? c - 0x30 : null;
  }
}

/// One place of the counter: a strip of digits translated so the wanted one
/// sits in the window.
class _Reel extends StatefulWidget {
  const _Reel({
    super.key,
    required this.digit,
    required this.direction,
    required this.slot,
    required this.cell,
    required this.digits,
    required this.style,
  });

  final int digit;
  final int direction;
  final double slot;

  /// The fixed width of this place, so a turning reel never shifts its
  /// neighbours. See [_ScrollNumberState._metrics].
  final double cell;

  /// The glyphs this language writes its figures with.
  final SeedLocalizations digits;
  final TextStyle style;

  @override
  State<_Reel> createState() => _ReelState();
}

class _ReelState extends State<_Reel> with SingleTickerProviderStateMixin {
  /// Where the reel stands, in digits. Deliberately unbounded rather than
  /// wrapped to 0..9: a reel at 9 going to 0 must land on 10, so that it rolls
  /// one step forward. Reduced modulo ten it would have to travel nine steps
  /// backwards to reach the same face, which is the opposite of what a counter
  /// ticking over looks like.
  late double _from = widget.digit.toDouble();
  late double _to = _from;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _c,
    curve: Curves.easeInOut,
  );

  double get _position => _from + (_to - _from) * _curved.value;

  @override
  void didUpdateWidget(_Reel old) {
    super.didUpdateWidget(old);
    if (widget.digit == old.digit) return;

    // Step to the nearest position showing the wanted face, in the direction
    // the count moved — never against it.
    final face = (_to.round() % 10 + 10) % 10;
    final forward = widget.direction >= 0;
    final steps = forward
        ? (widget.digit - face + 10) % 10
        : (face - widget.digit + 10) % 10;

    _from = _position;
    _to = _to + (forward ? steps : -steps);
    _c
      ..value = 0
      ..forward();
  }

  @override
  void dispose() {
    _curved.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        height: widget.slot,
        width: widget.cell,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final p = _position;
            final base = p.floor();
            // At rest the reel shows one face and builds one. The second is
            // only ever the one rolling in, so a still badge does not leave a
            // clipped digit in the tree for a screen reader to read out.
            final rolling = (p - base).abs() > 1e-6;
            // Translated rather than positioned: a stack of none but
            // positioned children has no width of its own, and the reel sits
            // in a row that has none to give it.
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Only the faces that can be in the window are built, so a
                // reel that has ticked over a thousand times is no heavier
                // than a fresh one.
                for (var i = base; i <= (rolling ? base + 1 : base); i++)
                  Transform.translate(
                    offset: Offset(0, (i - p) * widget.slot),
                    child: SizedBox(
                      width: widget.cell,
                      child: Text(
                        // Only the face is localised; the reel itself counts
                        // in plain numbers, so its arithmetic is unaffected by
                        // which glyphs the language happens to use.
                        widget.digits.digit((i % 10 + 10) % 10),
                        style: widget.style,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Scales its child away rather than dropping it, and once it is gone builds
/// nothing at all.
///
/// The second half matters as much as the first: a badge scaled to nothing is
/// still a badge as far as a screen reader or a test is concerned, and one
/// that starts out with nothing to say must never have been there.
class _Vanishing extends StatefulWidget {
  const _Vanishing({
    required this.visible,
    required this.duration,
    required this.curve,
    required this.reverseCurve,
    required this.child,
  });

  final bool visible;
  final Duration duration;

  /// Arriving, where the overshoot belongs.
  final Curve curve;

  /// Leaving. Kept separate rather than running [curve] backwards: an
  /// overshoot reversed makes the badge swell on its way out, which is the
  /// opposite of retreating.
  final Curve reverseCurve;

  final Widget child;

  @override
  State<_Vanishing> createState() => _VanishingState();
}

class _VanishingState extends State<_Vanishing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.visible ? 1 : 0,
  );

  @override
  void didUpdateWidget(_Vanishing old) {
    super.didUpdateWidget(old);
    _c.duration = widget.duration;
    if (widget.visible != old.visible) {
      widget.visible ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// What was on screen while the badge still had something to say.
  ///
  /// A count of 3 falling to 0 is drawn as it retreats, and redrawing it as
  /// the 0 that hid it would set the reels rolling on the way out — a number
  /// changing as it leaves, which is not what it is doing.
  Widget? _lastShown;

  @override
  Widget build(BuildContext context) {
    if (widget.visible) _lastShown = widget.child;
    final child = widget.visible ? widget.child : (_lastShown ?? widget.child);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        if (_c.value == 0 && !widget.visible) return const SizedBox.shrink();
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: _c,
            curve: widget.curve,
            reverseCurve: widget.reverseCurve,
          ),
          child: child,
        );
      },
    );
  }
}
