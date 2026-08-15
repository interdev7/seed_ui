import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind, kTouchSlop;
import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/popover.dart';

/// A small text bubble describing the widget it wraps.
///
/// Shows on hover with a pointer and on tap with touch, never stealing the
/// tap from the wrapped widget. Use it for a brief hint — an icon button's
/// name, a truncated label's full text — never for content the user must act
/// on; reach for [Popover] or a Popconfirm when the bubble needs buttons.
///
/// ```dart
/// Tooltip(
///   message: 'Search',
///   child: Button(
///     shape: ButtonShape.circle,
///     icon: const Icon(Icons.search),
///     onPressed: onSearch,
///   ),
/// )
/// ```
enum TooltipTrigger {
  /// Hover on a pointer device; tap on a touchscreen. The everyday default —
  /// works everywhere without stealing the trigger's own tap.
  hover,

  /// Tap or click on any device. Suits a hint tied to a non-interactive
  /// element the user is expected to tap for more.
  tap,

  /// Long-press on any device.
  longPress,
}

/// Per-component design tokens for [Tooltip].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [TooltipToken(...)])`, or per instance via [Tooltip.token].
@immutable
class TooltipToken {
  /// Creates a [TooltipToken].
  const TooltipToken({
    this.colorBg,
    this.colorText,
    this.borderRadius,
    this.padding,
    this.fontSize,
  });

  /// Tooltip background color (`colorBg`).
  final Color? colorBg;

  /// Tooltip text color (`colorText`).
  final Color? colorText;

  /// Tooltip corner radius (`borderRadius`).
  final double? borderRadius;

  /// Tooltip padding (`padding`).
  final EdgeInsets? padding;

  /// Tooltip font size (`fontSize`).
  final double? fontSize;

  _ResolvedTooltipToken _resolve(Token t) => _ResolvedTooltipToken(
        colorBg: colorBg ?? t.colorBgSpotlight,
        colorText:
            colorText ?? (t.isDark ? t.colorText : const Color(0xFFFFFFFF)),
        borderRadius: borderRadius ?? t.borderRadiusSM,
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: t.sizeXS,
              vertical: t.sizeXXS + 2,
            ),
        fontSize: fontSize ?? t.fontSize,
      );
}

@immutable
class _ResolvedTooltipToken {
  const _ResolvedTooltipToken({
    required this.colorBg,
    required this.colorText,
    required this.borderRadius,
    required this.padding,
    required this.fontSize,
  });

  final Color colorBg;
  final Color colorText;
  final double borderRadius;
  final EdgeInsets padding;
  final double fontSize;
}

/// A short text hint that surfaces on hover, tap or long-press.
///
/// Shares its name with Material's `Tooltip`; when importing both, hide one:
/// `import 'package:flutter/material.dart' hide Tooltip;`.
class Tooltip extends StatefulWidget {
  /// Creates a [Tooltip].
  const Tooltip({
    super.key,
    required this.message,
    required this.child,
    this.placement = PopoverPlacement.top,
    this.trigger = TooltipTrigger.hover,
    this.arrow = true,
    this.waitDuration = const Duration(milliseconds: 100),
    this.showDuration = const Duration(milliseconds: 1500),
    this.token,
  });

  /// The hint text.
  final String message;

  /// The widget the tooltip describes and anchors to.
  final Widget child;

  /// Which side of the child the bubble prefers. It flips and shifts to stay
  /// on screen.
  final PopoverPlacement placement;

  /// What reveals the tooltip. See [TooltipTrigger].
  final TooltipTrigger trigger;

  /// Whether to draw a caret pointing at the trigger.
  final bool arrow;

  /// How long the pointer must rest before the tooltip appears on hover.
  final Duration waitDuration;

  /// How long a touch-triggered tooltip stays before hiding itself.
  ///
  /// Applies to touch only: there is no pointer-exit event on a touchscreen,
  /// so a tap-shown tooltip retracts on this timer. Hovered tooltips ignore it
  /// and hide when the pointer leaves.
  final Duration showDuration;

  /// Per-instance token overrides.
  final TooltipToken? token;

  @override
  State<Tooltip> createState() => _SoftTooltipState();
}

class _SoftTooltipState extends State<Tooltip> {
  final PopoverController _controller = PopoverController();
  Timer? _showTimer;
  Timer? _hideTimer;

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _show() {
    _hideTimer?.cancel();
    if (_controller.isOpen) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _controller.open(
      builder: _buildBubble,
      placement: widget.placement,
      anchorRect: box.localToGlobal(Offset.zero) & box.size,
      gap: 8,
      // A tooltip must not intercept pointer events, or hovering it would pull
      // focus off the trigger and the pair would flicker.
      interactive: false,
      arrowColor: widget.arrow ? context.softToken.colorBgSpotlight : null,
      arrowShadow: widget.arrow ? context.softToken.boxShadowSecondary : null,
      anchorContext: context,
      onScrollDismiss: _hide,
    );
  }

  void _showTimed() {
    _show();
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.showDuration, _hide);
  }

  void _hide() {
    _showTimer?.cancel();
    _controller.close();
  }

  void _onEnter() {
    _showTimer?.cancel();
    _showTimer = Timer(widget.waitDuration, _show);
  }

  void _onExit() {
    _showTimer?.cancel();
    _hide();
  }

  // Taps are detected with a Listener rather than a GestureDetector so they
  // still reach the wrapped widget — an interactive child (a Button) owns
  // a gesture recognizer that would win the arena and swallow an onTap here.
  Offset? _downPosition;

  void _onPointerDown(PointerDownEvent event) {
    _downPosition = event.position;
  }

  void _onTapUp(PointerUpEvent event, {required bool touchOnly}) {
    // In hover mode the pointer path is covered by hover; only touch taps open
    // the tooltip. In tap mode every device toggles it.
    if (touchOnly && event.kind != PointerDeviceKind.touch) return;
    final down = _downPosition;
    _downPosition = null;
    // Ignore releases that were really a scroll, not a tap.
    if (down == null || (event.position - down).distance > kTouchSlop) return;

    if (_controller.isOpen) {
      _hide();
    } else {
      _showTimed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.trigger) {
      // Hover on a pointer, plus a touch-tap fallback where hover cannot fire.
      TooltipTrigger.hover => MouseRegion(
          onEnter: (_) => _onEnter(),
          onExit: (_) => _onExit(),
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: (e) => _onTapUp(e, touchOnly: true),
            child: widget.child,
          ),
        ),
      // Any tap or click toggles the tooltip.
      TooltipTrigger.tap => Listener(
          onPointerDown: _onPointerDown,
          onPointerUp: (e) => _onTapUp(e, touchOnly: false),
          child: widget.child,
        ),
      // Long-press is a distinct recognizer, so it can share the arena with a
      // wrapped button's tap.
      TooltipTrigger.longPress => GestureDetector(
          onLongPress: _showTimed,
          child: widget.child,
        ),
    };
  }

  Widget _buildBubble(BuildContext context) {
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<TooltipToken>(context) ??
            const TooltipToken())
        ._resolve(token);
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: r.padding,
      decoration: BoxDecoration(
        color: r.colorBg,
        borderRadius: BorderRadius.circular(r.borderRadius),
        boxShadow: token.boxShadowSecondary,
      ),
      child: Text(
        widget.message,
        style: TextStyle(
          color: r.colorText,
          fontSize: r.fontSize,
          fontFamily: token.fontFamily,
          fontFamilyFallback: token.fontFamilyFallback,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
