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

## From the keyboard

The control takes its turn in the tab order and answers **Space** and
**Enter**. A halo appears around it — the same one a focused `Input` wears —
but only when the focus arrived by keyboard: a control clicked with a mouse is
focused too, and a ring around that is noise.

`focusNode` drives the focus yourself; left null the control keeps one.
`autofocus` puts the focus there as soon as it is built.

The halo sits on the box, not on the words beside it: the label is not the
control.

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
  components: const [CheckboxToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
