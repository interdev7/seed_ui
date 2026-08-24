import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host({
  SoftSize? componentSize,
  bool? componentDisabled,
  required Widget child,
}) =>
    ConfigProvider(
      componentSize: componentSize,
      componentDisabled: componentDisabled,
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

Future<double> _buttonHeight(WidgetTester tester, Widget tree) async {
  await tester.pumpWidget(tree);
  await tester.pumpAndSettle();
  return tester.getRect(find.byType(Button)).height;
}

void main() {
  group('componentSize', () {
    testWidgets('sets the size for everything below it', (tester) async {
      final small = await _buttonHeight(
        tester,
        _host(
          componentSize: SoftSize.small,
          child: Button(onPressed: () {}, child: const Text('Pay')),
        ),
      );
      final large = await _buttonHeight(
        tester,
        _host(
          componentSize: SoftSize.large,
          child: Button(onPressed: () {}, child: const Text('Pay')),
        ),
      );
      final unset = await _buttonHeight(
        tester,
        _host(child: Button(onPressed: () {}, child: const Text('Pay'))),
      );

      expect(small, lessThan(unset));
      expect(large, greaterThan(unset));
    });

    testWidgets('what a widget states for itself still wins', (tester) async {
      final height = await _buttonHeight(
        tester,
        _host(
          componentSize: SoftSize.small,
          child: Button(
            size: SoftSize.large,
            onPressed: () {},
            child: const Text('Pay'),
          ),
        ),
      );
      final large = await _buttonHeight(
        tester,
        _host(
          child: Button(
            size: SoftSize.large,
            onPressed: () {},
            child: const Text('Pay'),
          ),
        ),
      );
      expect(height, large);
    });

    testWidgets('carries through a provider silent about it', (tester) async {
      final nested = await _buttonHeight(
        tester,
        ConfigProvider(
          componentSize: SoftSize.large,
          child: MaterialApp(
            home: ConfigProvider(
              theme: ThemeData(),
              child: Scaffold(
                body: Center(
                  child: Button(onPressed: () {}, child: const Text('Pay')),
                ),
              ),
            ),
          ),
        ),
      );
      final direct = await _buttonHeight(
        tester,
        _host(
          componentSize: SoftSize.large,
          child: Button(onPressed: () {}, child: const Text('Pay')),
        ),
      );
      final unset = await _buttonHeight(
        tester,
        _host(child: Button(onPressed: () {}, child: const Text('Pay'))),
      );
      expect(nested, direct);
      expect(
        nested,
        isNot(unset),
        reason: 'equal to the direct case is no proof if neither took effect',
      );
    });

    testWidgets('an enclosing AvatarGroup is nearer than the screen',
        (tester) async {
      await tester.pumpWidget(
        _host(
          componentSize: SoftSize.small,
          child: const AvatarGroup(
            size: SoftSize.large,
            children: [Avatar(child: Text('A'))],
          ),
        ),
      );
      final grouped = tester.getRect(find.byType(Avatar)).height;

      await tester.pumpWidget(
        _host(
          componentSize: SoftSize.small,
          child: const Avatar(child: Text('A')),
        ),
      );
      final loose = tester.getRect(find.byType(Avatar)).height;

      // Both halves must be doing something: the loose avatar shrank to the
      // screen's size, the grouped one held the group's.
      await tester.pumpWidget(
        _host(child: const Avatar(child: Text('A'))),
      );
      final unset = tester.getRect(find.byType(Avatar)).height;

      expect(loose, lessThan(unset), reason: 'the screen reached it');
      expect(grouped, greaterThan(unset), reason: 'the group outranked it');
    });
  });

  group('componentDisabled', () {
    testWidgets('turns off the controls below it', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          componentDisabled: true,
          child: Button(onPressed: () => taps++, child: const Text('Pay')),
        ),
      );
      await tester.tap(find.byType(Button));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('a control can stay live in a disabled subtree',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          componentDisabled: true,
          child: Button(
            disabled: false,
            onPressed: () => taps++,
            child: const Text('Pay'),
          ),
        ),
      );
      await tester.tap(find.byType(Button));
      await tester.pump();
      expect(taps, 1, reason: 'its own word wins over the screen');
    });

    testWidgets('reaches a switch and a checkbox too', (tester) async {
      var switched = false;
      var checked = false;
      await tester.pumpWidget(
        _host(
          componentDisabled: true,
          child: Column(
            children: [
              Switch(value: false, onChanged: (_) => switched = true),
              Checkbox(checked: false, onChanged: (_) => checked = true),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(Switch));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(switched, isFalse);
      expect(checked, isFalse);
    });

    testWidgets('carries through a provider silent about it', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        ConfigProvider(
          componentDisabled: true,
          child: MaterialApp(
            home: ConfigProvider(
              theme: ThemeData(),
              child: Scaffold(
                body: Center(
                  child: Button(
                    onPressed: () => taps++,
                    child: const Text('Pay'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(Button));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('a per-item flag is not the screen speaking', (tester) async {
      // CheckboxOption.disabled is about that option; nothing here should make
      // the group's own options change their mind.
      await tester.pumpWidget(
        _host(
          child: CheckboxGroup(
            value: const [],
            onChanged: (_) {},
            options: const [
              CheckboxOption(value: 'a', label: Text('Apple')),
              CheckboxOption(value: 'b', label: Text('Pear'), disabled: true),
            ],
          ),
        ),
      );
      final off = tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .where((c) => c.disabled ?? false);
      expect(off.length, 1);
    });
  });
}
