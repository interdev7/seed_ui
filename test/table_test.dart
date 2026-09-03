import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as m;
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
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

class _User {
  const _User(this.name, this.age);
  final String name;
  final int age;
}

const _users = [_User('Ann', 31), _User('Bartholomew Longname', 7)];

List<String> shownNames(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data)
    .whereType<String>()
    .where((s) => s == 'Chen' || s == 'Ann' || s == 'Bart')
    .toList();

Widget _host(Widget child, {double width = 600}) => ConfigProvider(
      child: m.MaterialApp(
        home: m.Scaffold(
          body: Center(child: SizedBox(width: width, child: child)),
        ),
      ),
    );

TableColumn<_User> _name({double? width, int? flex, TableAlign? align}) =>
    TableColumn<_User>(
      title: const Text('Name'),
      width: width,
      flex: flex,
      align: align,
      value: (u) => u.name,
    );

TableColumn<_User> _age({double? width, int? flex, TableAlign? align}) =>
    TableColumn<_User>(
      title: const Text('Age'),
      width: width,
      flex: flex,
      align: align,
      value: (u) => u.age,
    );

/// Where a column begins, measured from the table's own left edge.
double _left(WidgetTester tester, String text) =>
    tester.getRect(find.text(text)).left -
    tester.getRect(find.byType(Table<_User>)).left;

void main() {
  group('the grid', () {
    testWidgets('draws a heading and a cell for every row', (tester) async {
      await tester.pumpWidget(
        _host(Table<_User>(columns: [_name(), _age()], data: _users)),
      );
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Ann'), findsOneWidget);
      expect(find.text('Bartholomew Longname'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('a column keeps its cells in line', (tester) async {
      await tester.pumpWidget(
        _host(Table<_User>(columns: [_name(), _age()], data: _users)),
      );
      expect(_left(tester, 'Ann'), _left(tester, 'Bartholomew Longname'));
      expect(_left(tester, 'Name'), _left(tester, 'Ann'));
      expect(_left(tester, '31'), _left(tester, '7'));
    });

    testWidgets('a column with no width takes the room its content needs',
        (tester) async {
      // The whole point of saying nothing: the longer name pushes the second
      // column further along than the shorter one would.
      await tester.pumpWidget(
        _host(
          Table<_User>(
            columns: [_name(), _age()],
            data: const [_User('Ann', 31)],
          ),
        ),
      );
      final narrow = _left(tester, '31');

      await tester.pumpWidget(
        _host(Table<_User>(columns: [_name(), _age()], data: _users)),
      );
      expect(_left(tester, '31'), greaterThan(narrow));
    });

    testWidgets('a width is the width', (tester) async {
      // Flutter shares slack between every column by default, which inflated
      // a column that had asked for an exact number — 100 became 267.
      await tester.pumpWidget(
        _host(
          Table<_User>(columns: [_name(width: 100), _age()], data: _users),
        ),
      );
      final padding = _left(tester, 'Ann');
      expect(_left(tester, '31'), closeTo(100 + padding, 0.5));
    });

    testWidgets('flex splits what is left in proportion', (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(columns: [_name(flex: 1), _age(flex: 3)], data: _users),
        ),
      );
      final padding = _left(tester, 'Ann');
      expect(_left(tester, '31'), closeTo(150 + padding, 0.5));
    });

    test('a column may not ask for both a width and a flex', () {
      expect(() => _name(width: 10, flex: 1), throwsAssertionError);
    });

    testWidgets('align sends a cell to the far edge', (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            columns: [_name(), _age(align: TableAlign.end)],
            data: _users,
          ),
        ),
      );
      final table = tester.getRect(find.byType(Table<_User>));
      final cell = tester.getRect(find.text('31'));
      expect(table.right - cell.right, closeTo(_left(tester, 'Ann'), 0.5),
          reason: 'a padding away from the trailing edge');
    });

    testWidgets('a heading follows its column, unless told otherwise',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            columns: [_name(), _age(align: TableAlign.end)],
            data: _users,
          ),
        ),
      );
      final table = tester.getRect(find.byType(Table<_User>));
      expect(
        table.right - tester.getRect(find.text('Age')).right,
        closeTo(table.right - tester.getRect(find.text('31')).right, 0.5),
        reason: 'the heading sits over its own column',
      );

      await tester.pumpWidget(
        _host(
          Table<_User>(
            columns: [
              _name(),
              TableColumn<_User>(
                title: const Text('Age'),
                align: TableAlign.end,
                headerAlign: TableAlign.start,
                builder: (_, u, __) => Text('${u.age}'),
              ),
            ],
            data: _users,
          ),
        ),
      );
      expect(
        _left(tester, 'Age'),
        lessThan(_left(tester, '31')),
        reason: 'headerAlign overrules align for the heading alone',
      );
    });

    testWidgets('ellipsis holds a cell to one line', (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            columns: [
              TableColumn(
                title: const Text('Name'),
                width: 60,
                ellipsis: true,
                builder: (_, u, __) => Text(u.name),
              ),
            ],
            data: _users,
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('Bartholomew Longname'));
      final style = DefaultTextStyle.of(
        tester.element(find.text('Bartholomew Longname')),
      );
      expect(text.maxLines ?? style.maxLines, 1);
      expect(text.overflow ?? style.overflow, TextOverflow.ellipsis);
    });
  });

  group('a value is enough', () {
    testWidgets('a column with no builder draws its value as text',
        (tester) async {
      // Most columns are a word out of a row, and saying so should be the
      // whole of it.
      await tester.pumpWidget(
        _host(
          Table<_User>(
            columns: [
              TableColumn(title: const Text('Name'), value: (u) => u.name),
            ],
            data: _users,
          ),
        ),
      );
      expect(find.text('Ann'), findsOneWidget);
      expect(find.text('Bartholomew Longname'), findsOneWidget);
    });

    testWidgets('a builder overrules the value it is given', (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            columns: [
              TableColumn(
                title: const Text('Name'),
                value: (u) => u.name,
                builder: (_, u, __) => Text(u.name.toUpperCase()),
              ),
            ],
            data: _users,
          ),
        ),
      );
      expect(find.text('ANN'), findsOneWidget);
      expect(find.text('Ann'), findsNothing);
    });

    testWidgets('an absent value draws nothing, not the word null',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            columns: [
              TableColumn(title: const Text('Name'), value: (u) => null),
            ],
            data: _users,
          ),
        ),
      );
      expect(find.text('null'), findsNothing);
    });

    test('a column needs one of the two', () {
      expect(
        () => TableColumn<_User>(title: const Text('Name')),
        throwsAssertionError,
      );
    });
  });

  group('what surrounds it', () {
    testWidgets('showHeader takes the heading away', (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            columns: [_name()],
            data: _users,
            showHeader: false,
          ),
        ),
      );
      expect(find.text('Name'), findsNothing);
      expect(find.text('Ann'), findsOneWidget);
    });

    testWidgets('a header and a footer are handed the rows', (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            columns: [_name()],
            data: _users,
            header: (_, rows) => Text('${rows.length} above'),
            footer: (_, rows) => Text('${rows.length} below'),
          ),
        ),
      );
      expect(find.text('2 above'), findsOneWidget);
      expect(find.text('2 below'), findsOneWidget);
      expect(
        tester.getRect(find.text('2 above')).top,
        lessThan(tester.getRect(find.text('Name')).top),
      );
      expect(
        tester.getRect(find.text('2 below')).top,
        greaterThan(tester.getRect(find.text('Ann')).top),
      );
    });

    testWidgets('no rows leaves the heading and says so', (tester) async {
      await tester.pumpWidget(
        _host(Table<_User>(columns: [_name()], data: const [])),
      );
      expect(find.byType(Empty), findsOneWidget);
      expect(find.text('Name'), findsOneWidget,
          reason: 'the columns are still worth showing');
    });

    testWidgets('an empty of your own replaces it', (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            columns: [_name()],
            data: const [],
            empty: const Text('Nothing here'),
          ),
        ),
      );
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.byType(Empty), findsNothing);
    });

    testWidgets('and so does the provider, through its own slot',
        (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          emptyBuilder: (context, slot) => Text('none: ${slot.name}'),
          child: m.MaterialApp(
            home: m.Scaffold(
              body: Table<_User>(columns: [_name()], data: const []),
            ),
          ),
        ),
      );
      expect(find.text('none: table'), findsOneWidget);
    });

    testWidgets('loading lays a spinner over it', (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(columns: [_name()], data: _users, loading: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Spin), findsOneWidget);
      expect(tester.widget<Spin>(find.byType(Spin)).spinning, isTrue);
    });

    testWidgets('a tap reports the row it landed on', (tester) async {
      final taps = <(String, int)>[];
      await tester.pumpWidget(
        _host(
          Table<_User>(
            columns: [_name()],
            data: _users,
            onRowTap: (u, i) => taps.add((u.name, i)),
          ),
        ),
      );
      await tester.tap(find.text('Bartholomew Longname'));
      expect(taps, [('Bartholomew Longname', 1)]);
    });
  });

  group('scrolling', () {
    List<int> many(int n) => [for (var i = 0; i < n; i++) i];

    Widget rows(TableScroll? scroll, {int n = 30, double box = 400}) => _host(
          Table<int>(
            scroll: scroll,
            columns: [
              TableColumn<int>(title: const Text('N'), value: (v) => 'row $v'),
              TableColumn<int>(title: const Text('Sq'), value: (v) => 'sq $v'),
            ],
            data: many(n),
          ),
          width: box,
        );

    testWidgets('with no scroll the table is as tall as its rows',
        (tester) async {
      await tester.pumpWidget(rows(null, n: 4));
      final short = tester.getRect(find.byType(Table<int>)).height;
      await tester.pumpWidget(rows(null, n: 8));
      expect(
        tester.getRect(find.byType(Table<int>)).height,
        greaterThan(short),
      );
    });

    testWidgets('a height keeps the table to it', (tester) async {
      await tester.pumpWidget(rows(const TableScroll(y: 200)));
      final table = tester.getRect(find.byType(Table<int>));
      expect(table.height, lessThan(300), reason: 'thirty rows would be 600');
      expect(table.height, greaterThan(200), reason: 'the heading as well');
    });

    testWidgets('the heading stays while the rows go by', (tester) async {
      await tester.pumpWidget(rows(const TableScroll(y: 200)));
      final heading = tester.getRect(find.text('N')).top;
      final first = tester.getRect(find.text('row 0')).top;

      await tester.drag(find.text('row 1'), const Offset(0, -80));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.text('N')).top, heading,
          reason: 'the heading did not move');
      expect(tester.getRect(find.text('row 0')).top, closeTo(first - 80, 1),
          reason: 'the rows did');
    });

    testWidgets('a width wider than the box scrolls across', (tester) async {
      await tester.pumpWidget(rows(const TableScroll(x: 900), n: 3));
      final table = tester.getRect(find.byType(Table<int>));
      expect(table.width, closeTo(400, 1), reason: 'the box, not the content');

      final heading = tester.getRect(find.text('N')).left;
      await tester.drag(find.text('row 0'), const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('N')).left, closeTo(heading - 200, 1));
    });

    testWidgets('the heading and the rows never drift apart', (tester) async {
      // They share one viewport rather than a controller each, so there is
      // only one offset for them to disagree about.
      // The *second* column, not the first: every first column starts at
      // zero whatever the widths are, so comparing those proves nothing. And
      // a short heading over long cells, because that is where two tables
      // measuring themselves separately come apart — thirty pixels, measured.
      await tester.pumpWidget(
        _host(
          Table<int>(
            scroll: const TableScroll(y: 150),
            columns: [
              TableColumn<int>(
                title: const Text('N'),
                value: (v) => 'a very long cell $v',
              ),
              TableColumn<int>(title: const Text('Sq'), value: (v) => 'x'),
            ],
            data: many(5),
          ),
          width: 400,
        ),
      );
      expect(
        tester.getRect(find.text('Sq')).left,
        tester.getRect(find.text('x').first).left,
        reason: 'the heading sits over its own column',
      );

      await tester.drag(find.text('a very long cell 1'), const Offset(0, -40));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('Sq')).left,
        tester.getRect(find.text('x').first).left,
        reason: 'still over it once the rows have moved',
      );
    });

    testWidgets('a scrolling table still fits its columns to their content',
        (tester) async {
      // It used to share the width equally instead: the heading was a table
      // of its own, and an intrinsic width would have measured the title in
      // one and the cells in the other. One viewport holds both now, and the
      // widths are worked out from the text itself before a cell is built —
      // so a scrolling table sizes its columns like any other.
      await tester.pumpWidget(
        _host(
          Table<int>(
            scroll: const TableScroll(y: 200),
            columns: [
              TableColumn<int>(title: const Text('N'), value: (v) => 'x'),
              TableColumn<int>(
                title: const Text('Sq'),
                value: (v) => 'a much longer cell than the other',
              ),
            ],
            data: many(4),
          ),
          width: 400,
        ),
      );
      final table = tester.getRect(find.byType(Table<int>));
      final second = tester.getRect(find.text('Sq')).left - table.left;
      // 'x' and its padding, nowhere near the half the old table gave it.
      expect(second, lessThan(120), reason: 'the narrow column stayed narrow');
      expect(second, greaterThan(16), reason: 'and it is still a column');
    });

    testWidgets('a scrolling row is as tall as a still one', (tester) async {
      // Laid out at the preset's control height with the cell's padding still
      // on it, the text had nowhere to go and came out cut in half.
      await tester.pumpWidget(rows(null, n: 4));
      final still = tester.getRect(find.text('row 1')).top -
          tester.getRect(find.text('row 0')).top;

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(rows(const TableScroll(y: 200), n: 4));
      final scrolling = tester.getRect(find.text('row 1')).top -
          tester.getRect(find.text('row 0')).top;

      expect(scrolling, closeTo(still, 0.5));
      expect(
        tester.getRect(find.text('row 0')).height,
        lessThan(scrolling),
        reason: 'the text fits inside its row rather than being cut by it',
      );
    });

    testWidgets('the widths are measured again only when they would change',
        (tester) async {
      // Measuring is exact and so proportional to the data: five hundred rows
      // of two columns is a thousand strings, and every rebuild above the
      // table paid for all of them. Measured on fifteen columns, a tap on a
      // row cost a hundred and seventeen milliseconds.
      var built = 0;
      Widget host(List<int> data) => _host(
            StatefulBuilder(
              builder: (context, setState) => Table<int>(
                scroll: const TableScroll(y: 200),
                onRowTap: (_, __) => setState(() {}),
                columns: [
                  TableColumn<int>(
                    title: const Text('N'),
                    value: (v) {
                      built++;
                      return 'row $v';
                    },
                  ),
                ],
                data: data,
              ),
            ),
            width: 400,
          );

      // A fresh list every build, which is how a `data:` written inline
      // behaves — so the rows are compared, not the list.
      await tester.pumpWidget(host([for (var i = 0; i < 200; i++) i]));
      await tester.pumpAndSettle();
      built = 0;

      await tester.tap(find.text('row 1'));
      await tester.pumpAndSettle();
      expect(built, lessThan(50), reason: 'the rows on screen, and no more');

      // Different rows, though, and the question has changed.
      await tester.pumpWidget(host([for (var i = 0; i < 200; i++) i + 1000]));
      await tester.pumpAndSettle();
      expect(built, greaterThan(200), reason: 'every row was measured again');
    });

    testWidgets('only the rows on screen are built', (tester) async {
      // Five hundred rows of two columns is a thousand cells, and building
      // them all to show a dozen was the whole of what scrolling cost.
      await tester.pumpWidget(rows(const TableScroll(y: 200), n: 500));
      expect(find.byType(RichText).evaluate().length, lessThan(60));
      expect(find.text('row 0'), findsOneWidget);
      expect(find.text('row 499'), findsNothing);

      // All five hundred are there to be reached, though, and the count does
      // not grow on the way.
      final pointer = TestPointer(1, PointerDeviceKind.trackpad);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('row 1'))),
      );
      for (var i = 1; i <= 3; i++) {
        await tester.sendEventToBinding(pointer.scroll(Offset(0, 20000.0 * i)));
        await tester.pumpAndSettle();
      }
      expect(find.text('row 499'), findsOneWidget);
      expect(find.byType(RichText).evaluate().length, lessThan(60));
    });

    testWidgets('an empty scrolling table still shows its heading',
        (tester) async {
      await tester.pumpWidget(rows(const TableScroll(y: 200), n: 0));
      expect(find.text('N'), findsOneWidget);
      expect(find.byType(Empty), findsOneWidget);
    });

    testWidgets('a mouse can drag it sideways', (tester) async {
      // Flutter leaves the mouse out of dragDevices, so a scroll view cannot
      // be dragged with one at all — and buildScrollbar returns the child
      // untouched on the horizontal axis, so there is no bar to drag either.
      // Between them, a table that scrolled sideways could not be scrolled
      // sideways on the web, where the wheel only goes down.
      await tester.pumpWidget(rows(const TableScroll(x: 1200), n: 3));
      final before = tester.getRect(find.text('N')).left;

      final mouse = await tester.startGesture(
        tester.getCenter(find.text('row 1')),
        kind: PointerDeviceKind.mouse,
      );
      await mouse.moveBy(const Offset(-150, 0));
      await tester.pump();
      await mouse.up();
      await tester.pumpAndSettle();

      expect(tester.getRect(find.text('N')).left, closeTo(before - 150, 1));
    });

    testWidgets('no bar crosses the table, scrolling or still', (tester) async {
      // A bar across the foot of a wide table is a line the design did not
      // ask for, and it sits over the last row. What says there is more to
      // see is the shade a pinned column casts.
      await tester.pumpWidget(rows(const TableScroll(x: 1200), n: 3));
      expect(find.byType(RawScrollbar), findsNothing);

      // Not merely hidden at rest: a drag does not bring one out either.
      await tester.drag(find.text('N'), const Offset(-150, 0));
      await tester.pump();
      expect(find.byType(RawScrollbar), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('what the rows cannot use goes back to the page',
        (tester) async {
      // A scroll view inside another does not chain: reaching its own end it
      // simply stops. Measured before this, a table with a height of its own
      // froze the page for as long as the pointer was over it — thirteen
      // drags and the page had not moved a pixel.
      final page = ScrollController();
      addTearDown(page.dispose);
      await tester.pumpWidget(
        ConfigProvider(
          child: m.MaterialApp(
            home: m.Scaffold(
              body: SingleChildScrollView(
                controller: page,
                child: Column(
                  children: [
                    Table<int>(
                      scroll: const TableScroll(y: 200),
                      columns: [
                        for (var c = 0; c < 3; c++)
                          TableColumn<int>(
                            title: Text('C$c'),
                            value: (v) => 'c$c-$v',
                          ),
                      ],
                      data: [for (var i = 0; i < 40; i++) i],
                    ),
                    const SizedBox(height: 1500),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The first drag is the table's own business.
      await tester.drag(find.text('c0-1'), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(page.offset, 0);

      // Once its rows have run out, the page takes what is left.
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(Table<int>), const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      expect(page.offset, greaterThan(100));
    });

    test('a scroll must have room to happen in', () {
      expect(() => TableScroll(y: 0), throwsAssertionError);
      expect(() => TableScroll(x: -1), throwsAssertionError);
    });
  });

  group('pinned columns', () {
    Widget pinned({double? y, bool endFirst = false}) {
      final end = TableColumn<int>(
        title: const Text('End'),
        width: 80,
        fixed: TableColumnFixed.end,
        value: (v) => 'e$v',
      );
      final start = TableColumn<int>(
        title: const Text('Pin'),
        width: 100,
        fixed: TableColumnFixed.start,
        value: (v) => 'p$v',
      );
      return _host(
        Table<int>(
          scroll: TableScroll(x: 1000, y: y),
          columns: [
            if (endFirst) end,
            start,
            for (var c = 0; c < 5; c++)
              TableColumn<int>(title: Text('C$c'), value: (v) => 'c${c}r$v'),
            if (!endFirst) end,
          ],
          data: [for (var i = 0; i < 12; i++) i],
        ),
        width: 400,
      );
    }

    testWidgets('a pinned column stays while the rest go past', (tester) async {
      await tester.pumpWidget(pinned(y: 200));
      final table = tester.getRect(find.byType(Table<int>));
      final start = tester.getRect(find.text('p0')).left;
      final end = tester.getRect(find.text('e0')).left;
      expect(end - table.left, greaterThan(200),
          reason: 'the end pane is against the far edge of a 400-wide box');

      await tester.drag(find.text('c0r1'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.text('p0')).left, start);
      expect(tester.getRect(find.text('e0')).left, end);
    });

    testWidgets('the heading travels across with its rows', (tester) async {
      // Two viewports here — one for the heading, one for the rows — so this
      // is the one place they are kept in step by hand.
      await tester.pumpWidget(pinned(y: 200));
      final heading = tester.getRect(find.text('C0')).left;
      final cell = tester.getRect(find.text('c0r0')).left;

      await tester.drag(find.text('c0r1'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      // How far they went is the gesture's business — a drag gives up its
      // first pixels to the touch slop. That they went the *same* distance is
      // the table's.
      final movedHeading = heading - tester.getRect(find.text('C0')).left;
      final movedCell = cell - tester.getRect(find.text('c0r0')).left;
      expect(movedHeading, movedCell, reason: 'they moved as one');
      expect(movedHeading, greaterThan(100), reason: 'and they did move');
    });

    testWidgets('a pinned table scrolls sideways, heading and all',
        (tester) async {
      // The case the gallery caught: with a sticky heading the columns went
      // one way and the heading another — its pane was laid out at the width
      // of the box rather than the table, so its columns came out at the
      // floor while the rows' were half as wide again.
      await tester.pumpWidget(pinned(y: 200));
      final headingBefore = tester.getRect(find.text('C0')).left;
      final cellBefore = tester.getRect(find.text('c0r0')).left;
      expect(
        tester.getRect(find.text('C1')).left,
        tester.getRect(find.text('c1r0')).left,
        reason: 'the columns are the same width in both bands',
      );

      final mouse = await tester.startGesture(
        tester.getCenter(find.text('c0r1')),
        kind: PointerDeviceKind.mouse,
      );
      // Two moves, not one: a drag recognizer spends the first on winning the
      // arena and reports nothing for it, which is what a real mouse sending
      // a stream of moves never notices.
      await mouse.moveBy(const Offset(-30, 0));
      await mouse.moveBy(const Offset(-120, 0));
      await tester.pump();
      await mouse.up();
      await tester.pumpAndSettle();

      final headingMoved = headingBefore - tester.getRect(find.text('C0')).left;
      final cellMoved = cellBefore - tester.getRect(find.text('c0r0')).left;
      expect(cellMoved, greaterThan(100), reason: 'the rows went across');
      expect(headingMoved, cellMoved, reason: 'and the heading went with them');
    });

    testWidgets('a pinned column casts over what has gone behind it',
        (tester) async {
      // The shade is painted, not built: one viewport owns both axes now, so
      // there is no pane to hang a strip on — the rows are laid out where
      // they are and a gradient goes over them.
      Finder viewport() => find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_RowsViewport',
          );
      // `something` rather than a bare `rect`: the cells paint rectangles of
      // their own, and the shade is only one of them. Matched on the edge it
      // stands at rather than the whole rectangle — the shade is now drawn
      // per band, so its height is the band's rather than the table's.
      PaintPattern casts(double edge) => paints
        ..something(
          (symbol, arguments) =>
              symbol == #drawRect &&
              (arguments[0] as Rect).left == edge &&
              (arguments[0] as Rect).width == 12,
        );

      // A bare pump first, so this table gets a State of its own. Pumping one
      // Table<int> over another hands the second the first's element — and its
      // scroll position with it.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(pinned(y: 200));
      // How far there is left to go is only known after a layout, so the
      // trailing shadow arrives on the frame after the first.
      await tester.pumpAndSettle();

      // At rest the run is against its start: nothing has gone behind the
      // leading column, and everything is still ahead of the trailing one.
      expect(
        tester.renderObject(viewport()),
        casts(308),
        reason: 'the trailing column casts, and it alone',
      );

      // Run it to the far end and the two swap over. Scroll events rather
      // than drags: a drag begins where the finder is now, so after the first
      // one the grip has moved and the rest land nowhere.
      final pointer = TestPointer(1, PointerDeviceKind.trackpad);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('c0r1'))),
      );
      for (var i = 1; i <= 10; i++) {
        await tester.sendEventToBinding(pointer.scroll(Offset(120.0 * i, 0)));
        await tester.pumpAndSettle();
      }
      expect(
        tester.renderObject(viewport()),
        casts(100),
        reason: 'now the leading one does, against its own edge',
      );
      expect(
        tester.renderObject(viewport()),
        isNot(casts(308)),
        reason: 'and the trailing one has nothing left ahead to cast over',
      );
    });

    testWidgets('rows stay level across the panes', (tester) async {
      // The reason pinning fixes the row height: laid out apart, three tables
      // work out their own, and one wrapping cell put two of them a hundred
      // and forty pixels out of step.
      await tester.pumpWidget(pinned(y: 200));
      final top = tester.getRect(find.text('p0')).top;
      expect(tester.getRect(find.text('c0r0')).top, top);
      expect(tester.getRect(find.text('e0')).top, top);

      final second = tester.getRect(find.text('p1')).top;
      expect(tester.getRect(find.text('c0r1')).top, second);
      expect(tester.getRect(find.text('e1')).top, second);
    });

    testWidgets('a held column keeps its place until the scroll reaches it',
        (tester) async {
      // Held columns are no longer taken out and stacked at the edge: one
      // keeps its place among the others and stops when the scroll would
      // carry it past its rest — which is what lets a loose column stand
      // between two held ones and slide under them.
      await tester.pumpWidget(
        _host(
          Table<int>(
            scroll: const TableScroll(x: 1200, y: 200),
            columns: [
              TableColumn<int>(
                title: const Text('One'),
                width: 100,
                fixed: TableColumnFixed.start,
                value: (v) => 'one$v',
              ),
              TableColumn<int>(
                title: const Text('Loose'),
                width: 100,
                value: (v) => 'loose$v',
              ),
              TableColumn<int>(
                title: const Text('Two'),
                width: 100,
                fixed: TableColumnFixed.start,
                value: (v) => 'two$v',
              ),
              for (var c = 0; c < 6; c++)
                TableColumn<int>(
                  title: Text('C$c'),
                  width: 120,
                  value: (v) => 'c${c}r$v',
                ),
            ],
            data: [for (var i = 0; i < 8; i++) i],
          ),
          width: 400,
        ),
      );
      await tester.pumpAndSettle();

      final table = tester.getRect(find.byType(Table<int>));
      double leftOf(String text) =>
          tester.getRect(find.text(text)).left - table.left;

      // At rest the order is the order given, loose column and all.
      expect(leftOf('one0'), lessThan(leftOf('loose0')));
      expect(leftOf('loose0'), lessThan(leftOf('two0')));

      // Run it along: the loose one goes under, and the second held column
      // comes to rest right behind the first.
      final pointer = TestPointer(1, PointerDeviceKind.trackpad);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('c0r1'))),
      );
      for (var i = 0; i < 6; i++) {
        await tester.sendEventToBinding(pointer.scroll(const Offset(120, 0)));
        await tester.pumpAndSettle();
      }

      expect(leftOf('one0'), lessThan(20), reason: 'still at the edge');
      // Measured between the two texts, since each sits a cell's padding in:
      // the second stands exactly the first's hundred pixels along.
      expect(leftOf('two0') - leftOf('one0'), closeTo(100, 2),
          reason: 'stacked behind the first, which is a hundred wide');
      expect(find.text('loose0'), findsNothing,
          reason: 'gone under them, and no longer built');
    });

    testWidgets('a held column has a ground of its own', (tester) async {
      // It stands over the columns sliding under it, and a row is only as
      // opaque as its own fill — which is nothing until the pointer is on it.
      await tester.pumpWidget(pinned(y: 200));
      await tester.pumpAndSettle();

      List<Color> fillsOver(String text) => [
            ...tester
                .widgetList<DecoratedBox>(
                  find.ancestor(
                    of: find.text(text),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .map((d) => d.decoration)
                .whereType<BoxDecoration>()
                .map((d) => d.color)
                .whereType<Color>(),
            ...tester
                .widgetList<ColoredBox>(
                  find.ancestor(
                    of: find.text(text),
                    matching: find.byType(ColoredBox),
                  ),
                )
                .map((b) => b.color),
          ].where((c) => c.a != 0).toList();

      expect(fillsOver('p0'), isNotEmpty, reason: 'the held one is opaque');
      expect(fillsOver('p0').first.a, 1.0);
      expect(fillsOver('c0r0'), isEmpty, reason: 'a loose one is not');

      // And its heading with it: the heading's own fill is a two per cent
      // wash, so a held column's heading was see-through and the others could
      // be watched travelling behind it.
      expect(fillsOver('Pin').first.a, 1.0);
      expect(fillsOver('C0').first.a, lessThan(0.5),
          reason: 'a loose heading keeps the wash it always had');
    });

    testWidgets('the shade moves to the column that is holding',
        (tester) async {
      // Cast from the edge of the columns that are holding, not from where
      // they will all come to rest: a shade drawn at the far side of the band
      // appeared beside a column the scroll had not yet reached.
      final key = GlobalKey();
      await tester.pumpWidget(
        _host(
          RepaintBoundary(
            key: key,
            child: Table<int>(
              scroll: const TableScroll(x: 1200, y: 150),
              columns: [
                TableColumn<int>(
                  title: const Text('One'),
                  width: 100,
                  fixed: TableColumnFixed.start,
                  value: (v) => 'one$v',
                ),
                TableColumn<int>(
                  title: const Text('Loose'),
                  width: 100,
                  value: (v) => 'loose$v',
                ),
                TableColumn<int>(
                  title: const Text('Two'),
                  width: 100,
                  fixed: TableColumnFixed.start,
                  value: (v) => 'two$v',
                ),
                for (var c = 0; c < 6; c++)
                  TableColumn<int>(
                    title: Text('C$c'),
                    width: 120,
                    value: (v) => 'c${c}r$v',
                  ),
              ],
              data: [for (var i = 0; i < 6; i++) i],
            ),
          ),
          width: 400,
        ),
      );
      await tester.pumpAndSettle();

      // Alpha, not colour: a held cell is opaque, a loose one paints nothing,
      // and the shade is a wash over the nothing.
      Future<List<int>> alphaAt(List<int> xs) async {
        final box = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        final bytes = await tester.runAsync(() async {
          final image = await box.toImage();
          final data = await image.toByteData();
          image.dispose();
          return data;
        });
        final w = box.size.width.round();
        final origin = tester.getRect(find.byKey(key));
        // Just above the first body glyph: inside the cell's padding, where
        // no glyph reaches.
        final y =
            (tester.getRect(find.text('one0')).top - origin.top - 5).round();
        return [for (final x in xs) bytes!.getUint8((y * w + x) * 4 + 3)];
      }

      final pointer = TestPointer(1, PointerDeviceKind.trackpad);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.byKey(key))),
      );

      // It arrives with the scroll rather than switching on: a few pixels in,
      // it is only part of the way up.
      await tester.sendEventToBinding(pointer.scroll(const Offset(8, 0)));
      await tester.pumpAndSettle();
      final faint = (await alphaAt([101])).first;
      expect(faint, greaterThan(0));

      await tester.sendEventToBinding(pointer.scroll(const Offset(32, 0)));
      await tester.pumpAndSettle();
      var seen = await alphaAt([101, 108, 202]);
      expect(seen[0], greaterThan(faint), reason: 'and grows as it is held');
      expect(seen[0], greaterThan(5), reason: 'a wash past the first column');
      expect(seen[0], lessThan(60),
          reason: 'the reference casts a narrow edge, not a band');
      expect(seen[1], lessThan(seen[0]), reason: 'and it fades');
      expect(seen[2], 255,
          reason: 'the second is still at its own place, casting nothing');

      // Once the second has stacked, its own shade grows at its own edge —
      // it does not switch on at full strength, and the first column's is
      // covered by the second's cell arriving over it.
      await tester.sendEventToBinding(pointer.scroll(const Offset(100, 0)));
      await tester.pumpAndSettle();
      seen = await alphaAt([101, 201, 208]);
      expect(seen[0], 255, reason: 'the first two now stand together');
      expect(seen[1], greaterThan(5));
      expect(seen[1], lessThan(60));
      expect(seen[2], lessThan(seen[1]), reason: 'fading from the new edge');
    });

    testWidgets('a held column lights up under the pointer like any other',
        (tester) async {
      // The ground used to be painted inside the cell and the row's fill
      // outside it, so the opaque ground covered the fill: a held column
      // neither lit up under the pointer nor showed that its row was picked.
      await tester.pumpWidget(pinned(y: 200));
      await tester.pumpAndSettle();

      Color fillOf(String text) => tester
          .widgetList<ColoredBox>(
            find.ancestor(
              of: find.text(text),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((b) => b.color)
          // The innermost is the row's own: a loose cell's is transparent
          // until the pointer arrives, so it cannot be filtered out by alpha.
          .first;

      final resting = fillOf('p1');
      final loose = fillOf('c0r1');

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('p1')));
      await tester.pumpAndSettle();

      expect(fillOf('p1'), isNot(resting), reason: 'the held cell tints too');
      expect(fillOf('p1').a, 1.0, reason: 'and keeps its ground under it');
      expect(fillOf('c0r1'), isNot(loose), reason: 'and so does its row');
    });

    testWidgets('every cell is drawn once', (tester) async {
      // An earlier attempt drew the whole table again for each pinned edge,
      // so every cell existed three times over — three times the work, a
      // screen reader reading it three times, and an ambiguous finder in
      // every test anyone writes.
      await tester.pumpWidget(pinned(y: 200));
      expect(find.text('p0'), findsOneWidget);
      expect(find.text('c0r0'), findsOneWidget);
      expect(find.text('e0'), findsOneWidget);
    });

    testWidgets('pinning holds every row to one height', (tester) async {
      await tester.pumpWidget(
        _host(
          Table<int>(
            scroll: const TableScroll(x: 900),
            columns: [
              TableColumn<int>(
                title: const Text('Pin'),
                width: 80,
                fixed: TableColumnFixed.start,
                value: (v) => 'p$v',
              ),
              TableColumn<int>(
                title: const Text('Long'),
                // Long enough to actually wrap in the room it is given — a
                // string that fits on one line would leave this test with
                // nothing to catch.
                value: (v) => v == 0
                    ? 'a cell long enough to wrap over several lines indeed '
                        'and then a good deal more besides'
                    : 's$v',
              ),
            ],
            data: const [0, 1],
          ),
          width: 300,
        ),
      );
      // The cell that wraps is in the scrolling pane; the pinned pane's rows
      // must still line up with it. A floor was not enough — a cell that grew
      // past it put the two panes eight pixels out — so the height is exact
      // and anything longer is cut.
      // The *second* row, where both cells are one line: the first row's long
      // cell overflows the height it is held to and is clipped, so its text
      // sits higher than the cell does and proves nothing. Where row two
      // begins is the question — and it only lines up if row one was the same
      // height in both panes.
      expect(
        tester.getRect(find.text('p1')).top,
        tester.getRect(find.text('s1')).top,
        reason: 'the second row is level across both panes',
      );
    });

    testWidgets('many columns are not squeezed into illegibility',
        (tester) async {
      // Fifteen sharing a declared width came out thirty-seven pixels each.
      // Past a floor the table grows and scrolls instead.
      Future<double> widthOf(int columns) async {
        await tester.pumpWidget(
          _host(
            Table<int>(
              scroll: const TableScroll(x: 1100),
              columns: [
                for (var i = 0; i < columns; i++)
                  TableColumn<int>(title: Text('H$i'), value: (v) => 'c$i'),
              ],
              data: const [0],
            ),
            width: 800,
          ),
        );
        await tester.pumpAndSettle();
        return tester.getRect(find.text('H1')).left -
            tester.getRect(find.text('H0')).left;
      }

      expect(await widthOf(5), greaterThan(150), reason: 'room to spare');
      expect(await widthOf(15), greaterThanOrEqualTo(100),
          reason: 'and a floor once there is not');
    });

    testWidgets('a table is never laid out narrower than its own columns',
        (tester) async {
      // Fifteen columns at the hundred-pixel floor want fifteen hundred, and
      // the width declared was eleven hundred. Held to the declared one the
      // table overflowed its box and the scroll ran only as far as the box —
      // four hundred pixels of table that could not be reached at all.
      await tester.pumpWidget(
        _host(
          Table<int>(
            scroll: const TableScroll(x: 1100, y: 220),
            columns: [
              TableColumn<int>(
                title: const Text('Pin'),
                width: 160,
                fixed: TableColumnFixed.start,
                value: (v) => 'p$v',
              ),
              for (var i = 0; i < 15; i++)
                TableColumn<int>(title: Text('N$i'), value: (v) => 'n$i-$v'),
            ],
            data: const [0, 1, 2],
          ),
          width: 800,
        ),
      );
      expect(find.text('N0'), findsOneWidget);
      expect(find.text('N14'), findsNothing, reason: 'not yet in view');

      final pointer = TestPointer(1, PointerDeviceKind.trackpad);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('n0-1'))),
      );
      for (var i = 1; i <= 12; i++) {
        await tester.sendEventToBinding(pointer.scroll(Offset(120.0 * i, 0)));
        await tester.pumpAndSettle();
      }

      expect(
        tester.getRect(find.text('N14')).right,
        lessThanOrEqualTo(tester.getRect(find.byType(Table<int>)).right + 1),
        reason: 'the last column can be reached',
      );
      // The pinned one is still where it was, and the first of the ones that
      // travel has gone — off the edge and, being off it, unbuilt.
      expect(find.text('Pin'), findsOneWidget);
      expect(find.text('N0'), findsNothing);
    });

    testWidgets('nor is one without a pinned column', (tester) async {
      // The same reckoning on the other path, where the whole table is inside
      // one scroll view rather than a pane of it.
      await tester.pumpWidget(
        _host(
          Table<int>(
            scroll: const TableScroll(x: 1100, y: 220),
            columns: [
              for (var i = 0; i < 15; i++)
                TableColumn<int>(title: Text('N$i'), value: (v) => 'n$i-$v'),
            ],
            data: const [0, 1, 2],
          ),
          width: 800,
        ),
      );
      final first = tester.getRect(find.text('N0')).left;

      final pointer = TestPointer(1, PointerDeviceKind.trackpad);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('n0-1'))),
      );
      for (var i = 1; i <= 12; i++) {
        await tester.sendEventToBinding(pointer.scroll(Offset(120.0 * i, 0)));
        await tester.pumpAndSettle();
      }
      // Fifteen hundred of columns in an eight-hundred-wide box.
      expect(first - tester.getRect(find.text('N0')).left, closeTo(700, 1));
    });

    testWidgets('the floor is a token', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          theme: ThemeData(
            components: const ComponentsConfig(
              table: TableToken(columnMinWidth: 200),
            ),
          ),
          child: m.MaterialApp(
            home: m.Scaffold(
              body: Center(
                child: SizedBox(
                  width: 800,
                  child: Table<int>(
                    scroll: const TableScroll(x: 1100),
                    columns: [
                      for (var i = 0; i < 15; i++)
                        TableColumn<int>(
                          title: Text('H$i'),
                          value: (v) => 'c$i',
                        ),
                    ],
                    data: const [0],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('H1')).left -
            tester.getRect(find.text('H0')).left,
        greaterThanOrEqualTo(200),
      );
    });

    testWidgets('a rule stands between the columns when asked', (tester) async {
      // There are no panes any more — one viewport holds every column — so
      // the rule belongs to the cell that carries it, and the one beside a
      // pinned column is the same rule as any other.
      bool ruled() => find
          .byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).border is Border &&
                // Not the table's own outline, which is a border on every
                // side and the only one that is rounded.
                (w.decoration as BoxDecoration).borderRadius == null &&
                ((w.decoration as BoxDecoration).border! as Border).right !=
                    BorderSide.none,
          )
          .evaluate()
          .isNotEmpty;

      await tester.pumpWidget(pinned(y: 200));
      expect(ruled(), isFalse, reason: 'no rules were asked for');

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _host(
          Table<int>(
            bordered: true,
            scroll: const TableScroll(x: 1000, y: 200),
            columns: [
              TableColumn<int>(
                title: const Text('Pin'),
                width: 100,
                fixed: TableColumnFixed.start,
                value: (v) => 'p$v',
              ),
              for (var c = 0; c < 5; c++)
                TableColumn<int>(title: Text('C$c'), value: (v) => 'c${c}r$v'),
            ],
            data: const [0, 1],
          ),
          width: 400,
        ),
      );
      expect(ruled(), isTrue);
    });

    test('a pinned column must name a width', () {
      expect(
        () => TableColumn<int>(
          title: const Text('Pin'),
          fixed: TableColumnFixed.start,
          value: (v) => v,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('an empty pinned table still shows its heading',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Table<int>(
            scroll: const TableScroll(x: 900),
            columns: [
              TableColumn<int>(
                title: const Text('Pin'),
                width: 80,
                fixed: TableColumnFixed.start,
                value: (v) => v,
              ),
              TableColumn<int>(title: const Text('C'), value: (v) => v),
            ],
            data: const [],
          ),
          width: 300,
        ),
      );
      expect(find.text('Pin'), findsOneWidget);
      expect(find.byType(Empty), findsOneWidget);
    });
  });

  group('hovering', () {
    testWidgets('lights the row under the pointer, and only that one',
        (tester) async {
      // The fill used to live on the row's decoration, which only the whole
      // table can redraw — so every twitch of the pointer rebuilt every row,
      // ninety milliseconds of it at five hundred rows. It lives in the cell
      // now; this is the behaviour that had to survive the move.
      await tester.pumpWidget(
        _host(Table<_User>(columns: [_name()], data: _users)),
      );

      Color? fillAt(String text) {
        final box = find
            .ancestor(of: find.text(text), matching: find.byType(ColoredBox))
            .evaluate()
            .map((e) => (e.widget as ColoredBox).color)
            .where((c) => c.a > 0);
        return box.isEmpty ? null : box.first;
      }

      expect(fillAt('Ann'), isNull, reason: 'nothing is hovered yet');

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('Ann'))),
      );
      await tester.pumpAndSettle();

      expect(fillAt('Ann'), isNotNull, reason: 'the row it is over');
      expect(fillAt('Bartholomew Longname'), isNull, reason: 'and no other');
    });

    testWidgets('rowHoverable: false lights nothing', (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            columns: [_name()],
            data: _users,
            rowHoverable: false,
          ),
        ),
      );
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('Ann'))),
      );
      await tester.pumpAndSettle();
      expect(
        find
            .ancestor(of: find.text('Ann'), matching: find.byType(ColoredBox))
            .evaluate()
            .where((e) => (e.widget as ColoredBox).color.a > 0),
        isEmpty,
      );
    });
  });

  group('size', () {
    Future<double> rowHeight(WidgetTester tester, ControlSize? size) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            columns: [_name()],
            data: const [_User('Ann', 31)],
            size: size,
            showHeader: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getRect(find.byType(Table<_User>)).height;
    }

    testWidgets('a preset sets how much room a row takes', (tester) async {
      final small = await rowHeight(tester, SoftSize.small);
      final middle = await rowHeight(tester, null);
      final large = await rowHeight(tester, SoftSize.large);
      expect(small, lessThan(middle));
      expect(middle, lessThan(large));
    });

    testWidgets('a height of your own is the height of the row',
        (tester) async {
      // The number says how tall the row is, so the padding that would
      // otherwise have decided it stands down — adding to it would mean
      // 48 came out at 52.
      expect(await rowHeight(tester, const ControlSize.height(48)), 48);
      expect(await rowHeight(tester, const ControlSize.height(70)), 70);
    });

    testWidgets('a row never shrinks below what is in it', (tester) async {
      // A floor, not a straitjacket: ask for less than the content needs and
      // the content wins rather than being clipped.
      final asked = await rowHeight(tester, const ControlSize.height(4));
      expect(asked, greaterThan(4));
    });

    testWidgets('defaults reach a table that names nothing', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          defaults: const ComponentDefaults(
            table: TableDefaults(showHeader: false),
          ),
          child: m.MaterialApp(
            home: m.Scaffold(
              body: Table<_User>(columns: [_name()], data: _users),
            ),
          ),
        ),
      );
      expect(find.text('Name'), findsNothing);
    });

    testWidgets('a token sets the padding for every table', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          theme: ThemeData(
            components: const ComponentsConfig(
              table: TableToken(cellPaddingBlock: 40),
            ),
          ),
          child: m.MaterialApp(
            home: m.Scaffold(
              body: Table<_User>(
                columns: [_name()],
                data: const [_User('Ann', 31)],
                showHeader: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(Table<_User>)).height,
        greaterThan(80),
        reason: 'forty above and forty below',
      );
    });
  });

  group('sorting', () {
    const people = [
      _User('Chen', 27),
      _User('Ann', 45),
      _User('Bart', 31),
    ];

    List<String> shown(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((s) => s != 'Name' && s != 'Age')
        .toList();

    Widget table({
      List<TableSort>? sort,
      List<TableSort>? defaultSort,
      ValueChanged<List<TableSort>>? onSortChanged,
      int Function(_User, _User)? sorter,
      TableScroll? scroll,
    }) =>
        _host(
          Table<_User>(
            scroll: scroll,
            sort: sort,
            defaultSort: defaultSort,
            onSortChanged: onSortChanged,
            data: people,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                sortable: sorter == null,
                sorter: sorter,
                value: (u) => u.name,
              ),
              TableColumn<_User>(
                title: const Text('Age'),
                sortable: true,
                value: (u) => u.age,
              ),
            ],
          ),
        );

    testWidgets('a heading tapped cycles up, down, and back', (tester) async {
      await tester.pumpWidget(table());
      expect(shown(tester), ['Chen', '27', 'Ann', '45', 'Bart', '31'],
          reason: 'the order they came in');

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(shown(tester), ['Ann', '45', 'Bart', '31', 'Chen', '27']);

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(shown(tester), ['Chen', '27', 'Bart', '31', 'Ann', '45']);

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(shown(tester), ['Chen', '27', 'Ann', '45', 'Bart', '31'],
          reason: 'a third tap gives the rows back as they were');
    });

    testWidgets('a value is compared without being told how', (tester) async {
      await tester.pumpWidget(table());
      await tester.tap(find.text('Age'));
      await tester.pumpAndSettle();
      // Numbers, not the words: 45 sorts after 31, where '45' would not.
      expect(shown(tester), ['Chen', '27', 'Bart', '31', 'Ann', '45']);
    });

    testWidgets('a sorter of your own says how instead', (tester) async {
      // Backwards, which comparing the names themselves never gives.
      await tester
          .pumpWidget(table(sorter: (a, b) => b.name.compareTo(a.name)));
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(shown(tester), ['Chen', '27', 'Bart', '31', 'Ann', '45']);
    });

    testWidgets('a default sort is what it starts on', (tester) async {
      await tester.pumpWidget(
        table(defaultSort: const [TableSort(1, TableSortOrder.descending)]),
      );
      expect(shown(tester), ['Ann', '45', 'Bart', '31', 'Chen', '27']);
    });

    testWidgets('a sort given is the sort shown, and tapping only tells',
        (tester) async {
      List<TableSort>? told;
      await tester.pumpWidget(table(
        sort: const [TableSort(0, TableSortOrder.ascending)],
        onSortChanged: (next) => told = next,
      ));
      expect(shown(tester), ['Ann', '45', 'Bart', '31', 'Chen', '27']);

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(told, const [TableSort(0, TableSortOrder.descending)],
          reason: 'it said what it would have become');
      expect(shown(tester), ['Ann', '45', 'Bart', '31', 'Chen', '27'],
          reason: 'and changed nothing itself');
    });

    testWidgets('the carets darken under the hand, and take their time',
        (tester) async {
      // The reference gives the sorter a colour and a transition on it, and
      // darkens it while the heading is hovered. The one in force keeps its
      // own colour: the hand has nothing to add to a column already sorted.
      await tester.pumpWidget(table());
      await tester.pumpAndSettle();

      Color caretColour({required bool up}) => ((tester
              .widgetList<CustomPaint>(find.byWidgetPredicate((w) =>
                  w is CustomPaint &&
                  w.painter.runtimeType.toString() == '_CaretPainter'))
              .elementAt(up ? 0 : 1)
              .painter!) as dynamic)
          .color as Color;

      final resting = caretColour(up: true);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Name')));
      await tester.pump();

      // Part way through, it is neither what it was nor what it will be.
      await tester.pump(const Duration(milliseconds: 60));
      final partWay = caretColour(up: true);
      expect(partWay, isNot(resting), reason: 'it has started to darken');

      await tester.pumpAndSettle();
      final darkened = caretColour(up: true);
      expect(darkened, isNot(resting));
      expect(darkened, isNot(partWay), reason: 'and it took its time');

      // Away again, and back to what it was.
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(caretColour(up: true), resting);
    });

    testWidgets('the caret in force keeps its own colour', (tester) async {
      await tester.pumpWidget(
        table(defaultSort: const [TableSort(0, TableSortOrder.ascending)]),
      );
      await tester.pumpAndSettle();

      Color caretColour({required bool up}) => ((tester
              .widgetList<CustomPaint>(find.byWidgetPredicate((w) =>
                  w is CustomPaint &&
                  w.painter.runtimeType.toString() == '_CaretPainter'))
              .elementAt(up ? 0 : 1)
              .painter!) as dynamic)
          .color as Color;

      final inForce = caretColour(up: true);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Name')));
      await tester.pumpAndSettle();

      expect(caretColour(up: true), inForce, reason: 'the hand adds nothing');
      expect(caretColour(up: false), isNot(inForce),
          reason: 'while the other one darkens with the rest');
    });

    testWidgets('a column that does not sort has no carets and no tap',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: people,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
              ),
            ],
          ),
        ),
      );
      expect(
        find.byWidgetPredicate((w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_CaretPainter'),
        findsNothing,
      );
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(shown(tester), ['Chen', 'Ann', 'Bart'], reason: 'nothing moved');
    });

    testWidgets('the rows a scrolling table shows are the sorted ones',
        (tester) async {
      // The lazy body reads the same order as the grid: a row's index is its
      // place in what is shown, not in what was handed over.
      await tester.pumpWidget(table(scroll: const TableScroll(y: 200)));
      await tester.tap(find.text('Age'));
      await tester.pumpAndSettle();
      expect(shown(tester), ['Chen', '27', 'Bart', '31', 'Ann', '45']);
    });

    testWidgets('ties keep the order they came in', (tester) async {
      // Dart's sort is only stable below thirty-two elements, so past that
      // the index has to break the tie — forty rows of one value came out
      // shuffled without it.
      final same = [for (var i = 0; i < 40; i++) _User('n$i', 1)];
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: same,
            scroll: const TableScroll(y: 300),
            defaultSort: const [TableSort(0, TableSortOrder.ascending)],
            columns: [
              TableColumn<_User>(
                title: const Text('Age'),
                sortable: true,
                value: (u) => u.age,
              ),
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only the rows on screen are built, and those are the first of them.
      final names = shown(tester).where((s) => s != '1').toList();
      expect(names.length, greaterThan(4));
      expect(names, [for (var i = 0; i < names.length; i++) 'n$i']);
    });

    testWidgets('a table controlled and then let go keeps no stale sort',
        (tester) async {
      // Four rows whose names and ages do not run the same way, or a tap
      // stored where it should not have been would look like the right answer.
      const four = [
        _User('Chen', 27),
        _User('Ann', 45),
        _User('Bart', 31),
        _User('Dee', 50),
      ];
      Widget host({List<TableSort>? sort}) => _host(
            Table<_User>(
              data: four,
              sort: sort,
              columns: [
                TableColumn<_User>(
                  title: const Text('Name'),
                  sortable: true,
                  value: (u) => u.name,
                ),
                TableColumn<_User>(
                  title: const Text('Age'),
                  sortable: true,
                  value: (u) => u.age,
                ),
              ],
            ),
          );

      // Uncontrolled first, so the table has a sort of its own to come back to.
      await tester.pumpWidget(host());
      await tester.tap(find.text('Age'));
      await tester.pumpAndSettle();
      expect(shown(tester),
          ['Chen', '27', 'Bart', '31', 'Ann', '45', 'Dee', '50']);

      // Then given one, where a tap may only tell.
      await tester.pumpWidget(
        host(sort: const [TableSort(0, TableSortOrder.ascending)]),
      );
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(
          shown(tester), ['Ann', '45', 'Bart', '31', 'Chen', '27', 'Dee', '50'],
          reason: 'what it was told, and the tap only told');

      // Then let go: back to its own sort, not to what that tap would have
      // made of it.
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      expect(shown(tester),
          ['Chen', '27', 'Bart', '31', 'Ann', '45', 'Dee', '50']);
    });

    testWidgets('a row with nothing in the column sorts last either way',
        (tester) async {
      const some = [_User('has', 2), _User('none', -1), _User('also', 1)];
      Widget host(TableSortOrder order) => _host(
            Table<_User>(
              data: some,
              defaultSort: [TableSort(0, order)],
              columns: [
                TableColumn<_User>(
                  title: const Text('Age'),
                  sortable: true,
                  value: (u) => u.age == -1 ? null : u.age,
                ),
                TableColumn<_User>(
                  title: const Text('Name'),
                  value: (u) => u.name,
                ),
              ],
            ),
          );

      // Turned round with everything else, a blank cell rose to the top of a
      // descending sort, which is not what a blank cell means.
      await tester.pumpWidget(host(TableSortOrder.ascending));
      expect(shown(tester).last, 'none');

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(host(TableSortOrder.descending));
      expect(shown(tester).last, 'none');
    });

    testWidgets('the whole heading answers, not the word in it',
        (tester) async {
      await tester.pumpWidget(table());
      final cell = tester.getRect(
        find
            .ancestor(
              of: find.text('Name'),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      final word = tester.getRect(find.text('Name'));
      expect(cell.width, greaterThan(word.width + 8),
          reason: 'the padding is part of it, not just the word');

      // And a tap in the padding, clear of the word, still sorts.
      await tester.tapAt(Offset(cell.right - 4, cell.center.dy));
      await tester.pumpAndSettle();
      expect(shown(tester), ['Ann', '45', 'Bart', '31', 'Chen', '27']);
    });

    testWidgets('a sortable heading lights up under the pointer',
        (tester) async {
      Color? fillOver(Finder heading) {
        final boxes = find
            .ancestor(of: heading, matching: find.byType(ColoredBox))
            .evaluate()
            .map((e) => (e.widget as ColoredBox).color)
            .where((c) => c.a != 0);
        return boxes.isEmpty ? null : boxes.first;
      }

      await tester.pumpWidget(table());
      expect(fillOver(find.text('Name')), isNull);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Name')));
      await tester.pumpAndSettle();

      expect(fillOver(find.text('Name')), isNotNull);
      expect(fillOver(find.text('Chen')), isNull, reason: 'that one only');
    });

    testWidgets('the column being sorted by keeps the fill', (tester) async {
      Color? fillOver(Finder heading) {
        final boxes = find
            .ancestor(of: heading, matching: find.byType(ColoredBox))
            .evaluate()
            .map((e) => (e.widget as ColoredBox).color)
            .where((c) => c.a != 0);
        return boxes.isEmpty ? null : boxes.first;
      }

      // Sorted before anybody touched it, so the fill arrives with the sort
      // and not with the hand.
      await tester.pumpWidget(
        table(defaultSort: const [TableSort(1, TableSortOrder.ascending)]),
      );
      expect(fillOver(find.text('Age')), isNotNull);
      expect(fillOver(find.text('Name')), isNull, reason: 'that one only');

      // And it moves with the sort.
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(fillOver(find.text('Name')), isNotNull);
      expect(fillOver(find.text('Age')), isNull);

      // A third tap gives the rows back, and the fill goes with them.
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(fillOver(find.text('Name')), isNull);
    });

    testWidgets('a heading that does not sort stays quiet', (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: people,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
              ),
            ],
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Name')));
      await tester.pumpAndSettle();

      final lit = find
          .ancestor(of: find.text('Name'), matching: find.byType(ColoredBox))
          .evaluate()
          .map((e) => (e.widget as ColoredBox).color)
          .where((c) => c.a != 0);
      expect(lit, isEmpty, reason: 'nothing would happen if it were tapped');
    });

    testWidgets('the carets stand at the cell edge, not beside the word',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: people,
            columns: [
              TableColumn<_User>(
                title: const Text('N'),
                width: 200,
                sortable: true,
                value: (u) => u.name,
              ),
            ],
          ),
        ),
      );
      final carets = tester.getRect(
        find
            .byWidgetPredicate((w) =>
                w is CustomPaint &&
                w.painter.runtimeType.toString() == '_CaretPainter')
            .first,
      );
      final word = tester.getRect(find.text('N'));
      // A column of headings whose carets each sat at the end of a word of
      // its own length is a ragged edge.
      expect(carets.left - word.right, greaterThan(100));
    });

    testWidgets('columns with a priority sort together, the higher first',
        (tester) async {
      // City first, then age within a city.
      const crowd = [
        _User('b', 2),
        _User('a', 3),
        _User('b', 1),
        _User('a', 1),
      ];
      List<TableSort>? told;
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: crowd,
            onSortChanged: (next) => told = next,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                sortable: true,
                sortPriority: 2,
                value: (u) => u.name,
              ),
              TableColumn<_User>(
                title: const Text('Age'),
                sortable: true,
                sortPriority: 1,
                value: (u) => u.age,
              ),
            ],
          ),
          width: 700,
        ),
      );

      await tester.tap(find.text('Age'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();

      expect(told!.length, 2, reason: 'the second joined the first');
      // Name is the more telling, so it is compared first whichever order
      // they were tapped in.
      expect(told!.first.column, 0);

      final order = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .where((s) => s == 'a' || s == 'b')
          .toList();
      expect(order, ['a', 'a', 'b', 'b']);

      final ages = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .where((s) => s == '1' || s == '2' || s == '3')
          .toList();
      expect(ages, ['1', '3', '1', '2'], reason: 'age orders within each name');
    });

    testWidgets('a column with no priority sorts alone', (tester) async {
      List<TableSort>? told;
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: people,
            onSortChanged: (next) => told = next,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                sortable: true,
                sortPriority: 2,
                value: (u) => u.name,
              ),
              TableColumn<_User>(
                title: const Text('Age'),
                sortable: true,
                value: (u) => u.age,
              ),
            ],
          ),
          width: 700,
        ),
      );

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(told!.length, 1);

      await tester.tap(find.text('Age'));
      await tester.pumpAndSettle();
      expect(told!.length, 1, reason: 'it cleared the other');
      expect(told!.single.column, 1);
    });

    testWidgets('a third tap drops one column and leaves the rest',
        (tester) async {
      List<TableSort>? told;
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: people,
            onSortChanged: (next) => told = next,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                sortable: true,
                sortPriority: 2,
                value: (u) => u.name,
              ),
              TableColumn<_User>(
                title: const Text('Age'),
                sortable: true,
                sortPriority: 1,
                value: (u) => u.age,
              ),
            ],
          ),
          width: 700,
        ),
      );

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Age'));
      await tester.pumpAndSettle();
      expect(told!.length, 2);

      // Age: ascending, descending, gone — and Name stays.
      await tester.tap(find.text('Age'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Age'));
      await tester.pumpAndSettle();
      expect(told!.length, 1);
      expect(told!.single.column, 0);
    });

    testWidgets('the order given is put right by the priorities',
        (tester) async {
      // Named the wrong way round on purpose: a priority means one thing
      // everywhere, so the table compares Name first regardless.
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: const [_User('b', 1), _User('a', 2)],
            defaultSort: const [
              TableSort(1, TableSortOrder.ascending),
              TableSort(0, TableSortOrder.ascending),
            ],
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                sortable: true,
                sortPriority: 5,
                value: (u) => u.name,
              ),
              TableColumn<_User>(
                title: const Text('Age'),
                sortable: true,
                sortPriority: 1,
                value: (u) => u.age,
              ),
            ],
          ),
          width: 700,
        ),
      );
      final order = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .where((s) => s == 'a' || s == 'b')
          .toList();
      expect(order, ['a', 'b']);
    });

    test('a priority needs a column that sorts', () {
      expect(
        () => TableColumn<_User>(
          title: const Text('Name'),
          value: (u) => u.name,
          sortPriority: 1,
        ),
        throwsAssertionError,
      );
    });

    test('a sortable column needs something to compare', () {
      expect(
        () => TableColumn<_User>(
          title: const Text('Name'),
          sortable: true,
          builder: (_, __, ___) => const Text('x'),
        ),
        throwsAssertionError,
      );
    });
  });

  group('filtering', () {
    const people = [
      _User('Chen', 27),
      _User('Ann', 45),
      _User('Bart', 31),
      _User('Dee', 27),
    ];

    List<String> names(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((s) => people.any((p) => p.name == s))
        .toList();

    // A filter menu opens in the overlay, so the app has to have one.
    Widget host(Widget child) => ConfigProvider(
          child: m.MaterialApp(
            navigatorKey: UiKit.navigatorKey,
            home: m.Scaffold(
              body: Center(child: SizedBox(width: 600, child: child)),
            ),
          ),
        );

    Widget table({
      Map<int, List<Object?>>? filters,
      Map<int, List<Object?>>? defaultFilters,
      ValueChanged<Map<int, List<Object?>>>? onFiltersChanged,
      bool multiple = true,
      bool Function(Object?, _User)? onFilter,
      List<TableSort>? defaultSort,
    }) =>
        host(
          Table<_User>(
            data: people,
            filters: filters,
            defaultFilters: defaultFilters,
            onFiltersChanged: onFiltersChanged,
            defaultSort: defaultSort,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
                filterMultiple: multiple,
                onFilter: onFilter,
                filters: const [
                  TableFilter('Ann', 'Ann'),
                  TableFilter('Bart', 'Bart'),
                ],
              ),
              TableColumn<_User>(
                title: const Text('Age'),
                sortable: true,
                value: (u) => u.age,
                filters: const [TableFilter('young', 27)],
              ),
            ],
          ),
        );

    // The label is in the table as well as in the menu; the menu is above.
    Future<void> choose(WidgetTester tester, String label) async {
      await tester.tap(find.text(label).last);
      await tester.pump();
    }

    Future<void> openMenu(WidgetTester tester, int at) async {
      await tester.tap(
        find
            .byWidgetPredicate((w) =>
                w is CustomPaint &&
                w.painter.runtimeType.toString() == '_FunnelPainter')
            .at(at),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
        'a column with filters wears a funnel, and one without does not',
        (tester) async {
      await tester.pumpWidget(table());
      expect(
        find.byWidgetPredicate((w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_FunnelPainter'),
        findsNWidgets(2),
      );
    });

    testWidgets('choosing narrows the rows', (tester) async {
      await tester.pumpWidget(table());
      expect(names(tester), ['Chen', 'Ann', 'Bart', 'Dee']);

      await openMenu(tester, 0);
      await choose(tester, 'Ann');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(names(tester), ['Ann']);
    });

    testWidgets('within a column the choices are alternatives', (tester) async {
      await tester.pumpWidget(table());
      await openMenu(tester, 0);
      await choose(tester, 'Ann');
      await choose(tester, 'Bart');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(names(tester), ['Ann', 'Bart'],
          reason: 'either, not both at once');
    });

    testWidgets('across columns a row has to answer every one', (tester) async {
      await tester.pumpWidget(table());
      await openMenu(tester, 0);
      await choose(tester, 'Ann');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await openMenu(tester, 1);
      await choose(tester, 'young');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(names(tester), isEmpty, reason: 'Ann is 45, so nothing is left');
    });

    testWidgets('one at a time where the column says so', (tester) async {
      await tester.pumpWidget(table(multiple: false));
      await openMenu(tester, 0);
      await choose(tester, 'Ann');
      await choose(tester, 'Bart');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(names(tester), ['Bart'], reason: 'the second replaced the first');
    });

    testWidgets('reset gives every row back', (tester) async {
      await tester.pumpWidget(
        table(defaultFilters: const {
          0: ['Ann']
        }),
      );
      expect(names(tester), ['Ann']);

      await openMenu(tester, 0);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(names(tester), ['Chen', 'Ann', 'Bart', 'Dee']);
    });

    testWidgets('an onFilter of your own says what a choice means',
        (tester) async {
      // Everyone but the one chosen, which no comparison of values would give.
      await tester.pumpWidget(
        table(onFilter: (choice, user) => user.name != choice),
      );
      await openMenu(tester, 0);
      await choose(tester, 'Ann');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(names(tester), ['Chen', 'Bart', 'Dee']);
    });

    testWidgets('filters given are the filters shown, and choosing only tells',
        (tester) async {
      Map<int, List<Object?>>? told;
      await tester.pumpWidget(table(
        filters: const {
          0: ['Bart']
        },
        onFiltersChanged: (next) => told = next,
      ));
      expect(names(tester), ['Bart']);

      await openMenu(tester, 0);
      await choose(tester, 'Ann');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(told, {
        0: ['Bart', 'Ann'],
      });
      expect(names(tester), ['Bart'], reason: 'and changed nothing itself');
    });

    testWidgets('narrowing and sorting are the same table', (tester) async {
      await tester.pumpWidget(table(
        defaultFilters: const {
          1: [27]
        },
        defaultSort: const [TableSort(0, TableSortOrder.ascending)],
      ));
      expect(names(tester), ['Chen', 'Dee'],
          reason: 'the twenty-sevens, by name');
    });

    testWidgets('the funnel of a column being narrowed is marked',
        (tester) async {
      Color funnelAt(WidgetTester tester, int at) => (tester
              .widgetList<CustomPaint>(find.byWidgetPredicate((w) =>
                  w is CustomPaint &&
                  w.painter.runtimeType.toString() == '_FunnelPainter'))
              .elementAt(at)
              .painter! as dynamic)
          .color as Color;

      await tester.pumpWidget(table(defaultFilters: const {
        0: ['Ann']
      }));
      expect(funnelAt(tester, 0), isNot(funnelAt(tester, 1)));
    });

    testWidgets('a column present with nothing chosen narrows nothing',
        (tester) async {
      // A caller may well hand over a map with an empty entry in it — that
      // column is simply not narrowing, and the ones after it still are.
      await tester.pumpWidget(table(defaultFilters: const {
        0: [],
        1: [27],
      }));
      expect(names(tester), ['Chen', 'Dee']);
    });

    testWidgets('the menu is a panel of its own, not the whole screen',
        (tester) async {
      // Dropdown.content is handed straight to the overlay — that is what it
      // is for — so without a panel the menu had no ground of its own and
      // took every pixel the overlay offered it.
      await tester.pumpWidget(table());
      await openMenu(tester, 0);

      expect(find.byType(DropdownPanel), findsOneWidget);
      final menu = tester.getRect(find.byType(DropdownPanel));
      final screen = tester.getRect(find.byType(m.MaterialApp));
      expect(menu.width, lessThan(screen.width / 2));
      expect(menu.width, greaterThanOrEqualTo(120),
          reason: 'a menu narrower than this is one you cannot read');
    });

    testWidgets('the rule under the choices runs the width of the panel',
        (tester) async {
      await tester.pumpWidget(table());
      await openMenu(tester, 0);

      final panel = tester.getRect(find.byType(DropdownPanel));
      final rule = tester.getRect(
        find.descendant(
          of: find.byType(DropdownPanel),
          matching: find.byWidgetPredicate((w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border is Border &&
              // The rule, not a checkbox: a top side and nothing else.
              ((w.decoration as BoxDecoration).border! as Border).top !=
                  BorderSide.none &&
              ((w.decoration as BoxDecoration).border! as Border).left ==
                  BorderSide.none),
        ),
      );
      // The rule belongs to the block of buttons and runs across the whole
      // of it; the panel clips it to its own corners.
      expect(rule.left, closeTo(panel.left, 0.5));
      expect(rule.right, closeTo(panel.right, 0.5));
      expect(rule.bottom, closeTo(panel.bottom, 0.5));

      // sizeXS either side, and sizeXS - lineWidth above and below, so the
      // rule does not add to the height.
      final ok = tester.getRect(find.text('OK'));
      expect(panel.right - ok.right, greaterThan(8),
          reason: 'paddingXS plus the button\'s own');
    });

    testWidgets('a long list of choices scrolls instead of growing',
        (tester) async {
      await tester.pumpWidget(
        host(
          Table<_User>(
            data: people,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
                filters: [
                  for (var i = 0; i < 40; i++) TableFilter('n$i', 'n$i'),
                ],
              ),
            ],
          ),
        ),
      );
      await openMenu(tester, 0);
      expect(tester.getRect(find.byType(DropdownPanel)).height, lessThan(400),
          reason: 'two hundred and sixty-four and the footer');
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('the funnel takes a ground of its own under the hand',
        (tester) async {
      Color? funnelFill(WidgetTester tester) {
        final painted = find
            .ancestor(
              of: find.byWidgetPredicate((w) =>
                  w is CustomPaint &&
                  w.painter.runtimeType.toString() == '_FunnelPainter'),
              matching: find.byType(DecoratedBox),
            )
            .evaluate()
            .map((e) => (e.widget as DecoratedBox).decoration)
            .whereType<BoxDecoration>()
            .map((d) => d.color)
            .where((c) => c != null && c.a != 0);
        return painted.isEmpty ? null : painted.first;
      }

      Color funnelColour(WidgetTester tester) => ((tester
              .widgetList<CustomPaint>(find.byWidgetPredicate((w) =>
                  w is CustomPaint &&
                  w.painter.runtimeType.toString() == '_FunnelPainter'))
              .first
              .painter!) as dynamic)
          .color as Color;

      await tester.pumpWidget(table());
      expect(funnelFill(tester), isNull);
      final idle = funnelColour(tester);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find
          .byWidgetPredicate((w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_FunnelPainter')
          .first));
      await tester.pumpAndSettle();

      expect(funnelFill(tester), isNotNull);
      // And the mark itself darkens: the ground alone would leave a mark you
      // can barely see sitting on it.
      expect(funnelColour(tester), isNot(idle));
    });

    Widget searchable({
      bool search = true,
      bool Function(String, TableFilter)? match,
    }) =>
        host(
          Table<_User>(
            data: people,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
                filterSearch: search,
                filterSearchMatch: match,
                filters: const [
                  TableFilter('Ann', 'Ann'),
                  TableFilter('Bart', 'Bart'),
                  TableFilter('Chen', 'Chen'),
                ],
              ),
            ],
          ),
        );

    testWidgets('a menu is searched only where the column asks',
        (tester) async {
      await tester.pumpWidget(searchable(search: false));
      await openMenu(tester, 0);
      expect(find.byType(Input), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(searchable());
      await openMenu(tester, 0);
      expect(find.byType(Input), findsOneWidget);
    });

    testWidgets('typing narrows the menu, ignoring case and spaces',
        (tester) async {
      await tester.pumpWidget(searchable());
      await openMenu(tester, 0);
      expect(find.byType(Checkbox), findsNWidgets(3));

      await tester.enterText(find.byType(Input), '  aN ');
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.widgetWithText(Checkbox, 'Ann'), findsOneWidget);
    });

    testWidgets('a choice out of sight is still a choice', (tester) async {
      // Narrowing the menu must not quietly drop what has been ticked.
      await tester.pumpWidget(searchable());
      await openMenu(tester, 0);
      await choose(tester, 'Ann');

      await tester.enterText(find.byType(Input), 'bart');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Checkbox, 'Ann'), findsNothing);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(names(tester), ['Ann']);
    });

    testWidgets('a match of your own says what typing means', (tester) async {
      // Only where the label begins with what was typed, which a substring
      // match would not give: 'Bart' holds an 'a' but does not start with one.
      await tester.pumpWidget(searchable(
        search: false,
        match: (typed, choice) => choice.label.startsWith(typed),
      ));
      await openMenu(tester, 0);
      await tester.enterText(find.byType(Input), 'A');
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.widgetWithText(Checkbox, 'Ann'), findsOneWidget);
      expect(find.widgetWithText(Checkbox, 'Bart'), findsNothing);
    });

    test('searching a menu needs a menu to search', () {
      expect(
        () => TableColumn<_User>(
          title: const Text('Name'),
          value: (u) => u.name,
          filterSearch: true,
        ),
        throwsAssertionError,
      );
    });

    test('a column with filters needs something to match on', () {
      expect(
        () => TableColumn<_User>(
          title: const Text('Name'),
          builder: (_, __, ___) => const Text('x'),
          filters: const [TableFilter('Ann', 'Ann')],
        ),
        throwsAssertionError,
      );
    });

    test('a column with an empty filter list is a mistake', () {
      expect(
        () => TableColumn<_User>(
          title: const Text('Name'),
          value: (u) => u.name,
          filters: const [],
        ),
        throwsAssertionError,
      );
    });
  });

  group('selection', () {
    const people = [
      _User('Chen', 27),
      _User('Ann', 45),
      _User('Bart', 31),
    ];

    List<String> names(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((s) => people.any((p) => p.name == s))
        .toList();

    Widget table({
      TableSelectionMode mode = TableSelectionMode.checkbox,
      List<_User>? selected,
      List<_User>? defaultSelected,
      ValueChanged<List<_User>>? onChanged,
      bool Function(_User)? selectable,
      bool showSelectAll = true,
      Map<int, List<Object?>>? defaultFilters,
    }) =>
        _host(
          Table<_User>(
            data: people,
            defaultFilters: defaultFilters,
            selection: TableSelection<_User>(
              mode: mode,
              selected: selected,
              defaultSelected: defaultSelected,
              onChanged: onChanged,
              selectable: selectable,
              showSelectAll: showSelectAll,
            ),
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
                filters: const [TableFilter('Ann', 'Ann')],
              ),
            ],
          ),
        );

    // The heading's box first, then one per row.
    Finder boxes() => find.byType(Checkbox);

    testWidgets('a column of boxes goes in front of the others',
        (tester) async {
      await tester.pumpWidget(table());
      expect(boxes(), findsNWidgets(4), reason: 'three rows and the heading');
      expect(
        tester.getRect(boxes().first).left,
        lessThan(tester.getRect(find.text('Name')).left),
      );
    });

    testWidgets('ticking a row reports it', (tester) async {
      List<_User>? told;
      await tester.pumpWidget(table(onChanged: (rows) => told = rows));

      await tester.tap(boxes().at(2));
      await tester.pumpAndSettle();
      expect(told, [people[1]], reason: 'Ann, the second row');

      await tester.tap(boxes().at(1));
      await tester.pumpAndSettle();
      expect(told, [people[1], people[0]]);

      await tester.tap(boxes().at(2));
      await tester.pumpAndSettle();
      expect(told, [people[0]], reason: 'and letting one go removes it');
    });

    testWidgets('the heading takes every row, and gives them back',
        (tester) async {
      await tester.pumpWidget(table());
      await tester.tap(boxes().first);
      await tester.pumpAndSettle();
      expect(
        tester.widgetList<Checkbox>(boxes()).every((b) => b.checked),
        isTrue,
      );

      await tester.tap(boxes().first);
      await tester.pumpAndSettle();
      expect(
        tester.widgetList<Checkbox>(boxes()).any((b) => b.checked),
        isFalse,
      );
    });

    testWidgets('the heading is part way when some rows are picked',
        (tester) async {
      await tester.pumpWidget(table(defaultSelected: const [_User('Ann', 45)]));
      final head = tester.widget<Checkbox>(boxes().first);
      expect(head.checked, isFalse);
      expect(head.indeterminate, isTrue);
    });

    testWidgets('a row that may not be picked is passed over', (tester) async {
      await tester.pumpWidget(
        table(selectable: (u) => u.name != 'Bart'),
      );
      expect(tester.widget<Checkbox>(boxes().at(3)).disabled, isTrue);

      // The heading reads as full once every row that *can* be picked is,
      // however many are barred.
      await tester.tap(boxes().first);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(boxes().first).checked, isTrue);
      expect(tester.widget<Checkbox>(boxes().at(3)).checked, isFalse);
    });

    testWidgets('the heading answers for the rows on show, not all of them',
        (tester) async {
      List<_User>? told;
      await tester.pumpWidget(table(
        defaultFilters: const {
          0: ['Ann'],
        },
        onChanged: (rows) => told = rows,
      ));
      expect(names(tester), ['Ann']);

      await tester.tap(boxes().first);
      await tester.pumpAndSettle();
      expect(told, [people[1]], reason: 'a filter narrows what "all" means');
    });

    testWidgets('a filter hides a picked row without un-picking it',
        (tester) async {
      List<_User>? told;
      await tester.pumpWidget(table(
        defaultSelected: const [_User('Chen', 27)],
        defaultFilters: const {
          0: ['Ann'],
        },
        onChanged: (rows) => told = rows,
      ));
      // Chen is picked but filtered away; taking "all" must not drop him.
      await tester.tap(boxes().first);
      await tester.pumpAndSettle();
      expect(told, [people[0], people[1]]);
    });

    testWidgets('radio picks one row and no more', (tester) async {
      List<_User>? told;
      await tester.pumpWidget(table(
        mode: TableSelectionMode.radio,
        onChanged: (rows) => told = rows,
      ));
      expect(boxes(), findsNothing, reason: 'dots, not boxes');
      expect(find.byType(Radio<bool>), findsNWidgets(3));

      await tester.tap(find.byType(Radio<bool>).at(0));
      await tester.pumpAndSettle();
      expect(told, [people[0]]);

      await tester.tap(find.byType(Radio<bool>).at(2));
      await tester.pumpAndSettle();
      expect(told, [people[2]], reason: 'the second replaced the first');
    });

    testWidgets('no box at the head where one would mean nothing',
        (tester) async {
      await tester.pumpWidget(table(showSelectAll: false));
      expect(boxes(), findsNWidgets(3), reason: 'the rows alone');
    });

    testWidgets('a selection given is the selection shown, and ticking tells',
        (tester) async {
      List<_User>? told;
      await tester.pumpWidget(table(
        selected: const [_User('Chen', 27)],
        onChanged: (rows) => told = rows,
      ));
      expect(tester.widget<Checkbox>(boxes().at(1)).checked, isTrue);

      await tester.tap(boxes().at(2));
      await tester.pumpAndSettle();
      expect(told, [people[0], people[1]]);
      expect(tester.widget<Checkbox>(boxes().at(2)).checked, isFalse,
          reason: 'and changed nothing itself');
    });

    testWidgets('the heading cannot be ticked when no row can', (tester) async {
      await tester.pumpWidget(table(selectable: (u) => false));
      expect(tester.widget<Checkbox>(boxes().first).disabled, isTrue);
    });

    testWidgets('a table controlled and then let go keeps no stale selection',
        (tester) async {
      // Uncontrolled first, so the table has a selection of its own to come
      // back to; then given one, where ticking may only tell; then let go.
      await tester.pumpWidget(table());
      await tester.tap(boxes().at(1));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(boxes().at(1)).checked, isTrue);

      await tester.pumpWidget(table(selected: const [_User('Bart', 31)]));
      await tester.tap(boxes().at(2));
      await tester.pumpAndSettle();

      await tester.pumpWidget(table());
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(boxes().at(1)).checked, isTrue,
          reason: 'its own pick, not what that tick would have made');
      expect(tester.widget<Checkbox>(boxes().at(2)).checked, isFalse);
    });

    testWidgets('a picked row is tinted, hand or no hand', (tester) async {
      Color fillOfRow(WidgetTester tester, String name) => tester
          .widgetList<ColoredBox>(
            find.ancestor(
              of: find.text(name),
              matching: find.byType(ColoredBox),
            ),
          )
          .first
          .color;

      await tester.pumpWidget(table());
      final plain = fillOfRow(tester, 'Ann');

      await tester.tap(boxes().at(2));
      await tester.pumpAndSettle();
      final picked = fillOfRow(tester, 'Ann');

      // Without this a picked row looked exactly like every other one, and
      // the tick in front of it was the only thing saying so.
      expect(picked, isNot(plain));
      expect(picked.a, greaterThan(0));
      expect(fillOfRow(tester, 'Chen'), plain, reason: 'that row only');

      // And the pointer still shows where it is on top of that.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Ann')));
      await tester.pumpAndSettle();
      expect(fillOfRow(tester, 'Ann'), isNot(picked));
    });

    testWidgets('a picked row is tinted in a scrolling table too',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: people,
            scroll: const TableScroll(y: 200),
            selection: const TableSelection<_User>(
              defaultSelected: [_User('Ann', 45)],
            ),
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      Color fill(String name) => tester
          .widgetList<ColoredBox>(
            find.ancestor(
              of: find.text(name),
              matching: find.byType(ColoredBox),
            ),
          )
          .first
          .color;

      expect(fill('Ann'), isNot(fill('Chen')));
    });

    testWidgets('no selection, no column', (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: people,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
              ),
            ],
          ),
        ),
      );
      expect(boxes(), findsNothing);
    });
  });

  group('opening rows', () {
    const people = [
      _User('Chen', 27),
      _User('Ann', 45),
      _User('Bart', 31),
    ];

    Widget table({
      List<_User>? expanded,
      List<_User>? defaultExpanded,
      ValueChanged<List<_User>>? onChanged,
      bool Function(_User)? expandable,
      bool byRowTap = false,
      bool showColumn = true,
      TableScroll? scroll,
    }) =>
        _host(
          Table<_User>(
            data: people,
            scroll: scroll,
            expandable: TableExpandable<_User>(
              builder: (_, u, __) => Text('about ${u.name}'),
              expanded: expanded,
              defaultExpanded: defaultExpanded,
              onChanged: onChanged,
              expandable: expandable,
              byRowTap: byRowTap,
              showColumn: showColumn,
            ),
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
              ),
              TableColumn<_User>(
                title: const Text('Age'),
                value: (u) => u.age,
              ),
            ],
          ),
        );

    Finder chevrons() => find.byWidgetPredicate((w) =>
        w is CustomPaint &&
        w.painter.runtimeType.toString() == '_ExpandIconPainter');

    testWidgets('a chevron opens a row and shuts it again', (tester) async {
      await tester.pumpWidget(table());
      expect(find.text('about Ann'), findsNothing);

      await tester.tap(chevrons().at(1));
      await tester.pumpAndSettle();
      expect(find.text('about Ann'), findsOneWidget);

      await tester.tap(chevrons().at(1));
      await tester.pumpAndSettle();
      expect(find.text('about Ann'), findsNothing);
    });

    testWidgets('the panel reveals and hides the way the kit reveals things',
        (tester) async {
      await tester.pumpWidget(table());
      await tester.tap(chevrons().first);

      // Part way through, the panel is on screen but not yet its full height:
      // it is the same reveal a Collapse panel uses.
      // Measured on the table rather than on the text: the reveal clips the
      // panel, so the text inside it keeps its own height throughout.
      await tester.pump();
      final shut = tester.getRect(find.byType(Table<_User>)).height;
      await tester.pump(const Duration(milliseconds: 60));
      final opening = tester.getRect(find.byType(Table<_User>)).height;
      await tester.pumpAndSettle();
      final open = tester.getRect(find.byType(Table<_User>)).height;
      expect(opening, greaterThan(shut));
      expect(opening, lessThan(open));

      // And it animates shut rather than vanishing — a panel simply dropped
      // from the tree cannot animate at all.
      await tester.tap(chevrons().first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('about Chen'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('about Chen'), findsNothing);
    });

    testWidgets('the panel content does not move sideways as it reveals',
        (tester) async {
      // The reveal passes loose constraints, so a child that hugs its content
      // came out narrow and centred for the length of the animation and then
      // snapped to full width and the leading edge on the last frame:
      // measured, a panel's text sat at 328.8 and 142.5 wide throughout, then
      // jumped to 116 and 568.
      await tester.pumpWidget(table());
      await tester.tap(chevrons().first);
      await tester.pump();

      Rect? during;
      for (final ms in const [40, 80, 140]) {
        await tester.pump(Duration(milliseconds: ms));
        final found = find.text('about Chen');
        if (found.evaluate().isEmpty) continue;
        final now = tester.getRect(found);
        during ??= now;
        expect(now.left, closeTo(during.left, 0.5));
        expect(now.width, closeTo(during.width, 0.5));
      }
      expect(during, isNotNull, reason: 'the panel was on screen part way');

      await tester.pumpAndSettle();
      final settled = tester.getRect(find.text('about Chen'));
      expect(settled.left, closeTo(during!.left, 0.5));
      expect(settled.width, closeTo(during.width, 0.5));
    });

    testWidgets('a panel is never shorter than a row', (tester) async {
      // A row whose height was named carries no vertical padding — the height
      // itself stands in for it — so a panel padded the same way collapsed to
      // the height of its text: measured, twenty pixels under a row of
      // sixty-four.
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: people,
            size: const ControlSize.height(64),
            expandable: TableExpandable<_User>(
              defaultExpanded: const [_User('Chen', 27)],
              builder: (_, u, __) => Text('about ${u.name}'),
            ),
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      Rect boxOf(String text) => tester.getRect(
            find
                .ancestor(of: find.text(text), matching: find.byType(Padding))
                .first,
          );
      expect(boxOf('about Chen').height, greaterThanOrEqualTo(64));
      expect(boxOf('about Chen').height, closeTo(boxOf('Ann').height, 0.5));
    });

    testWidgets('the mark is a plus that becomes a minus', (tester) async {
      // Read off the pixels, not off the animation's value: what matters is
      // what is drawn, and a painter can hold the right number and still draw
      // the wrong thing.
      Future<int> uprightPixels(WidgetTester tester) async {
        final painter =
            tester.widgetList<CustomPaint>(chevrons()).first.painter!;
        final recorder = ui.PictureRecorder();
        painter.paint(ui.Canvas(recorder), const Size(20, 20));
        // Rasterising needs the real async world: inside the test's fake one
        // toImage never completes.
        final bytes = await tester.runAsync(() async {
          final image = await recorder.endRecording().toImage(20, 20);
          final data = await image.toByteData();
          image.dispose();
          return data;
        });
        // Down the middle, skipping the row the crossbar occupies and the
        // frame at either end.
        var lit = 0;
        for (var y = 3; y < 17; y++) {
          if ((y - 10).abs() < 2) continue;
          final alpha = bytes!.getUint8((y * 20 + 10) * 4 + 3);
          if (alpha > 40) lit++;
        }
        return lit;
      }

      await tester.pumpWidget(table());
      expect(await uprightPixels(tester), greaterThan(0),
          reason: 'a plus while the row is shut');

      await tester.tap(chevrons().first);
      await tester.pumpAndSettle();
      expect(await uprightPixels(tester), 0, reason: 'a minus once it is open');
    });

    testWidgets('the panel spans the whole table, not one column',
        (tester) async {
      // Flutter's Table cannot span a row across its columns, so the panel is
      // drawn between two grids rather than inside one.
      await tester.pumpWidget(table(defaultExpanded: const [_User('Ann', 45)]));
      final panel = tester.getRect(find.text('about Ann'));
      final table_ = tester.getRect(find.byType(Table<_User>));
      expect(panel.left, lessThan(tester.getRect(find.text('Age')).left));
      expect(table_.width, closeTo(600, 1));
    });

    testWidgets('every grid is told the same widths', (tester) async {
      // Two grids that each measured their own rows would disagree the moment
      // the widest row fell in one of them and not the other. The long name
      // is in the first segment; the rows after the panel are in the second.
      const wide = [
        _User('Bartholomew Considine of Galway', 45),
        _User('Al', 27),
        _User('Bo', 31),
      ];
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: wide,
            expandable: TableExpandable<_User>(
              builder: (_, u, __) => Text('about ${u.name}'),
              defaultExpanded: const [
                _User('Bartholomew Considine of Galway', 45)
              ],
            ),
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
              ),
              TableColumn<_User>(
                title: const Text('Age'),
                value: (u) => u.age,
              ),
            ],
          ),
        ),
      );

      // The age of the row above the panel and of the ones below it stand in
      // the same column, because both grids were handed the same numbers.
      final above = tester.getRect(find.text('45')).left;
      final below = tester.getRect(find.text('27')).left;
      expect(below, closeTo(above, 0.5));
      expect(tester.getRect(find.text('Age')).left, closeTo(above, 0.5));
    });

    testWidgets('more than one row can stand open', (tester) async {
      await tester.pumpWidget(table());
      await tester.tap(chevrons().first);
      await tester.pumpAndSettle();
      await tester.tap(chevrons().at(2));
      await tester.pumpAndSettle();

      expect(find.text('about Chen'), findsOneWidget);
      expect(find.text('about Bart'), findsOneWidget);
      expect(find.text('about Ann'), findsNothing);
    });

    testWidgets('a row that cannot open shows no chevron', (tester) async {
      await tester.pumpWidget(table(expandable: (u) => u.name != 'Ann'));
      expect(chevrons(), findsNWidgets(2));
    });

    testWidgets('a tap on the row opens it where the table asks',
        (tester) async {
      await tester.pumpWidget(table(byRowTap: true));
      await tester.tap(find.text('Bart'));
      await tester.pumpAndSettle();
      expect(find.text('about Bart'), findsOneWidget);
    });

    testWidgets('no column of chevrons where none was asked for',
        (tester) async {
      await tester.pumpWidget(table(showColumn: false, byRowTap: true));
      expect(chevrons(), findsNothing);

      await tester.tap(find.text('Bart'));
      await tester.pumpAndSettle();
      expect(find.text('about Bart'), findsOneWidget);
    });

    testWidgets('what is open is reported, and can be told', (tester) async {
      List<_User>? told;
      await tester.pumpWidget(table(
        expanded: const [_User('Chen', 27)],
        onChanged: (rows) => told = rows,
      ));
      expect(find.text('about Chen'), findsOneWidget);

      await tester.tap(chevrons().at(1));
      await tester.pumpAndSettle();
      expect(told, [const _User('Chen', 27), const _User('Ann', 45)]);
      expect(find.text('about Ann'), findsNothing,
          reason: 'it said what it would have become, and changed nothing');
    });

    testWidgets('a table controlled and then let go keeps no stale opening',
        (tester) async {
      await tester.pumpWidget(table());
      await tester.tap(chevrons().first);
      await tester.pumpAndSettle();
      expect(find.text('about Chen'), findsOneWidget);

      await tester.pumpWidget(table(expanded: const [_User('Bart', 31)]));
      await tester.tap(chevrons().at(1));
      await tester.pumpAndSettle();

      await tester.pumpWidget(table());
      await tester.pumpAndSettle();
      expect(find.text('about Chen'), findsOneWidget,
          reason: 'its own, not what that tap would have made');
      expect(find.text('about Ann'), findsNothing);
    });

    testWidgets('a named panel height keeps the body lazy', (tester) async {
      // A lazy body finds a row by reckoning where it starts, and a panel of
      // whatever height its content happens to be cannot be reckoned with.
      // Named, it can: the rows before a given one are so many ordinary ones
      // and so many panels, which is a count and not a measurement.
      await tester.pumpWidget(
        _host(
          Table<int>(
            bordered: true,
            scroll: const TableScroll(y: 240),
            data: [for (var i = 0; i < 300; i++) i],
            expandable: TableExpandable<int>(
              panelHeight: 60,
              defaultExpanded: const [1],
              builder: (_, v, __) => Text('about $v'),
            ),
            columns: [
              TableColumn<int>(title: const Text('N'), value: (v) => 'n$v'),
            ],
          ),
          width: 600,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RichText).evaluate().length, lessThan(40),
          reason: 'three hundred rows built six hundred cells before');

      expect(find.text('about 1'), findsOneWidget);
      final panel = tester.getRect(
        find
            .ancestor(
              of: find.text('about 1'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(panel.height, closeTo(60, 0.5), reason: 'the height named');

      // And the row after it has been pushed down by exactly that much on
      // top of its own.
      final gap = tester.getRect(find.text('n2')).top -
          tester.getRect(find.text('n1')).top;
      expect(gap, closeTo(44 + 60, 1));
    });

    testWidgets('without a named height it opens as it always did',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Table<int>(
            scroll: const TableScroll(y: 240),
            data: [for (var i = 0; i < 12; i++) i],
            expandable: TableExpandable<int>(
              defaultExpanded: const [1],
              builder: (_, v, __) => Text('about $v'),
            ),
            columns: [
              TableColumn<int>(title: const Text('N'), value: (v) => 'n$v'),
            ],
          ),
          width: 600,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('about 1'), findsOneWidget);
      expect(find.text('n11'), findsOneWidget,
          reason: 'every row built, which is the trade for not saying');
    });

    testWidgets('a table with a height of its own scrolls the panels too',
        (tester) async {
      await tester.pumpWidget(table(
        scroll: const TableScroll(y: 150),
        defaultExpanded: const [_User('Chen', 27)],
      ));
      await tester.pumpAndSettle();
      expect(find.text('about Chen'), findsOneWidget);
      expect(
        tester.getRect(find.byType(Table<_User>)).height,
        lessThan(300),
        reason: 'the height it was given, panel and all',
      );
    });
  });

  group('paging', () {
    final many = [for (var i = 0; i < 25; i++) _User('n$i', i)];

    // The pager's own numbers: the Age column shows numbers too.
    Finder pageButton(String n) => find.descendant(
          of: find.byType(Pagination),
          matching: find.text(n),
        );

    List<String> shown(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((s) => many.any((u) => u.name == s))
        .toList();

    Widget table({
      TablePagination pagination = const TablePagination(defaultPageSize: 10),
      Map<int, List<Object?>>? defaultFilters,
      Map<int, List<Object?>>? filters,
      List<TableSort>? defaultSort,
      TableSelection<_User>? selection,
    }) =>
        _host(
          Table<_User>(
            data: many,
            pagination: pagination,
            defaultFilters: defaultFilters,
            filters: filters,
            defaultSort: defaultSort,
            selection: selection,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
                filters: const [TableFilter('early', 'n1')],
                onFilter: (choice, u) => u.age < 5,
              ),
              TableColumn<_User>(
                title: const Text('Age'),
                sortable: true,
                value: (u) => u.age,
              ),
            ],
          ),
          width: 700,
        );

    testWidgets('only a page of rows is shown', (tester) async {
      await tester.pumpWidget(table());
      expect(shown(tester).length, 10);
      expect(shown(tester).first, 'n0');
      expect(shown(tester).last, 'n9');
    });

    testWidgets('the pager moves between pages', (tester) async {
      await tester.pumpWidget(table());
      await tester.tap(pageButton('3'));
      await tester.pumpAndSettle();
      expect(shown(tester), ['n20', 'n21', 'n22', 'n23', 'n24']);
    });

    testWidgets('what it says is what it does', (tester) async {
      int? toldPage;
      int? toldSize;
      await tester.pumpWidget(table(
        pagination: TablePagination(
          defaultPageSize: 10,
          onChanged: (page, size) {
            toldPage = page;
            toldSize = size;
          },
        ),
      ));
      await tester.tap(pageButton('2'));
      await tester.pumpAndSettle();
      expect(toldPage, 2);
      expect(toldSize, 10);
    });

    testWidgets('a page given is the page shown, and tapping only tells',
        (tester) async {
      int? told;
      await tester.pumpWidget(table(
        pagination: TablePagination(
          page: 2,
          pageSize: 10,
          onChanged: (page, _) => told = page,
        ),
      ));
      expect(shown(tester).first, 'n10');

      await tester.tap(pageButton('3'));
      await tester.pumpAndSettle();
      expect(told, 3);
      expect(shown(tester).first, 'n10', reason: 'and changed nothing itself');
    });

    testWidgets('a table controlled and then let go keeps no stale page',
        (tester) async {
      // Uncontrolled first, so the table has a page of its own to come back
      // to; then given one, where tapping may only tell; then let go.
      await tester.pumpWidget(table());
      await tester.tap(pageButton('2'));
      await tester.pumpAndSettle();
      expect(shown(tester).first, 'n10');

      int? told;
      await tester.pumpWidget(
        table(
          pagination: TablePagination(
            page: 1,
            pageSize: 10,
            onChanged: (page, _) => told = page,
          ),
        ),
      );
      await tester.tap(pageButton('3'));
      await tester.pumpAndSettle();
      expect(told, 3, reason: 'the tap reached the table');
      expect(shown(tester).first, 'n0', reason: 'it showed what it was told');

      await tester.pumpWidget(table());
      await tester.pumpAndSettle();
      expect(shown(tester).first, 'n10',
          reason: 'its own page, not what that tap would have made');
    });

    testWidgets('the page and the page size are controlled apart',
        (tester) async {
      // Page given, size not: tapping a page may only tell, while the size
      // changer still works on its own.
      int? told;
      await tester.pumpWidget(table(
        pagination: TablePagination(
          page: 1,
          defaultPageSize: 10,
          onChanged: (page, _) => told = page,
        ),
      ));
      await tester.tap(pageButton('3'));
      await tester.pumpAndSettle();
      expect(told, 3);
      expect(shown(tester).first, 'n0', reason: 'the page it was told');

      // And letting go of the page hands back the first one, not that tap.
      await tester.pumpWidget(table(
        pagination: const TablePagination(defaultPageSize: 10),
      ));
      await tester.pumpAndSettle();
      expect(shown(tester).first, 'n0',
          reason: 'a page it was told to show is not a page it chose');
    });

    testWidgets('paging happens after narrowing and sorting', (tester) async {
      await tester.pumpWidget(table(
        defaultFilters: const {
          0: ['early'],
        },
        defaultSort: const [TableSort(1, TableSortOrder.descending)],
      ));
      // Five rows survive the filter, so one page of them, newest first.
      expect(shown(tester), ['n4', 'n3', 'n2', 'n1', 'n0']);
    });

    testWidgets('narrowing past the page you are on lands on the last one',
        (tester) async {
      await tester.pumpWidget(table());
      await tester.tap(pageButton('3'));
      await tester.pumpAndSettle();
      expect(shown(tester).first, 'n20');

      // Now only five rows are left: page three does not exist. Controlled
      // filters, since a default is read once and this table already lives.
      await tester.pumpWidget(table(filters: const {
        0: ['early'],
      }));
      await tester.pumpAndSettle();
      expect(shown(tester), ['n0', 'n1', 'n2', 'n3', 'n4'],
          reason: 'the last page there is, and never an empty one');
    });

    testWidgets('the heading box takes the page, not the whole table',
        (tester) async {
      List<_User>? told;
      await tester.pumpWidget(table(
        selection: TableSelection<_User>(onChanged: (rows) => told = rows),
      ));
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(told!.length, 10, reason: 'the ten on show, not all twenty-five');
    });

    testWidgets('a pager stands where it is told, against the edge it is told',
        (tester) async {
      Future<Rect> pagerAt(List<TablePaginationPosition> where) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(table(
          pagination: TablePagination(defaultPageSize: 5, position: where),
        ));
        await tester.pumpAndSettle();
        return tester.getRect(find.byType(Pagination));
      }

      final bottomEnd =
          await pagerAt(const [TablePaginationPosition.bottomEnd]);
      final topStart = await pagerAt(const [TablePaginationPosition.topStart]);
      expect(topStart.center.dy, lessThan(bottomEnd.center.dy));

      // The alignment is part of the position, so the pager's own content
      // sits against the edge named — the default being the trailing one,
      // where a total drawn beside it would otherwise hug the leading edge.
      final endNumbers = await pagerAt(
        const [TablePaginationPosition.bottomEnd],
      );
      final endOne = tester.getRect(find.descendant(
        of: find.byType(Pagination),
        matching: find.text('1'),
      ));
      final startNumbers = await pagerAt(
        const [TablePaginationPosition.bottomStart],
      );
      final startOne = tester.getRect(find.descendant(
        of: find.byType(Pagination),
        matching: find.text('1'),
      ));
      expect(endOne.left, greaterThan(startOne.left));
      expect(endNumbers.width, closeTo(startNumbers.width, 0.5));
    });

    testWidgets('by default the pager is under the table, against the end',
        (tester) async {
      await tester.pumpWidget(table());
      final pager = tester.getRect(find.byType(Pagination));
      final rows = tester.getRect(find.text('n0'));
      expect(pager.center.dy, greaterThan(rows.center.dy));

      // Against the trailing edge, which is also what keeps a `showTotal`
      // drawn beside it off the leading one.
      final one = tester.getRect(find.descendant(
        of: find.byType(Pagination),
        matching: find.text('1'),
      ));
      expect(one.center.dx, greaterThan(pager.center.dx));
    });

    testWidgets('none pages the rows and draws nothing', (tester) async {
      await tester.pumpWidget(table(
        pagination: const TablePagination(
          defaultPageSize: 10,
          position: [TablePaginationPosition.none],
        ),
      ));
      expect(find.byType(Pagination), findsNothing);
      expect(shown(tester).length, 10, reason: 'still a page of rows');
    });

    testWidgets('a total the caller names is what the pager counts',
        (tester) async {
      // The rows handed over are one page already — taken out by whatever
      // knows the rest — so the table draws them as they came.
      final page = [for (var i = 20; i < 30; i++) _User('n$i', i)];
      var asked = 0;
      var askedFor = 0;
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: page,
            pagination: TablePagination(
              page: 3,
              pageSize: 10,
              total: 100,
              onChanged: (p, _) {
                asked++;
                askedFor = p;
              },
            ),
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
              ),
            ],
          ),
          width: 700,
        ),
      );

      // All ten drawn, none sliced away.
      expect(find.text('n20'), findsOneWidget);
      expect(find.text('n29'), findsOneWidget);

      // And the pager knows there are ten pages, not one — and that it is
      // standing on the third.
      expect(
        find.descendant(
          of: find.byType(Pagination),
          matching: find.text('10'),
        ),
        findsOneWidget,
      );
      expect(tester.widget<Pagination>(find.byType(Pagination)).current, 3);

      await tester.tap(find.descendant(
        of: find.byType(Pagination),
        matching: find.text('4'),
      ));
      await tester.pumpAndSettle();
      expect(asked, 1);
      expect(askedFor, 4, reason: 'the caller fetches that page itself');
    });

    testWidgets('the outline goes round the table, not round the pager',
        (tester) async {
      // Drawn inside the frame, the pager pushed the outline below itself and
      // left the last row with nothing under it — the row's own rule is the
      // one the outline stands in for.
      await tester.pumpWidget(
        _host(
          Table<_User>(
            bordered: true,
            data: many,
            pagination: const TablePagination(defaultPageSize: 5),
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
              ),
            ],
          ),
          width: 700,
        ),
      );

      final outline = tester.getRect(
        find
            .byWidgetPredicate((w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).borderRadius != null &&
                (w.decoration as BoxDecoration).border != null)
            .first,
      );
      final pager = tester.getRect(find.byType(Pagination));
      final lastRow = tester.getRect(find.text('n4'));

      expect(outline.bottom, lessThanOrEqualTo(pager.top),
          reason: 'the pager stands outside the frame');
      expect(lastRow.bottom, lessThan(outline.bottom),
          reason: 'and the last row is closed off by it');
    });

    testWidgets('no pagination, no pager', (tester) async {
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: Table<_User>(
              data: many,
              columns: [
                TableColumn<_User>(
                  title: const Text('Name'),
                  value: (u) => u.name,
                ),
              ],
            ),
          ),
          width: 700,
        ),
      );
      expect(find.byType(Pagination), findsNothing);
      expect(shown(tester).length, 25);
    });

    testWidgets('a pager above, under, or both', (tester) async {
      await tester.pumpWidget(table());
      expect(find.byType(Pagination), findsOneWidget);
      final table_ = tester.getRect(find.byType(Table<_User>));
      expect(tester.getRect(find.byType(Pagination)).center.dy,
          greaterThan(table_.center.dy));

      // Five to a page, or two pagers and ten rows do not fit the surface the
      // test is given — and controlled, since a default is read once and this
      // table already lives.
      await tester.pumpWidget(table(
        pagination: const TablePagination(
          page: 1,
          pageSize: 5,
          position: [
            TablePaginationPosition.topEnd,
            TablePaginationPosition.bottomEnd,
          ],
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(Pagination), findsNWidgets(2));
    });
  });

  group('grouped columns', () {
    const people = [_User('Chen', 27), _User('Ann', 45)];

    Widget table({bool bordered = false}) => _host(
          Table<_User>(
            bordered: bordered,
            data: people,
            columns: [
              TableColumn<_User>(
                title: const Text('Who'),
                children: [
                  TableColumn<_User>(
                    title: const Text('Name'),
                    sortable: true,
                    value: (u) => u.name,
                  ),
                  TableColumn<_User>(
                    title: const Text('Age'),
                    value: (u) => u.age,
                  ),
                ],
              ),
              TableColumn<_User>(
                title: const Text('Note'),
                value: (u) => 'about ${u.name}',
              ),
            ],
          ),
          width: 700,
        );

    testWidgets('a group heads the columns under it', (tester) async {
      await tester.pumpWidget(table());
      final group = tester.getRect(find.text('Who'));
      final name = tester.getRect(find.text('Name'));
      final age = tester.getRect(find.text('Age'));

      // Above both, and spanning the pair of them.
      expect(group.center.dy, lessThan(name.center.dy));
      expect(group.center.dy, lessThan(age.center.dy));
      expect(group.center.dx, greaterThan(name.left));
      expect(group.center.dx, lessThan(age.right));
    });

    testWidgets('a column heading nothing stands the whole depth',
        (tester) async {
      await tester.pumpWidget(table());
      final who = tester.getRect(find.text('Who')).center.dy;
      final name = tester.getRect(find.text('Name')).center.dy;
      final note = tester.getRect(find.text('Note')).center.dy;

      // Note has no group over it, so its cell is as tall as the group's
      // title and the row beneath it together — and its own title sits
      // between the two, rather than on either row.
      expect(note, greaterThan(who));
      expect(note, lessThan(name));
    });

    testWidgets('the cells line up under the heading they belong to',
        (tester) async {
      await tester.pumpWidget(table());
      expect(
        tester.getRect(find.text('Chen')).left,
        closeTo(tester.getRect(find.text('Name')).left, 0.5),
      );
      expect(
        tester.getRect(find.text('about Chen')).left,
        closeTo(tester.getRect(find.text('Note')).left, 0.5),
      );
    });

    testWidgets('a leaf still sorts, and by its own place', (tester) async {
      await tester.pumpWidget(table());
      expect(shownNames(tester), ['Chen', 'Ann']);

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(shownNames(tester), ['Ann', 'Chen'],
          reason: 'the first leaf, not the first column given');
    });

    testWidgets('a group is not a column to sort or narrow', (tester) async {
      await tester.pumpWidget(table());
      await tester.tap(find.text('Who'));
      await tester.pumpAndSettle();
      expect(shownNames(tester), ['Chen', 'Ann'], reason: 'nothing moved');
    });

    testWidgets('a group nests, and a leaf beside one stands its depth',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: people,
            columns: [
              TableColumn<_User>(
                title: const Text('Who'),
                children: [
                  // A leaf and a group side by side under the same head: the
                  // leaf has to stand as deep as the group beside it.
                  TableColumn<_User>(
                    title: const Text('Name'),
                    value: (u) => u.name,
                  ),
                  TableColumn<_User>(
                    title: const Text('Years'),
                    children: [
                      TableColumn<_User>(
                        title: const Text('Age'),
                        value: (u) => u.age,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          width: 700,
        ),
      );

      final who = tester.getRect(find.text('Who')).center.dy;
      final years = tester.getRect(find.text('Years')).center.dy;
      final age = tester.getRect(find.text('Age')).center.dy;
      final name = tester.getRect(find.text('Name')).center.dy;

      expect(who, lessThan(years));
      expect(years, lessThan(age));
      // Name has nothing under it, so it stands through both rows below Who
      // and its title sits between them.
      expect(name, greaterThan(years));
      expect(name, lessThan(age));

      // And the cells still line up with the leaf they belong to.
      expect(
        tester.getRect(find.text('Chen')).left,
        closeTo(tester.getRect(find.text('Name')).left, 0.5),
      );
    });

    testWidgets('a scrolling table keeps its groups and stays lazy',
        (tester) async {
      // The heading of a grouped table cannot be a row of the grid — a
      // title reaches across the columns under it — so the viewport is told
      // where every heading cell stands and how much it covers, and only the
      // cells that start something are built.
      await tester.pumpWidget(
        _host(
          Table<int>(
            bordered: true,
            scroll: const TableScroll(y: 240),
            data: [for (var i = 0; i < 300; i++) i],
            columns: [
              TableColumn<int>(
                title: const Text('Who'),
                children: [
                  TableColumn<int>(
                    title: const Text('Name'),
                    value: (v) => 'n$v',
                  ),
                  TableColumn<int>(
                    title: const Text('City'),
                    value: (v) => 'c$v',
                  ),
                ],
              ),
              TableColumn<int>(title: const Text('Age'), value: (v) => 'a$v'),
            ],
          ),
          width: 700,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RichText).evaluate().length, lessThan(80),
          reason: 'three hundred rows built twelve hundred cells before');

      // The group stands above what it heads, and across it.
      final who = tester.getRect(find.text('Who'));
      final name = tester.getRect(find.text('Name'));
      final city = tester.getRect(find.text('City'));
      expect(who.center.dy, lessThan(name.center.dy));
      // The group's own cell reaches across both columns under it — measured
      // on the cell, since a title is centred in it while a leaf heading is
      // not, and comparing the words would compare their alignment.
      final whoCell = tester.getRect(
        find
            .ancestor(of: find.text('Who'), matching: find.byType(DecoratedBox))
            .first,
      );
      expect(whoCell.right, greaterThan(city.right),
          reason: 'a title reaching across one column would stop at Name');

      // Age heads nothing, so it stands the whole depth: its title sits
      // between the two rows rather than on either.
      final age = tester.getRect(find.text('Age'));
      expect(age.center.dy, greaterThan(who.center.dy));
      expect(age.center.dy, lessThan(name.center.dy));

      // And the cells stand under the columns they belong to.
      expect(tester.getRect(find.text('n0')).left, closeTo(name.left, 0.5));
      expect(tester.getRect(find.text('c0')).left, closeTo(city.left, 0.5));
      expect(tester.getRect(find.text('a0')).left, closeTo(age.left, 0.5));
    });

    test('a group holds no cells of its own', () {
      expect(
        () => TableColumn<_User>(
          title: const Text('Who'),
          value: (u) => u.name,
          children: [
            TableColumn<_User>(
              title: const Text('Name'),
              value: (u) => u.name,
            ),
          ],
        ),
        throwsAssertionError,
      );
    });

    test('a group with nothing under it heads nothing', () {
      expect(
        () => TableColumn<_User>(title: const Text('Who'), children: const []),
        throwsAssertionError,
      );
    });
  });

  group('a row that adds up', () {
    const people = [
      _User('Chen', 27),
      _User('Ann', 45),
      _User('Bart', 31),
    ];

    Widget table({
      bool onAge = true,
      Map<int, List<Object?>>? defaultFilters,
      TablePagination? pagination,
    }) =>
        _host(
          Table<_User>(
            data: people,
            defaultFilters: defaultFilters,
            pagination: pagination,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
                filters: const [TableFilter('young', 'young')],
                onFilter: (choice, u) => u.age < 40,
                summary: (_, rows) => Text('${rows.length} people'),
              ),
              TableColumn<_User>(
                title: const Text('Age'),
                align: TableAlign.end,
                value: (u) => u.age,
                summary: onAge
                    ? (_, rows) => Text('${rows.fold(0, (n, u) => n + u.age)}')
                    : null,
              ),
            ],
          ),
          width: 700,
        );

    testWidgets('a column says what it adds up, and it is drawn under the rest',
        (tester) async {
      await tester.pumpWidget(table());
      expect(find.text('3 people'), findsOneWidget);
      expect(find.text('103'), findsOneWidget);

      final summary = tester.getRect(find.text('103'));
      expect(summary.center.dy,
          greaterThan(tester.getRect(find.text('Bart')).center.dy));
    });

    testWidgets('it lines up with the columns it sums', (tester) async {
      await tester.pumpWidget(table());
      // The Age summary is right-aligned like its column.
      expect(
        tester.getRect(find.text('103')).right,
        closeTo(tester.getRect(find.text('45')).right, 0.5),
      );
      expect(
        tester.getRect(find.text('3 people')).left,
        closeTo(tester.getRect(find.text('Chen')).left, 0.5),
      );
    });

    testWidgets('it stands on the body\'s own ground, not a tint',
        (tester) async {
      // A fill would make it read as a second heading; the rule above it is
      // what sets it apart. The heading's own fill comes from a TableRow
      // decoration rather than a box, so the two are compared through the
      // token they are drawn from.
      late Token token;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              token = context.softToken;
              return Table<_User>(
                data: people,
                columns: [
                  TableColumn<_User>(
                    title: const Text('Age'),
                    value: (u) => u.age,
                    summary: (_, rows) => const Text('sum'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      final fills = tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.text('sum'),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.color)
          .whereType<Color>()
          .where((c) => c.a != 0)
          .toList();

      expect(fills, isNotEmpty);
      expect(fills.first, token.colorBgContainer);
      expect(fills.first, isNot(token.colorFillQuaternary),
          reason: 'not the heading\'s fill');
    });

    testWidgets('the outline is painted over it, not behind it',
        (tester) async {
      // A row with a fill of its own is opaque right to the edge, so a frame
      // drawn behind it is simply painted over: measured at the left edge, a
      // body row showed the rule while the summary beside it came out pure
      // white. Read off the pixels, since nothing about the layout changes.
      final key = GlobalKey();
      await tester.pumpWidget(
        _host(
          RepaintBoundary(
            key: key,
            child: Table<_User>(
              bordered: true,
              data: const [_User('Chen', 27)],
              columns: [
                TableColumn<_User>(
                  title: const Text('Name'),
                  value: (u) => u.name,
                  summary: (_, rows) => const Text('one'),
                ),
              ],
            ),
          ),
          width: 300,
        ),
      );
      await tester.pumpAndSettle();

      final box = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final bytes = await tester.runAsync(() async {
        final image = await box.toImage();
        final data = await image.toByteData();
        image.dispose();
        return data;
      });
      final w = box.size.width.round();
      final top = tester.getRect(find.byKey(key)).top;

      int redAt(int x, int y) => bytes!.getUint8((y * w + x) * 4);
      int alphaAt(int x, int y) => bytes!.getUint8((y * w + x) * 4 + 3);

      final besideSummary =
          (tester.getRect(find.text('one')).center.dy - top).round();
      final underSummary = box.size.height.round() - 1;

      // Opaque there, and darker than the fill behind it: the rule is on top.
      expect(alphaAt(0, besideSummary), 255);
      expect(redAt(0, besideSummary), lessThan(250));
      expect(redAt(w ~/ 2, underSummary), lessThan(250));
    });

    testWidgets('a bordered table rules it like any other row', (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            bordered: true,
            data: people,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
                summary: (_, rows) => const Text('three'),
              ),
              TableColumn<_User>(
                title: const Text('Age'),
                value: (u) => u.age,
                summary: (_, rows) => const Text('103'),
              ),
            ],
          ),
          width: 700,
        ),
      );

      // The cells stand exactly where the body's do, so the rule between them
      // carries on down.
      expect(
        tester.getRect(find.text('three')).left,
        closeTo(tester.getRect(find.text('Chen')).left, 0.5),
      );
      expect(
        tester.getRect(find.text('103')).left,
        closeTo(tester.getRect(find.text('27')).left, 0.5),
      );

      // And the first cell carries the rule on its inner edge.
      final ruled = tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.text('three'),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.border is BorderDirectional)
          .map((d) => d.border! as BorderDirectional)
          .where((b) => b.end != BorderSide.none);
      expect(ruled, isNotEmpty);
    });

    testWidgets('a column that says nothing leaves its place empty',
        (tester) async {
      await tester.pumpWidget(table(onAge: false));
      expect(find.text('3 people'), findsOneWidget);
      expect(find.text('103'), findsNothing);
    });

    testWidgets('no column says anything, no row', (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: people,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
              ),
            ],
          ),
        ),
      );
      expect(find.textContaining('people'), findsNothing);
    });

    testWidgets('it adds up the rows on show, not every row', (tester) async {
      await tester.pumpWidget(table(defaultFilters: const {
        0: ['young'],
      }));
      // Chen is 27 and Bart is 31; Ann at 45 was filtered away.
      expect(find.text('2 people'), findsOneWidget);
      expect(find.text('58'), findsOneWidget);
    });

    testWidgets('and on a paged table, the page', (tester) async {
      await tester.pumpWidget(table(
        pagination: const TablePagination(defaultPageSize: 2),
      ));
      expect(find.text('2 people'), findsOneWidget);
      expect(find.text('72'), findsOneWidget, reason: 'Chen and Ann');
    });

    testWidgets('a scrolling table keeps it and stays lazy', (tester) async {
      // The row that adds up is held at the foot as the heading is held at
      // the head, so it costs a lazy body nothing: measured, three hundred
      // rows built twelve hundred cells before and fifty after.
      Future<int> cells({required bool summary}) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          _host(
            Table<int>(
              scroll: const TableScroll(y: 240),
              data: [for (var i = 0; i < 300; i++) i],
              columns: [
                for (var c = 0; c < 3; c++)
                  TableColumn<int>(
                    title: Text('C$c'),
                    value: (v) => 'c$c-$v',
                    summary: summary && c == 0
                        ? (_, rows) => Text('${rows.length} rows')
                        : null,
                  ),
              ],
            ),
            width: 700,
          ),
        );
        await tester.pumpAndSettle();
        return find.byType(RichText).evaluate().length;
      }

      final plain = await cells(summary: false);
      final withSummary = await cells(summary: true);
      expect(plain, lessThan(70));
      expect(withSummary, lessThan(70), reason: 'and it did not cost that');
      expect(find.text('300 rows'), findsOneWidget);
    });

    testWidgets('it holds at the foot while the rows run under it',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Table<int>(
            scroll: const TableScroll(y: 200),
            data: [for (var i = 0; i < 60; i++) i],
            columns: [
              TableColumn<int>(
                title: const Text('N'),
                value: (v) => 'n$v',
                summary: (_, rows) => const Text('all of them'),
              ),
            ],
          ),
          width: 400,
        ),
      );
      await tester.pumpAndSettle();

      final table = tester.getRect(find.byType(Table<int>));
      final atFirst = tester.getRect(find.text('all of them'));
      // Against the bottom of the table, not after the last row.
      expect(atFirst.bottom, closeTo(table.bottom, 20));

      final pointer = TestPointer(1, PointerDeviceKind.trackpad);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('n1'))),
      );
      for (var i = 0; i < 5; i++) {
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
        await tester.pumpAndSettle();
      }

      expect(find.text('n0'), findsNothing, reason: 'the rows have moved');
      expect(
        tester.getRect(find.text('all of them')).bottom,
        closeTo(atFirst.bottom, 0.5),
        reason: 'and it has not',
      );

      // Run to the very end: the last row stands clear of it rather than
      // under it, because the body was given the height the footer left.
      for (var i = 0; i < 20; i++) {
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, 400)));
        await tester.pumpAndSettle();
      }
      expect(find.text('n59'), findsOneWidget);
      expect(
        tester.getRect(find.text('n59')).bottom,
        lessThanOrEqualTo(tester.getRect(find.text('all of them')).top + 1),
      );
    });

    test('a group has no cell of its own to sum up', () {
      expect(
        () => TableColumn<_User>(
          title: const Text('Who'),
          summary: (_, __) => const Text('x'),
          children: [
            TableColumn<_User>(
              title: const Text('Name'),
              value: (u) => u.name,
            ),
          ],
        ),
        throwsAssertionError,
      );
    });
  });

  group('cells that span', () {
    const people = [
      _User('Chen', 27),
      _User('Ann', 45),
      _User('Bart', 31),
    ];

    Widget table({
      TableCellSpan Function(BuildContext, _User, int)? onName,
      TableCellSpan Function(BuildContext, _User, int)? onCity,
      bool bordered = false,
    }) =>
        _host(
          Table<_User>(
            bordered: bordered,
            data: people,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
                span: onName,
              ),
              TableColumn<_User>(
                title: const Text('City'),
                value: (u) => 'city ${u.age}',
                span: onCity,
              ),
              TableColumn<_User>(
                title: const Text('Age'),
                value: (u) => u.age,
              ),
            ],
          ),
          width: 700,
        );

    testWidgets('a cell reaching across covers its neighbour', (tester) async {
      await tester.pumpWidget(table(
        onName: (_, u, i) =>
            i == 0 ? const TableCellSpan(columns: 2) : const TableCellSpan(),
      ));

      // The covered cell is not drawn at all — nothing has to say it is.
      expect(find.text('city 27'), findsNothing);
      expect(find.text('city 45'), findsOneWidget);

      // And the spanning cell is as wide as the two places it took.
      final wide = tester.getRect(
        find
            .ancestor(of: find.text('Chen'), matching: find.byType(SizedBox))
            .first,
      );
      final narrow = tester.getRect(
        find
            .ancestor(of: find.text('Ann'), matching: find.byType(SizedBox))
            .first,
      );
      expect(wide.width, greaterThan(narrow.width * 1.5));
    });

    testWidgets('a cell reaching down stands over the rows it covers',
        (tester) async {
      await tester.pumpWidget(table(
        onName: (_, u, i) =>
            i == 0 ? const TableCellSpan(rows: 2) : const TableCellSpan(),
      ));

      expect(find.text('Chen'), findsOneWidget);
      expect(find.text('Ann'), findsNothing, reason: 'covered from above');
      expect(find.text('Bart'), findsOneWidget);
      expect(find.text('city 45'), findsOneWidget,
          reason: 'only the first column was covered');

      // It is as tall as the two rows it covers, rather than sitting in the
      // first of them and leaving a hole in the second.
      Rect boxOf(String text) => tester.getRect(
            find
                .ancestor(
                  of: find.text(text),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
      final spanning = boxOf('Chen');
      final below = boxOf('Bart');
      expect(spanning.height, closeTo(below.height * 2, 0.5));
      expect(spanning.bottom, closeTo(below.top, 0.5));
    });

    testWidgets('no rule is drawn through a cell that reaches down',
        (tester) async {
      // The rules go on the cells, not on the rows: a row that carried its
      // own drew a line straight through the middle of a merged cell.
      await tester.pumpWidget(table(
        onName: (_, u, i) =>
            i == 0 ? const TableCellSpan(rows: 2) : const TableCellSpan(),
      ));

      final border = (tester
              .widgetList<DecoratedBox>(
                find.ancestor(
                  of: find.text('Chen'),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .first
              .decoration as BoxDecoration)
          .border! as BorderDirectional;
      // Its own bottom rule sits under the last row it covers — here the row
      // before the last, so it carries one.
      expect(border.bottom, isNot(BorderSide.none));

      // And the row it covers draws nothing of its own in that column.
      expect(find.text('Ann'), findsNothing);
    });

    testWidgets('spanning columns alone leaves the rows to their content',
        (tester) async {
      // Only a cell reaching down needs a height known before the fact.
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: const [_User('Chen', 27), _User('Ann', 45)],
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
                span: (_, u, i) => i == 0
                    ? const TableCellSpan(columns: 2)
                    : const TableCellSpan(),
              ),
              TableColumn<_User>(
                title: const Text('Note'),
                // Two lines in the second row, one in the first.
                value: (u) => u.age == 45 ? 'a\nb' : 'a',
              ),
            ],
          ),
          width: 400,
        ),
      );

      Rect boxOf(String text) => tester.getRect(
            find
                .ancestor(
                  of: find.text(text),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
      expect(boxOf('Ann').height, greaterThan(boxOf('Chen').height),
          reason: 'the taller row is taller');
    });

    testWidgets('a span asking for more than there is takes what there is',
        (tester) async {
      await tester.pumpWidget(table(
        onName: (_, u, i) => i == 2
            ? const TableCellSpan(columns: 9, rows: 9)
            : const TableCellSpan(),
      ));
      // The last row and every column: nothing beyond the table is reached
      // for, and nothing throws.
      expect(find.text('Bart'), findsOneWidget);
      expect(find.text('city 31'), findsNothing);
    });

    testWidgets('the columns still line up with the heading', (tester) async {
      await tester.pumpWidget(table(
        onName: (_, u, i) =>
            i == 0 ? const TableCellSpan(columns: 2) : const TableCellSpan(),
      ));
      expect(
        tester.getRect(find.text('Ann')).left,
        closeTo(tester.getRect(find.text('Name')).left, 0.5),
      );
      expect(
        tester.getRect(find.text('city 45')).left,
        closeTo(tester.getRect(find.text('City')).left, 0.5),
      );
    });

    testWidgets('a bordered table rules the spanned cell once', (tester) async {
      await tester.pumpWidget(table(
        bordered: true,
        onName: (_, u, i) =>
            i == 0 ? const TableCellSpan(columns: 2) : const TableCellSpan(),
      ));

      // The rule stands after the pair, not through the middle of the cell.
      final rules = tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.text('Chen'),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.border is BorderDirectional)
          .map((d) => d.border! as BorderDirectional)
          .where((b) => b.end != BorderSide.none)
          .length;
      expect(rules, 1);

      // The last row carries no rule under it: the outline stands in for it.
      final underLast = (tester
              .widgetList<DecoratedBox>(
                find.ancestor(
                  of: find.text('Bart'),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .first
              .decoration as BoxDecoration)
          .border! as BorderDirectional;
      expect(underLast.bottom, BorderSide.none);

      // And the last cell in the row carries none: the outline closes it off.
      final atEnd = tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.text('27'),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.border is BorderDirectional)
          .map((d) => d.border! as BorderDirectional)
          .where((b) => b.end != BorderSide.none)
          .length;
      expect(atEnd, 0);
    });

    testWidgets('two spans in one row do not tread on each other',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: const [_User('Chen', 27), _User('Ann', 45)],
            columns: [
              TableColumn<_User>(
                title: const Text('A'),
                value: (u) => 'a ${u.name}',
                span: (_, u, i) => i == 0
                    ? const TableCellSpan(rows: 2)
                    : const TableCellSpan(),
              ),
              TableColumn<_User>(
                title: const Text('B'),
                value: (u) => 'b ${u.name}',
                span: (_, u, i) => i == 1
                    ? const TableCellSpan(columns: 2)
                    : const TableCellSpan(),
              ),
              TableColumn<_User>(
                title: const Text('C'),
                value: (u) => 'c ${u.name}',
              ),
            ],
          ),
          width: 700,
        ),
      );

      // Row 0: A spans down, B and C ordinary.
      expect(find.text('a Chen'), findsOneWidget);
      expect(find.text('b Chen'), findsOneWidget);
      expect(find.text('c Chen'), findsOneWidget);
      // Row 1: A is covered from above; B takes B and C.
      expect(find.text('a Ann'), findsNothing);
      expect(find.text('b Ann'), findsOneWidget);
      expect(find.text('c Ann'), findsNothing);
    });

    testWidgets('what lights up is decided by the cell under the pointer',
        (tester) async {
      // Two rows, a merged cell standing over both of them in one column:
      //
      //   a  |  bd
      //   c  |
      //
      // Point at a, and a lights with the cell over it — but not c. Point at
      // the merged cell and everything it covers lights. What lights is the
      // *cell* under the pointer, not the row it happens to sit in.
      await tester.pumpWidget(table(
        onName: (_, u, i) =>
            i == 1 ? const TableCellSpan(rows: 2) : const TableCellSpan(),
      ));
      await tester.pumpAndSettle();

      bool lit(String text) => tester
          .widgetList<ColoredBox>(
            find.ancestor(
              of: find.text(text),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((b) => b.color)
          .any((c) => c.a != 0);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      // 'Ann' is the merged cell, covering the rows of 'city 45' and
      // 'city 31'; 'city 27' is the row above, which it does not cover.
      await mouse.moveTo(tester.getCenter(find.text('city 45')));
      await tester.pumpAndSettle();
      expect(lit('city 45'), isTrue, reason: 'the row pointed at');
      expect(lit('Ann'), isTrue, reason: 'and the cell standing over it');
      expect(lit('city 31'), isFalse, reason: 'but not the row below');

      await mouse.moveTo(tester.getCenter(find.text('city 31')));
      await tester.pumpAndSettle();
      expect(lit('city 31'), isTrue);
      expect(lit('Ann'), isTrue);
      expect(lit('city 45'), isFalse, reason: 'nor the row above');

      // The merged cell itself: everything it covers.
      await mouse.moveTo(tester.getCenter(find.text('Ann')));
      await tester.pumpAndSettle();
      expect(lit('Ann'), isTrue);
      expect(lit('city 45'), isTrue);
      expect(lit('city 31'), isTrue);
      expect(lit('city 27'), isFalse, reason: 'and nothing beyond it');
    });

    testWidgets('a grid full of spans loses nothing and draws nothing twice',
        (tester) async {
      // Six rows and five columns, with spans across, down, and both at once.
      // The covered places are worked out by the table, so the way to know it
      // is right is to count: every cell that should be there exactly once,
      // and every covered one gone.
      await tester.pumpWidget(
        _host(
          Table<int>(
            data: [for (var i = 0; i < 6; i++) i],
            columns: [
              TableColumn<int>(
                title: const Text('A'),
                value: (v) => 'a$v',
                span: (_, v, i) => i == 0 || i == 3
                    ? const TableCellSpan(columns: 2)
                    : const TableCellSpan(),
              ),
              TableColumn<int>(title: const Text('B'), value: (v) => 'b$v'),
              TableColumn<int>(
                title: const Text('C'),
                value: (v) => 'c$v',
                span: (_, v, i) => switch (i) {
                  1 => const TableCellSpan(rows: 3),
                  4 => const TableCellSpan(rows: 2),
                  _ => const TableCellSpan(),
                },
              ),
              TableColumn<int>(
                title: const Text('D'),
                value: (v) => 'd$v',
                span: (_, v, i) => i == 2
                    ? const TableCellSpan(columns: 2, rows: 2)
                    : const TableCellSpan(),
              ),
              TableColumn<int>(title: const Text('E'), value: (v) => 'e$v'),
            ],
          ),
          width: 800,
        ),
      );
      await tester.pumpAndSettle();

      // A spans B on rows 0 and 3; C is one cell over rows 1..3 and another
      // over 4..5; D on row 2 takes E with it and covers row 3 as well.
      const gone = [
        'b0', 'b3', // covered across by A
        'c2', 'c3', // covered down by the C cell that starts at row 1
        'c5', // covered down by the C cell that starts at row 4
        'd3', // covered down by the D cell that starts at row 2
        'e2', 'e3', // covered across and down by that same D cell
      ];
      for (final text in gone) {
        expect(find.text(text), findsNothing, reason: '$text is covered');
      }

      for (final text in [
        'a0',
        'a1',
        'a2',
        'a3',
        'a4',
        'a5',
        'b1',
        'b2',
        'b4',
        'b5',
        'c0',
        'c1',
        'c4',
        'd0',
        'd1',
        'd2',
        'd4',
        'd5',
        'e0',
        'e1',
        'e4',
        'e5',
      ]) {
        expect(find.text(text), findsOneWidget, reason: '$text is drawn once');
      }

      // And nothing has drifted: an unspanned cell still stands under its own
      // heading, however much is merged around it.
      for (final pair in [
        ('a1', 'A'),
        ('b1', 'B'),
        ('d1', 'D'),
        ('e1', 'E'),
      ]) {
        expect(
          tester.getRect(find.text(pair.$1)).left,
          closeTo(tester.getRect(find.text(pair.$2)).left, 0.5),
          reason: '${pair.$1} under ${pair.$2}',
        );
      }
    });

    testWidgets('a scrolling table keeps its spans and stays lazy',
        (tester) async {
      // The rows of a lazy body are all one height, so a cell reaching down
      // three of them is three times that — known before anything is laid
      // out. What the viewport needs is a plan of where each cell starts,
      // worked out for every row and kept: a cell starting above the screen
      // still reaches into it, and the walk begins as far back as the
      // deepest span goes.
      await tester.pumpWidget(
        _host(
          Table<int>(
            bordered: true,
            scroll: const TableScroll(y: 240),
            data: [for (var i = 0; i < 300; i++) i],
            columns: [
              TableColumn<int>(
                title: const Text('A'),
                value: (v) => 'a$v',
                span: (_, v, i) => i % 10 == 0
                    ? const TableCellSpan(columns: 2)
                    : const TableCellSpan(),
              ),
              TableColumn<int>(title: const Text('B'), value: (v) => 'b$v'),
              TableColumn<int>(
                title: const Text('C'),
                value: (v) => 'c$v',
                span: (_, v, i) => i % 7 == 1
                    ? const TableCellSpan(rows: 3)
                    : const TableCellSpan(),
              ),
            ],
          ),
          width: 700,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RichText).evaluate().length, lessThan(70),
          reason: 'three hundred rows built twelve hundred cells before');

      expect(find.text('b0'), findsNothing, reason: 'covered across by a0');
      expect(find.text('b1'), findsOneWidget);
      expect(find.text('c2'), findsNothing, reason: 'covered down by c1');

      Rect boxOf(String text) => tester.getRect(
            find
                .ancestor(
                  of: find.text(text),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
      expect(boxOf('c1').height, closeTo(boxOf('a1').height * 3, 1),
          reason: 'three rows tall, and the rows are of a height');
    });

    testWidgets('a cell reaching in from above the screen is still drawn',
        (tester) async {
      // The whole reason the plan covers every row rather than the ones on
      // show. The span is deeper than the cache the viewport keeps either
      // side, so nothing but the look-back can find it.
      await tester.pumpWidget(
        _host(
          Table<int>(
            scroll: const TableScroll(y: 200),
            data: [for (var i = 0; i < 120; i++) i],
            columns: [
              TableColumn<int>(
                title: const Text('N'),
                value: (v) => 'n$v',
                span: (_, v, i) => i == 20
                    ? const TableCellSpan(rows: 30)
                    : const TableCellSpan(),
              ),
              TableColumn<int>(title: const Text('M'), value: (v) => 'm$v'),
            ],
          ),
          width: 400,
        ),
      );
      await tester.pumpAndSettle();

      final pointer = TestPointer(1, PointerDeviceKind.trackpad);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('m1'))),
      );
      // Well inside the cell's range, and well past where it started.
      for (var i = 0; i < 10; i++) {
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, 160)));
        await tester.pumpAndSettle();
      }

      expect(find.text('m36'), findsOneWidget, reason: 'we are in its range');
      expect(find.text('n20'), findsOneWidget,
          reason: 'and the cell that started at row twenty is still there');
      expect(find.text('n36'), findsNothing, reason: 'covered by it');

      // And only the rows on show are built: the look-back is a walk over
      // the plan, not over the cells.
      expect(find.byType(RichText).evaluate().length, lessThan(40));
    });

    test('a span covers at least its own place', () {
      expect(() => TableCellSpan(columns: 0), throwsAssertionError);
      expect(() => TableCellSpan(rows: 0), throwsAssertionError);
    });

    test('a group has no cell of its own to span', () {
      expect(
        () => TableColumn<_User>(
          title: const Text('Who'),
          span: (_, __, ___) => const TableCellSpan(),
          children: [
            TableColumn<_User>(
              title: const Text('Name'),
              value: (u) => u.name,
            ),
          ],
        ),
        throwsAssertionError,
      );
    });
  });

  group('a heading held in view', () {
    final many = [for (var i = 0; i < 30; i++) _User('n$i', i)];

    Widget page({double offsetHeader = 0}) => _host(
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 300, child: Text('above')),
                Table<_User>(
                  bordered: true,
                  sticky: TableSticky(offsetHeader: offsetHeader),
                  data: many,
                  columns: [
                    TableColumn<_User>(
                      title: const Text('Name'),
                      value: (u) => u.name,
                    ),
                  ],
                ),
              ],
            ),
          ),
          width: 400,
        );

    testWidgets('it holds at the top once the table has gone past',
        (tester) async {
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      double headingTop() => tester.getRect(find.text('Name')).top;
      double tableTop() => tester.getRect(find.byType(Table<_User>)).top;

      expect(tableTop(), 300);
      final resting = headingTop();

      // Still below the top: nothing to hold yet.
      await tester.drag(find.text('n2'), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(headingTop(), closeTo(resting - 200, 1));

      // Now the table's top has gone above, and the heading stops with it.
      await tester.drag(find.text('n2'), const Offset(0, -200));
      await tester.pumpAndSettle();
      final held = headingTop();
      expect(tableTop(), lessThan(0));
      expect(held, lessThan(60), reason: 'up against the top of the page');

      await tester.drag(find.text('n2'), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tableTop(), lessThan(-200), reason: 'the table went further');
      expect(headingTop(), closeTo(held, 1), reason: 'the heading did not');
    });

    testWidgets('it keeps its place in the layout', (tester) async {
      // Drawn lower down, not moved: the rows must not slide up into the
      // space the heading came from.
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      double firstRowBelowTable() =>
          tester.getRect(find.text('n0')).top -
          tester.getRect(find.byType(Table<_User>)).top;
      final gap = firstRowBelowTable();
      // A heading's worth of room, not nothing: the space it leaves is
      // reserved rather than reclaimed.
      expect(gap, greaterThan(40));

      await tester.drag(find.text('n2'), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(firstRowBelowTable(), closeTo(gap, 1));
    });

    testWidgets('an offset holds it below a bar of your own', (tester) async {
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      await tester.drag(find.text('n2'), const Offset(0, -400));
      await tester.pumpAndSettle();
      final plain = tester.getRect(find.text('Name')).top;

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(page(offsetHeader: 40));
      await tester.pumpAndSettle();
      await tester.drag(find.text('n2'), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Name')).top, closeTo(plain + 40, 1));
    });

    testWidgets('it has a ground of its own', (tester) async {
      // The heading's own fill is a two per cent wash: held over the rows it
      // let them be read straight through.
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();

      final fills = tester
          .widgetList<ColoredBox>(
            find.ancestor(
              of: find.text('Name'),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((b) => b.color)
          .where((c) => c.a == 1.0)
          .toList();
      expect(fills, isNotEmpty);
    });

    testWidgets('it costs a lazy table nothing, because it never applies',
        (tester) async {
      // A table with a height of its own already keeps its heading, so sticky
      // is ignored there — and must not push it off the lazy body on the way.
      Future<int> cells({required bool sticky}) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          _host(
            Table<int>(
              scroll: const TableScroll(y: 200),
              sticky: sticky ? const TableSticky() : null,
              columns: [
                TableColumn<int>(title: const Text('N'), value: (v) => 'n$v'),
              ],
              data: [for (var i = 0; i < 200; i++) i],
            ),
          ),
        );
        await tester.pumpAndSettle();
        return find.byType(RichText).evaluate().length;
      }

      final without = await cells(sticky: false);
      final with_ = await cells(sticky: true);
      expect(with_, without);
      expect(without, lessThan(60), reason: 'and both are lazy');
    });

    testWidgets('a table with rows of its own is left alone', (tester) async {
      // Its heading already stays put; holding it again would only take it
      // away from its own rows.
      await tester.pumpWidget(
        _host(
          Table<_User>(
            sticky: const TableSticky(),
            scroll: const TableScroll(y: 200),
            data: many,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('n0'), findsOneWidget);
    });
  });

  group('a width of its own', () {
    Widget table({TableScroll? scroll, double box = 300}) => _host(
          Table<_User>(
            scroll: scroll,
            data: const [
              _User('a name long enough to want room', 27),
              _User('short', 45),
            ],
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
              ),
              TableColumn<_User>(
                title: const Text('Age'),
                value: (u) => u.age,
              ),
            ],
          ),
          width: box,
        );

    testWidgets('the columns take what they need, not a share of the box',
        (tester) async {
      // Squeezed into the box, the long name has to wrap or be cut; asked for
      // its own width, it stands out to its full length and the table scrolls.
      await tester.pumpWidget(table(scroll: const TableScroll.toContent()));
      await tester.pumpAndSettle();

      final name = tester.getRect(find.text('a name long enough to want room'));
      expect(name.width, greaterThan(300),
          reason: 'wider than the box it stands in');
    });

    testWidgets('and it scrolls sideways', (tester) async {
      await tester.pumpWidget(table(scroll: const TableScroll.toContent()));
      await tester.pumpAndSettle();
      final before = tester.getRect(find.text('Name')).left;

      // Dragged by the heading in view: with a content width the far column
      // stands off the screen and cannot be hit.
      await tester.drag(find.text('Name'), const Offset(-120, 0));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Name')).left, closeTo(before - 120, 1));
    });

    testWidgets('without it the columns share the box', (tester) async {
      await tester.pumpWidget(table());
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(Table<_User>)).width, closeTo(300, 1));
    });

    testWidgets('a scrolling body can take its width from its columns too',
        (tester) async {
      await tester.pumpWidget(
        table(scroll: const TableScroll.toContent(y: 120)),
      );
      await tester.pumpAndSettle();
      final name = tester.getRect(find.text('a name long enough to want room'));
      expect(name.width, greaterThan(300));
      expect(tester.getRect(find.byType(Table<_User>)).height, lessThan(220),
          reason: 'the height it was given, heading and all');
    });

    test('a content width says so through its own constructor', () {
      expect(const TableScroll.toContent().isToContent, isTrue);
      expect(const TableScroll(x: 900).isToContent, isFalse);
      expect(const TableScroll().isToContent, isFalse);
    });
  });

  group('columns you can move', () {
    const people = [_User('Chen', 27), _User('Ann', 45)];

    Widget table({
      bool draggable = true,
      void Function(int, int)? onReordered,
    }) =>
        _host(
          Table<_User>(
            data: people,
            columnsDraggable: draggable,
            onColumnsReordered: onReordered,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                sortable: true,
                value: (u) => u.name,
              ),
              TableColumn<_User>(
                // Sortable too, so a sort pointed at the wrong column sorts
                // by something and the difference can be seen.
                title: const Text('Age'),
                sortable: true,
                value: (u) => u.age,
              ),
              TableColumn<_User>(
                title: const Text('City'),
                value: (u) => 'city',
              ),
            ],
          ),
          width: 700,
        );

    testWidgets('a heading carried onto another takes its place',
        (tester) async {
      int? from;
      int? to;
      await tester.pumpWidget(table(onReordered: (a, b) {
        from = a;
        to = b;
      }));

      List<String> headings() => tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .where((s) => s == 'Name' || s == 'Age' || s == 'City')
          .toList();
      expect(headings(), ['Name', 'Age', 'City']);

      final onto = tester.getCenter(find.text('City'));
      final grab = await tester.startGesture(
        tester.getCenter(find.text('Name')),
      );
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(onto);
      await tester.pump();
      await grab.up();
      await tester.pumpAndSettle();

      // The table moved it itself; the callback is word of what happened.
      expect(headings(), ['Age', 'City', 'Name']);
      expect(from, 0);
      expect(to, 2);
    });

    testWidgets('the neighbours slide aside while it is carried',
        (tester) async {
      await tester.pumpWidget(table(onReordered: (_, __) {}));
      await tester.pumpAndSettle();

      // The first is the heading in the table; while a drag is under way the
      // carried copy is a second widget with the same text.
      double leftOf(String text) => tester.getRect(find.text(text).first).left;
      final ageAtRest = leftOf('Age');
      final cityAtRest = leftOf('City');
      final nameAtRest = leftOf('Name');

      // Taken before the drag: where a column would land is read off the
      // layout, which does not move, and not off the slid cells.
      final atCity = tester.getCenter(find.text('City'));
      final atAge = tester.getCenter(find.text('Age'));
      final grab =
          await tester.startGesture(tester.getCenter(find.text('Name')));
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(atCity);
      await tester.pumpAndSettle();

      // The two it steps over have closed the gap it left, and it stands
      // where they were — nothing has been reordered, only moved.
      expect(leftOf('Age'), lessThan(ageAtRest));
      expect(leftOf('City'), lessThan(cityAtRest));
      expect(leftOf('Name'), greaterThan(nameAtRest));

      // And it slides rather than jumping. Carried back over Age, City has
      // nothing to get out of the way of any more and goes home — part way
      // through, it is between the two places.
      await grab.moveTo(atAge);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final partWay = leftOf('City');
      await tester.pumpAndSettle();
      expect(partWay, isNot(closeTo(leftOf('City'), 0.5)));
      expect(leftOf('City'), closeTo(cityAtRest, 0.5),
          reason: 'and it arrives where it started');
    });

    testWidgets('a hand held still leaves the columns still', (tester) async {
      // Where a column would land is read off the layout, which does not
      // move. Asked of whatever cell lay under the finger instead, the
      // answer chased the cells as they slid and the two columns swapped
      // back and forth with the hand standing still.
      await tester.pumpWidget(table(onReordered: (_, __) {}));
      await tester.pumpAndSettle();

      double leftOf(String text) => tester.getRect(find.text(text).first).left;

      final atCity = tester.getCenter(find.text('City'));
      final grab =
          await tester.startGesture(tester.getCenter(find.text('Name')));
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(atCity);
      await tester.pumpAndSettle();

      final settled = [leftOf('Name'), leftOf('Age'), leftOf('City')];

      // A hand is never quite still, and every twitch asks the question
      // again: with the cells sliding under it, the answer alternated and
      // the columns swapped back and forth.
      for (var i = 0; i < 8; i++) {
        await grab.moveTo(atCity + Offset(i.isEven ? 1 : -1, 0));
        await tester.pumpAndSettle();
        expect(
          [leftOf('Name'), leftOf('Age'), leftOf('City')],
          [
            closeTo(settled[0], 1.5),
            closeTo(settled[1], 1.5),
            closeTo(settled[2], 1.5),
          ],
          reason: 'nothing moved but the finger',
        );
      }

      await grab.up();
      await tester.pumpAndSettle();
    });

    testWidgets('letting go settles at once, with no second journey',
        (tester) async {
      // By the drop the columns are already standing where they will stand,
      // so committing the order must change nothing. Kept as they were, the
      // cells carried their offsets into the new order and set off again —
      // arriving from opposite sides at places they were already in.
      await tester.pumpWidget(table(onReordered: (_, __) {}));
      await tester.pumpAndSettle();

      double leftOf(String text) => tester.getRect(find.text(text).first).left;

      final atCity = tester.getCenter(find.text('City'));
      final grab =
          await tester.startGesture(tester.getCenter(find.text('Name')));
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(atCity);
      await tester.pumpAndSettle();

      final carried = [leftOf('Age'), leftOf('City')];

      await grab.up();
      await tester.pump();
      // One frame later, and already home.
      expect(
        [leftOf('Age'), leftOf('City')],
        [closeTo(carried[0], 1), closeTo(carried[1], 1)],
      );

      await tester.pumpAndSettle();
      expect(
        [leftOf('Age'), leftOf('City')],
        [closeTo(carried[0], 1), closeTo(carried[1], 1)],
        reason: 'and it never set off again',
      );

      // And the heading the hand left goes back to its own colour: it is no
      // longer under anything.
      final lit = tester
          .widgetList<ColoredBox>(
            find.ancestor(
              of: find.text('Name'),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((b) => b.color)
          .where((c) => c.a != 0);
      expect(lit, isEmpty);
    });

    testWidgets('a hand that wanders off and comes back still moves them',
        (tester) async {
      // Leaving the table is not letting go of it. Cleared together with what
      // it was picked up from, there was nothing left to move the neighbours
      // for and only the heading's own fill answered.
      await tester.pumpWidget(table(onReordered: (_, __) {}));
      await tester.pumpAndSettle();

      double leftOf(String text) => tester.getRect(find.text(text).first).left;
      final atRest = leftOf('City');
      final atCity = tester.getCenter(find.text('City'));

      final grab =
          await tester.startGesture(tester.getCenter(find.text('Name')));
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(atCity);
      await tester.pumpAndSettle();
      final carried = leftOf('City');
      expect(carried, lessThan(atRest));

      // Out of the table altogether, and the neighbours go home.
      await grab.moveTo(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(leftOf('City'), closeTo(atRest, 1));

      // Back again, and they move aside once more.
      await grab.moveTo(atCity);
      await tester.pumpAndSettle();
      expect(leftOf('City'), closeTo(carried, 1));

      await grab.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a drag given up puts the columns back', (tester) async {
      await tester.pumpWidget(table(onReordered: (_, __) {}));

      List<String> headings() => tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .where((s) => s == 'Name' || s == 'Age' || s == 'City')
          .toList();

      final onto = tester.getCenter(find.text('City'));
      final grab =
          await tester.startGesture(tester.getCenter(find.text('Name')));
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(onto);
      await tester.pump();
      await grab.cancel();
      await tester.pumpAndSettle();

      expect(headings(), ['Name', 'Age', 'City'],
          reason: 'the preview was only a preview');
    });

    testWidgets('a column of boxes in front does not shift what is dragged',
        (tester) async {
      // The place a column is drawn at and the place it was listed at are two
      // different numbers, and a column of boxes in front makes them differ:
      // dragging by the drawn place moved the column beside the one held.
      final columns = ['Name', 'Age', 'City'];
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: people,
            selection: const TableSelection<_User>(),
            columnsDraggable: true,
            columns: [
              for (final name in columns)
                TableColumn<_User>(
                  title: Text(name),
                  value: (u) => '$name-cell',
                ),
            ],
          ),
          width: 700,
        ),
      );

      List<String> cells() => tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .where((s) => s.endsWith('-cell'))
          .toList();
      expect(cells().take(3), ['Name-cell', 'Age-cell', 'City-cell']);

      final onto = tester.getCenter(find.text('City'));
      final grab =
          await tester.startGesture(tester.getCenter(find.text('Name')));
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(onto);
      await tester.pump();
      await grab.up();
      await tester.pumpAndSettle();

      expect(cells().take(3), ['Age-cell', 'City-cell', 'Name-cell']);
    });

    testWidgets('a column of boxes in front does not shift what a sort names',
        (tester) async {
      // The same two numbers, on the lazy body: keyed by the drawn place, a
      // tap on the first heading sorted by the second column — which here
      // does not sort at all, so nothing happened.
      await tester.pumpWidget(
        _host(
          Table<_User>(
            scroll: const TableScroll(y: 200),
            selection: const TableSelection<_User>(),
            data: people,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                sortable: true,
                value: (u) => u.name,
              ),
              TableColumn<_User>(
                title: const Text('Other'),
                value: (u) => 'z',
              ),
            ],
          ),
          width: 700,
        ),
      );
      await tester.pumpAndSettle();

      List<String> names() => tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .where((s) => s == 'Chen' || s == 'Ann')
          .toList();
      expect(names(), ['Chen', 'Ann']);

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(names(), ['Ann', 'Chen'], reason: 'it sorted by the column held');
    });

    testWidgets('a heading dropped on itself moves nothing', (tester) async {
      var told = 0;
      await tester.pumpWidget(table(onReordered: (_, __) => told++));

      // Taken before the drag: while it is under way the carried heading is
      // a second widget with the same text.
      final where = tester.getCenter(find.text('Age'));
      final grab = await tester.startGesture(where);
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(where);
      await tester.pump();
      await grab.up();
      await tester.pumpAndSettle();

      expect(told, 0);
    });

    testWidgets('a scrolling table can be rearranged and stays lazy',
        (tester) async {
      // The viewport lays the columns out, so it is the viewport that is
      // asked where a carried heading would land — and the shift it slides
      // them by goes into the same reckoning that places them.
      await tester.pumpWidget(
        _host(
          Table<int>(
            scroll: const TableScroll(y: 240),
            columnsDraggable: true,
            data: [for (var i = 0; i < 300; i++) i],
            columns: [
              for (final name in ['A', 'B', 'C'])
                TableColumn<int>(
                  title: Text(name),
                  value: (v) => '$name$v',
                ),
            ],
          ),
          width: 700,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RichText).evaluate().length, lessThan(80),
          reason: 'and it did not cost the lazy body');

      double leftOf(String text) => tester.getRect(find.text(text)).left;
      final atRest = [leftOf('A0'), leftOf('B0'), leftOf('C0')];

      final onto = tester.getCenter(find.text('C'));
      final grab = await tester.startGesture(tester.getCenter(find.text('A')));
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(onto);
      await tester.pumpAndSettle();

      // Carried: A stands where C stood and the others have closed up behind
      // it — the columns are of a width, so the places swap exactly.
      expect(leftOf('A0'), closeTo(atRest[2], 1));
      expect(leftOf('B0'), closeTo(atRest[0], 1));
      expect(leftOf('C0'), closeTo(atRest[1], 1));

      final carried = [leftOf('A0'), leftOf('B0'), leftOf('C0')];
      await grab.up();
      await tester.pump();
      expect(
        [leftOf('A0'), leftOf('B0'), leftOf('C0')],
        [
          closeTo(carried[0], 1),
          closeTo(carried[1], 1),
          closeTo(carried[2], 1),
        ],
        reason: 'letting go settles where it already stood',
      );
    });

    testWidgets('nothing is draggable unless the table says so',
        (tester) async {
      await tester.pumpWidget(table(draggable: false));
      expect(find.byType(Draggable<int>), findsNothing);
      expect(find.byType(DragTarget<int>), findsNothing);
    });

    testWidgets('moving a column does not move what a sort names',
        (tester) async {
      // The order columns are drawn in is not the order they are named in: a
      // sort keeps meaning the column it was given, not the one that ends up
      // standing there.
      await tester.pumpWidget(table(onReordered: (_, __) {}));
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();

      List<String> names() => tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .where((s) => s == 'Chen' || s == 'Ann')
          .toList();
      expect(names(), ['Ann', 'Chen'], reason: 'sorted by name');

      final onto = tester.getCenter(find.text('City'));
      final grab =
          await tester.startGesture(tester.getCenter(find.text('Name')));
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(onto);
      await tester.pump();
      await grab.up();
      await tester.pumpAndSettle();

      expect(names(), ['Ann', 'Chen'],
          reason: 'still sorted by name, wherever the column now stands');

      // And the mark is still on Name: the sort names a column, not a place.
      Color? fillOver(String text) {
        final fills = tester
            .widgetList<ColoredBox>(
              find.ancestor(
                of: find.text(text),
                matching: find.byType(ColoredBox),
              ),
            )
            .map((b) => b.color)
            .where((c) => c.a != 0)
            .toList();
        return fills.isEmpty ? null : fills.first;
      }

      expect(fillOver('Name'), isNotNull);
      expect(fillOver('Age'), isNull);
    });

    testWidgets('a heading that sorts can still be tapped', (tester) async {
      // The drag is wrapped round the sorting, not instead of it.
      await tester.pumpWidget(table(onReordered: (_, __) {}));
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();

      final names = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .where((s) => s == 'Chen' || s == 'Ann')
          .toList();
      expect(names, ['Ann', 'Chen'], reason: 'it sorted');
    });
  });

  group('rows you can move', () {
    final many = [for (var i = 0; i < 5; i++) _User('n$i', i)];

    Widget table({
      bool draggable = true,
      void Function(int, int)? onReordered,
      List<TableSort>? defaultSort,
    }) =>
        _host(
          Table<_User>(
            data: many,
            rowsDraggable: draggable,
            onRowsReordered: onReordered,
            defaultSort: defaultSort,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                sortable: true,
                value: (u) => u.name,
              ),
            ],
          ),
          width: 400,
        );

    List<String> shown(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((s) => s.startsWith('n'))
        .toList();

    testWidgets('a row carried onto another takes its place', (tester) async {
      int? from;
      int? to;
      await tester.pumpWidget(table(onReordered: (a, b) {
        from = a;
        to = b;
      }));
      await tester.pumpAndSettle();
      expect(shown(tester).take(3), ['n0', 'n1', 'n2']);

      final onto = tester.getCenter(find.text('n2'));
      final grab = await tester.startGesture(
        tester.getCenter(find.text('n0')),
      );
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(onto);
      await tester.pumpAndSettle();
      await grab.up();
      await tester.pumpAndSettle();

      expect(shown(tester).take(3), ['n1', 'n2', 'n0']);
      expect(from, 0);
      expect(to, 2);
    });

    testWidgets('the rows below slide up as it is carried', (tester) async {
      await tester.pumpWidget(table(onReordered: (_, __) {}));
      await tester.pumpAndSettle();

      double topOf(String text) => tester.getRect(find.text(text).first).top;
      final atRest = [topOf('n1'), topOf('n2')];

      final onto = tester.getCenter(find.text('n2'));
      final grab = await tester.startGesture(
        tester.getCenter(find.text('n0')),
      );
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(onto);
      await tester.pumpAndSettle();

      expect(topOf('n1'), lessThan(atRest[0]));
      expect(topOf('n2'), lessThan(atRest[1]));

      await grab.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a hand that wanders off and comes back still moves them',
        (tester) async {
      await tester.pumpWidget(table(onReordered: (_, __) {}));
      await tester.pumpAndSettle();

      double topOf(String text) => tester.getRect(find.text(text).first).top;
      final atRest = topOf('n2');
      final onto = tester.getCenter(find.text('n2'));

      final grab = await tester.startGesture(
        tester.getCenter(find.text('n0')),
      );
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(onto);
      await tester.pumpAndSettle();
      final carried = topOf('n2');
      expect(carried, lessThan(atRest));

      await grab.moveTo(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(topOf('n2'), closeTo(atRest, 1));

      await grab.moveTo(onto);
      await tester.pumpAndSettle();
      expect(topOf('n2'), closeTo(carried, 1));

      await grab.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a drag given up puts the rows back', (tester) async {
      await tester.pumpWidget(table(onReordered: (_, __) {}));
      await tester.pumpAndSettle();

      final onto = tester.getCenter(find.text('n2'));
      final grab = await tester.startGesture(
        tester.getCenter(find.text('n0')),
      );
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(onto);
      await tester.pumpAndSettle();
      await grab.cancel();
      await tester.pumpAndSettle();

      expect(shown(tester).take(3), ['n0', 'n1', 'n2']);
    });

    testWidgets('nothing is draggable unless the table says so',
        (tester) async {
      await tester.pumpWidget(table(draggable: false));
      await tester.pumpAndSettle();
      expect(find.byType(Draggable<int>), findsNothing);
    });

    testWidgets('a row can still be tapped', (tester) async {
      // The drag is wrapped round what a row already does, not put in its
      // place.
      _User? tapped;
      await tester.pumpWidget(
        _host(
          Table<_User>(
            data: many,
            rowsDraggable: true,
            onRowTap: (record, _) => tapped = record,
            columns: [
              TableColumn<_User>(
                title: const Text('Name'),
                value: (u) => u.name,
              ),
            ],
          ),
          width: 400,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('n1'));
      await tester.pumpAndSettle();
      expect(tapped?.name, 'n1');
    });

    testWidgets('a scrolling table can be rearranged and stays lazy',
        (tester) async {
      // A lazy body has no row of its own to take hold of, only the cells
      // standing in it — so a cell carries its row, and the viewport is
      // asked which row the finger is over.
      await tester.pumpWidget(
        _host(
          Table<int>(
            scroll: const TableScroll(y: 240),
            rowsDraggable: true,
            data: [for (var i = 0; i < 300; i++) i],
            columns: [
              TableColumn<int>(title: const Text('N'), value: (v) => 'n$v'),
            ],
          ),
          width: 500,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RichText).evaluate().length, lessThan(60),
          reason: 'and it did not cost the lazy body');

      double topOf(String text) => tester.getRect(find.text(text)).top;
      final atRest = [topOf('n0'), topOf('n1'), topOf('n2')];

      final onto = tester.getCenter(find.text('n2'));
      final grab = await tester.startGesture(
        tester.getCenter(find.text('n0')),
      );
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(onto);
      await tester.pumpAndSettle();

      expect(topOf('n0'), closeTo(atRest[2], 1),
          reason: 'carried to the third');
      expect(topOf('n1'), closeTo(atRest[0], 1), reason: 'and these closed up');
      expect(topOf('n2'), closeTo(atRest[1], 1));

      final carried = [topOf('n0'), topOf('n1'), topOf('n2')];
      await grab.up();
      await tester.pump();
      expect(
        [topOf('n0'), topOf('n1'), topOf('n2')],
        [
          closeTo(carried[0], 1),
          closeTo(carried[1], 1),
          closeTo(carried[2], 1),
        ],
        reason: 'letting go settles where it already stood',
      );
    });

    testWidgets('a sort still has the last word', (tester) async {
      // The order a drag changes is the one the rows came in; sorting a table
      // you can also arrange by hand is asking for two answers to one
      // question, so the sort wins.
      await tester.pumpWidget(table(
        onReordered: (_, __) {},
        defaultSort: const [TableSort(0, TableSortOrder.descending)],
      ));
      await tester.pumpAndSettle();
      expect(shown(tester).take(2), ['n4', 'n3']);

      final onto = tester.getCenter(find.text('n2'));
      final grab = await tester.startGesture(
        tester.getCenter(find.text('n4')),
      );
      await tester.pump(kLongPressTimeout);
      await grab.moveTo(onto);
      await tester.pumpAndSettle();
      await grab.up();
      await tester.pumpAndSettle();

      expect(shown(tester).take(2), ['n4', 'n3'],
          reason: 'still in the order the sort asks for');
    });
  });

  group('the marks a heading carries', () {
    testWidgets('they are sized against each other, not each on its own',
        (tester) async {
      // The mark that opens a row is the size of a checkbox — the reference
      // scales it to the same interactive size — and the carets and the
      // funnel are both the icon size. Asserted as relations rather than as
      // numbers: what matters is that a column of boxes and a column of
      // marks agree.
      await tester.pumpWidget(
        _host(
          Table<int>(
            data: const [0, 1],
            selection: const TableSelection<int>(),
            expandable: TableExpandable<int>(
              builder: (_, v, __) => const Text('panel'),
            ),
            columns: [
              TableColumn<int>(
                title: const Text('N'),
                sortable: true,
                value: (v) => 'n$v',
                filters: const [TableFilter('one', 1)],
              ),
            ],
          ),
          width: 600,
        ),
      );
      await tester.pumpAndSettle();

      Size painted(String painter) => tester
          .getRect(
            find
                .byWidgetPredicate((w) =>
                    w is CustomPaint &&
                    w.painter.runtimeType.toString() == painter)
                .first,
          )
          .size;

      final box = tester
          .getRect(
            find
                .byWidgetPredicate(
                  (w) => w.runtimeType.toString() == 'CheckboxBox',
                )
                .first,
          )
          .size;

      expect(painted('_ExpandIconPainter').width, closeTo(box.width, 0.5));
      expect(painted('_ExpandIconPainter').height, closeTo(box.height, 0.5));

      // The pair of carets stands as tall as the funnel: both are the mark
      // size, and a heading carrying one of each should not look lopsided.
      final caret = painted('_CaretPainter');
      final funnel = painted('_FunnelPainter');
      expect(
          caret.height * 2 + funnel.height * 0.16, closeTo(funnel.height, 1.5));
    });
  });
}
