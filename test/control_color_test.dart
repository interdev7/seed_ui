import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => ConfigProvider(
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

/// The fill of the button showing [label].
Color _fill(WidgetTester tester, String label) {
  final decoration = tester
      .widgetList<DecoratedBox>(
        find.ancestor(
            of: find.text(label), matching: find.byType(DecoratedBox)),
      )
      .first
      .decoration as BoxDecoration;
  return decoration.color!;
}

void main() {
  group('parseHexColor', () {
    test('reads the four lengths CSS writes', () {
      expect(parseHexColor('#fff'), const Color(0xFFFFFFFF));
      expect(parseHexColor('fff'), const Color(0xFFFFFFFF));
      expect(parseHexColor('#1677ff'), const Color(0xFF1677FF));
      expect(parseHexColor('1677FF'), const Color(0xFF1677FF));
    });

    test('a short form doubles each digit', () {
      expect(parseHexColor('#1a2'), const Color(0xFF11AA22));
    });

    test('alpha goes last, the way CSS writes it', () {
      // #ff000080 is red at half alpha — not 0xFF0000 at full alpha with a
      // leading 0x80, which is what reading it as ARGB would give.
      expect(parseHexColor('#ff000080'), const Color(0x80FF0000));
      expect(parseHexColor('#f008'), const Color(0x88FF0000));
    });

    test('no alpha means opaque', () {
      expect(parseHexColor('#000').a, 1.0);
    });

    test('rejects what it cannot read, rather than coming out black', () {
      for (final bad in ['nope', '#12345', '', '#', '#ff00gg', '#ff 00 00']) {
        expect(
          () => parseHexColor(bad),
          throwsFormatException,
          reason: 'accepted "$bad"',
        );
      }
    });

    test('says what it got and what it wanted', () {
      // int.parse would throw anyway, with 'Invalid radix-16 number' and no
      // hint of what a colour should look like. The message is the point.
      String messageFor(String bad) {
        try {
          parseHexColor(bad);
        } on FormatException catch (e) {
          return e.message;
        }
        return '(no throw)';
      }

      expect(messageFor('#ff00gg'), contains('#ff00gg'));
      expect(messageFor('#ff00gg'), contains('#rrggbb'));
      expect(messageFor('#12345'), contains('5'));
      expect(messageFor('#12345'), contains('3, 4, 6 or 8'));
    });
  });

  group('ButtonColor', () {
    testWidgets('a colour of your own reaches the button', (tester) async {
      const mine = Color(0xFF7B2FF7);
      await tester.pumpWidget(
        _host(
          Button(
            variant: ButtonVariant.solid,
            color: const ButtonColor(mine),
            onPressed: () {},
            child: const Text('Buy'),
          ),
        ),
      );
      expect(_fill(tester, 'Buy'), mine);
    });

    testWidgets('the string form means the same thing', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              Button(
                variant: ButtonVariant.solid,
                color: const ButtonColor(Color(0xFFFFFFFF)),
                onPressed: () {},
                child: const Text('A'),
              ),
              Button(
                variant: ButtonVariant.solid,
                color: ButtonColor.fromString('#fff'),
                onPressed: () {},
                child: const Text('B'),
              ),
            ],
          ),
        ),
      );
      expect(_fill(tester, 'B'), _fill(tester, 'A'));
    });

    testWidgets('a preset still follows the theme', (tester) async {
      const pink = Color(0xFFEB2F96);
      await tester.pumpWidget(
        ConfigProvider(
          theme: ThemeData(token: const SeedToken(colorPrimary: pink)),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Button(
                  variant: ButtonVariant.solid,
                  color: ButtonColor.primary,
                  onPressed: () {},
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(_fill(tester, 'Go'), pink);
    });

    testWidgets('a colour of your own is not the theme colour', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              Button(
                variant: ButtonVariant.solid,
                color: const ButtonColor(Color(0xFF7B2FF7)),
                onPressed: () {},
                child: const Text('Mine'),
              ),
              Button(
                variant: ButtonVariant.solid,
                color: ButtonColor.primary,
                onPressed: () {},
                child: const Text('Theme'),
              ),
            ],
          ),
        ),
      );
      expect(_fill(tester, 'Mine'), isNot(_fill(tester, 'Theme')));
    });

    test('two of the same colour are the same value', () {
      expect(
        const ButtonColor(Color(0xFF112233)),
        const ButtonColor(Color(0xFF112233)),
      );
      expect(
        const ButtonColor(Color(0xFF112233)),
        isNot(const ButtonColor(Color(0xFF332211))),
      );
    });

    test('the presets are the enum, so they can still be switched over', () {
      const ButtonColor colour = ButtonColor.danger;
      final named = switch (colour) {
        ButtonCustomColor() => 'custom',
        ButtonPreset.danger => 'danger',
        ButtonPreset() => 'other',
      };
      expect(named, 'danger');
    });
  });
  group('TagColor', () {
    Color tagFill(WidgetTester tester) => (tester
            .widgetList<DecoratedBox>(
              find.ancestor(
                of: find.text('Mine'),
                matching: find.byType(DecoratedBox),
              ),
            )
            .first
            .decoration as BoxDecoration)
        .color!;

    testWidgets('one slot now takes both a preset and a colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Tag(
            variant: TagVariant.solid,
            color: TagColor(Color(0xFF00A870)),
            child: Text('Mine'),
          ),
        ),
      );
      final custom = tagFill(tester);

      await tester.pumpWidget(
        _host(
          const Tag(
            variant: TagVariant.solid,
            color: TagColor.success,
            child: Text('Mine'),
          ),
        ),
      );
      expect(custom, isNot(tagFill(tester)));
    });

    testWidgets('the string form means the same thing', (tester) async {
      await tester.pumpWidget(
        _host(
          const Tag(
            variant: TagVariant.solid,
            color: TagColor(Color(0xFF00A870)),
            child: Text('Mine'),
          ),
        ),
      );
      final byValue = tagFill(tester);

      await tester.pumpWidget(
        _host(
          Tag(
            variant: TagVariant.solid,
            color: TagColor.fromString('#00a870'),
            child: const Text('Mine'),
          ),
        ),
      );
      expect(tagFill(tester), byValue);
    });
  });
}
