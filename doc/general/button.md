# Button

A pressable button with hover, press, loading and disabled states. Its look is
a **variant** (how it is filled) crossed with a **color** (which palette it
draws from).

```dart
Button(
  variant: ButtonVariant.solid,
  color: ButtonColor.primary,
  onPressed: save,
  child: const Text('Save'),
)
```

## Variants

| `ButtonVariant` | Look |
| --- | --- |
| `solid` | Solid colour fill — the most prominent |
| `outlined` | Neutral fill with a coloured or grey outline (the default) |
| `dashed` | Dashed outline, for adding an item to a list or form |
| `filled` | Tinted fill with a matching border — present but low-key |
| `text` | No chrome until hovered, when a faint fill appears |
| `link` | Coloured label with no chrome, for link-styled navigation |

`text` and `link` never carry a resting background; only `text` shows a faint
fill, and only while hovered or pressed.

## Colors

| `ButtonColor` | Accent |

### A colour of your own

`color` takes a preset or any colour. A preset follows the theme, so a palette
change carries every button with it; a colour of your own is taken as given and
shaded into the same hover, press and disabled states.

```dart
Button(color: ButtonColor.primary, ...)              // follows the theme
Button(color: const ButtonColor(Colors.white), ...)  // a colour of your own
Button(color: ButtonColor.fromString('#fff'), ...)   // the same, as CSS writes it
```

`fromString` accepts `#rgb`, `#rgba`, `#rrggbb` and `#rrggbbaa`, with or
without the `#`. **Alpha goes last**, as CSS writes it — not first, as
`Color(0xAARRGGBB)` does. Anything else throws a `FormatException` naming what
it got, rather than quietly coming out black.

The presets live on `ButtonPreset`, so they can still be switched over
exhaustively:

```dart
final name = switch (color) {
  ButtonCustomColor(:final color) => '$color',
  ButtonPreset.danger => 'danger',
  ButtonPreset() => 'a preset',
};
```
| --- | --- |
| `defaultColor` | Neutral (grey outline, dark solid); hovers to the primary colour |
| `primary` | The theme's primary |
| `danger` | Error red, for destructive actions |
| `success` | Success green |
| `warning` | Warning amber |

Any variant can pair with any color:

```dart
Button(variant: ButtonVariant.solid,   color: ButtonColor.danger,  onPressed: del, child: const Text('Delete'))
Button(variant: ButtonVariant.filled,  color: ButtonColor.primary, onPressed: () {}, child: const Text('Filled'))
Button(variant: ButtonVariant.outlined, onPressed: () {}, child: const Text('Default'))
```

## Properties

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget?` | `null` | Label; omit with `icon` set for an icon-only button |
| `onPressed` | `VoidCallback?` | `null` | Tap handler; null disables the button |
| `variant` | `ButtonVariant?` | `null` | Follows `ButtonDefaults.variant`, else `outlined`. How the button is filled |
| `color` | `ButtonColor?` | `null` | A preset, or a colour of your own. Follows `ButtonDefaults.color`, else `defaultColor` |
| `size` | `SoftSize` | `middle` | `small` (24), `middle` (32), `large` (40) |
| `shape` | `ButtonShape?` | `null` | Follows `ButtonDefaults.shape`, else `defaultShape`. `defaultShape`, `circle`, `round` |
| `icon` | `Widget?` | `null` | Leading icon, tinted and sized to the label |
| `loading` | `bool` | `false` | Swaps the icon for a spinner and blocks taps |
| `gradient` | `Gradient?` | `null` | Optional background gradient (e.g. `LinearGradient`) |
| `block` | `bool` | `false` | Stretches to the parent's full width |
| `disabled` | `bool?` | `null` | Follows the provider's `componentDisabled`, else `false`. Greys out and blocks taps |

## Sizes

```dart
Button(size: SoftSize.large, variant: ButtonVariant.solid, color: ButtonColor.primary, onPressed: () {}, child: const Text('Large'))
```

## Icons

An `icon` with a `child` renders as a leading icon; an `icon` with no `child`
makes a square — or, with `ButtonShape.circle`, a round — icon-only button.
The icon inherits the button's foreground colour and font size.

```dart
Button(
  variant: ButtonVariant.solid,
  color: ButtonColor.primary,
  shape: ButtonShape.circle,
  icon: const Icon(Icons.search),
  onPressed: onSearch,
)
```

## Loading

`loading: true` replaces the icon with a [Spinner](../feedback/spinner.md) and blocks
taps, so a submit handler cannot fire twice.

> A button rendered with `loading: true` animates forever, so widget tests
> covering it must not call `pumpAndSettle`. See
> [testing](../../README.md#testing-against-the-kit).

## Migrating from `type`

The old `type` + `danger` API maps to variant + color:

| Old | New |
| --- | --- |
| `type: primary` | `variant: solid, color: primary` |
| `type: default` | `variant: outlined` |
| `type: dashed` | `variant: dashed` |
| `type: text` | `variant: text` |
| `type: link` | `variant: link, color: primary` |
| `danger: true` | `color: danger` |

## Design tokens

`ButtonToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
Button(
  // …
  token: const ButtonToken(),
);

// …or for every Button in a subtree:
ConfigProvider(
  components: const [ButtonToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
