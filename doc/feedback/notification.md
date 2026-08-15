# notification

Corner-anchored cards carrying a headline, supporting detail and optional
action buttons. Reached through the global `notification` getter — no
`BuildContext` required.

```dart
notification.success('Done', description: 'Your file was uploaded.');
```

## Setup

Like `message`, notifications render into the root navigator's overlay:

```dart
MaterialApp(
  navigatorKey: UiKit.navigatorKey,
  home: const HomePage(),
)
```

## Methods

| Method | Description |
| --- | --- |
| `notification.success(message, ...)` | Success card |
| `notification.error(message, ...)` | Error card |
| `notification.warning(message, ...)` | Warning card |
| `notification.info(message, ...)` | Info card |
| `notification.open(config)` | Full control via `NotificationConfig` |
| `notification.config(...)` | Changes defaults for later calls |
| `notification.destroy([key])` | Dismisses everything, or one card by key |

The status openers accept `description`, `duration`, `placement`, `actions`,
`onClose` and `key`, and return a `NotificationHandle` that dismisses the
card early.

Default duration is 4.5 seconds — longer than a `message`, since there is more
to read.

## Placement

Four corners, each an independent stack:

```dart
notification.info(
  'Saved',
  placement: NotificationPlacement.bottomLeft,
);
```

| Value | Behaviour |
| --- | --- |
| `topRight` | Default; slides in from the right, stacks downward |
| `topLeft` | Slides in from the left, stacks downward |
| `bottomRight` | Slides in from the right, stacks upward |
| `bottomLeft` | Slides in from the left, stacks upward |

Because the corners are independent, `maxCount` applies per corner and cards
in different corners never reorder each other.

Cards are 384px wide, capped to the space the viewport leaves between the
corner offsets, so they never run off the opposite edge on a narrow screen. Once
a corner's cards outgrow the viewport the stack scrolls.

## Stacking

Past `stackThreshold` cards (3 by default) a corner folds into a deck: the
newest card stays legible and the ones behind it peek out, scaled and faded.
The deck unfolds into the full list on hover, and on touch — where there is no
hover — on a tap. Tapping outside folds it back, as does system back (the
Android button, a back gesture, the browser's back), which is intercepted only
while the deck is held open by a tap.

Collapsing and unfolding is one continuous animation: every card interpolates
its own height, offset, scale and opacity, so nothing jumps between two
layouts.

```dart
notification.config(stack: false);        // never fold
notification.config(stackThreshold: 5);   // fold past five cards
```

## Dismissing

A card leaves by playing its entry animation in reverse — sliding back towards
the edge it came from while its slot collapses — whether it was dismissed by
the close button, the timeout, `destroy()` or `maxCount`.

It can also be swiped away towards that same edge: right for a right-anchored
corner, left for a left-anchored one. The swipe commits past 30% of the card's
width or on a fling; short of that the card springs back. Dragging the other
way only rubber-bands.

## Actions

```dart
late final NotificationHandle close;
close = notification.open(NotificationConfig(
  message: const Text('Update available'),
  description: const Text('Version 2.0 is ready to install.'),
  type: StatusType.info,
  duration: Duration.zero,
  actions: [
    Button(
      size: SoftSize.small,
      onPressed: () => close(),
      child: const Text('Later'),
    ),
    Button(
      size: SoftSize.small,
      color: ButtonColor.primary,
      onPressed: () {
        close();
        install();
      },
      child: const Text('Install'),
    ),
  ],
));
```

Pair actions with `duration: Duration.zero`: a card that vanishes mid-decision
is worse than no card. Use `late final` for the handle so the buttons can
close their own notification.

## Keys

Reusing a `key` replaces the card showing under it. `destroy(key)` dismisses
just that one:

```dart
notification.info('Syncing…', duration: Duration.zero, key: 'sync');
notification.success('Synced', key: 'sync');   // replaces it
notification.destroy('sync');                  // dismisses it
```

## Defaults

```dart
notification.config(
  maxCount: 3,
  duration: const Duration(seconds: 8),
  placement: NotificationPlacement.bottomRight,
  offset: 32,          // distance from the screen corner
  stack: true,         // fold a crowded corner into a deck
  stackThreshold: 3,   // how many cards before it folds
);
```

## Full configuration

| Field | Type | Description |
| --- | --- | --- |
| `message` | `Widget` | Headline (required) |
| `description` | `Widget?` | Supporting detail |
| `type` | `StatusType?` | Status icon; null renders no icon |
| `duration` | `Duration?` | `Duration.zero` disables auto-dismiss |
| `placement` | `NotificationPlacement?` | Overrides the configured corner |
| `icon` | `Widget?` | Replaces the status icon |
| `actions` | `List<Widget>?` | Buttons along the bottom |
| `onClose` | `VoidCallback?` | Runs after the exit animation |
| `onTap` | `VoidCallback?` | Tap handler for the card body |
| `closable` | `bool` | Shows the close button; defaults to true |
| `key` | `Object?` | Identity for replacement |
| `token` | `NotificationToken?` | Per-instance token overrides |

Omitting `type` gives a neutral card with no status icon — right for content
that is not success or failure, such as a chat message or a new-item alert.

## Testing

```dart
notification.info('Hello', duration: Duration.zero);
await tester.pump();
await tester.pump(const Duration(milliseconds: 400));
expect(find.text('Hello'), findsOneWidget);

notification.destroy();
await tester.pump();
await tester.pump(const Duration(milliseconds: 400));
await tester.pump();
```

The stack is global, so dismiss everything at the end of each test. Avoid
`pumpAndSettle` — see [testing](../../README.md#testing-against-the-kit).
