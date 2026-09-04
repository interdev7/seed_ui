import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart' hide Table;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
import 'package:seed_ui_example/components/data_display/table_demo.dart';

void main() {
  testWidgets('every table in the demo builds', (tester) async {
    // The whole page at once: a column that forgets its value throws while
    // being built, and the app shows a box of nothing where the group was —
    // which is easy to miss when only one group of twenty is wrong.
    tester.view.physicalSize = const Size(1900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ConfigProvider(
        child: m.MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: const m.Scaffold(
            body: SingleChildScrollView(child: TableDemo()),
          ),
        ),
      ),
    );
    // Not pumpAndSettle: the page ends on a table that is loading, and a
    // spinner never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('What a column keeps to itself'), findsOneWidget);
  });
}
