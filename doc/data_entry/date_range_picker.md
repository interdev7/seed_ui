# DateRangePicker

A field that collects a stretch of days.

```dart
DateRangePicker(
  value: _holiday,
  onChanged: (range) => setState(() => _holiday = range),
)
```

## Its own component, not a flag

A range is picked in two goes, the second constrained by the first, and it is
drawn as a band rather than a mark. Bolting that onto `DatePicker` would leave
both harder to read — so the two share their panel and nothing else.

## The value is a `DateRange`

```dart
final range = DateRange(DateTime(2026, 3, 9), DateTime(2026, 3, 4));
range.start        // 2026-03-04
range.days         // 6 — both ends counted
range.holds(day)   // ends included
```

**The ends are put in order**, whichever way round they come: a reader
dragging backwards through a calendar means the same stretch of time. Both are
days at midnight, as `DatePicker`'s value is, so two ranges for the same days
compare equal whatever clock they were built from.

## Two months, side by side

A range that crosses a month is the ordinary case, and turning the page
mid-drag loses the thread. The left pane carries the backward chevron and the
right the forward one: the two move together, so a chevron between them would
say nothing.

**On a narrow window the second month goes under the first.** A month that
does not fit is a month nobody can see: the panel is as wide as it is drawn,
so there is nothing to scroll sideways to. Stacked, the rail of presets lies
along the top rather than down the side — beside a one-month panel it would
take back the room the stacking just found.

The deeper panels — months, years — belong to one pane. They are steps on the
way to a day, and two decades side by side would be two ways of answering the
same question.

## Picking in two goes

The first tap puts an anchor down; the panel then draws from it to wherever
the pointer is, so the stretch is visible before it is taken. **Nothing is
handed back until both ends are in** — one end is not a range — and the panel
closes when the second lands.

The half being filled in is marked in the field, so a reader who has put one
end down can see which one the panel is waiting for. The mark keeps room
around the words rather than hugging them, and the half is sized for the words
**and** that room — otherwise the padding would push the date into an
ellipsis.

## What is refused

```dart
DateRangePicker(
  minDate: DateTime(2026, 1, 1),
  maxDate: DateTime(2026, 12, 31),
  disabledDate: (day) => day.weekday == DateTime.sunday,
  minDays: 2,
  maxDays: 14,
)
```

`minDate`, `maxDate` and `disabledDate` work as they do on `DatePicker`.

`minDays` and `maxDays` are told **while the second end is being chosen**, so
the days that would make too short or too long a range are greyed rather than
refused after the fact. A refusal that arrives after the tap is one nobody saw
coming.

## The band

Days inside a range wear a band that runs the full width of their cell, so a
stretch joins up sideways rather than reading as a row of separate marks. It
is only as tall as the pill inside it: the same height as the cell and one
week would run into the next, and a month would read as a single grey block.

A day already inside the band takes a deeper tint of the same colour under the
pointer, not the grey a day on the panel's own ground takes — grey over the
band is a flash of the wrong colour every time the pointer crosses a day.

## Presets

```dart
DateRangePicker(
  presets: [
    DateRangePreset.of('The last seven days', () {
      final today = dateOnly(DateTime.now());
      return DateRange(today.subtract(const Duration(days: 6)), today);
    }),
    DateRangePreset('That quarter', DateRange(
      DateTime(2026, 1, 1),
      DateTime(2026, 3, 31),
    )),
  ],
)
```

`DateRangePreset.of` works its range out **when the preset is taken**: "the
last seven days" should mean seven days ending now, not seven ending whenever
the field was drawn. A preset whose either end is barred is greyed and does
nothing.

## Width, and the mark between the halves

The two halves are always one width, which is what puts the arrow exactly
between them rather than nearer one date than the other. Each date is centred
in its half for the same reason: pushed to the start, the left one sits away
from the mark and the right one against it, and a mark meaning "from here to
there" stops reading as between them at all.

**Told** a width, the halves share whatever is left after the furniture, so
the field fills what it was given. Merely **offered** an upper bound, each
half takes the longest the format can write or its placeholder, whichever
asks for more, and gives way when there is less.

## Sizes

`size` takes either a preset or a measurement, exactly as `DatePicker` does:

```dart
DateRangePicker(size: SoftSize.large)
DateRangePicker(size: ControlSize.height(36))
DateRangePicker(size: ControlSize.box(320, 36))
```

## Clearing it

The mark appears when the pointer is over the field or the panel is open, and
one click clears — the target is the height of the field, not the fourteen
pixels of the glyph.

## API

| Prop | Type | Default | Notes |
| --- | --- | --- | --- |
| `value` | `DateRange?` | `null` | Null lets the picker keep its own |
| `defaultValue` | `DateRange?` | `null` | What an uncontrolled picker starts with |
| `onChanged` | `ValueChanged<DateRange?>?` | — | Both ends, or null when cleared |
| `format` | `String` | `'yyyy-MM-dd'` | `DatePicker`'s grammar |
| `disabledDate` | `bool Function(DateTime)?` | — | Asked about every day drawn |
| `minDate` / `maxDate` | `DateTime?` | — | The ends on offer |
| `minDays` / `maxDays` | `int?` | — | How short and how long a range may be |
| `allowClear` | `bool?` | `null` | Follows the defaults, else true |
| `disabled` | `bool?` | `null` | Follows `componentDisabled` |
| `size` | `ControlSize?` | `null` | A preset, or a measurement |
| `variant` | `DatePickerVariant?` | `null` | `outlined`, `filled`, `borderless` |
| `startPlaceholder` / `endPlaceholder` | `String?` | `null` | Falls back to the locale |
| `semanticsLabel` | `String?` | — | Names a field labelled from outside |
| `placement` | `PopoverPlacement` | `bottomLeft` | Where the panel opens |
| `open` / `onOpenChange` | `bool?` / `ValueChanged<bool>?` | — | Controlled panel |
| `status` | `InputStatus?` | `null` | `warning` or `error` |
| `prefix` | `Widget?` | — | Sits before the value |
| `suffixIcon` | `Widget?` | — | Replaces the calendar mark |
| `onClear` | `VoidCallback?` | — | After the range is dropped |
| `footerBuilder` | `WidgetBuilder?` | — | A row of your own under the panel |
| `presets` | `List<DateRangePreset>` | `const []` | Named stretches on a rail |
| `token` | `DatePickerToken?` | — | The panel is `DatePicker`'s, so its numbers are too |

## From the keyboard

The field is a stop in the tab order, and `↓` or `Enter` opens the panel. Once
open:

| Key | What it does |
| --- | --- |
| `←` / `→` | The day before, and the day after |
| `↑` / `↓` | The same weekday a week back, and a week on |
| `Enter` | Take the day the keyboard rests on |
| `Esc` | Put the panel away, taking nothing |

**Walking is not picking.** A reader stepping through the month has chosen
nothing until they press `Enter`; the first `Enter` puts the anchor down and
the second closes the range. Once the anchor is down the band follows the
walk, so the stretch is visible before it is taken. A day the rules bar is
stepped over rather than stopped at.

## What a screen reader hears

The field says it is a button, what it is called, whether its panel is open,
and — as its value — the two ends with a dash between them.

## Design tokens

The panel is `DatePicker`'s, so `DatePickerToken` carries its numbers:
`borderRadius`, `cellWidth`, `cellHeight`, `headerHeight`, `presetsWidth`.

## Localization

**Start date** and **End date**, the month and weekday names, the figures and
which day the week starts on all come from the locale.

See [localization](../localization.md).

## Not here yet

A time on each end, and more than two panes. Both are the same question — how
much of a panel one field may hold — and neither is answered by making this
one wider.
