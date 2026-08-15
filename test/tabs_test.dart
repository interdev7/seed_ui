import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

const _items = [
  TabItem(key: 'a', label: Text('Alpha'), content: Text('Panel A')),
  TabItem(key: 'b', label: Text('Beta'), content: Text('Panel B')),
  TabItem(
    key: 'c',
    label: Text('Gamma'),
    disabled: true,
    content: Text('Panel C'),
  ),
];

void main() {
  testWidgets('shows the first panel and switches on tab tap', (tester) async {
    await tester.pumpWidget(_host(const Tabs(items: _items)));
    expect(find.text('Panel A'), findsOneWidget);
    expect(find.text('Panel B'), findsNothing);

    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(find.text('Panel B'), findsOneWidget);
  });

  testWidgets('reports onChange with the new key', (tester) async {
    String? changed;
    await tester.pumpWidget(
      _host(
        Tabs(items: _items, onChange: (k) => changed = k),
      ),
    );
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(changed, 'b');
  });

  testWidgets('a disabled tab does not switch', (tester) async {
    await tester.pumpWidget(_host(const Tabs(items: _items)));
    await tester.tap(find.text('Gamma'));
    await tester.pumpAndSettle();
    expect(find.text('Panel A'), findsOneWidget);
    expect(find.text('Panel C'), findsNothing);
  });

  testWidgets('controlled activeKey is honoured', (tester) async {
    await tester.pumpWidget(
      _host(
        const Tabs(items: _items, activeKey: 'b'),
      ),
    );
    expect(find.text('Panel B'), findsOneWidget);
    // Without onChange the controlled key does not move.
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(find.text('Panel B'), findsOneWidget);
  });

  testWidgets('editable card fires onEdit for add and remove', (tester) async {
    final events = <String>[];
    await tester.pumpWidget(
      _host(
        Tabs(
          type: TabsType.editableCard,
          items: _items,
          onEdit: (key, action) => events.add('${action.name}:$key'),
        ),
      ),
    );

    // Close button on the first tab.
    final cross = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == 'CrossPainter',
    );
    expect(cross, findsWidgets);
    await tester.tap(cross.first);
    await tester.pump();
    expect(events.any((e) => e.startsWith('remove:')), isTrue);

    // Add button.
    final plus = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == '_PlusPainter',
    );
    expect(plus, findsOneWidget);
    await tester.tap(plus);
    await tester.pump();
    expect(events, contains('add:null'));
  });

  testWidgets('controller drives switching and notifies listeners',
      (tester) async {
    final controller = TabsController(items: _items);
    var notifications = 0;
    controller.addListener(() => notifications++);

    await tester.pumpWidget(_host(Tabs(controller: controller)));
    expect(find.text('Panel A'), findsOneWidget);

    controller.select('b');
    await tester.pumpAndSettle();
    expect(find.text('Panel B'), findsOneWidget);
    expect(controller.activeKey, 'b');
    expect(notifications, 1);
  });

  testWidgets('controller.setTitle updates a tab label live', (tester) async {
    final controller = TabsController(items: _items);
    await tester.pumpWidget(_host(Tabs(controller: controller)));
    expect(find.text('Alpha'), findsOneWidget);

    controller.setTitle('a', 'Renamed');
    await tester.pumpAndSettle();
    expect(find.text('Renamed'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
  });

  testWidgets('onCreateTab seeds the new tab; null fields autoincrement',
      (tester) async {
    final controller = TabsController(
      items: const [
        TabItem(key: '1', label: Text('Tab 1'), content: Text('One')),
      ],
    );
    await tester.pumpWidget(
      _host(
        Tabs(
          type: TabsType.editableCard,
          controller: controller,
          onCreateTab: (index) => index == 1
              ? const CreateTabData(
                  label: Text('News'),
                  key: 'news',
                  content: Text('News!'),
                )
              : null,
        ),
      ),
    );

    final plus = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == '_PlusPainter',
    );
    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(controller.items.length, 2);
    expect(controller.activeKey, 'news');
    expect(find.text('News!'), findsOneWidget);

    // A second add with onCreateTab returning null falls back to autoincrement.
    await tester.tap(plus);
    await tester.pump();
    expect(controller.items.length, 3);
    expect(controller.items.last.key, isNot('news'));
  });

  testWidgets('controller.remove closes a tab and moves the active tab',
      (tester) async {
    final controller = TabsController(items: _items, activeKey: 'b');
    await tester.pumpWidget(_host(Tabs(controller: controller)));
    controller.remove('b');
    await tester.pumpAndSettle();
    expect(controller.items.any((e) => e.key == 'b'), isFalse);
    expect(controller.activeKey, isNotNull);
  });
}
