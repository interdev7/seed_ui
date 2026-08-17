# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.6.3

### Added

- `Badge`. A count, dot or status pinned to a corner, with overflow, a hidden
  zero, custom content and a `title` for assistive technology, since the digits
  as drawn are rarely what the count means.
- `Ribbon`, a label banded across a container's corner. Its own widget rather
  than a `Badge` constructor: the two share an idea but not a single property.
  Note it clashes with Material's `Badge`; hide one at the import.

## 0.6.2

### Fixed

- Tapping a tab in a scrolling bar left it a few pixels past the leading edge.
  The label's weight animates on selection, so the tab that lost the bold
  narrowed while the bar was still travelling towards a position read before
  it did. The bar now re-aims once the type has settled.
- A snapping bar could not rest at the end of its run. Only tab boundaries
  counted as resting places and none of them is the maximum, so reaching the
  end hauled the bar back to the last boundary before it: the final tabs sat
  stranded past the trailing edge, tapping one near the end jerked the bar
  left, and every attempt to scroll to them sprang back. Both ends of the run
  now count too. Visible on bouncing (iOS) physics, where the pull back is not
  masked by the hard stop clamping physics make at the maximum.
- Snap boundaries were measured once per build and never again, so a bar that
  reflowed without rebuilding — a webfont arriving late — snapped to where the
  tabs used to be.

## 0.6.1

### Added

- `Tabs.snap`. A flung bar settles with a tab against its leading edge rather
  than wherever the throw ended, so a long run cannot stop mid-label. Off by
  default: a bar of a few tabs has nothing to settle into.

  Snapping is to the measured tab boundaries, not to a fixed stride — tabs are
  as wide as their labels, so a page-sized step would land in the middle of
  one.
- `Upload.progress`, a whole `Progress` used as a template for the in-flight
  bar. Only its percent is replaced, so its colour, thickness and shape carry
  through — the same shape `Steps` already uses for its ring.
- `SegmentedToken.itemHoverBg`, which had been hardcoded.

### Fixed

- `Segmented` drew its track with a translucent fill. In a dark theme that
  lightens the track above the page, leaving the elevated thumb *darker* than
  the groove it sits in: the elevation read inverted, and only the shadow
  separated the two. The track takes the layout background now, widening the
  dark-theme gap from 17 steps to 31. The shadow stays — it was not the
  problem.

## 0.6.0

### Changed

- **Breaking.** `Upload` gains the layouts its counterparts elsewhere offer:
  `UploadVariant` is now `text`, `picture`, `cards` and `circleCards`, in
  place of `list` and `cards`. `picture` is the new default and matches what
  `list` drew; `text` drops the preview, `circleCards` rounds the tiles.
- **Breaking.** `Upload.onTap` is now `Upload.onPreview` — it drives the
  preview button as well as a tap on the row.

### Fixed

- `Segmented` drew its track with a translucent fill, which in a dark theme
  lightens it above the page — leaving the elevated thumb *darker* than the
  groove it sits in, so the elevation read inverted and only the shadow
  separated the two. The track takes the layout background now: the thumb is
  the lighter surface in both themes, and in dark the gap widens from 17 steps
  to 31. `SegmentedToken.itemHoverBg` is exposed alongside it.
- `Upload` drew its dashed outline around the prompt inside the drop zone
  rather than around the zone: a card was ringed about its plus instead of its
  edge, and a long hint ran flush to the dashes with nowhere to wrap. The dash
  is a foreground painter now, so it takes the zone's own box.
- The paperclip's lower loop curved the wrong way, folding the bottom half of
  the glyph back into the strokes above it — half a clip reached the screen.
- A card's trigger showed a bare plus. It carries a word under it now, which
  a glyph on its own does not manage — it reads as decoration rather than as
  something to press.

### Added

- `UploadItem.id`, and `UploadItem.key` which falls back to the name.
  Callbacks hand back the item they belong to, and a list is usually rebuilt
  between a tap and the handler running, so matching on object identity broke
  the moment `copyWith` made a new object.
- `Upload.onDownload`, with a button beside retry and remove.
- A paperclip on `text` rows, and a spinner in place of the preview while a
  file is in flight — unless it brought one of its own.
- The glyphs `Upload` draws now live with the rest of the kit's icons, and the
  plus that `Tabs` had copied is shared rather than duplicated.
- The gallery declared its image assets at the top level of its pubspec
  instead of under `flutter:`, where nothing reads them — the logo never
  reached the bundle.
- `Upload.itemBuilder` and `UploadActions`, for replacing a row or tile while
  keeping the handlers the built-in one would have wired up.

  Transport stays out: `action`, `headers` and the rest would mean HTTP inside
  the package, which costs either the web platform or the last of the zero
  dependencies. Sending bytes remains the app's, as picking them is.

## 0.5.0

### Added

- `MessagePlacement`, so a toast can be anchored to the bottom of the screen
  as well as the top. Per call — `message.success('Saved', placement:
  MessagePlacement.bottom)` — or as a default through `message.config`.

  Each edge keeps its own stack, matching how `notification` treats its
  corners, so a toast at the top never reorders one at the bottom and
  `maxCount` applies per edge.

### Fixed

- `message.config` and `notification.config` crashed when called from a
  `dispose` while a card was still on screen: they asked a mounted listener to
  rebuild during unmount, when the framework has the tree locked. Restoring a
  global default on the way out of a page is exactly the shape that hit it.

  The stacks now defer that request to the end of the frame when one is in
  flight, and only then — the common path stays synchronous, so a toast still
  appears on the very next frame.

### Changed

- **Breaking.** `message.config(top: ...)` is now `message.config(offset:
  ...)`. With two edges to anchor to, "top" named the wrong thing; `offset` is
  the distance from whichever edge is in use, and is the word `notification`
  already used.

## 0.4.0

### Removed

- **Breaking.** `ProgressBorderRadius.fixed`, an alias for
  `ProgressBorderRadius.all`. The last duplicate in the public API.

### Added

- A logo, and a statement in `CONTRIBUTING.md` of what the version number will
  promise from `1.0.0`: the exported names and their signatures, not the token
  values or the pixels they produce.

## 0.3.0

### Fixed

- `Segmented` overflowed instead of scrolling when its options were wider than
  the box it was given — on a phone, a run of five labels painted the debug
  stripes and put the last segments past the edge, out of reach. A horizontal
  run now scrolls. With room to spare there is nothing to scroll and the
  control is still exactly its options wide, and `block: true` is unaffected.

### Changed

- **Breaking.** `Progress.size` is typed `ControlSize?` instead of `dynamic`.
  It was the only public field in the kit with no type, so `Progress(size:
  'large')` compiled and failed at run time. Numbers and `Size` become the
  types the kit already had:

  | Before | Now |
  | --- | --- |
  | `size: 20` | `size: ControlSize.fixed(20)` |
  | `size: Size(200, 10)` | `size: ControlSize.raw(200, 10)` |
  | `size: SoftSize.small` | unchanged |

- **Breaking.** `ProgressSteps` had three ways to say one thing — a `fill`
  parameter, a `stepFill` parameter and a `stepFill` getter. Only `fill`
  remains.

### Removed

- **Breaking.** `ControlSize.from(dynamic)`, whose own doc comment called it
  legacy. With `Progress.size` typed there is nothing left to convert.
- **Breaking.** `ProgressBorderRadius.from(dynamic)` — unused anywhere, and
  untyped.
- **Breaking.** `Progress.onprogressChange`, an alias for `onProgressChange`
  whose lower-case `p` read as a typo.
- **Breaking.** The deprecated `MessageType` typedef. Before 1.0 is when a
  deprecation gets deleted rather than carried on.

None of the four were used by the kit, the gallery, the tests or the docs.

### Added

- Screenshots on the package page. Each pairs the light and dark themes side
  by side, so one slot carries the theming story and the shape is one a
  gallery can render — a lone phone screenshot is a sliver.

- **`Upload`** — a file list with a picker trigger, per-file progress, and
  retry and remove actions. Two layouts: rows, or a grid of tiles for images.

  It picks nothing and sends nothing. Opening a file dialog needs platform
  code and there is no such API in the Flutter SDK, so taking it on would mean
  either a plugin dependency every consumer inherits, or native code for six
  platforms to maintain. Instead `Upload` draws the state and calls back:
  `onPick` opens whatever picker the app already uses, and the app owns the
  list, rebuilding items with new `progress` and `status` as its upload runs.

  The dashed drop target is drawn here, but the operating system's drag events
  are not Flutter's to give either — pass them in through `dragging`.

  The gallery demonstrates it against a real `file_picker`, which is a
  dependency of the example and not of the package. `seed_ui` still has none
  beyond the Flutter SDK, and its own platform support is unchanged — the
  gallery's iOS deployment target moved to 14.0 to satisfy that plugin, which
  binds the example alone.

## 0.2.0

### Changed

- **Breaking.** Text-carrying properties on the *declarative* components now
  take a `Widget` instead of a `String`, matching Flutter's own convention
  (`AlertDialog.title`, `ListTile.title`) and the kit's existing
  `Alert.message` and `TabItem.label`. Each is rendered inside a
  `DefaultTextStyle` carrying its own colour, size and weight, so a bare
  `Text('Saved')` still needs no styling — and a `Row`, a `RichText` or an
  icon now fits where only a string did.

  | | |
  | --- | --- |
  | `MessageConfig.content` | `Widget` |
  | `NotificationConfig.message` / `.description` | `Widget` |
  | `ModalConfig.title` / `.content` / `.okText` / `.cancelText` | `Widget` |
  | `Popconfirm.title` / `.description` / `.okText` / `.cancelText` | `Widget` |
  | `DrawerConfig.title` | `Widget` |
  | `Result.title` / `.subTitle` | `Widget` |
  | `Tooltip.message` | `Widget` |
  | `Progress.format` | `Widget Function(double)` |

  The *imperative* shorthands keep taking plain text, because they are
  one-liners inside callbacks and a `Text(...)` there costs more than it
  gives:

  ```dart
  message.success('Saved');
  notification.error('Upload failed', description: 'The server said no.');
  Modal.confirm(title: 'Delete file?', content: 'This cannot be undone.');
  ```

  One rule covers it: **a shorthand takes a `String`, a config takes a
  `Widget`.** Anything richer goes through the config the shorthand already
  wraps — `message.open(MessageConfig(content: Row(...)))`.

  `SegmentedOption.label` stays a `String` for the same reason: it already
  has a `child` beside it for the widget case.

- **Breaking.** `CreateTabData.title` is now `CreateTabData.label`, typed
  `Widget?`. It seeds `TabItem.label`, so it now shares that name and type.
  `TabsController.setTitle` is unchanged and still takes a `String`.

### Removed

- **Breaking.** `ModalConfig.child` and the `child` parameter of every `Modal`
  opener. With `content` typed `Widget` the two were the same thing; `content`
  is the survivor, and it scrolls once it outgrows the dialog.

### Fixed

- A dark theme left the system status bar unreadable: nothing ever stated a
  `SystemUiOverlayStyle`, so the platform's dark icons stayed on a dark bar.
  `ConfigProvider` now declares one matching its theme, through an
  `AnnotatedRegion` rather than `SystemChrome` — the style belongs to its
  subtree instead of mutating global state. Only the icon brightness is set,
  leaving a translucent or coloured bar alone, and
  `ConfigProvider(systemOverlayStyle: false)` hands control back to an app
  that drives its own chrome.

- The gallery declared a hosted `seed_ui` dependency, so it — and with it the
  `example` CI job and the published demo — was building against the release
  on pub.dev rather than the working tree. A `dependency_overrides` entry
  points it back at the repository, which immediately surfaced 80 call sites
  the previous setup had hidden.

## 0.1.0

### Removed

**Breaking.** Four names left the public API. All four were implementation
details that no documented API returned or accepted, and nothing in the
example or the docs used them:

- `ControlSizeResolver` — the internal `ControlSize.resolve1D` helper.
- `SpinButton` — chrome internal to `InputNumber`.
- `detectBorderRadiusFromContext`, `detectBorderRadiusFromWidget`.

Everything else the kit exported stays: types such as `PopoverPlacement` and
`RailInsets` appear in public signatures (`Tooltip.placement`,
`TimelineToken.railInset`), so callers need to be able to name them.

### Changed

- **Breaking.** `Timeline.items` now takes `List<TimelineEntry>`.
  `TimelineEntry` is sealed over exactly two cases, `TimelineItem` and
  `TimelineGroupItem`. Lists of plain items keep working unchanged.

  `TimelineGroupItem` used to extend `TimelineItem`, which gave it fourteen
  inherited fields it never read — a caller reaching for `color` or `dot` on a
  group got silence — and let a group nest inside another group, which
  compiled but drew an empty node. Neither is expressible now.

### Fixed

- `Tour` eased its panel into place but dropped the mask on at full strength,
  so opening a tour read as a flash. The dim now fades in over the theme's mid
  duration, matching the popover barrier.

### Added

- A snapshot test over the exported API (`test/public_api_test.dart`). Any
  change to `lib/seed_ui.dart`'s surface now shows up as a reviewable diff,
  and a bare `export` without a `show` clause fails the suite.
- `CONTRIBUTING.md`, issue forms and a pull-request template.
- Tests for `TimelineGroupController`, collapsible timeline groups, and the
  horizontal and reversed timeline layouts.

## 0.0.1

First public release.

### Added

- **Token-driven theming.** `SeedToken` seeds every colour, size and motion
  value; `ConfigProvider` supplies the resolved `ThemeData` to the tree, with
  per-component overrides through `ComponentsConfig` and algorithmic palette
  generation via `generate`.
- **Context-free feedback APIs.** `message`, `notification`, `Modal` and
  `Drawer` render into the root overlay through `UiKit.navigatorKey`, so they
  can be called without a `BuildContext`.
- **General:** `Button` — variant × colour, five shapes, sizes, loading and
  danger states.
- **Feedback:** `Alert`, `Spinner`, `Spin`, `message`, `notification`, `Modal`,
  `Drawer`, `Popconfirm`, `Progress`, `Result`.
- **Data entry:** `Input`, `InputNumber`, `Switch`, `Checkbox`, `Radio`,
  `Select`.
- **Data display:** `Avatar`, `Card`, `Collapse`, `Empty`, `Listy`, `Popover`,
  `Segmented`, `SortableList`, `Steps`, `Tabs`, `Tag`, `Timeline`, `Tooltip`,
  `Tour`, `Tree`.
- **Navigation:** `Dropdown`, `Pagination`.
- Component gallery covering every widget in `example/`.
- Per-component documentation in `doc/`.

### Notes

- Components build on `package:flutter/widgets.dart` and carry no Material
  dependency, so they drop into Material and Cupertino apps alike.
- The public API is not yet stable; breaking changes may land in any `0.x`
  release.
