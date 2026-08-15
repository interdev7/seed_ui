import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/border_radius_detector.dart';
import '../../utils/overlay_host.dart';
import '../../utils/size_resolver.dart';
import 'progress.dart';

/// Design tokens for [Spin].
@immutable
class SpinToken {
  /// Creates a [SpinToken].
  const SpinToken({
    this.colorPrimary,
    this.colorBgContainer,
    this.dotSize,
    this.dotSizeSM,
    this.dotSizeLG,
  });

  /// Primary color for spin dots.
  final Color? colorPrimary;

  /// Background mask color for container / fullscreen spin overlay.
  final Color? colorBgContainer;

  /// Default dot container size (middle).
  final double? dotSize;

  /// Small dot container size.
  final double? dotSizeSM;

  /// Large dot container size.
  final double? dotSizeLG;

  _ResolvedSpinToken _resolve(Token t) => _ResolvedSpinToken(
        colorPrimary: colorPrimary ?? t.primary.base,
        colorBgContainer: colorBgContainer ?? t.colorBgContainer,
        dotSize: dotSize ?? 20.0,
        dotSizeSM: dotSizeSM ?? 14.0,
        dotSizeLG: dotSizeLG ?? 32.0,
      );
}

@immutable
class _ResolvedSpinToken {
  const _ResolvedSpinToken({
    required this.colorPrimary,
    required this.colorBgContainer,
    required this.dotSize,
    required this.dotSizeSM,
    required this.dotSizeLG,
  });

  final Color colorPrimary;
  final Color colorBgContainer;
  final double dotSize;
  final double dotSizeSM;
  final double dotSizeLG;
}

/// Position of the spinner indicator relative to its container or overlay mask.
enum SpinPosition {
  /// Top-left corner.
  topLeft,

  /// Centred along the top edge.
  topCenter,

  /// Top-right corner.
  topRight,

  /// Centred along the left edge.
  centerLeft,

  /// Dead centre — the default.
  center,

  /// Centred along the right edge.
  centerRight,

  /// Bottom-left corner.
  bottomLeft,

  /// Centred along the bottom edge.
  bottomCenter,

  /// Bottom-right corner.
  bottomRight;

  /// This position as a Flutter [Alignment].
  Alignment get alignment => switch (this) {
        SpinPosition.topLeft => Alignment.topLeft,
        SpinPosition.topCenter => Alignment.topCenter,
        SpinPosition.topRight => Alignment.topRight,
        SpinPosition.centerLeft => Alignment.centerLeft,
        SpinPosition.center => Alignment.center,
        SpinPosition.centerRight => Alignment.centerRight,
        SpinPosition.bottomLeft => Alignment.bottomLeft,
        SpinPosition.bottomCenter => Alignment.bottomCenter,
        SpinPosition.bottomRight => Alignment.bottomRight,
      };
}

/// A spinning loading indicator matching `Spin`.
///
/// Can be used standalone or as a wrapper around a [child] widget to show
/// a blurred loading overlay when [spinning] is `true`.
///
/// ```dart
/// // Standalone spin
/// Spin()
/// Spin(size: SoftSize.large, tip: 'Loading...')
///
/// // Container wrapping
/// Spin(
///   spinning: isLoading,
///   tip: 'Loading data...',
///   child: ListView(...),
/// )
/// ```
class Spin extends StatefulWidget {
  /// Creates a [Spin].
  const Spin({
    super.key,
    this.spinning = true,
    this.size = SoftSize.middle,
    this.tip,
    this.delay,
    this.indicator,
    this.child,
    this.fullscreen = false,
    this.percent,
    this.color,
    this.position,
    this.overlayBorderRadius,
    this.token,
  });

  /// Whether [Spin] is actively spinning / showing loading overlay.
  final bool spinning;

  /// Preset ([SoftSize]) diameter/size of the indicator.
  ///
  /// Presets:
  /// - `SoftSize.small` (14px)
  /// - `SoftSize.middle` (20px)
  /// - `SoftSize.large` (32px)
  final ControlSize size;

  /// Optional description text or widget shown below the indicator.
  final Widget? tip;

  /// Optional delay before displaying the loading indicator when [spinning]
  /// becomes `true` (prevents flicker for fast operations).
  final Duration? delay;

  /// Custom indicator widget overriding the default 4-dot animation.
  final Widget? indicator;

  /// Optional child widget wrapped with a loading mask when [spinning] is `true`.
  final Widget? child;

  /// Renders [Spin] as a fullscreen modal backdrop.
  final bool fullscreen;

  /// Optional progress percent (0.0 to 1.0 or 0 to 100).
  final double? percent;

  /// Overrides the primary spin color.
  final Color? color;

  /// Position of the indicator within its container or overlay mask.
  /// Defaults to [SpinPosition.center] if not specified.
  final SpinPosition? position;

  /// Optional border radius for the loading overlay.
  /// If null, it attempts to detect the radius from the parent tree automatically.
  final BorderRadiusGeometry? overlayBorderRadius;

  /// Per-instance token overrides.
  final SpinToken? token;

  @override
  State<Spin> createState() => _SpinState();
}

class _SpinState extends State<Spin> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _delaySpinning = true;
  Timer? _delayTimer;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _updateSpinningState(initial: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFullscreenOverlay();
  }

  @override
  void didUpdateWidget(Spin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinning != oldWidget.spinning ||
        widget.delay != oldWidget.delay ||
        widget.fullscreen != oldWidget.fullscreen) {
      _updateSpinningState();
    }
    _syncFullscreenOverlay();
  }

  final GlobalKey<_FullscreenSpinOverlayState> _overlayKey =
      GlobalKey<_FullscreenSpinOverlayState>();

  void _syncFullscreenOverlay() {
    if (!widget.fullscreen) {
      _triggerOverlayDismiss();
      return;
    }

    final overlayState = UiKit.overlay ?? Overlay.maybeOf(context);
    if (overlayState == null) return;

    if (_overlayEntry == null) {
      if (widget.spinning) {
        _overlayEntry = OverlayEntry(
          builder: (context) => _buildFullscreenOverlayWidget(),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _overlayEntry != null &&
              _overlayEntry!.mounted == false) {
            overlayState.insert(_overlayEntry!);
          }
        });
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) {
          _overlayEntry!.markNeedsBuild();
        }
      });
    }
  }

  void _triggerOverlayDismiss() {
    if (_overlayEntry != null) {
      final state = _overlayKey.currentState;
      if (state != null) {
        state.dismiss();
      } else {
        if (_overlayEntry!.mounted) {
          _overlayEntry!.remove();
        }
        _overlayEntry!.dispose();
      }
      _overlayEntry = null;
    }
  }

  Widget _buildFullscreenOverlayWidget() {
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<SpinToken>(context) ??
            const SpinToken())
        ._resolve(token);

    final showSpin = widget.spinning && _delaySpinning;
    final dir = Directionality.maybeOf(context) ?? TextDirection.ltr;

    return _FullscreenSpinOverlay(
      key: _overlayKey,
      showSpin: showSpin,
      token: token,
      r: r,
      spinContent: _buildSpinContent(token, r),
      textDirection: dir,
      position: widget.position,
      overlayEntry: _overlayEntry!,
    );
  }

  void _updateSpinningState({bool initial = false}) {
    _delayTimer?.cancel();

    if (!widget.spinning) {
      _delaySpinning = false;
      _controller.stop();
      if (!initial && mounted) setState(() {});
      return;
    }

    if (widget.delay != null && widget.delay! > Duration.zero) {
      _delaySpinning = false;
      if (!initial && mounted) setState(() {});

      _delayTimer = Timer(widget.delay!, () {
        if (mounted && widget.spinning) {
          setState(() {
            _delaySpinning = true;
          });
          if (!_controller.isAnimating) {
            _controller.repeat();
          }
          _syncFullscreenOverlay();
        }
      });
    } else {
      _delaySpinning = true;
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
      if (!initial && mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _triggerOverlayDismiss();
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  BorderRadiusGeometry _resolveBorderRadius(BuildContext context, Token token) {
    if (widget.overlayBorderRadius != null) {
      return widget.overlayBorderRadius!;
    }

    // 1. Try to detect from the child widget tree (since Spin wraps the child)
    final detectedFromChild = detectBorderRadiusFromWidget(widget.child);
    if (detectedFromChild != null) {
      return detectedFromChild;
    }

    // 2. Fallback to detecting from ancestors (in case Spin is wrapped by something else)
    final detectedFromAncestor = detectBorderRadiusFromContext(context);
    if (detectedFromAncestor != null) {
      return detectedFromAncestor;
    }

    if (widget.size is SoftSize) {
      return BorderRadius.circular(
        switch (widget.size as SoftSize) {
          SoftSize.small => token.borderRadiusSM,
          SoftSize.middle => token.borderRadius,
          SoftSize.large => token.borderRadiusLG,
        },
      );
    }
    return BorderRadius.circular(token.borderRadiusSM);
  }

  double _resolveSize(Token token, _ResolvedSpinToken r) {
    return widget.size.resolve1D(
      small: r.dotSizeSM,
      middle: r.dotSize,
      large: r.dotSizeLG,
    );
  }

  Widget _buildTipWidget(Token token) {
    if (widget.tip == null) return const SizedBox.shrink();
    return DefaultTextStyle(
      textAlign: TextAlign.center,
      style: TextStyle(
        color: token.primary.base,
        fontSize: token.fontSize,
        fontFamily: token.fontFamily,
        fontFamilyFallback: token.fontFamilyFallback,
        decoration: TextDecoration.none,
      ),
      child: widget.tip!,
    );
  }

  Widget _buildIndicator(Color dotColor, double size) {
    final customIndicator = widget.indicator;
    if (customIndicator != null) {
      return SizedBox(
        width: size,
        height: size,
        child: FittedBox(
          fit: BoxFit.contain,
          child: customIndicator,
        ),
      );
    }

    if (widget.percent != null) {
      double pct = widget.percent!;

      if (pct > 1.0) {
        pct = pct / 100.0;
      }
      pct = pct.clamp(0.0, 1.0);

      return SizedBox(
        width: size,
        height: size,
        child: Progress(
          percent: pct,
          type: ProgressType.circle,
          showInfo: false,
          color: dotColor,
          size: size,
          strokeWidth: math.max(2.0, size * 0.1),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(size, size),
          painter: _Spin4DotPainter(
            progress: _controller.value,
            color: dotColor,
          ),
        );
      },
    );
  }

  Widget _buildSpinContent(Token token, _ResolvedSpinToken r) {
    final dotColor = widget.color ?? r.colorPrimary;
    final sz = _resolveSize(token, r);
    final indicatorWidget = _buildIndicator(dotColor, sz);
    final tipWidget = _buildTipWidget(token);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          indicatorWidget,
          if (widget.tip != null) ...[
            SizedBox(height: token.sizeXS),
            tipWidget,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<SpinToken>(context) ??
            const SpinToken())
        ._resolve(token);

    final showSpin = widget.spinning && _delaySpinning;

    if (widget.fullscreen) {
      if (Overlay.maybeOf(context) != null) {
        return const SizedBox.shrink();
      }
      return _buildFullscreenOverlayWidget();
    }

    final align = widget.position?.alignment ?? Alignment.center;

    if (widget.child == null) {
      return AnimatedOpacity(
        opacity: showSpin ? 1.0 : 0.0,
        duration: token.motionDurationMid,
        curve: token.motionEaseInOut,
        child: _buildSpinContent(token, r),
      );
    }

    final content = IgnorePointer(
      ignoring: !showSpin,
      child: AnimatedOpacity(
        opacity: showSpin ? 1.0 : 0.0,
        duration: token.motionDurationMid,
        curve: token.motionEaseInOut,
        child: AbsorbPointer(
          absorbing: showSpin,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: r.colorBgContainer.withValues(alpha: 0.5),
                    borderRadius: _resolveBorderRadius(context, token),
                  ),
                ),
              ),
              Align(
                alignment: align,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildSpinContent(token, r),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Stack(
      children: [
        widget.child!,
        Positioned.fill(child: content),
      ],
    );
  }
}

/// Custom painter rendering the signature 4-dot rotating & scaling animation.
class _Spin4DotPainter extends CustomPainter {
  _Spin4DotPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    final double dotDiameter = size.width * 0.42;
    final double dotRadius = dotDiameter / 2;

    // Rotate entire 4-dot container 360 deg continuously
    canvas.save();
    canvas.translate(center, center);
    canvas.rotate(progress * 2 * math.pi);
    canvas.translate(-center, -center);

    // 4 Dot positions relative to container box (top-left, top-right, bottom-right, bottom-left)
    final offsets = [
      Offset(dotRadius, dotRadius),
      Offset(size.width - dotRadius, dotRadius),
      Offset(size.width - dotRadius, size.height - dotRadius),
      Offset(dotRadius, size.height - dotRadius),
    ];

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      // Each dot pulses scale/opacity offset by index.
      final double phase = (progress + (i * 0.25)) % 1.0;
      final double scale =
          0.35 + 0.65 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
      final double opacity = (0.3 + 0.7 * scale).clamp(0.2, 1.0);

      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(offsets[i], dotRadius * scale, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_Spin4DotPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _FullscreenSpinOverlay extends StatefulWidget {
  const _FullscreenSpinOverlay({
    super.key,
    required this.showSpin,
    required this.token,
    required this.r,
    required this.spinContent,
    required this.textDirection,
    this.position,
    required this.overlayEntry,
  });

  final bool showSpin;
  final Token token;
  final _ResolvedSpinToken r;
  final Widget spinContent;
  final TextDirection textDirection;
  final SpinPosition? position;
  final OverlayEntry overlayEntry;

  @override
  State<_FullscreenSpinOverlay> createState() => _FullscreenSpinOverlayState();
}

class _FullscreenSpinOverlayState extends State<_FullscreenSpinOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _opacityAnim;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: widget.token.motionDurationMid,
    );
    _opacityAnim = CurvedAnimation(
      parent: _animController,
      curve: widget.token.motionEaseInOut,
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && _isDismissing) {
        _removeAndDisposeOverlay();
      }
    });

    if (widget.showSpin) {
      _animController.forward();
    }
  }

  void _removeAndDisposeOverlay() {
    if (widget.overlayEntry.mounted) {
      widget.overlayEntry.remove();
    }
    widget.overlayEntry.dispose();
  }

  void dismiss() {
    _isDismissing = true;
    if (mounted) {
      _animController.reverse();
    }
  }

  @override
  void didUpdateWidget(_FullscreenSpinOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showSpin != oldWidget.showSpin) {
      if (widget.showSpin) {
        _isDismissing = false;
        _animController.forward();
      } else {
        dismiss();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.textDirection,
      child: Positioned.fill(
        child: AnimatedBuilder(
          animation: _opacityAnim,
          builder: (context, child) {
            final isVisible = _opacityAnim.value > 0.0;
            return IgnorePointer(
              ignoring: !widget.showSpin,
              child: Opacity(
                opacity: _opacityAnim.value,
                child: AbsorbPointer(
                  absorbing: isVisible && widget.showSpin,
                  child: Container(
                    color: widget.r.colorBgContainer.withValues(alpha: 0.65),
                    child: Align(
                      alignment: widget.position?.alignment ?? Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: widget.spinContent,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
