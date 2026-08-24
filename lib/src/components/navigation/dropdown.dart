import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/services.dart' show BrowserContextMenu;
import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/popover.dart';

/// How a [Dropdown] is opened.
enum DropdownTrigger {
  /// Opens while the pointer is over the trigger (desktop menus).
  hover,

  /// Opens on a primary tap and closes on an outside tap.
  click,

  /// Opens on a secondary tap / long-press (a context menu).
  contextMenu,
}

/// Base type for the entries of a [Dropdown] menu: an item, a divider or a
/// titled group.
@immutable
sealed class DropdownEntry {
  const DropdownEntry();
}

/// A selectable row in a [Dropdown] menu.
class DropdownItem extends DropdownEntry {
  /// Creates a [DropdownItem].
  const DropdownItem({
    this.key,
    this.label,
    this.icon,
    this.disabled = false,
    this.danger = false,
    this.children,
    this.onTap,
  });

  /// Identity reported through [Dropdown.onItemTap].
  final Object? key;

  /// The row's content.
  final Widget? label;

  /// Optional leading icon.
  final Widget? icon;

  /// Greys the row out and blocks tapping.
  final bool disabled;

  /// Recolours the row red, for destructive actions.
  final bool danger;

  /// A nested submenu, opened to the side on hover.
  final List<DropdownEntry>? children;

  /// Tapped handler. [Dropdown.onItemTap] also fires with [key].
  final VoidCallback? onTap;

  bool get _hasChildren => children != null && children!.isNotEmpty;
}

/// A horizontal divider between [Dropdown] entries.
class DropdownDivider extends DropdownEntry {
  /// Creates a [DropdownDivider].
  const DropdownDivider();
}

/// A titled group of [Dropdown] entries.
class DropdownGroup extends DropdownEntry {
  /// Creates a [DropdownGroup].
  const DropdownGroup({required this.label, required this.children});

  /// The group heading.
  final Widget label;

  /// The entries under the heading.
  final List<DropdownEntry> children;
}

/// Per-component design tokens for [Dropdown].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(dropdown: DropdownToken(...)))`,
/// or per instance via [Dropdown.token].
@immutable
class DropdownToken {
  /// Creates a [DropdownToken].
  const DropdownToken({
    this.menuBg,
    this.padding,
    this.borderRadius,
    this.itemHoverBg,
    this.barrierColor,
  });

  /// Menu background color (`menuBg`).
  final Color? menuBg;

  /// Menu padding (`padding`).
  final EdgeInsets? padding;

  /// Menu corner radius (`borderRadius`).
  final double? borderRadius;

  /// Item hover background color (`itemHoverBg`).
  final Color? itemHoverBg;

  /// Dismiss barrier background color (`barrierColor`).
  final Color? barrierColor;

  _ResolvedDropdownToken _resolve(Token t) => _ResolvedDropdownToken(
        menuBg: menuBg ?? t.colorBgElevated,
        padding: padding ?? EdgeInsets.all(t.sizeXXS),
        borderRadius: borderRadius ?? t.borderRadiusLG,
        itemHoverBg: itemHoverBg ?? t.colorFillTertiary,
        barrierColor: barrierColor,
      );
}

@immutable
class _ResolvedDropdownToken {
  const _ResolvedDropdownToken({
    required this.menuBg,
    required this.padding,
    required this.borderRadius,
    required this.itemHoverBg,
    this.barrierColor,
  });

  final Color menuBg;
  final EdgeInsets padding;
  final double borderRadius;
  final Color itemHoverBg;
  final Color? barrierColor;
}

/// Defaults for every [Dropdown] under a `ConfigProvider`.
///
/// House style for dropdown menus: where they sit and what opens them.
@immutable
class DropdownDefaults {
  /// Creates a [DropdownDefaults].
  const DropdownDefaults(
      {this.placement, this.arrow, this.closeOnSelect, this.trigger});

  /// Where menus sit against their anchor.
  final PopoverPlacement? placement;

  /// Whether menus draw a pointer.
  final bool? arrow;

  /// Whether picking an item closes the menu.
  final bool? closeOnSelect;

  /// What opens a menu.
  final List<DropdownTrigger>? trigger;
}

/// A menu that floats from a trigger.
///
/// Wrap any widget and describe the [menu]; the menu opens on the configured
/// [trigger], positioned by [placement] and flipping to stay on screen. It is
/// the shared overlay primitive behind menus, and [Select] builds its option
/// popup on the same [DropdownPanel] chrome.
///
/// ```dart
/// Dropdown(
///   menu: [
///     DropdownItem(key: 'edit', label: const Text('Edit')),
///     DropdownItem(key: 'delete', label: const Text('Delete'), danger: true),
///   ],
///   onItemTap: (key) => handle(key),
///   child: Button(child: const Text('Actions')),
/// )
/// ```
class Dropdown extends StatefulWidget {
  /// Creates a [Dropdown].
  const Dropdown({
    super.key,
    required this.child,
    this.menu,
    this.content,
    this.trigger,
    this.placement,
    this.disabled,
    this.open,
    this.onOpenChange,
    this.arrow,
    this.onItemTap,
    this.closeOnSelect,
    this.popupRender,
    this.barrierColor,
    this.token,
  }) : assert(
          menu != null || content != null,
          'Provide either menu or content.',
        );

  /// The trigger the menu anchors to.
  final Widget child;

  /// The menu entries. Mutually exclusive with [content].
  final List<DropdownEntry>? menu;

  /// A fully custom popup body, instead of
  /// [menu]. Receives a callback to close the dropdown.
  final Widget Function(BuildContext context, VoidCallback close)? content;

  /// Wraps the default [menu]. Receives the built
  /// menu and returns the popup body (still inside the panel chrome), e.g. to
  /// append a divider and an input below the menu. Ignored when [content] is
  /// set.
  final Widget Function(BuildContext context, Widget menu)? popupRender;

  /// Which gestures open the menu.
  final List<DropdownTrigger>? trigger;

  /// Which side of the trigger the menu prefers.
  final PopoverPlacement? placement;

  /// Greys the trigger out and blocks opening.
  final bool? disabled;

  /// Drives visibility externally. Null lets the dropdown manage its own state.
  final bool? open;

  /// Notified when the menu wants to open or close.
  final ValueChanged<bool>? onOpenChange;

  /// Draws a caret pointing at the trigger.
  final bool? arrow;

  /// Called with an item's `key` when it is tapped.
  final ValueChanged<Object?>? onItemTap;

  /// Whether tapping an item closes the menu (ignored for submenu parents).
  final bool? closeOnSelect;

  /// Background color of the dismiss barrier.
  final Color? barrierColor;

  /// Per-instance token overrides.
  final DropdownToken? token;

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  /// The defaults set for this component in the subtree, if any.
  DropdownDefaults? get _defaults =>
      ConfigProvider.defaultsOf<DropdownDefaults>(context);

  /// This widget's word, then the subtree's, then the kit's.
  PopoverPlacement get _placement =>
      widget.placement ?? _defaults?.placement ?? PopoverPlacement.bottomLeft;

  /// This widget's word, then the subtree's, then the kit's.
  bool get _arrow => widget.arrow ?? _defaults?.arrow ?? false;

  /// This widget's word, then the subtree's, then the kit's.
  bool get _closeOnSelect =>
      widget.closeOnSelect ?? _defaults?.closeOnSelect ?? true;

  /// This widget's word, then the subtree's, then the kit's.
  List<DropdownTrigger> get _trigger =>
      widget.trigger ?? _defaults?.trigger ?? const [DropdownTrigger.hover];

  /// Whether this control is disabled: its own word, else the one set
  /// for the subtree, else no.
  bool get _disabled =>
      widget.disabled ?? ConfigProvider.componentDisabledOf(context) ?? false;

  final PopoverController _popover = PopoverController();
  final GlobalKey _anchorKey = GlobalKey();
  bool _open = false;

  // Hover bookkeeping: the menu stays open while the pointer is over either the
  // trigger or the panel, and closes shortly after it leaves both.
  bool _overTrigger = false;
  bool _overPanel = false;

  /// Where a click-trigger press started, so a drag or a scroll that ends over
  /// the trigger is not mistaken for a tap.
  Offset? _tapOrigin;

  bool get _hoverMode => _trigger.contains(DropdownTrigger.hover);

  bool _suppressedBrowserMenu = false;

  /// Rebuilds the (overlay) menu when the widget's config changes while open.
  final ValueNotifier<int> _rev = ValueNotifier<int>(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On web a secondary tap otherwise pops the native browser menu over
    // ours. Settled here rather than in initState: the trigger may come from
    // the provider's defaults, and inherited widgets cannot be read that
    // early.
    if (kIsWeb &&
        !_suppressedBrowserMenu &&
        _trigger.contains(DropdownTrigger.contextMenu)) {
      BrowserContextMenu.disableContextMenu();
      _suppressedBrowserMenu = true;
    }
  }

  @override
  void initState() {
    super.initState();
    // Honour an initial controlled-open state.
    if (widget.open ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (widget.open ?? false)) _show();
      });
    }
  }

  @override
  void didUpdateWidget(Dropdown old) {
    super.didUpdateWidget(old);
    if (widget.open != null && widget.open != _open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.open! ? _show() : _hide();
      });
    }
    // The menu lives in an overlay whose entry is built once; bump the revision
    // so changed menu items (or a popupRender closing over new state) show at
    // once, not only after reopening. Deferred, since notifying the overlay's
    // listener during this build phase is illegal.
    if (_open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _open) _rev.value++;
      });
    }
  }

  @override
  void dispose() {
    if (_suppressedBrowserMenu) BrowserContextMenu.enableContextMenu();
    _popover.dispose();
    _rev.dispose();
    super.dispose();
  }

  void _requestOpen(bool next) {
    if (_disabled) return;
    if (widget.onOpenChange != null) widget.onOpenChange!(next);
    if (widget.open == null) {
      next ? _show() : _hide();
    }
  }

  void _show() {
    if (_open || _disabled) return;
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    setState(() => _open = true);
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<DropdownToken>(context) ??
            const DropdownToken())
        ._resolve(token);
    _popover.open(
      placement: _placement,
      anchorRect: anchor,
      gap: token.sizeXXS,
      // Hover menus have no dismiss barrier, so hovering elsewhere still works;
      // click/context menus close on an outside tap.
      onDismiss: _hoverMode ? null : () => _requestOpen(false),
      interactive: true,
      arrowColor: _arrow ? token.colorBgElevated : null,
      arrowShadow: _arrow ? token.boxShadowSecondary : null,
      barrierColor: widget.barrierColor ?? r.barrierColor,
      anchorContext: context,
      onScrollDismiss: () => _requestOpen(false),
      builder: (context) => ValueListenableBuilder<int>(
        valueListenable: _rev,
        builder: (context, _, __) => _hoverMode
            ? MouseRegion(
                onEnter: (_) => _overPanel = true,
                onExit: (_) {
                  _overPanel = false;
                  _scheduleHoverClose();
                },
                child: _panel(context),
              )
            : _panel(context),
      ),
    );
  }

  Widget _panel(BuildContext context) {
    if (widget.content != null) {
      return widget.content!(context, () => _requestOpen(false));
    }
    final Widget menu = DropdownMenuList(
      entries: widget.menu!,
      onSelect: (item) {
        widget.onItemTap?.call(item.key);
        item.onTap?.call();
        if (_closeOnSelect) _requestOpen(false);
      },
    );
    return DropdownPanel(
      child: widget.popupRender != null
          ? widget.popupRender!(context, menu)
          : menu,
    );
  }

  void _hide() {
    if (!_open) return;
    // The panel's MouseRegion is torn down without firing onExit, so clear the
    // hover flags here — otherwise a stale _overPanel keeps the next hover open.
    _overPanel = false;
    _overTrigger = false;
    setState(() => _open = false);
    _popover.close();
  }

  void _scheduleHoverClose() {
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted && !_overTrigger && !_overPanel) _requestOpen(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget trigger = KeyedSubtree(key: _anchorKey, child: widget.child);

    if (_trigger.contains(DropdownTrigger.click)) {
      // Deliberately a Listener, not a GestureDetector: the child is often a
      // Button or another tappable, whose own recognizer sits deeper in the
      // tree and would win the gesture arena outright, leaving the menu dead.
      // A Listener takes no part in the arena, so the trigger opens and the
      // child's own onPressed still fires.
      trigger = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) => _tapOrigin = event.position,
        onPointerCancel: (_) => _tapOrigin = null,
        onPointerUp: (event) {
          final origin = _tapOrigin;
          _tapOrigin = null;
          // Anything that travelled is a drag or a scroll, not a tap.
          if (origin == null ||
              (event.position - origin).distance > kTouchSlop) {
            return;
          }
          _requestOpen(!_open);
        },
        child: trigger,
      );
    }

    if (_trigger.contains(DropdownTrigger.contextMenu)) {
      trigger = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTap: () => _requestOpen(!_open),
        onLongPress: () => _requestOpen(!_open),
        child: trigger,
      );
    }

    if (_hoverMode) {
      trigger = MouseRegion(
        onEnter: (_) {
          _overTrigger = true;
          _requestOpen(true);
        },
        onExit: (_) {
          _overTrigger = false;
          _scheduleHoverClose();
        },
        child: trigger,
      );
    }

    return trigger;
  }
}

/// The elevated surface a dropdown menu — or any floating panel such as a
/// [Select]'s options — is painted on: background, radius, shadow and clipping.
class DropdownPanel extends StatelessWidget {
  /// Creates a [DropdownPanel].
  const DropdownPanel({
    super.key,
    required this.child,
    this.minWidth = 120,
    this.token,
  });

  /// The panel body.
  final Widget child;

  /// Least width the panel may shrink to.
  final double minWidth;

  /// Per-instance token overrides.
  final DropdownToken? token;

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (this.token ??
            ConfigProvider.componentOf<DropdownToken>(context) ??
            const DropdownToken())
        ._resolve(token);
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: r.menuBg,
          borderRadius: BorderRadius.circular(r.borderRadius),
          boxShadow: token.boxShadowSecondary,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r.borderRadius),
          child: child,
        ),
      ),
    );
  }
}

/// Renders a list of [DropdownEntry]s as menu rows. Used inside a
/// [DropdownPanel].
class DropdownMenuList extends StatelessWidget {
  /// Creates a [DropdownMenuList].
  const DropdownMenuList({
    super.key,
    required this.entries,
    required this.onSelect,
  });

  /// The rows to render, in order — items, groups and dividers.
  final List<DropdownEntry> entries;

  /// Called with the item the user chose.
  final ValueChanged<DropdownItem> onSelect;

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    // IntrinsicWidth sizes the menu to its widest row, so the rows' Expanded
    // labels do not stretch the panel to the whole viewport width.
    return IntrinsicWidth(
      child: Padding(
        padding: EdgeInsets.all(token.sizeXXS),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in entries) _buildEntry(context, token, entry),
          ],
        ),
      ),
    );
  }

  Widget _buildEntry(BuildContext context, Token token, DropdownEntry entry) {
    switch (entry) {
      case DropdownDivider():
        return Padding(
          padding: EdgeInsets.symmetric(vertical: token.sizeXXS),
          child: Container(height: token.lineWidth, color: token.colorSplit),
        );
      case DropdownGroup(:final label, :final children):
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                token.sizeSM,
                token.sizeXXS,
                token.sizeSM,
                token.sizeXXS,
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: token.colorTextTertiary,
                  fontSize: token.fontSizeSM,
                  fontFamily: token.fontFamily,
                  fontFamilyFallback: token.fontFamilyFallback,
                  decoration: TextDecoration.none,
                ),
                child: label,
              ),
            ),
            for (final c in children) _buildEntry(context, token, c),
          ],
        );
      case DropdownItem():
        return _MenuRow(item: entry, onSelect: onSelect);
    }
  }
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({required this.item, required this.onSelect});

  final DropdownItem item;
  final ValueChanged<DropdownItem> onSelect;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hovered = false;
  final PopoverController _submenu = PopoverController();
  bool _submenuOpen = false;

  @override
  void dispose() {
    _submenu.dispose();
    super.dispose();
  }

  /// Opens the submenu, or closes it if it is already open.
  ///
  /// Hover alone is not enough to reach one: a touch screen has no pointer to
  /// hover with, and a submenu parent takes no other action, so on a phone the
  /// row simply did nothing. A tap works for both — on a desktop the menu is
  /// usually open by then anyway, and tapping closes it again.
  void _toggleSubmenu() {
    if (_submenuOpen) {
      _submenu.close();
      _submenuOpen = false;
      return;
    }
    _openSubmenu();
  }

  void _openSubmenu() {
    if (_submenuOpen) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    _submenuOpen = true;
    final token = context.softToken;
    _submenu.open(
      // Out to the side the menu reads towards, so a mirrored layout opens
      // its submenus away from the parent rather than back over it.
      placement: Directionality.of(context) == TextDirection.rtl
          ? PopoverPlacement.leftTop
          : PopoverPlacement.rightTop,
      anchorRect: anchor,
      gap: token.sizeXXS,
      interactive: true,
      builder: (context) => MouseRegion(
        onEnter: (_) => _hovered = true,
        onExit: (_) {
          _hovered = false;
          _closeSubmenuSoon();
        },
        child: DropdownPanel(
          child: DropdownMenuList(
            entries: widget.item.children!,
            onSelect: widget.onSelect,
          ),
        ),
      ),
    );
  }

  void _closeSubmenuSoon() {
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted && !_hovered) {
        _submenu.close();
        _submenuOpen = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final item = widget.item;
    final disabled = item.disabled;
    final base = item.danger ? token.error.base : token.colorText;
    final color = disabled ? token.colorTextQuaternary : base;
    final bg = _hovered && !disabled
        ? (item.danger ? token.error.bg : token.colorFillTertiary)
        : const Color(0x00000000);

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        if (item._hasChildren && !disabled) _openSubmenu();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        if (item._hasChildren) _closeSubmenuSoon();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled
            ? null
            : item._hasChildren
                ? _toggleSubmenu
                : () => widget.onSelect(item),
        child: AnimatedContainer(
          duration: token.motionDurationFast,
          height: token.controlHeight,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: EdgeInsets.symmetric(horizontal: token.sizeSM),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(token.borderRadiusSM),
          ),
          child: Row(
            children: [
              if (item.icon != null) ...[
                IconTheme.merge(
                  data: IconThemeData(color: color, size: token.fontSize),
                  child: item.icon!,
                ),
                SizedBox(width: token.sizeXS),
              ],
              Expanded(
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: color,
                    fontSize: token.fontSize,
                    fontFamily: token.fontFamily,
                    fontFamilyFallback: token.fontFamilyFallback,
                    decoration: TextDecoration.none,
                  ),
                  child: item.label ?? const SizedBox.shrink(),
                ),
              ),
              if (item._hasChildren) ...[
                SizedBox(width: token.sizeXS),
                CustomPaint(
                  size: const Size(8, 12),
                  painter: _CaretPainter(token.colorTextTertiary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A right-pointing caret marking a submenu parent.
class _CaretPainter extends CustomPainter {
  _CaretPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.25, size.height * 0.2)
        ..lineTo(size.width * 0.75, size.height * 0.5)
        ..lineTo(size.width * 0.25, size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CaretPainter old) => old.color != color;
}
