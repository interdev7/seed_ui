# Slider

A groove with a handle, for choosing a number by dragging.

```dart
Slider(value: _volume, onChanged: (v) => setState(() => _volume = v))
```

`Slider` clashes with Material's own. Hide one of them at the import:

```dart
import 'package:flutter/material.dart' hide Slider, RangeSlider;
```

## The scale

`min` and `max` bound it and `step` is how finely the handle moves:

```dart
Slider(value: _v, min: 0, max: 10, step: 0.5, onChanged: _set)
```

A **null** `step` lets the handle rest only on the marks — and on the ends of
the scale, which are always stops:

```dart
Slider(
  value: _v,
  step: null,
  marks: const [SliderMark(20, Text('low')), SliderMark(80, Text('high'))],
  onChanged: _set,
)
```

## Marks and dots

`marks` writes labels under the points they name, each centred on its own
value. `dots` marks every step rather than only the labelled ones.

`included` decides whether the groove is filled up to the handle. False leaves
it plain — for a slider that names a point rather than an amount.

## Two handles

`RangeSlider` carries a pair and fills the span between them:

```dart
RangeSlider(values: _price, onChanged: (v) => setState(() => _price = v))
```

It is a separate widget rather than a flag on `Slider`, because what the two
carry differs in type: one holds a number and the other a pair, and a single
widget would have to take a value that is sometimes either.

A drag takes hold of the handle it began nearest and keeps it for the whole
gesture, so one pushed past its neighbour follows the finger rather than being
handed over halfway. The pair is always reported low first.

## Which way it runs

`vertical` runs the scale down the page, from the bottom as a measure does.
With marks it is as wide as the groove, the gap and the widest label together,
measured from the labels themselves — so it takes real room in a row rather
than overflowing it.

`reverse` starts it at the far end. Reading right to left already turns the
scale round, so `reverse` flips it back rather than naming a side — the only
rule under which `reverse` means the same thing in both reading directions.

| | `reverse: false` | `reverse: true` |
| --- | --- | --- |
| left to right | starts at the left | starts at the right |
| right to left | starts at the right | starts at the left |

## The keys

Tab to the slider and the arrows along the groove move the handle one step —
`step`, or a hundredth of the scale when that is null. The key that points
along the groove is the one that advances the value, so a mirrored scale
answers the same key the other way.

The arrows move whichever handle the pointer last touched, which is the first
one until something else is picked up.

## The bubble

While a handle is being moved its value is shown above it. `tooltip` decides
what that says, and returning null says nothing at all:

```dart
Slider(value: _v, tooltip: (v) => '${v.round()}%', onChanged: _set)
```

It is drawn inside the slider rather than in an overlay: it has to follow a
handle that moves every frame, and an overlay entry would be torn down and
rebuilt for each one. An ancestor that clips will clip it too.

## Properties

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `value` / `values` | `double` / `(double, double)` | required | Where the handle stands |
| `onChanged` | `ValueChanged?` | `null` | Called as it moves; null makes it read-only |
| `onChangeComplete` | `ValueChanged?` | `null` | Called once the gesture ends |
| `min` | `double` | `0` | The bottom of the scale |
| `max` | `double` | `100` | The top of it |
| `step` | `double?` | `1` | How far one move takes it; null means the marks |
| `marks` | `List<SliderMark>` | `[]` | Points written along the scale |
| `dots` | `bool` | `false` | Dot every step, not only the marked ones |
| `included` | `bool` | `true` | Whether the groove is filled |
| `disabled` | `bool` | `false` | Greys it out and blocks dragging |
| `vertical` | `bool` | `false` | Runs the scale down the page |
| `reverse` | `bool` | `false` | Starts it at the far end |
| `tooltip` | `String? Function(double)?` | `null` | What the bubble says |
| `token` | `SliderToken?` | `null` | Per-instance token overrides |

## Tokens

`SliderToken`: `railSize`, `handleSize`, `handleSizeHover`, `dotSize`,
`handleLineWidth`, `handleLineWidthHover`, `railBg`, `railHoverBg`, `trackBg`,
`trackHoverBg`, `handleColor`, `handleActiveColor`, `handleColorDisabled`,
`trackBgDisabled`, `dotBorderColor`, `dotActiveBorderColor`.

The handle is a quarter of the large control height, so it grows with the
theme's own scale rather than carrying a number of its own. Its ring is drawn
outside the disc, the way a focus shadow sits, so the handle keeps the
diameter its token names.

```dart
Slider(value: _v, token: const SliderToken(railSize: 8), onChanged: _set)
```

…or every slider under a subtree through `ConfigProvider`:

```dart
ConfigProvider(
  theme: ThemeData(components: ComponentsConfig(
    slider: SliderToken(handleSize: 14),
  )),
  child: const MyApp(),
)
```

## Not yet

Editable range nodes — `minCount`, `maxCount` and a draggable track — are not
here.
