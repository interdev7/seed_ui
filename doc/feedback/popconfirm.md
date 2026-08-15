# Popconfirm

A confirmation bubble anchored to its trigger, for low-stakes yes/no
decisions — deleting a row, discarding a draft — where a full
[Modal](../feedback/modal.md) would be too heavy. Unlike `message` and `notification`,
this is a widget you wrap around a trigger, not a global call.

```dart
Popconfirm(
  title: Text('Delete this item?'),
  okText: Text('Delete'),
  danger: true,
  onOk: () => delete(item),
  child: Button(
    variant: ButtonVariant.text,
    onPressed: () {},
    child: const Text('Delete'),
  ),
)
```

The bubble opens when the trigger is tapped and closes on confirm, cancel, or
a tap outside it.

> **Trigger buttons.** Give the wrapped control a non-null `onPressed` (even
> `() {}`) so it renders enabled — the popconfirm handles the tap itself, but a
> button with a null handler still looks disabled.

## Modal or Popconfirm?

Use `Popconfirm` when the decision is minor and tied to a specific
control, and its consequences are obvious from context. Reach for `Modal` when
the choice deserves the user's full attention, needs more than a sentence of
explanation, or is not anchored to one trigger.

## Placement

The bubble defaults to `PopoverPlacement.top`. All twelve placements are
available — four sides, each with a `start`/`end` variant that shifts the
bubble along the trigger's edge:

```dart
Popconfirm(
  title: Text('Sure?'),
  placement: PopoverPlacement.rightTop,
  onOk: save,
  child: trigger,
)
```

| Group | Values                                |
| ----- | ------------------------------------- |
| Above | `top`, `topLeft`, `topRight`          |
| Below | `bottom`, `bottomLeft`, `bottomRight` |
| Left  | `left`, `leftTop`, `leftBottom`       |
| Right | `right`, `rightTop`, `rightBottom`    |

If the chosen side lacks room, the bubble flips to the opposite one; along the
other axis it shifts as needed to stay within the viewport. The position is
resolved when the bubble opens, so — as in most popover libraries — scroll the
page and you should close and reopen it rather than expect it to track.

## Async confirmation

Return a `Future` from `onOk` and the confirm button spins while it runs,
with the bubble held open, so the trigger cannot fire twice:

```dart
Popconfirm(
  title: Text('Publish now?'),
  onOk: () async {
    await api.publish();
    message.success('Published');
  },
  child: trigger,
)
```

While confirming, an outside tap will not close the bubble — the operation
runs to completion.

## Description

`description` adds a line of detail below the title:

```dart
Popconfirm(
  title: Text('Delete this item?'),
  description: Text('This action cannot be undone.'),
  onOk: delete,
  child: trigger,
)
```

## Cancellation

`onCancel` fires when the user presses cancel or taps outside. Set
`showCancel: false` for a single-button acknowledgement that still requires a
deliberate tap:

```dart
Popconfirm(
  title: Text('Got it?'),
  showCancel: false,
  onOk: acknowledge,
  child: trigger,
)
```

## Disabling

`disabled: true` lets the trigger behave normally and never opens the bubble —
useful when the action is conditionally unavailable but the control should
still be interactive for another reason.

## Configuration

| Field         | Type                         | Default    | Description                                |
| ------------- | ---------------------------- | ---------- | ------------------------------------------ |
| `child`       | `Widget`                     | required   | The trigger                                |
| `title`       | `Widget`                     | required   | The question                               |
| `description` | `Widget?`                    | `null`     | Detail below the title                     |
| `okText`      | `Widget`                     | `Text('OK')` | Confirm button label                     |
| `cancelText`  | `Widget`                  | `Text('Cancel')` | Cancel button label                   |
| `onOk`        | `FutureOr<void> Function()?` | `null`     | Confirm handler                            |
| `onCancel`    | `VoidCallback?`              | `null`     | Cancel/dismiss handler                     |
| `danger`      | `bool`                       | `false`    | Recolors the confirm button                |
| `placement`   | `PopoverPlacement`           | `top`      | Bubble side                                |
| `arrow`       | `bool`                       | `true`     | Draw a caret pointing at the trigger       |
| `icon`        | `Widget?`                    | warning    | Leading icon; `SizedBox.shrink()` hides it |
| `showCancel`  | `bool`                       | `true`     | Whether to show the cancel button          |
| `disabled`    | `bool`                       | `false`    | Trigger acts normally, bubble never opens  |
| `barrierColor`| `Color?`                     | `null`     | Background color of the dismiss barrier    |

## Building your own popover

`Popconfirm` is built on `Popover`, a general anchored-overlay widget
you can use for custom bubbles:

```dart
Popover(
  placement: PopoverPlacement.bottom,
  content: (context) => MyBubble(),
  child: MyTrigger(),
)
```

Drive it with `open`/`onOpenChanged` for controlled visibility, or imperatively
through a `GlobalKey<PopoverState>`. For lower-level control still, a
`PopoverController` manages a single anchored layer directly.

## Testing

`pumpAndSettle` cannot be used — an async confirm renders a perpetual spinner.
Drive frames explicitly:

```dart
await tester.tap(find.text('trigger'));
await tester.pump();
await tester.pump(const Duration(milliseconds: 250));
expect(find.text('Delete this item?'), findsOneWidget);

await tester.tap(find.text('OK'));
await tester.pump();
await tester.pump(const Duration(milliseconds: 250));
await tester.pump();
```

## Design tokens

`PopconfirmToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
Popconfirm(
  // …
  token: const PopconfirmToken(),
);

// …or for every Popconfirm in a subtree:
ConfigProvider(
  components: const [PopconfirmToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
