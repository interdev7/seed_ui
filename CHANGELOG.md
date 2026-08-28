# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.13.0

### Added

- **`Segmented.scrollButtons`** — a run too wide to fit now says so.

  An arrow appears on whichever end has something hidden behind it, and each
  tap brings on one more segment; both show when there is more either way, and
  each goes when its end runs out. A run that fits shows neither. Segments that
  scrolled with nothing to say so looked like all the segments there were.

  The arrows sit over the ends rather than beside them — a button taking space
  of its own would narrow the viewport the moment it appeared, hiding another
  segment and so keeping itself needed — and a step stops short by a button's
  width so the segment it brings on does not arrive underneath one. `arrowBg`,
  `arrowHoverBg` and `arrowColor` dress them; `scrollButtons: false` turns them
  off.

- **`DropdownEntry<T>`** — the menu carries the type of what it reports.

  ```dart
  Dropdown(
    menu: [
      DropdownItem(value: RowAction.edit, label: const Text('Edit')),
      DropdownItem(value: RowAction.remove, label: const Text('Delete')),
    ],
    onItemTap: (action) => switch (action) { ... },
  )
  ```

  `DropdownItem.key` was an `Object?`, so every handler began by asking what it
  had been given. It is now `DropdownItem<T>.value`, inferred from the items
  and handed back through `onItemTap` — and an enum makes the `switch`
  exhaustive. A submenu's `children` carry their parent's type.

  A menu of items alone needs no type written anywhere. A `DropdownDivider`
  among them asks for one to be named once, on the `Dropdown`: a divider
  carries no value, and Dart settles a list's element type before the menu's.

### Changed

- **`DropdownItem.key` is now `DropdownItem.value`, and `Dropdown` is
  `Dropdown<T>`.** `key` next to Flutter's own `Key` read as tree identity
  when it was nothing of the sort, and `Segmented` and `Select` had settled on
  `value` for this long ago. Rename the argument and drop the `is` check the
  old `Object?` forced on every handler.

## 0.12.0

### Added

- **`ThemeData.materialTheme`** — the Material theme that matches a kit theme.

  ```dart
  final kit = ThemeData(dark: isDark);

  ConfigProvider(
    theme: kit,
    child: MaterialApp(theme: kit.materialTheme, home: const Home()),
  )
  ```

  The kit's theme is not Material's, and anything Material still draws keeps
  reading `MaterialApp.theme`. A page transition paints its backdrop with
  `colorScheme.surface`; left unset that is Material's light default, so under
  a dark kit theme every navigation flashed white before the page arrived.

  It is reached from the theme itself rather than through a `BuildContext`, so
  no `Builder` is needed between the provider and the app;
  `context.softToken.materialTheme` is the same value from inside the tree. A
  bridge for Material's own chrome, not a port of the kit's design language.

## 0.11.0

### Added

- **`FloatButton` and `FloatButtonGroup`** — the button that floats above the
  page, alone or opening into several.

  ```dart
  FloatButtonGroup<UserAction>(
    layout: const FloatButtonLayout.fan(jitter: 0.4, seed: 7),
    items: const [
      FloatButtonItem(value: UserAction.edit, label: 'Edit'),
      FloatButtonItem(value: UserAction.share, label: 'Share'),
    ],
    onItemTap: (value) => handle(value),
  )
  ```

  It is a `Button` underneath with its control height pinned, so `ButtonColor`
  and `ButtonShape` are the same types they are everywhere else rather than
  look-alikes, and hover, press and disabled behave as they already do.

  `FloatButtonLayout` is sealed, not an enum: `vertical`, `horizontal`, `fan`,
  `grid` and `custom` do not all carry the same data, and an enum would have to
  hang a fan's radius on the group, where it would be silently meaningless for
  three variants out of five. A ring is not a sixth layout — it is
  `fan(sweep: 2 * pi)`.

  The direction of travel is read off the trigger's place on screen: a group
  parked at the bottom right opens up and to the left. `label` is a widget hung
  outside the button's own box, and `FloatButtonLabelPlacement.auto` works out
  the side from the layout — sideways along a column, above a row, and outward
  along its own spoke on a fan, so labels fan out with the buttons instead of
  piling up on one side.

  `size` takes a preset or a measurement of your own, on a button alone or on a
  whole group. A fan's radius is worked out from how many items share the
  sweep — the chord between neighbouring spokes is `2r·sin(step/2)` — so they
  stand clear of one another however many there are. `fan(jitter:)` scatters
  them along their spokes without being random: the same `seed` gives the same
  arrangement on every open and in every test run, and an item is kept beyond
  the radius at which it clears the next spoke, so no arrangement can collide.

  The page underneath an open group keeps working — it scrolls, and its buttons
  still answer.

  Items are data, so the group can size and place them. `value` is yours (which
  action is this?) and `key` is the tree's (which element?) — a `GlobalKey`
  there lets a `Tour` aim at an item. `onItemTap` fires with the value beside
  the item's own `onTap`, as `Dropdown` already does.

  One `itemBuilder` hook covers every wrapper, so there is no `badge` prop and
  no `tooltip` prop:

  ```dart
  itemBuilder: (context, item, child) =>
      Tooltip(message: Text(item.label ?? ''), child: child),
  ```

  `dismissible` and `closeOnSelect` answer two different questions — a tap
  outside, and a tap on an item. **Escape closes the group whatever they say**:
  a menu with no way out from the keyboard is a trap, and no setting may make
  one. `FloatButtonController` drives a group from outside the build, for a
  tour step that needs the items on screen before it can point at one; passing
  both a controller and `open` is an assertion error.

  A scroll under an open group re-aims it rather than closing it — closing
  would contradict `dismissible: false`.

  A label wears the kit's text style and nothing else — no plate behind it,
  because a caption that needs one is a caption you wrap yourself. The opening
  is shaped by `FloatButtonToken.curve`.

  Positions are settled by a `Flow` delegate during paint, so a frame of the
  opening animation moves every item without laying anything out again.

- **`ControlSize.width(180)`** — the other half of `box()`. It names a width
  and leaves the height to the preset scale, where `height()` names a height
  and leaves the width to the component. Every control that took a
  `ControlSize` takes it: `Input`, `InputNumber`, `Select`, `TimePicker`,
  `DatePicker`, `Progress`, `Steps`, `Avatar` and `Spin`.

  ```dart
  Input(size: ControlSize.width(180))      // 180 wide, standard height
  Progress(percent: 0.5, size: const ControlSize.width(160))
  ```

  A circle has one measurement, so `width` and `height` mean the same thing to
  an `Avatar`, a `Spin` or a `Steps` marker: `ControlSize.width(56)` is the
  same 56-wide circle as `ControlSize.height(56)`. The names part company only
  where a control has two dimensions to name.

### Changed

- **`ControlSize.fixed` and `.raw` are now `.height` and `.box`.** The old
  names said a measurement was given without saying *which* — and the one-
  dimension case meant different things in different places: a height on a
  field, a diameter on an avatar. A circle's height is its diameter, so one
  honest name covers both.

  ```dart
  ControlSize.fixed(36)       →  ControlSize.height(36)
  ControlSize.raw(200, 36)    →  ControlSize.box(200, 36)
  ```

  The classes behind them moved with the names, so the pair cannot drift
  apart: `ExplicitSquareSize` is `ExplicitHeight` (its `dimension` is now
  `height`), and `ExplicitSize` is `ExplicitBox`.

  **`SoftSize` is untouched** — `size: SoftSize.large` reads exactly as before.
  It answers a different question: a preset follows the theme's scale, a
  measurement does not.

  No deprecated aliases. Two names for one idea is the confusion this removes,
  and 1.0 would freeze whichever survived.

## 0.10.0

### Added

- **A `Select` with no width no longer throws.** Its value area was
  `Expanded`, which needs a width from above, so a select in a `Row` crashed
  the way the pickers used to. With nothing to fill it now falls back to its
  widest label.

  It does not size itself the way the pickers do, and deliberately: a picker's
  format promises what the field can ever hold, while a select's content is
  whatever was chosen — and in tags mode the chips decide their own size.
  Given a width, it fills it.

- **A controlled `open` no longer throws.** Handing `TimePicker` or
  `DatePicker` an `open` that changed made them mount the overlay entry from
  `didUpdateWidget` — which runs inside a build, where marking the Overlay as
  needing to build is illegal. Both now wait for the frame to finish. A picker
  born with `open: true` opens as well, which it never did.

- **`Input`, `InputNumber`, `Select`, `TimePicker` and `DatePicker` take a
  `ControlSize`.** Their
  `size` accepted only a preset, so an exact height meant wrapping the field.
  The line is drawn by what the preset actually feeds: these three feed the box
  alone — a height and a type size that can stay put — while `Button` and
  `Input` feed four or five things at once and keep `SoftSize`.

  ```dart
  DatePicker(size: ControlSize.fixed(36))     // 36 tall
  DatePicker(size: ControlSize.raw(200, 36))  // 200 by 36
  ```

  `explicitWidth` goes with it, so a two-dimensional size names the width as
  well — a `Select` or a picker given `raw(180, 36)` needs no `SizedBox`
  around it.

  `resolveHeight` was added beside `resolve1D` for it: a two-dimensional size
  has to give its height, not its larger side, or a 200-by-36 field would come
  out two hundred pixels tall.

  `Input` was the interesting one. The rule as first written said its preset
  feeds five things at once — height, type size, two paddings and a radius —
  so a bare number would supply one and leave the rest guessing. Measured
  rather than restated, that is wrong: the text sits exactly centred at 20, 36
  and 56 pixels and nothing overflows, because the box holds the height up and
  the padding only adds air inside it.

  The two-dimensional form names the width as well, on all four. `Input` has
  two ways out of its build — a plain field returns before the row that
  carries a search button — and an earlier attempt patched only the second, so
  `raw()` looked like it did nothing at all. Both honour it now.

  `fixed()` names a height and nothing else, so a field given one still fills
  the width it is offered: a text input has no content to measure itself
  against, unlike a picker whose format says what it can hold.

  `InputNumber` is an `Input` with steppers, so it took the measurement the
  moment the field did — except for the stepper buttons, which are sized
  separately and would have stuck out of the border. In spinner mode a named
  width beats the `spinnerWidth` token.

  `Button` is the same question and still takes a `SoftSize`. Its size feeds
  four places, one of them `ButtonShape.circle` where the height is a
  diameter, so it needs its own pass rather than a mechanical one.

  Source-compatible — `SoftSize` is a `ControlSize`, so every existing call
  still reads the same.

- **`DatePicker`** — the kit's second picker, on the foundation `TimePicker`
  laid. The value is a `DateTime` at midnight: Dart's own date type, so nothing
  is converted on the way in or out, and `dateOnly` trims one that carries a
  time.

  **The panel has three depths.** The header walks up — days to months, months
  to years — and picking walks back down, so a date years away is three taps
  rather than twenty-eight presses of a chevron. The grid is always six weeks;
  a month that fitted in five would shorten the panel and shift everything
  under it.

  ```dart
  DatePicker(
    value: _startsOn,
    minDate: DateTime(2026, 1, 1),
    disabledDate: (day) => day.weekday == DateTime.sunday,
    onChanged: (date) => setState(() => _startsOn = date),
  )
  ```

  Typed as well as picked, and **a day the month does not have is refused**
  rather than rolled over — `DateTime` itself turns the 31st of February into
  the 3rd of March, which would land a typo somewhere else entirely. Leap years
  come out right, century rules included, because the arithmetic asks
  `DateTime` rather than working them out again.

  It carries the same field as `TimePicker`: self-sizing width, `status`,
  `prefix`, `suffixIcon`, `onClear`, `footerBuilder`, controlled and
  uncontrolled modes, and the locale's own figures.

- **`DateFields`, `formatDate`, `parseDate`, `monthGrid`, `addMonths`,
  `daysInMonth`, `dateOnly`, `isSameDay`, `isSameMonth`, `weekdayOrder`** —
  the date core, exported on its own so every awkward case is reachable
  without a picker on screen.

- **Calendar words in every language.** `shortMonths`, `shortWeekdays`,
  `selectDate`, `today`, and **`firstDayOfWeek`** on `SeedLocalizations`. Most
  languages start the week on Monday; Japanese, Portuguese and Hebrew start on
  Sunday and Arabic on Saturday, and a calendar that always led with Monday
  would misread a month at a glance for everyone it is wrong for.

  The Turkmen and Hebrew abbreviations are the conventional ones as far as I
  can tell and deserve a native reader's eye.

## 0.9.0

### Added

- **`TimePicker`'s panel is laid out properly.** Five faults in the first cut,
  all found on screen before it shipped: it filled the viewport (a stretched
  `Column` takes whatever width it is given, and the overlay gives it the
  screen); tapping a value changed nothing visible (the panel lives in the
  overlay, a tree of its own, so `setState` on the picker never reached it);
  the digits sat crooked (a line height of 1 with no even leading split);
  values had no gap between them; and the field stayed blank until OK.

  The layout now follows the reference it was modelled on: a column the width
  of 1.4 control heights, cells one control height less four, eight rows deep,
  the digits set in from the start rather than centred, and the pill inset
  horizontally so the gap between values is real. A chosen value takes the
  same primary tint a chosen row takes in a `Select`'s list.

  Picking writes the field at once even where the value itself waits for OK —
  a panel showing a choice above a blank field reads as broken — and the
  chosen value glides to the top of its column, with room below the run so
  even the last hour can get there.

  **The field sizes itself to the format.** A picker in a `Row` used to throw
  outright — its value area was `Expanded`, which needs a width from above — so
  every one had to be wrapped in a `SizedBox` measured by hand. The format
  already says what the field can ever hold, so it now says how wide it needs
  to be — or the placeholder does, whichever is wider, since the field shows
  both at different times and must not resize between them. A shorter
  placeholder is the lever for a narrower field.

  Told a width it fills it, as a form field should; merely offered an upper
  bound — by a `Wrap`, a plain `Column`, a `Row` — it takes what it needs, and
  gives way when there is less. Both look the same to `hasBoundedWidth`, and
  treating them alike stretched every picker across its parent.

  Chosen values land at once rather than easing up from the hover grey, which
  showed as a flash under the finger. The figures follow the locale, and a time
  typed back in those figures is read correctly. A picker with no `value` keeps
  what it is given, from an optional `defaultValue`, the way `Select` does —
  before this it forgot the choice the moment the panel closed. Added `status`,
  `prefix`, `suffixIcon`, `onClear` and `footerBuilder`.

  The field's own text carries the even
  leading split the rest of the kit uses, without which the glyphs sit above
  the middle of the box; `Select`'s field had the same fault and is fixed with
  it.

- **`fontWeight` and `fontWeightStrong` in the theme.** Weight was the one
  piece of typography the kit had no lever for: twenty widgets wrote
  `FontWeight.w400` or `w600` into their own text styles, and the only way to
  change one was to wrap that widget. `SeedToken` now carries both, and every
  one of those twenty reads a token instead.

  ```dart
  ThemeData(
    token: SeedToken(
      fontWeight: FontWeight.w300,        // ordinary text
      fontWeightStrong: FontWeight.w700,  // titles, the chosen row
    ),
  )
  ```

  Defaults are `w400` and `w600`, so nothing changes on screen.

  Three components draw a weight that is their own affair and now carry a
  token for it: `ButtonToken.fontWeight`, `ResultToken.fontWeight` and
  `TabsToken.fontWeightActive`.

- **`Avatar.customSize` is gone**; its `size` slot now takes a diameter
  directly, as `Spin`, `Progress` and `Steps` already did:

  ```dart
  Avatar(size: SoftSize.large)          // the theme's scale
  Avatar(size: ControlSize.fixed(64))   // a diameter of your own
  ```

  It was the last "two props for one idea" left in the kit, after
  `Tag.customColor`. An audit found no others.

- **`size` and `disabled` in the per-component defaults.** They could only be
  said for a whole screen, through `ConfigProvider.componentSize` and
  `componentDisabled` — so "small buttons on an otherwise normal screen" could
  not be said at all, even though the mechanism for it was already there.

  They resolve nearest first, and `componentSize` keeps working exactly as
  before:

  ```dart
  widget.size                                   // 1. this widget said so
    ?? defaults.button?.size                    // 2. said about buttons
    ?? ConfigProvider.componentSizeOf(context)  // 3. said about the screen
    ?? SoftSize.middle                          // 4. the kit's own default
  ```

  Added to every defaults class whose component has the prop — fourteen for
  `size`, fourteen for `disabled`.

  Two things surfaced while wiring it. `Progress` never consulted
  `componentSize` at all: its `size` was already nullable, so the earlier
  migration passed it by. And the docs never pointed from one mechanism to the
  other, which is how you go looking for a size in `ButtonDefaults` and come
  away thinking it cannot be set.

- **`TimePicker`** — the kit's first picker, and the shape a `DatePicker` will
  follow. A time of day is a `Duration` since midnight: Dart has no
  time-of-day type outside Material, which this package is built without, and a
  `Duration` needs no conversion to be compared or handed to `formatDuration`,
  the format engine `Countdown` already uses. One convention for the package,
  and no new name to collide with Material's `TimeOfDay`.

  **The format decides the columns.** `'HH:mm'` offers hours and minutes and
  hands back a value with no seconds in it; `'h:mm a'` grows a meridiem column
  and reads as a 12-hour clock. A panel offering a column the format would then
  discard would be collecting something it does not keep.

  ```dart
  TimePicker(
    value: _opensAt,
    format: 'HH:mm',
    onChanged: (time) => setState(() => _opensAt = time),
  )
  ```

  Typed as well as picked; an entry that is not a time leaves the value alone
  rather than clearing it, and a 12-hour format refuses `9:00` rather than
  guessing which half of the day it means. A multi-column panel waits for OK,
  since an hour with no minute yet is not a time worth reporting. `hourStep`,
  `minuteStep`, `secondStep`, `DisabledTime`, `hideDisabledOptions`, `showNow`,
  `needConfirm`, `allowClear`, a controlled `open`, and the usual `size`,
  `variant` and `disabled` — which follow `ConfigProvider` like every other
  control.

  `TimeFields`, `formatTime`, `parseTime` and `normalizeTime` are exported on
  their own: the awkward cases — midnight on a 12-hour clock, a half-typed
  entry, a format naming no minutes — are all reachable without a picker on
  screen.

- **`selectTime`, `now`, `am` and `pm`** on `SeedLocalizations`, filled for all
  twelve languages.

- **Duration unit letters in every language** — `dayUnit`, `hourUnit`,
  `minuteUnit`, `secondUnit` on `SeedLocalizations`. `Countdown` already
  translated its figures, but the letters in `format: 'D[d] HH:mm'` are
  literal text inside a pattern the app owns, so they stayed English beside
  Arabic-Indic or Chinese figures — which reads as a bug rather than a
  default. The kit cannot translate a pattern handed to it; it now ships the
  words to build one:

  ```dart
  final l = context.seedLocale;
  Countdown(target: deadline, format: 'D[${l.dayUnit}] HH[${l.hourUnit}]')
  ```

  Filled for all twelve languages, and the gallery's countdown page now
  follows its language picker.

## 0.8.0

### Added

- **`ConfigProvider.defaults`** — default *props* for components, beside the
  tokens in `ThemeData.components`. A token says how a button is drawn; a
  default says what a button is unless it says otherwise, which is the only way
  to state a shape, a variant, or whether a tag closes:

  ```dart
  ConfigProvider(
    defaults: const ComponentDefaults(
      button: ButtonDefaults(shape: ButtonShape.round),
      tag: TagDefaults(closable: true),
    ),
    child: ...,
  )
  ```

  It covers **30 components and 83 props** — every prop that is a house-style
  decision rather than the state of one instance. `Alert.showIcon` is house
  style; `Alert.type`, success or error, is about that one message and stays
  where it is, as do `loading`, `dragging` and `indeterminate`.

  A widget's own prop always wins, and the sets merge slot by slot through
  nested providers. `ConfigProvider.defaultsOf<T>` reads them for a widget of
  your own. The full table is in [doc/theming.md](doc/theming.md).

- **`ButtonColor` and `TagColor` take a colour of your own**, not just a
  preset. The colour twin of `ControlSize`, and the same three call shapes:

  ```dart
  Button(color: ButtonColor.primary, ...)              // follows the theme
  Button(color: const ButtonColor(Colors.white), ...)  // a colour of your own
  Button(color: ButtonColor.fromString('#fff'), ...)   // as CSS writes it
  ```

  Each is now a sealed class: the presets moved to `ButtonPreset` / `TagPreset`
  and are still reachable by their old names, so existing code is unaffected
  and `switch` stays exhaustive. A colour of your own is shaded into the same
  hover, press and disabled states a preset gets.

  `parseHexColor` is exported for the same job elsewhere. It reads `#rgb`,
  `#rgba`, `#rrggbb` and `#rrggbbaa` — **alpha last, as CSS writes it**, not
  first as `Color(0xAARRGGBB)` does — and throws `FormatException` naming what
  it got rather than quietly returning black.

- **`unintended_html_in_doc_comment`** added to the lint set. An inline code
  span that opens on one line and closes on the next is not a code span, so
  `defaultsOf<ButtonDefaults>` in one doc comment reached pub.dev as an HTML
  tag and cost ten points on the score. `flutter_lints` does not carry that
  rule, so nothing local caught it; now `flutter analyze` does.

- **The gallery shows its version** beside the logo, generated from
  `pubspec.yaml` by `tool/sync_version.sh` and guarded by
  `tool/check_version.sh` — a screenshot now says which version it is.

- **`ConfigProvider.componentSize` and `ConfigProvider.componentDisabled`** —
  one word for a whole subtree, the way antd's `SizeContext` and
  `DisabledContext` work. A dense screen sets `componentSize: SoftSize.small`
  and every button, input, select and tab in it follows; a form that goes
  read-only while it saves sets `componentDisabled: saving` instead of
  threading `disabled:` through every field. Both inherit through nested
  providers like the rest of the configuration, and both are read by
  `componentSizeOf` / `componentDisabledOf` for widgets of your own.

  What a widget states for itself always wins, so a control can stay live in a
  disabled subtree. A nearer container still outranks the screen: an `Avatar`
  inside an `AvatarGroup` takes the group's size.

### Changed

- **`size` and `disabled` are now nullable on the components that follow the
  provider.** They had concrete defaults (`SoftSize.middle`, `false`), which
  left a component unable to tell "nobody said" from "somebody said the
  default" — and so nothing could be layered underneath. Passing a value is
  unaffected; only reading one back off a widget instance sees the change:

  ```dart
  // before
  final off = button.disabled;
  // after
  final off = button.disabled ?? false;
  ```

- **`Tag.customColor` is gone**; its `color` slot now takes a colour directly.
  Two props for one idea meant `color` and `customColor` could disagree, and
  only one of them could win.

  ```dart
  // before
  Tag(customColor: const Color(0xFF722ED1), ...)
  // after
  Tag(color: const TagColor(Color(0xFF722ED1)), ...)
  ```

  The same applies to the 83 props that now follow `ConfigProvider.defaults`;
  the table in [doc/theming.md](doc/theming.md) lists them. Passing a value is
  unaffected — only reading one back off a widget instance sees the change.

  `size` changed on `Avatar`, `AvatarGroup`, `Badge`, `Button`, `Card`,
  `Collapse`, `Input`, `InputNumber`, `Pagination`, `RadioGroup`, `Segmented`,
  `Select`, `Spin`, `Steps` and `Tabs`. `disabled` changed on `Button`,
  `Checkbox`, `CheckboxGroup`, `Dropdown`, `Input`, `InputNumber`,
  `Pagination`, `Radio`, `RadioGroup`, `RangeSlider`, `Segmented`, `Select`,
  `Slider`, `Switch`, `CheckableTagGroup`, `Tree` and `Upload`.

  Per-item flags kept their concrete defaults, because they are about the item
  rather than the screen: `SelectOption`, `RadioOption`, `CheckboxOption`,
  `SegmentedOption`, `CheckableTagOption`, `DropdownItem`, `TreeNode`,
  `StepItem`, `TabItem`, `CardTab` and `TourButton`. So did
  `Popconfirm.disabled`, which means "do not ask", not "cannot be used".

## 0.7.0

### Added

- **`Listy` shows a placeholder when it has no rows**, instead of an empty
  scroll area — `emptyContent` if you name one, otherwise the app's
  `emptyBuilder`, otherwise `Empty`. A list still fetching its first page is not
  empty: nothing appears while `loadMore.loading` is true or another page is
  expected. The end marker stands down while the placeholder is up, so an empty
  list does not say the same thing twice, and the header stays put, because
  pull to refresh is wanted exactly when nothing came back.

### Changed

- **`ConfigProvider.renderEmpty` is now `emptyBuilder`, and it is told which
  component is asking.** The old name said how the thing was called rather than
  what it makes, and the callback took only a context — so a single app-wide
  builder had no way to tell a dropdown from a page-sized list and had to hand
  both the same placeholder. It now takes an `EmptySlot` alongside the context.
  `Select` asks with `EmptySlot.select`, `Listy` with `EmptySlot.listy`.

  ```dart
  // before
  renderEmpty: (context) => const Text('Nothing'),
  // after
  emptyBuilder: (context, slot) => const Text('Nothing'),
  ```

  Until now `renderEmpty` was consulted by exactly one component in the whole
  kit.

  The accessor moved with it: `ConfigProvider.renderEmptyOf` is now
  `ConfigProvider.emptyBuilderOf`. Components should reach for
  `ConfigProvider.emptyFor(context, slot)` instead — it falls back to the kit's
  `Empty` rather than handing back a null to deal with.

- **Nested `ConfigProvider`s now inherit.** A provider inside another one used
  to hand down its own theme whole, so one placed to say a single thing —
  rounder buttons on this screen — silently reset the palette to the stock blue
  and reverted every other component to the defaults. The kit's own Listy demo
  had that bug: its density block ignored the theme picker. A nested theme now
  takes what it does not state from the theme above it: say only `components`
  and the colours stay, say only a seed and the brightness stays, say only
  `dark:` and the palette it is flipped on stays. `ThemeData.raw` is still taken
  as final.
- `emptyBuilder` and the `locale` are inherited the same way. Both used to be
  read from the nearest provider alone, so any provider between them and the
  widget — one carrying nothing but a theme — erased them.
- Each provider now merges once, when it builds, instead of every reader
  searching the tree outwards. Widgets under a provider that rebuilds for
  reasons of its own are no longer woken.

### Removed

- **`ConfigProvider(components: [...])`**, the parallel list of loose token
  objects. `ThemeData(components: ComponentsConfig(...))` says the same thing
  with the type checker watching, and a test already guarantees every token
  has a slot there. The 38 token dartdocs that pointed at the list now point at
  `ComponentsConfig`.

  ```dart
  // before
  ConfigProvider(components: const [ButtonToken(borderRadius: 16)], ...)
  // after
  ConfigProvider(
    theme: ThemeData(
      components: const ComponentsConfig(button: ButtonToken(borderRadius: 16)),
    ),
    ...
  )
  ```

- `ConfigProvider` is a `StatefulWidget` rather than an `InheritedWidget`.
  `of`, `componentOf` and `context.softToken` are unchanged; only a direct
  `dependOnInheritedWidgetOfExactType<ConfigProvider>()` would notice.

## 0.6.12

### Added

- `Listy.separatorRender`, a separator that is a widget rather than a border.
  The list draws a hairline under each row as part of the row's decoration, and
  `ListyStyles.item` could restyle or drop it — but only as a
  `BoxDecoration`, which cannot say dashed, inset, or a gap. Supplying one takes
  the default hairline away, so the two are never drawn one over the other. It
  runs between rows only: never after the last, and never between a section's
  last row and the next header.

## 0.6.11

### Removed

- `lib/main.dart`, a Flutter starter file that had been sitting in the package
  since before the first release. It put a `main()` and a `MainApp` widget into
  everyone's dependency — 0.6.10 shipped it — and it was the only thing failing
  `flutter analyze --fatal-infos`. Nothing referenced it.

### Fixed

- A vertical `Slider` wrote each mark opposite the dot it names. The scale runs
  up the page, as a measure does, but the labels were laid out from the top
  while the dots were laid out from the bottom. Both now go through one
  reckoning, so they cannot drift apart again.
- A vertical `Slider` with marks clamped itself to the width of its groove and
  overflowed the row it sat in by the gap beside it. It is now as wide as the
  groove, the gap and its widest label together, measured from the labels
  themselves rather than guessed at.

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
