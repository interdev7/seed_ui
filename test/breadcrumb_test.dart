import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart'
    hide
        ThemeData,
        Checkbox,
        Radio,
        RadioGroup,
        Switch,
        Tooltip,
        Drawer,
        Divider;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => ConfigProvider(
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: Scaffold(
          body: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    );

const _path = [
  BreadcrumbItem(value: 'home', label: 'Home'),
  BreadcrumbItem(value: 'projects', label: 'Projects'),
  BreadcrumbItem(value: 'seed', label: 'Seed'),
];

Color _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  testWidgets('crumbs in order, a separator between each two', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const Breadcrumb<String>(items: _path)));
    expect(find.text('/'), findsNWidgets(2));
    final home = tester.getCenter(find.text('Home')).dx;
    final projects = tester.getCenter(find.text('Projects')).dx;
    final seed = tester.getCenter(find.text('Seed')).dx;
    expect(home < projects && projects < seed, isTrue);
  });

  testWidgets('a separator of your own', (tester) async {
    await tester.pumpWidget(
      _host(const Breadcrumb<String>(items: _path, separator: Text('>'))),
    );
    expect(find.text('>'), findsNWidgets(2));
    expect(find.text('/'), findsNothing);
  });

  testWidgets('a crumb up the path reports its value; the page does not', (
    tester,
  ) async {
    final told = <String?>[];
    var own = 0;
    await tester.pumpWidget(
      _host(
        Breadcrumb<String>(
          items: [
            BreadcrumbItem(value: 'home', label: 'Home', onTap: () => own++),
            ..._path.skip(1),
          ],
          onItemTap: told.add,
        ),
      ),
    );
    await tester.tap(find.text('Home'));
    await tester.tap(find.text('Seed'));
    expect(told, ['home']);
    expect(own, 1);
  });

  testWidgets('a key presses a crumb too', (tester) async {
    final told = <String?>[];
    await tester.pumpWidget(
      _host(Breadcrumb<String>(items: _path, onItemTap: told.add)),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(told, ['home']);
  });

  testWidgets('a link lights up under the pointer; the page does not', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const Breadcrumb<String>(items: _path)));
    final resting = _colorOf(tester, 'Home');
    final page = _colorOf(tester, 'Seed');
    expect(resting, isNot(page), reason: 'the page is darker than the path');

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Home')));
    await tester.pump();
    expect(_colorOf(tester, 'Home'), page);

    await mouse.moveTo(tester.getCenter(find.text('Seed')));
    await tester.pump();
    expect(_colorOf(tester, 'Home'), resting);
    expect(_colorOf(tester, 'Seed'), page);
    await mouse.removePointer();
  });

  testWidgets('a reader hears links up the path and the page as text', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const Breadcrumb<String>(items: _path)));
    expect(
      tester.getSemantics(find.text('Home')),
      matchesSemantics(
        label: 'Home',
        isLink: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Seed')),
      matchesSemantics(label: 'Seed'),
    );
    handle.dispose();
  });

  testWidgets('a crumb that is an icon alone is named by semanticsLabel', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const Breadcrumb<String>(
          items: [
            BreadcrumbItem(
              value: 'home',
              icon: Icon(Icons.home),
              semanticsLabel: 'Home',
            ),
            BreadcrumbItem(label: 'Seed'),
          ],
        ),
      ),
    );
    expect(
      find.bySemanticsLabel('Home'),
      findsOneWidget,
    );
    handle.dispose();
  });

  group('a crumb with a menu', () {
    Widget menu(List<String?> told) => _host(
          Breadcrumb<String>(
            items: const [
              BreadcrumbItem(value: 'home', label: 'Home'),
              BreadcrumbItem(
                value: 'seed',
                label: 'Seed',
                menu: [
                  DropdownItem(value: 'atlas', label: 'Atlas'),
                  DropdownItem(value: 'orbit', label: 'Orbit'),
                ],
              ),
            ],
            onItemTap: told.add,
          ),
        );

    testWidgets('a tap opens it, and a choice is reported', (tester) async {
      final told = <String?>[];
      await tester.pumpWidget(menu(told));
      expect(find.text('Atlas'), findsNothing);

      await tester.tap(find.text('Seed'));
      await tester.pumpAndSettle();
      expect(find.text('Atlas'), findsOneWidget);

      await tester.tap(find.text('Orbit'));
      await tester.pumpAndSettle();
      expect(told, ['orbit']);
      expect(find.text('Atlas'), findsNothing);
    });

    testWidgets('a key opens it', (tester) async {
      await tester.pumpWidget(menu([]));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Atlas'), findsOneWidget);
    });

    testWidgets('a tap elsewhere shuts it', (tester) async {
      await tester.pumpWidget(menu([]));
      await tester.tap(find.text('Seed'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(700, 500));
      await tester.pumpAndSettle();
      expect(find.text('Atlas'), findsNothing);
    });
  });

  group('maxItems', () {
    const long = [
      BreadcrumbItem(value: 'a', label: 'A'),
      BreadcrumbItem(value: 'b', label: 'B'),
      BreadcrumbItem(value: 'c', label: 'C'),
      BreadcrumbItem(value: 'd', label: 'D'),
      BreadcrumbItem(value: 'e', label: 'E'),
    ];

    testWidgets('folds the middle into a menu of what it hides', (
      tester,
    ) async {
      final told = <String?>[];
      await tester.pumpWidget(
        _host(
          Breadcrumb<String>(items: long, maxItems: 4, onItemTap: told.add),
        ),
      );
      for (final shown in ['A', '…', 'D', 'E']) {
        expect(find.text(shown), findsOneWidget, reason: shown);
      }
      expect(find.text('B'), findsNothing);
      expect(find.text('C'), findsNothing);

      await tester.tap(find.text('…'));
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);
      await tester.tap(find.text('C'));
      await tester.pumpAndSettle();
      expect(told, ['c']);
    });

    testWidgets('a path that fits is left alone', (tester) async {
      await tester.pumpWidget(
        _host(const Breadcrumb<String>(items: long, maxItems: 5)),
      );
      expect(find.text('…'), findsNothing);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('the … is called "Show more" out loud', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const Breadcrumb<String>(items: long, maxItems: 3)),
      );
      expect(find.bySemanticsLabel('Show more'), findsOneWidget);
      expect(find.text('D'), findsNothing, reason: 'root, …, page');
      handle.dispose();
    });
  });
}
