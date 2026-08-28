import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

void main() {
  group('the Material bridge', () {
    test('paints Material in the kit\'s colours', () {
      for (final dark in const [false, true]) {
        final kit = ThemeData(dark: dark);
        final m = kit.materialTheme;

        expect(
          m.brightness,
          dark ? Brightness.dark : Brightness.light,
        );
        // The one that stops a white flash between pages: a transition paints
        // its backdrop with this.
        expect(m.colorScheme.surface, kit.token.colorBgLayout);
        // Material derives these from the surface, but they are part of the
        // promise all the same.
        expect(m.scaffoldBackgroundColor, kit.token.colorBgLayout);
        expect(m.dividerColor, kit.token.colorSplit);
        expect(m.colorScheme.primary, kit.token.primary.base);
        expect(m.colorScheme.error, kit.token.error.base);
        expect(m.colorScheme.onSurface, kit.token.colorText);
      }
    });

    test('the two themes really differ', () {
      // A bridge that returned the same thing either way would satisfy every
      // check above and still flash.
      expect(
        ThemeData(dark: true).materialTheme.colorScheme.surface,
        isNot(ThemeData(dark: false).materialTheme.colorScheme.surface),
      );
    });

    test('a token reaches the same theme as its ThemeData', () {
      final kit = ThemeData(dark: true);
      expect(
        kit.token.materialTheme.colorScheme.surface,
        kit.materialTheme.colorScheme.surface,
      );
    });

    testWidgets('it needs no Builder to be named beside its provider',
        (tester) async {
      final kit = ThemeData(dark: true);
      await tester.pumpWidget(
        ConfigProvider(
          theme: kit,
          child: material.MaterialApp(
            theme: kit.materialTheme,
            home: const Scaffold(body: SizedBox()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      expect(
        material.Theme.of(context).colorScheme.surface,
        kit.token.colorBgLayout,
      );
    });
  });
}
