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
one, so a title spanning several of them cannot be a cell of the grid. Without
a `scroll.y` the heading is laid out by hand instead, as a tree — a group is
its title above a row of what it heads — against the same measured widths the
body is given. With one, the viewport is handed a plan saying where every
heading cell stands and how much of the grid it covers, and only the cells
that start something are built: the rows stay lazy. The same caveat applies as elsewhere: a
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
cut rather than allowed to grow its row. A table with no `scroll.y` keeps the
grid it always had, where a cell that wraps still grows its row — there is
nothing to virtualise in a table you can see all of.

### What it asks in return

Finding a row by multiplying is the whole of how a lazy body works, so
anything that breaks a uniform grid of rows would take the laziness with it.
Nothing does any more, but two things ask something first:

| | what it asks |
| --- | --- |
| `expandable` | a `panelHeight`, since a panel of whatever height its content happens to be cannot be reckoned with |
| a pinned column | a `width`, since it is measured before the body is laid out |

Say neither and the table still works — it simply builds every row it was
given, which for a few dozen is nothing and for a few hundred is the reason
`pagination` exists.

Everything else the table can do rides on the lazy body as it is. A `summary`
is held at the foot the way the heading is held at the head. A grouped heading
and a spanned body are each a plan the viewport is given — where every cell
starts and how much of the grid it covers — with only the cells that start
something built. Both kinds of dragging are a shift the viewport adds where it
places a column or a row, and the viewport itself is asked where a carried one
would land, since it laid them out. Measured at three hundred rows: twelve
hundred cells built with any of them before, and forty or so after.

`sticky` never cost anything either: a table with a `scroll.y` already keeps
its heading in view inside its own height, so `sticky` does not apply to one.

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

**The shade belongs to the column, not to the band.** Each held column casts
its own at its own trailing edge, moving with it — the reference hangs the
shadow off the fixed cell itself for the same reason. A shade belonging to the
band jumped from one column's edge to the next the moment the second came to
rest.

It is a narrow edge rather than a band: `colorSplit` at the column's own edge,
gone twelve pixels out. Its strength comes from how far the column has been
held — nothing where the scroll has only just caught it, full a shade's width
later. So it arrives with
the scroll rather than switching on, and follows the hand instead of a clock.
A column coming to rest covers the shade of the one it stops behind, which is
what makes the handover a covering rather than a jump.

A held column's cells stand on `pinnedBg` with the row's own fill composed
over it, rather than the two being stacked: painted the other way round the
opaque ground covered the fill, and a held column neither lit up under the
pointer nor showed that its row was picked.

**A held column keeps its place.** It is not taken out and stacked at the edge
before anything has moved: it stands where you listed it, among the others,
and stops only when the scroll would carry it past its rest — behind the
columns held before it. So a loose column can stand between two held ones and
slide under them as the scroll catches up, and the order you wrote is the
order you see.

Two things come with it, and both are consequences rather than choices.

**A pinned column needs a `width`.** It is measured before the body is laid
out, and a share of a width nothing has worked out yet means nothing.

**Pinning holds every row to one height**, as scrolling does, and for the same
reason: a held column lives in a body that finds a row by multiplying. The height is exact rather than a floor, so a cell with
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

`sortPriority` lets several columns be in force at once: a column that names
one joins what is already sorted rather than replacing it, and the higher
number is compared first. A column that names none sorts alone — tapping it
puts the table in order by that column and no other.

```dart
TableColumn(title: const Text('City'), sortable: true, sortPriority: 2, ...)
TableColumn(title: const Text('Age'),  sortable: true, sortPriority: 1, ...)
```

`sort`, `defaultSort` and `onSortChanged` all take a list for the same reason.
The table keeps that list in priority order and reports it that way, so a
caller naming the sorts in any order still has them compared by what the
columns say.

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

On a table with a `scroll.y`, **name the panel's height** and the rows stay
lazy: a lazy body finds a row by reckoning where it starts, and it can go on
doing that with panels among the rows so long as their height is known — the
rows before a given one are so many ordinary ones and so many panels, which is
a count and not a measurement. Leave it unsaid and the panel is as tall as
what is in it, and every row is built. See
[What it asks in return](#what-it-asks-in-return).

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

**Rows that come a page at a time.** Left to itself the table counts what it
was handed and takes the page out of it — the rows are all here and paging
them is a matter of showing some. Name a `total` and the arrangement turns
around: the rows handed over are taken to be one page already, drawn as they
came, and that number is what the pager counts.

```dart
Table<Post>(
  data: page,                                  // just this page's rows
  pagination: TablePagination(
    page: current,
    pageSize: 10,
    total: 100,                                // what the server says there is
    onChanged: (page, size) => fetch(page, size),
  ),
  columns: columns,
)
```

A page is then fetched when it is asked for, never all of them at once.
Sorting and narrowing still work on what is here — one page — so a table paged
this way usually leaves both to the server too.

The page and the page size are controlled apart: give `page` and a tap only
reports through `onChanged` while the size changer still works on its own.

The pager stands outside the table's outline — it is about the table rather
than part of it, and inside the frame it pushed the outline below itself,
leaving the last row with nothing under it.

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

On a table with a `scroll.y` it is held at the foot while the rows run under
it, as the heading is held at the head — so it costs the lazy body nothing.

In a bordered table it is ruled like any other row, and the outline closes it
off: the frame is painted in front of the rows rather than behind them, or a
row with a fill of its own would paint straight over it.

It goes on the column rather than in a list of cells, so there is nothing to
keep in step with the columns: a column that says nothing leaves its place
empty, and a table where no column says anything draws no such row at all.

The rows handed to it are the rows on show — a page of them where the table is
paged, and what the filters left — the same rows `header` and `footer` are
given. A group heads other columns and has no cell of its own to sum up, so
the summary goes on one of the columns under it.

## Cells that span

A column's `span` says how many places its cell takes up in a given row.

```dart
TableColumn(
  title: const Text('Name'),
  value: (u) => u.name,
  span: (context, user, i) =>
      i == 0 ? const TableCellSpan(columns: 2) : const TableCellSpan(),
)
```

A cell that spans covers its neighbours, and those neighbours are simply not
drawn: the table works out which places are taken, so nothing has to return a
nought to say it is covered. A span asking for more columns or rows than there
are takes what there is.

Without a `scroll.y` the body is laid out by hand rather than as a grid — a
cell reaching across two columns cannot be a cell of a `Table` — against the
same measured widths the heading and the summary are given. With one, the
viewport is handed a plan of where each cell starts and what it takes, and
only the cells that start something are built: the rows stay lazy. The plan
covers every row rather than the ones on show, since a cell starting above the
screen still reaches into it.

The rules go on the cells rather than on the rows, or a line would be drawn
straight through the middle of a cell that reaches down.

What lights up under the pointer is decided by the **cell** it is on, not by
the row that cell sits in. Take two rows with one column merged across them:

```
a  |  bd
c  |
```

Point at `a` and `a` lights with `bd`, the cell standing over it — `c` does
not. Point at `c` and `c` lights with `bd`. Point at `bd` and everything it
covers lights, `a` and `c` both: the cell is one cell, and half of it lit is
worse than none.

A cell reaching **down** needs to know how tall a row is before it can be laid
over two of them, so a table with one holds every row to one height — as a
lazy body does, and for the same reason. Spanning columns alone leaves the
rows to their content. A body with a cell reaching down is one placed block,
so there is nowhere between its rows to open a panel: `expandable` and a row
span do not combine.

## A heading held in view

`sticky` keeps the heading against the top of the page while the rows scroll
past it.

```dart
Table<User>(sticky: const TableSticky(), columns: columns, data: users)
```

It is for a table whose rows are part of the page. One with a `scroll.y` of
its own already keeps its heading — the rows scroll inside it — so `sticky` is
ignored there rather than taking the heading away from its own rows.

A table without a `scroll.y` builds all its rows anyway — there is nothing to
virtualise in a table you can see all of — so `sticky` costs nothing. It is
not among [what turns laziness off](#what-turns-it-off), because it never
applies where there is any.

The heading keeps its place in the layout and is only *drawn* lower down, so
nothing moves and no space is taken twice. It takes `pinnedBg` under it, since
a heading's own fill is a two per cent wash and standing over the rows it
would let them be read straight through. `offsetHeader` holds it below a bar
of your own. A held heading needs its height known before it is laid out, so a
sticky table holds its heading to one row's height per level, as a lazy body
holds its rows.

## Rows you can move

`rowsDraggable` lets a row be picked up and dropped into another's place, with
the same mechanics as the columns: the others slide out of the way, each by
exactly a row, and the table keeps the order it is left in.

```dart
Table<User>(
  columns: columns,
  data: users,
  rowsDraggable: true,
  onRowsReordered: (from, to) => message.success('moved'),
)
```

The order a drag changes is **the one the rows came in** — the order underneath
narrowing and sorting. So a sort still has the last word: a table you can both
sort and arrange by hand would otherwise be two answers to one question.

Every row is held to one height, as pinning holds them: a row sliding aside
has to know how far, and that is a height. A row can still be tapped — the
drag is wrapped round what a row already does rather than put in its place.

## Columns you can move

`columnsDraggable` lets a heading be picked up and dropped on another column's
place. **The table does the moving** and keeps the order it is left in — there
is no reordering logic to write.

```dart
Table<User>(
  columns: columns,
  data: users,
  columnsDraggable: true,
  onColumnsReordered: (from, to) => message.success('moved'),
)
```

`onColumnsReordered` is word of what happened rather than the thing that makes
it happen; leave it off and dragging still works.

**Only the drawing moves.** A sort and a filter go on naming a column by where
it was listed, so carrying one about does not quietly point them at its
neighbour: the table keeps the order it draws in apart from the order the
columns are named in.

While a heading is carried it is lifted, tilted and given a ground of its own,
and **the columns slide aside as it goes** — each by exactly the width of the
one being carried, over the theme's own duration. Where it is going is where
it is already standing, so letting go changes nothing further — the drop hands
every cell a fresh offset of nought against a layout that now matches, rather
than an old one to carry into its new place; giving the drag up slides them
back instead. A mark on a neighbour can only say *which* column;
moving them says it outright.

Nothing is reordered until the drop: the layout keeps the order it has and
only what is painted moves, so when the order does change the offsets fall to
nought against a layout that already matches it, and nothing jumps.

Carry it off the table and the neighbours go home; bring it back and they move
aside again — leaving is not letting go.

Where a carried column would land is read from where the finger is against
that layout, not from whichever cell lies under it. The cells slide, so asking
them chases the answer: every twitch of the hand found a different cell where
the last one had been, and the two columns swapped back and forth without the
hand moving at all.

Dragging columns needs their widths known in advance, so a table with
`columnsDraggable` is drawn against one measured set of them — which is to say
[it is not lazy](#what-turns-it-off).

A column with `children` is not draggable, nor are the leaves under it: a
group's title spans several places at once, and a leaf carried out of its
group would belong to nothing.

A heading that sorts still sorts: the drag is wrapped round the tapping rather
than put in its place.

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

The marks a heading carries are sized against each other rather than each on
its own: the mark that opens a row is a checkbox's size, since a column of
boxes and a column of marks should agree, and the carets and the funnel are
both the icon size — the reference sets a font size on the two caret glyphs
rather than a size on each triangle, so `sortCaretSize` is the pair's own
height and the triangles are worked out from it.


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
| `expandIconSize` | `size` — the mark that opens a row, which is a checkbox's size |
| `summaryBg` | `colorFillQuaternary` — behind the row that adds the columns up |
| `expandedBg` | `colorFillQuaternary` — behind the panel under an opened row |
| `selectionColumnWidth` | `controlHeightSM` — room for the box itself; the column is this plus a cell's padding |
| `filterMenuMaxHeight` | `264` — how tall a filter menu grows before its choices scroll |
| `headerHoverBg` | `colorFillSecondary` — behind a sortable heading under the pointer, and behind the one being sorted by |
| `headerMarkActiveColor` | `primary.base` — a mark in force: the caret of the order, a funnel that is narrowing |
| `headerMarkColor` | `colorTextQuaternary` — a mark merely offered |
| `sortCaretSize` | `fontSizeSM` — how tall the pair of carets stands, all told |
| `pinnedBg` | `colorBgContainer` — behind anything held in place, a column at an edge or a heading held in view, which has to be opaque |
| `pinnedShadowColor` | `colorSplit` — the shade a held column casts over the rows going past it |
| `pinnedShadowExtent` | `sizeSM` — how far that shade reaches before it has faded out |

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

Everything the component set out to do is here.
