import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      navigatorKey: UiKit.navigatorKey,
      home: Scaffold(body: Center(child: child)),
    );

const _menu = [
  DropdownItem(key: 'edit', label: Text('Edit')),
  DropdownDivider(),
  DropdownItem(key: 'delete', label: Text('Delete'), danger: true),
  DropdownItem(key: 'off', label: Text('Off'), disabled: true),
];

void main() {
  testWidgets('click trigger opens the menu and reports the tapped key',
      (tester) async {
    Object? tapped;
    await tester.pumpWidget(
      _host(
        Dropdown(
          trigger: const [DropdownTrigger.click],
          menu: _menu,
          onItemTap: (k) => tapped = k,
          child: const Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(tapped, 'delete');
    // Closed after selecting.
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('a disabled item does not fire or close', (tester) async {
    Object? tapped;
    await tester.pumpWidget(
      _host(
        Dropdown(
          trigger: const [DropdownTrigger.click],
          menu: _menu,
          onItemTap: (k) => tapped = k,
          child: const Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    expect(tapped, isNull);
    expect(find.text('Edit'), findsOneWidget); // still open
  });

  testWidgets('an outside tap closes a click menu', (tester) async {
    await tester.pumpWidget(
      _host(
        const Dropdown(
          trigger: [DropdownTrigger.click],
          menu: _menu,
          child: Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('popupRender wraps the default menu', (tester) async {
    await tester.pumpWidget(
      _host(
        Dropdown(
          trigger: const [DropdownTrigger.click],
          menu: _menu,
          popupRender: (context, menu) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [menu, const Text('Footer')],
          ),
          child: const Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    // Both the default menu and the appended footer render.
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Footer'), findsOneWidget);
  });

  testWidgets('menu updates live while open, without reopening',
      (tester) async {
    Widget build(List<String> items) => _host(
          Dropdown(
            trigger: const [],
            open: true,
            menu: [
              for (final i in items) DropdownItem(key: i, label: Text(i)),
            ],
            child: const Text('Open'),
          ),
        );

    await tester.pumpWidget(build(['One']));
    await tester.pumpAndSettle();
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsNothing);

    // Grow the menu while it stays open; the overlay must reflect it at once.
    await tester.pumpWidget(build(['One', 'Two']));
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsOneWidget);
  });

  testWidgets('custom content renders and can close itself', (tester) async {
    await tester.pumpWidget(
      _host(
        Dropdown(
          trigger: const [DropdownTrigger.click],
          content: (context, close) => DropdownPanel(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: close,
                child: const Text('Custom body'),
              ),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Custom body'), findsOneWidget);

    await tester.tap(find.text('Custom body'));
    await tester.pumpAndSettle();
    expect(find.text('Custom body'), findsNothing);
  });
}
