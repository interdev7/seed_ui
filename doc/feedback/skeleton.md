# Skeleton

A stand-in for content that is still loading: grey blocks where an avatar, a
title and a paragraph will be, with a light sweeping across them.

```dart
Skeleton(
  loading: user == null,
  avatar: const SkeletonAvatar(),
  active: true,
  child: UserCard(user),
)
```

While `loading` is true it draws the blocks; once it is false it shows
`child`. Hand it the same `loading` flag the data comes with, and the page
swaps from placeholder to content in place.

## What it draws

By default a title bar and three lines, the last one shorter, as the end of a
paragraph is:

| Part | Property | Default |
| --- | --- | --- |
| Avatar | `avatar` | none; `SkeletonAvatar()` adds one at the start |
| Title | `title` | `SkeletonTitle()` — 38% of the width, 50% beside an avatar |
| Paragraph | `paragraph` | `SkeletonParagraph()` — three lines, two beside an avatar |

Pass `null` for `title` or `paragraph` to leave it out.

```dart
const Skeleton(
  title: SkeletonTitle(width: 0.5),
  paragraph: SkeletonParagraph(rows: 4, widths: [1, 1, 0.8, 0.4]),
)
```

`SkeletonParagraph.widths` gives each line its share of the width, from 0 to
1. A line with no entry takes the whole width, except the last of several,
which stops at 61%.

`round: true` gives the title and the lines round ends.

## The light

`active: true` sweeps one band of light across the whole skeleton, over every
block at once. It is off unless asked. Where the platform asks for less
motion the blocks stay still whatever `active` says.

The sweep repaints the blocks and nothing around them, and it stops the
moment the skeleton leaves the screen or `loading` turns false.

## Blocks of other shapes

For a placeholder that is not a title and a paragraph, use the blocks on their
own, in a layout of your own:

| Widget | Stands in for | Size |
| --- | --- | --- |
| `SkeletonAvatar` | an avatar — `shape` round or square | the control height for its `size` |
| `SkeletonButton` | a button — `shape` as a button's, `block` for the whole width | as tall as a button, twice as wide |
| `SkeletonInput` | a text field — `block` for the whole width | as tall as a field, five times as wide |
| `SkeletonImage` | a picture — `width`, `height` | three control heights square |
| `SkeletonNode` | anything else — `child` gives the size and is drawn on top | the child's |

```dart
Row(
  children: const [
    SkeletonButton(active: true),
    SizedBox(width: 8),
    SkeletonInput(active: true),
  ],
)
```

`size` takes `SoftSize.small`, `middle` or `large`, or a measurement of your
own, and without one follows `ConfigProvider`'s component size. Inside a
`Skeleton` a block takes the skeleton's light rather than starting one of its
own; standing alone, each takes its own `active`.

## Accessibility

A screen reader hears "Loading", in the app's language, once for a skeleton
however many blocks it draws, and once for a block standing alone. The blocks
themselves say nothing.

## Defaults for a subtree

`SkeletonDefaults` sets `active` and `round` for every skeleton and block below
a `ConfigProvider`:

```dart
ConfigProvider(
  defaults: const ComponentDefaults(
    skeleton: SkeletonDefaults(active: true),
  ),
  child: ...,
)
```

## Design tokens

`SkeletonToken` overrides this component's own tokens. Every field is an
override; an unset one falls back to the value derived from the global theme.

| Token | Default |
| --- | --- |
| `blockColor` | `colorFillSecondary` |
| `highlightColor` | `colorFill`, `colorTextQuaternary` in a dark theme — the light |
| `blockRadius` | `borderRadiusSM` — a title's, a line's, an image's corners |
| `titleHeight` | `fontSizeLG` |
| `titleGap` | `sizeLG` — between the title and the paragraph |
| `paragraphLineHeight` | `fontSizeLG` |
| `paragraphLineGap` | `size` |
| `avatarGap` | `size` — between the avatar and the text beside it |
| `motionDuration` | 1.4 s — one sweep of the light |

```dart
Skeleton(
  // …
  token: const SkeletonToken(blockColor: Color(0x14000000)),
);

// …or for every Skeleton in a subtree:
ConfigProvider(
  theme: ThemeData(
    components: const ComponentsConfig(
      skeleton: SkeletonToken(motionDuration: Duration(seconds: 2)),
    ),
  ),
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
