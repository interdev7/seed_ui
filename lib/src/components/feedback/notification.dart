import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/overlay_host.dart';
import 'message.dart' show StatusType;

/// Screen corner a notification is anchored to.
///
/// Each corner keeps its own stack, so cards in different corners never
/// reorder one another and `maxCount` applies per corner.
enum NotificationPlacement {
  /// Top-left; slides in from the left and stacks downward.
  topLeft,

  /// Top-right; slides in from the right and stacks downward. The default.
  topRight,

  /// Bottom-left; slides in from the left and stacks upward.
  bottomLeft,

  /// Bottom-right; slides in from the right and stacks upward.
  bottomRight,
}

/// Dismisses an open notification ahead of its timeout.
typedef NotificationHandle = void Function();

/// Per-component design tokens for [NotificationConfig].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [NotificationToken(...)])`, or per instance via [NotificationConfig.token].
@immutable
class NotificationToken {
  /// Creates a [NotificationToken].
  const NotificationToken({
    this.colorBgElevated,
    this.padding,
    this.borderRadius,
    this.titleFontSize,
    this.descriptionFontSize,
    this.width,
  });

  /// Card background color (`colorBgElevated`).
  final Color? colorBgElevated;

  /// Card padding (`padding`).
  final EdgeInsets? padding;

  /// Card corner radius (`borderRadius`).
  final double? borderRadius;

  /// Title font size (`titleFontSize`).
  final double? titleFontSize;

  /// Description font size (`descriptionFontSize`).
  final double? descriptionFontSize;

  /// Nominal card width (`width`).
  final double? width;

  _ResolvedNotificationToken _resolve(Token t) => _ResolvedNotificationToken(
        colorBgElevated: colorBgElevated ?? t.colorBgElevated,
        padding: padding ?? EdgeInsets.all(t.sizeMD),
        borderRadius: borderRadius ?? t.borderRadiusLG,
        titleFontSize: titleFontSize ?? t.fontSizeLG,
        descriptionFontSize: descriptionFontSize ?? t.fontSize,
        width: width ?? 384,
      );
}

@immutable
class _ResolvedNotificationToken {
  const _ResolvedNotificationToken({
    required this.colorBgElevated,
    required this.padding,
    required this.borderRadius,
    required this.titleFontSize,
    required this.descriptionFontSize,
    required this.width,
  });

  final Color colorBgElevated;
  final EdgeInsets padding;
  final double borderRadius;
  final double titleFontSize;
  final double descriptionFontSize;
  final double width;
}

/// Everything a single notification can be configured with.
///
/// Pass one to [NotificationApi.open] when the shorthand openers such as
/// [NotificationApi.success] do not expose what you need.
@immutable
class NotificationConfig {
  /// Creates a [NotificationConfig].
  const NotificationConfig({
    required this.message,
    this.description,
    this.type,
    this.duration,
    this.placement,
    this.icon,
    this.actions,
    this.onClose,
    this.onTap,
    this.closable = true,
    this.key,
    this.token,
  });

  /// Bold headline shown at the top of the card.
  ///
  /// Rendered inside a [DefaultTextStyle] carrying the headline's colour and
  /// size, so a bare `Text('Saved')` needs no styling of its own.
  final Widget message;

  /// Optional supporting detail below the headline.
  ///
  /// Wrapped in its own [DefaultTextStyle], dimmer and smaller than [message].
  final Widget? description;

  /// Leave null for a neutral notification with no status icon.
  final StatusType? type;

  /// How long to stay on screen.
  ///
  /// [Duration.zero] pins the card until it is dismissed. Pair it with
  /// [actions]: a card that vanishes mid-decision is worse than no card.
  /// Null falls back to the configured default.
  final Duration? duration;

  /// Which corner to anchor to. Null uses the configured default.
  final NotificationPlacement? placement;

  /// Replaces the status icon.
  final Widget? icon;

  /// Action buttons rendered along the bottom of the card.
  ///
  /// Each button is responsible for dismissing the notification, usually via
  /// the handle returned when it was opened.
  final List<Widget>? actions;

  /// Called once the exit animation has finished, however it was dismissed.
  final VoidCallback? onClose;

  /// Called when the card body is tapped. Null makes the card inert.
  final VoidCallback? onTap;

  /// Whether to show the close button.
  ///
  /// Only turn this off for a card that dismisses itself, either on a timeout
  /// or through its own [actions] — otherwise the user is left with no way
  /// out.
  final bool closable;

  /// Reusing a key replaces the notification already showing under it.
  final Object? key;

  /// Per-instance token overrides.
  final NotificationToken? token;
}

/// Corner-anchored cards carrying a headline, detail text and optional
/// actions, reached through the [notification] getter.
///
/// ```dart
/// notification.success('Done', description: 'Your file was uploaded.');
///
/// notification.open(NotificationConfig(
///   message: const Text('Update available'),
///   duration: Duration.zero,
///   actions: [Button(onPressed: install, child: const Text('Install'))],
/// ));
/// ```
///
/// The shorthands take plain text; [NotificationConfig.message] and
/// [NotificationConfig.description] are widgets, for anything richer.
///
/// Requires [UiKit.navigatorKey] to be installed on the app. Use
/// [message] instead for brief status text with no detail or actions.
class NotificationApi {
  const NotificationApi._();

  static final _NotificationStack _stack = _NotificationStack();

  /// Shows a green tick notification. Returns a handle that closes it early.
  NotificationHandle success(
    String message, {
    String? description,
    Duration? duration,
    NotificationPlacement? placement,
    List<Widget>? actions,
    VoidCallback? onClose,
    Object? key,
  }) =>
      open(
        NotificationConfig(
          message: Text(message),
          description: description == null ? null : Text(description),
          type: StatusType.success,
          duration: duration,
          placement: placement,
          actions: actions,
          onClose: onClose,
          key: key,
        ),
      );

  /// Shows a red cross notification. Returns a handle that closes it early.
  NotificationHandle error(
    String message, {
    String? description,
    Duration? duration,
    NotificationPlacement? placement,
    List<Widget>? actions,
    VoidCallback? onClose,
    Object? key,
  }) =>
      open(
        NotificationConfig(
          message: Text(message),
          description: description == null ? null : Text(description),
          type: StatusType.error,
          duration: duration,
          placement: placement,
          actions: actions,
          onClose: onClose,
          key: key,
        ),
      );

  /// Shows an amber warning notification. Returns a handle that closes it
  /// early.
  NotificationHandle warning(
    String message, {
    String? description,
    Duration? duration,
    NotificationPlacement? placement,
    List<Widget>? actions,
    VoidCallback? onClose,
    Object? key,
  }) =>
      open(
        NotificationConfig(
          message: Text(message),
          description: description == null ? null : Text(description),
          type: StatusType.warning,
          duration: duration,
          placement: placement,
          actions: actions,
          onClose: onClose,
          key: key,
        ),
      );

  /// Shows a neutral informational notification. Returns a handle that closes
  /// it early.
  NotificationHandle info(
    String message, {
    String? description,
    Duration? duration,
    NotificationPlacement? placement,
    List<Widget>? actions,
    VoidCallback? onClose,
    Object? key,
  }) =>
      open(
        NotificationConfig(
          message: Text(message),
          description: description == null ? null : Text(description),
          type: StatusType.info,
          duration: duration,
          placement: placement,
          actions: actions,
          onClose: onClose,
          key: key,
        ),
      );

  /// Shows a notification built from [config], for anything the named helpers
  /// do not cover.
  NotificationHandle open(NotificationConfig config) => _stack.push(config);

  /// Overrides the defaults applied to subsequent notifications.
  void config({
    int? maxCount,
    Duration? duration,
    NotificationPlacement? placement,
    double? offset,
    bool? stack,
    int? stackThreshold,
  }) =>
      _stack.configure(
        maxCount: maxCount,
        duration: duration,
        placement: placement,
        offset: offset,
        stack: stack,
        stackThreshold: stackThreshold,
      );

  /// Dismisses every notification, or just the one matching [key].
  void destroy([Object? key]) => _stack.destroy(key);
}

/// The global notification API.
NotificationApi get notification => const NotificationApi._();

// --------------------------------------------------------------------------
// Internals
// --------------------------------------------------------------------------

class _NotificationItem extends OverlayItem {
  _NotificationItem(this.config, this.onRemove);

  final NotificationConfig config;
  final void Function(_NotificationItem) onRemove;

  final GlobalKey<_NotificationCardState> cardKey =
      GlobalKey<_NotificationCardState>();
  Timer? timer;
  bool _closing = false;

  @override
  void close() {
    if (_closing) return;
    _closing = true;
    timer?.cancel();
    // Let the card play its exit transition; cards that are not currently
    // mounted (e.g. hidden behind the stacked deck) just leave right away.
    final card = cardKey.currentState;
    if (card == null || !card.mounted) {
      _finish();
      return;
    }
    card.playExit(_finish);
  }

  void _finish() {
    config.onClose?.call();
    onRemove(this);
  }
}

class _NotificationStack {
  /// Each corner is an independent stack with its own overlay layer.
  final Map<NotificationPlacement, StackedOverlay<_NotificationItem>> _stacks =
      {};

  Duration _defaultDuration = const Duration(milliseconds: 4500);
  NotificationPlacement _defaultPlacement = NotificationPlacement.topRight;
  double _offset = 24;
  int? _maxCount;
  bool _stackEnabled = true;
  int _stackThreshold = 3;

  StackedOverlay<_NotificationItem> _stackFor(NotificationPlacement placement) {
    return _stacks.putIfAbsent(placement, () {
      final stack = StackedOverlay<_NotificationItem>();
      stack.maxCount = _maxCount;
      return stack;
    });
  }

  void configure({
    int? maxCount,
    Duration? duration,
    NotificationPlacement? placement,
    double? offset,
    bool? stack,
    int? stackThreshold,
  }) {
    if (maxCount != null) {
      _maxCount = maxCount;
      for (final stack in _stacks.values) {
        stack.maxCount = maxCount;
      }
    }
    if (duration != null) _defaultDuration = duration;
    if (placement != null) _defaultPlacement = placement;
    if (offset != null) _offset = offset;
    if (stack != null) _stackEnabled = stack;
    if (stackThreshold != null) _stackThreshold = stackThreshold;

    for (final s in _stacks.values) {
      s.revision.value++;
    }
  }

  void destroy([Object? key]) {
    for (final stack in _stacks.values) {
      if (key == null) {
        stack.destroyAll();
      } else {
        for (final item in stack.items) {
          if (item.config.key == key) item.close();
        }
      }
    }
  }

  NotificationHandle push(NotificationConfig config) {
    final placement = config.placement ?? _defaultPlacement;
    final stack = _stackFor(placement);

    if (config.key != null) {
      destroy(config.key);
    }

    final item = _NotificationItem(config, stack.remove);
    stack.add(item, (context) => _buildContainer(context, placement, stack));

    final duration = config.duration ?? _defaultDuration;
    if (duration > Duration.zero) {
      item.timer = Timer(duration, item.close);
    }
    return item.close;
  }

  Widget _buildContainer(
    BuildContext context,
    NotificationPlacement placement,
    StackedOverlay<_NotificationItem> stack,
  ) {
    return _NotificationPlacementContainer(
      placement: placement,
      stack: stack,
      offset: _offset,
      stackEnabled: _stackEnabled,
      stackThreshold: _stackThreshold,
    );
  }
}

class _NotificationPlacementContainer extends StatefulWidget {
  const _NotificationPlacementContainer({
    required this.placement,
    required this.stack,
    required this.offset,
    required this.stackEnabled,
    required this.stackThreshold,
  });

  final NotificationPlacement placement;
  final StackedOverlay<_NotificationItem> stack;
  final double offset;
  final bool stackEnabled;
  final int stackThreshold;

  @override
  State<_NotificationPlacementContainer> createState() =>
      _NotificationPlacementContainerState();
}

class _NotificationPlacementContainerState
    extends State<_NotificationPlacementContainer>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  /// Touch devices get no hover, so a tap on the collapsed deck unfolds it.
  /// Stays set until the stack drops back under the threshold.
  bool _tapExpanded = false;

  /// Marks the list's box so an outside tap can be told from one on a card.
  final GlobalKey _listKey = GlobalKey();

  /// Live only while the deck is held open by a tap, so system back — the
  /// Android button, a back gesture, the browser's back — folds the list
  /// instead of leaving the page.
  OverlayPopScope? _popScope;

  void _setTapExpanded(bool value) {
    if (_tapExpanded == value) return;
    if (mounted) {
      setState(() => _tapExpanded = value);
    } else {
      _tapExpanded = value;
    }
    if (value) {
      _popScope = OverlayPopScope(onPop: () => _setTapExpanded(false))
        ..register(context);
    } else {
      _releasePopScope();
    }
  }

  void _releasePopScope() {
    _popScope?.unregister();
    _popScope = null;
  }

  /// Folds the deck back unless the tap landed on the list itself.
  void _handleOutsideTap(Offset position) {
    final box = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final local = box.globalToLocal(position);
      if (local.dx >= 0 &&
          local.dy >= 0 &&
          local.dx <= box.size.width &&
          local.dy <= box.size.height) {
        return;
      }
    }
    _setTapExpanded(false);
  }

  /// 0 = collapsed deck, 1 = fully expanded list. Cards read this to
  /// interpolate their own height, offset, scale and opacity, so hovering
  /// unfolds the stack instead of swapping one layout for another.
  late final AnimationController _expand = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _expand, curve: Curves.easeInOut);

  @override
  void dispose() {
    _releasePopScope();
    _expand.dispose();
    super.dispose();
  }

  /// Retargets the unfold animation without touching the controller during a
  /// build, which would rebuild the tree it is currently building.
  void _syncExpansion(bool expanded) {
    final target = expanded ? 1.0 : 0.0;
    if (_expand.value == target &&
        _expand.status != AnimationStatus.forward &&
        _expand.status != AnimationStatus.reverse) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (expanded) {
        _expand.forward();
      } else {
        _expand.reverse();
      }
    });
  }

  bool _isTop(NotificationPlacement p) =>
      p == NotificationPlacement.topLeft || p == NotificationPlacement.topRight;

  bool _isLeft(NotificationPlacement p) =>
      p == NotificationPlacement.topLeft ||
      p == NotificationPlacement.bottomLeft;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.stack.revision,
      builder: (context, _, __) {
        final token = ConfigProvider.of(context).token;
        final padding = MediaQuery.paddingOf(context);
        final top = _isTop(widget.placement);
        final left = _isLeft(widget.placement);
        final items = widget.stack.items;

        if (items.isEmpty) return const SizedBox.shrink();

        final maxWidth = MediaQuery.sizeOf(context).width -
            widget.offset * 2 -
            padding.horizontal;

        // Once the deck shrinks back under the threshold the touch expansion
        // has nothing left to hold open.
        if (items.length <= widget.stackThreshold && _tapExpanded) {
          _tapExpanded = false;
          _releasePopScope();
        }

        final collapsed = widget.stackEnabled &&
            items.length > widget.stackThreshold &&
            !_hovered &&
            !_tapExpanded;
        _syncExpansion(!collapsed);

        // The scroll view has to clip, so the layer is inflated by
        // [_shadowPad] on every side and shifted back by the same amount:
        // clipping then happens well clear of the cards' drop shadows.
        final maxHeight = MediaQuery.sizeOf(context).height -
            widget.offset * 2 -
            padding.vertical +
            _shadowPad * 2;

        final layer = Positioned(
          top: top ? widget.offset + padding.top - _shadowPad : null,
          bottom: top ? null : widget.offset + padding.bottom - _shadowPad,
          left: left ? widget.offset - _shadowPad : null,
          right: left ? null : widget.offset - _shadowPad,
          child: DefaultTextStyle(
            style: TextStyle(
              color: token.colorText,
              fontSize: token.fontSize,
              fontFamily: token.fontFamily,
              fontFamilyFallback: token.fontFamilyFallback,
              decoration: TextDecoration.none,
            ),
            child: MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: ConstrainedBox(
                key: _listKey,
                constraints: BoxConstraints(maxHeight: math.max(0, maxHeight)),
                child: SingleChildScrollView(
                  // Bottom-anchored corners grow upward, so their scroll view
                  // has to stick to the far edge as well.
                  reverse: !top,
                  padding: const EdgeInsets.all(_shadowPad),
                  child: Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _curve,
                        builder: (context, _) =>
                            _buildList(items, top, left, maxWidth),
                      ),
                      // While collapsed the first tap belongs to the deck, not
                      // to the front card's own action or close button.
                      if (collapsed)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _setTapExpanded(true),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        if (!_tapExpanded) return layer;

        // A translucent listener still lets the app below receive the tap, so
        // folding the deck back never costs the user a click.
        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) => _handleOutsideTap(event.position),
              ),
            ),
            layer,
          ],
        );
      },
    );
  }

  /// Lays every card out along a single axis, with the collapsed deck and the
  /// expanded list as the two ends of one continuous interpolation.
  ///
  /// Collapsed, only the newest card keeps its height; the ones behind it are
  /// flattened to a zero-height slot and pushed out by [_stepOffset] each, so
  /// they read as a peeking pile. As the animation runs those slots grow back
  /// to full height and the offsets, scale and opacity unwind to neutral.
  Widget _buildList(
    List<_NotificationItem> items,
    bool top,
    bool left,
    double maxWidth,
  ) {
    final t = _curve.value;
    final count = items.length;
    final maxDepth = math.max(0, widget.stackThreshold - 1);
    final anchor = Alignment(left ? -1 : 1, top ? -1 : 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      verticalDirection: top ? VerticalDirection.down : VerticalDirection.up,
      children: [
        for (int i = 0; i < count; i++)
          _slot(
            items[i],
            // 0 is the newest card: the one at the front of the deck.
            depth: count - 1 - i,
            maxDepth: maxDepth,
            t: t,
            top: top,
            left: left,
            anchor: anchor,
            maxWidth: maxWidth,
          ),
      ],
    );
  }

  Widget _slot(
    _NotificationItem item, {
    required int depth,
    required int maxDepth,
    required double t,
    required bool top,
    required bool left,
    required Alignment anchor,
    required double maxWidth,
  }) {
    final capped = math.min(depth, maxDepth);
    final collapsedOpacity = depth == 0
        ? 1.0
        : (depth <= maxDepth ? (1.0 - depth * 0.15).clamp(0.4, 1.0) : 0.0);

    return Align(
      alignment: anchor,
      // Only the front card occupies space while collapsed; the rest grow back
      // into the layout as the stack unfolds.
      heightFactor: depth == 0 ? 1.0 : t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * capped * _stepOffset * (top ? 1 : -1)),
        child: Transform.scale(
          scale: 1.0 - (1 - t) * capped * _stepScale,
          alignment: anchor,
          child: Opacity(
            opacity: collapsedOpacity + (1 - collapsedOpacity) * t,
            child: _NotificationCard(
              key: item.cardKey,
              config: item.config,
              fromLeft: left,
              onClose: item.close,
              maxWidth: maxWidth,
            ),
          ),
        ),
      ),
    );
  }

  static const double _stepOffset = 10.0;
  static const double _stepScale = 0.04;

  /// Breathing room kept inside the scroll viewport so its clip never cuts a
  /// card's drop shadow, and so the collapsed deck's peeking edges stay
  /// visible.
  static const double _shadowPad = 24.0;
}

class _NotificationCard extends StatefulWidget {
  const _NotificationCard({
    super.key,
    required this.config,
    required this.fromLeft,
    required this.onClose,
    required this.maxWidth,
  });

  final NotificationConfig config;
  final bool fromLeft;
  final VoidCallback onClose;

  /// Space actually available between the screen edges.
  final double maxWidth;

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward();

  /// Springs the card back to rest when a swipe stops short of dismissing it.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  Animation<double>? _settleAnimation;

  /// Live horizontal displacement from the finger, in logical pixels.
  double _dragX = 0;

  /// True once a swipe has committed, so the drag offset is left frozen while
  /// the exit animation carries the card the rest of the way out.
  bool _dismissing = false;

  @override
  void dispose() {
    _controller.dispose();
    _settle.dispose();
    super.dispose();
  }

  /// Outward is the edge the card came from: right for right-anchored corners.
  double get _outward => widget.fromLeft ? -1 : 1;

  void _onDragStart(DragStartDetails _) {
    _settle.stop();
  }

  void _onDragUpdate(DragUpdateDetails details, double width) {
    if (_dismissing) return;
    var next = _dragX + details.delta.dx;
    // Dragging back inward is resisted rather than blocked, so the card never
    // feels stuck to the finger.
    if (next * _outward < 0) next *= 0.25;
    setState(() => _dragX = next);
  }

  void _onDragEnd(DragEndDetails details, double width) {
    if (_dismissing) return;
    final travelled = _dragX * _outward;
    final velocity = details.primaryVelocity ?? 0;
    final flung = velocity * _outward > 600;

    if (travelled > width * 0.3 || (flung && travelled > 8)) {
      // The exit animation slides towards the same edge, so leaving the drag
      // offset in place keeps the motion continuous.
      _dismissing = true;
      widget.onClose();
      return;
    }

    _settleAnimation = Tween<double>(begin: _dragX, end: 0)
        .animate(CurvedAnimation(parent: _settle, curve: Curves.easeOut))
      ..addListener(() {
        if (mounted) setState(() => _dragX = _settleAnimation!.value);
      });
    _settle.forward(from: 0);
  }

  void playExit(VoidCallback done) {
    if (!mounted) {
      done();
      return;
    }
    // Removing the entry mutates the stack, so defer past the frame the
    // animation finishes in rather than rebuilding mid-frame.
    _controller.reverse().whenCompleteOrCancel(() {
      WidgetsBinding.instance.addPostFrameCallback((_) => done());
    });
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (widget.config.token ??
            ConfigProvider.componentOf<NotificationToken>(context) ??
            const NotificationToken())
        ._resolve(token);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: token.motionEaseOutCirc,
      reverseCurve: token.motionEaseInOut,
    );

    // Animate the slot's height so neighbours reflow smoothly as a card enters
    // or leaves — but via Align(heightFactor), not SizeTransition, whose
    // internal ClipRect would crop the soft drop shadow into a hard rectangle.
    // Align does not clip, so the shadow renders in full.
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Align(
        alignment: Alignment.topCenter,
        heightFactor: curved.value.clamp(0.0, 1.0),
        child: child,
      ),
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          // Slides in from whichever edge the card is anchored to.
          position: Tween<Offset>(
            begin: Offset(widget.fromLeft ? -1 : 1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: Padding(
            padding: EdgeInsets.only(bottom: token.sizeXS),
            child: _swipeable(token, r),
          ),
        ),
      ),
    );
  }

  /// Wraps the card in a horizontal drag that dismisses it towards the edge it
  /// arrived from — swipe right for a right-anchored card, left for a
  /// left-anchored one. The opposite direction only rubber-bands.
  Widget _swipeable(Token token, _ResolvedNotificationToken r) {
    final width = math.min(r.width, math.max(1.0, widget.maxWidth));
    final progress = (_dragX * _outward / width).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: (d) => _onDragUpdate(d, width),
      onHorizontalDragEnd: (d) => _onDragEnd(d, width),
      child: Transform.translate(
        offset: Offset(_dragX, 0),
        child: Opacity(
          opacity: 1 - progress * 0.6,
          child: _card(token, r),
        ),
      ),
    );
  }

  Widget _card(Token token, _ResolvedNotificationToken r) {
    final config = widget.config;
    final hasIcon = config.icon != null || config.type != null;

    Widget card = Container(
      // Nominal width, capped to whatever room the viewport leaves.
      width: math.min(r.width, math.max(0.0, widget.maxWidth)),
      padding: r.padding,
      decoration: BoxDecoration(
        color: r.colorBgElevated,
        borderRadius: BorderRadius.circular(r.borderRadius),
        boxShadow: token.boxShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasIcon) ...[
            config.icon ?? StatusIcon(type: config.type!, token: token),
            SizedBox(width: token.sizeSM),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: TextStyle(
                    color: token.colorText,
                    fontSize: r.titleFontSize,
                    fontFamily: token.fontFamily,
                    fontFamilyFallback: token.fontFamilyFallback,
                    decoration: TextDecoration.none,
                  ),
                  child: config.message,
                ),
                if (config.description != null) ...[
                  SizedBox(height: token.sizeXS),
                  DefaultTextStyle(
                    style: TextStyle(
                      color: token.colorTextSecondary,
                      fontSize: r.descriptionFontSize,
                      fontFamily: token.fontFamily,
                      fontFamilyFallback: token.fontFamilyFallback,
                      height: token.lineHeight,
                      decoration: TextDecoration.none,
                    ),
                    child: config.description!,
                  ),
                ],
                if (config.actions != null && config.actions!.isNotEmpty) ...[
                  SizedBox(height: token.sizeSM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (final action in config.actions!)
                        Padding(
                          padding: EdgeInsets.only(left: token.sizeXS),
                          child: action,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (config.closable) ...[
            SizedBox(width: token.sizeXS),
            _CloseButton(onTap: widget.onClose, token: token),
          ],
        ],
      ),
    );

    if (config.onTap != null) {
      card = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: config.onTap,
        child: card,
      );
    }
    return card;
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onTap, required this.token});

  final VoidCallback onTap;
  final Token token;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final token = widget.token;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _hovered ? token.colorFillSecondary : null,
            borderRadius: BorderRadius.circular(token.borderRadiusSM),
          ),
          child: CustomPaint(
            painter: CrossPainter(
              _hovered ? token.colorText : token.colorTextTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
