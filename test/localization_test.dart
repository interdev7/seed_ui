import 'package:flutter/material.dart'
    hide Badge, ThemeData, Checkbox, Radio, Switch, Tooltip, Drawer;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// A popconfirm is the shortest way to a pair of localised buttons on screen.
///
/// The provider goes above [MaterialApp], as the kit's own README and example
/// place it: a popconfirm draws into the navigator's overlay, so a provider
/// inside `home` would sit below the thing meant to read it. Theme tokens
/// reach overlays by the same route.
Widget _confirm({SeedLocalizations? locale, Locale? appLocale}) {
  final app = MaterialApp(
    navigatorKey: UiKit.navigatorKey,
    locale: appLocale,
    // Alongside Flutter's own, which is the point: the kit's delegate is one
    // more in the list, not a scheme of its own. MaterialApp refuses a
    // non-English locale without the global ones.
    localizationsDelegates: const [
      SeedLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: SeedLocalizations.supportedLocales,
    home: const Scaffold(
      body: Center(
        child: Popconfirm(title: Text('Sure?'), child: Text('trigger')),
      ),
    ),
  );
  return locale == null ? app : ConfigProvider(locale: locale, child: app);
}

/// See `popconfirm_test.dart`: `pumpAndSettle` is unusable with the kit's
/// perpetual animations.
Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('trigger'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump();
}

void main() {
  group('SeedLocalizations', () {
    test('anything left out of a language stays English', () {
      const partial = SeedLocalizations(localeName: 'xx', ok: 'Aye');
      expect(partial.ok, 'Aye');
      expect(partial.cancel, 'Cancel', reason: 'a partial one is still usable');
    });

    test('copyWith replaces a word without forking a language', () {
      final tweaked = SeedLocalizations.ru.copyWith(ok: 'Ладно');
      expect(tweaked.ok, 'Ладно');
      expect(tweaked.cancel, 'Отмена', reason: 'the rest is untouched');
      expect(SeedLocalizations.ru.ok, 'OK', reason: 'the original is const');
    });

    test('a locale is matched on its language, country and script aside', () {
      expect(SeedLocalizations.forLocale(const Locale('pt', 'BR')).localeName,
          'pt');
      expect(SeedLocalizations.forLocale(const Locale('pt', 'PT')).localeName,
          'pt');
      // Nothing the kit says differs between those, and matching the whole tag
      // would drop both to English over a distinction that does not exist.
      expect(
        SeedLocalizations.forLocale(const Locale('cy')).localeName,
        'en',
        reason: 'an unshipped language falls back rather than failing',
      );
    });

    test('every shipped language is offered as a supported locale', () {
      expect(
        SeedLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
        SeedLocalizations.byLanguage.keys.toSet(),
      );
    });

    test('two languages saying the same words are the same value', () {
      expect(SeedLocalizations.en, const SeedLocalizations());
      expect(SeedLocalizations.en, isNot(SeedLocalizations.ru));
      expect(
        SeedLocalizations.en.hashCode,
        const SeedLocalizations().hashCode,
      );
    });
  });

  group('in a widget', () {
    testWidgets('the delegate follows the app locale', (tester) async {
      await tester.pumpWidget(_confirm(appLocale: const Locale('ru')));
      await _open(tester);
      expect(find.text('Отмена'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('a locale change is picked up without a restart', (
      tester,
    ) async {
      await tester.pumpWidget(_confirm(appLocale: const Locale('en')));
      await _open(tester);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.pumpWidget(_confirm(appLocale: const Locale('tr')));
      await tester.pump();
      expect(find.text('İptal'), findsOneWidget);
    });

    testWidgets('ConfigProvider wins over the delegate', (tester) async {
      await tester.pumpWidget(
        _confirm(appLocale: const Locale('ru'), locale: SeedLocalizations.tk),
      );
      await _open(tester);
      expect(find.text('Ýatyr'), findsOneWidget);
      expect(find.text('Отмена'), findsNothing);
    });

    testWidgets('a single word can be replaced through the provider', (
      tester,
    ) async {
      await tester.pumpWidget(
        _confirm(locale: SeedLocalizations.en.copyWith(ok: 'Got it')),
      );
      await _open(tester);
      expect(find.text('Got it'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget, reason: 'the rest stands');
    });

    testWidgets('a widget property still beats the locale', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          locale: SeedLocalizations.ru,
          child: MaterialApp(
            navigatorKey: UiKit.navigatorKey,
            home: const Scaffold(
              body: Center(
                child: Popconfirm(
                  title: Text('Sure?'),
                  okText: Text('Delete'),
                  child: Text('trigger'),
                ),
              ),
            ),
          ),
        ),
      );
      await _open(tester);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Отмена'), findsOneWidget, reason: 'only ok was named');
    });

    testWidgets('with no delegate and no provider it still draws, in English', (
      tester,
    ) async {
      // The case that matters most for a widget kit: an application that never
      // wired any of this up must not crash, and must not show blanks.
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: const Scaffold(
            body: Center(
              child: Popconfirm(title: Text('Sure?'), child: Text('trigger')),
            ),
          ),
        ),
      );
      await _open(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Empty and Listy take their lines from the locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ConfigProvider(
          locale: SeedLocalizations.de,
          child: MaterialApp(
            home: Scaffold(body: Center(child: Empty())),
          ),
        ),
      );
      expect(find.text('Keine Daten'), findsOneWidget);
    });
  });
  group('figures', () {
    test('most languages leave the figures alone', () {
      expect(SeedLocalizations.en.figures('99+'), '99+');
      expect(SeedLocalizations.ru.figures('01:30'), '01:30');
      // Hebrew reads right to left but writes Latin figures.
      expect(SeedLocalizations.he.figures('42'), '42');
    });

    test('Arabic writes its own, and only the figures', () {
      expect(SeedLocalizations.ar.figures('2024'), '٢٠٢٤');
      // Separators, a plus, a slash: untouched.
      expect(SeedLocalizations.ar.figures('01:30:45'), '٠١:٣٠:٤٥');
      expect(SeedLocalizations.ar.figures('99+'), '٩٩+');
    });

    test('a language can be given other figures, or told to keep Latin', () {
      final maghreb = SeedLocalizations.ar.copyWith(
        digits: SeedLocalizations.latinDigits,
      );
      expect(maghreb.figures('2024'), '2024', reason: 'the Maghreb case');
      expect(maghreb.cancel, 'إلغاء', reason: 'still Arabic in every word');
    });

    test('a language must give exactly ten glyphs', () {
      expect(
        () => SeedLocalizations(digits: '012'),
        throwsAssertionError,
      );
    });
  });

  group('figures on screen', () {
    Widget arabic(Widget child) => ConfigProvider(
          locale: SeedLocalizations.ar,
          child: MaterialApp(home: Scaffold(body: Center(child: child))),
        );

    testWidgets('a badge counts in the language it is drawn in', (
      tester,
    ) async {
      await tester.pumpWidget(arabic(const Badge(count: 42)));
      await tester.pumpAndSettle();
      expect(find.text('٤'), findsOneWidget);
      expect(find.text('٢'), findsOneWidget);
      expect(find.text('4'), findsNothing);
    });

    testWidgets('past the overflow too, the plus left as it is', (
      tester,
    ) async {
      await tester.pumpWidget(arabic(const Badge(count: 200)));
      expect(find.text('٩٩+'), findsOneWidget);
    });

    testWidgets('and a countdown', (tester) async {
      await tester.pumpWidget(
        arabic(
          Countdown(
            target: DateTime.now().add(const Duration(hours: 1, minutes: 2)),
            format: 'HH:mm',
          ),
        ),
      );
      expect(find.text('٠١:٠٢'), findsOneWidget);
    });
  });
  testWidgets('the unit letters follow the language, as the figures do',
      (tester) async {
    Future<String> shown(SeedLocalizations locale) async {
      await tester.pumpWidget(
        ConfigProvider(
          locale: locale,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final l = context.seedLocale;
                  return Countdown(
                    target: DateTime.now().add(const Duration(hours: 5)),
                    format: 'H[${l.hourUnit}] m[${l.minuteUnit}]',
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join();
    }

    final english = await shown(SeedLocalizations.en);
    final russian = await shown(SeedLocalizations.ru);
    final chinese = await shown(SeedLocalizations.zh);

    expect(english, contains('h'));
    expect(russian, contains('ч'));
    expect(russian, isNot(contains('h')), reason: 'the English letter stayed');
    expect(chinese, contains('时'));
  });

  test('copyWith carries the unit letters through', () {
    // Changing one word must not quietly reset the rest to English.
    final tweaked = SeedLocalizations.ru.copyWith(ok: 'Ладно');
    expect(tweaked.ok, 'Ладно');
    expect(tweaked.dayUnit, SeedLocalizations.ru.dayUnit);
    expect(tweaked.hourUnit, SeedLocalizations.ru.hourUnit);
    expect(tweaked.minuteUnit, SeedLocalizations.ru.minuteUnit);
    expect(tweaked.secondUnit, SeedLocalizations.ru.secondUnit);

    final custom = SeedLocalizations.en.copyWith(minuteUnit: 'min');
    expect(custom.minuteUnit, 'min');
    expect(custom.hourUnit, 'h');
  });

  test('every language names its own unit letters', () {
    // A language that forgot them silently falls back to English letters
    // beside its own figures, which reads as a bug rather than a default.
    const languages = {
      'ru': SeedLocalizations.ru,
      'tk': SeedLocalizations.tk,
      'de': SeedLocalizations.de,
      'fr': SeedLocalizations.fr,
      'es': SeedLocalizations.es,
      'zh': SeedLocalizations.zh,
      'ja': SeedLocalizations.ja,
      'tr': SeedLocalizations.tr,
      'pt': SeedLocalizations.pt,
      'ar': SeedLocalizations.ar,
      'he': SeedLocalizations.he,
    };
    for (final entry in languages.entries) {
      final l = entry.value;
      for (final unit in [l.dayUnit, l.hourUnit, l.minuteUnit, l.secondUnit]) {
        expect(unit, isNotEmpty, reason: '${entry.key} has an empty unit');
      }
    }
    // Latin-script languages legitimately share letters with English; the
    // others must not.
    for (final code in ['ru', 'zh', 'ja', 'ar', 'he']) {
      final l = languages[code]!;
      expect(
        [l.dayUnit, l.hourUnit, l.minuteUnit, l.secondUnit],
        isNot(['d', 'h', 'm', 's']),
        reason: '$code still carries the English letters',
      );
    }
  });

  test('every language names its own calendar words', () {
    const languages = {
      'ru': SeedLocalizations.ru,
      'tk': SeedLocalizations.tk,
      'de': SeedLocalizations.de,
      'fr': SeedLocalizations.fr,
      'es': SeedLocalizations.es,
      'zh': SeedLocalizations.zh,
      'ja': SeedLocalizations.ja,
      'tr': SeedLocalizations.tr,
      'pt': SeedLocalizations.pt,
      'ar': SeedLocalizations.ar,
      'he': SeedLocalizations.he,
    };
    for (final entry in languages.entries) {
      final l = entry.value;
      expect(l.shortMonths, hasLength(12), reason: '${entry.key} months');
      expect(l.shortWeekdays, hasLength(7), reason: '${entry.key} weekdays');
      expect(
        l.shortMonths.every((m) => m.isNotEmpty),
        isTrue,
        reason: '${entry.key} has an empty month',
      );
      expect(
        l.shortWeekdays.every((d) => d.isNotEmpty),
        isTrue,
        reason: '${entry.key} has an empty weekday',
      );
      expect(
        l.firstDayOfWeek,
        inInclusiveRange(DateTime.monday, DateTime.sunday),
        reason: '${entry.key} first day',
      );
      // A language that forgot them would silently show English names beside
      // its own words, which reads as a bug rather than a default.
      expect(
        l.shortMonths,
        isNot(SeedLocalizations.englishMonths),
        reason: '${entry.key} still carries the English months',
      );
    }
  });

  test('a week does not always start on Monday', () {
    // The kit would misread a month at a glance for everyone it is wrong for.
    expect(SeedLocalizations.en.firstDayOfWeek, DateTime.monday);
    expect(SeedLocalizations.ja.firstDayOfWeek, DateTime.sunday);
    expect(SeedLocalizations.ar.firstDayOfWeek, DateTime.saturday);
  });
}
