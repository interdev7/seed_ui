# Tree

A hierarchical list. Each `TreeNode` has a `title` and
optional `children`.

```dart
Tree(
  defaultExpandAll: true,
  nodes: const [
    TreeNode(key: '0', title: Text('parent'), children: [
      TreeNode(key: '0-0', title: Text('leaf 0-0')),
      TreeNode(key: '0-1', title: Text('leaf 0-1')),
    ]),
  ],
)

```

## Nodes

Each `TreeNode` has a `key`, a `title`, `children`, and optionally an `icon`,
`iconBuilder`, `disabled`, `disableCheckbox`, per-node `checkable` / `selectable` overrides, or
`isLeaf`.

### Directory Tree

For file system representations, you can use the built-in `DirectoryNode` and `FileNode` extensions. They automatically handle icons (open/closed folder states for directories, file icon for files) and enforce leaf logic for files. Both nodes also include a `path` property for easy file system reference.

```dart
Tree(
  showIcon: true, // Required to display the node icons
  nodes: [
    DirectoryNode(
      key: 'src',
      title: const Text('src'),
      path: '/lib/src',
      children: [
        FileNode(
          key: 'main.dart',
          title: const Text('main.dart'),
          path: '/lib/src/main.dart',
          sizeInBytes: 1024,
        ),
      ],
    ),
  ],
)

```

## Expansion, selection, checking

Each of the three states is **controlled** (pass the keys + handler) or
**uncontrolled** (pass the defaults):

| State  | Controlled     | Uncontrolled                               | Handler    |
| ------ | -------------- | ------------------------------------------ | ---------- |
| Expand | `expandedKeys` | `defaultExpandedKeys` / `defaultExpandAll` | `onExpand` |

`autoExpandParent` keeps the ancestors of every expanded node expanded (handy
with search), so listing a deep key expands the parents that lead to it.

| Select | `selectedKeys` | `defaultSelectedKeys` | `onSelect` |
| Check | `checkedKeys` | `defaultCheckedKeys` | `onCheck` |

- `selectable` (default true) and `multiple` control selection. Selecting does
  not expand — the switcher does that.
- `checkable` adds a checkbox to every node. Its state **cascades** to parents
  and children; a parent shows an indeterminate box when only some descendants
  are checked. `onCheck` reports `(checked, halfChecked)`.
- `checkStrictly` keeps parent and child checkboxes independent (no cascade).

A `disabled` node still shows its checkbox (rendered disabled) and is skipped by
the cascade; `checkable: false` on a node hides its checkbox entirely.

## Appearance

| Property       | Effect                                                                        |
| -------------- | ----------------------------------------------------------------------------- |
| `showLine`     | Draws connector guide lines                                                   |
| `showLeafIcon` | Shows a leaf marker on childless nodes (with `showLine`)                      |
| `showIcon`     | Shows each node's `icon` (or `iconBuilder` result)                            |
| `blockNode`    | Stretches the highlight to the full row width                                 |
| `disabled`     | Disables the whole tree                                                       |
| `switcherIcon` | Replaces the expand chevron (a `TreeNode.switcherIcon` overrides it per node) |

## Lazy loading

A shut switcher points the way the reading runs, which is the way the node
would open — so a mirrored tree turns the chevron over. Open, it points down
whichever way the page reads, and the quarter turn between the two simply goes
the other way about.

`loadData` fetches a node's children the first time it expands. Return a future
that completes once the parent has updated `nodes` with the loaded children; the
node's switcher shows a spinner while it is pending. A node with no children is
still expandable when `loadData` is set (unless `isLeaf: true`).

```dart
Tree(
  nodes: _data,
  loadData: (node) async {
    final children = await fetchChildren(node.key);
    setState(() => _data = withChildren(_data, node.key, children));
  },
)

```

## Drag and drop

`draggable: true` lets nodes be dragged to reorder them. On a drop, `onDrop`
fires with a `TreeDropDetails` (`dragKey`, `dropKey`, `position` — `before`,
`inside` or `after`); **you** mutate `nodes` and rebuild — the tree never changes
the data itself. Dropping a node onto itself or into its own subtree is always
rejected; `allowDrop` adds finer rules. `onDragStart` / `onDragEnd` report the
dragged key.

```dart
Tree(
  nodes: _data,
  draggable: true,
  onDrop: (d) => setState(() => _data = reorder(_data, d)),
  allowDrop: (d) => d.position != TreeDropPosition.inside, // siblings only
)

```

While dragging, a blue insert line shows `before`/`after`, and an outline shows
`inside`; the target requires an `Overlay` ancestor (any `MaterialApp` /
`Navigator` provides one).

## Design tokens

`Tree` has its own token set — `titleHeight`, `indentSize`, `nodeHoverBg`,
`nodeSelectedBg`, `borderRadius`. Every field is an override; an unset one falls
back to the global theme.

```dart
Tree(
  nodes: nodes,
  token: const TreeToken(indentSize: 20),
)

```

…or every `Tree` under a subtree through `ConfigProvider`:

```dart
ConfigProvider(
  components: const [TreeToken(nodeSelectedBg: Color(0xFFE6F4FF))],
  child: MaterialApp(...),
)
```
