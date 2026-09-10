import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
// The panel's grid is the kit's own scaffolding rather than public surface,
// so it is reached through the implementation library.
import 'package:seed_ui/src/components/data_entry/date_picker.dart'
    show DayGrid;
import 'package:seed_ui_example/components/data_entry/date_range_picker_demo.dart';

Widget _host(Widget child, {double width = 900}) => ConfigProvider(
  child: MaterialApp(
    navigatorKey: UiKit.navigatorKey,
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: SingleChildScrollView(child: child),
      ),
    ),
  ),
);

void main() {
  testWidgets('the DateRangePicker page builds, and its panel opens', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const DateRangePickerDemo()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DateRangePicker).first);
    await tester.pumpAndSettle();
    // Two months, which is what a range panel is for.
    expect(find.byType(DayGrid), findsNWidgets(2));
  });

  testWidgets('the page lays out on a narrow screen too', (tester) async {
    await tester.pumpWidget(_host(const DateRangePickerDemo(), width: 380));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
