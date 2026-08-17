import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/overlay_host.dart';

/// Semantic status shared by every feedback component.
enum StatusType {
  /// An operation completed as intended.
  success,

  /// An operation failed.
  error,

  /// Neutral information requiring no action.
  info,

  /// Something needs attention but has not yet failed.
  warning,

  /// An operation is still running. Rendered as a spinner rather than a
  /// static glyph.
  loading,
}

/// Screen edge a message is anchored to.
///
/// Each edge keeps its own stack, so toasts at the top and at the bottom
/// never reorder one another and `maxCount` applies per edge.
enum MessagePlacement {
  /// Below the top edge; the stack grows downward. The default.
  top,

  /// Above the bottom edge; the stack grows upward.
  bottom,
}

/// Dismisses an open message ahead of its timeout.
typedef MessageHandle = void Function();

/// Per-component design tokens for [MessageConfig].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [MessageToken(...)])`, or per instance via [MessageConfig.token].
@immutable
class MessageToken {
  /// Creates a [MessageToken].
  const MessageToken({
    this.contentColor,
    this.colorBgElevated,
    this.padding,
    this.borderRadius,
  });

  /// Content text color (`contentColor`).
  final Color? contentColor;

  /// Card background color (`colorBgElevated`).
  final Color? colorBgElevated;

  /// Card padding (`padding`).
  final EdgeInsets? padding;

  /// Card corner radius (`borderRadius`).
  final double? borderRadius;

  _ResolvedMessageToken _resolve(Token t) => _ResolvedMessageToken(
        contentColor: contentColor ?? t.colorText,
        colorBgElevated: colorBgElevated ?? t.colorBgElevated,
        padding: padding ??
            EdgeInsets.symmetric(horizontal: t.sizeSM, vertical: t.sizeXS + 1),
        borderRadius: borderRadius ?? t.borderRadiusLG,
      );
}

@immutable
class _ResolvedMessageToken {
  const _ResolvedMessageToken({
    required this.contentColor,
    required this.colorBgElevated,
    required this.padding,
    required this.borderRadius,
  });

  final Color contentColor;
  final Color colorBgElevated;
  final EdgeInsets padding;
  final double borderRadius;
}

/// Everything a single message can be configured with.
///
/// Pass one to [MessageApi.open] when the shorthand openers such as
/// [MessageApi.success] do not expose what you need.
@immutable
class MessageConfig {
  /// Creates a [MessageConfig].
  const MessageConfig({
    required this.content,
    this.type = StatusType.info,
    this.duration,
    this.placement,
    this.icon,
    this.onClose,
    this.key,
    this.token,
  });

  /// The toast's body. Usually a [Text]; anything else is laid out as given.
  ///
  /// Rendered inside a [DefaultTextStyle] carrying the toast's own colour and
  /// size, so a bare `Text('Saved')` needs no styling of its own.
  final Widget content;

  /// Which status icon and color to use.
  final StatusType type;

  /// How long to stay on screen.
  ///
  /// [Duration.zero] pins the toast until it is dismissed through the handle
  /// returned by the opener. Null falls back to the configured default.
  final Duration? duration;

  /// Which edge to anchor to. Null uses the configured default.
  final MessagePlacement? placement;

  /// Replaces the status icon.
  final Widget? icon;

  /// Called once the exit animation has finished.
  final VoidCallback? onClose;

  /// Reusing a key replaces the message already showing under it.
  final Object? key;

  /// Per-instance token overrides.
  final MessageToken? token;
}

/// Brief, centred status toasts, reached through the [message] getter.
///
/// Toasts appear near the top by default; [MessagePlacement.bottom] anchors
/// them to the other edge instead, per call or as a default through [config].
///
/// ```dart
/// message.success('Saved');
///
/// final close = message.loading('Uploading…');
/// await upload();
/// close();
/// ```
///
/// The shorthands above take plain text. For anything richer — an icon beside
/// the label, a [RichText] — build a [MessageConfig], whose [MessageConfig.content]
/// is a widget:
///
/// ```dart
/// message.open(MessageConfig(
///   content: Row(children: [Icon(Icons.wifi_off), Text('Offline')]),
/// ));
/// ```
///
/// Requires [UiKit.navigatorKey] to be installed on the app.
class MessageApi {
  const MessageApi._();

  static final _MessageStack _stack = _MessageStack();

  /// Shows a green tick toast. Returns a handle that closes it early.
  MessageHandle success(
    String content, {
    Duration? duration,
    MessagePlacement? placement,
    VoidCallback? onClose,
    Object? key,
  }) =>
      open(
        MessageConfig(
          content: Text(content),
          type: StatusType.success,
          duration: duration,
          placement: placement,
          onClose: onClose,
          key: key,
        ),
      );

  /// Shows a red cross toast. Returns a handle that closes it early.
  MessageHandle error(
    String content, {
    Duration? duration,
    MessagePlacement? placement,
    VoidCallback? onClose,
    Object? key,
  }) =>
      open(
        MessageConfig(
          content: Text(content),
          type: StatusType.error,
          duration: duration,
          placement: placement,
          onClose: onClose,
          key: key,
        ),
      );

  /// Shows an amber warning toast. Returns a handle that closes it early.
  MessageHandle warning(
    String content, {
    Duration? duration,
    MessagePlacement? placement,
    VoidCallback? onClose,
    Object? key,
  }) =>
      open(
        MessageConfig(
          content: Text(content),
          type: StatusType.warning,
          duration: duration,
          placement: placement,
          onClose: onClose,
          key: key,
        ),
      );

  /// Shows a neutral informational toast. Returns a handle that closes it
  /// early.
  MessageHandle info(
    String content, {
    Duration? duration,
    MessagePlacement? placement,
    VoidCallback? onClose,
    Object? key,
  }) =>
      open(
        MessageConfig(
          content: Text(content),
          type: StatusType.info,
          duration: duration,
          placement: placement,
          onClose: onClose,
          key: key,
        ),
      );

  /// Shows a spinner toast that stays until dismissed. Call the returned
  /// handle once the work is done.
  MessageHandle loading(
    String content, {
    Duration? duration,
    MessagePlacement? placement,
    VoidCallback? onClose,
    Object? key,
  }) =>
      open(
        MessageConfig(
          content: Text(content),
          type: StatusType.loading,
          // Loading has no natural timeout: it ends when the work does.
          duration: duration ?? Duration.zero,
          placement: placement,
          onClose: onClose,
          key: key,
        ),
      );

  /// Shows a toast built from [config], for anything the named helpers do
  /// not cover.
  MessageHandle open(MessageConfig config) => _stack.push(config);

  /// Overrides the defaults applied to subsequent messages.
  void config({
    int? maxCount,
    Duration? duration,
    MessagePlacement? placement,
    double? offset,
  }) =>
      _stack.configure(
        maxCount: maxCount,
        duration: duration,
        placement: placement,
        offset: offset,
      );

  /// Dismisses every open message.
  void destroy() => _stack.destroyAll();
}

/// The global message API.
MessageApi get message => const MessageApi._();

// --------------------------------------------------------------------------
// Internals
// --------------------------------------------------------------------------

class _MessageItem extends OverlayItem {
  _MessageItem(this.config, this.onRemove);

  final MessageConfig config;
  final void Function(_MessageItem) onRemove;

  /// Drives the enter and exit animation of this card.
  final GlobalKey<_MessageCardState> cardKey = GlobalKey<_MessageCardState>();
  bool _closing = false;

  @override
  void close() {
    if (_closing) return;
    _closing = true;
    final state = cardKey.currentState;
    if (state == null) {
      _finish();
    } else {
      state.playExit(_finish);
    }
  }

  void _finish() {
    config.onClose?.call();
    onRemove(this);
  }
}

class _MessageStack {
  /// Each edge is an independent stack with its own overlay layer, so a toast
  /// at the top never reorders one at the bottom.
  final Map<MessagePlacement, StackedOverlay<_MessageItem>> _stacks = {};

  Duration _defaultDuration = const Duration(seconds: 3);
  MessagePlacement _defaultPlacement = MessagePlacement.top;
  double _offset = 24;
  int? _maxCount;

  StackedOverlay<_MessageItem> _stackFor(MessagePlacement placement) =>
      _stacks.putIfAbsent(placement, () {
        final stack = StackedOverlay<_MessageItem>();
        stack.maxCount = _maxCount;
        return stack;
      });

  void configure({
    int? maxCount,
    Duration? duration,
    MessagePlacement? placement,
    double? offset,
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

    for (final stack in _stacks.values) {
      stack.markChanged();
    }
  }

  void destroyAll() {
    for (final stack in _stacks.values) {
      stack.destroyAll();
    }
  }

  MessageHandle push(MessageConfig config) {
    final placement = config.placement ?? _defaultPlacement;
    final stack = _stackFor(placement);

    // A repeated key replaces its message instead of stacking a duplicate.
    // Keys are global rather than per edge: reusing one is how a caller says
    // "this supersedes that", which holds even if the edge changed.
    if (config.key != null) {
      for (final s in _stacks.values) {
        for (final item in s.items) {
          if (item.config.key == config.key) item.close();
        }
      }
    }

    final item = _MessageItem(config, stack.remove);
    stack.add(item, (context) => _buildContainer(context, placement, stack));

    final duration = config.duration ?? _defaultDuration;
    if (duration > Duration.zero) {
      Timer(duration, item.close);
    }
    return item.close;
  }

  Widget _buildContainer(
    BuildContext context,
    MessagePlacement placement,
    StackedOverlay<_MessageItem> stack,
  ) {
    final atTop = placement == MessagePlacement.top;
    return ValueListenableBuilder<int>(
      valueListenable: stack.revision,
      builder: (context, _, __) {
        final token = ConfigProvider.of(context).token;
        final padding = MediaQuery.paddingOf(context);
        return Positioned(
          top: atTop ? _offset + padding.top : null,
          bottom: atTop ? null : _offset + padding.bottom,
          left: 0,
          right: 0,
          // The overlay sits outside any Material ancestor, where Flutter
          // falls back to a debug style with yellow underlines.
          child: DefaultTextStyle(
            style: TextStyle(
              color: token.colorText,
              fontSize: token.fontSize,
              fontFamily: token.fontFamily,
              fontFamilyFallback: token.fontFamilyFallback,
              decoration: TextDecoration.none,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // Both edges stack the same way: whatever is already on screen
              // keeps its place and the newcomer goes beyond it, so a toast
              // never jumps while the user is reading it.
              verticalDirection:
                  atTop ? VerticalDirection.down : VerticalDirection.up,
              children: [
                for (final item in stack.items)
                  _MessageCard(
                    key: item.cardKey,
                    config: item.config,
                    atTop: atTop,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageCard extends StatefulWidget {
  const _MessageCard({
    super.key,
    required this.config,
    required this.atTop,
  });

  final MessageConfig config;

  /// Which edge the card belongs to. It decides where the card slides in
  /// from, which end of its slot grows, and which side carries the gap.
  final bool atTop;

  @override
  State<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<_MessageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Runs the exit animation, invoking [done] once it finishes.
  void playExit(VoidCallback done) {
    _controller.reverse().whenComplete(done);
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (widget.config.token ??
            ConfigProvider.componentOf<MessageToken>(context) ??
            const MessageToken())
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
        // The slot collapses toward the edge the card came from, so its
        // neighbours reflow away from the screen rather than across it.
        alignment: widget.atTop ? Alignment.topCenter : Alignment.bottomCenter,
        heightFactor: curved.value.clamp(0.0, 1.0),
        child: child,
      ),
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          // In from the nearer edge: downward at the top, upward at the
          // bottom.
          position: Tween<Offset>(
            begin: Offset(0, widget.atTop ? -0.6 : 0.6),
            end: Offset.zero,
          ).animate(curved),
          child: Padding(
            padding: widget.atTop
                ? EdgeInsets.only(bottom: token.sizeXS)
                : EdgeInsets.only(top: token.sizeXS),
            child: _card(token, r),
          ),
        ),
      ),
    );
  }

  Widget _card(Token token, _ResolvedMessageToken r) {
    return Center(
      child: Container(
        padding: r.padding,
        decoration: BoxDecoration(
          color: r.colorBgElevated,
          borderRadius: BorderRadius.circular(r.borderRadius),
          boxShadow: token.boxShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            widget.config.icon ??
                StatusIcon(type: widget.config.type, token: token),
            SizedBox(width: token.sizeXS),
            Flexible(
              // Fully specified because the overlay has no Material ancestor
              // to inherit from. `height` is deliberately omitted: a taller
              // line box would push the label down relative to the icon
              // beside it.
              child: DefaultTextStyle(
                style: TextStyle(
                  color: r.contentColor,
                  fontSize: token.fontSize,
                  fontFamily: token.fontFamily,
                  fontFamilyFallback: token.fontFamilyFallback,
                  decoration: TextDecoration.none,
                ),
                child: widget.config.content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
