# Input

A single- or multi-line text field: a bordered box that brightens to the
primary colour on focus, with optional affixes, a clear button and validation
statuses.

```dart
Input(
  placeholder: 'Username',
  prefix: Icon(Icons.person_outline),
  allowClear: true,
  onChanged: (value) => setState(() => _name = value),
)
```

## Value: controlled or not

Like a Flutter `TextField`, `Input` works either way:

- **Uncontrolled** — omit `controller` and read edits through `onChanged`. The
  field owns its own controller.
- **Controlled** — pass a `controller` to read the current text or set it
  programmatically.

```dart
final controller = TextEditingController();
// ...
Input(controller: controller);
controller.text = 'preset';          // set
final value = controller.text;       // read
```

For an uncontrolled field with initial text, pass `defaultValue` (it seeds the
field's own controller and is ignored when a `controller` is supplied):

```dart
Input(defaultValue: 'Hello, seed!')
```

Pass a `focusNode` to control focus externally, or leave it null and the field
manages its own.

## States

| Property | Effect |
| --- | --- |
| `disabled` | Greys out; blocks editing and focus |
| `readOnly` | Shows the value, blocks editing, but stays focusable and selectable |
| `status` | `InputStatus.error` / `.warning` recolour the border |

```dart
Input(status: InputStatus.error, controller: emailController)
```

The border follows interaction: grey at rest, primary on hover, brighter with a
soft focus ring when focused — recoloured to the status when one is set.

## Sizes

`size` takes either a preset or a measurement of your own.

The presets are `small` (24px), `middle` (32px, default) and `large` (40px),
from the control height tokens. Large also bumps the font size.

```dart
Input(size: SoftSize.large, placeholder: 'Large')
Input(size: ControlSize.height(36), placeholder: '36 tall')
```

A preset carries a type size with it; a bare measurement names only itself, so
the standard type, padding and radius stand. The text stays centred at any
height — the box holds the height up, the padding only adds air inside it —
so a measurement past either end of the preset scale is safe.

`ControlSize.box(200, 36)` names the width too, so it needs no `SizedBox`
around it. `fixed()` names only a height — a field given one goes on filling
the width it is offered, since a text input has nothing to measure itself
against.

## Affixes

`prefix` and `suffix` sit inside the border, tinted as secondary content:

```dart
Input(
  prefix: Icon(Icons.search),
  suffix: Text('.com'),
  placeholder: 'Domain',
)
```

## Clear button

`allowClear: true` shows a clear button while the field is focused and
non-empty; tapping it empties the field and fires `onChanged('')`.

```dart
Input(allowClear: true, placeholder: 'Search')
```

## Password

Pass a `PasswordConfig` to mask the text and, by default, add a reveal toggle:

```dart
Input(placeholder: 'Password', password: PasswordConfig())
```

| `PasswordConfig` field | Type | Default | Description |
| --- | --- | --- | --- |
| `visibilityToggle` | `bool` | `true` | Whether the reveal toggle is shown |
| `iconRender` | `Widget Function(bool visible)?` | `null` | Custom toggle glyph; `visible` is whether the text is revealed |
| `onVisibleChange` | `ValueChanged<bool>?` | `null` | Called when visibility toggles; receives the new `visible` state |

## Character count

A `CountConfig` shows a counter beside the field. Its `max` is a **soft** limit:
exceeding it marks the field with a warning but does **not** truncate — unlike
`maxLength`, which hard-caps while typing.

```dart
// Warn (but keep the text) past 10 characters.
Input(defaultValue: 'Hello, seed!', count: CountConfig(show: true, max: 10))
```

`strategy` customises how characters are counted — the default counts UTF-16
code units, so pass a grapheme counter to make an emoji count as one:

```dart
Input(
  defaultValue: '🔥🔥🔥',
  count: CountConfig(show: true, strategy: (t) => t.characters.length),
)
```

`exceedFormatter` clips the value when it passes `max` (without it the field is
only warned, never cut):

```dart
Input(
  defaultValue: '🔥 seed',
  count: CountConfig(
    show: true,
    max: 6,
    strategy: (t) => t.characters.length,
    exceedFormatter: (t, max) => t.characters.take(max).toString(),
  ),
)
```

| `CountConfig` field | Type | Default | Description |
| --- | --- | --- | --- |
| `show` | `bool` | `false` | Render the counter beside the field |
| `max` | `int?` | `null` | Soft limit; warns but does not truncate |
| `strategy` | `int Function(String)?` | UTF-16 length | Custom counting |
| `formatter` | `Widget Function(CountArgs)?` | `null` | Custom counter widget |
| `exceedFormatter` | `String Function(String, int)?` | `null` | Clip logic past `max` |

## Search

A `SearchConfig` turns the field into a search box that reports the value
through `onSearch` (fired on click or when the user presses Enter):

```dart
Input(
  placeholder: 'Search',
  search: SearchConfig(
    enterButton: true,
    onSearch: (value) => runSearch(value),
  ),
)
```

`enterButton: false` (the default) shows a plain magnifier inside the field;
`true` attaches a primary search button; `enterButtonLabel` gives that button a
custom label. Set `loading: true` to show a spinner while a search runs, and
`searchIcon` to replace the magnifier glyph.

| `SearchConfig` field | Type | Default | Description |
| --- | --- | --- | --- |
| `enterButton` | `bool` | `false` | `true` attaches a primary search button |
| `enterButtonLabel` | `Widget?` | `null` | Custom label for the attached button |
| `loading` | `bool` | `false` | Show a spinner on the search control |
| `onSearch` | `ValueChanged<String>?` | `null` | Called on click or Enter |
| `searchIcon` | `Widget?` | `null` | Replaces the magnifier glyph |

## Text area

A `maxLines` above 1 (or null for unbounded) turns the field into a text area,
growing up to `maxLines` before scrolling. Use `minLines` for a taller start:

```dart
Input(maxLines: 6, minLines: 3, placeholder: 'Notes')
```

## Constraints and formatting

| Property | Description |
| --- | --- |
| `maxLength` | Caps the number of characters |
| `keyboardType` | The soft-keyboard type |
| `textInputAction` | The action key (done, next, …) |
| `inputFormatters` | Standard Flutter `TextInputFormatter`s |
| `onSubmitted` | Called on submit |

```dart
Input(
  keyboardType: TextInputType.number,
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  maxLength: 6,
  placeholder: 'Code',
)
```

## Notes

The field is built on Flutter's `EditableText` with platform-appropriate
selection handles (Cupertino on Apple, Material elsewhere), so selection,
autofill and the system keyboard behave natively in both Material and Cupertino
apps.

## Other properties

- `autofocus` — focuses the field as soon as it appears.
- `textAlign` — horizontal alignment of the text and placeholder.
- `suffixFlush` — renders `suffix` flush against the inner right border (no
  gap, tint or padding), for full-height affixes such as an `InputNumber`
  stepper or an attached button. Such an affix is clipped to the box's own
  corner, so a hover or pressed fill cannot spill past the rounding.

## Design tokens

`InputToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
Input(
  // …
  token: const InputToken(),
);

// …or for every Input in a subtree:
ConfigProvider(
  components: const [InputToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
