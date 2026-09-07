import 'package:flutter/material.dart' hide ThemeData, Radio, RadioGroup;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    ConfigProvider(
      theme: ThemeData(),
      child: Directionality(
        textDirection: direction,
        child: MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Scaffold(body: Align(child: child)),
          ),
        ),
      ),
    );

/// The corners a control draws, resolved for [direction] — the radius itself
/// is named by start and end, and takes its sides from the reading direction
/// when it is painted.
BorderRadius _radiusOf(
  WidgetTester tester,
  String label, {
  TextDirection direction = TextDirection.ltr,
}) {
  final box = tester.widget<Container>(
    find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
  );
  final decoration = box.decoration as BoxDecoration?;
  return decoration!.borderRadius!.resolve(direction);
}

/// The border radius the outermost decorated box of a control draws.
BorderRadius _boxRadius(WidgetTester tester, String label) {
  final decorated = tester.widgetList<DecoratedBox>(
    find.ancestor(of: find.text(label), matching: find.byType(DecoratedBox)),
  );
  for (final box in decorated) {
    final decoration = box.decoration;
    if (decoration is BoxDecoration && decoration.borderRadius != null) {
      return decoration.borderRadius!.resolve(TextDirection.ltr);
    }
  }
  fail('no decorated box with a radius around "$label"');
}

void main() {
  group('CompactSlot.radiusOf', () {
    testWidgets('hands back every corner where there is no group',
        (tester) async {
      late BorderRadius radius;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              radius =
                  CompactSlot.radiusOf(context, 8).resolve(TextDirection.ltr);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(radius, BorderRadius.circular(8));
    });

    testWidgets('squares the joined side of each place in a row',
        (tester) async {
      final seen = <CompactPosition, BorderRadius>{};
      Widget probe(CompactPosition position) => CompactSlot(
            position: position,
            direction: Axis.horizontal,
            child: Builder(
              builder: (context) {
                seen[position] =
                    CompactSlot.radiusOf(context, 8).resolve(TextDirection.ltr);
                return const SizedBox();
              },
            ),
          );
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              for (final position in CompactPosition.values) probe(position),
            ],
          ),
        ),
      );
      const round = Radius.circular(8);
      expect(
        seen[CompactPosition.first],
        const BorderRadius.only(topLeft: round, bottomLeft: round),
      );
      expect(
        seen[CompactPosition.last],
        const BorderRadius.only(topRight: round, bottomRight: round),
      );
      expect(seen[CompactPosition.middle], BorderRadius.zero);
      expect(seen[CompactPosition.only], BorderRadius.circular(8));
    });

    testWidgets(
        'keeps the outer corners outer when the words run the other '
        'way', (tester) async {
      late BorderRadius first;
      await tester.pumpWidget(
        _host(
          CompactSlot(
            position: CompactPosition.first,
            direction: Axis.horizontal,
            child: Builder(
              builder: (context) {
                first =
                    CompactSlot.radiusOf(context, 8).resolve(TextDirection.rtl);
                return const SizedBox();
              },
            ),
          ),
          direction: TextDirection.rtl,
        ),
      );
      // The first control of a right-to-left run stands at the right.
      const round = Radius.circular(8);
      expect(
        first,
        const BorderRadius.only(topRight: round, bottomRight: round),
      );
    });

    testWidgets('down a column the ends are top and bottom', (tester) async {
      final seen = <CompactPosition, BorderRadius>{};
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              for (final position in [
                CompactPosition.first,
                CompactPosition.middle,
                CompactPosition.last,
              ])
                CompactSlot(
                  position: position,
                  direction: Axis.vertical,
                  child: Builder(
                    builder: (context) {
                      seen[position] = CompactSlot.radiusOf(context, 8)
                          .resolve(TextDirection.ltr);
                      return const SizedBox();
                    },
                  ),
                ),
            ],
          ),
        ),
      );
      const round = Radius.circular(8);
      expect(
        seen[CompactPosition.first],
        const BorderRadius.only(topLeft: round, topRight: round),
      );
      expect(
        seen[CompactPosition.last],
        const BorderRadius.only(bottomLeft: round, bottomRight: round),
      );
      expect(seen[CompactPosition.middle], BorderRadius.zero);
    });
  });

  group('Compact', () {
    testWidgets('gives a lone child every corner', (tester) async {
      await tester.pumpWidget(
        _host(
          const Compact(
            children: [Button(child: Text('Only'))],
          ),
        ),
      );
      final radius = _radiusOf(tester, 'Only');
      expect(radius.topLeft, isNot(Radius.zero));
      expect(radius.topRight, isNot(Radius.zero));
    });

    testWidgets('squares the corners where two buttons meet', (tester) async {
      await tester.pumpWidget(
        _host(
          const Compact(
            children: [
              Button(child: Text('Left')),
              Button(child: Text('Mid')),
              Button(child: Text('Right')),
            ],
          ),
        ),
      );
      final left = _radiusOf(tester, 'Left');
      final mid = _radiusOf(tester, 'Mid');
      final right = _radiusOf(tester, 'Right');
      expect(left.topLeft, isNot(Radius.zero));
      expect(left.topRight, Radius.zero);
      expect(mid, BorderRadius.zero);
      expect(right.topLeft, Radius.zero);
      expect(right.topRight, isNot(Radius.zero));
    });

    testWidgets(
        'the run is narrower than the controls laid side by side, by '
        'one line per seam', (tester) async {
      const label = Text('Same');
      await tester.pumpWidget(
        _host(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [Button(child: label), Button(child: label)],
          ),
        ),
      );
      final apart = tester.getSize(find.byType(Row).first).width;
      await tester.pumpWidget(
        _host(
          const Compact(
            children: [Button(child: label), Button(child: label)],
          ),
        ),
      );
      final joined = tester.getSize(find.byType(Compact)).width;
      final line = ThemeData().token.lineWidth;
      expect(joined, moreOrLessEquals(apart - line, epsilon: 0.01));
    });

    testWidgets('the second control starts where the first ends',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const Compact(
            children: [
              Button(child: Text('One')),
              Button(child: Text('Two')),
            ],
          ),
        ),
      );
      final buttons = find.byType(Button);
      final firstEnd = tester.getTopRight(buttons.at(0)).dx;
      final secondStart = tester.getTopLeft(buttons.at(1)).dx;
      final line = ThemeData().token.lineWidth;
      // They overlap by exactly the width of the line they share.
      expect(firstEnd - secondStart, moreOrLessEquals(line, epsilon: 0.01));
    });

    testWidgets('the run ends where the last control ends', (tester) async {
      await tester.pumpWidget(
        _host(
          const Compact(
            children: [
              Button(child: Text('One')),
              Button(child: Text('Two')),
            ],
          ),
        ),
      );
      expect(
        tester.getTopRight(find.byType(Button).at(1)).dx,
        moreOrLessEquals(tester.getTopRight(find.byType(Compact)).dx,
            epsilon: 0.01),
      );
    });

    testWidgets('block shares the whole width it is given', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 400,
            child: Compact(
              block: true,
              children: [
                Button(child: Text('One')),
                Button(child: Text('A much longer label')),
              ],
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(Compact)).width, 400);
      final one = tester.getSize(find.byType(Button).at(0)).width;
      final two = tester.getSize(find.byType(Button).at(1)).width;
      expect(one, moreOrLessEquals(two, epsilon: 1));
    });

    testWidgets('a column joins top to bottom, whichever way the words run',
        (tester) async {
      // A column's ends are the top and the bottom either way round: nothing
      // about it is mirrored, and its seam is closed upwards all the same.
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          _host(
            const SizedBox(
              width: 200,
              child: Compact(
                direction: Axis.vertical,
                children: [
                  Button(child: Text('Up')),
                  Button(child: Text('Down')),
                ],
              ),
            ),
            direction: direction,
          ),
        );
        final up = _radiusOf(tester, 'Up', direction: direction);
        expect(up.topLeft, isNot(Radius.zero), reason: '$direction');
        expect(up.bottomLeft, Radius.zero, reason: '$direction');
        final line = ThemeData().token.lineWidth;
        expect(
          tester.getBottomLeft(find.byType(Button).at(0)).dy -
              tester.getTopLeft(find.byType(Button).at(1)).dy,
          moreOrLessEquals(line, epsilon: 0.01),
          reason: '$direction',
        );
      }
    });

    testWidgets('joins an input to a button', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            child: Compact(
              children: [
                Expanded(child: Input(placeholder: 'Search')),
                Button(child: Text('Go')),
              ],
            ),
          ),
        ),
      );
      final go = _radiusOf(tester, 'Go');
      expect(go.topLeft, Radius.zero);
      expect(go.topRight, isNot(Radius.zero));
      final field = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.byType(EditableText),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final radius = (field.decoration! as BoxDecoration)
          .borderRadius!
          .resolve(TextDirection.ltr);
      expect(radius.topLeft, isNot(Radius.zero));
      expect(radius.topRight, Radius.zero);
    });

    testWidgets('joins a select and the pickers', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 600,
            child: Compact(
              children: [
                Expanded(
                  child: Select<String>(
                    placeholder: 'Where',
                    options: [SelectOption(value: 'a', label: Text('A'))],
                  ),
                ),
                Expanded(child: DatePicker(placeholder: 'When')),
                Expanded(child: TimePicker(placeholder: 'What time')),
              ],
            ),
          ),
        ),
      );
      expect(_boxRadius(tester, 'Where').topRight, Radius.zero);
      expect(_boxRadius(tester, 'Where').topLeft, isNot(Radius.zero));
      expect(_boxRadius(tester, 'When'), BorderRadius.zero);
      expect(_boxRadius(tester, 'What time').topLeft, Radius.zero);
      expect(_boxRadius(tester, 'What time').topRight, isNot(Radius.zero));
    });

    testWidgets('a child that came with a flex keeps it', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            child: Compact(
              children: [
                Expanded(flex: 2, child: Button(child: Text('Wide'))),
                Expanded(child: Button(child: Text('Narrow'))),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final wide = tester.getSize(find.byType(Button).at(0)).width;
      final narrow = tester.getSize(find.byType(Button).at(1)).width;
      final line = ThemeData().token.lineWidth;
      // The second is a line wider than its share, being laid over the first.
      expect(wide, moreOrLessEquals((narrow - line) * 2, epsilon: 0.5));
    });

    testWidgets('stands in a place that names no height', (tester) async {
      await tester.pumpWidget(
        _host(
          const Wrap(
            children: [
              Compact(
                children: [
                  Button(child: Text('One')),
                  Button(child: Text('Two')),
                ],
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      // The two still stand at the same height, being of a size.
      expect(
        tester.getTopLeft(find.byType(Button).at(0)).dy,
        tester.getTopLeft(find.byType(Button).at(1)).dy,
      );
    });

    testWidgets('joins a run of radio buttons to what follows it',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 420,
            child: Compact(
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
                const Button(child: Text('Apply')),
              ],
            ),
          ),
        ),
      );
      // The group's own first button keeps the round corners; its last one,
      // which now meets the button, gives them up.
      expect(_radiusOf(tester, 'A').topLeft, isNot(Radius.zero));
      expect(_radiusOf(tester, 'B'), BorderRadius.zero);
      expect(_radiusOf(tester, 'Apply').topRight, isNot(Radius.zero));
      expect(_radiusOf(tester, 'Apply').topLeft, Radius.zero);
    });

    testWidgets('a run of radio buttons standing alone keeps both its ends',
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
      expect(_radiusOf(tester, 'A').topLeft, isNot(Radius.zero));
      expect(_radiusOf(tester, 'A').topRight, Radius.zero);
      expect(_radiusOf(tester, 'B').topRight, isNot(Radius.zero));
    });

    testWidgets('a control nested deeper in the run still finds its slot',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const Compact(
            children: [
              Button(child: Text('Publish')),
              Dropdown<String>(
                trigger: [DropdownTrigger.click],
                menu: [DropdownItem(value: 'a', label: Text('Schedule'))],
                child: Button(child: Text('More')),
              ),
            ],
          ),
        ),
      );
      // The button is inside the dropdown, not directly inside the group.
      expect(_radiusOf(tester, 'More').topLeft, Radius.zero);
      expect(_radiusOf(tester, 'More').topRight, isNot(Radius.zero));
    });

    testWidgets('a control told it now has a neighbour redraws its corners',
        (tester) async {
      // The same const widgets in both runs, so nothing but the slot has
      // changed: what redraws the corners is the control's dependency on it,
      // not a parent rebuilding the button.
      const one = Button(child: Text('One'));
      const two = Button(child: Text('Two'));
      const three = Button(child: Text('Three'));

      Future<void> pumpRun(List<Widget> children) =>
          tester.pumpWidget(_host(Compact(children: children)));

      await pumpRun(const [one, two]);
      // The corners are animated, so let the change finish arriving.
      await tester.pumpAndSettle();
      expect(_radiusOf(tester, 'Two').topRight, isNot(Radius.zero));

      // 'Two' now stands in the middle, and must give up the corners it had.
      await pumpRun(const [one, two, three]);
      await tester.pumpAndSettle();
      expect(_radiusOf(tester, 'Two'), BorderRadius.zero);
      expect(_radiusOf(tester, 'Three').topRight, isNot(Radius.zero));
    });

    testWidgets('the seam is closed the way the run reads', (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          _host(
            const Compact(
              children: [
                Button(child: Text('One')),
                Button(child: Text('Two')),
              ],
            ),
            direction: direction,
          ),
        );
        final buttons = find.byType(Button);
        final first = tester.getRect(buttons.at(0));
        final second = tester.getRect(buttons.at(1));
        final line = ThemeData().token.lineWidth;

        // Whichever way round they stand, the two overlap by exactly the line
        // they share — pulled the wrong way they would part instead, and draw
        // two lines with a gap between them.
        final overlap = direction == TextDirection.ltr
            ? first.right - second.left
            : second.right - first.left;
        expect(
          overlap,
          moreOrLessEquals(line, epsilon: 0.01),
          reason: '$direction',
        );

        // And the run is no wider than the two of them less that line.
        expect(
          tester.getSize(find.byType(Compact)).width,
          moreOrLessEquals(first.width + second.width - line, epsilon: 0.01),
          reason: '$direction',
        );
      }
    });

    testWidgets('a run of radio buttons closes its seam either way round',
        (tester) async {
      for (final direction in TextDirection.values) {
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
            direction: direction,
          ),
        );
        final boxes = find.byType(AnimatedContainer);
        final first = tester.getRect(boxes.at(0));
        final second = tester.getRect(boxes.at(1));
        final line = ThemeData().token.lineWidth;
        final overlap = direction == TextDirection.ltr
            ? first.right - second.left
            : second.right - first.left;
        expect(
          overlap,
          moreOrLessEquals(line, epsilon: 0.01),
          reason: '$direction',
        );
      }
    });

    testWidgets('a control still works where it stands', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Compact(
            children: [
              const Button(child: Text('One')),
              Button(onPressed: () => taps++, child: const Text('Two')),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Two'));
      expect(taps, 1);
    });

    testWidgets('an empty group takes no room', (tester) async {
      await tester.pumpWidget(_host(const Compact(children: [])));
      expect(tester.getSize(find.byType(Compact)), Size.zero);
    });

    testWidgets('a widget that knows nothing of the group still stands in it',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const Compact(
            children: [
              Button(child: Text('One')),
              Text('Plain'),
            ],
          ),
        ),
      );
      expect(find.text('Plain'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
