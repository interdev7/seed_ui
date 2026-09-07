import 'package:flutter/material.dart'
    hide Badge, ThemeData, Tooltip, Card, Drawer, Switch, Radio, RadioGroup;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
import 'package:seed_ui_example/components/general/compact_demo.dart';

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const ConfigProvider(
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: CompactDemo())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every group fits the room it is given, on a phone as on a '
      'desk', (tester) async {
    // The narrow one first: a run laid out to a fixed width overflowed here,
    // which is what a reader on a phone met.
    for (final size in const [Size(314, 1600), Size(1000, 1600)]) {
      await _pump(tester, size);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });
}
