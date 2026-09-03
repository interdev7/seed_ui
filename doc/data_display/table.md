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

## Columns under one head

A column with `children` heads them: it has a title spanning what is under it
and no cells of its own. Groups nest as deep as you like, and only the
leaves — the columns with no children — hold cells.

```dart
TableColumn(
  title: const Text('Name'),
  children: [
    TableColumn(title: const Text('First'), value: (u) => u.first),
    TableColumn(title: const Text('Last'), value: (u) => u.last),
  ],
)
```

A column that heads nothing stands the whole depth of the heading beside a
group, so nothing has to be spanned downwards by hand.

A sort and a filter belong to a leaf and are keyed by its place among the
leaves — a group has nothing to order or narrow, and tapping one does nothing.

**How it is drawn.** A `Table` maps a row's children onto its columns one for
one, so a title spanning several of them cannot be a cell of the grid. The
heading is laid out by hand instead, as a tree — a group is its title above a
row of what it heads — against the same measured widths the body is given,
which is what keeps the two lined up. The same caveat applies as elsewhere: a
column headed by something other than `Text` should name a `width` if its
heading is the widest thing in it.

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

`scroll.y` is the height of the rows, not of the table. The heading stands
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

## Sorting

`sortable` lets a heading be tapped, and the column's `value` is what it
compares — which is why most columns need nothing else said.

```dart
TableColumn(title: const Text('Age'), sortable: true, value: (u) => u.age)
```

A tap cycles ascending, descending, and back to the order the rows came in,
which is what a reader expects of a third tap: somewhere to put the rows back
without reaching for anything else. The whole heading answers — padding and
all, not just the word — and lights up under the pointer while it is a heading
that will do something. The column the table is
sorted by keeps that fill, hand or no hand: it is the one doing something, so
it is marked, and the mark arrives with a `defaultSort` before anybody has
touched anything.

Both carets are always drawn: one alone would say the column *is* sorted that
way, and a column that merely *can* be sorted has to say so too. They stand at
the cell's trailing edge rather than beside the word, or a column of headings
would have each pair at the end of a word of its own length, and a ragged edge
with it.

`sorter` says how to compare where the value will not do — a date shown as
`12 Mar` sorts by the date, not by the word. Naming one makes the column
sortable, so `sortable` need not be set as well.

```dart
TableColumn(
  title: const Text('Due'),
  sorter: (a, b) => a.due.compareTo(b.due),
  value: (u) => format(u.due),
)
```

Two things the table settles on its own:

- **Ties keep the order they came in.** Dart's `sort` is only stable below
  thirty-two elements, so the row's original place breaks the tie.
- **A row with nothing in the column goes last**, ascending or descending. The
  direction is applied to the comparison and not to that rule; turned round
  with everything else, a blank cell rose to the top of a descending sort.

Left to itself the table keeps its own sort, starting from `defaultSort`.
Give it `sort` and it shows what it is told and nothing else — pair it with
`onSortChanged`, or the heading will not answer.

```dart
Table(
  sort: _sort,
  onSortChanged: (next) => setState(() => _sort = next),
  ...
)
```

Sorting and building only what is on screen are the same table: the rows are
put in order once per data and sort, and the ones in view are built from that.
The column widths are measured from the rows as given, not as shown — an order
does not change how wide a word is, so sorting never re-measures.

## Filtering

`filters` puts a funnel at the head of a column, opening a menu of choices.
The column's `value` is what a choice is matched against, so most columns need
nothing else said.

```dart
TableColumn(
  title: const Text('City'),
  value: (u) => u.city,
  filters: const [
    TableFilter('Bristol', 'Bristol'),
    TableFilter('Galway', 'Galway'),
  ],
)
```

`onFilter` says what a choice means where matching the value will not do — a
range, a first letter, a field the column does not show.

```dart
onFilter: (choice, user) => user.name.startsWith(choice! as String)
```

Within one column the choices are alternatives: a row belongs if it answers
any of them. Across columns a row has to answer every one, which is what
narrowing twice means. `filterMultiple: false` makes a column's menu behave as
a set of radios, so a choice replaces the one before it.

`filterSearch: true` puts a field above the choices for narrowing the menu
itself, worth it once there are more of them than a reader will scan. What is
typed is matched against each choice's label, ignoring case and the spaces
around it; `filterSearchMatch` says what typing means instead — the same shape
as `sorter` against `sortable`. A choice already ticked stays ticked while it
is out of sight: narrowing the menu must not quietly drop what was chosen.

Nothing chosen is every row — a filter narrows, and one that has been asked
for nothing narrows nothing. A column present in the map with an empty list is
the same thing.

Left to itself the table keeps its own choices, starting from
`defaultFilters`. Give it `filters` and it shows what it is told, with
`onFiltersChanged` saying what a menu would have made of them. Both are keyed
by the column's place in `columns`, as `TableSort` is.

The funnel answers the hand apart from the heading it stands in: it takes a
rounded ground of its own, a step stronger than the heading's, and the mark
darkens with it. Sharing the heading's ground would leave the two answering as
one, when tapping the mark and tapping the heading do different things — and a
mark you can barely see sitting on a fill is worse than no fill.

The menu is as wide as its widest choice, floored at a hundred and twenty
pixels, and its choices scroll past two hundred and sixty-four rather than
growing off the screen. They carry the same padding as any other menu in the
kit — a menu that reads as its own kind of thing is one the reader has to
learn twice. Under them a rule runs the whole width of the block of buttons,
clipped to the panel's corners, with `sizeXS` either side and
`sizeXS - lineWidth` above and below so the rule does not add to the height.

Filtering happens before sorting: the rows are narrowed,
then put in order. The column widths are measured from the rows as given
rather than as shown, so neither narrowing nor sorting re-measures — a column
keeps its width while you filter, instead of jumping about under the hand.

## Picking rows

`selection` puts a column of boxes in front of the others, and a box at the
head that takes every row on show.

```dart
Table<User>(
  selection: TableSelection(onChanged: (rows) => setState(() => picked = rows)),
  columns: columns,
  data: users,
)
```

A row is itself, not a key: what comes back are the records, and two rows that
compare equal are one row as far as picking goes. Give records a `==` of their
own where that matters.

`mode: TableSelectionMode.radio` picks one row at a time, and drops the box at
the head — taking every row is not something a column of dots can mean.
`showSelectAll: false` drops it for the same reason of your own choosing.

`selectable` says which rows may be picked at all. A row that may not shows a
box that cannot be ticked, and the head passes it over, so a table whose
pickable rows are all picked reads as full however many are barred.

A picked row is tinted whether or not the pointer is on it, and a step
stronger while it is — without that a picked row looked exactly like every
other one, and the tick in front of it was the only thing saying so.

**The head answers for the rows on show.** A filter narrowing the table
narrows what "all" means — which is what it means everywhere else — and a row
already picked stays picked while a filter hides it: hiding a row is not
un-picking it.

Left to itself the table keeps its own picks, starting from
`defaultSelected`. Give it `selected` and it shows what it is told, with
`onChanged` saying what a tick would have made of them. `columnWidth` and
`fixed` size and pin the column, as any other column is sized and pinned.

## Rows that open

`expandable` puts a column of chevrons in front of the others, and the row
that is opened has a panel of your own drawing under it, across the whole
table.

```dart
Table<User>(
  expandable: TableExpandable(builder: (context, user, i) => Text(user.bio)),
  columns: columns,
  data: users,
)
```

A panel is never shorter than a row and free to be taller. A row whose height
was named carries no vertical padding — the height itself stands in for it —
so a panel padded the same way used to collapse to the height of its text.

The panel reveals and hides with the same animation a `Collapse` panel uses,
so a table opens the way everything else in the kit opens. The mark is a plus
inside a rounded square whose upright goes as the row opens, leaving a minus —
so it says what a tap will do rather than which way the row is pointing.

A row is itself, not a key, as with picking. `expandable` says which rows can
be opened at all — one that cannot shows no mark, since a mark that does
nothing is worse than none. `byRowTap: true` opens a row from anywhere on
it, and `showColumn: false` drops the chevrons where that is doing the work.

Left to itself the table keeps its own, starting from `defaultExpanded`; give
it `expanded` and it shows what it is told, with `onChanged` reporting.

**How the panel is drawn, and what it costs.** Flutter's `Table` cannot span a
row across its columns, so a panel cannot be a row of the grid — it sits
between two grids instead. Which is only safe if those grids agree on their
widths, so the columns are measured once and every grid is handed the same
numbers rather than each working out its own from the rows it happens to hold.
That measurement is the same one a scrolling table uses, so the same caveat
applies: a column headed by something other than `Text` should name a `width`
if its heading is the widest thing in it.

It also means **a table whose rows open is not lazy**, even with `scroll.y`: a
panel is whatever height its content is, and a lazy body finds a row by
multiplying. The rows still scroll inside the height you gave; they are all
built.

## A page at a time

`pagination` shows the rows a page at a time. The pager is the kit's own
`Pagination`, so everything it can be told is told the same way and a theme's
`PaginationDefaults` reaches it as it reaches any other.

```dart
Table<User>(
  pagination: const TablePagination(defaultPageSize: 20),
  columns: columns,
  data: users,
)
```

Paging happens after narrowing and sorting, so a page is a page of what the
filters left, in the order the sort asked for. Everything that draws works
from the page, so a row's index is its place on it, and picking, opening and
tapping all mean the row the reader is looking at — including the heading's
box, which takes the page rather than the whole table.

Narrowing a table until the page you were on no longer exists lands you on the
last page there is, not back on the first, and never on a page with nothing on
it.

The page and the page size are controlled apart: give `page` and a tap only
reports through `onChanged` while the size changer still works on its own.

`position` says where the pager stands and which edge it is drawn against —
`topStart`, `topCenter`, `topEnd`, `bottomStart`, `bottomCenter`, `bottomEnd`,
or `none` for a table paged from somewhere else on the screen. It takes a
list, so a long table can carry one at both ends:

```dart
position: const [TablePaginationPosition.topEnd, TablePaginationPosition.bottomEnd]
```

The default is a single `bottomEnd`. The edge is part of the position rather
than a knob of its own, so a `showTotal` drawn beside the pager sits with it
instead of hugging the leading edge.

## A row that adds up

A column's `summary` says what it adds up, drawn in a row under the rest.

```dart
TableColumn(
  title: const Text('Age'),
  value: (u) => u.age,
  summary: (context, rows) => Text('${rows.fold(0, (n, u) => n + u.age)}'),
)
```

It goes on the column rather than in a list of cells, so there is nothing to
keep in step with the columns: a column that says nothing leaves its place
empty, and a table where no column says anything draws no such row at all.

The rows handed to it are the rows on show — a page of them where the table is
paged, and what the filters left — the same rows `header` and `footer` are
given. A group heads other columns and has no cell of its own to sum up, so
the summary goes on one of the columns under it.

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
| `filterIconSize` | `sizeSM` — how big the funnel is |
| `filterHoverBg` | `colorFill` — the funnel's own ground under the pointer |
| `filterSearchWidth` | `140` — how wide the field that narrows a menu is |
| `expandIconSize` | `sizeMD` — how big the mark that opens a row is |
| `summaryBg` | `colorFillQuaternary` — behind the row that adds the columns up |
| `expandedBg` | `colorFillQuaternary` — behind the panel under an opened row |
| `selectionColumnWidth` | `controlHeightSM` — room for the box itself; the column is this plus a cell's padding |
| `filterMenuMaxHeight` | `264` — how tall a filter menu grows before its choices scroll |
| `headerHoverBg` | `colorFillSecondary` — behind a sortable heading under the pointer, and behind the one being sorted by |
| `headerMarkActiveColor` | `primary.base` — a mark in force: the caret of the order, a funnel that is narrowing |
| `headerMarkColor` | `colorTextQuaternary` — a mark merely offered |
| `sortCaretSize` | `sizeXXS` — how tall each caret is |
| `pinnedShadowColor` | black at 15% (32% dark) — the shade a pinned column casts over the rows going past it |
| `pinnedShadowExtent` | `sizeLG` — how far that shade reaches before it has faded out |

## How many rows

A table with a `scroll.y` builds only the rows on screen, so the count no
longer costs anything: three hundred rows and three thousand build the same
hundred-odd cells. Measured over twenty scroll ticks on three thousand rows of
fifteen columns, against the same table before the viewport:

| | paragraphs in the tree | twenty ticks |
| --- | --- | --- |
| before | 45015 | 5215ms |
| now | 114 | 184ms |

A table with no `scroll.y` still builds every row, which is right: there is
nothing to virtualise in a table you can see all of.

The other cost is measuring, and it is worth being exact about it. Measuring is
exact and so proportional to the data — five hundred rows of fifteen columns is
seven and a half thousand strings, and at fifteen microseconds each that is a
hundred and seventeen milliseconds. That was paid on every rebuild above the
table: a tap on a row cost all of it. The answer is now kept and only worked
out again when the question changes, which brought that tap to sixteen
milliseconds. The rows are compared element by element rather than by the
list's identity, since `data:` written inline is a new list every build.

## Not here yet

Spanned cells are still to come.
