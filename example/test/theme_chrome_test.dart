import 'package:flutter/material.dart' hide ThemeData, Tooltip, Drawer, Switch;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
import 'package:seed_ui_example/main.dart';

/// The colour Material paints behind a page transition, and the colour the
/// page itself is painted in. A page transition draws its backdrop with
/// `colorScheme.surface`; if that does not follow the kit, every navigation in
/// a dark theme flashes white before the page arrives.
(Color surface, Color layout) _colours(WidgetTester tester) {
  final context = tester.element(find.byType(MainLayout));
  return (
    Theme.of(context).colorScheme.surface,
    context.softToken.colorBgLayout,
  );
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const DemoApp());
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('Material chrome is painted in the kit\'s colours', (
    tester,
  ) async {
    await _pump(tester);

    final light = _colours(tester);
    expect(light.$1, light.$2, reason: 'light: surface follows the layout');

    // Switch the app to the dark theme through its own control.
    final state = tester.state<State<DemoApp>>(find.byType(DemoApp));
    ThemeController.of(
      tester.element(find.byType(MainLayout)),
    ).setTheme(ThemeModeOption.dark);
    // MaterialApp lerps a theme change, so let the animation finish.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.mounted, isTrue);

    final dark = _colours(tester);
    expect(dark.$1, dark.$2, reason: 'dark: surface follows the layout');
    expect(dark.$1, isNot(light.$1), reason: 'and the two really differ');
  });
}
