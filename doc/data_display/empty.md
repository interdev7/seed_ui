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

`Empty` is what the kit falls back to for empty states such as a
[Select](../data_entry/select.md) with no matching options. There are two override points,
as follows:

- **Globally** — set `ConfigProvider.renderEmpty`, a `WidgetBuilder` used
  wherever a component would otherwise show its default empty state:

  ```dart
  ConfigProvider(
    renderEmpty: (context) => const Empty(description: Text('Nothing here')),
    child: MaterialApp(...),
  )
  ```

- **Per component** — a component's own override (for example a `Select`'s
  `notFoundContent`) always wins over the global `renderEmpty`.

The resolution order is: the component's own override → `renderEmpty` →
a default `Empty`.

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
