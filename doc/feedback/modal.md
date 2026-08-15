# Modal

Blocking dialogs that interrupt the page to ask a question or report an
outcome. Reached through the global `Modal` getter — no `BuildContext`
required.

```dart
final ok = await Modal.confirm(
  title: 'Delete file?',
  content: 'This cannot be undone.',
  okText: 'Delete',
  danger: true,
);
if (ok) delete();
```

Every opener returns a `Future<bool>` that completes with true when confirmed
and false when dismissed, so a decision reads as one `await` instead of a pair
of callbacks.

## Setup

Modals render into the root navigator's overlay:

```dart
MaterialApp(
  navigatorKey: UiKit.navigatorKey,
  home: const HomePage(),
)
```

## Methods

| Method | Buttons | Use for |
| --- | --- | --- |
| `Modal.confirm(...)` | OK + Cancel | A decision the user can decline |
| `Modal.info(...)` | OK | Neutral information |
| `Modal.success(...)` | OK | Reporting a completed operation |
| `Modal.error(...)` | OK | Reporting a failure |
| `Modal.warning(...)` | OK | Flagging something that needs attention |
| `Modal.open(config)` | — | Full control via `ModalConfig` |
| `Modal.destroyAll()` | — | Dismisses every open dialog |

The acknowledgement variants hide the cancel button: there is nothing to
decline, so offering both buttons would only ask the user to pick between two
identical outcomes.

## Vertical placement

By default the dialog sits in the upper third of the screen. That keeps it
near where the user is already looking, and — because it is anchored rather
than centred — its top edge does not move as the content grows, so a dialog
whose body loads asynchronously will not jump.

To centre it:

```dart
Modal.confirm(title: 'Delete file?', centered: true);
```

For an exact offset from the top of the safe area:

```dart
Modal.confirm(title: 'Delete file?', top: 100);
```

`centered` wins if both are given. Both are available on every opener and on
`ModalConfig`.

Horizontal placement is always centred; use `width` to change how much room
the dialog takes.

## Async confirmation

Return a `Future` from `onOk` and the button spins while it runs, with the
dialog held open. The user cannot confirm twice or navigate away from a
decision that is still being applied:

```dart
Modal.confirm(
  title: 'Publish changes?',
  onOk: () async {
    await api.publish();
    message.success('Published');
    return true;
  },
);
```

Cancel stays live throughout, so a hung request never traps the user.

## Vetoing the close

Return `false` from `onOk` to keep the dialog open — useful when validation
fails:

```dart
Modal.confirm(
  title: 'Rename',
  child: TextField(controller: controller),
  onOk: () {
    if (controller.text.trim().isEmpty) {
      message.error('Name cannot be empty');
      return false;
    }
    return true;
  },
);
```

Returning `true` or `null` closes the dialog as usual.

## Dismissal

A modal can be dismissed four ways, all resolving the future to false and
firing `onCancel`:

- the cancel button
- the close icon (`closable`)
- tapping the mask (`maskClosable`)
- pressing Escape (`escapeClosable`)

Turn off `maskClosable` for decisions carrying unsaved work, so a stray tap
cannot discard it:

```dart
Modal.confirm(
  title: 'Discard draft?',
  maskClosable: false,
);
```

Leave at least one route out. Setting `closable: false`, `maskClosable: false`
and `escapeClosable: false` together on a dialog whose buttons never close it
strands the user.

## Focus and the keyboard

While a modal is open it takes focus, so Tab cannot reach the page behind the
mask and Escape is handled by the dialog rather than the page. Focus returns
to the page when the modal closes.

## Custom content

`child` replaces the body text with any widget:

```dart
Modal.confirm(
  title: 'Pick a colour',
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [for (final c in colours) ColourTile(c)],
  ),
);
```

Long content scrolls: the dialog is capped at 80% of the viewport height.

## Custom footer

`footer` replaces the default buttons entirely. The supplied widgets are
responsible for closing the dialog, so hold on to the handle:

```dart
Modal.open(ModalConfig(
  title: 'Choose',
  footer: [
    Button(onPressed: () => Modal.destroyAll(), child: const Text('Later')),
  ],
));
```

## Stacking

Modals stack, so a confirmation can raise an error dialog on failure. Each
layer keeps its own mask and focus scope, and Escape dismisses the innermost
one. `Modal.destroyAll()` clears every layer.

## Configuration

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | `String?` | `null` | Headline |
| `content` | `String?` | `null` | Body text; ignored when `child` is set |
| `child` | `Widget?` | `null` | Arbitrary body content |
| `type` | `StatusType?` | varies | Status icon; null renders none |
| `okText` | `String` | `'OK'` | Confirming button label |
| `cancelText` | `String` | `'Cancel'` | Dismissing button label |
| `showCancel` | `bool` | `true` | Whether to show the cancel button |
| `onOk` | `FutureOr<bool?> Function()?` | `null` | Confirm handler |
| `onCancel` | `VoidCallback?` | `null` | Runs on any dismissal |
| `danger` | `bool` | `false` | Recolors the confirm button |
| `width` | `double` | `416` | Nominal width, capped to the viewport |
| `centered` | `bool` | `false` | Centers vertically; wins over `top` |
| `top` | `double?` | `null` | Exact offset from the top of the safe area |
| `closable` | `bool` | `true` | Shows the close icon |
| `maskClosable` | `bool` | `true` | Mask taps dismiss |
| `escapeClosable` | `bool` | `true` | Escape dismisses |
| `barrierColor` | `Color?` | `null` | Background color of the dismiss barrier |
| `icon` | `Widget?` | `null` | Replaces the status icon |
| `footer` | `List<Widget>?` | `null` | Replaces the buttons |

## Testing

Because the openers return a future that only completes when the dialog
closes, a regression in any dismissal path turns `await` into a hang. Give
modal tests a deadline so they fail fast:

```dart
@Timeout(Duration(seconds: 10))
library;
```

Drive frames explicitly — `pumpAndSettle` cannot be used when a confirm button
is in its loading state:

```dart
final future = Modal.confirm(title: 'Delete?');
await tester.pump();
await tester.pump(const Duration(milliseconds: 400));

await tester.tap(find.text('OK'));
await tester.pump();
await tester.pump(const Duration(milliseconds: 400));
await tester.pump();

expect(await future, isTrue);
```

Call `Modal.destroyAll()` at the end of tests that leave a dialog open — the
stack is global and otherwise leaks into the next test.

## Design tokens

`ModalToken` overrides this component's own tokens. It rides on `ModalConfig`, since a
modal is opened through the API rather than built as a widget:

```dart
modal.open(ModalConfig(
  // …
  token: const ModalToken(),
));

// …or for every modal in a subtree:
ConfigProvider(
  components: const [ModalToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
