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
| `format` | `String` | `'yyyy-MM-dd'` | See the grammar above |
| `disabledDate` | `bool Function(DateTime)?` | — | Asked about every day drawn |
| `minDate` / `maxDate` | `DateTime?` | — | The ends of the range on offer |
| `showToday` | `bool?` | `null` | Follows the defaults, else true |
| `allowClear` | `bool?` | `null` | Follows the defaults, else true |
| `disabled` | `bool?` | `null` | Follows `componentDisabled` |
| `size` | `ControlSize?` | `null` | A preset, or a measurement of your own. Follows `componentSize` |
| `variant` | `DatePickerVariant?` | `null` | `outlined`, `filled`, `borderless` |
| `placeholder` | `String?` | `null` | Falls back to the locale |
| `placement` | `PopoverPlacement` | `bottomLeft` | Where the panel opens |
| `open` / `onOpenChange` | `bool?` / `ValueChanged<bool>?` | — | Controlled panel |
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
| `cellHeight` | `controlHeightSM + sizeXXS` (28) |
| `headerHeight` | `controlHeightLG` (40) |
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

`multiple`, the `week` and `quarter` panels, and a range picker. A range is its
own component — start-and-end has its own logic, and bolting it on as a flag
would spoil both.
