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

    testWidgets('a scrolling table shares the width between its columns',
        (tester) async {
      // The trade a detached heading forces: an intrinsic width would measure
      // the title in one table and the cells in the other.
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
      expect(second, closeTo(200 + 16, 2), reason: 'half each, then padding');
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

    testWidgets('and there is a bar to show it can be', (tester) async {
      await tester.pumpWidget(rows(const TableScroll(x: 1200), n: 3));
      final bar = tester.widget<RawScrollbar>(find.byType(RawScrollbar));
      expect(bar.thumbVisibility, isTrue,
          reason: 'a table wide enough to scroll should say so');
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
      await mouse.moveBy(const Offset(-150, 0));
      await tester.pump();
      await mouse.up();
      await tester.pumpAndSettle();

      final headingMoved = headingBefore - tester.getRect(find.text('C0')).left;
      final cellMoved = cellBefore - tester.getRect(find.text('c0r0')).left;
      expect(cellMoved, greaterThan(100), reason: 'the rows went across');
      expect(headingMoved, cellMoved, reason: 'and the heading went with them');
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
      final first = tester.getRect(find.text('N0')).left;

      final pointer = TestPointer(1, PointerDeviceKind.trackpad);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('n0-1'))),
      );
      for (var i = 1; i <= 12; i++) {
        await tester.sendEventToBinding(pointer.scroll(Offset(120.0 * i, 0)));
        await tester.pumpAndSettle();
      }

      // Fifteen hundred of columns in a six-hundred-and-forty-wide pane.
      expect(first - tester.getRect(find.text('N0')).left, closeTo(860, 1));
      expect(
        tester.getRect(find.text('N14')).right,
        lessThanOrEqualTo(tester.getRect(find.byType(Table<int>)).right + 1),
        reason: 'the last column can be reached',
      );
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

    testWidgets('a rule stands between the panes', (tester) async {
      // Inside a pane the table draws its own; between them there was
      // nothing, so a pinned column ran into its neighbour unmarked.
      bool hasSeam() => find
          .byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).border is BorderDirectional,
          )
          .evaluate()
          .isNotEmpty;

      await tester.pumpWidget(pinned(y: 200));
      expect(hasSeam(), isFalse, reason: 'no rules were asked for');

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
      expect(hasSeam(), isTrue);
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
}
