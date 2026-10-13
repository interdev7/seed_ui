import 'dart:ui' show Tristate;

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

Widget _host(Widget child, {bool still = false, double width = 260}) =>
    ConfigProvider(
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: still),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    );

const _items = <MenuEntry<String>>[
  MenuItem(value: 'mail', label: 'Mail', icon: Icon(Icons.mail)),
  MenuItem(
    value: 'settings',
    label: 'Settings',
    icon: Icon(Icons.settings),
    children: [
      MenuItem(value: 'profile', label: 'Profile'),
      MenuItem(value: 'security', label: 'Security'),
    ],
  ),
  MenuDivider(),
  MenuGroup(
    label: 'More',
    children: [
      MenuItem(value: 'help', label: 'Help'),
      MenuItem(value: 'off', label: 'Off', disabled: true),
    ],
  ),
];

Color _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  group('inline', () {
    testWidgets('a tap selects an item and reports it', (tester) async {
      final told = <String>[];
      await tester.pumpWidget(
        _host(Menu<String>(items: _items, onSelect: told.add)),
      );
      final resting = _colorOf(tester, 'Mail');
      await tester.tap(find.text('Mail'));
      await tester.pump();
      expect(told, ['mail']);
      expect(_colorOf(tester, 'Mail'), isNot(resting));
    });

    testWidgets('a disabled item cannot be chosen', (tester) async {
      final told = <String>[];
      await tester.pumpWidget(
        _host(Menu<String>(items: _items, onSelect: told.add)),
      );
      await tester.tap(find.text('Off'));
      await tester.pump();
      expect(told, isEmpty);
    });

    testWidgets('a group heading and a divider are drawn', (tester) async {
      await tester.pumpWidget(_host(const Menu<String>(items: _items)));
      expect(find.text('More'), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
    });

    testWidgets('a title opens its submenu in place, and shuts it', (
      tester,
    ) async {
      final opened = <Set<String>>[];
      await tester.pumpWidget(
        _host(Menu<String>(items: _items, onOpenChanged: opened.add)),
      );
      expect(find.text('Profile').hitTestable(), findsNothing);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Profile').hitTestable(), findsOneWidget);
      expect(opened.last, {'settings'});
      expect(
        tester.getTopLeft(find.text('Profile')).dx,
        greaterThan(tester.getTopLeft(find.text('Mail')).dx),
        reason: 'a level further in',
      );

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Profile').hitTestable(), findsNothing);
      expect(opened.last, isEmpty);
    });

    testWidgets('where motion is turned down, it opens at once', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Menu<String>(items: _items), still: true),
      );
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Profile').hitTestable(), findsOneWidget);
    });

    testWidgets('the title of the selected item\'s submenu is lit too', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Menu<String>(
            items: _items,
            selectedValue: 'security',
            defaultOpenValues: {'settings'},
          ),
        ),
      );
      expect(_colorOf(tester, 'Settings'), _colorOf(tester, 'Security'));
      expect(_colorOf(tester, 'Settings'), isNot(_colorOf(tester, 'Mail')));
    });

    testWidgets('selectedValue moves the selection when it changes', (
      tester,
    ) async {
      Widget menu(String v) => _host(
            Menu<String>(items: _items, selectedValue: v),
          );
      await tester.pumpWidget(menu('mail'));
      final lit = _colorOf(tester, 'Mail');
      await tester.pumpWidget(menu('help'));
      expect(_colorOf(tester, 'Help'), lit);
      expect(_colorOf(tester, 'Mail'), isNot(lit));
    });

    testWidgets('openValues holds the submenus open', (tester) async {
      await tester.pumpWidget(
        _host(
          Menu<String>(
            items: _items,
            openValues: const {'settings'},
            onOpenChanged: (_) {},
          ),
        ),
      );
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(
        find.text('Profile').hitTestable(),
        findsOneWidget,
        reason: 'told to stay open, it waits to be told otherwise',
      );
    });

    testWidgets('accordion shuts the others at the same level', (
      tester,
    ) async {
      const two = <MenuEntry<String>>[
        MenuItem(
          value: 'a',
          label: 'A',
          children: [MenuItem(value: 'a1', label: 'A1')],
        ),
        MenuItem(
          value: 'b',
          label: 'B',
          children: [MenuItem(value: 'b1', label: 'B1')],
        ),
      ];
      await tester.pumpWidget(
        _host(const Menu<String>(items: two, accordion: true)),
      );
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(find.text('A1').hitTestable(), findsNothing);
      expect(find.text('B1').hitTestable(), findsOneWidget);
    });

    testWidgets('the keys walk, open and choose', (tester) async {
      final told = <String>[];
      await tester.pumpWidget(
        _host(Menu<String>(items: _items, onSelect: told.add)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // Mail
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // Settings
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); // opens
      await tester.pumpAndSettle();
      expect(find.text('Profile').hitTestable(), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // Profile
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(told, ['profile']);
    });

    testWidgets('a shut submenu is out of the tab order', (tester) async {
      final told = <String>[];
      await tester.pumpWidget(
        _host(Menu<String>(items: _items, onSelect: told.add)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // Mail
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // Settings
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // Help, not Profile
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(told, ['help']);
    });

    testWidgets('a reader hears what is selected and what is open', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const Menu<String>(items: _items, selectedValue: 'mail')),
      );
      expect(
        tester.getSemantics(find.text('Mail')),
        matchesSemantics(
          label: 'Mail',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      final title = tester.getSemantics(find.text('Settings'));
      expect(title.flagsCollection.isExpanded, Tristate.isFalse);
      expect(find.bySemanticsLabel('Profile'), findsNothing,
          reason: 'a shut submenu says nothing');
      handle.dispose();
    });
  });

  testWidgets('the rows stand as far from the top and bottom as the sides', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Menu<String>(
          items: [
            MenuItem(value: 'a', label: 'A'),
            MenuItem(value: 'b', label: 'B'),
          ],
          selectedValue: 'a',
        ),
      ),
    );
    final menu = tester.getRect(find.byType(Menu<String>));
    final first = tester.getRect(
      find
          .ancestor(of: find.text('A'), matching: find.byType(DecoratedBox))
          .first,
    );
    final last = tester.getRect(
      find
          .ancestor(of: find.text('B'), matching: find.byType(DecoratedBox))
          .first,
    );
    final side = first.left - menu.left;
    expect(side, 4);
    expect(first.top - menu.top, side);
    expect(menu.bottom - last.bottom, side);
  });

  group('collapsed', () {
    testWidgets('folds to its icons, named for a reader', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const Align(
            alignment: Alignment.topLeft,
            child: Menu<String>(items: _items, inlineCollapsed: true),
          ),
        ),
      );
      expect(tester.getSize(find.byType(Menu<String>)).width, 80);
      expect(find.text('Mail'), findsNothing);
      expect(find.bySemanticsLabel('Mail'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a submenu floats out beside it', (tester) async {
      final told = <String>[];
      await tester.pumpWidget(
        _host(
          Menu<String>(
            items: _items,
            inlineCollapsed: true,
            onSelect: told.add,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(told, ['profile']);
    });
  });

  group('vertical', () {
    testWidgets('a submenu floats out to the side, and a choice is reported',
        (tester) async {
      final told = <String>[];
      await tester.pumpWidget(
        _host(
          Menu<String>(
            mode: MenuMode.vertical,
            items: _items,
            onSelect: told.add,
          ),
        ),
      );
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Profile')).dx,
        greaterThan(tester.getTopRight(find.text('Settings')).dx),
      );
      await tester.tap(find.text('Security'));
      await tester.pumpAndSettle();
      expect(told, ['security']);
      expect(find.text('Profile'), findsNothing);
      expect(
        _colorOf(tester, 'Settings'),
        isNot(_colorOf(tester, 'Mail')),
        reason: 'the title of the chosen item is lit',
      );
    });
  });

  testWidgets('a pointer can go two submenus deep and choose', (
    tester,
  ) async {
    const deep = <MenuEntry<String>>[
      MenuItem(
        value: 'settings',
        label: 'Settings',
        children: [
          MenuItem(value: 'profile', label: 'Profile'),
          MenuItem(
            value: 'advanced',
            label: 'Advanced',
            children: [MenuItem(value: 'logs', label: 'Logs')],
          ),
        ],
      ),
    ];
    final told = <String>[];
    await tester.pumpWidget(
      _host(
        Menu<String>(
          mode: MenuMode.vertical,
          items: deep,
          onSelect: told.add,
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Settings')));
    await tester.pumpAndSettle();
    for (final step in ['Profile', 'Advanced', 'Logs']) {
      await mouse.moveTo(tester.getCenter(find.text(step)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }
    expect(find.text('Logs'), findsOneWidget);
    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();
    expect(told, ['logs']);
    await mouse.removePointer();
  });

  testWidgets('a floating submenu marks the selected item in it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Menu<String>(
          mode: MenuMode.vertical,
          items: _items,
          selectedValue: 'security',
        ),
      ),
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    Color colorOf(String text) => tester
        .widget<RichText>(
          find.descendant(of: find.text(text), matching: find.byType(RichText)),
        )
        .text
        .style!
        .color!;
    expect(colorOf('Security'), isNot(colorOf('Profile')));
    expect(colorOf('Security'), colorOf('Settings'),
        reason: 'the item and its title alike');
  });

  testWidgets('a title\'s chevron points where its submenu opened', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(380, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    int turns() => tester
        .widget<RotatedBox>(
          find.descendant(
            of: find
                .ancestor(
                  of: find.text('Settings'),
                  matching: find.byType(Row),
                )
                .first,
            matching: find.byType(RotatedBox),
          ),
        )
        .quarterTurns;
    await tester.pumpWidget(
      _host(const Menu<String>(mode: MenuMode.vertical, items: _items),
          width: 330),
    );
    expect(turns(), 0, reason: 'out to the right, as it reads');
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('Profile')).right,
      lessThan(tester.getRect(find.text('Settings')).right),
      reason: 'no room to the right: it opened on the left',
    );
    expect(turns(), 2);
  });

  testWidgets('read the other way, a submenu floats out to the left', (
    tester,
  ) async {
    await tester.pumpWidget(
      ConfigProvider(
        child: MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              // In the middle, with room on either side: where it opens is
              // the reading direction's choice, not the screen's.
              body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 240,
                  child: Menu<String>(
                    mode: MenuMode.vertical,
                    items: _items,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('Profile')).right,
      lessThan(tester.getRect(find.text('Settings')).left),
    );
  });

  group('horizontal', () {
    testWidgets('a row; a submenu drops down; a bar under the selected', (
      tester,
    ) async {
      final told = <String>[];
      await tester.pumpWidget(
        _host(
          Menu<String>(
            mode: MenuMode.horizontal,
            items: _items,
            selectedValue: 'mail',
            onSelect: told.add,
          ),
          width: 600,
        ),
      );
      final mail = tester.getCenter(find.text('Mail'));
      final settings = tester.getCenter(find.text('Settings'));
      expect(mail.dy, settings.dy);
      expect(mail.dx, lessThan(settings.dx));
      expect(tester.getSize(find.byType(Menu<String>)).height, 48);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Profile')).dy,
        greaterThan(settings.dy),
      );
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(told, ['profile']);
    });

    group('a bar too narrow for its items', () {
      const many = <MenuEntry<String>>[
        MenuItem(value: 'one', label: 'One'),
        MenuItem(value: 'two', label: 'Two'),
        MenuItem(value: 'three', label: 'Three'),
        MenuGroup(
          label: 'More',
          children: [
            MenuItem(value: 'four', label: 'Four'),
            MenuItem(value: 'five', label: 'Five'),
          ],
        ),
      ];

      Widget bar(double width, {String? selected, List<String>? told}) => _host(
            Menu<String>(
              mode: MenuMode.horizontal,
              items: many,
              selectedValue: selected,
              onSelect: told?.add,
            ),
            width: width,
          );

      testWidgets('folds what does not fit into a …, and nothing spills', (
        tester,
      ) async {
        await tester.pumpWidget(bar(220));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('…').hitTestable(), findsOneWidget);
        expect(find.text('One').hitTestable(), findsOneWidget);
        expect(find.text('Five').hitTestable(), findsNothing);
        expect(
          tester.getRect(find.byType(Menu<String>)).width,
          lessThanOrEqualTo(220),
        );
      });

      testWidgets('the … opens a menu of what it hides', (tester) async {
        final told = <String>[];
        await tester.pumpWidget(bar(220, told: told));
        await tester.pump();
        await tester.tap(find.text('…'));
        await tester.pumpAndSettle();
        expect(find.text('Five').hitTestable(), findsOneWidget);
        expect(find.text('One'), findsOneWidget,
            reason: 'what shows in the bar is not in the menu again');
        await tester.tap(find.text('Five').hitTestable());
        await tester.pumpAndSettle();
        expect(told, ['five']);
      });

      testWidgets('the … is lit when the selected item hides in it', (
        tester,
      ) async {
        await tester.pumpWidget(bar(220, selected: 'five'));
        await tester.pump();
        Color colorOf(String text) =>
            tester.widget<Text>(find.text(text)).style!.color!;
        expect(colorOf('…'), isNot(colorOf('One')));
      });

      testWidgets('a bar that fits shows every item and no …', (
        tester,
      ) async {
        await tester.pumpWidget(bar(220));
        await tester.pump();
        await tester.pumpWidget(bar(800));
        await tester.pump();
        expect(find.text('…').hitTestable(), findsNothing);
        expect(find.text('Five').hitTestable(), findsOneWidget);
        expect(find.text('More'), findsNothing, reason: 'no headings in a bar');
      });

      testWidgets('a reader hears "Show more" and not what hides', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(bar(220));
        await tester.pump();
        expect(find.bySemanticsLabel('Show more'), findsOneWidget);
        expect(find.bySemanticsLabel('Five'), findsNothing);
        handle.dispose();
      });
    });

    testWidgets('the arrows walk along the row', (tester) async {
      final told = <String>[];
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 600,
            child: Menu<String>(
              mode: MenuMode.horizontal,
              items: const [
                MenuItem(value: 'a', label: 'A'),
                MenuItem(value: 'b', label: 'B'),
              ],
              onSelect: told.add,
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(told, ['b']);
    });
  });
}
