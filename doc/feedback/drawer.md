# Drawer

Panels that slide in from a screen edge over a dimming mask, for content too
large or too secondary for a [Modal](../feedback/modal.md) — filters, detail views,
navigation. Reached through the global `Drawer` getter — no `BuildContext`
required.

```dart
Drawer.open(const DrawerConfig(
  title: Text('Filters'),
  child: FiltersForm(),
));
```

`open` returns a `Future<void>` that completes once the drawer closes, so work
can be sequenced after it:

```dart
await Drawer.open(DrawerConfig(title: Text('Edit'), child: EditForm()));
refreshList();
```

## Name collision

Flutter's Material library also exports a `Drawer` (the widget inside a
`Scaffold`). If you import both, hide the Material one so this getter resolves:

```dart
import 'package:flutter/material.dart' hide Drawer;
import 'package:seed_ui/seed_ui.dart';
```

If you need both in the same file, prefix instead:

```dart
import 'package:seed_ui/seed_ui.dart' as soft;
// ...
soft.Drawer.open(const soft.DrawerConfig(child: Text('…')));
```

## Setup

Drawers render into the root navigator's overlay:

```dart
MaterialApp(
  navigatorKey: UiKit.navigatorKey,
  home: const HomePage(),
)
```

## Placement

Four edges, set by `placement`:

```dart
Drawer.open(const DrawerConfig(
  placement: DrawerPlacement.left,
  child: NavMenu(),
));
```

| Value    | Slides from          | `size` controls |
| -------- | -------------------- | --------------- |
| `right`  | Right edge (default) | Width           |
| `left`   | Left edge            | Width           |
| `top`    | Top edge             | Height          |
| `bottom` | Bottom edge          | Height          |

`size` is the extent along the sliding axis — width for left/right, height for
top/bottom — and defaults to 378. It is capped to the viewport, so an
oversized value simply fills the screen rather than overflowing.

```dart
Drawer.open(const DrawerConfig(
  placement: DrawerPlacement.bottom,
  size: 240,
  child: QuickActions(),
));
```

## Header

Supplying a `title` renders a header with the title and, when `closable` is
true, a close button, separated from the body by a divider. Without a title
there is no header — provide your own close affordance in `child`, or rely on
the mask and Escape.

## Dismissal

A drawer can be dismissed three ways, all firing `onClose` and completing the
future:

- the close button in the header (`closable`)
- tapping the mask (`maskClosable`)
- pressing Escape (`escapeClosable`)

```dart
Drawer.open(DrawerConfig(
  title: Text('Unsaved changes'),
  maskClosable: false, // force a deliberate close
  onClose: saveDraft,
  child: Editor(),
));
```

As with modals, do not disable every route out of a header-less drawer, or the
user has no way to close it. `Drawer.destroyAll()` closes any open drawer
programmatically.

## Focus and the keyboard

While a drawer is open it takes focus, so Tab cannot reach the page behind the
mask and Escape is handled by the drawer. Focus returns to the page on close.

## Content and scrolling

`child` fills the panel below the header, inside a default large-size padding
you can override with `padding`. The panel respects the safe area. For content
taller than the panel, wrap `child` in a scroll view:

```dart
Drawer.open(DrawerConfig(
  title: Text('Details'),
  padding: EdgeInsets.zero,
  child: ListView(children: [for (final row in rows) DetailRow(row)]),
));
```

## Configuration

| Field            | Type              | Default     | Description                                           |
| ---------------- | ----------------- | ----------- | ----------------------------------------------------- |
| `child`          | `Widget`          | required    | Panel content                                         |
| `title`          | `Widget?`         | `null`      | Header; omit for no header                            |
| `placement`      | `DrawerPlacement` | `right`     | Edge to slide from                                    |
| `size`           | `double`          | `378`       | Extent along the sliding axis, capped to the viewport |
| `onClose`        | `VoidCallback?`   | `null`      | Runs on any dismissal                                 |
| `closable`       | `bool`            | `true`      | Shows the header close button                         |
| `maskClosable`   | `bool`            | `true`      | Mask taps dismiss                                     |
| `escapeClosable` | `bool`            | `true`      | Escape dismisses                                      |
| `barrierColor`   | `Color?`          | `null`      | Background color of the dismiss barrier               |
| `padding`        | `EdgeInsets?`     | large inset | Padding around `child`                                |

## Testing

`open` returns a future that only completes when the drawer closes, so a
regression in a dismissal path turns `await` into a hang. Give drawer tests a
deadline, and drive frames explicitly rather than with `pumpAndSettle`:

```dart
@Timeout(Duration(seconds: 10))
library;

// ...
Drawer.open(const DrawerConfig(title: Text('Panel'), child: Text('body')));
await tester.pump();
await tester.pump(const Duration(milliseconds: 400));
expect(find.text('Panel'), findsOneWidget);

Drawer.destroyAll();
await tester.pump();
await tester.pump(const Duration(milliseconds: 400));
await tester.pump();
```

Remember to `hide Drawer` from Material in the test too.

## Design tokens

`DrawerToken` overrides this component's own tokens. It rides on `DrawerConfig`, since a
drawer is opened through the API rather than built as a widget:

```dart
drawer.open(DrawerConfig(
  // …
  token: const DrawerToken(),
));

// …or for every drawer in a subtree:
ConfigProvider(
  components: const [DrawerToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
