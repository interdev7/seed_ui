import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import 'tabs.dart';

/// How a [Card] draws its edge.
enum CardVariant {
  /// A 1px border around the card (the default).
  outlined,

  /// No border; the card blends into the surface behind it.
  borderless,
}

/// A [Card]'s nesting role.
enum CardType {
  /// A standalone card (the default).
  outer,

  /// A card nested inside another, with a tinted, borderless header.
  inner,
}

/// Per-component design tokens for [Card] — its own token table.
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [CardToken(...)])`, or per instance via [Card.token].
@immutable
class CardToken {
  /// Creates a [CardToken].
  const CardToken({
    this.headerBg,
    this.headerFontSize,
    this.headerFontSizeSM,
    this.headerHeight,
    this.headerHeightSM,
    this.headerPadding,
    this.headerPaddingSM,
    this.bodyPadding,
    this.bodyPaddingSM,
    this.actionsBg,
    this.actionsLiMargin,
    this.extraColor,
    this.borderRadius,
  });

  /// Header background (`headerBg`). Transparent by default.
  final Color? headerBg;

  /// Header title font size — default (`headerFontSize`) and small.
  final double? headerFontSize;

  /// Header title font size at the small size.
  final double? headerFontSizeSM;

  /// Header min-height — default (`headerHeight`) and small.
  final double? headerHeight;

  /// Header min-height at the small size.
  final double? headerHeightSM;

  /// Horizontal header padding — default (`headerPadding`) and small.
  final double? headerPadding;

  /// Horizontal header padding at the small size.
  final double? headerPaddingSM;

  /// Body padding — default (`bodyPadding`) and small.
  final EdgeInsets? bodyPadding;

  /// Body padding at the small size.
  final EdgeInsets? bodyPaddingSM;

  /// Action-bar background (`actionsBg`).
  final Color? actionsBg;

  /// Vertical margin around each action (`actionsLiMargin`).
  final double? actionsLiMargin;

  /// Colour of the header `extra` slot (`extraColor`).
  final Color? extraColor;

  /// Corner radius of the card.
  final double? borderRadius;

  _ResolvedCardToken _resolve(Token t) => _ResolvedCardToken(
        headerBg: headerBg ?? const Color(0x00000005),
        headerFontSize: headerFontSize ?? t.fontSizeLG,
        headerFontSizeSM: headerFontSizeSM ?? t.fontSize,
        headerHeight: headerHeight ?? 56,
        headerHeightSM: headerHeightSM ?? 38,
        headerPadding: headerPadding ?? t.sizeLG,
        headerPaddingSM: headerPaddingSM ?? t.sizeSM,
        bodyPadding: bodyPadding ?? EdgeInsets.all(t.sizeLG),
        bodyPaddingSM: bodyPaddingSM ?? EdgeInsets.all(t.sizeSM),
        actionsBg: actionsBg ?? t.colorBgContainer,
        actionsLiMargin: actionsLiMargin ?? t.sizeSM,
        extraColor: extraColor ?? t.colorText,
        borderRadius: borderRadius ?? t.borderRadiusLG,
      );
}

/// Fully resolved [CardToken] — every value non-null.
@immutable
class _ResolvedCardToken {
  const _ResolvedCardToken({
    required this.headerBg,
    required this.headerFontSize,
    required this.headerFontSizeSM,
    required this.headerHeight,
    required this.headerHeightSM,
    required this.headerPadding,
    required this.headerPaddingSM,
    required this.bodyPadding,
    required this.bodyPaddingSM,
    required this.actionsBg,
    required this.actionsLiMargin,
    required this.extraColor,
    required this.borderRadius,
  });

  final Color headerBg;
  final double headerFontSize;
  final double headerFontSizeSM;
  final double headerHeight;
  final double headerHeightSM;
  final double headerPadding;
  final double headerPaddingSM;
  final EdgeInsets bodyPadding;
  final EdgeInsets bodyPaddingSM;
  final Color actionsBg;
  final double actionsLiMargin;
  final Color extraColor;
  final double borderRadius;
}

/// A tab in a [Card]'s [Card.tabList] — a key and a bar label.
@immutable
class CardTab {
  /// Creates a [CardTab].
  const CardTab({
    required this.key,
    required this.label,
    this.disabled = false,
  });

  /// Unique identity of the tab.
  final String key;

  /// The bar label.
  final Widget label;

  /// Greys the tab out and blocks selecting it.
  final bool disabled;
}

/// A content container.
///
/// ```dart
/// Card(
///   title: const Text('Card title'),
///   extra: Button(type: ButtonVariant.text, onPressed: () {}, child: const Text('More')),
///   child: const Text('Card content'),
/// )
/// ```
///
/// [cover] sits above the header, [actions] form a divided bar along the
/// bottom, and [hoverable] lifts the card on pointer hover. [variant] toggles
/// the border and [type] switches to a nested inner style. Supply [tabList] to
/// render navigation tabs in the header, driven by [activeTabKey] /
/// [onTabChange].
class Card extends StatefulWidget {
  /// Creates a [Card].
  const Card({
    super.key,
    this.title,
    this.extra,
    this.child,
    this.cover,
    this.actions,
    this.hoverable = false,
    this.loading = false,
    this.variant = CardVariant.outlined,
    this.type = CardType.outer,
    this.size = SoftSize.middle,
    this.tabList,
    this.activeTabKey,
    this.defaultActiveTabKey,
    this.onTabChange,
    this.tabBarExtraContent,
    this.gradient,
    this.token,
  });

  /// Optional background gradient override.
  final Gradient? gradient;

  /// Header title.
  final Widget? title;

  /// Header content pinned to the far end (next to the title).
  final Widget? extra;

  /// The body content.
  final Widget? child;

  /// A widget (usually an image) shown above the header, edge to edge.
  final Widget? cover;

  /// A divided bar of actions along the bottom.
  final List<Widget>? actions;

  /// Lifts the card with a shadow while the pointer is over it.
  final bool hoverable;

  /// Replaces the body with a shimmering placeholder.
  final bool loading;

  /// Whether the card draws a border.
  final CardVariant variant;

  /// Standalone or nested-inner style.
  final CardType type;

  /// `small` tightens the header and body padding; `middle`/`large` are the
  /// default size.
  final SoftSize size;

  /// Navigation tabs rendered in the header.
  final List<CardTab>? tabList;

  /// The active tab key (controlled). Null makes [tabList] uncontrolled.
  final String? activeTabKey;

  /// Initial active tab for an uncontrolled [tabList].
  final String? defaultActiveTabKey;

  /// Called with the new key when the active [tabList] tab changes.
  final ValueChanged<String>? onTabChange;

  /// Extra content pinned to the ends of the [tabList] bar.
  final TabBarExtra? tabBarExtraContent;

  /// Per-instance token overrides.
  final CardToken? token;

  @override
  State<Card> createState() => _CardState();
}

class _CardState extends State<Card> {
  bool _hover = false;

  bool get _small => widget.size == SoftSize.small;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<CardToken>(context) ??
            const CardToken())
        ._resolve(t);

    final radius = BorderRadius.circular(r.borderRadius);
    final hasHeader =
        widget.title != null || widget.extra != null || widget.tabList != null;

    final children = <Widget>[];
    if (widget.cover != null) {
      children.add(
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: radius.topLeft,
            topRight: radius.topRight,
          ),
          child: widget.cover!,
        ),
      );
    }
    if (hasHeader) children.add(_buildHeader(t, r));
    children.add(_buildBody(t, r));
    if (widget.actions != null && widget.actions!.isNotEmpty) {
      children.add(_buildActions(t, r));
    }

    final elevated = widget.hoverable && _hover;
    Widget card = AnimatedContainer(
      duration: t.motionDurationMid,
      curve: t.motionEaseInOut,
      decoration: BoxDecoration(
        color: widget.gradient == null ? t.colorBgContainer : null,
        gradient: widget.gradient,
        borderRadius: radius,
        border:
            widget.variant == CardVariant.outlined && widget.gradient == null
                ? Border.all(color: t.colorBorderSecondary, width: t.lineWidth)
                : null,
        boxShadow: elevated ? t.boxShadow : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );

    if (widget.hoverable) {
      card = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: card,
      );
    }
    return card;
  }

  Widget _buildHeader(Token t, _ResolvedCardToken r) {
    final inner = widget.type == CardType.inner;
    final pad = _small ? r.headerPaddingSM : r.headerPadding;
    final minH = _small ? r.headerHeightSM : r.headerHeight;
    final fontSize = _small ? r.headerFontSizeSM : r.headerFontSize;
    final hasTabs = widget.tabList != null;

    final title = widget.title == null
        ? null
        : DefaultTextStyle(
            style: TextStyle(
              color: t.colorText,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            child: widget.title!,
          );

    final extra = widget.extra == null
        ? null
        : DefaultTextStyle(
            style: TextStyle(color: r.extraColor, fontSize: t.fontSize),
            child: widget.extra!,
          );

    // The head wrapper: the title on the leading side, the extra pushed to the
    // far end (`margin-inline-start: auto` ) — so a lone extra still
    // sits on the right.
    Widget wrapper(Widget? trailing, {required bool constrained}) {
      final row = Padding(
        padding: EdgeInsets.symmetric(horizontal: pad),
        child: Row(
          children: [
            if (title != null) Expanded(child: title) else const Spacer(),
            if (trailing != null) trailing,
          ],
        ),
      );
      return constrained
          ? ConstrainedBox(
              constraints: BoxConstraints(minHeight: minH),
              child: row,
            )
          : Padding(
              padding: EdgeInsets.only(top: _small ? t.sizeXS : t.sizeSM),
              child: row,
            );
    }

    final Widget header;
    if (hasTabs) {
      // With no title, the tabs and the extra share one row — the extra rides
      // along as the bar's trailing content. With a title, the title/extra
      // wrapper sits above the tabs (the head layout).
      final withTitle = title != null;
      var barExtra = widget.tabBarExtraContent;
      if (!withTitle && extra != null) {
        barExtra =
            TabBarExtra(left: barExtra?.left, right: barExtra?.right ?? extra);
      }
      final tabsBar = Padding(
        padding: EdgeInsets.symmetric(horizontal: pad),
        child: Tabs(
          items: [
            for (final tab in widget.tabList!)
              TabItem(key: tab.key, label: tab.label, disabled: tab.disabled),
          ],
          activeKey: widget.activeTabKey,
          defaultActiveKey: widget.defaultActiveTabKey,
          onChange: widget.onTabChange,
          size: _small ? SoftSize.small : SoftSize.middle,
          tabBarExtraContent: barExtra,
        ),
      );
      header = withTitle
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                wrapper(extra, constrained: false),
                const SizedBox(height: 10),
                tabsBar,
              ],
            )
          : tabsBar;
    } else {
      header = wrapper(extra, constrained: true);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: inner ? t.colorFillQuaternary : r.headerBg,
        // With a tab list, the tabs carry their own base line — no extra
        // divider under the header. Otherwise the kit draws the head border with
        // colorBorderSecondary, matching the card's own edge.
        border: Border(
          bottom: BorderSide(
            color: t.colorBorderSecondary,
            width: t.lineWidth,
          ),
        ),
      ),
      child: header,
    );
  }

  Widget _buildBody(Token t, _ResolvedCardToken r) {
    final padding = _small ? r.bodyPaddingSM : r.bodyPadding;
    final content = widget.loading
        ? _Skeleton(t)
        : (widget.child ?? const SizedBox.shrink());
    return Padding(
      padding: padding,
      child: DefaultTextStyle(
        style: TextStyle(
          color: t.colorText,
          fontSize: t.fontSize,
          height: t.lineHeight,
          // Split the line's extra leading evenly above and below the glyphs,
          // so a single line sits vertically centred in the padded body — as
          // rather than riding the top of its box.
          leadingDistribution: TextLeadingDistribution.even,
        ),
        child: content,
      ),
    );
  }

  Widget _buildActions(Token t, _ResolvedCardToken r) {
    final items = widget.actions!;
    final row = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        row.add(
          Container(
            width: t.lineWidth,
            height: t.fontSize * 1.4,
            color: t.colorBorderSecondary,
          ),
        );
      }
      row.add(
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: r.actionsLiMargin),
            child: Center(
              child: DefaultTextStyle(
                style: TextStyle(
                    color: t.colorTextSecondary, fontSize: t.fontSize),
                child: IconTheme.merge(
                  data: IconThemeData(color: t.colorTextSecondary),
                  child: items[i],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: r.actionsBg,
        border: Border(
          top: BorderSide(color: t.colorBorderSecondary, width: t.lineWidth),
        ),
      ),
      child: IntrinsicHeight(
        child:
            Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: row),
      ),
    );
  }
}

/// Presentational metadata for a [Card].
///
/// ```dart
/// Card(child: CardMeta(
///   avatar: CircleAvatar(...),
///   title: const Text('Card title'),
///   description: const Text('This is the description'),
/// ))
/// ```
class CardMeta extends StatelessWidget {
  /// Creates a [CardMeta].
  const CardMeta({super.key, this.avatar, this.title, this.description});

  /// Leading avatar.
  final Widget? avatar;

  /// Bold title line.
  final Widget? title;

  /// Muted description below the title.
  final Widget? description;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final text = <Widget>[];
    if (title != null) {
      text.add(
        DefaultTextStyle(
          style: TextStyle(
            color: t.colorText,
            fontSize: t.fontSizeLG,
            fontWeight: FontWeight.w600,
            // Pin the line box and centre the glyphs in it. Left to the font's
            // metrics the title's box is taller than its ink and lopsided, so it
            // never lines up with the avatar next to it.
            height: t.lineHeight,
            leadingDistribution: TextLeadingDistribution.even,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          child: title!,
        ),
      );
    }
    if (description != null) {
      text.add(
        Padding(
          padding: EdgeInsets.only(top: title != null ? t.sizeXS : 0),
          child: DefaultTextStyle(
            style: TextStyle(
              color: t.colorTextSecondary,
              fontSize: t.fontSize,
              height: t.lineHeight,
              leadingDistribution: TextLeadingDistribution.even,
            ),
            child: description!,
          ),
        ),
      );
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: text,
    );

    if (avatar == null) return column;

    // Height of the title's first line — what the avatar has to line up with.
    final titleLine =
        (title != null ? t.fontSizeLG : t.fontSize) * t.lineHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // An avatar shorter than the title line (a status icon, say) centres on
        // that line instead of clinging to the top of its box; a taller one
        // (a real avatar) keeps its top edge, and the band grows
        // with it.
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: titleLine),
          child: Center(widthFactor: 1, child: avatar!),
        ),
        SizedBox(width: t.size),
        Expanded(child: column),
      ],
    );
  }
}

/// A shimmering placeholder shown in place of a loading card's body.
class _Skeleton extends StatelessWidget {
  const _Skeleton(this.t);

  final Token t;

  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widthFactor,
          child: Container(
            height: t.fontSize,
            decoration: BoxDecoration(
              color: t.colorFillSecondary,
              borderRadius: BorderRadius.circular(t.borderRadiusSM),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        bar(0.6),
        SizedBox(height: t.size),
        bar(1),
        SizedBox(height: t.sizeSM),
        bar(1),
        SizedBox(height: t.sizeSM),
        bar(0.4),
      ],
    );
  }
}
