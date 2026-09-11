# MultiDatePicker

A field that collects any number of days.

```dart
MultiDatePicker(
  values: _shifts,
  onChanged: (days) => setState(() => _shifts = days),
)
```

## Its own component, not a flag

The value is a list, the field carries a tag for each day rather than one line
of text, and the panel stays open. A picker that had to be both this and
`DatePicker` would be worse at each — the same reason
[`DateRangePicker`](date_range_picker.md) stands on its own.

What all three share is the panel: the grids, the header and the cells are
written once and each picker says what a day means to it.

## The list is kept in order

The days come back **earliest first**, whatever order they were pressed in. A
run of dates is read in order, and a list that came back in the order somebody
happened to tap would have to be sorted by every caller.

The clock is dropped on the way in, so the same day twice over is held once —
`DateTime(2026, 3, 4)` and `DateTime(2026, 3, 4, 14, 32)` are one day.

## Picking

**The panel stays open.** Picking a second day is the ordinary next thing to
do; a panel that shut after the first would make a list of five days five
journeys. Pressing a day already in takes it out again.

**The panel shows what the owner settled on.** Handed `values` from outside,
the picker asks and then draws the answer rather than drawing the ask: a day
is marked on the tap that took it, and an owner that refuses the change is
shown refusing it. The panel lives in the overlay and is redrawn on its own,
one frame behind the tap, which is what gives the owner its say.

The footer counts what is in and carries **Ok**, because a panel that does not
close on a pick still needs a way to say "done" that is not "press somewhere
else".

## What it refuses

```dart
MultiDatePicker(
  minDate: DateTime(2026, 1, 1),
  maxDate: DateTime(2026, 12, 31),
  disabledDate: (day) => day.weekday == DateTime.sunday,
  maxCount: 5,
)
```

`minDate`, `maxDate` and `disabledDate` work as they do on `DatePicker`.

`maxCount` bars the rest of the panel once that many days are in, rather than
refusing a tap that looked available: a limit nobody can see reads as a bug. A
day already in can still be taken out — otherwise a full list would be a list
nobody could correct.

## What the field shows

A tag for each day, each with a cross that removes it. `maxTagCount` names
that many and counts the rest as `+ 3 ...`, worded as a `Select` holding more
than it shows words it; left alone, every day is named and the
field grows to hold them — a picker holding three days should read as three
days.

### Keeping to one line

```dart
MultiDatePicker(maxTagCountResponsive: true)
```

As many days as **fit** are named and the rest are counted, worked out from
the room the field actually has rather than from a number decided in advance.
Nothing wraps, so nothing makes the field taller.

It settles the question `maxTagCount` answers, so the two are not used
together.

It needs no width of its own. The line takes what the tags put on it and hides
something only once the room runs out — given the whole page it names them
all, squeezed into a column it collapses. A tag that ends up with less room
than its words want ellipsises them rather than spilling over its own edge.

The line is the same one `Select` uses. What the tags are and what the chip
says is each control's business; how many of them fit is the line's.

## Width

**The field takes what it is holding.** Given no width it is as wide as its
tags, or as its placeholder while it holds none, and it grows as days go in.
Offered less than that, the tags wrap and it takes what it was offered; told a
width outright, it fills it.

The height follows: it is a **minimum**, not a fixed height, so a field
holding a fortnight is taller than one holding a day. Fixed, the tags would be
clipped and the reader would be told nothing about it.

## Drawing a tag yourself

```dart
MultiDatePicker(
  tagBuilder: (context, tag, child) => holidays.contains(tag.date)
      ? Tag(
          color: TagColor.gold,
          closable: true,
          onClose: tag.onRemove,
          child: Text(tag.label),
        )
      : child,
)
```

`child` is the tag the picker would have drawn — wrap it to add something, or
return your own. `tag` carries `date`, `label` (the day written by the
picker's own format and the locale's figures, so a tag drawn by hand reads
like the ones beside it), `enabled`, and `onRemove`.

**Take `onRemove` with you.** A tag drawn by hand that drops it leaves the day
with no way out but the panel. It is null on a barred field: a tag nobody may
remove should not offer to be removed.

`removeIcon` replaces the cross on every tag. The mark only — where it sits
and what pressing it does stay the picker's business, so a picture cannot be
swapped in for something that does nothing.

## API

| Prop | Type | Default | Notes |
| --- | --- | --- | --- |
| `values` | `List<DateTime>?` | `null` | Null lets the picker keep its own |
| `defaultValues` | `List<DateTime>?` | `null` | What an uncontrolled picker starts with |
| `onChanged` | `ValueChanged<List<DateTime>>?` | — | The whole list, every time it changes |
| `format` | `String` | `'yyyy-MM-dd'` | `DatePicker`'s grammar |
| `disabledDate` | `bool Function(DateTime)?` | — | Asked about every day drawn |
| `minDate` / `maxDate` | `DateTime?` | — | The ends on offer |
| `maxCount` | `int?` | — | How many days may be held at once |
| `maxTagCount` | `int?` | `null` | How many are named before the rest are counted |
| `maxTagCountResponsive` | `bool` | `false` | Keep to one line, naming as many as fit |
| `allowClear` | `bool?` | `null` | Follows the defaults, else true |
| `disabled` | `bool?` | `null` | Follows `componentDisabled` |
| `size` | `ControlSize?` | `null` | A preset, or a measurement |
| `variant` | `DatePickerVariant?` | `null` | `outlined`, `filled`, `borderless` |
| `placeholder` | `String?` | `null` | Falls back to the locale |
| `semanticsLabel` | `String?` | — | Names a field labelled from outside |
| `placement` | `PopoverPlacement` | `bottomLeft` | Where the panel opens |
| `open` / `onOpenChanged` | `bool?` / `ValueChanged<bool>?` | — | Controlled panel |
| `status` | `InputStatus?` | `null` | `warning` or `error` |
| `prefix` | `Widget?` | — | Sits before the tags |
| `suffixIcon` | `Widget?` | — | Replaces the calendar mark |
| `onClear` | `VoidCallback?` | — | After the days are dropped |
| `footerBuilder` | `WidgetBuilder?` | — | A row of your own under the panel |
| `cellBuilder` | `DateCellBuilder?` | — | Draws a day cell — see [DatePicker](date_picker.md) |
| `tagBuilder` | `DateTagBuilder?` | — | Draws one tag, given the picker's own |
| `removeIcon` | `Widget?` | — | Replaces the cross on every tag |
| `token` | `DatePickerToken?` | — | The panel is `DatePicker`'s, so its numbers are too |

## From the keyboard

The field is a stop in the tab order, and `↓` or `Enter` opens the panel. Once
open:

| Key | What it does |
| --- | --- |
| `←` / `→` | The day before, and the day after |
| `↑` / `↓` | The same weekday a week back, and a week on |
| `Enter` | Take the day the keyboard rests on, or put it back |
| `Esc` | Put the panel away |

`Enter` leaves the panel open, as a tap does: the keyboard has to be able to
build the same list the pointer can.

## What a screen reader hears

The field says it is a button, what it is called, whether its panel is open,
and — as its value — the days it holds, in order.

## Design tokens

The panel is `DatePicker`'s, so `DatePickerToken` carries its numbers.

## Localization

The placeholder, the month and weekday names, the figures and which day the
week starts on all come from the locale.

See [localization](../localization.md).

## Not here yet

Presets, and a limit on which days may be chosen *together* — "any five, but
no two in the same week" is a rule about the list rather than about a day, and
`disabledDate` is asked one day at a time.
