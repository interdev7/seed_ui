# Divider

A line that separates content: blocks of a page, or words and buttons in a
row.

```dart
const Divider(child: Text('Details'))
```

> **Name clash.** Material has a `Divider` too. When importing both, hide
> Material's: `import 'package:flutter/material.dart' hide Divider;`.

## Horizontal

The default. It fills the width it is given and leaves room above and below;
`size` says how much:

| `size` | Room above and below |
| --- | --- |
| `SoftSize.small` | `sizeXS` (8) |
| `SoftSize.middle` (default) | `sizeLG` (24) |
| `SoftSize.large` | `sizeXL` (32) |

With no `size` of its own it follows `ConfigProvider`'s component size, as the
other components do.

## With a title

`child` sets a title in the line. `titlePlacement` says where:

| `DividerTitlePlacement` | Where |
| --- | --- |
| `start` | Near the start, a twentieth of the line before it |
| `center` (default) | In the middle |
| `end` | Near the end |

`start` and `end` follow the reading direction. `titleMargin` fixes how far a
`start` or `end` title stands from its edge, in pixels:

```dart
const Divider(
  titlePlacement: DividerTitlePlacement.start,
  titleMargin: 0,
  child: Text('Flush with the edge'),
)
```

A title is set as a small heading. `plain: true` sets it as body text instead,
for a divider that should not draw the eye.

## Vertical

`orientation: DividerOrientation.vertical` stands a short line between things
in a row, as tall as a line of text:

```dart
Row(
  mainAxisSize: MainAxisSize.min,
  children: const [
    Text('Edit'),
    Divider(orientation: DividerOrientation.vertical),
    Text('Share'),
  ],
)
```

A vertical divider takes no title.

## Line style

| `DividerVariant` | Line |
| --- | --- |
| `solid` (default) | Unbroken |
| `dashed` | Short dashes |
| `dotted` | Round dots |

Dashes and dots are measured from the line's thickness, so a thicker line has
longer dashes and wider gaps.

## Defaults for a subtree

`DividerDefaults` sets `variant`, `size`, `titlePlacement` and `plain` for
every divider below a `ConfigProvider`:

```dart
ConfigProvider(
  defaults: const ComponentDefaults(
    divider: DividerDefaults(variant: DividerVariant.dashed),
  ),
  child: ...,
)
```

## Accessibility

The line is decoration, and a screen reader passes it by. A title is read as
the text it is.

## Design tokens

`DividerToken` overrides this component's own tokens. Every field is an
override; an unset one falls back to the value derived from the global theme.

| Token | Default |
| --- | --- |
| `lineColor` | `colorSplit` |
| `lineWidth` | `lineWidth` |
| `marginSM`, `margin`, `marginLG` | `sizeXS`, `sizeLG`, `sizeXL` — room above and below, by size |
| `verticalMargin` | `sizeXS` — room either side of a vertical divider |
| `verticalHeight` | nine tenths of `fontSize` |
| `titleGap` | `size` — between a title and the line |
| `titleColor` | `colorText` |
| `titleFontSize`, `titleFontWeight` | `fontSizeLG`, `w500` |
| `plainTitleFontSize` | `fontSize` |

```dart
Divider(
  // …
  token: const DividerToken(lineColor: Color(0xFF1677FF)),
);

// …or for every Divider in a subtree:
ConfigProvider(
  theme: ThemeData(
    components: const ComponentsConfig(divider: DividerToken(lineWidth: 2)),
  ),
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
