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
    DropdownItem(value: RowAction.edit, label: const Text('Edit')),
    DropdownItem(value: RowAction.remove, label: const Text('Delete'),
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
    DropdownItem(value: RowAction.edit, label: const Text('Edit')),
    DropdownItem(value: RowAction.remove, label: const Text('Delete')),
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
    DropdownItem(value: RowAction.edit, label: Text('Edit')),
    DropdownDivider(),
    DropdownItem(value: RowAction.remove, label: Text('Delete')),
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

## Submenus

Give a `DropdownItem` a `children` list and it becomes a submenu parent — a
caret appears and the nested menu opens to the side on hover.

```dart
DropdownItem(
  label: const Text('More'),
  children: [
    DropdownItem(value: 'help', label: const Text('Help')),
    DropdownItem(value: 'about', label: const Text('About')),
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

## Testing

The menu renders into the root navigator's overlay, so the test app must
install `UiKit.navigatorKey`. See [testing](../../README.md#testing-against-the-kit).
