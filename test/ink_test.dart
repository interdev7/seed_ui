import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// The kit's two inks.
const _white = Color(0xFFFFFFFF);
const _black = Color(0xFF141414);

void main() {
  group('the ink a fill asks for', () {
    test('white where the fill is dark, black where it is light', () {
      // A brand the kit has never seen gets legible words without anybody
      // saying so.
      expect(inkOn(const Color(0xFF1677FF)), _white, reason: 'the usual blue');
      expect(inkOn(const Color(0xFFFF4D4F)), _white, reason: 'a red');
      expect(inkOn(const Color(0xFF001529)), _white, reason: 'a navy');
      expect(inkOn(const Color(0xFFFFD500)), _black, reason: 'a yellow');
      expect(inkOn(const Color(0xFFC6FF00)), _black, reason: 'a lime');
      expect(inkOn(const Color(0xFFFFD6E7)), _black, reason: 'a pale pink');
    });

    test('a colour group works its own out, and takes one it is given', () {
      final yellow = ColorGroup.fromPalette(generate(const Color(0xFFFFD500)));
      expect(yellow.onBase, _black);
      expect(yellow.withInk(_white).onBase, _white, reason: 'overruled');
    });

    testWidgets('a yellow brand writes its solid button in black', (
      tester,
    ) async {
      await tester.pumpWidget(
        ConfigProvider(
          theme: ThemeData(
            token: const SeedToken(colorPrimary: Color(0xFFFFD500)),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Button(
                  color: ButtonColor.primary,
                  variant: ButtonVariant.solid,
                  onPressed: () {},
                  child: const Text('Pay'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        DefaultTextStyle.of(tester.element(find.text('Pay'))).style.color,
        _black,
      );
    });

    testWidgets('and a blue one keeps white', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Button(
                  color: ButtonColor.primary,
                  variant: ButtonVariant.solid,
                  onPressed: () {},
                  child: const Text('Pay'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        DefaultTextStyle.of(tester.element(find.text('Pay'))).style.color,
        _white,
      );
    });

    testWidgets('a theme can overrule the arithmetic', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          theme: ThemeData(
            token: const SeedToken(colorPrimary: Color(0xFFFFD500)),
            refineTokens: (t) => t.copyWith(primary: t.primary.withInk(_white)),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Button(
                  color: ButtonColor.primary,
                  variant: ButtonVariant.solid,
                  onPressed: () {},
                  child: const Text('Pay'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        DefaultTextStyle.of(tester.element(find.text('Pay'))).style.color,
        _white,
      );
    });

    testWidgets('a colour named on the spot gets the same treatment', (
      tester,
    ) async {
      // There is no theme slot a `ButtonColor(...)` could look an ink up in,
      // which is why the rule lives on the colour group and not on the token.
      await tester.pumpWidget(
        ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Button(
                  color: const ButtonColor(Color(0xFFFFD500)),
                  variant: ButtonVariant.solid,
                  onPressed: () {},
                  child: const Text('Pay'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        DefaultTextStyle.of(tester.element(find.text('Pay'))).style.color,
        _black,
      );
    });
  });
}
