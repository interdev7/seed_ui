# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
