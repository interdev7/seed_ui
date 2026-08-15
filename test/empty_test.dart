import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child, {WidgetBuilder? renderEmpty}) => ConfigProvider(
      renderEmpty: renderEmpty,
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  testWidgets('Empty shows the default description', (tester) async {
    await tester.pumpWidget(_host(const Empty()));
    expect(find.text('No data'), findsOneWidget);
  });

  testWidgets('a Select with no options falls back to Empty', (tester) async {
    await tester.pumpWidget(
      _host(
        const Select<String>(placeholder: 'Pick', options: []),
      ),
    );
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(find.text('No data'), findsOneWidget);
  });

  testWidgets('ConfigProvider.renderEmpty overrides the default',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const Select<String>(placeholder: 'Pick', options: []),
        renderEmpty: (context) => const Text('Nothing custom'),
      ),
    );
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing custom'), findsOneWidget);
    expect(find.text('No data'), findsNothing);
  });

  testWidgets('notFoundContent wins over renderEmpty', (tester) async {
    await tester.pumpWidget(
      _host(
        const Select<String>(
          placeholder: 'Pick',
          options: [],
          notFoundContent: Text('Per-field empty'),
        ),
        renderEmpty: (context) => const Text('Global empty'),
      ),
    );
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(find.text('Per-field empty'), findsOneWidget);
    expect(find.text('Global empty'), findsNothing);
  });
}
