# TimePicker

A field that collects a time of day.

```dart
TimePicker(
  value: _opensAt,
  format: 'HH:mm',
  onChanged: (time) => setState(() => _opensAt = time),
)
```

## The value is a `Duration`

A time of day is a `Duration` since midnight. `Duration(hours: 9, minutes: 30)`
is half past nine.

Dart has no time-of-day type outside Material, which this package is
deliberately built without — and a `Duration` needs no conversion to be
compared, added to, or handed to
[`formatDuration`](../data_display/countdown.md), which the kit already uses
for `Countdown`. One convention serves the whole package.

Coming from a `DateTime`:

```dart
final t = Duration(hours: dt.hour, minutes: dt.minute);
```

## The format decides the columns

`format` does two jobs: it writes the value out, and it says which columns the
panel offers.

| Format | Panel | Hands back |
| --- | --- | --- |
| `HH:mm:ss` | hour, minute, second | seconds kept |
| `HH:mm` | hour, minute | seconds always zero |
| `HH` | hour | minutes and seconds zero |
| `h:mm a` | hour, minute, meridiem | a 12-hour clock |

A panel offering a column the format would then discard would be collecting
something it does not keep, so the two cannot disagree.

The grammar is `TimeFields`:

| Token | Means | Example |
| --- | --- | --- |
| `H` / `HH` | hour, 0-23 | `9`, `09` |
| `h` / `hh` | hour, 1-12 | `9`, `09` |
| `m` / `mm` | minute | `5`, `05` |
| `s` / `ss` | second | `5`, `05` |
| `A` / `a` | meridiem, upper or lower | `AM`, `am` |
| `[...]` | literal text | `[at]` |

## Width

The field sizes itself — no `SizedBox` to work out by hand. In a `Row`,
`TimePicker(format: 'HH:mm')` takes the room it needs.

It takes the **wider of two things**, because it shows both at different times
and must not resize between them:

| | |
| --- | --- |
| the longest the format can render | `00:00` for `'HH:mm'` |
| the placeholder | until a time is chosen |

Sizing to the figures alone cut the placeholder off with an ellipsis. Sizing to
the placeholder alone would make every picker as wide as the locale's own
wording, since one is always supplied.

**A shorter placeholder is the lever for a narrower field** — `placeholder: ''`
leaves the figures to decide.

**Told** a width it fills it, so a picker in a form column lines up with the
fields around it. Merely **offered** an upper bound it takes what it needs and
gives way if there is less:

| Parent | Result |
| --- | --- |
| `SizedBox(width: 220)` | 220 — told |
| `Column(crossAxisAlignment: stretch)` | fills — told |
| `Wrap`, a plain `Column`, a `Row` | its own width — offered |
| a narrow one of those | shrinks rather than overflowing |

The measurement uses the widest figure the face draws, since a proportional
font does not give every digit the same width, and it follows the locale's own
figures.

## Typing

The field is typed as well as picked. An entry that is not a time leaves the
value alone rather than clearing it, so a stray keystroke cannot wipe a set
time. Widths are lenient — `9:5` reads as `09:05` — because a field is read
while it is still being typed.

A 12-hour format needs to be told which half of the day: `9:00` on its own is
refused rather than guessed at.

Pass `inputReadOnly: true` to leave the panel the only way in — worth it on
touch, where a keyboard covers the panel it is meant to fill.

## Confirming

A panel with more than one column waits for **OK** before reporting a value: an
hour with no minute yet is not a time the caller wants to hear about. A
single-column panel commits as soon as you pick.

`needConfirm` overrides that either way.

Either way the **field follows the panel at once**: pick an hour and it shows,
even while the value itself waits for OK. A panel showing a choice above a
blank field reads as broken. Closing without confirming puts the committed
value back.

## Blocking times

```dart
TimePicker(
  format: 'HH:mm',
  disabledTime: DisabledTime(
    hours: () => [for (var h = 0; h < 9; h++) h],
    minutes: (hour) => hour == 9 ? [for (var m = 0; m < 30; m++) m] : const [],
  ),
)
```

Each callback names what is **not** available, and the later ones are told what
has been chosen so far. `hideDisabledOptions: true` takes them off the list
instead of greying them out.

## API

| Prop | Type | Default | Notes |
| --- | --- | --- | --- |
| `value` | `Duration?` | `null` | Since midnight. Null lets the picker keep its own |
| `defaultValue` | `Duration?` | `null` | What an uncontrolled picker starts with |
| `onChanged` | `ValueChanged<Duration?>?` | — | Null when cleared |
| `format` | `String` | `'HH:mm:ss'` | Also decides the columns |
| `hourStep` / `minuteStep` / `secondStep` | `int` | `1` | Must divide evenly |
| `disabledTime` | `DisabledTime?` | — | What cannot be chosen |
| `hideDisabledOptions` | `bool` | `false` | Hide rather than grey |
| `showNow` | `bool?` | `null` | Follows the defaults, else true |
| `needConfirm` | `bool?` | `null` | Follows the column count |
| `allowClear` | `bool?` | `null` | Follows the defaults, else true |
| `disabled` | `bool?` | `null` | Follows `componentDisabled` |
| `size` | `SoftSize?` | `null` | Follows `componentSize` |
| `variant` | `TimePickerVariant?` | `null` | `outlined`, `filled`, `borderless` |
| `placeholder` | `String?` | `null` | Falls back to the locale |
| `placement` | `PopoverPlacement` | `bottomLeft` | Where the panel opens |
| `open` / `onOpenChange` | `bool?` / `ValueChanged<bool>?` | — | Controlled panel |
| `inputReadOnly` | `bool` | `false` | Panel only |
| `status` | `InputStatus?` | `null` | `warning` or `error`, drawn as on the kit's other fields |
| `prefix` | `Widget?` | — | Sits before the value |
| `suffixIcon` | `Widget?` | — | Replaces the clock face |
| `onClear` | `VoidCallback?` | — | After the value is dropped |
| `footerBuilder` | `WidgetBuilder?` | — | A row of your own under the panel's footer |
| `token` | `TimePickerToken?` | — | Per-instance tokens |

## Design tokens

| Token | Default |
| --- | --- |
| `borderRadius` | `borderRadius` |
| `cellHeight` | `controlHeight - sizeXXS` (28) |
| `columnWidth` | `controlHeightLG * 1.4` (56) |
| `visibleRows` | `8` |

## Defaults for a whole app

```dart
ConfigProvider(
  defaults: const ComponentDefaults(
    timePicker: TimePickerDefaults(
      variant: TimePickerVariant.filled,
      showNow: false,
    ),
  ),
  child: ...,
)
```

## Localization

The placeholder, **Now** and **OK**, and the meridiem words come from the
locale — and so do the **figures**: under a locale with its own digits the
panel and the field show them, the way `Countdown` and `Badge` already do, and
a time typed back in those figures is read correctly.

See [localization](../localization.md).
