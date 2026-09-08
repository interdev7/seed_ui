# Dropdown

A menu that floats from a trigger. Wrap any widget,
describe the menu entries, and the menu opens on hover, click or right-click,
positioned near the trigger and flipping to stay on screen.

It is the shared overlay primitive behind the kit's menus: [Select](../data_entry/select.md)
builds its option popup on the same [DropdownPanel](#reusing-the-panel) chrome.

```dart
enum RowAction { edit, remove }

Dropdown(
  menu: [
    DropdownItem(value: RowAction.edit, label: 'Edit'),
    DropdownItem(value: RowAction.remove, label: 'Delete',
        danger: true),
  ],
  onItemTap: (action) => switch (action) {
    RowAction.edit => edit(),
    RowAction.remove => remove(),
    null => null,
  },
  child: Button(child: const Text('Actions')),
)
```

Nothing there names a type. `Dropdown<T>` takes it from the items, hands it
back through `onItemTap`, and an enum makes that `switch` exhaustive — a case
you forget is a compile error rather than a silent nothing.

## Entries

The `menu` is a list of `DropdownEntry`:

| Type                 | Purpose                                                                                       |
| -------------------- | --------------------------------------------------------------------------------------------- |
| `DropdownItem<T>`    | A selectable row: `value`, `label`, `icon`, `disabled`, `danger`, `onTap`, nested `children` |
| `DropdownDivider<T>` | A horizontal rule between rows                                                                |
| `DropdownGroup<T>`   | A titled `label` over a list of `children`                                                    |

`onItemTap` fires with the tapped item's `value`; an item's own `onTap` fires
too. A `danger` item is red; a `disabled` item is greyed and inert. A submenu's
`children` carry the same `T` as the menu they hang from.

### When the type has to be named

A menu of items alone infers `T` from the items — nothing to write:

```dart
Dropdown(
  menu: [
    DropdownItem(value: RowAction.edit, label: 'Edit'),
    DropdownItem(value: RowAction.remove, label: 'Delete'),
  ],
  onItemTap: handle,
  child: trigger,
)
```

Put a `DropdownDivider` among them and the type has to be named once — on the
`Dropdown`, or on the list if it is hoisted:

```dart
Dropdown<RowAction>(
  menu: const [
    DropdownItem(value: RowAction.edit, label: 'Edit'),
    DropdownDivider(),
    DropdownItem(value: RowAction.remove, label: 'Delete'),
  ],
  onItemTap: handle,
  child: trigger,
)

// Hoisted, and so with no call site to infer from:
static const _menu = <DropdownEntry<RowAction>>[ ... ];
```

This is a limit of Dart's inference rather than a choice made here. A list
literal's element type is settled by the least upper bound of its elements, and
Dart's least upper bound across two *different* classes — an item and a divider
— collapses to `Object`. Four ways round it were measured and none works: a
non-generic divider carrying `Never`, a divider exposed as a typed constant, a
type fixed by a typed handler, and covariance. The only design that infers is
one class for items, dividers and groups together, which would make illegal
states representable and take pattern matching with it — a worse type to save
one annotation.

Write `<DropdownEntry>` with no argument and it compiles, silently meaning
`DropdownEntry<dynamic>`: the menu is untyped again and nothing says so. Name
the type.


## The label is a word, not a widget

`label` is a `String`. An item is what the menu is *told*; how it is drawn is
settled elsewhere. Kept as data it can be read — searched, sorted, spoken to a
screen reader, handed to a builder that draws it beside a count. A widget could
be none of those, and the one thing it bought you — an item that does not look
like an item — is what `itemBuilder` is for.

A label longer than the room it is given is cut with an ellipsis rather than
running off the end of the row.

## Drawing a row yourself

`itemBuilder` draws the inside of every row, submenus included:

```dart
Dropdown<String>(
  menu: entries,
  itemBuilder: (context, item, hovered) => Row(
    children: [
      Expanded(child: Text(item.label ?? '')),
      if (hovered) Text(counts[item.value]?.toString() ?? ''),
    ],
  ),
  child: Button(child: const Text('Actions')),
)
```

What it draws and what it does not is the whole of the design. The highlight,
the caret marking a submenu and the tap that chooses an item stay with the
menu, so a builder is never asked to rebuild the machinery in order to change
the look. It replaces the icon and the words, and nothing else.

**A row is as tall as what is in it.** `itemHeight` is a least, not a height:
a builder that asks for more takes it, because drawing a row inside a box you
cannot resize is not drawing it yourself. `itemPadding` says how far the row's
contents sit from its edges — set it to zero for a builder that paints its own
background out to them.

The colour and text style are set *around* the builder, so one that returns a
bare `Text` is dressed like every other row — greyed out when the item is
barred, red when it is dangerous — and one that wants otherwise says so.

`hovered` is the one thing a builder could not work out from the item alone.
Everything else it needs — `value`, `icon`, `disabled`, `danger` — is on the
item it is handed.

## Submenus

Give a `DropdownItem` a `children` list and it becomes a submenu parent — a
caret appears and the nested menu opens to the side on hover.

```dart
DropdownItem(
  label: 'More',
  children: [
    DropdownItem(value: 'help', label: 'Help'),
    DropdownItem(value: 'about', label: 'About'),
  ],
)
```

## Triggers

`trigger` is a list, so a menu can respond to several gestures:

| `DropdownTrigger` | Opens on                                                  |
| ----------------- | --------------------------------------------------------- |
| `hover` (default) | Pointer over the trigger; stays open while over the panel |
| `click`           | Primary tap; closes on an outside tap                     |
| `contextMenu`     | Secondary tap or long-press                               |

```dart
Dropdown(trigger: const [DropdownTrigger.click], menu: items, child: trigger)
```

`click` listens for pointer events rather than claiming a tap gesture, so it
works even when the child is itself tappable — a `Button` with its own
`onPressed` opens the menu *and* runs its callback, instead of swallowing the
tap. A drag or a scroll that ends over the trigger is not mistaken for one.

## Placement, arrow, disabled

`placement` accepts any [PopoverPlacement](../feedback/popconfirm.md#placement) (defaults to
`bottomLeft`). `arrow: true` draws a caret pointing at the trigger.
`disabled: true` blocks opening.

`closeOnSelect` (default `true`) decides whether tapping an item dismisses the
menu — submenu parents never close. `barrierColor` tints the dismiss barrier a
click/context menu puts behind itself; `token` overrides `DropdownToken` for
this instance.

## Controlled visibility

Drive it with `open` + `onOpenChange`:

```dart
Dropdown(
  open: _open,
  onOpenChange: (v) => setState(() => _open = v),
  trigger: const [DropdownTrigger.click],
  menu: items,
  child: trigger,
)
```

## Custom body

Instead of `menu`, pass `content` for a fully custom popup (the
`dropdownRender`). It receives a `close` callback:

```dart
Dropdown(
  trigger: const [DropdownTrigger.click],
  content: (context, close) => DropdownPanel(
    child: Padding(padding: const EdgeInsets.all(12), child: MyBody(onDone: close)),
  ),
  child: trigger,
)
```

## Wrapping the menu — popupRender

`content` replaces the whole popup; `popupRender` instead **wraps** the default
menu, so you can keep the built menu and append,
say, a divider and an input below it. It stays inside the panel chrome:

```dart
Dropdown(
  menu: items,
  popupRender: (context, menu) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      menu,
      const Divider(height: 1),
      Padding(padding: const EdgeInsets.all(8), child: MyAddItemRow()),
    ],
  ),
  child: trigger,
)
```

## Reusing the panel

`DropdownPanel` is the elevated surface (background, radius, shadow, clipping)
every floating menu is painted on, and `DropdownMenuList` renders a list of
entries as rows. Both are public so you can build custom overlays with the same
look — as `Select` does for its options.

`DropdownPanel.minWidth` is the least it may shrink to, a hundred and twenty by
default: a menu narrower than that reads as a mistake however short its words
are. `DropdownMenuList` takes the `entries` to draw and an `onSelect` called
with the item chosen — it reports the item rather than its value, so a caller
can tell two entries carrying the same value apart.


### One look for every menu

Background, corners, border and shadow are all token fields, so a house style
is said once and every menu under the provider wears it — no builder at the
call site:

```dart
ConfigProvider(
  theme: ThemeData(
    components: ComponentsConfig(
      dropdown: DropdownToken(
        menuBg: brandSurface,
        borderRadius: 20,
        border: BorderSide(color: brandLine),
        shadow: [BoxShadow(color: brandGlow, blurRadius: 24)],
      ),
    ),
  ),
  child: screen,
)
```

The provider need not be at the root. A menu is mounted in an overlay above
the app, but what stood over the trigger is carried down to the panel, so a
provider around one screen dresses that screen's menus — submenus with them.

`gap` is the distance a panel stands off what opened it: a menu from its
trigger, and a submenu from the **panel** it came out of — not from its row,
which is inset by the menu's padding and would leave the two overlapping. A
theme with no size unit leaves them touching, which reads as one surface
rather than two.

### A surface of your own

`popupRender` fills the panel; it does not replace it. Reach for it past what the token can
say — a gradient, an image, two layers. To put your own surface where the panel
was, blank the chrome and draw whatever you like inside:

```dart
Dropdown(
  token: const DropdownToken(
    menuBg: Color(0x00000000),
    borderRadius: 0,
    shadow: [],
  ),
  popupRender: (context, menu) => Container(
    decoration: BoxDecoration(
      color: myBackground,
      borderRadius: BorderRadius.circular(20),
      boxShadow: mine,
    ),
    child: menu,
  ),
  menu: entries,
  child: trigger,
)
```

A panel with no rounding is not clipped, so a shadow or a glow drawn in its
place is not cut off at its edge.

**`popupRender` dresses the panel it is handed, and only that one.** A submenu
opens a panel of its own, which wears the token — so a menu whose chrome has
been blanked for a surface of its own opens its submenus onto nothing. Blank
the chrome for a menu without submenus; style a nested one through the token,
which covers background, gradient, corners, border, shadow and the gap between
the two. A gradient in particular is a token field for exactly this reason: a
wash that stopped at the first panel would look like a mistake. With rounding it is clipped, because a row's
hover fill has to stop at the corner.

For a popup that is not a menu at all, `content:` replaces the body outright
and the panel with it — see **Custom body**.

## From the keyboard

A downward arrow on the trigger opens the menu — Enter and Space are left to
the trigger itself, which is usually a `Button` and answers them already;
taking them here would fire its `onPressed` and open the menu on one press.

Once open the panel takes the focus, so the keys reach the rows rather than
the button they came from:

| Key | What it does |
| --- | --- |
| `↓` / `↑` | Move down and up the rows, stepping over what is barred |
| `Home` / `End` | The first row that can be taken, and the last |
| `Enter` / `Space` | Take the row the keyboard rests on |
| `Esc` | Put the menu away, taking nothing |

The row the keyboard rests on wears the mark hovering leaves, so the hand and
the keyboard say the same thing — and `itemBuilder` is told `hovered` for it
too, since to a row being pointed at and being rested on are the same news.
The ends hold rather than wrapping round.

A menu is walked with a highlight, not with a focus per row: forty rows that
each took a `Tab` would be forty presses.

`DropdownMenuList` carries the two fields this needs — `autofocus`, whether
the panel takes the focus as it opens, and `onDismiss`, what `Esc` calls —
for anyone building a panel of their own out of it.

## Design tokens

A `token` on the dropdown itself overrides these for that menu alone — its
panel, its rows and its submenus alike; a `ComponentsConfig(dropdown: …)` on a
`ConfigProvider` does it for every menu under it.

The panel is drawn *around* whatever `popupRender` returns, so a
`ConfigProvider` placed inside that builder cannot reach it: by the time it is
consulted the panel's background, corners and shadow are already settled. Round
one menu's corners with `token:` on the dropdown.

`DropdownToken` overrides this component's own tokens. Every field is an
override; an unset one falls back to the value derived from the global theme.

| Token | Default |
| --- | --- |
| `menuBg` | `colorBgElevated` |
| `padding` | `sizeXXS` on every side |
| `borderRadius` | `borderRadiusLG` |
| `gradient` | none — a wash over `menuBg`, and it reaches submenus |
| `border` | none — the shadow tells the panel from the page; a line as well is one edge too many |
| `shadow` | `boxShadowSecondary` — an empty list casts nothing |
| `gap` | `sizeXXS` — between a menu and its trigger, and between a submenu and its row |
| `itemHoverBg` | `colorFillTertiary` |
| `itemHeight` | `controlHeight` — the least a row may be, not the height it must be |
| `itemPadding` | `sizeSM` across — how far a row's contents sit from its edges |
| `barrierColor` | none — no barrier is painted unless one is asked for |

## Testing

The menu renders into the root navigator's overlay, so the test app must
install `UiKit.navigatorKey`. See [testing](../../README.md#testing-against-the-kit).
