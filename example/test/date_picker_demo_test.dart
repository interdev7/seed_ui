import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
import 'package:seed_ui_example/components/data_entry/date_picker_demo.dart';

Widget _page() => ConfigProvider(
  child: MaterialApp(
    navigatorKey: UiKit.navigatorKey,
    home: const Scaffold(body: SingleChildScrollView(child: DatePickerDemo())),
  ),
);

void main() {
  testWidgets('the DatePicker page builds, and its panel opens', (
    tester,
  ) async {
    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DatePicker), findsWidgets);

    await tester.tap(find.byType(DatePicker).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('the page lays out on a narrow screen too', (tester) async {
    // The pickers size themselves, so a row of them overflows once the page
    // is narrow enough — which is what Wrap is for.
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
