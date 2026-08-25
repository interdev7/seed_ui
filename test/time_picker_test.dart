import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => ConfigProvider(
      child: MaterialApp(
        // The panel renders into the kit's overlay, which needs this key.
        navigatorKey: UiKit.navigatorKey,
        home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
      ),
    );

/// Opens the panel by tapping the field.
Future<void> _openPanel(WidgetTester tester) async {
  await tester.tap(find.byType(TimePicker));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the placeholder until a time is set', (tester) async {
    await tester.pumpWidget(_host(const TimePicker()));
    expect(find.text('Select time'), findsOneWidget);

    await tester.pumpWidget(
      _host(const TimePicker(value: Duration(hours: 9, minutes: 30))),
    );
    await tester.pump();
    expect(find.text('Select time'), findsNothing);
  });

  testWidgets('writes the value through the format', (tester) async {
    await tester.pumpWidget(
      _host(
        const TimePicker(
          value: Duration(hours: 9, minutes: 5, seconds: 3),
          format: 'HH:mm',
        ),
      ),
    );
    await tester.pump();
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, '09:05');
  });

  // Counted structurally: each column is its own scrolling list, and the
  // numbers are built lazily, so looking for '59' would only prove a column is
  // tall. One test per format — an open panel outlives a pumpWidget, so
  // several formats in one test would measure the wrong one.
  for (final (format, expected) in const [
    ('HH', 1),
    ('HH:mm', 2),
    ('HH:mm:ss', 3),
    ('h:mm a', 3),
  ]) {
    testWidgets('$format offers $expected column(s)', (tester) async {
      await tester.pumpWidget(_host(TimePicker(format: format)));
      await _openPanel(tester);
      expect(find.byType(ListView), findsNWidgets(expected));
    });
  }

  testWidgets('picking commits straight away when one column is shown', (
    tester,
  ) async {
    Duration? chosen;
    var calls = 0;
    await tester.pumpWidget(
      _host(
        TimePicker(
          format: 'HH',
          onChanged: (v) {
            chosen = v;
            calls++;
          },
        ),
      ),
    );
    await _openPanel(tester);
    await tester.tap(find.text('03'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(chosen, const Duration(hours: 3));
  });

  testWidgets('a multi-column panel waits for OK', (tester) async {
    Duration? chosen;
    await tester.pumpWidget(
      _host(TimePicker(format: 'HH:mm', onChanged: (v) => chosen = v)),
    );
    await _openPanel(tester);

    // '03' stands in both the hour and the minute column; the hour is first.
    await tester.tap(find.text('03').first);
    await tester.pumpAndSettle();
    expect(
      chosen,
      isNull,
      reason: 'an hour with no minute yet is not a time worth reporting',
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(chosen, const Duration(hours: 3));
  });

  testWidgets('needConfirm can be asked for outright', (tester) async {
    Duration? chosen;
    await tester.pumpWidget(
      _host(
        TimePicker(
          format: 'HH',
          needConfirm: true,
          onChanged: (v) => chosen = v,
        ),
      ),
    );
    await _openPanel(tester);
    await tester.tap(find.text('03'));
    await tester.pumpAndSettle();
    expect(chosen, isNull);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('a blocked value cannot be picked', (tester) async {
    Duration? chosen;
    await tester.pumpWidget(
      _host(
        TimePicker(
          format: 'HH',
          disabledTime: DisabledTime(hours: () => [3]),
          onChanged: (v) => chosen = v,
        ),
      ),
    );
    await _openPanel(tester);
    expect(find.text('03'), findsOneWidget, reason: 'greyed, not gone');

    await tester.tap(find.text('03'));
    await tester.pumpAndSettle();
    expect(chosen, isNull);
  });

  testWidgets('hideDisabledOptions takes them off the list', (tester) async {
    await tester.pumpWidget(
      _host(
        TimePicker(
          format: 'HH',
          hideDisabledOptions: true,
          disabledTime: DisabledTime(hours: () => [3]),
        ),
      ),
    );
    await _openPanel(tester);
    expect(find.text('03'), findsNothing);
    expect(find.text('04'), findsOneWidget);
  });

  testWidgets('the step thins out what is offered', (tester) async {
    await tester.pumpWidget(
      _host(const TimePicker(format: 'HH:mm', minuteStep: 15)),
    );
    await _openPanel(tester);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('16'), findsNothing);
  });

  testWidgets('clearing hands back null', (tester) async {
    Duration? chosen = const Duration(hours: 9);
    var called = false;
    await tester.pumpWidget(
      _host(
        TimePicker(
          value: const Duration(hours: 9),
          format: 'HH',
          onChanged: (v) {
            chosen = v;
            called = true;
          },
        ),
      ),
    );
    await tester.pump();

    // The clear button only shows under the pointer.
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(TimePicker)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CustomPaint).last);
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(chosen, isNull);
  });

  testWidgets('typing a time is read back', (tester) async {
    Duration? chosen;
    await tester.pumpWidget(
      _host(TimePicker(format: 'HH:mm', onChanged: (v) => chosen = v)),
    );
    await tester.enterText(find.byType(EditableText), '14:45');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(chosen, const Duration(hours: 14, minutes: 45));
  });

  testWidgets('an unreadable entry leaves the value alone', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(
        TimePicker(
          value: const Duration(hours: 9),
          format: 'HH:mm',
          onChanged: (_) => calls++,
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(EditableText), '99:99');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(calls, 0, reason: 'a stray keystroke must not wipe a set time');
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, '09:00', reason: 'the field was put back');
  });

  testWidgets('a disabled picker does not open', (tester) async {
    await tester.pumpWidget(
      _host(const TimePicker(format: 'HH', disabled: true)),
    );
    await tester.tap(find.byType(TimePicker));
    await tester.pumpAndSettle();
    expect(find.text('03'), findsNothing);
  });

  testWidgets('ConfigProvider.componentDisabled reaches it', (tester) async {
    await tester.pumpWidget(
      ConfigProvider(
        componentDisabled: true,
        child: MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: const Scaffold(body: Center(child: TimePicker(format: 'HH'))),
        ),
      ),
    );
    await tester.tap(find.byType(TimePicker));
    await tester.pumpAndSettle();
    expect(find.text('03'), findsNothing);
  });

  testWidgets('defaults reach it through the provider', (tester) async {
    await tester.pumpWidget(
      ConfigProvider(
        defaults: const ComponentDefaults(
          timePicker: TimePickerDefaults(showNow: false),
        ),
        child: MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: const Scaffold(body: Center(child: TimePicker(format: 'HH'))),
        ),
      ),
    );
    await _openPanel(tester);
    expect(find.text('Now'), findsNothing);
  });

  testWidgets('the panel speaks the locale', (tester) async {
    await tester.pumpWidget(
      ConfigProvider(
        locale: SeedLocalizations.ru,
        child: MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: const Scaffold(body: Center(child: TimePicker(format: 'HH'))),
        ),
      ),
    );
    expect(find.text('Выберите время'), findsOneWidget);
    await _openPanel(tester);
    expect(find.text('Сейчас'), findsOneWidget);
  });

  testWidgets('a 12-hour format offers the meridiem', (tester) async {
    await tester.pumpWidget(_host(const TimePicker(format: 'h:mm a')));
    await _openPanel(tester);
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
  });
}
