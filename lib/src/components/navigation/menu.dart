import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/popover.dart' show PopoverPlacement;
import '../data_display/tooltip.dart';
import 'dropdown.dart';

/// How a [Menu] lays itself out and where its submenus open.
enum MenuMode {
  /// A column, as in a sidebar; a submenu opens in place, under its title.
  inline,

  /// A column; a submenu floats out beside its title.
  vertical,

  /// A row, as in a top bar; a submenu drops down under its title.
  horizontal,
}

/// Base type for the entries of a [Menu]: an item, a group or a divider.
@immutable
abstract class MenuEntry<T> {
  /// Const constructor for subclasses.
  const MenuEntry();
}

/// A place in a [Menu], or, with [children], the title of a submenu.
///
/// Like a [DropdownItem], an item is data: its words are a `String`, and [T]
/// tells one item from another — a route, an id, an enum.
class MenuItem<T> extends MenuEntry<T> {
  /// Creates a [MenuItem].
  const MenuItem({
    this.value,
    this.label,
    this.icon,
    this.extra,
    this.disabled = false,
    this.danger = false,
    this.children,
    this.onTap,
  });

  /// What this item reports through [Menu.onSelect], and how the menu tells
  /// which item is selected and which submenus are open.
  final T? value;

  /// The item's words.
  final String? label;

  /// An icon before the words. In a collapsed menu it is all that shows.
  final Widget? icon;

  /// Something after the words, at the far end of the row: a count, a badge.
  final Widget? extra;

  /// Greys the item out; it cannot be chosen or opened.
  final bool disabled;

  /// Draws the item in the error colour, for something that destroys.
  final bool danger;

  /// The entries of this item's submenu. An item with children is a title:
  /// choosing it opens the submenu instead of selecting it.
  final List<MenuEntry<T>>? children;

  /// Called when the item is chosen, beside [Menu.onSelect].
  final VoidCallback? onTap;
}

/// A titled run of entries inside a [Menu].
class MenuGroup<T> extends MenuEntry<T> {
  /// Creates a [MenuGroup].
  const MenuGroup({required this.label, required this.children});

  /// The group heading.
  final String label;

  /// The entries under the heading.
  final List<MenuEntry<T>> children;
}

/// A thin line between entries of a [Menu].
class MenuDivider<T> extends MenuEntry<T> {
  /// Creates a [MenuDivider].
  const MenuDivider();
}

/// Per-component design tokens for [Menu].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(menu: MenuToken(...)))`, or per instance via
/// [Menu.token].
@immutable
class MenuToken {
  /// Creates a [MenuToken].
  const MenuToken({
    this.itemColor,
    this.itemHoverBg,
    this.itemSelectedColor,
    this.itemSelectedBg,
    this.itemDisabledColor,
    this.dangerItemColor,
    this.dangerItemSelectedBg,
    this.groupTitleColor,
    this.subMenuItemBg,
    this.itemHeight,
    this.itemBorderRadius,
    this.itemMarginInline,
    this.itemPaddingInline,
    this.inlineIndent,
    this.iconSize,
    this.iconGap,
    this.horizontalItemHeight,
    this.horizontalItemPaddingInline,
    this.horizontalBarHeight,
    this.collapsedWidth,
    this.fontSize,
    this.collapsedIconSize,
  });

  /// The words of an item at rest.
  final Color? itemColor;

  /// The wash behind an item under the pointer.
  final Color? itemHoverBg;

  /// The words of the selected item, and of the titles above it.
  final Color? itemSelectedColor;

  /// The wash behind the selected item.
  final Color? itemSelectedBg;

  /// The words of a disabled item.
  final Color? itemDisabledColor;

  /// The words of a `danger` item.
  final Color? dangerItemColor;

  /// The wash behind a selected `danger` item.
  final Color? dangerItemSelectedBg;

  /// A group heading's words.
  final Color? groupTitleColor;

  /// The wash behind an open inline submenu.
  final Color? subMenuItemBg;

  /// How tall an item in a column is.
  final double? itemHeight;

  /// The corners of an item's wash and focus ring.
  final double? itemBorderRadius;

  /// Space either side of an item in a column, outside its wash.
  final double? itemMarginInline;

  /// Space inside an item in a column, before its icon.
  final double? itemPaddingInline;

  /// How much further in each level of an inline submenu starts.
  final double? inlineIndent;

  /// The size of an item's icon.
  final double? iconSize;

  /// Space between an icon and the words after it.
  final double? iconGap;

  /// How tall a horizontal menu is.
  final double? horizontalItemHeight;

  /// Space either side of an item's words in a horizontal menu.
  final double? horizontalItemPaddingInline;

  /// How thick the bar under a horizontal menu's selected item is.
  final double? horizontalBarHeight;

  /// How wide a collapsed menu is.
  final double? collapsedWidth;

  /// The items' text size.
  final double? fontSize;

  /// The size of an icon in a collapsed menu, where it stands alone.
  final double? collapsedIconSize;

  _ResolvedMenuToken _resolve(Token t) => _ResolvedMenuToken(
        collapsedIconSize: collapsedIconSize ?? t.fontSizeLG,
        itemColor: itemColor ?? t.colorText,
        itemHoverBg: itemHoverBg ?? t.colorFillSecondary,
        itemSelectedColor: itemSelectedColor ?? t.primary.base,
        itemSelectedBg: itemSelectedBg ?? t.primary.bg,
        itemDisabledColor: itemDisabledColor ?? t.colorTextQuaternary,
        dangerItemColor: dangerItemColor ?? t.error.base,
        dangerItemSelectedBg: dangerItemSelectedBg ?? t.error.bg,
        groupTitleColor: groupTitleColor ?? t.colorTextTertiary,
        subMenuItemBg: subMenuItemBg ?? t.colorFillQuaternary,
        itemHeight: itemHeight ?? t.controlHeightLG,
        itemBorderRadius: itemBorderRadius ?? t.borderRadiusLG,
        itemMarginInline: itemMarginInline ?? t.sizeXXS,
        itemPaddingInline: itemPaddingInline ?? t.size,
        inlineIndent: inlineIndent ?? t.sizeLG,
        iconSize: iconSize ?? t.fontSize,
        iconGap: iconGap ?? t.sizeXS,
        horizontalItemHeight:
            horizontalItemHeight ?? t.controlHeightLG + t.sizeXS,
        horizontalItemPaddingInline: horizontalItemPaddingInline ?? t.sizeMD,
        horizontalBarHeight: horizontalBarHeight ?? t.lineWidth * 2,
        collapsedWidth: collapsedWidth ?? t.controlHeightLG * 2,
        fontSize: fontSize ?? t.fontSize,
      );

  /// This one with [other]'s fields laid over it, one field at a time.
  MenuToken merge(MenuToken other) => MenuToken(
        collapsedIconSize: other.collapsedIconSize ?? collapsedIconSize,
        itemColor: other.itemColor ?? itemColor,
        itemHoverBg: other.itemHoverBg ?? itemHoverBg,
        itemSelectedColor: other.itemSelectedColor ?? itemSelectedColor,
        itemSelectedBg: other.itemSelectedBg ?? itemSelectedBg,
        itemDisabledColor: other.itemDisabledColor ?? itemDisabledColor,
        dangerItemColor: other.dangerItemColor ?? dangerItemColor,
        dangerItemSelectedBg:
            other.dangerItemSelectedBg ?? dangerItemSelectedBg,
        groupTitleColor: other.groupTitleColor ?? groupTitleColor,
        subMenuItemBg: other.subMenuItemBg ?? subMenuItemBg,
        itemHeight: other.itemHeight ?? itemHeight,
        itemBorderRadius: other.itemBorderRadius ?? itemBorderRadius,
        itemMarginInline: other.itemMarginInline ?? itemMarginInline,
        itemPaddingInline: other.itemPaddingInline ?? itemPaddingInline,
        inlineIndent: other.inlineIndent ?? inlineIndent,
        iconSize: other.iconSize ?? iconSize,
        iconGap: other.iconGap ?? iconGap,
        horizontalItemHeight:
            other.horizontalItemHeight ?? horizontalItemHeight,
        horizontalItemPaddingInline:
            other.horizontalItemPaddingInline ?? horizontalItemPaddingInline,
        horizontalBarHeight: other.horizontalBarHeight ?? horizontalBarHeight,
        collapsedWidth: other.collapsedWidth ?? collapsedWidth,
        fontSize: other.fontSize ?? fontSize,
      );
}

@immutable
class _ResolvedMenuToken {
  const _ResolvedMenuToken({
    required this.itemColor,
    required this.itemHoverBg,
    required this.itemSelectedColor,
    required this.itemSelectedBg,
    required this.itemDisabledColor,
    required this.dangerItemColor,
    required this.dangerItemSelectedBg,
    required this.groupTitleColor,
    required this.subMenuItemBg,
    required this.itemHeight,
    required this.itemBorderRadius,
    required this.itemMarginInline,
    required this.itemPaddingInline,
    required this.inlineIndent,
    required this.iconSize,
    required this.iconGap,
    required this.horizontalItemHeight,
    required this.horizontalItemPaddingInline,
    required this.horizontalBarHeight,
    required this.collapsedWidth,
    required this.fontSize,
    required this.collapsedIconSize,
  });

  final Color itemColor;
  final Color itemHoverBg;
  final Color itemSelectedColor;
  final Color itemSelectedBg;
  final Color itemDisabledColor;
  final Color dangerItemColor;
  final Color dangerItemSelectedBg;
  final Color groupTitleColor;
  final Color subMenuItemBg;
  final double itemHeight;
  final double itemBorderRadius;
  final double itemMarginInline;
  final double itemPaddingInline;
  final double inlineIndent;
  final double iconSize;
  final double iconGap;
  final double horizontalItemHeight;
  final double horizontalItemPaddingInline;
  final double horizontalBarHeight;
  final double collapsedWidth;
  final double fontSize;
  final double collapsedIconSize;
}

/// Defaults for every [Menu] under a `ConfigProvider`.
@immutable
class MenuDefaults {
  /// Creates a [MenuDefaults].
  const MenuDefaults({this.mode, this.accordion});

  /// How menus lay themselves out.
  final MenuMode? mode;

  /// Whether opening an inline submenu shuts the others at its level.
  final bool? accordion;

  /// This one with [other]'s fields laid over it, one field at a time.
  MenuDefaults merge(MenuDefaults other) => MenuDefaults(
        mode: other.mode ?? mode,
        accordion: other.accordion ?? accordion,
      );
}

/// A list of places to go: a sidebar, a top bar, the sections of a settings
/// page.
///
/// ```dart
/// Menu<String>(
///   selectedValue: route,
///   onSelect: (route) => router.go(route),
///   items: const [
///     MenuItem(value: '/mail', label: 'Mail', icon: Icon(Icons.mail)),
///     MenuItem(
///       value: 'settings',
///       label: 'Settings',
///       icon: Icon(Icons.settings),
///       children: [
///         MenuItem(value: '/profile', label: 'Profile'),
///         MenuItem(value: '/security', label: 'Security'),
///       ],
///     ),
///   ],
/// )
/// ```
///
/// One item is selected at a time, and the titles of the submenus it sits in
/// are drawn as selected too, so a reader can see the way down to it.
class Menu<T> extends StatefulWidget {
  /// Creates a [Menu].
  const Menu({
    super.key,
    required this.items,
    this.mode,
    this.selectedValue,
    this.onSelect,
    this.openValues,
    this.defaultOpenValues,
    this.onOpenChanged,
    this.accordion,
    this.inlineCollapsed = false,
    this.token,
  });

  /// The entries, top to bottom or start to end.
  final List<MenuEntry<T>> items;

  /// How the menu lays itself out. Defaults to [MenuMode.inline].
  final MenuMode? mode;

  /// The selected item. A tap selects an item on its own; naming one here
  /// moves the selection whenever this changes, as when the route moves.
  final T? selectedValue;

  /// Called with an item's value when it is chosen.
  final ValueChanged<T>? onSelect;

  /// The inline submenus that are open, by their titles' values. Null lets
  /// the menu keep its own, starting from [defaultOpenValues].
  final Set<T>? openValues;

  /// The inline submenus open at first, when [openValues] is null.
  final Set<T>? defaultOpenValues;

  /// Called with the inline submenus that are open whenever a title opens or
  /// shuts one.
  final ValueChanged<Set<T>>? onOpenChanged;

  /// Whether opening an inline submenu shuts the others at its level.
  /// Defaults to no.
  final bool? accordion;

  /// Whether an inline menu is folded to its icons, its words shown in a
  /// tooltip and its submenus floating out beside it.
  final bool inlineCollapsed;

  /// Per-instance token overrides.
  final MenuToken? token;

  @override
  State<Menu<T>> createState() => _MenuState<T>();
}

class _MenuState<T> extends State<Menu<T>> {
  late T? _selected = widget.selectedValue;
  late Set<T> _open = {...?widget.defaultOpenValues};

  /// How many of a horizontal menu's items fit before the rest fold into
  /// the `…`; null until the row has been laid out, and while all fit.
  int? _fits;

  void _onFits(int? fits) {
    if (fits != _fits && mounted) setState(() => _fits = fits);
  }

  Set<T> get _openNow => widget.openValues ?? _open;

  @override
  void didUpdateWidget(Menu<T> old) {
    super.didUpdateWidget(old);
    if (widget.selectedValue != old.selectedValue) {
      _selected = widget.selectedValue;
    }
  }

  MenuMode get _mode =>
      widget.mode ??
      ConfigProvider.defaultsOf<MenuDefaults>(context)?.mode ??
      MenuMode.inline;

  bool get _accordion =>
      widget.accordion ??
      ConfigProvider.defaultsOf<MenuDefaults>(context)?.accordion ??
      false;

  void _choose(MenuItem<T> item) {
    item.onTap?.call();
    final value = item.value;
    if (value == null) return;
    setState(() => _selected = value);
    widget.onSelect?.call(value);
  }

  void _chooseValue(T? value, List<MenuEntry<T>> within) {
    final item = _find(within, value);
    if (item != null) {
      _choose(item);
    } else if (value != null) {
      setState(() => _selected = value);
      widget.onSelect?.call(value);
    }
  }

  void _toggle(MenuItem<T> title, List<MenuEntry<T>> siblings) {
    final key = title.value;
    if (key == null) return;
    final next = {..._openNow};
    if (next.contains(key)) {
      next.remove(key);
    } else {
      if (_accordion) {
        for (final s in siblings) {
          if (s is MenuItem<T> && s.children != null) next.remove(s.value);
        }
      }
      next.add(key);
    }
    if (widget.openValues == null) setState(() => _open = next);
    widget.onOpenChanged?.call(next);
  }

  /// The item named [value] anywhere under [entries].
  MenuItem<T>? _find(List<MenuEntry<T>> entries, T? value) {
    for (final e in entries) {
      if (e is MenuItem<T>) {
        if (e.value == value && e.children == null) return e;
        final inner = e.children == null ? null : _find(e.children!, value);
        if (inner != null) return inner;
      } else if (e is MenuGroup<T>) {
        final inner = _find(e.children, value);
        if (inner != null) return inner;
      }
    }
    return null;
  }

  /// Whether [entries] hold the selected item, however deep.
  bool _holdsSelected(List<MenuEntry<T>> entries) =>
      _selected != null && _find(entries, _selected) != null;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<MenuToken>(context) ??
            const MenuToken())
        ._resolve(t);
    final mode = _mode;
    final horizontal = mode == MenuMode.horizontal;
    final collapsed = mode == MenuMode.inline && widget.inlineCollapsed;
    final ltr = Directionality.maybeOf(context) != TextDirection.rtl;

    final ctx = _Ctx<T>(
      state: this,
      token: r,
      mode: mode,
      collapsed: collapsed,
    );

    Widget body;
    if (horizontal) {
      // A bar has no room for headings or rules: a group's items stand in the
      // row with the rest. A row wider than the bar scrolls rather than
      // spilling over its end.
      final all = _flat(widget.items).toList();
      final fits = _fits;
      final hidden = fits == null || fits >= all.length
          ? <MenuItem<T>>[]
          : all.sublist(fits);
      body = SizedBox(
        height: r.horizontalItemHeight,
        child: _FoldingRow(
          onFits: _onFits,
          children: [
            for (var i = 0; i < all.length; i++)
              // A folded item stays in the tree, to be measured again when
              // the bar widens, and out of reach of the keys while it hides.
              ExcludeFocus(
                excluding: fits != null && i >= fits,
                child: _HorizontalItem<T>(ctx: ctx, item: all[i]),
              ),
            ExcludeFocus(
              excluding: hidden.isEmpty,
              child: _HorizontalItem<T>(
                ctx: ctx,
                semanticsLabel: context.seedLocale.showMore,
                item: MenuItem<T>(label: '…', children: hidden),
              ),
            ),
          ],
        ),
      );
    } else {
      // Rows keep half their gap above and below them, so the first and the
      // last would stand closer to the menu's edge than to its sides. The
      // rest of the gap goes round the column, and every edge is as far from
      // the rows as the sides are.
      body = Padding(
        padding: EdgeInsets.symmetric(
          vertical: math.max(0, r.itemMarginInline - t.sizeXXS / 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: _column(ctx, widget.items, 0),
        ),
      );
      if (collapsed) body = SizedBox(width: r.collapsedWidth, child: body);
    }

    final next = horizontal
        ? (ltr ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft)
        : LogicalKeyboardKey.arrowDown;
    final previous = horizontal
        ? (ltr ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight)
        : LogicalKeyboardKey.arrowUp;

    return DefaultTextStyle.merge(
      style: TextStyle(
        fontSize: r.fontSize,
        fontFamily: t.fontFamily,
        fontFamilyFallback: t.fontFamilyFallback,
        decoration: TextDecoration.none,
      ),
      child: Shortcuts(
        shortcuts: {
          SingleActivator(next): const NextFocusIntent(),
          SingleActivator(previous): const PreviousFocusIntent(),
        },
        child: FocusTraversalGroup(child: body),
      ),
    );
  }

  /// The items of [entries], a group's in its place, dividers left out.
  Iterable<MenuItem<T>> _flat(List<MenuEntry<T>> entries) sync* {
    for (final e in entries) {
      if (e is MenuItem<T>) yield e;
      if (e is MenuGroup<T>) yield* _flat(e.children);
    }
  }

  List<Widget> _column(_Ctx<T> ctx, List<MenuEntry<T>> entries, int level) {
    final r = ctx.token;
    final t = context.softToken;
    return [
      for (final e in entries)
        if (e is MenuDivider<T>)
          Padding(
            padding: EdgeInsets.symmetric(vertical: t.sizeXXS),
            child: SizedBox(
              height: t.lineWidth,
              child: ColoredBox(color: t.colorSplit),
            ),
          )
        else if (e is MenuGroup<T>) ...[
          if (!ctx.collapsed)
            Semantics(
              header: true,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  r.itemMarginInline +
                      r.itemPaddingInline +
                      level * r.inlineIndent,
                  t.sizeXS,
                  r.itemMarginInline,
                  t.sizeXS,
                ),
                child: Text(
                  e.label,
                  style: TextStyle(color: r.groupTitleColor),
                ),
              ),
            ),
          ..._column(ctx, e.children, level),
        ] else if (e is MenuItem<T>)
          if (e.children != null &&
              ctx.mode == MenuMode.inline &&
              !ctx.collapsed)
            _InlineSubmenu<T>(
              ctx: ctx,
              item: e,
              level: level,
              siblings: entries,
            )
          else
            _ColumnItem<T>(ctx: ctx, item: e, level: level),
    ];
  }
}

/// What every row of one menu shares.
@immutable
class _Ctx<T> {
  const _Ctx({
    required this.state,
    required this.token,
    required this.mode,
    required this.collapsed,
  });

  final _MenuState<T> state;
  final _ResolvedMenuToken token;
  final MenuMode mode;
  final bool collapsed;
}

/// The entries of a floating submenu, as the dropdown it floats in takes
/// them, the selected item and the titles above it marked.
List<DropdownEntry<T>> _asDropdown<T>(
  _MenuState<T> state,
  List<MenuEntry<T>> entries,
) =>
    [
      for (final e in entries)
        if (e is MenuItem<T>)
          DropdownItem<T>(
            value: e.value,
            label: e.label,
            icon: e.icon,
            disabled: e.disabled,
            danger: e.danger,
            selected: e.children == null
                ? e.value != null && e.value == state._selected
                : state._holdsSelected(e.children!),
            children:
                e.children == null ? null : _asDropdown(state, e.children!),
          )
        else if (e is MenuGroup<T>)
          DropdownGroup<T>(
            label: e.label,
            children: _asDropdown(state, e.children),
          )
        else
          DropdownDivider<T>(),
    ];

/// A row that can be hovered, focused and pressed, drawing its own wash.
class _Row extends StatefulWidget {
  const _Row({
    required this.token,
    required this.enabled,
    required this.onTap,
    required this.builder,
    this.semanticsLabel,
    this.selected,
    this.expanded,
    this.onKey,
  });

  final _ResolvedMenuToken token;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget Function(bool hovered, bool focused) builder;
  final String? semanticsLabel;
  final bool? selected;
  final bool? expanded;
  final KeyEventResult Function(KeyEvent event)? onKey;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final onKey = widget.onKey;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      selected: widget.selected,
      expanded: widget.expanded,
      label: widget.semanticsLabel,
      onTap: widget.enabled ? widget.onTap : null,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: onKey == null ? null : (_, event) => onKey(event),
        child: FocusableActionDetector(
          enabled: widget.enabled,
          mouseCursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap?.call();
                return null;
              },
            ),
          },
          // The detector's own hover highlight waits for the keyboard's mode
          // of highlighting; a pointer over a row should light it whatever
          // the last key was.
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              excludeFromSemantics: true,
              behavior: HitTestBehavior.opaque,
              onTap: widget.enabled ? widget.onTap : null,
              // A row named for a reader in other words than it shows — an
              // icon alone, the `…` — keeps what it shows to the eye.
              child: widget.semanticsLabel == null
                  ? widget.builder(_hovered && widget.enabled, _focused)
                  : ExcludeSemantics(
                      child: widget.builder(
                        _hovered && widget.enabled,
                        _focused,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The focus ring every row wears while the keyboard is on it.
List<BoxShadow>? _ring(Token t, bool focused) => focused
    ? [
        BoxShadow(
          color: t.primary.base.withValues(alpha: 0.12),
          blurRadius: 0,
          spreadRadius: t.focusRingWidth,
        ),
      ]
    : null;

/// The icon, the words and the end of a row in a column.
Widget _rowContent<T>({
  required BuildContext context,
  required _ResolvedMenuToken r,
  required MenuItem<T> item,
  required Color color,
  required bool collapsed,
  Widget? trailing,
}) {
  final icon = item.icon == null
      ? null
      : IconTheme.merge(
          data: IconThemeData(
            color: color,
            size: collapsed ? r.collapsedIconSize : r.iconSize,
          ),
          child: item.icon!,
        );
  if (collapsed) {
    return Center(child: icon ?? Text(item.label?.characters.first ?? ''));
  }
  return Row(
    children: [
      if (icon != null) ...[icon, SizedBox(width: r.iconGap)],
      Expanded(
        child: Text(
          item.label ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color),
        ),
      ),
      if (item.extra != null) item.extra!,
      if (trailing != null) ...[SizedBox(width: r.iconGap), trailing],
    ],
  );
}

/// An item in a column: a place, or the title of a submenu that floats out.
class _ColumnItem<T> extends StatelessWidget {
  const _ColumnItem({
    required this.ctx,
    required this.item,
    required this.level,
  });

  final _Ctx<T> ctx;
  final MenuItem<T> item;
  final int level;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = ctx.token;
    final state = ctx.state;
    final submenu = item.children != null;
    final selected = submenu
        ? state._holdsSelected(item.children!)
        : (item.value != null && item.value == state._selected);
    final color = item.disabled
        ? r.itemDisabledColor
        : item.danger
            ? r.dangerItemColor
            : (selected ? r.itemSelectedColor : r.itemColor);

    Widget row(bool hovered, bool focused) => Container(
          height: r.itemHeight,
          margin: EdgeInsets.symmetric(
            horizontal: r.itemMarginInline,
            vertical: t.sizeXXS / 2,
          ),
          padding: ctx.collapsed
              ? null
              : EdgeInsetsDirectional.only(
                  start: r.itemPaddingInline + level * r.inlineIndent,
                  end: r.itemPaddingInline,
                ),
          decoration: BoxDecoration(
            color: selected && !submenu
                ? (item.danger ? r.dangerItemSelectedBg : r.itemSelectedBg)
                : (hovered ? r.itemHoverBg : null),
            borderRadius: BorderRadius.circular(r.itemBorderRadius),
            boxShadow: _ring(t, focused),
          ),
          child: _rowContent(
            context: context,
            r: r,
            item: item,
            color: color,
            collapsed: ctx.collapsed,
            trailing: submenu && !ctx.collapsed
                ? CustomPaint(
                    size: Size.square(t.fontSizeSM),
                    painter: ChevronPainter(color),
                  )
                : null,
          ),
        );

    if (!submenu) {
      final Widget leaf = _Row(
        token: r,
        enabled: !item.disabled,
        selected: selected,
        semanticsLabel: ctx.collapsed ? item.label : null,
        onTap: () => state._choose(item),
        builder: row,
      );
      if (!ctx.collapsed || item.label == null) return leaf;
      return Tooltip(
        placement: PopoverPlacement.right,
        message: Text(item.label!),
        child: leaf,
      );
    }

    return _Floating<T>(
      ctx: ctx,
      item: item,
      placement: PopoverPlacement.rightTop,
      builder: (open) => _Row(
        token: r,
        enabled: !item.disabled,
        selected: selected,
        expanded: false,
        semanticsLabel: ctx.collapsed ? item.label : null,
        onTap: open,
        builder: row,
      ),
    );
  }
}

/// A submenu that floats out of its title, in a dropdown.
class _Floating<T> extends StatefulWidget {
  const _Floating({
    required this.ctx,
    required this.item,
    required this.placement,
    required this.builder,
  });

  final _Ctx<T> ctx;
  final MenuItem<T> item;
  final PopoverPlacement placement;
  final Widget Function(VoidCallback open) builder;

  @override
  State<_Floating<T>> createState() => _FloatingState<T>();
}

class _FloatingState<T> extends State<_Floating<T>> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Dropdown<T>(
      menu: _asDropdown(widget.ctx.state, widget.item.children!),
      placement: widget.placement,
      // A pointer opens it by resting on the title; a tap or a key by
      // pressing it.
      trigger: const [DropdownTrigger.hover],
      open: _open,
      onOpenChanged: (open) => setState(() => _open = open),
      disabled: widget.item.disabled,
      onItemTap: (value) {
        setState(() => _open = false);
        widget.ctx.state._chooseValue(value, widget.item.children!);
      },
      child: widget.builder(() => setState(() => _open = !_open)),
    );
  }
}

/// A submenu that opens in place, under its title.
class _InlineSubmenu<T> extends StatelessWidget {
  const _InlineSubmenu({
    required this.ctx,
    required this.item,
    required this.level,
    required this.siblings,
  });

  final _Ctx<T> ctx;
  final MenuItem<T> item;
  final int level;
  final List<MenuEntry<T>> siblings;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = ctx.token;
    final state = ctx.state;
    final open = item.value != null && state._openNow.contains(item.value);
    final selected = state._holdsSelected(item.children!);
    final color = item.disabled
        ? r.itemDisabledColor
        : item.danger
            ? r.dangerItemColor
            : (selected ? r.itemSelectedColor : r.itemColor);
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = still ? Duration.zero : t.motionDurationMid;
    final ltr = Directionality.maybeOf(context) != TextDirection.rtl;

    final title = _Row(
      token: r,
      enabled: !item.disabled,
      expanded: open,
      onTap: () => state._toggle(item, siblings),
      onKey: (event) {
        if (event is KeyUpEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        final inward =
            ltr ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;
        final outward =
            ltr ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
        if ((key == inward && !open) || (key == outward && open)) {
          state._toggle(item, siblings);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      builder: (hovered, focused) => Container(
        height: r.itemHeight,
        margin: EdgeInsets.symmetric(
          horizontal: r.itemMarginInline,
          vertical: t.sizeXXS / 2,
        ),
        padding: EdgeInsetsDirectional.only(
          start: r.itemPaddingInline + level * r.inlineIndent,
          end: r.itemPaddingInline,
        ),
        decoration: BoxDecoration(
          color: hovered ? r.itemHoverBg : null,
          borderRadius: BorderRadius.circular(r.itemBorderRadius),
          boxShadow: _ring(t, focused),
        ),
        child: _rowContent(
          context: context,
          r: r,
          item: item,
          color: color,
          collapsed: false,
          trailing: AnimatedRotation(
            // Down while shut, up while open.
            turns: open ? -0.25 : 0.25,
            duration: duration,
            child: CustomPaint(
              size: Size.square(t.fontSizeSM),
              painter: ChevronPainter(color),
            ),
          ),
        ),
      ),
    );

    final children = ExcludeFocus(
      excluding: !open,
      child: ExcludeSemantics(
        excluding: !open,
        child: ColoredBox(
          color: r.subMenuItemBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: state._column(ctx, item.children!, level + 1),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        title,
        TweenAnimationBuilder<double>(
          tween: Tween(end: open ? 1 : 0),
          duration: duration,
          curve: Curves.easeInOut,
          child: children,
          builder: (context, shown, child) => shown == 0
              ? const SizedBox(width: double.infinity)
              : ClipRect(
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    heightFactor: shown,
                    child: child,
                  ),
                ),
        ),
      ],
    );
  }
}

/// An item in a horizontal menu: a place, or a title its submenu drops from.
class _HorizontalItem<T> extends StatelessWidget {
  const _HorizontalItem({
    required this.ctx,
    required this.item,
    this.semanticsLabel,
  });

  final _Ctx<T> ctx;
  final MenuItem<T> item;

  /// What a screen reader calls the item, in place of its words: the `…`.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = ctx.token;
    final state = ctx.state;
    final submenu = item.children != null;
    final selected = submenu
        ? state._holdsSelected(item.children!)
        : (item.value != null && item.value == state._selected);

    Widget row(bool hovered, bool focused) {
      final lit = selected || hovered;
      final color = item.disabled
          ? r.itemDisabledColor
          : item.danger
              ? r.dangerItemColor
              : (lit ? r.itemSelectedColor : r.itemColor);
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: r.horizontalItemPaddingInline,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r.itemBorderRadius),
          boxShadow: _ring(t, focused),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(color: color, size: r.iconSize),
                    child: item.icon!,
                  ),
                  SizedBox(width: r.iconGap),
                ],
                Text(item.label ?? '', style: TextStyle(color: color)),
                if (item.extra != null) ...[
                  SizedBox(width: r.iconGap),
                  item.extra!,
                ],
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                opacity: lit && !item.disabled ? 1 : 0,
                duration: t.motionDurationMid,
                child: Container(
                  height: r.horizontalBarHeight,
                  color: item.danger ? r.dangerItemColor : r.itemSelectedColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!submenu) {
      return _Row(
        token: r,
        enabled: !item.disabled,
        selected: selected,
        semanticsLabel: semanticsLabel,
        onTap: () => state._choose(item),
        builder: row,
      );
    }
    return _Floating<T>(
      ctx: ctx,
      item: item,
      placement: PopoverPlacement.bottomLeft,
      builder: (open) => _Row(
        token: r,
        enabled: !item.disabled,
        selected: selected,
        expanded: false,
        semanticsLabel: semanticsLabel,
        onTap: open,
        builder: row,
      ),
    );
  }
}

/// A row that shows the children that fit and folds the rest.
///
/// The last child is the `…` that stands for the folded ones; it is shown
/// only when something is folded, and room is kept for it then. Every child
/// is laid out each time, folded or not, so a bar that widens again knows
/// at once what fits.
class _FoldingRow extends MultiChildRenderObjectWidget {
  const _FoldingRow({required this.onFits, required super.children});

  /// Told how many children before the `…` fit, or null when all do.
  final ValueChanged<int?> onFits;

  @override
  _RenderFoldingRow createRenderObject(BuildContext context) =>
      _RenderFoldingRow(
        onFits: onFits,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(BuildContext context, _RenderFoldingRow row) {
    row
      ..onFits = onFits
      ..textDirection = Directionality.of(context);
  }
}

class _FoldingParentData extends ContainerBoxParentData<RenderBox> {
  bool shown = true;
}

class _RenderFoldingRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FoldingParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FoldingParentData> {
  _RenderFoldingRow({
    required this.onFits,
    required TextDirection textDirection,
  }) : _textDirection = textDirection;

  ValueChanged<int?> onFits;
  int? _reported = -1;

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FoldingParentData) {
      child.parentData = _FoldingParentData();
    }
  }

  @override
  void performLayout() {
    final height = constraints.maxHeight;
    final children = getChildrenAsList();
    for (final child in children) {
      child.layout(
        BoxConstraints.tightFor(height: height),
        parentUsesSize: true,
      );
    }
    final items = children.sublist(0, children.length - 1);
    final more = children.last;
    final total = items.fold<double>(0, (sum, c) => sum + c.size.width);
    final room = constraints.maxWidth;

    int? fits;
    if (total > room) {
      var used = more.size.width;
      var count = 0;
      for (final item in items) {
        if (used + item.size.width > room) break;
        used += item.size.width;
        count++;
      }
      fits = count;
    }

    final rtl = textDirection == TextDirection.rtl;
    final width = fits == null ? total : room;
    var x = 0.0;
    void place(RenderBox child, bool shown) {
      final data = child.parentData! as _FoldingParentData;
      data.shown = shown;
      if (!shown) return;
      data.offset = Offset(rtl ? width - x - child.size.width : x, 0);
      x += child.size.width;
    }

    for (var i = 0; i < items.length; i++) {
      place(items[i], fits == null || i < fits);
    }
    place(more, fits != null);
    size = constraints.constrain(Size(width, height));

    if (fits != _reported) {
      _reported = fits;
      // Told after the frame: the menu rebuilds the `…` around what folded,
      // and a build may not start inside a layout.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (attached) onFits(fits);
      });
    }
  }

  // Asked how wide it would like to be, the row answers for every item side
  // by side; asked how narrow it can go, for the `…` alone.
  @override
  double computeMaxIntrinsicWidth(double height) {
    final children = getChildrenAsList();
    return children
        .take(children.length - 1)
        .fold(0.0, (sum, c) => sum + c.getMaxIntrinsicWidth(height));
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      lastChild?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) => getChildrenAsList()
      .fold(0.0, (most, c) => math.max(most, c.getMinIntrinsicHeight(width)));

  @override
  double computeMaxIntrinsicHeight(double width) => getChildrenAsList()
      .fold(0.0, (most, c) => math.max(most, c.getMaxIntrinsicHeight(width)));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final height = constraints.maxHeight;
    final children = getChildrenAsList();
    final total = children.take(children.length - 1).fold<double>(
          0,
          (sum, c) =>
              sum +
              c.getDryLayout(BoxConstraints.tightFor(height: height)).width,
        );
    return constraints.constrain(
      Size(math.min(total, constraints.maxWidth), height),
    );
  }

  bool _shown(RenderBox child) =>
      (child.parentData! as _FoldingParentData).shown;

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in getChildrenAsList()) {
      if (!_shown(child)) continue;
      final data = child.parentData! as _FoldingParentData;
      context.paintChild(child, data.offset + offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in getChildrenAsList().reversed) {
      if (!_shown(child)) continue;
      final data = child.parentData! as _FoldingParentData;
      final hit = result.addWithPaintOffset(
        offset: data.offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    for (final child in getChildrenAsList()) {
      if (_shown(child)) visitor(child);
    }
  }
}
