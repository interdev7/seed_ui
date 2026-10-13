import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';

/// Which way a [Divider] runs.
enum DividerOrientation {
  /// A line across, between blocks of content.
  horizontal,

  /// A short upright line, between words or buttons in a row.
  vertical,
}

/// How a [Divider]'s line is drawn.
enum DividerVariant {
  /// One unbroken line.
  solid,

  /// Short dashes.
  dashed,

  /// Round dots.
  dotted,
}

/// Where a horizontal [Divider]'s title sits along the line.
///
/// `start` and `end` follow the reading direction: `start` is the left in a
/// left-to-right language and the right in a right-to-left one.
enum DividerTitlePlacement {
  /// Near the start, the line running on past it.
  start,

  /// In the middle.
  center,

  /// Near the end.
  end,
}

/// Per-component design tokens for [Divider].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(divider: DividerToken(...)))`, or per instance via
/// [Divider.token].
@immutable
class DividerToken {
  /// Creates a [DividerToken].
  const DividerToken({
    this.lineColor,
    this.lineWidth,
    this.marginSM,
    this.margin,
    this.marginLG,
    this.verticalMargin,
    this.verticalHeight,
    this.titleGap,
    this.titleColor,
    this.titleFontSize,
    this.titleFontWeight,
    this.plainTitleFontSize,
  });

  /// The line's colour.
  final Color? lineColor;

  /// The line's thickness.
  final double? lineWidth;

  /// Space above and below a small horizontal divider.
  final double? marginSM;

  /// Space above and below a middle horizontal divider.
  final double? margin;

  /// Space above and below a large horizontal divider.
  final double? marginLG;

  /// Space either side of a vertical divider.
  final double? verticalMargin;

  /// How tall a vertical divider stands.
  final double? verticalHeight;

  /// Space between a title and the line either side of it.
  final double? titleGap;

  /// The title's colour.
  final Color? titleColor;

  /// The title's size.
  final double? titleFontSize;

  /// The title's weight.
  final FontWeight? titleFontWeight;

  /// The title's size when the divider is `plain`.
  final double? plainTitleFontSize;

  _ResolvedDividerToken _resolve(Token t) => _ResolvedDividerToken(
        lineColor: lineColor ?? t.colorSplit,
        lineWidth: lineWidth ?? t.lineWidth,
        marginSM: marginSM ?? t.sizeXS,
        margin: margin ?? t.sizeLG,
        marginLG: marginLG ?? t.sizeXL,
        verticalMargin: verticalMargin ?? t.sizeXS,
        verticalHeight: verticalHeight ?? t.fontSize * 0.9,
        titleGap: titleGap ?? t.size,
        titleColor: titleColor ?? t.colorText,
        titleFontSize: titleFontSize ?? t.fontSizeLG,
        titleFontWeight: titleFontWeight ?? FontWeight.w500,
        plainTitleFontSize: plainTitleFontSize ?? t.fontSize,
      );

  /// This one with [other]'s fields laid over it, one field at a time.
  DividerToken merge(DividerToken other) => DividerToken(
        lineColor: other.lineColor ?? lineColor,
        lineWidth: other.lineWidth ?? lineWidth,
        marginSM: other.marginSM ?? marginSM,
        margin: other.margin ?? margin,
        marginLG: other.marginLG ?? marginLG,
        verticalMargin: other.verticalMargin ?? verticalMargin,
        verticalHeight: other.verticalHeight ?? verticalHeight,
        titleGap: other.titleGap ?? titleGap,
        titleColor: other.titleColor ?? titleColor,
        titleFontSize: other.titleFontSize ?? titleFontSize,
        titleFontWeight: other.titleFontWeight ?? titleFontWeight,
        plainTitleFontSize: other.plainTitleFontSize ?? plainTitleFontSize,
      );
}

@immutable
class _ResolvedDividerToken {
  const _ResolvedDividerToken({
    required this.lineColor,
    required this.lineWidth,
    required this.marginSM,
    required this.margin,
    required this.marginLG,
    required this.verticalMargin,
    required this.verticalHeight,
    required this.titleGap,
    required this.titleColor,
    required this.titleFontSize,
    required this.titleFontWeight,
    required this.plainTitleFontSize,
  });

  final Color lineColor;
  final double lineWidth;
  final double marginSM;
  final double margin;
  final double marginLG;
  final double verticalMargin;
  final double verticalHeight;
  final double titleGap;
  final Color titleColor;
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final double plainTitleFontSize;
}

/// Defaults for every [Divider] under a `ConfigProvider`.
@immutable
class DividerDefaults {
  /// Creates a [DividerDefaults].
  const DividerDefaults({
    this.variant,
    this.size,
    this.titlePlacement,
    this.plain,
  });

  /// How lines are drawn.
  final DividerVariant? variant;

  /// How much room horizontal dividers leave around themselves.
  final SoftSize? size;

  /// Where titles sit.
  final DividerTitlePlacement? titlePlacement;

  /// Whether titles are set as body text.
  final bool? plain;

  /// This one with [other]'s fields laid over it, one field at a time.
  DividerDefaults merge(DividerDefaults other) => DividerDefaults(
        variant: other.variant ?? variant,
        size: other.size ?? size,
        titlePlacement: other.titlePlacement ?? titlePlacement,
        plain: other.plain ?? plain,
      );
}

/// A line that separates content: blocks of a page, or words and buttons in
/// a row.
///
/// Horizontal by default, filling the width it is given, with room above and
/// below. A [child] puts a title in the line. A vertical one stands as tall as
/// a line of text, for a row such as `Edit | Share | Delete`.
///
/// ```dart
/// const Divider(child: Text('Details'))
/// ```
///
/// It is decoration: a screen reader hears its title, if it has one, and
/// nothing for the line.
class Divider extends StatelessWidget {
  /// Creates a [Divider].
  const Divider({
    super.key,
    this.child,
    this.orientation = DividerOrientation.horizontal,
    this.variant,
    this.size,
    this.titlePlacement,
    this.titleMargin,
    this.plain,
    this.token,
  });

  /// The title set in a horizontal line. Ignored by a vertical one.
  final Widget? child;

  /// Which way the line runs.
  final DividerOrientation orientation;

  /// How the line is drawn. Defaults to [DividerVariant.solid].
  final DividerVariant? variant;

  /// How much room a horizontal divider leaves above and below itself:
  /// [SoftSize.small], [SoftSize.middle] (the default) or [SoftSize.large].
  final SoftSize? size;

  /// Where the title sits along the line. Defaults to
  /// [DividerTitlePlacement.center].
  final DividerTitlePlacement? titlePlacement;

  /// How far a [DividerTitlePlacement.start] or [DividerTitlePlacement.end]
  /// title stands from its edge. Null leaves a twentieth of the line there.
  /// Ignored for a centred title.
  final double? titleMargin;

  /// Whether the title is set as body text rather than as a heading.
  /// Defaults to no.
  final bool? plain;

  /// Per-instance token overrides.
  final DividerToken? token;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (token ??
            ConfigProvider.componentOf<DividerToken>(context) ??
            const DividerToken())
        ._resolve(t);
    final defaults = ConfigProvider.defaultsOf<DividerDefaults>(context);
    final effectiveVariant =
        variant ?? defaults?.variant ?? DividerVariant.solid;

    if (orientation == DividerOrientation.vertical) {
      return ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: r.verticalMargin),
          child: _Line(
            axis: Axis.vertical,
            variant: effectiveVariant,
            color: r.lineColor,
            thickness: r.lineWidth,
            length: r.verticalHeight,
          ),
        ),
      );
    }

    final effectiveSize = size ??
        defaults?.size ??
        ConfigProvider.componentSizeOf(context) ??
        SoftSize.middle;
    final margin = switch (effectiveSize) {
      SoftSize.small => r.marginSM,
      SoftSize.middle => r.margin,
      SoftSize.large => r.marginLG,
    };
    Widget line() => _Line(
          axis: Axis.horizontal,
          variant: effectiveVariant,
          color: r.lineColor,
          thickness: r.lineWidth,
        );

    final title = child;
    if (title == null) {
      return ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: margin),
          child: SizedBox(width: double.infinity, child: line()),
        ),
      );
    }

    final isPlain = plain ?? defaults?.plain ?? false;
    final placement = titlePlacement ??
        defaults?.titlePlacement ??
        DividerTitlePlacement.center;
    final styled = DefaultTextStyle.merge(
      style: TextStyle(
        color: r.titleColor,
        fontSize: isPlain ? r.plainTitleFontSize : r.titleFontSize,
        fontWeight: isPlain ? FontWeight.normal : r.titleFontWeight,
        fontFamily: t.fontFamily,
        fontFamilyFallback: t.fontFamilyFallback,
        decoration: TextDecoration.none,
      ),
      textAlign: TextAlign.center,
      child: title,
    );

    // A title at an edge keeps a fixed run of line before it when one is
    // named, and a twentieth of the line otherwise; the rest goes after.
    Widget run({int flex = 1}) => Expanded(flex: flex, child: line());
    final fixed = titleMargin;
    final Widget edge =
        fixed != null ? SizedBox(width: fixed, child: line()) : run();
    final rest = run(flex: fixed != null ? 1 : 19);
    final (leading, trailing) = switch (placement) {
      DividerTitlePlacement.center => (run(), run()),
      DividerTitlePlacement.start => (edge, rest),
      DividerTitlePlacement.end => (rest, edge),
    };

    return Padding(
      padding: EdgeInsets.symmetric(vertical: margin),
      child: Row(
        children: [
          // The runs of line carry no semantics of their own: a reader meets
          // the title and nothing else.
          leading,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: r.titleGap),
            child: styled,
          ),
          trailing,
        ],
      ),
    );
  }
}

/// One run of a divider's line: solid, dashed or dotted.
class _Line extends StatelessWidget {
  const _Line({
    required this.axis,
    required this.variant,
    required this.color,
    required this.thickness,
    this.length,
  });

  final Axis axis;
  final DividerVariant variant;
  final Color color;
  final double thickness;

  /// How long a vertical line is; a horizontal one takes the width it is
  /// given.
  final double? length;

  @override
  Widget build(BuildContext context) {
    final horizontal = axis == Axis.horizontal;
    return SizedBox(
      width: horizontal ? double.infinity : thickness,
      height: horizontal ? thickness : length,
      child: variant == DividerVariant.solid
          ? ColoredBox(color: color)
          : CustomPaint(
              painter: _BrokenLinePainter(
                color: color,
                axis: axis,
                dotted: variant == DividerVariant.dotted,
              ),
            ),
    );
  }
}

/// Draws a dashed or dotted line along the long side of its box, the
/// pieces measured from the line's own thickness so a thicker line has
/// longer dashes and wider gaps.
class _BrokenLinePainter extends CustomPainter {
  _BrokenLinePainter({
    required this.color,
    required this.axis,
    required this.dotted,
  });

  final Color color;
  final Axis axis;
  final bool dotted;

  @override
  void paint(Canvas canvas, Size size) {
    final horizontal = axis == Axis.horizontal;
    final thickness = horizontal ? size.height : size.width;
    final length = horizontal ? size.width : size.height;
    if (thickness <= 0 || length <= 0) return;
    final paint = Paint()..color = color;
    // Dots are round and a thickness apart; dashes are four long with three
    // between, the proportions a browser draws a dashed border in.
    final piece = dotted ? thickness : thickness * 4;
    final gap = dotted ? thickness * 2 : thickness * 3;
    for (var at = 0.0; at < length; at += piece + gap) {
      final end = (at + piece).clamp(0.0, length);
      final rect = horizontal
          ? Rect.fromLTRB(at, 0, end, thickness)
          : Rect.fromLTRB(0, at, thickness, end);
      if (dotted) {
        canvas.drawOval(rect, paint);
      } else {
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BrokenLinePainter old) =>
      old.color != color || old.axis != axis || old.dotted != dotted;
}
