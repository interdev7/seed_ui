@Timeout(Duration(minutes: 5))
library;

import 'package:flutter/widgets.dart' hide Form, Table, TableRow;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

import 'harness.dart';

class _Order {
  const _Order(this.ref, this.customer, this.city, this.total, this.status);
  final String ref;
  final String customer;
  final String city;
  final int total;
  final String status;
}

const _orders = [
  _Order('SD-1041', 'Marguerite Yates', 'Lisbon', 1240, 'Paid'),
  _Order('SD-1042', 'Ines Kaminski', 'Kraków', 380, 'Pending'),
  _Order('SD-1043', 'Tomás Rivera', 'Valencia', 2610, 'Paid'),
  _Order('SD-1044', 'Ada Nwosu', 'Lagos', 95, 'Refunded'),
  _Order('SD-1045', 'Jun Watanabe', 'Sapporo', 1875, 'Paid'),
];

void main() {
  testWidgets('table', (tester) async {
    await shoot(
      tester,
      'table',
      size: const Size(700, 340),
      () => Table<_Order>(
        data: _orders,
        rowKey: (o) => o.ref,
        bordered: true,
        pagination: const TablePagination(defaultPageSize: 5, total: 43),
        selection: TableSelection<_Order>(
          defaultSelected: [_orders[2]],
        ),
        columns: [
          TableColumn(
            title: const Text('Order'),
            value: (o) => o.ref,
            width: 100,
            fixed: TableColumnFixed.start,
          ),
          TableColumn(
            title: const Text('Customer'),
            value: (o) => o.customer,
            sorter: (a, b) => a.customer.compareTo(b.customer),
          ),
          TableColumn(
            title: const Text('Total'),
            value: (o) => o.total,
            align: TableAlign.end,
            sorter: (a, b) => a.total.compareTo(b.total),
            summary: (context, rows) => const Text('€6 200'),
          ),
          TableColumn(
            title: const Text('Status'),
            value: (o) => o.status,
            width: 124,
            filters: const [
              TableFilter('Paid', 'Paid'),
              TableFilter('Pending', 'Pending'),
              TableFilter('Refunded', 'Refunded'),
            ],
            onFilter: (value, o) => o.status == value,
            builder: (context, o, i) => Tag(
              color: switch (o.status) {
                'Paid' => TagColor.success,
                'Pending' => TagColor.warning,
                _ => TagColor.defaultColor,
              },
              child: Text(o.status),
            ),
            summary: (context, rows) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  });

  testWidgets('date picker', (tester) async {
    await shoot(
      tester,
      'date_picker',
      size: const Size(560, 380),
      () => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 300,
          child: DatePicker(
            defaultValue: DateTime(2026, 4, 17),
            showToday: true,
            presets: [
              DatePreset.of('Today', () => DateTime(2026, 4, 17)),
              DatePreset.of('In a week', () => DateTime(2026, 4, 24)),
              DatePreset.of('Month end', () => DateTime(2026, 4, 30)),
            ],
          ),
        ),
      ),
      after: (tester) async {
        // The picture is the panel; a closed field says nothing about it.
        await tester.tap(find.byType(DatePicker));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('form', (tester) async {
    await shoot(
      tester,
      'form',
      size: const Size(560, 420),
      () => Form(
        layout: FormLayout.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormItem.text(
              name: 'name',
              label: const Text('Full name'),
              initialValue: 'Marguerite Yates',
              rules: const [FormRule.required()],
            ),
            FormItem.text(
              name: 'email',
              label: const Text('Email'),
              initialValue: 'marguerite@',
              rules: const [FormRule.email()],
            ),
            FormItem.select<String>(
              name: 'plan',
              label: const Text('Plan'),
              initialValue: 'team',
              options: const [
                SelectOption(value: 'solo', label: Text('Solo')),
                SelectOption(value: 'team', label: Text('Team')),
              ],
            ),
            FormItem.toggle(
              name: 'digest',
              label: const Text('Weekly digest'),
              initialValue: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Button(
                  color: ButtonColor.primary,
                  variant: ButtonVariant.solid,
                  onPressed: () {},
                  child: const Text('Save changes'),
                ),
                const SizedBox(width: 8),
                Button(onPressed: () {}, child: const Text('Cancel')),
              ],
            ),
          ],
        ),
      ),
    );
  });

  testWidgets('slider', (tester) async {
    await shoot(
      tester,
      'slider',
      size: const Size(560, 250),
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Slider(
            defaultValue: 62,
            marks: const [
              SliderMark(0, '0°'),
              SliderMark(50, '50°'),
              SliderMark(100, '100°'),
            ],
            zones: const [SliderZone(80, 100)],
            onChanged: (_) {},
          ),
          const SizedBox(height: 34),
          RangeSlider(
            defaultValues: const (25, 70),
            draggableTrack: true,
            onChanged: (_) {},
          ),
          const SizedBox(height: 28),
          MultiRangeSlider(
            defaultValues: const [10, 35, 60, 85],
            onChanged: (_) {},
          ),
        ],
      ),
    );
  });
}
