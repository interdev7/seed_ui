import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/rendering.dart' show PaintingContextCallback;
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/widgets.dart';

import '../theme/config_provider.dart';
import 'overlay_host.dart';

/// Where a popover sits relative to its anchor.
///
/// The first word is the edge it grows from; the suffix nudges it along that
/// edge (`Left`/`Right`, `Top`/`Bottom`) so a caret can line up with the
/// trigger. When there is not enough room the popover flips to the opposite
/// side, and is otherwise shifted to stay within the viewport.
enum PopoverPlacement {
  /// Above the anchor, left edges aligned.
  topLeft,

  /// Above the anchor, centred on it.
  top,

  /// Above the anchor, right edges aligned.
  topRight,

  /// Below the anchor, left edges aligned.
  bottomLeft,

  /// Below the anchor, centred on it.
  bottom,

  /// Below the anchor, right edges aligned.
  bottomRight,

  /// Left of the anchor, top edges aligned.
  leftTop,

  /// Left of the anchor, centred on it.
  left,

  /// Left of the anchor, bottom edges aligned.
  leftBottom,

  /// Right of the anchor, top edges aligned.
  rightTop,

  /// Right of the anchor, centred on it.
  right,

  /// Right of the anchor, bottom edges aligned.
  rightBottom,
}

/// How a floating surface arrives.
enum PopoverAnimation {
  /// Fades in while growing a little out of the edge nearest its trigger.
  simple,

  /// The macOS "genie": the surface is drawn as a warped sheet that pours out
  /// of the trigger and settles into shape.
  ///
  /// It works by rasterising the surface and drawing that picture through a
  /// deformed mesh, so it costs a snapshot per frame of the animation — worth
  /// it for a showpiece, not for a tooltip that appears on every hover.
  genie,
}

/// The primary edge a placement grows from.
enum PopoverSide {
  /// The card sits above its trigger.
  top,

  /// The card sits below its trigger.
  bottom,

  /// The card sits to the left of its trigger.
  left,

  /// The card sits to the right of its trigger.
  right
}

extension _PlacementInfo on PopoverPlacement {
  PopoverSide get side => switch (this) {
        PopoverPlacement.top ||
        PopoverPlacement.topLeft ||
        PopoverPlacement.topRight =>
          PopoverSide.top,
        PopoverPlacement.bottom ||
        PopoverPlacement.bottomLeft ||
        PopoverPlacement.bottomRight =>
          PopoverSide.bottom,
        PopoverPlacement.left ||
        PopoverPlacement.leftTop ||
        PopoverPlacement.leftBottom =>
          PopoverSide.left,
        PopoverPlacement.right ||
        PopoverPlacement.rightTop ||
        PopoverPlacement.rightBottom =>
          PopoverSide.right,
      };

  /// Cross-axis alignment: -1 for start, 0 for centre, 1 for end.
  double get align => switch (this) {
        PopoverPlacement.topLeft ||
        PopoverPlacement.bottomLeft ||
        PopoverPlacement.leftTop ||
        PopoverPlacement.rightTop =>
          -1,
        PopoverPlacement.topRight ||
        PopoverPlacement.bottomRight ||
        PopoverPlacement.leftBottom ||
        PopoverPlacement.rightBottom =>
          1,
        _ => 0,
      };
}

/// Controls one anchored popover: an overlay layer positioned near a target.
///
/// This is the shared machinery behind [Popover]; components such as
/// Popconfirm, Tooltip and Dropdown drive it rather than touching the overlay
/// directly.
class PopoverController {
  /// Creates a [PopoverController].
  PopoverController();

  OverlayEntry? _entry;
  OverlayPopScope? _popScope;

  /// Whether the popover is currently mounted.
  bool get isOpen => _entry != null;

  /// Called after [close] finishes its exit animation. Set by [Popover].
  VoidCallback? onClosed;

  final GlobalKey<_SoftPopoverLayerState> _layerKey =
      GlobalKey<_SoftPopoverLayerState>();

  // The anchor rectangle, held in a notifier so the layer can be repositioned
  // (e.g. when the trigger grows) without reinserting the overlay entry.
  final ValueNotifier<Rect> _anchor = ValueNotifier<Rect>(Rect.zero);

  /// Updates the rectangle the popover positions itself around. A no-op when the
  /// rectangle is unchanged.
  void reposition(Rect anchorRect) => _anchor.value = anchorRect;

  /// Rebuilds the open layer, so a content [builder] that closes over changed
  /// state (e.g. a menu whose items grew) re-runs. A no-op when closed.
  void markNeedsBuild() => _entry?.markNeedsBuild();

  // The popover is positioned from a snapshot of the anchor taken at open time,
  // so once the page scrolls the anchor moves out from under it. Rather than
  // chase the anchor every frame, dismiss on the first scroll — the behaviour
  // Flutter's own Tooltip uses.
  ScrollPosition? _scrollPosition;
  VoidCallback? _scrollListener;

  /// Mounts the popover built by [builder] at [placement] around [anchorRect]
  /// (the trigger's rectangle in global coordinates).
  ///
  /// Pass [anchorContext] and [onScrollDismiss] to have the popover close when
  /// the nearest scrollable moves.
  void open({
    required WidgetBuilder builder,
    required PopoverPlacement placement,
    required Rect anchorRect,
    required double gap,
    VoidCallback? onDismiss,
    bool interactive = true,
    bool dismissExcludesAnchor = false,
    Color? arrowColor,
    List<BoxShadow>? arrowShadow,
    Color? barrierColor,
    PopoverAnimation animation = PopoverAnimation.simple,
    Duration? duration,
    Curve? curve,
    BuildContext? anchorContext,
    VoidCallback? onScrollDismiss,
  }) {
    if (_entry != null) return;
    _anchor.value = anchorRect;
    _entry = OverlayEntry(
      builder: (context) => _SoftPopoverLayer(
        key: _layerKey,
        placement: placement,
        anchor: _anchor,
        gap: gap,
        onDismiss: onDismiss,
        interactive: interactive,
        dismissExcludesAnchor: dismissExcludesAnchor,
        arrowColor: arrowColor,
        arrowShadow: arrowShadow,
        barrierColor: barrierColor,
        animation: animation,
        duration: duration,
        curve: curve,
        builder: builder,
      ),
    );
    UiKit.requireOverlay().insert(_entry!);
    _attachScrollDismiss(anchorContext, onScrollDismiss);
    _popScope = OverlayPopScope(
      onPop: () {
        if (onDismiss != null) {
          onDismiss();
        } else {
          close();
        }
      },
    );
    _popScope!.register(anchorContext);
  }

  void _attachScrollDismiss(
    BuildContext? anchorContext,
    VoidCallback? onScrollDismiss,
  ) {
    if (anchorContext == null || onScrollDismiss == null) return;
    final position = Scrollable.maybeOf(anchorContext)?.position;
    if (position == null) return;
    _scrollPosition = position;
    var fired = false;
    _scrollListener = () {
      if (fired) return;
      fired = true;
      onScrollDismiss();
    };
    position.addListener(_scrollListener!);
  }

  void _detachScrollDismiss() {
    if (_scrollListener != null) {
      _scrollPosition?.removeListener(_scrollListener!);
      _scrollListener = null;
      _scrollPosition = null;
    }
  }

  /// Runs the exit animation, then removes the layer.
  void close() {
    _detachScrollDismiss();
    _popScope?.unregister();
    _popScope = null;
    final entry = _entry;
    if (entry == null) return;

    void finish() {
      entry.remove();
      if (_entry == entry) _entry = null;
      onClosed?.call();
    }

    final state = _layerKey.currentState;
    if (state == null) {
      finish();
    } else {
      state.playExit(finish);
    }
  }

  /// Removes the layer immediately, without animating. For teardown.
  void dispose() {
    _detachScrollDismiss();
    _popScope?.unregister();
    _popScope = null;
    _entry?.remove();
    _entry = null;
    _anchor.dispose();
  }
}

class _SoftPopoverLayer extends StatefulWidget {
  const _SoftPopoverLayer({
    super.key,
    required this.placement,
    required this.anchor,
    required this.gap,
    required this.builder,
    this.onDismiss,
    this.interactive = true,
    this.dismissExcludesAnchor = false,
    this.arrowColor,
    this.arrowShadow,
    this.barrierColor,
    this.animation = PopoverAnimation.simple,
    this.duration,
    this.curve,
  });

  final PopoverAnimation animation;

  /// How long the surface takes to arrive, and on what curve. Null takes the
  /// pace the [animation] wants.
  final Duration? duration;

  /// The curve the arrival runs on. Null takes the pace the [animation] wants.
  final Curve? curve;
  final PopoverPlacement placement;
  final ValueListenable<Rect> anchor;
  final double gap;
  final WidgetBuilder builder;
  final VoidCallback? onDismiss;

  /// When false the content ignores pointer events, so a tooltip cannot eat
  /// hover from the widgets it floats over.
  final bool interactive;

  /// When true the dismiss barrier leaves a hole over the anchor, so the
  /// trigger stays interactive while the popover is open (e.g. removing a tag
  /// from a Select without the click closing the dropdown).
  final bool dismissExcludesAnchor;

  /// When non-null a caret of this colour is drawn pointing at the anchor.
  final Color? arrowColor;

  /// The shadow drawn under the caret — pass the bubble's own shadow so the
  /// two read as a single surface.
  final List<BoxShadow>? arrowShadow;

  /// Tint painted over the page behind an open popover. Null leaves it clear.
  final Color? barrierColor;

  @override
  State<_SoftPopoverLayer> createState() => _SoftPopoverLayerState();
}

class _SoftPopoverLayerState extends State<_SoftPopoverLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // A fade wants to be quick; a genie is something to watch, and at the pace
    // of a fade it is over before the eye reads the shape at all.
    duration: widget.duration ??
        (widget.animation == PopoverAnimation.genie
            ? const Duration(milliseconds: 420)
            : const Duration(milliseconds: 180)),
  )..forward();

  /// The caret's resolved geometry, filled in by the layout delegate once the
  /// bubble has been measured and positioned.
  final ValueNotifier<PopoverArrowGeometry?> _arrow =
      ValueNotifier<PopoverArrowGeometry?>(null);

  @override
  void dispose() {
    _controller.dispose();
    _arrow.dispose();
    super.dispose();
  }

  void playExit(VoidCallback done) {
    _controller.reverse().whenComplete(done);
  }

  /// Scale origin so the popover grows out of the edge nearest its anchor,
  /// based on the side the delegate actually settled on.
  @override
  Widget build(BuildContext context) {
    final token = ConfigProvider.of(context).token;
    final curved = CurvedAnimation(
      parent: _controller,
      // The genie's timing lives here rather than in its geometry: it leaves
      // the trigger gently, flows, and settles. The fade wants the token's own
      // curve, which is quicker off the mark.
      curve: widget.curve ??
          (widget.animation == PopoverAnimation.genie
              ? Curves.easeInOutCubic
              : token.motionEaseOutCirc),
      reverseCurve: token.motionEaseInOut,
    );
    final padding = MediaQuery.paddingOf(context);

    PopoverLayoutDelegate delegateFor(Rect anchorRect) => PopoverLayoutDelegate(
          anchor: anchorRect,
          placement: widget.placement,
          // Leave room for the caret between the bubble and its anchor.
          gap:
              widget.gap + (widget.arrowColor != null ? popoverArrowLength : 0),
          arrowSink: widget.arrowColor != null ? _arrow : null,
          viewportPadding: EdgeInsets.fromLTRB(
            8 + padding.left,
            8 + padding.top,
            8 + padding.right,
            8 + padding.bottom,
          ),
        );

    return Stack(
      children: [
        // A transparent barrier so an outside tap dismisses the popover, the
        // way clicking away closes a menu. When the anchor is excluded, the
        // barrier leaves a hole over it so the trigger stays interactive.
        if (widget.onDismiss != null || widget.barrierColor != null)
          widget.dismissExcludesAnchor
              ? ValueListenableBuilder<Rect>(
                  valueListenable: widget.anchor,
                  builder: (context, r, _) => FadeTransition(
                    opacity: curved,
                    child: _HoleBarrier(
                      hole: r,
                      color: widget.barrierColor,
                      onTap: widget.onDismiss ?? () {},
                    ),
                  ),
                )
              : Positioned.fill(
                  child: FadeTransition(
                    opacity: curved,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: widget.onDismiss,
                      child: widget.barrierColor != null
                          ? Container(color: widget.barrierColor)
                          : null,
                    ),
                  ),
                ),
        // Repositions when the anchor rectangle changes (e.g. the trigger
        // grows), without reinserting the overlay entry.
        ValueListenableBuilder<Rect>(
          valueListenable: widget.anchor,
          child: _Arrival(
            animation: widget.animation,
            progress: curved,
            side: widget.placement.side,
            anchor: widget.anchor,
            shadows: widget.arrowShadow ?? token.boxShadowSecondary,
            child: DefaultTextStyle(
              // The overlay sits outside any Material ancestor, where
              // Flutter falls back to a debug style with yellow underlines.
              style: TextStyle(
                color: token.colorText,
                fontSize: token.fontSize,
                fontFamily: token.fontFamily,
                fontFamilyFallback: token.fontFamilyFallback,
                decoration: TextDecoration.none,
              ),
              child: widget.interactive
                  // Taps inside must not reach the dismiss barrier.
                  ? GestureDetector(
                      onTap: () {},
                      child: Builder(builder: widget.builder),
                    )
                  : IgnorePointer(child: Builder(builder: widget.builder)),
            ),
          ),
          builder: (context, anchorRect, child) => CustomSingleChildLayout(
            delegate: delegateFor(anchorRect),
            child: child,
          ),
        ),
        // The caret is a rotated square drawn *over* the bubble edge: its inner
        // half sits on the bubble (same colour, so no seam) and covers the
        // bubble's shadow band there, while its outer half is the visible
        // pointer. Painting it after the bubble keeps the two perfectly
        // uniform.
        if (widget.arrowColor != null)
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: curved,
                child: ValueListenableBuilder<PopoverArrowGeometry?>(
                  valueListenable: _arrow,
                  builder: (context, arrow, _) => arrow == null
                      ? const SizedBox.shrink()
                      : CustomPaint(
                          key: const Key('softPopoverArrow'),
                          painter: PopoverArrowPainter(
                            arrow,
                            widget.arrowColor!,
                            drawShadow: widget.barrierColor == null,
                          ),
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// How the surface arrives: a fade and a small grow, or the genie.
class _Arrival extends StatelessWidget {
  const _Arrival({
    required this.animation,
    required this.progress,
    required this.side,
    required this.anchor,
    required this.child,
    this.shadows,
  });

  final PopoverAnimation animation;
  final Animation<double> progress;
  final PopoverSide side;
  final ValueListenable<Rect> anchor;
  final List<BoxShadow>? shadows;
  final Widget child;

  /// Grows out of the edge nearest the trigger, so the surface reads as coming
  /// from it rather than appearing over it.
  Alignment get _origin => switch (side) {
        PopoverSide.top => Alignment.bottomCenter,
        PopoverSide.bottom => Alignment.topCenter,
        PopoverSide.left => Alignment.centerRight,
        PopoverSide.right => Alignment.centerLeft,
      };

  @override
  Widget build(BuildContext context) {
    if (animation == PopoverAnimation.simple) {
      return FadeTransition(
        opacity: progress,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1).animate(progress),
          alignment: _origin,
          child: child,
        ),
      );
    }

    return _Genie(
      progress: progress,
      side: side,
      anchor: anchor,
      shadows: shadows,
      child: child,
    );
  }
}

/// The macOS "genie": the surface pours out of the edge nearest its trigger.
///
/// The child is rasterised and that picture is drawn through a mesh whose rows
/// are squeezed towards the trigger — wide where the surface has arrived,
/// pinched where it is still coming through. A transform cannot do this: it is
/// the same affine map everywhere, and the genie is a different squeeze at
/// every row.
class _Genie extends StatefulWidget {
  const _Genie({
    required this.progress,
    required this.side,
    required this.anchor,
    required this.child,
    this.shadows,
  });

  final Animation<double> progress;
  final PopoverSide side;

  /// The trigger, in the overlay's coordinates: the mouth the sheet pours out
  /// of, and the point its neck leans towards.
  final ValueListenable<Rect> anchor;
  final List<BoxShadow>? shadows;
  final Widget child;

  @override
  State<_Genie> createState() => _GenieState();
}

class _GenieState extends State<_Genie> {
  bool _pouring = true;
  final SnapshotController _controller =
      SnapshotController(allowSnapshotting: true);

  /// Kept for the life of the pour rather than built in [build].
  ///
  /// A painter listens to the animation from its constructor, and a replaced
  /// one is never disposed by the framework — `SnapshotWidget` only drops its
  /// own listener. A fresh one per build would leave a listener on the
  /// controller for every rebuild the layer does.
  late _GeniePainter _painter = _buildPainter();

  _GeniePainter _buildPainter() => _GeniePainter(
        progress: widget.progress,
        side: widget.side,
        anchor: widget.anchor,
        shadows: widget.shadows,
      );

  @override
  void initState() {
    super.initState();
    widget.progress.addStatusListener(_onStatus);
    _pouring = !widget.progress.isCompleted;
    _controller.allowSnapshotting = _pouring;
  }

  @override
  void didUpdateWidget(_Genie old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      old.progress.removeStatusListener(_onStatus);
      widget.progress.addStatusListener(_onStatus);
    }
    if (old.progress != widget.progress ||
        old.side != widget.side ||
        old.anchor != widget.anchor ||
        old.shadows != widget.shadows) {
      _painter.dispose();
      _painter = _buildPainter();
    }
  }

  @override
  void dispose() {
    widget.progress.removeStatusListener(_onStatus);
    _painter.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Rasterising costs a picture per frame, so it stops the moment the surface
  /// has arrived — a settled popover is a plain widget again, with live text
  /// and working buttons.
  void _onStatus(AnimationStatus status) =>
      _setPouring(!widget.progress.isCompleted);

  /// Rasterising and the shadow move together.
  ///
  /// The surface gives up its own shadow exactly while it is being rasterised,
  /// so the two have to change on the same frame: one without the other is a
  /// frame with two shadows or with none, which is a visible step.
  ///
  /// A status can arrive mid-build — closing a popover by rebuilding its owner
  /// runs `close()` from `didUpdateWidget`, and the controller reports the
  /// change straight away — and marking this widget dirty then is not allowed.
  /// The pair is put off to after the frame instead, where they still change
  /// together and the surface stays a plain widget for one frame longer.
  void _setPouring(bool pouring) {
    if (pouring == _pouring) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setPouring(pouring);
      });
      return;
    }
    _controller.allowSnapshotting = pouring;
    setState(() => _pouring = pouring);
  }

  @override
  Widget build(BuildContext context) {
    return SnapshotWidget(
      controller: _controller,
      painter: _painter,
      child: PopoverSurface(
        shadowIsCastForYou: _pouring && widget.shadows != null,
        child: widget.child,
      ),
    );
  }
}

/// Tells the surface whether something else is drawing its shadow.
///
/// While the genie pours, the surface is drawn as a picture of its own size: a
/// shadow the surface draws itself is cropped to that size, and what is left is
/// a hard grey band around the sheet, sitting over the proper shadow. So the
/// sheet casts it and the surface goes without one until it lands.
class PopoverSurface extends InheritedWidget {
  /// Creates a [PopoverSurface].
  const PopoverSurface({
    super.key,
    required this.shadowIsCastForYou,
    required super.child,
  });

  /// Whether the surface below has already had its shadow drawn for it.
  final bool shadowIsCastForYou;

  /// Whether the surface should skip its own shadow. False anywhere else, so a
  /// popover surface can be built the same way wherever it is used.
  static bool shadowIsCast(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<PopoverSurface>()
          ?.shadowIsCastForYou ??
      false;

  @override
  bool updateShouldNotify(PopoverSurface old) =>
      old.shadowIsCastForYou != shadowIsCastForYou;
}

/// The genie's sheet: where each row of the card is drawn, and which part of
/// the card it shows.
///
/// The effect is not a shape that animates. It is a **funnel that stands
/// still** — narrow at the trigger, opening out to the card's full width a
/// little way along — and the card *flows through it*. A row's width is
/// decided by **where that row is at this moment**, not by its number in the
/// card: what is still inside the neck is squeezed, what has left it is whole.
/// Every wrong version of this came from tying the width to the row instead of
/// to its place.
///
/// Kept apart from the painting so the shape can be measured rather than
/// eyeballed. Not exported: this is the kit's own workings, open to its tests.
@visibleForTesting
class GenieMesh {
  /// Creates a [GenieMesh].
  const GenieMesh({required this.side, this.rows = 48});

  /// Which side of the trigger the card sits on. The card grows away from the
  /// trigger, so this says which of its edges is the mouth.
  final PopoverSide side;

  /// How many rows the sheet is cut into. Enough that the neck reads as a
  /// curve rather than a fan of facets; few enough to stay cheap.
  final int rows;

  bool get _vertical => side == PopoverSide.top || side == PopoverSide.bottom;

  /// Whether the mouth is the card's leading edge along the axis — true when
  /// the card sits below or to the right of its trigger.
  bool get _fromStart =>
      side == PopoverSide.bottom || side == PopoverSide.right;

  /// How much of the card's own length the neck reaches into.
  ///
  /// Nearly all of it. The funnel has to be long enough to be seen — the gap
  /// between a card and its trigger is only a few pixels — and long enough
  /// that the leading edge is still widening when it arrives: a short neck
  /// lets it out at full width while the rest is barely clear of the trigger,
  /// and the card reads as a wide lid with a spike under it.
  static const double neckLength = 0.9;

  /// Smooth at both ends, so the funnel's walls are curves — a straight taper
  /// is what makes a warp read as a trapezoid.
  /// How much of the shadow's own weight is showing at [t].
  ///
  /// It comes up over the first few frames rather than over the whole pour: a
  /// shadow that arrives with the sheet is not a shadow the sheet is casting.
  /// Short enough to be there from the start, long enough not to be a blob
  /// appearing under the trigger.
  static double shadowWeight(double t) => smooth((t * 6).clamp(0.0, 1.0));

  /// Smoothstep: eases [x] in and out, coming to rest at both ends.
  static double smooth(double x) {
    final c = x.clamp(0.0, 1.0);
    return c * c * (3 - 2 * c);
  }

  /// Smooth in its slope *and* its acceleration at both ends.
  ///
  /// A curve that merely starts and ends at rest still changes fastest in the
  /// middle, and the eye reads a change of speed as a jolt.
  static double smoother(double x) {
    final c = x.clamp(0.0, 1.0);
    return c * c * c * (c * (c * 6 - 15) + 10);
  }

  /// The sheet at [t], which is progress **already eased** by the animation's
  /// curve.
  ///
  /// Timing belongs to the curve and shape belongs here. Easing in both places
  /// double-counts it: the pour crawls, then bolts, and a curve handed in from
  /// outside barely shows.
  ///
  /// [mouthCross] is where the trigger's centre sits across the card, and
  /// [mouthWidth] how wide the trigger is against it — both as fractions of
  /// the card's cross axis. They are the throat of the funnel.
  GenieSheet build({
    required double t,
    required Offset offset,
    required Size size,
    required Size sourceSize,
    required double mouthCross,
    double mouthWidth = 0.12,
  }) {
    final progress = t.clamp(0.0, 1.0);

    // How far out of the trigger the card has come, along its own length —
    // the curve has already shaped this.
    final out = progress;

    // The row at the mouth never leaves the throat — the card ends up beside
    // its trigger, not across the room — so the funnel itself relaxes at the
    // end. Late, though: relax it from the start and the neck is gone before
    // the card has flowed through it, which is most of the effect.
    final settled = smooth(((progress - 0.45) / 0.55).clamp(0.0, 1.0));

    final throatCross = mouthCross.clamp(-0.5, 1.5);
    final throat = mouthWidth.clamp(0.02, 1.0);

    final positions = <Offset>[];
    final texture = <Offset>[];
    final indices = <int>[];

    for (var row = 0; row <= rows; row++) {
      // 0 at the card's mouth edge, 1 at its far edge.
      final u = row / rows;

      // Where this row is *now*, measured from the trigger along the card's
      // length. The card is drawn out of the trigger, so early on the whole of
      // it is still in the first fraction of the way.
      final at = u * out;

      // The funnel, fixed in that space: a throat at the trigger opening out
      // to the card's full width by `neckLength`. This is read at the row's
      // position — that is the whole of the effect.
      final open = smooth(at / neckLength);
      var width = throat + (1 - throat) * open;
      var centre = throatCross + (0.5 - throatCross) * open;

      // …and the funnel itself fades out as the card lands, so the settled
      // card is a plain rectangle rather than something still in a throat.
      width += (1 - width) * settled;
      centre += (0.5 - centre) * settled;

      final alongPos = _fromStart ? at : 1 - at;

      // Which part of the card this row shows. Rows run from the mouth, so a
      // card growing upwards reads its picture from the bottom up; reading it
      // the other way mirrors the sheet and stands the text on its head.
      final texAlong = _fromStart ? u : 1 - u;

      for (final edge in [-1.0, 1.0]) {
        final crossPos = centre + edge * 0.5 * width;
        positions.add(
          _vertical
              ? Offset(
                  offset.dx + crossPos * size.width,
                  offset.dy + alongPos * size.height,
                )
              : Offset(
                  offset.dx + alongPos * size.width,
                  offset.dy + crossPos * size.height,
                ),
        );
        texture.add(
          _vertical
              ? Offset(
                  (0.5 + edge * 0.5) * sourceSize.width,
                  texAlong * sourceSize.height,
                )
              : Offset(
                  texAlong * sourceSize.width,
                  (0.5 + edge * 0.5) * sourceSize.height,
                ),
        );
      }

      if (row > 0) {
        final a = (row - 1) * 2;
        indices.addAll([a, a + 1, a + 2, a + 1, a + 3, a + 2]);
      }
    }

    return GenieSheet(
      positions: positions,
      texture: texture,
      indices: indices,
    );
  }
}

/// One frame of [GenieMesh].
@visibleForTesting
class GenieSheet {
  /// Creates a [GenieSheet].
  const GenieSheet({
    required this.positions,
    required this.texture,
    required this.indices,
  });

  /// Where each vertex is drawn.
  final List<Offset> positions;

  /// Which point of the card's picture that vertex shows.
  final List<Offset> texture;

  /// Triangle list into [positions] and [texture], three entries per face.
  final List<int> indices;
}

class _GeniePainter extends SnapshotPainter {
  _GeniePainter({
    required this.progress,
    required this.side,
    required this.anchor,
    this.shadows,
  }) {
    progress.addListener(notifyListeners);
    anchor.addListener(notifyListeners);
  }

  final Animation<double> progress;
  final PopoverSide side;
  final ValueListenable<Rect> anchor;
  final List<BoxShadow>? shadows;

  @override
  void dispose() {
    progress.removeListener(notifyListeners);
    anchor.removeListener(notifyListeners);
    super.dispose();
  }

  /// Casts the surface's shadow from the sheet's own silhouette, under it.
  ///
  /// The picture the sheet is drawn from is the surface's own size, so the blur
  /// that spills past its edges is cropped out of it: without this there is no
  /// shadow at all until the pour ends.
  ///
  /// The shape follows the sheet, but the blur and the weight do not grow with
  /// it. Ramping the blur radius up from nothing leaves the early frames a hard
  /// grey slab with sharp corners — the shadow only looks like a shadow once it
  /// is fully blurred, so it is fully blurred from the first frame.
  void _paintGenieShadow(Canvas canvas, GenieSheet sheet, double t) {
    final list = shadows;
    if (list == null || list.isEmpty) return;

    final rows = sheet.positions.length ~/ 2;
    if (rows < 2) return;

    final vertical = side == PopoverSide.top || side == PopoverSide.bottom;
    // Rows run from the mouth away from it, whichever end that is.
    final away = (vertical
                ? sheet.positions[(rows - 1) * 2].dy - sheet.positions[0].dy
                : sheet.positions[(rows - 1) * 2].dx - sheet.positions[0].dx) >=
            0
        ? 1.0
        : -1.0;

    /// The silhouette, grown outwards by [inflate] — which is what a box
    /// shadow's spread does. Filling the shape and stroking it to twice the
    /// radius instead covers the same ground but doubles the opacity where the
    /// two overlap, and at a slow duration that reads as a ring.
    Path outline(double inflate) {
      Offset at(int row, int edge) {
        final p = sheet.positions[row * 2 + edge];
        // Edge 0 is the lower cross coordinate, so it moves the other way.
        final cross = edge == 0 ? -inflate : inflate;
        final along = row == 0
            ? -away * inflate
            : row == rows - 1
                ? away * inflate
                : 0.0;
        return vertical
            ? Offset(p.dx + cross, p.dy + along)
            : Offset(p.dx + along, p.dy + cross);
      }

      final path = Path()..moveTo(at(0, 0).dx, at(0, 0).dy);
      for (var row = 1; row < rows; row++) {
        path.lineTo(at(row, 0).dx, at(row, 0).dy);
      }
      for (var row = rows - 1; row >= 0; row--) {
        path.lineTo(at(row, 1).dx, at(row, 1).dy);
      }
      return path..close();
    }

    final alpha = GenieMesh.shadowWeight(t);
    // A blur is the dear part of drawing a shadow, and there is one per layer.
    // The first frames of the pour are below the point where any of them show.
    if (alpha <= 0) return;

    for (final shadow in list) {
      if (shadow.color.a * alpha < 1 / 255) continue;
      final path = outline(shadow.spreadRadius);
      canvas.drawPath(
        shadow.offset == Offset.zero ? path : path.shift(shadow.offset),
        Paint()
          ..color = shadow.color.withValues(alpha: shadow.color.a * alpha)
          ..maskFilter = shadow.blurSigma > 0
              ? MaskFilter.blur(BlurStyle.normal, shadow.blurSigma)
              : null,
      );
    }
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset,
    Size size,
    PaintingContextCallback painter,
  ) {
    // Called when there is no snapshot to draw — the first frame, a platform
    // that cannot rasterise, **and every frame once the surface has landed**,
    // because rasterising stops there. Better a plain fade than nothing.
    if (progress.isCompleted) {
      // A settled popover is a plain widget: painting it through an opacity of
      // 255 would leave a compositing layer under it for as long as it is open,
      // for nothing.
      painter(context, offset);
      return;
    }
    final list = shadows;
    // Only while the surface has given its shadow up. A settled popover draws
    // its own again, and casting one here as well stacks two — which is a
    // shadow that jumps wider the moment the pour ends and back the moment it
    // starts closing.
    if (list != null && !progress.isCompleted) {
      for (final shadow in list) {
        context.canvas.drawRect(
          (offset & size).shift(shadow.offset).inflate(shadow.spreadRadius),
          Paint()
            ..color = shadow.color
                .withValues(alpha: shadow.color.a * progress.value.clamp(0, 1))
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurSigma),
        );
      }
    }
    context.pushOpacity(offset, (progress.value * 255).round(), painter);
  }

  @override
  void paintSnapshot(
    PaintingContext context,
    Offset offset,
    Size size,
    ui.Image image,
    Size sourceSize,
    double pixelRatio,
  ) {
    final t = progress.value.clamp(0.0, 1.0);
    final vertical = side == PopoverSide.top || side == PopoverSide.bottom;
    // Where the mouth is across the sheet. The neck leans towards it, so a
    // card off to one side bends on its way out rather than opening
    // symmetrically — which is the difference between a genie and a trapezoid.
    final trigger = anchor.value;
    final mouth = trigger.center - offset;
    final mouthCross = vertical
        ? (size.width == 0 ? 0.5 : mouth.dx / size.width)
        : (size.height == 0 ? 0.5 : mouth.dy / size.height);
    // The throat is as wide as the trigger: the card is drawn out of the thing
    // that opened it, not out of a slot of some arbitrary size.
    final mouthWidth = vertical
        ? (size.width == 0 ? 0.12 : trigger.width / size.width)
        : (size.height == 0 ? 0.12 : trigger.height / size.height);

    final sheet = GenieMesh(side: side).build(
      t: t,
      offset: offset,
      size: size,
      sourceSize: sourceSize,
      mouthCross: mouthCross,
      mouthWidth: mouthWidth,
    );

    // Draw the flowing Genie shadow behind the mesh
    _paintGenieShadow(context.canvas, sheet, t);

    if (t >= 1) {
      context.canvas.drawImageRect(
        image,
        Offset.zero & sourceSize,
        offset & size,
        Paint(),
      );
      return;
    }

    final paint = Paint()
      ..shader = ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
      )
      // Fades in over the first part of the pour only: a sheet that is still
      // half transparent when it lands looks like a fade, not a genie.
      ..color = const Color(0xFFFFFFFF)
          .withValues(alpha: GenieMesh.smooth(t * 2.5).clamp(0.0, 1.0));

    context.canvas.drawVertices(
      ui.Vertices(
        VertexMode.triangles,
        sheet.positions,
        textureCoordinates: sheet.texture,
        indices: sheet.indices,
      ),
      BlendMode.srcOver,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GeniePainter old) =>
      old.progress.value != progress.value ||
      old.side != side ||
      old.shadows != shadows;
}

/// A dismiss barrier covering everything except a rectangular [hole] (the
/// anchor), built from four strips so taps in the hole fall through to the
/// trigger below.
class _HoleBarrier extends StatelessWidget {
  const _HoleBarrier({
    required this.hole,
    required this.onTap,
    this.color,
  });

  final Rect hole;
  final VoidCallback onTap;
  final Color? color;

  Widget get _strip => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: color != null ? Container(color: color) : null,
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(left: 0, top: 0, right: 0, height: hole.top, child: _strip),
        Positioned(
          left: 0,
          top: hole.bottom,
          right: 0,
          bottom: 0,
          child: _strip,
        ),
        Positioned(
          left: 0,
          top: hole.top,
          width: hole.left,
          height: hole.height,
          child: _strip,
        ),
        Positioned(
          left: hole.right,
          top: hole.top,
          right: 0,
          height: hole.height,
          child: _strip,
        ),
      ],
    );
  }
}

/// Positions the popover near its anchor, flipping to the opposite side when
/// the preferred side lacks room and shifting to keep it within the viewport.
class PopoverLayoutDelegate extends SingleChildLayoutDelegate {
  /// Creates a [PopoverLayoutDelegate].
  PopoverLayoutDelegate({
    required this.anchor,
    required this.placement,
    required this.gap,
    required this.viewportPadding,
    this.arrowSink,
    this.decisionSize,
  });

  /// The trigger's rect in overlay coordinates — where the sheet pours from.
  final Rect anchor;

  /// Which side of the anchor the sheet grows toward.
  final PopoverPlacement placement;

  /// Space kept between the anchor and the sheet, in logical pixels.
  final double gap;

  /// Space kept between the sheet and the viewport edges.
  final EdgeInsets viewportPadding;

  /// Receives the caret geometry once the bubble is measured. Written during
  /// layout, so listeners repaint on the following frame.
  final ValueNotifier<PopoverArrowGeometry?>? arrowSink;

  /// The size to judge *which side* the bubble goes on, when that is not the
  /// size it is being laid out at — a bubble easing between two sizes would
  /// otherwise change its mind halfway there.
  final Size? decisionSize;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The popover may size itself freely, up to the room the viewport leaves.
    return BoxConstraints.loose(
      Size(
        constraints.maxWidth - viewportPadding.horizontal,
        constraints.maxHeight - viewportPadding.vertical,
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final side = _resolveSide(size, decisionSize ?? childSize);

    double x, y;
    if (side == PopoverSide.top || side == PopoverSide.bottom) {
      y = side == PopoverSide.top
          ? anchor.top - gap - childSize.height
          : anchor.bottom + gap;
      x = _crossAxis(
        anchorStart: anchor.left,
        anchorExtent: anchor.width,
        childExtent: childSize.width,
        align: placement.align,
        min: viewportPadding.left,
        max: size.width - viewportPadding.right - childSize.width,
      );
    } else {
      x = side == PopoverSide.left
          ? anchor.left - gap - childSize.width
          : anchor.right + gap;
      y = _crossAxis(
        anchorStart: anchor.top,
        anchorExtent: anchor.height,
        childExtent: childSize.height,
        align: placement.align,
        min: viewportPadding.top,
        max: size.height - viewportPadding.bottom - childSize.height,
      );
    }

    // Final safety net: flip handles the common case, but when neither side of
    // the anchor has room, the main-axis position above can still overflow.
    // Clamp both axes so the popover is always fully on screen.
    x = _clampInto(
      x,
      viewportPadding.left,
      size.width - viewportPadding.right - childSize.width,
    );
    y = _clampInto(
      y,
      viewportPadding.top,
      size.height - viewportPadding.bottom - childSize.height,
    );

    if (arrowSink != null) {
      _emitArrow(side, Offset(x, y), childSize);
    }
    return Offset(x, y);
  }

  /// Places the caret on the bubble edge facing the anchor, aligned to the
  /// anchor's centre but kept clear of the rounded corners.
  void _emitArrow(PopoverSide side, Offset bubble, Size childSize) {
    const inset = popoverArrowWidth / 2 + 8; // half-caret + corner radius
    PopoverArrowGeometry geometry;
    if (side == PopoverSide.top || side == PopoverSide.bottom) {
      final lo = bubble.dx + inset;
      final hi = bubble.dx + childSize.width - inset;
      // When the bubble is too narrow for the inset band, centre the caret on
      // the bubble rather than jamming it against a corner.
      final cx = hi < lo
          ? bubble.dx + childSize.width / 2
          : anchor.center.dx.clamp(lo, hi);
      final edgeY =
          side == PopoverSide.top ? bubble.dy + childSize.height : bubble.dy;
      geometry = PopoverArrowGeometry(Offset(cx, edgeY), side);
    } else {
      final lo = bubble.dy + inset;
      final hi = bubble.dy + childSize.height - inset;
      final cy = hi < lo
          ? bubble.dy + childSize.height / 2
          : anchor.center.dy.clamp(lo, hi);
      final edgeX =
          side == PopoverSide.left ? bubble.dx + childSize.width : bubble.dx;
      geometry = PopoverArrowGeometry(Offset(edgeX, cy), side);
    }
    // Never mutate a notifier synchronously inside layout.
    if (arrowSink!.value != geometry) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        arrowSink!.value = geometry;
      });
    }
  }

  /// Clamps [value] to `[min, max]`, tolerating a viewport smaller than the
  /// child (where `max` falls below `min`).
  double _clampInto(double value, double min, double max) =>
      value.clamp(min, max < min ? min : max);

  /// Flips the preferred side to its opposite when the preferred one cannot
  /// fit the child but the opposite can.
  PopoverSide _resolveSide(Size size, Size childSize) {
    final side = placement.side;
    final need = (side == PopoverSide.top || side == PopoverSide.bottom)
        ? childSize.height
        : childSize.width;

    final roomTop = anchor.top - gap - viewportPadding.top;
    final roomBottom =
        size.height - viewportPadding.bottom - anchor.bottom - gap;
    final roomLeft = anchor.left - gap - viewportPadding.left;
    final roomRight = size.width - viewportPadding.right - anchor.right - gap;

    // First choice: the side asked for. Second: the opposite one, if the room
    // is there. Third: the other axis — on a phone a wide bubble fits neither
    // left nor right of its anchor, and clamping it into the viewport would
    // lay it over the very thing it points at.
    final flipped = switch (side) {
      PopoverSide.top => (
          need > roomTop && roomBottom >= need,
          PopoverSide.bottom
        ),
      PopoverSide.bottom => (
          need > roomBottom && roomTop >= need,
          PopoverSide.top
        ),
      PopoverSide.left => (
          need > roomLeft && roomRight >= need,
          PopoverSide.right
        ),
      PopoverSide.right => (
          need > roomRight && roomLeft >= need,
          PopoverSide.left
        ),
    };
    if (flipped.$1) return flipped.$2;

    final room = switch (side) {
      PopoverSide.top => roomTop,
      PopoverSide.bottom => roomBottom,
      PopoverSide.left => roomLeft,
      PopoverSide.right => roomRight,
    };
    if (room >= need) return side;

    // Neither side of this axis will take it: cross over to the axis that
    // will, preferring the roomier of its two sides.
    final horizontal = side == PopoverSide.left || side == PopoverSide.right;
    final acrossNeed = horizontal ? childSize.height : childSize.width;
    final (nearRoom, nearSide, farRoom, farSide) = horizontal
        ? (roomBottom, PopoverSide.bottom, roomTop, PopoverSide.top)
        : (roomRight, PopoverSide.right, roomLeft, PopoverSide.left);

    if (nearRoom >= acrossNeed || nearRoom >= farRoom) {
      if (nearRoom >= acrossNeed || farRoom < acrossNeed) return nearSide;
    }
    return farRoom >= acrossNeed ? farSide : side;
  }

  /// Aligns the child along the anchor's cross axis, then clamps it into the
  /// viewport.
  double _crossAxis({
    required double anchorStart,
    required double anchorExtent,
    required double childExtent,
    required double align,
    required double min,
    required double max,
  }) {
    // align: -1 starts at the anchor edge, 0 centres, 1 ends at it.
    final double pos = switch (align) {
      -1 => anchorStart,
      1 => anchorStart + anchorExtent - childExtent,
      _ => anchorStart + (anchorExtent - childExtent) / 2,
    };
    return _clampInto(pos, min, max);
  }

  @override
  bool shouldRelayout(PopoverLayoutDelegate old) =>
      old.anchor != anchor ||
      old.placement != placement ||
      old.gap != gap ||
      old.decisionSize != decisionSize ||
      old.viewportPadding != viewportPadding;
}

/// Width of the caret's base, and how far it protrudes toward the anchor.
const double popoverArrowWidth = 17.5;

/// How far the caret protrudes from the bubble toward its anchor.
const double popoverArrowLength = 9.5;

/// The resolved caret: the point on the bubble edge it springs from, and which
/// edge that is.
@immutable
class PopoverArrowGeometry {
  /// Creates a [PopoverArrowGeometry].
  const PopoverArrowGeometry(this.base, this.side);

  /// Centre of the caret's base, on the bubble edge, in overlay coordinates.
  final Offset base;

  /// Which bubble edge the caret springs from.
  final PopoverSide side;

  /// The same caret, moved — for a bubble that is on its way somewhere.
  PopoverArrowGeometry shifted(Offset by) =>
      PopoverArrowGeometry(base + by, side);

  @override
  bool operator ==(Object other) =>
      other is PopoverArrowGeometry && other.base == base && other.side == side;

  @override
  int get hashCode => Object.hash(base, side);
}

/// A widget that shows an anchored [content] popover around its [child].
///
/// Wrap the trigger and describe the floating content; the popover positions
/// itself around the trigger, flipping and shifting to stay on screen.
/// Components with richer behaviour (Popconfirm, Dropdown) build directly on
/// [PopoverController] instead.
/// A floating surface anchored to a trigger — the layer the kit's components
/// stand on rather than a component itself.
///
/// It positions and nothing more: [Popover], [Tooltip], [Dropdown], [Select],
/// [Popconfirm] and [Tour] each give it a surface of their own and decide what
/// opens it. A caller who wants a card with a title and a body wants [Popover];
/// this is for building something the kit has not got.
class PopoverLayer extends StatefulWidget {
  /// Creates a [PopoverLayer].
  const PopoverLayer({
    super.key,
    required this.child,
    required this.content,
    this.placement = PopoverPlacement.top,
    this.open,
    this.onOpenChanged,
    this.gap = 8,
    this.dismissOnOutsideTap = true,
    this.interactive = true,
    this.arrowColor,
    this.arrowShadow,
    this.barrierColor,
    this.animation = PopoverAnimation.simple,
    this.duration,
    this.curve,
  });

  /// How the surface arrives — a fade and a grow, or the genie.
  final PopoverAnimation animation;

  /// How long it takes to arrive, and on what curve. Null takes the pace the
  /// [animation] wants.
  final Duration? duration;

  /// The curve the arrival runs on. Null takes the pace the [animation] wants.
  final Curve? curve;

  /// The trigger the popover anchors to.
  final Widget child;

  /// Builds the floating content.
  final WidgetBuilder content;

  /// Which side of the trigger the popover prefers.
  final PopoverPlacement placement;

  /// Drives visibility externally. Null lets the popover manage its own state
  /// via [onOpenChanged].
  final bool? open;

  /// Notified when the popover wants to open or close (outside tap, etc.).
  final ValueChanged<bool>? onOpenChanged;

  /// Distance between the trigger and the popover, in logical pixels.
  final double gap;

  /// Whether tapping outside dismisses the popover.
  final bool dismissOnOutsideTap;

  /// When false the content ignores pointer events. Set it for tooltips, so
  /// the floating text cannot steal hover from the widgets beneath it.
  final bool interactive;

  /// When non-null, draws a caret of this colour pointing at the trigger. Use
  /// the popover content's own background colour so the two read as one shape.
  final Color? arrowColor;

  /// Shadow drawn under the caret. Pass the content's own shadow so the caret
  /// and bubble read as a single surface.
  final List<BoxShadow>? arrowShadow;

  /// Tint painted over the page behind an open popover. Null leaves it clear.
  final Color? barrierColor;

  @override
  State<PopoverLayer> createState() => PopoverLayerState();
}

/// State for a [PopoverLayer], exposed so an enclosing widget can reach the
/// layer's [PopoverController] through a [GlobalKey].
class PopoverLayerState extends State<PopoverLayer> {
  final PopoverController _controller = PopoverController();

  @override
  void initState() {
    super.initState();
    if (widget.open ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _show());
    }
  }

  @override
  void didUpdateWidget(PopoverLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // An open popover shows what it was given when it opened. Rebuilding the
    // page does not reach into the overlay, so a surface that reads changing
    // state — a count, a selection, a form — would sit there stale.
    //
    // After the frame: this runs inside a build, and the overlay entry is
    // another part of the tree.
    if (_controller.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.markNeedsBuild();
      });
    }

    if (widget.open != null && widget.open != oldWidget.open) {
      if (widget.open!) {
        // Inserting an overlay entry marks the Overlay dirty, which is illegal
        // during the build this update runs in — defer to after the frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && (widget.open ?? false)) _show();
        });
      } else {
        _controller.close();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _requestClose() {
    // The layer closes on its own account — an outside tap, a scroll — and by
    // then its owner may be gone from the tree. Reporting to a dead state is
    // an error, and the layer is going away regardless.
    if (!mounted) return;
    if (widget.onOpenChanged != null) {
      widget.onOpenChanged!(false);
    } else {
      _controller.close();
    }
  }

  void _show() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final topLeft = box.localToGlobal(Offset.zero);
    _controller.open(
      builder: widget.content,
      placement: widget.placement,
      anchorRect: topLeft & box.size,
      gap: widget.gap,
      onDismiss: widget.dismissOnOutsideTap ? _requestClose : null,
      interactive: widget.interactive,
      arrowColor: widget.arrowColor,
      arrowShadow: widget.arrowShadow,
      barrierColor: widget.barrierColor,
      animation: widget.animation,
      duration: widget.duration,
      curve: widget.curve,
      anchorContext: context,
      onScrollDismiss: _requestClose,
    );
  }

  /// Opens the popover. Useful when driving it imperatively.
  void open() =>
      widget.onOpenChanged != null ? widget.onOpenChanged!(true) : _show();

  /// Closes the popover.
  void close() => _requestClose();

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Paints the caret as a solid triangle in the bubble's own colour, drawn over
/// the bubble so its base overlaps the edge by 1px — no seam, no border. A
/// single soft shadow cast *outward* (toward the anchor) keeps the tip visible
/// on a light surface without laying a band across the bubble.
class PopoverArrowPainter extends CustomPainter {
  /// Creates a [PopoverArrowPainter].
  const PopoverArrowPainter(
    this.geometry,
    this.color, {
    this.drawShadow = true,
  });

  /// Where the caret sits and which edge it springs from.
  final PopoverArrowGeometry geometry;

  /// The caret's fill, matching the bubble it belongs to.
  final Color color;

  /// Whether to lay a shadow under the caret as well as fill it.
  final bool drawShadow;

  static const double _width = 18.0;
  static const double _length = 9.0;

  @override
  void paint(Canvas canvas, Size size) {
    const half = _width / 2;
    const len = _length;
    const overlap = 1.0;

    const roundFactor = 0.25;

    const double bevel = len * roundFactor;
    const double baseBevel = half * roundFactor;

    final b = geometry.base;

    late final Path path;
    late final Offset out;

    late final Rect clipRect;

    switch (geometry.side) {
      case PopoverSide.top:
        path = Path()
          ..moveTo(b.dx - half, b.dy - overlap)
          ..lineTo(b.dx + half, b.dy - overlap)
          ..lineTo(b.dx + baseBevel, b.dy + len - bevel)
          ..cubicTo(
            b.dx + baseBevel / 2,
            b.dy + len,
            b.dx - baseBevel / 2,
            b.dy + len,
            b.dx - baseBevel,
            b.dy + len - bevel,
          )
          ..close();
        out = const Offset(0, 1);
        clipRect = Rect.fromLTRB(
          b.dx - half - 10,
          b.dy - overlap,
          b.dx + half + 10,
          b.dy + len + 10,
        );

      case PopoverSide.bottom:
        path = Path()
          ..moveTo(b.dx - half, b.dy + overlap)
          ..lineTo(b.dx + half, b.dy + overlap)
          ..lineTo(b.dx + baseBevel, b.dy - len + bevel)
          ..cubicTo(
            b.dx + baseBevel / 2,
            b.dy - len,
            b.dx - baseBevel / 2,
            b.dy - len,
            b.dx - baseBevel,
            b.dy - len + bevel,
          )
          ..close();
        out = const Offset(0, -1);
        clipRect = Rect.fromLTRB(
          b.dx - half - 10,
          b.dy - len - 10,
          b.dx + half + 10,
          b.dy + overlap,
        );

      case PopoverSide.left:
        path = Path()
          ..moveTo(b.dx - overlap, b.dy - half)
          ..lineTo(b.dx - overlap, b.dy + half)
          ..lineTo(b.dx + len - bevel, b.dy + baseBevel)
          ..cubicTo(
            b.dx + len,
            b.dy + baseBevel / 2,
            b.dx + len,
            b.dy - baseBevel / 2,
            b.dx + len - bevel,
            b.dy - baseBevel,
          )
          ..close();
        out = const Offset(1, 0);
        clipRect = Rect.fromLTRB(
          b.dx - overlap,
          b.dy - half - 10,
          b.dx + len + 10,
          b.dy + half + 10,
        );

      case PopoverSide.right:
        path = Path()
          ..moveTo(b.dx + overlap, b.dy - half)
          ..lineTo(b.dx + overlap, b.dy + half)
          ..lineTo(b.dx - len + bevel, b.dy + baseBevel)
          ..cubicTo(
            b.dx - len,
            b.dy + baseBevel / 2,
            b.dx - len,
            b.dy - baseBevel / 2,
            b.dx - len + bevel,
            b.dy - baseBevel,
          )
          ..close();
        out = const Offset(-1, 0);
        clipRect = Rect.fromLTRB(
          b.dx - len - 10,
          b.dy - half - 10,
          b.dx + overlap,
          b.dy + half + 10,
        );
    }

    if (drawShadow) {
      canvas.save();
      canvas.clipRect(clipRect);
      canvas.translate(out.dx * 1.5, out.dy * 1.5);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0x33000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.restore();
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(PopoverArrowPainter old) =>
      old.geometry != geometry ||
      old.color != color ||
      old.drawShadow != drawShadow;
}
