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

  testWidgets('the panel is only as wide as its columns', (tester) async {
    // It once filled the viewport: a stretched Column takes whatever width it
    // is given, and the overlay gives it the screen.
    await tester.pumpWidget(_host(const TimePicker(format: 'HH:mm')));
    await _openPanel(tester);

    final panel = find.ancestor(
      of: find.byType(ListView).first,
      matching: find.byType(DecoratedBox),
    );
    final panelWidth = tester.getSize(panel.first).width;
    final columnWidth = tester.getSize(find.byType(ListView).first).width;

    expect(columnWidth, greaterThan(0));
    expect(
      panelWidth,
      lessThan(columnWidth * 4),
      reason: 'two columns and a divider, not the whole screen',
    );
    expect(
        panelWidth, lessThan(tester.getSize(find.byType(MaterialApp)).width));
  });

  testWidgets('picking shows in the panel straight away', (tester) async {
    // The panel is built into the overlay, a tree of its own, so setState on
    // the picker does not reach it. Without a nudge nothing at all happened
    // on screen when a value was tapped.
    await tester.pumpWidget(_host(const TimePicker(format: 'HH:mm')));
    await _openPanel(tester);

    Color? pillOf(String label) {
      final box = find
          .ancestor(
            of: find.text(label).first,
            matching: find.byType(AnimatedContainer),
          )
          .first;
      return (tester.widget<AnimatedContainer>(box).decoration
              as BoxDecoration?)
          ?.color;
    }

    final before = pillOf('03');
    await tester.tap(find.text('03').first);
    await tester.pumpAndSettle();

    expect(pillOf('03'), isNot(before), reason: 'the chosen hour is lit');
  });

  testWidgets('picking shows in the field before OK is pressed', (
    tester,
  ) async {
    // The value still waits for OK, but the field must not sit blank while
    // the panel already shows a choice.
    Duration? committed;
    await tester.pumpWidget(
      _host(TimePicker(format: 'HH:mm', onChanged: (v) => committed = v)),
    );
    await _openPanel(tester);

    String fieldText() =>
        tester.widget<EditableText>(find.byType(EditableText)).controller.text;

    expect(fieldText(), isEmpty);

    await tester.tap(find.text('03').first);
    await tester.pumpAndSettle();

    expect(fieldText(), startsWith('03'), reason: 'the field followed at once');
    expect(committed, isNull, reason: 'but the value still waits for OK');
  });

  testWidgets('digits are set in from the start, not centred', (tester) async {
    // Centring looks even only while every label is the same width; setting
    // the digits in from the start keeps a column straight whatever it holds.
    //
    // Asserted on the layout rather than on pixels: the test font gives every
    // glyph the same width, which makes a centred cell and an inset one
    // measure alike.
    await tester.pumpWidget(_host(const TimePicker(format: 'HH:mm')));
    await _openPanel(tester);

    final pill = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('00').first,
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );

    expect(pill.alignment, AlignmentDirectional.centerStart);
    final inset = pill.padding! as EdgeInsetsDirectional;
    expect(inset.start, greaterThan(0), reason: 'the digits are set in');
  });

  testWidgets('a value is inset from the sides of its column', (tester) async {
    // The gap between one value and the next is what makes the panel legible;
    // a pill filling the column edge to edge reads as a solid block.
    await tester.pumpWidget(_host(const TimePicker(format: 'HH:mm')));
    await _openPanel(tester);

    final columnWidth = tester.getSize(find.byType(ListView).first).width;
    final pill = tester
        .getSize(
          find
              .ancestor(
                of: find.text('00').first,
                matching: find.byType(AnimatedContainer),
              )
              .first,
        )
        .width;

    expect(pill, lessThan(columnWidth), reason: 'inset on both sides');
    expect(pill, greaterThan(columnWidth / 2), reason: 'but not squeezed');
  });

  testWidgets('the chosen value glides to the top of its column', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const TimePicker(format: 'HH:mm')));
    await _openPanel(tester);

    ScrollPosition hourColumn() => tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;

    expect(hourColumn().pixels, 0);
    await tester.tap(find.text('05').first);
    await tester.pumpAndSettle();

    // Five rows up: the chosen hour now sits against the top of the column.
    expect(hourColumn().pixels, greaterThan(0));
  });

  testWidgets('even the last value can reach the top', (tester) async {
    // Without room below the run the late hours can only ever sit at the
    // bottom of the column, which reads as the panel refusing to move.
    await tester.pumpWidget(_host(const TimePicker(format: 'HH:mm')));
    await _openPanel(tester);

    final pos = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;

    final rowHeight = tester.getSize(find.text('00').first).height;
    expect(rowHeight, greaterThan(0));
    // 23 rows of travel for a 24-hour column.
    expect(pos.maxScrollExtent, greaterThanOrEqualTo(23 * 28.0));
  });

  testWidgets('the panel is inset from its own top edge', (tester) async {
    await tester.pumpWidget(_host(const TimePicker(format: 'HH:mm')));
    await _openPanel(tester);

    final panel = find.ancestor(
      of: find.byType(ListView).first,
      matching: find.byType(DecoratedBox),
    );
    final panelTop = tester.getRect(panel.first).top;
    final columnTop = tester.getRect(find.byType(ListView).first).top;

    expect(
      columnTop - panelTop,
      greaterThan(0),
      reason: 'the first value must not sit against the panel edge',
    );
  });

  testWidgets('the default format offers seconds', (tester) async {
    await tester.pumpWidget(_host(const TimePicker()));
    await _openPanel(tester);
    expect(find.byType(ListView), findsNWidgets(3));
  });

  testWidgets('the field text is centred in its box', (tester) async {
    // A line height of 1 with no even leading split puts the glyphs above the
    // middle of the box, and "12:00" reads as sitting too high in the field.
    //
    // Asserted on the style: the test font has symmetric metrics, so the
    // fault is invisible to a measurement here but plain on a real face.
    await tester.pumpWidget(
      _host(
        const TimePicker(format: 'HH:mm', value: Duration(hours: 12)),
      ),
    );
    await tester.pump();

    final style = tester.widget<EditableText>(find.byType(EditableText)).style;
    expect(style.height, 1.0);
    expect(style.leadingDistribution, TextLeadingDistribution.even);
  });

  testWidgets('the figures follow the language, as elsewhere in the kit', (
    tester,
  ) async {
    await tester.pumpWidget(
      ConfigProvider(
        locale: SeedLocalizations.ar,
        child: MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: SizedBox(width: 220, child: TimePicker(format: 'HH:mm')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TimePicker));
    await tester.pumpAndSettle();

    // Arabic-Indic, the way Countdown and Badge already render their figures.
    expect(find.text('٠٠'), findsWidgets);
    expect(find.text('00'), findsNothing);
  });

  testWidgets('a typed time is read back in the locale it is shown in', (
    tester,
  ) async {
    // The field shows the locale's figures, so the parser has to accept them
    // back — a plain \\d would not.
    Duration? chosen;
    await tester.pumpWidget(
      ConfigProvider(
        locale: SeedLocalizations.ar,
        child: MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 220,
                  child: TimePicker(
                    format: 'HH:mm',
                    onChanged: (v) => chosen = v,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '١٤:٤٥');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(chosen, const Duration(hours: 14, minutes: 45));
  });

  testWidgets('without a value of its own it keeps what is picked', (
    tester,
  ) async {
    // An uncontrolled picker, as Select is: no value, no onChanged, and the
    // choice still survives the panel closing.
    await tester.pumpWidget(_host(const TimePicker(format: 'HH')));
    await _openPanel(tester);
    await tester.tap(find.text('03'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      '03',
    );
  });

  testWidgets('defaultValue starts an uncontrolled picker off', (tester) async {
    await tester.pumpWidget(
      _host(
        const TimePicker(
          format: 'HH:mm',
          defaultValue: Duration(hours: 7, minutes: 15),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      '07:15',
    );
  });

  testWidgets('a chosen value lands at once, without a grey stage', (
    tester,
  ) async {
    // Easing from the hover grey to the chosen tint shows the grey on the way,
    // which reads as a flash under the finger.
    // Two columns, so the panel stays open after the pick.
    await tester.pumpWidget(_host(const TimePicker(format: 'HH:mm')));
    await _openPanel(tester);
    await tester.tap(find.text('03').first);
    await tester.pumpAndSettle();

    final pill = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('03').first,
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(pill.duration, Duration.zero);
  });

  testWidgets('status paints the border', (tester) async {
    Color borderOf() {
      final box = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(TimePicker),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      return ((box.decoration! as BoxDecoration).border! as Border).top.color;
    }

    await tester.pumpWidget(_host(const TimePicker(format: 'HH')));
    await tester.pumpAndSettle();
    final plain = borderOf();

    await tester.pumpWidget(
      _host(const TimePicker(format: 'HH', status: InputStatus.error)),
    );
    await tester.pumpAndSettle();
    expect(borderOf(), isNot(plain));
  });

  testWidgets('onClear fires when the value is dropped', (tester) async {
    var cleared = 0;
    await tester.pumpWidget(
      _host(
        TimePicker(
          format: 'HH',
          defaultValue: const Duration(hours: 9),
          onClear: () => cleared++,
        ),
      ),
    );
    await tester.pump();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(TimePicker)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CustomPaint).last);
    await tester.pumpAndSettle();

    expect(cleared, 1);
  });

  testWidgets('a prefix, a suffix and a footer of your own', (tester) async {
    await tester.pumpWidget(
      _host(
        TimePicker(
          format: 'HH',
          prefix: const Text('from'),
          suffixIcon: const Text('*'),
          footerBuilder: (context) => const Text('a note'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('from'), findsOneWidget);
    expect(find.text('*'), findsOneWidget);

    await _openPanel(tester);
    expect(find.text('a note'), findsOneWidget);
  });
}
