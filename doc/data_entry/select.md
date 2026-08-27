# Select

A dropdown for choosing one or more values from a list: a bordered box that
opens a floating, scrollable menu, with optional search, multi-select, free
tagging, a clear button and validation statuses.

```dart
Select<String>(
  value: _picked,
  placeholder: 'Pick a fruit',
  allowClear: true,
  options: const [
    SelectOption(value: 'apple', filterText: 'Apple'),
    SelectOption(value: 'banana', filterText: 'Banana'),
  ],
  onChanged: (v) => setState(() => _picked = v),
)
```

## The value is always a list

Unlike the scalar single-select value of most web selects, `Select`'s value is always a
`List<T>` — a single-select simply holds at most one element. This keeps one
widget working across every mode. For a single select, read `value.first` (or
`value.isEmpty`).

- **Controlled** — pass `value` and update it from `onChanged`.
- **Uncontrolled** — omit `value`, optionally seed with `defaultValue`, and
  read edits through `onChanged`.

## Options

Each `SelectOption<T>` carries the `value` reported on selection, an optional
`label` widget for display, and a `filterText` string used for the default
search filter and for display when `label` is null (falling back to
`'$value'`). Set `disabled` to block an option.

```dart
SelectOption(value: 'apple', label: Row(children: [Icon(...), Text('Apple')]), filterText: 'Apple')
```

## Modes

| `SelectMode` | Behaviour |
| --- | --- |
| `single` | Pick one value; the dropdown closes on selection |
| `multiple` | Pick several, shown as removable tags; stays open |
| `tags` | Like `multiple`, but typing a value not in the list creates it |

`tags` mode is intended for `Select<String>` — a created tag's value is the
raw typed string.

```dart
Select<String>(
  mode: SelectMode.multiple,
  maxTagCount: 3,
  value: _picked,
  options: fruitOptions,
  onChanged: (v) => setState(() => _picked = v),
)
```

`maxTagCount` collapses tags past a numeric limit into a `+N` chip (the tags
still wrap across lines). Set `maxTagCountResponsive: true` instead to keep the
tags on a **single line**, collapsing whatever does not fit into the `+N` chip —
a responsive tag count.

The option popup is rendered on the shared [DropdownPanel](../navigation/dropdown.md) — the
same surface the [Dropdown](../navigation/dropdown.md) menu uses.

## Search

`showSearch: true` lets the user filter by typing. The default filter is a
case-insensitive substring match against each option's text; override it with
`filterOption`, and observe keystrokes with `onSearch`.

```dart
Select<String>(
  showSearch: true,
  filterOption: (input, option) => option.filterText!.startsWith(input),
  options: fruitOptions,
)
```

For the filter, sort and `onSearch` together — the search
object — pass a `SelectSearch` to `search` (which also enables search):

```dart
Select<String>(
  options: fruitOptions,
  search: SelectSearch<String>(
    filterSort: (a, b) => a.filterText!.compareTo(b.filterText!), // sort options
    onSearch: (query) => fetchRemote(query),
    // filterOption: ..., autoClearSearchValue: false,
  ),
)
```

Only multi-select marks the chosen option with a tick in the dropdown; a
single select marks it by highlight alone.

## Clear, loading, disabled

| Property | Effect |
| --- | --- |
| `allowClear` | Shows a clear button on hover/open while there is a selection |
| `loading` | Swaps the arrow for a spinner and shows a loading dropdown |
| `disabled` | Greys out and blocks interaction |

## Sizes, variants and status

`size` takes either a preset — `small` (24px), `middle` (32px, default) or
`large` (40px) — or a measurement of your own:

```dart
Select<String>(size: ControlSize.height(36), options: fruitOptions)
Select<String>(size: ControlSize.width(180), options: fruitOptions)
Select<String>(size: ControlSize.box(180, 36), options: fruitOptions)
```

A preset carries a type size with it; a bare measurement names only itself, so
the standard type stands. The two-dimensional form names the width too, so it
needs no `SizedBox` around it.

`variant`
is `outlined` (default), `filled` or `borderless`. `status` recolours the
border to `SelectStatus.error` or `.warning`.

```dart
Select<String>(size: SoftSize.large, variant: SelectVariant.filled, options: fruitOptions)
```

## Keyboard

When the field is focused: **↑/↓** move the highlight (opening the dropdown if
closed), **Enter** selects the highlighted option (or creates a tag), **Esc**
closes, and **Backspace** on an empty search removes the last tag in
multiple/tags modes.

## Dropdown

| Property | Description |
| --- | --- |
| `listHeight` | Max dropdown height before scrolling (default 256) |
| `popupMatchSelectWidth` | Match the trigger's width (default true); otherwise sizes to content, never narrower than the trigger |
| `notFoundContent` | Shown when no option matches; defaults to [Empty](../data_display/empty.md) (or the app-wide `ConfigProvider.emptyBuilder`). In `tags` mode a typed query instead offers a "Create" row |
| `open` / `onOpenChange` | Drive dropdown visibility externally |

## Customisation

| Property | Description |
| --- | --- |
| `suffixIcon` | Replaces the trailing arrow |
| `menuItemSelectedIcon` | Replaces the tick beside a selected option |
| `optionRender` | Custom builder for a dropdown option row: `(option, selected) => Widget` |
| `itemRender` | Custom builder for a selected item in the box (single label or each tag): `(option) => Widget` |

## Testing

The dropdown renders into the root navigator's overlay, so the test app must
install `UiKit.navigatorKey`:

```dart
MaterialApp(
  navigatorKey: UiKit.navigatorKey,
  home: Scaffold(body: Center(child: mySelect)),
)
```

The dropdown's outside-tap barrier covers the screen while open, so a clear
button (revealed on hover) must be tested with the dropdown closed. See
[testing](../../README.md#testing-against-the-kit).

## Design tokens

`SelectToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
Select(
  // …
  token: const SelectToken(),
);

// …or for every Select in a subtree:
ConfigProvider(
  components: const [SelectToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
