# message

Brief status toasts, centred at the top of the screen. Reached through the
global `message` getter — no `BuildContext` required.

```dart
message.success('Saved');
```

## Setup

`message` renders into the root navigator's overlay, so the navigator key must
be installed once:

```dart
MaterialApp(
  navigatorKey: UiKit.navigatorKey,
  home: const HomePage(),
)
```

Without it, calls assert in debug mode with instructions.

## Methods

| Method | Default duration | Notes |
| --- | --- | --- |
| `message.success(content)` | 3s | |
| `message.error(content)` | 3s | |
| `message.warning(content)` | 3s | |
| `message.info(content)` | 3s | |
| `message.loading(content)` | never | Ends when you call the returned handle |
| `message.open(config)` | 3s | Full control via `MessageConfig` |
| `message.config(...)` | — | Changes defaults for later calls |
| `message.destroy()` | — | Dismisses everything on screen |

Each opener accepts `duration`, `onClose` and `key`, and returns a
`MessageHandle` that dismisses the toast early.

## Duration

`Duration.zero` pins a message on screen until it is dismissed explicitly:

```dart
final close = message.info('Reconnecting…', duration: Duration.zero);
await reconnect();
close();
```

`message.loading` defaults to this, since loading ends when the work does
rather than after a timer:

```dart
final close = message.loading('Uploading…');
try {
  await upload();
  message.success('Uploaded');
} finally {
  close();
}
```

## Keys

Reusing a `key` replaces the message showing under it instead of stacking a
second copy — useful for progress that updates in place:

```dart
message.loading('Uploading… 0%', key: 'upload');
message.loading('Uploading… 50%', key: 'upload');
message.success('Uploaded', key: 'upload');
```

## Defaults

```dart
message.config(
  maxCount: 3,                          // evicts the oldest past this many
  duration: const Duration(seconds: 5), // applies to calls without an explicit duration
  top: 48,                              // distance from the top edge
);
```

`maxCount` counts toasts on screen; when exceeded, the oldest is dismissed
with its normal exit animation.

## Full configuration

```dart
message.open(MessageConfig(
  content: 'Custom',
  type: StatusType.warning,
  duration: const Duration(seconds: 10),
  icon: const Icon(Icons.pets, size: 16),
  onClose: () => debugPrint('closed'),
  key: 'custom',
));
```

| Field | Type | Description |
| --- | --- | --- |
| `content` | `String` | The text |
| `type` | `StatusType` | Status icon and color |
| `duration` | `Duration?` | `Duration.zero` disables auto-dismiss |
| `icon` | `Widget?` | Replaces the status icon |
| `onClose` | `VoidCallback?` | Runs after the exit animation |
| `key` | `Object?` | Identity for replacement |

## message or notification?

Use `message` for a one-line outcome the user does not need to act on. Reach
for [notification](../feedback/notification.md) when there is a headline plus detail, or
buttons to press.

## Testing

`message.loading` renders a perpetually animating spinner, so
`pumpAndSettle` will time out. Drive frames by hand:

```dart
testWidgets('shows a toast', (tester) async {
  await tester.pumpWidget(MaterialApp(
    navigatorKey: UiKit.navigatorKey,
    home: const Scaffold(body: SizedBox()),
  ));

  message.success('Saved', duration: Duration.zero);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.text('Saved'), findsOneWidget);

  message.destroy();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(); // the stack rebuilds a frame after the animation ends
  expect(find.text('Saved'), findsNothing);
});
```

Because the stack is global, always `message.destroy()` at the end of a test —
a live toast otherwise leaks into the next one.

## Design tokens

`MessageToken` overrides this component's own tokens. It rides on
`MessageConfig`, since a message is opened through the API rather than built as
a widget:

```dart
message.open(const MessageConfig(
  content: 'Saved',
  token: MessageToken(),
));

// …or for every message in a subtree:
ConfigProvider(
  components: const [MessageToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
