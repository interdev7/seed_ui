# Switch

A toggle for an immediate on/off setting — flipping it takes effect at once,
with no separate save step.

```dart
Switch(
  value: _wifiOn,
  onChanged: (v) => setState(() => _wifiOn = v),
)
```

For a choice confirmed later by a form submit, prefer a checkbox.

## Value

`Switch` is controlled: pass the current `value` and update it in
`onChanged`. A null `onChanged` (or `disabled`) makes it inert.

## Sizes

`SwitchSize.defaultSize` (22px tall) and `.small` (16px), for dense rows:

```dart
Switch(value: v, size: SwitchSize.small, onChanged: onToggle)
```

## States

| Property | Effect |
| --- | --- |
| `disabled` | Greys out and blocks toggling |
| `loading` | Shows a spinner on the thumb and blocks toggling |

Use `loading` while persisting the change:

```dart
Switch(
  value: _enabled,
  loading: _saving,
  onChanged: (v) async {
    setState(() => _saving = true);
    await api.setEnabled(v);
    setState(() { _enabled = v; _saving = false; });
  },
)
```

## Labels

`checkedChild` and `uncheckedChild` show a small label or icon inside the
track, on the side away from the thumb:

```dart
Switch(
  value: v,
  onChanged: onToggle,
  checkedChild: const Text('ON'),
  uncheckedChild: const Text('OFF'),
)
```

## Design tokens

`SwitchToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
Switch(
  // …
  token: const SwitchToken(),
);

// …or for every Switch in a subtree:
ConfigProvider(
  components: const [SwitchToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
