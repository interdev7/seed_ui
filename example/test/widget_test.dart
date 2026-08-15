import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui_example/main.dart';

void main() {
  testWidgets('the demo app boots and lists its pages', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pump();

    expect(find.text('seed_ui'), findsOneWidget);
    expect(find.text('New Year Theme 🎄'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every theme in the switcher builds', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pump();

    for (final mode in ThemeModeOption.values) {
      ThemeController.of(tester.element(find.text('seed_ui'))).setTheme(mode);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'mode: $mode');
    }
  });
}
