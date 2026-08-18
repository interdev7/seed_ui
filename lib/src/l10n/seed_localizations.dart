import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';

/// The words the kit says on its own account.
///
/// Only text the components produce themselves lives here — a modal's `OK`, a
/// tour's `Next`, the line an empty list shows. Everything an application
/// writes is the application's to translate, by whatever means it already
/// uses.
///
/// ## Wiring it up
///
/// Register the delegate and the kit follows the app's locale, changing with
/// it at runtime:
///
/// ```dart
/// MaterialApp(
///   localizationsDelegates: const [
///     SeedLocalizations.delegate,
///     GlobalMaterialLocalizations.delegate,
///     ...
///   ],
///   supportedLocales: SeedLocalizations.supportedLocales,
/// )
/// ```
///
/// This is why the kit works with `intl`, `easy_localization`, `slang` and the
/// rest without depending on any of them: they all end up setting the app's
/// [Locale], and the delegate reads that. Nothing here needs to know which one
/// is in use.
///
/// ## Without a delegate
///
/// Pass one to [ConfigProvider] instead, which is also how a single subtree is
/// put into another language:
///
/// ```dart
/// ConfigProvider(locale: SeedLocalizations.ru, child: MyApp())
/// ```
///
/// A widget kit has to draw in any application, so nothing here throws when
/// neither is present: the words fall back to English.
///
/// ## Changing a word, or adding a language
///
/// [copyWith] takes any subset, so a whole language need not be forked to
/// change one word:
///
/// ```dart
/// ConfigProvider(
///   locale: SeedLocalizations.en.copyWith(ok: 'Got it'),
///   child: MyApp(),
/// )
/// ```
///
/// A new language is one `const SeedLocalizations(...)`, passed the same way.
@immutable
class SeedLocalizations {
  /// Creates a set of words. Anything left out stays English, so a partial
  /// translation is a usable one.
  const SeedLocalizations({
    this.localeName = 'en',
    this.ok = 'OK',
    this.cancel = 'Cancel',
    this.previous = 'Previous',
    this.next = 'Next',
    this.finish = 'Finish',
    this.noData = 'No data',
    this.noMoreItems = 'No more items',
    this.perPage = '/ page',
    this.digits = latinDigits,
  }) : assert(
          digits.length == 10,
          'digits must give exactly one glyph for each of 0 to 9',
        );

  /// Which language this is, for identifying it. Not used for matching.
  final String localeName;

  /// Confirms a modal or a popconfirm.
  final String ok;

  /// Dismisses one.
  final String cancel;

  /// A tour's step backwards.
  final String previous;

  /// A tour's step forwards.
  final String next;

  /// The last step of a tour, in place of [next].
  final String finish;

  /// What an empty list or table says.
  final String noData;

  /// What a list says once it has been scrolled to its end.
  final String noMoreItems;

  /// Follows a page size in a pagination's size picker: `20 / page`.
  final String perPage;

  /// The ten glyphs for 0 to 9, in order.
  ///
  /// Only the figures the kit writes itself are rewritten — a badge's count, a
  /// countdown, page numbers. Numbers inside your own text are yours.
  ///
  /// This is a glyph substitution, not number formatting: no grouping, no
  /// decimal marks, nothing needing locale data the kit does not carry.
  ///
  /// Arabic ships the Arabic-Indic figures, which is what CLDR gives as the
  /// default for the language. The Maghreb writes Arabic with Latin figures,
  /// and since the kit matches on language alone it cannot tell: an app there
  /// wants `copyWith(digits: SeedLocalizations.latinDigits)`.
  final String digits;

  /// `0123456789`. What most languages use, and the default.
  static const String latinDigits = '0123456789';

  /// `٠١٢٣٤٥٦٧٨٩`, used across much of the Arabic-writing world.
  static const String arabicIndicDigits = '٠١٢٣٤٥٦٧٨٩';

  /// The glyph this language writes [d] with. [d] must be 0 to 9.
  String digit(int d) => digits.characters.elementAt(d);

  /// Rewrites the ASCII figures in [text] in this language's own, leaving
  /// everything else — separators, a `+`, a `/` — as it stands.
  String figures(String text) {
    if (digits == latinDigits) return text;
    final out = StringBuffer();
    for (final ch in text.codeUnits) {
      out.write(
        ch >= 0x30 && ch <= 0x39 ? digit(ch - 0x30) : String.fromCharCode(ch),
      );
    }
    return out.toString();
  }

  /// A copy with the given words replaced.
  SeedLocalizations copyWith({
    String? localeName,
    String? ok,
    String? cancel,
    String? previous,
    String? next,
    String? finish,
    String? noData,
    String? noMoreItems,
    String? perPage,
    String? digits,
  }) =>
      SeedLocalizations(
        localeName: localeName ?? this.localeName,
        ok: ok ?? this.ok,
        cancel: cancel ?? this.cancel,
        previous: previous ?? this.previous,
        next: next ?? this.next,
        finish: finish ?? this.finish,
        noData: noData ?? this.noData,
        noMoreItems: noMoreItems ?? this.noMoreItems,
        perPage: perPage ?? this.perPage,
        digits: digits ?? this.digits,
      );

  @override
  bool operator ==(Object other) =>
      other is SeedLocalizations &&
      other.localeName == localeName &&
      other.ok == ok &&
      other.cancel == cancel &&
      other.previous == previous &&
      other.next == next &&
      other.finish == finish &&
      other.noData == noData &&
      other.noMoreItems == noMoreItems &&
      other.perPage == perPage &&
      other.digits == digits;

  @override
  int get hashCode => Object.hash(
        localeName,
        ok,
        cancel,
        previous,
        next,
        finish,
        noData,
        noMoreItems,
      );

  // ===========================================================================
  // The languages that ship with the kit.
  //
  // Every word but `noMoreItems` is taken from Ant Design's own locale files
  // rather than translated here, so the kit says what the library it is
  // modelled on says. `noMoreItems` has no counterpart there and is the one
  // line in each language awaiting a native reader.
  // ===========================================================================

  /// English. The fallback for anything unmatched.
  static const SeedLocalizations en = SeedLocalizations();

  /// Russian.
  static const SeedLocalizations ru = SeedLocalizations(
    localeName: 'ru',
    cancel: 'Отмена',
    previous: 'Назад',
    next: 'Далее',
    finish: 'Завершить',
    noData: 'Нет данных',
    noMoreItems: 'Больше ничего нет',
    perPage: '/ стр.',
  );

  /// Turkmen.
  static const SeedLocalizations tk = SeedLocalizations(
    localeName: 'tk',
    ok: 'Bolýar',
    cancel: 'Ýatyr',
    previous: 'Öňki',
    next: 'Indiki',
    finish: 'Tamamla',
    noData: 'Maglumat ýok',
    noMoreItems: 'Başga zat ýok',
    perPage: '/ sahypa',
  );

  /// German.
  static const SeedLocalizations de = SeedLocalizations(
    localeName: 'de',
    cancel: 'Abbrechen',
    previous: 'Zurück',
    next: 'Weiter',
    finish: 'Fertig',
    noData: 'Keine Daten',
    noMoreItems: 'Keine weiteren Einträge',
    perPage: '/ Seite',
  );

  /// French.
  static const SeedLocalizations fr = SeedLocalizations(
    localeName: 'fr',
    cancel: 'Annuler',
    previous: 'Étape précédente',
    next: 'Étape suivante',
    finish: 'Fin de la visite guidée',
    noData: 'Aucune donnée',
    noMoreItems: 'Aucun élément supplémentaire',
    perPage: '/ page',
  );

  /// Spanish.
  static const SeedLocalizations es = SeedLocalizations(
    localeName: 'es',
    ok: 'Aceptar',
    cancel: 'Cancelar',
    previous: 'Anterior',
    next: 'Siguiente',
    finish: 'Finalizar',
    noData: 'Sin datos',
    noMoreItems: 'No hay más elementos',
    perPage: '/ página',
  );

  /// Chinese, simplified.
  static const SeedLocalizations zh = SeedLocalizations(
    localeName: 'zh',
    ok: '确定',
    cancel: '取消',
    previous: '上一步',
    next: '下一步',
    finish: '结束导览',
    noData: '暂无数据',
    noMoreItems: '没有更多了',
    perPage: '条/页',
  );

  /// Japanese.
  static const SeedLocalizations ja = SeedLocalizations(
    localeName: 'ja',
    cancel: 'キャンセル',
    previous: '前の',
    next: '次',
    finish: '仕上げる',
    noData: 'データなし',
    noMoreItems: 'これ以上ありません',
    perPage: '件/ページ',
  );

  /// Turkish.
  static const SeedLocalizations tr = SeedLocalizations(
    localeName: 'tr',
    ok: 'Tamam',
    cancel: 'İptal',
    previous: 'Önceki',
    next: 'Sonraki',
    finish: 'Bitir',
    noData: 'Veri yok',
    noMoreItems: 'Başka öğe yok',
    perPage: '/ sayfa',
  );

  /// Portuguese.
  static const SeedLocalizations pt = SeedLocalizations(
    localeName: 'pt',
    cancel: 'Cancelar',
    previous: 'Anterior',
    next: 'Próximo',
    finish: 'Finalizar',
    noData: 'Sem conteúdo',
    noMoreItems: 'Não há mais itens',
    perPage: '/ página',
  );

  /// Arabic. Read right to left.
  static const SeedLocalizations ar = SeedLocalizations(
    localeName: 'ar',
    ok: 'تأكيد',
    cancel: 'إلغاء',
    previous: 'السابق',
    next: 'التالي',
    finish: 'إنهاء',
    noData: 'لا توجد بيانات',
    noMoreItems: 'لا مزيد من العناصر',
    perPage: '/ صفحة',
    digits: arabicIndicDigits,
  );

  /// Hebrew. Read right to left.
  static const SeedLocalizations he = SeedLocalizations(
    localeName: 'he',
    ok: 'אישור',
    cancel: 'ביטול',
    previous: 'הקודם',
    next: 'הבא',
    finish: 'סיום',
    noData: 'אין נתונים',
    noMoreItems: 'אין פריטים נוספים',
    perPage: '/ עמוד',
  );

  /// Every language the kit ships, by language code.
  static const Map<String, SeedLocalizations> byLanguage = {
    'en': en,
    'ru': ru,
    'tk': tk,
    'de': de,
    'fr': fr,
    'es': es,
    'zh': zh,
    'ja': ja,
    'tr': tr,
    'pt': pt,
    'ar': ar,
    'he': he,
  };

  /// For `MaterialApp.supportedLocales`.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ru'),
    Locale('tk'),
    Locale('de'),
    Locale('fr'),
    Locale('es'),
    Locale('zh'),
    Locale('ja'),
    Locale('tr'),
    Locale('pt'),
    Locale('ar'),
    Locale('he'),
  ];

  /// The words for [locale], falling back to [en].
  ///
  /// Matched on the language alone. A country or script tells the kit nothing
  /// it needs — none of these seven words differs between `pt_BR` and `pt_PT`
  /// — and matching on the whole tag would drop such a locale to English over
  /// a distinction that does not exist here.
  static SeedLocalizations forLocale(Locale locale) =>
      byLanguage[locale.languageCode] ?? en;

  /// The words in scope, from the delegate.
  ///
  /// Falls back to [en] when the delegate was never registered, rather than
  /// throwing: a widget kit has to draw in any application, wired up or not.
  ///
  /// Prefer `context.seedLocale`, which also honours [ConfigProvider].
  static SeedLocalizations of(BuildContext context) =>
      Localizations.of<SeedLocalizations>(context, SeedLocalizations) ?? en;

  /// Follows the app's locale. See the class doc.
  static const LocalizationsDelegate<SeedLocalizations> delegate =
      _SeedLocalizationsDelegate();
}

class _SeedLocalizationsDelegate
    extends LocalizationsDelegate<SeedLocalizations> {
  const _SeedLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      SeedLocalizations.byLanguage.containsKey(locale.languageCode);

  // Synchronous on purpose: an asynchronous load would draw one frame with no
  // words in it, and the words are already here as constants.
  @override
  Future<SeedLocalizations> load(Locale locale) =>
      SynchronousFuture(SeedLocalizations.forLocale(locale));

  @override
  bool shouldReload(_SeedLocalizationsDelegate old) => false;
}
