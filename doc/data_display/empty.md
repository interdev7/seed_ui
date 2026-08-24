# Empty

An empty-state placeholder. Shows an illustration, a
description and optional actions when there is nothing to display.

```dart
Empty(
  description: const Text('No results'),
  child: Button(onPressed: create, child: const Text('Create')),
)
```

## Images

| `EmptyImage` | Look |
| --- | --- |
| `standard` (default) | The standard empty-state drawing |
| `simple` | A smaller, simpler outline |

Pass `imageWidget` for a fully custom illustration.

## Description

`description` is the text under the illustration. Null shows the default
"No data"; pass `SizedBox.shrink()` to hide it. `child` adds actions below it.

## As the default "no data" state

`Empty` is what the kit falls back to wherever a component has nothing to show:
a [Select](../data_entry/select.md) with no matching options, a
[Listy](listy.md) with no rows. There are two override points.

- **Globally** — set `ConfigProvider.emptyBuilder`. It is called with the
  `EmptySlot` that is asking, so one builder serves the whole app and can still
  tell a dropdown apart from a page-sized list:

  ```dart
  ConfigProvider(
    emptyBuilder: (context, slot) => switch (slot) {
      EmptySlot.select => const Text('Nothing matches'),
      EmptySlot.listy => const Empty(description: Text('No records yet')),
    },
    child: MaterialApp(...),
  )
  ```

  Ignore the slot and every empty state gets the same placeholder:

  ```dart
  emptyBuilder: (context, slot) => const Empty(
    description: Text('Nothing here'),
  ),
  ```

- **Per component** — a component's own override always wins over the global
  builder: a `Select`'s `notFoundContent`, a `Listy`'s `emptyContent`.

The resolution order is: the component's own override → `emptyBuilder` →
a default `Empty`.

### The slots

| Slot | Asked by |
| --- | --- |
| `EmptySlot.select` | a [Select](../data_entry/select.md) whose dropdown has no options left |
| `EmptySlot.listy` | a [Listy](listy.md) with no rows |

The enum grows as components gain empty states; a slot is only listed once
something actually asks with it.

## Illustration

- `image` — which built-in illustration to draw (`EmptyImage`). Ignored when
  `imageWidget` supplies your own artwork.

## Design tokens

`EmptyToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
Empty(
  // …
  token: const EmptyToken(),
);

// …or for every Empty in a subtree:
ConfigProvider(
  components: const [EmptyToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
