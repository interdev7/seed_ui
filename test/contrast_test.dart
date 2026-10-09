import 'dart:math' as math;

import 'package:flutter/material.dart'
    hide Badge, ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// Words drawn on a fill are held to the contrast a screen asks of them.
///
/// Four components put white text on a fill and stopped there: an avatar's
/// initials on its grey, a badge's count and a ribbon's words on whatever
/// colour they were given, a progress bar's figure on its own fill. White on
/// the avatar's default grey was 1.6:1; on a yellow somebody named, under 1.4.
/// WCAG asks 4.5:1 of text this size.

const _pale = Color(0xFFFFE58F);
const _brightYellow = Color(0xFFFADB14);

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// The colour the text [text] is actually drawn in.
Color _inkOf(WidgetTester tester, String text) {
  final rich = tester.widget<RichText>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );
  return rich.text.style!.color!;
}

Widget _host(Widget child, {bool dark = false}) => ConfigProvider(
      theme: ThemeData(dark: dark),
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

void main() {
  for (final dark in [false, true]) {
    final scheme = dark ? 'dark' : 'light';

    testWidgets("an avatar's initials read on its own grey ($scheme)", (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Avatar(child: Text('AB')), dark: dark),
      );
      final t = tester.element(find.byType(Avatar)).softToken;
      final fill = Color.alphaBlend(t.colorFill, t.colorBgContainer);

      expect(_contrast(_inkOf(tester, 'AB'), fill), greaterThan(4.5));
    });
  }

  testWidgets("an avatar's initials read on a pale fill it was given", (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const Avatar(backgroundColor: _pale, child: Text('AB'))),
    );
    expect(_contrast(_inkOf(tester, 'AB'), _pale), greaterThan(4.5));
  });

  testWidgets('an initials colour named outright still wins', (tester) async {
    await tester.pumpWidget(
      _host(
        const Avatar(
          backgroundColor: _pale,
          foregroundColor: Color(0xFF0000FF),
          child: Text('AB'),
        ),
      ),
    );
    expect(_inkOf(tester, 'AB'), const Color(0xFF0000FF));
  });

  testWidgets("a badge's count reads on a yellow it was given", (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Badge(
          count: 5,
          color: _brightYellow,
          child: SizedBox(width: 40, height: 40),
        ),
      ),
    );
    expect(_contrast(_inkOf(tester, '5'), _brightYellow), greaterThan(4.5));
  });

  testWidgets('a badge left alone keeps its white count', (tester) async {
    await tester.pumpWidget(
      _host(const Badge(count: 5, child: SizedBox(width: 40, height: 40))),
    );
    expect(_inkOf(tester, '5'), const Color(0xFFFFFFFF));
  });

  testWidgets("a ribbon's words read on a yellow it was given", (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Ribbon(
          text: Text('New'),
          color: _brightYellow,
          child: SizedBox(width: 120, height: 60),
        ),
      ),
    );
    expect(_contrast(_inkOf(tester, 'New'), _brightYellow), greaterThan(4.5));
  });

  testWidgets('a figure inside a pale bar reads on it', (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 300,
          child: Progress(
            percent: 0.6,
            color: _pale,
            strokeWidth: 20,
            percentPosition: PercentPosition(type: PercentInfoType.inner),
          ),
        ),
      ),
    );
    expect(_contrast(_inkOf(tester, '60%'), _pale), greaterThan(4.5));
  });

  testWidgets("a figure inside the kit's own bar stays white", (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 300,
          child: Progress(
            percent: 0.6,
            strokeWidth: 20,
            percentPosition: PercentPosition(type: PercentInfoType.inner),
          ),
        ),
      ),
    );
    expect(_inkOf(tester, '60%'), const Color(0xFFFFFFFF));
  });
}
