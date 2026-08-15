import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class TreeDemo extends StatelessWidget {
  const TreeDemo({super.key});

  static const _nodes = [
    TreeNode(
      key: '0',
      title: Text('parent 0'),
      children: [
        TreeNode(
          key: '0-0',
          title: Text('parent 0-0'),
          children: [
            TreeNode(key: '0-0-0', title: Text('leaf 0-0-0')),
            TreeNode(key: '0-0-1', title: Text('leaf 0-0-1')),
          ],
        ),
        TreeNode(
          key: '0-1',
          title: Text('parent 0-1'),
          children: [
            TreeNode(key: '0-1-0', title: Text('leaf 0-1-0')),
            TreeNode(
              key: '0-1-1',
              title: Text('disabled leaf'),
              disabled: true,
            ),
          ],
        ),
      ],
    ),
    TreeNode(
      key: '1',
      title: Text('parent 1'),
      children: [
        TreeNode(key: '1-0', title: Text('leaf 1-0')),
        TreeNode(key: '1-1', title: Text('leaf 1-1')),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Basic (selectable, expand all)',
          Tree(nodes: _nodes, defaultExpandAll: true),
        ),
        Group(
          'Checkable (cascade)',
          Tree(
            nodes: _nodes,
            checkable: true,
            defaultExpandAll: true,
            defaultCheckedKeys: ['0-0-0'],
          ),
        ),
        Group(
          'Check strictly (independent)',
          Tree(
            nodes: _nodes,
            checkable: true,
            checkStrictly: true,
            defaultExpandAll: true,
          ),
        ),
        Group(
          'Show line',
          Tree(nodes: _nodes, showLine: true, defaultExpandAll: true),
        ),
        Group(
          'autoExpandParent (deep key stays reachable)',
          Tree(
            nodes: _nodes,
            autoExpandParent: true,
            defaultExpandedKeys: ['0-1'],
          ),
        ),
        Group(
          'Show line + leaf icon + per-node switcher',
          Tree(
            showLine: true,
            defaultExpandAll: true,
            nodes: [
              TreeNode(
                key: 'r',
                title: Text('parent'),
                children: [
                  TreeNode(key: 'r-0', title: Text('leaf 0')),
                  TreeNode(
                    key: 'r-1',
                    title: Text('custom switcher parent'),
                    switcherIcon: Icon(Icons.edit, size: 12),
                    children: [TreeNode(key: 'r-1-0', title: Text('leaf 1-0'))],
                  ),
                ],
              ),
            ],
          ),
        ),
        _AsyncLoadDemo(),
        _DraggableDemo(),
        _DirectoryDraggableDemo(),
        Group(
          'Block node + multiple select',
          Tree(
            nodes: _nodes,
            blockNode: true,
            multiple: true,
            defaultExpandAll: true,
            defaultSelectedKeys: ['0-0-0', '1-0'],
          ),
        ),
        Group(
          'With icons',
          Tree(
            nodes: [
              TreeNode(
                key: 'a',
                title: Text('Documents'),
                icon: Icon(Icons.folder),
                children: [
                  TreeNode(
                    key: 'a-0',
                    title: Text('report.pdf'),
                    icon: Icon(Icons.description),
                  ),
                ],
              ),
            ],
            showIcon: true,
            defaultExpandAll: true,
          ),
        ),
      ],
    );
  }
}

/// A node representing a directory/folder.
class DirectoryNode extends TreeNode {
  final String path;
  final DateTime? lastModified;

  DirectoryNode({
    required super.key,
    required super.title,
    this.path = '',
    this.lastModified,
    super.children,
    super.disabled,
    super.checkable,
    super.selectable,
    super.disableCheckbox,
    super.switcherIcon,
  }) : super(
         iconBuilder: (context, isExpanded) => Icon(
           isExpanded ? Icons.folder_open : Icons.folder,
           color: const Color(0xFF1677FF),
         ),
       );
}

/// A node representing a file.
class FileNode extends TreeNode {
  final String path;
  final int sizeInBytes;
  final String extension;

  FileNode({
    required super.key,
    required super.title,
    this.path = '',
    this.sizeInBytes = 0,
    this.extension = '',
    super.disabled,
    super.checkable,
    super.selectable,
    super.disableCheckbox,
    super.switcherIcon,
  }) : super(
         isLeaf: true,
         iconBuilder: (context, _) => const Icon(
           Icons.insert_drive_file_outlined,
           color: Color(0xFF8C8C8C),
         ),
       );
}

/// Lazily loads a node's children the first time it is expanded.
class _AsyncLoadDemo extends StatefulWidget {
  const _AsyncLoadDemo();

  @override
  State<_AsyncLoadDemo> createState() => _AsyncLoadDemoState();
}

class _AsyncLoadDemoState extends State<_AsyncLoadDemo> {
  List<TreeNode> _data = const [
    TreeNode(key: '0', title: Text('Expand to load')),
    TreeNode(key: '1', title: Text('Expand to load')),
    TreeNode(key: '2', title: Text('Tree node (leaf)'), isLeaf: true),
  ];

  List<TreeNode> _withChildren(List<TreeNode> list, String key) => [
    for (final n in list)
      if (n.key == key)
        TreeNode(
          key: n.key,
          title: n.title,
          children: [
            TreeNode(key: '${n.key}-0', title: const Text('Child node')),
            TreeNode(key: '${n.key}-1', title: const Text('Child node')),
          ],
        )
      else
        n,
  ];

  Future<void> _load(TreeNode node) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _data = _withChildren(_data, node.key));
  }

  @override
  Widget build(BuildContext context) =>
      Group('Load data asynchronously', Tree(nodes: _data, loadData: _load));
}

/// Reorders nodes by dragging; onDrop rewrites the tree structure.
class _DraggableDemo extends StatefulWidget {
  const _DraggableDemo();

  @override
  State<_DraggableDemo> createState() => _DraggableDemoState();
}

class _DraggableDemoState extends State<_DraggableDemo> {
  List<TreeNode> _data = const [
    TreeNode(
      key: '0-0',
      title: Text('0-0'),
      children: [
        TreeNode(
          key: '0-0-0',
          title: Text('0-0-0'),
          children: [
            TreeNode(key: '0-0-0-0', title: Text('0-0-0-0')),
            TreeNode(key: '0-0-0-1', title: Text('0-0-0-1')),
            TreeNode(key: '0-0-0-2', title: Text('0-0-0-2')),
          ],
        ),
        TreeNode(
          key: '0-0-1',
          title: Text('0-0-1'),
          children: [TreeNode(key: '0-0-1-0', title: Text('0-0-1-0'))],
        ),
      ],
    ),
    TreeNode(key: '0-1', title: Text('0-1')),
  ];

  (List<TreeNode>, TreeNode?) _remove(List<TreeNode> list, String key) {
    TreeNode? removed;
    final out = <TreeNode>[];
    for (final n in list) {
      if (n.key == key) {
        removed = n;
        continue;
      }
      final (kids, r) = _remove(n.children, key);
      removed ??= r;
      out.add(_cloneNode(n, children: kids));
    }
    return (out, removed);
  }

  List<TreeNode> _insert(
    List<TreeNode> list,
    TreeDropDetails d,
    TreeNode moved,
  ) {
    final out = <TreeNode>[];
    for (final n in list) {
      if (d.position == TreeDropPosition.before && n.key == d.dropKey) {
        out.add(moved);
      }
      if (n.key == d.dropKey && d.position == TreeDropPosition.inside) {
        out.add(_cloneNode(n, children: [moved, ...n.children]));
      } else {
        out.add(_cloneNode(n, children: _insert(n.children, d, moved)));
      }
      if (d.position == TreeDropPosition.after && n.key == d.dropKey) {
        out.add(moved);
      }
    }
    return out;
  }

  TreeNode _cloneNode(TreeNode n, {required List<TreeNode> children}) {
    if (n is DirectoryNode) {
      return DirectoryNode(
        key: n.key,
        title: n.title,
        path: n.path,
        lastModified: n.lastModified,
        disabled: n.disabled,
        checkable: n.checkable,
        selectable: n.selectable,
        disableCheckbox: n.disableCheckbox,
        switcherIcon: n.switcherIcon,
        children: children,
      );
    }
    if (n is FileNode) {
      return FileNode(
        key: n.key,
        title: n.title,
        path: n.path,
        sizeInBytes: n.sizeInBytes,
        extension: n.extension,
        disabled: n.disabled,
        checkable: n.checkable,
        selectable: n.selectable,
        disableCheckbox: n.disableCheckbox,
        switcherIcon: n.switcherIcon,
      );
    }
    return TreeNode(
      key: n.key,
      title: n.title,
      icon: n.icon,
      disabled: n.disabled,
      disableCheckbox: n.disableCheckbox,
      checkable: n.checkable,
      selectable: n.selectable,
      isLeaf: n.isLeaf,
      switcherIcon: n.switcherIcon,
      children: children,
    );
  }

  void _onDrop(TreeDropDetails d) {
    final (pruned, moved) = _remove(_data, d.dragKey);
    if (moved == null) return;
    setState(() => _data = _insert(pruned, d, moved));
  }

  @override
  Widget build(BuildContext context) => Group(
    'Draggable (reorder)',
    Tree(
      nodes: _data,
      draggable: true,
      defaultExpandAll: true,
      onDrop: _onDrop,
    ),
  );
}

/// Directory and File nodes with drag-and-drop support.
class _DirectoryDraggableDemo extends StatefulWidget {
  const _DirectoryDraggableDemo();

  @override
  State<_DirectoryDraggableDemo> createState() =>
      _DirectoryDraggableDemoState();
}

class _DirectoryDraggableDemoState extends State<_DirectoryDraggableDemo> {
  List<TreeNode> _data = [
    DirectoryNode(
      key: 'src',
      title: const Text('src'),
      path: '/lib/src',
      children: [
        DirectoryNode(
          key: 'components',
          title: const Text('components'),
          path: '/lib/src/components',
          children: [
            FileNode(
              key: 'button.dart',
              title: const Text('button.dart'),
              path: '/lib/src/components/button.dart',
              sizeInBytes: 1024,
              extension: 'dart',
            ),
            FileNode(
              key: 'tree.dart',
              title: const Text('tree.dart'),
              path: '/lib/src/components/tree.dart',
              sizeInBytes: 2048,
              extension: 'dart',
            ),
          ],
        ),
        FileNode(
          key: 'main.dart',
          title: const Text('main.dart'),
          path: '/lib/src/main.dart',
          sizeInBytes: 512,
          extension: 'dart',
        ),
      ],
    ),
    FileNode(
      key: 'pubspec.yaml',
      title: const Text('pubspec.yaml'),
      path: '/pubspec.yaml',
      sizeInBytes: 300,
      extension: 'yaml',
    ),
  ];

  (List<TreeNode>, TreeNode?) _remove(List<TreeNode> list, String key) {
    TreeNode? removed;
    final out = <TreeNode>[];
    for (final n in list) {
      if (n.key == key) {
        removed = n;
        continue;
      }
      final (kids, r) = _remove(n.children, key);
      removed ??= r;
      out.add(_cloneNode(n, children: kids));
    }
    return (out, removed);
  }

  List<TreeNode> _insert(
    List<TreeNode> list,
    TreeDropDetails d,
    TreeNode moved,
  ) {
    final out = <TreeNode>[];
    for (final n in list) {
      if (d.position == TreeDropPosition.before && n.key == d.dropKey) {
        out.add(moved);
      }
      if (n.key == d.dropKey && d.position == TreeDropPosition.inside) {
        // Prevent inserting into files since files cannot have children
        if (n is FileNode) {
          out.add(n);
          continue;
        }
        out.add(_cloneNode(n, children: [moved, ...n.children]));
      } else {
        out.add(_cloneNode(n, children: _insert(n.children, d, moved)));
      }
      if (d.position == TreeDropPosition.after && n.key == d.dropKey) {
        out.add(moved);
      }
    }
    return out;
  }

  TreeNode _cloneNode(TreeNode n, {required List<TreeNode> children}) {
    if (n is DirectoryNode) {
      return DirectoryNode(
        key: n.key,
        title: n.title,
        path: n.path,
        lastModified: n.lastModified,
        disabled: n.disabled,
        checkable: n.checkable,
        selectable: n.selectable,
        disableCheckbox: n.disableCheckbox,
        switcherIcon: n.switcherIcon,
        children: children,
      );
    }
    if (n is FileNode) {
      return FileNode(
        key: n.key,
        title: n.title,
        path: n.path,
        sizeInBytes: n.sizeInBytes,
        extension: n.extension,
        disabled: n.disabled,
        checkable: n.checkable,
        selectable: n.selectable,
        disableCheckbox: n.disableCheckbox,
        switcherIcon: n.switcherIcon,
      );
    }
    return TreeNode(
      key: n.key,
      title: n.title,
      icon: n.icon,
      disabled: n.disabled,
      disableCheckbox: n.disableCheckbox,
      checkable: n.checkable,
      selectable: n.selectable,
      isLeaf: n.isLeaf,
      switcherIcon: n.switcherIcon,
      children: children,
    );
  }

  bool _allowDrop(TreeDropDetails d) {
    // If trying to drop 'inside' a FileNode, reject it since files can't contain children
    if (d.position == TreeDropPosition.inside) {
      final targetNode = _findNode(_data, d.dropKey);
      if (targetNode is FileNode) {
        return false;
      }
    }
    return true;
  }

  TreeNode? _findNode(List<TreeNode> list, String key) {
    for (final n in list) {
      if (n.key == key) return n;
      final found = _findNode(n.children, key);
      if (found != null) return found;
    }
    return null;
  }

  void _onDrop(TreeDropDetails d) {
    final (pruned, moved) = _remove(_data, d.dragKey);
    if (moved == null) return;
    setState(() => _data = _insert(pruned, d, moved));
  }

  @override
  Widget build(BuildContext context) => Group(
    'Directory Tree (Draggable files & folders)',
    Tree(
      nodes: _data,
      showIcon: true,
      showLine: true,
      draggable: true,
      defaultExpandAll: true,
      onDrop: _onDrop,
      allowDrop: _allowDrop,
    ),
  );
}
