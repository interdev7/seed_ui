# Timeline

A vertical list of events. Each `TimelineItem` is a
dot on the axis with its `content` beside it.

```dart
Timeline(items: [
  TimelineItem(content: const Text('Create a services site 2015-09-01')),
  TimelineItem(content: const Text('Solve initial network problems 2015-09-01')),
  TimelineItem(color: token.error.base, content: const Text('Technical testing')),
])
```

For a task in progress — statuses, a current step, tappable stages — reach for
[Steps](steps.md) instead: it measures a journey rather than recording one.

## Items

Each `TimelineItem` has a body — any of `title`, `description` and `content` —
and optionally:

- `title` — the node's headline (Chakra UI's `Timeline.Title`), rendered in the
  body's own emphasis.
- `description` — a supporting line under the title
  (`Timeline.Description`), smaller and in the secondary text colour.
- `color` — the dot colour. Null uses the theme primary;
  pass any `Color` for the `green` / `red` / `gray` presets or a custom hue.
- `dot` — a custom node replacing the default ring dot.
- `label` — content on the opposite side of the axis (a timestamp, say).
- `position` — forces the content's side in `alternate` mode.
- `height` / `width` — fixes the item's length along the axis (the line below
  it when vertical, or to its right when horizontal), like the
  `styles.root.height`.
- `dashed` — dashes this item's connecting line (`styles.rail.borderStyle`).
- `contentOpacity` — fades this item's content (`styles.content.opacity`).

```dart
TimelineItem(
  content: const Text('…for a long time…'),
  height: 100,
  dashed: true,
  contentOpacity: 0.45,
)
```

`title`, `description` and `content` stack in that order, so a node reads as a
titled entry without composing a `Column` by hand. `content` still stands alone
when that is all you need:

```dart
TimelineItem(
  color: token.success.base,
  title: const Text('Build #1287 passed'),
  description: const Text('2015-09-01 09:12'),
  content: Card(
    size: SoftSize.small,
    title: const Text('CI report'),
    child: const Text('124 tests · 0 failed'),
  ),
)
```

## Groups

A `TimelineGroupItem` is a run of nodes on the same axis that collapses down to
its first few. Drop one into `items` like any other item — it draws no dot of
its own, its `items` supply every node, so the axis stays one continuous line
whether the group is open or shut.

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<TimelineItem>` | required | The nodes in the group |
| `controller` | `TimelineGroupController?` | `null` | Drives it from outside |
| `initiallyExpanded` | `bool` | `false` | Starting state with no controller |
| `collapsedCount` | `int` | `1` | Leading nodes that stay visible |

`TimelineGroupController` exposes `open()`, `close()`, `toggle()` and
`expanded`, and is a `ChangeNotifier` — listen to it to keep a button's label in
step. Dispose it with the widget that owns it; a group without a controller
keeps its own state and needs no disposal.

```dart
final group = TimelineGroupController();

ListenableBuilder(
  listenable: group,
  builder: (context, _) => Button(
    onPressed: group.toggle,
    child: Text(group.expanded ? 'Hide steps' : 'Show 4 more steps'),
  ),
);

Timeline(items: [
  const TimelineItem(title: Text('Pull request opened')),
  TimelineGroupItem(
    controller: group,
    items: [
      const TimelineItem(title: Text('CI pipeline'), description: Text('4 steps')),
      const TimelineItem(title: Text('Lint')),
      const TimelineItem(title: Text('Unit tests')),
      const TimelineItem(title: Text('Build')),
    ],
  ),
  const TimelineItem(title: Text('Merged to main')),
]);
```

The hidden nodes slide open along the axis — vertically through the shared
`Expandable`, horizontally by the same motion on the other axis.

## Mode

| `TimelineMode` | Layout |
| --- | --- |
| `left` (default) | Axis on the left, content on the right |
| `right` | Axis on the right, content on the left |
| `alternate` | Axis centred, content alternating side to side |

```dart
Timeline(mode: TimelineMode.alternate, items: items)
```

## Orientation

`orientation` runs the axis down the page (`TimelineOrientation.vertical`, the
default) or across it (`horizontal`). In a horizontal timeline the `mode` values
read as top/bottom rather than left/right, and `label` takes the opposite side
from the content.

```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Timeline(
    orientation: TimelineOrientation.horizontal,
    items: items,
  ),
)
```

## Dots and spacing

- `variant` — `TimelineVariant.outlined` (default) draws ring dots,
  `filled` solid ones. A single item overrides the run with its own
  `dotVariant`, for the one node that has to stand out:

  ```dart
  Timeline(items: const [
    TimelineItem(title: Text('Joined')),
    TimelineItem(title: Text('Verified'), dotVariant: TimelineVariant.filled),
  ])
  ```

- `titleSpan` — distance from the dot to the content in logical pixels,
  12 by default. Horizontally it is the same gap, above
  and below the axis.

  ```dart
  Timeline(titleSpan: 32, items: items)
  ```
- `linePadding` — insets on each connecting line, opening a gap at the item's
  leading (`top`) or trailing (`bottom`) end. Null keeps the line fully joined.
- `railInset` (a token) — the gaps the line keeps either side of a **dot**, as a
  [`RailInsets`](../../lib/src/utils/rail.dart). No gaps, the default, runs the
  thread right up to the dot; a gap turns it into a
  separator, the way [Steps](steps.md) draws its rail. The sides are named for
  the run: `top`/`bottom` above and below a dot on a vertical axis,
  `left`/`right` either side of one across the page.

  Each gap is measured from the dot's **edge**, so the gap you ask for is the
  gap you see whatever `dotSize` says, and neither grows past the run it eats
  into — that would ask for a line of negative length.

  ```dart
  Timeline(items: items, token: const TimelineToken(
    railInset: RailInsets.all(4),
  ));

  // Or one end alone: a gap below each dot, the thread joined above it.
  Timeline(items: items, token: const TimelineToken(
    railInset: RailInsets.vertical(bottom: 4),
  ));
  ```

## Pending & reverse

`pending` appends a trailing "in progress" node — its widget is the node's
content, joined by a dashed segment and marked with a spinner (`pendingDot`
overrides it). `reverse: true` flips the order, moving the pending node to the
top.

```dart
Timeline(
  pending: const Text('Recording…'),
  items: items,
)
```

## Design tokens

`Timeline` has its own token set
(`tailColor`, `tailWidth`, `dotBg`, `dotBorderWidth`, `dotSize`, `railInset`,
`itemPaddingBottom` for vertical timelines and `itemPaddingEnd` for horizontal
ones). Every field is an override; an unset one falls back to the
global theme.

```dart
Timeline(
  items: items,
  token: const TimelineToken(tailColor: Color(0xFFEB2F96)),
)
```

…or every `Timeline` under a subtree through `ConfigProvider` — the
`ConfigProvider.theme.components`:

```dart
ConfigProvider(
  components: const [TimelineToken(dotSize: 12)],
  child: MaterialApp(...),
)
```

A per-instance `token` still wins over the `ConfigProvider` one.
