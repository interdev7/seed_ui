# Steps

A progress indicator for a task with stages. The rail
behind the current step is drawn in the accent, ahead of it in the split colour,
and each marker takes its look from its status.

```dart
Steps(
  current: _step,
  onChange: (index) => setState(() => _step = index),
  items: const [
    StepItem(title: Text('Cart'), content: Text('3 items')),
    StepItem(title: Text('Payment')),
    StepItem(title: Text('Done')),
  ],
)
```

Where [Timeline](timeline.md) records events that already happened, this
measures a journey that is still going. The two share only their rail — the same
[`RailPainter`](../../lib/src/utils/rail.dart) draws both — and nothing above it.

## Anatomy

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<StepItem>` | required | The steps, in order |
| `current` | `int?` | `null` | The step in play (controlled) |
| `defaultCurrent` | `int` | `0` | Starting step when uncontrolled |
| `controller` | `StepsController?` | `null` | Drives the run from outside |
| `onChange` | `ValueChanged<int>?` | `null` | Fires with the step a tap landed on |
| `initial` | `int` | `0` | Number the first step from here |
| `orientation` | `StepsOrientation` | `horizontal` | Which way the run goes |
| `type` | `StepsType` | `standard` | How it is drawn |
| `variant` | `StepsVariant` | `filled` | Filled or outlined markers |
| `size` | `ControlSize?` | `null` | Follows the provider's `componentSize`, else `SoftSize.middle`; or a number for the marker's diameter |
| `status` | `StepStatus` | `process` | Status of the current step |
| `titlePlacement` | `StepTitlePlacement?` | `null` | Title beside the marker or under it |
| `percent` | `double?` | `null` | Progress ring on the current marker, 0..1 |
| `progress` | `Progress?` | `null` | Template for that ring |
| `responsive` | `bool` | `true` | Stand up when the space is too narrow |
| `maxCount` | `int?` | `null` | Fold a longer run down to this many slots |
| `overflow` | `StepsOverflow` | `scroll` | Scroll when the steps will not fit, or fold to what does |
| `token` | `StepsToken?` | `null` | Per-instance token overrides |

### StepItem

| Property | Type | Description |
| --- | --- | --- |
| `title` | `Widget?` | The step's name |
| `subTitle` | `Widget?` | A short aside beside the title |
| `content` | `Widget?` | Supporting text under it |
| `icon` | `Widget?` | Replaces the marker's number |
| `status` | `StepStatus?` | Forces this step's status |
| `disabled` | `bool` | Blocks tapping this step |

## Layout of a horizontal step

Marker, then the title beside it, the content under the title, and the rail
carrying on from there to the next step — centred on the marker, not on the
text. The text is measured first and the rail takes what is left, so a title
only wraps when it genuinely has to.

The header is a band as tall as the taller of the marker and one line of title,
with the marker and the rail centred in it. Centring them on the title
instead holds only while every title is one line: let one wrap — a narrow
run with `responsive: false` — and each step centres on its own height, turning
the run into a staircase. A wrapped title grows downwards out of the band, and
every marker stays on one axis.

## The rail is a separator

The line between two markers keeps a gap at both ends — it separates steps
rather than growing out of a circle. The gaps
are measured per orientation: a wide one along a horizontal run, a narrow one down
a vertical one where the markers already sit close together, and none at all for
`inline`, whose steps sit shoulder to shoulder.

A rail is painted as a rect snapped to the pixel grid, not as a stroked line:
a hairline centred on a whole coordinate straddles two rows of pixels and comes
out as two half-strength lines — which reads as a pale line under a paler one
rather than one clean line.

A rail never shrinks below `railMinLength` (32 by default). Squeezed, it is the
gaps that give way, not the line: a few pixels of line between two markers read
as a speck of dirt rather than a connection, so the room at its ends goes first.

`railInset` on the token overrides the gaps, one end at a time — it is a
[`RailInsets`](../../lib/src/utils/rail.dart), the same value type
[Timeline](timeline.md) takes:

```dart
const StepsToken(railInset: RailInsets.all(8))                // every end
const StepsToken(railInset: RailInsets.horizontal(left: 0))   // flush at the marker it leaves
const StepsToken(railInset: RailInsets.symmetric(vertical: 4))
```

A side left null keeps the default for that end, so naming one changes one.

## Status

`StepStatus` is `wait`, `process`, `finish` or `error`. A step works its own out
from where it sits relative to `current` — behind it is `finish`, on it is the
run's `status`, ahead of it is `wait` — and an item that names a `status` of its
own overrides that.

Setting the run's `status` to `error` is how a stalled process reads: the current
marker turns red and keeps its place.

```dart
Steps(current: 2, status: StepStatus.error, items: items)
```

## Driving the run

Three ways, matching the rest of the kit:

```dart
// Controlled.
Steps(current: _step, onChange: (i) => setState(() => _step = i), items: items);

// Uncontrolled — the run remembers where it is.
Steps(defaultCurrent: 0, onChange: (_) {}, items: items);

// Imperative, for a wizard whose buttons live elsewhere.
final steps = StepsController();
Button(onPressed: steps.next, child: const Text('Next'));
Steps(controller: steps, items: items);
```

`StepsController` exposes `current`, `next()`, `previous()` and `goTo(index)`,
and is a `ChangeNotifier` — listen to it to keep a "Next" button in step. It
clamps to the steps that exist, so `next()` on the last one does nothing.
Dispose it with the widget that owns it.

Taps only do anything when `onChange` or a `controller` is present; a plain
`Steps(current: …)` is a read-only indicator. Individual steps opt out with
`disabled`.

## Types

| `StepsType` | Look |
| --- | --- |
| `standard` (default) | Numbered markers, titles and content |
| `dot` | Small dots, titles underneath |
| `inline` | The dot run in miniature: small dots, muted one-line titles, no content, rails edge to edge |
| `navigation` | Tappable blocks split by chevrons, the current one underlined |
| `panel` | Each step in its own panel |

## The progress ring

`percent` draws a progress ring around the current marker — a step that is
itself measurable, such as an upload. It belongs to the numbered types, since
a dot has nothing to ring.

The ring is the kit's own [`Progress`](../feedback/progress.md), with the marker
riding in its middle as a `child`, so anything that component can do is
available here. Pass one as a template to `progress`: its type, colours, stroke
and gap are kept, while the value and the marker are filled in.

```dart
Steps(
  current: 1,
  percent: 0.6,
  progress: Progress(
    percent: 0,          // stood in for by `percent` above
    type: ProgressType.dashboard,
    color: Colors.orange,
    strokeWidth: 4,
  ),
  items: items,
)
```

A run with a ring reserves the extra room for **every** step, not only the one
wearing it — otherwise the marker slot would squeeze the ring back down to the
marker and hide it, which is what a phone-width (vertical) run does to a
horizontal one. `stepsRingPadding` is how much wider the ring sits.

A template on its own carries the value: `progress: Progress(percent: 0.6,
type: ProgressType.circle)` needs no `percent`. A `ProgressType.line` template
is refused — a bar has no middle to hold a marker.

## Navigation

Tappable blocks split by chevrons, the current one underlined. `size` scales a
block whole — marker, type and padding — and `itemWidth` / `itemHeight` set a
block's size outright in place of the size its text asks for:

```dart
Steps(
  type: StepsType.navigation,
  items: items,
  size: SoftSize.large,
  token: const StepsToken(itemWidth: 160),
)
```

## Panels

A horizontal panel run is a strip of arrow-shaped segments: each panel points at
the next and its neighbour is notched to receive the point, following a plain
`M 0 0 L 100 50 L 0 100` path. The
marker is dropped here — the panel itself carries the state through its fill —
and `panelArrowWidth` on the token sets how far the point reaches.

The colours come from the status, derived from the marker:
the step in play is solid with white text, a finished one takes the accent tint,
a failed one the error tint, and the ones ahead stay grey. In the `outlined`
variant the fills are washed and each panel is outlined in its own status
colour, arrow included.

```dart
Steps(type: StepsType.panel, variant: StepsVariant.outlined, items: items)
```

Every panel *and* the arrow between them is stroked, so an outlined run
comes out with doubled seams. Here the whole strip is painted in one pass: a
panel draws its own top, bottom and outer end, and each join is drawn once as a
seam of its own. That is not a rule to remember but a structure, and
`test/steps_test.dart` counts the actual stroke calls to keep it that way.

Drawing a join once means choosing whose colour it takes. The **selected panel
wins**: its outline is the one the eye follows, so the chevron in front of it
carries the accent rather than keeping the previous step's grey. Everywhere else
the join belongs to the panel it grows out of.

A vertical run is the same shape turned a quarter: each panel points **down**
into the next, which is notched to take it. The panels keep the shape they have
across the page — as wide as the widest of them and no wider, all of them equal.
A `Column` left to itself takes every pixel its parent offers, which in a
stretch parent blows one panel across the screen and leaves its arrow pointing
down a canyon; the strip shrink-wraps instead, down to the same
`panelMinWidth` floor and up to the width it is offered.

### Fitting the space

Panels are as wide as their text needs — the longest title or line of content in
the run sets the width, and every panel takes it, so the strip stays even.
Given more room than that they share it; given less, the strip keeps its size
and scrolls horizontally rather than crushing four panels into a hundred pixels.

`panelMinWidth` (160, or 120 in a small run) is the floor under that: the least
a panel may be, however short its text. It is a floor, not a width — where there
is room to spare, raising it changes nothing until the panels would have been
narrower than it.

`panelWidth` and `panelHeight` replace the measuring outright:

```dart
Steps(
  type: StepsType.panel,
  items: items,
  token: const StepsToken(panelWidth: 200, panelHeight: 96),
)
```

A named width is kept whatever room there is — the strip does not stretch to
fill the page — and both work down a vertical run as well.

```dart
Steps(
  type: StepsType.panel,
  items: items,
  token: const StepsToken(panelMinWidth: 100),
)
```

`size` reaches the panels as well: `SoftSize.small` tightens the padding to
`sizeXS`, takes the small corner radius, shortens the arrow and lowers the width
floor to 120. `panelPadding`, `panelRadius`
and `panelArrowWidth` tune the rest of the shape.

## Hover

On a clickable run, hovering anywhere on a step — its marker, title or content —
answers on the whole step:

- the **title and content** take the hover shade of the status's own family, so
  a failed step lifts to `error.hover` rather than turning blue;
- the **marker** lifts too — a filled one to the accent's hover tint, an
  outlined one to the hover outline and ink.

Every one of those changes is animated, not switched: the marker eases over the
mid duration, the text over the slow one. The
fills are composited onto the surface first — a translucent neutral animated to
an opaque tint dips through a dark grey on the way, which reads as a flash.

The step **in play** is left alone — the rule is `:not(-active):hover`,
and for good reason — its colours are what the component is saying, and they
must not wobble under the pointer.

A step's hit area is the step, not the row it sits in. A vertical run is as wide
as its parent, but each step shrink-wraps to its marker and text, so the pointer
has to actually be over it.

## Size

`size` is the run's scale, not the dots' — it sets the marker's diameter and the
type beside it, and in a panel run the padding, the corner radius, the arrow and
the width floor.

| `size` | Marker | Type |
| --- | --- | --- |
| `SoftSize.small` | 24 | The compact run |
| `SoftSize.middle` | 32 | The default |
| `SoftSize.large` | 40 | The kit's third step |
| `ControlSize.height(48)` | 48 | Follows the marker: ≤26 small, ≥38 large |
| `ControlSize.width(48)` | 48 | The marker is a circle, so a width names that same diameter |

```dart
Steps(size: SoftSize.large, items: items);
Steps(size: const ControlSize.height(48), items: items);
```

Dot markers keep their own sizes (`dotSize`, `dotCurrentSize`) whatever `size`
says: a dot is a dot.

## Rail length

Left alone, the rail is the give in the layout: the steps take the width their
text needs and the rail fills what is left, so between a long title and a short
one the rails differ. `railLength` names the length instead — of the **line you
see**, with `railInset`'s gaps sitting outside it, not eaten out of it:

```dart
Steps(items: items, token: const StepsToken(railLength: 120))
```

It is the shortest the line may be, not a cap. A step whose content is wider
than its header — a long description under a short title — takes the width it
needs, and the rail stretches to cover the difference: a rail that stops short
of the next marker is a broken rail, whatever the token says. Where the header
is the wider of the two, the length is exactly what you asked for. The run
scrolls when the steps together outgrow the room.

Down a vertical run it fixes the drop between two markers the same way, growing
only when the step's own text is taller.

## Folding a long run

`maxCount` caps how many steps are on screen at once — the
`maxCount`. A longer run keeps the first step, the last, the one in play and as
many of its neighbours as the cap allows; each stretch of hidden steps collapses
into a single ellipsis marker.

```dart
Steps(maxCount: 5, current: _step, onChange: ..., items: nineSteps)
```

The slots fill in order — the current step's neighbours first, then
one in from each end, then the same again a step further out. With nine steps
and `maxCount: 5`, standing on step 4: `1 … 3 4 5 … 9`.

Three things follow from the fold:

- **The indexes never change.** `onChange` and the controller speak in the
  indexes of `items`, not of what is drawn, so a tap on the last step reports
  the last step.
- **A marker keeps its own number.** The circle above "Step 9" says 9, not its
  place in the folded list. Numbering by position instead would put a 4 over
  a title reading "Step 9".
- **An ellipsis is not a step.** It is disabled, and tapping it does nothing.
- **It carries what it hides.** A failure among the hidden steps turns the
  ellipsis red; a stretch entirely behind the current step reads as finished.

### Folding to fit

`overflow: StepsOverflow.fold` works the cap out from the room instead of
taking it from you: the run counts how many steps fit at the least a step may
take, folds the rest away, and so never scrolls.

```dart
Steps(overflow: StepsOverflow.fold, items: items, current: _step)
```

It answers to the room, so the same run shows six steps on a desktop and three
on a phone, and a vertical run counts by the height it is given. An explicit
`maxCount` still wins — naming a number means you meant it. Folding stops at
three, and where even three will not fit the run scrolls after all: the mode
promises a layout that does not break, not one that never scrolls.

A `maxCount` below three is ignored — first, current and last already take three
slots — as is one no shorter than the run itself.

## A narrowing run

A horizontal run fills the width it is given and shares it out equally. As that
width shrinks it has three answers, in order of what each costs the reader:

1. **Text beside the marker** — the roomy layout, while the titles fit.
2. **Text under the marker** — below that, the run stacks itself: markers on one
   line with the rails between them, title and content centred underneath. No
   marker column to pay for, so the text gets the whole step.
3. **Scroll** — only when even a stacked step is below its floor does the run
   stop sharing and keep its own size, scrolling sideways.

The decision is taken once for the whole run: half the steps stacked and half
beside would read as two different components. A caller who names
`titlePlacement` keeps it, however narrow, and `dot` is stacked by definition.

Navigation blocks work the same way: they take their size from the longest
title in the run, share the width when there is more of it, and scroll when
there is less.

### The floor

The floor is derived, not fixed: the marker, the gap, room for five characters
of title — and as much again where any step carries a `subTitle`, since a
subtitle cannot shrink and would otherwise push the title out of its row — plus
the least rail that still reads as a line. `itemMinWidth` on the token replaces
it outright:

```dart
Steps(items: items, token: const StepsToken(itemMinWidth: 200))
```

`inline` is exempt: it is the miniature, one line of title and no content, and
it fits where a full run does not.

## Orientation and narrow space

`orientation` runs the steps across the page or down it. A horizontal run needs
room, so `responsive` (on by default) stands it up below 532px — the
own breakpoint — rather than squeezing every title into two characters.

```dart
Steps(orientation: StepsOrientation.vertical, current: 1, items: items);
Steps(responsive: false, items: items); // keep it horizontal, whatever happens
```

## Design tokens

`StepsToken` overrides the marker sizes (`iconSize`, `iconSizeSM`,
`iconSizeLG`, `dotSize`,
`dotCurrentSize`), the rail thickness and its gap from the markers
(`railInset`), the rail's own length (`railLength`) and the shortest it may be
drawn (`railMinLength`), the gap between a marker
and its title, the floor on a step's width (`itemMinWidth`),
the cap on a step's text column (`contentMaxWidth`), the panel padding and
radius, and the arrow colour.

```dart
Steps(
  items: items,
  token: const StepsToken(iconSize: 40, itemGap: 12),
);

// …or for every Steps in a subtree:
ConfigProvider(
  components: const [StepsToken(iconSize: 40)],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
