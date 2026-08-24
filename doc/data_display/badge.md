# Badge

A count or dot pinned to the corner of what it describes, and `Ribbon` — a
label banded across a container's corner.

```dart
Badge(count: 12, child: const Avatar(child: Text('U')))
```

`Badge` clashes with Material's own `Badge`. Hide one of them at the import:

```dart
import 'package:flutter/material.dart' hide Badge;
```

## Counts

A count of zero is hidden, so a badge can stay in place while the thing it
counts empties out. `showZero` keeps it visible when the nought is the point —
a dashboard that should read `0 errors` rather than go blank.

```dart
Badge(count: 0, child: _bell)              // nothing is drawn
Badge(count: 0, showZero: true, child: _bell)
```

Anything above `overflowCount` reads as a ceiling rather than a number. The
boundary itself is still a number: at the default of 99, `99` is `99` and
`100` is `99+`.

```dart
Badge(count: 1200, overflowCount: 999, child: _bell)   // 999+
```

### The roll

A count that changes rolls its digits into place rather than swapping them.
Each place is its own reel, and they turn in the direction the count moved: up
when it grew, down when it shrank.

Ticking over is the case worth naming. Going 9 to 10 the units reel travels
one step forward to reach 0 — not nine steps backwards, which is what reducing
the position to a single digit would force and what a counter never looks
like.

Each place is a fixed cell, the width of the widest digit. A reel sized to
whatever digit it happens to show would change width as it turns and shove its
neighbours sideways — the tens visibly jogging while only the units were meant
to move.

Only a plain number rolls. Past the overflow the badge reads `99+`, which is
not a number going anywhere, so it is drawn still.

A count falling to nothing retreats into the corner it came from instead of
blinking out, and once gone it leaves the tree, so a badge scaled to nothing
is not left behind for a screen reader to find. It keeps the count it was
showing as it goes: redrawing it as the zero that hid it would set the reels
rolling on the way out.

A single-character count keeps the pill round; the padding that makes it a
lozenge is added only once there is a second character needing the room.

Give a `title` whenever the count is not self-explanatory. Without one a
screen reader announces the digits exactly as drawn, which says "ninety-nine
plus" where "over ninety-nine unread messages" was meant.

```dart
Badge(count: 120, title: '120 unread messages', child: _bell)
```

## Dots

`dot` drops the number and leaves a mark that says only *something changed*.
It wins over `count`, so a badge can be switched between the two without
taking the count away.

```dart
Badge(dot: true, child: const Icon(Icons.notifications))
```

## Standalone, and statuses

Without a `child` the badge stands on its own — what a table cell usually
wants. `status` draws a small dot in the palette's colours, with `text` beside
it:

```dart
Badge(status: BadgeStatus.processing, text: const Text('Deploying'))
```

| `BadgeStatus` | Colour | Reads as |
| --- | --- | --- |
| `neutral` | Grey | Nothing is happening |
| `success` | Green | Finished, or healthy |
| `processing` | Blue, with a ring pulsing outward | Still under way |
| `warning` | Amber | Needs attention |
| `error` | Red | A failure |

The processing ring is drawn outside the dot's own box, so a row does not
shift when a status changes.

## Anything else in the pill

`content` replaces the number with a widget — a word, a glyph. It is exempt
from `overflowCount` and `showZero`: whatever it is, it is not a number the
badge can reason about.

```dart
Badge(content: const Text('new'), child: _card)
```

## Placing it

The badge hangs half off the child's top trailing corner. `offset` nudges it
from there — positive `dx` moves it outward, positive `dy` downward.

```dart
Badge(count: 5, offset: const Offset(-4, 4), child: _avatar)
```

`size` has two settings: `SoftSize.middle` and the shorter `SoftSize.small`.
`SoftSize.large` reads as `middle`; a badge has only the two heights.

## Ribbon

A band across the top corner of a container, kept as its own widget rather
than folded into `Badge` as a constructor. The two share an idea but not a
single property: a ribbon has no count, no overflow and no dot, and a badge
has no placement and no corner fold.

```dart
Ribbon(
  text: const Text('Hot'),
  color: const Color(0xFFFA541C),
  child: Card(child: const Text('...')),
)
```

`placement` runs the band off the leading end instead:

```dart
Ribbon(placement: RibbonPlacement.start, text: const Text('New'), child: _card)
```

The small triangle beneath the band is the band turning the corner. It is
drawn a quarter of the way to black from whatever fill it is given, which
reads as shadow on every hue rather than going muddy on the darker ones.

## Properties

### Badge

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget?` | `null` | What the badge is pinned to; null stands alone |
| `count` | `int?` | `null` | The number to show |
| `content` | `Widget?` | `null` | Arbitrary content in place of `count` |
| `dot` | `bool` | `false` | A bare mark rather than a count |
| `status` | `BadgeStatus?` | `null` | Draws a status dot instead |
| `text` | `Widget?` | `null` | The label beside a `status` dot |
| `showZero` | `bool` | `false` | Whether a count of zero is drawn |
| `overflowCount` | `int` | `99` | The largest number drawn in full |
| `color` | `Color?` | `null` | Overrides the fill, status included |
| `offset` | `Offset` | `Offset.zero` | Nudge from the corner; ignored standalone |
| `size` | `SoftSize?` | `null` | Follows the provider's `componentSize`, else `middle`; `small` gives a shorter pill |
| `title` | `String?` | `null` | What assistive technology hears |
| `token` | `BadgeToken?` | `null` | Per-instance token overrides |

### Ribbon

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | What the ribbon is draped over |
| `text` | `Widget?` | `null` | What the band says |
| `color` | `Color?` | `null` | Band fill; the fold is darkened to match |
| `placement` | `RibbonPlacement` | `end` | Which corner the band runs off |
| `token` | `RibbonToken?` | `null` | Per-instance token overrides |

## Tokens

`BadgeToken`: `indicatorHeight`, `indicatorHeightSM`, `dotSize`, `statusSize`,
`fontSize`, `bg`, `textColor`, `ringColor`.

`RibbonToken`: `height`, `fontSize`, `bg`, `textColor`.

Override one instance:

```dart
Badge(count: 3, token: const BadgeToken(bg: Color(0xFF722ED1)))
```

…or every badge under a subtree through `ConfigProvider`:

```dart
ConfigProvider(
  theme: ThemeData(components: ComponentsConfig(
    badge: BadgeToken(indicatorHeight: 18),
    ribbon: RibbonToken(height: 26),
  )),
  child: const MyApp(),
)
```
