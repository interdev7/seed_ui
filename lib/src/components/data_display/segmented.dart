import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';

/// Layout axis for a [Segmented].
enum SegmentedDirection {
  /// Options run left to right.
  horizontal,

  /// Options stack top to bottom.
  vertical
}

/// One option in a [Segmented].
@immutable
class SegmentedOption<T> {
  /// Creates a [SegmentedOption].
  const SegmentedOption({
    required this.value,
    this.label,
    this.icon,
    this.child,
    this.disabled = false,
  }) : assert(
          label != null || icon != null || child != null,
          'a segment needs a label, an icon, or a custom child',
        );

  /// The value reported when this segment is selected.
  final T value;

  /// Text shown in the segment.
  final String? label;

  /// Icon shown before the label, or alone.
  final Widget? icon;

  /// Custom content, replacing [label] and [icon] entirely.
  ///
  /// It receives no automatic colouring, so style it yourself if it should
  /// dim when unselected.
  final Widget? child;

  /// Whether this individual segment is unselectable.
  final bool disabled;
}

/// Per-component design tokens for [Segmented].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(segmented: SegmentedToken(...)))`,
/// or per instance via [Segmented.token].
@immutable
class SegmentedToken {
  /// Creates a [SegmentedToken].
  const SegmentedToken({
    this.trackBg,
    this.trackPadding,
    this.itemColor,
    this.itemHoverColor,
    this.itemHoverBg,
    this.itemSelectedBg,
    this.itemSelectedColor,
    this.borderRadius,
    this.borderRadiusSM,
    this.borderRadiusLG,
  });

  /// Track background color (`trackBg`).
  final Color? trackBg;

  /// Track inner padding (`trackPadding`).
  final double? trackPadding;

  /// Unselected item text color (`itemColor`).
  final Color? itemColor;

  /// Item hover text color (`itemHoverColor`).
  final Color? itemHoverColor;

  /// Fill behind an unselected segment while the pointer is over it
  /// (`itemHoverBg`).
  final Color? itemHoverBg;

  /// Selected thumb background color (`itemSelectedBg`).
  final Color? itemSelectedBg;

  /// Selected item text color (`itemSelectedColor`).
  final Color? itemSelectedColor;

  /// Corner radius for standard control (`borderRadius`).
  final double? borderRadius;

  /// Corner radius for small control (`borderRadiusSM`).
  final double? borderRadiusSM;

  /// Corner radius for large control (`borderRadiusLG`).
  final double? borderRadiusLG;

  _ResolvedSegmentedToken _resolve(Token t) => _ResolvedSegmentedToken(
        // The layout background, not a translucent fill. A fill lightens the
        // track in a dark theme, which leaves the elevated thumb *darker* than
        // the groove it sits in — the elevation reads inverted, and the only
        // thing separating the two is the shadow.
        trackBg: trackBg ?? t.colorBgLayout,
        trackPadding: trackPadding ?? t.sizeXXS / 2,
        itemColor: itemColor ?? t.colorTextSecondary,
        itemHoverColor: itemHoverColor ?? t.colorText,
        itemHoverBg: itemHoverBg ?? t.colorFillSecondary,
        itemSelectedBg: itemSelectedBg ?? t.colorBgElevated,
        itemSelectedColor: itemSelectedColor ?? t.colorText,
        borderRadius: borderRadius ?? t.borderRadius,
        borderRadiusSM: borderRadiusSM ?? t.borderRadiusSM,
        borderRadiusLG: borderRadiusLG ?? t.borderRadiusLG,
      );
}

@immutable
class _ResolvedSegmentedToken {
  const _ResolvedSegmentedToken({
    required this.trackBg,
    required this.trackPadding,
    required this.itemColor,
    required this.itemHoverColor,
    required this.itemHoverBg,
    required this.itemSelectedBg,
    required this.itemSelectedColor,
    required this.borderRadius,
    required this.borderRadiusSM,
    required this.borderRadiusLG,
  });

  final Color trackBg;
  final double trackPadding;
  final Color itemColor;
  final Color itemHoverColor;
  final Color itemHoverBg;
  final Color itemSelectedBg;
  final Color itemSelectedColor;
  final double borderRadius;
  final double borderRadiusSM;
  final double borderRadiusLG;
}

/// Defaults for every [Segmented] under a `ConfigProvider`.
///
/// House style for segmented controls.
@immutable
class SegmentedDefaults {
  /// Creates a [SegmentedDefaults].
  const SegmentedDefaults({
    this.direction,
    this.size,
    this.disabled,
  });

  /// Which way the segments run.
  final Axis? direction;

  /// Which control height a [Segmented] takes, unless it names one.
  ///
  /// Nearer than `ConfigProvider.componentSize`, so this wins where both
  /// are set: small buttons on an otherwise normal screen.
  final SoftSize? size;

  /// Whether a [Segmented] is disabled, unless it says otherwise.
  ///
  /// Nearer than `ConfigProvider.componentDisabled`, and beaten in turn by
  /// the widget's own word.
  final bool? disabled;
}

/// A single-select control laid out as a strip of segments, with a thumb that
/// slides to the chosen one — for switching between a few mutually exclusive
/// options in place.
///
/// ```dart
/// Segmented<String>(
///   value: _view,
///   options: const [
///     SegmentedOption(value: 'list', label: 'List'),
///     SegmentedOption(value: 'grid', label: 'Grid'),
///   ],
///   onChanged: (v) => setState(() => _view = v),
/// )
/// ```
///
/// Segments size to their content, so long labels are never clipped. Set
/// [block] to stretch them to fill the width equally, or [direction] to stack
/// them vertically. For more than a handful of options, or navigation between
/// views, prefer tabs.
class Segmented<T> extends StatefulWidget {
  /// Creates a [Segmented].
  const Segmented({
    super.key,
    required this.value,
    required this.options,
    this.onChanged,
    this.size,
    this.direction,
    this.block = false,
    this.disabled,
    this.trackColor,
    this.thumbColor,
    this.token,
  });

  /// The selected value. Must match one option's value.
  final T value;

  /// The segments, in order.
  final List<SegmentedOption<T>> options;

  /// Called with the new value when a segment is chosen. Null disables the
  /// whole control.
  final ValueChanged<T>? onChanged;

  /// Which height preset to use.
  final SoftSize? size;

  /// Whether the segments run in a row or a column.
  final Axis? direction;

  /// Stretch the segments to fill the available space equally.
  final bool block;

  /// Greys the whole control out and blocks selection.
  final bool? disabled;

  /// Overrides the track (background) colour.
  final Color? trackColor;

  /// Overrides the sliding thumb's colour.
  final Color? thumbColor;

  /// Per-instance token overrides.
  final SegmentedToken? token;

  @override
  State<Segmented<T>> createState() => _SoftSegmentedState<T>();
}

class _SoftSegmentedState<T> extends State<Segmented<T>> {
  /// The defaults set for this component in the subtree, if any.
  SegmentedDefaults? get _defaults =>
      ConfigProvider.defaultsOf<SegmentedDefaults>(context);

  /// This widget's word, then the subtree's, then the kit's.
  Axis get _direction =>
      widget.direction ?? _defaults?.direction ?? Axis.horizontal;

  /// Whether this control is disabled: its own word, else the one set
  /// for the subtree, else no.
  bool get _disabled =>
      widget.disabled ??
      _defaults?.disabled ??
      ConfigProvider.componentDisabledOf(context) ??
      false;

  /// The size in force: this widget's own, else the one set for the
  /// subtree, else the standard preset.
  SoftSize get _size =>
      widget.size ??
      _defaults?.size ??
      ConfigProvider.componentSizeOf(context) ??
      SoftSize.middle;

  final GlobalKey _stackKey = GlobalKey();
  final Map<int, GlobalKey> _segmentKeys = {};
  Rect? _thumbRect;
  int? _hoveredIndex;

  bool get _enabled => !_disabled && widget.onChanged != null;
  bool get _vertical => _direction == Axis.vertical;

  int get _selectedIndex {
    final i = widget.options.indexWhere((o) => o.value == widget.value);
    return i < 0 ? 0 : i;
  }

  GlobalKey _keyFor(int i) => _segmentKeys.putIfAbsent(i, GlobalKey.new);

  double _height(Token token) => switch (_size) {
        SoftSize.small => token.controlHeightSM,
        SoftSize.middle => token.controlHeight,
        SoftSize.large => token.controlHeightLG,
      };

  double _radius(_ResolvedSegmentedToken r) => switch (_size) {
        SoftSize.small => r.borderRadiusSM,
        SoftSize.middle => r.borderRadius,
        SoftSize.large => r.borderRadiusLG,
      };

  double _fontSize(Token token) => switch (_size) {
        SoftSize.small => token.fontSizeSM,
        SoftSize.middle => token.fontSize,
        SoftSize.large => token.fontSizeLG,
      };

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<SegmentedToken>(context) ??
            const SegmentedToken())
        ._resolve(token);
    // Positions depend on the laid-out sizes, so measure after the frame and
    // let AnimatedPositioned slide the thumb to the selected segment's rect.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

    final segmentWidgets = [
      for (var i = 0; i < widget.options.length; i++)
        _buildSegment(token, r, i, widget.options[i], i == _selectedIndex),
    ];

    final rect = _thumbRect;
    final control = Container(
      padding: EdgeInsets.all(r.trackPadding),
      decoration: BoxDecoration(
        color: widget.trackColor ?? r.trackBg,
        borderRadius: BorderRadius.circular(_radius(r)),
      ),
      child: _maybeScrollable(
        Stack(
          key: _stackKey,
          children: [
            // The thumb slides behind the labels once measured. It is positioned
            // in the Stack's own coordinates, so the rect is measured relative to
            // the Stack — not the padded Container.
            if (rect != null)
              AnimatedPositioned(
                duration: token.motionDurationMid,
                curve: token.motionEaseInOut,
                left: rect.left,
                top: rect.top,
                width: rect.width,
                height: rect.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _enabled
                        ? (widget.thumbColor ?? r.itemSelectedBg)
                        : (widget.thumbColor ?? r.itemSelectedBg)
                            .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(_radius(r)),
                    boxShadow: _enabled ? token.boxShadowSecondary : null,
                  ),
                ),
              ),
            _strip(segmentWidgets),
          ],
        ),
      ),
    );

    if (block) return control;

    // the segmented control is `inline-flex`: it is as wide as its
    // options and no wider. A parent that hands down a tight width — a stretch
    // Column, a wide page — would otherwise blow the track across the screen.
    // `block: true` is how you ask for the full width.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      // IntrinsicWidth asks the strip how wide it wants to be and then honours
      // the incoming constraint: room enough, and the control is exactly its
      // options wide; not enough, and it is clamped, which is what gives the
      // scroll view below something to scroll inside.
      child: _vertical ? control : IntrinsicWidth(child: control),
    );
  }

  /// Lets a horizontal run scroll rather than overflow.
  ///
  /// A content-sized control cannot always have the width it asks for — a
  /// phone is narrower than six segments. Overflowing paints the debug stripes
  /// and hides the segments past the edge, so the run scrolls instead. With
  /// room to spare the viewport is exactly the content's width and there is
  /// nothing to scroll, so this costs the common case nothing.
  Widget _maybeScrollable(Widget child) {
    if (_vertical || block) return child;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // The thumb is measured against the strip's own coordinates, so it
      // travels with the content instead of floating over the viewport.
      physics: const ClampingScrollPhysics(),
      child: child,
    );
  }

  /// Lays the segments out along the chosen axis. Equal-size layouts wrap the
  /// row/column in an Intrinsic box — the safe place for it, unlike around the
  /// whole Stack, which trips a rendering assertion.
  Widget _strip(List<Widget> segments) {
    if (_vertical) {
      // A column of equal-width segments; IntrinsicWidth bounds the cross axis
      // so `stretch` is legal.
      return IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: segments,
        ),
      );
    }
    if (block) {
      // Equal-width segments filling the width. IntrinsicHeight keeps them all
      // the height of the tallest, which matters when one carries an icon and
      // another does not.
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: segments,
        ),
      );
    }
    // Content-sized single-line segments are all one control-height tall, so
    // they line up without any Intrinsic box.
    return Row(mainAxisSize: MainAxisSize.min, children: segments);
  }

  bool get block => widget.block;

  void _measure() {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final segBox = _segmentKeys[_selectedIndex]
        ?.currentContext
        ?.findRenderObject() as RenderBox?;
    if (stackBox == null || segBox == null || !segBox.hasSize) return;
    final origin = segBox.localToGlobal(Offset.zero, ancestor: stackBox);
    final rect = origin & segBox.size;
    if (rect != _thumbRect && mounted) setState(() => _thumbRect = rect);
  }

  Widget _buildSegment(
    Token token,
    _ResolvedSegmentedToken r,
    int index,
    SegmentedOption<T> option,
    bool selected,
  ) {
    final enabled = _enabled && !option.disabled;
    final color = !enabled
        ? token.colorTextQuaternary
        : selected
            ? r.itemSelectedColor
            : r.itemColor;
    final hovered = _hoveredIndex == index && enabled && !selected;

    final label = option.label == null
        ? null
        : Text(
            option.label!,
            textAlign: TextAlign.center,
            // A segment is one line, always. Content-sized ones are as wide as
            // their label and never need more; a block one shares the width
            // equally and cuts what will not fit, which keeps the run one
            // control tall however long a label is. Wrapping instead made the
            // whole strip grow a second line to suit its longest word.
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: _fontSize(token),
              fontFamily: token.fontFamily,
              fontFamilyFallback: token.fontFamilyFallback,
              height: 1.2,
              decoration: TextDecoration.none,
            ),
          );

    final content = option.child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (option.icon != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: color, size: _fontSize(token)),
                child: option.icon!,
              ),
              if (label != null) SizedBox(width: token.sizeXXS),
            ],
            if (label != null)
              // In block mode the row is width-bounded, and Flexible is what
              // lets the label shrink below its natural width so the ellipsis
              // has somewhere to happen. Elsewhere the row is unbounded and
              // Flexible would be illegal, so the label goes in directly.
              block ? Flexible(child: label) : label,
          ],
        );

    final segment = KeyedSubtree(
      key: _keyFor(index),
      child: MouseRegion(
        cursor: enabled && !selected
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: enabled ? (_) => _setHovered(index) : null,
        onExit: enabled ? (_) => _setHovered(null) : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled && !selected
              ? () => widget.onChanged!(option.value)
              : null,
          child: AnimatedContainer(
            duration: token.motionDurationFast,
            curve: token.motionEaseInOut,
            constraints: BoxConstraints(minHeight: _height(token)),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(
              horizontal: token.sizeSM,
              vertical: token.sizeXXS / 2,
            ),
            decoration: BoxDecoration(
              // A faint highlight while hovering an unselected segment.
              color: hovered ? r.itemHoverBg : null,
              borderRadius: BorderRadius.circular(_radius(r)),
            ),
            child: content,
          ),
        ),
      ),
    );

    // Block mode stretches each segment to an equal share of the main axis.
    if (!block) return segment;
    return Expanded(child: segment);
  }

  void _setHovered(int? index) {
    if (_hoveredIndex != index && mounted) {
      setState(() => _hoveredIndex = index);
    }
  }
}
