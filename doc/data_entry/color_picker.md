# ColorPicker

A colour, chosen from a square of shades, a strip of hues and a strip of
opacity, typed in, or taken from ready ones.

```dart
ColorPicker(
  value: brand,
  onChanged: (c) => setState(() => brand = c),
  showText: true,
)
```

The field is a swatch of the colour; a tap on it, or Enter on it, opens the
panel under it. `ColorPickerPanel` is the same panel standing on its own — in
a page, a drawer, a card:

```dart
ColorPickerPanel(
  value: colour,
  onChanged: (c) => setState(() => colour = c),
)
```

## The panel

| Part | What it does |
| --- | --- |
| The square | Saturation along it, brightness up it, in the hue of the strip |
| The hue strip | The hue, round the wheel |
| The opacity strip | How see-through the colour is, over a chequered pattern |
| The fields | The colour written out: `HEX`, `RGB` or `HSB`, and its opacity in per cent |
| Ready colours | `presets`, under the fields |

The panel keeps the colour as hue, saturation and brightness, so a grey or a
black keeps the hue it was dragged to — and a grey handed in from outside
leaves the hue strip where it stood.

## Value

| Property | What it does |
| --- | --- |
| `value`, `defaultValue` | The colour held from outside, or the one to start with; null is no colour |
| `onChanged` | Called on every change, while a handle is still being dragged; null when cleared |
| `onChangeComplete` | Called once a change is done: a handle let go, a field confirmed, a ready colour taken |

Save in `onChangeComplete` and show in `onChanged`: a drag across the square
calls `onChanged` many times a second.

## Formats

`format` says how the fields write the colour out — `ColorFormat.hex`
(`#1677FF`), `rgb` (0–255 each) or `hsb` (degrees and per cent). Null lets
the panel keep its own, switched by the reader; `onFormatChanged` reports the
switch.

A hex field takes the colour as soon as it writes one, six digits or three,
and keeps the opacity the colour had. A number field takes its number once it
is confirmed or left.

## Opacity

`disabledAlpha: true` keeps colours opaque: the opacity strip and field go,
and any colour taken loses its opacity.

## No colour

`allowClear: true` puts a swatch struck through in red beside the format
switch; it clears the colour to none, and `onChanged` is called with null. The
field then shows the struck-through swatch, and the words "No colour" with
`showText`.

## Copying

`canCopy: true` puts a copy button at the end of the fields. It copies the
colour as the fields write it — `#1677FF`, `rgb(22, 119, 255)` or
`hsb(215, 91%, 100%)`, with its opacity (`rgba(…, 0.5)`, `#1677FF80`) when it
is see-through — and shows a tick for a moment after. A screen reader hears
"Copied". It is off unless asked, and there is nothing to copy while the
colour is none.

`onCopy` is called with the text once it is on the clipboard — to say so in a
message of your own, or to count it. `copyIconBuilder` draws the button's icon,
told whether the colour was just copied; the colour comes from an `IconTheme`
around it, so a plain `Icon` takes it:

```dart
ColorPicker(
  canCopy: true,
  onCopy: (text) => message.success('Copied $text'),
  copyIconBuilder: (context, copied) =>
      Icon(copied ? Icons.check : Icons.content_copy),
)
```

## Ready colours

```dart
ColorPicker(
  presets: const [
    ColorPreset(
      label: 'Brand',
      colors: [Color(0xFF1677FF), Color(0xFF52C41A), Color(0xFFFAAD14)],
    ),
  ],
)
```

A ready colour is taken at once, and ringed while it is the colour. A screen
reader hears it by its hex.

## The field

| Property | What it does |
| --- | --- |
| `showText` | Writes the colour's hex beside the swatch |
| `size` | `SoftSize.small`, `middle` or `large`, or a measurement of your own |
| `disabled` | Greys it out; it does not open |
| `open`, `onOpenChanged` | Holds the panel open or shut from outside |
| `placement` | Where the panel opens (`PopoverPlacement.bottomLeft`) |
| `child` | A trigger of your own in place of the swatch — a button, a chip |

## Keyboard and screen readers

The field is a button; Enter opens the panel. In the panel the square and
each strip are a stop in the tab order: the arrow keys move a handle by one
per cent — along the reading direction, and up and down. A screen reader hears
the strips as sliders — "Hue, 215°", "Opacity, 50%" — and the square by its
saturation and brightness; the field is a button named by `semanticsLabel` —
"Brand colour" — whose value is the colour's hex, or "No colour".

## Defaults for a subtree

`ColorPickerDefaults` sets `format`, `disabledAlpha` and `canCopy` for every
picker and panel below a `ConfigProvider`.

## Design tokens

`ColorPickerToken` overrides this component's own tokens. Every field is an
override; an unset one falls back to the value derived from the global theme.

| Token | Default |
| --- | --- |
| `panelWidth` | seven `controlHeight`s |
| `saturationHeight` | five `controlHeight`s — the square |
| `sliderHeight` | `sizeXS` — the strips |
| `handleSize` | `size` |
| `handleShadow` | a soft shadow in `colorTextQuaternary` |
| `presetSize` | `fontSizeXL` — a ready colour's swatch |
| `gap` | `sizeSM` — between the parts of the panel |
| `borderRadius` | `borderRadiusSM` — the square, the swatches, the trigger |
| `checkerColor`, `checkerSize` | `colorFillSecondary`, `sizeXXS` — the pattern behind a see-through colour |
| `panelBg` | `colorBgElevated` |

```dart
ColorPicker(
  // …
  token: const ColorPickerToken(saturationHeight: 200),
);

// …or for every ColorPicker in a subtree:
ConfigProvider(
  theme: ThemeData(
    components: const ComponentsConfig(
      colorPicker: ColorPickerToken(handleSize: 20),
    ),
  ),
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
