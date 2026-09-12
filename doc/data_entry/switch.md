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

Drive it yourself with `value` + `onChanged`, or leave it to keep its own
state with `defaultValue`:

```dart
Switch(value: _wifi, onChanged: (v) => setState(() => _wifi = v))
Switch(defaultValue: true)                       // drives itself
Switch(defaultValue: true, onChanged: _report)   // drives itself, and tells you
```

A null `onChanged` on a **controlled** switch makes it inert: nothing can
change the value, so nothing does. An uncontrolled one flips whether or not
anybody is listening. `disabled` bars it either way.

## Sizes

Three presets — `SoftSize.small` (16px tall), `.middle` (22px) and `.large`
(28px) — or a height of your own:

```dart
Switch(value: v, size: SoftSize.small, onChanged: onToggle)
Switch(value: v, size: const ControlSize.height(40), onChanged: onToggle)
```

The track height is the only number a switch needs: it is twice as long as it
is tall, and the handle sits inside it with a gap of an eleventh of that
height at each end. The label, its icon and the stretch of a pressed handle
follow the same scale, so a switch at any height is the same switch.

Left unsaid, the size comes from `SwitchDefaults.size`, then from the
`componentSize` set for the subtree, then `SoftSize.middle`.

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

## From the keyboard

The control takes its turn in the tab order and answers **Space** and
**Enter**. A halo appears around it — the same one a focused `Input` wears —
but only when the focus arrived by keyboard: a control clicked with a mouse is
focused too, and a ring around that is noise.

`focusNode` drives the focus yourself; left null the control keeps one.
`autofocus` puts the focus there as soon as it is built.

The halo sits on the track.

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

`trackHeightSM`, `trackHeight` and `trackHeightLG` are the three presets, and
everything else is worked out from whichever is in force. `trackMinWidthSM`,
`trackMinWidth`, `handleSizeSM` and `handleSize` override that working-out for
the preset they name — leave them unset and the proportions hold.
