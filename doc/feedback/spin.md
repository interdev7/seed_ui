# Spin

A spinner indicator for loading states.

```dart
// Standalone
Spin()

// Container wrapper
Spin(
  spinning: isLoading,
  tip: const Text('Loading...'),
  child: ListView(...),
)
```

## Sizes

`size` accepts preset sizes (`SoftSize.small`, `SoftSize.middle`, `SoftSize.large`) or explicit dimensions:

- `SoftSize.small`: 14px indicator
- `SoftSize.middle`: 20px indicator (default)
- `SoftSize.large`: 32px indicator
- Explicit dimension: `24.0` or `Size(24, 24)`

```dart
Spin(size: SoftSize.small)
Spin(size: SoftSize.middle)
Spin(size: SoftSize.large)
```

## Anatomy / API

| Property     | Type         | Default           | Description                                                                       |
| ------------ | ------------ | ----------------- | --------------------------------------------------------------------------------- |
| `spinning`   | `bool`       | `true`            | Controls active loading state                                                     |
| `size`       | `SoftSize`   | `SoftSize.middle` | Preset size (`SoftSize.small`/`middle`/`large`)                                   |
| `tip`        | `Widget?`    | `null`            | Optional widget (e.g. `Text`) rendered below the indicator, automatically styled  |
| `delay`      | `Duration?`  | `null`            | Delays displaying indicator when `spinning` turns true (prevents loading flicker) |
| `indicator`  | `Widget?`    | `null`            | Custom indicator widget overriding default 4-dot rotating animation               |
| `child`      | `Widget?`    | `null`            | Container widget wrapped with mask & blur overlay when `spinning: true`           |
| `fullscreen`          | `bool`                   | `false`           | Renders as a full-screen modal backdrop overlay                                   |
| `percent`             | `double?`                | `null`            | Progress percentage (0.0–1.0 or 0–100). Replaces the 4 dots with a circle ring.   |
| `color`               | `Color?`                 | `null`            | Overrides primary dot indicator color                                             |
| `overlayBorderRadius` | `BorderRadiusGeometry?`  | `null`            | Override overlay border radius. If null, auto-detects from context/parent widget. |
| `token`               | `SpinToken?`             | `null`            | Per-instance token overrides                                                      |

## Container Loading Overlay (child)

When a `child` is passed, `Spin` acts as a container wrapper. When `spinning: true`, the child is masked with opacity and touch input is blocked (`AbsorbPointer`), while the indicator and `tip` are centered on top.

```dart
Spin(
  spinning: _loading,
  tip: const Text('Fetching data...'),
  child: Container(
    padding: const EdgeInsets.all(16),
    child: const Text('Card Content'),
  ),
)
```

## Custom Indicator

Override the default 4-dot animation per instance:

```dart
Spin(
  indicator: const Icon(Icons.sync, color: Colors.blue),
  tip: const Text('Syncing...'),
)
```

## Delay Loading

Use `delay` to specify a grace period before showing the spin indicator. If loading completes within the delay window, the spinner will not flicker on screen:

```dart
Spin(
  spinning: _loading,
  delay: Duration(milliseconds: 500),
  child: ContentWidget(),
)
```

## Fullscreen Mode

Render a modal backdrop overlay over the entire screen:

```dart
Spin(
  fullscreen: true,
  tip: const Text('Loading application...'),
)
```

## Position

`position` (a `SpinPosition`) places the indicator within its container or
overlay mask. Defaults to `SpinPosition.center`.
