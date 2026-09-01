import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Table, TableRow, ThemeData;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
import 'package:seed_ui_example/components/data_display/table_two_d_demo.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

Future<void> _pump(WidgetTester tester) => tester.pumpWidget(
  const ConfigProvider(
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(size: Size(900, 700)),
        child: SingleChildScrollView(child: TableTwoDDemo()),
      ),
    ),
  ),
);

void main() {
  testWidgets('the page builds only the cells on screen', (tester) async {
    await _pump(tester);

    // 500 rows of 15 columns is 7500 cells. Anything near that would mean the
    // viewport is not doing its job.
    expect(find.byType(RichText).evaluate().length, lessThan(300));
    expect(find.text('Row 1'), findsOneWidget);
    expect(find.text('Row 400'), findsNothing);

    // All 500 are there to be reached, though — the count above is what is
    // built, not what exists.
    for (var i = 0; i < 30; i++) {
      await tester.drag(
        find.byType(TableView),
        const Offset(0, -800),
        kind: PointerDeviceKind.trackpad,
      );
      await tester.pump();
    }
    expect(find.text('Row 500'), findsOneWidget);
    expect(find.byType(RichText).evaluate().length, lessThan(300));
  });

  testWidgets('the heading and the name column stay put', (tester) async {
    await _pump(tester);
    final at = find.byType(TableView);

    await tester.drag(
      at,
      const Offset(-400, -400),
      kind: PointerDeviceKind.trackpad,
    );
    await tester.pump();

    // The far rows arrived, so the drag landed on both axes.
    expect(find.text('Row 1'), findsNothing);
    // And the pinned pair rode along with it.
    expect(find.text('Name'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^Row \d+$')), findsWidgets);
  });
}
