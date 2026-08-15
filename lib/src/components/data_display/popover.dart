import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/popover.dart';

/// What opens a [Popover].
enum PopoverTrigger {
  /// Hover on a pointer device; tap on a touchscreen, where there is no hover
  /// to speak of.
  hover,

  /// Tap or click.
  tap,

  /// Long-press on any device.
  longPress,
}

/// Per-component design tokens for [Popover].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [PopoverToken(...)])`, or per instance via [Popover.token].
@immutable
class PopoverToken {
  /// Creates a [PopoverToken].
  const PopoverToken({
    this.colorBg,
    this.titleColor,
    this.contentColor,
    this.borderRadius,
    this.padding,
    this.minWidth,
    this.maxWidth,
  });

  /// The card's background (`colorBgElevated`).
  final Color? colorBg;

  /// Colour of [Popover.title] (`titleColor`).
  final Color? titleColor;

  /// Colour of [Popover.content] (`contentColor`).
  final Color? contentColor;

  /// The card's corner radius.
  final double? borderRadius;

  /// Padding inside the card.
  final EdgeInsets? padding;

  /// The narrowest and widest the card may be — the `minWidth` of
  /// 177 and the room a card is given to grow into.
  final double? minWidth;

  /// The room a card is given to grow into before its text wraps.
  final double? maxWidth;

  _ResolvedPopoverToken _resolve(Token t) => _ResolvedPopoverToken(
        colorBg: colorBg ?? t.colorBgElevated,
        titleColor: titleColor ?? t.colorText,
        contentColor: contentColor ?? t.colorText,
        borderRadius: borderRadius ?? t.borderRadiusLG,
        padding: padding ??
            EdgeInsets.symmetric(horizontal: t.size, vertical: t.sizeSM),
        minWidth: minWidth ?? 177,
        maxWidth: maxWidth ?? 360,
      );
}

@immutable
class _ResolvedPopoverToken {
  const _ResolvedPopoverToken({
    required this.colorBg,
    required this.titleColor,
    required this.contentColor,
    required this.borderRadius,
    required this.padding,
    required this.minWidth,
    required this.maxWidth,
  });

  final Color colorBg;
  final Color titleColor;
  final Color contentColor;
  final double borderRadius;
  final EdgeInsets padding;
  final double minWidth;
  final double maxWidth;
}

/// A floating card with a title and a body.
///
/// Where a [Tooltip] explains in a line of text, a popover holds a card: it can
/// carry links, buttons, a form. That is the whole of the difference, and it is
/// why the two share everything below them.
///
/// ```dart
/// Popover(
///   title: const Text('Title'),
///   content: const Text('Some content here.'),
///   child: Button(child: const Text('Hover me')),
/// )
/// ```
///
/// The card is opened by hovering, tapping or long-pressing — [trigger] — or
/// driven from outside with [open] and [onOpenChange].
class Popover extends StatefulWidget {
  /// Creates a [Popover].
  const Popover({
    super.key,
    required this.child,
    this.title,
    this.content,
    this.placement = PopoverPlacement.top,
    this.trigger = PopoverTrigger.hover,
    this.open,
    this.defaultOpen = false,
    this.onOpenChange,
    this.arrow = true,
    this.animation = PopoverAnimation.simple,
    this.duration,
    this.curve,
    this.color,
    this.mouseEnterDelay = const Duration(milliseconds: 100),
    this.mouseLeaveDelay = const Duration(milliseconds: 100),
    this.dismissOnOutsideTap = true,
    this.token,
  });

  /// What the card is anchored to.
  final Widget child;

  /// The card's heading.
  final Widget? title;

  /// The card's body — text, links, buttons, a form.
  final Widget? content;

  /// Which side of the trigger the card prefers. It flips and shifts to stay
  /// on screen.
  final PopoverPlacement placement;

  /// What opens it.
  final PopoverTrigger trigger;

  /// Whether the card is open (controlled). Null lets the popover manage it.
  final bool? open;

  /// Whether it starts open when uncontrolled.
  final bool defaultOpen;

  /// Called with the state the popover wants to be in.
  final ValueChanged<bool>? onOpenChange;

  /// Whether a caret points at the trigger.
  final bool arrow;

  /// How the card arrives.
  ///
  /// [PopoverAnimation.simple] fades and grows out of the edge nearest the
  /// trigger. [PopoverAnimation.genie] pours it out of the trigger, macOS
  /// style — a showpiece, and it rasterises the card for the length of the
  /// animation, so it is not what a popover that opens on every hover wants.
  final PopoverAnimation animation;

  /// How long the card takes to arrive, and on what curve.
  ///
  /// Null takes the pace the [animation] wants: quick for a fade, longer for a
  /// genie, which carries its own easing row by row and so runs straight
  /// unless you say otherwise.
  final Duration? duration;

  /// The curve the arrival runs on. Null takes the animation's own pace.
  final Curve? curve;

  /// The card's background, in place of the token's.
  final Color? color;

  /// How long a pointer must rest on the trigger before the card appears, and
  /// how long it may leave before the card goes — the pause that lets the
  /// pointer travel from the trigger into the card without it closing.
  final Duration mouseEnterDelay;

  /// How long the pointer may be away before the card goes — the pause that
  /// lets it travel from the trigger into the card without closing it.
  final Duration mouseLeaveDelay;

  /// Whether a tap outside puts it away.
  final bool dismissOnOutsideTap;

  /// Per-instance token overrides.
  final PopoverToken? token;

  @override
  State<Popover> createState() => _PopoverState();
}

class _PopoverState extends State<Popover> {
  late bool _uncontrolled = widget.defaultOpen;
  Timer? _pending;

  /// Whether the pointer is over the trigger or the card. A hover popover
  /// stays up while either is true, so the pointer can travel between them.
  bool _onTrigger = false;
  bool _onCard = false;

  bool get _isOpen => widget.open ?? _uncontrolled;
  bool get _byHover => widget.trigger == PopoverTrigger.hover;

  @override
  void dispose() {
    _pending?.cancel();
    super.dispose();
  }

  void _set(bool open) {
    _pending?.cancel();
    if (open == _isOpen) return;
    if (widget.open == null) setState(() => _uncontrolled = open);
    widget.onOpenChange?.call(open);
  }

  /// Hover asks after a pause: a pointer crossing the trigger on its way
  /// somewhere else should not open a card, and one crossing the gap between
  /// trigger and card should not close it.
  void _askAfterPause() {
    _pending?.cancel();
    final wanted = _onTrigger || _onCard;
    _pending = Timer(
      wanted ? widget.mouseEnterDelay : widget.mouseLeaveDelay,
      () {
        if (!mounted) return;
        _set(_onTrigger || _onCard);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<PopoverToken>(context) ??
            const PopoverToken())
        ._resolve(t);
    final background = widget.color ?? r.colorBg;

    Widget trigger = widget.child;

    if (_byHover) {
      trigger = MouseRegion(
        onEnter: (_) {
          _onTrigger = true;
          _askAfterPause();
        },
        onExit: (_) {
          _onTrigger = false;
          _askAfterPause();
        },
        // A touchscreen has no hover: there, the same trigger answers a tap.
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _set(!_isOpen),
          child: trigger,
        ),
      );
    } else {
      trigger = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap:
            widget.trigger == PopoverTrigger.tap ? () => _set(!_isOpen) : null,
        onLongPress: widget.trigger == PopoverTrigger.longPress
            ? () => _set(!_isOpen)
            : null,
        child: trigger,
      );
    }

    return PopoverLayer(
      open: _isOpen,
      onOpenChanged: _set,
      placement: widget.placement,
      dismissOnOutsideTap: widget.dismissOnOutsideTap,
      animation: widget.animation,
      duration: widget.duration,
      curve: widget.curve,
      arrowColor: widget.arrow ? background : null,
      arrowShadow: t.boxShadowSecondary,
      content: (context) => _card(context, t, r, background),
      child: trigger,
    );
  }

  /// [context] is the one the surface is built in — under the arrival, where
  /// [PopoverSurface] can be read. The state's own context is the trigger's and
  /// would always say no.
  Widget _card(
    BuildContext context,
    Token t,
    _ResolvedPopoverToken r,
    Color background,
  ) {
    Widget card = Container(
      constraints: BoxConstraints(
        minWidth: r.minWidth,
        maxWidth: r.maxWidth,
      ),
      padding: r.padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(r.borderRadius),
        // While the genie pours, the sheet casts this shadow instead: drawn
        // here it would be cropped to the picture and read as a grey band.
        boxShadow:
            PopoverSurface.shadowIsCast(context) ? null : t.boxShadowSecondary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.title != null)
            DefaultTextStyle(
              style: TextStyle(
                color: r.titleColor,
                fontSize: t.fontSize,
                fontWeight: FontWeight.w600,
                height: t.lineHeight,
                leadingDistribution: TextLeadingDistribution.even,
                decoration: TextDecoration.none,
              ),
              child: widget.title!,
            ),
          if (widget.title != null && widget.content != null)
            SizedBox(height: t.sizeXS),
          if (widget.content != null)
            DefaultTextStyle(
              style: TextStyle(
                color: r.contentColor,
                fontSize: t.fontSize,
                height: t.lineHeight,
                leadingDistribution: TextLeadingDistribution.even,
                decoration: TextDecoration.none,
              ),
              child: widget.content!,
            ),
        ],
      ),
    );

    if (_byHover) {
      // The card is part of the trigger as far as hover is concerned: a
      // pointer that reaches it keeps the card up, which is what makes the
      // links and buttons inside a hover popover usable at all.
      card = MouseRegion(
        onEnter: (_) {
          _onCard = true;
          _askAfterPause();
        },
        onExit: (_) {
          _onCard = false;
          _askAfterPause();
        },
        child: card,
      );
    }

    return card;
  }
}
