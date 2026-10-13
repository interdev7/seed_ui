# Rate

A rating in stars: how a reader marks a film, a meal, an answer.

```dart
Rate(
  value: stars,
  onChanged: (v) => setState(() => stars = v),
  semanticsLabel: 'Rating',
)
```

## Choosing

A tap on a star gives that many. The pointer resting on a star shows what a
tap would give before it is given, and the star under it grows a little.
Tapping the rating already given takes it back to nothing — `allowClear:
false` keeps it instead.

`allowHalf: true` lets a rating stop at half a star: a tap on a star's first
half gives half of it. The first half follows the reading direction — the
right half in a right-to-left layout, where the stars run from the right.

| Property | What it does |
| --- | --- |
| `count` | How many stars (5 unless named) |
| `value` | Holds the rating from outside; null lets the stars keep their own |
| `defaultValue` | What the stars start with, when `value` is null |
| `onChanged` | Called with the new rating |
| `onHoverChanged` | Called with what a tap would give as the pointer moves, and null as it leaves |

## The keys

The stars are one stop in the tab order, with a focus ring while the
keyboard is on them; `autofocus` and `focusNode` work as on any field. The
arrow keys move the rating by a star, or by half of one with `allowHalf` —
along the reading direction, and up and down too. Home takes it to nothing
and End to every star.

## Disabled and read-only

`disabled` greys the stars out and takes nothing. `readOnly` shows the rating
in full colour without letting it be changed — an average under a product, a
score already given.

## Your own character

`character` draws each star as something else: a heart, a letter, a number.
It is called with the star's index, and the colour comes from an `IconTheme`
and a `DefaultTextStyle` around it, so an `Icon` or a `Text` takes it without
being told:

```dart
Rate(character: (_) => const Icon(Icons.favorite))
Rate(character: (i) => Text('${i + 1}'))
```

## Tooltips

`tooltips` gives a word to each star, shown while the pointer rests on it:

```dart
const Rate(tooltips: ['terrible', 'bad', 'normal', 'good', 'wonderful'])
```

## Sizes

`size` takes `SoftSize.small` (16), `middle` (20, the default) or `large` (24),
or a measurement of your own. Without one it follows `ConfigProvider`'s
component size.

## Screen readers

A screen reader hears a slider named by `semanticsLabel`, with its value as
"3 / 5" in the app's digits, and can move it up and down with its own
gestures.

## Defaults for a subtree

`RateDefaults` sets `allowHalf` and `allowClear` for every rating below a
`ConfigProvider`.

## Design tokens

`RateToken` overrides this component's own tokens. Every field is an
override; an unset one falls back to the value derived from the global theme.

| Token | Default |
| --- | --- |
| `starColor` | a warm yellow, `#FADB14` — a lit star |
| `starBg` | `colorFillSecondary` — a star not yet reached |
| `gap` | `sizeXS` — between two stars |
| `hoverScale` | `1.1` — how much the star under the pointer grows |

```dart
Rate(
  // …
  token: const RateToken(starColor: Color(0xFFFF4D4F)),
);

// …or for every Rate in a subtree:
ConfigProvider(
  theme: ThemeData(
    components: const ComponentsConfig(rate: RateToken(gap: 4)),
  ),
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
