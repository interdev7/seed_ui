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

## Size

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
| `footerBuilder` | `WidgetBuilder?` | — | A row of your own under the footer |
| `token` | `DatePickerToken?` | — | Per-instance tokens |

## Design tokens

| Token | Default |
| --- | --- |
| `borderRadius` | `borderRadius` |
| `cellWidth` | `controlHeightSM * 1.5` (36) |
| `cellHeight` | `controlHeightSM` (24) |
| `headerHeight` | `controlHeightLG` (40) |

## Localization

The placeholder, **Today**, the month and weekday names and the figures all
come from the locale — and so does **which day the week starts on**. Most
languages start on Monday; Japanese, Portuguese and Hebrew start on Sunday,
Arabic on Saturday. A calendar that always led with Monday would misread a
month at a glance for everyone it is wrong for.

The chevrons carry the locale's **Previous** and **Next** as their accessible
names: a painted chevron says nothing to a screen reader.

See [localization](../localization.md).

## Not yet

`showTime`, `presets`, `multiple`, the `week` and `quarter` panels, and a range
picker. A range is its own component — start-and-end has its own logic, and
bolting it on as a flag would spoil both.
