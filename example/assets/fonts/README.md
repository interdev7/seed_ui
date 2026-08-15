# Bundled fonts

Shipped with the example so the New Year preset works offline, with no runtime
download.

| Font | Role | Licence |
| --- | --- | --- |
| Nunito | Body — everything the kit renders | SIL OFL 1.1 (`OFL-Nunito.txt`) |
| Marck Script | Handwritten greeting | SIL OFL 1.1 (`OFL-MarckScript.txt`) |
| Ruslan Display | Ornamental heading | SIL OFL 1.1 (`OFL-RuslanDisplay.txt`) |

All three carry **Latin and Cyrillic in the same file**, which is why this set
was chosen: a bilingual line such as "Merry & Bright · С Новым годом" stays in
one typeface the whole way through. Mountains of Christmas was bundled here
first and dropped for exactly this reason — its Cyrillic half fell back to the
body font mid-sentence.

`test/fonts_test.dart` asserts that coverage by reading the `cmap` table out of
each file, so a future swap cannot quietly reintroduce the gap.

## Using a font of your own

Three steps, no theme code to edit:

1. Put the file in this folder.
2. Declare the family in `example/pubspec.yaml` under `flutter: fonts:`.
3. Name it when building the theme:

```dart
newYearTheme(type: const NewYearTypography(script: 'JollySweater'))
```

Check two things first — coverage and licence.

**Coverage.** Does it carry the alphabets you ship? Add it to the map in
`test/fonts_test.dart` and the test will tell you.

**Licence.** Bundling a font into a repository is *redistribution*, which is a
stronger permission than "free to use" or even "free for commercial use". These
are the fonts from [fonts-online.ru](https://fonts-online.ru/categories/christmas-fonts)
that were looked at, as their pages state their terms:

| Font | Commercial | Redistribution | Safe to bundle |
| --- | --- | --- | --- |
| Jolly Sweater | yes | yes | yes — the page cites SIL OFL |
| Kosolapa Script | yes | yes | yes |
| Igrunok SP | yes | **no** | no — use it in an app, do not ship the file in a repo |
| Alice RA | **no** | yes | no |
| Bakinskay | — | — | no licence data on the page |
| MC Twinkle Star | — | — | no licence data on the page |
| mr_GuardianCircusG | — | — | no licence data on the page |
| Clutterful Cartoon Rus | — | — | no licence data on the page |
| PF Playskool Pro | — | — | no licence data on the page |

An aggregator's tag is not a licence document: before shipping any of these,
read the licence file that comes inside the download. None of them are bundled
here — their downloads are behind a form, and the terms above are the site's
summary rather than the author's text.

Other verified Cyrillic-capable festive faces on Google Fonts, all OFL, if you
want a different flavour without the licence homework: Yeseva One, Pacifico,
Lobster, Bad Script, Neucha, Prata, Amatic SC.
