# Tooltip

A small text bubble describing the widget it wraps. It appears on hover with a
pointer and on tap with touch, and never intercepts the tap meant for the
child.

```dart
Tooltip(
  message: const Text('Search'),
  child: Button(
    shape: ButtonShape.circle,
    icon: const Icon(Icons.search),
    onPressed: onSearch,
  ),
)
```

Use it for a brief hint — an icon button's name, the full text of a truncated
label. When the bubble needs buttons or richer content, reach for a
[Popconfirm](../feedback/popconfirm.md) or build one with `Popover`.

## Placement

Defaults to `PopoverPlacement.top`. All twelve placements are available and
the bubble flips and shifts to stay on screen, exactly as
[Popconfirm](../feedback/popconfirm.md#placement) does — the two share the same positioning
engine.

```dart
Tooltip(
  message: const Text('Delete'),
  placement: PopoverPlacement.right,
  child: deleteButton,
)
```

## Trigger

`trigger` chooses what reveals the tooltip:

| Value | Behaviour |
| --- | --- |
| `hover` (default) | Hover on a pointer; tap on a touchscreen. Works everywhere without stealing the trigger's own tap. |
| `tap` | Any tap or click toggles it, on every device. |
| `longPress` | Long-press, on every device. |

```dart
Tooltip(
  message: const Text('More options'),
  trigger: TooltipTrigger.tap,
  child: icon,
)
```

Use `tap` for a hint on a non-interactive element the user is expected to tap
for more; leave the default `hover` when wrapping a button, so a normal tap
still does the button's job.

## Arrow

A caret pointing at the trigger is drawn by default. It sits on whichever side
the bubble settled on after flipping, and aligns to the trigger's centre,
staying clear of the rounded corners. Turn it off with `arrow: false`.

```dart
Tooltip(message: const Text('No caret'), arrow: false, child: chip)
```

## On-screen positioning

The bubble never runs off the edge. If the preferred side lacks room it flips
to the opposite one; otherwise it shifts along the other axis and is clamped
into the viewport. The caret follows the resolved side and keeps pointing at
the trigger. This is the same engine [Popconfirm](../feedback/popconfirm.md#placement)
uses.

## Timing

| Property | Default | Effect |
| --- | --- | --- |
| `waitDuration` | 100ms | Hover delay before showing |
| `showDuration` | 1500ms | How long a tapped (touch) tooltip stays before hiding |

`showDuration` applies to touch only. A hovered tooltip stays as long as the
pointer is over the trigger and hides when it leaves; a touchscreen has no
pointer-exit event, so a tap-shown tooltip retracts on this timer instead.

```dart
Tooltip(
  message: const Text('Saved automatically'),
  waitDuration: const Duration(milliseconds: 400),
  child: statusDot,
)
```

## Behaviour

- **Hover** (pointer): shows after `waitDuration`, hides when the pointer
  leaves.
- **Tap** (touch): shows immediately and hides after `showDuration`; a second
  tap hides it early. The tap still reaches the child, so wrapping a button
  leaves the button fully functional — the hint appears *and* the button
  fires.
- **Click** (pointer): does nothing special; on a desktop the mouse is already
  hovering, so the hint is showing anyway.

The tap is detected with a `Listener` rather than a gesture recognizer, so it
never competes with — or steals from — a wrapped button's own tap. The bubble
itself ignores pointer events, so it cannot pull hover off the trigger and make
the pair flicker.

## Styling

The bubble uses the `colorBgSpotlight` token — a dark surface in light themes
and a light one in dark themes — so it reads as a distinct layer above the
page. It follows the active theme automatically.

## Configuration

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `message` | `Widget` | required | The hint — usually a `Text` |
| `child` | `Widget` | required | The widget the tooltip describes |
| `placement` | `PopoverPlacement` | `top` | Preferred side |
| `trigger` | `TooltipTrigger` | `hover` | What reveals the tooltip |
| `arrow` | `bool` | `true` | Draw a caret pointing at the trigger |
| `waitDuration` | `Duration` | 100ms | Hover delay before showing |
| `showDuration` | `Duration` | 1500ms | Touch/tap display time before hiding |

## Testing

Simulate hover with a synthetic mouse pointer, and drive frames explicitly —
`pumpAndSettle` cannot be used with the kit's animations:

```dart
final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
await gesture.addPointer(location: Offset.zero);
addTearDown(gesture.removePointer);
await gesture.moveTo(tester.getCenter(find.text('trigger')));

await tester.pump(const Duration(milliseconds: 150)); // past waitDuration
await tester.pump(const Duration(milliseconds: 250)); // enter animation
expect(find.text('Search'), findsOneWidget);
```

## Design tokens

`TooltipToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
Tooltip(
  // …
  token: const TooltipToken(),
);

// …or for every Tooltip in a subtree:
ConfigProvider(
  components: const [TooltipToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
