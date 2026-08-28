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

A menu of items alone infers `T` from the items. Put a `DropdownDivider` among
them and it has to be named once:

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
```

A divider carries no value, and Dart settles a list's element type before the
menu's, so a mixed literal has nothing to go on and falls back to `Object`.
Naming the type on the `Dropdown` puts it back, and the items and the handler
are both checked against it from there. The same applies to a menu hoisted into
a variable, which has no context at all: annotate it
`const List<DropdownEntry<RowAction>> menu = [...]`.

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

## Testing

The menu renders into the root navigator's overlay, so the test app must
install `UiKit.navigatorKey`. See [testing](../../README.md#testing-against-the-kit).
