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

### A column that is not drawn

`hidden` leaves a column out of the table without taking it out of `columns`.
Which matters more than it sounds: a sort and a filter are keyed by a column's
place among the ones you listed, so dropping one from the list moves every key
after it. Hidden, it keeps its place and only stops being drawn. A group whose
every leaf is hidden goes as well — a title standing over an empty stretch of
table is worse than no title.

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

A column may also name a `minWidth`: a floor for one that sizes itself, for a
column of short words that still has to be reachable, or one whose cells are
built rather than read and so cannot be measured until they exist. It beats
the `columnMinWidth` token, which is only what a column that cannot be
measured falls back to and never widens one that measured narrower.

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

The cells of that column carry the same fill down their whole length, since
the heading says which column is doing something and the fill says how far
that reaches. It is the fill the hand leaves, so a hand over one of those rows
makes no further difference — there is nothing more to say. A picked row keeps
its own fill: what will happen to the row outranks what one of its columns is
up to. `rowSortedBg` is the token.

`sortDirections` names the orders a heading goes round, in the order it goes:
`const [TableSortOrder.descending]` for a column of dates that wants the
newest first and nothing else. The unsorted state always closes the round — a
reader has to be able to put the rows back the way they came. `sortIcon` draws
the mark in place of the carets, told which way the column is sorted or null
where it is not, the same shape as `filterIcon`. Draw one rather than typing
an arrow: a glyph the font has not got is a box, and most fonts have not got
arrows.

Both carets are always drawn: one alone would say the column *is* sorted that
way, and a column that merely *can* be sorted has to say so too. They darken
under the hand, and take their time about it — a mark that is only offered
says so quietly, and under the pointer it says the heading will answer. The
one in force keeps its own colour: the hand has nothing to add to a column
already sorted by. They stand at
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

The word and the mark keep `sizeXXS` between them, the same breath the sort
carets take, so a heading aligned to the end does not run into the funnel.

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

### Choices with choices under them

A `TableFilter` can carry `children`, and then it stands for the ones under it:
picking it picks them all, and it stands half-picked while only some are. The
column is asked about the leaves, never about the branch, so an `onFilter`
never has to know the choices were grouped at all — and a branch needs no
value of its own.

```dart
filters: const [
  TableFilter('Joe', 'Joe'),
  TableFilter('Warm', null, children: [
    TableFilter('Red', 'red'),
    TableFilter('Amber', 'amber'),
  ]),
]
```

How they are laid out is a separate question, since the same grouped choices
read either way: `filterMode` is `TableFilterMode.menu` by default, where a
branch opens beside the panel as every other menu in the kit does, and
`TableFilterMode.tree` puts the whole tree in one panel, each branch opening
in place under it. A tree also offers a line that takes everything at once —
a tree of any depth is a lot of boxes to tick one by one, where a list has its
choices all in view already.

Searching keeps a branch for the sake of the leaf it leads to, and opens it:
hiding the very thing it found would be a strange kind of search. A branch
that matched itself keeps all of its own.

The tree is the kit's own `Tree`, so it opens and shuts the way everything
else does and half-ticks its branches on the same rule. It is told what is
ticked rather than left to work it out, which means a branch whose every leaf
is chosen is named along with them. And it is told how wide to be: a tree
opens and shuts, so it has no one width to be asked for, and the panel is
measured from the widest line it could ever draw. Labels give way with an
ellipsis rather than running off the end of a row, so a measurement that is a
little short costs a few letters and not the layout.

### A panel of your own

`filterPanel` puts your own widget where the menu of choices would be — a
field to search by, a pair of dates, a slider. Its `builder` is handed a
`TableFilterControls`: `chosen`, what the column is narrowing by now; `choose`,
to say what it should be narrowing by; `apply`, to narrow the table by it;
`clear`, to give every row back; and `close`, to shut the panel without
deciding anything.

```dart
TableColumn(
  title: const Text('Name'),
  value: (u) => u.name,
  onFilter: (choice, u) => u.name.toLowerCase().contains(
        (choice! as String).toLowerCase(),
      ),
  filterPanel: TableFilterPanel(
    builder: (context, panel) => Input(
      defaultValue: panel.chosen.firstOrNull as String?,
      onChanged: (typed) => panel.choose([if (typed.isNotEmpty) typed]),
      onSubmitted: (_) => panel.apply(),
    ),
  ),
)
```

A pair rather than a bare builder because where the panel hangs is the panel's
business as much as what is in it. The mark that opens it stands at the far end
of the heading, so a panel that aligned its left edge with the mark would sit
off to the right of its own column; it hangs by its right edge instead, and
`placement` says otherwise where a panel wants something else. It still flips
to stay on screen either way.

`choose` is not `apply`: what the panel gathers is held while it is open and
only reaches the table when `apply` is called, so a half-typed word does not
re-narrow the rows on every keystroke. What is held survives the panel being
rebuilt, as the menu's ticks do.

A panel of your own still has to say what a choice means, since it is free to
hand back anything at all — give the column a `value` to match against, or an
`onFilter`. The panel is drawn on the kit's own ground with its corners and
shadow, and is as wide as it asks to be, so give it a width if what is inside
has no width of its own.

A panel is an ordinary widget tree, overlays included: a `Popover` or a
`Tooltip` inside one opens over the panel without the panel taking that as a
tap outside itself, so a band of ages can explain what it covers where it
stands.

`filterIcon` draws the mark at the head of the column in place of the funnel,
told whether the column is narrowing anything — the one thing the funnel says
that a mark of your own would otherwise have to work out.

```dart
filterIcon: (context, narrowing) => Icon(
  Icons.search,
  size: 14,
  color: narrowing ? token.colorPrimary : null,
)
```

Every cell in a row is sized as tall as the tallest, not merely centred
against it, so a fill covers the row it is in. Centred, a fill drawn inside a
short cell stopped at its own height and left a band of the row bare above and
below — a hovered row with one wrapping cell was lit in the middle and looked
as if it had a border nobody had asked for.

Filtering happens before sorting: the rows are narrowed,
then put in order. The column widths are measured from the rows as given
rather than as shown, so neither narrowing nor sorting re-measures — a column
keeps its width while you filter, instead of jumping about under the hand.

## A row dressed from outside

`rowStyle` gives one row a ground and words of its own — a row that is
overdue, one nobody is to act on — without the table having to know what
either of those means. It is called for each row on show and may answer null
for the rows that are like every other.

```dart
Table(
  rowStyle: (context, order, index) => order.overdue
      ? TableStyle(color: token.error.bg)
      : null,
  ...
)
```

`TableColumn.cellStyle` says the same thing about one cell, and is answered
the same way. It is the narrower word, so it covers what the row said where
the two disagree and adds to it where they do not — a row marked overdue with
one figure in it marked wrong. Its ground fills the whole cell, padding and
all, which is what a `builder` painting its own ground can never do: a builder
draws *inside* the padding, so it colours the words and not the cell.

What the table says about a row is drawn *over* what these answer: a hand
across it, a tick beside it, a column being sorted by. Those fills are washes
rather than paint, so both read at once — which is why the caller's ground is
the outer one and paints first. The words are merged rather than replaced, so
a style that names a colour and nothing else keeps the rest of the table's —
and a cell's words are merged over its row's, not instead of them.

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

## One thing said once

`columnDefaults` is the house style for the columns: where the cells sit,
whether they cut off, how wide they are, which edge they are held at. Saying
the same thing on each of ten columns is ten places to change it and ten to
get it wrong.

```dart
Table(
  columnDefaults: const TableColumnDefaults(
    align: TableAlign.center,
    ellipsis: true,
  ),
  columns: columns,
  data: rows,
)
```

A column that names the field wins; these are the answers for the ones that
stay quiet. It reaches the leaves of a group as well, since a group holds no
cells of its own. What a column *is* — its value, its title, what it sorts and
filters by — is the column's own business and is not here.

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

## Rows with rows under them

`TableExpandable.children` says where a row's own rows are, and the table is a
tree: a row opens into its children rather than into a panel, each indented a
step further in.

```dart
Table<Person>(
  data: people,
  expandable: TableExpandable(children: (p) => p.reports),
  columns: columns,
)
```

The mark rides in the first column, before the cell's content, rather than in
a column of its own — a tree says where a row sits by where it starts, and a
column of marks off to the side would say it twice. So a tree adds no chevron
column. A row with nothing under it wears no mark and keeps the space one
would have taken, so the words of a childless row line up with its siblings'.

Nothing is nested in the layout: the tree is flattened to the rows on show, so
everything that reckons by rows — the lazy body, the hover, a drag — goes on
reckoning the same way. Narrowing, sorting and paging happen to the rows you
handed over, before the children are let in, so a page is a page of what was
given and a child follows its parent wherever the parent lands.

A row is let in and out rather than appearing: it grows out of nothing the
same way an opened panel does, and shrinks away again when its parent is let
go of — a parent's children stay drawn until the motion is over. This costs
the table its grid: a row of a grid is held to the grid's height and cannot
grow out of nothing, so a tree lays its rows out by hand, as a table with
spanning cells or draggable rows already does. On a `scroll.y` body the rows
arrive without the reveal, for the same reason a panel needs its height named
— a row is found by counting what stands before it, and something growing
cannot be counted.

Picking a row of a tree picks everything under it — however deep, and whether
or not those rows are on show, since a box on a branch is a shorthand for what
is inside it and would otherwise mean one thing open and another closed. A row
with some but not all of its own picked stands half-picked, and one whose
every row is picked is picked itself. `TableSelection.checkStrictly` leaves
every row to answer for itself instead. A row that cannot be picked is passed
over, and a branch above it still counts as whole once every row that *could*
be taken has been.

`indentSize` is how far each step goes, falling back to the `indentSize`
token. `builder` and `children` are the two things a row can open into, and
one of them has to be named.

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

## Borders you can drag

`columnsResizable` puts a grip on each column's trailing border. Dragging it
changes **that column** and nothing else: the table grows or shrinks by what
the column gained or lost, rather than taking it from the neighbour. A table
of many columns where every drag robbed the one beside it would be a puzzle
rather than a table.

A column may say `resizable` for itself — true to join in where the table
says nothing, false to stand out of a table that says yes. A group has no
border of its own to drag, and neither has a column with a `flex`, which is a
share rather than a width.

How far in it may be dragged is the column's `minWidth`, or the
`columnMinWidth` token where it names none. `onColumnResized` is word of what
happened — which column, and how wide it is now — with the column named by
its place among the ones you listed, as a sort and a filter are. The table
keeps the width itself, as it keeps an order a drag has left.

Two things worth knowing. The grip is a strip along the inside of the border,
`resizeHandleWidth` wide, rather than one straddling it: a `Stack` hit-tests
only what lies within it, so a grip hanging half over the border would be half
a grip nobody could take hold of. And it claims the pointer the moment it
arrives, because a table that scrolls sideways would otherwise take that
pointer for a scroll — measured, and the border did not move at all.

A width asked for is the width drawn only where the table is not stretching
its columns to fill its box. Give it `TableScroll.toContent()`, or more
columns than fit, and a drag means what it says; in a table with room to spare
the columns are scaled up to fill it, and a dragged width is a share of that.

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

In a bordered table the rule between two columns is hung on the cell rather
than drawn by the grid, so it travels with the column it divides: a carried
column takes its rule along and the gap it opens is ruled off like any other.
Only where a drag can happen — elsewhere the grid draws one line down the
table rather than one per cell.

Which column goes without a rule is decided by where a column *appears* to
stand rather than where it is laid out: only the painting moves during a drag,
so the last column of the layout can be sitting in the middle, and it would
take its blank edge there with it.

## A page that reads the other way

Everything the table lays out follows the direction the page reads. The first
column is the one against the leading edge, which is the right in a mirrored
layout; `TableAlign.start` and `TableAlign.end` are the near and far edges
rather than the left and the right; the marks a heading carries stand at its
trailing edge, and the panel a funnel opens hangs by that same edge, so it
still lies under its own column. A column held with `TableColumnFixed.start`
is held against the leading edge and casts its shade over what passes on the
far side of it.

A row or a heading carried in the hand is drawn the way the table was: it
travels in the overlay, which knows nothing of the table it came from, so it
is told.

The rows themselves are laid out from the leading edge and mirrored by the
viewport, so there is one reckoning rather than two kept in step. The two
places that turn that reckoning back into pixels are told about the page by
hand: the shade, which is painted on the canvas rather than laid out, and the
question a drag asks about which column lies under the finger.

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

## What it says out loud

Every heading says it is one, so a reader tells the heading from the rows
under it without having to work that out from the wording. A heading that
sorts also answers as a button and carries the state the carets draw — sorted
ascending, sorted descending, or not sorted — since a picture says nothing to
somebody who cannot see it.

The marks beside the words are their own things, reachable one at a time: the
funnel is named apart from the heading it stands in, because tapping the two
does different things, and it says whether it is narrowing anything. The mark
that opens a row is named for what it will do rather than for what it is — a
plus tells a reader nothing.

The boxes in the selection column say which row they take and the one at the
head says it takes everything; both say whether they are ticked, and the head
one says when it is only partly. That much comes from `Checkbox` and `Radio`
themselves, which now carry their own state, so it holds wherever else in the
kit they are used.

Not here yet: the keyboard. Nothing in the kit is reachable by tab — `Button`
is a bare gesture detector — so a table alone answering to keys would be out
of step with everything around it. It wants doing across the kit at once.

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
| `dragShadow` | `boxShadowSecondary` — under a row or heading being carried |
| `indentSize` | `sizeMD` — each step down a tree of rows |
| `resizeHandleWidth` | `sizeXS` — how wide the strip is that answers a drag on a border |
| `resizeLineColor` | `primary.base` — the line down the border while it is being dragged |
| `rowSortedBg` | `colorFillQuaternary` — the cells of the column being sorted by |
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
| `headerMarkHoverColor` | `colorTextTertiary` — what it darkens to under the hand |
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
