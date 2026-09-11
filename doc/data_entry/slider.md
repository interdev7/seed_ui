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

`marks` writes labels by the points they name, each centred on its own value.
`dots` marks every step rather than only the labelled ones.

```dart
Slider(
  marks: const [
    SliderMark(0, 'cold'),
    SliderMark(37, 'body', side: SliderMarkSide.before),
    SliderMark(60, 'hot', disabled: true),
    SliderMark.dot(80),
  ],
)
```

**The label is a string**, because nearly every mark is one. For the rest,
`markBuilder` is handed what the slider would have drawn — wrap it and the
mark keeps its colour, its size and its state for nothing:

```dart
SliderMark(
  80,
  '80%',
  markBuilder: (context, mark, active, child) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [child, if (active) const Icon(Icons.check, size: 12)],
  ),
)
```

`active` is whether the handle has reached that mark.

**A mark is a widget, so anything can be wrapped around it** — a menu, a
popover, a tooltip of your own:

```dart
SliderMark(
  60,
  'booked',
  markBuilder: (context, mark, active, child) => Dropdown<String>(
    trigger: const [DropdownTrigger.click],
    menu: const [DropdownItem(value: 'free', label: 'Free it up')],
    onItemTap: (value) => ...,
    child: child,
  ),
)
```

It is `markBuilder` and not `labelBuilder` because a mark with no words has no
label to build — and that is exactly the mark somebody wants to hang a menu
on. For one of those the builder is handed a box the size of a dot, **standing
on the rail where the dot is**, because the dot is the thing anybody would
press. Put in the band with the labels, it would sit under an invisible patch
of nothing while the thing you can see stayed dead.

**A mark takes a pointer only where it has been given something to do.** A
plain mark takes none: its label sits in the band beside the rail, never over
it, so pressing the scale still moves the handle wherever the marks are. A
mark with a `markBuilder` and no words takes the pointer at its own dot —
which is the point of hanging a menu on it.

The band is as tall as the tallest thing in it. Told a height instead, as it
used to be, anything taller hung out of it — drawn, since the band does not
clip, and dead to the pointer, since a hit outside a box is no hit. A popover
on a mark worked in its top half and nowhere else.

**`side` names the flow, not the screen.** `before` is above the rail across a
row and the leading side down a column; `after` is the other, and is where a
mark goes unless it says otherwise. Top, bottom, left and right would leave
two of the four meaning nothing on any given slider, and an API that can say
something impossible will eventually be asked to.

**`hidden` leaves a mark undrawn without taking it out of the list** — a
hidden column keeps its place among a table's columns for the same reason: a
mark shown and hidden again is the same mark.

**`disabled` means the handle may not rest there.** It bites where the marks
are the only places to rest — a slider with no `step` — and there the handle
passes the stop by. Given a step, the handle stops at steps rather than at
marks, and a disabled mark is only greyed.

`SliderMark.dot` is a stop with nothing to say: not every step, so `dots` will
not do, and possibly `disabled`.

Marks are value types with `copyWith`, so changing one is a list you rebuild
rather than a controller you hold:

```dart
setState(() => marks = [
  for (final m in marks) m.value == 60 ? m.copyWith(disabled: false) : m,
]);
```

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

## A span you can take hold of

```dart
RangeSlider(values: (20, 60), draggableTrack: true, onChanged: ...)
```

The filled span moves as one, keeping its length. **A handle always wins**:
the span is taken only where the press lands on no handle at all, so every
handle keeps its own drag — including one standing in the middle of the span,
which a track asked by value rather than by handle would swallow.

Pushed against an end of the scale the shift is cut back as one, so the span
stops whole rather than the leading handle stopping while the trailing one
goes on.

A tap moves the nearest handle **on the way up**, not on the way down: a press
is not yet a tap, and a slider that acted at once had already moved a handle
under the finger by the time a drag began — leaving the span no longer under
the press, and nothing to take hold of.

## Handles you can put in and take out

```dart
MultiRangeSlider(
  values: _bands,
  minCount: 2,
  maxCount: 5,
  onChanged: (v) => setState(() => _bands = v),
)
```

Its own component rather than a flag on `RangeSlider`: a pair of handles is a
`(double, double)` and this is a `List<double>`, and a list of two is not the
same promise as a pair. A control that had to be both would hand back a type
its caller has to check.

**A tap on the rail puts a handle in. Dragging a handle onto its neighbour
takes it out** — the two meet, one goes, and the handle is drawn faint on the
way so letting go is never a surprise. They count as met once the discs cover
one another, not once their values are equal: half a step on a scale of a
hundred is two pixels of rail, and a catch nobody can hit is a gesture nobody
finds. Nothing is decided until the finger
lifts, so bringing it back off the neighbour simply keeps it.

A tap on a handle does nothing: it is already where it is being asked to go.

Why that gesture and not another. A second tap would make a handle a switch —
press it twice and you are back where you started — and registering a double
tap holds the first one back behind its window, so putting a handle in would
wait for a tap that is usually not coming. A press held fires on a timer,
takes the drag out of the running, and carries a handle off under the finger
of anybody who pauses before moving it. Pulling a handle away from the rail is
not available at all: a one-axis drag recogniser reports nothing about the
other axis, and a pan would lose the arena to any page the slider is scrolled
inside.

The slider is not the only way out. The whole list comes back through
`onChanged`, so an app with room for it can put its own control beside the
scale — a chip per handle, a menu, a button — and hand back a list one
shorter. The gesture is there for the app that has no room for that.

What it costs is two handles left standing on the same value. For a control
whose handles are the edges between bands, two edges in one place is a band of
nothing — so the trade is the right way round.

`minCount` is two at the least: one handle is a `Slider`, and a range with one
end is not a range. `maxCount` refuses the next one; left null there is no
ceiling.

The values come back **in order**, however they were dragged or added — a
handle pushed past its neighbour would otherwise change what "the third band"
means halfway through a drag.

## A stretch that means something

```dart
Slider(
  min: 40,
  max: 200,
  included: false,
  zones: const [
    SliderZone(120, 160, color: Color(0x3300B42B)),
    SliderZone(160, 200, color: Color(0x33FF4D4F)),
  ],
)
```

A mark names a point; a zone names a run — a safe heart rate, a budget
already spent, the hours a shop is open. A zone written backwards means the
same stretch.

Zones are drawn **on the rail and under the track**: the zone colours the
scale, and the track is the answer. A slider that is mostly zones is one to
turn `included` off for, or the answer covers what it is measured against.

## How far the handle may go

```dart
Slider(min: 0, max: 24, bounds: (9, 17))
```

The scale still shows what it showed — a day is still twenty-four hours long,
and its marks are all still written — and the handle simply cannot be put
outside the part on offer. Narrowing `min` and `max` would hide the rest of
the day, which is not the same thing to say.

A draggable span obeys it too: the whole span stops at the bound rather than
one end of it going on.

## Resting on the marks as well as the steps

```dart
Slider(step: 1, snapToMarks: true, marks: [SliderMark(33.4, 'a third')])
```

Without a `step` the marks are already the only stops there are. With one they
were nothing but writing — a mark at 33.4 on a scale of whole numbers could
be read and never reached. Asked for, whichever of the two is nearer to the
finger wins.

A mark the handle may not rest on is no magnet either: `disabled` means what
it says here too.

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
| `zones` | `List<SliderZone>` | `const []` | Stretches of the scale, coloured |
| `bounds` | `(double, double)?` | `null` | How far the handle may go, within the scale |
| `snapToMarks` | `bool` | `false` | Rest on the marks as well as on the steps |
| `included` | `bool` | `true` | Whether the groove is filled |
| `disabled` | `bool` | `false` | Greys it out and blocks dragging |
| `vertical` | `bool` | `false` | Runs the scale down the page |
| `reverse` | `bool` | `false` | Starts it at the far end |
| `tooltip` | `String? Function(double)?` | `null` | What the bubble says |
| `token` | `SliderToken?` | `null` | Per-instance token overrides |

## Design tokens

`SliderToken`: `railSize`, `handleSize`, `handleSizeHover`, `dotSize`,
`handleLineWidth`, `handleLineWidthHover`, `railBg`, `railHoverBg`, `trackBg`,
`trackHoverBg`, `handleColor`, `handleActiveColor`, `handleColorDisabled`,
`trackBgDisabled`, `dotBorderColor`, `dotActiveBorderColor`, `markColor`,
`markDisabledColor`, `markFontSize`.

A mark's colour and size live here rather than on the mark, where only the odd
one that has to stand out from the rest keeps a `style` of its own.

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

## Not here yet

**A bubble that stays put.** The one over a handle shows only while the
handle is being moved, so that a bubble left standing does not sit over
whatever the slider is labelled with. A slider that wants its value on show
at all times writes it beside itself.

**Marks the reader can drag.** They are data the caller owns, which is why
there is no controller for them; the moment a reader could move one, the
slider would own something of its own and would need one. That is the piece
of work, not the controller.
