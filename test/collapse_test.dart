import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _wrap(Widget child) => ConfigProvider(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: child),
      ),
    );

const _items = [
  CollapseItem(key: '1', label: Text('Header 1'), content: Text('Body 1')),
  CollapseItem(key: '2', label: Text('Header 2'), content: Text('Body 2')),
];

void main() {
  testWidgets('defaultActiveKeys opens a panel; tapping toggles it',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Collapse(
          items: _items,
          defaultActiveKeys: ['1'],
          destroyInactivePanel: true,
        ),
      ),
    );
    expect(find.text('Body 1'), findsOneWidget);

    await tester.tap(find.text('Header 1'));
    await tester.pumpAndSettle();
    expect(find.text('Body 1'), findsNothing);
  });

  testWidgets('collapsed content stays mounted by default', (tester) async {
    await tester.pumpWidget(
      _wrap(const Collapse(items: _items, defaultActiveKeys: ['1'])),
    );
    // Panel 2 is closed, but its body remains in the tree (hidden).
    expect(find.text('Body 2'), findsOneWidget);
  });

  testWidgets('onChange reports the open keys', (tester) async {
    List<String>? changed;
    await tester.pumpWidget(
      _wrap(
        Collapse(items: _items, onChange: (k) => changed = k),
      ),
    );
    await tester.tap(find.text('Header 2'));
    await tester.pumpAndSettle();
    expect(changed, ['2']);
  });

  testWidgets('accordion keeps at most one panel open', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Collapse(
          items: _items,
          accordion: true,
          defaultActiveKeys: ['1'],
          destroyInactivePanel: true,
        ),
      ),
    );
    await tester.tap(find.text('Header 2'));
    await tester.pumpAndSettle();
    expect(find.text('Body 2'), findsOneWidget);
    expect(find.text('Body 1'), findsNothing);
  });

  testWidgets('a disabled panel does not toggle', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Collapse(
          destroyInactivePanel: true,
          items: [
            CollapseItem(
              key: '1',
              label: Text('Header 1'),
              collapsible: CollapsibleTrigger.disabled,
              content: Text('Body 1'),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Header 1'));
    await tester.pumpAndSettle();
    expect(find.text('Body 1'), findsNothing);
  });

  testWidgets('controlled activeKeys ignores taps without onChange',
      (tester) async {
    await tester
        .pumpWidget(_wrap(const Collapse(items: _items, activeKeys: ['1'])));
    expect(find.text('Body 1'), findsOneWidget);
    await tester.tap(find.text('Header 1'));
    await tester.pumpAndSettle();
    expect(find.text('Body 1'), findsOneWidget);
  });
}
