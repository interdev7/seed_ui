# Menu

A list of places to go: a sidebar, a top bar, the sections of a settings page.

```dart
Menu<String>(
  selectedValue: route,
  onSelect: (route) => router.go(route),
  items: const [
    MenuItem(value: '/mail', label: 'Mail', icon: Icon(Icons.mail)),
    MenuItem(
      value: 'settings',
      label: 'Settings',
      icon: Icon(Icons.settings),
      children: [
        MenuItem(value: '/profile', label: 'Profile'),
        MenuItem(value: '/security', label: 'Security'),
      ],
    ),
  ],
)
```

## Entries are data

| Entry | What it is |
| --- | --- |
| `MenuItem` | A place — or, with `children`, the title of a submenu |
| `MenuGroup` | A heading over a run of entries |
| `MenuDivider` | A thin line between entries |

A `MenuItem<T>` takes a `value` (a route, an id, an enum), a `label`, an
`icon`, an `extra` drawn at the far end of the row (a count, a badge), and
`disabled` and `danger`. Its own `onTap` is called beside `onSelect`.

An item with `children` is a title: choosing it opens its submenu rather than
selecting it. Give a title a `value` too — that is how the menu knows which
submenus are open.

## Modes

| `MenuMode` | Layout | A submenu |
| --- | --- | --- |
| `inline` (default) | A column, as in a sidebar | Opens in place under its title, a level further in |
| `vertical` | A column | Floats out beside its title |
| `horizontal` | A row, as in a top bar | Drops down under its title |

A horizontal menu has no room for headings or rules: a group's items stand in
the row with the rest, and dividers are left out. Items that do not fit fold
into a `…` at the end of the bar, which opens a menu of them; as the bar
widens they come back. The `…` is lit when the selected item is among them,
and a screen reader calls it "Show more".

## Selection

One item is selected at a time. A tap selects an item on its own;
`selectedValue` moves the selection whenever it changes — hand it the current
route and the menu follows the page. `onSelect` is called with the value of
whatever is chosen, in place or in a floating submenu.

The titles of the submenus the selected item sits in are drawn as selected
too, so the way down to it can be seen with the submenus shut. A floating
submenu marks the selected item inside it the same way.

## Open submenus

Inline submenus open and shut with a tap on their title, sliding open and
shut — at once where the platform asks for less motion.

| Property | What it does |
| --- | --- |
| `defaultOpenValues` | The submenus open at first |
| `openValues` | Holds them open or shut from outside; the menu waits to be told |
| `onOpenChanged` | Called with the open set whenever a title opens or shuts one |
| `accordion` | Opening one shuts the others at its level |

## Collapsed

`inlineCollapsed: true` folds an inline menu to its icons, `collapsedWidth`
wide. An item's words show in a tooltip beside it and are still what a screen
reader hears; a submenu floats out beside its title. Give every top-level item
an icon before collapsing a menu.

```dart
Menu<String>(items: items, inlineCollapsed: sidebarFolded)
```

## Keyboard and screen readers

Every item is a stop in the tab order. The arrow keys along the menu — up and
down in a column, along the row in a horizontal one — move between items, and
Enter or Space chooses. On an inline title the arrow pointing inwards opens its
submenu and the one pointing back shuts it, following the reading direction.
A shut submenu is out of the tab order.

A screen reader hears each item as a button, the selected one as selected, and
an inline title as expanded or collapsed. A group's heading is a heading.

## Defaults for a subtree

`MenuDefaults` sets `mode` and `accordion` for every menu below a
`ConfigProvider`.

## Design tokens

`MenuToken` overrides this component's own tokens. Every field is an override;
an unset one falls back to the value derived from the global theme.

| Token | Default |
| --- | --- |
| `itemColor` | `colorText` |
| `itemHoverBg` | `colorFillSecondary` |
| `itemSelectedColor`, `itemSelectedBg` | `primary.base`, `primary.bg` |
| `itemDisabledColor` | `colorTextQuaternary` |
| `dangerItemColor`, `dangerItemSelectedBg` | `error.base`, `error.bg` |
| `groupTitleColor` | `colorTextTertiary` |
| `subMenuItemBg` | `colorFillQuaternary` — behind an open inline submenu |
| `itemHeight` | `controlHeightLG` |
| `itemBorderRadius` | `borderRadiusLG` |
| `itemMarginInline` | `sizeXXS` — either side of an item, outside its wash |
| `itemPaddingInline` | `size` — inside an item, before its icon |
| `inlineIndent` | `sizeLG` — how much further in each level starts |
| `iconSize`, `iconGap` | `fontSize`, `sizeXS` |
| `horizontalItemHeight` | `controlHeightLG + sizeXS` |
| `horizontalItemPaddingInline` | `sizeMD` |
| `horizontalBarHeight` | two `lineWidth`s — under the selected item of a row |
| `collapsedWidth`, `collapsedIconSize` | `controlHeightLG × 2`, `fontSizeLG` |
| `fontSize` | `fontSize` |

```dart
Menu<String>(
  // …
  token: const MenuToken(itemHeight: 36),
);

// …or for every Menu in a subtree, a dark sidebar:
ConfigProvider(
  theme: ThemeData(
    components: const ComponentsConfig(
      menu: MenuToken(
        itemColor: Color(0xA6FFFFFF),
        itemSelectedColor: Color(0xFFFFFFFF),
        itemSelectedBg: Color(0xFF1677FF),
      ),
    ),
  ),
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
