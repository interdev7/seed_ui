import 'package:flutter/widgets.dart';
import 'package:seed_ui/seed_ui.dart';

/// A festive New Year theme, tuned across every component in the kit.
///
/// The look is a lit tree in a warm room: fir green leads, bauble red answers,
/// gold appears only where an accent earns it, and bark brown carries the
/// surfaces — panel headers, tracks, hovers — the way branches carry ornaments.
///
/// ```dart
/// ConfigProvider(
///   theme: newYearTheme(),
///   child: MaterialApp(...),
/// )
/// ```
///
/// Pass `dark: true` for the same room at night.
///
/// Type is part of the preset: [NewYearTypography.body] carries every label the
/// kit renders, while its script and ornament faces are there for the handful
/// of headings that should look festive. Pass a [type] of your own to swap any
/// of them without touching the theme.
ThemeData newYearTheme({
  bool dark = false,
  NewYearTypography type = NewYearTypography.bundled,
}) {
  final c = dark ? NewYearPalette.dark : NewYearPalette.light;

  return ThemeData(
    dark: dark,
    token: SeedToken(
      colorPrimary: c.fir,
      colorSuccess: c.holly,
      colorWarning: c.gold,
      colorError: c.bauble,
      colorInfo: c.frost,
      // The whole neutral ramp — text, borders, fills, hovers — is derived
      // from these two by the kit. Making the ink warm brown rather than pure
      // black is what tints every divider and hover the colour of bark,
      // without naming a single one of them.
      colorTextBase: c.ink,
      colorBgBase: c.paper,
      borderRadius: 10,
      // Rounded, friendly body type for everything the kit draws. The display
      // face is deliberately *not* set globally — see [NewYearFonts].
      fontFamily: type.body,
    ),
    components: ComponentsConfig(
      // ---- General ---------------------------------------------------------
      button: const ButtonToken(
        borderRadius: 10,
        borderRadiusLG: 14,
        paddingInline: 20,
        paddingInlineLG: 26,
      ),

      // ---- Data entry ------------------------------------------------------
      input: InputToken(
        colorBgContainer: c.surface,
        colorBorder: c.bark,
        hoverBorderColor: c.fir,
        activeBorderColor: c.fir,
        borderRadius: 10,
      ),
      inputNumber: InputNumberToken(
        handleBg: c.surface,
        // Hover lights the chevron; only a press washes the handle.
        handleHoverColor: c.fir,
        handleActiveBg: c.firWash,
        handleBorderColor: c.bark,
      ),
      checkbox: CheckboxToken(
        colorPrimary: c.fir,
        colorBorder: c.bark,
        colorBgContainer: c.surface,
        borderRadius: 6,
      ),
      radio: RadioToken(
        colorPrimary: c.fir,
        colorBorder: c.bark,
        dotColor: c.fir,
        buttonBg: c.surface,
        buttonCheckedBg: c.firWash,
      ),
      select: SelectToken(
        selectorBg: c.surface,
        // The open menu reads like a garland: the picked option in fir, the
        // one under the pointer in the lighter wash.
        optionSelectedBg: c.firWash,
        optionActiveBg: c.barkWash,
        borderRadius: 10,
      ),
      switchToken: SwitchToken(colorPrimary: c.fir, colorBg: c.bark),

      // ---- Data display ----------------------------------------------------
      avatar: AvatarToken(
        // A gold rim, so stacked avatars read as baubles on a string.
        groupBorderColor: c.gold,
        borderRadius: 10,
      ),
      card: CardToken(
        headerBg: c.barkWash,
        actionsBg: c.surface,
        extraColor: c.fir,
        borderRadius: 14,
      ),
      collapse: CollapseToken(
        headerBg: c.barkWash,
        contentBg: c.surface,
        borderRadius: 12,
      ),
      empty: EmptyToken(colorTextDescription: c.inkMuted),
      listy: const ListyToken(itemPaddingBlock: 14, itemPaddingInline: 18),
      sortableList: SortableListToken(
        liftShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        liftRadius: 12,
      ),
      steps: StepsToken(
        // A garland: the travelled rail is fir, the markers sit on it like
        // baubles, and panels take the same bark seam as the rest of the kit.
        railThickness: 2,
        iconSize: 34,
        panelRadius: 14,
        arrowColor: c.bark,
      ),
      segmented: SegmentedToken(
        trackBg: c.barkWash,
        itemSelectedBg: c.surface,
        itemSelectedColor: c.fir,
        itemHoverColor: c.fir,
        borderRadius: 12,
      ),
      tabs: TabsToken(
        // Gold underline: the one place a full-strength gold line belongs.
        inkBarColor: c.gold,
        itemSelectedColor: c.fir,
        itemHoverColor: c.fir,
        cardBg: c.barkWash,
      ),
      tag: TagToken(
        defaultBg: c.barkWash,
        defaultColor: c.ink,
        borderRadius: 999,
      ),
      timeline: TimelineToken(
        tailColor: c.bark,
        dotBg: c.surface,
        dotSize: 12,
        dotBorderWidth: 3,
      ),
      tooltip: TooltipToken(
        colorBg: c.tooltipBg,
        colorText: c.tooltipText,
        borderRadius: 10,
      ),
      tree: TreeToken(
        nodeHoverBg: c.barkWash,
        nodeSelectedBg: c.firWash,
        borderRadius: 8,
      ),

      // ---- Navigation ------------------------------------------------------
      dropdown: DropdownToken(
        menuBg: c.elevated,
        itemHoverBg: c.firWash,
        borderRadius: 12,
      ),
      pagination: PaginationToken(
        itemBg: c.surface,
        itemActiveBg: c.goldWash,
        itemActiveColorPrimary: c.goldInk,
        borderRadius: 10,
      ),

      // ---- Feedback --------------------------------------------------------
      alert: const AlertToken(borderRadius: 12),
      drawer: DrawerToken(colorBgElevated: c.elevated, colorBgMask: c.mask),
      message: MessageToken(colorBgElevated: c.elevated, borderRadius: 12),
      modal: ModalToken(
        colorBgElevated: c.elevated,
        colorBgMask: c.mask,
        borderRadius: 16,
      ),
      notification: NotificationToken(
        colorBgElevated: c.elevated,
        borderRadius: 14,
      ),
      popconfirm: PopconfirmToken(
        colorBgElevated: c.elevated,
        borderRadius: 12,
      ),
      progress: ProgressToken(
        // A garland filling up: fir on a bark-tinted track.
        defaultColor: c.fir,
        remainingColor: c.barkWash,
      ),
      result: const ResultToken(iconSize: 64),
      spin: SpinToken(colorPrimary: c.fir),
    ),
  );
}

/// The three faces the preset draws with, and the styles that apply them.
///
/// Each face has a job:
///
/// * [body] — everything the kit renders: buttons, inputs, list rows.
/// * [script] — a handwritten greeting, for the one line that should look
///   written by hand.
/// * [ornament] — a decorative short heading.
///
/// The bundled set ([NewYearTypography.bundled]) is Nunito, Marck Script and
/// Ruslan Display: all three are SIL OFL and all three cover **Latin and
/// Cyrillic in the same file**, so text never changes typeface halfway
/// through.
///
/// To use a face of your own, drop the file into `assets/fonts`, declare the
/// family in `pubspec.yaml`, and name it here — the theme needs no editing:
///
/// ```dart
/// newYearTheme(
///   type: const NewYearTypography(script: 'JollySweater'),
/// )
/// ```
///
/// Two things to check before you do. Does the font carry the alphabets you
/// ship — plenty of holiday faces are Latin-only. And does its licence permit
/// *redistribution*, not merely use: bundling a font into a repository is
/// redistribution, and "free for commercial use" often does not include it.
/// See `assets/fonts/README.md` for the licence notes on the fonts that were
/// looked at.
@immutable
class NewYearTypography {
  const NewYearTypography({
    this.body = 'Nunito',
    this.script = 'MarckScript',
    this.ornament = 'RuslanDisplay',
  });

  /// The set shipped with the example.
  static const NewYearTypography bundled = NewYearTypography();

  /// Body face — becomes the theme's `fontFamily`.
  final String body;

  /// Handwritten face for greetings.
  final String script;

  /// Ornamental face for short headings.
  final String ornament;

  /// A handwritten greeting of [size].
  TextStyle scriptStyle({required Color color, double size = 34}) =>
      _festive(script, color, size, 1.35);

  /// A decorative heading of [size].
  TextStyle ornamentStyle({required Color color, double size = 24}) =>
      _festive(ornament, color, size, 1.3);

  /// Both display styles keep [body] as a fallback. The bundled faces cover
  /// Cyrillic themselves, but a swapped-in one may not — and a name, a currency
  /// mark or a CJK string still has to land somewhere readable.
  TextStyle _festive(String family, Color color, double size, double height) =>
      TextStyle(
        fontFamily: family,
        fontFamilyFallback: [body],
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color,
        // These faces have tall ascenders and deep descenders; a roomy line
        // keeps them clear of the text above and below.
        height: height,
        decoration: TextDecoration.none,
      );
}

/// The colours the theme is built from, kept in one place so a demo page can
/// borrow them for its own decoration.
@immutable
class NewYearPalette {
  const NewYearPalette._({
    required this.fir,
    required this.holly,
    required this.gold,
    required this.goldInk,
    required this.goldWash,
    required this.bauble,
    required this.frost,
    required this.bark,
    required this.barkWash,
    required this.firWash,
    required this.ink,
    required this.inkMuted,
    required this.paper,
    required this.surface,
    required this.elevated,
    required this.mask,
    required this.shadow,
    required this.tooltipBg,
    required this.tooltipText,
  });

  /// The tree: the leading accent, used for primary actions and links.
  ///
  /// Mid-tone on purpose — the shade ramp is generated by stepping brightness,
  /// so a deep-forest seed would tint alerts and tags grey.
  final Color fir;

  /// A brighter needle green for success.
  final Color holly;

  /// Tinsel. Used sparingly — a tab underline, an active page.
  final Color gold;

  /// Dark gold that stays readable as text on [goldWash].
  final Color goldInk;

  /// The faintest gold, for a surface rather than a stroke.
  final Color goldWash;

  /// Baubles: the error/danger red.
  final Color bauble;

  /// A cold blue for informational notes — frost on the window.
  final Color frost;

  /// Branch brown for borders and dividers.
  final Color bark;

  /// A wash of the same brown for headers, tracks and hovers.
  final Color barkWash;

  /// A wash of fir for selected rows and menu items.
  final Color firWash;

  /// Warm near-black used as the text base; it tints the whole neutral ramp.
  final Color ink;

  /// Muted body text.
  final Color inkMuted;

  /// Page background.
  final Color paper;

  /// Panels and controls sitting on [paper].
  final Color surface;

  /// Floating surfaces: modals, drawers, menus, toasts.
  final Color elevated;

  /// The scrim behind them.
  final Color mask;

  /// Shadow colour for lifted things.
  final Color shadow;

  /// Tooltip body — a dark fir chip in both schemes, so it reads as a label
  /// pinned to the tree rather than another panel.
  final Color tooltipBg;

  /// Text on [tooltipBg].
  final Color tooltipText;

  /// Daylight: warm paper, fir, and just enough gold.
  static const NewYearPalette light = NewYearPalette._(
    // The accents are deliberately mid-tone rather than deep-forest: the kit
    // derives a ten-shade ramp from each by stepping brightness, so a very
    // dark seed yields muddy tints — a "pale mint" alert background comes out
    // grey. These keep their tinted surfaces clean.
    fir: Color(0xFF1FB25F),
    holly: Color(0xFF16A34A),
    gold: Color(0xFFE0A62E),
    goldInk: Color(0xFF8A6A17),
    goldWash: Color(0xFFFBF1D8),
    bauble: Color(0xFFCE2B37),
    frost: Color(0xFF4A90C2),
    bark: Color(0xFFD8C6AE),
    barkWash: Color(0xFFF6EEE3),
    firWash: Color(0xFFE6F2EA),
    ink: Color(0xFF2A1D18),
    inkMuted: Color(0xFF6B5A50),
    paper: Color(0xFFFFFCF6),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFFFFDF9),
    mask: Color(0x66201310),
    shadow: Color(0x332A1D18),
    tooltipBg: Color(0xFF14382A),
    tooltipText: Color(0xFFF3EFE7),
  );

  /// Night: the room lit by the tree, greens and golds pushed brighter so they
  /// hold their own against the dark.
  static const NewYearPalette dark = NewYearPalette._(
    fir: Color(0xFF2FB86B),
    holly: Color(0xFF35C077),
    gold: Color(0xFFE7B84F),
    goldInk: Color(0xFFF3D48A),
    goldWash: Color(0xFF3A3018),
    bauble: Color(0xFFE2504E),
    frost: Color(0xFF5FA3D6),
    bark: Color(0xFF4A3D33),
    barkWash: Color(0xFF23302A),
    firWash: Color(0xFF1B3A2B),
    ink: Color(0xFFF2EDE6),
    inkMuted: Color(0xFFB8AFA5),
    paper: Color(0xFF101C17),
    surface: Color(0xFF16241E),
    elevated: Color(0xFF1B2C24),
    mask: Color(0x99060C09),
    shadow: Color(0x66000000),
    tooltipBg: Color(0xFF0C1913),
    tooltipText: Color(0xFFEFEAE2),
  );
}
