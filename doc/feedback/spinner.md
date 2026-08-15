# Spinner

An indeterminate circular progress indicator: a faint track with a rotating
arc over it.

```dart
Spinner(size: 16, color: context.softToken.primary.base)
```

## Properties

| Property | Type | Description |
| --- | --- | --- |
| `size` | `double` | Width and height in logical pixels |
| `color` | `Color` | Arc color; the track is the same color at 20% opacity |

Both are required — the spinner is a primitive used inside other components,
which pass the size and color already resolved from the surrounding context.

## Usage

Most of the time you get one for free rather than building it yourself:
`Button(loading: true)` and `message.loading(...)` both render a spinner
sized and tinted to their content.

Reach for it directly when indicating loading in your own layout:

```dart
Widget build(BuildContext context) {
  final token = context.softToken;
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Spinner(size: 32, color: token.primary.base),
        SizedBox(height: token.sizeSM),
        Text('Loading…', style: TextStyle(color: token.colorTextSecondary)),
      ],
    ),
  );
}
```

Pull the color from a token rather than hard-coding it, so the spinner follows
the theme.

## Testing

The spinner rotates continuously and never completes. Any widget test that
renders one — directly, or through a loading button or toast — **cannot use
`pumpAndSettle`**, which waits for the tree to stop animating and will instead
time out. Pump explicit durations:

```dart
await tester.pump();
await tester.pump(const Duration(milliseconds: 400));
```

If a test hangs after adding a loading state, this is almost always why.
