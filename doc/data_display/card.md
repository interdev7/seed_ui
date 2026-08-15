# Card

A content container. It groups a `title`, an optional
`extra` slot, a body `child`, and optional `cover`, `actions` and `tabList`.

```dart
Card(
  title: const Text('Card title'),
  extra: Button(
    variant: ButtonVariant.text,
    onPressed: () {},
    child: const Text('More'),
  ),
  child: const Text('Card content'),
)
```

## Header

`title` and `extra` share the header row — the title on the leading side, the
`extra` widget pinned to the far end. Omit both (and `tabList`) for a headerless
card.

## Cover, actions and meta

- `cover` renders a widget (usually an image) above the header, clipped to the
  card's top corners.
- `actions` is a list of widgets laid out as an evenly-divided bar along the
  bottom.
- `CardMeta` is a ready-made `avatar` + `title` + `description` block for the
  body — the card's meta block.

```dart
Card(
  cover: Image.network(url),
  actions: const [Icon(Icons.settings), Icon(Icons.edit)],
  child: const CardMeta(
    avatar: CircleAvatar(child: Text('A')),
    title: Text('Card title'),
    description: Text('This is the description'),
  ),
)
```

## Variant, type and size

| Property | Values |
| --- | --- |
| `variant` | `outlined` (default), `borderless` |
| `type` | `outer` (default), `inner` (nested, tinted header) |
| `size` | `small`, `middle` (default) / `large` |
| `gradient` | `Gradient?` background fill override (e.g. `LinearGradient`) |

`hoverable: true` lifts the card with a shadow while the pointer is over it.
`loading: true` replaces the body with a placeholder.

## Tab list

`tabList` renders navigation tabs in the header. Drive it controlled with
`activeTabKey` + `onTabChange`, or uncontrolled with `defaultActiveTabKey`.
`tabBarExtraContent` pins extra content to the ends of the tab bar.

```dart
Card(
  tabList: const [
    CardTab(key: 'a', label: Text('Article')),
    CardTab(key: 'b', label: Text('App')),
  ],
  activeTabKey: _tab,
  onTabChange: (k) => setState(() => _tab = k),
  child: Text('Content of tab "$_tab"'),
)
```

## Design tokens

`Card` has its own token set (`headerBg`,
`headerFontSize`, `headerHeight`, `headerPadding`, `bodyPadding`, `actionsBg`,
`extraColor`, and so on, each with a small variant). Every field is an override;
an unset one falls back to the global theme.

Customise one instance with `token`:

```dart
Card(
  title: const Text('Tinted header'),
  token: const CardToken(headerBg: Color(0xFFF0F5FF)),
  child: const Text('...'),
)
```

…or every `Card` under a subtree through `ConfigProvider` — the
`ConfigProvider.theme.components`:

```dart
ConfigProvider(
  components: const [CardToken(headerBg: Color(0xFFF0F5FF))],
  child: MaterialApp(...),
)
```

A per-instance `token` still wins over the `ConfigProvider` one.
