import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/popover.dart' show PopoverPlacement;
import 'dropdown.dart';

/// Per-component design tokens for [Breadcrumb].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(breadcrumb: BreadcrumbToken(...)))`, or per instance via
/// [Breadcrumb.token].
@immutable
class BreadcrumbToken {
  /// Creates a [BreadcrumbToken].
  const BreadcrumbToken({
    this.itemColor,
    this.lastItemColor,
    this.linkHoverColor,
    this.linkHoverBg,
    this.separatorColor,
    this.separatorMargin,
    this.fontSize,
    this.iconFontSize,
    this.itemPaddingInline,
    this.borderRadius,
  });

  /// The words of every crumb but the last.
  final Color? itemColor;

  /// The words of the last crumb: the page the reader is on.
  final Color? lastItemColor;

  /// The words of a crumb under the pointer.
  final Color? linkHoverColor;

  /// The wash behind a crumb under the pointer.
  final Color? linkHoverBg;

  /// The separator's colour.
  final Color? separatorColor;

  /// Space either side of a separator.
  final double? separatorMargin;

  /// The crumbs' text size.
  final double? fontSize;

  /// The size of a crumb's icon.
  final double? iconFontSize;

  /// Space inside a crumb, either side of its words, that the hover wash and
  /// the focus ring cover.
  final double? itemPaddingInline;

  /// The corners of the hover wash and the focus ring.
  final double? borderRadius;

  _ResolvedBreadcrumbToken _resolve(Token t) => _ResolvedBreadcrumbToken(
        itemColor: itemColor ?? t.colorTextTertiary,
        lastItemColor: lastItemColor ?? t.colorText,
        linkHoverColor: linkHoverColor ?? t.colorText,
        linkHoverBg: linkHoverBg ?? t.colorFillSecondary,
        separatorColor: separatorColor ?? t.colorTextTertiary,
        separatorMargin: separatorMargin ?? t.sizeXS,
        fontSize: fontSize ?? t.fontSize,
        iconFontSize: iconFontSize ?? t.fontSize,
        itemPaddingInline: itemPaddingInline ?? t.sizeXXS,
        borderRadius: borderRadius ?? t.borderRadiusSM,
      );

  /// This one with [other]'s fields laid over it, one field at a time.
  BreadcrumbToken merge(BreadcrumbToken other) => BreadcrumbToken(
        itemColor: other.itemColor ?? itemColor,
        lastItemColor: other.lastItemColor ?? lastItemColor,
        linkHoverColor: other.linkHoverColor ?? linkHoverColor,
        linkHoverBg: other.linkHoverBg ?? linkHoverBg,
        separatorColor: other.separatorColor ?? separatorColor,
        separatorMargin: other.separatorMargin ?? separatorMargin,
        fontSize: other.fontSize ?? fontSize,
        iconFontSize: other.iconFontSize ?? iconFontSize,
        itemPaddingInline: other.itemPaddingInline ?? itemPaddingInline,
        borderRadius: other.borderRadius ?? borderRadius,
      );
}

@immutable
class _ResolvedBreadcrumbToken {
  const _ResolvedBreadcrumbToken({
    required this.itemColor,
    required this.lastItemColor,
    required this.linkHoverColor,
    required this.linkHoverBg,
    required this.separatorColor,
    required this.separatorMargin,
    required this.fontSize,
    required this.iconFontSize,
    required this.itemPaddingInline,
    required this.borderRadius,
  });

  final Color itemColor;
  final Color lastItemColor;
  final Color linkHoverColor;
  final Color linkHoverBg;
  final Color separatorColor;
  final double separatorMargin;
  final double fontSize;
  final double iconFontSize;
  final double itemPaddingInline;
  final double borderRadius;
}

/// One step of a [Breadcrumb]'s path.
///
/// Like a [DropdownItem], a crumb is data: its words are a `String`, so they
/// can be searched, folded into the `…` menu and read out, and [T] tells one
/// crumb from another — a route, an id, an enum.
@immutable
class BreadcrumbItem<T> {
  /// Creates a [BreadcrumbItem].
  const BreadcrumbItem({
    this.value,
    this.label,
    this.icon,
    this.semanticsLabel,
    this.onTap,
    this.menu,
  });

  /// What this crumb reports through [Breadcrumb.onItemTap].
  final T? value;

  /// The crumb's words.
  final String? label;

  /// An icon before the words, or in their place.
  final Widget? icon;

  /// What a screen reader calls the crumb, in place of its [label]. A crumb
  /// that is an [icon] alone needs one: a house is "Home" only to the eye.
  final String? semanticsLabel;

  /// Called when the crumb is tapped, beside [Breadcrumb.onItemTap]. Ignored
  /// on a crumb with a [menu]: a tap there opens the menu.
  final VoidCallback? onTap;

  /// Places beside this one, offered in a menu under the crumb: the other
  /// projects, the other folders at this level. A menu item's value is
  /// reported through [Breadcrumb.onItemTap].
  final List<DropdownEntry<T>>? menu;
}

/// Where the reader is, as the path that led there: `Home / Projects / Seed`.
///
/// Every crumb but the last is a link back up the path; the last is the page
/// itself, and is not.
///
/// ```dart
/// Breadcrumb<String>(
///   items: const [
///     BreadcrumbItem(value: '/', label: 'Home'),
///     BreadcrumbItem(value: '/projects', label: 'Projects'),
///     BreadcrumbItem(label: 'Seed'),
///   ],
///   onItemTap: (route) => router.go(route!),
/// )
/// ```
///
/// A long path wraps onto further lines; [maxItems] folds the middle of it
/// into a `…` that opens a menu of what it hides.
class Breadcrumb<T> extends StatelessWidget {
  /// Creates a [Breadcrumb].
  const Breadcrumb({
    super.key,
    required this.items,
    this.onItemTap,
    this.separator,
    this.maxItems,
    this.token,
  });

  /// The path, from its root to the page the reader is on.
  final List<BreadcrumbItem<T>> items;

  /// Called with a crumb's [BreadcrumbItem.value] when it is tapped, and with
  /// a menu item's value when one is chosen.
  final ValueChanged<T?>? onItemTap;

  /// What stands between two crumbs. Null is a `/`.
  final Widget? separator;

  /// How many crumbs to show before the middle of the path folds into a `…`.
  /// The first crumb and the last `maxItems - 2` stay; null shows them all.
  /// Taken as at least 3: a root, a `…` and the page.
  final int? maxItems;

  /// Per-instance token overrides.
  final BreadcrumbToken? token;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (token ??
            ConfigProvider.componentOf<BreadcrumbToken>(context) ??
            const BreadcrumbToken())
        ._resolve(t);

    final limit = maxItems == null ? null : (maxItems! < 3 ? 3 : maxItems!);
    final fold = limit != null && items.length > limit;
    final hidden = fold ? items.sublist(1, items.length - (limit - 2)) : null;

    final crumbs = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (hidden != null && i >= 1 && i <= hidden.length) {
        if (i == 1) crumbs.add(_folded(context, hidden, r));
        continue;
      }
      final item = items[i];
      final last = i == items.length - 1;
      crumbs.add(
        _Crumb<T>(
          item: item,
          current: last,
          token: r,
          onTap: last && item.menu == null
              ? null
              : () {
                  item.onTap?.call();
                  onItemTap?.call(item.value);
                },
          onMenuItemTap: onItemTap,
          semanticsLabel: item.semanticsLabel,
        ),
      );
    }

    final sep = Padding(
      padding: EdgeInsets.symmetric(horizontal: r.separatorMargin),
      child: ExcludeSemantics(
        child: separator ?? const Text('/'),
      ),
    );

    return DefaultTextStyle.merge(
      style: TextStyle(
        color: r.separatorColor,
        fontSize: r.fontSize,
        fontFamily: t.fontFamily,
        fontFamilyFallback: t.fontFamilyFallback,
        decoration: TextDecoration.none,
      ),
      child: IconTheme.merge(
        data: IconThemeData(size: r.iconFontSize, color: r.separatorColor),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < crumbs.length; i++) ...[
              if (i > 0) sep,
              crumbs[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _folded(
    BuildContext context,
    List<BreadcrumbItem<T>> hidden,
    _ResolvedBreadcrumbToken r,
  ) =>
      _Crumb<T>(
        item: BreadcrumbItem<T>(
          label: '…',
          menu: [
            for (final item in hidden)
              DropdownItem<T>(
                value: item.value,
                label: item.label ?? item.semanticsLabel,
                icon: item.icon,
                onTap: item.onTap,
              ),
          ],
        ),
        current: false,
        token: r,
        semanticsLabel: context.seedLocale.showMore,
        chevron: false,
        onTap: () {},
        onMenuItemTap: onItemTap,
      );
}

/// One crumb: a link, the page itself, or a link that opens a menu.
class _Crumb<T> extends StatefulWidget {
  const _Crumb({
    required this.item,
    required this.current,
    required this.token,
    required this.onTap,
    required this.onMenuItemTap,
    this.semanticsLabel,
    this.chevron = true,
  });

  final BreadcrumbItem<T> item;
  final bool current;
  final _ResolvedBreadcrumbToken token;

  /// Null for the page itself, which is not a link.
  final VoidCallback? onTap;
  final ValueChanged<T?>? onMenuItemTap;
  final String? semanticsLabel;

  /// Whether a crumb with a menu draws the chevron that says so.
  final bool chevron;

  @override
  State<_Crumb<T>> createState() => _CrumbState<T>();
}

class _CrumbState<T> extends State<_Crumb<T>> {
  bool _hovered = false;
  bool _focused = false;
  bool _open = false;

  bool get _hasMenu => widget.item.menu != null;

  void _activate() {
    if (_hasMenu) {
      setState(() => _open = !_open);
    } else {
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = widget.token;
    final item = widget.item;
    final link = widget.onTap != null;
    final lit = link && _hovered;
    final color = widget.current
        ? r.lastItemColor
        : (lit ? r.linkHoverColor : r.itemColor);

    final label = item.label;
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null)
          IconTheme.merge(
            data: IconThemeData(color: color, size: r.iconFontSize),
            child: item.icon!,
          ),
        if (item.icon != null && label != null) SizedBox(width: t.sizeXXS),
        if (label != null) Text(label, style: TextStyle(color: color)),
        if (_hasMenu && widget.chevron) ...[
          SizedBox(width: t.sizeXXS),
          RotatedBox(
            quarterTurns: 1,
            child: CustomPaint(
              size: Size.square(t.fontSizeSM),
              painter: ChevronPainter(color),
            ),
          ),
        ],
      ],
    );

    content = Container(
      padding: EdgeInsets.symmetric(horizontal: r.itemPaddingInline),
      decoration: BoxDecoration(
        color: lit ? r.linkHoverBg : null,
        borderRadius: BorderRadius.circular(r.borderRadius),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: t.primary.base.withValues(alpha: 0.12),
                  blurRadius: 0,
                  spreadRadius: t.focusRingWidth,
                ),
              ]
            : null,
      ),
      child: content,
    );

    if (!link) {
      // The page itself: words, and nothing to press.
      return Semantics(label: widget.semanticsLabel, child: content);
    }

    content = Semantics(
      link: !_hasMenu,
      button: _hasMenu,
      label: widget.semanticsLabel,
      excludeSemantics: widget.semanticsLabel != null,
      onTap: _activate,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        // The detector's own hover highlight waits for the keyboard's mode of
        // highlighting; a pointer over a link should light it whatever the
        // last key was.
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            excludeFromSemantics: true,
            behavior: HitTestBehavior.opaque,
            onTap: _activate,
            child: content,
          ),
        ),
      ),
    );

    if (!_hasMenu) return content;
    return Dropdown<T>(
      menu: item.menu,
      // Opened by the crumb itself, so a key opens it as well as a tap.
      trigger: const [],
      open: _open,
      onOpenChanged: (open) => setState(() => _open = open),
      placement: PopoverPlacement.bottomLeft,
      onItemTap: (value) {
        setState(() => _open = false);
        widget.onMenuItemTap?.call(value);
      },
      child: content,
    );
  }
}
