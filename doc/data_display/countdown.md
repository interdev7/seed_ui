# Countdown

A running count of the time to a moment, or since one.

```dart
Countdown(target: DateTime.now().add(const Duration(hours: 2)))
```

Named `Countdown` rather than `Timer` because `dart:async` already has a
`Timer`, and the file showing this widget is usually the same file that needs
the other one. It counts either way round; `type` says which.

## Which way it runs

```dart
Countdown(target: saleEndsAt)                                  // down, default
Countdown(target: startedAt, type: CountdownType.up)           // up
```

Counting down stops at zero — a countdown that has run out has run out, rather
than going on into negative time — and calls `onFinish` once when it gets
there. Counting up has no end to reach, so `onFinish` is never called.

## The format

Each token stands for a unit, and a run of it is the width it is padded to:
`ss` gives `07`, `s` gives `7`.

| Token | Unit |
| --- | --- |
| `Y` | Years |
| `M` | Months |
| `D` | Days |
| `H` | Hours |
| `m` | Minutes |
| `s` | Seconds |
| `S` | Milliseconds |

Units are taken largest first, each from what the ones above it left. A format
that omits a unit therefore rolls it into the next one down:

```dart
format: 'HH:mm:ss'          // a day and two hours → 26:00:00
format: 'D[d] HH:mm:ss'     //                     → 1d 02:00:00
```

Text in square brackets is kept as written, which is how a unit letter gets
drawn as itself:

```dart
format: 'H[h] m[m]'         // → 2h 5m
```

## Rounding, and why it is up

A countdown rounds **up** to the smallest unit the format asks for. Three and
a half seconds away reads `00:04`, not `00:03`: you have four seconds left,
and formatting the remainder as it stands would open a fresh countdown one
short of its own length. It then turns over on the target's own half-second,
not the wall clock's.

Counting up rounds down, which is the same rule read the other way: one and
nine tenths of a second elapsed is one second gone.

## What it costs to leave on screen

The format decides how often the widget wakes. Asking for milliseconds drives
it from frames; anything coarser sleeps exactly as long as the drawn text will
stay the same, then wakes once. Either way nothing is redrawn while the text
would not change, so an hours-and-minutes countdown costs almost nothing.

The count is measured against the wall clock rather than accumulated ticks, so
it stays right across a suspended app instead of losing the time it slept.

## Driving it from outside: `CountdownController`

Changing the moment counted against needs no controller — rebuild with a new
`target` and the count starts again against it. What does need one is
**pausing**: the count runs on the wall clock, and there is no arrangement of
properties that holds it still.

```dart
final controller = CountdownController(
  target: DateTime.now().add(const Duration(minutes: 5)),
);

Countdown(controller: controller)
```

Give the widget a `target` or a `controller`, never both — two moments to count
against is one too many.

| Member | What it does |
| --- | --- |
| `pause()` | Holds the count still |
| `resume()` | Runs on from where it stopped |
| `add(Duration)` | Moves the target; a negative one cuts the count short |
| `restart(Duration)` | Counts that long from now, releasing any pause |
| `target` | The moment counted against; settable |
| `value` | What is on screen, as a `Duration` |
| `isPaused` | Whether it is being held |

Resuming gives the pause back rather than charging for it: the target moves by
however long the count stood still, so it carries on from the figure it
stopped at. Time added while paused is added to that same figure, not to
whatever the wall clock has run down to behind its back.

Dispose of the controller with the `State` that made it.

## Wrapping it

`builder` hands you the formatted time and takes over the drawing — a label, a
prefix, an icon:

```dart
Countdown(
  target: deadline,
  format: 'mm:ss',
  builder: (context, formatted) => Row(
    children: [const Icon(Icons.timer_outlined), Text(' $formatted left')],
  ),
)
```

`onChange` reports the same value as a `Duration`, whenever the text moves.

## Properties

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `target` | `DateTime?` | `null` | The moment counted towards, or from |
| `controller` | `CountdownController?` | `null` | Drives the count; see above |
| `type` | `CountdownType` | `down` | Towards the target, or away from it |
| `format` | `String` | `'HH:mm:ss'` | How the time is written out |
| `onFinish` | `VoidCallback?` | `null` | Once, when a downward count reaches zero |
| `onChange` | `ValueChanged<Duration>?` | `null` | Whenever the drawn time moves |
| `builder` | `Widget Function(BuildContext, String)?` | `null` | Wraps the formatted time |
| `token` | `CountdownToken?` | `null` | Per-instance token overrides |

## Tokens

`CountdownToken`: `fontSize`, `color`, `fontWeight`.

```dart
Countdown(target: deadline, token: const CountdownToken(fontSize: 32))
```

…or every countdown under a subtree through `ConfigProvider`:

```dart
ConfigProvider(
  theme: ThemeData(components: ComponentsConfig(
    countdown: CountdownToken(color: Color(0xFFCF1322)),
  )),
  child: const MyApp(),
)
```
