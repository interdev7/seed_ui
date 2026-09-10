import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
import 'package:seed_ui/src/components/data_entry/date_picker.dart'
    show DayGrid;

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
  _presetTests();
  _kindTests();
  _spacingTests();
  _clearRaceTests();
  _showTimeTests();
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
      expect((await sizeOf(tester, const ControlSize.height(36))).height, 36);
    });

    testWidgets('a two-dimensional size names both', (tester) async {
      // The larger side would make the field two hundred pixels tall, which
      // is what a plain 1D resolve would have given.
      final size = await sizeOf(tester, const ControlSize.box(200, 36));
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
                    size: ControlSize.height(36),
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

void _presetTests() {
  group('presets', () {
    testWidgets('a preset takes its date and closes the panel', (tester) async {
      DateTime? chosen;
      await tester.pumpWidget(
        _host(
          DatePicker(
            value: DateTime(2026, 3, 4),
            onChanged: (v) => chosen = v,
            presets: [DatePreset('Midsummer', DateTime(2026, 6, 24))],
          ),
        ),
      );
      await _openPanel(tester);

      expect(find.text('Midsummer'), findsOneWidget);
      await tester.tap(find.text('Midsummer'));
      await tester.pumpAndSettle();

      expect(chosen, DateTime(2026, 6, 24));
      expect(find.text('Midsummer'), findsNothing, reason: 'the panel closed');
    });

    testWidgets('no rail is drawn where there are no presets', (tester) async {
      await tester.pumpWidget(_host(DatePicker(value: DateTime(2026, 3, 4))));
      await _openPanel(tester);
      // The rail is the only thing in the panel that scrolls.
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('a preset is asked for its date when it is taken',
        (tester) async {
      var asked = 0;
      DateTime? chosen;
      await tester.pumpWidget(
        _host(
          DatePicker(
            value: DateTime(2026, 3, 4),
            onChanged: (v) => chosen = v,
            presets: [
              DatePreset.of('Now', () {
                asked++;
                return DateTime(2026, 9, asked);
              }),
            ],
          ),
        ),
      );
      await _openPanel(tester);
      final atFirstDraw = asked;
      expect(atFirstDraw, greaterThan(0), reason: 'drawn once to be greyed');

      await tester.tap(find.text('Now'));
      await tester.pumpAndSettle();
      // Asked again on the tap rather than handed the date it was drawn
      // with: a preset reckoned from the clock has moved on since.
      expect(chosen, DateTime(2026, 9, atFirstDraw + 1));
    });

    testWidgets('a preset landing on a blocked day does nothing',
        (tester) async {
      DateTime? chosen;
      await tester.pumpWidget(
        _host(
          DatePicker(
            value: DateTime(2026, 3, 4),
            onChanged: (v) => chosen = v,
            maxDate: DateTime(2026, 3, 31),
            presets: [DatePreset('Midsummer', DateTime(2026, 6, 24))],
          ),
        ),
      );
      await _openPanel(tester);
      await tester.tap(find.text('Midsummer'));
      await tester.pumpAndSettle();

      expect(chosen, isNull);
      expect(find.text('Midsummer'), findsOneWidget, reason: 'still open');
      // Greyed rather than hidden, so the rail keeps its shape.
      final style = tester.widget<Text>(find.text('Midsummer')).style!;
      expect(style.color, const Color(0xFF000000).withValues(alpha: 0.25));
    });
  });
}

void _showTimeTests() {
  group('showTime', () {
    testWidgets('a format naming no time is given a clock', (tester) async {
      await tester.pumpWidget(
        _host(
          DatePicker(showTime: true, value: DateTime(2026, 3, 4, 14, 32, 5)),
        ),
      );
      // Collected and then written nowhere would look broken.
      expect(find.text('2026-03-04 14:32:05'), findsOneWidget);
    });

    testWidgets('a format that names its own time is left alone',
        (tester) async {
      await tester.pumpWidget(
        _host(
          DatePicker(
            showTime: true,
            format: 'yyyy-MM-dd HH:mm',
            value: DateTime(2026, 3, 4, 14, 32, 5),
          ),
        ),
      );
      expect(find.text('2026-03-04 14:32'), findsOneWidget);
    });

    testWidgets('picking a day hands nothing back until Ok', (tester) async {
      DateTime? chosen;
      await tester.pumpWidget(
        _host(
          DatePicker(
            showTime: true,
            value: DateTime(2026, 3, 4, 14, 32, 5),
            onChanged: (v) => chosen = v,
          ),
        ),
      );
      await _openPanel(tester);
      // The day grid stands before the columns, and 15 is a minute as well
      // as a day.
      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();

      // A date whose time is still being chosen is half an answer.
      expect(chosen, isNull);
      expect(find.text('OK'), findsOneWidget, reason: 'the panel stayed open');

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      // The clock it was already carrying, kept.
      expect(chosen, DateTime(2026, 3, 15, 14, 32, 5));
    });

    testWidgets('a day picked twice keeps the hour chosen in between',
        (tester) async {
      DateTime? chosen;
      await tester.pumpWidget(
        _host(
          DatePicker(
            showTime: true,
            format: 'yyyy-MM-dd HH:mm',
            value: DateTime(2026, 3, 4, 0, 0),
            onChanged: (v) => chosen = v,
          ),
        ),
      );
      await _openPanel(tester);
      // The day grid stands before the columns, and 15 is a minute as well
      // as a day.
      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();
      // The hour column. A padded figure, so no day of the month matches it,
      // and near the top of the column so it is on screen without scrolling.
      await tester.tap(find.text('03').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('16').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(chosen, DateTime(2026, 3, 16, 3, 0));
    });

    testWidgets('the footer says Now, and sets the clock too', (tester) async {
      DateTime? chosen;
      await tester.pumpWidget(
        _host(
          DatePicker(
            showTime: true,
            value: DateTime(2020, 1, 1),
            onChanged: (v) => chosen = v,
          ),
        ),
      );
      await _openPanel(tester);
      expect(find.text('Today'), findsNothing);
      await tester.tap(find.text('Now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // A footer that moved the day and left the hour at midnight would be
      // half an answer.
      expect(chosen, isNotNull);
      expect(
        chosen!.difference(DateTime.now()).abs(),
        lessThan(const Duration(minutes: 1)),
      );
    });

    // How wide the panel actually opens, whatever it is built from.
    Future<double> panelWidth(WidgetTester tester, DatePicker picker) async {
      await tester.pumpWidget(_host(picker));
      await _openPanel(tester);
      final rect = tester.getRect(
        find
            .ancestor(
              of: find.text('OK'),
              matching: find.byType(DecoratedBox),
            )
            .last,
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      return rect.width;
    }

    testWidgets('the panel measures itself rather than taking the screen',
        (tester) async {
      final one = await panelWidth(
        tester,
        DatePicker(
          showTime: true,
          format: 'yyyy-MM-dd HH',
          value: DateTime(2026, 3, 4),
        ),
      );
      final two = await panelWidth(
        tester,
        DatePicker(
          showTime: true,
          format: 'yyyy-MM-dd HH:mm',
          value: DateTime(2026, 3, 4),
        ),
      );
      final three = await panelWidth(
        tester,
        DatePicker(
          showTime: true,
          format: 'yyyy-MM-dd HH:mm:ss',
          value: DateTime(2026, 3, 4),
        ),
      );

      final screen =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(three, lessThan(screen));

      // Each further column widens the panel by exactly one column and the
      // line beside it — and nothing in the panel had to be told that.
      expect(two - one, three - two);
      expect(two - one, greaterThan(0));
    });

    testWidgets('a wider token widens the panel, with nothing told to',
        (tester) async {
      final standard = await panelWidth(
        tester,
        DatePicker(showTime: true, value: DateTime(2026, 3, 4)),
      );
      final wider = await panelWidth(
        tester,
        DatePicker(
          showTime: true,
          value: DateTime(2026, 3, 4),
          token: const DatePickerToken(timeColumnWidth: 80),
        ),
      );
      // Three columns, forty each. A panel that added its own width up from
      // a remembered number would have missed this entirely.
      expect(wider - standard, 3 * (80 - 48));
    });

    testWidgets('a footer wider than the calendar is not cut off',
        (tester) async {
      final plain = await panelWidth(
        tester,
        DatePicker(showTime: true, value: DateTime(2026, 3, 4)),
      );
      final withFooter = await panelWidth(
        tester,
        DatePicker(
          showTime: true,
          value: DateTime(2026, 3, 4),
          footerBuilder: (_) => const SizedBox(width: 900, height: 10),
        ),
      );
      // The panel is as wide as what is in it — up to what the popover has
      // room for, which is the screen less its own inset. Growing is right;
      // growing past the window would not be.
      final screen =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(withFooter, greaterThan(plain));
      expect(withFooter, lessThan(900));
      expect(withFooter, lessThanOrEqualTo(screen));
    });

    testWidgets('no time columns without showTime', (tester) async {
      await tester.pumpWidget(_host(DatePicker(value: DateTime(2026, 3, 4))));
      await _openPanel(tester);
      expect(find.text('OK'), findsNothing, reason: 'nothing to confirm');
      expect(find.text('Today'), findsOneWidget);
    });
  });
}

void _clearRaceTests() {
  group('the clear mark', () {
    Future<void> arriveAndClick(WidgetTester tester, Finder field) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Where the mark sits, worked out while the field is hovered.
      await gesture.moveTo(tester.getCenter(field));
      await tester.pumpAndSettle();
      final mark = find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == 'ClearIconPainter',
      );
      final spot = tester.getCenter(mark);

      // Away again, so nothing is hovered.
      await gesture.moveTo(const Offset(5, 5));
      await tester.pumpAndSettle();

      // And straight back onto the mark and click, without a frame between —
      // a mouse arriving from the panel above, or from the control beside it.
      await gesture.moveTo(spot);
      await gesture.down(spot);
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('is bigger than the glyph drawn in it', (tester) async {
      await tester.pumpWidget(
        _host(DatePicker(value: DateTime(2026, 3, 4))),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(DatePicker)));
      await tester.pumpAndSettle();

      final mark = find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == 'ClearIconPainter',
      );
      final glyph = tester.getSize(mark);
      final target = tester.getSize(
        find.ancestor(of: mark, matching: find.byType(GestureDetector)).first,
      );

      // Fourteen pixels is what the glyph measures, and it is not what
      // anybody can be asked to hit. The target is the height of the field;
      // its width is the slot's, so growing it costs the field nothing.
      expect(glyph.height, lessThan(20));
      expect(target.height, greaterThan(glyph.height * 1.5));
    });

    testWidgets('clears again after a date has been picked', (tester) async {
      // Clear, pick, clear. The second clear handed back null — the label
      // beside the field said so — and the box went on showing the date,
      // because the picker's own fallback value had been left holding it and
      // `value ?? _internal` reached past the null to find it.
      DateTime? value = DateTime(2026, 3, 4);
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 220,
              child: DatePicker(
                value: value,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      final mark = find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == 'ClearIconPainter',
      );
      Future<void> clear() async {
        await gesture.moveTo(tester.getCenter(find.byType(DatePicker)));
        await tester.pumpAndSettle();
        await tester.tapAt(tester.getCenter(mark));
        await tester.pumpAndSettle();
      }

      await clear();
      expect(value, isNull);

      await tester.tap(find.byType(DatePicker));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      expect(value, isNotNull);

      await clear();
      expect(value, isNull);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '',
        reason: 'the box says what the value says',
      );
    });

    testWidgets('clears on the first click, not the second', (tester) async {
      DateTime? value = DateTime(2026, 3, 4);
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => DatePicker(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await arriveAndClick(tester, find.byType(DatePicker));
      // The mark is drawn a frame after the pointer arrives; a target that
      // came and went with the paint was not there for the first click, and
      // the click opened the panel instead.
      expect(value, isNull);
    });
  });
}

void _kindTests() {
  group('what the picker collects', () {
    testWidgets('a week is taken by pressing any day in it', (tester) async {
      DateTime? chosen;
      await tester.pumpWidget(
        _host(
          DatePicker(
            picker: DatePickerKind.week,
            value: DateTime(2026, 3, 4),
            onChanged: (v) => chosen = v,
          ),
        ),
      );
      await _openPanel(tester);
      // The 12th of March 2026 is a Thursday; its week opens on the 9th.
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      expect(chosen, DateTime(2026, 3, 9));
    });

    testWidgets('a week picker marks the whole row, not one day',
        (tester) async {
      await tester.pumpWidget(
        _host(
          DatePicker(
            picker: DatePickerKind.week,
            // A Thursday, so the week runs from the 9th to the 15th.
            value: DateTime(2026, 3, 12),
          ),
        ),
      );
      await _openPanel(tester);

      Color? fillUnder(String day) {
        final box = tester.widget<AnimatedContainer>(
          find
              .ancestor(
                of: find.text(day),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );
        return (box.decoration! as BoxDecoration).color;
      }

      // One press on any of them is the same answer, so marking one and not
      // the rest would say the others were something else.
      expect(fillUnder('9'), fillUnder('12'));
      expect(fillUnder('15'), fillUnder('12'));
      expect(fillUnder('16'), isNot(fillUnder('12')));
    });

    testWidgets('a week is written as a week', (tester) async {
      await tester.pumpWidget(
        _host(
          DatePicker(
            picker: DatePickerKind.week,
            value: DateTime(2026, 3, 9),
          ),
        ),
      );
      // A week written yyyy-MM-dd would name a day and mean seven of them.
      expect(find.text('2026-W11'), findsOneWidget);
    });

    testWidgets('a quarter picker opens on its four quarters', (tester) async {
      DateTime? chosen;
      await tester.pumpWidget(
        _host(
          DatePicker(
            picker: DatePickerKind.quarter,
            value: DateTime(2026, 8, 20),
            onChanged: (v) => chosen = v,
          ),
        ),
      );
      expect(find.text('2026-Q3'), findsOneWidget);
      await _openPanel(tester);
      expect(find.text('Q1'), findsOneWidget);
      expect(find.text('Q4'), findsOneWidget);
      expect(find.text('15'), findsNothing, reason: 'no days to be had');

      await tester.tap(find.text('Q2'));
      await tester.pumpAndSettle();
      expect(chosen, DateTime(2026, 4));
    });

    testWidgets('a month picker takes a month and stops there', (tester) async {
      DateTime? chosen;
      await tester.pumpWidget(
        _host(
          DatePicker(
            picker: DatePickerKind.month,
            value: DateTime(2026, 8, 20),
            onChanged: (v) => chosen = v,
          ),
        ),
      );
      expect(find.text('2026-08'), findsOneWidget);
      await _openPanel(tester);
      expect(find.text('15'), findsNothing, reason: 'no days to be had');
      await tester.tap(find.text('Apr'));
      await tester.pumpAndSettle();
      expect(chosen, DateTime(2026, 4));
    });

    testWidgets('a year picker takes a year', (tester) async {
      DateTime? chosen;
      await tester.pumpWidget(
        _host(
          DatePicker(
            picker: DatePickerKind.year,
            value: DateTime(2026, 8, 20),
            onChanged: (v) => chosen = v,
          ),
        ),
      );
      expect(find.text('2026'), findsWidgets);
      await _openPanel(tester);
      await tester.tap(find.text('2028').last);
      await tester.pumpAndSettle();
      expect(chosen, DateTime(2028));
    });

    testWidgets('a format of your own is left alone', (tester) async {
      await tester.pumpWidget(
        _host(
          DatePicker(
            picker: DatePickerKind.month,
            format: 'MMM yyyy',
            value: DateTime(2026, 8, 20),
          ),
        ),
      );
      expect(find.text('Aug 2026'), findsOneWidget);
    });
  });

  group('a cell drawn by the caller', () {
    testWidgets('is handed the day, what the panel knows and its own mark',
        (tester) async {
      final seen = <DateCell>[];
      await tester.pumpWidget(
        _host(
          DatePicker(
            value: DateTime(2026, 3, 4),
            cellBuilder: (context, cell, child) {
              seen.add(cell);
              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  child,
                  if (cell.date.day == 12)
                    const Text('•', key: ValueKey('dot')),
                ],
              );
            },
          ),
        ),
      );
      await _openPanel(tester);

      expect(seen, hasLength(42), reason: 'six weeks, drawn by the caller');
      expect(find.byKey(const ValueKey('dot')), findsOneWidget);

      final fourth = seen.firstWhere((c) => c.date == DateTime(2026, 3, 4));
      expect(fourth.chosen, isTrue);
      expect(fourth.outside, isFalse);

      // Wrapping rather than replacing, so the cell keeps every state the
      // panel gives it for nothing.
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('a barred day says so to the caller', (tester) async {
      final blocked = <DateTime>[];
      await tester.pumpWidget(
        _host(
          DatePicker(
            value: DateTime(2026, 3, 4),
            disabledDate: (d) => d.weekday == DateTime.sunday,
            cellBuilder: (context, cell, child) {
              if (cell.disabled) blocked.add(cell.date);
              return child;
            },
          ),
        ),
      );
      await _openPanel(tester);
      expect(blocked, isNotEmpty);
      expect(blocked.every((d) => d.weekday == DateTime.sunday), isTrue);
    });
  });
}

void _spacingTests() {
  group('the air in the grid', () {
    /// The mark drawn inside the cell holding [day].
    Rect markUnder(WidgetTester tester, String day) => tester.getRect(
          find
              .ancestor(
                of: find.text(day),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );

    Future<double> gapBetweenWeeks(WidgetTester tester, double gap) async {
      await tester.pumpWidget(
        _host(
          DatePicker(
            value: DateTime(2026, 3, 4),
            token: DatePickerToken(mainAxisSpacing: gap),
          ),
        ),
      );
      await _openPanel(tester);
      // The 9th and the 16th of March 2026 stand one above the other.
      final upper = markUnder(tester, '9');
      final lower = markUnder(tester, '16');
      return lower.top - upper.bottom;
    }

    testWidgets('mainAxisSpacing is the gap between one week and the next',
        (tester) async {
      expect(
        await gapBetweenWeeks(tester, 4),
        moreOrLessEquals(4, epsilon: 0.5),
      );
    });

    testWidgets('and a wider one is wider', (tester) async {
      expect(
        await gapBetweenWeeks(tester, 12),
        moreOrLessEquals(12, epsilon: 0.5),
      );
    });

    testWidgets('the mark keeps its size, whatever the gap', (tester) async {
      await tester.pumpWidget(
        _host(
          DatePicker(
            value: DateTime(2026, 3, 4),
            token: const DatePickerToken(
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
            ),
          ),
        ),
      );
      await _openPanel(tester);

      // Added around the cell, not taken out of it: `cellWidth` and
      // `cellHeight` say how big a day is, and asking for more air parts the
      // days rather than shrinking them.
      final mark = markUnder(tester, '9');
      expect(mark.height, 24, reason: 'controlHeightSM, the default cell');
      expect(mark.width, 36, reason: 'controlHeightSM * 1.5');

      // And the grid grew by the air, which is what asking for it means.
      expect(
        tester.getRect(find.byType(DayGrid)).height,
        (24 + 15) * 7,
        reason: 'six weeks, the weekday names, and the gaps',
      );
    });

    Future<double> gapBetweenDays(WidgetTester tester, double gap) async {
      await tester.pumpWidget(
        _host(
          DatePicker(
            value: DateTime(2026, 3, 4),
            token: DatePickerToken(crossAxisSpacing: gap),
          ),
        ),
      );
      await _openPanel(tester);
      // The 9th and the 10th of March 2026 stand side by side.
      final left = markUnder(tester, '9');
      final right = markUnder(tester, '10');
      return right.left - left.right;
    }

    testWidgets('crossAxisSpacing is the gap between one day and the next',
        (tester) async {
      expect(await gapBetweenDays(tester, 4), moreOrLessEquals(4, epsilon: .5));
    });

    testWidgets('and a wider one is wider', (tester) async {
      expect(
        await gapBetweenDays(tester, 10),
        moreOrLessEquals(10, epsilon: 0.5),
      );
    });

    testWidgets('the band under a range is not cut by the gap', (tester) async {
      await tester.pumpWidget(
        _host(
          const DateRangePicker(token: DatePickerToken(crossAxisSpacing: 10)),
        ),
      );
      await tester.tap(find.byType(DateRangePicker));
      await tester.pumpAndSettle();
      await tester.tap(find.text('9').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('11').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DateRangePicker));
      await tester.pumpAndSettle();

      // The band is the box that spans the whole cell. An AnimatedContainer
      // makes a DecoratedBox of its own for the pill, which is narrower by
      // the gap, and the panel is one too — so the band is picked by its
      // width rather than by its place among the ancestors.
      // The pitch: the day and its share of the air, which is what the band
      // spans so a stretch joins up.
      const cell = 36.0 + 10; // cellWidth plus the crossAxisSpacing asked for
      Rect bandUnder(String day) {
        final boxes = find.ancestor(
          of: find.text(day).first,
          matching: find.byType(DecoratedBox),
        );
        for (final element in boxes.evaluate()) {
          final rect =
              tester.getRect(find.byElementPredicate((e) => e == element));
          if ((rect.width - cell).abs() < 0.5) return rect;
        }
        fail('no box the width of a cell stands behind $day');
      }

      // The gap is taken out of the mark, not out of the cell: a band cut
      // into pieces would stop reading as one stretch.
      final ninth = bandUnder('9');
      final tenth = bandUnder('10');
      expect(tenth.left, moreOrLessEquals(ninth.right, epsilon: 0.5));
    });
  });
}
