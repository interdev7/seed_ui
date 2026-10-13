# InputOtp

A code typed one character to a cell: the six digits a text message or an
authenticator app hands over.

```dart
InputOtp(
  length: 6,
  semanticsLabel: 'Verification code',
  onCompleted: (code) => verify(code),
)
```

## How it types

One field stands behind the cells, so the field behaves as one:

- a whole code pasted at once lands in every cell, with anything that is not a
  code character dropped — `12-34 56` becomes `123456` — and anything past the
  last cell cut off;
- a phone offers the code from its messages above the keyboard
  (`AutofillHints.oneTimeCode`);
- Backspace walks back;
- a long press offers the platform's own menu, to paste a code copied
  elsewhere.

A tap on a cell puts the cursor on it, and what is typed replaces the
character there and moves on to the next — so a wrong digit is mended by
tapping it and typing the right one. A tap between two cells puts the cursor
after the last character.

## Value

| Property | What it does |
| --- | --- |
| `length` | How many cells (6 unless named) |
| `onChanged` | Called with the code whenever it changes |
| `onCompleted` | Called with the code once every cell is filled |
| `value` | Holds the code from outside; null lets the field keep its own |
| `defaultValue` | What the field starts with, when `value` is null |

## Characters

`characters` says which characters the field takes:

| `InputOtpCharacters` | Takes | Keyboard |
| --- | --- | --- |
| `digits` (default) | `0`–`9` | a keypad of digits |
| `alphanumeric` | letters and digits, kept as typed | letters |
| `any` | anything but whitespace | letters |

`mask` draws one character in every filled cell in place of what was typed —
`'•'` for a code that should not be read over a shoulder. A screen reader is
not told the characters either.

## Separator

`separator` is called with each cell's index and draws what it returns after
that cell; null draws nothing there:

```dart
InputOtp(separator: (i) => i == 2 ? const Text('–') : null)
```

## Size and status

`size` takes `SoftSize.small`, `middle` or `large`, or a measurement of your
own; a cell is as wide as it is tall unless `InputOtpToken.cellWidth` says
otherwise. Without one it follows `ConfigProvider`'s component size.

`status` colours every cell's border as a warning or an error, as on an
[Input](input.md). `disabled` greys the cells and takes nothing.

## Focus and screen readers

The cell the next character goes into wears the focus ring, with a caret that
blinks while it is empty — and stays lit, without blinking, where the platform
asks for less motion. `autofocus` and `focusNode` work as on any field.

A screen reader meets one text field, named by `semanticsLabel`, holding the
code; the cells and the separators say nothing of their own.

## Design tokens

`InputOtpToken` overrides this component's own tokens. Every field is an
override; an unset one falls back to the value derived from the global theme.

| Token | Default |
| --- | --- |
| `gap` | `sizeXS` — between two cells, and either side of a separator |
| `cellWidth` | none — as wide as the cell is tall |
| `colorBorder` | `colorBorder` |
| `activeBorderColor` | `primary.base` — the cell the next character goes into |
| `hoverBorderColor` | `primary.borderHover` |
| `cellBg`, `disabledCellBg` | `colorBgContainer`, `colorFillTertiary` |
| `colorText` | `colorText` |
| `caretColor` | `primary.base` |
| `borderRadius` | `borderRadius` |
| `fontSize` | `fontSizeLG` for a middle field, a step down and up for small and large |

```dart
InputOtp(
  // …
  token: const InputOtpToken(gap: 12),
);

// …or for every InputOtp in a subtree:
ConfigProvider(
  theme: ThemeData(
    components: const ComponentsConfig(
      inputOtp: InputOtpToken(borderRadius: 12),
    ),
  ),
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
