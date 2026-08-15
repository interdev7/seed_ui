# Tour

A guided walk through a screen. Each step points at one
of your widgets: the page behind is dimmed except for a hole over the target,
and a panel explains what it is.

```dart
final _search = GlobalKey();
final _tour = TourController();

Input(key: _search);
Button(onPressed: _tour.open, child: const Text('Show me around'));

Tour(controller: _tour, steps: [
  TourStep(
    target: _search,
    title: const Text('Search'),
    description: const Text('Find anything from here.'),
  ),
]);
```

The widget takes no room in the tree — it drives an overlay. Put it wherever
you like, but inside a `Stack` give it a `Positioned`: an unpositioned zero-size
child shrinks the stack, and its positioned siblings stop hit-testing. That is
Flutter's rule, not the tour's, and it costs a real target its taps.

## Anatomy

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `steps` | `List<TourStep>` | required | The stops, in order |
| `controller` | `TourController?` | `null` | Drives it from outside |
| `open` | `bool?` | `null` | Whether it is on screen (controlled) |
| `current` | `int?` | `null` | The step being shown (controlled) |
| `onChange` | `ValueChanged<int>?` | `null` | Fires with the step moved to |
| `onClose` | `VoidCallback?` | `null` | Fires on dismissal, however it happened |
| `onFinish` | `VoidCallback?` | `null` | Fires on the last step's button, before `onClose` |
| `type` | `TourType` | `normal` | `primary` paints the panel in the accent |
| `placement` | `TourPlacement` | `bottom` | Where a panel sits relative to its target |
| `mask` | `TourMask` | shown | Whether the page is dimmed, and in what colour |
| `gap` | `TourGap` | `offset: 6, radius: 2` | The room the hole leaves round a target |
| `arrow` | `bool` | `true` | Whether a caret points at the target |
| `closable` | `bool` | `true` | Whether panels carry a close button |
| `closeIcon` | `Widget?` | `null` | Replaces the close button's cross |
| `dismissible` | `bool` | `true` | Whether a tap on the mask closes the tour |
| `scrollIntoView` | `bool` | `true` | Scroll the page to a target that is out of view |
| `disabledInteraction` | `bool` | `false` | Blocks taps on the highlighted target |
| `duration` | `Duration?` | `null` | How long the highlight takes to travel |
| `curve` | `Curve?` | `null` | The curve it travels on |
| `indicatorsBuilder` | `Widget Function(context, current, total)?` | `null` | Replaces the step dots |
| `actionsBuilder` | `Widget Function(context, actions, current, total)?` | `null` | Wraps or replaces the buttons |
| `token` | `TourToken?` | `null` | Per-instance token overrides |

### TourStep

| Property | Type | Description |
| --- | --- | --- |
| `target` | `GlobalKey?` | The widget this step points at; null centres the panel |
| `title` | `Widget?` | The heading |
| `description` | `Widget?` | What the step explains |
| `cover` | `Widget?` | A picture or video above the heading |
| `placement` | `TourPlacement?` | Overrides the tour's placement |
| `type`, `mask`, `gap`, `arrow`, `closable`, `closeIcon`, `dismissible`, `scrollIntoView` | — | Per-step overrides of the tour's own |
| `nextButton`, `prevButton` | `TourButton?` | The buttons' labels, looks and press hooks |

The close button takes an icon of its own — the tour's, or one step's:

```dart
Tour(closeIcon: const Icon(Icons.keyboard_arrow_down), steps: steps);
TourStep(closeIcon: const Icon(Icons.close_fullscreen), title: …);
```

## The buttons

Every step draws a "Next" (or, on the last step, "Finish") and, past the first,
a "Previous". `nextButton` and `prevButton` change what they say, how they look
and what else they do:

```dart
TourStep(
  target: _upload,
  title: const Text('Upload'),
  nextButton: TourButton(
    label: const Text('Got it'),
    icon: const Icon(Icons.check),
    // Runs as well as moving the tour on, not instead of it.
    onPressed: () => analytics.log('tour.upload.ack'),
  ),
)
```

`TourButton(disabled: true)` stops that button working, so a step cannot be
left until whatever it is asking for has happened:

```dart
nextButton: TourButton(
  label: Text(_uploaded ? 'Next' : 'Upload one first'),
  disabled: !_uploaded,
)
```

When a config is not enough, `TourButton.custom` hands you the action the tour
would have run — moving on, going back, finishing — and takes whatever widget
you build:

```dart
nextButton: TourButton.custom(
  (context, act) => Button(
    shape: ButtonShape.round,
    variant: ButtonVariant.solid,
    color: ButtonColor.primary,
    onPressed: act,
    child: const Text('Take the tour →'),
  ),
)
```

The action is null while the button is `disabled`, so a widget that respects it
reads as off. `indicatorsBuilder` and `actionsBuilder` on the tour do the same
for the dots and the whole button row. Anything you build inherits the panel's
own text style, whatever it is on — including a primary panel's light ink.

`variant` and `color` are the kit's own [Button](../general/button.md) ones;
what you leave out keeps the tour's answer, so a `TourButton` with only a label
renames the button and changes nothing else.

## Reaching the target

A tour that walks past the fold is no use if the reader has to go and find the
target themselves, so the page comes to it: every scrollable between the target
and the screen is asked to reveal it, on the tour's own `duration` and `curve`.

A target already comfortably in view is left alone — re-centring the page under
someone who can see the thing perfectly well is worse than not scrolling at all
— and `scrollIntoView: false`, on the tour or on one step, turns it off.

The spotlight also **follows** a target that moves: the target is re-read at the
end of every frame there is, so a page scrolled under an open tour keeps its
highlight in the right place. The watch asks for no frames of its own, so an
idle tour is idle. Note the difference in motion, which is deliberate: a change
of **step** is travelled, a target that **moves** is followed at once.

## The target stays live

The hole is a hole: taps inside it reach the widget underneath, so a tour can
walk you through a real interaction rather than describing it. Everything
outside the hole dismisses the tour, as clicking away closes a dialog.

`disabledInteraction: true` seals the hole where a step must not be acted on
yet.

```dart
Tour(disabledInteraction: true, steps: steps)
```

Everything outside the hole dismisses the tour by default. `dismissible: false`
takes that away, so it can only be left by its own buttons — the mask still
swallows the tap either way, since the page behind a tour is not to be clicked
by accident. A single step can hold on while the rest let go:

```dart
Tour(dismissible: false, steps: steps);
TourStep(dismissible: false, title: const Text('Read this one'));
```

## The highlight

`gap` sets how far the hole reaches past the target and how round its corners
are — the defaults are 6 and 2:

```dart
Tour(gap: const TourGap(offset: 12, radius: 16), steps: steps);
Tour(gap: const TourGap(offsetX: 24, offsetY: 4), steps: steps);
```

Between steps the highlight **travels**: one animated rectangle drives both the
hole in the mask and the panel's anchor, so the spotlight and the card move as
one thing rather than blinking from place to place. A tour opening on its first step does not slide in — there is nowhere to travel
from.

A step that points at nothing still has somewhere to be: the middle of the
screen, as a rectangle of no size. So the spotlight **opens out of that point**
on the way from a welcome step to a target, and shuts back into it on the way
back, instead of appearing and vanishing outright.

There is one panel for the whole tour, not one per step: it travels to the next
step and swaps its contents on the way. A centred step is centred *on its
anchor* — the point in the middle of the screen — by the same layout that puts a
panel beside a target, so even that is a journey rather than a swap. Cross-fading
two panels instead showed both at once over the mask, which reads as a flash.

Three rules keep the journey smooth, and each of them was a jolt before it was
one:

- **The travel is done by the layout**, not by sliding a finished one. A step
  placed below its target followed by one placed beside another changes the rule
  in a single frame, and only the layout knows — before anything is painted —
  that the panel has moved.
- **The card eases into the size each step wants**, corners and all: the box
  that animates sits *inside* the decoration, since outside it the decoration
  snaps to the new size and only an invisible box eases. A size that moves while
  the panel travels also moves where the layout puts it, which the journey
  absorbs — and it would let the layout change its mind about which side of the
  target to sit on, so the side is judged by the size the card is **heading
  for**, not the one it is easing through. A side decided halfway is a jump of
  hundreds of pixels, and no easing hides it.
- **The text crosses over instead of being replaced.** Inside the travelling
  surface the old title and description fade out as the new ones fade in. The
  outgoing copy keeps its own size, out of the layout and clipped to the card,
  so it cannot drag the panel's size around while it leaves — the panel is
  already the size the arriving step wants. Squeezed into the arriving box
  instead, a wide step leaving a narrow one overflowed in stripes.
- **A journey starts when the step changes and nothing else.** The panel's own
  resizing moves where it lands, and a journey measured against that restarts on
  every frame.

The caret takes the same journey, so panel and caret stay one surface. Where
two steps sit on different sides of their targets it has to change edges, which
it cannot do gradually: it travels to its new point and **turns at the halfway
mark**, where it is furthest from both panels and the turn is least noticeable.
Left alone it jumped from one edge to the other in a single frame.

`duration` and `curve` are the timing, and `Duration.zero` moves everything in
one frame:

```dart
Tour(
  steps: steps,
  duration: const Duration(milliseconds: 450),
  curve: Curves.easeOutBack,
);

Tour(steps: steps, duration: Duration.zero); // no travel at all
```

The same pair lives on the token as `travelDuration` and `travelCurve`, for a
theme that wants every tour to move alike — `ConfigProvider(components: const
[TourToken(travelDuration: …)])`. What is named on the widget wins.

The dimming is painted as the page and the hole in **one shape**, filled
even-odd: the hole is the part the rule leaves out, so its edge is the fill's
own edge rather than a second shape drawn over it. Subtracting one path from
another would say the same thing, but path operations need a renderer able to
do them — on the web that is not a given, and the mask came out solid with
nothing lit at all.

`mask` turns it off or recolours it:

```dart
Tour(mask: TourMask.none, steps: steps);                       // non-modal
Tour(mask: const TourMask(color: Color(0x59001342)), steps: steps);
```

## Placement

The twelve edge placements are the kit's own, so a tour panel flips to the other
side of its target when there is no room and shifts to stay on screen — the same
machinery [Popover](../../lib/src/utils/popover.dart) and Tooltip stand on.

A panel that fits neither side of the axis it was asked for crosses to the
other one — on a phone a wide panel fits neither left nor right of its target,
and pinning it to the screen edge would lay it over the very thing it points
at. [Popover](../../lib/src/utils/popover.dart) and Tooltip inherit the same
rule.

`TourPlacement.center` ignores the target and puts the panel in the middle of
the screen. A step with no `target` does the same, which is how a tour opens
with a welcome before it has anything to point at.

## Driving it

```dart
// A controller, for buttons that live elsewhere.
final tour = TourController();
tour.open();       // from the beginning — or tour.open(2) to start at a step
tour.resume();     // back on screen where it left off
tour.next();
tour.previous();
tour.close();

// Or controlled, like the rest of the kit.
Tour(open: _open, current: _step, onChange: (i) => setState(() => _step = i));
```

`open()` starts the tour, it does not resume it: pressing "Begin tour" a second
time shows the first step again, which is what the button says. `close()` leaves
the current step where it is, so `resume()` carries on from there.

`TourController` is a `ChangeNotifier` — listen to it to keep your own UI in
step. Dispose it with the widget that owns it.

## Type

`TourType.primary` paints the panel in the accent colour with light text, and
the caret follows. The main button inverts so it does not disappear into the
panel.

```dart
Tour(type: TourType.primary, steps: steps)
```

## Design tokens

A panel is as wide as its content and no wider, up to `width` — the
own `width: 520` together with `max-width: fit-content`, so a one-line step gets
a small panel rather than a 520px slab.

`TourToken` overrides that ceiling (`width`, 520), the close
button's size (`closeBtnSize`), the indicator dots (`indicatorSize`), the
dimming colour (`maskColor`), the muted fill a primary panel uses for its
spent dots and its previous button (`primaryPrevBtnBg`), and how the highlight
travels (`travelDuration`, `travelCurve`).

```dart
Tour(steps: steps, token: const TourToken(width: 360));

// …or for every Tour in a subtree:
ConfigProvider(
  components: const [TourToken(width: 360)],
  child: MaterialApp(...),
);
```
