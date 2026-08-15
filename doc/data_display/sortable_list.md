# SortableList

A list whose items can be dragged to reorder, with the others sliding smoothly
out of the way — vertically or horizontally. It is built on Flutter's
`SliverReorderableList`, so the make-room animation comes for free.

```dart
SortableList(
  onReorder: (from, to) => setState(() {
    _items.insert(to, _items.removeAt(from));
  }),
  children: [
    for (final item in _items)
      KeyedSubtree(key: ValueKey(item.id), child: MyRow(item)),
  ],
)
```

Each child **must** carry a unique `Key` so items keep their identity across
reorders. `onReorder(from, to)` gives indices that are already adjusted, so
`insert(to, removeAt(from))` applies the move directly.

## Direction

`direction: Axis.horizontal` lays the items out in a row and lets them be
dragged left/right instead of up/down. The default is `Axis.vertical`.

## Drag handle

By default a grip handle at the start of each item begins the drag. Set
`showHandle: false` to drag a whole item after a long-press instead.

## Layout

| Property | Effect |
| --- | --- |
| `gap` | Space between items |
| `padding` | Padding around the whole list |
| `shrinkWrap` (default true) | Sizes to content, for embedding in a column/row |

For a long, independently scrolling list, set `shrinkWrap: false` and give it a
bounded height (or width, when horizontal).

## Other properties

- `controller` — an external `ScrollController` for the list.
- `physics` — scroll physics; defaults to non-scrolling when `shrinkWrap` is on.
- `handle` — a custom drag handle replacing the default grip, used when
  `showHandle` is true.
- `liftBuilder` — full control over the lifted item while dragging. Null uses
  the shadow-only lift from `SortableListToken`.

## Design tokens

`SortableListToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
SortableList(
  // …
  token: const SortableListToken(),
);

// …or for every SortableList in a subtree:
ConfigProvider(
  components: const [SortableListToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
