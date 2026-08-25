# Localization

The kit says a handful of words on its own account — a modal's `OK`, a tour's
`Next`, the line an empty list shows. Everything else on screen is your text,
translated by whatever you already use.

Twelve languages ship: `en`, `ru`, `tk`, `de`, `fr`, `es`, `zh`, `ja`, `tr`,
`pt`, `ar`, `he`.

## Working with intl, easy_localization and the rest

Register the delegate and the kit follows the app's locale, changing with it at
runtime:

```dart
MaterialApp(
  localizationsDelegates: const [
    SeedLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: SeedLocalizations.supportedLocales,
)
```

That is the whole of the integration, and it is why the kit works with `intl`,
`easy_localization`, `slang` and anything else **without depending on any of
them**. Those packages all end up doing one thing: setting the app's `Locale`.
The delegate reads that, so it never needs to know which one is in use, and
`seed_ui` keeps a `pubspec.yaml` with no dependencies in it.

`easy_localization`, for instance, needs nothing special — its
`EasyLocalization` widget supplies the locale and delegates, and the kit's
delegate goes in the same list:

```dart
EasyLocalization(
  supportedLocales: SeedLocalizations.supportedLocales,
  path: 'assets/translations',
  child: MaterialApp(
    locale: context.locale,
    localizationsDelegates: [
      SeedLocalizations.delegate,
      ...context.localizationDelegates,
    ],
    supportedLocales: context.supportedLocales,
  ),
)
```

The global Flutter delegates are not optional for a non-English locale:
`MaterialApp` refuses to build without a `MaterialLocalizations` that covers
it. That is Flutter's requirement, not the kit's.

## Without a delegate

Pass a locale to `ConfigProvider`, which is also how one subtree is put into a
different language from the rest:

```dart
ConfigProvider(
  locale: SeedLocalizations.ru,
  child: MaterialApp(...),
)
```

Put it **above** `MaterialApp`, as with the theme. Modals, popconfirms and
tooltips draw into the navigator's overlay, and a provider inside `home` would
sit below the very thing meant to read it.

## Which one wins

1. A widget property — `Popconfirm(okText: Text('Delete'))`
2. The nearest `ConfigProvider.locale`
3. Whatever the delegate resolved from the app's locale
4. English

Nothing here throws when none of it is wired up. A widget kit has to draw in
any application, so the words simply fall back to English.

## Changing a word

`copyWith` takes any subset, so a language need not be forked to change one
word:

```dart
ConfigProvider(
  locale: SeedLocalizations.en.copyWith(ok: 'Got it'),
  child: MyApp(),
)
```

## Adding a language

One `const`, passed the same way. Anything left out stays English, so a partial
translation is a usable one:

```dart
const nl = SeedLocalizations(
  localeName: 'nl',
  cancel: 'Annuleren',
  previous: 'Vorige',
  next: 'Volgende',
);
```

Pull requests adding one to the kit are welcome.

## The words

| Field | English | Where it appears |
| --- | --- | --- |
| `ok` | OK | `Modal`, `Popconfirm` |
| `cancel` | Cancel | `Modal`, `Popconfirm` |
| `previous` | Previous | `Tour` |
| `next` | Next | `Tour` |
| `finish` | Finish | `Tour`, on the last step |
| `noData` | No data | `Empty` |
| `noMoreItems` | No more items | `Listy`, at the end of a list |
| `perPage` | / page | `Pagination`, in the size picker |

## Figures

Some languages write their numbers with their own glyphs. `digits` gives the
ten, and Arabic ships the Arabic-Indic figures — what CLDR gives as the
language's default — so a badge counts `٤٢` and a countdown reads `٠١:٠٢`.

Only the figures the kit writes itself are rewritten: a badge's count, a
countdown, page numbers, a step's number. Numbers inside your own text are
yours to format.

This is glyph substitution, not number formatting. There is no grouping and no
decimal mark, because those need locale data the kit does not carry — reach
for `intl` when you need them.

The Maghreb writes Arabic with Latin figures. The kit matches on language
alone and cannot tell, so an app there says:

```dart
ConfigProvider(
  locale: SeedLocalizations.ar.copyWith(
    digits: SeedLocalizations.latinDigits,
  ),
  child: MyApp(),
)
```

## On the translations

Every word but `noMoreItems` is taken from the locale files of the library
this kit is modelled on, rather than translated here, so each language says
what its own speakers already read elsewhere. `noMoreItems` has no counterpart
there and is the one line in each language still awaiting a native reader —
corrections are welcome.

## Right-to-left

Arabic and Hebrew ship as languages. Mirroring the layout for them is a
separate matter from the words, and is not finished: see the note in the
README.

## Duration units

`dayUnit`, `hourUnit`, `minuteUnit` and `secondUnit` are the short letters a
[Countdown](data_display/countdown.md) format is built from. The kit cannot
translate a pattern you handed it, so it ships the words instead:

```dart
final l = context.seedLocale;
Countdown(target: deadline, format: 'HH[${l.hourUnit}] mm[${l.minuteUnit}]')
```
