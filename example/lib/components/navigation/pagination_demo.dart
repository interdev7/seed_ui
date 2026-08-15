import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class PaginationDemo extends StatefulWidget {
  const PaginationDemo({super.key});

  @override
  State<PaginationDemo> createState() => _PaginationDemoState();
}

class _PaginationDemoState extends State<PaginationDemo> {
  int _page = 3;
  int _size = 10;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Group(
          'Basic (controlled)',
          Pagination(
            current: _page,
            pageSize: _size,
            total: 235,
            onChange: (page, size) => setState(() {
              _page = page;
              _size = size;
            }),
          ),
        ),
        const Group('Uncontrolled', Pagination(total: 85, defaultCurrent: 1)),
        const Group(
          'Small',
          Pagination(total: 235, size: SoftSize.small, defaultCurrent: 5),
        ),
        const Group(
          'Large',
          Pagination(total: 235, size: SoftSize.large, defaultCurrent: 5),
        ),
        const Group(
          'With size changer & quick jumper',
          Pagination(
            total: 500,
            defaultCurrent: 6,
            showSizeChanger: true,
            showQuickJumper: true,
          ),
        ),
        Group(
          'Show total',
          Pagination(
            total: 235,
            defaultCurrent: 2,
            showTotal: (total, from, to) => Text('$from-$to of $total items'),
          ),
        ),
        const Group(
          'Simple(readOnly = false)',
          Pagination(total: 235, simple: PaginationSimple(), defaultCurrent: 4),
        ),
        const Group(
          'Simple(readOnly = true)',
          Pagination(
            total: 235,
            simple: PaginationSimple(readOnly: true),
            defaultCurrent: 4,
          ),
        ),
        const Group(
          'Disabled',
          Pagination(total: 85, disabled: true, defaultCurrent: 2),
        ),
      ],
    );
  }
}
