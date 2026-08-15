import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => ConfigProvider(
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

void main() {
  testWidgets('renders its label', (tester) async {
    await tester.pumpWidget(_host(const Tag(child: Text('Hello'))));
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('closable fires onClose', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      _host(
        Tag(
          closable: true,
          onClose: () => closed = true,
          child: const Text('Close me'),
        ),
      ),
    );
    await tester.tap(find.byType(CustomPaint).last);
    expect(closed, isTrue);
  });

  testWidgets('CheckableTag toggles', (tester) async {
    bool? seen;
    await tester.pumpWidget(
      _host(
        CheckableTag(
          checked: false,
          onChanged: (v) => seen = v,
          child: const Text('Movies'),
        ),
      ),
    );
    await tester.tap(find.text('Movies'));
    expect(seen, isTrue);
  });

  testWidgets('a disabled CheckableTag does not toggle', (tester) async {
    await tester.pumpWidget(
      _host(
        const CheckableTag(checked: false, child: Text('Books')),
      ),
    );
    await tester.tap(find.text('Books'));
    // No onChanged: nothing to assert beyond no crash; the tap is inert.
    expect(find.text('Books'), findsOneWidget);
  });

  testWidgets('CheckableTagGroup multiple adds and removes', (tester) async {
    List<String> value = const ['a'];
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => CheckableTagGroup<String>(
            multiple: true,
            value: value,
            options: const [
              CheckableTagOption(value: 'a', label: Text('A')),
              CheckableTagOption(value: 'b', label: Text('B')),
            ],
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );

    await tester.tap(find.text('B'));
    await tester.pump();
    expect(value, ['a', 'b']);

    await tester.tap(find.text('A'));
    await tester.pump();
    expect(value, ['b']);
  });

  testWidgets('CheckableTagGroup single replaces the selection',
      (tester) async {
    List<String> value = const ['a'];
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => CheckableTagGroup<String>(
            value: value,
            options: const [
              CheckableTagOption(value: 'a', label: Text('A')),
              CheckableTagOption(value: 'b', label: Text('B')),
            ],
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );

    await tester.tap(find.text('B'));
    await tester.pump();
    expect(value, ['b']);
  });
}
