# FloatButton

A button that floats above the page — the round action button that sits in a
corner, alone or at the head of a group that opens into several.

```dart
FloatButton(
  icon: const Icon(Icons.search),
  color: ButtonColor.primary,
  onPressed: search,
)
```

The mark is yours to bring — any widget will do. A `Button` publishes its
foreground through `IconTheme`, so a Material `Icon` tints itself to match;
the kit's own `SearchIcon` and `UserIcon` take an explicit colour instead.
Give no icon at all and a group's trigger draws a plus that turns into a cross
as it opens.

It is a [Button](button.md) underneath, with its control height pinned and a
shadow behind it, so variants, colours, hover and press states behave exactly
as they do everywhere else. `ButtonColor` and `ButtonShape` are the same types,
not look-alikes.

## Where it goes

A `FloatButton` renders where you put it — a `Stack`, a `Positioned`, a
`Scaffold.floatingActionButton` slot. It does not seize a corner of its own.

```dart
Stack(
  children: [
    body,
    Positioned(
      right: 24,
      bottom: 24,
      child: FloatButton(onPressed: create),
    ),
  ],
)
```

Only a group's **expansion** goes into the nearest `Overlay`, and only while it
is open. That is what lets a fan reach past whatever the trigger is sitting in,
and lets a label hang off the side without being clipped.

## Groups

```dart
FloatButtonGroup(
  layout: const FloatButtonLayout.fan(),
  children: [
    FloatButton(icon: const Icon(Icons.edit), label: const Text('Edit')),
    FloatButton(icon: const Icon(Icons.share), label: const Text('Share')),
  ],
)
```

The direction the items travel is read off the trigger's place on screen: a
group parked at the bottom right opens up and to the left, one at the top left
opens down and to the right. Nothing needs to be told twice.

`children` is a `List<Widget>`, not a `List<FloatButton>`, on purpose. A group
tells its items what they need through the tree rather than by inspecting their
type, so wrapping one changes nothing:

```dart
children: [
  Badge(count: 5, child: FloatButton(icon: const Icon(Icons.mail), onPressed: open)),
  Tooltip(message: 'Admins only', child: FloatButton(icon: const Icon(Icons.key))),
]
```

There is no `badge` prop, and no `tooltip` prop, because `Badge` and `Tooltip`
are already widgets that wrap.

An item folds the group away once its `onPressed` has run — a menu left open
would hide the result of the very thing just tapped.

## Layouts

`FloatButtonLayout` is a sealed type rather than an enum, because the variants
do not all carry the same data. A fan has a radius, a sweep and an angle to
aim; a column has none of that. An enum would have to hang those numbers on the
group, where they would be silently meaningless for three variants out of five.

| Layout | Carries | What it does |
| --- | --- | --- |
| `FloatButtonLayout.vertical({gap})` | a gap | A column, climbing away from the nearer edge |
| `FloatButtonLayout.horizontal({gap})` | a gap | A row, opening away from the nearer side |
| `FloatButtonLayout.fan({radius, sweep, start, jitter, seed})` | geometry | An arc swept around the trigger |
| `FloatButtonLayout.grid(columns, {gap})` | a column count | A block filling the quadrant |
| `FloatButtonLayout.custom(place)` | your own function | Positions you work out yourself |

A ring is not a sixth layout: it is `fan(sweep: 2 * pi)`. A variant that brings
no new number does not earn a class of its own.

### Aiming a fan

`start` names the angle the arc is centred on, in radians clockwise from three
o'clock. Left null it aims away from the nearest corner, which is right nearly
always — a fan that opened off the edge of the screen would be no use.

### Scatter

`jitter` runs from 0 (a drawn arc) to 1, and `seed` chooses which scatter you
get.

```dart
FloatButtonLayout.fan(jitter: 0.4, seed: 7)
```

Two things it deliberately is not. It is **not random**: the same seed gives
the same arrangement on every open, in every process and in every test run. A
menu whose buttons landed somewhere new each time would defeat the muscle
memory that makes a menu worth having, and would take its tests with it. And it
is **bounded** by half the gap, so however high it goes, two items still cannot
collide.

## Labels

`label` is a `Widget?`, hung outside the button's own box, so it neither
shrinks the mark nor widens the circle.

```dart
FloatButton(
  icon: const Icon(Icons.description),
  label: const Text('Document'),
  onPressed: newDoc,
)
```

`FloatButtonLabelPlacement` names the side: `top`, `bottom`, `left`, `right` —
or `auto`, which is the default and is not a fifth side but a rule. The rule
depends on the layout, because a label must not land where the next item is
about to:

| Layout | `auto` puts the label |
| --- | --- |
| `vertical` | Out to the side — above would sit on the item above |
| `horizontal` | Above or below — beside would sit on the next item |
| `fan` | Outward along that item's own spoke, so labels fan out with the buttons |
| `grid` | Out of the side of the block |
| `custom` | Outward from the trigger, snapped to the nearest side |

## Opening

| Prop | Meaning |
| --- | --- |
| `trigger` | `FloatButtonTrigger.click` (the default) or `.hover` |
| `open` | Drives the group from outside; null lets it manage itself |
| `onOpenChange` | Called whenever the group wants to open or close |

A controlled group reports and waits: it does not open until `open` says so, so
the parent stays the single account of whether it is open. A group born with
`open: true` opens on its first frame.

## Tokens

| Token | Default |
| --- | --- |
| `size` | `controlHeightLG + sizeXS` — diameter of a round button, height of a square one |
| `gap` | `sizeSM` — between two items |
| `labelGap` | `sizeXS` — between a button and its label |
| `labelPadding`, `labelBackgroundColor`, `labelTextColor`, `labelFontSize`, `labelBorderRadius` | the label's chip |
| `borderRadius` | `borderRadiusLG`, for a square button |
| `shadow` | `boxShadowSecondary` |
| `motionDuration` | `motionDurationMid` |

```dart
ConfigProvider(
  theme: ThemeData(
    components: const ComponentsConfig(
      floatButton: FloatButtonToken(size: 64),
    ),
  ),
  defaults: const ComponentDefaults(
    floatButton: FloatButtonDefaults(shape: ButtonShape.defaultShape),
  ),
  child: ...,
)
```

## Why `Flow`

An open group positions its items with a `Flow`, whose delegate settles them
during **paint** rather than layout. A frame of the opening animation moves
every item — along an arc, with a stagger, scaling as it goes — without laying
anything out again.

`Flow` has one trait worth knowing if you extend this: it decides its own size
*before* measuring its children, so it can never shrink to fit them. That costs
nothing here because the flow fills the overlay, which is also why labels can
overhang freely.
