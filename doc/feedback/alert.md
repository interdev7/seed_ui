# Alert

An inline banner for a status message, shown in the page flow rather than
floating over it. Use it for a persistent notice tied to a region of the UI —
a form error, a feature announcement.

```dart
Alert(
  type: StatusType.success,
  message: const Text('Saved'),
  description: const Text('Your changes are live.'),
  showIcon: true,
  closable: true,
)
```

For transient feedback reach for [message](../feedback/message.md); for a notice that
interrupts, a [Modal](../feedback/modal.md).

## Types

`type` selects the colours and icon, from [StatusType]: `success`, `info`
(default), `warning`, `error`. `loading` is treated as `info`.

## Anatomy

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `message` | `Widget` | required | Headline; grows to `fontSizeLG` when a description is present |
| `description` | `Widget?` | `null` | Detail block below the message |
| `type` | `StatusType` | `info` | Colours and icon |
| `showIcon` | `bool` | `false` | Show the leading status icon |
| `closable` | `bool` | `false` | Show a close button |
| `icon` | `Widget?` | `null` | Replaces the status icon |
| `action` | `Widget?` | `null` | Trailing widget, usually a button |
| `banner` | `bool` | `false` | Full-width banner: square, borderless |
| `gradient` | `Gradient?` | `null` | Optional background gradient fill |
| `onClose` | `VoidCallback?` | `null` | Runs after dismissal |
| `token` | `AlertToken?` | `null` | Per-instance token overrides |

## Closable

A closable alert manages its own visibility — tapping the close button removes
it from the tree and fires `onClose`:

```dart
Alert(
  message: const Text('Connection restored'),
  type: StatusType.success,
  closable: true,
  onClose: () => debugPrint('dismissed'),
)
```

## With an action

`action` sits at the trailing edge, for a one-tap response:

```dart
Alert(
  message: const Text('A new version is available'),
  showIcon: true,
  action: Button(
    size: SoftSize.small,
    onPressed: reload,
    child: const Text('Reload'),
  ),
)
```

## Banner

`banner: true` drops the border and corners for a notice pinned across the top
of a page:

```dart
Alert(
  banner: true,
  type: StatusType.warning,
  message: const Text('You are viewing a staging environment.'),
  showIcon: true,
)
```

## Text styling

`message` and `description` are widgets, and the alert seeds their text style
through `DefaultTextStyle` — a plain `Text` picks up the right size and colour
with no styling of its own. The title takes `fontSizeLG` once a description is
present and the body size otherwise.

Because it is only a default, a child that sets its own `TextStyle` wins, and
anything composes:

```dart
Alert(
  type: StatusType.info,
  showIcon: true,
  message: Row(children: [
    const Text('Build '),
    Tag(color: TagColor.processing, child: const Text('#1287')),
    const Text(' is running'),
  ]),
  description: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Started 2 minutes ago.'),
      const SizedBox(height: 8),
      const Progress(percent: 0.62, size: SoftSize.small),
    ],
  ),
)
```

## Design tokens

`AlertToken` overrides `padding`, `withDescriptionPadding`,
`withDescriptionIconSize`, `borderRadius` and `fontSize` — per instance through
`token`, or for a whole subtree through
`ThemeData(components: ComponentsConfig(alert: AlertToken(...)))`.

```dart
Alert(
  message: const Text('Roomier and rounder'),
  description: const Text('padding and radius overridden'),
  showIcon: true,
  token: const AlertToken(
    withDescriptionPadding: EdgeInsets.all(20),
    borderRadius: 20,
  ),
)
```
