import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// Puts one button on screen and returns its width.
///
/// Width, not height: the button keeps its box height and grows sideways with
/// the preset. And settled, because the change rides an `AnimatedContainer` —
/// measured at once it still reads the preset before it.
Future<double> _buttonWidth(
  WidgetTester tester, {
  SoftSize? ambient,
  ButtonDefaults? defaults,
  SoftSize? own,
}) async {
  await tester.pumpWidget(
    ConfigProvider(
      componentSize: ambient,
      defaults: ComponentDefaults(button: defaults),
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: Button(size: own, onPressed: () {}, child: const Text('Go')),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.getSize(find.byType(Button)).width;
}

void main() {
  group('size resolves nearest-first', () {
    testWidgets('a component default beats the screen-wide size', (
      tester,
    ) async {
      final small = await _buttonWidth(tester, ambient: SoftSize.small);
      final large = await _buttonWidth(tester, ambient: SoftSize.large);
      expect(small, lessThan(large), reason: 'the two presets differ at all');

      final chosen = await _buttonWidth(
        tester,
        ambient: SoftSize.large,
        defaults: const ButtonDefaults(size: SoftSize.small),
      );
      expect(chosen, small, reason: 'the button default won over the screen');
    });

    testWidgets("the widget's own size beats both", (tester) async {
      final large = await _buttonWidth(tester, ambient: SoftSize.large);

      final own = await _buttonWidth(
        tester,
        ambient: SoftSize.small,
        defaults: const ButtonDefaults(size: SoftSize.small),
        own: SoftSize.large,
      );
      expect(own, large, reason: 'the widget had the last word');
    });

    testWidgets('the screen-wide size still reaches a silent component', (
      tester,
    ) async {
      // Nothing about buttons is said here, so componentSize must still land:
      // the new hop must not have displaced it.
      final small = await _buttonWidth(tester, ambient: SoftSize.small);
      final large = await _buttonWidth(tester, ambient: SoftSize.large);
      expect(small, lessThan(large));
    });

    testWidgets('one component can differ from the rest of the screen', (
      tester,
    ) async {
      // The point of the whole change: small buttons on an otherwise normal
      // screen, which componentSize alone cannot say.
      Future<(double, double)> measure({ButtonDefaults? button}) async {
        await tester.pumpWidget(
          ConfigProvider(
            componentSize: SoftSize.large,
            defaults: ComponentDefaults(button: button),
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Button(onPressed: () {}, child: const Text('Go')),
                      SizedBox(width: 200, child: Input(key: UniqueKey())),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return (
          tester.getSize(find.byType(Button)).width,
          tester.getSize(find.byType(Input)).height,
        );
      }

      final (plainButton, plainInput) = await measure();
      final (smallButton, sameInput) = await measure(
        button: const ButtonDefaults(size: SoftSize.small),
      );

      expect(smallButton, lessThan(plainButton), reason: 'the button shrank');
      expect(sameInput, plainInput, reason: 'the input was left alone');
    });
  });

  group('disabled resolves nearest-first', () {
    testWidgets('a component default disables just that component', (
      tester,
    ) async {
      var pressed = 0;
      await tester.pumpWidget(
        ConfigProvider(
          defaults: const ComponentDefaults(
            button: ButtonDefaults(disabled: true),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Button(
                  onPressed: () => pressed++,
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(pressed, 0);
    });

    testWidgets("the widget's own word beats the default", (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        ConfigProvider(
          componentDisabled: true,
          defaults: const ComponentDefaults(
            button: ButtonDefaults(disabled: true),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Button(
                  disabled: false,
                  onPressed: () => pressed++,
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(pressed, 1, reason: 'the button said it was live');
    });
  });

  test('the defaults that can carry a size or a disabled do', () {
    // A guard against the set drifting apart again.
    expect(const ButtonDefaults(size: SoftSize.small).size, SoftSize.small);
    expect(const InputDefaults(size: SoftSize.small).size, SoftSize.small);
    expect(const SelectDefaults(size: SoftSize.small).size, SoftSize.small);
    expect(const TimePickerDefaults(size: SoftSize.small).size, SoftSize.small);
    expect(const ButtonDefaults(disabled: true).disabled, isTrue);
    expect(const InputDefaults(disabled: true).disabled, isTrue);
    expect(const SelectDefaults(disabled: true).disabled, isTrue);
    expect(const TimePickerDefaults(disabled: true).disabled, isTrue);
  });
}
