import 'package:flutter/material.dart'
    hide ThemeData, Tooltip, Card, Drawer, Switch;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

import 'package:seed_ui_example/components/data_display/tour_demo.dart';

Future<void> _pumpDemo(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ConfigProvider(
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: TourDemo())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every tour on the page opens and can be walked', (tester) async {
    await _pumpDemo(tester);

    // The plain tour: its first step will not let go until Upload is pressed.
    await tester.tap(find.text('Begin tour'));
    await tester.pumpAndSettle();
    expect(find.text('Upload a file'), findsOneWidget);
    expect(find.text('Press Upload to carry on'), findsOneWidget);

    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsWidgets);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All done'));
    await tester.pumpAndSettle();
    expect(find.text('Other actions'), findsNothing);
  });

  testWidgets('the corner tour crosses the page without complaint', (
    tester,
  ) async {
    await _pumpDemo(tester);

    await tester.tap(find.text('Tour the corners'));
    await tester.pumpAndSettle();
    expect(find.text('A tour of the page'), findsOneWidget);

    for (final title in [
      'Top left',
      'Top right',
      'The middle',
      'Bottom left',
      'Bottom right',
      'Inside a scroller',
    ]) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget, reason: 'stopped at $title');
      expect(tester.takeException(), isNull, reason: 'at $title');
    }

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
  });

  testWidgets('every placement lands somewhere sensible', (tester) async {
    await _pumpDemo(tester);

    for (final placement in TourPlacement.values) {
      await tester.tap(find.text(placement.name));
      await tester.pumpAndSettle();

      final panel = tester.getRect(
        find
            .ancestor(
              of: find.text('placement: ${placement.name}'),
              matching: find.byType(Container),
            )
            .last,
      );
      final screen = tester.getRect(find.byType(MaterialApp));

      expect(
        panel.left,
        greaterThanOrEqualTo(screen.left - 0.5),
        reason: placement.name,
      );
      expect(
        panel.right,
        lessThanOrEqualTo(screen.right + 0.5),
        reason: placement.name,
      );
      expect(tester.takeException(), isNull, reason: placement.name);

      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('the rich tour draws its cover, indicators and extra action', (
    tester,
  ) async {
    await _pumpDemo(tester);

    await tester.tap(find.text('Begin the rich tour'));
    await tester.pumpAndSettle();

    expect(find.text('A step with a cover'), findsOneWidget);
    expect(find.byIcon(Icons.image), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.byIcon(Icons.close_fullscreen), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
  });

  testWidgets('the knobs reach the tours', (tester) async {
    await _pumpDemo(tester);

    // Motion off, mask off, no arrow: a tour that is a plain popover.
    await tester.tap(find.text('no motion'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first); // mask
    await tester.pumpAndSettle();

    await tester.tap(find.text('Begin tour'));
    await tester.pumpAndSettle();

    final masks = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .where((p) => p.runtimeType.toString() == '_MaskPainter');
    expect(masks, isEmpty, reason: 'the mask switch was turned off');
    expect(find.text('Upload a file'), findsOneWidget);
  });
}
