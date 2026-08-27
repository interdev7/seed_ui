# InputNumber

A numeric input with up/down stepper buttons.
Built on [Input](../data_entry/input.md), it clamps to a range, steps by a fixed amount and
optionally rounds to a set precision.

```dart
InputNumber(
  value: _qty,
  min: 0,
  max: 10,
  onChanged: (v) => setState(() => _qty = v),
)
```

## Controlled or not

- **Controlled** — pass `value` and update from `onChanged`.
- **Uncontrolled** — omit `value`, optionally seed with `defaultValue`.

`onChanged` receives a `num?` (null when the field is emptied). The value is
committed and clamped when the field loses focus or the user presses Enter;
stepper buttons and arrow keys apply immediately.

## Range, step, precision

| Property | Description |
| --- | --- |
| `min` / `max` | Clamp the value; the matching stepper disables at the bound |
| `step` | Amount added/removed per step (default 1) |
| `precision` | Decimal places to round to; null keeps the value as typed |

```dart
InputNumber(defaultValue: 1.5, step: 0.1, precision: 2) // 1.50, 1.60, …
```

## Controls & keyboard

`controls: false` hides the steppers. `keyboard: false` disables the ↑/↓ arrow
keys. Both are on by default.

## Formatting

`formatter` renders the value (e.g. a currency prefix or thousands separators)
and `parser` turns typed text back into a number:

```dart
InputNumber(
  defaultValue: 1000,
  prefix: const Text(r'$'),
  formatter: (v) => addThousands(v),
  parser: (t) => num.tryParse(t.replaceAll(',', '')),
)
```

## Other

`prefix`, `suffix` (when `controls` is off), `size`, `status`
(`error`/`warning`), `disabled` and `readOnly` behave as on
[Input](../data_entry/input.md).

`size` takes a preset — `small`, `middle`, `large` — or a measurement:

```dart
InputNumber(size: ControlSize.height(44))       // 44 tall
InputNumber(size: ControlSize.width(160))      // 160 wide, standard height
InputNumber(size: ControlSize.box(160, 36))    // 160 by 36
```

The steppers follow the height, so they stay inside the border. In
`InputNumberMode.spinner` a named width beats the `spinnerWidth` token.

## Other properties

- `placeholder` — grey hint shown while the field is empty.
- `focusNode` — an external `FocusNode` for the field.
- `onSubmitted` — fires when the user submits the value (enter).

## Spinner mode

`mode: InputNumberMode.spinner` swaps the stacked handles for a minus and a plus
at either end, with the value centred between them — the `spinner`
mode, and the shape a thumb can hit.

```dart
InputNumber(
  mode: InputNumberMode.spinner,
  defaultValue: 3,
  min: 1,
  max: 10,
)
```

Both buttons reach the border on their own side and are parted from the value by
a single hairline; each is clipped to the box's corner, so their fills cannot
spill past the rounding.

## Steppers

The handles behave as follows: hovering one lights its chevron with
`handleHoverColor` (the primary accent by default), and only pressing it washes
the handle with `handleActiveBg` — faintly. `handleHoverBg` exists for a theme
that wants a filled hover block back, and is transparent otherwise.

A spinner is a stepper, not a text field, so it keeps its own width — as wide
as its two buttons and the number between them — and a parent that stretches its
children cannot blow it across the page. Widen it with `spinnerWidth` on the
token when the numbers are long:

```dart
InputNumber(
  mode: InputNumberMode.spinner,
  defaultValue: 3,
  token: const InputNumberToken(spinnerWidth: 240),
)
```

The spinner sits flush against the inner border and is clipped to the input's
own corner, so a fill cannot spill past the rounding.

## Design tokens

`InputNumberToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
InputNumber(
  // …
  token: const InputNumberToken(),
);

// …or for every InputNumber in a subtree:
ConfigProvider(
  components: const [InputNumberToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
