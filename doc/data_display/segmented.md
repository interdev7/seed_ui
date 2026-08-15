# Segmented

A single-select control laid out as a row of segments, with a thumb that slides
to the chosen one. Use it to switch between a few mutually exclusive options in
place — a view mode, a density, a time range.

```dart
Segmented<String>(
  value: _view,
  onChanged: (v) => setState(() => _view = v),
  options: const [
    SegmentedOption(value: 'list', label: 'List'),
    SegmentedOption(value: 'grid', label: 'Grid'),
  ],
)
```

For more than a handful of options, or for navigating between views, prefer
tabs.

## Value

`Segmented<T>` is generic over the value type, so options can carry any
value — a string, an int, an enum. It is a controlled widget: pass the selected
`value` and update it in `onChanged`.

```dart
enum Range { day, week, month }

Segmented<Range>(
  value: _range,
  onChanged: (v) => setState(() => _range = v),
  options: const [
    SegmentedOption(value: Range.day, label: 'Day'),
    SegmentedOption(value: Range.week, label: 'Week'),
    SegmentedOption(value: Range.month, label: 'Month'),
  ],
)
```

## Options

Each `SegmentedOption` needs a `value` and a `label`, an `icon`, or both:

```dart
SegmentedOption(value: 'list', label: 'List', icon: Icon(Icons.view_list))
```

Set `disabled: true` on an option to make that segment unselectable while the
rest stay live. For anything richer than a label and icon, pass a `child` — it
replaces both and renders as-is (style your own selected/unselected colours):

```dart
SegmentedOption(value: 'a', child: MyBadge())
```

## Direction

`direction: Axis.vertical` stacks the segments in a column,
each stretched to the same width; the thumb slides up and down instead of
across.

## Adaptive layout and the sliding thumb

Segments size to their content, so a long label like "Comfortable" is never
clipped. The thumb is measured from the selected segment's actual rectangle and
animated to it with the kit's motion curve, so it slides smoothly regardless of
whether segments differ in width.

## Sizes and layout

| Property     | Description                                              |
| ------------ | -------------------------------------------------------- |
| `size`       | `small` (24px), `middle` (32px, default), `large` (40px) |
| `direction`  | `horizontal` (default) or `vertical`                     |
| `block`      | Stretch the segments to fill the available space equally |
| `disabled`   | Grey the whole control out and block selection           |
| `trackColor` | Override the background colour                           |
| `thumbColor` | Override the sliding thumb's colour                      |

A non-block control sizes to its content; a `block` one fills its parent,
splitting the space evenly.

```dart
Segmented<int>(
  value: _density,
  block: true,
  onChanged: (v) => setState(() => _density = v),
  options: const [
    SegmentedOption(value: 0, label: 'Compact'),
    SegmentedOption(value: 1, label: 'Cozy'),
    SegmentedOption(value: 2, label: 'Comfortable'),
  ],
)
```

## Disabling

Passing `disabled: true`, or leaving `onChanged` null, makes the whole control
inert and greyed. Disable a single option instead with its own `disabled` flag.

## Width

The control is as wide as its options and no wider — the
`inline-flex` behaviour. A parent that hands down a tight width, such as a
`Column` with `crossAxisAlignment: stretch`, does not stretch the track.

`block: true` is how you ask for the full width, with the options sharing it
equally:

```dart
Segmented(block: true, value: v, options: options, onChanged: onChanged)
```

## Design tokens

`SegmentedToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
Segmented(
  // …
  token: const SegmentedToken(),
);

// …or for every Segmented in a subtree:
ConfigProvider(
  components: const [SegmentedToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
