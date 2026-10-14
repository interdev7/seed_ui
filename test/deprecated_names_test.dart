// The old names are what this file is about.
// ignore_for_file: deprecated_member_use

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

/// Every name the kit has renamed still works until 1.0.0, so code written
/// against an earlier version keeps building and keeps doing what it did.
Widget _host(Widget child) => ConfigProvider(
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 320, height: 400, child: child),
          ),
        ),
      ),
    );

void main() {
  testWidgets('Dropdown.popupRender', (tester) async {
    await tester.pumpWidget(
      _host(
        Dropdown<String>(
          open: true,
          menu: const [DropdownItem(value: 'a', label: 'A')],
          popupRender: (context, menu) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [menu, const Text('footer')]),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('footer'), findsOneWidget);
  });

  testWidgets('AvatarGroup.popupRender', (tester) async {
    await tester.pumpWidget(
      _host(
        AvatarGroup(
          maxCount: 1,
          maxPopoverTrigger: const [DropdownTrigger.tap],
          popupRender: (context, group) => const Text('hidden ones'),
          children: const [
            Avatar(child: Text('A')),
            Avatar(child: Text('B')),
          ],
        ),
      ),
    );
    await tester.tap(find.text('+1'));
    await tester.pumpAndSettle();
    expect(find.text('hidden ones'), findsOneWidget);
  });

  testWidgets('Select.optionRender and itemRender', (tester) async {
    await tester.pumpWidget(
      _host(
        Select<String>(
          value: const ['a'],
          options: const [
            SelectOption(value: 'a', filterText: 'Apple'),
            SelectOption(value: 'b', filterText: 'Banana'),
          ],
          itemRender: (o) => Text('chosen ${o.value}'),
          optionRender: (o, selected) => Text('row ${o.value}'),
        ),
      ),
    );
    expect(find.text('chosen a'), findsOneWidget);
    await tester.tap(find.byType(Select<String>));
    await tester.pumpAndSettle();
    expect(find.text('row b'), findsOneWidget);
  });

  testWidgets('Listy.itemRender and separatorRender', (tester) async {
    await tester.pumpWidget(
      _host(
        Listy<String, String, String>(
          items: const ['one', 'two'],
          itemRender: (item, i) => Text('item $item'),
          separatorRender: (item, i) => const Text('between'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('item one'), findsOneWidget);
    expect(find.text('between'), findsOneWidget);
  });

  test('a Listy takes one row builder, not both', () {
    expect(
      () => Listy<String, String, String>(
        items: const [],
        itemBuilder: (_, __) => const SizedBox(),
        itemRender: (_, __) => const SizedBox(),
      ),
      throwsAssertionError,
    );
    expect(
      () => Listy<String, String, String>(items: const []),
      throwsAssertionError,
    );
  });

  testWidgets('PasswordConfig.iconRender', (tester) async {
    await tester.pumpWidget(
      _host(
        Input(
          password: PasswordConfig(
            iconRender: (visible) => Text(visible ? 'shown' : 'hidden'),
          ),
        ),
      ),
    );
    expect(find.text('hidden'), findsOneWidget);
  });
}
