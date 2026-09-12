// Draws the rest of the kit so it can be looked at.
//
// Four screenshots found five defects that sixteen hundred tests had not: a
// font that reached half the words, a tag that overflowed its cell, a form of
// ragged widths, three controls wearing a popover's shadow. A test asks a
// question somebody thought of; a picture answers ones nobody did.
//
//     flutter test tool/screenshots/audit_test.dart
//     open tool/screenshots/audit
//
// Nothing here ships: `tool/` is in .pubignore, and these are not assertions.
@Timeout(Duration(minutes: 5))
library;

import 'package:flutter/widgets.dart' hide Form, RadioGroup, Table, TableRow;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

import 'harness.dart';

/// A labelled row of specimens.
Widget _group(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 6),
        Wrap(spacing: 12, runSpacing: 12, children: children),
        const SizedBox(height: 18),
      ],
    );

void main() {
  setUpAll(() => outDir = 'tool/screenshots/audit');

  testWidgets('feedback', (tester) async {
    await shoot(
      tester,
      'feedback',
      size: const Size(620, 900),
      settle: false,
      () => ListView(
        children: [
          _group('Alert', [
            const SizedBox(
              width: 560,
              child: Alert(
                message: Text('Your seat is held for ten minutes'),
                type: StatusType.info,
                closable: true,
              ),
            ),
            const SizedBox(
              width: 560,
              child: Alert(
                message: Text('The card was declined'),
                description: Text('Try another, or pay on collection.'),
                type: StatusType.error,
                showIcon: true,
              ),
            ),
          ]),
          _group('Progress', [
            const SizedBox(width: 260, child: Progress(percent: 0.64)),
            const SizedBox(
              width: 260,
              child: Progress(percent: 1, status: StatusType.success),
            ),
            const SizedBox(
              width: 90,
              height: 90,
              child: Progress(percent: 0.72, type: ProgressType.circle),
            ),
          ]),
          _group('Spin', [
            const Spin(),
            const Spin(size: SoftSize.large),
            const SizedBox(width: 120, height: 60, child: Spin(percent: 0.4)),
          ]),
          _group('Result', [
            const SizedBox(
              width: 560,
              child: Result(
                status: StatusType.success,
                title: Text('Order placed'),
                subtitle: Text('A receipt is on its way to you.'),
              ),
            ),
          ]),
          _group('Empty', [const SizedBox(width: 260, child: Empty())]),
        ],
      ),
    );
  });

  testWidgets('data entry', (tester) async {
    await shoot(
      tester,
      'data_entry',
      size: const Size(620, 560),
      () => ListView(
        children: [
          _group('Input', [
            const SizedBox(width: 260, child: Input(placeholder: 'Name')),
            const SizedBox(
              width: 260,
              child: Input(
                placeholder: 'Password',
                password: PasswordConfig(),
              ),
            ),
            const SizedBox(
              width: 260,
              child: Input(
                placeholder: 'Short',
                status: InputStatus.error,
                allowClear: true,
              ),
            ),
            const SizedBox(
              width: 260,
              child: Input(
                placeholder: 'Notes',
                count: CountConfig(max: 40),
              ),
            ),
          ]),
          _group('InputNumber', [
            const SizedBox(width: 200, child: InputNumber(value: 42)),
            const SizedBox(
              width: 200,
              child: InputNumber(value: 3.5, mode: InputNumberMode.spinner),
            ),
          ]),
          _group('Checkbox and Radio', [
            const Checkbox(defaultChecked: true, label: Text('Remember me')),
            const Checkbox(indeterminate: true, label: Text('Some of them')),
            RadioGroup<String>(
              defaultValue: 'card',
              options: const [
                RadioOption(value: 'card', label: Text('Card')),
                RadioOption(value: 'cash', label: Text('Cash')),
              ],
              onChanged: (_) {},
            ),
          ]),
          _group('Tag', [
            const Tag(child: Text('default')),
            const Tag(color: TagColor.success, child: Text('paid')),
            const Tag(closable: true, child: Text('closable')),
            const CheckableTag(checked: true, child: Text('checked')),
          ]),
          _group('Upload', [
            const SizedBox(width: 300, child: Upload<String>(items: [])),
          ]),
        ],
      ),
    );
  });

  testWidgets('navigation', (tester) async {
    await shoot(
      tester,
      'navigation',
      size: const Size(620, 560),
      () => ListView(
        children: [
          _group('Tabs', [
            const SizedBox(
              width: 560,
              height: 90,
              child: Tabs(
                defaultActiveKey: 'one',
                items: [
                  TabItem(key: 'one', label: Text('Summary')),
                  TabItem(key: 'two', label: Text('Payments')),
                  TabItem(key: 'three', label: Text('History')),
                ],
              ),
            ),
          ]),
          _group('Steps', [
            const SizedBox(
              width: 560,
              child: Steps(
                current: 1,
                items: [
                  StepItem(title: Text('Basket')),
                  StepItem(
                      title: Text('Pay'), subtitle: Text('card ending 04')),
                  StepItem(title: Text('Collect')),
                ],
              ),
            ),
          ]),
          _group('Pagination', [
            const SizedBox(width: 560, child: Pagination(total: 96)),
          ]),
          _group('Breadcrumb-ish: Segmented and Compact', [
            Segmented<String>(
              value: 'day',
              options: const [
                SegmentedOption(value: 'day', label: 'Day'),
                SegmentedOption(value: 'week', label: 'Week'),
                SegmentedOption(value: 'month', label: 'Month'),
              ],
              onChanged: (_) {},
            ),
            SizedBox(
              width: 300,
              child: Compact(
                children: [
                  const Expanded(child: Input(placeholder: 'Search')),
                  Button(
                    color: ButtonColor.primary,
                    variant: ButtonVariant.solid,
                    onPressed: () {},
                    child: const Text('Go'),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  });

  testWidgets('data display', (tester) async {
    await shoot(
      tester,
      'data_display',
      size: const Size(620, 700),
      settle: false,
      () => ListView(
        children: [
          _group('Avatar and Badge', [
            const Avatar(child: Text('MY')),
            const Avatar(shape: AvatarShape.square, child: Text('IK')),
            const AvatarGroup(
              maxCount: 2,
              children: [
                Avatar(child: Text('A')),
                Avatar(child: Text('B')),
                Avatar(child: Text('C')),
              ],
            ),
            const Badge(count: 8, child: Avatar(child: Text('JW'))),
            const Badge(dot: true, child: Avatar(child: Text('AN'))),
            const Badge(status: BadgeStatus.processing, text: Text('running')),
          ]),
          _group('Card', [
            const SizedBox(
              width: 260,
              child: Card(
                title: Text('Sales'),
                extra: Text('week'),
                child: Text('£4,912 from 63 orders'),
              ),
            ),
            const SizedBox(
              width: 260,
              child: Card(
                hoverable: true,
                child: CardMeta(
                  avatar: Avatar(child: Text('TR')),
                  title: Text('Tomás Rivera'),
                  description: Text('Valencia'),
                ),
              ),
            ),
          ]),
          _group('Collapse', [
            const SizedBox(
              width: 560,
              child: Collapse(
                defaultActiveKeys: ['one'],
                items: [
                  CollapseItem(
                    key: 'one',
                    label: Text('What is held'),
                    content: Text('The seat, for ten minutes.'),
                  ),
                  CollapseItem(key: 'two', label: Text('What is not')),
                ],
              ),
            ),
          ]),
          _group('Countdown and Spinner', [
            Countdown(
              target:
                  DateTime.now().add(const Duration(minutes: 9, seconds: 58)),
            ),
            const Spinner(size: 20, color: Color(0xFF1677FF)),
          ]),
          _group('Timeline', [
            const SizedBox(
              width: 300,
              child: Timeline(
                items: [
                  TimelineItem(content: Text('Ordered')),
                  TimelineItem(content: Text('Packed')),
                  TimelineItem(content: Text('On its way')),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  });

  testWidgets('lists and trees', (tester) async {
    await shoot(
      tester,
      'lists',
      size: const Size(620, 560),
      () => ListView(
        children: [
          _group('Listy', [
            SizedBox(
              width: 560,
              height: 150,
              child: Listy<String, String, String>(
                items: const ['Lisbon', 'Kraków', 'Valencia'],
                rowKey: (r) => r,
                itemRender: (item, i) => Text(item),
              ),
            ),
          ]),
          _group('Tree', [
            const SizedBox(
              width: 300,
              child: Tree(
                checkable: true,
                defaultExpandAll: true,
                nodes: [
                  TreeNode(
                    key: 'a',
                    title: Text('Europe'),
                    children: [
                      TreeNode(key: 'a1', title: Text('Lisbon')),
                      TreeNode(key: 'a2', title: Text('Kraków')),
                    ],
                  ),
                ],
              ),
            ),
          ]),
          _group('SortableList', [
            SizedBox(
              width: 300,
              child: SortableList(
                onReorder: (_, __) {},
                children: const [
                  // Centred in their own row: a handle is centred against the
                  // item, so an item that puts its text at the top of a tall
                  // box leaves the handle sitting under it.
                  SizedBox(
                    height: 32,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text('One'),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text('Two'),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  });

  testWidgets('the floating kinds', (tester) async {
    await shoot(
      tester,
      'floating',
      size: const Size(620, 420),
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              Tooltip(
                message: const Text('A word about it'),
                child: Button(onPressed: () {}, child: const Text('Tooltip')),
              ),
              Popover(
                title: const Text('What this is'),
                content: const Text('Two lines of it, and a button below.'),
                defaultOpen: true,
                child: Button(onPressed: () {}, child: const Text('Popover')),
              ),
            ],
          ),
          const SizedBox(height: 120),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              Popconfirm(
                title: const Text('Delete this order?'),
                description: const Text('It cannot be brought back.'),
                onOk: () {},
                child: Button(onPressed: () {}, child: const Text('Delete')),
              ),
              Dropdown<String>(
                menu: const [
                  DropdownItem(value: 'a', label: 'Rename'),
                  DropdownItem(value: 'b', label: 'Duplicate'),
                  DropdownItem(value: 'c', label: 'Delete'),
                ],
                trigger: const [DropdownTrigger.click],
                onItemTap: (_) {},
                child: Button(onPressed: () {}, child: const Text('Dropdown')),
              ),
            ],
          ),
        ],
      ),
      after: (tester) async {
        // Opened by hand: a dropdown and a popconfirm have no `defaultOpen`,
        // and a picture of a closed one says nothing. A dropdown answers to
        // hover by default, so it is asked to answer a press instead.
        await tester.tap(find.text('Dropdown'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete').first);
        await tester.pumpAndSettle();
      },
    );
  });
}
