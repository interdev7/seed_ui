# Table

Rows and columns, with a heading. A column says how to draw a cell and, if it
likes, how wide to be.

```dart
Table<User>(
  data: users,
  columns: [
    TableColumn(title: const Text('Name'), value: (u) => u.name),
    TableColumn(title: const Text('Age'), align: TableAlign.end, value: (u) => u.age),
  ],
)
```

## The name

`Table` is Flutter's own as well, so a file that wants both needs to say which:

```dart
import 'package:flutter/material.dart' hide Table;   // the kit's
import 'package:seed_ui/seed_ui.dart' hide Table;    // Flutter's
```

The kit takes the plain name because that is the one people look for. `Listy`
went the other way — `List` is `dart:core`'s and there is no hiding that.

## Columns

| Field | |
| --- | --- |
| `value` | What the column reads out of a row |
| `builder` | Draws one cell, where text will not do: `(context, record, index)` |
| `title` | What stands at the head of the column |
| `width` | A width in logical pixels |
| `flex` | A share of what is left over |
| `align` | Which edge the cells are drawn against |
| `headerAlign` | The same for the heading. Defaults to `align` |
| `ellipsis` | Cuts the text rather than letting it wrap |

A column needs one of the two. **A `value` is the whole of most columns** —
the cell is that value as text, and there is nothing else to write:

```dart
TableColumn(title: const Text('Name'), value: (u) => u.name)
```

Reach for `builder` where text will not do. Naming a `value` as well is worth
it even then: the value is what a sort compares and a filter matches, so a
`Tag` can sort by the word inside it.

```dart
TableColumn(
  title: const Text('City'),
  value: (u) => u.city,
  builder: (_, u, __) => Tag(child: Text(u.city)),
)
```

There is no key into a map to get wrong: `T` is your own row type, and `value`
is handed one.

### How wide a column is

**Say nothing and it fits its content** — the column takes the width of its
widest cell, which is what a table is expected to do and needs writing
nowhere.

Whatever is left over after that goes to the automatic columns, shared between
them. A `width` is exact and a `flex` is a share, so:

```dart
TableColumn(title: const Text('Name'), width: 120, builder: ...)  // 120, exactly
TableColumn(title: const Text('City'), flex: 1, builder: ...)     // one part
TableColumn(title: const Text('Age'), flex: 2, builder: ...)      // of three
```

A column may name one or the other, never both — one is a number of pixels and
the other a share of what is left.

## Size

`size` takes a preset or a height of your own.

```dart
Table(size: SoftSize.small, ...)                  // dense
Table(size: const ControlSize.height(64), ...)    // rows 64 tall
```

A preset says how much padding a cell carries and lets the content decide the
rest. A number says how tall the row is, so the vertical padding stands aside
rather than adding to it — and it is a floor, so a cell that needs more still
gets it.

## Scrolling

```dart
Table(scroll: const TableScroll(y: 320), ...)    // a body that scrolls
Table(scroll: const TableScroll(x: 1200), ...)   // wider than its box
```

**`y`** gives the rows a height of their own, and the heading stops travelling
with them: it sits above and stays.

A table inside a scrolling page hands back what its rows cannot use. Scroll
views do not chain on their own — one inside another simply stops at its end —
so a table with a height of its own would otherwise freeze the page for as long
as the pointer was over it.

**`x`** is the width the table is laid out at, however narrow its box, and what
does not fit scrolls across. It is a **floor**: a table is never laid out
narrower than its own columns need, so adding columns past the width you named
widens the table rather than cutting it off.

It is still a number you have to mean. Name a width your window is wider than
and there is nothing to scroll — which is not a fault, but does look like one. The heading goes with the rows — both sit
in the same viewport rather than in one each kept in step by hand, so there is
only one offset for them to disagree about.

A table that scrolls sideways can be dragged with a mouse, the heading
travelling with the rows. That does not come free: Flutter leaves the mouse out
of `dragDevices`, so a scroll view cannot be dragged with one at all. On the web
that left a table that scrolled sideways with no way to scroll it, since the
wheel only goes down.

No bar is drawn across it, scrolling or still. A bar at the foot of a wide
table is a line the design did not ask for and it sits over the last row; the
shade a pinned column casts is what says there is more to see.

### What scrolling costs

A table given a `scroll.y` builds only the rows on screen. Five hundred rows of
fifteen columns is seven and a half thousand cells, and building them all to
show forty was the whole of the cost: measured over three thousand rows, the
tree went from forty-five thousand paragraphs to a hundred and fourteen, and
twenty scroll ticks from five thousand two hundred milliseconds to a hundred
and eighty-four. The count no longer moves with the data — three hundred rows
and three thousand build the same hundred-odd cells.

Columns still fit their content, and are measured again only when the answer
would change — the rows are compared element by element first, which costs
microseconds where measuring them costs milliseconds. A lazy body cannot ask
them to negotiate — the
rows that would do the negotiating have not been built — so the widths are
settled first, from the text itself: a `TextPainter` measures a string for the
price of laying that string out, and never touches the widget tree. A column
with a `value` is measured over every row, however many there are.

Two things it cannot measure that way, and both have the same answer — give the
column a `width`:

- a column that draws with a `builder` and names no `value`, because nothing
  can guess how wide a `Tag` is;
- a heading that is not a `Text`, for the same reason.

**Every row is one height** — the cell's padding plus a line of its text, so a
scrolling table's rows stand exactly as tall as a still one's. A row is found
by multiplying, not by laying out the ones above it, so a cell that wraps is
cut rather than allowed to grow its row. A table with no `scroll.y` keeps the grid it always had, where a cell that
wraps still grows its row — there is nothing to virtualise in a table you can
see all of.

`scroll.y` is the height of the rows, as antd means it. The heading stands
above them and is not counted in it.

### Columns that stay put

`fixed` pins a column to an edge and lets the rest scroll past it.

```dart
TableColumn(
  title: const Text('Name'),
  width: 160,
  fixed: TableColumnFixed.start,
  value: (u) => u.name,
)
```

Two things come with it, and both are consequences rather than choices.

**A pinned column needs a `width`.** It is measured before the body is laid
out, and a share of a width nothing has worked out yet means nothing.

**Pinning holds every row to one height**, as scrolling does, and for the same
reason: a pinned column is the first or the last column of a body that finds a
row by multiplying. The height is exact rather than a floor, so a cell with
more in it is cut.

Order does not matter. A column marked `end` is drawn at that edge wherever it
was listed.

A pinned column casts a shade over the rows that have gone behind it, and only
then: at rest against its own end there is nothing there to shade. It is
painted over those rows rather than behind the column — a shadow is painted
behind the box that casts it, and a pinned column's cells are mostly
transparent, so the cast used to show through the column as a grey wash.

A `bordered` table rules between every pair of columns, the pinned ones
included.

## Around the rows

| Prop | |
| --- | --- |
| `bordered` | An outline, and rules between the columns |
| `showHeader` | Whether the heading row is drawn |
| `header`, `footer` | Drawn above and below, and handed the rows |
| `empty` | What stands in when there are no rows |
| `loading` | Lays a `Spin` over the table |
| `rowHoverable` | Whether a row lights up under the pointer |
| `onRowTap` | Called with the record and its index |

With no rows the heading stays — the columns are still worth showing — and the
kit's `Empty` takes the space below it. `ConfigProvider.emptyBuilder` is asked
first, under `EmptySlot.table`, so a kit-wide placeholder covers tables too.

## Tokens

| Token | Default |
| --- | --- |
| `headerBg`, `headerColor` | the heading row |
| `rowHoverBg` | the row under the pointer |
| `borderColor` | `colorSplit` |
| `cellPaddingBlock`, `cellPaddingBlockSM`, `cellPaddingBlockLG` | 12, 8, 16 |
| `cellPaddingInline`, `cellPaddingInlineSM`, `cellPaddingInlineLG` | 16, 8, 20 |
| `footerBg`, `borderRadius`, `fontSize` | |
| `columnMinWidth` | `controlHeightLG × 2.5` — the narrowest a `flex` column is squeezed to |
| `pinnedShadowColor` | black at 15% (32% dark) — the shade a pinned column casts over the rows going past it |
| `pinnedShadowExtent` | `sizeLG` — how far that shade reaches before it has faded out |

## How many rows

Every row is built, not just the ones on screen: five hundred rows measure four
thousand widgets. That is fine for a page of rows — which, with pagination, is
what a table usually holds — and too slow for thousands.

It is worth being exact about where the cost is, because the obvious answer is
wrong. **Scrolling rebuilds nothing**: counted over twenty ticks on three
hundred rows, the table rebuilds zero times, a cell zero times. What costs is
painting three thousand widgets that are mostly off screen. So the usual
advice — memoise the widths, hoist the `EdgeInsets`, make each row a
`StatefulWidget` — buys nothing here, because none of that runs.

Repaint boundaries do help, since they let a layer be re-offered instead of
repainted. Measured over twenty ticks on three hundred rows with a pinned
column:

| | sideways | downwards |
| --- | --- | --- |
| before | 334ms | 135ms |
| with them | 210ms | 103ms |

The cure is still to build only what is on screen, and that needs a
two-dimensional viewport with the column widths worked out by hand rather than
by Flutter's `Table`. It is the next piece of work on this component.

## Not here yet

Lazy rows, sorting, filtering, row selection, expandable rows and pagination
are still to come, in that order.
