# Breadcrumb

Where the reader is, as the path that led there: `Home / Projects / Seed`.
Every crumb but the last is a link back up the path; the last is the page
itself, and is not.

```dart
Breadcrumb<String>(
  items: const [
    BreadcrumbItem(value: '/', label: 'Home'),
    BreadcrumbItem(value: '/projects', label: 'Projects'),
    BreadcrumbItem(label: 'Seed'),
  ],
  onItemTap: (route) => router.go(route!),
)
```

## Crumbs are data

A `BreadcrumbItem<T>` is told what it is, not how to draw it:

| Field | What it is |
| --- | --- |
| `value` | What the crumb reports through `onItemTap` — a route, an id, an enum |
| `label` | Its words, as a `String` |
| `icon` | An icon before the words, or in their place |
| `semanticsLabel` | What a screen reader calls it — needed for a crumb that is an icon alone |
| `onTap` | Its own handler, called beside `onItemTap` |
| `menu` | Places beside this one, offered in a menu under the crumb |

`onItemTap` is called with a crumb's `value` when it is tapped, and with a menu
item's `value` when one is chosen, so one handler can do all the routing.

## A menu on a crumb

`menu` takes the same entries as a [Dropdown](dropdown.md) and draws a small
chevron after the crumb's words. A tap, or Enter or Space on a focused crumb,
opens it; a tap elsewhere shuts it:

```dart
BreadcrumbItem(
  value: 'seed',
  label: 'Seed',
  menu: const [
    DropdownItem(value: 'atlas', label: 'Atlas'),
    DropdownItem(value: 'orbit', label: 'Orbit'),
  ],
)
```

A crumb with a menu opens the menu when tapped, and its own `onTap` is not
called. The last crumb may have one too — "the other projects" beside the one
the reader is in.

## A long path

A path that does not fit wraps onto further lines. `maxItems` folds its middle
instead: the first crumb and the last `maxItems - 2` stay, and a `…` between
them opens a menu of the crumbs it hides. `maxItems` is taken as at least 3 —
a root, the `…` and the page.

```dart
Breadcrumb<String>(items: deepPath, maxItems: 4)
// Home / … / Reports / March
```

## Separator

`separator` is any widget; null is a `/`. It is decoration, and a screen reader
passes it by.

```dart
Breadcrumb<String>(
  items: path,
  separator: const Icon(Icons.chevron_right),
)
```

## Keyboard and screen readers

Each link is a stop in the tab order and is pressed with Enter or Space; the
page itself is not a stop. A screen reader hears the links as links, the page
as plain text, a crumb with a menu as a button, and the `…` as "Show more" in
the app's language.

## Design tokens

`BreadcrumbToken` overrides this component's own tokens. Every field is an
override; an unset one falls back to the value derived from the global theme.

| Token | Default |
| --- | --- |
| `itemColor` | `colorTextTertiary` — the links up the path |
| `lastItemColor` | `colorText` — the page itself |
| `linkHoverColor` | `colorText` |
| `linkHoverBg` | `colorFillSecondary` |
| `separatorColor` | `colorTextTertiary` |
| `separatorMargin` | `sizeXS` — either side of a separator |
| `fontSize` | `fontSize` |
| `iconFontSize` | `fontSize` |
| `itemPaddingInline` | `sizeXXS` — inside a crumb, under the hover wash |
| `borderRadius` | `borderRadiusSM` — the hover wash's and the focus ring's corners |

```dart
Breadcrumb<String>(
  // …
  token: const BreadcrumbToken(separatorMargin: 4),
);

// …or for every Breadcrumb in a subtree:
ConfigProvider(
  theme: ThemeData(
    components: const ComponentsConfig(
      breadcrumb: BreadcrumbToken(fontSize: 13),
    ),
  ),
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
