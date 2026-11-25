# Roadmap

Planned work that has a reason to wait. Each item says what triggers it.

## Done

- **0.30.0 — moved off `package:flutter/material.dart`** to `material_ui` and
  `cupertino_ui`; Flutter 3.47+ required, CI on the latest stable again.

## Smaller items

- **`DateRangePicker` on a phone.** It shows two months side by side, which is
  wider than a phone. `DatePanelStyle.fittedTo` (0.29.1) narrows the days of a
  single month; the range picker needs one month at a time, or months stacked,
  on narrow screens.
