# Tabs

A tabbed panel. Each `TabItem` supplies a bar label and
its content panel.

```dart
Tabs(
  items: [
    TabItem(key: '1', label: const Text('Tab 1'), content: const Text('Content 1')),
    TabItem(key: '2', label: const Text('Tab 2'), content: const Text('Content 2')),
  ],
  onChange: (key) => setState(() => _active = key),
)
```

## Controlled or not

- **Controlled** — pass `activeKey` and update from `onChange`.
- **Uncontrolled** — omit `activeKey`, optionally set `defaultActiveKey`
  (defaults to the first item).

`onTabClick` fires on every tab tap (even the active one); `onChange` only when
the active tab changes.

## Items

`contentPosition` (`left` default, `center`, `right`) sets the horizontal
placement of the active tab's content within its panel.

Each `TabItem` has a `key`, a `label`, a `content` panel, and optionally an
`icon`, `disabled`, or `closable` (for editable cards).

## Types

| `TabsType`       | Look                                                 |
| ---------------- | ---------------------------------------------------- |
| `line` (default) | Underlined tabs with a sliding ink bar               |
| `card`           | Card-style tabs; the active one joins the panel      |
| `editableCard`   | Card tabs with a close button each and an add button |

```dart
Tabs(type: TabsType.card, items: items)
```

For `editableCard`, handle `onEdit`:

```dart
Tabs(
  type: TabsType.editableCard,
  items: _items,
  onEdit: (key, action) => setState(() {
    if (action == TabEditAction.add) _items = [..._items, newTab()];
    else _items = _items.where((t) => t.key != key).toList();
  }),
)
```

`hideAdd` removes the add button; `addIcon` replaces its glyph.

## Controller

For dynamic tabs — a browser, an IDE, anything that adds, closes, renames or
switches tabs at runtime — attach a `TabsController`. When supplied it becomes
the source of truth (so `items` may be omitted) and notifies its listeners on
every change.

```dart
final tabs = TabsController(items: [
  TabItem(key: '1', label: const Text('Tab 1'), content: const Text('One')),
]);

tabs.addListener(() => print('active: ${tabs.activeKey}'));

Tabs(controller: tabs, type: TabsType.editableCard, onCreateTab: (index) {
  // Seed the new tab; return null to accept the `Tab N` / autoincrement default.
  return CreateTabData(label: Text('News'), key: 'news', content: const Text('News!'));
});
```

Controller methods: `select(key)`, `add(item)` / `insert(index, item)`,
`remove(key)`, `update(key, ...)` and the shorthand `setTitle(key, title)` — the
latter is ideal for a browser tab tracking a page's `<title>`. Read state with
`activeKey`, `activeItem`, `items`, `indexOf(key)`.

`onCreateTab(index)` fires when the `+` button is pressed and returns an `CreateTabData`
(any null field falls back to the default); it requires a controller, which owns
the resulting tab. Without a controller, use `onEdit` and manage `items` yourself:

## Position & layout

`tabPosition` puts the bar on any edge — `top` (default), `bottom`, `left`,
`right`. `centered` centres horizontal tabs.

```dart
Tabs(tabPosition: TabPosition.left, items: items)
```

When the bar overflows and scrolls, `scrollAlign` decides where the selected
tab lands: `top` (default) pins it to the start/leading edge, `center` centres
it in the visible extent. Only the bar's own scroll view moves, never the page.

```dart
Tabs(tabPosition: TabPosition.left, scrollAlign: TabScrollAlign.center, items: items)
```

### Snapping

`snap: true` settles a flung bar with a tab against its leading edge, instead
of wherever the throw happened to end — so a long run cannot come to rest
mid-label.

```dart
Tabs(items: items, snap: true)
```

Off by default: a bar of a few tabs has nothing to settle into, and the extra
pull would only feel like resistance.

Snapping is to the measured tab boundaries, not to a fixed stride. Tabs are as
wide as their labels, so a page-sized step would land in the middle of one.

## Extra content

`tabBarExtraContent` pins widgets to the ends of the bar — the slot of
the same name. Use `TabBarExtra.right` for the common single-side case, or give
both a `left` and a `right`:

```dart
Tabs(items: items, tabBarExtraContent: TabBarExtra.right(Button(...)))

Tabs(
  items: items,
  tabBarExtraContent: TabBarExtra(left: leftNode, right: rightNode),
)
```

## Size & animation

`size` is `small`, `middle` (default) or `large`. `animated: false` disables the
panel cross-fade.

## Controller

`controller` (a `TabsController`) owns the tabs and the active key. When set it
is the source of truth and `items` is ignored — reach for it when tabs are added
or removed from outside the widget.

## Design tokens

`Tabs` has its own token set (`inkBarColor`,
`itemColor`, `itemHoverColor`, `itemSelectedColor`, `titleFontSize…`, `cardBg`,
`cardGutter`, `horizontalItemPadding…`, and so on). Every field is an override;
an unset one falls back to the global theme.

Customise one instance with `token`:

```dart
Tabs(
  items: items,
  token: const TabsToken(inkBarColor: Color(0xFFEB2F96)),
)
```

…or every `Tabs` under a subtree through `ConfigProvider` — the
`ConfigProvider.theme.components`:

```dart
ConfigProvider(
  components: const [TabsToken(itemSelectedColor: Color(0xFFEB2F96))],
  child: MaterialApp(...),
)
```

A per-instance `token` still wins over the `ConfigProvider` one. Read a
component's tokens elsewhere with `ConfigProvider.componentOf<TabsToken>(context)`.
