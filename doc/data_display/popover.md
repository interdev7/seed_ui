# Popover

A floating card with a title and a body. Where a
[Tooltip](tooltip.md) explains in a line of text, a popover holds a card: links,
buttons, a small form. That is the whole of the difference, and it is why the
two share everything below them.

```dart
Popover(
  title: const Text('Title'),
  content: const Text('Some content here.'),
  child: Button(child: const Text('Hover me')),
)
```

## Anatomy

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | What the card is anchored to |
| `title` | `Widget?` | `null` | The card's heading |
| `content` | `Widget?` | `null` | The card's body |
| `placement` | `PopoverPlacement` | `top` | Which side of the trigger it prefers |
| `trigger` | `PopoverTrigger` | `hover` | `hover`, `tap` or `longPress` |
| `open` | `bool?` | `null` | Whether it is open (controlled) |
| `defaultOpen` | `bool` | `false` | Whether it starts open when uncontrolled |
| `onOpenChange` | `ValueChanged<bool>?` | `null` | Fires with the state it wants to be in |
| `arrow` | `bool` | `true` | Whether a caret points at the trigger |
| `animation` | `PopoverAnimation` | `simple` | How the card arrives — `simple` or `genie` |
| `duration` | `Duration?` | `null` | How long the arrival takes |
| `curve` | `Curve?` | `null` | The curve it arrives on |
| `color` | `Color?` | `null` | The card's background, in place of the token's |
| `mouseEnterDelay` | `Duration` | `100ms` | The pause before hover opens it |
| `mouseLeaveDelay` | `Duration` | `100ms` | The pause before leaving closes it |
| `dismissOnOutsideTap` | `bool` | `true` | Whether a tap outside puts it away |
| `token` | `PopoverToken?` | `null` | Per-instance token overrides |

## Triggers

`hover` is the default and also answers a tap, since a touchscreen has no hover
to speak of. `tap` and `longPress` are the other two.

The two delays are what make a hover popover usable: a pointer crossing the
trigger on its way elsewhere should not open a card, and a pointer crossing the
gap between the trigger and the card should not close it. **The card counts as
part of the trigger** while it is open, so the links and buttons inside it can
actually be reached — without that, a hover popover could hold nothing you could
press.

## Driving it

```dart
// Uncontrolled, with a starting state.
Popover(defaultOpen: true, content: const Text('…'), child: …);

// Controlled — the caller owns it, as everywhere else in the kit.
Popover(
  open: _open,
  onOpenChange: (v) => setState(() => _open = v),
  content: const Text('…'),
  child: …,
);
```

## Placement

Twelve placements: the first word is the edge the card grows from, the suffix
nudges it along that edge — `topLeft`, `top`, `topRight`, and the same for
`bottom`, `left` and `right`. Where the side it asked for has no room the card
flips to the opposite one; where neither side of that axis has room it crosses
to the other axis; and it is clamped into the viewport either way.

## How it arrives

`simple` fades the card in while it grows a little out of the edge nearest its
trigger.

`genie` is the macOS minimise effect run backwards: the card is **rasterised**
and that picture is drawn through a mesh, so it can be bent in ways no transform
allows — a transform is the same map everywhere, and this is a different width
at every row.

The effect is not a shape that animates. It is a **funnel that stands still** —
narrow at the trigger, opening out to the card's full width a little way along —
and the card *flows through it*. A row's width is decided by **where that row is
at this moment**, not by its number in the card: what is still in the throat is
squeezed, what has left it is whole. Getting that the wrong way round is what
turns a genie into a lid closing, or a trapezoid sliding.

Measured, one frame at a time, from the trigger's edge outwards:

```
out  6%   0.25 0.25 0.25 0.25 0.25 0.26 0.26   a blob in the throat
out 32%   0.25 0.26 0.28 0.31 0.35 0.41 0.46   leaving it
out 68%   0.35 0.38 0.45 0.56 0.68 0.80 0.90   a clear funnel
out 94%   0.81 0.82 0.86 0.91 0.96 0.99 1.00   the throat relaxing
out 100%  1.00 1.00 1.00 1.00 1.00 1.00 1.00   a plain card
```

Four rules hold it together, and each was a fault first:

- **The neck runs nearly the whole card.** The leading edge should still be
  widening as it arrives; a short neck lets it out at full width while the rest
  is barely clear of the trigger, and the card reads as a wide lid with a spike
  under it.
- **The throat is as wide as the trigger.** The card is drawn out of the thing
  that opened it, not out of a slot of some arbitrary size, and the throat sits
  under the trigger's centre, so a card off to one side reaches back towards it.
- **The funnel relaxes late.** The row at the mouth never leaves the throat — a
  popover ends up beside its trigger, not across the room — so the funnel itself
  fades out at the end. Relax it from the start and the neck is gone before the
  card has flowed through it, which is most of the effect.
- **The picture runs the same way as the rows.** Read it the other way and the
  sheet is mirrored: the text stands on its head for the whole animation and
  flips upright on the last frame.
- **The walls are curves.** Widths that step evenly are a trapezoid; these start
  gently, swell and ease off.

The flow is carried by a curve that is smooth in its **acceleration** as well as
its speed (`6t⁵ − 15t⁴ + 10t³`). A curve that merely starts and ends at rest
still changes fastest in the middle, and the eye reads a change of speed as a
jolt.

None of this is judged by eye: the geometry lives in a small class of its own
and is measured in `test/genie_mesh_test.dart` — that the card grows out of the
trigger, that the funnel is narrow at the mouth and open beyond it, that a row's
width follows **where it is** rather than which row it is, that the throat
matches the trigger, that the sheet is never mirrored, that it fills its box
exactly when it lands, and that the busiest frame is in the middle while the
last barely moves.

It also runs longer than the fade — a genie at the pace of a fade is over before
the eye reads the shape.

The mesh is a *shape at a progress*; the pace comes from the curve, and easing
in both places double-counts it. Its default, `Curves.easeInOutCubic`, was
picked by measuring how far the sheet moves per frame over 25 frames:

| curve | first frame | busiest frame | at | last frames |
| --- | --- | --- | --- | --- |
| `Curves.linear` | 4.0 px | 8.1 px | 0.76 | 4.9 px |
| **`Curves.easeInOutCubic`** | **0.4 px** | **20.3 px** | **0.52** | **0.7 px** |
| `Curves.easeInOutQuint` | 0.1 px | 45.7 px | 0.48 | 0.4 px |
| `Curves.easeOutCubic` | 11.6 px | 15.3 px | 0.16 | 0.3 px |

Linear finishes as fast as it runs, and the quintic — what the easing inside the
mesh used to amount to — throws 46 px in one frame at the halfway mark, which
reads as a snap. The cubic leaves the trigger gently, does its work in the
middle, and settles.

### The shadow

The card is drawn as a picture of its own size, so the blur that spills past its
edges is cropped out of it. Left alone that shows twice over: the genie runs
with no proper shadow at all, and what is left of the card's own is a hard grey
band around the sheet.

So the two swap. `PopoverSurface.shadowIsCast(context)` tells a surface that
something else is drawing its shadow, and the kit's own reads it —

```dart
boxShadow: PopoverSurface.shadowIsCast(context) ? null : t.boxShadowSecondary,
```

— returning false anywhere else, so a surface is built the same way wherever it
is used. The swap and the rasterising change together: one without the other is
a frame with two shadows or with none, and that step is visible. A status can
arrive mid-build — a controlled popover closes from `didUpdateWidget` and the
controller reports it straight away — and marking the widget dirty then is not
allowed, so the pair is put off to after the frame. They still move together,
and the surface stays a plain widget for one frame longer.

Rasterising also stops the moment the surface lands, and from then on the
painter's plain path runs every frame. It casts a shadow only while the surface
has given its own up: casting one there as well stacks two, and the shadow jumps
wider when the pour ends and back when closing starts.

The sheet then casts the shadow from its own silhouette, and what does and does
not follow the pour is the whole of it:

| | follows the pour | why |
| --- | --- | --- |
| shape | yes | it is the shadow *of the sheet* |
| weight | over the first ~20% only | a shadow that fades in with the card reads as a second card |
| blur | no, full from frame one | a blur ramped up from nothing is a hard grey slab with sharp corners |
| spread | no, full from frame one | it grows the silhouette itself, so the weight matches the widget's at the handover |

A spread grows the silhouette — each row's edges pushed out across the sheet,
the end rows along it — and the shape is filled **once**. Filling it and then
stroking it to twice the radius covers the same ground but doubles the opacity
where the two overlap, which at a slow duration reads as a ring. The silhouette
has square corners where the card is rounded; measured against the card's own
shadow that is 5/255 at worst, which is why the handover does not show.

### What a poured frame costs

Measured rather than assumed, on this machine:

| | cost |
| --- | --- |
| building the sheet | 8.1 µs |
| `ui.Vertices` from it | 4.2 µs |
| painting the card into the picture | **2 times** over a 28-frame pour |
| per frame on the GPU | one textured `drawVertices`, plus one blurred fill per shadow layer |

The CPU side is 12 µs against a 16.6 ms frame — nothing to tune. The blurs are
the dear part, and they are the same blurs the card pays for standing still.
The picture is rasterised once and reused; the second paint is the handover.

Two things worth knowing if you touch this code:

- the painter is kept for the whole pour, not built in `build`. It listens to
  the animation from its constructor, and a replaced painter is never disposed
  by the framework — `SnapshotWidget` only drops its own listener — so a fresh
  one per rebuild leaves a listener behind each time;
- once the surface has landed the painter still runs on every frame, so it
  paints the child straight through instead of through an opacity of 255, which
  would leave a compositing layer under the popover for as long as it is open.

`duration` and `curve` set the pace yourself, on either arrival:

```dart
Popover(
  animation: PopoverAnimation.genie,
  duration: const Duration(milliseconds: 700),
  content: const Text('…'),
  child: …,
);

Popover(curve: Curves.easeOutBack, content: const Text('…'), child: …);
```

Left null they take what the arrival wants: quick and eased for the fade,
longer and gentler at both ends for the genie — 420 ms on
`Curves.easeInOutCubic`.

```dart
Popover(
  animation: PopoverAnimation.genie,
  title: const Text('Out of the trigger'),
  content: const Text('…'),
  child: Button(child: const Text('Open')),
)
```

Two things follow from it being a picture:

- **It costs a raster per frame** while it runs. Worth it for a showpiece, not
  for a popover that opens on every hover.
- **The picture is frozen** — text does not blink, buttons do not respond. So
  the rasterising stops the moment the card lands, and from then on it is an
  ordinary widget again. Without that, a genie popover could hold nothing you
  could press.

Where a platform cannot rasterise the card, the genie falls back to a plain
fade rather than showing nothing.

## Colour

`color` paints the card, and the caret takes it too, so the two read as one
shape rather than a triangle stuck to a box. Set the text colours to match
through the token:

```dart
Popover(
  color: t.primary.base,
  token: PopoverToken(
    titleColor: t.colorBgContainer,
    contentColor: t.colorBgContainer,
  ),
  title: const Text('In the accent'),
  content: const Text('…'),
  child: …,
)
```

## Design tokens

`PopoverToken` overrides the card's background (`colorBg`), its title and
content colours, the corner radius, the padding, and the width it may take
(`minWidth`, 177 by default, and `maxWidth`).

```dart
Popover(token: const PopoverToken(minWidth: 240), …);

// …or for every popover in a subtree:
ConfigProvider(
  components: const [PopoverToken(minWidth: 240)],
  child: MaterialApp(...),
);
```

## Underneath: PopoverLayer

`Popover` is a card built on `PopoverLayer`, the kit's floating layer.
[Tooltip](tooltip.md), [Dropdown](../navigation/dropdown.md),
[Select](../data_entry/select.md), [Popconfirm](../feedback/popconfirm.md) and
[Tour](tour.md) stand on the same layer, each with a surface of its own.

The layer positions and nothing more: it has no trigger — it takes `open` and
reports `onOpenChanged`, and the caller decides what opens it — and no styling,
since the surface is whatever you pass it.

```dart
PopoverLayer(
  open: _open,
  onOpenChanged: (v) => setState(() => _open = v),
  placement: PopoverPlacement.top,
  arrowColor: t.colorBgElevated,   // the caret takes your surface's colour
  arrowShadow: t.boxShadowSecondary,
  content: (context) => YourSurface(),
  child: YourTrigger(),
)
```

`interactive: false` lets pointers fall through to the page — what a tooltip
wants, so floating text cannot steal hover from what it describes.
`barrierColor` dims and blocks the page behind, which is how a floating surface
reads as modal without being a dialog. A layer closes when the page beneath it
scrolls, since it is positioned from the trigger's rectangle at the moment it
opened; [Tour](tour.md) is the exception and re-measures every frame on purpose.
