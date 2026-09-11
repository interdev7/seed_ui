# DatePicker

A field that collects a calendar date.

```dart
DatePicker(
  value: _startsOn,
  onChanged: (date) => setState(() => _startsOn = date),
)
```

## The value is a `DateTime`

Dart's own date type, with the clock at midnight — nothing to convert on the
way in or out. Coming from a `DateTime` that carries a time, use `dateOnly`:

```dart
DatePicker(value: dateOnly(order.placedAt))
```

Midnight matters: two `DateTime`s for the same day are not equal if their
clocks differ, so a picker keeping a stray 14:32 would hand back "same" days
that compare unequal.

## The panel has three depths

```
day → month → year     the header walks up
year → month → day     picking walks back down
```

Reaching 1998 from 2026 by tapping a chevron twenty-eight times is not a
design. The header's middle is the way up; the chevrons step by one page of
whatever is on screen — a month, a year, a decade.

The grid is **always six weeks**. A month that fitted in five would make the
panel shorter and shift everything under it.

## The format

`format` writes the value out. The grammar extends the one `TimePicker` reads,
so one string can carry both halves — `'yyyy-MM-dd HH:mm'`.

| Token | Means | Example |
| --- | --- | --- |
| `yyyy` / `yy` | year | `2026`, `26` |
| `MMM` | month, short name | `Mar` |
| `MM` / `M` | month, number | `03`, `3` |
| `dd` / `d` | day of month | `04`, `4` |
| `EEE` | weekday, short name | `Wed` |
| `[...]` | literal text | `[on]` |

`M` is the month and `m` the minute, as every other date library has it — case
is what tells them apart.

## Typing

The field is typed as well as picked. An entry that is not a date leaves the
value alone rather than clearing it. Widths are lenient — `2026-1-5` reads as
`2026-01-05` — because a field is read while it is still being typed.

**A day the month does not have is refused**, not rolled over. `DateTime`
itself turns the 31st of February into the 3rd of March, which would land a
typo somewhere else entirely.

Leap years come out right, including the century rules: 2024 and 2400 have a
29th of February, 2100 does not. The kit asks `DateTime` rather than
hand-rolling the arithmetic.

## A time as well as a date

```dart
DatePicker(
  showTime: true,
  value: _startsAt,
  onChanged: (at) => setState(() => _startsAt = at),
)
```

The scrolling columns stand beside the calendar — the same ones `TimePicker`
shows, so a time is picked the same way wherever it is asked for. Three things
follow from collecting two halves at once:

**Nothing is handed back until Ok.** A date whose time is still being chosen is
half an answer, so `onChanged` waits for the footer.

**A day picked twice keeps the hour chosen in between.** The draft carries its
clock; only the day under it moves.

**Today becomes Now**, and sets the clock as well as the day. A footer that
moved the date and left the hour at midnight would be the same half answer.

A `format` naming no time is given `HH:mm:ss`, since a picker that collected an
hour and then wrote it nowhere would look broken. Name your own to keep it
shorter:

```dart
DatePicker(showTime: true, format: 'yyyy-MM-dd HH:mm')
```

The panel measures itself. Add a column by naming a longer format, widen one
through `timeColumnWidth`, put something broad under it with `footerBuilder` —
the panel follows, and nothing has to be told a width. It stops at what the
popover has room for, so a wide footer widens the panel but never the window.

`disabledTime` refuses values in the columns, exactly as it does on
`TimePicker`. The columns appear beside the **day** panel only: the months of a
year and the years of a decade are steps on the way to a day, and an hour
picked against them would belong to no date yet.

## Presets

A rail of named dates beside the panel:

```dart
DatePicker(
  presets: [
    DatePreset.of('Today', DateTime.now),
    DatePreset.of('A week from now', () => DateTime.now().add(Duration(days: 7))),
    DatePreset('The end of the quarter', DateTime(2026, 3, 31)),
  ],
)
```

`DatePreset.of` works its date out **when the preset is taken**, not when the
panel is built: a picker opened at one minute to midnight and tapped a minute
later would otherwise hand back yesterday. `DatePreset` takes a date that is
already known.

A preset landing on a day `minDate`, `maxDate` or `disabledDate` bars is greyed
and does nothing — a name on a rail that reached a blocked day would be a way
round the block, exactly as **Today** would be.

The rail leads on the side the page reads from, and scrolls inside its own
height rather than making the panel grow past the calendar beside it.

## What it collects

```dart
DatePicker(picker: DatePickerKind.week)      // 2026-W11
DatePicker(picker: DatePickerKind.month)     // 2026-08
DatePicker(picker: DatePickerKind.quarter)   // 2026-Q3
DatePicker(picker: DatePickerKind.year)      // 2026
```

**The value stays a `DateTime`** whichever it is — the first day of the thing
chosen. A week is its first day, counted from wherever the locale starts its
weeks; a quarter is the first day of its first month. Nothing here needs a
type of its own: a week is a day you can add seven to.

The panel opens at the depth that suits and stops there — a month picker has
no days to offer, so it shows none. A week picker still shows days, because a
week is chosen by pressing a day in it, and **the whole row is marked**: one
press on any of them is the same answer, so marking one and not the rest would
say the others were something else.

A `format` left alone is chosen to suit; name your own and it stands. The
grammar gains two tokens:

| Token | Means | Example |
| --- | --- | --- |
| `ww` / `w` | week of the year, ISO | `11` |
| `Q` | quarter | `3` |

ISO weeks run Monday to Sunday and week one is the one holding the first
Thursday — the other reckoning gives a week 53 that is one day long, and a
date library that hands back a one-day week is one nobody trusts twice.

Quarter names come from the locale: `Q` in English and German, `T` for
*trimestre* in the Romance languages, 季度 in Chinese.

## Drawing a cell yourself

```dart
DatePicker(
  cellBuilder: (context, cell, child) => Stack(
    alignment: Alignment.bottomCenter,
    children: [
      child,
      if (bookings.containsKey(cell.date)) const _Dot(),
    ],
  ),
)
```

**`child` is what the panel would have drawn** — the pill, its fill, the band
under a range. Wrap it rather than replacing it and the cell keeps every state
the panel gives it for nothing: chosen, today, hovered, barred, the mark the
keyboard leaves. Replacing it is allowed and is the caller's business, but
then all of that is theirs to draw too.

### What `cell` says

`DateCell` is everything the panel knows about that day at the moment it is
drawn. Every field is settled — none of them is a callback you have to ask
again — and together they are exactly what the default mark is drawn from, so
a builder that replaces the child has the same facts the panel had.

| Field | Type | What it means |
| --- | --- | --- |
| `date` | `DateTime` | The day, at midnight. This is the value a tap would hand back for a `day` picker — a `week` picker settles it to the week's first day afterwards |
| `today` | `bool` | Whether it is today, by the clock at the moment of the build. The panel draws today as an outline rather than a fill, so a day that is both today and chosen can still be told apart |
| `chosen` | `bool` | Whether the picker holds it. **Either end of a range counts**, and in a `week` picker every day of the chosen row is `chosen` — one press on any of them is the same answer |
| `within` | `bool` | Whether it lies **between** the two ends of a range, ends excluded. Always false in a single-date picker. While a range is being dragged out this follows the pointer, so it changes as the reader moves |
| `outside` | `bool` | Whether it belongs to the month either side rather than the one on show. The grid is always six weeks, so a few of these are always drawn; the panel greys them |
| `disabled` | `bool` | Whether it cannot be chosen — `minDate`, `maxDate`, `disabledDate`, and in a range picker `minDays`/`maxDays` while the second end is being chosen |
| `resting` | `bool` | Whether the keyboard is resting on it. Not the same as hovered: the pointer's own highlight belongs to the mark and is not reported here, because it changes on every frame the pointer moves and a builder rebuilding for that would cost more than it is worth |

Two things it deliberately does not say. **Hovered** is the mark's business,
for the reason above. **Which pane** a day is drawn in, in a range picker's
two-month panel: the same date is drawn once, and a builder that cared which
side it fell on would be building against the layout rather than the date.

`DateRangePicker` takes the same builder, and its cells carry `within` and the
band under them for real.

### The air in the grid

`mainAxisSpacing` and `crossAxisSpacing` say how far apart the days stand.
The air is added **around** the cell, not taken out of it: `cellWidth` and
`cellHeight` are how big a day is, and asking for more air parts the days
rather than shrinking them. A wider gap therefore makes the panel bigger,
which is what asking for it means.

The band a range draws still spans the gap. It is laid across the whole
**pitch** — the day and the air beside it — so a stretch of days reads as one
band rather than coming out in pieces.

## Blocking days

```dart
DatePicker(
  minDate: DateTime(2026, 1, 1),
  maxDate: DateTime(2026, 12, 31),
  disabledDate: (day) => day.weekday == DateTime.sunday,
)
```

`minDate` and `maxDate` close the ends off; `disabledDate` is asked about every
day the panel draws. Blocked days are greyed rather than hidden, so the shape
of the month stays readable — and **Today** obeys the same rule, since a footer
that could reach a blocked day would be a way round it.

## Width

The field sizes itself, as `TimePicker` does: the wider of the longest the
format can render and the placeholder. **Told** a width it fills it; merely
**offered** an upper bound it takes what it needs and gives way when there is
less.

## Clearing it

The mark appears when the pointer is over the field or the panel is open, and
one click clears. One click, not two: the target is in the slot whenever there
is something to clear, and only what is *drawn* there follows the pointer — a
target that came and went with the paint would not be there yet for a mouse
that arrives and clicks in the same frame.

## Sizes

`size` takes either a preset or a measurement:

```dart
DatePicker(size: SoftSize.large)              // the theme's scale
DatePicker(size: ControlSize.height(36))       // 36 tall
DatePicker(size: ControlSize.width(200))      // 200 wide, standard height
DatePicker(size: ControlSize.box(200, 36))    // 200 by 36
```

A preset carries a type size of its own; a bare measurement names only itself,
so the standard type size stands. A two-dimensional size gives its **height**
as the height — not its larger side, which would make a 200-by-36 field two
hundred pixels tall.

Fields whose preset carries more than the box — `Button`, `Input`, where the
padding and the radius move with it too — keep `SoftSize`: a bare number would
supply one of the four and leave the rest guessing.

## API

| Prop | Type | Default | Notes |
| --- | --- | --- | --- |
| `value` | `DateTime?` | `null` | Null lets the picker keep its own |
| `defaultValue` | `DateTime?` | `null` | What an uncontrolled picker starts with |
| `onChanged` | `ValueChanged<DateTime?>?` | — | Null when cleared |
| `picker` | `DatePickerKind` | `day` | `day`, `week`, `month`, `quarter`, `year` |
| `format` | `String` | `'yyyy-MM-dd'` | See the grammar above; follows `picker` unless named |
| `cellBuilder` | `DateCellBuilder?` | — | Draws a day cell, given the panel's own mark |
| `disabledDate` | `bool Function(DateTime)?` | — | Asked about every day drawn |
| `minDate` / `maxDate` | `DateTime?` | — | The ends of the range on offer |
| `showToday` | `bool?` | `null` | Follows the defaults, else true |
| `allowClear` | `bool?` | `null` | Follows the defaults, else true |
| `disabled` | `bool?` | `null` | Follows `componentDisabled` |
| `size` | `ControlSize?` | `null` | A preset, or a measurement of your own. Follows `componentSize` |
| `variant` | `DatePickerVariant?` | `null` | `outlined`, `filled`, `borderless` |
| `placeholder` | `String?` | `null` | Falls back to the locale |
| `placement` | `PopoverPlacement` | `bottomLeft` | Where the panel opens |
| `open` / `onOpenChanged` | `bool?` / `ValueChanged<bool>?` | — | Controlled panel |
| `inputReadOnly` | `bool` | `false` | Panel only |
| `status` | `InputStatus?` | `null` | `warning` or `error` |
| `prefix` | `Widget?` | — | Sits before the value |
| `suffixIcon` | `Widget?` | — | Replaces the calendar mark |
| `onClear` | `VoidCallback?` | — | After the value is dropped |
| `showTime` | `bool` | `false` | Collects a time of day too |
| `disabledTime` | `DisabledTime?` | — | Which values the time columns refuse |
| `presets` | `List<DatePreset>` | `const []` | Named dates on a rail beside the panel |
| `footerBuilder` | `WidgetBuilder?` | — | A row of your own under the footer |
| `token` | `DatePickerToken?` | — | Per-instance tokens |

## From the keyboard

The field is a stop in the tab order like any other, and `↓` or `Enter` opens
the panel — there is nothing else for a key to do on a field whose whole
purpose is the panel. Once open:

| Key | What it does |
| --- | --- |
| `←` / `→` | The day before, and the day after |
| `↑` / `↓` | The same weekday a week back, and a week on |
| `PageUp` / `PageDown` | The month before, and the month after |
| `Enter` | Take the day the keyboard rests on |
| `Esc` | Put the panel away, taking nothing |

The day the keyboard rests on wears the mark the pointer leaves, so the hand
and the keyboard say the same thing — and it appears only once a key has
been pressed, since a grey box on a panel nobody has walked yet reads as a
mistake. A day `disabledDate` bars is stepped over rather than stopped at, and
the month follows the cursor: walking off the end of March shows April.

The sideways arrows follow the reading direction.

## What a screen reader hears

The field says it is a button, what it is called, and whether its panel is
open. What it holds is spoken by the editable inside it, so the value is not
named twice.

`semanticsLabel` names a picker whose label is written outside it — a `Form`
field's, say; the placeholder names one that stands on its own. An error status
marks it invalid.

## Design tokens

| Token | Default |
| --- | --- |
| `borderRadius` | `borderRadius` |
| `cellWidth` | `controlHeightSM * 1.5` (36) |
| `cellHeight` | `controlHeightSM` (24) — the day itself, without the air |
| `headerHeight` | `controlHeightLG` (40) |
| `mainAxisSpacing` | `sizeXXS` (4) — the air between one week and the next |
| `crossAxisSpacing` | `sizeXXS` (4) — the air between one day and the next |
| `presetsWidth` | `controlHeightLG * 3` (120) |
| `timeColumnWidth` | `controlHeightSM * 2` (48) |

## Localization

The placeholder, **Today**, the month and weekday names and the figures all
come from the locale — and so does **which day the week starts on**. Most
languages start on Monday; Japanese, Portuguese and Hebrew start on Sunday,
Arabic on Saturday. A calendar that always led with Monday would misread a
month at a glance for everyone it is wrong for.

The chevrons carry the locale's **Previous** and **Next** as their accessible
names: a painted chevron says nothing to a screen reader.

See [localization](../localization.md).

## Not here yet

Nothing. Collecting more than one date is
[`MultiDatePicker`](multi_date_picker.md) and a range is
[`DateRangePicker`](date_range_picker.md) — each its own component, since each
has a value of a different shape and a panel that behaves differently.

A range is not here and will not be: it is
[`DateRangePicker`](date_range_picker.md), its own component. Start-and-end has
its own logic, and bolting it on as a flag would spoil both.
