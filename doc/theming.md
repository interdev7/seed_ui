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

### The system status bar

`ConfigProvider` states a status-bar style matching its theme, so a dark theme
gets light icons instead of the platform's dark ones — which on a dark bar
cannot be seen at all. It is declared through an `AnnotatedRegion`, not pushed
through `SystemChrome`, so the style belongs to the provider's subtree rather
than to global state.

Only the icon brightness is claimed. The bar's own colour is left alone, so a
translucent or coloured status bar the app set survives.

If the app drives the system chrome itself — through `AppBar.systemOverlayStyle`
or its own `AnnotatedRegion` — turn it off:

```dart
ConfigProvider(
  theme: ThemeData(dark: true),
  systemOverlayStyle: false,
  child: const MyApp(),
)
```

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

### Nesting providers

Providers nest, and a nested one **inherits**. It changes what it names and
leaves everything else as the provider above it had it — the palette, the
brightness, the other components' tokens, the language, the empty state.

So a screen that wants rounder buttons says only that:

```dart
ConfigProvider(
  theme: ThemeData(
    components: ComponentsConfig(button: ButtonToken(borderRadius: 16)),
  ),
  child: ...,  // keeps the app's colours, language and everything else
)
```

What a nested theme inherits depends on what it states:

| The nested theme states | What it takes from above |
| --- | --- |
| only `components` | the whole token set |
| only a seed (`token:`) | the brightness |
| only `dark:` | the palette the brightness is flipped on |
| both | nothing — it is fully specified |
| `ThemeData.raw(...)` | nothing; the token is taken as final |

Component tokens merge slot by slot, the nearer provider winning where the two
name the same component. `emptyBuilder` and `locale` are inherited the same way:
the nearest provider that states one wins, and a provider silent about it
passes down whatever it inherited.

This is why `ThemeData.dark` nested inside a themed provider turns the lights
out without discarding your colours:

```dart
ConfigProvider(
  theme: ThemeData(token: SeedToken(colorPrimary: Color(0xFFEB2F96))),
  child: ConfigProvider(
    theme: ThemeData.dark,  // pink, in the dark
    child: ...,
  ),
)
```

### A preset, or a measurement

`size` is a `ControlSize` on some components and a `SoftSize` on others, and
the line between them is what the preset actually feeds:

| | Components | Why |
| --- | --- | --- |
| `ControlSize` | `Avatar`, `Spin`, `Steps`, `Progress`, `Select`, `TimePicker`, `DatePicker` | The size feeds the box alone — a diameter, or a height and a type size that can stay put |
| `SoftSize` | `Button`, `Input` | The preset feeds four or five things at once: height, type size, padding, radius. A bare number would supply one and leave the rest guessing |

Where `ControlSize` is taken, all three forms work: `SoftSize.large`,
`ControlSize.height(36)` and `ControlSize.box(200, 36)`.

### Font weight

Two seeds carry weight, and every component reads one of them:

```dart
ConfigProvider(
  theme: ThemeData(
    token: const SeedToken(
      fontWeight: FontWeight.w300,        // ordinary text
      fontWeightStrong: FontWeight.w700,  // titles and the chosen row
    ),
  ),
  child: ...,
)
```

`fontWeight` is labels, body copy, a button's own words. `fontWeightStrong` is
what a component draws when something should stand out from the copy around
it: a card or modal title, a section header, the selected option in a list.

Said once, they reach the whole kit. Before this existed, every weight was
written into the widget that drew it and could only be changed by wrapping
each one.

A component whose weight is its own affair carries a token for it, so it can
differ without moving the rest:

| Token | Default |
| --- | --- |
| `ButtonToken.fontWeight` | the theme's `fontWeight` |
| `ResultToken.fontWeight` | `w500` |
| `TabsToken.fontWeightActive` | `w500` |
| `CountdownToken.fontWeight` | the theme's `fontWeight` |

### One size, one switch, for a whole subtree

Two settings on `ConfigProvider` are defaults for the widgets under it rather
than colours: `componentSize` and `componentDisabled`.

```dart
ConfigProvider(
  componentSize: SoftSize.small,   // a dense screen
  componentDisabled: saving,       // the form is read-only while it saves
  child: ...,
)
```

`componentSize` is the size every component takes when it does not name its
own — buttons, inputs, selects, tabs, avatars, the lot. `componentDisabled` is
the same idea for controls: one flag instead of a `disabled:` threaded through
every field.

For **one component only**, say it in that component's defaults instead — see
[Tokens, and defaults](#tokens-and-defaults) below:

```dart
ConfigProvider(
  componentSize: SoftSize.large,                    // the screen
  defaults: const ComponentDefaults(
    button: ButtonDefaults(size: SoftSize.small),   // but the buttons
  ),
  child: ...,
)
```

What a widget states for itself always wins, so a control can stay live in a
disabled subtree:

```dart
Button(disabled: false, onPressed: _cancel, child: const Text('Cancel'))
```

Both are inherited like everything else on the provider: a nested provider
silent about them passes down whatever it received, and one that names them
overrides for its own subtree.

Two boundaries worth knowing.

**A nearer container outranks the screen.** An `Avatar` inside an
`AvatarGroup` takes the group's size, not the provider's — the group is the
more specific word about it.

**A per-item flag is not the screen speaking.** `componentDisabled` reaches the
controls a person operates. The `disabled` on one `SelectOption`, `TreeNode`,
`TabItem` or `CheckboxOption` is about that item and is left alone, as is
`Popconfirm.disabled`, which means "do not ask" rather than "cannot be used".

Reading them yourself, for a widget of your own that should follow along:

```dart
final size = ConfigProvider.componentSizeOf(context) ?? SoftSize.middle;
final off = ConfigProvider.componentDisabledOf(context) ?? false;
```

### Tokens, and defaults

Two different things can be set for a component, and they are not the same
knob.

| | Where | What it carries |
| --- | --- | --- |
| **Tokens** | `ThemeData(components: ComponentsConfig(...))` | The numbers and colours a component draws with — `ButtonToken(borderRadius: 16)` |
| **Defaults** | `ConfigProvider(defaults: ComponentDefaults(...))` | The component's own props, where a widget did not name one — `ButtonDefaults(shape: ButtonShape.round)` |

A token says *how a button is drawn*. A default says *what a button is, unless
it says otherwise*. Some things can only be said the second way: a shape, a
variant, whether a tag closes, which illustration an empty state uses.

```dart
ConfigProvider(
  theme: ThemeData(
    components: ComponentsConfig(button: ButtonToken(borderRadius: 16)),
  ),
  defaults: const ComponentDefaults(
    button: ButtonDefaults(shape: ButtonShape.round, variant: ButtonVariant.solid),
    tag: TagDefaults(closable: true),
  ),
  child: ...,
)
```

A widget's own prop always wins, and defaults are inherited and merged slot by
slot like everything else on the provider: a nested provider that names one
component leaves the others as the provider above had them.

#### Which of the three wins

`size` and `disabled` can be said in three places. They resolve **nearest
first** — the closer the word is to the widget, the stronger it is:

```dart
widget.size                                   // 1. this widget said so
  ?? defaults.button?.size                    // 2. said about buttons
  ?? ConfigProvider.componentSizeOf(context)  // 3. said about the screen
  ?? SoftSize.middle                          // 4. the kit's own default
```

`componentSize` keeps working exactly as before; it is simply no longer the
only way to say it. The same ladder governs `disabled`.

Every component whose `size` or `disabled` is nullable carries the matching
field in its defaults: `Avatar`, `Button`, `Card`, `Collapse`, `Input`,
`InputNumber`, `Pagination`, `Progress`, `RadioGroup`, `Segmented`, `Select`,
`Steps`, `Tabs`, `TimePicker` for `size`; `Button`, `CheckableTagGroup`,
`CheckboxGroup`, `Dropdown`, `Input`, `InputNumber`, `Pagination`,
`RadioGroup`, `Segmented`, `Select`, `Slider`, `TimePicker`, `Tree`, `Upload`
for `disabled`.

What can be set so far — the list grew to cover every prop that is a
house-style decision rather than the state of one instance:

| Component | Defaults |
| --- | --- |
| `Alert` | `showIcon`, `closable` |
| `Avatar` | `shape` |
| `Button` | `variant`, `color`, `shape` |
| `Card` | `hoverable`, `variant`, `type` |
| `CheckableTagGroup` | `multiple` |
| `CheckboxGroup` | `direction` |
| `Collapse` | `accordion`, `bordered`, `ghost`, `expandIconPosition`, `collapsible` |
| `Countdown` | `type` |
| `Dropdown` | `placement`, `arrow`, `closeOnSelect`, `trigger` |
| `Empty` | `image` |
| `Input` | `allowClear` |
| `InputNumber` | `controls`, `keyboard`, `mode` |
| `Pagination` | `showSizeChanger`, `showQuickJumper`, `hideOnSinglePage`, `showLessItems`, `align` |
| `Popconfirm` | `placement`, `arrow`, `showCancel` |
| `Popover` | `placement`, `trigger`, `arrow`, `animation`, `dismissOnOutsideTap` |
| `Progress` | `showInfo`, `gapPlacement` |
| `RadioGroup` | `direction`, `optionType`, `buttonStyle` |
| `Ribbon` | `placement` |
| `Segmented` | `direction` |
| `Select` | `variant`, `allowClear`, `showSearch` |
| `Slider` | `dots`, `included` |
| `SortableList` | `direction`, `showHandle` |
| `Steps` | `orientation`, `type`, `variant`, `responsive`, `overflow` |
| `Tabs` | `type`, `tabPosition`, `hideAdd`, `animated`, `scrollAlign`, `snap`, `contentPosition` |
| `Tag` | `variant`, `closable` |
| `Timeline` | `mode`, `orientation`, `variant` |
| `Tooltip` | `placement`, `arrow` |
| `Tour` | `placement`, `arrow`, `closable` |
| `Tree` | `showLine`, `showLeafIcon`, `showIcon`, `blockNode` |
| `Upload` | `variant`, `showRemove`, `showRetry`, `showSize` |

A prop belongs here when it is a decision about the house rather than the
occupant. `Alert.showIcon` is house style; `Alert.type` — success or error — is
about that one message, and stays where it is. So do the props that describe
what a widget is *doing*: `loading`, `dragging`, `indeterminate`.

For a widget of your own that should follow along:

```dart
final shape = ConfigProvider.defaultsOf<ButtonDefaults>(context)?.shape;
```
