import 'package:flutter/material.dart' hide Checkbox;

import '../../icons/icons.dart' show ChevronPainter, HolderPainter, Spinner;
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/expandable.dart';
import '../../utils/keyed_set.dart';
import '../data_entry/checkbox.dart' show Checkbox;

/// Per-component design tokens for [Tree] — its own token table.
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [TreeToken(...)])`, or per instance via [Tree.token].
@immutable
class TreeToken {
  /// Creates a [TreeToken].
  const TreeToken({
    this.titleHeight,
    this.indentSize,
    this.nodeHoverBg,
    this.nodeSelectedBg,
    this.borderRadius,
  });

  /// Height of a node row (`titleHeight`).
  final double? titleHeight;

  /// Horizontal indent per depth level.
  final double? indentSize;

  /// Row background on hover (`nodeHoverBg`).
  final Color? nodeHoverBg;

  /// Row background when selected (`nodeSelectedBg`).
  final Color? nodeSelectedBg;

  /// Corner radius of the row highlight.
  final double? borderRadius;

  _ResolvedTreeToken _resolve(Token t) => _ResolvedTreeToken(
        titleHeight: titleHeight ?? t.controlHeightSM,
        indentSize: indentSize ?? t.controlHeightSM,
        nodeHoverBg: nodeHoverBg ?? t.colorFillTertiary,
        nodeSelectedBg: nodeSelectedBg ?? t.primary.bg,
        borderRadius: borderRadius ?? t.borderRadiusSM,
      );
}

@immutable
class _ResolvedTreeToken {
  const _ResolvedTreeToken({
    required this.titleHeight,
    required this.indentSize,
    required this.nodeHoverBg,
    required this.nodeSelectedBg,
    required this.borderRadius,
  });

  final double titleHeight;
  final double indentSize;
  final Color nodeHoverBg;
  final Color nodeSelectedBg;
  final double borderRadius;
}

/// One node in a [Tree] — a [title] and optional [children].
@immutable
class TreeNode {
  /// Creates a [TreeNode].
  const TreeNode({
    required this.key,
    required this.title,
    this.children = const [],
    this.icon,
    this.iconBuilder,
    this.disabled = false,
    this.disableCheckbox = false,
    this.checkable,
    this.selectable,
    this.isLeaf,
    this.switcherIcon,
  });

  /// Unique identity of the node.
  final String key;

  /// The node's label.
  final Widget title;

  /// Child nodes.
  final List<TreeNode> children;

  /// Optional leading icon (shown when `Tree.showIcon`).
  final Widget? icon;

  /// Dynamic icon builder that reacts to the node's expanded state.
  /// Used primarily for Directory nodes (open/closed folders).
  final Widget Function(BuildContext context, bool isExpanded)? iconBuilder;

  /// Greys the node out and blocks selecting it.
  final bool disabled;

  /// Disables just this node's checkbox.
  final bool disableCheckbox;

  /// Overrides the tree's `checkable` for this node.
  final bool? checkable;

  /// Overrides the tree's `selectable` for this node.
  final bool? selectable;

  /// Forces the node to be a leaf (no switcher) or a parent.
  final bool? isLeaf;

  /// Replaces the expand switcher for just this node.
  final Widget? switcherIcon;

  bool get _hasChildren => children.isNotEmpty && !(isLeaf ?? false);
}

/// A node representing a directory/folder.
class DirectoryNode extends TreeNode {
  /// Creates a [DirectoryNode].
  DirectoryNode({
    required super.key,
    required super.title,
    this.path = '',
    this.lastModified,
    super.children,
    super.disabled,
    super.checkable,
  }) : super(
          // Dynamic icon builder that reacts to the node's expanded state.
          iconBuilder: (context, isExpanded) => Icon(
            isExpanded ? Icons.folder_open : Icons.folder,
            color: const Color(0xFF1677FF), // The default primary blue
          ),
        );

  /// The file system path or hierarchical path of the directory.
  final String path;

  /// The last modified date of the directory.
  final DateTime? lastModified;
}

/// A node representing a file.
class FileNode extends TreeNode {
  /// Creates a [FileNode].
  FileNode({
    required super.key,
    required super.title,
    this.path = '',
    this.sizeInBytes = 0,
    this.extension = '',
    super.disabled,
    super.checkable,
  }) : super(
          // A file is ALWAYS a leaf; it cannot have children or an expander arrow.
          isLeaf: true,
          // Static file icon.
          iconBuilder: (context, _) => const Icon(
            Icons.insert_drive_file_outlined,
            color: Color(0xFF8C8C8C), // Secondary text gray
          ),
        );

  /// The file system path or hierarchical path of the file.
  final String path;

  /// The size of the file in bytes.
  final int sizeInBytes;

  /// The file extension.
  final String extension;
}

/// Where a dragged node lands relative to the drop target.
enum TreeDropPosition {
  /// As the target's previous sibling.
  before,

  /// As the target's (first) child.
  inside,

  /// As the target's next sibling.
  after,
}

/// A pending or completed drag-and-drop, passed to [Tree.onDrop] and
/// [Tree.allowDrop].
@immutable
class TreeDropDetails {
  /// Creates a [TreeDropDetails].
  const TreeDropDetails({
    required this.dragKey,
    required this.dropKey,
    required this.position,
  });

  /// The key of the node being dragged.
  final String dragKey;

  /// The key of the node it is being dropped onto.
  final String dropKey;

  /// Where it lands relative to [dropKey].
  final TreeDropPosition position;
}

/// A hierarchical list.
///
/// ```dart
/// Tree(
///   defaultExpandAll: true,
///   nodes: const [
///     TreeNode(key: '0', title: Text('parent'), children: [
///       TreeNode(key: '0-0', title: Text('leaf')),
///       TreeNode(key: '0-1', title: Text('leaf')),
///     ]),
///   ],
/// )
/// ```
///
/// Expansion, selection and checking are each controlled (pass the keys +
/// handler) or uncontrolled (pass the defaults). [checkable] adds checkboxes
/// whose state cascades to parents and children unless [checkStrictly].
class Tree extends StatefulWidget {
  /// Creates a [Tree].
  const Tree({
    super.key,
    required this.nodes,
    this.checkable = false,
    this.selectable = true,
    this.multiple = false,
    this.checkStrictly = false,
    this.blockNode = false,
    this.showLine = false,
    this.showLeafIcon = true,
    this.showIcon = false,
    this.disabled = false,
    this.loadData,
    this.checkedKeys,
    this.defaultCheckedKeys,
    this.onCheck,
    this.selectedKeys,
    this.defaultSelectedKeys,
    this.onSelect,
    this.expandedKeys,
    this.defaultExpandedKeys,
    this.onExpand,
    this.defaultExpandAll = false,
    this.autoExpandParent = false,
    this.switcherIcon,
    this.draggable = false,
    this.onDrop,
    this.allowDrop,
    this.onDragStart,
    this.onDragEnd,
    this.token,
  });

  /// The root nodes.
  final List<TreeNode> nodes;

  /// Shows a checkbox on every node.
  final bool checkable;

  /// Whether nodes can be selected.
  final bool selectable;

  /// Allows selecting more than one node.
  final bool multiple;

  /// Keeps parent and child checkboxes independent (no cascade).
  final bool checkStrictly;

  /// Stretches the selectable/hover highlight to the full row width.
  final bool blockNode;

  /// Draws connector guide lines.
  final bool showLine;

  /// Shows a leaf marker for childless nodes when [showLine] is on.
  final bool showLeafIcon;

  /// Shows each node's [TreeNode.icon].
  final bool showIcon;

  /// Disables the whole tree.
  final bool disabled;

  /// Lazily loads a node's children the first time it expands. Return a future
  /// that completes once the parent has updated [nodes] with the children.
  /// The node's switcher shows a spinner while the future is pending.
  final Future<void> Function(TreeNode node)? loadData;

  /// Checked node keys (controlled). Non-null with [onCheck].
  final List<String>? checkedKeys;

  /// Initially checked keys (uncontrolled).
  final List<String>? defaultCheckedKeys;

  /// Called with `(checked, halfChecked)` when a checkbox toggles.
  final void Function(List<String> checked, List<String> halfChecked)? onCheck;

  /// Selected node keys (controlled).
  final List<String>? selectedKeys;

  /// Initially selected keys (uncontrolled).
  final List<String>? defaultSelectedKeys;

  /// Called with the selected keys when selection changes.
  final ValueChanged<List<String>>? onSelect;

  /// Expanded node keys (controlled).
  final List<String>? expandedKeys;

  /// Initially expanded keys (uncontrolled).
  final List<String>? defaultExpandedKeys;

  /// Called with the expanded keys when a node expands or collapses.
  final ValueChanged<List<String>>? onExpand;

  /// Expands every parent initially (uncontrolled only).
  final bool defaultExpandAll;

  /// Keeps the ancestors of every expanded node expanded, so a deep node stays
  /// reachable.
  final bool autoExpandParent;

  /// Builds a custom switcher from the expanded state. When null, a chevron
  /// that turns a quarter-turn on expand is used.
  final Widget Function(BuildContext context, bool expanded)? switcherIcon;

  /// Enables drag-and-drop reordering of nodes.
  final bool draggable;

  /// Called when a node is dropped. Mutate [nodes] here and rebuild — the tree
  /// does not change the data itself.
  final ValueChanged<TreeDropDetails>? onDrop;

  /// Vetoes a drop. Dropping a node onto itself or into its own subtree is
  /// always rejected regardless of this; use it for finer rules. Returns true
  /// to allow.
  final bool Function(TreeDropDetails details)? allowDrop;

  /// Called with the node's key when its drag begins.
  final ValueChanged<String>? onDragStart;

  /// Called with the node's key when its drag ends (dropped or cancelled).
  final ValueChanged<String>? onDragEnd;

  /// Per-instance token overrides.
  final TreeToken? token;

  @override
  State<Tree> createState() => _TreeState();
}

class _TreeState extends State<Tree> {
  late final KeyedSet _expanded;
  late final KeyedSet _selected = KeyedSet(widget.defaultSelectedKeys);
  late final KeyedSet _checked = KeyedSet(widget.defaultCheckedKeys);

  final Map<String, TreeNode> _nodeOf = {};
  final Map<String, String?> _parentOf = {};
  final Set<String> _loading = {};
  final Set<String> _loaded = {};

  // Drag-and-drop: the node being dragged and the current drop target/position.
  String? _dragKey;
  String? _dropKey;
  TreeDropPosition? _dropPos;

  @override
  void initState() {
    super.initState();
    _index(widget.nodes, null);
    Iterable<String> expanded = widget.defaultExpandAll
        ? _nodeOf.values.where((n) => n._hasChildren).map((n) => n.key)
        : (widget.defaultExpandedKeys ?? const []);
    // Uncontrolled autoExpandParent seeds ancestors once, so toggling afterwards
    // behaves normally (no per-frame re-augmentation fighting the user).
    if (widget.autoExpandParent && widget.expandedKeys == null) {
      expanded = _withAncestors(expanded.toSet());
    }
    _expanded = KeyedSet(expanded);
  }

  /// Adds every ancestor of the keys in [keys].
  Set<String> _withAncestors(Set<String> keys) {
    final out = {...keys};
    for (final k in keys) {
      for (var p = _parentOf[k]; p != null; p = _parentOf[p]) {
        out.add(p);
      }
    }
    return out;
  }

  /// The expanded set used for both rendering and toggling. A *controlled*
  /// tree re-augments ancestors each build (the parent owns the state);
  /// uncontrolled is seeded once in [initState].
  Set<String> _resolveExpanded() {
    final set = _expanded.effective(widget.expandedKeys);
    return widget.autoExpandParent && widget.expandedKeys != null
        ? _withAncestors(set)
        : set;
  }

  @override
  void didUpdateWidget(Tree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.nodes, widget.nodes)) {
      _nodeOf.clear();
      _parentOf.clear();
      _index(widget.nodes, null);
    }
  }

  /// Records every node's parent and identity.
  void _index(List<TreeNode> nodes, String? parent) {
    for (final n in nodes) {
      _nodeOf[n.key] = n;
      _parentOf[n.key] = parent;
      _index(n.children, n.key);
    }
  }

  bool _checkableNode(TreeNode n) =>
      widget.checkable &&
      (n.checkable ?? true) &&
      !n.disableCheckbox &&
      !n.disabled &&
      !widget.disabled;

  // --- expansion ---

  /// Whether a node shows a switcher: a real parent, or a node that could load
  /// children lazily.
  bool _expandable(TreeNode n) =>
      !(n.isLeaf ?? false) &&
      (n.children.isNotEmpty || widget.loadData != null);

  void _toggleExpand(String key) {
    final cur = _resolveExpanded();
    final expanding = !cur.contains(key);
    final next = {...cur};
    expanding ? next.add(key) : next.remove(key);
    if (_expanded.commit(widget.expandedKeys, next)) setState(() {});
    widget.onExpand?.call(next.toList());

    final node = _nodeOf[key];
    if (expanding &&
        widget.loadData != null &&
        node != null &&
        node.children.isEmpty &&
        !(node.isLeaf ?? false)) {
      _load(node);
    }
  }

  Future<void> _load(TreeNode node) async {
    if (_loading.contains(node.key) || _loaded.contains(node.key)) return;
    setState(() => _loading.add(node.key));
    try {
      await widget.loadData!(node);
    } finally {
      if (mounted) {
        setState(() {
          _loading.remove(node.key);
          _loaded.add(node.key);
        });
      }
    }
  }

  // --- drag & drop ---

  /// Whether [key] is [ancestor] itself or sits in its subtree.
  bool _inSubtree(String key, String ancestor) {
    for (String? k = key; k != null; k = _parentOf[k]) {
      if (k == ancestor) return true;
    }
    return false;
  }

  bool _canDrop(TreeDropDetails d) {
    if (d.dragKey == d.dropKey) return false;
    // Never move a node into its own subtree — it would detach that subtree.
    if (_inSubtree(d.dropKey, d.dragKey)) return false;
    return widget.allowDrop?.call(d) ?? true;
  }

  void _startDrag(String key) {
    setState(() => _dragKey = key);
    widget.onDragStart?.call(key);
  }

  void _endDrag(String key) {
    if (_dragKey == null) return;
    setState(() {
      _dragKey = null;
      _dropKey = null;
      _dropPos = null;
    });
    widget.onDragEnd?.call(key);
  }

  /// Called as the pointer moves over [dropKey]; records a valid target/position
  /// (and clears the indicator when the spot is disallowed).
  void _hoverDrop(String dropKey, TreeDropPosition pos) {
    final drag = _dragKey;
    if (drag == null) return;
    final ok = _canDrop(
      TreeDropDetails(dragKey: drag, dropKey: dropKey, position: pos),
    );
    if (!ok) {
      if (_dropKey != null) {
        setState(() {
          _dropKey = null;
          _dropPos = null;
        });
      }
      return;
    }
    if (_dropKey != dropKey || _dropPos != pos) {
      setState(() {
        _dropKey = dropKey;
        _dropPos = pos;
      });
    }
  }

  void _leaveDrop(String dropKey) {
    if (_dropKey == dropKey) {
      setState(() {
        _dropKey = null;
        _dropPos = null;
      });
    }
  }

  void _commitDrop() {
    final drag = _dragKey, drop = _dropKey, pos = _dropPos;
    if (drag != null && drop != null && pos != null) {
      final d = TreeDropDetails(dragKey: drag, dropKey: drop, position: pos);
      if (_canDrop(d)) widget.onDrop?.call(d);
    }
  }

  // --- selection ---

  void _select(TreeNode node) {
    if (widget.disabled ||
        node.disabled ||
        !(node.selectable ?? widget.selectable)) {
      return;
    }
    final cur = _selected.effective(widget.selectedKeys);
    final Set<String> next;
    if (widget.multiple) {
      next = {...cur};
      next.contains(node.key) ? next.remove(node.key) : next.add(node.key);
    } else {
      next = cur.contains(node.key) ? <String>{} : {node.key};
    }
    if (_selected.commit(widget.selectedKeys, next)) setState(() {});
    widget.onSelect?.call(next.toList());
  }

  // --- checking (with cascade) ---

  void _check(TreeNode node, bool willCheck) {
    final next = {..._checked.effective(widget.checkedKeys)};
    if (widget.checkStrictly) {
      willCheck ? next.add(node.key) : next.remove(node.key);
    } else {
      _cascadeDown(node, willCheck, next);
      _recomputeAncestors(node.key, next);
    }
    if (_checked.commit(widget.checkedKeys, next)) setState(() {});
    final half = _halfChecked(next);
    widget.onCheck?.call(next.toList(), half.toList());
  }

  void _cascadeDown(TreeNode node, bool willCheck, Set<String> checked) {
    if (_checkableNode(node)) {
      willCheck ? checked.add(node.key) : checked.remove(node.key);
    }
    for (final c in node.children) {
      _cascadeDown(c, willCheck, checked);
    }
  }

  void _recomputeAncestors(String key, Set<String> checked) {
    var parent = _parentOf[key];
    while (parent != null) {
      final pnode = _nodeOf[parent]!;
      final kids = pnode.children.where(_checkableNode).toList();
      final allChecked =
          kids.isNotEmpty && kids.every((c) => checked.contains(c.key));
      if (_checkableNode(pnode) && allChecked) {
        checked.add(parent);
      } else {
        checked.remove(parent);
      }
      parent = _parentOf[parent];
    }
  }

  /// Nodes not fully checked but with at least one checked descendant.
  Set<String> _halfChecked(Set<String> checked) {
    final half = <String>{};
    bool visit(TreeNode n) {
      var descendantChecked = false;
      for (final c in n.children) {
        if (visit(c)) descendantChecked = true;
      }
      final self = checked.contains(n.key);
      if (n.children.isNotEmpty && !self && descendantChecked) half.add(n.key);
      return self || descendantChecked;
    }

    for (final n in widget.nodes) {
      visit(n);
    }
    return half;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<TreeToken>(context) ??
            const TreeToken())
        ._resolve(t);

    final expanded = _resolveExpanded();
    final selected = _selected.effective(widget.selectedKeys);
    final checked = _checked.effective(widget.checkedKeys);
    final half = widget.checkable && !widget.checkStrictly
        ? _halfChecked(checked)
        : const <String>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: _buildLevel(
        t,
        r,
        widget.nodes,
        0,
        const [],
        expanded,
        selected,
        checked,
        half,
      ),
    );
  }

  List<Widget> _buildLevel(
    Token t,
    _ResolvedTreeToken r,
    List<TreeNode> nodes,
    int level,
    List<bool> ancestorsLast,
    Set<String> expanded,
    Set<String> selected,
    Set<String> checked,
    Set<String> half,
  ) {
    return [
      for (var i = 0; i < nodes.length; i++)
        _buildNode(
          t,
          r,
          nodes[i],
          level,
          ancestorsLast,
          i == 0,
          i == nodes.length - 1,
          expanded,
          selected,
          checked,
          half,
        ),
    ];
  }

  Widget _buildNode(
    Token t,
    _ResolvedTreeToken r,
    TreeNode node,
    int level,
    List<bool> ancestorsLast,
    bool isFirst,
    bool isLast,
    Set<String> expanded,
    Set<String> selected,
    Set<String> checked,
    Set<String> half,
  ) {
    final isExpanded = expanded.contains(node.key);
    final hasChildren = _expandable(node);

    final row = _NodeRow(
      token: t,
      style: r,
      node: node,
      level: level,
      ancestorsLast: ancestorsLast,
      isFirst: isFirst,
      isLast: isLast,
      expanded: isExpanded,
      hasChildren: hasChildren,
      loading: _loading.contains(node.key),
      showLine: widget.showLine,
      showLeafIcon: widget.showLeafIcon,
      showIcon: widget.showIcon,
      blockNode: widget.blockNode,
      // A disabled node still *shows* a checkbox (rendered disabled); only
      // `checkable: false` hides it. Disabled nodes are excluded from the
      // cascade separately, via [_checkableNode].
      checkable: widget.checkable && (node.checkable ?? true),
      selectable: !widget.disabled &&
          !node.disabled &&
          (node.selectable ?? widget.selectable),
      selected: selected.contains(node.key),
      checked: checked.contains(node.key),
      halfChecked: half.contains(node.key),
      disabled: widget.disabled || node.disabled,
      switcherIcon: node.switcherIcon ??
          (widget.switcherIcon == null
              ? null
              : widget.switcherIcon!(context, isExpanded)),
      onExpand: () => _toggleExpand(node.key),
      onSelect: () => _select(node),
      onCheck: (v) => _check(node, v),
      draggable: widget.draggable && !widget.disabled && !node.disabled,
      dragging: _dragKey == node.key,
      dropIndicator: _dropKey == node.key ? _dropPos : null,
      onDragStart: () => _startDrag(node.key),
      onDragEnd: () => _endDrag(node.key),
      onDropHover: (pos) => _hoverDrop(node.key, pos),
      onDropLeave: () => _leaveDrop(node.key),
      onDropAccept: _commitDrop,
    );

    if (!hasChildren) return row;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Expandable(
          expanded: isExpanded,
          // Unmount collapsed subtrees ( far cheaper
          // for large trees) rather than keeping them at zero height.
          destroyWhenCollapsed: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: _buildLevel(
              t,
              r,
              node.children,
              level + 1,
              [...ancestorsLast, isLast],
              expanded,
              selected,
              checked,
              half,
            ),
          ),
        ),
      ],
    );
  }
}

/// One node's row: guide lines, switcher, checkbox, icon and title.
class _NodeRow extends StatefulWidget {
  const _NodeRow({
    required this.token,
    required this.style,
    required this.node,
    required this.level,
    required this.ancestorsLast,
    required this.isFirst,
    required this.isLast,
    required this.expanded,
    required this.hasChildren,
    required this.loading,
    required this.showLine,
    required this.showLeafIcon,
    required this.showIcon,
    required this.blockNode,
    required this.checkable,
    required this.selectable,
    required this.selected,
    required this.checked,
    required this.halfChecked,
    required this.disabled,
    required this.switcherIcon,
    required this.onExpand,
    required this.onSelect,
    required this.onCheck,
    required this.draggable,
    required this.dragging,
    required this.dropIndicator,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onDropHover,
    required this.onDropLeave,
    required this.onDropAccept,
  });

  final Token token;
  final _ResolvedTreeToken style;
  final TreeNode node;
  final int level;
  final List<bool> ancestorsLast;
  final bool isFirst;
  final bool isLast;
  final bool expanded;
  final bool hasChildren;
  final bool loading;
  final bool showLine;
  final bool showLeafIcon;
  final bool showIcon;
  final bool blockNode;
  final bool checkable;
  final bool selectable;
  final bool selected;
  final bool checked;
  final bool halfChecked;
  final bool disabled;
  final Widget? switcherIcon;
  final VoidCallback onExpand;
  final VoidCallback onSelect;
  final ValueChanged<bool> onCheck;
  final bool draggable;
  final bool dragging;
  final TreeDropPosition? dropIndicator;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final ValueChanged<TreeDropPosition> onDropHover;
  final VoidCallback onDropLeave;
  final VoidCallback onDropAccept;

  @override
  State<_NodeRow> createState() => _NodeRowState();
}

class _NodeRowState extends State<_NodeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    final r = widget.style;
    final indent = r.indentSize;

    // Leading area: ancestor guides + this node's switcher cell.
    final leadWidth = (widget.level + 1) * indent;
    final lead = SizedBox(
      width: leadWidth,
      height: r.titleHeight,
      child: Stack(
        children: [
          if (widget.showLine)
            Positioned.fill(
              child: CustomPaint(
                painter: _TreeLinePainter(
                  color: t.colorBorder,
                  direction: Directionality.of(context),
                  indent: indent,
                  level: widget.level,
                  ancestorsLast: widget.ancestorsLast,
                  isFirst: widget.isFirst,
                  isLast: widget.isLast,
                  hasChildrenExpanded: widget.hasChildren && widget.expanded,
                ),
              ),
            ),
          PositionedDirectional(
            // The node's own depth, counted from the edge the tree starts at.
            start: widget.level * indent,
            top: 0,
            bottom: 0,
            width: indent,
            child: _switcher(context),
          ),
        ],
      ),
    );

    final titleColor = widget.disabled ? t.colorTextQuaternary : t.colorText;
    final title = DefaultTextStyle(
      style: TextStyle(color: titleColor, fontSize: t.fontSize, height: 1.0),
      overflow: TextOverflow.ellipsis,
      child: widget.node.title,
    );

    final selectedBg = widget.selected ? r.nodeSelectedBg : null;
    final hoverBg = _hovered && widget.selectable && !widget.selected
        ? r.nodeHoverBg
        : null;
    final activeIcon =
        widget.node.iconBuilder?.call(context, widget.expanded) ??
            widget.node.icon;

    Widget titleRegion = Container(
      height: r.titleHeight,
      alignment: AlignmentDirectional.centerStart,
      padding: EdgeInsets.symmetric(horizontal: t.sizeXS),
      decoration: BoxDecoration(
        color: selectedBg ?? hoverBg,
        borderRadius: BorderRadius.circular(r.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon && activeIcon != null) ...[
            IconTheme.merge(
              data: IconThemeData(color: titleColor, size: t.fontSize),
              child: activeIcon,
            ),
            SizedBox(width: t.sizeXXS),
          ],
          Flexible(child: title),
        ],
      ),
    );

    if (widget.selectable) {
      titleRegion = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onSelect,
          child: titleRegion,
        ),
      );
    }

    Widget rowContent = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        lead,
        // A grip handle marks the row as draggable.
        if (widget.draggable) ...[
          Padding(
            // Between the grip and what comes after it in reading order.
            padding: EdgeInsetsDirectional.only(end: t.sizeXXS),
            child: CustomPaint(
              size: Size.square(t.fontSize),
              painter: HolderPainter(t.colorTextTertiary),
            ),
          ),
        ],
        if (widget.checkable) ...[
          Checkbox(
            checked: widget.checked,
            indeterminate: widget.halfChecked,
            disabled: widget.disabled || widget.node.disableCheckbox,
            onChanged: widget.onCheck,
          ),
          SizedBox(width: t.sizeXS),
        ],
        widget.blockNode
            ? Expanded(child: titleRegion)
            : Flexible(child: titleRegion),
      ],
    );

    if (widget.dragging) {
      rowContent = Opacity(opacity: 0.4, child: rowContent);
    }
    // A blue insert line (before/after) or an "into" outline over the row.
    if (widget.dropIndicator != null) {
      rowContent = _withDropIndicator(rowContent, t, r, indent);
    }
    if (!widget.draggable) return rowContent;

    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != widget.node.key,
      onMove: (d) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final y = box.globalToLocal(d.offset).dy;
        final h = r.titleHeight;
        final pos = y < h / 3
            ? TreeDropPosition.before
            : (y > h * 2 / 3
                ? TreeDropPosition.after
                : TreeDropPosition.inside);
        widget.onDropHover(pos);
      },
      onLeave: (_) => widget.onDropLeave(),
      onAcceptWithDetails: (_) => widget.onDropAccept(),
      builder: (context, _, __) => MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Draggable<String>(
          data: widget.node.key,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          onDragStarted: widget.onDragStart,
          onDragEnd: (_) => widget.onDragEnd(),
          onDraggableCanceled: (_, __) => widget.onDragEnd(),
          feedback: _feedback(t, r),
          child: rowContent,
        ),
      ),
    );
  }

  /// A floating label shown under the pointer while dragging.
  Widget _feedback(Token t, _ResolvedTreeToken r) => Opacity(
        opacity: 0.85,
        child: Container(
          padding:
              EdgeInsets.symmetric(horizontal: t.sizeXS, vertical: t.sizeXXS),
          decoration: BoxDecoration(
            color: t.colorBgElevated,
            borderRadius: BorderRadius.circular(r.borderRadius),
            boxShadow: t.boxShadowSecondary,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: t.colorText,
              fontSize: t.fontSize,
              height: 1.0,
            ),
            child: widget.node.title,
          ),
        ),
      );

  /// Overlays the drop indicator: an insert line for before/after, an outline
  /// for inside. The line is indented to where the node would land.
  Widget _withDropIndicator(
    Widget child,
    Token t,
    _ResolvedTreeToken r,
    double indent,
  ) {
    final pos = widget.dropIndicator!;
    final color = t.primary.base;
    if (pos == TreeDropPosition.inside) {
      return Stack(
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: t.lineWidth),
                  borderRadius: BorderRadius.circular(r.borderRadius),
                ),
              ),
            ),
          ),
        ],
      );
    }
    final left = (widget.level + 1) * indent;
    final line = PositionedDirectional(
      // Inset to where the node would land, from the edge the tree starts at.
      start: left,
      end: 0,
      top: pos == TreeDropPosition.before ? 0 : null,
      bottom: pos == TreeDropPosition.after ? 0 : null,
      child: IgnorePointer(
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
    return Stack(clipBehavior: Clip.none, children: [child, line]);
  }

  Widget _switcher(BuildContext context) {
    final t = widget.token;

    // A pending lazy load shows a spinner in place of the switcher.
    if (widget.loading) {
      return Center(child: Spinner(size: 12, color: t.colorTextSecondary));
    }

    // Leaves: a small leaf marker when guide lines want one, else nothing.
    if (!widget.hasChildren) {
      if (widget.showLine && widget.showLeafIcon) {
        return Center(
          child: CustomPaint(
            size: const Size.square(12),
            painter: TreeLeafIconPainter(t.colorTextTertiary),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final glyph = widget.switcherIcon ??
        AnimatedRotation(
          duration: t.motionDurationMid,
          curve: t.motionEaseInOut,
          turns: widget.expanded ? 0.25 : 0.0,
          child: CustomPaint(
            size: const Size.square(12),
            painter: ChevronPainter(t.colorTextSecondary, strokeWidth: 1.3),
          ),
        );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onExpand,
        child: Center(child: glyph),
      ),
    );
  }
}

/// A small file/leaf glyph shown at leaf nodes when guide lines are on.
class TreeLeafIconPainter extends CustomPainter {
  /// Creates a [TreeLeafIconPainter].
  TreeLeafIconPainter(this.color);

  /// The fill colour of the document glyph.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final w = size.width, h = size.height;
    // A page with a folded top-right corner.
    final fold = w * 0.3;
    final path = Path()
      ..moveTo(w * 0.22, h * 0.16)
      ..lineTo(w * 0.66, h * 0.16)
      ..lineTo(w * 0.78, h * 0.16 + fold)
      ..lineTo(w * 0.78, h * 0.84)
      ..lineTo(w * 0.22, h * 0.84)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(w * 0.66, h * 0.16),
      Offset(w * 0.66, h * 0.16 + fold),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.66, h * 0.16 + fold),
      Offset(w * 0.78, h * 0.16 + fold),
      paint,
    );
  }

  @override
  bool shouldRepaint(TreeLeafIconPainter old) => old.color != color;
}

/// Draws the connector guides for one node row.
class _TreeLinePainter extends CustomPainter {
  _TreeLinePainter({
    required this.color,
    required this.direction,
    required this.indent,
    required this.level,
    required this.ancestorsLast,
    required this.isFirst,
    required this.isLast,
    required this.hasChildrenExpanded,
  });

  final Color color;

  /// Which way the tree reads. The guides step inward from the edge the
  /// reading starts at, so a mirrored tree wants them stepping in from the
  /// other side; reflecting the canvas moves every one of them at once.
  final TextDirection direction;

  final double indent;
  final int level;
  final List<bool> ancestorsLast;
  final bool isFirst;
  final bool isLast;
  final bool hasChildrenExpanded;

  @override
  void paint(Canvas canvas, Size size) {
    // Reflected rather than re-derived: every guide is a fixed step in from
    // the leading edge, so turning the canvas over moves them all together
    // and keeps the arithmetic below in one coordinate system.
    final mirrored = direction == TextDirection.rtl;
    if (mirrored) {
      canvas
        ..save()
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;

    // Drawn one level at a time so the strokes meet cleanly at the corners.
    for (var i = 0; i < level; i++) {
      final x = i * indent + indent / 2;
      final isLastAncestor = (i == level - 1);
      final isLastSibling = isLastAncestor && isLast;

      // The vertical run for this level.
      final top = (i == 0 && isFirst) ? midY : 0.0;
      final bottom = isLastSibling ? midY : size.height;

      if (i < level - 1) {
        // An ancestor only carries a line down while it has siblings left.
        if (i < ancestorsLast.length && !ancestorsLast[i]) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
      } else {
        // The node's own level always draws its full run.
        canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);

        // The elbow reaching across to the node.
        canvas.drawLine(Offset(x, midY), Offset(x + indent, midY), paint);
      }
    }

    // An expanded node carries the line on down to its children.
    if (hasChildrenExpanded) {
      final x = level * indent + indent / 2;
      canvas.drawLine(Offset(x, midY), Offset(x, size.height), paint);
    }

    if (mirrored) canvas.restore();
  }

  @override
  bool shouldRepaint(_TreeLinePainter old) =>
      old.color != color ||
      old.direction != direction ||
      old.indent != indent ||
      old.level != level ||
      old.isFirst != isFirst ||
      old.isLast != isLast ||
      old.hasChildrenExpanded != hasChildrenExpanded ||
      !_listEquals(old.ancestorsLast, ancestorsLast);
}

bool _listEquals(List<bool> a, List<bool> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
