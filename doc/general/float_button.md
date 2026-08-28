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
FloatButtonGroup<UserAction>(
  layout: const FloatButtonLayout.fan(),
  items: const [
    FloatButtonItem(value: UserAction.edit, label: 'Edit', icon: Icon(Icons.edit)),
    FloatButtonItem(value: UserAction.share, label: 'Share', icon: Icon(Icons.share)),
  ],
  onItemTap: (value) => handle(value),
)
```

The direction the items travel is worked out from the room around the trigger.
A group goes up and to the left — where a button in the usual corner has to go
— unless the items would not fit there, in which case it takes the roomier
side. Nothing needs to be told twice.

### Items are data

`FloatButtonItem` is a plain object, not a widget. The group has to size and
place its items to lay them out at all, and an object is the safer home for
something held outside a build — a widget kept in a field can close over a
context that has since gone stale.

| Field | |
| --- | --- |
| `value` | What the item reports through `onItemTap`. An enum makes the `switch` exhaustive |
| `key` | A key fastened to the item in the tree — a `GlobalKey` here lets a `Tour` aim at it |
| `label` | The caption, as a string. The kit styles it |
| `icon`, `child` | The mark, or content of your own in its place |
| `color` | Where this item differs from its group — a destructive action asking to be red |
| `disabled` | Greys it out |
| `onTap` | Fires alongside `onItemTap` |

`key` and `value` are two kinds of identity and deliberately separate: `key` is
the tree's (which element is this?), `value` is yours (which action is this?).
Note that items exist only while the group is open, so a tour step aiming at
one has to open the group first — which is what the controller is for.

### Wrapping an item

There is no `badge` prop and no `tooltip` prop. One hook covers every wrapper
there will ever be:

```dart
itemBuilder: (context, item, child) => Tooltip(
  message: Text(item.label ?? ''),
  child: child,
),
```

`child` is the finished float button; return it inside whatever you like. A
wrapper that changes the item's size is worth knowing about: the layout spaces
items by the size in the token, so something much larger will crowd its
neighbours.

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

### How far out

`radius` left null is worked out from the number of items. The chord between
two neighbouring spokes is `2r·sin(step/2)`, so the more items share a sweep,
the further out they must sit to keep from touching; the kit picks the distance
that leaves a gap between them. A fixed default cannot do this — an earlier one
put four items eleven pixels *inside* each other.

Naming a radius yourself is taken as given, crowding and all. Sometimes an
overlap is the look you want.

### Sizes

`size` takes a preset from the token scale or a measurement of your own, on a
button alone or on a whole group. A circle's height is its diameter, so a bare
number reads true:

```dart
FloatButton(size: SoftSize.large, ...)          // 56
FloatButton(size: const ControlSize.height(72), ...)
FloatButtonGroup<T>(size: SoftSize.small, ...)  // trigger and items alike
```

A group sizes its items alike, which is what lets it space them.

### Scatter

`jitter` runs from 0 (a drawn arc) to 1, and `seed` chooses which scatter you
get.

```dart
FloatButtonLayout.fan(jitter: 0.4, seed: 7)
```

Two things it deliberately is not. It is **not random**: the same seed gives
the same arrangement on every open, in every process and in every test run. A
menu whose buttons landed somewhere new each time would defeat the muscle
memory that makes a menu worth having, and would take its tests with it.

The scatter runs **along the spokes**, not across them: items standing at
visibly different distances is what reads as scatter, where nudging them a few
degrees sideways does not. It is also the one direction an item can travel
without ever nearing its neighbours — the distance from a point at radius `r`
to the next spoke is `r·sin(step)` — so an item is simply kept beyond the
radius where that clears a whole item, and no arrangement can collide however
far two of them differ.

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

The kit dresses the text — colour, size, the theme's face — and stops there.
There is no plate behind it, because a caption that needs one is a caption you
wrap yourself, which is what `label` being a widget is for:

```dart
label: DecoratedBox(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(6),
  ),
  child: const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Text('Document'),
  ),
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
| `grid` | Underneath, in the room a grid leaves between its rows |
| `custom` | Outward from the trigger, snapped to the nearest side |

A caption takes its own size and sits a few pixels clear of the button, centred
on it across the other axis.

## Blocking

It does not. The page underneath an open group keeps working: it scrolls, and
its buttons still answer. A tap outside closes the group and reaches the page
both. Putting a sheet over the page for as long as a menu is up is not a trade
a float button may make.

## Opening

| Prop | Meaning |
| --- | --- |
| `trigger` | `FloatButtonTrigger.click` (the default) or `.hover` |
| `open` | Drives the group from the widget tree; null lets it manage itself |
| `controller` | Drives it from outside the build. Excludes `open` |
| `onOpenChange` | Called whenever the group wants to open or close |
| `dismissible` | Whether a tap on open ground closes it. Default yes |
| `closeOnSelect` | Whether tapping an item closes it. Default yes |

A controlled group reports and waits: it does not open until `open` or the
controller says so, so the caller stays the single account of whether it is
open. A group born open opens on its first frame. Passing both `open` and a
`controller` is an assertion error — two owners of one truth disagree sooner
or later.

`dismissible` and `closeOnSelect` are different questions: one is about a tap
outside, the other about a tap on an item. A toolbar that stays up while you
work is `closeOnSelect: false`.

**Escape always closes the group**, whatever `dismissible` says. A menu with no
way out from the keyboard is a trap, and no setting may make one. The key is
read straight off the keyboard rather than through a focus node, because a
layer in an overlay never takes focus from the route that owns it.

```dart
final fab = FloatButtonController();
...
FloatButtonGroup<UserAction>(controller: fab, items: items)
...
fab.open();   // and close(), and toggle()
```

## Tokens

| Token | Default |
| --- | --- |
| `size` | `controlHeightLG + sizeXS` — diameter of a round button, height of a square one |
| `gap` | `sizeSM` — between two items |
| `labelGap` | `sizeXXS` — between a button and its label |
| `labelTextColor`, `labelFontSize` | the label's text |
| `borderRadius` | `borderRadiusLG`, for a square button |
| `shadow` | `boxShadowSecondary` |
| `motionDuration` | `motionDurationMid` |
| `curve` | `motionEaseOut` — the shape of the opening |

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

## Scrolling

The trigger's position is read once per opening rather than every frame, and a
scroll under an open group is what makes that stale. The group re-aims itself
instead of closing: closing would be the cheap answer, and it contradicts
`dismissible: false`. The re-measure waits for the frame the scroll belongs to,
since a scroll notification arrives before that frame has been laid out.
