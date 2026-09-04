import 'package:flutter/material.dart'
    hide
        Table,
        TableRow,
        ThemeData,
        Checkbox,
        Radio,
        RadioGroup,
        Switch,
        Tooltip,
        Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class Person {
  const Person(this.name, this.age, this.city);
  final String name;
  final int age;
  final String city;
}

/// A person with people under them, for a table of trees.
class Report {
  const Report(this.name, this.title, this.under);
  final String name;
  final String title;
  final List<Report> under;
}

const _org = [
  Report('Ann Whitfield', 'Head of everything', [
    Report('Bartholomew Considine', 'Runs the north', [
      Report('Chen Wei', 'Keeps the books', []),
      Report('Dee Okonkwo', 'Keeps the peace', []),
    ]),
    Report('Eve Lindqvist', 'Runs the south', [
      Report('Farid Haddad', 'Keeps the hours', []),
    ]),
  ]),
  Report('Gus Marchetti', 'Answers to nobody', []),
];

const _people = [
  Person('Ann Whitfield', 31, 'Bristol'),
  Person('Bartholomew Considine', 45, 'Galway'),
  Person('Chen Wei', 27, 'Chengdu'),
];

class TableDemo extends StatefulWidget {
  const TableDemo({super.key});

  @override
  State<TableDemo> createState() => _TableDemoState();
}

class _TableDemoState extends State<TableDemo> {
  /// Enough rows to have something to scroll.
  static final _many = [
    for (var i = 0; i < 24; i++)
      Person(
        '${_people[i % _people.length].name} ${i + 1}',
        20 + i,
        _people[i % _people.length].city,
      ),
  ];

  /// Enough rows that building them all would tell.
  static final _crowd = [
    for (var i = 0; i < 500; i++)
      Person(
        '${_people[i % _people.length].name} ${i + 1}',
        20 + i % 50,
        _people[i % _people.length].city,
      ),
  ];

  ControlSize _size = SoftSize.middle;
  bool _bordered = false;
  Person? _tapped;
  TableSort? _sort;
  List<TableSort> _sorts = const [];
  Map<int, List<Object?>> _filters = const {};
  List<Person> _picked = const [];
  List<Person> _paged = const [];
  bool _radio = false;
  int _page = 1;
  List<Report> _staff = const [];
  bool _strictly = false;

  List<TableColumn<Person>> get _columns => [
    // A value is the whole of most columns: no builder, no ceremony.
    TableColumn(title: const Text('Name'), value: (p) => p.name),
    TableColumn(title: const Text('City'), value: (p) => p.city),
    TableColumn(
      title: const Text('Age'),
      // A number reads better against the far edge, and the heading follows
      // it without being told twice.
      align: TableAlign.end,
      value: (p) => p.age,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Group(
          'Say nothing about width',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                columns: _columns,
                data: _people,
                size: _size,
                bordered: _bordered,
                onRowTap: (p, _) => setState(() => _tapped = p),
              ),
              const SizedBox(height: 8),
              Text(
                'Each column is as wide as its widest cell, which is what a '
                'table is expected to do.'
                '${_tapped == null ? '' : '  Tapped: ${_tapped!.name}.'}',
              ),
            ],
          ),
        ),
        Group(
          'Size and border',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Segmented<ControlSize>(
                size: SoftSize.small,
                value: _size,
                options: const [
                  SegmentedOption(value: SoftSize.small, label: 'small'),
                  SegmentedOption(value: SoftSize.middle, label: 'middle'),
                  SegmentedOption(value: SoftSize.large, label: 'large'),
                  SegmentedOption(
                    value: ControlSize.height(64),
                    label: 'height(64)',
                  ),
                ],
                onChanged: (v) => setState(() => _size = v),
              ),
              const SizedBox(height: 8),
              Segmented<bool>(
                size: SoftSize.small,
                value: _bordered,
                options: const [
                  SegmentedOption(value: false, label: 'plain'),
                  SegmentedOption(value: true, label: 'bordered'),
                ],
                onChanged: (v) => setState(() => _bordered = v),
              ),
              const SizedBox(height: 8),
              const Text(
                'Both steer the table above. A preset sets how much padding a '
                'cell carries; a height of your own sets the row outright.',
              ),
            ],
          ),
        ),
        Group(
          'One thing said once for every column',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _people,
                // Said once rather than on each column in turn.
                columnDefaults: const TableColumnDefaults(
                  align: TableAlign.center,
                  ellipsis: true,
                  width: 140,
                ),
                columns: [
                  TableColumn(title: const Text('Name'), value: (p) => p.name),
                  TableColumn(title: const Text('City'), value: (p) => p.city),
                  // This one has an answer of its own, and keeps it.
                  TableColumn(
                    title: const Text('Age'),
                    align: TableAlign.end,
                    value: (p) => p.age,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'columnDefaults is the house style: where the cells sit, '
                'whether they cut off, how wide they are. A column that names '
                'the field wins — Age is against the far edge while the rest '
                'are centred.',
              ),
            ],
          ),
        ),
        Group(
          'What a column keeps to itself',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _people,
                columns: [
                  TableColumn(
                    title: const Text('Name'),
                    // A floor, so a column of short names is still reachable.
                    minWidth: 180,
                    value: (p) => p.name,
                  ),
                  // Kept in the list and left out of the table, so the places
                  // the sorts below are keyed by do not move.
                  TableColumn(
                    title: const Text('City'),
                    hidden: true,
                    value: (p) => p.city,
                  ),
                  TableColumn(
                    title: const Text('Age'),
                    align: TableAlign.end,
                    sortable: true,
                    // Oldest first, and back to the order they came in — a
                    // round of one, where up then down says nothing useful.
                    sortDirections: const [TableSortOrder.descending],
                    // A mark of our own in place of the carets. An icon
                    // rather than an arrow glyph: a typed arrow is a box in
                    // any font that has not got one, and most have not.
                    sortIcon: (context, order) => Icon(
                      switch (order) {
                        TableSortOrder.descending => Icons.arrow_downward,
                        TableSortOrder.ascending => Icons.arrow_upward,
                        null => Icons.unfold_more,
                      },
                      size: 14,
                      color: order == null
                          ? context.softToken.colorTextTertiary
                          : context.softToken.primary.base,
                    ),
                    value: (p) => p.age,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'City is hidden — still the second column, so a sort keyed by '
                'that place goes on meaning it. Name has a floor of its own. '
                'Age goes round one order and back, and draws its own mark.',
              ),
            ],
          ),
        ),
        Group(
          'A row dressed from outside',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _many.take(6).toList(),
                columns: [
                  TableColumn(title: const Text('Name'), value: (p) => p.name),
                  TableColumn(title: const Text('City'), value: (p) => p.city),
                  TableColumn(
                    title: const Text('Age'),
                    align: TableAlign.end,
                    value: (p) => p.age,
                    // One cell rather than the row: the narrower word, and it
                    // fills the cell, padding and all.
                    cellStyle: (context, person, index) => person.age == 23
                        ? TableStyle(
                            color: context.softToken.warning.bg,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                ],
                // The table knows nothing about what makes a row worth
                // marking; this says it from outside.
                rowStyle: (context, person, index) => person.age >= 24
                    ? TableStyle(
                        color: context.softToken.error.bg,
                        textStyle: TextStyle(
                          color: context.softToken.error.textActive,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'rowStyle gives a row a ground and words of its own — a row '
                'that is overdue, or one nobody is to act on. cellStyle says '
                'the same of one cell and is the narrower word: the age of 27 '
                'is marked inside a row that is already marked. Point at one: '
                'what the table says about a row is a wash drawn over both, '
                'so nothing is lost.',
              ),
            ],
          ),
        ),
        Group(
          'A width, and a share of the rest',
          Table<Person>(
            bordered: true,
            data: _people,
            columns: [
              TableColumn(
                title: const Text('Name'),
                width: 120,
                ellipsis: true,
                value: (p) => p.name,
              ),
              TableColumn(
                title: const Text('City'),
                flex: 1,
                value: (p) => p.city,
              ),
              TableColumn(
                title: const Text('Age'),
                flex: 2,
                align: TableAlign.end,
                value: (p) => p.age,
              ),
            ],
          ),
        ),
        Group(
          'A title above and a summary below',
          Table<Person>(
            bordered: true,
            columns: _columns,
            data: _people,
            header: (_, rows) => Text('${rows.length} people'),
            footer: (_, rows) => Text(
              'Average age '
              '${(rows.map((p) => p.age).reduce((a, b) => a + b) / rows.length).round()}',
            ),
          ),
        ),
        Group(
          'A builder where text will not do',
          Table<Person>(
            bordered: true,
            data: _people,
            columns: [
              TableColumn(title: const Text('Name'), value: (p) => p.name),
              TableColumn(
                title: const Text('City'),
                // The value still stands for the cell — a sort will compare
                // the word, not the widget around it.
                value: (p) => p.city,
                builder: (_, p, __) =>
                    Tag(color: TagPreset.processing, child: Text(p.city)),
              ),
            ],
          ),
        ),
        Group(
          'Sorting',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _people,
                onSortChanged: (next) =>
                    setState(() => _sort = next.isEmpty ? null : next.first),
                columns: [
                  // A value is enough: the column knows what to compare.
                  TableColumn(
                    title: const Text('Name'),
                    sortable: true,
                    value: (p) => p.name,
                  ),
                  TableColumn(
                    title: const Text('City'),
                    // Sorted by the last letter, which no comparison of the
                    // words themselves would give.
                    sorter: (a, b) => a.city
                        .substring(a.city.length - 1)
                        .compareTo(b.city.substring(b.city.length - 1)),
                    value: (p) => p.city,
                  ),
                  TableColumn(
                    title: const Text('Age'),
                    sortable: true,
                    align: TableAlign.end,
                    value: (p) => p.age,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap a heading: up, then down, then back to the order the '
                'rows came in. The column being sorted by is marked down its '
                'whole length, not only at its head. Name and Age compare '
                'their values; City is told how, and sorts by the last '
                'letter. '
                '${_sort == null ? 'Unsorted.' : 'Sorted by column ${_sort!.column}, ${_sort!.order.name}.'}',
              ),
            ],
          ),
        ),
        Group(
          'Sorting by more than one column',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _many.take(9).toList(),
                onSortChanged: (next) => setState(() => _sorts = next),
                columns: [
                  // A priority makes a column join what is already in force;
                  // the higher number is compared first.
                  TableColumn(
                    title: const Text('City'),
                    sortable: true,
                    sortPriority: 2,
                    value: (p) => p.city,
                  ),
                  TableColumn(
                    title: const Text('Age'),
                    sortable: true,
                    sortPriority: 1,
                    align: TableAlign.end,
                    value: (p) => p.age,
                  ),
                  // No priority: tapping this one sorts by it alone.
                  TableColumn(
                    title: const Text('Name'),
                    sortable: true,
                    value: (p) => p.name,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap City, then Age: both stay, city first and age within a '
                'city. Tap Name and it sorts by that alone, since it has '
                'nothing to say about ties. '
                '${_sorts.isEmpty ? 'Unsorted.' : 'In force: ${_sorts.map((s) => '${s.column} ${s.order.name}').join(', ')}.'}',
              ),
            ],
          ),
        ),
        Group(
          'A page at a time',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _crowd.take(42).toList(),
                columns: _columns,
                pagination: const TablePagination(
                  defaultPageSize: 5,
                  showSizeChanger: true,
                  pageSizeOptions: [5, 10, 20],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The pager is the kit\'s own Pagination, so everything it can '
                'be told is told the same way. Paging happens after narrowing '
                'and sorting, so a page is a page of what the filters left.',
              ),
            ],
          ),
        ),
        Group(
          'A pager you steer yourself',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _crowd.take(42).toList(),
                columns: _columns,
                pagination: TablePagination(
                  // Told which page to show, so the table shows that and
                  // nothing else; the buttons below do the deciding.
                  page: _page,
                  pageSize: 6,
                  onChanged: (page, _) => setState(() => _page = page),
                  showTotal: (total, from, to) =>
                      Text('$from–$to of $total people'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Button(
                    size: SoftSize.small,
                    onPressed: _page > 1
                        ? () => setState(() => _page -= 1)
                        : null,
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 8),
                  Button(
                    size: SoftSize.small,
                    onPressed: _page < 7
                        ? () => setState(() => _page += 1)
                        : null,
                    child: const Text('On'),
                  ),
                  const SizedBox(width: 12),
                  Text('Page $_page of 7'),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'The page lives outside the table. showTotal draws a word or '
                'two about how many rows there are in all — the rows the '
                'filters left, not the ones on this page.',
              ),
            ],
          ),
        ),
        Group(
          'Where the pager stands',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _many.take(11).toList(),
                columns: _columns,
                pagination: const TablePagination(
                  position: [TablePaginationPosition.topCenter],
                  defaultPageSize: 4,
                ),
              ),
              const SizedBox(height: 16),
              Table<Person>(
                bordered: true,
                data: _many.take(11).toList(),
                columns: _columns,
                pagination: const TablePagination(
                  defaultPageSize: 4,
                  simple: PaginationSimple(),
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 16),
              Table<Person>(
                bordered: true,
                data: _many.take(11).toList(),
                columns: _columns,
                pagination: const TablePagination(
                  defaultPageSize: 4,
                  position: [
                    TablePaginationPosition.topEnd,
                    TablePaginationPosition.bottomEnd,
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'position takes a list, so a long table can carry a pager at '
                'both ends. Each names where it stands and which edge it is '
                'drawn against — the default being under the table, against '
                'the trailing edge. A plain pager is the page it is on and '
                'the two arrows, for somewhere narrow.',
              ),
            ],
          ),
        ),
        Group(
          'Paging what the filters left',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _crowd.take(60).toList(),
                pagination: const TablePagination(defaultPageSize: 5),
                selection: TableSelection<Person>(
                  selected: _paged,
                  onChanged: (rows) => setState(() => _paged = rows),
                  // The box at the head takes the page; these are for what is
                  // wider than that, which nothing else can ask for.
                  selections: [
                    TableSelectionEntry.all<Person>('All sixty'),
                    TableSelectionEntry.invert<Person>('Turn it round'),
                    TableSelectionEntry.none<Person>('None'),
                  ],
                ),
                columns: [
                  TableColumn(
                    title: const Text('Name'),
                    sortable: true,
                    value: (p) => p.name,
                  ),
                  TableColumn(
                    title: const Text('City'),
                    value: (p) => p.city,
                    filters: const [
                      TableFilter('Bristol', 'Bristol'),
                      TableFilter('Galway', 'Galway'),
                      TableFilter('Chengdu', 'Chengdu'),
                    ],
                  ),
                  TableColumn(
                    title: const Text('Age'),
                    sortable: true,
                    align: TableAlign.end,
                    value: (p) => p.age,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Picked: ${_paged.length} of 60.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.softToken.primary.base,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tick the box at the head: five — the page in front of you, '
                'which is what a box in a heading means. Now open the caret '
                'beside it and take All sixty: that is the whole table, and '
                'once a table is paged there is no other way to ask for it. '
                'Turn it round takes the fifty-five you had not.\n\n'
                'Narrow by city and the pager counts what is left.',
              ),
            ],
          ),
        ),
        Group(
          'Back to the top when the rows change',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                // A page of twenty in a body two hundred tall: each page is
                // taller than what you can see of it, so there is something
                // to be halfway down.
                scroll: const TableScroll(y: 200),
                backToTopOnChange: true,
                data: _crowd.take(60).toList(),
                pagination: const TablePagination(defaultPageSize: 20),
                columns: [
                  TableColumn(
                    title: const Text('Name'),
                    sortable: true,
                    value: (p) => p.name,
                  ),
                  TableColumn(
                    title: const Text('Age'),
                    align: TableAlign.end,
                    sortable: true,
                    value: (p) => p.age,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Scroll the rows down to the middle of the page, then turn to '
                'page 2 — you start at its first row, not at whatever row was '
                'under your eyes. Sorting does the same, since the rows under '
                'you are no longer the rows you were reading. Leave it out and '
                'the body stays where you left it.',
              ),
            ],
          ),
        ),
        Group(
          'A pager that knows when to go',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _people,
                columns: _columns,
                pagination: const TablePagination(
                  defaultPageSize: 10,
                  hideOnSinglePage: true,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Three rows and ten to a page: there is only one page, so '
                'hideOnSinglePage leaves the table without a pager at all.',
              ),
            ],
          ),
        ),
        Group(
          'A row that adds up',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _many.take(6).toList(),
                pagination: const TablePagination(defaultPageSize: 4),
                columns: [
                  TableColumn(
                    title: const Text('Name'),
                    value: (p) => p.name,
                    summary: (_, rows) => Text('${rows.length} on this page'),
                  ),
                  TableColumn(title: const Text('City'), value: (p) => p.city),
                  TableColumn(
                    title: const Text('Age'),
                    align: TableAlign.end,
                    value: (p) => p.age,
                    summary: (_, rows) =>
                        Text('${rows.fold<int>(0, (n, p) => n + p.age)}'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Each column says what it adds up, so there is no list of '
                'cells to keep in step with the columns. City says nothing '
                'and leaves its place empty. Turn the page: the row sums what '
                'is on show, not everything handed over.',
              ),
            ],
          ),
        ),
        Group(
          'Cells that span',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _many.take(6).toList(),
                columns: [
                  TableColumn(
                    title: const Text('Name'),
                    value: (p) => p.name,
                    // Runs across the city beside it, on the first row and
                    // again further down.
                    span: (_, p, i) => i == 0 || i == 3
                        ? const TableCellSpan(columns: 2)
                        : const TableCellSpan(),
                  ),
                  TableColumn(title: const Text('City'), value: (p) => p.city),
                  TableColumn(
                    title: const Text('Age'),
                    align: TableAlign.end,
                    value: (p) => p.age,
                    // Three rows as one cell, then two more further down.
                    span: (_, p, i) => switch (i) {
                      1 => const TableCellSpan(rows: 3),
                      4 => const TableCellSpan(rows: 2),
                      _ => const TableCellSpan(),
                    },
                  ),
                  TableColumn(
                    title: const Text('Note'),
                    value: (p) => 'about ${p.city}',
                    // Two rows *and* two columns at once, taking the last
                    // column with it.
                    span: (_, p, i) => i == 2
                        ? const TableCellSpan(columns: 2, rows: 2)
                        : const TableCellSpan(),
                  ),
                  TableColumn(
                    title: const Text('Last'),
                    value: (p) => 'x${p.age}',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'A cell that spans covers its neighbours, and those are simply '
                'not drawn — the table works out which, so nothing has to '
                'return a nought. Note on the third row takes two columns and '
                'two rows at once. Point at any cell: what lights up is that '
                'cell and the rows it stands over, not the rows beside it.',
              ),
            ],
          ),
        ),
        Group(
          'Columns under one head',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _people,
                columns: [
                  // A column with children heads them and holds no cells of
                  // its own; only the leaves have values.
                  TableColumn(
                    title: const Text('Who'),
                    children: [
                      TableColumn(
                        title: const Text('Name'),
                        sortable: true,
                        value: (p) => p.name,
                      ),
                      TableColumn(
                        title: const Text('City'),
                        value: (p) => p.city,
                      ),
                    ],
                  ),
                  TableColumn(
                    title: const Text('Age'),
                    sortable: true,
                    align: TableAlign.end,
                    value: (p) => p.age,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Age heads nothing, so it stands the whole depth beside the '
                'group. Groups nest as deep as you like, and a sort or a '
                'filter belongs to a leaf — a group has nothing to order.',
              ),
            ],
          ),
        ),
        Group(
          'Rows that open',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _people,
                columns: _columns,
                expandable: TableExpandable<Person>(
                  // The youngest has nothing more to say, so no chevron.
                  expandable: (p) => p.age > 27,
                  builder: (_, p, __) => Text(
                    '${p.name} is ${p.age} and lives in ${p.city}. '
                    'The panel spans the whole table, not one column.',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The panel sits between two grids, since a table cannot span a '
                'row across its columns. Both grids are handed the same '
                'widths, so nothing shifts as a row opens.',
              ),
            ],
          ),
        ),
        Group(
          'Rows with rows under them',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Report>(
                bordered: true,
                data: _org,
                expandable: TableExpandable<Report>(
                  // Rows rather than a panel: a row opens into its own
                  // children, indented under it.
                  children: (r) => r.under,
                ),
                columns: [
                  TableColumn(title: const Text('Name'), value: (r) => r.name),
                  TableColumn(title: const Text('Does'), value: (r) => r.title),
                  TableColumn(
                    title: const Text('Under them'),
                    align: TableAlign.end,
                    value: (r) => r.under.length,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'The mark rides in the first column, before the words, and '
                'each step down is a step in. A row with nobody under it '
                'wears no mark and keeps the space one would take, so the '
                'names line up. Nothing is nested in the layout: the tree is '
                'flattened to the rows on show.',
              ),
            ],
          ),
        ),
        Group(
          'A tree that is picked from and paged',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Report>(
                bordered: true,
                data: _org,
                selection: TableSelection<Report>(
                  checkStrictly: _strictly,
                  selected: _staff,
                  onChanged: (rows) => setState(() => _staff = rows),
                ),
                expandable: TableExpandable<Report>(
                  children: (r) => r.under,
                  // A step of your own, where the default is too tight or too
                  // wide for the words in the column.
                  indentSize: 32,
                ),
                columns: [
                  TableColumn(title: const Text('Name'), value: (r) => r.name),
                  TableColumn(title: const Text('Does'), value: (r) => r.title),
                ],
              ),
              const SizedBox(height: 8),
              Segmented<bool>(
                size: SoftSize.small,
                value: _strictly,
                options: const [
                  SegmentedOption(value: false, label: 'with their own'),
                  SegmentedOption(value: true, label: 'checkStrictly'),
                ],
                onChanged: (v) => setState(() {
                  _strictly = v;
                  _staff = const [];
                }),
              ),
              const SizedBox(height: 8),
              Text(
                'Picking a branch picks everyone under it, however deep and '
                'whether or not they are on show, and a branch with some of '
                'its own picked stands half-picked. checkStrictly leaves '
                'every row to answer for itself. '
                '${_staff.isEmpty ? 'Nobody picked.' : 'Picked: ${_staff.map((r) => r.name.split(' ').first).join(', ')}.'}',
              ),
            ],
          ),
        ),
        Group(
          'A panel that is told how tall it is',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                scroll: const TableScroll(y: 240),
                data: _crowd.take(200).toList(),
                columns: _columns,
                expandable: TableExpandable<Person>(
                  // Named, so the body stays lazy: a row is found by counting
                  // what stands before it, and a panel of any height cannot
                  // be counted.
                  panelHeight: 56,
                  builder: (_, p, __) =>
                      Text('${p.name} is ${p.age} and lives in ${p.city}.'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Two hundred rows and every panel the same height: only the '
                'rows on screen are built. Leave panelHeight out and a panel '
                'is as tall as what is in it, at the cost of building every '
                'row.',
              ),
            ],
          ),
        ),
        Group(
          'A row that opens by being tapped',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _people,
                columns: _columns,
                expandable: TableExpandable<Person>(
                  byRowTap: true,
                  // No column of chevrons: the whole row is the mark.
                  showColumn: false,
                  builder: (_, p, __) => Text('More about ${p.name}.'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'byRowTap opens a row from anywhere on it, and showColumn: '
                'false takes the chevrons away — worth pairing, since a '
                'chevron that is not the only way in is one the reader has to '
                'aim at for nothing.',
              ),
            ],
          ),
        ),
        Group(
          'Picking rows',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _people,
                selection: TableSelection<Person>(
                  mode: _radio
                      ? TableSelectionMode.radio
                      : TableSelectionMode.checkbox,
                  selected: _picked,
                  onChanged: (rows) => setState(() => _picked = rows),
                  // The youngest cannot be picked, to show a row that is
                  // barred rather than merely unpicked.
                  selectable: (p) => p.age > 27,
                ),
                columns: _columns,
              ),
              const SizedBox(height: 8),
              Segmented<bool>(
                size: SoftSize.small,
                value: _radio,
                options: const [
                  SegmentedOption(value: false, label: 'checkbox'),
                  SegmentedOption(value: true, label: 'radio'),
                ],
                onChanged: (v) => setState(() {
                  _radio = v;
                  _picked = const [];
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _picked.isEmpty
                    ? 'Nothing picked. The box at the head takes every row on '
                          'show, passing over any that cannot be picked.'
                    : 'Picked: ${_picked.map((p) => p.name).join(', ')}.',
              ),
            ],
          ),
        ),
        Group(
          'Filtering',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _many.take(8).toList(),
                onFiltersChanged: (next) => setState(() => _filters = next),
                columns: [
                  TableColumn(
                    title: const Text('Name'),
                    value: (p) => p.name,
                    // The choice is matched against the value where nothing
                    // else is said; here it is a first letter, so it is.
                    onFilter: (choice, p) =>
                        p.name.startsWith(choice! as String),
                    filters: const [
                      TableFilter('A…', 'Ann'),
                      TableFilter('B…', 'Bar'),
                      TableFilter('C…', 'Che'),
                    ],
                  ),
                  TableColumn(
                    title: const Text('City'),
                    sortable: true,
                    value: (p) => p.city,
                    // A field above the choices, worth it once there are more
                    // of them than a reader will scan.
                    filterSearch: true,
                    filters: const [
                      TableFilter('Bristol', 'Bristol'),
                      TableFilter('Galway', 'Galway'),
                      TableFilter('Chengdu', 'Chengdu'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'A funnel opens a menu of choices. Within one column they are '
                'alternatives; across columns a row has to answer every one. '
                'City matches its value; Name is told what a choice means and '
                'matches a first letter. '
                '${_filters.isEmpty ? 'Nothing chosen.' : 'In force: $_filters.'}',
              ),
            ],
          ),
        ),
        Group(
          'Choices with choices under them',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _many.take(8).toList(),
                columns: [
                  TableColumn(
                    title: const Text('Name'),
                    value: (p) => p.name,
                    onFilter: (choice, p) =>
                        p.name.startsWith(choice! as String),
                    // A tree in one panel: each branch opens in place, and
                    // the search keeps whatever leads to what it found.
                    filterMode: TableFilterMode.tree,
                    filterSearch: true,
                    filters: const [
                      TableFilter('Chen', 'Che'),
                      TableFilter(
                        'Either of the others',
                        null,
                        children: [
                          TableFilter('Ann', 'Ann'),
                          TableFilter('Bartholomew', 'Bar'),
                        ],
                      ),
                    ],
                  ),
                  TableColumn(
                    title: const Text('City'),
                    value: (p) => p.city,
                    // The same choices, laid out as a list: a branch opens
                    // beside the menu rather than inside it.
                    filters: const [
                      TableFilter('Bristol', 'Bristol'),
                      TableFilter(
                        'Elsewhere',
                        null,
                        children: [
                          TableFilter('Galway', 'Galway'),
                          TableFilter('Chengdu', 'Chengdu'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'A choice with children stands for the ones under it: picking '
                'it picks them all, and it stands half-picked while only some '
                'are. The column is asked about the leaves, so an onFilter '
                'never has to know the choices were grouped. filterMode says '
                'how they are laid out — Name is a tree in one panel, City a '
                'list whose branch opens beside it.',
              ),
            ],
          ),
        ),
        Group(
          'A filter panel of your own',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _many.take(8).toList(),
                columns: [
                  TableColumn(
                    title: const Text('Name'),
                    value: (p) => p.name,
                    onFilter: (choice, p) => p.name.toLowerCase().contains(
                      (choice! as String).toLowerCase(),
                    ),
                    // A word to search by has no list of choices to offer, so
                    // the panel is what makes this column filterable at all.
                    filterPanel: TableFilterPanel(
                      builder: (context, panel) => SizedBox(
                        width: 200,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Input(
                                size: SoftSize.small,
                                defaultValue:
                                    panel.chosen.firstOrNull as String?,
                                placeholder: 'Search a name',
                                // What is gathered is held while the panel is
                                // open; only apply reaches the table.
                                onChanged: (typed) =>
                                    panel.choose([if (typed.isNotEmpty) typed]),
                                onSubmitted: (_) => panel.apply(),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Button(
                                      size: SoftSize.small,
                                      color: ButtonColor.primary,
                                      onPressed: panel.apply,
                                      child: const Text('Search'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Button(
                                      size: SoftSize.small,
                                      onPressed: panel.clear,
                                      child: const Text('Reset'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    filterIcon: (context, narrowing) => Icon(
                      Icons.search,
                      size: 14,
                      color: narrowing
                          ? context.softToken.primary.base
                          : context.softToken.colorTextTertiary,
                    ),
                  ),
                  TableColumn(title: const Text('City'), value: (p) => p.city),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'filterPanel puts your own widget where the menu would be, '
                'hung by its right edge so it sits under its own column — '
                'placement says otherwise. filterIcon puts your own mark where '
                'the funnel would be, told whether the column is narrowing '
                'anything.',
              ),
            ],
          ),
        ),
        Group(
          'A filter panel with a popover in it',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _many.take(8).toList(),
                columns: [
                  TableColumn(title: const Text('Name'), value: (p) => p.name),
                  TableColumn(
                    title: const Text('Age'),
                    align: TableAlign.end,
                    value: (p) => p.age,
                    // The choice is a band, not a value, so the column is
                    // told what one means.
                    onFilter: (choice, p) {
                      final band = choice! as String;
                      return switch (band) {
                        'young' => p.age < 30,
                        'middle' => p.age >= 30 && p.age < 40,
                        _ => p.age >= 40,
                      };
                    },
                    filterPanel: TableFilterPanel(
                      builder: (context, panel) {
                        // A panel of your own is a widget tree like any other,
                        // overlays included: a popover opens above the panel
                        // without closing it.
                        Widget band(
                          String key,
                          String label,
                          String explains,
                        ) => Popover(
                          placement: PopoverPlacement.right,
                          title: Text(label),
                          content: Text(explains),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Checkbox(
                              checked: panel.chosen.contains(key),
                              label: Text(label),
                              onChanged: (on) => panel.choose([
                                ...panel.chosen.where((c) => c != key),
                                if (on) key,
                              ]),
                            ),
                          ),
                        );

                        return SizedBox(
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                band('young', 'Under 30', 'The youngest rows.'),
                                band(
                                  'middle',
                                  '30 to 39',
                                  'Thirty up to forty.',
                                ),
                                band('older', '40 and up', 'Forty and beyond.'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Button(
                                        size: SoftSize.small,
                                        color: ButtonColor.primary,
                                        onPressed: panel.apply,
                                        child: const Text('Apply'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Button(
                                        size: SoftSize.small,
                                        onPressed: panel.clear,
                                        child: const Text('Reset'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Hover a band to see what it covers: the popover opens over '
                'the panel and the panel stays put, since a panel of your own '
                'is an ordinary widget tree and an overlay inside one is '
                'ordinary too.',
              ),
            ],
          ),
        ),
        Group(
          'Five hundred rows, sorted',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                scroll: const TableScroll(y: 240),
                defaultSort: const [TableSort(1, TableSortOrder.ascending)],
                data: _crowd,
                columns: [
                  TableColumn(
                    title: const Text('Name'),
                    sortable: true,
                    value: (p) => p.name,
                  ),
                  TableColumn(
                    title: const Text('Age'),
                    sortable: true,
                    align: TableAlign.end,
                    value: (p) => p.age,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Sorting and building only what is on screen are the same '
                'table: the rows are put in order once, and the ones you can '
                'see are built from that.',
              ),
            ],
          ),
        ),
        Group(
          'A body that scrolls, and a heading that does not',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                scroll: const TableScroll(y: 200),
                columns: _columns,
                data: _many,
              ),
              const SizedBox(height: 8),
              const Text(
                'Give the body a height and the heading stops travelling with '
                'the rows — and only the rows on screen are built. The '
                'columns still fit their content: the widths are worked out '
                'from the text before a cell exists.',
              ),
            ],
          ),
        ),
        Group(
          'Five hundred rows',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                scroll: const TableScroll(y: 240),
                columns: _columns,
                data: _crowd,
              ),
              const SizedBox(height: 8),
              const Text(
                'Five hundred rows cost what forty do: the ones off screen '
                'are never built. Scroll to the end and back — the widths do '
                'not shift, because they were settled from every row before '
                'the first one was drawn.',
              ),
            ],
          ),
        ),
        Group(
          'Wider than its box',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                scroll: const TableScroll(x: 900, y: 200),
                columns: [
                  ..._columns,
                  TableColumn(
                    title: const Text('Note'),
                    value: (p) => 'about ${p.name}',
                  ),
                ],
                data: _many,
              ),
              const SizedBox(height: 8),
              const Text(
                'Drag across: the heading goes with the rows, because both '
                'sit in the same viewport rather than in one each kept in '
                'step by hand.',
              ),
            ],
          ),
        ),
        Group(
          'As wide as it needs',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                // No number: the columns take the width of what is in them.
                scroll: const TableScroll.toContent(),
                data: _people,
                columns: [
                  ..._columns,
                  for (var i = 0; i < 4; i++)
                    TableColumn(
                      title: Text('Note $i'),
                      value: (p) => 'about ${p.name}, note $i',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Drag across. Nothing is squeezed to fit and nothing is '
                'stretched to fill: each column is as wide as its widest '
                'cell, and the table scrolls when that is wider than the box.',
              ),
            ],
          ),
        ),
        Group(
          'Columns that stay put',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                scroll: const TableScroll(x: 1100, y: 220),
                columns: [
                  TableColumn(
                    title: const Text('Name'),
                    width: 160,
                    fixed: TableColumnFixed.start,
                    ellipsis: true,
                    value: (p) => p.name,
                  ),
                  for (var i = 0; i < 15; i++)
                    TableColumn(
                      title: Text('Note $i'),
                      value: (p) => '${p.city} $i',
                    ),
                  TableColumn(
                    title: const Text('Age'),
                    width: 80,
                    fixed: TableColumnFixed.end,
                    align: TableAlign.end,
                    value: (p) => p.age,
                  ),
                ],
                data: _many,
              ),
              const SizedBox(height: 8),
              const Text(
                'Drag across: the name and the age stay while the notes go '
                'past. A pinned column needs a width, and pinning holds every '
                'row to one height — three panes laid out apart can only stay '
                'level on a height they all know.',
              ),
            ],
          ),
        ),
        Group(
          'Held columns that stack',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                scroll: const TableScroll(x: 1600, y: 220),
                data: _many,
                columns: [
                  TableColumn(
                    title: const Text('Name'),
                    width: 160,
                    fixed: TableColumnFixed.start,
                    ellipsis: true,
                    value: (p) => p.name,
                  ),
                  // Loose, and standing between two held ones.
                  TableColumn(
                    title: const Text('Age'),
                    width: 90,
                    align: TableAlign.end,
                    value: (p) => p.age,
                  ),
                  TableColumn(
                    title: const Text('City'),
                    width: 120,
                    fixed: TableColumnFixed.start,
                    value: (p) => p.city,
                  ),
                  for (var i = 0; i < 10; i++)
                    TableColumn(
                      title: Text('Note $i'),
                      width: 120,
                      value: (p) => '${p.city} $i',
                    ),
                  TableColumn(
                    title: const Text('Act'),
                    width: 90,
                    fixed: TableColumnFixed.end,
                    value: (p) => 'do',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Drag across. Name and City are both held at the leading edge '
                'with a loose Age between them: the order you wrote is the '
                'order you see, Age slides under, and City comes to rest right '
                'behind Name rather than being moved there from the start.',
              ),
            ],
          ),
        ),
        Group(
          'A heading held in view',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                // No scroll.y: the rows are part of the page, and the heading
                // is held against the top as the page goes past.
                sticky: const TableSticky(),
                data: _many,
                columns: _columns,
              ),
              const SizedBox(height: 8),
              const Text(
                'Scroll the page: the heading stops at the top and the rows '
                'carry on under it. It keeps its place in the layout — it is '
                'only drawn lower down — so nothing shifts. offsetHeader '
                'holds it below a bar of your own.',
              ),
            ],
          ),
        ),
        Group(
          'Borders you can drag',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                // As wide as its columns: a table with room to spare scales
                // them up to fill it, and then a width asked for is not the
                // width drawn.
                scroll: const TableScroll.toContent(),
                data: _people,
                columnsResizable: true,
                onColumnResized: (column, width) =>
                    message.success('Column $column is ${width.round()} wide'),
                columns: [
                  TableColumn(
                    title: const Text('Name'),
                    width: 220,
                    ellipsis: true,
                    // Its own floor: drag as far in as you like, it stops
                    // here.
                    minWidth: 120,
                    value: (p) => p.name,
                  ),
                  TableColumn(
                    title: const Text('City'),
                    width: 160,
                    value: (p) => p.city,
                  ),
                  TableColumn(
                    title: const Text('Age'),
                    width: 100,
                    align: TableAlign.end,
                    // This one keeps its width: a column of short numbers has
                    // no business being stretched.
                    // resizable: false,
                    value: (p) => p.age,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Take hold of a border and drag: only that column changes, '
                'and the table grows or shrinks by what it gained or lost. '
                'Name stops at its own floor of 120; Age has no grip at all.',
              ),
            ],
          ),
        ),
        Group(
          'Columns you can move',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _people,
                columns: _columns,
                // The table does the moving; the callback is word of it.
                columnsDraggable: true,
                onColumnsReordered: (from, to) =>
                    message.success('Column $from moved to $to'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Drag a heading onto another: the table moves the column '
                'itself and keeps the order you leave it in. A line shows '
                'where it will land. The callback is only word of what '
                'happened — nothing has to be written to make it work.',
              ),
            ],
          ),
        ),
        Group(
          'Rows you can move',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                data: _many.take(6).toList(),
                columns: _columns,
                rowsDraggable: true,
                onRowsReordered: (from, to) =>
                    message.success('Row $from moved to $to'),
              ),
              const SizedBox(height: 8),
              const Text(
                'The same mechanics as the columns: pick a row up and the '
                'others slide out of the way, each by exactly a row. The '
                'table keeps the order you leave it in. The order a drag '
                'changes is the one the rows came in, so a sort still has the '
                'last word.',
              ),
            ],
          ),
        ),
        Group(
          'Nothing to show',
          Table<Person>(bordered: true, columns: _columns, data: const []),
        ),
        Group(
          'Loading',
          Table<Person>(
            bordered: true,
            columns: _columns,
            data: _people,
            loading: true,
          ),
        ),
      ],
    );
  }
}
