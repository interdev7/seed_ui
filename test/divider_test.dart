import 'package:flutter/material.dart'
    hide
        ThemeData,
        Checkbox,
        Radio,
        RadioGroup,
        Switch,
        Tooltip,
        Drawer,
        Divider;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(
  Widget child, {
  ComponentDefaults? defaults,
  TextDirection direction = TextDirection.ltr,
}) =>
    ConfigProvider(
      defaults: defaults,
      child: MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 400, child: child),
            ),
          ),
        ),
      ),
    );

/// The runs of line either side of a title, start first.
List<Rect> _runs(WidgetTester tester) => tester
    .widgetList<ColoredBox>(
      find.descendant(
        of: find.byType(Divider),
        matching: find.byType(ColoredBox),
      ),
    )
    .map((b) => tester.getRect(find.byWidget(b)))
    .toList()
  ..sort((a, b) => a.left.compareTo(b.left));

void main() {
  group('horizontal', () {
    testWidgets('fills the width, with room above and below by size', (
      tester,
    ) async {
      for (final (size, margin) in [
        (SoftSize.small, 8.0),
        (SoftSize.middle, 24.0),
        (SoftSize.large, 32.0),
      ]) {
        await tester.pumpWidget(_host(Divider(size: size)));
        expect(
          tester.getSize(find.byType(Divider)),
          Size(400, 1 + margin * 2),
          reason: '$size',
        );
      }
    });

    testWidgets('a subtree can name its size, variant and placement', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Divider(child: Text('T')),
          defaults: const ComponentDefaults(
            divider: DividerDefaults(
              size: SoftSize.small,
              titlePlacement: DividerTitlePlacement.start,
            ),
          ),
        ),
      );
      final runs = _runs(tester);
      expect(runs.first.width, lessThan(runs.last.width / 10));
      expect(tester.getSize(find.byType(Divider)).height,
          tester.getSize(find.text('T')).height + 16);
    });
  });

  group('a title', () {
    testWidgets('in the centre has as much line either side', (tester) async {
      await tester.pumpWidget(_host(const Divider(child: Text('Title'))));
      final runs = _runs(tester);
      expect(runs, hasLength(2));
      expect(runs.first.width, closeTo(runs.last.width, 0.5));
      final title = tester.getRect(find.text('Title'));
      expect(title.left - runs.first.right, 16, reason: 'titleGap');
    });

    testWidgets('at the start has a twentieth of the line before it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Divider(
            titlePlacement: DividerTitlePlacement.start,
            child: Text('Title'),
          ),
        ),
      );
      final runs = _runs(tester);
      final total = runs.first.width + runs.last.width;
      expect(runs.first.width, closeTo(total / 20, 0.5));
    });

    testWidgets('start is the right in a right-to-left language', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Divider(
            titlePlacement: DividerTitlePlacement.start,
            child: Text('Title'),
          ),
          direction: TextDirection.rtl,
        ),
      );
      final runs = _runs(tester);
      expect(runs.last.width, lessThan(runs.first.width / 10));
    });

    testWidgets('titleMargin fixes the run before it', (tester) async {
      await tester.pumpWidget(
        _host(
          const Divider(
            titlePlacement: DividerTitlePlacement.end,
            titleMargin: 40,
            child: Text('Title'),
          ),
        ),
      );
      expect(_runs(tester).last.width, 40);
    });

    testWidgets('plain sets it as body text', (tester) async {
      TextStyle styleOf() => tester
          .widget<RichText>(find.descendant(
            of: find.text('T'),
            matching: find.byType(RichText),
          ))
          .text
          .style!;
      await tester.pumpWidget(_host(const Divider(child: Text('T'))));
      expect(styleOf().fontSize, 16);
      expect(styleOf().fontWeight, FontWeight.w500);
      await tester.pumpWidget(
        _host(const Divider(plain: true, child: Text('T'))),
      );
      expect(styleOf().fontSize, 14);
      expect(styleOf().fontWeight, FontWeight.normal);
    });
  });

  testWidgets('vertical stands as tall as text, with room either side', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Row(
          children: [
            Text('A'),
            Divider(orientation: DividerOrientation.vertical),
            Text('B'),
          ],
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(Divider)),
      const Size(1 + 8 * 2, 14 * 0.9),
    );
  });

  testWidgets('dashed and dotted are drawn in pieces', (tester) async {
    for (final variant in DividerVariant.values) {
      await tester.pumpWidget(_host(Divider(variant: variant)));
      final pieces = find.descendant(
        of: find.byType(Divider),
        matching: find.byType(CustomPaint),
      );
      expect(
        pieces,
        variant == DividerVariant.solid ? findsNothing : findsOneWidget,
        reason: '$variant',
      );
    }
  });

  testWidgets('a reader hears the title and nothing of the line', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const Column(
          children: [Divider(), Divider(child: Text('Details'))],
        ),
      ),
    );
    expect(find.bySemanticsLabel('Details'), findsOneWidget);
    final bare = tester.getSemantics(find.byType(Divider).first);
    expect(bare.label, isEmpty);
    handle.dispose();
  });
}
