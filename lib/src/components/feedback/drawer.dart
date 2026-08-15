import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/overlay_host.dart';

/// Edge a drawer slides in from.
enum DrawerPlacement {
  /// From the left edge; the panel's width is its [DrawerConfig.size].
  left,

  /// From the right edge; the panel's width is its [DrawerConfig.size].
  right,

  /// From the top edge; the panel's height is its [DrawerConfig.size].
  top,

  /// From the bottom edge; the panel's height is its [DrawerConfig.size].
  bottom,
}

/// Dismisses an open drawer ahead of any user interaction.
typedef DrawerHandle = void Function();

/// Per-component design tokens for [Drawer].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [DrawerToken(...)])`, or per instance via [DrawerConfig.token].
@immutable
class DrawerToken {
  /// Creates a [DrawerToken].
  const DrawerToken({
    this.colorBgMask,
    this.colorBgElevated,
    this.padding,
    this.footerPadding,
  });

  /// Mask backdrop color (`colorBgMask`).
  final Color? colorBgMask;

  /// Panel background color (`colorBgElevated`).
  final Color? colorBgElevated;

  /// Body padding (`padding`).
  final EdgeInsets? padding;

  /// Footer padding (`footerPadding`).
  final EdgeInsets? footerPadding;

  _ResolvedDrawerToken _resolve(Token t) => _ResolvedDrawerToken(
        colorBgMask: colorBgMask ?? t.colorBgMask,
        colorBgElevated: colorBgElevated ?? t.colorBgElevated,
        padding: padding ?? EdgeInsets.all(t.sizeLG),
        footerPadding: footerPadding ??
            EdgeInsets.symmetric(horizontal: t.sizeLG, vertical: t.sizeSM),
      );
}

@immutable
class _ResolvedDrawerToken {
  const _ResolvedDrawerToken({
    required this.colorBgMask,
    required this.colorBgElevated,
    required this.padding,
    required this.footerPadding,
  });

  final Color colorBgMask;
  final Color colorBgElevated;
  final EdgeInsets padding;
  final EdgeInsets footerPadding;
}

/// Everything a single drawer can be configured with.
///
/// Pass one to [DrawerApi.open].
@immutable
class DrawerConfig {
  /// Creates a [DrawerConfig].
  const DrawerConfig({
    required this.child,
    this.title,
    this.placement = DrawerPlacement.right,
    this.size = 378,
    this.onClose,
    this.closable = true,
    this.maskClosable = true,
    this.escapeClosable = true,
    this.padding,
    this.barrierColor,
    this.token,
  });

  /// The panel's content, laid out below the optional header.
  final Widget child;

  /// Header text shown at the top of the panel, above a divider.
  final String? title;

  /// Which edge the panel slides in from.
  final DrawerPlacement placement;

  /// Extent along the sliding axis: the width for [DrawerPlacement.left]
  /// and [DrawerPlacement.right], the height for top and bottom. Capped to
  /// the viewport.
  final double size;

  /// Called when the drawer is dismissed by any means.
  final VoidCallback? onClose;

  /// Whether to show the close icon in the header.
  ///
  /// Only meaningful alongside a [title], since the icon lives in the header.
  final bool closable;

  /// Whether tapping the mask dismisses the drawer.
  final bool maskClosable;

  /// Whether pressing Escape dismisses the drawer.
  final bool escapeClosable;

  /// Padding around [child]. Defaults to a uniform large-size inset.
  final EdgeInsets? padding;

  /// Background color of the dismiss barrier.
  final Color? barrierColor;

  /// Per-instance token overrides.
  final DrawerToken? token;
}

/// Sliding side panels, reached through the [Drawer] getter.
///
/// ```dart
/// final closed = await Drawer.open(DrawerConfig(
///   title: 'Filters',
///   child: FiltersForm(),
/// ));
/// ```
///
/// [open] returns a `Future<void>` that completes once the drawer has closed,
/// so work can be sequenced after it.
///
/// Requires [UiKit.navigatorKey] to be installed on the app.
class DrawerApi {
  const DrawerApi._();

  /// Opens a drawer and completes when it closes.
  Future<void> open(DrawerConfig config) => _open(config);

  /// Dismisses every open drawer.
  void destroyAll() {
    for (final entry in List<_DrawerEntry>.of(_entries)) {
      entry.dismiss();
    }
  }
}

/// The global drawer API.
///
/// Named for the thing it opens rather than in `lowerCamelCase`, so that
/// `Drawer.open(...)` reads the same as the widget it stands in for.
// ignore: non_constant_identifier_names
DrawerApi get Drawer => const DrawerApi._();

// --------------------------------------------------------------------------
// Internals
// --------------------------------------------------------------------------

/// Open drawers, oldest first. Stacking is allowed, though uncommon.
final List<_DrawerEntry> _entries = [];

class _DrawerEntry {
  _DrawerEntry(this.config);

  final DrawerConfig config;
  final Completer<void> completer = Completer<void>();
  final GlobalKey<_DrawerScaffoldState> cardKey =
      GlobalKey<_DrawerScaffoldState>();
  OverlayEntry? overlayEntry;
  late final OverlayPopScope popScope = OverlayPopScope(
    onPop: dismiss,
  );
  bool _closing = false;

  /// Runs the exit animation, then completes the future.
  void dismiss() {
    if (_closing) return;
    _closing = true;
    popScope.unregister();
    config.onClose?.call();

    void finish() {
      overlayEntry?.remove();
      overlayEntry = null;
      _entries.remove(this);
      if (!completer.isCompleted) completer.complete();
    }

    final state = cardKey.currentState;
    if (state == null) {
      finish();
    } else {
      state.playExit(finish);
    }
  }
}

Future<void> _open(DrawerConfig config) {
  final entry = _DrawerEntry(config);
  entry.overlayEntry = OverlayEntry(
    builder: (context) => _DrawerLayer(entry: entry, key: ValueKey(entry)),
  );
  _entries.add(entry);
  UiKit.requireOverlay().insert(entry.overlayEntry!);
  entry.popScope.register();
  return entry.completer.future;
}

class _DrawerLayer extends StatelessWidget {
  const _DrawerLayer({super.key, required this.entry});

  final _DrawerEntry entry;

  @override
  Widget build(BuildContext context) {
    final config = entry.config;
    final token = ConfigProvider.of(context).token;

    // A drawer owns the keyboard while open: focus is trapped inside so Tab
    // cannot reach the page behind the mask, and Escape reaches the panel.
    return FocusScope(
      autofocus: true,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape &&
              config.escapeClosable) {
            entry.dismiss();
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
          child: _DrawerScaffold(key: entry.cardKey, entry: entry),
        ),
      ),
    );
  }
}

class _DrawerScaffold extends StatefulWidget {
  const _DrawerScaffold({super.key, required this.entry});

  final _DrawerEntry entry;

  @override
  State<_DrawerScaffold> createState() => _DrawerScaffoldState();
}

class _DrawerScaffoldState extends State<_DrawerScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward();

  DrawerConfig get _config => widget.entry.config;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Runs the exit animation, invoking [done] once it finishes.
  void playExit(VoidCallback done) {
    _controller.reverse().whenComplete(done);
  }

  bool get _isHorizontal =>
      _config.placement == DrawerPlacement.left ||
      _config.placement == DrawerPlacement.right;

  Offset get _hiddenOffset => switch (_config.placement) {
        DrawerPlacement.left => const Offset(-1, 0),
        DrawerPlacement.right => const Offset(1, 0),
        DrawerPlacement.top => const Offset(0, -1),
        DrawerPlacement.bottom => const Offset(0, 1),
      };

  Alignment get _alignment => switch (_config.placement) {
        DrawerPlacement.left => Alignment.centerLeft,
        DrawerPlacement.right => Alignment.centerRight,
        DrawerPlacement.top => Alignment.topCenter,
        DrawerPlacement.bottom => Alignment.bottomCenter,
      };

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (_config.token ??
            ConfigProvider.componentOf<DrawerToken>(context) ??
            const DrawerToken())
        ._resolve(token);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: token.motionEaseOut,
      reverseCurve: token.motionEaseInOut,
    );

    return Stack(
      children: [
        // The mask fades while the panel slides.
        Positioned.fill(
          child: FadeTransition(
            opacity: curved,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _config.maskClosable ? widget.entry.dismiss : null,
              child: ColoredBox(color: _config.barrierColor ?? r.colorBgMask),
            ),
          ),
        ),
        Align(
          alignment: _alignment,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: _hiddenOffset,
              end: Offset.zero,
            ).animate(curved),
            // Taps inside the panel must not reach the mask below.
            child: GestureDetector(
              onTap: () {},
              child: _panel(token, r),
            ),
          ),
        ),
      ],
    );
  }

  Widget _panel(Token token, _ResolvedDrawerToken r) {
    final config = _config;
    final media = MediaQuery.sizeOf(context);
    // Cap the sliding extent to the viewport so a large size never overflows.
    final maxExtent = _isHorizontal ? media.width : media.height;
    final extent = config.size.clamp(0.0, maxExtent);

    return Container(
      // Along the sliding axis the panel is [extent]; across it, it fills the
      // viewport — a left/right drawer is full height, a top/bottom one full
      // width.
      width: _isHorizontal ? extent : double.infinity,
      height: _isHorizontal ? double.infinity : extent,
      decoration: BoxDecoration(
        color: r.colorBgElevated,
        boxShadow: token.boxShadow,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            if (config.title != null) _header(token),
            Expanded(
              child: Padding(
                padding: config.padding ?? r.padding,
                child: config.child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(Token token) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: token.sizeLG,
            vertical: token.size,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _config.title!,
                  style: TextStyle(
                    color: token.colorText,
                    fontSize: token.fontSizeLG,
                    fontFamily: token.fontFamily,
                    fontFamilyFallback: token.fontFamilyFallback,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              if (_config.closable) ...[
                SizedBox(width: token.sizeXS),
                _DrawerCloseButton(
                  token: token,
                  onTap: widget.entry.dismiss,
                ),
              ],
            ],
          ),
        ),
        Container(height: token.lineWidth, color: token.colorSplit),
      ],
    );
  }
}

class _DrawerCloseButton extends StatefulWidget {
  const _DrawerCloseButton({required this.token, required this.onTap});

  final Token token;
  final VoidCallback onTap;

  @override
  State<_DrawerCloseButton> createState() => _DrawerCloseButtonState();
}

class _DrawerCloseButtonState extends State<_DrawerCloseButton> {
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
