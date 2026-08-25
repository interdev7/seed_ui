import 'package:flutter/widgets.dart';

import '../../icons/icons.dart' show ChevronPainter;
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/expandable.dart';
import '../../utils/keyed_set.dart';

/// Which side of a [Collapse] header the expand icon sits on.
enum CollapseIconPosition {
  /// The expand icon leads the header.
  start,

  /// The expand icon trails the header.
  end
}

/// What toggles a [CollapseItem].
enum CollapsibleTrigger {
  /// The whole header toggles the panel (the default).
  header,

  /// Only the expand icon toggles the panel.
  icon,

  /// The panel is greyed out and cannot toggle.
  disabled,
}

/// Per-component design tokens for [Collapse] — the Collapse token
/// table.
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(collapse: CollapseToken(...)))`,
/// or per instance via [Collapse.token].
@immutable
class CollapseToken {
  /// Creates a [CollapseToken].
  const CollapseToken({
    this.headerBg,
    this.headerPadding,
    this.contentBg,
    this.contentPadding,
    this.borderRadius,
  });

  /// Header background (`headerBg`). Defaults to `colorFillQuaternary`.
  final Color? headerBg;

  /// Header padding at the middle size (`headerPadding`). Small and large are
  /// derived from it.
  final EdgeInsets? headerPadding;

  /// Content background (`contentBg`). Defaults to `colorBgContainer`.
  final Color? contentBg;

  /// Content padding at the middle size (`contentPadding`).
  final EdgeInsets? contentPadding;

  /// Corner radius of a bordered collapse.
  final double? borderRadius;

  _ResolvedCollapseToken _resolve(Token t) => _ResolvedCollapseToken(
        headerBg: headerBg ?? t.colorFillQuaternary,
        headerPadding: headerPadding ??
            EdgeInsets.symmetric(vertical: t.sizeSM, horizontal: t.size),
        contentBg: contentBg ?? t.colorBgContainer,
        contentPadding: contentPadding ?? EdgeInsets.all(t.size),
        borderRadius: borderRadius ?? t.borderRadiusLG,
      );
}

/// Fully resolved [CollapseToken] — every value non-null.
@immutable
class _ResolvedCollapseToken {
  const _ResolvedCollapseToken({
    required this.headerBg,
    required this.headerPadding,
    required this.contentBg,
    required this.contentPadding,
    required this.borderRadius,
  });

  final Color headerBg;
  final EdgeInsets headerPadding;
  final Color contentBg;
  final EdgeInsets contentPadding;
  final double borderRadius;

  /// Header padding scaled for the size preset.
  EdgeInsets headerPad(SoftSize s) => switch (s) {
        SoftSize.small =>
          headerPadding * 0.67, // ~8/11 — the small preset is tighter.
        SoftSize.middle => headerPadding,
        SoftSize.large =>
          headerPadding + const EdgeInsets.symmetric(vertical: 4),
      };

  EdgeInsets contentPad(SoftSize s) => switch (s) {
        SoftSize.small => contentPadding * 0.67,
        SoftSize.middle => contentPadding,
        SoftSize.large => contentPadding,
      };
}

/// One panel in a [Collapse] — a [label] header and its [content] body.
@immutable
class CollapseItem {
  /// Creates a [CollapseItem].
  const CollapseItem({
    required this.key,
    required this.label,
    this.content,
    this.extra,
    this.showArrow = true,
    this.collapsible,
    this.forceRender = false,
  });

  /// Unique identity of the panel.
  final String key;

  /// The header label.
  final Widget label;

  /// The body, shown while the panel is open.
  final Widget? content;

  /// A widget pinned to the far end of the header (before the end-side icon).
  final Widget? extra;

  /// Whether the expand icon shows for this panel.
  final bool showArrow;

  /// Overrides the collapse's [Collapse.collapsible] for this panel.
  final CollapsibleTrigger? collapsible;

  /// Keeps the [content] in the tree even while collapsed.
  final bool forceRender;
}

/// Defaults for every [Collapse] under a `ConfigProvider`.
///
/// House style for collapses.
@immutable
class CollapseDefaults {
  /// Creates a [CollapseDefaults].
  const CollapseDefaults({
    this.accordion,
    this.bordered,
    this.ghost,
    this.expandIconPosition,
    this.collapsible,
    this.size,
  });

  /// Whether only one panel opens at a time.
  final bool? accordion;

  /// Whether panels are bordered.
  final bool? bordered;

  /// Whether panels drop their background.
  final bool? ghost;

  /// Which end the chevron sits at.
  final CollapseIconPosition? expandIconPosition;

  /// What opens a panel.
  final CollapsibleTrigger? collapsible;

  /// Which control height a [Collapse] takes, unless it names one.
  ///
  /// Nearer than `ConfigProvider.componentSize`, so this wins where both
  /// are set: small buttons on an otherwise normal screen.
  final SoftSize? size;
}

/// A set of collapsible panels.
///
/// ```dart
/// Collapse(
///   items: [
///     CollapseItem(key: '1', label: const Text('Panel 1'), content: const Text('Body 1')),
///     CollapseItem(key: '2', label: const Text('Panel 2'), content: const Text('Body 2')),
///   ],
///   defaultActiveKeys: const ['1'],
/// )
/// ```
///
/// Drive it controlled with [activeKeys] + [onChange], or uncontrolled with
/// [defaultActiveKeys]. [accordion] keeps at most one panel open; [ghost] drops
/// the borders and background; [bordered] toggles the outer frame.
class Collapse extends StatefulWidget {
  /// Creates a [Collapse].
  const Collapse({
    super.key,
    required this.items,
    this.activeKeys,
    this.defaultActiveKeys,
    this.onChange,
    this.accordion,
    this.bordered,
    this.ghost,
    this.size,
    this.expandIconPosition,
    this.collapsible,
    this.expandIcon,
    this.destroyInactivePanel = false,
    this.token,
  });

  /// The panels, in order.
  final List<CollapseItem> items;

  /// The open panels' keys. Non-null makes the collapse controlled.
  final List<String>? activeKeys;

  /// Initially open keys for an uncontrolled collapse.
  final List<String>? defaultActiveKeys;

  /// Called with the full set of open keys whenever it changes.
  final ValueChanged<List<String>>? onChange;

  /// Allows at most one open panel at a time.
  final bool? accordion;

  /// Draws the outer border and inter-panel dividers.
  final bool? bordered;

  /// Borderless and transparent — panels blend into the page.
  final bool? ghost;

  /// Header/content padding preset.
  final SoftSize? size;

  /// Which side the expand icon sits on.
  final CollapseIconPosition? expandIconPosition;

  /// Default trigger for every panel; a panel may override it.
  final CollapsibleTrigger? collapsible;

  /// Builds a custom expand icon from the panel's open state. When null, a
  /// chevron that turns a quarter-turn on open is used.
  final Widget Function(BuildContext context, bool isActive)? expandIcon;

  /// Removes a panel's content from the tree while it is collapsed.
  final bool destroyInactivePanel;

  /// Per-instance token overrides.
  final CollapseToken? token;

  @override
  State<Collapse> createState() => _CollapseState();
}

class _CollapseState extends State<Collapse> {
  /// The defaults set for this component in the subtree, if any.
  CollapseDefaults? get _defaults =>
      ConfigProvider.defaultsOf<CollapseDefaults>(context);

  /// This widget's word, then the subtree's, then the kit's.
  bool get _accordion => widget.accordion ?? _defaults?.accordion ?? false;

  /// This widget's word, then the subtree's, then the kit's.
  bool get _bordered => widget.bordered ?? _defaults?.bordered ?? true;

  /// This widget's word, then the subtree's, then the kit's.
  bool get _ghost => widget.ghost ?? _defaults?.ghost ?? false;

  /// This widget's word, then the subtree's, then the kit's.
  CollapseIconPosition get _expandIconPosition =>
      widget.expandIconPosition ??
      _defaults?.expandIconPosition ??
      CollapseIconPosition.start;

  /// This widget's word, then the subtree's, then the kit's.
  CollapsibleTrigger get _collapsible =>
      widget.collapsible ?? _defaults?.collapsible ?? CollapsibleTrigger.header;

  /// The size in force: this widget's own, else the one set for the
  /// subtree, else the standard preset.
  SoftSize get _size =>
      widget.size ??
      _defaults?.size ??
      ConfigProvider.componentSizeOf(context) ??
      SoftSize.middle;

  late final KeyedSet _open = KeyedSet(widget.defaultActiveKeys);

  Set<String> get _active => _open.effective(widget.activeKeys);

  void _toggle(String key) {
    final current = _active;
    final open = current.contains(key);
    final Set<String> next;
    if (_accordion) {
      next = open ? <String>{} : {key};
    } else {
      next = {...current};
      open ? next.remove(key) : next.add(key);
    }
    if (_open.commit(widget.activeKeys, next)) setState(() {});
    widget.onChange?.call(next.toList());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<CollapseToken>(context) ??
            const CollapseToken())
        ._resolve(t);

    final panels = <Widget>[];
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      panels.add(
        _Panel(
          token: t,
          style: r,
          item: item,
          size: _size,
          active: _active.contains(item.key),
          ghost: _ghost,
          bordered: _bordered,
          // Every panel but the first carries the divider on its own header, so
          // the separator is always present regardless of the neighbour's state
          // and never doubles with an open panel's content border. Borderless
          // keeps the dividers; only ghost drops them.
          showTopBorder: !_ghost && i > 0,
          iconPosition: _expandIconPosition,
          collapsible: item.collapsible ?? _collapsible,
          expandIcon: widget.expandIcon,
          destroyInactive: widget.destroyInactivePanel,
          onToggle: () => _toggle(item.key),
        ),
      );
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: panels,
    );

    // Ghost blends into the page — no frame, no rounding, no background.
    if (_ghost) return column;

    // Both bordered and borderless keep the rounded frame and background; only
    // the border line itself is dropped when borderless. The border is a
    // foreground decoration so it paints *over* the panels' own backgrounds —
    // otherwise the grey header and white body fills cover the side borders and
    // only the top/inner dividers show.
    final radius = BorderRadius.circular(r.borderRadius);
    return Container(
      decoration: BoxDecoration(color: r.contentBg, borderRadius: radius),
      foregroundDecoration: _bordered
          ? BoxDecoration(
              border: Border.all(color: t.colorBorder, width: t.lineWidth),
              borderRadius: radius,
            )
          : null,
      clipBehavior: Clip.antiAlias,
      child: column,
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.token,
    required this.style,
    required this.item,
    required this.size,
    required this.active,
    required this.ghost,
    required this.bordered,
    required this.showTopBorder,
    required this.iconPosition,
    required this.collapsible,
    required this.expandIcon,
    required this.destroyInactive,
    required this.onToggle,
  });

  final Token token;
  final _ResolvedCollapseToken style;
  final CollapseItem item;
  final SoftSize size;
  final bool active;
  final bool ghost;
  final bool bordered;
  final bool showTopBorder;
  final CollapseIconPosition iconPosition;
  final CollapsibleTrigger collapsible;
  final Widget Function(BuildContext, bool)? expandIcon;
  final bool destroyInactive;
  final VoidCallback onToggle;

  bool get _disabled => collapsible == CollapsibleTrigger.disabled;

  Widget _icon(BuildContext context) {
    if (expandIcon != null) return expandIcon!(context, active);
    final color =
        _disabled ? token.colorTextQuaternary : token.colorTextSecondary;
    return AnimatedRotation(
      duration: token.motionDurationMid,
      curve: token.motionEaseInOut,
      turns: active ? 0.25 : 0.0,
      child: CustomPaint(
        size: const Size.square(12),
        painter: ChevronPainter(color, strokeWidth: 1.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = _disabled ? token.colorTextQuaternary : token.colorText;

    // The icon toggles on its own tap only when the trigger is `icon`; that
    // keeps its hit target independent of the header.
    Widget icon = item.showArrow
        ? Padding(
            padding: EdgeInsets.only(
              right:
                  iconPosition == CollapseIconPosition.start ? token.sizeXS : 0,
              left: iconPosition == CollapseIconPosition.end ? token.sizeXS : 0,
            ),
            child: _icon(context),
          )
        : const SizedBox.shrink();
    if (collapsible == CollapsibleTrigger.icon && item.showArrow) {
      icon = _Tappable(onTap: onToggle, child: icon);
    }

    final label = DefaultTextStyle(
      style: TextStyle(
        color: headerColor,
        fontSize: token.fontSize,
        height: 1.0,
      ),
      child: item.label,
    );

    final headerRow = Row(
      children: [
        if (item.showArrow && iconPosition == CollapseIconPosition.start) icon,
        Expanded(child: label),
        if (item.extra != null) ...[
          item.extra!,
          SizedBox(width: token.sizeXS),
        ],
        if (item.showArrow && iconPosition == CollapseIconPosition.end) icon,
      ],
    );

    Widget header = Container(
      decoration: BoxDecoration(
        color: ghost ? null : style.headerBg,
        // The inter-panel divider lives on the header's top edge.
        border: showTopBorder
            ? Border(
                top: BorderSide(
                  color: token.colorBorder,
                  width: token.lineWidth,
                ),
              )
            : null,
      ),
      padding: style.headerPad(size),
      child: headerRow,
    );
    // The whole header toggles unless the trigger is `icon` (handled above) or
    // `disabled`.
    if (collapsible == CollapsibleTrigger.header) {
      header = _Tappable(onTap: onToggle, child: header);
    }

    // Bordered panels separate the open header from its content with a line and
    // a white content surface. Borderless merges them: no divider, and the
    // content takes the header's own background so header and body read as one
    // block. Ghost is fully transparent.
    final contentBorder = bordered && !ghost
        ? Border(
            top: BorderSide(color: token.colorBorder, width: token.lineWidth),
          )
        : null;
    final contentColor = ghost
        ? null
        : bordered
            ? style.contentBg
            : style.headerBg;

    final body = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: contentColor,
        border: contentBorder,
      ),
      padding: style.contentPad(size),
      child: DefaultTextStyle(
        style: TextStyle(
          color: token.colorText,
          fontSize: token.fontSize,
          height: token.lineHeight,
        ),
        child: item.content ?? const SizedBox.shrink(),
      ),
    );

    final contentArea = Expandable(
      expanded: active,
      destroyWhenCollapsed: destroyInactive && !item.forceRender,
      child: body,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, contentArea],
    );
  }
}

/// A minimal tap wrapper with a pointer cursor, avoiding a Material dependency.
class _Tappable extends StatelessWidget {
  const _Tappable({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}
