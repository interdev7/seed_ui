# Progress

A progress indicator for a task whose completion is known, as a bar or a ring.

```dart
Progress(percent: 0.6)
Progress(type: ProgressType.circle, percent: 0.75)
```

For work of unknown duration use a [Spinner](../feedback/spinner.md) instead.

## Percent

`percent` runs from 0 to 1 (asserted). The line variant shows the rounded
percentage to its right; the circle shows it centred.

```dart
Progress(percent: 0.42) // renders "42%"
```

## Status

By default the fill is the primary colour, turning success-green at 100%. Set
`status` to override:

```dart
Progress(percent: 0.5, status: StatusType.error)   // red
Progress(percent: 1, status: StatusType.success)   // green + check
```

At 100% a check (success) or cross (error) replaces the text label.

## ControlSize

`size` accepts `ControlSize` presets or explicit dimensions:

- Preset: `SoftSize.small`, `SoftSize.middle`, `SoftSize.large`
- Fixed 1D dimension: `ControlSize.fixed(20)` or `ExplicitSquareSize(20)` or `20`
- Explicit 2D size: `ControlSize.raw(200, 10)` or `ExplicitSize(200, 10)`

```dart
Progress(percent: 0.8, size: SoftSize.small)
Progress(percent: 0.8, size: ControlSize.fixed(20))
Progress(percent: 0.8, size: ExplicitSize(200, 10))
```

## A child in place of the label

`child` takes the spot the percentage would have: the middle of a ring, or the
label's place on a bar. This is how a ring wraps something — an icon, a count,
a step's marker:

```dart
Progress(type: ProgressType.circle, percent: 0.6, child: Icon(Icons.cloud_upload))
```

[Steps](../data_display/steps.md) uses exactly this for the ring round its
current marker.

`copyWith` returns a copy with the given fields replaced, which is how a
`Progress` passed in as a template gets its value filled in.

## API Options

| Property          | Type                         | Default              | Description                                                                                  |
| ----------------- | ---------------------------- | -------------------- | -------------------------------------------------------------------------------------------- |
| `percent`         | `double`                     | required             | Completion ratio, 0–1                                                                        |
| `type`            | `ProgressType`               | `line`               | `line`, `circle` or `dashboard` (open ring)                                                  |
| `status`          | `StatusType?`                | `null`               | Overrides status color (`normal`, `active`, `success`, `error`)                              |
| `showInfo`        | `bool`                       | `true`               | Show percentage / completion badge                                                           |
| `strokeWidth`     | `double?`                    | `8` line, `6` circle | Track thickness                                                                              |
| `size`            | `ControlSize?`               | `SoftSize.middle`    | Preset (`SoftSize`), `ControlSize.fixed(20)`, or `ControlSize.raw(200, 10)`                  |
| `color`           | `Color?`                     | `null`               | Overrides fill color                                                                         |
| `trailColor`      | `Color?`                     | `null`               | Overrides unfilled track color                                                               |
| `gradient`        | `Gradient?`                  | `null`               | Linear or sweep gradient fill                                                                |
| `strokeColor`     | `List<Color>?`               | `null`               | Colors for individual steps or line colors                                                   |
| `rangeColors`     | `Map<ProgressRange, Color>?` | `null`               | Discrete color ranges keyed by start threshold (0–1)                                         |
| `steps`           | `ProgressSteps?`             | `null`               | Step configuration (`ProgressSteps(count, gap: 7, fill: ...)`)|
| `borderRadius`    | `ProgressBorderRadius?`      | `null`               | Custom corner radius for line progress (`ProgressBorderRadius.all(4)`, etc.) |
| `strokeLinecap`   | `StrokeCap?`                 | `round`              | Bar/ring cap shape (`round`, `butt` / `square`)                                              |
| `gapDegree`       | `double`                     | `75`                 | Open gap angle in degrees for dashboard                                                      |
| `gapPlacement`    | `GapPlacement`               | `bottom`             | Gap placement (`top`, `bottom`, `left`, `right`)                                             |
| `percentPosition` | `PercentPosition?`           | `null`               | Position and alignment of info label (`type: inner/outer`, `align: start/center/end/follow`) |
| `direction`       | `TextDirection?`             | `null`               | Text direction (`ltr`, `rtl`)                                                                |
| `format`          | `String Function(double)?`   | `null`               | Custom percentage label formatter                                                            |
| `onDone`          | `VoidCallback?`              | `null`               | Callback fired when progress reaches 100% completion                                         |
| `onProgressChange`| `void Function(double)?`     | `null`               | Callback fired when progress percentage changes (0.0 to 1.0)                                |
| `child`           | `Widget?`                    | `null`               | Content in place of the label: the middle of a ring, the label's spot on a bar               |

## Percent Position (Info Position)

`percentPosition` controls whether the percentage label is inside (`inner`) or outside (`outer`) the track, and its alignment (`start`, `center`, `end`, `follow`):

```dart
// Inner centered percentage (e.g. thick bar)
Progress(
  percent: 0.5,
  percentPosition: PercentPosition.inner(align: PercentInfoAlign.center),
  strokeWidth: 20,
)

// Inner follower percentage (tracks filled bar tip)
Progress(
  percent: 0.5,
  percentPosition: PercentPosition.inner(align: PercentInfoAlign.follow),
  strokeWidth: 20,
)

// Outer start-aligned percentage
Progress(
  percent: 0.6,
  percentPosition: PercentPosition.outer(align: PercentInfoAlign.start),
)
```

## Range Colors

Use `rangeColors` to assign discrete colors to percentage ranges. Each key is
the **start** of a range (0–1 scale); the last entry applies until 100 %.
Takes priority over `color` but **not** over `gradient`.

```dart
Progress(
  percent: 0.5,
  rangeColors: {
    ProgressRange(0.0, to: 0.3): Color(0xFFFF4D4F), // 0–30 %  — red
    ProgressRange(0.3, to: 0.7): Color(0xFFFFA940), // 30–70 % — orange
    ProgressRange(0.7): Color(0xFF52C41A), // 70–100% — green
  },
)
```

## Step Progress

`steps` configures discrete step segments using `ProgressSteps`. Works with `line`, `circle`, and `dashboard` progress types.

`ProgressSteps` parameters:
- `count`: total number of step segments (`int`)
- `gap`: spacing between step segments in pixels (default `2.0`)
- `fill`: filling mode (`ProgressStepFill.gradually` or `ProgressStepFill.immediately`)
- `stepRadius`: custom per-step radius builder `(isFirst, percent) => ProgressBorderRadius`
- `onStepChange`: callback when active step changes `(currentStep, totalSteps) => void`

```dart
// Basic line steps with immediate fill & step callback
Progress(
  percent: 0.6,
  steps: ProgressSteps(
    5,
    fill: ProgressStepFill.immediately,
    onStepChange: (step, total) {
      print('Step $step of $total reached');
    },
  ),
  onProgressChange: (percent) {
    print('Progress updated to ${percent * 100}%');
  },
)

// Circle steps
Progress(
  type: ProgressType.circle,
  percent: 0.6,
  steps: const ProgressSteps(5),
)

// Custom count & pixel gap (Circle/Line)
Progress(
  type: ProgressType.circle,
  percent: 0.5,
  steps: const ProgressSteps(5, gap: 7),
  strokeWidth: 20,
)

// Per-step corner radius customization (stepRadius)
Progress(
  percent: 0.6,
  strokeWidth: 16,
  steps: ProgressSteps(
    5,
    gap: 6,
    stepRadius: (isFirst, percent) {
      if (isFirst == true) return const ProgressBorderRadius.horizontal(left: 6);
      if (isFirst == false) return const ProgressBorderRadius.horizontal(right: 6);
      return ProgressBorderRadius.zero;
    },
  ),
)
```

## Border Radius (Line)

Control corner radius for line progress using `ProgressBorderRadius`, `BorderRadius`, or a `double`:

```dart
// Fixed radius for all corners
Progress(
  percent: 0.6,
  strokeWidth: 14,
  borderRadius: ProgressBorderRadius.all(4),
)

// Per-corner radius (e.g. rounded left, flat right)
Progress(
  percent: 0.6,
  strokeWidth: 14,
  borderRadius: ProgressBorderRadius(
    topLeft: 10,
    bottomLeft: 10,
  ),
)
```

## Dashboard Ring

```dart
Progress(
  type: ProgressType.dashboard,
  percent: 0.75,
  gapDegree: 90,
  gapPlacement: GapPlacement.bottom,
)
```

## Design tokens

`ProgressToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
Progress(
  // …
  token: const ProgressToken(),
);

// …or for every Progress in a subtree:
ConfigProvider(
  components: const [ProgressToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.

## Corners, and which end is which

`ProgressBorderRadius` comes in two forms. The plain constructors name a side —
`topLeft`, `horizontal(left:)` — and that side is what you get, whichever way
the bar reads. The directional ones name a reading end:

```dart
const ProgressBorderRadius.horizontalDirectional(start: 8)
const ProgressBorderRadius.directional(topStart: 10, bottomStart: 10)
```

`start` is the end the bar grows from, so the pair swaps over in a
right-to-left layout.

The directional form is usually what `ProgressSteps.stepRadius` wants. It is
handed `isFirst` — a place in the run, not a side — and the first step sits on
the right when the bar reads that way, so a radius named by side rounds the
wrong end of it.
