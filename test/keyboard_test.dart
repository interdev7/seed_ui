import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Table, TableRow;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child, {TextDirection words = TextDirection.ltr}) =>
    ConfigProvider(
      theme: ThemeData(),
      child: MaterialApp(
        home: Directionality(
          textDirection: words,
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );

/// Whether the control under [finder] wears the focus halo.
bool _haloed(WidgetTester tester, Finder finder) {
  for (final w in tester.widgetList(finder)) {
    final decoration = switch (w) {
      Container(:final decoration) => decoration,
      AnimatedContainer(:final decoration) => decoration,
      DecoratedBox(:final decoration) => decoration,
      _ => null,
    };
    if (decoration is BoxDecoration) {
      final shadows = decoration.boxShadow;
      if (shadows != null && shadows.any((s) => s.spreadRadius == 3)) {
        return true;
      }
    }
  }
  return false;
}

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();
}

/// A row of the table below.
class _Person {
  const _Person(this.name, this.age);

  final String name;
  final int age;
}

void main() {
  group('a button', () {
    testWidgets('is reached by tab and pressed by space and enter',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(Button(onPressed: () => taps++, child: const Text('Go'))),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(taps, 1, reason: 'space');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 2, reason: 'enter');
    });

    testWidgets('shows a halo once the keyboard put the focus there',
        (tester) async {
      await tester.pumpWidget(
        _host(Button(onPressed: () {}, child: const Text('Go'))),
      );
      final box = find.ancestor(
        of: find.text('Go'),
        matching: find.byType(AnimatedContainer),
      );
      expect(_haloed(tester, box), isFalse);
      await _tab(tester);
      expect(_haloed(tester, box), isTrue);
    });

    testWidgets('one that does nothing is not a stop on the way round',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              const Button(child: Text('Dead')),
              Button(onPressed: () => taps++, child: const Text('Live')),
            ],
          ),
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      // The first tab landed on the live one, having skipped the dead.
      expect(taps, 1);
    });

    testWidgets('a disabled one cannot be pressed from the keyboard',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Button(
            disabled: true,
            onPressed: () => taps++,
            child: const Text('Go'),
          ),
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(taps, 0);
    });

    testWidgets('takes the focus at once when told to', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Button(
            autofocus: true,
            onPressed: () => taps++,
            child: const Text('Go'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  group('a checkbox', () {
    testWidgets('is ticked from the keyboard', (tester) async {
      var checked = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => Checkbox(
              checked: checked,
              onChanged: (v) => setState(() => checked = v),
              label: const Text('Tick'),
            ),
          ),
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(checked, isTrue);
    });

    testWidgets('the halo sits on the box, not on the words', (tester) async {
      await tester.pumpWidget(
        _host(
          Checkbox(checked: false, onChanged: (_) {}, label: const Text('T')),
        ),
      );
      await _tab(tester);
      expect(_haloed(tester, find.byType(AnimatedContainer)), isTrue);
    });
  });

  group('a radio button', () {
    testWidgets('is chosen from the keyboard', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _host(
          Radio<String>(
            value: 'a',
            groupValue: picked,
            onChanged: (v) => picked = v,
            child: const Text('A'),
          ),
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(picked, 'a');
    });
  });

  group('a switch', () {
    testWidgets('is flipped from the keyboard', (tester) async {
      var on = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => Switch(
              value: on,
              onChanged: (v) => setState(() => on = v),
            ),
          ),
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(on, isTrue);
    });

    testWidgets('wears the halo on its track', (tester) async {
      await tester.pumpWidget(_host(Switch(value: false, onChanged: (_) {})));
      await _tab(tester);
      expect(_haloed(tester, find.byType(AnimatedContainer)), isTrue);
    });
  });

  testWidgets('the tab order runs down the page', (tester) async {
    final pressed = <String>[];
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            for (final label in ['one', 'two', 'three'])
              Button(
                onPressed: () => pressed.add(label),
                child: Text(label),
              ),
          ],
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
    }
    expect(pressed, ['one', 'two', 'three']);
  });

  group('a segmented run', () {
    Future<void> pump(
      WidgetTester tester,
      List<int> chosen, {
      int value = 0,
      Axis direction = Axis.horizontal,
      TextDirection words = TextDirection.ltr,
      List<int> barred = const [],
    }) async {
      await tester.pumpWidget(
        _host(
          words: words,
          Segmented<int>(
            value: value,
            direction: direction,
            onChanged: chosen.add,
            options: [
              for (var i = 0; i < 4; i++)
                SegmentedOption(
                  value: i,
                  label: 'opt $i',
                  disabled: barred.contains(i),
                ),
            ],
          ),
        ),
      );
      await _tab(tester);
    }

    testWidgets('is one stop in the tab order, not one per option',
        (tester) async {
      final chosen = <int>[];
      var after = 0;
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              Segmented<int>(
                value: 0,
                onChanged: chosen.add,
                options: const [
                  SegmentedOption(value: 0, label: 'a'),
                  SegmentedOption(value: 1, label: 'b'),
                  SegmentedOption(value: 2, label: 'c'),
                ],
              ),
              Button(onPressed: () => after++, child: const Text('After')),
            ],
          ),
        ),
      );
      // One tab into the run, a second past it and onto the button: a bar of
      // fourteen options that took fourteen tabs to walk past is a bar
      // nobody walks past.
      await _tab(tester);
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(after, 1);
    });

    testWidgets('the arrows move the choice along it', (tester) async {
      final chosen = <int>[];
      await pump(tester, chosen);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(chosen, [1]);
    });

    testWidgets('and stop at the ends rather than wrapping round',
        (tester) async {
      final chosen = <int>[];
      await pump(tester, chosen, value: 3);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(chosen, isEmpty, reason: 'nowhere further to go');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(chosen, [2]);

      // And the same at the other end: holding an arrow down should not
      // cycle past the first option and round again.
      final atStart = <int>[];
      await pump(tester, atStart, value: 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(atStart, isEmpty);
    });

    testWidgets('home and end reach the ends', (tester) async {
      final chosen = <int>[];
      await pump(tester, chosen, value: 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(chosen, [3, 0]);
    });

    testWidgets('a barred option is stepped over', (tester) async {
      final chosen = <int>[];
      await pump(tester, chosen, barred: [1]);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(chosen, [2]);
    });

    testWidgets('down a column it is the up and down keys', (tester) async {
      final chosen = <int>[];
      await pump(tester, chosen, direction: Axis.vertical);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(chosen, isEmpty, reason: 'sideways means nothing in a column');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(chosen, [1]);
    });

    testWidgets('the arrow that steps on is the one the words run towards',
        (tester) async {
      final chosen = <int>[];
      await pump(tester, chosen, words: TextDirection.rtl);
      // The run reads right to left, so its next option lies to the left.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(chosen, [1]);
    });
  });

  group('a bar of tabs', () {
    testWidgets('the arrows move along it', (tester) async {
      final chosen = <String>[];
      await tester.pumpWidget(
        _host(
          Tabs(
            items: const [
              TabItem(key: 'one', label: Text('One'), content: Text('first')),
              TabItem(key: 'two', label: Text('Two'), content: Text('second')),
              TabItem(
                key: 'three',
                label: Text('Three'),
                content: Text('third'),
              ),
            ],
            onChange: chosen.add,
          ),
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(chosen, ['two', 'three']);
      expect(find.text('third'), findsOneWidget);
    });

    testWidgets('a barred tab is stepped over', (tester) async {
      final chosen = <String>[];
      await tester.pumpWidget(
        _host(
          Tabs(
            items: const [
              TabItem(key: 'one', label: Text('One'), content: Text('first')),
              TabItem(
                key: 'two',
                label: Text('Two'),
                disabled: true,
                content: Text('second'),
              ),
              TabItem(
                key: 'three',
                label: Text('Three'),
                content: Text('third'),
              ),
            ],
            onChange: chosen.add,
          ),
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(chosen, ['three']);
    });

    testWidgets('down the side it is the up and down keys', (tester) async {
      final chosen = <String>[];
      await tester.pumpWidget(
        _host(
          Tabs(
            tabPosition: TabPosition.left,
            items: const [
              TabItem(key: 'one', label: Text('One'), content: Text('first')),
              TabItem(key: 'two', label: Text('Two'), content: Text('second')),
            ],
            onChange: chosen.add,
          ),
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(chosen, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(chosen, ['two']);
    });
  });

  group('a pager', () {
    Future<List<int>> pump(WidgetTester tester, {int current = 2}) async {
      final pages = <int>[];
      await tester.pumpWidget(
        _host(
          Pagination(
            total: 100,
            current: current,
            onChange: (page, _) => pages.add(page),
          ),
        ),
      );
      await _tab(tester);
      return pages;
    }

    testWidgets('the arrows turn the pages', (tester) async {
      final pages = await pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(pages, [3, 1]);
    });

    testWidgets('home and end reach the first page and the last',
        (tester) async {
      final pages = await pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(pages, [10, 1]);
    });

    testWidgets('the ends hold', (tester) async {
      final pages = await pump(tester, current: 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(pages, isEmpty, reason: 'there is no page before the first');
    });

    testWidgets('a pager with one page is not a stop on the way round',
        (tester) async {
      var after = 0;
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              const Pagination(total: 5),
              Button(onPressed: () => after++, child: const Text('After')),
            ],
          ),
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(after, 1);
    });
  });

  group('a menu', () {
    const menu = [
      DropdownItem(value: 'edit', label: 'Edit'),
      DropdownDivider<String>(),
      DropdownItem(value: 'off', label: 'Off', disabled: true),
      DropdownItem(value: 'delete', label: 'Delete'),
    ];

    Future<List<String?>> open(WidgetTester tester) async {
      final taken = <String?>[];
      await tester.pumpWidget(
        ConfigProvider(
          theme: ThemeData(),
          child: MaterialApp(
            navigatorKey: UiKit.navigatorKey,
            home: Scaffold(
              body: Center(
                child: Dropdown<String>(
                  trigger: const [DropdownTrigger.click],
                  menu: menu,
                  onItemTap: taken.add,
                  child: Button(onPressed: () {}, child: const Text('Open')),
                ),
              ),
            ),
          ),
        ),
      );
      await _tab(tester);
      return taken;
    }

    testWidgets('a downward arrow opens it', (tester) async {
      await open(tester);
      expect(find.text('Edit'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('the arrows walk it and enter takes what they land on',
        (tester) async {
      final taken = await open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      // Down onto the first row, then again — over the barred one — onto the
      // last.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taken, ['delete']);
    });

    testWidgets('escape puts it away, taking nothing', (tester) async {
      final taken = await open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsNothing);
      expect(taken, isEmpty);
    });

    testWidgets('the row the keyboard rests on is lit', (tester) async {
      await open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final rows = tester.widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byType(DropdownMenuList<String>),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final lit = rows.where(
        (row) =>
            (row.decoration! as BoxDecoration).color != const Color(0x00000000),
      );
      expect(lit, hasLength(1), reason: 'one row, and only one');
    });

    testWidgets('the ends of the menu hold', (tester) async {
      final taken = await open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      // Up from the first row goes nowhere rather than round to the last.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taken, ['edit']);
    });

    testWidgets('end reaches the last row that can be taken', (tester) async {
      final taken = await open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taken, ['delete']);
    });
  });

  group('an accordion', () {
    testWidgets('each header is a stop, and space opens it', (tester) async {
      final open = <List<String>>[];
      await tester.pumpWidget(
        _host(
          Collapse(
            items: const [
              CollapseItem(
                  key: 'a', label: Text('First'), content: Text('one')),
              CollapseItem(
                  key: 'b', label: Text('Second'), content: Text('two')),
            ],
            onChange: open.add,
          ),
        ),
      );
      // The second header, not the first: the panels are separate sections,
      // so each is its own stop rather than a step along one run.
      await _tab(tester);
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(open, [
        ['b'],
      ]);
    });
  });

  group('a tree', () {
    const nodes = [
      TreeNode(
        key: 'fruit',
        title: Text('Fruit'),
        children: [
          TreeNode(key: 'apple', title: Text('Apple')),
          TreeNode(key: 'pear', title: Text('Pear')),
        ],
      ),
      TreeNode(key: 'veg', title: Text('Veg')),
    ];

    Future<List<List<String>>> pump(
      WidgetTester tester, {
      List<String> expanded = const [],
    }) async {
      final picked = <List<String>>[];
      await tester.pumpWidget(
        _host(
          Tree(
            nodes: nodes,
            defaultExpandedKeys: expanded,
            onSelect: picked.add,
          ),
        ),
      );
      await _tab(tester);
      return picked;
    }

    testWidgets('the ends of the tree hold', (tester) async {
      final picked = await pump(tester);
      // Up from nowhere lands on the last row; up again from the first goes
      // nowhere rather than round to the bottom.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked, [
        ['fruit'],
      ]);
    });

    testWidgets('is one stop, walked with the arrows', (tester) async {
      final picked = await pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      // Down twice with nothing open: Fruit, then Veg.
      expect(picked, [
        ['veg'],
      ]);
    });

    testWidgets('the inward arrow opens a branch, then steps into it',
        (tester) async {
      final picked = await pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsOneWidget, reason: 'it opened');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
          picked,
          [
            ['apple'],
          ],
          reason: 'the second press stepped down to the first child');
    });

    testWidgets('the outward arrow shuts a branch, then steps up to it',
        (tester) async {
      final picked = await pump(tester, expanded: ['fruit']);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      // On Apple now; out steps up to Fruit, and out again shuts it.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsNothing, reason: 'shut');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked, [
        ['fruit'],
      ]);
    });

    testWidgets('the node the keyboard rests on is lit', (tester) async {
      await pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final lit = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(Tree),
              matching: find.byType(Container),
            ),
          )
          .where(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color != null,
          );
      expect(lit, isNotEmpty);
    });
  });

  group('a table', () {
    const people = [
      _Person('Ada', 36),
      _Person('Grace', 45),
      _Person('Alan', 41),
    ];

    Widget table({
      void Function(_Person record, int index)? onRowTap,
      TableSelection<_Person>? selection,
      bool sortable = false,
    }) =>
        _host(
          SizedBox(
            width: 400,
            child: Table<_Person>(
              data: people,
              onRowTap: onRowTap,
              selection: selection,
              columns: [
                TableColumn<_Person>(
                  title: const Text('Name'),
                  value: (p) => p.name,
                  sortable: sortable,
                  sorter: sortable ? (a, b) => a.name.compareTo(b.name) : null,
                ),
                TableColumn<_Person>(
                  title: const Text('Age'),
                  value: (p) => '${p.age}',
                ),
              ],
            ),
          ),
        );

    testWidgets('is one stop, and enter opens the row the cursor is on',
        (tester) async {
      final tapped = <String>[];
      final at = <int>[];
      await tester.pumpWidget(
        table(
          onRowTap: (record, index) {
            tapped.add(record.name);
            at.add(index);
          },
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(tapped, ['Grace']);
      // The row's own place, not the first: a handler that writes it down
      // must be told which row it was.
      expect(at, [1]);
    });

    testWidgets('home and end reach the first row and the last',
        (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        table(onRowTap: (record, _) => tapped.add(record.name)),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(tapped, ['Alan', 'Ada']);
    });

    testWidgets('the last row holds', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        table(onRowTap: (record, _) => tapped.add(record.name)),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(tapped, ['Alan'], reason: 'still on the last');
    });

    testWidgets('space picks the row the cursor is on', (tester) async {
      var picked = <_Person>[];
      await tester.pumpWidget(
        table(
          selection: TableSelection<_Person>(
            onChanged: (rows) => picked = rows,
          ),
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(picked.map((p) => p.name), ['Ada']);
    });

    testWidgets(
        'up out of the first row lands in the head, where the '
        'sorting is', (tester) async {
      await tester.pumpWidget(table(sortable: true));
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Sorted by name: Ada, Alan, Grace.
      final names = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .where((d) => d == 'Ada' || d == 'Alan' || d == 'Grace')
          .toList();
      expect(names, ['Ada', 'Alan', 'Grace']);
    });

    testWidgets('a table with nothing to sort keeps the cursor in the rows',
        (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        table(onRowTap: (record, _) => tapped.add(record.name)),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(tapped, ['Ada'], reason: 'there was no head row to go up into');
    });
  });
}
