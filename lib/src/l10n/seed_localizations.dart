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
    this.reset = 'Reset',
    this.search = 'Search',
    this.noMoreItems = 'No more items',
    this.perPage = '/ page',
    this.selectTime = 'Select time',
    this.selectDate = 'Select date',
    this.today = 'Today',
    this.shortMonths = englishMonths,
    this.shortWeekdays = englishWeekdays,
    this.firstDayOfWeek = DateTime.monday,
    this.now = 'Now',
    this.am = 'AM',
    this.pm = 'PM',
    this.dayUnit = 'd',
    this.hourUnit = 'h',
    this.minuteUnit = 'm',
    this.secondUnit = 's',
    this.digits = latinDigits,
  }) : assert(
          digits.length == 10,
          'digits must give exactly one glyph for each of 0 to 9',
        );

  /// Which language this is, for identifying it. Not used for matching.
  final String localeName;

  /// Clears a `Table` column's filter menu, next to [ok] which applies it.
  final String reset;

  /// Placeholder of the field that narrows a `Table` column's filter menu.
  final String search;

  /// Placeholder of an empty `TimePicker`.
  final String selectTime;

  /// The English month abbreviations, used when a language says nothing.
  static const List<String> englishMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// The English weekday abbreviations, from Monday.
  static const List<String> englishWeekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Placeholder of an empty `DatePicker`.
  final String selectDate;

  /// Jumps a `DatePicker` to the current day.
  final String today;

  /// The twelve months, shortened, from January.
  ///
  /// Short forms only: a calendar header has one cell's worth of room, and
  /// every date library ships the same abbreviations rather than the full
  /// names.
  final List<String> shortMonths;

  /// The seven weekdays, shortened, from Monday — the order
  /// [DateTime.weekday] counts in.
  final List<String> shortWeekdays;

  /// Which day a week starts on, as [DateTime.monday] through
  /// [DateTime.sunday].
  ///
  /// Most of the world starts on Monday; the United States and much of the
  /// Americas start on Sunday, and several Arabic-speaking countries on
  /// Saturday. A calendar that always led with Monday would misread a month at
  /// a glance for the people it is wrong for.
  final int firstDayOfWeek;

  /// Jumps a `TimePicker` to the current time.
  final String now;

  /// The first half of the day, on a 12-hour clock.
  ///
  /// Used only by a format naming `a` or `A`. Languages that never write a
  /// 12-hour clock keep the Latin letters, which is what their own software
  /// shows when a 12-hour format is forced.
  final String am;

  /// The second half of the day, on a 12-hour clock. See [am].
  final String pm;

  /// Short unit letters for a duration, as a [Countdown] format writes them.
  ///
  /// A `format` is a pattern the app owns, so the kit cannot translate one
  /// that was handed to it. These are the words to build one from:
  ///
  /// ```dart
  /// final l = context.seedLocale;
  /// Countdown(
  ///   target: deadline,
  ///   format: 'D[${l.dayUnit}] HH[${l.hourUnit}] mm[${l.minuteUnit}]',
  /// )
  /// ```
  ///
  /// Short forms, because a countdown is read at a glance and a spelled-out
  /// "minutes" would be wider than the figure it labels.
  final String dayUnit;

  /// Short unit letter for hours. See [dayUnit].
  final String hourUnit;

  /// Short unit letter for minutes. See [dayUnit].
  final String minuteUnit;

  /// Short unit letter for seconds. See [dayUnit].
  final String secondUnit;

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
    String? selectTime,
    String? selectDate,
    String? today,
    List<String>? shortMonths,
    List<String>? shortWeekdays,
    int? firstDayOfWeek,
    String? now,
    String? am,
    String? pm,
    String? dayUnit,
    String? hourUnit,
    String? minuteUnit,
    String? secondUnit,
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
        selectTime: selectTime ?? this.selectTime,
        selectDate: selectDate ?? this.selectDate,
        today: today ?? this.today,
        shortMonths: shortMonths ?? this.shortMonths,
        shortWeekdays: shortWeekdays ?? this.shortWeekdays,
        firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
        now: now ?? this.now,
        am: am ?? this.am,
        pm: pm ?? this.pm,
        dayUnit: dayUnit ?? this.dayUnit,
        hourUnit: hourUnit ?? this.hourUnit,
        minuteUnit: minuteUnit ?? this.minuteUnit,
        secondUnit: secondUnit ?? this.secondUnit,
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
      other.selectTime == selectTime &&
      other.selectDate == selectDate &&
      other.today == today &&
      other.firstDayOfWeek == firstDayOfWeek &&
      other.now == now &&
      other.am == am &&
      other.pm == pm &&
      other.dayUnit == dayUnit &&
      other.hourUnit == hourUnit &&
      other.minuteUnit == minuteUnit &&
      other.secondUnit == secondUnit &&
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
  // Every word but `noMoreItems` is taken from the locale files of the
  // library this kit is modelled on, rather than translated here, so each
  // language says what its own speakers already read elsewhere.
  // `noMoreItems` has no counterpart there and is the one line in each
  // language awaiting a native reader.
  // ===========================================================================

  /// English. The fallback for anything unmatched.
  static const SeedLocalizations en = SeedLocalizations();

  /// Russian.
  static const SeedLocalizations ru = SeedLocalizations(
    localeName: 'ru',
    selectDate: 'Выберите дату',
    today: 'Сегодня',
    firstDayOfWeek: DateTime.monday,
    shortMonths: [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ],
    shortWeekdays: [
      'пн',
      'вт',
      'ср',
      'чт',
      'пт',
      'сб',
      'вс',
    ],
    selectTime: 'Выберите время',
    now: 'Сейчас',
    am: 'AM',
    pm: 'PM',
    dayUnit: 'д',
    hourUnit: 'ч',
    minuteUnit: 'м',
    secondUnit: 'с',
    cancel: 'Отмена',
    previous: 'Назад',
    next: 'Далее',
    finish: 'Завершить',
    noData: 'Нет данных',
    reset: 'Сбросить',
    search: 'Поиск',
    noMoreItems: 'Больше ничего нет',
    perPage: '/ стр.',
  );

  /// Turkmen.
  static const SeedLocalizations tk = SeedLocalizations(
    localeName: 'tk',
    selectDate: 'Senäni saýlaň',
    today: 'Şu gün',
    firstDayOfWeek: DateTime.monday,
    shortMonths: [
      'ýan',
      'few',
      'mart',
      'apr',
      'maý',
      'iýun',
      'iýul',
      'awg',
      'sen',
      'okt',
      'noý',
      'dek',
    ],
    shortWeekdays: [
      'duş',
      'siş',
      'çar',
      'pen',
      'ann',
      'şen',
      'ýek',
    ],
    selectTime: 'Wagty saýlaň',
    now: 'Häzir',
    am: 'AM',
    pm: 'PM',
    dayUnit: 'g',
    hourUnit: 'sag',
    minuteUnit: 'min',
    secondUnit: 'sek',
    ok: 'Bolýar',
    cancel: 'Ýatyr',
    previous: 'Öňki',
    next: 'Indiki',
    finish: 'Tamamla',
    noData: 'Maglumat ýok',
    reset: 'Arassala',
    search: 'Gözleg',
    noMoreItems: 'Başga zat ýok',
    perPage: '/ sahypa',
  );

  /// German.
  static const SeedLocalizations de = SeedLocalizations(
    localeName: 'de',
    selectDate: 'Datum wählen',
    today: 'Heute',
    firstDayOfWeek: DateTime.monday,
    shortMonths: [
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez',
    ],
    shortWeekdays: [
      'Mo',
      'Di',
      'Mi',
      'Do',
      'Fr',
      'Sa',
      'So',
    ],
    selectTime: 'Zeit auswählen',
    now: 'Jetzt',
    am: 'AM',
    pm: 'PM',
    dayUnit: 'T',
    hourUnit: 'Std',
    minuteUnit: 'Min',
    secondUnit: 'Sek',
    cancel: 'Abbrechen',
    previous: 'Zurück',
    next: 'Weiter',
    finish: 'Fertig',
    noData: 'Keine Daten',
    reset: 'Zurücksetzen',
    search: 'Suchen',
    noMoreItems: 'Keine weiteren Einträge',
    perPage: '/ Seite',
  );

  /// French.
  static const SeedLocalizations fr = SeedLocalizations(
    localeName: 'fr',
    selectDate: 'Sélectionner une date',
    today: 'Aujourd\'hui',
    firstDayOfWeek: DateTime.monday,
    shortMonths: [
      'janv',
      'févr',
      'mars',
      'avr',
      'mai',
      'juin',
      'juil',
      'août',
      'sept',
      'oct',
      'nov',
      'déc',
    ],
    shortWeekdays: [
      'lun',
      'mar',
      'mer',
      'jeu',
      'ven',
      'sam',
      'dim',
    ],
    selectTime: 'Sélectionner l\'heure',
    now: 'Maintenant',
    am: 'AM',
    pm: 'PM',
    dayUnit: 'j',
    hourUnit: 'h',
    minuteUnit: 'min',
    secondUnit: 's',
    cancel: 'Annuler',
    previous: 'Étape précédente',
    next: 'Étape suivante',
    finish: 'Fin de la visite guidée',
    noData: 'Aucune donnée',
    reset: 'Réinitialiser',
    search: 'Rechercher',
    noMoreItems: 'Aucun élément supplémentaire',
    perPage: '/ page',
  );

  /// Spanish.
  static const SeedLocalizations es = SeedLocalizations(
    localeName: 'es',
    selectDate: 'Seleccionar fecha',
    today: 'Hoy',
    firstDayOfWeek: DateTime.monday,
    shortMonths: [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ],
    shortWeekdays: [
      'lun',
      'mar',
      'mié',
      'jue',
      'vie',
      'sáb',
      'dom',
    ],
    selectTime: 'Seleccionar hora',
    now: 'Ahora',
    am: 'AM',
    pm: 'PM',
    dayUnit: 'd',
    hourUnit: 'h',
    minuteUnit: 'min',
    secondUnit: 's',
    ok: 'Aceptar',
    cancel: 'Cancelar',
    previous: 'Anterior',
    next: 'Siguiente',
    finish: 'Finalizar',
    noData: 'Sin datos',
    reset: 'Restablecer',
    search: 'Buscar',
    noMoreItems: 'No hay más elementos',
    perPage: '/ página',
  );

  /// Chinese, simplified.
  static const SeedLocalizations zh = SeedLocalizations(
    localeName: 'zh',
    selectDate: '请选择日期',
    today: '今天',
    firstDayOfWeek: DateTime.monday,
    shortMonths: [
      '1月',
      '2月',
      '3月',
      '4月',
      '5月',
      '6月',
      '7月',
      '8月',
      '9月',
      '10月',
      '11月',
      '12月',
    ],
    shortWeekdays: [
      '一',
      '二',
      '三',
      '四',
      '五',
      '六',
      '日',
    ],
    selectTime: '请选择时间',
    now: '此刻',
    am: '上午',
    pm: '下午',
    dayUnit: '天',
    hourUnit: '时',
    minuteUnit: '分',
    secondUnit: '秒',
    ok: '确定',
    cancel: '取消',
    previous: '上一步',
    next: '下一步',
    finish: '结束导览',
    noData: '暂无数据',
    reset: '重置',
    search: '搜索',
    noMoreItems: '没有更多了',
    perPage: '条/页',
  );

  /// Japanese.
  static const SeedLocalizations ja = SeedLocalizations(
    localeName: 'ja',
    selectDate: '日付を選択',
    today: '今日',
    firstDayOfWeek: DateTime.sunday,
    shortMonths: [
      '1月',
      '2月',
      '3月',
      '4月',
      '5月',
      '6月',
      '7月',
      '8月',
      '9月',
      '10月',
      '11月',
      '12月',
    ],
    shortWeekdays: [
      '月',
      '火',
      '水',
      '木',
      '金',
      '土',
      '日',
    ],
    selectTime: '時間を選択',
    now: '現在',
    am: '午前',
    pm: '午後',
    dayUnit: '日',
    hourUnit: '時',
    minuteUnit: '分',
    secondUnit: '秒',
    cancel: 'キャンセル',
    previous: '前の',
    next: '次',
    finish: '仕上げる',
    noData: 'データなし',
    reset: 'リセット',
    search: '検索',
    noMoreItems: 'これ以上ありません',
    perPage: '件/ページ',
  );

  /// Turkish.
  static const SeedLocalizations tr = SeedLocalizations(
    localeName: 'tr',
    selectDate: 'Tarih seçin',
    today: 'Bugün',
    firstDayOfWeek: DateTime.monday,
    shortMonths: [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ],
    shortWeekdays: [
      'Pzt',
      'Sal',
      'Çar',
      'Per',
      'Cum',
      'Cmt',
      'Paz',
    ],
    selectTime: 'Saat seçin',
    now: 'Şimdi',
    am: 'ÖÖ',
    pm: 'ÖS',
    dayUnit: 'g',
    hourUnit: 'sa',
    minuteUnit: 'dk',
    secondUnit: 'sn',
    ok: 'Tamam',
    cancel: 'İptal',
    previous: 'Önceki',
    next: 'Sonraki',
    finish: 'Bitir',
    noData: 'Veri yok',
    reset: 'Sıfırla',
    search: 'Ara',
    noMoreItems: 'Başka öğe yok',
    perPage: '/ sayfa',
  );

  /// Portuguese.
  static const SeedLocalizations pt = SeedLocalizations(
    localeName: 'pt',
    selectDate: 'Selecionar data',
    today: 'Hoje',
    firstDayOfWeek: DateTime.sunday,
    shortMonths: [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ],
    shortWeekdays: [
      'seg',
      'ter',
      'qua',
      'qui',
      'sex',
      'sáb',
      'dom',
    ],
    selectTime: 'Selecionar hora',
    now: 'Agora',
    am: 'AM',
    pm: 'PM',
    dayUnit: 'd',
    hourUnit: 'h',
    minuteUnit: 'min',
    secondUnit: 's',
    cancel: 'Cancelar',
    previous: 'Anterior',
    next: 'Próximo',
    finish: 'Finalizar',
    noData: 'Sem conteúdo',
    reset: 'Redefinir',
    search: 'Pesquisar',
    noMoreItems: 'Não há mais itens',
    perPage: '/ página',
  );

  /// Arabic. Read right to left.
  static const SeedLocalizations ar = SeedLocalizations(
    localeName: 'ar',
    selectDate: 'اختر التاريخ',
    today: 'اليوم',
    firstDayOfWeek: DateTime.saturday,
    shortMonths: [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ],
    shortWeekdays: [
      'اثن',
      'ثلا',
      'أرب',
      'خمي',
      'جمع',
      'سبت',
      'أحد',
    ],
    selectTime: 'اختر الوقت',
    now: 'الآن',
    am: 'ص',
    pm: 'م',
    dayUnit: 'ي',
    hourUnit: 'س',
    minuteUnit: 'د',
    secondUnit: 'ث',
    ok: 'تأكيد',
    cancel: 'إلغاء',
    previous: 'السابق',
    next: 'التالي',
    finish: 'إنهاء',
    noData: 'لا توجد بيانات',
    reset: 'إعادة تعيين',
    search: 'بحث',
    noMoreItems: 'لا مزيد من العناصر',
    perPage: '/ صفحة',
    digits: arabicIndicDigits,
  );

  /// Hebrew. Read right to left.
  static const SeedLocalizations he = SeedLocalizations(
    localeName: 'he',
    selectDate: 'בחר תאריך',
    today: 'היום',
    firstDayOfWeek: DateTime.sunday,
    shortMonths: [
      'ינו',
      'פבר',
      'מרץ',
      'אפר',
      'מאי',
      'יונ',
      'יול',
      'אוג',
      'ספט',
      'אוק',
      'נוב',
      'דצמ',
    ],
    shortWeekdays: [
      'ב',
      'ג',
      'ד',
      'ה',
      'ו',
      'ש',
      'א',
    ],
    selectTime: 'בחר שעה',
    now: 'עכשיו',
    am: 'AM',
    pm: 'PM',
    dayUnit: 'י',
    hourUnit: 'ש',
    minuteUnit: 'ד',
    secondUnit: 'שנ',
    ok: 'אישור',
    cancel: 'ביטול',
    previous: 'הקודם',
    next: 'הבא',
    finish: 'סיום',
    noData: 'אין נתונים',
    reset: 'איפוס',
    search: 'חיפוש',
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
