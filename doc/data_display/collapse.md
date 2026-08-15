# Collapse

A set of collapsible panels. Each `CollapseItem`
supplies a header `label` and its `content` body.

```dart
Collapse(
  items: [
    CollapseItem(key: '1', label: const Text('Panel 1'), content: const Text('Body 1')),
    CollapseItem(key: '2', label: const Text('Panel 2'), content: const Text('Body 2')),
  ],
  defaultActiveKeys: const ['1'],
)
```

## Controlled or not

- **Controlled** — pass `activeKeys` and update from `onChange`.
- **Uncontrolled** — omit `activeKeys`, optionally set `defaultActiveKeys`.

`onChange` reports the full set of open keys.

## Items

Each `CollapseItem` has a `key`, a `label`, a `content` body, and optionally an
`extra` widget (pinned to the header's far end), `showArrow`, a per-panel
`collapsible`, or `forceRender`.

## Behaviour & layout

| Property | Effect |
| --- | --- |
| `accordion` | At most one panel open at a time |
| `bordered` (default true) | Outer frame and inter-panel dividers |
| `ghost` | Borderless, transparent — panels blend into the page |
| `size` | `small`, `middle` (default), `large` padding preset |
| `expandIconPosition` | `start` (default) or `end` |
| `collapsible` | `header` (default), `icon`, or `disabled` trigger |
| `destroyInactivePanel` | Drops collapsed content from the tree |

`collapsible` and `showArrow` can be set per `CollapseItem`, overriding the
collapse-level default. Supply `expandIcon` to replace the chevron:

```dart
Collapse(
  items: items,
  expandIcon: (context, isActive) => Icon(isActive ? Icons.remove : Icons.add),
)
```

By default collapsed content stays mounted (hidden); set
`destroyInactivePanel: true` to remove it, or a panel's `forceRender: true` to
keep it even when destroying.

## Design tokens

`Collapse` has its own token set
(`headerBg`, `headerPadding`, `contentBg`, `contentPadding`, `borderRadius`).
Every field is an override; an unset one falls back to the global theme.

Customise one instance with `token`:

```dart
Collapse(
  items: items,
  token: const CollapseToken(headerBg: Color(0x14EB2F96)),
)
```

…or every `Collapse` under a subtree through `ConfigProvider` — the
`ConfigProvider.theme.components`:

```dart
ConfigProvider(
  components: const [CollapseToken(headerBg: Color(0x14EB2F96))],
  child: MaterialApp(...),
)
```

A per-instance `token` still wins over the `ConfigProvider` one. Read a
component's tokens elsewhere with
`ConfigProvider.componentOf<CollapseToken>(context)`.
