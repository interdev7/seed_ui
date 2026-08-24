import 'package:flutter/widgets.dart';

import '../../icons/icons.dart' show CrossPainter, PlusPainter;
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';

/// The visual style of a [Tabs] bar.
enum TabsType {
  /// Underlined tabs with a sliding ink bar (the default).
  line,

  /// Card-style tabs; the active one joins the content panel.
  card,

  /// [card] tabs plus a close button per tab and an add button.
  editableCard,
}

/// Which edge the tab bar sits on.
enum TabPosition {
  /// The bar sits above the panels.
  top,

  /// The bar sits below the panels.
  bottom,

  /// The bar runs down the left of the panels.
  left,

  /// The bar runs down the right of the panels.
  right
}

/// What an edit gesture on an [TabsType.editableCard] requested.
enum TabEditAction {
  /// A new tab was requested.
  add,

  /// An existing tab was closed.
  remove
}

/// Horizontal placement of a tab's content within its panel.
enum TabContentPosition {
  /// Labels are pinned to the start of the bar.
  left,

  /// Labels are centred in the bar.
  center,

  /// Labels are pinned to the end of the bar.
  right
}

/// Where the selected tab lands when the bar scrolls it into view.
enum TabScrollAlign {
  /// Align the selected tab to the start (top / leading edge) of the bar.
  top,

  /// Centre the selected tab within the bar's visible extent.
  center,
}

/// Extra content pinned to the ends of a [Tabs] bar.
/// Use [TabBarExtra.right] for the common single-side
/// case, or supply both [left] and [right].
///
/// ```dart
/// Tabs(tabBarExtraContent: TabBarExtra.right(Button(...)), items: items)
/// Tabs(tabBarExtraContent: TabBarExtra(left: a, right: b), items: items)
/// ```
@immutable
class TabBarExtra {
  /// Creates a [TabBarExtra].
  const TabBarExtra({this.left, this.right});

  /// Extra pinned to the far side the tabs grow toward (the end).
  const TabBarExtra.right(Widget widget)
      : left = null,
        right = widget;

  /// Extra pinned to the start of the bar.
  const TabBarExtra.left(Widget widget)
      : left = widget,
        right = null;

  /// Content at the start of the bar.
  final Widget? left;

  /// Content at the end of the bar.
  final Widget? right;
}

/// Per-component design tokens for [Tabs] — its own token table.
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(tabs: TabsToken(...)))`, or per instance via [Tabs.token].
@immutable
class TabsToken {
  /// Creates a [TabsToken].
  const TabsToken({
    this.inkBarColor,
    this.itemColor,
    this.itemHoverColor,
    this.itemActiveColor,
    this.itemSelectedColor,
    this.titleFontSize,
    this.titleFontSizeSM,
    this.titleFontSizeLG,
    this.cardBg,
    this.cardGutter,
    this.cardHeight,
    this.cardPadding,
    this.cardPaddingSM,
    this.cardPaddingLG,
    this.horizontalItemGutter,
    this.horizontalItemPadding,
    this.horizontalItemPaddingSM,
    this.horizontalItemPaddingLG,
    this.verticalItemPadding,
    this.verticalItemMargin,
  });

  /// Colour of the sliding indicator (`inkBarColor`).
  final Color? inkBarColor;

  /// Resting label colour (`itemColor`).
  final Color? itemColor;

  /// Hover label colour (`itemHoverColor`).
  final Color? itemHoverColor;

  /// Pressed label colour (`itemActiveColor`).
  final Color? itemActiveColor;

  /// Active tab label colour (`itemSelectedColor`).
  final Color? itemSelectedColor;

  /// Title font size — middle (`titleFontSize`), small and large.
  final double? titleFontSize;

  /// Title font size at the small size.
  final double? titleFontSizeSM;

  /// Title font size at the large size.
  final double? titleFontSizeLG;

  /// Card-tab background (`cardBg`).
  final Color? cardBg;

  /// Gap between card tabs (`cardGutter`).
  final double? cardGutter;

  /// Card-tab height (`cardHeight`).
  final double? cardHeight;

  /// Card-tab padding — middle (`cardPadding`), small and large.
  final EdgeInsets? cardPadding;

  /// Card-tab padding at the small size.
  final EdgeInsets? cardPaddingSM;

  /// Card-tab padding at the large size.
  final EdgeInsets? cardPaddingLG;

  /// Gap between horizontal line tabs (`horizontalItemGutter`).
  final double? horizontalItemGutter;

  /// Horizontal line-tab padding — middle, small and large.
  final EdgeInsets? horizontalItemPadding;

  /// Horizontal line-tab padding at the small size.
  final EdgeInsets? horizontalItemPaddingSM;

  /// Horizontal line-tab padding at the large size.
  final EdgeInsets? horizontalItemPaddingLG;

  /// Vertical tab padding (`verticalItemPadding`).
  final EdgeInsets? verticalItemPadding;

  /// Gap between vertical tabs (`verticalItemMargin`).
  final EdgeInsets? verticalItemMargin;

  /// Fills in every unset field from the global [t], producing the effective
  /// tokens the widget draws with.
  _ResolvedTabsToken _resolve(Token t) => _ResolvedTabsToken(
        inkBarColor: inkBarColor ?? t.primary.base,
        itemColor: itemColor ?? t.colorText,
        itemHoverColor: itemHoverColor ?? t.primary.hover,
        itemActiveColor: itemActiveColor ?? t.primary.active,
        itemSelectedColor: itemSelectedColor ?? t.primary.base,
        disabledColor: t.colorTextQuaternary,
        titleFontSize: titleFontSize ?? t.fontSize,
        titleFontSizeSM: titleFontSizeSM ?? t.fontSize,
        titleFontSizeLG: titleFontSizeLG ?? t.fontSizeLG,
        cardBg: cardBg ?? t.colorFillQuaternary,
        cardGutter: cardGutter ?? 2,
        cardHeight: cardHeight ?? t.controlHeightLG,
        // 8px 16px / 4px 8px / 11px 16px.
        cardPadding: cardPadding ??
            EdgeInsets.symmetric(horizontal: t.size, vertical: t.sizeXS),
        cardPaddingSM: cardPaddingSM ??
            EdgeInsets.symmetric(horizontal: t.sizeXS, vertical: t.sizeXXS),
        cardPaddingLG: cardPaddingLG ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        horizontalItemGutter: horizontalItemGutter ?? t.sizeXL,
        horizontalItemPadding:
            horizontalItemPadding ?? EdgeInsets.symmetric(vertical: t.sizeSM),
        horizontalItemPaddingSM:
            horizontalItemPaddingSM ?? EdgeInsets.symmetric(vertical: t.sizeXS),
        horizontalItemPaddingLG: horizontalItemPaddingLG ??
            EdgeInsets.symmetric(vertical: t.sizeSM + 2),
        verticalItemPadding: verticalItemPadding ??
            EdgeInsets.symmetric(horizontal: t.size, vertical: t.sizeXS),
        verticalItemMargin:
            verticalItemMargin ?? EdgeInsets.only(top: t.sizeSM),
      );
}

/// Fully resolved [TabsToken] — every value non-null.
@immutable
class _ResolvedTabsToken {
  const _ResolvedTabsToken({
    required this.inkBarColor,
    required this.itemColor,
    required this.itemHoverColor,
    required this.itemActiveColor,
    required this.itemSelectedColor,
    required this.disabledColor,
    required this.titleFontSize,
    required this.titleFontSizeSM,
    required this.titleFontSizeLG,
    required this.cardBg,
    required this.cardGutter,
    required this.cardHeight,
    required this.cardPadding,
    required this.cardPaddingSM,
    required this.cardPaddingLG,
    required this.horizontalItemGutter,
    required this.horizontalItemPadding,
    required this.horizontalItemPaddingSM,
    required this.horizontalItemPaddingLG,
    required this.verticalItemPadding,
    required this.verticalItemMargin,
  });

  final Color inkBarColor;
  final Color itemColor;
  final Color itemHoverColor;
  final Color itemActiveColor;
  final Color itemSelectedColor;
  final Color disabledColor;
  final double titleFontSize;
  final double titleFontSizeSM;
  final double titleFontSizeLG;
  final Color cardBg;
  final double cardGutter;
  final double cardHeight;
  final EdgeInsets cardPadding;
  final EdgeInsets cardPaddingSM;
  final EdgeInsets cardPaddingLG;
  final double horizontalItemGutter;
  final EdgeInsets horizontalItemPadding;
  final EdgeInsets horizontalItemPaddingSM;
  final EdgeInsets horizontalItemPaddingLG;
  final EdgeInsets verticalItemPadding;
  final EdgeInsets verticalItemMargin;

  double fontSize(SoftSize s) => switch (s) {
        SoftSize.small => titleFontSizeSM,
        SoftSize.middle => titleFontSize,
        SoftSize.large => titleFontSizeLG,
      };

  EdgeInsets linePadding(SoftSize s) => switch (s) {
        SoftSize.small => horizontalItemPaddingSM,
        SoftSize.middle => horizontalItemPadding,
        SoftSize.large => horizontalItemPaddingLG,
      };

  EdgeInsets cardPaddingFor(SoftSize s) {
    final mainPad = switch (s) {
      SoftSize.small => cardPaddingSM,
      SoftSize.middle => cardPadding,
      SoftSize.large => cardPaddingLG,
    };
    return mainPad;
  }
}

/// One tab: a [label] in the bar and its [content] panel.
@immutable
class TabItem {
  /// Creates a [TabItem].
  const TabItem({
    required this.key,
    this.label,
    this.content,
    this.icon,
    this.disabled = false,
    this.closable = true,
  });

  /// Unique identity of the tab.
  final String key;

  /// The bar label.
  final Widget? label;

  /// The panel shown when this tab is active.
  final Widget? content;

  /// Optional leading icon in the bar.
  final Widget? icon;

  /// Greys the tab out and blocks selecting it.
  final bool disabled;

  /// Whether an editable-card tab shows a close button.
  final bool closable;

  /// Returns a copy of this tab with the given fields replaced.
  TabItem copyWith({
    Widget? label,
    Widget? content,
    Widget? icon,
    bool? disabled,
    bool? closable,
  }) =>
      TabItem(
        key: key,
        label: label ?? this.label,
        content: content ?? this.content,
        icon: icon ?? this.icon,
        disabled: disabled ?? this.disabled,
        closable: closable ?? this.closable,
      );
}

/// Seed values for a tab added through the `+` button, returned from
/// [Tabs.onCreateTab]. Any null field falls back to the automatic default — an
/// autoincremented key and a `Tab N` label.
@immutable
class CreateTabData {
  /// Creates a [CreateTabData].
  const CreateTabData({this.label, this.key, this.content});

  /// The new tab's bar label. Null uses the default `Tab N`.
  ///
  /// Named and typed to match [TabItem.label], which is what it becomes.
  final Widget? label;

  /// The new tab's key. Null autoincrements a unique key.
  final String? key;

  /// The new tab's panel content.
  final Widget? content;
}

/// Drives a [Tabs] programmatically: read or change the active tab, mutate the
/// tab list, and listen for changes. Attach through [Tabs.controller].
///
/// When a controller is supplied it becomes the source of truth for the tabs,
/// so `Tabs.items` may be omitted.
///
/// ```dart
/// final tabs = TabsController(items: [...]);
/// tabs.addListener(() => print('active: ${tabs.activeKey}'));
/// tabs.setTitle('news', 'Breaking news');   // e.g. from a page's <title>
/// tabs.add(TabItem(key: 'x', label: Text('New')));
/// ```
class TabsController extends ChangeNotifier {
  /// Creates a [TabsController].
  TabsController({List<TabItem> items = const [], String? activeKey})
      : _items = List.of(items),
        _activeKey = activeKey ?? (items.isNotEmpty ? items.first.key : null);

  List<TabItem> _items;
  String? _activeKey;
  int _autoId = 0;

  /// The tabs, in order (read-only view).
  List<TabItem> get items => List.unmodifiable(_items);

  /// Replaces the whole tab list, keeping the active tab if it still exists.
  set items(List<TabItem> value) {
    _items = List.of(value);
    if (!_items.any((e) => e.key == _activeKey)) {
      _activeKey = _items.isNotEmpty ? _items.first.key : null;
    }
    notifyListeners();
  }

  /// The active tab's key, or null when there are no tabs.
  String? get activeKey => _activeKey;

  /// The active tab, or null.
  TabItem? get activeItem {
    for (final it in _items) {
      if (it.key == _activeKey) return it;
    }
    return null;
  }

  /// The index of the tab with [key], or -1.
  int indexOf(String key) => _items.indexWhere((e) => e.key == key);

  /// Makes the tab [key] active (no-op if missing or already active).
  void select(String key) {
    if (key == _activeKey || !_items.any((e) => e.key == key)) return;
    _activeKey = key;
    notifyListeners();
  }

  /// Appends [item]; activates it unless [activate] is false.
  void add(TabItem item, {bool activate = true}) =>
      insert(_items.length, item, activate: activate);

  /// Inserts [item] at [index]; activates it unless [activate] is false.
  void insert(int index, TabItem item, {bool activate = true}) {
    _items = [..._items]..insert(index.clamp(0, _items.length), item);
    if (activate || _activeKey == null) _activeKey = item.key;
    notifyListeners();
  }

  /// Removes the tab [key], moving the active tab to a neighbour if needed.
  void remove(String key) {
    final i = indexOf(key);
    if (i < 0) return;
    _items = [..._items]..removeAt(i);
    if (_activeKey == key) {
      _activeKey =
          _items.isEmpty ? null : _items[i.clamp(0, _items.length - 1)].key;
    }
    notifyListeners();
  }

  /// Replaces fields of the tab [key] in place — handy for a live label such as
  /// a browser tab tracking a page's `<title>`.
  void update(
    String key, {
    Widget? label,
    Widget? content,
    Widget? icon,
    bool? disabled,
    bool? closable,
  }) {
    final i = indexOf(key);
    if (i < 0) return;
    _items = [..._items];
    _items[i] = _items[i].copyWith(
      label: label,
      content: content,
      icon: icon,
      disabled: disabled,
      closable: closable,
    );
    notifyListeners();
  }

  /// Convenience for [update] that sets the tab's label to plain [title] text.
  void setTitle(String key, String title) => update(key, label: Text(title));

  /// A fresh integer key not already in use — the `Tab N` autoincrement.
  String nextKey() {
    do {
      _autoId++;
    } while (_items.any((e) => e.key == '$_autoId'));
    return '$_autoId';
  }
}

/// Defaults for every [Tabs] under a `ConfigProvider`.
///
/// House style for tab strips.
@immutable
class TabsDefaults {
  /// Creates a [TabsDefaults].
  const TabsDefaults(
      {this.type,
      this.tabPosition,
      this.hideAdd,
      this.animated,
      this.scrollAlign,
      this.snap,
      this.contentPosition});

  /// Which shape the tabs take.
  final TabsType? type;

  /// Which side the strip sits on.
  final TabPosition? tabPosition;

  /// Whether the add button is hidden on editable tabs.
  final bool? hideAdd;

  /// Whether switching tabs is animated.
  final bool? animated;

  /// Where a scrolled-to tab comes to rest.
  final TabScrollAlign? scrollAlign;

  /// Whether the strip settles on a tab boundary.
  final bool? snap;

  /// Which end the extra content sits at.
  final TabContentPosition? contentPosition;
}

/// A tabbed panel.
///
/// ```dart
/// Tabs(
///   items: [
///     TabItem(key: '1', label: const Text('Tab 1'), content: const Text('Content 1')),
///     TabItem(key: '2', label: const Text('Tab 2'), content: const Text('Content 2')),
///   ],
///   onChange: (key) => setState(() => _active = key),
/// )
/// ```
///
/// Drive it controlled with [activeKey] + [onChange], or uncontrolled with
/// [defaultActiveKey]. [type] switches between underline, card and
/// closable/addable card styles; [tabPosition] moves the bar to any edge.
class Tabs extends StatefulWidget {
  /// Creates a [Tabs].
  const Tabs({
    super.key,
    this.items = const [],
    this.controller,
    this.activeKey,
    this.defaultActiveKey,
    this.onChange,
    this.onTabClick,
    this.onCreateTab,
    this.type,
    this.size,
    this.tabPosition,
    this.centered = false,
    this.tabBarExtraContent,
    this.onEdit,
    this.hideAdd,
    this.addIcon,
    this.animated,
    this.scrollAlign,
    this.snap,
    this.contentPosition,
    this.token,
  });

  /// The tabs, in order. Ignored when a [controller] is supplied.
  final List<TabItem> items;

  /// Optional controller owning the tabs and active key. When set it is the
  /// source of truth and [items] is ignored.
  final TabsController? controller;

  /// The active tab's key. Null makes the tabs uncontrolled.
  final String? activeKey;

  /// Initial active key for an uncontrolled tabs (defaults to the first item).
  final String? defaultActiveKey;

  /// Called with the new key when the active tab changes.
  final ValueChanged<String>? onChange;

  /// Called with a tab's key when it is clicked (even if already active).
  final ValueChanged<String>? onTabClick;

  /// Called when the `+` button adds a tab, with the new tab's index. Return
  /// a [CreateTabData] to seed its label/key/content, or null for the
  /// defaults.
  /// Requires a [controller], which owns the resulting tab.
  final CreateTabData? Function(int index)? onCreateTab;

  /// Underline, card or editable-card style.
  final TabsType? type;

  /// Which height preset to use.
  final SoftSize? size;

  /// Which edge the bar sits on.
  final TabPosition? tabPosition;

  /// Centres the tabs within the bar (horizontal positions only).
  final bool centered;

  /// Extra content pinned to the ends of a horizontal bar (left and/or right).
  final TabBarExtra? tabBarExtraContent;

  /// Called on add/remove for [TabsType.editableCard].
  final void Function(String? key, TabEditAction action)? onEdit;

  /// Hides the add button of an editable-card.
  final bool? hideAdd;

  /// Replaces the add button's glyph.
  final Widget? addIcon;

  /// Whether switching panels cross-fades.
  final bool? animated;

  /// Where a selected tab lands when the bar scrolls it into view.
  final TabScrollAlign? scrollAlign;

  /// Whether a flung bar settles with a tab against its leading edge instead
  /// of wherever the throw happened to end.
  ///
  /// Off by default, because a bar of a few tabs has nothing to settle into.
  /// It earns its keep on a long run — a browser's worth of tabs on a phone —
  /// where stopping mid-label leaves a name cut in half.
  ///
  /// Snapping is to tab boundaries, not to fixed pages: tabs are as wide as
  /// their labels, so a page-sized step would land in the middle of one.
  final bool? snap;

  /// Horizontal placement of the active tab's content within its panel.
  final TabContentPosition? contentPosition;

  /// Per-instance token override, taking precedence over any supplied through
  /// `ThemeData(components: ComponentsConfig(tabs: TabsToken(...)))`.
  final TabsToken? token;

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  /// The defaults set for this component in the subtree, if any.
  TabsDefaults? get _defaults =>
      ConfigProvider.defaultsOf<TabsDefaults>(context);

  /// This widget's word, then the subtree's, then the kit's.
  TabsType get _type => widget.type ?? _defaults?.type ?? TabsType.line;

  /// This widget's word, then the subtree's, then the kit's.
  TabPosition get _tabPosition =>
      widget.tabPosition ?? _defaults?.tabPosition ?? TabPosition.top;

  /// This widget's word, then the subtree's, then the kit's.
  bool get _hideAdd => widget.hideAdd ?? _defaults?.hideAdd ?? false;

  /// This widget's word, then the subtree's, then the kit's.
  bool get _animated => widget.animated ?? _defaults?.animated ?? true;

  /// This widget's word, then the subtree's, then the kit's.
  TabScrollAlign get _scrollAlign =>
      widget.scrollAlign ?? _defaults?.scrollAlign ?? TabScrollAlign.top;

  /// This widget's word, then the subtree's, then the kit's.
  bool get _snap => widget.snap ?? _defaults?.snap ?? false;

  /// This widget's word, then the subtree's, then the kit's.
  TabContentPosition get _contentPosition =>
      widget.contentPosition ??
      _defaults?.contentPosition ??
      TabContentPosition.left;

  /// The size in force: this widget's own, else the one set for the
  /// subtree, else the standard preset.
  SoftSize get _size =>
      widget.size ?? ConfigProvider.componentSizeOf(context) ?? SoftSize.middle;

  String? _internal;
  final Map<String, GlobalKey> _tabKeys = {};
  final GlobalKey _stripKey = GlobalKey();
  final ScrollController _barController = ScrollController();
  Rect? _indicator;

  /// Where each tab starts along the scrolling axis, in the strip's own
  /// coordinates. Kept only for [Tabs.snap].
  List<double> _tabOffsets = const [];

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onController);
    _scrollActiveIntoView();
  }

  @override
  void didUpdateWidget(Tabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onController);
      widget.controller?.addListener(_onController);
    }
    if (oldWidget.activeKey != widget.activeKey) _scrollActiveIntoView();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onController);
    _barController.dispose();
    super.dispose();
  }

  /// Rebuilds and re-aligns when the controller mutates.
  void _onController() {
    if (mounted) setState(() {});
    _scrollActiveIntoView();
  }

  bool get _horizontal =>
      _tabPosition == TabPosition.top || _tabPosition == TabPosition.bottom;
  bool get _card => _type != TabsType.line;
  bool get _editable => _type == TabsType.editableCard;

  /// The effective tab list — the controller's when attached, else [Tabs.items].
  List<TabItem> get _items => widget.controller?.items ?? widget.items;

  String get _active {
    final keys = _items.map((e) => e.key).toList();
    final candidate = widget.controller?.activeKey ??
        widget.activeKey ??
        _internal ??
        widget.defaultActiveKey ??
        (keys.isNotEmpty ? keys.first : '');
    return keys.contains(candidate)
        ? candidate
        : (keys.isNotEmpty ? keys.first : '');
  }

  /// The resolved tokens for this build (global defaults + overrides).
  late _ResolvedTabsToken _r;

  EdgeInsets _tabPadding() {
    if (_card) return _r.cardPaddingFor(_size);
    return _horizontal ? _r.linePadding(_size) : _r.verticalItemPadding;
  }

  void _select(String key) {
    widget.onTabClick?.call(key);
    if (key == _active) return;
    if (widget.controller != null) {
      widget.controller!.select(key); // notifies -> rebuild + re-align
    } else if (widget.activeKey == null) {
      setState(() => _internal = key);
    }
    widget.onChange?.call(key);
    _scrollActiveIntoView();
  }

  /// Handles the `+` button: with a controller, seeds a tab from [Tabs.onCreateTab]
  /// (or the autoincrement defaults) and adds it; otherwise defers to [onEdit].
  void _handleAdd() {
    final controller = widget.controller;
    if (controller == null) {
      widget.onEdit?.call(null, TabEditAction.add);
      return;
    }
    final index = controller.items.length;
    final data = widget.onCreateTab?.call(index);
    final key = data?.key ?? controller.nextKey();
    final label = data?.label ?? Text('Tab ${index + 1}');
    controller.add(TabItem(key: key, label: label, content: data?.content));
    widget.onEdit?.call(key, TabEditAction.add);
    widget.onChange?.call(key);
  }

  /// Handles a tab's close button.
  void _handleRemove(String key) {
    widget.onEdit?.call(key, TabEditAction.remove);
    widget.controller?.remove(key);
  }

  /// Scrolls the bar so the active tab sits at the start or centre, per
  /// [Tabs.scrollAlign]. Only the bar's own scroll view moves, never the page.
  void _scrollActiveIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _alignTarget();
      if (target == null) return;
      final token = context.softToken;
      _barController
          .animateTo(
            target,
            duration: token.motionDurationMid,
            curve: token.motionEaseInOut,
          )
          // The label's weight animates from w400 to w500 over the same span,
          // so the tab that just lost the bold narrows while we are still
          // travelling and everything after it slides left. The target was
          // read before any of that, which leaves the tab short of the edge by
          // the width the label gave up. Re-aim once the type has settled.
          .then((_) => _correctAlignment());
    });
  }

  void _correctAlignment() {
    if (!mounted || !_barController.hasClients) return;
    final target = _alignTarget();
    if (target == null || (target - _barController.offset).abs() < 0.5) return;
    final token = context.softToken;
    _barController.animateTo(
      target,
      duration: token.motionDurationFast,
      curve: token.motionEaseOut,
    );
  }

  /// Where the bar must sit for the active tab to be aligned, or null while
  /// the geometry is not there to say.
  /// How far along the bar's own scroll a tab sits.
  ///
  /// Not simply its offset inside the strip: a horizontal bar that reads right
  /// to left starts at the far end, where a scroll offset of zero shows the
  /// content's right edge. A tab's distance along the scroll is then measured
  /// from that edge, not from the left one. Getting this wrong sends every
  /// scroll — the snap boundaries and the jump to the active tab alike — to
  /// the mirror image of where it was meant to go.
  double _scrollOffsetOf(RenderBox tab, RenderBox strip) {
    final origin = tab.localToGlobal(Offset.zero, ancestor: strip);
    if (!_horizontal) return origin.dy;
    if (Directionality.of(context) == TextDirection.ltr) return origin.dx;
    return strip.size.width - (origin.dx + tab.size.width);
  }

  double? _alignTarget() {
    if (!mounted || !_barController.hasClients) return null;
    final tab =
        _tabKeys[_active]?.currentContext?.findRenderObject() as RenderBox?;
    final strip = _stripKey.currentContext?.findRenderObject() as RenderBox?;
    if (tab == null || strip == null || !tab.hasSize || !strip.hasSize) {
      return null;
    }
    final start = _scrollOffsetOf(tab, strip);
    final extent = _horizontal ? tab.size.width : tab.size.height;
    final viewport = _barController.position.viewportDimension;
    final target = _scrollAlign == TabScrollAlign.center
        ? start - (viewport - extent) / 2
        : start;
    return target.clamp(
      _barController.position.minScrollExtent,
      _barController.position.maxScrollExtent,
    );
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureOffsets();
      // The ink bar is a line-tab affair; the offsets are needed either way.
      if (_type == TabsType.line) _measure();
    });
  }

  /// Records where every tab begins, so a fling can settle against one.
  void _measureOffsets() {
    if (!_snap) return;
    final strip = _stripKey.currentContext?.findRenderObject() as RenderBox?;
    if (strip == null || !strip.hasSize) return;
    final offsets = <double>[];
    for (final item in _items) {
      final box =
          _tabKeys[item.key]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      offsets.add(_scrollOffsetOf(box, strip));
    }
    if (offsets.length != _tabOffsets.length ||
        !const _Approx().equal(offsets, _tabOffsets)) {
      if (mounted) setState(() => _tabOffsets = offsets);
    }
  }

  void _measure() {
    final strip = _stripKey.currentContext?.findRenderObject() as RenderBox?;
    final tab =
        _tabKeys[_active]?.currentContext?.findRenderObject() as RenderBox?;
    if (strip == null || tab == null || !strip.hasSize || !tab.hasSize) return;
    final origin = tab.localToGlobal(Offset.zero, ancestor: strip);
    final rect = origin & tab.size;
    if (_indicator != rect && mounted) setState(() => _indicator = rect);
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final override = widget.token ??
        ConfigProvider.componentOf<TabsToken>(context) ??
        const TabsToken();
    _r = override._resolve(token);
    _scheduleMeasure();

    final bar = _buildBar(token);

    final panel = _buildPanel(token);

    if (_horizontal) {
      // The panel sizes to its content, so Tabs works in an unbounded-height
      // context (a scroll view) as well as a bounded one.
      final children = _tabPosition == TabPosition.top
          ? [
              bar,
              if (panel != null) panel,
            ]
          : [
              if (panel != null) panel,
              bar,
            ];
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    final children = _tabPosition == TabPosition.left
        ? [
            bar,
            if (panel != null) Expanded(child: panel),
          ]
        : [
            if (panel != null) Expanded(child: panel),
            bar,
          ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  // --- tab bar ---

  Widget _buildBar(Token token) {
    // Spacing between tabs is a spacer, not a margin on the tab — so the ink
    // bar (measured from the tab's box) hugs the label, not the gap too.
    final gutter = _card ? _r.cardGutter : _r.horizontalItemGutter;
    final items = _items;
    final tabs = <Widget>[
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0)
          _horizontal ? SizedBox(width: gutter) : SizedBox(height: gutter),
        _buildTab(token, items[i]),
      ],
      if (_editable && !_hideAdd) ...[
        SizedBox(width: _r.cardGutter),
        _buildAddButton(token),
      ],
    ];

    final strip = Stack(
      key: _stripKey,
      children: [
        if (_horizontal)
          Row(mainAxisSize: MainAxisSize.min, children: tabs)
        else
          // Vertical tabs stretch to a common width (the widest tab) so every
          // one reaches the bar's base line — card tabs then sit flush against
          // it, and the active one overlaps to merge with the panel.
          IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: tabs,
            ),
          ),
        if (_type == TabsType.line && _indicator != null)
          _buildIndicator(token),
      ],
    );

    // The base line runs the full length of the bar. For line tabs it is the
    // container's border (the ink bar rides it). For card tabs it is drawn
    // *behind* the tabs instead, so each tab can paint over its own slice —
    // grey when inactive, panel colour when active — without any shift.
    final baseLineSide =
        BorderSide(color: token.colorBorderSecondary, width: token.lineWidth);
    final border = switch (_tabPosition) {
      TabPosition.top => Border(bottom: baseLineSide),
      TabPosition.bottom => Border(top: baseLineSide),
      TabPosition.left => Border(right: baseLineSide),
      TabPosition.right => Border(left: baseLineSide),
    };

    final Widget scroll = SingleChildScrollView(
      controller: _barController,
      scrollDirection: _horizontal ? Axis.horizontal : Axis.vertical,
      physics: _snap && _tabOffsets.length > 1
          ? _TabSnapPhysics(offsets: _tabOffsets)
          : null,
      child: strip,
    );

    // The boundaries are measured once per build, but the strip can change
    // width without rebuilding this widget — a webfont arriving late reflows
    // every label. The metrics change when it does, so re-measure then;
    // otherwise a fling snaps to where the tabs used to be.
    final barView = _snap
        ? NotificationListener<ScrollMetricsNotification>(
            onNotification: (_) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _measureOffsets());
              return false;
            },
            child: scroll,
          )
        : scroll;

    // Extra content sits at the start and/or end of a horizontal bar.
    final extra = widget.tabBarExtraContent;
    final Widget content;
    if (_horizontal && (extra != null || widget.centered)) {
      content = Row(
        children: [
          if (extra?.left != null)
            Padding(
              padding: EdgeInsets.only(right: token.size),
              child: extra!.left!,
            ),
          if (widget.centered) const Spacer(),
          Expanded(child: barView),
          if (widget.centered) const Spacer(),
          if (extra?.right != null)
            Padding(
              padding: EdgeInsets.only(left: token.size),
              child: extra!.right!,
            ),
        ],
      );
    } else {
      content = barView;
    }

    if (_card) {
      // Base line behind the tabs, spanning the whole bar; each tab paints over
      // its own slice (see _CardTabPainter).
      final w = token.lineWidth;
      final c = token.colorBorderSecondary;
      final line = switch (_tabPosition) {
        TabPosition.top => Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(height: w, child: ColoredBox(color: c)),
          ),
        TabPosition.bottom => Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SizedBox(height: w, child: ColoredBox(color: c)),
          ),
        TabPosition.left => Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: SizedBox(width: w, child: ColoredBox(color: c)),
          ),
        TabPosition.right => Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: SizedBox(width: w, child: ColoredBox(color: c)),
          ),
      };
      return Stack(children: [line, content]);
    }

    return Container(
      decoration: BoxDecoration(border: border),
      child: content,
    );
  }

  Widget _buildIndicator(Token token) {
    final r = _indicator!;
    const thickness = 2.0;
    final Widget bar = AnimatedContainer(
      duration: token.motionDurationMid,
      curve: token.motionEaseInOut,
      color: _r.inkBarColor,
    );
    // The ink bar hugs the base-line edge, matching the active tab's extent.
    return switch (_tabPosition) {
      TabPosition.top => AnimatedPositioned(
          duration: token.motionDurationMid,
          curve: token.motionEaseInOut,
          left: r.left,
          width: r.width,
          bottom: 0,
          height: thickness,
          child: bar,
        ),
      TabPosition.bottom => AnimatedPositioned(
          duration: token.motionDurationMid,
          curve: token.motionEaseInOut,
          left: r.left,
          width: r.width,
          top: 0,
          height: thickness,
          child: bar,
        ),
      TabPosition.left => AnimatedPositioned(
          duration: token.motionDurationMid,
          curve: token.motionEaseInOut,
          top: r.top,
          height: r.height,
          right: 0,
          width: thickness,
          child: bar,
        ),
      TabPosition.right => AnimatedPositioned(
          duration: token.motionDurationMid,
          curve: token.motionEaseInOut,
          top: r.top,
          height: r.height,
          left: 0,
          width: thickness,
          child: bar,
        ),
    };
  }

  Widget _buildTab(Token token, TabItem item) {
    final key = _tabKeys.putIfAbsent(item.key, GlobalKey.new);
    return KeyedSubtree(
      key: key,
      child: _TabButton(
        token: token,
        style: _r,
        active: item.key == _active,
        disabled: item.disabled,
        card: _card,
        editable: _editable && item.closable,
        horizontal: _horizontal,
        position: _tabPosition,
        fontSize: _r.fontSize(_size),
        padding: _tabPadding(),
        icon: item.icon,
        label: item.label,
        onTap: item.disabled ? null : () => _select(item.key),
        onClose:
            _editable && item.closable ? () => _handleRemove(item.key) : null,
      ),
    );
  }

  Widget _buildAddButton(Token token) {
    // Match a card tab's full height: its top border + vertical padding + label.
    final height = token.lineWidth +
        _r.cardPaddingFor(_size).vertical +
        _r.fontSize(_size);
    return _AddButton(
      token: token,
      height: height,
      icon: widget.addIcon,
      onTap: _handleAdd,
    );
  }

  // --- panel ---

  Widget? _buildPanel(Token token) {
    final items = _items;
    if (items.every((e) => e.content == null)) return null;
    final active = items.where((e) => e.key == _active).toList();
    final content = active.isEmpty
        ? const SizedBox.shrink()
        : (active.first.content ?? const SizedBox.shrink());

    final align = switch (_contentPosition) {
      TabContentPosition.left => Alignment.centerLeft,
      TabContentPosition.center => Alignment.center,
      TabContentPosition.right => Alignment.centerRight,
    };

    final padded = Padding(
      padding: EdgeInsets.all(token.size),
      child: Align(
        alignment: align,
        child: KeyedSubtree(key: ValueKey(_active), child: content),
      ),
    );

    if (!_animated) return padded;
    return AnimatedSwitcher(
      duration: token.motionDurationMid,
      switchInCurve: token.motionEaseOut,
      transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
      child: padded,
    );
  }
}

/// One tab in the bar.
class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.token,
    required this.style,
    required this.active,
    required this.disabled,
    required this.card,
    required this.editable,
    required this.horizontal,
    required this.position,
    required this.fontSize,
    required this.padding,
    required this.onTap,
    this.icon,
    this.label,
    this.onClose,
  });

  final Token token;
  final _ResolvedTabsToken style;
  final bool active;
  final bool disabled;
  final bool card;
  final bool editable;
  final bool horizontal;
  final TabPosition position;
  final double fontSize;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Widget? icon;
  final Widget? label;
  final VoidCallback? onClose;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    final s = widget.style;
    final color = widget.disabled
        ? s.disabledColor
        : widget.active
            ? s.itemSelectedColor
            : _hovered
                ? s.itemHoverColor
                : s.itemColor;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          // Ease the icon colour on the same curve as the label, so hover and
          // selection animate the whole tab together rather than the text alone.
          TweenAnimationBuilder<Color?>(
            duration: t.motionDurationMid,
            curve: t.motionEaseInOut,
            tween: ColorTween(end: color),
            builder: (context, value, child) => IconTheme.merge(
              data: IconThemeData(color: value, size: widget.fontSize),
              child: widget.icon!,
            ),
          ),
          SizedBox(width: t.sizeXS),
        ],
        // Animate the label colour so a tab change eases in.
        AnimatedDefaultTextStyle(
          duration: t.motionDurationMid,
          curve: t.motionEaseInOut,
          style: TextStyle(
            color: color,
            fontSize: widget.fontSize,
            fontWeight: widget.active ? FontWeight.w500 : FontWeight.w400,
            fontFamily: t.fontFamily,
            fontFamilyFallback: t.fontFamilyFallback,
            height: 1.0,
            leadingDistribution: TextLeadingDistribution.even,
            decoration: TextDecoration.none,
          ),
          child: widget.label ?? const SizedBox.shrink(),
        ),
        if (widget.editable) ...[
          SizedBox(width: t.sizeXS),
          _CloseButton(color: color, onTap: widget.onClose),
        ],
      ],
    );

    final padded = Padding(padding: widget.padding, child: row);
    // Card tabs are painted (not a bordered box): every tab keeps the same size
    // and position, and the panel-facing edge is drawn in the panel colour for
    // the active tab so it merges with the content — no shift, no size change.
    // The bar's base line sits behind the tabs; each tab's painted edge covers
    // its slice of it (grey when inactive, panel colour when active).
    final Widget body = widget.card
        ? CustomPaint(
            painter: _CardTabPainter(
              position: widget.position,
              radius: t.borderRadiusLG,
              fill: widget.active ? t.colorBgContainer : s.cardBg,
              border: t.colorBorderSecondary,
              panelColor:
                  widget.active ? t.colorBgContainer : t.colorBorderSecondary,
              strokeWidth: t.lineWidth,
            ),
            child: padded,
          )
        : padded;

    return MouseRegion(
      cursor:
          widget.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: body,
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          size: const Size.square(12),
          painter: CrossPainter(color, strokeWidth: 1.1, inset: 3),
        ),
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  const _AddButton({
    required this.token,
    required this.height,
    required this.onTap,
    this.icon,
  });

  final Token token;
  final double height;
  final VoidCallback onTap;
  final Widget? icon;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    final color = _hovered ? t.primary.base : t.colorText;
    final radius = Radius.circular(t.borderRadiusLG);
    final line = BorderSide(color: t.colorBorderSecondary, width: t.lineWidth);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        // Height is computed to match a tab, so the button stays the same size
        // as the tabs across every size preset.
        child: Container(
          width: t.controlHeight,
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.colorFillQuaternary,
            borderRadius: BorderRadius.only(
              topLeft: radius,
              topRight: radius,
            ),
            border: Border(top: line, left: line, right: line),
          ),
          child: widget.icon ??
              CustomPaint(
                size: const Size.square(14),
                painter: PlusPainter(color),
              ),
        ),
      ),
    );
  }
}

/// Paints a card tab: a rounded-top box with a uniform border, except the
/// panel-facing edge which is drawn in [panelColor] — grey to sit on the base
/// line, or the panel colour on the active tab so it merges with the content.
/// Painting (rather than a bordered box) keeps every tab the same size.
class _CardTabPainter extends CustomPainter {
  _CardTabPainter({
    required this.position,
    required this.radius,
    required this.fill,
    required this.border,
    required this.panelColor,
    required this.strokeWidth,
  });

  final TabPosition position;
  final double radius;
  final Color fill;
  final Color border;
  final Color panelColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final r = Radius.circular(radius);
    // Round the two corners away from the panel; the panel edge stays square.
    final rrect = switch (position) {
      TabPosition.top =>
        RRect.fromRectAndCorners(rect, topLeft: r, topRight: r),
      TabPosition.bottom =>
        RRect.fromRectAndCorners(rect, bottomLeft: r, bottomRight: r),
      TabPosition.left =>
        RRect.fromRectAndCorners(rect, topLeft: r, bottomLeft: r),
      TabPosition.right =>
        RRect.fromRectAndCorners(rect, topRight: r, bottomRight: r),
    };

    canvas.drawRRect(rrect, Paint()..color = fill);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Overpaint the (straight) panel-facing edge in its own colour.
    final edge = Paint()
      ..color = panelColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final (a, b) = switch (position) {
      TabPosition.top => (
          Offset(0, size.height - inset),
          Offset(size.width, size.height - inset),
        ),
      TabPosition.bottom => (Offset(0, inset), Offset(size.width, inset)),
      TabPosition.left => (
          Offset(size.width - inset, 0),
          Offset(size.width - inset, size.height),
        ),
      TabPosition.right => (Offset(inset, 0), Offset(inset, size.height)),
    };
    canvas.drawLine(a, b, edge);
  }

  @override
  bool shouldRepaint(_CardTabPainter old) =>
      old.position != position ||
      old.radius != radius ||
      old.fill != fill ||
      old.border != border ||
      old.panelColor != panelColor ||
      old.strokeWidth != strokeWidth;
}

/// Compares two lists of offsets without tripping on sub-pixel noise.
class _Approx {
  const _Approx();

  bool equal(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.5) return false;
    }
    return true;
  }
}

/// Settles a flung tab bar with a tab against its leading edge.
///
/// Snapping is to the recorded tab boundaries rather than to a fixed step:
/// tabs are as wide as their labels, so a page-sized stride would come to rest
/// in the middle of one.
class _TabSnapPhysics extends ScrollPhysics {
  const _TabSnapPhysics({required this.offsets, super.parent});

  /// Where each tab begins, in scroll coordinates, ascending.
  final List<double> offsets;

  @override
  _TabSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _TabSnapPhysics(offsets: offsets, parent: buildParent(ancestor));

  /// Where the throw would have ended, had nothing caught it.
  double _naturalEnd(ScrollMetrics position, double velocity) {
    final simulation = super.createBallisticSimulation(position, velocity);
    final end = simulation?.x(double.infinity) ?? position.pixels;
    return end.clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  /// The reachable resting place nearest [to].
  ///
  /// Only boundaries the bar can actually rest at are considered. Picking the
  /// nearest of all of them and clamping afterwards looks the same until the
  /// end of the run, where the nearest boundary lies past the maximum: the
  /// clamp then lands between two tabs and cuts the leading one.
  ///
  /// Both ends of the run count alongside the tab boundaries. A tab boundary
  /// is almost never the maximum, so without them the end of the run has no
  /// reachable place to settle and the bar is dragged back to the last
  /// boundary before it — far enough to leave the final tabs stranded off the
  /// trailing edge, with every attempt to reach them pulled back. Once the
  /// tabs have run out there is nothing left to align, and resting flush
  /// against the end is the whole of what is wanted.
  double? _nearestReachable(double to, ScrollMetrics position) {
    double? best;
    void consider(double o) {
      if (o < position.minScrollExtent || o > position.maxScrollExtent) return;
      if (best == null || (o - to).abs() < (best! - to).abs()) best = o;
    }

    offsets.forEach(consider);
    consider(position.minScrollExtent);
    consider(position.maxScrollExtent);
    return best;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (offsets.isEmpty) {
      return super.createBallisticSimulation(position, velocity);
    }
    // Out past an edge is the parent's business: let it rubber-band back
    // rather than snapping to a tab that is not reachable.
    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    final target = _nearestReachable(_naturalEnd(position, velocity), position);
    // Nothing reachable — a run shorter than its viewport — so let the parent
    // settle it however it would.
    if (target == null) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tol = toleranceFor(position);
    if ((target - position.pixels).abs() < tol.distance) return null;

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tol,
    );
  }

  // A snapping list always has somewhere to settle, so it must be allowed to
  // run its simulation even when the throw was gentle.
  @override
  bool get allowImplicitScrolling => false;
}
