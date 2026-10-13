# AutoComplete

A text field that offers to finish what is being typed: a city, an e-mail
domain, a name from a long list.

```dart
AutoComplete(
  placeholder: 'City',
  options: const [
    AutoCompleteOption(value: 'Amsterdam'),
    AutoCompleteOption(value: 'Ankara'),
    AutoCompleteOption(value: 'Athens'),
  ],
  onSelect: (city) => setState(() => this.city = city),
)
```

Unlike a [Select](select.md), what is typed is the value: a suggestion only
fills it in, and the reader may type something no suggestion holds.

## Suggestions

An `AutoCompleteOption` takes the `value` that goes into the field, an optional
`label` to show in its place — an address with the district under it — and
`disabled`. Without a label, the suggestion shows its value with the part that
matches the typing in bold.

The suggestions open under the field when it takes the focus and as it is
typed in, narrowed by `filterOption`. Without one, a suggestion is kept when
its value holds the typed text, whatever its case.

| Property | What it does |
| --- | --- |
| `onChanged` | Called with the text whenever it changes, typed or filled in |
| `onSelect` | Called with a suggestion's value when it is chosen |
| `onSearch` | Called with the text as it is typed — not when a suggestion fills it |
| `value`, `defaultValue` | The text held from outside, or the text to start with |
| `notFoundContent` | Shown when nothing matches; null opens nothing at all |
| `listHeight` | The most the suggestions stand tall before they scroll (256) |

## Suggestions fetched as the reader types

Fetch in `onSearch`, hand what comes back to `options`, and keep everything
with `filterOption` — the server has done the matching. The list updates in
place while it is open:

```dart
AutoComplete(
  options: found,
  filterOption: (_, __) => true,
  notFoundContent: loading ? const Text('Searching…') : null,
  onSearch: (text) async {
    setState(() => loading = true);
    final result = await api.suggest(text);
    setState(() {
      found = [for (final s in result) AutoCompleteOption(value: s)];
      loading = false;
    });
  },
)
```

## Keys

The arrow keys walk the suggestions, passing over those that cannot be chosen
and wrapping at the ends; Enter takes the one reached, and Escape puts the list
away. A down arrow in a field whose list is shut opens it.

`defaultActiveFirstOption` (yes unless told otherwise) reaches the first
suggestion as the list opens, so Enter takes it without an arrow first.
`backfill: true` writes each suggestion the keys reach into the field as they
reach it; Escape gives the typing back.

## The field

It is an [Input](input.md) underneath, and takes its `placeholder`,
`allowClear`, `disabled`, `status`, `size`, `autofocus`, `focusNode` and
`semanticsLabel`.

## Design tokens

`AutoCompleteToken` overrides this component's own tokens. Every field is an
override; an unset one falls back to the value derived from the global theme.
The field is styled by `InputToken`, and the panel the suggestions stand in by
`DropdownToken`.

| Token | Default |
| --- | --- |
| `optionActiveBg` | `colorFillSecondary` — the suggestion the keys or the pointer are on |
| `optionColor` | `colorText` |
| `optionPadding` | `sizeSM` across, and as tall as a control |
| `optionFontSize` | `fontSize` |
| `matchWeight` | `fontWeightStrong` — the part that matches the typing |

```dart
AutoComplete(
  // …
  token: const AutoCompleteToken(optionFontSize: 13),
);

// …or for every AutoComplete in a subtree:
ConfigProvider(
  theme: ThemeData(
    components: const ComponentsConfig(
      autoComplete: AutoCompleteToken(matchWeight: FontWeight.w700),
    ),
  ),
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
