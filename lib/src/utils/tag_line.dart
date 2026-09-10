import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A line of tags that keeps to one row, hiding what will not fit behind a
/// chip that counts it.
///
/// Shared, because a control holding several things runs out of room the same
/// way wherever it does it. What the tags are, and what the chip says, is the
/// control's business; how many of them fit is this.
class ResponsiveTagLine extends StatefulWidget {
  /// Creates a line of tags.
  const ResponsiveTagLine({
    required this.tags,
    required this.overflowBuilder,
    required this.spacing,
    this.trailing,
    super.key,
  });

  /// The tags, in order. As many as fit are shown.
  final List<Widget> tags;

  /// What stands after them and is never hidden — a caret to type into,
  /// where the control has one. A control with nothing to add leaves it out.
  final Widget? trailing;

  /// Draws the chip that stands for what did not fit.
  final Widget Function(int hidden) overflowBuilder;

  /// The gap between one tag and the next.
  final double spacing;

  @override
  State<ResponsiveTagLine> createState() => _ResponsiveTagLineState();
}

class _ResponsiveTagLineState extends State<ResponsiveTagLine> {
  final ValueNotifier<int> _hidden = ValueNotifier<int>(0);

  @override
  void dispose() {
    _hidden.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _hidden,
      builder: (context, hidden, _) {
        return _TagLineLayout(
          spacing: widget.spacing,
          hasTrailing: widget.trailing != null,
          onHidden: (n) {
            if (_hidden.value != n) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _hidden.value = n;
              });
            }
          },
          children: [
            ...widget.tags,
            // The overflow chip is present but zero-opacity when nothing is
            // hidden, so its measured width can be reserved during layout.
            Offstage(
              offstage: hidden == 0,
              child: widget.overflowBuilder(hidden),
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        );
      },
    );
  }
}

class _TagLineLayout extends MultiChildRenderObjectWidget {
  const _TagLineLayout({
    required super.children,
    required this.spacing,
    required this.onHidden,
    required this.hasTrailing,
  });

  final double spacing;
  final ValueChanged<int> onHidden;
  final bool hasTrailing;

  @override
  _RenderTagLine createRenderObject(BuildContext context) => _RenderTagLine(
        spacing: spacing,
        onHidden: onHidden,
        hasTrailing: hasTrailing,
      );

  @override
  void updateRenderObject(BuildContext context, _RenderTagLine renderObject) {
    renderObject
      ..spacing = spacing
      ..onHidden = onHidden
      ..hasTrailing = hasTrailing;
  }
}

class _TagLineParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderTagLine extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TagLineParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TagLineParentData> {
  _RenderTagLine({
    required double spacing,
    required ValueChanged<int> onHidden,
    required bool hasTrailing,
  })  : _spacing = spacing,
        _onHidden = onHidden,
        _hasTrailing = hasTrailing;

  /// Whether the last child is something that stands after the tags and is
  /// never hidden, rather than a tag itself.
  bool _hasTrailing;
  set hasTrailing(bool v) {
    if (_hasTrailing == v) return;
    _hasTrailing = v;
    markNeedsLayout();
  }

  double _spacing;
  set spacing(double v) {
    if (_spacing != v) {
      _spacing = v;
      markNeedsLayout();
    }
  }

  ValueChanged<int> _onHidden;
  set onHidden(ValueChanged<int> v) => _onHidden = v;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TagLineParentData) {
      child.parentData = _TagLineParentData();
    }
  }

  // The children painted this layout: the visible tags, then (if anything is
  // hidden) the overflow chip, then the field. Hidden tags are left out so they
  // do not paint stacked at the origin.
  final List<RenderBox> _painted = [];

  @override
  void performLayout() {
    _painted.clear();
    // Children: [tag0..tagN-1, overflowChip, field]. The last two are special.
    final all = getChildrenAsList();
    final maxWidth = constraints.maxWidth;
    // The overflow chip is always there, offstage while nothing is hidden;
    // the trailing child may not be.
    if (all.length < (_hasTrailing ? 2 : 1)) {
      size = constraints.smallest;
      return;
    }
    final field = _hasTrailing ? all.removeLast() : null;
    final overflow = all.removeLast();
    final tags = all;

    final loose = BoxConstraints.loose(Size(maxWidth, constraints.maxHeight));
    for (final c in [...tags, overflow, if (field != null) field]) {
      c.layout(loose, parentUsesSize: true);
    }
    final overflowW = overflow.size.width;
    // Nothing after the tags is nothing to keep room for.
    final fieldW = field?.size.width ?? 0.0;

    // Greedily keep tags that fit, reserving room for the field and — once we
    // know something must hide — the overflow chip.
    var x = 0.0;
    var visible = 0;
    for (var i = 0; i < tags.length; i++) {
      final w = tags[i].size.width;
      final isLast = i == tags.length - 1;
      final reserve = fieldW + (isLast ? 0 : overflowW + _spacing);
      if (x + w + _spacing + reserve <= maxWidth || i == 0) {
        x += w + _spacing;
        visible++;
      } else {
        break;
      }
    }
    final hidden = tags.length - visible;

    double height = field?.size.height ?? 0.0;
    for (final c in [...tags, overflow]) {
      height = height > c.size.height ? height : c.size.height;
    }

    var cursor = 0.0;
    void place(RenderBox c) {
      (c.parentData as _TagLineParentData).offset =
          Offset(cursor, (height - c.size.height) / 2);
      cursor += c.size.width + _spacing;
      _painted.add(c);
    }

    for (var i = 0; i < visible; i++) {
      place(tags[i]);
    }
    if (hidden > 0) place(overflow);
    if (field != null) place(field);

    // As wide as what was put on it, not as wide as it was offered. Taking
    // the offer meant a line under a loose parent — a page, a column that
    // hands its children no width — claimed the whole of it, so everything
    // fitted, nothing hid, and the control grew instead of collapsing. Told a
    // width outright, `constrain` puts it back: a tight minimum wins.
    final used = cursor > 0 ? cursor - _spacing : 0.0;
    size = constraints.constrain(Size(used, height));
    _onHidden(hidden);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in _painted) {
      final pd = child.parentData as _TagLineParentData;
      context.paintChild(child, offset + pd.offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // Only the painted children are interactive; iterate front-to-back.
    for (final child in _painted.reversed) {
      final pd = child.parentData as _TagLineParentData;
      final hit = result.addWithPaintOffset(
        offset: pd.offset,
        position: position,
        hitTest: (r, transformed) => child.hitTest(r, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
