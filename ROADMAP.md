# Roadmap

Planned work that has a reason to wait. Each item says what triggers it.

## 0.30.0 — move off `package:flutter/material.dart`

**Why.** Since Flutter 3.47, importing `package:flutter/material.dart` (and
`GlobalMaterialLocalizations` / `GlobalCupertinoLocalizations`) is deprecated
in favour of the separate `material_ui` package. On the latest stable the
analyzer reports it everywhere we import Material — 7 files in `lib/`, about
120 in `test/`, `tool/` and `example/`.

**Why not yet.** `material_ui` exists only from Flutter 3.47, and the package
supports Flutter `>=3.22.0`. Switching now would stop the package installing
for everyone on 3.22–3.46. `material.dart` is deprecated, not removed.

**Meanwhile (done in 0.29.1).** CI's strict checks (`flutter analyze
--fatal-infos` in `ci.yaml` and `release.yaml`) are pinned to Flutter 3.44.4.
The advisory job *Analyze on latest stable* runs the newest Flutter with
`continue-on-error` and shows the deprecations without blocking.

**When to do it.** Once Flutter 3.47+ is old enough to require — or earlier,
the moment `material.dart` is announced for removal.

**What it takes.**

1. Raise `environment.flutter` to `>=3.47.0` in `pubspec.yaml` (and in
   `example/pubspec.yaml`).
2. In `lib/`, replace `package:flutter/material.dart` with
   `package:material_ui/material_ui.dart` and add `material_ui` to
   `dependencies`. Files today: `utils/border_radius_detector.dart`,
   `components/navigation/pagination.dart`, `components/data_entry/input.dart`,
   `components/data_entry/input_otp.dart`, `components/data_display/tree.dart`,
   `components/data_display/tooltip.dart`, `theme/material_theme.dart`.
3. The same in `test/`, `tool/` and `example/` (dev dependency for tests).
4. Replace `GlobalMaterialLocalizations` / `GlobalCupertinoLocalizations` with
   what the deprecation message names; update `doc/localization.md`, whose
   setup snippet shows them.
5. Unpin CI: in `ci.yaml` and `release.yaml` set the strict jobs back to the
   latest stable (drop `flutter-version: 3.44.4`) and remove the advisory job.
6. Release as **0.30.0** — a breaking change for apps on Flutter below 3.47.
   Say so at the top of the CHANGELOG entry, with the minimum Flutter version.

## Smaller items

- **`DateRangePicker` on a phone.** It shows two months side by side, which is
  wider than a phone. `DatePanelStyle.fittedTo` (0.29.1) narrows the days of a
  single month; the range picker needs one month at a time, or months stacked,
  on narrow screens.
