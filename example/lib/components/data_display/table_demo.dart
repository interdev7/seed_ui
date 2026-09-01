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
