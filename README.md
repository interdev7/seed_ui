<p align="center">
  <img src="https://raw.githubusercontent.com/interdev7/seed_ui/main/assets/logo.png" width="112" alt="seed_ui">
</p>

<h1 align="center">seed_ui</h1>

[![pub package](https://img.shields.io/pub/v/seed_ui.svg)](https://pub.dev/packages/seed_ui)
[![CI](https://github.com/interdev7/seed_ui/actions/workflows/ci.yaml/badge.svg)](https://github.com/interdev7/seed_ui/actions/workflows/ci.yaml)
[![codecov](https://codecov.io/gh/interdev7/seed_ui/branch/main/graph/badge.svg)](https://codecov.io/gh/interdev7/seed_ui)
[![pub points](https://img.shields.io/pub/points/seed_ui)](https://pub.dev/packages/seed_ui/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A themeable widget library for Flutter, built around design tokens and
context-free feedback APIs. Inspired by [Ant Design](https://ant.design) — see
[Acknowledgements](#acknowledgements).

### ▶ [Try every component in your browser](https://interdev7.github.io/seed_ui/)

The gallery below runs the real widgets — switch the theme, resize the window,
open a drawer.

- **Token-driven theming.** Every color, size and motion value is derived from
  a small set of seeds. Change `colorPrimary` and the whole kit follows — see
  [theming](doc/theming.md), including light/dark switching.
- **Feedback you can call from anywhere.** `message.success('Saved')`
  and `notification.error(...)` need no `BuildContext`.
- **No Material dependency in the widgets.** Components build on
  `package:flutter/widgets.dart`, so they drop into Material and Cupertino
  apps alike.

## Installation

```yaml
dependencies:
  seed_ui: ^0.6.6
```

## Getting started

Two pieces of wiring, both optional-but-recommended:

```dart
import 'package:flutter/material.dart';
import 'package:seed_ui/seed_ui.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ConfigProvider(
      theme: ThemeData(
        token: const SeedToken(colorPrimary: Color(0xFF1677FF)),
      ),
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: const HomePage(),
      ),
    );
  }
}
```

Twelve languages ship with the kit, and it follows your app's locale through
an ordinary `LocalizationsDelegate` — so `intl`, `easy_localization` and the
rest work with it while `seed_ui` depends on none of them. See
[Localization](doc/localization.md).

`ConfigProvider` supplies the theme. Widgets fall back to the default
theme without it, so it is optional.

`UiKit.navigatorKey` is **required** if you call `message` or
`notification`: those APIs render into the root navigator's overlay, and the
key is how they find it. Without it they assert in debug mode.

## Components

| Component                                         | Description                                                                    |
| ------------------------------------------------- | ------------------------------------------------------------------------------ |
| [Alert](doc/feedback/alert.md)                    | Inline status banner                                                           |
| [Avatar](doc/data_display/avatar.md)              | Represents users or objects; image, icon, text, grouping                       |
| [Badge](doc/data_display/badge.md)                | Corner count, dot or status — and `Ribbon` across a container's corner         |
| [Countdown](doc/data_display/countdown.md)        | Time to a moment or since one, counting either way                             |
| [Button](doc/general/button.md)                   | Pressable button with variant, color, size, shape, loading and danger states   |
| [Spinner](doc/feedback/spinner.md)                | Indeterminate circular progress indicator                                      |
| [Spin](doc/feedback/spin.md)                      | Loading state for a region, with tip, delay, percent and fullscreen mask       |
| [message](doc/feedback/message.md)                | Brief centred status toasts                                                    |
| [notification](doc/feedback/notification.md)      | Corner-anchored cards with a headline, detail and actions                      |
| [Modal](doc/feedback/modal.md)                    | Blocking dialogs that return the user's decision                               |
| [Drawer](doc/feedback/drawer.md)                  | Panels that slide in from a screen edge                                        |
| [Popconfirm](doc/feedback/popconfirm.md)          | Confirmation bubble anchored to a trigger                                      |
| [Tooltip](doc/data_display/tooltip.md)            | Text hint on hover or tap                                                      |
| [Progress](doc/feedback/progress.md)              | Bar or ring progress indicator                                                 |
| [Result](doc/feedback/result.md)                  | Full-page operation outcome                                                    |
| [Input](doc/data_entry/input.md)                  | Single- or multi-line text field                                               |
| [InputNumber](doc/data_entry/input_number.md)     | Numeric input with steppers, range, precision                                  |
| [Segmented](doc/data_display/segmented.md)        | Segmented single-select control                                                |
| [Tabs](doc/data_display/tabs.md)                  | Tabbed panels — line, card, editable-card                                      |
| [Card](doc/data_display/card.md)                  | Content container — header, cover, actions, tabs, meta                         |
| [Collapse](doc/data_display/collapse.md)          | Collapsible panels — accordion, ghost, custom icons                            |
| [Tree](doc/data_display/tree.md)                  | Hierarchical list — expand, select, cascading checkboxes, lines, drag-and-drop |
| [SortableList](doc/data_display/sortable_list.md) | Drag-to-reorder list — vertical or horizontal, smooth make-room animation      |
| [Listy](doc/data_display/listy.md)                | Long list with grouped sections, sticky headers and imperative scroll control  |
| [Steps](doc/data_display/steps.md)                | Progress through a task's stages — statuses, wizard controller, five types     |
| [Timeline](doc/data_display/timeline.md)          | Vertical event axis — modes, colours, custom dots, pending                     |
| [Tour](doc/data_display/tour.md)                  | Guided walk through a screen — spotlight mask, anchored panels, steps          |
| [Popover](doc/data_display/popover.md)            | Floating card with a title and a body — hover, tap or long-press               |
| [Switch](doc/data_entry/switch.md)                | On/off toggle                                                                  |
| [Checkbox](doc/data_entry/checkbox.md)            | Checkbox, single or grouped                                                    |
| [Radio](doc/data_entry/radio.md)                  | Radio button group                                                             |
| [Select](doc/data_entry/select.md)                | Dropdown select — single, multiple or tags                                     |
| [Dropdown](doc/navigation/dropdown.md)            | Menu floating from a trigger; submenus, groups                                 |
| [Empty](doc/data_display/empty.md)                | Empty-state placeholder; global renderEmpty                                    |
| [Pagination](doc/navigation/pagination.md)        | Pager: numbers, size-changer, jumper, simple                                   |
| [Tag](doc/data_display/tag.md)                    | Label / chip; presets, custom colours, closable, checkable                     |
| [Upload](doc/data_entry/upload.md)                | File list with a picker trigger, per-file progress, retry and remove           |

See also [theming](doc/theming.md) for the token system.

> **Name clash.** The kit's `Drawer` getter shares a name with Material's
> `Drawer` widget. When importing both, hide the Material one:
> `import 'package:flutter/material.dart' hide Drawer;`. See
> [the Drawer docs](doc/feedback/drawer.md#name-collision).

## At a glance

```dart
Button(
  variant: ButtonVariant.solid,
  color: ButtonColor.primary,
  onPressed: save,
  child: const Text('Save'),
)

message.success('Saved');

final close = message.loading('Uploading…');
await upload();
close();

notification.error('Upload failed',
  description: 'The server rejected the file.',
  actions: [
    Button(
      size: SoftSize.small,
      onPressed: retry,
      child: const Text('Retry'),
    ),
  ],
);
```

## Example app

A gallery covering every component lives in `example/`:

```sh
cd example
flutter run
```

## Testing against the kit

`Spinner` animates continuously, which means any test rendering a loading
button, a `message.loading()` toast or a spinner **cannot use
`pumpAndSettle`** — the tree never becomes quiescent and the call times out.
Drive frames explicitly instead:

```dart
await tester.pump();                                  // start the animation
await tester.pump(const Duration(milliseconds: 400)); // run it to completion
await tester.pump();                                  // let the stack rebuild
```

The trailing pump matters: overlay entries are removed from an animation
completion callback, and the container rebuilds on the following frame.

## Acknowledgements

The component set, the token vocabulary and much of the interaction detail are
inspired by [Ant Design](https://ant.design) — an excellent design system, and
the reference this kit measured itself against while it was written. seed_ui is
an independent Flutter project: not affiliated with, endorsed by, or a port of
Ant Design.

## Contributing

Issues and pull requests are welcome at
[github.com/interdev7/seed_ui](https://github.com/interdev7/seed_ui).

Before opening a PR, please make sure the tree is clean:

```sh
dart format .
flutter analyze
flutter test
```

## License

[MIT](LICENSE) © Anton Samoylov

## Status

Under active development. The public API is not stable yet: while the package
is on `0.x`, a breaking change bumps the minor version, and every one is
spelled out in the [changelog](CHANGELOG.md). `1.0.0` follows once the surface
has gone a few releases without needing one.

From `1.0.0` the guarantee covers the exported names and their signatures, not
the values behind the tokens or the pixels they produce — see
[what the version number promises](CONTRIBUTING.md#what-the-version-number-promises).
