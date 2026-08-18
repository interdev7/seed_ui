import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, Switch, Tooltip, Drawer;
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
        ConfigProvider(
          locale: SeedLocalizations.de,
          child: const MaterialApp(
            home: Scaffold(body: Center(child: Empty())),
          ),
        ),
      );
      expect(find.text('Keine Daten'), findsOneWidget);
    });
  });
}
