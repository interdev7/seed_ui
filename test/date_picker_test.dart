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

Future<void> _openPanel(WidgetTester tester) async {
  await tester.tap(find.byType(DatePicker));
  await tester.pumpAndSettle();
}

/// The text of the field.
String _fieldText(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  testWidgets('shows the placeholder until a date is set', (tester) async {
    await tester.pumpWidget(_host(const DatePicker()));
    expect(find.text('Select date'), findsOneWidget);

    await tester.pumpWidget(
      _host(DatePicker(value: DateTime(2026, 3, 4))),
    );
    await tester.pump();
    expect(find.text('Select date'), findsNothing);
    expect(_fieldText(tester), '2026-03-04');
  });

  testWidgets('writes the value through the format', (tester) async {
    await tester.pumpWidget(
      _host(DatePicker(value: DateTime(2026, 3, 4), format: 'd MMM yyyy')),
    );
    await tester.pump();
    expect(_fieldText(tester), '4 Mar 2026');
  });

  testWidgets('the panel opens on the month of the value', (tester) async {
    await tester.pumpWidget(
      _host(DatePicker(value: DateTime(2026, 3, 4))),
    );
    await _openPanel(tester);
    expect(find.text('Mar 2026'), findsOneWidget);
  });

  testWidgets('picking a day commits it and closes', (tester) async {
    DateTime? chosen;
    await tester.pumpWidget(
      _host(
        DatePicker(
          value: DateTime(2026, 3, 4),
          onChanged: (v) => chosen = v,
        ),
      ),
    );
    await _openPanel(tester);

    // The 15th of March 2026 — unambiguous, since the grid's other months
    // cannot also show a 15 for this layout.
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();

    expect(chosen, DateTime(2026, 3, 15));
  });

  for (final month in [DateTime(2026, 2), DateTime(2026, 8)]) {
    testWidgets('${month.month}/2026 draws six weeks of cells', (tester) async {
      // February 2026 is the tightest month there is and August one of the
      // longest. A grid that grew a row would shift everything under it, so
      // both draw 42 cells — six weeks — either way.
      await tester.pumpWidget(_host(DatePicker(value: month)));
      await _openPanel(tester);

      // Each day cell is an AnimatedContainer; so is the field itself.
      expect(find.byType(AnimatedContainer), findsNWidgets(43));
    });
  }

  group('walking through the panels', () {
    testWidgets('the header goes up: day to month to year', (tester) async {
      await tester.pumpWidget(_host(DatePicker(value: DateTime(2026, 3, 4))));
      await _openPanel(tester);

      await tester.tap(find.text('Mar 2026'));
      await tester.pumpAndSettle();
      expect(find.text('2026'), findsOneWidget, reason: 'the months of 2026');
      expect(find.text('Mar'), findsOneWidget);

      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();
      expect(find.text('2020–2029'), findsOneWidget);
    });

    testWidgets('picking walks back down', (tester) async {
      await tester.pumpWidget(_host(DatePicker(value: DateTime(2026, 3, 4))));
      await _openPanel(tester);

      await tester.tap(find.text('Mar 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();

      // A year, then a month, then the days.
      await tester.tap(find.text('2023'));
      await tester.pumpAndSettle();
      expect(find.text('2023'), findsOneWidget, reason: 'the months of 2023');

      await tester.tap(find.text('Jul'));
      await tester.pumpAndSettle();
      expect(find.text('Jul 2023'), findsOneWidget);
    });
  });

  testWidgets('the chevrons step by what is on screen', (tester) async {
    await tester.pumpWidget(_host(DatePicker(value: DateTime(2026, 3, 4))));
    await _openPanel(tester);

    await tester.tap(find.bySemanticsLabel('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Apr 2026'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Previous'));
    await tester.tap(find.bySemanticsLabel('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Feb 2026'), findsOneWidget);

    // One page of what is on screen: a year at the month depth.
    await tester.tap(find.text('Feb 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Next'));
    await tester.pumpAndSettle();
    expect(find.text('2027'), findsOneWidget);
  });

  testWidgets('a blocked day cannot be picked', (tester) async {
    DateTime? chosen;
    await tester.pumpWidget(
      _host(
        DatePicker(
          value: DateTime(2026, 3, 4),
          disabledDate: (d) => d.day == 15,
          onChanged: (v) => chosen = v,
        ),
      ),
    );
    await _openPanel(tester);
    expect(find.text('15'), findsOneWidget, reason: 'greyed, not gone');

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(chosen, isNull);
  });

  testWidgets('Today does nothing when today itself is blocked', (
    tester,
  ) async {
    // The footer is another way to the same day, and it must not be a way
    // round the rule.
    DateTime? chosen;
    await tester.pumpWidget(
      _host(
        DatePicker(
          value: DateTime(2026, 3, 4),
          disabledDate: (_) => true,
          onChanged: (v) => chosen = v,
        ),
      ),
    );
    await _openPanel(tester);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(chosen, isNull);
  });

  testWidgets('minDate and maxDate close the ends off', (tester) async {
    DateTime? chosen;
    await tester.pumpWidget(
      _host(
        DatePicker(
          value: DateTime(2026, 3, 10),
          minDate: DateTime(2026, 3, 10),
          maxDate: DateTime(2026, 3, 20),
          onChanged: (v) => chosen = v,
        ),
      ),
    );
    await _openPanel(tester);

    // Days 1-5 and 23-28 stand twice in this grid, once for the neighbouring
    // month drawn faintly. These three are March's alone.
    await tester.tap(find.text('7'));
    await tester.pumpAndSettle();
    expect(chosen, isNull, reason: 'before minDate');

    await tester.tap(find.text('22'));
    await tester.pumpAndSettle();
    expect(chosen, isNull, reason: 'after maxDate');

    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(chosen, DateTime(2026, 3, 12));
  });

  testWidgets('typing a date is read back', (tester) async {
    DateTime? chosen;
    await tester.pumpWidget(
      _host(DatePicker(onChanged: (v) => chosen = v)),
    );
    await tester.enterText(find.byType(EditableText), '2026-07-19');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(chosen, DateTime(2026, 7, 19));
  });

  testWidgets('an impossible date leaves the value alone', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(
        DatePicker(
          value: DateTime(2026, 3, 4),
          onChanged: (_) => calls++,
        ),
      ),
    );
    await tester.pump();

    // The 31st of February would otherwise roll into March.
    await tester.enterText(find.byType(EditableText), '2026-02-31');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(_fieldText(tester), '2026-03-04', reason: 'the field was put back');
  });

  testWidgets('without a value of its own it keeps what is picked', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(DatePicker(defaultValue: DateTime(2026, 3, 4))),
    );
    await tester.pump();
    expect(_fieldText(tester), '2026-03-04');

    await _openPanel(tester);
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(_fieldText(tester), '2026-03-15');
  });

  testWidgets('clearing hands back null', (tester) async {
    DateTime? chosen = DateTime(2026, 3, 4);
    var cleared = 0;
    await tester.pumpWidget(
      _host(
        DatePicker(
          value: DateTime(2026, 3, 4),
          onChanged: (v) => chosen = v,
          onClear: () => cleared++,
        ),
      ),
    );
    await tester.pump();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(DatePicker)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CustomPaint).last);
    await tester.pumpAndSettle();

    expect(chosen, isNull);
    expect(cleared, 1);
  });

  testWidgets('a disabled picker does not open', (tester) async {
    await tester.pumpWidget(
      _host(DatePicker(value: DateTime(2026, 3, 4), disabled: true)),
    );
    await tester.tap(find.byType(DatePicker));
    await tester.pumpAndSettle();
    expect(find.text('Mar 2026'), findsNothing);
  });

  group('the locale', () {
    testWidgets('names the months and the days', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          locale: SeedLocalizations.ru,
          child: MaterialApp(
            navigatorKey: UiKit.navigatorKey,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: DatePicker(value: DateTime(2026, 3, 4)),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Выберите дату'), findsNothing, reason: 'has a value');

      await _openPanel(tester);
      expect(find.text('мар 2026'), findsOneWidget);
      expect(find.text('пн'), findsOneWidget);
      expect(find.text('Сегодня'), findsOneWidget);
    });

    // One test per language: an open panel outlives a pumpWidget, so two
    // languages in one test would have the second tap land on the first
    // panel's barrier.
    // The leading head, and the day that must sit under it. March 2026
    // begins on a Sunday, so a Monday-first grid leads with 23 February, a
    // Sunday-first one with the 1st, and a Saturday-first one with the 28th.
    for (final (name, locale, expected, firstCell) in [
      ('English', SeedLocalizations.en, 'Mon', '23'),
      ('Japanese', SeedLocalizations.ja, '日', '1'),
      ('Arabic', SeedLocalizations.ar, 'سبت', '٢٨'),
    ]) {
      testWidgets('$name weeks start on $expected', (tester) async {
        await tester.pumpWidget(
          ConfigProvider(
            locale: locale,
            child: MaterialApp(
              navigatorKey: UiKit.navigatorKey,
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 320,
                    child: DatePicker(value: DateTime(2026, 3, 4)),
                  ),
                ),
              ),
            ),
          ),
        );
        await _openPanel(tester);

        // Read off the panel, not off the locale: comparing the locale with
        // itself would prove nothing.
        var leading = '';
        var x = double.infinity;
        for (final day in locale.shortWeekdays) {
          final at = find.text(day);
          if (at.evaluate().isEmpty) continue;
          // Centres, not edges: the head and the cell are both centred in
          // their column and their texts are different widths.
          final centre = tester.getCenter(at.first).dx;
          if (centre < x) {
            x = centre;
            leading = day;
          }
        }
        expect(leading, expected);

        // The heads and the grid must agree: a grid that ignored the locale
        // would still head its columns correctly and put the wrong days under
        // them.
        final under = find.text(firstCell);
        expect(under, findsWidgets, reason: 'no $firstCell on the panel');
        expect(
          tester.getCenter(under.first).dx,
          closeTo(x, 1),
          reason: 'the first cell does not sit under the first head',
        );
      });
    }

    testWidgets('counts in the language own figures', (tester) async {
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
                    width: 320,
                    child: DatePicker(value: DateTime(2026, 3, 4)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _openPanel(tester);
      // Arabic-Indic, as Countdown and TimePicker already render figures.
      expect(find.text('١٥'), findsWidgets);
      expect(find.text('15'), findsNothing);
    });
  });

  testWidgets('the field sizes itself when nothing dictates a width', (
    tester,
  ) async {
    await tester.pumpWidget(
      ConfigProvider(
        child: MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: Scaffold(
            body: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [DatePicker(value: DateTime(2026, 3, 4))],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final width = tester.getSize(find.byType(DatePicker)).width;
    expect(width, greaterThan(0));
    expect(width, lessThan(400), reason: 'sized to itself, not the page');
  });

  testWidgets('defaults reach it through the provider', (tester) async {
    await tester.pumpWidget(
      ConfigProvider(
        defaults: const ComponentDefaults(
          datePicker: DatePickerDefaults(showToday: false),
        ),
        child: MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: DatePicker(value: DateTime(2026, 3, 4)),
              ),
            ),
          ),
        ),
      ),
    );
    await _openPanel(tester);
    expect(find.text('Today'), findsNothing);
  });

  group('size takes a preset or a measurement', () {
    Future<Size> sizeOf(WidgetTester tester, ControlSize? size) async {
      await tester.pumpWidget(
        ConfigProvider(
          child: MaterialApp(
            navigatorKey: UiKit.navigatorKey,
            home: Scaffold(
              body: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [DatePicker(size: size, placeholder: '')],
                ),
              ),
            ),
          ),
        ),
      );
      // Settled: the height rides an AnimatedContainer, so a measurement at
      // once still reads the preset before it.
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(DatePicker));
    }

    testWidgets('a preset still walks the theme scale', (tester) async {
      final small = await sizeOf(tester, SoftSize.small);
      final large = await sizeOf(tester, SoftSize.large);
      expect(small.height, lessThan(large.height));
    });

    testWidgets('a bare dimension is the height, taken as given', (
      tester,
    ) async {
      expect((await sizeOf(tester, const ControlSize.fixed(36))).height, 36);
    });

    testWidgets('a two-dimensional size names both', (tester) async {
      // The larger side would make the field two hundred pixels tall, which
      // is what a plain 1D resolve would have given.
      final size = await sizeOf(tester, const ControlSize.raw(200, 36));
      expect(size.height, 36);
      expect(size.width, 200);
    });

    testWidgets('a measurement leaves the type size alone', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          child: MaterialApp(
            navigatorKey: UiKit.navigatorKey,
            home: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 240,
                  child: DatePicker(
                    size: ControlSize.fixed(36),
                    placeholder: 'x',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      // A dimension says nothing about type, so the standard size stands.
      expect(tester.widget<Text>(find.text('x')).style?.fontSize, 14);
    });
  });

  group('a panel driven from outside', () {
    Widget driven({required bool open, required VoidCallback toggle}) =>
        ConfigProvider(
          child: MaterialApp(
            navigatorKey: UiKit.navigatorKey,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 200,
                      child: DatePicker(open: open),
                    ),
                    GestureDetector(
                      onTap: toggle,
                      child: const Text('flip'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    testWidgets('opens without building the overlay mid-build', (
      tester,
    ) async {
      // didUpdateWidget runs inside a build, and mounting the overlay entry
      // marks the Overlay as needing to build — doing it there throws.
      var open = false;
      late StateSetter setOuter;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            return driven(
              open: open,
              toggle: () => setState(() => open = !open),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('flip'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Today'), findsOneWidget, reason: 'the panel opened');

      setOuter(() => open = false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Today'), findsNothing);
    });

    testWidgets('a picker born open opens', (tester) async {
      await tester.pumpWidget(driven(open: true, toggle: () {}));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Today'), findsOneWidget);
    });
  });
}
