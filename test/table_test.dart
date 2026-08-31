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
