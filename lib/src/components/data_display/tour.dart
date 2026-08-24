import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/widgets.dart';

import '../../icons/icons.dart' show CrossPainter;
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/popover.dart';
import '../general/button.dart';

/// How a tour panel is painted.
enum TourType {
  /// A surface panel with the theme's own text colours.
  normal,

  /// The panel takes the accent colour and light text on top of it.
  primary,
}

/// Where a tour panel sits relative to the step's target.
///
/// The twelve edge placements are [PopoverPlacement]'s; [center] ignores the
/// target and puts the panel in the middle of the screen — how a tour that has
/// nothing to point at yet opens.
enum TourPlacement {
  /// In the middle of the screen, pointing at nothing.
  center,

  /// Above the target, centred on it.
  top,

  /// Above the target, left edges aligned.
  topLeft,

  /// Above the target, right edges aligned.
  topRight,

  /// Below the target, centred on it.
  bottom,

  /// Below the target, left edges aligned.
  bottomLeft,

  /// Below the target, right edges aligned.
  bottomRight,

  /// Left of the target, centred on it.
  left,

  /// Left of the target, top edges aligned.
  leftTop,

  /// Left of the target, bottom edges aligned.
  leftBottom,

  /// Right of the target, centred on it.
  right,

  /// Right of the target, top edges aligned.
  rightTop,

  /// Right of the target, bottom edges aligned.
  rightBottom;

  PopoverPlacement? get _popover => switch (this) {
        TourPlacement.center => null,
        TourPlacement.top => PopoverPlacement.top,
        TourPlacement.topLeft => PopoverPlacement.topLeft,
        TourPlacement.topRight => PopoverPlacement.topRight,
        TourPlacement.bottom => PopoverPlacement.bottom,
        TourPlacement.bottomLeft => PopoverPlacement.bottomLeft,
        TourPlacement.bottomRight => PopoverPlacement.bottomRight,
        TourPlacement.left => PopoverPlacement.left,
        TourPlacement.leftTop => PopoverPlacement.leftTop,
        TourPlacement.leftBottom => PopoverPlacement.leftBottom,
        TourPlacement.right => PopoverPlacement.right,
        TourPlacement.rightTop => PopoverPlacement.rightTop,
        TourPlacement.rightBottom => PopoverPlacement.rightBottom,
      };
}

/// The room the highlight leaves around a target, and how round its corners
/// are.
@immutable
class TourGap {
  /// Creates a [TourGap].
  const TourGap({this.offset = 6, this.offsetX, this.offsetY, this.radius = 2});

  /// How far the hole reaches past the target on every side.
  final double offset;

  /// Per-axis overrides, for a target that wants more room one way than the
  /// other — the array form of `offset`.
  final double? offsetX;

  /// Vertical spotlight padding, overriding the shared gap.
  final double? offsetY;

  /// Corner radius of the hole.
  final double radius;

  double get _x => offsetX ?? offset;
  double get _y => offsetY ?? offset;

  /// The hole this gap cuts around [target].
  RRect holeFor(Rect target) => RRect.fromRectAndRadius(
        Rect.fromLTRB(
          target.left - _x,
          target.top - _y,
          target.right + _x,
          target.bottom + _y,
        ),
        Radius.circular(radius),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TourGap &&
          offset == other.offset &&
          offsetX == other.offsetX &&
          offsetY == other.offsetY &&
          radius == other.radius;

  @override
  int get hashCode => Object.hash(offset, offsetX, offsetY, radius);
}

/// Whether a tour dims the page behind it, and in what colour.
@immutable
class TourMask {
  /// Creates a [TourMask].
  const TourMask({this.show = true, this.color});

  /// No dimming at all: the tour reads as a series of popovers.
  static const TourMask none = TourMask(show: false);

  /// Whether the page behind is dimmed.
  final bool show;

  /// Overrides the dimming colour.
  final Color? color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TourMask && show == other.show && color == other.color;

  @override
  int get hashCode => Object.hash(show, color);
}

/// How one of a step's buttons is drawn and what it does.
///
/// Everything is optional: what is left out keeps the tour's own answer, so
/// `TourButton(label: Text('Got it'))` renames the button and changes nothing
/// else.
@immutable
class TourButton {
  /// Creates a [TourButton].
  const TourButton({
    this.label,
    this.icon,
    this.onPressed,
    this.variant,
    this.color,
    this.disabled = false,
  }) : builder = null;

  /// A button of your own in place of the tour's.
  ///
  /// The builder is handed the action the tour would have run — moving on,
  /// going back, finishing — so your widget only has to decide what it looks
  /// like and when to call it. It is null while [disabled], so a button that
  /// respects it reads as off.
  ///
  /// ```dart
  /// nextButton: TourButton.custom(
  ///   (context, act) => Button(
  ///     shape: ButtonShape.round,
  ///     variant: ButtonVariant.solid,
  ///     color: ButtonColor.primary,
  ///     onPressed: act,
  ///     child: const Text('Take the tour →'),
  ///   ),
  /// )
  /// ```
  const TourButton.custom(
    this.builder, {
    this.onPressed,
    this.disabled = false,
  })  : label = null,
        icon = null,
        variant = null,
        color = null;

  /// Replaces the button's text.
  final Widget? label;

  /// An icon beside the label.
  final Widget? icon;

  /// Called *as well as* moving the tour — the button is
  /// still the tour's, this is your hook into it.
  final VoidCallback? onPressed;

  /// Overrides the button's variant.
  final ButtonVariant? variant;

  /// Overrides the button's colour.
  final ButtonColor? color;

  /// Greys the button out and stops it working. The step then cannot be left
  /// by that button — useful while something on the page is unfinished.
  final bool disabled;

  /// Builds a button of your own; see [TourButton.custom].
  final Widget Function(BuildContext context, VoidCallback? act)? builder;
}

/// One stop on a [Tour].
@immutable
class TourStep {
  /// Creates a [TourStep].
  const TourStep({
    this.target,
    this.title,
    this.description,
    this.cover,
    this.placement,
    this.type,
    this.mask,
    this.gap,
    this.arrow,
    this.closable,
    this.closeIcon,
    this.dismissible,
    this.scrollIntoView,
    this.nextButton,
    this.prevButton,
  });

  /// The widget this step points at, by its [GlobalKey]. Null puts the panel in
  /// the middle of the screen with nothing highlighted.
  final GlobalKey? target;

  /// The step's heading.
  final Widget? title;

  /// What the step explains.
  final Widget? description;

  /// A picture or video above the heading.
  final Widget? cover;

  /// Where the panel sits relative to the target. Null takes the tour's own.
  final TourPlacement? placement;

  /// Overrides the tour's [Tour.type] for this step alone.
  final TourType? type;

  /// Overrides the tour's [Tour.mask] for this step alone.
  final TourMask? mask;

  /// Overrides the tour's [Tour.gap] for this step alone.
  final TourGap? gap;

  /// Whether a caret points at the target. Null takes the tour's own.
  final bool? arrow;

  /// Whether the panel carries a close button. Null takes the tour's own.
  final bool? closable;

  /// This step's close icon, in place of the tour's.
  final Widget? closeIcon;

  /// Whether a tap on the mask closes the tour here. Null takes the tour's own.
  final bool? dismissible;

  /// Whether the page scrolls to bring this step's target into view. Null
  /// takes the tour's own.
  final bool? scrollIntoView;

  /// The next (or, on the last step, finish) button — its label, its look and
  /// a hook into its press.
  final TourButton? nextButton;

  /// The previous button, on every step but the first.
  final TourButton? prevButton;
}

/// Drives a [Tour] from outside the widget.
///
/// ```dart
/// final tour = TourController();
/// ...
/// Button(onPressed: tour.open, child: const Text('Show me around'));
/// Tour(controller: tour, steps: steps);
/// ```
///
/// Dispose it with the widget that owns it.
class TourController extends ChangeNotifier {
  /// Creates a [TourController].
  TourController({int current = 0}) : _current = current;

  int _current;
  bool _open = false;
  int _length = 0;

  /// The step being shown, counting from zero.
  int get current => _current;

  /// Whether the tour is on screen.
  bool get isOpen => _open;

  /// Starts the tour from the beginning, or at [step] when one is named.
  ///
  /// A tour is started, not resumed: pressing "Begin tour" a second time shows
  /// the first step again. [resume] is the other intent.
  void open([int? step]) {
    _current = (step ?? 0).clamp(0, _length > 0 ? _length - 1 : 0);
    _open = true;
    notifyListeners();
  }

  /// Puts it back on screen where it left off.
  void resume() {
    if (_open) return;
    _open = true;
    notifyListeners();
  }

  /// Takes it off the screen, leaving the current step where it is, so a
  /// [resume] carries on from here.
  void close() {
    if (!_open) return;
    _open = false;
    notifyListeners();
  }

  /// Moves on, finishing the tour after the last step.
  void next() {
    if (_current >= _length - 1) {
      close();
      return;
    }
    goTo(_current + 1);
  }

  /// Goes back, stopping at the first step.
  void previous() => goTo(_current - 1);

  /// Jumps to [index], clamped to the steps that exist.
  void goTo(int index) {
    final limit = _length > 0 ? _length - 1 : 0;
    final clamped = index.clamp(0, limit);
    if (clamped == _current) return;
    _current = clamped;
    notifyListeners();
  }
}

/// Per-component design tokens for [Tour] — its own token table.
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(tour: TourToken(...)))`, or per instance via [Tour.token].
@immutable
class TourToken {
  /// Creates a [TourToken].
  const TourToken({
    this.width,
    this.closeBtnSize,
    this.indicatorSize,
    this.maskColor,
    this.primaryPrevBtnBg,
    this.travelDuration,
    this.travelCurve,
  });

  /// The widest a panel may be (`width`, 520 ).
  final double? width;

  /// Size of the close button (`closeBtnSize`).
  final double? closeBtnSize;

  /// Diameter of a step indicator dot.
  final double? indicatorSize;

  /// Colour the page is dimmed with.
  final Color? maskColor;

  /// Fill of the previous button, and of the spent indicators, in a primary
  /// panel (`primaryPrevBtnBg`).
  final Color? primaryPrevBtnBg;

  /// How long the highlight takes to travel from one step to the next.
  /// [Duration.zero] moves it in one frame.
  final Duration? travelDuration;

  /// The curve it travels on.
  final Curve? travelCurve;

  _ResolvedTourToken _resolve(Token t) => _ResolvedTourToken(
        width: width ?? 520,
        closeBtnSize: closeBtnSize ?? t.fontSize * t.lineHeight,
        indicatorSize: indicatorSize ?? 6,
        maskColor: maskColor ?? const Color(0x80000000),
        primaryPrevBtnBg:
            primaryPrevBtnBg ?? const Color(0xFFFFFFFF).withValues(alpha: 0.15),
        travelDuration: travelDuration ?? t.motionDurationSlow,
        travelCurve: travelCurve ?? t.motionEaseInOut,
      );
}

@immutable
class _ResolvedTourToken {
  const _ResolvedTourToken({
    required this.width,
    required this.closeBtnSize,
    required this.indicatorSize,
    required this.maskColor,
    required this.primaryPrevBtnBg,
    required this.travelDuration,
    required this.travelCurve,
  });

  final double width;
  final double closeBtnSize;
  final double indicatorSize;
  final Color maskColor;
  final Color primaryPrevBtnBg;
  final Duration travelDuration;
  final Curve travelCurve;
}

/// A guided walk through a screen.
///
/// Each step points at a widget of yours, given by its [GlobalKey]: the page
/// behind is dimmed except for a hole over the target, and a panel explains it.
///
/// ```dart
/// final _search = GlobalKey();
/// final _tour = TourController();
/// ...
/// Input(key: _search);
/// Tour(controller: _tour, steps: [
///   TourStep(
///     target: _search,
///     title: const Text('Search'),
///     description: const Text('Find anything from here.'),
///   ),
/// ]);
/// ```
///
/// The widget itself takes no room; it drives an overlay.
class Tour extends StatefulWidget {
  /// Creates a [Tour].
  const Tour({
    super.key,
    required this.steps,
    this.controller,
    this.open,
    this.current,
    this.onChange,
    this.onClose,
    this.onFinish,
    this.type = TourType.normal,
    this.placement = TourPlacement.bottom,
    this.mask = const TourMask(),
    this.gap = const TourGap(),
    this.arrow = true,
    this.closable = true,
    this.closeIcon,
    this.dismissible = true,
    this.scrollIntoView = true,
    this.disabledInteraction = false,
    this.duration,
    this.curve,
    this.indicatorsBuilder,
    this.actionsBuilder,
    this.token,
  });

  /// The stops, in order.
  final List<TourStep> steps;

  /// Drives the tour from outside.
  final TourController? controller;

  /// Whether the tour is on screen (controlled). Null leaves it to the
  /// [controller].
  final bool? open;

  /// The step being shown (controlled).
  final int? current;

  /// Called with the step the tour moved to.
  final ValueChanged<int>? onChange;

  /// Called when the tour is dismissed — by the close button, the mask or the
  /// last step's finish.
  final VoidCallback? onClose;

  /// Called when the last step's button is pressed, before [onClose].
  final VoidCallback? onFinish;

  /// How the panels are painted.
  final TourType type;

  /// Where a panel sits relative to its target.
  final TourPlacement placement;

  /// Whether the page behind is dimmed, and in what colour.
  final TourMask mask;

  /// The room the highlight leaves around a target.
  final TourGap gap;

  /// Whether a caret points at the target.
  final bool arrow;

  /// Whether panels carry a close button.
  final bool closable;

  /// The close button's icon. Null draws the kit's own cross; a step may take
  /// one of its own through [TourStep.closeIcon].
  final Widget? closeIcon;

  /// Whether a tap on the mask closes the tour.
  ///
  /// The mask still swallows the tap either way — the page behind a tour is
  /// not to be clicked by accident — but with this off the tour can only be
  /// left by its own buttons. A step may say otherwise through
  /// [TourStep.dismissible].
  final bool dismissible;

  /// Whether the page scrolls to bring a step's target into view.
  ///
  /// A tour that walks past the fold is no use if the reader has to find the
  /// target themselves. Every scrollable between the target and the screen is
  /// asked to reveal it, and only when it is not comfortably in view already —
  /// a step whose target is on screen leaves the page where it is.
  final bool scrollIntoView;

  /// Blocks taps on the highlighted target. By default the hole in the mask
  /// lets them through, so a tour can walk you through a real interaction.
  final bool disabledInteraction;

  /// How long the highlight and the panel take to travel from one step to the
  /// next. Null takes [TourToken.travelDuration]; [Duration.zero] moves them
  /// in one frame.
  final Duration? duration;

  /// The curve they travel on. Null takes [TourToken.travelCurve].
  final Curve? curve;

  /// Replaces the row of step dots.
  final Widget Function(BuildContext context, int current, int total)?
      indicatorsBuilder;

  /// Replaces the buttons. [actions] is what the tour would have drawn, so a
  /// caller can add to it rather than rebuild it.
  final Widget Function(
    BuildContext context,
    Widget actions,
    int current,
    int total,
  )? actionsBuilder;

  /// Per-instance token overrides.
  final TourToken? token;

  @override
  State<Tour> createState() => _TourState();
}

class _TourState extends State<Tour> with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;

  /// Kept from the moment the entry goes in, so the watch never has to look it
  /// up through a context that may be on its way out of the tree.
  OverlayState? _overlay;

  /// Used when the tour brought no controller of its own.
  late final TourController _fallback = TourController(
    current: widget.current ?? 0,
  );

  TourController get _controller => widget.controller ?? _fallback;

  /// The spotlight's own journey between steps. A target that moves under an
  /// open tour — a page scrolling — is followed at once; only a change of step
  /// is travelled.
  ///
  /// Made in [initState] rather than on first use: a `vsync` looks up the
  /// ticker mode through the context, and a tour that was never opened would
  /// do that from `dispose`, where the tree is already coming apart.
  late final AnimationController _spot;

  /// Where the spotlight was when the current journey began, and where it was
  /// last drawn — which is what a new journey starts from, including the
  /// point in the middle of the screen a step with no target sits at.
  Rect? _spotFrom;
  Rect? _spotDrawn;

  /// The size the panel's contents want, measured as they are laid out and
  /// read by the layout that places the panel — which must judge the side by
  /// where the card is heading, not by the size it is easing through.
  final _SizeRef _natural = _SizeRef();

  /// The target's rectangle, re-read every frame so the panel follows a target
  /// that moves — a scroll, a resize, a layout that settles late.
  final ValueNotifier<Rect?> _anchor = ValueNotifier<Rect?>(null);

  bool get _isOpen => widget.open ?? _controller.isOpen;
  int get _current => (widget.current ?? _controller.current)
      .clamp(0, widget.steps.isEmpty ? 0 : widget.steps.length - 1);

  @override
  void initState() {
    super.initState();
    _spot = AnimationController(vsync: this);
    _controller
      .._length = widget.steps.length
      ..addListener(_onController);
    if (widget.open ?? false) _controller._open = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(Tour old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onController);
      widget.controller?.addListener(_onController);
    }
    _controller._length = widget.steps.length;
    _scheduleSync();
  }

  @override
  void dispose() {
    _spot.dispose();
    _controller.removeListener(_onController);
    _fallback.dispose();
    _entry?.remove();
    _entry = null;
    _anchor.dispose();
    super.dispose();
  }

  void _onController() {
    if (_controller.current != _shownStep) _startSpotJourney();
    _scheduleSync();
  }

  /// The step the spotlight is currently drawn for.
  int? _shownStep;

  /// Sets the spotlight off from where it is now towards the new step.
  void _startSpotJourney() {
    final duration = widget.duration ?? _resolvedToken.travelDuration;
    if (duration == Duration.zero) return;
    _spotFrom = _spotDrawn;
    _spot
      ..duration = duration
      ..forward(from: 0);
  }

  /// [destination] while standing still; part way there while travelling.
  Rect _spotBetween(Rect? from, Rect destination, Curve curve) {
    if (from == null || _spot.isCompleted || _spot.isDismissed) {
      return destination;
    }
    return Rect.lerp(from, destination, curve.transform(_spot.value))!;
  }

  /// Runs [_sync] as soon as it is safe to.
  ///
  /// Inserting an overlay entry, or marking one as needing to build, is a
  /// change to another part of the tree — illegal while the framework is
  /// building. A controller that moves the tour from inside a build (a
  /// `didUpdateWidget`, a listener firing mid-frame) would otherwise throw.
  void _scheduleSync() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    } else {
      _sync();
    }
  }

  /// Puts the overlay up or takes it down, and keeps it in step.
  void _sync() {
    if (!mounted) return;
    if (_isOpen && widget.steps.isNotEmpty) {
      _reveal();
      _measure();
      if (_entry == null) {
        _entry = OverlayEntry(builder: _buildOverlay);
        _overlay = Overlay.of(context, rootOverlay: true);
        _overlay!.insert(_entry!);
        WidgetsBinding.instance.addPostFrameCallback((_) => _watch());
      } else {
        _entry!.markNeedsBuild();
      }
    } else {
      _revealedFor = null;
      _entry?.remove();
      _entry = null;
      _overlay = null;
    }
  }

  /// The step the page was last scrolled for, so a target is revealed once
  /// rather than on every frame the overlay rebuilds.
  int? _revealedFor;

  /// Brings the current step's target into view, if it is not there already.
  ///
  /// Every scrollable between the target and the screen is asked, so a target
  /// inside a list inside a page is reached. A target already comfortably on
  /// screen is left alone: re-centring the page under a reader who can see the
  /// thing perfectly well is worse than not scrolling at all.
  void _reveal() {
    final step = widget.steps[_current];
    if (!(step.scrollIntoView ?? widget.scrollIntoView)) return;
    if (_revealedFor == _current) return;
    _revealedFor = _current;

    final target = step.target?.currentContext;
    if (target == null) return;
    final box = target.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;

    final screen = MediaQuery.sizeOf(context);
    final at = box.localToGlobal(Offset.zero) & box.size;
    // A margin, so a target hard against an edge still counts as hidden: a
    // spotlight touching the edge of the screen has nowhere to put its panel.
    const margin = 48.0;
    final visible = at.top >= margin &&
        at.left >= 0 &&
        at.bottom <= screen.height - margin &&
        at.right <= screen.width;
    if (visible) return;

    Scrollable.ensureVisible(
      target,
      alignment: 0.5,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      duration: widget.duration ?? _resolvedToken.travelDuration,
      curve: widget.curve ?? _resolvedToken.travelCurve,
    );
  }

  /// Re-reads the target at the end of every frame there is, for as long as
  /// the tour is up.
  ///
  /// A page that scrolls under an open tour produces frames of its own, so the
  /// watch costs nothing while it is still — and it asks for none of its own,
  /// so an idle tour is idle. Measuring inside the frame instead would be a
  /// change to the tree while the tree is being built.
  void _watch() {
    if (!mounted || _entry == null) return;
    _measure();
    WidgetsBinding.instance.addPostFrameCallback((_) => _watch());
  }

  /// Reads the current step's target rectangle in the overlay's coordinates.
  void _measure() {
    final key = widget.steps[_current].target;
    final box = key?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      _anchor.value = null;
      return;
    }
    // Converted through the screen, not by asking for the overlay as an
    // ancestor: the overlay is not an ancestor of the page, so that transform
    // is only right while nothing has moved. Under a scrolled page it left the
    // spotlight where the target used to be.
    final overlay = _overlay?.context.findRenderObject() as RenderBox?;
    final onScreen = box.localToGlobal(Offset.zero);
    final origin = overlay == null ? onScreen : overlay.globalToLocal(onScreen);
    _anchor.value = origin & box.size;
  }

  _ResolvedTourToken get _resolvedToken => (widget.token ??
          ConfigProvider.componentOf<TourToken>(context) ??
          const TourToken())
      ._resolve(context.softToken);

  void _step(int to) {
    if (to == _current) return;
    _startSpotJourney();
    _controller.goTo(to);
    widget.onChange?.call(to);
    _scheduleSync();
  }

  void _close() {
    _controller.close();
    widget.onClose?.call();
    _scheduleSync();
  }

  void _finish() {
    widget.onFinish?.call();
    _close();
  }

  @override
  Widget build(BuildContext context) {
    // The overlay is rebuilt from here so it follows the theme and any change
    // to the steps; the widget itself takes no room in the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _entry != null) {
        _measure();
        _entry!.markNeedsBuild();
      }
    });
    return const SizedBox.shrink();
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<TourToken>(context) ??
            const TourToken())
        ._resolve(t);

    final step = widget.steps[_current];
    // Named on the widget where a caller wants it to read as behaviour, on the
    // token where it belongs to a theme; the widget wins.
    final travelDuration = widget.duration ?? r.travelDuration;
    final travelCurve = widget.curve ?? r.travelCurve;
    final placement = step.placement ?? widget.placement;
    final mask = step.mask ?? widget.mask;
    final gap = step.gap ?? widget.gap;

    return ValueListenableBuilder<Rect?>(
      valueListenable: _anchor,
      builder: (context, anchor, _) {
        final hasTarget = anchor != null;

        // A step that points at nothing still has somewhere to be: the middle
        // of the screen, as a rectangle of no size. The spotlight then opens
        // out of that point on the way to a target and shuts back into it on
        // the way from one, instead of appearing and vanishing outright.
        final screen = MediaQuery.sizeOf(context);
        final destination = anchor ??
            Rect.fromCenter(
              center: Offset(screen.width / 2, screen.height / 2),
              width: 0,
              height: 0,
            );

        // Driven by the tour's own journey rather than by an implicit
        // animation on the destination: a target that moves under an open tour
        // — a page scrolling — must be followed at once, and only a change of
        // step travelled.
        return AnimatedBuilder(
          animation: _spot,
          builder: (context, _) => _overlayFor(
            context,
            t,
            r,
            step: step,
            placement: placement,
            mask: mask,
            gap: gap,
            anchor: _spotDrawn =
                _spotBetween(_spotFrom, destination, travelCurve),
            destination: destination,
            hasTarget: hasTarget,
            duration: travelDuration,
            curve: travelCurve,
          ),
        );
      },
    );
  }

  Widget _overlayFor(
    BuildContext context,
    Token t,
    _ResolvedTourToken r, {
    required TourStep step,
    required TourPlacement placement,
    required TourMask mask,
    required TourGap gap,
    required Rect anchor,
    required Rect destination,
    required bool hasTarget,
    required Duration duration,
    required Curve curve,
  }) {
    {
      // Drawn from the travelling rectangle rather than from the step's own,
      // so it opens and shuts with the movement; a rectangle of no size has no
      // hole to draw.
      final hole = anchor.isEmpty ? null : gap.holeFor(anchor);

      final panel = _TourPanel(
        t: t,
        r: r,
        step: step,
        duration: duration,
        curve: curve,
        naturalSize: _natural,
        type: step.type ?? widget.type,
        current: _current,
        total: widget.steps.length,
        closable: step.closable ?? widget.closable,
        closeIcon: step.closeIcon ?? widget.closeIcon,
        indicatorsBuilder: widget.indicatorsBuilder,
        actionsBuilder: widget.actionsBuilder,
        onClose: _close,
        onPrev: () {
          _step(_current - 1);
          step.prevButton?.onPressed?.call();
        },
        onNext: () {
          if (_current == widget.steps.length - 1) {
            _finish();
          } else {
            _step(_current + 1);
          }
          step.nextButton?.onPressed?.call();
        },
      );

      return Stack(
        children: [
          // The mask: the page dimmed, with a hole over the target. Taps in
          // the hole reach the page beneath unless the tour says otherwise,
          // so a step can walk you through a real interaction.
          Positioned.fill(
            child: _TourMask(
              hole: hole,
              colour: mask.show ? (mask.color ?? r.maskColor) : null,
              blockTarget: widget.disabledInteraction || !hasTarget,
              onTapOutside:
                  (step.dismissible ?? widget.dismissible) ? _close : null,
            ),
          ),
          // One panel for the whole tour: it travels to the next step and
          // swaps its contents on the way. Cross-fading two of them showed
          // both at once over the mask, which reads as a flash.
          _AnchoredPanel(
            // Laid out where it is going — the travel is done inside the
            // layout, which is the only place that knows the panel has moved
            // before anything is painted.
            anchor: destination,
            // A step with nothing to point at is centred on its anchor: a
            // point in the middle of the screen. Same layout, so even that is
            // a journey rather than a swap.
            placement: hasTarget ? placement._popover : null,
            arrow: hasTarget &&
                placement != TourPlacement.center &&
                (step.arrow ?? widget.arrow),
            arrowColour: (step.type ?? widget.type) == TourType.primary
                ? t.primary.base
                : t.colorBgElevated,
            maxWidth: r.width,
            duration: duration,
            curve: curve,
            // What counts as a new journey. The panel's own resizing moves
            // where the layout puts it, and that is not one.
            journey: _current,
            naturalSize: _natural,
            child: panel,
          ),
        ],
      );
    }
  }
}

/// The dimmed page with a hole over the step's target.
class _TourMask extends StatelessWidget {
  const _TourMask({
    required this.hole,
    required this.colour,
    required this.blockTarget,
    required this.onTapOutside,
  });

  final RRect? hole;
  final Color? colour;
  final bool blockTarget;

  /// Null still swallows the tap — the page behind a tour is not to be clicked
  /// by accident — it simply does not close the tour.
  final VoidCallback? onTapOutside;

  @override
  Widget build(BuildContext context) {
    // The dim eases in rather than snapping on, matching the popover
    // barrier — a tour that slams the page dark reads as a flash. The tween
    // runs once on mount: `end` never changes, so stepping through the tour
    // does not re-fade it.
    final t = context.softToken;
    final dimming = colour == null
        ? const SizedBox.expand()
        : TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: t.motionDurationMid,
            curve: t.motionEaseOut,
            builder: (context, progress, _) => CustomPaint(
              painter: _MaskPainter(
                hole: hole,
                colour: colour!.withValues(alpha: colour!.a * progress),
              ),
              size: Size.infinite,
            ),
          );

    // Everything outside the hole absorbs taps and dismisses the tour; the
    // hole itself is left alone, so the target underneath still answers.
    final barrier = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTapOutside,
      child: IgnorePointer(child: dimming),
    );

    if (hole == null || blockTarget) return barrier;

    return Stack(
      children: [
        Positioned.fill(child: IgnorePointer(child: dimming)),
        // Four strips around the hole: the hole is the gap between them.
        ..._strips(hole!.outerRect),
      ],
    );
  }

  Iterable<Widget> _strips(Rect r) sync* {
    Widget strip() => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTapOutside,
        );
    yield Positioned(left: 0, top: 0, right: 0, height: r.top, child: strip());
    yield Positioned(
      left: 0,
      top: r.bottom,
      right: 0,
      bottom: 0,
      child: strip(),
    );
    yield Positioned(
      left: 0,
      top: r.top,
      width: r.left,
      height: r.height,
      child: strip(),
    );
    yield Positioned(
      left: r.right,
      top: r.top,
      right: 0,
      height: r.height,
      child: strip(),
    );
  }
}

/// Paints the dimming, cut out where the target is.
class _MaskPainter extends CustomPainter {
  const _MaskPainter({required this.hole, required this.colour});

  final RRect? hole;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    final paint = Paint()..color = colour;
    if (hole == null) {
      canvas.drawRect(screen, paint);
      return;
    }
    // The page and the hole as one shape, filled even-odd: the hole is the
    // part the rule leaves out, so its edge is the fill's own edge rather than
    // something drawn over it.
    //
    // Not `Path.combine`, which subtracts one path from another: that needs a
    // renderer able to do path operations, and on the web that is not a given
    // — the mask came out solid, with nothing lit at all.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(screen)
        ..addRRect(hole!),
      paint,
    );
  }

  @override
  bool shouldRepaint(_MaskPainter old) =>
      old.hole != hole || old.colour != colour;
}

/// Places the panel against the target, with a caret pointing at it.
class _AnchoredPanel extends StatefulWidget {
  const _AnchoredPanel({
    required this.anchor,
    required this.placement,
    required this.arrow,
    required this.arrowColour,
    required this.maxWidth,
    required this.duration,
    required this.curve,
    required this.journey,
    required this.naturalSize,
    required this.child,
  });

  final Rect anchor;

  /// Null centres the panel on its anchor instead of putting it beside.
  final PopoverPlacement? placement;
  final bool arrow;
  final Color arrowColour;
  final double maxWidth;

  /// How long the panel takes to travel, and on what curve.
  final Duration duration;
  final Curve curve;

  /// What counts as a new journey — the step, and nothing else.
  final Object journey;

  /// The size the panel's contents want, filled in as they are laid out.
  final _SizeRef naturalSize;

  final Widget child;

  @override
  State<_AnchoredPanel> createState() => _AnchoredPanelState();
}

class _AnchoredPanelState extends State<_AnchoredPanel>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<PopoverArrowGeometry?> _arrow =
      ValueNotifier<PopoverArrowGeometry?>(null);

  late final AnimationController _travel = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  /// Where the layout put the panel last frame, and how far short of that it
  /// was held.
  Offset? _landed;
  Offset _offset = Offset.zero;

  /// Where this journey began, in the overlay's own coordinates. Null while
  /// the panel is standing still.
  Offset? _from;

  /// Where the caret was pointing when the journey began.
  PopoverArrowGeometry? _caretFrom;

  @override
  void didUpdateWidget(_AnchoredPanel old) {
    super.didUpdateWidget(old);
    _travel.duration = widget.duration;

    // A new step is a new journey — from wherever the panel is at this very
    // moment, which is its last landing plus however far it was held back.
    // Started here, during the build that changes the step, so no frame is
    // ever painted at the destination first.
    if (widget.journey != old.journey && widget.duration != Duration.zero) {
      _from = (_landed ?? Offset.zero) + _offset;
      // The caret's own starting point, before the layout replaces it with the
      // one for the step being travelled to.
      _caretFrom = _caret;
      _travel.forward(from: 0);
    }
  }

  /// How far short of its destination the panel is, this frame.
  ///
  /// Called from inside the layout — the only place that knows where the panel
  /// has landed. The start is kept in absolute coordinates on purpose: the
  /// panel's own size and the side it settles on can change as it travels, and
  /// a journey measured in deltas would restart on each of those frames and
  /// throw the panel about.
  Offset _travelOffset(Offset landed) {
    _landed = landed;
    final start = _from;
    if (start == null || widget.duration == Duration.zero) {
      return _offset = Offset.zero;
    }
    return _offset = Offset.lerp(
      start - landed,
      Offset.zero,
      widget.curve.transform(_travel.value),
    )!;
  }

  /// The caret as it should be drawn this frame.
  ///
  /// Between two steps on the same side of their targets this is the same
  /// journey the panel makes. Between two on different sides the caret has to
  /// change edges, which it cannot do gradually: it travels to the new point
  /// and turns at the halfway mark, where it is furthest from both panels and
  /// the turn is least noticeable. Left alone it jumped from one edge to the
  /// other in a single frame.
  PopoverArrowGeometry? _caretNow(PopoverArrowGeometry? destination) {
    if (destination == null) return null;
    final from = _caretFrom;
    if (from == null || _travel.isCompleted || _travel.isDismissed) {
      return destination.shifted(_offset);
    }
    final t = widget.curve.transform(_travel.value);
    return PopoverArrowGeometry(
      Offset.lerp(from.base, destination.base, t)!,
      t >= 0.5 ? destination.side : from.side,
    );
  }

  /// The caret the layout last worked out, for the step being travelled to.
  PopoverArrowGeometry? get _caret => _arrow.value;

  @override
  void dispose() {
    _travel.dispose();
    _arrow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final viewportPadding = EdgeInsets.fromLTRB(
      8 + padding.left,
      8 + padding.top,
      8 + padding.right,
      8 + padding.bottom,
    );
    return Stack(
      children: [
        CustomSingleChildLayout(
          delegate: _TravellingDelegate(
            inner: widget.placement == null
                ? _CentredOnAnchorDelegate(
                    anchor: widget.anchor,
                    viewportPadding: viewportPadding,
                  )
                : PopoverLayoutDelegate(
                    anchor: widget.anchor,
                    placement: widget.placement!,
                    gap: 8 + (widget.arrow ? popoverArrowLength : 0),
                    arrowSink: widget.arrow ? _arrow : null,
                    viewportPadding: viewportPadding,
                    // The side is judged by where the card is heading, not by
                    // the size it is easing through: a panel that grows out of
                    // its side would otherwise be shoved back by the viewport
                    // halfway there, which is a jump no easing hides.
                    decisionSize: widget.naturalSize.value,
                  ),
            offsetFor: _travelOffset,
            relayout: _travel,
          ),
          // the panel is `width: 520` *and* `max-width: fit-content`:
          // 520 is the ceiling, not the size. The intrinsic pass is what makes
          // a short step a small panel.
          //
          // Standing still, the panel eases into a new size — a step whose text
          // changes under it grows rather than snaps. On a journey it takes the
          // arriving size at once: a size that moves while the panel travels
          // moves where the layout puts it, and the side it settles on is
          // decided from that size. A side decided halfway is a jump of
          // hundreds of pixels, and no amount of easing hides it.
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            child: widget.child,
          ),
        ),
        if (widget.arrow)
          Positioned.fill(
            child: IgnorePointer(
              // The caret is drawn in the overlay's own coordinates, so it
              // takes the panel's journey as a shift of the same size — a
              // caret waiting at the destination is a flash of its own.
              child: AnimatedBuilder(
                animation: _travel,
                builder: (context, _) =>
                    ValueListenableBuilder<PopoverArrowGeometry?>(
                  valueListenable: _arrow,
                  builder: (context, arrow, _) {
                    final caret = _caretNow(arrow);
                    return caret == null
                        ? const SizedBox.shrink()
                        : CustomPaint(
                            key: const Key('softTourArrow'),
                            painter: PopoverArrowPainter(
                              caret,
                              widget.arrowColour,
                              drawShadow: false,
                            ),
                          );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A size measured in one place and read in another, without notifying: both
/// happen inside the same layout, where a notification would be a rebuild.
class _SizeRef {
  Size? value;
}

/// Reports the size its child settles at, during layout.
///
/// The panel's box eases between two sizes, but the layout must judge which
/// side of the target to sit on by the size it is heading for — otherwise a
/// panel that grows out of its side is shoved back by the viewport, which is a
/// jump of hundreds of pixels.
class _NaturalSize extends SingleChildRenderObjectWidget {
  const _NaturalSize({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderNaturalSize(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderNaturalSize box) =>
      box.onSize = onSize;
}

class _RenderNaturalSize extends RenderProxyBox {
  _RenderNaturalSize(this.onSize);

  ValueChanged<Size> onSize;

  @override
  void performLayout() {
    super.performLayout();
    onSize(size);
  }
}

/// Lays the panel out where it belongs, then holds it back along the way.
///
/// The travel belongs here rather than in a transform over a finished layout:
/// a step placed below its target followed by one placed beside another
/// changes the rule in a single frame, and only the layout knows — before
/// anything is painted — that the panel has moved.
class _TravellingDelegate extends SingleChildLayoutDelegate {
  _TravellingDelegate({
    required this.inner,
    required this.offsetFor,
    required Listenable relayout,
  }) : super(relayout: relayout);

  final SingleChildLayoutDelegate inner;
  final Offset Function(Offset landed) offsetFor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      inner.getConstraintsForChild(constraints);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final landed = inner.getPositionForChild(size, childSize);
    return landed + offsetFor(landed);
  }

  @override
  bool shouldRelayout(_TravellingDelegate old) => true;
}

/// Centres the panel on its anchor, kept inside the viewport.
///
/// A step with nothing to point at anchors to a point in the middle of the
/// screen, so the same machinery that puts a panel beside a target puts this
/// one in the middle — and the panel travels between the two.
class _CentredOnAnchorDelegate extends SingleChildLayoutDelegate {
  const _CentredOnAnchorDelegate({
    required this.anchor,
    required this.viewportPadding,
  });

  final Rect anchor;
  final EdgeInsets viewportPadding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(
          constraints.maxWidth - viewportPadding.horizontal,
          constraints.maxHeight - viewportPadding.vertical,
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double clamp(double value, double min, double max) =>
        max < min ? min : value.clamp(min, max);
    return Offset(
      clamp(
        anchor.center.dx - childSize.width / 2,
        viewportPadding.left,
        size.width - viewportPadding.right - childSize.width,
      ),
      clamp(
        anchor.center.dy - childSize.height / 2,
        viewportPadding.top,
        size.height - viewportPadding.bottom - childSize.height,
      ),
    );
  }

  @override
  bool shouldRelayout(_CentredOnAnchorDelegate old) =>
      old.anchor != anchor || old.viewportPadding != viewportPadding;
}

/// The card itself: cover, heading, description, then indicators and buttons.
class _TourPanel extends StatelessWidget {
  const _TourPanel({
    required this.t,
    required this.r,
    required this.step,
    required this.duration,
    required this.curve,
    required this.naturalSize,
    required this.type,
    required this.current,
    required this.total,
    required this.closable,
    required this.closeIcon,
    required this.onClose,
    required this.onPrev,
    required this.onNext,
    this.indicatorsBuilder,
    this.actionsBuilder,
  });

  final Token t;
  final _ResolvedTourToken r;
  final TourStep step;

  /// How the contents change over, matched to the panel's own journey.
  final Duration duration;
  final Curve curve;

  /// Where the size the contents want is left for the layout to read.
  final _SizeRef naturalSize;

  final TourType type;
  final int current;
  final int total;
  final bool closable;
  final Widget? closeIcon;
  final VoidCallback onClose;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final Widget Function(BuildContext, int, int)? indicatorsBuilder;
  final Widget Function(BuildContext, Widget, int, int)? actionsBuilder;

  bool get _primary => type == TourType.primary;
  bool get _isLast => current == total - 1;

  Color get _ink => _primary ? const Color(0xFFFFFFFF) : t.colorText;
  Color get _inkSecondary =>
      _primary ? const Color(0xE6FFFFFF) : t.colorTextSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _primary ? t.primary.base : t.colorBgElevated,
        borderRadius: BorderRadius.circular(t.borderRadiusLG),
        boxShadow: t.boxShadowSecondary,
      ),
      // The contents changing over are clipped to the card while they cross.
      clipBehavior: Clip.antiAlias,
      // The card itself eases between the sizes its steps want: the box that
      // animates is *inside* the decoration, so the surface grows with its
      // corners round. Outside it, the decoration snapped to the new size and
      // only an invisible box eased.
      child: _sizing(
        // Inside the easing box, not above it: above, it hands the card a
        // width of its own and there is nothing left to ease.
        intrinsic: true,
        // The panel lives in an overlay, outside any Material ancestor, where
        // Flutter falls back to a 48px debug style with yellow underlines. The
        // tour's own text sets its style; everything a caller builds — a custom
        // button, custom indicators — inherits this one.
        child: DefaultTextStyle(
          style: TextStyle(
            color: _ink,
            fontSize: t.fontSize,
            fontFamily: t.fontFamily,
            fontFamilyFallback: t.fontFamilyFallback,
            height: t.lineHeight,
            leadingDistribution: TextLeadingDistribution.even,
            decoration: TextDecoration.none,
          ),
          child: Stack(
            children: [
              // The contents change over rather than being replaced outright.
              // The outgoing copy is positioned, so it fades on top without
              // dragging the panel's size around with it: the surface is already
              // the size the new step wants.
              AnimatedSwitcher(
                duration: duration,
                switchInCurve: curve,
                switchOutCurve: curve,
                layoutBuilder: (current, previous) => Stack(
                  alignment: AlignmentDirectional.topStart,
                  clipBehavior: Clip.none,
                  children: [
                    // The outgoing copy keeps its own size and the card clips
                    // it. Squeezed into the arriving panel's box it overflowed
                    // in stripes — a wide step leaving a narrow one has a footer
                    // that does not fit. `IntrinsicWidth` is what bounds it:
                    // the column inside stretches, and an unbounded width would
                    // be an error rather than a natural size.
                    for (final child in previous)
                      Positioned.fill(
                        child: OverflowBox(
                          alignment: AlignmentDirectional.topStart,
                          minWidth: 0,
                          maxWidth: double.infinity,
                          minHeight: 0,
                          maxHeight: double.infinity,
                          child: IntrinsicWidth(child: child),
                        ),
                      ),
                    if (current != null) current,
                  ],
                ),
                child: Column(
                  key: ValueKey<int>(current),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (step.cover != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          t.size,
                          t.size + (closable ? r.closeBtnSize + t.sizeXS : 0),
                          t.size,
                          0,
                        ),
                        child: step.cover!,
                      ),
                    if (step.title != null)
                      Padding(
                        // Clear of the close button, which sits in the panel's
                        // trailing corner — the left one when the panel reads
                        // right to left, so the room has to follow it.
                        padding: EdgeInsetsDirectional.fromSTEB(
                          t.size,
                          t.size,
                          t.size + (closable ? r.closeBtnSize : 0),
                          t.sizeXS,
                        ),
                        child: DefaultTextStyle(
                          style: TextStyle(
                            color: _ink,
                            fontSize: t.fontSize,
                            fontWeight: FontWeight.w600,
                            height: t.lineHeight,
                            leadingDistribution: TextLeadingDistribution.even,
                            decoration: TextDecoration.none,
                          ),
                          child: step.title!,
                        ),
                      ),
                    if (step.description != null)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: t.size),
                        child: DefaultTextStyle(
                          style: TextStyle(
                            color: _inkSecondary,
                            fontSize: t.fontSize,
                            height: t.lineHeight,
                            leadingDistribution: TextLeadingDistribution.even,
                            decoration: TextDecoration.none,
                          ),
                          child: step.description!,
                        ),
                      ),
                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(t.size, t.sizeXS, t.size, t.size),
                      // `spaceBetween` rather than a Spacer: a flex child measures
                      // as nothing during the intrinsic pass that sizes the panel,
                      // so the footer would come out too narrow and overflow.
                      // Built here, under the panel's own DefaultTextStyle: a
                      // builder that reads the style off its context must see the
                      // panel's, not the overlay's debug one.
                      child: Builder(
                        builder: (context) {
                          final actions = _actions(context);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (total > 1)
                                indicatorsBuilder?.call(
                                      context,
                                      current,
                                      total,
                                    ) ??
                                    _indicators()
                              else
                                const SizedBox.shrink(),
                              Padding(
                                // Between the indicators and the buttons that
                                // follow them, whichever way the row runs.
                                padding: EdgeInsetsDirectional.only(
                                  start: t.size,
                                ),
                                child: actionsBuilder?.call(
                                      context,
                                      actions,
                                      current,
                                      total,
                                    ) ??
                                    actions,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (closable)
                PositionedDirectional(
                  top: t.size,
                  end: t.size,
                  child: _CloseButton(
                    key: const Key('softTourClose'),
                    size: r.closeBtnSize,
                    colour: _primary
                        ? const Color(0xE6FFFFFF)
                        : t.colorTextTertiary,
                    icon: closeIcon,
                    onPressed: onClose,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The box the card takes: eased between steps, or the content's own when
  /// the tour is told not to animate — [AnimatedSize] re-dirties itself
  /// mid-layout when asked to take no time.
  Widget _sizing({required Widget child, bool intrinsic = false}) {
    final measured = _NaturalSize(
      onSize: (size) => naturalSize.value = size,
      child: intrinsic ? IntrinsicWidth(child: child) : child,
    );
    return duration == Duration.zero
        ? measured
        : AnimatedSize(
            duration: duration,
            curve: curve,
            alignment: AlignmentDirectional.topStart,
            child: measured,
          );
  }

  Widget _indicators() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Padding(
              padding: EdgeInsetsDirectional.only(
                end: i == total - 1 ? 0 : t.sizeXXS,
              ),
              child: AnimatedContainer(
                duration: t.motionDurationMid,
                curve: t.motionEaseInOut,
                width: r.indicatorSize,
                height: r.indicatorSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == current
                      ? (_primary ? const Color(0xFFFFFFFF) : t.primary.base)
                      : (_primary ? r.primaryPrevBtnBg : t.colorFill),
                ),
              ),
            ),
        ],
      );

  Widget _actions(BuildContext context) {
    final prev = step.prevButton;
    final next = step.nextButton;

    Widget button(TourButton? spec, VoidCallback act, Widget fallback) {
      final action = (spec?.disabled ?? false) ? null : act;
      return spec?.builder?.call(context, action) ?? fallback;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (current != 0) ...[
          button(
            prev,
            onPrev,
            Button(
              size: SoftSize.small,
              variant: prev?.variant ?? ButtonVariant.outlined,
              color: prev?.color ?? ButtonColor.defaultColor,
              icon: prev?.icon,
              // A disabled button is one the step will not let you leave by.
              onPressed: (prev?.disabled ?? false) ? null : onPrev,
              child: prev?.label ?? Text(context.seedLocale.previous),
            ),
          ),
          SizedBox(width: t.sizeXS),
        ],
        button(
          next,
          onNext,
          Button(
            size: SoftSize.small,
            variant: next?.variant ?? ButtonVariant.solid,
            // On a primary panel the accent is already the background, so the
            // main button inverts instead of doubling up on it.
            color: next?.color ??
                (_primary ? ButtonColor.defaultColor : ButtonColor.primary),
            icon: next?.icon,
            onPressed: (next?.disabled ?? false) ? null : onNext,
            child: next?.label ??
                Text(
                  _isLast ? context.seedLocale.finish : context.seedLocale.next,
                ),
          ),
        ),
      ],
    );
  }
}

/// The panel's close button — a cross that lights up under the pointer.
class _CloseButton extends StatefulWidget {
  const _CloseButton({
    super.key,
    required this.size,
    required this.colour,
    required this.onPressed,
    this.icon,
  });

  final double size;
  final Color colour;
  final VoidCallback onPressed;

  /// Drawn in place of the cross, in the button's own colour and size.
  final Widget? icon;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: t.motionDurationMid,
          curve: t.motionEaseInOut,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _hovered
                ? Color.alphaBlend(t.colorFillQuaternary, t.colorBgElevated)
                    .withValues(alpha: 0.2)
                : const Color(0x00000000),
            borderRadius: BorderRadius.circular(t.borderRadiusSM),
          ),
          child: Center(
            child: widget.icon == null
                ? CustomPaint(
                    size: Size.square(widget.size * 0.5),
                    painter: CrossPainter(widget.colour),
                  )
                : IconTheme.merge(
                    data: IconThemeData(
                      color: widget.colour,
                      size: widget.size * 0.7,
                    ),
                    child: widget.icon!,
                  ),
          ),
        ),
      ),
    );
  }
}
