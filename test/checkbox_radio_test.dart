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

  testWidgets('a run of buttons stands exactly as tall as a button beside it',
      (tester) async {
    await tester.pumpWidget(
      _host(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<String>(
              value: 'a',
              optionType: RadioOptionType.button,
              options: const [
                RadioOption(value: 'a', label: Text('A')),
                RadioOption(value: 'b', label: Text('B')),
              ],
              onChanged: (_) {},
            ),
            Button(onPressed: () {}, child: const Text('Apply')),
          ],
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(RadioGroup<String>)).height,
      tester.getSize(find.byType(Button)).height,
    );
    // Not merely the same in the layout: a stroke centred on the edge stands
    // half a line outside the box, and the run came out a pixel taller than
    // the button. Every side is drawn inside, as a button draws its own.
    final decoration = tester
        .widget<AnimatedContainer>(find.byType(AnimatedContainer).first)
        .decoration! as BoxDecoration;
    expect(
      decoration.border!.top.strokeAlign,
      BorderSide.strokeAlignInside,
    );
  });

  testWidgets('two buttons of a run share one divider, not two',
      (tester) async {
    await tester.pumpWidget(
      _host(
        RadioGroup<String>(
          value: 'a',
          optionType: RadioOptionType.button,
          options: const [
            RadioOption(value: 'a', label: Text('A')),
            RadioOption(value: 'b', label: Text('B')),
          ],
          onChanged: (_) {},
        ),
      ),
    );
    final boxes = find.byType(AnimatedContainer);
    final first = tester.getRect(boxes.at(0));
    final second = tester.getRect(boxes.at(1));
    final line = ThemeData().token.lineWidth;
    expect(first.right - second.left, moreOrLessEquals(line, epsilon: 0.01));
    // And the run ends where its last button ends.
    expect(
      tester.getRect(find.byType(RadioGroup<String>)).right,
      moreOrLessEquals(second.right, epsilon: 0.01),
    );
  });

  group('controls that keep their own state', () {
    // Every other data-entry control in the kit offers an uncontrolled form;
    // these four were controlled-only, with no rule saying why.

    testWidgets('a Checkbox starts where defaultChecked says and ticks', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Checkbox(defaultChecked: true, label: Text('Remember'))),
      );
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).checked, isNull);
      expect(_ticked(tester), isTrue, reason: 'it started ticked');

      await tester.tap(find.text('Remember'));
      await tester.pumpAndSettle();
      expect(_ticked(tester), isFalse, reason: 'and unticked itself');
    });

    testWidgets('a Checkbox still reports every tick', (tester) async {
      final seen = <bool>[];
      await tester.pumpWidget(
        _host(Checkbox(label: const Text('x'), onChanged: seen.add)),
      );
      await tester.tap(find.text('x'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('x'));
      await tester.pumpAndSettle();
      expect(seen, [true, false]);
    });

    testWidgets('a controlled Checkbox that refuses is shown refusing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(Checkbox(
            checked: false, label: const Text('x'), onChanged: (_) {})),
      );
      await tester.tap(find.text('x'));
      await tester.pumpAndSettle();
      expect(_ticked(tester), isFalse);
    });

    testWidgets('a CheckboxGroup starts where defaultValue says', (
      tester,
    ) async {
      final seen = <List<String>>[];
      await tester.pumpWidget(
        _host(
          CheckboxGroup<String>(
            defaultValue: const ['a'],
            onChanged: seen.add,
            options: const [
              CheckboxOption(value: 'a', label: Text('Apples')),
              CheckboxOption(value: 'b', label: Text('Bananas')),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Bananas'));
      await tester.pumpAndSettle();
      expect(seen.single, ['a', 'b'], reason: 'it kept what it started with');
    });

    testWidgets('a RadioGroup starts where defaultValue says and moves', (
      tester,
    ) async {
      final seen = <String>[];
      await tester.pumpWidget(
        _host(
          RadioGroup<String>(
            defaultValue: 'monthly',
            onChanged: seen.add,
            options: const [
              RadioOption(value: 'monthly', label: Text('Monthly')),
              RadioOption(value: 'yearly', label: Text('Yearly')),
            ],
          ),
        ),
      );
      // Re-choosing what is already chosen reports nothing, which proves it
      // really did start on `monthly`.
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      expect(seen, isEmpty);

      await tester.tap(find.text('Yearly'));
      await tester.pumpAndSettle();
      expect(seen, ['yearly']);
    });

    testWidgets('a RadioGroup nobody drives still moves with no listener', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const RadioGroup<String>(
            defaultValue: 'monthly',
            options: [
              RadioOption(value: 'monthly', label: Text('Monthly')),
              RadioOption(value: 'yearly', label: Text('Yearly')),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Yearly'));
      await tester.pumpAndSettle();
      final radios =
          tester.widgetList<Radio<String>>(find.byType(Radio<String>));
      expect(
        radios.map((r) => r.groupValue).toSet(),
        {'yearly'},
        reason: 'the group moved itself',
      );
    });
  });

  testWidgets('a radio dot is drawn in the colour the token names', (
    tester,
  ) async {
    // `dotColor`, `buttonBg`, `buttonCheckedBg` and `buttonColor` were all
    // declared, resolved and never read.
    const dot = Color(0xFF123456);
    await tester.pumpWidget(
      _host(
        ConfigProvider(
          theme: ThemeData(
            components: const ComponentsConfig(
              radio: RadioToken(dotColor: dot),
            ),
          ),
          child: Radio<String>(
            value: 'a',
            groupValue: 'a',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final ring = tester
        .widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(Radio<String>),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .map((b) => b.decoration! as BoxDecoration)
        .first;
    expect((ring.border! as Border).top.color, dot);
  });

  testWidgets('a button-style run takes its own fills and ink', (
    tester,
  ) async {
    const resting = Color(0xFF102030);
    const taken = Color(0xFF405060);
    const ink = Color(0xFF708090);
    await tester.pumpWidget(
      _host(
        ConfigProvider(
          theme: ThemeData(
            components: const ComponentsConfig(
              radio: RadioToken(
                buttonBg: resting,
                buttonCheckedBg: taken,
                buttonColor: ink,
              ),
            ),
          ),
          child: RadioGroup<String>(
            value: 'a',
            optionType: RadioOptionType.button,
            buttonStyle: RadioButtonStyle.solid,
            options: const [
              RadioOption(value: 'a', label: Text('Taken')),
              RadioOption(value: 'b', label: Text('Not')),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fills = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((b) => (b.decoration! as BoxDecoration).color)
        .whereType<Color>()
        .toSet();
    expect(fills, contains(taken), reason: 'the one that was taken');
    expect(fills, contains(resting), reason: 'and the one that was not');
    // The run draws a second, invisible layer of the same words to keep the
    // two rows aligned, so the label is in the tree twice.
    expect(
      DefaultTextStyle.of(tester.element(find.text('Not').first)).style.color,
      ink,
    );
  });
}

/// Whether the one box on screen reads as ticked.
///
/// Read from the semantics rather than from the widget: an uncontrolled box
/// keeps its state inside, so `Checkbox.checked` says nothing about it — and
/// this is the same thing a screen reader is told.
bool _ticked(WidgetTester tester) =>
    tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byType(Checkbox),
            matching: find.byType(Semantics),
          ),
        )
        .firstWhere((s) => s.properties.checked != null)
        .properties
        .checked ??
    false;
