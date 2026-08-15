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

Controlled: pass `checked` and update it in `onChanged`. A null `onChanged` (or
`disabled`) makes it inert. The optional `label` sits beside the box, and the
whole row is tappable.

`CheckboxGroup` is the one that takes `value` — a list of the selected
options' values.

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
