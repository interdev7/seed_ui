import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('Checkbox', () {
    testWidgets('toggles and reports the new value', (tester) async {
      bool? seen;
      await tester.pumpWidget(
        _host(
          Checkbox(
            checked: false,
            onChanged: (v) => seen = v,
            label: const Text('Agree'),
          ),
        ),
      );

      await tester.tap(find.text('Agree'));
      expect(seen, isTrue);
    });

    testWidgets('disabled does not toggle', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          Checkbox(
            checked: false,
            disabled: true,
            onChanged: (_) => calls++,
            label: const Text('Agree'),
          ),
        ),
      );

      await tester.tap(find.text('Agree'));
      expect(calls, 0);
    });

    testWidgets('indeterminate still reports the opposite of value',
        (tester) async {
      bool? seen;
      await tester.pumpWidget(
        _host(
          Checkbox(
            checked: false,
            indeterminate: true,
            onChanged: (v) => seen = v,
            label: const Text('All'),
          ),
        ),
      );

      await tester.tap(find.text('All'));
      expect(seen, isTrue);
    });
  });

  group('CheckboxGroup', () {
    testWidgets('adds and removes values from the selection', (tester) async {
      List<String>? seen;
      await tester.pumpWidget(
        _host(
          CheckboxGroup<String>(
            value: const ['a'],
            onChanged: (v) => seen = v,
            options: const [
              CheckboxOption(value: 'a', label: Text('Apple')),
              CheckboxOption(value: 'b', label: Text('Banana')),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Banana'));
      expect(seen, ['a', 'b']);

      await tester.tap(find.text('Apple'));
      expect(seen, isEmpty);
    });
  });

  group('Radio / RadioGroup', () {
    testWidgets('selecting an option reports its value', (tester) async {
      String? seen;
      await tester.pumpWidget(
        _host(
          RadioGroup<String>(
            value: 'a',
            onChanged: (v) => seen = v,
            options: const [
              RadioOption(value: 'a', label: Text('A')),
              RadioOption(value: 'b', label: Text('B')),
            ],
          ),
        ),
      );

      await tester.tap(find.text('B'));
      expect(seen, 'b');
    });

    testWidgets('re-selecting the current value does nothing', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          RadioGroup<String>(
            value: 'a',
            onChanged: (_) => calls++,
            options: const [
              RadioOption(value: 'a', label: Text('A')),
              RadioOption(value: 'b', label: Text('B')),
            ],
          ),
        ),
      );

      await tester.tap(find.text('A'));
      expect(calls, 0);
    });

    testWidgets('a disabled option is not selectable', (tester) async {
      String? seen;
      await tester.pumpWidget(
        _host(
          RadioGroup<String>(
            value: 'a',
            onChanged: (v) => seen = v,
            options: const [
              RadioOption(value: 'a', label: Text('A')),
              RadioOption(value: 'b', label: Text('B'), disabled: true),
            ],
          ),
        ),
      );

      await tester.tap(find.text('B'));
      expect(seen, isNull);
    });

    testWidgets('button optionType selects on tap', (tester) async {
      String? seen;
      await tester.pumpWidget(
        _host(
          RadioGroup<String>(
            value: 'a',
            optionType: RadioOptionType.button,
            buttonStyle: RadioButtonStyle.solid,
            onChanged: (v) => seen = v,
            options: const [
              RadioOption(value: 'a', label: Text('Hangzhou')),
              RadioOption(value: 'b', label: Text('Shanghai')),
            ],
          ),
        ),
      );

      // Button mode stacks a decorative layer, so the label appears twice; the
      // visible, interactive one is first.
      await tester.tap(find.text('Shanghai').first);
      expect(seen, 'b');
    });

    testWidgets('a custom child renders as the label', (tester) async {
      await tester.pumpWidget(
        _host(
          RadioGroup<int>(
            value: 1,
            onChanged: (_) {},
            options: const [
              RadioOption(value: 1, label: Text('CUSTOM')),
              RadioOption(value: 2, label: Text('Two')),
            ],
          ),
        ),
      );
      expect(find.text('CUSTOM'), findsOneWidget);
    });
  });

  group('a label longer than the room it is in', () {
    testWidgets('gives way rather than running off the row', (tester) async {
      // A label takes the width its words want, and in a narrow column that
      // is more than there is.
      for (final child in [
        const Checkbox(
          checked: false,
          label: Text('A label far longer than the box it has been given'),
        ),
        const Radio<bool>(
          value: true,
          groupValue: false,
          child: Text('A label far longer than the box it has been given'),
        ),
      ]) {
        await tester.pumpWidget(
          ConfigProvider(
            child: MaterialApp(
              home: Scaffold(
                body: Center(child: SizedBox(width: 90, child: child)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${child.runtimeType}');
      }
    });
  });
}
