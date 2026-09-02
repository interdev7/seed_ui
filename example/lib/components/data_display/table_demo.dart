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
  Map<int, List<Object?>> _filters = const {};
  List<Person> _picked = const [];
  bool _radio = false;
  int _page = 1;

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
                onSortChanged: (next) => setState(() => _sort = next),
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
                'rows came in. Name and Age compare their values; City is '
                'told how, and sorts by the last letter. '
                '${_sort == null ? 'Unsorted.' : 'Sorted by column ${_sort!.column}, ${_sort!.order.name}.'}',
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
                selection: const TableSelection<Person>(),
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
              const Text(
                'Narrow by city and the pager counts what is left, not sixty. '
                'Narrow past the page you are on and you land on the last page '
                'there is, never on an empty one. The box at the head takes '
                'the page in front of you, not the whole table.',
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
          'Five hundred rows, sorted',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Person>(
                bordered: true,
                scroll: const TableScroll(y: 240),
                defaultSort: const TableSort(1, TableSortOrder.ascending),
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
