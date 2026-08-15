# Theming

The kit has no hard-coded colors or sizes. Everything components draw comes
from a `Token`, which is derived from a handful of seed values.

```code
SeedToken  →  Token.derive()  →  Token  →  components
   (inputs)          (algorithm)          (values)
```

## Seeds

`SeedToken` is what you set. Every field has a default, so override only
what you care about.

| Field           | Default   | Purpose                                               |
| --------------- | --------- | ----------------------------------------------------- |
| `colorPrimary`  | `#1677FF` | Accent for primary actions and links                  |
| `colorSuccess`  | `#52C41A` | Success status                                        |
| `colorWarning`  | `#FAAD14` | Warning status                                        |
| `colorError`    | `#FF4D4F` | Error status and danger actions                       |
| `colorInfo`     | `#1677FF` | Informational status                                  |
| `colorTextBase` | `#000000` | Base the text, border, divider and fill ramps         |
| `colorBgBase`   | `#FFFFFF` | Base the surfaces are built from (see below)          |
| `fontFamily`    | `null`    | Font for all kit text; null uses the platform default |
| `fontSize`      | `14`      | Base font size; other sizes are relative to it        |
| `borderRadius`  | `6`       | Base corner radius                                    |
| `sizeUnit`      | `4`       | Base spacing unit                                     |
| `controlHeight` | `32`      | Height of a medium control                            |
| `lineWidth`     | `1`       | Border thickness                                      |

### Tinting the surfaces

By default the kit paints neutral surfaces — white panels on `#f5f5f5`,
`#141414` panels on black — whatever the accent colours are. Name a
`colorBgBase` of your own and the surfaces follow it instead: panels take that
colour, the page sits a touch deeper, floating layers a touch lighter, and the
tinted accent shades are blended into it so a `bg` fill matches the page it
lands on.

```dart
// A warm, paper-coloured light theme.
ThemeData(
  token: const SeedToken(
    colorBgBase: Color(0xFFFFFCF6),
    colorTextBase: Color(0xFF2A1D18),
  ),
)
```

A complete worked preset — palette, per-component tokens and bundled type —
lives in the example app at `example/lib/theme/new_year_theme.dart`.

`colorTextBase` does more than colour text: every divider, border, hover and
fill is that colour at some alpha. A warm brown ink is what makes a whole theme
read as warm without naming a single divider.

Two rules keep this from surprising anyone:

- The background is only honoured when it is on the same side as the scheme. A
  light `colorBgBase` with `dark: true` would paint a dark app white, so the
  classic dark surfaces stand in instead.
- A dark theme normally builds its text ramp from white. A `colorTextBase` that
  is *already* light is kept, so an off-white ink carries its warmth through.

```dart
ConfigProvider(
  theme: ThemeData(
    token: const SeedToken(
      colorPrimary: Color(0xFFEB2F96),
      borderRadius: 2,
      controlHeight: 36,
    ),
  ),
  child: const MyApp(),
)
```

## Derived tokens

`Token` is what components read. It is produced by `Token.derive()`
and never constructed by hand.

### Color groups

Each semantic color expands into a `ColorGroup` of ten shades, so a status
color stays recognisable whether it is a fill, an outline or a label:

| Member                            | Typical use                               |
| --------------------------------- | ----------------------------------------- |
| `bg`, `bgHover`                   | Tinted backgrounds                        |
| `border`, `borderHover`           | Outlines                                  |
| `hover`, `base`, `active`         | Interactive fills, keyed to pointer state |
| `text`, `textHover`, `textActive` | Colored labels                            |

```dart
final token = context.softToken;
Container(color: token.error.bg, child: Text('!', style: TextStyle(color: token.error.text)));
```

### Neutrals

Text, borders, surfaces and fills each form a ramp from most to least
prominent:

- **Text** — `colorText`, `colorTextSecondary`, `colorTextTertiary`,
  `colorTextQuaternary`
- **Borders** — `colorBorder`, `colorBorderSecondary`, `colorSplit`
- **Surfaces** — `colorBgContainer` (cards), `colorBgElevated` (floating
  layers), `colorBgLayout` (page), `colorBgSpotlight`, `colorBgMask` (scrims)
- **Fills** — `colorFill`, `colorFillSecondary`, `colorFillTertiary`,
  `colorFillQuaternary`

### Sizing

Spacing steps are multiples of `sizeUnit`:

| Token     | Default |
| --------- | ------- |
| `sizeXXS` | 4       |
| `sizeXS`  | 8       |
| `sizeSM`  | 12      |
| `size`    | 16      |
| `sizeMD`  | 20      |
| `sizeLG`  | 24      |
| `sizeXL`  | 32      |

Control heights: `controlHeightSM` (24), `controlHeight` (32),
`controlHeightLG` (40).

Radii: `borderRadiusXS` (2), `borderRadiusSM` (4), `borderRadius` (6),
`borderRadiusLG` (8).

### Typography

`fontSizeSM` (12), `fontSize` (14), `fontSizeLG` (16), `fontSizeXL` (20),
plus `lineHeight` and `fontFamily`.

**Fonts.** Both `fontFamily` and `fontFamilyFallback` default to null, and on
every platform that is the right choice: the OS UI font — San Francisco on
Apple, Roboto on Android, Segoe UI on Windows — is exactly what a CSS
`-apple-system` / `BlinkMacSystemFont` stack resolves to, and it already
covers ordinary text and its own emoji.

Do not port a full CSS font stack here. It relies on `-apple-system`
winning first, which has no Flutter equivalent: with a null primary Flutter
picks the first *named* fallback that happens to exist — Helvetica Neue on
Apple — instead of the real system font, shifting every label's metrics. Even
an emoji-only fallback can make the shaper render spaces from the wrong font,
widening the gaps between words. So the default carries no fallback at all.

Set your own font only when you have bundled one:

```dart
SeedToken(fontFamily: 'Inter')
SeedToken(fontFamily: 'Inter', fontFamilyFallback: ['Noto Sans CJK'])
```

A display face — a script, a hand-lettered holiday font — is a different job:
charming in one heading, unreadable in a form. Keep it out of the seed and
apply it by hand where it belongs, naming the body face as its fallback so a
script the display font lacks still renders:

```dart
// The seed carries the readable face…
SeedToken(fontFamily: 'Nunito')

// …and a heading opts into the festive one.
TextStyle(
  fontFamily: 'MountainsOfChristmas',
  fontFamilyFallback: const ['Nunito'],
  fontSize: 34,
)
```

That fallback is not decoration: most Latin display fonts carry no Cyrillic or
CJK, and without it those headings come out as empty boxes.

Better still, pick a display face that covers the scripts you actually ship. A
fallback rescues a heading from blank boxes, but it still changes typeface
mid-sentence — obvious in a bilingual line. The example's preset bundles Marck
Script and Ruslan Display for that reason, and its `test/fonts_test.dart` reads
the `cmap` table of each bundled file to prove the coverage rather than trusting
the font's description.

> **Note on `lineHeight`.** Applying it to short single-line labels shrink-wraps
> the line box around the font's metrics and visibly offsets glyphs against
> adjacent icons. Use it for paragraphs, not for button labels or toast text.

#### Animating a fill

The neutral fills — `colorFill`, `colorFillSecondary`, `colorFillTertiary`,
`colorFillQuaternary` — are a few per cent of the text colour, so they tint
whatever is behind them. That is right for a static surface and wrong for an
animated one: lerping one of them to an opaque colour runs the midpoint through
a half-transparent dark grey, which reads as a flash.

Composite before animating, and both ends of the transition stay light:

```dart
Color.alphaBlend(token.colorFillTertiary, token.colorBgContainer)
```

`Button` does this for its disabled fill and `Steps` for its markers and panels,
which is why neither flashes when a step advances or a button wakes up.

## Motion

Durations `motionDurationFast` (100ms), `motionDurationMid` (200ms),
`motionDurationSlow` (300ms) and curves `motionEaseInOut`, `motionEaseOut`,
`motionEaseOutCirc`.

## Reading tokens

```dart
final token = context.softToken;         // extension on BuildContext
final theme = ConfigProvider.of(context);
```

`context.softToken` establishes a dependency, so widgets rebuild when the
theme changes.

## Dark theme

```dart
ThemeData(dark: true)
// or
ThemeData.dark
```

Dark mode is not a color inversion: the palette generator blends each shade
into the dark surface so accents stay legible, and the text ramp is rebuilt
from a light base. Every component reads its colours from the token, so nothing
is hard-coded to light — switching the theme restyles the whole kit, overlays
(message, notification, Modal, Drawer, Tooltip) included.

### Switching at runtime

There is no global "theme mode" — the kit follows Flutter's own model, where
you hold the choice in state and rebuild the provider, exactly as you would
swap a `ThemeData`. Put the provider **above** `MaterialApp` so the navigator's
overlay inherits it too:

```dart
class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    return ConfigProvider(
      theme: ThemeData(dark: _dark),
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: HomePage(onToggle: () => setState(() => _dark = !_dark)),
      ),
    );
  }
}
```

Because components depend on the provider via `context.softToken`, the flip
rebuilds them automatically — no manual invalidation. The example app has a
working light/dark toggle wired up this way.

### Following the platform

```dart
Builder(
  builder: (context) => ConfigProvider(
    theme: ThemeData(
      dark: MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    ),
    child: const MyApp(),
  ),
)
```

Combine both: seed the state from the platform brightness and still let the
user override it with a toggle.

## Palette generation

`generate(color)` returns the ten shades behind a `ColorGroup`, with index
5 being the input color. It is exported for building custom palettes:

```dart
final shades = generate(const Color(0xFF722ED1));
final darkShades = generate(const Color(0xFF722ED1), dark: true);
```

A pale or washed-out seed runs out of headroom at the light end of the ramp and
its first shades collapse into one another — the default error red `#ff4d4f`
loses two, a light brown such as `#eed9c4` three. `ColorGroup` guards against
that for `bgHover`: when the shade next to `bg` is indistinguishable, it steps
from `bg` towards the darkest shade instead, far enough to actually read. So a
`filled` surface always has a visible hover, whatever colour it was seeded
with.

## Working with Design Tokens

In `seed_ui`, styling is governed by a global Design Token system. Instead of hardcoding colors, borders, and paddings inside components, all components derive their appearance from `Token`. This ensures consistency across your app and makes theming a breeze.

### Accessing Tokens in Your Widgets

You can easily access the current design tokens from anywhere in the widget tree using `context.softToken`. This is highly recommended when building custom components so they automatically adapt to your theme (e.g., light vs dark mode).

```dart
class MyCustomWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 1. Get the current token set
    final token = context.softToken;
    
    return Container(
      // 2. Use tokens for colors, sizing, fonts, etc.
      color: token.colorBgContainer,
      padding: EdgeInsets.all(token.sizeLG),
      child: Text(
        'Hello World',
        style: TextStyle(
          color: token.colorText,
          fontSize: token.fontSizeLG,
          fontFamily: token.fontFamily,
        ),
      ),
    );
  }
}
```

### Component-Specific Overrides (Tokens)

If you need to change the style of a specific component type globally (or locally), you can pass component-specific tokens. Every component has its own token class (e.g., `ButtonToken`, `InputToken`, `AvatarToken`).

You can override them globally via `ThemeData` using `ComponentsConfig`:

```dart
ConfigProvider(
  theme: ThemeData(
    components: const ComponentsConfig(
      avatar: AvatarToken(colorTextPlaceholder: Colors.white),
      button: ButtonToken(controlHeight: 40),
    ),
  ),
  child: MyApp(),
)
```

Or you can override them on a single instance:

```dart
Button(
  token: const ButtonToken(
    colorPrimary: Colors.red, // Overrides the global theme just for this button
  ),
  child: const Text('Delete'),
)
```
