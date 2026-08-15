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

/// Former name of [StatusType], kept for source compatibility.
@Deprecated('Use StatusType')
typedef MessageType = StatusType;

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
    this.icon,
    this.onClose,
    this.key,
    this.token,
  });

  /// The text shown in the toast.
  final String content;

  /// Which status icon and color to use.
  final StatusType type;

  /// How long to stay on screen.
  ///
  /// [Duration.zero] pins the toast until it is dismissed through the handle
  /// returned by the opener. Null falls back to the configured default.
  final Duration? duration;

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
/// ```dart
/// message.success('Saved');
///
/// final close = message.loading('Uploading…');
/// await upload();
/// close();
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
    VoidCallback? onClose,
    Object? key,
  }) =>
      open(
        MessageConfig(
          content: content,
          type: StatusType.success,
          duration: duration,
          onClose: onClose,
          key: key,
        ),
      );

  /// Shows a red cross toast. Returns a handle that closes it early.
  MessageHandle error(
    String content, {
    Duration? duration,
    VoidCallback? onClose,
    Object? key,
  }) =>
      open(
        MessageConfig(
          content: content,
          type: StatusType.error,
          duration: duration,
          onClose: onClose,
          key: key,
        ),
      );

  /// Shows an amber warning toast. Returns a handle that closes it early.
  MessageHandle warning(
    String content, {
    Duration? duration,
    VoidCallback? onClose,
    Object? key,
  }) =>
      open(
        MessageConfig(
          content: content,
          type: StatusType.warning,
          duration: duration,
          onClose: onClose,
          key: key,
        ),
      );

  /// Shows a neutral informational toast. Returns a handle that closes it
  /// early.
  MessageHandle info(
    String content, {
    Duration? duration,
    VoidCallback? onClose,
    Object? key,
  }) =>
      open(
        MessageConfig(
          content: content,
          type: StatusType.info,
          duration: duration,
          onClose: onClose,
          key: key,
        ),
      );

  /// Shows a spinner toast that stays until dismissed. Call the returned
  /// handle once the work is done.
  MessageHandle loading(
    String content, {
    Duration? duration,
    VoidCallback? onClose,
    Object? key,
  }) =>
      open(
        MessageConfig(
          content: content,
          type: StatusType.loading,
          // Loading has no natural timeout: it ends when the work does.
          duration: duration ?? Duration.zero,
          onClose: onClose,
          key: key,
        ),
      );

  /// Shows a toast built from [config], for anything the named helpers do
  /// not cover.
  MessageHandle open(MessageConfig config) => _stack.push(config);

  /// Overrides the defaults applied to subsequent messages.
  void config({int? maxCount, Duration? duration, double? top}) =>
      _stack.configure(maxCount: maxCount, duration: duration, top: top);

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
  final StackedOverlay<_MessageItem> _overlay = StackedOverlay<_MessageItem>();

  Duration _defaultDuration = const Duration(seconds: 3);
  double _top = 24;

  void configure({int? maxCount, Duration? duration, double? top}) {
    if (maxCount != null) _overlay.maxCount = maxCount;
    if (duration != null) _defaultDuration = duration;
    if (top != null) _top = top;
  }

  void destroyAll() => _overlay.destroyAll();

  MessageHandle push(MessageConfig config) {
    // A repeated key replaces its message instead of stacking a duplicate.
    if (config.key != null) {
      final existing = _overlay.items
          .where((item) => item.config.key == config.key)
          .firstOrNull;
      if (existing != null) existing.close();
    }

    final item = _MessageItem(config, _overlay.remove);
    _overlay.add(item, _buildContainer);

    final duration = config.duration ?? _defaultDuration;
    if (duration > Duration.zero) {
      Timer(duration, item.close);
    }
    return item.close;
  }

  Widget _buildContainer(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _overlay.revision,
      builder: (context, _, __) {
        final token = ConfigProvider.of(context).token;
        return Positioned(
          top: _top + MediaQuery.paddingOf(context).top,
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
              children: [
                for (final item in _overlay.items)
                  _MessageCard(key: item.cardKey, config: item.config),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageCard extends StatefulWidget {
  const _MessageCard({super.key, required this.config});

  final MessageConfig config;

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
        alignment: Alignment.topCenter,
        heightFactor: curved.value.clamp(0.0, 1.0),
        child: child,
      ),
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.6),
            end: Offset.zero,
          ).animate(curved),
          child: Padding(
            padding: EdgeInsets.only(bottom: token.sizeXS),
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
              child: Text(
                widget.config.content,
                // Fully specified because the overlay has no Material
                // ancestor to inherit from. `height` is deliberately omitted:
                // a taller line box would push the label down relative to the
                // icon beside it.
                style: TextStyle(
                  color: r.contentColor,
                  fontSize: token.fontSize,
                  fontFamily: token.fontFamily,
                  fontFamilyFallback: token.fontFamilyFallback,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
