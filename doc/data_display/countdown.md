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
| `target` | `DateTime` | required | The moment counted towards, or from |
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
