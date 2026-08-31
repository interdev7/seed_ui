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
  ControlSize _size = SoftSize.middle;
  bool _bordered = false;
  Person? _tapped;

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
