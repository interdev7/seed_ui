# Radio

A radio button for one choice among a group.

```dart
RadioGroup<String>(
  value: _plan,
  onChanged: (v) => setState(() => _plan = v),
  options: const [
    RadioOption(value: 'free', label: 'Free'),
    RadioOption(value: 'pro', label: 'Pro'),
  ],
)
```

## Group

`RadioGroup<T>` is the usual entry point: give it the selected `value`, the
`options`, and an `onChanged`. It is generic over the value type, so options can
carry any value.

| Property | Description |
| --- | --- |
| `value` | The selected value (nullable) |
| `options` | `RadioOption`s, each with a value, label and optional `disabled` |
| `onChanged` | Called with the newly chosen value |
| `direction` | `Axis.horizontal` (default, wrapping) or `Axis.vertical` |
| `disabled` | Greys the whole group out |
| `spacing` / `runSpacing` | Gaps between options |

Re-selecting the current value does nothing (no `onChanged` fires).

## Custom labels

An option's label can be any widget via `child`, replacing the plain `label`
string:

```dart
RadioOption(value: 'a', child: Row(children: [Icon(Icons.star), Text('Pro')]))
```

## Button style

Set `optionType: RadioOptionType.button` to render the options as connected
buttons instead of dots — a compact single-select bar:

```dart
RadioGroup<String>(
  value: _city,
  optionType: RadioOptionType.button,
  onChanged: (v) => setState(() => _city = v),
  options: const [
    RadioOption(value: 'hz', label: 'Hangzhou'),
    RadioOption(value: 'sh', label: 'Shanghai'),
    RadioOption(value: 'bj', label: 'Beijing'),
  ],
)
```

| Property | Description |
| --- | --- |
| `buttonStyle` | `outline` (default, coloured outline when selected) or `solid` (filled) |
| `size` | `small`, `middle` (default), `large` |
| `block` | Stretch the buttons to fill the width equally |

```dart
RadioGroup<String>(
  value: _v,
  optionType: RadioOptionType.button,
  buttonStyle: RadioButtonStyle.solid,
  block: true,
  size: SoftSize.large,
  options: options,
  onChanged: onChanged,
)
```

## Standalone

For a one-off outside a group, use `Radio<T>` directly, driving it with a
`groupValue`:

```dart
Radio<String>(
  value: 'a',
  groupValue: _picked,
  onChanged: (v) => setState(() => _picked = v),
  child: const Text('Option A'),
)
```

## Checkbox or radio?

Use a radio group when exactly one option applies; use a
[checkbox group](../data_entry/checkbox.md) when several may.

## Design tokens

`RadioToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
Radio(
  // …
  token: const RadioToken(),
);

// …or for every Radio in a subtree:
ConfigProvider(
  components: const [RadioToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
