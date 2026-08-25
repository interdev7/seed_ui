import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/overlay_host.dart';
import '../general/button.dart';
import 'message.dart' show StatusType;

/// Dismisses an open modal ahead of any user interaction.
typedef ModalHandle = void Function();

/// Per-component design tokens for [ModalConfig].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(modal: ModalToken(...)))`,
/// or per instance via [ModalConfig.token].
@immutable
class ModalToken {
  /// Creates a [ModalToken].
  const ModalToken({
    this.colorBgMask,
    this.colorBgElevated,
    this.padding,
    this.borderRadius,
    this.titleFontSize,
    this.contentFontSize,
  });

  /// Mask backdrop color (`colorBgMask`).
  final Color? colorBgMask;

  /// Modal dialog background color (`colorBgElevated`).
  final Color? colorBgElevated;

  /// Modal dialog padding (`padding`).
  final EdgeInsets? padding;

  /// Modal dialog corner radius (`borderRadius`).
  final double? borderRadius;

  /// Title font size (`titleFontSize`).
  final double? titleFontSize;

  /// Content font size (`contentFontSize`).
  final double? contentFontSize;

  _ResolvedModalToken _resolve(Token t) => _ResolvedModalToken(
        colorBgMask: colorBgMask ?? t.colorBgMask,
        colorBgElevated: colorBgElevated ?? t.colorBgElevated,
        padding: padding ?? EdgeInsets.all(t.sizeMD),
        borderRadius: borderRadius ?? t.borderRadiusLG,
        titleFontSize: titleFontSize ?? t.fontSizeLG,
        contentFontSize: contentFontSize ?? t.fontSize,
      );
}

@immutable
class _ResolvedModalToken {
  const _ResolvedModalToken({
    required this.colorBgMask,
    required this.colorBgElevated,
    required this.padding,
    required this.borderRadius,
    required this.titleFontSize,
    required this.contentFontSize,
  });

  final Color colorBgMask;
  final Color colorBgElevated;
  final EdgeInsets padding;
  final double borderRadius;
  final double titleFontSize;
  final double contentFontSize;
}

/// Everything a single modal can be configured with.
///
/// Pass one to [ModalApi.open] when the shorthand openers such as
/// [ModalApi.confirm] do not expose what you need.
@immutable
class ModalConfig {
  /// Creates a [ModalConfig].
  const ModalConfig({
    this.title,
    this.content,
    this.type,
    this.okText,
    this.cancelText,
    this.showCancel = true,
    this.onOk,
    this.onCancel,
    this.danger = false,
    this.width = 416,
    this.centered = false,
    this.top,
    this.closable = true,
    this.maskClosable = true,
    this.escapeClosable = true,
    this.barrierColor,
    this.icon,
    this.footer,
    this.token,
  });

  /// Headline shown at the top of the dialog.
  ///
  /// Rendered inside a [DefaultTextStyle] carrying the title's size and
  /// weight, so a bare `Text('Delete file?')` needs no styling of its own.
  final Widget? title;

  /// The dialog's body — a paragraph, a form, anything.
  ///
  /// Wrapped in its own [DefaultTextStyle] and allowed to scroll once it
  /// outgrows the dialog's height cap.
  final Widget? content;

  /// Status icon beside the title. Null renders no icon.
  final StatusType? type;

  /// Label of the confirming button.
  /// Null takes the word from the locale in scope.
  final Widget? okText;

  /// Label of the dismissing button.
  /// Null takes the word from the locale in scope.
  final Widget? cancelText;

  /// Whether to show the cancel button.
  ///
  /// Acknowledgement dialogs — [ModalApi.info] and friends — hide it,
  /// since there is nothing to decline.
  final bool showCancel;

  /// Called when the confirming button is pressed.
  ///
  /// Returning a [Future] keeps the button in its loading state until the
  /// future settles, and the modal stays open until it does. Return false to
  /// keep the modal open — useful when validation fails.
  final FutureOr<bool?> Function()? onOk;

  /// Called when the modal is dismissed by any means: the cancel button, the
  /// close icon, the mask or Escape.
  final VoidCallback? onCancel;

  /// Recolors the confirming button to the error palette, for destructive
  /// decisions.
  final bool danger;

  /// Nominal dialog width, capped to whatever the viewport leaves.
  final double width;

  /// Centers the dialog vertically instead of anchoring it near the top.
  ///
  /// Takes precedence over [top].
  final bool centered;

  /// Distance in logical pixels from the top of the safe area.
  ///
  /// Null keeps the default placement in the upper third, which stays near
  /// where the user is already looking and does not shift as the content
  /// grows. Ignored when [centered] is true.
  final double? top;

  /// Whether to show the close icon in the corner.
  final bool closable;

  /// Whether tapping the mask dismisses the modal.
  ///
  /// Turn it off for decisions that must be made deliberately, so a stray tap
  /// cannot discard unsaved work.
  final bool maskClosable;

  /// Whether pressing Escape dismisses the modal.
  final bool escapeClosable;

  /// Background color of the dismiss barrier.
  final Color? barrierColor;

  /// Replaces the status icon.
  final Widget? icon;

  /// Replaces the entire footer, discarding the default buttons.
  ///
  /// The supplied widgets are responsible for closing the modal themselves.
  final List<Widget>? footer;

  /// Per-instance token overrides.
  final ModalToken? token;
}

/// Blocking dialogs, reached through the [Modal] getter.
///
/// ```dart
/// final ok = await Modal.confirm(
///   title: 'Delete file?',
///   content: 'This cannot be undone.',
///   danger: true,
/// );
/// if (ok) delete();
/// ```
///
/// The openers above take plain text. For a body that is more than a
/// paragraph — a form, a colour picker — build a [ModalConfig], whose
/// [ModalConfig.title] and [ModalConfig.content] are widgets:
///
/// ```dart
/// Modal.open(ModalConfig(
///   title: const Text('Pick a colour'),
///   content: ColourGrid(onPick: ...),
/// ));
/// ```
///
/// Every opener returns a `Future<bool>` completing with true when confirmed
/// and false when dismissed, so a decision reads as a single `await` rather
/// than a pair of callbacks.
///
/// Requires [UiKit.navigatorKey] to be installed on the app.
class ModalApi {
  const ModalApi._();

  /// A decision with both a confirming and a dismissing action.
  Future<bool> confirm({
    String? title,
    String? content,
    String? okText,
    String? cancelText,
    FutureOr<bool?> Function()? onOk,
    VoidCallback? onCancel,
    bool danger = false,
    bool centered = false,
    double? top,
    bool maskClosable = true,
    Color? barrierColor,
    StatusType? type = StatusType.warning,
  }) =>
      open(
        ModalConfig(
          title: title == null ? null : Text(title),
          content: content == null ? null : Text(content),
          type: type,
          okText: okText == null ? null : Text(okText),
          cancelText: cancelText == null ? null : Text(cancelText),
          onOk: onOk,
          onCancel: onCancel,
          danger: danger,
          centered: centered,
          top: top,
          maskClosable: maskClosable,
          barrierColor: barrierColor,
        ),
      );

  /// An acknowledgement carrying neutral information.
  Future<bool> info({
    String? title,
    String? content,
    String? okText,
    bool centered = false,
    double? top,
    Color? barrierColor,
  }) =>
      _acknowledge(
        StatusType.info,
        title,
        content,
        okText,
        centered,
        top,
        barrierColor,
      );

  /// An acknowledgement confirming something succeeded.
  Future<bool> success({
    String? title,
    String? content,
    String? okText,
    bool centered = false,
    double? top,
    Color? barrierColor,
  }) =>
      _acknowledge(
        StatusType.success,
        title,
        content,
        okText,
        centered,
        top,
        barrierColor,
      );

  /// An acknowledgement reporting a failure.
  Future<bool> error({
    String? title,
    String? content,
    String? okText,
    bool centered = false,
    double? top,
    Color? barrierColor,
  }) =>
      _acknowledge(
        StatusType.error,
        title,
        content,
        okText,
        centered,
        top,
        barrierColor,
      );

  /// An acknowledgement flagging something that needs attention.
  Future<bool> warning({
    String? title,
    String? content,
    String? okText,
    bool centered = false,
    double? top,
    Color? barrierColor,
  }) =>
      _acknowledge(
        StatusType.warning,
        title,
        content,
        okText,
        centered,
        top,
        barrierColor,
      );

  Future<bool> _acknowledge(
    StatusType type,
    String? title,
    String? content,
    String? okText,
    bool centered,
    double? top,
    Color? barrierColor,
  ) =>
      open(
        ModalConfig(
          title: title == null ? null : Text(title),
          content: content == null ? null : Text(content),
          type: type,
          okText: okText == null ? null : Text(okText),
          showCancel: false,
          centered: centered,
          top: top,
          barrierColor: barrierColor,
        ),
      );

  /// Opens a fully configured modal.
  Future<bool> open(ModalConfig config) => _open(config);

  /// Dismisses every open modal, innermost first.
  void destroyAll() {
    for (final entry in List<_ModalEntry>.of(_entries)) {
      entry.dismiss(false);
    }
  }
}

/// The global modal API.
///
/// Named for the thing it opens rather than in `lowerCamelCase`, so that
/// `Modal.confirm(...)` reads as the dialog it raises.
// ignore: non_constant_identifier_names
ModalApi get Modal => const ModalApi._();

// --------------------------------------------------------------------------
// Internals
// --------------------------------------------------------------------------

/// Open modals, outermost first. Stacking is allowed so a confirmation can
/// itself raise an error dialog.
final List<_ModalEntry> _entries = [];

class _ModalEntry {
  _ModalEntry(this.config);

  final ModalConfig config;
  final Completer<bool> completer = Completer<bool>();
  final GlobalKey<_ModalCardState> cardKey = GlobalKey<_ModalCardState>();
  OverlayEntry? overlayEntry;
  late final OverlayPopScope popScope = OverlayPopScope(
    onPop: () => dismiss(false),
  );
  bool _closing = false;

  /// Runs the exit animation, then completes the future with [result].
  void dismiss(bool result) {
    if (_closing) return;
    _closing = true;
    popScope.unregister();
    if (!result) config.onCancel?.call();

    void finish() {
      overlayEntry?.remove();
      overlayEntry = null;
      _entries.remove(this);
      if (!completer.isCompleted) completer.complete(result);
    }

    final state = cardKey.currentState;
    if (state == null) {
      finish();
    } else {
      state.playExit(finish);
    }
  }
}

Future<bool> _open(ModalConfig config) {
  final entry = _ModalEntry(config);
  entry.overlayEntry = OverlayEntry(
    builder: (context) => _ModalLayer(entry: entry, key: ValueKey(entry)),
  );
  _entries.add(entry);
  UiKit.requireOverlay().insert(entry.overlayEntry!);
  entry.popScope.register();
  return entry.completer.future;
}

class _ModalLayer extends StatelessWidget {
  const _ModalLayer({super.key, required this.entry});

  final _ModalEntry entry;

  @override
  Widget build(BuildContext context) {
    final config = entry.config;
    final token = ConfigProvider.of(context).token;

    // A modal owns the keyboard while it is open: focus is trapped inside so
    // Tab cannot reach the page behind the mask.
    return FocusScope(
      // Focus must actually land inside the modal, otherwise key events keep
      // going to whatever the page behind the mask had focused — and Escape
      // never reaches us.
      autofocus: true,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape &&
              config.escapeClosable) {
            entry.dismiss(false);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: DefaultTextStyle(
          // The overlay sits outside any Material ancestor, where Flutter
          // falls back to a debug style with yellow underlines.
          style: TextStyle(
            color: token.colorText,
            fontSize: token.fontSize,
            fontFamily: token.fontFamily,
            fontFamilyFallback: token.fontFamilyFallback,
            decoration: TextDecoration.none,
          ),
          child: _ModalCard(key: entry.cardKey, entry: entry),
        ),
      ),
    );
  }
}

class _ModalCard extends StatefulWidget {
  const _ModalCard({super.key, required this.entry});

  final _ModalEntry entry;

  @override
  State<_ModalCard> createState() => _ModalCardState();
}

class _ModalCardState extends State<_ModalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..forward();

  bool _confirming = false;

  ModalConfig get _config => widget.entry.config;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Runs the exit animation, invoking [done] once it finishes.
  void playExit(VoidCallback done) {
    _controller.reverse().whenComplete(done);
  }

  Future<void> _handleOk() async {
    final onOk = _config.onOk;
    if (onOk == null) {
      widget.entry.dismiss(true);
      return;
    }

    // An async handler keeps the button spinning and the modal open, so the
    // user cannot act twice on a decision that is still being applied.
    setState(() => _confirming = true);
    try {
      final result = await onOk();
      if (result == false) return; // handler vetoed the close
      widget.entry.dismiss(true);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (_config.token ??
            ConfigProvider.componentOf<ModalToken>(context) ??
            const ModalToken())
        ._resolve(token);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: token.motionEaseOutCirc,
      reverseCurve: token.motionEaseInOut,
    );

    return FadeTransition(
      opacity: curved,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _config.maskClosable
                  ? () => widget.entry.dismiss(false)
                  : null,
              child: ColoredBox(color: _config.barrierColor ?? r.colorBgMask),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Align(
                alignment: _config.centered
                    ? Alignment.center
                    : _config.top != null
                        // An explicit offset pins the dialog to the top edge;
                        // padding then pushes it down by that much.
                        ? Alignment.topCenter
                        : const Alignment(0, -0.6),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: _config.centered ? 0 : (_config.top ?? 0),
                  ),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
                    // Taps inside the dialog must not reach the mask below.
                    child: GestureDetector(
                      onTap: () {},
                      child: _dialog(token, r),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialog(Token token, _ResolvedModalToken r) {
    final config = _config;
    final available = MediaQuery.sizeOf(context).width - token.sizeLG * 2;
    final hasIcon = config.icon != null || config.type != null;

    return Container(
      width: math.min(config.width, math.max(0, available)),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      padding: r.padding,
      decoration: BoxDecoration(
        color: r.colorBgElevated,
        borderRadius: BorderRadius.circular(r.borderRadius),
        boxShadow: token.boxShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Flexible bounds the body's height against the dialog's maxHeight,
          // which is what lets long content scroll instead of overflowing.
          Flexible(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasIcon) ...[
                  config.icon ?? StatusIcon(type: config.type!, token: token),
                  SizedBox(width: token.sizeSM),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (config.title != null)
                        DefaultTextStyle(
                          style: TextStyle(
                            color: token.colorText,
                            fontSize: r.titleFontSize,
                            fontFamily: token.fontFamily,
                            fontFamilyFallback: token.fontFamilyFallback,
                            fontWeight: token.fontWeightStrong,
                            decoration: TextDecoration.none,
                          ),
                          child: config.title!,
                        ),
                      if (config.title != null && config.content != null)
                        SizedBox(height: token.sizeXS),
                      if (config.content != null)
                        // Scrolls only once the body outgrows the dialog's
                        // height cap, so short content is unaffected.
                        Flexible(
                          child: SingleChildScrollView(
                            child: DefaultTextStyle(
                              style: TextStyle(
                                color: token.colorTextSecondary,
                                fontSize: r.contentFontSize,
                                fontFamily: token.fontFamily,
                                fontFamilyFallback: token.fontFamilyFallback,
                                height: token.lineHeight,
                                decoration: TextDecoration.none,
                              ),
                              child: config.content!,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (config.closable) ...[
                  SizedBox(width: token.sizeXS),
                  _ModalCloseButton(
                    token: token,
                    onTap: () => widget.entry.dismiss(false),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: token.sizeLG),
          _footer(token),
        ],
      ),
    );
  }

  Widget _footer(Token token) {
    final config = _config;
    final custom = config.footer;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (custom != null)
          for (final widget in custom)
            Padding(
              padding: EdgeInsets.only(left: token.sizeXS),
              child: widget,
            )
        else ...[
          if (config.showCancel)
            Button(
              // Cancelling must stay available while the confirm is running,
              // otherwise a hung request traps the user in the dialog.
              onPressed: () => widget.entry.dismiss(false),
              child: config.cancelText ?? Text(context.seedLocale.cancel),
            ),
          SizedBox(width: token.sizeXS),
          Button(
            variant: ButtonVariant.solid,
            color: config.danger ? ButtonColor.danger : ButtonColor.primary,
            loading: _confirming,
            onPressed: _handleOk,
            child: config.okText ?? Text(context.seedLocale.ok),
          ),
        ],
      ],
    );
  }
}

class _ModalCloseButton extends StatefulWidget {
  const _ModalCloseButton({required this.token, required this.onTap});

  final Token token;
  final VoidCallback onTap;

  @override
  State<_ModalCloseButton> createState() => _ModalCloseButtonState();
}

class _ModalCloseButtonState extends State<_ModalCloseButton> {
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
