import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// The weight the text [label] is actually drawn with.
FontWeight? _weightOf(WidgetTester tester, String label) {
  final element = tester.element(find.text(label));
  final own = tester.widget<Text>(find.text(label)).style?.fontWeight;
  return own ?? DefaultTextStyle.of(element).style.fontWeight;
}

Widget _host(ThemeData? theme, Widget child) => ConfigProvider(
      theme: theme,
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

void main() {
  group('the theme carries the weights', () {
    test('and has sensible defaults', () {
      final t = ThemeData().token;
      expect(t.fontWeight, FontWeight.w400);
      expect(t.fontWeightStrong, FontWeight.w600);
    });

    testWidgets('ordinary text follows fontWeight', (tester) async {
      await tester.pumpWidget(
        _host(null, Button(onPressed: () {}, child: const Text('Go'))),
      );
      expect(_weightOf(tester, 'Go'), FontWeight.w400);

      await tester.pumpWidget(
        _host(
          ThemeData(token: const SeedToken(fontWeight: FontWeight.w300)),
          Button(onPressed: () {}, child: const Text('Go')),
        ),
      );
      await tester.pumpAndSettle();
      expect(_weightOf(tester, 'Go'), FontWeight.w300);
    });

    testWidgets('titles follow fontWeightStrong', (tester) async {
      await tester.pumpWidget(
        _host(null, const Card(title: Text('Heading'), child: Text('body'))),
      );
      expect(_weightOf(tester, 'Heading'), FontWeight.w600);

      await tester.pumpWidget(
        _host(
          ThemeData(token: const SeedToken(fontWeightStrong: FontWeight.w800)),
          const Card(title: Text('Heading'), child: Text('body')),
        ),
      );
      await tester.pumpAndSettle();
      expect(_weightOf(tester, 'Heading'), FontWeight.w800);
    });

    testWidgets('one weight change reaches more than one component', (
      tester,
    ) async {
      // The point of the whole change: said once, not per widget.
      await tester.pumpWidget(
        _host(
          ThemeData(token: const SeedToken(fontWeightStrong: FontWeight.w900)),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(title: Text('CardTitle'), child: Text('body')),
              Timeline(items: [TimelineItem(title: Text('Node'))]),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_weightOf(tester, 'CardTitle'), FontWeight.w900);
      expect(_weightOf(tester, 'Node'), FontWeight.w900);
    });
  });

  group('a component can differ from the theme', () {
    testWidgets("ButtonToken.fontWeight overrides the theme's", (tester) async {
      await tester.pumpWidget(
        _host(
          ThemeData(
            token: const SeedToken(fontWeight: FontWeight.w300),
            components: const ComponentsConfig(
              button: ButtonToken(fontWeight: FontWeight.w700),
            ),
          ),
          Button(onPressed: () {}, child: const Text('Go')),
        ),
      );
      await tester.pumpAndSettle();
      expect(_weightOf(tester, 'Go'), FontWeight.w700);
    });

    testWidgets('a per-instance token wins over the global one', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ThemeData(
            components: const ComponentsConfig(
              button: ButtonToken(fontWeight: FontWeight.w700),
            ),
          ),
          Button(
            token: const ButtonToken(fontWeight: FontWeight.w200),
            onPressed: () {},
            child: const Text('Go'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_weightOf(tester, 'Go'), FontWeight.w200);
    });
  });
}
