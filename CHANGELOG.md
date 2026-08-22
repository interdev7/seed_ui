# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.6.10

### Fixed

- A component token set on one `ConfigProvider` was lost under any provider
  nested inside it — a theme switcher, a screen that recolours a corner — even
  when the inner one said nothing about that component. The search stopped at
  the nearest provider and fell back to the defaults, which is why a token set
  once at the top of an app still had to be repeated on every widget. It now
  carries on outwards until it finds one, and depends on each provider it
  consults so a change to the outer one still reaches through.

### Added

- `Slider` and `RangeSlider`. A groove with one handle or two, with `min`,
  `max`, `step`, `marks`, `dots`, `included`, `vertical` and `reverse`, and
  both `onChanged` and `onChangeComplete`. A null `step` lets the handle rest
  only on the marks and the ends of the scale.

  Two widgets rather than one behind a flag: what they carry differs in type,
  and a single one would take a value that is sometimes a number and sometimes
  a pair.

  Reading right to left turns the scale round on its own, and `reverse` flips
  it back rather than naming a side — the rule Ant Design applies, and the
  only one under which `reverse` means the same thing in both languages. The
  arrow keys move a handle one step, and the key that points along the groove
  is the one that advances the value, so a mirrored scale answers the same key
  the other way.

  A handle being moved carries its value above it, styled as the kit's tooltip
  is; `tooltip` decides what that says and may say nothing. It is drawn inside
  the slider rather than in an overlay, since it has to follow a handle that
  moves every frame — an ancestor that clips will clip it too.

  Ant Design's editable range nodes are not here.

## 0.6.9

### Fixed

- `Timeline` set its content adrift from the axis in a right-to-left layout.
  The columns are laid out in a row, which reverses itself when the language
  does, but their padding and alignment named sides outright — so the gap went
  to the far edge instead of against the line, leaving one column touching it
  and the other pushed away twice over. A collapsed item also revealed itself
  from the left rather than from where its text begins.
- A `Switch` kept its thumb on the right when on and the left when off, so a
  mirrored one travelled backwards. The thumb rests at the start and moves to
  the end, as Material's own does, and the label inside the track keeps clear
  of wherever it is resting.
- `AvatarGroup` clipped each face leftwards, which lapped the wrong one over
  the other in a mirrored run; `Listy` group headings and `Card`'s skeleton
  bars read from the left rather than from where the line begins; and
  `SortableList` spaced its items by the right of each rather than after it.
- A `Tree` was built by side throughout, so a mirrored one turned its rows
  over while leaving everything inside them behind: the depth guides and the
  expand switcher stayed at the left, the title read from the left of its own
  row, the drag grip's gap fell on the wrong side of it, and the drop
  indicator was inset from the left rather than from where the node would
  land.
- A `Steps` rail broke in the middle of a right-to-left run. The line between
  two markers is drawn as two halves, each keeping its gap on the side facing
  a marker, but the painter insets by side while the row hands the halves over
  in reading order. Where those disagreed the gap turned inward: the ends ran
  flush into the markers and a five-pixel void opened where the halves should
  meet.
- A `Steps` rail could be swallowed by its own inset. The rail takes whatever
  the steps leave it, so beside a short step — a vertical run on a phone, say
  — a `railInset` of any size ate the whole slot and the line came out
  negative, drawn as nothing. Every inset past a small one then looked alike,
  because there was no line left to look at. The slot now keeps room for its
  gaps and the least line that still reads as one, and the step grows to fit.
- A `Steps` panel run pointed the same way whichever way it read: the strip is
  painted, and the painter knew its axis but not the direction, so the arrows
  faced right in a mirrored layout while the content beside them ran the other
  way. The canvas is reflected for a right-to-left run, which turns the shapes
  and their order together.
- `ProgressBorderRadius` could only name a side, which left
  `ProgressSteps.stepRadius` with no way to say what it means: it is handed
  `isFirst`, a place in the run, and the first step is on the right when the
  bar reads that way. Added `ProgressBorderRadius.directional` and
  `.horizontalDirectional`, whose corners follow the reading order.
  `toBorderRadius` takes the direction to resolve against; the existing
  constructors are unchanged and still mean the side they name.
- A `Tour` panel was built by side throughout: its close button sat in the
  right corner rather than the trailing one, the room reserved for it in the
  title cleared the wrong edge, the gap between the step dots and the buttons
  fell on the wrong side of them, and the panel grew — and held its outgoing
  copy — from the top left rather than from where it starts.
- A `Timeline` item's title, description and content always read towards the
  start of their block, so in the column standing before the axis the lines
  drifted away from the line they belong to instead of meeting it. Text faces
  the axis now — end for the near column, start for the far one, swapping with
  the item's placement, as Ant Design does. Labels follow the same rule.

  Two settings are needed, not one: the box alignment places a block narrower
  than its column, but a block as wide as the column — any text long enough to
  wrap — is placed by its paragraph alignment alone. Setting only the first
  left a short title against the axis with the description below it against
  the far edge.
- A horizontal `Timeline` painted its thread rightwards from every dot, so in
  a right-to-left run — which a row reverses on its own — the first item sent
  its thread off the outer edge and the items stopped joining up. Which way
  the thread runs is now read off the direction, along with the rail insets
  and which end is dashed.
- `Tabs` scrolled to the mirror image of where it meant to in a right-to-left
  layout. Both the snap boundaries and the jump to the active tab took a tab's
  offset inside the strip as its distance along the scroll, but a horizontal
  bar that reads right to left starts at the far end: an offset of zero shows
  the content's right edge, and distances are measured from there.
- `Select` laid itself out physically: the wider inset belonged to the label
  and the narrower to the arrow, and a mirrored layout swapped the two. Its
  value, its placeholder and each option in the list were pinned to the left
  rather than to the edge the language starts at. Tags took their padding the
  same way round.
- An `Input`'s placeholder stayed on the left of a mirrored field while the
  typed text moved: it is drawn separately, and `TextAlign.start` was mapped
  onto a physical left. `start`, `end` and `justify` follow the reading
  direction now; `left` and `right` name a side outright and still do not
  mirror.
- `Input` rounded the corners the addon is joined to by side rather than by
  reading order, so an attached button met a rounded end and the free end came
  out square. Its prefix and suffix insets followed suit.
- `InputNumber` drew the rule between the field and its handles on their left
  rather than between the two.

## 0.6.8

### Fixed

- A `Dropdown` submenu could only be reached by hovering, so on a touch screen
  a parent row such as `More` did nothing at all: hover has no counterpart
  there, and the row took no other action. A tap opens it now, and closes it
  again.
- A `Dropdown` submenu opened to the right in a right-to-left layout, back
  over the menu it belongs to rather than away from it.

## 0.6.7

### Fixed

- A `Segmented` in `block` mode wrapped a label that would not fit, growing
  the whole strip a second line to suit its longest word. A segment is one
  line: what spills is cut with an ellipsis, as it is in Ant Design, where the
  label carries `text-overflow: ellipsis` and the item `min-width: 0`.
- A `Pagination` whose run of pages was too wide for its room overflowed
  rather than fitting. The run is atomic by design, so it cannot be given less
  space than it needs; it scrolls now, as a long row of segments does. Widest
  where the figures are — Arabic-Indic ones, or a longer word for `/ page` —
  but a narrow screen was enough on its own.
- A run of `RadioGroup` buttons rounded the wrong corners in a right-to-left
  layout. The ends were square and the two rounded edges met in the middle,
  because the first button took the left corners while the row put it on the
  right. The rounding is directional now.
- A `Badge` count sat off-centre and high in a language that writes its own
  figures. The reel measured `0`–`9` while drawing `٠`–`٩`, whose widths are
  their own, and the line box was forced to exactly the font size — square
  around Latin digits, which have neither ascender nor descender, and too
  tight for these, which pushed them up out of centre. The glyphs actually
  drawn are measured now, and the font is left to say how tall a line is.
- A `Badge` hung off the right of what it marks rather than the trailing
  corner, so it stayed on the wrong side in a right-to-left layout — and its
  overhang was pushed rightwards whichever way the layout read, which left it
  short of the corner and lying over the child rather than off it.
- A `Badge` count that grew a digit changed the pill's padding in a single
  frame while the figures were still easing. The padding eases with them now.
- `Ribbon` came apart in a right-to-left layout. Its corners, its offset and
  its fold were placed physically while the column's own alignment was
  directional, so the two disagreed and the fold left the band it belongs to.
  Each is now given the kind of value it expects.

### Added

- Localized figures. `SeedLocalizations.digits` gives the ten glyphs a language
  writes its numbers with, and Arabic ships the Arabic-Indic ones — CLDR's
  default for the language — so a badge counts `٤٢` and a countdown reads
  `٠١:٠٢`. Only the figures the kit writes itself are rewritten; numbers inside
  your own text stay yours. Glyph substitution, not number formatting: grouping
  and decimal marks need locale data the kit does not carry.

  The Maghreb writes Arabic with Latin figures, and matching on language alone
  cannot tell, so `copyWith(digits: SeedLocalizations.latinDigits)` says so.
- `SeedLocalizations.perPage`, the `/ page` that follows a size in
  `Pagination`'s size picker. Missed when the rest of the words were gathered.

## 0.6.6

### Added

- Localization. Twelve languages — en, ru, tk, de, fr, es, zh, ja, tr, pt, ar,
  he — through `SeedLocalizations` and an ordinary `LocalizationsDelegate`, so
  the kit follows the app's locale and changes with it at runtime. That is what
  makes it work with `intl`, `easy_localization`, `slang` and the rest while
  depending on none of them: they all set the app's `Locale`, which is all the
  delegate reads.

  `ConfigProvider(locale:)` overrides the delegate for a subtree, and
  `copyWith` replaces a single word without forking a language. A widget
  property still beats both, and with nothing wired up at all the words fall
  back to English rather than throwing — a widget kit has to draw in any
  application.

  Every word but `noMoreItems` is taken from Ant Design's own locale files
  rather than translated here.

### Changed

- `Modal.okText`, `Modal.cancelText` and the same pair on `Popconfirm` are now
  nullable, null meaning the word from the locale in scope. Passing a widget
  works exactly as before.

## 0.6.5

### Added

- `Countdown`. Time to a moment or since one, counting either way, with antd's
  format tokens — `Y M D H m s S`, padded to the width of the run, with square
  brackets kept as written. A unit left out of the format rolls into the next
  one down, so `HH:mm:ss` reads `26:00:00` where `D[d] HH:mm:ss` reads
  `1d 02:00:00`.

  Named `Countdown` rather than `Timer`: `dart:async` already has one, and it
  is needed in the very file that shows this widget.

  A countdown rounds up to the smallest unit its format asks for — three and a
  half seconds left reads `00:04`, since formatting the remainder as it stands
  opens a fresh countdown one short of its own length. It wakes only when the
  drawn text is due to change, and measures against the wall clock, so it
  stays right across a suspended app.

  `CountdownController` drives one from outside the build. Changing the moment
  counted against never needed a handle — a new `target` does that — but
  pausing does: the count runs on the wall clock, and no arrangement of
  properties holds it still. Resuming gives the pause back rather than charging
  for it, and time added while paused is added to the figure on screen rather
  than to whatever the clock ran down to behind its back.

## 0.6.4

### Added

- `Badge` counts roll their digits into place, each place its own reel, turning
  the way the count moved. Ticking over takes the short way round: 9 to 10
  rolls the units one step forward to 0 rather than nine steps back. Each place
  is a fixed cell, so a turning reel cannot shove its neighbours sideways, and
  `99+` is drawn still, being no number going anywhere. A count falling to
  nothing retreats rather than blinking out — keeping the count it was showing
  as it goes — and leaves the tree once gone.

### Fixed

- A standalone `Badge` took the full width of its row. A container told to
  align its child takes all the width it is offered.
- A single-character count is round again: the padding that makes the pill a
  lozenge belongs only to counts of more than one character.
- The ring around a count is drawn outside it rather than as a border, which
  was eating into the height the tokens name and leaving the badge shorter
  than it asked to be.

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
