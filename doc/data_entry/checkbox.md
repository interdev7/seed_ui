# Checkbox

A checkbox for an independent boolean choice, usually confirmed later by a form
submit.

```dart
Checkbox(
  checked: _agree,
  onChanged: (v) => setState(() => _agree = v),
  label: const Text('I agree'),
)
```

For a setting that takes effect immediately, prefer a [Switch](../data_entry/switch.md).

## Value

Drive it yourself with `checked` + `onChanged`, or leave it to keep its own
state with `defaultChecked`:

```dart
Checkbox(checked: _agree, onChanged: (v) => setState(() => _agree = v))
Checkbox(defaultChecked: true, label: const Text('Remember me'))
```

A null `onChanged` on a **controlled** box makes it inert: nothing can change
the state, so nothing does. An uncontrolled one ticks whether or not anybody
is listening. `disabled` bars it either way. The optional `label` sits beside
the box, and the whole row is tappable.

`CheckboxGroup` is the one that takes `value` — a list of the selected
options' values — and `defaultValue` for a group that keeps its own.

## Indeterminate

`indeterminate: true` shows a dash instead of a tick — the "some but not all"
state of a parent that summarises a set of child checkboxes. Toggling still
reports the opposite of `checked`, so you decide what a tap means:

```dart
Checkbox(
  checked: _allChecked,
  indeterminate: _someChecked && !_allChecked,
  onChanged: (_) => setState(_toggleAll),
  label: const Text('Select all'),
)
```

## Group

`CheckboxGroup<T>` manages several checkboxes selecting a list of values:

```dart
CheckboxGroup<String>(
  value: _picked,
  onChanged: (v) => setState(() => _picked = v),
  options: const [
    CheckboxOption(value: 'a', label: 'Apple'),
    CheckboxOption(value: 'b', label: 'Banana'),
    CheckboxOption(value: 'c', label: 'Cherry', disabled: true),
  ],
)
```

`onChanged` receives the full new selection. Set `direction: Axis.vertical` to
stack the options, or tune `spacing`/`runSpacing`. Disable one option with its
`disabled` flag, or the whole group with the group's `disabled`.

## Sizes

`size` takes a preset or a measurement, as every control does, and scales the
box and its words together — 14, 16 and 20 pixels, at the theme's small,
standard and large type:

```dart
Checkbox(size: SoftSize.small, label: const Text('Remember me'))
CheckboxGroup<String>(size: SoftSize.large, value: _days, options: days)
Checkbox(size: const ControlSize.height(24))   // a 24-pixel box
```

Left unset, a box takes `CheckboxDefaults.size`, then the subtree's
`ConfigProvider.componentSize` — so in a small form it is small beside a
`Switch` that is small too. How many pixels each preset is lives in the
token: `boxSize`, `boxSizeSM`, `boxSizeLG`, and `fontSize`, `fontSizeSM`,
`fontSizeLG` for the words.

## Without words beside it

A box with no `label` — a tick in a row of your own table, a box whose words
are drawn somewhere else — has nothing to be named by, and a screen reader
says "checkbox, not checked" and no more. `semanticsLabel` names it, and
where there is a `label` too, is read in its place:

```dart
Checkbox(checked: picked, semanticsLabel: 'Select ${row.name}', onChanged: pick)
```

## Saying the answer is wanting

`status` recolours the box's edge — red for `InputStatus.error`, amber for
`InputStatus.warning` — as it does an input's border. `CheckboxGroup` hands it
to every box, and `FormItem.check` passes its own, so a box a rule refused
turns red beside its message.

## From the keyboard

The control takes its turn in the tab order and answers **Space** and
**Enter**. A halo appears around it — the same one a focused `Input` wears —
but only when the focus arrived by keyboard: a control clicked with a mouse is
focused too, and a ring around that is noise.

`focusNode` drives the focus yourself; left null the control keeps one.
`autofocus` puts the focus there as soon as it is built.

The halo sits on the box, not on the words beside it: the label is not the
control.

## Read-only

`readOnly` shows whether a box is ticked without letting anyone change it: a tap, Space or a screen reader's double-tap does nothing, and it takes no focus. Both `Checkbox` and `CheckboxGroup` take it.

```dart
Checkbox(checked: _remember, readOnly: true, label: const Text('Remember me'))
CheckboxGroup<String>(value: _days, readOnly: true, options: days)
```

Unlike `disabled` it keeps its colours, because the value is worth reading; unlike a null `onChanged` it is told apart for a screen reader, which hears it as read-only.

## Design tokens

`CheckboxToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
Checkbox(
  // …
  token: const CheckboxToken(),
);

// …or for every Checkbox in a subtree:
ConfigProvider(
  theme: ThemeData(
    components: const ComponentsConfig(checkbox: CheckboxToken()),
  ),
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
