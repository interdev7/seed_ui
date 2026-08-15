# Result

A full-width status page for the outcome of an operation — a completed
purchase, a 404, a permission error.

```dart
Result(
  status: StatusType.success,
  title: 'Payment received',
  subTitle: 'Order 2017182818828182881 is being processed.',
  extra: [
    Button(
      color: ButtonColor.primary,
      onPressed: goHome,
      child: const Text('Go home'),
    ),
  ],
)
```

For a compact inline notice use a [Alert](../feedback/alert.md) instead.

## Anatomy

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | `String` | required | Headline stating the outcome |
| `subTitle` | `String?` | `null` | Supporting line below the title |
| `status` | `StatusType` | `info` | Icon and colour |
| `icon` | `Widget?` | `null` | Replaces the status icon |
| `extra` | `List<Widget>?` | `null` | Action buttons, centred below the text |
| `child` | `Widget?` | `null` | Content between the text and the actions |

## Status

`status` picks the icon and its tint: `success`, `info` (default), `warning`,
`error`. The icon is a bold glyph on a soft tinted disc.

## Actions

`extra` lays its widgets out centred and wrapping, so several buttons read as a
group:

```dart
Result(
  status: StatusType.error,
  title: 'Submission failed',
  subTitle: 'Please check and try again.',
  extra: [
    Button(color: ButtonColor.primary, onPressed: retry, child: const Text('Retry')),
    Button(onPressed: back, child: const Text('Go back')),
  ],
)
```

## Extra content

`child` inserts arbitrary content between the text and the actions — a details
panel explaining an error, say:

```dart
Result(
  status: StatusType.error,
  title: 'Could not process the request',
  child: Alert(
    type: StatusType.error,
    message: 'The account is missing a billing address.',
    showIcon: true,
  ),
  extra: [/* ... */],
)
```

## Design tokens

`ResultToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
Result(
  // …
  token: const ResultToken(),
);

// …or for every Result in a subtree:
ConfigProvider(
  components: const [ResultToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
