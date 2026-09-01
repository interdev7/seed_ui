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
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

class _User {
  const _User(this.name, this.age);
  final String name;
  final int age;
}

const _users = [_User('Ann', 31), _User('Bartholomew Longname', 7)];

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
      // their own, and the shade is only one of them.
      PaintPattern casts(Rect where) => paints
        ..something(
          (symbol, arguments) => symbol == #drawRect && arguments[0] == where,
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
        casts(const Rect.fromLTWH(296, 0, 24, 232)),
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
        casts(const Rect.fromLTWH(100, 0, 24, 232)),
        reason: 'now the leading one does, against its own edge',
      );
      expect(
        tester.renderObject(viewport()),
        isNot(casts(const Rect.fromLTWH(296, 0, 24, 232))),
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

    testWidgets('a pinned column goes to its edge wherever it was listed',
        (tester) async {
      await tester.pumpWidget(pinned(y: 200, endFirst: true));
      final table = tester.getRect(find.byType(Table<int>));
      expect(
        tester.getRect(find.text('e0')).left - table.left,
        greaterThan(200),
        reason: 'listed first, drawn last, because that is its edge',
      );
      expect(tester.getRect(find.text('p0')).left - table.left, lessThan(100));
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
      TableSort? sort,
      TableSort? defaultSort,
      ValueChanged<TableSort?>? onSortChanged,
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
        table(defaultSort: const TableSort(1, TableSortOrder.descending)),
      );
      expect(shown(tester), ['Ann', '45', 'Bart', '31', 'Chen', '27']);
    });

    testWidgets('a sort given is the sort shown, and tapping only tells',
        (tester) async {
      TableSort? told;
      await tester.pumpWidget(table(
        sort: const TableSort(0, TableSortOrder.ascending),
        onSortChanged: (next) => told = next,
      ));
      expect(shown(tester), ['Ann', '45', 'Bart', '31', 'Chen', '27']);

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(told, const TableSort(0, TableSortOrder.descending),
          reason: 'it said what it would have become');
      expect(shown(tester), ['Ann', '45', 'Bart', '31', 'Chen', '27'],
          reason: 'and changed nothing itself');
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
            defaultSort: const TableSort(0, TableSortOrder.ascending),
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
      Widget host({TableSort? sort}) => _host(
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
        host(sort: const TableSort(0, TableSortOrder.ascending)),
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
              defaultSort: TableSort(0, order),
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
          reason: 'the padding is part of it, as antd lights up the th');

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
        table(defaultSort: const TableSort(1, TableSortOrder.ascending)),
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
      TableSort? defaultSort,
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
        defaultSort: const TableSort(0, TableSortOrder.ascending),
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
      expect(menu.width, greaterThanOrEqualTo(120), reason: 'antd\'s floor');
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
      // And the mark itself darkens, as antd's does: the ground alone would
      // leave a mark you can barely see sitting on it.
      expect(funnelColour(tester), isNot(idle));
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
}
