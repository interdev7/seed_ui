import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'palette.dart';

/// Sealed hierarchy representing component sizes in seed_ui.
///
/// Accepts preset sizes ([SoftSize.small], [SoftSize.middle], [SoftSize.large]),
/// a height of your own ([ExplicitHeight] or [ControlSize.height]),
/// or a width and height of your own ([ExplicitBox] or [ControlSize.box]).
sealed class ControlSize {
  const ControlSize();

  /// A height of your own, in logical pixels.
  ///
  /// A circle's height is its diameter, so this reads true for an [Avatar] or
  /// a spinner as well as for a field.
  const factory ControlSize.height(double height) = ExplicitHeight;

  /// A width and a height of your own.
  const factory ControlSize.box(double width, double height) = ExplicitBox;
}

/// The shared height preset for the kit's controls — small, middle (the
/// default) or large — mapping to the `controlHeight` token scale. Reused
/// across Button, Input, Select, Radio, Segmented and Pagination.
enum SoftSize implements ControlSize {
  /// The compact preset, for dense rows.
  small,

  /// The standard preset — the default.
  middle,

  /// The roomy preset, for primary calls to action.
  large;
}

/// Explicit 2D width and height size.
class ExplicitBox extends ControlSize {
  /// Creates an explicit 2D size with [width] and [height].
  const ExplicitBox(this.width, this.height);

  /// Width in logical pixels.
  final double width;

  /// Height in logical pixels.
  final double height;
}

/// Explicit 1D dimension size (square/diameter or line height).
class ExplicitHeight extends ControlSize {
  /// Creates a height of your own.
  const ExplicitHeight(this.height);

  /// Height in logical pixels. A circle's height is its diameter.
  final double height;
}

/// The minimal set of inputs an entire theme is derived from.
///
/// Override only what you care about — every other value in [Token] is
/// computed from these seeds, so changing [colorPrimary] alone restyles the
/// whole kit coherently.
@immutable
class SeedToken {
  /// Creates a [SeedToken].
  const SeedToken({
    this.colorPrimary = const Color(0xFF1677FF),
    this.colorSuccess = const Color(0xFF52C41A),
    this.colorWarning = const Color(0xFFFAAD14),
    this.colorError = const Color(0xFFFF4D4F),
    this.colorInfo = const Color(0xFF1677FF),
    this.colorTextBase = const Color(0xFF000000),
    this.colorBgBase = const Color(0xFFFFFFFF),
    this.fontFamily,
    this.fontFamilyFallback,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w400,
    this.fontWeightStrong = FontWeight.w600,
    this.borderRadius = 6,
    this.sizeUnit = 4,
    this.sizeStep = 4,
    this.controlHeight = 32,
    this.lineWidth = 1,
    this.wireframe = false,
  });

  /// Accent color for primary actions, links and focus states.
  final Color colorPrimary;

  /// Color denoting a completed or successful outcome.
  final Color colorSuccess;

  /// Color denoting something that needs attention but is not yet a failure.
  final Color colorWarning;

  /// Color denoting a failure, and the accent used by destructive actions.
  final Color colorError;

  /// Color denoting neutral, informational content.
  final Color colorInfo;

  /// Base the text ramp is built from; alpha is applied to it to produce
  /// secondary, tertiary and quaternary text, and every border, divider and
  /// fill. A dark theme builds the ramp from white instead — unless this is
  /// already a light colour, which is then kept.
  final Color colorTextBase;

  /// Base the surfaces are built from, and the backdrop tinted shades are
  /// blended into.
  ///
  /// Left at white, the kit paints neutral surfaces. Name your own —
  /// on the same side as the scheme — and panels take it, the page sits a touch
  /// deeper and floating layers a touch lighter.
  final Color colorBgBase;

  /// Font applied to all text in the kit. Null uses the platform default —
  /// the OS UI font, which is what a CSS `-apple-system` stack resolves to.
  final String? fontFamily;

  /// Fonts tried, in order, for glyphs the primary font lacks.
  ///
  /// Null by default, which is the right choice on every platform: the OS
  /// font already covers ordinary text and its own emoji. Supplying an
  /// explicit fallback — emoji fonts especially — can make the shaper render
  /// spaces or glyphs from the wrong font, widening word gaps. Only set this
  /// for a specific font you have bundled and know you need.
  final List<String>? fontFamilyFallback;

  /// Base font size. Every other size in [Token] is an offset from it.
  final double fontSize;

  /// Weight of ordinary text — labels, body copy, a button's own words.
  ///
  /// One place to make the whole kit lighter or heavier. A brand that sets
  /// its buttons in medium says so here rather than in every widget.
  final FontWeight fontWeight;

  /// Weight of text that carries: titles, headings, the chosen row in a list.
  ///
  /// Used wherever a component draws something that should stand out from the
  /// copy around it.
  final FontWeight fontWeightStrong;

  /// Base corner radius. Smaller and larger radii are derived from it.
  final double borderRadius;

  /// Base spacing unit. Spacing tokens are whole multiples of this value.
  final double sizeUnit;

  /// Increment between adjacent spacing steps.
  final double sizeStep;

  /// Height of a medium control such as a button or input. Small and large
  /// variants are scaled from it.
  final double controlHeight;

  /// Thickness of borders and dividers.
  final double lineWidth;

  /// Opts into a flatter, outline-first look with fewer filled surfaces.
  final bool wireframe;

  /// A copy of this token with the given fields replaced.
  SeedToken copyWith({
    Color? colorPrimary,
    Color? colorSuccess,
    Color? colorWarning,
    Color? colorError,
    Color? colorInfo,
    Color? colorTextBase,
    Color? colorBgBase,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    FontWeight? fontWeight,
    FontWeight? fontWeightStrong,
    double? borderRadius,
    double? sizeUnit,
    double? sizeStep,
    double? controlHeight,
    double? lineWidth,
    bool? wireframe,
  }) {
    return SeedToken(
      colorPrimary: colorPrimary ?? this.colorPrimary,
      colorSuccess: colorSuccess ?? this.colorSuccess,
      colorWarning: colorWarning ?? this.colorWarning,
      colorError: colorError ?? this.colorError,
      colorInfo: colorInfo ?? this.colorInfo,
      colorTextBase: colorTextBase ?? this.colorTextBase,
      colorBgBase: colorBgBase ?? this.colorBgBase,
      fontFamily: fontFamily ?? this.fontFamily,
      fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontWeightStrong: fontWeightStrong ?? this.fontWeightStrong,
      borderRadius: borderRadius ?? this.borderRadius,
      sizeUnit: sizeUnit ?? this.sizeUnit,
      sizeStep: sizeStep ?? this.sizeStep,
      controlHeight: controlHeight ?? this.controlHeight,
      lineWidth: lineWidth ?? this.lineWidth,
      wireframe: wireframe ?? this.wireframe,
    );
  }
}

/// The full set of shades a single semantic color expands into.
///
/// Components pick the member matching the surface they are painting —
/// [bg] for fills, [border] for outlines, [hover]/[active] for interaction
/// states — so a status color stays recognisable in every context.
@immutable
class ColorGroup {
  /// Creates a [ColorGroup].
  const ColorGroup({
    required this.bg,
    required this.bgHover,
    required this.border,
    required this.borderHover,
    required this.hover,
    required this.base,
    required this.active,
    required this.textHover,
    required this.text,
    required this.textActive,
  });

  /// Creates a [ColorGroup] via [ColorGroup.fromPalette].
  factory ColorGroup.fromPalette(List<Color> p) => ColorGroup(
        bg: p[0],
        bgHover: _bgHover(p),
        border: p[2],
        borderHover: p[3],
        hover: p[4],
        base: p[5],
        active: p[6],
        textHover: p[4],
        text: p[5],
        textActive: p[6],
      );

  /// The tinted background a `filled` surface takes on hover.
  ///
  /// Normally the second-lightest shade. Pale or washed-out base colours run
  /// out of headroom at the light end of the palette, though, and their first
  /// shades collapse into one another — the default error red #ff4d4f loses
  /// two, a light brown such as #EED9C4 loses three — which would leave the
  /// surface with no visible hover at all. Those palettes instead step from
  /// the resting shade towards the darkest one, far enough to actually read.
  static Color _bgHover(List<Color> p) {
    if (_separated(p[0], p[1])) return p[1];
    for (final factor in const [0.08, 0.15, 0.25, 0.4]) {
      final candidate = Color.lerp(p[0], p.last, factor)!;
      if (_separated(p[0], candidate)) return candidate;
    }
    return Color.lerp(p[0], p.last, 0.4)!;
  }

  /// Whether two shades differ enough to read as separate states.
  static bool _separated(Color a, Color b) =>
      math.max(
        (a.r - b.r).abs(),
        math.max((a.g - b.g).abs(), (a.b - b.b).abs()),
      ) >
      0.04;

  /// Tinted background for a resting surface, such as an alert banner.
  final Color bg;

  /// Tinted background while the pointer is over it.
  final Color bgHover;

  /// Outline for a resting surface.
  final Color border;

  /// Outline while the pointer is over it.
  final Color borderHover;

  /// Solid fill while the pointer is over it.
  final Color hover;

  /// Solid fill at rest — the seed color itself.
  final Color base;

  /// Solid fill while being pressed.
  final Color active;

  /// Label color while the pointer is over it.
  final Color textHover;

  /// Label color at rest.
  final Color text;

  /// Label color while being pressed.
  final Color textActive;
}

/// The resolved theme values components actually read.
///
/// Derived from a [SeedToken] via [Token.derive]; never constructed
/// by hand.
@immutable
class Token {
  const Token._({
    required this.seed,
    required this.isDark,
    required this.primary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.colorText,
    required this.colorTextSecondary,
    required this.colorTextTertiary,
    required this.colorTextQuaternary,
    required this.colorBorder,
    required this.colorBorderSecondary,
    required this.colorSplit,
    required this.colorBgContainer,
    required this.colorBgElevated,
    required this.colorBgLayout,
    required this.colorBgSpotlight,
    required this.colorBgMask,
    required this.colorFill,
    required this.colorFillSecondary,
    required this.colorFillTertiary,
    required this.colorFillQuaternary,
    required this.boxShadow,
    required this.boxShadowSecondary,
  });

  /// Expands [seed] into the complete token set for a light or [dark] theme.
  factory Token.derive(SeedToken seed, {bool dark = false}) {
    // A seed that names its own background — and names one on the same side as
    // the scheme — is taken at its word: surfaces, borders and the tinted
    // accent shades are all built from it, so a themed page is themed all the
    // way down rather than sitting on stock white or black. The default seed
    // (white paper) keeps the classic Ant surfaces in both schemes.
    const defaultBg = Color(0xFFFFFFFF);
    final seedBgIsDark = seed.colorBgBase.computeLuminance() < 0.5;
    final tinted = seed.colorBgBase != defaultBg && dark == seedBgIsDark;

    // In dark mode the palette must blend its shades into the dark surface, not
    // the seed's (light) background — otherwise the tinted `bg` shades come out
    // pale, and light text on them is unreadable.
    final paletteBg = tinted
        ? seed.colorBgBase
        : (dark ? const Color(0xFF141414) : seed.colorBgBase);
    List<Color> pal(Color c) => generate(c, dark: dark, background: paletteBg);

    // Dark themes invert the text base: light glyphs on a dark surface. A seed
    // that already supplies a light ink is kept, so a warm off-white carries
    // its warmth into every derived text and fill.
    final textBase = dark
        ? (seed.colorTextBase.computeLuminance() > 0.5
            ? seed.colorTextBase
            : const Color(0xFFFFFFFF))
        : seed.colorTextBase;

    /// Moves [c] towards black (negative) or white (positive).
    Color shade(Color c, double amount) => Color.lerp(
          c,
          amount < 0 ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
          amount.abs(),
        )!;

    return Token._(
      seed: seed,
      isDark: dark,
      primary: ColorGroup.fromPalette(pal(seed.colorPrimary)),
      success: ColorGroup.fromPalette(pal(seed.colorSuccess)),
      warning: ColorGroup.fromPalette(pal(seed.colorWarning)),
      error: ColorGroup.fromPalette(pal(seed.colorError)),
      info: ColorGroup.fromPalette(pal(seed.colorInfo)),
      colorText: alphaOn(textBase, dark ? 0.85 : 0.88),
      colorTextSecondary: alphaOn(textBase, 0.65),
      colorTextTertiary: alphaOn(textBase, 0.45),
      colorTextQuaternary: alphaOn(textBase, 0.25),
      // The stock greys, or — for a tinted theme — the same weights drawn from
      // the seed's own ink, so a border is bark rather than grey.
      colorBorder: tinted
          ? alphaOn(textBase, dark ? 0.26 : 0.15)
          : (dark ? const Color(0xFF424242) : const Color(0xFFD9D9D9)),
      colorBorderSecondary: tinted
          ? alphaOn(textBase, dark ? 0.19 : 0.06)
          : (dark ? const Color(0xFF303030) : const Color(0xFFF0F0F0)),
      colorSplit: alphaOn(textBase, dark ? 0.12 : 0.06),
      // Panels sit on the seed background; the page is a touch deeper and
      // floating surfaces a touch lighter, the relationship Ant's own
      // white/#f5f5f5/#141414/#1f1f1f trio expresses.
      colorBgContainer: tinted
          ? seed.colorBgBase
          : (dark ? const Color(0xFF141414) : const Color(0xFFFFFFFF)),
      colorBgElevated: tinted
          ? (dark ? shade(seed.colorBgBase, 0.06) : seed.colorBgBase)
          : (dark ? const Color(0xFF1F1F1F) : const Color(0xFFFFFFFF)),
      colorBgLayout: tinted
          ? shade(seed.colorBgBase, dark ? -0.30 : -0.04)
          : (dark ? const Color(0xFF000000) : const Color(0xFFF5F5F5)),
      colorBgSpotlight:
          dark ? const Color(0xFF424242) : alphaOn(textBase, 0.85),
      colorBgMask: alphaOn(const Color(0xFF000000), 0.45),
      // A light overlay on a dark surface reads far fainter than a dark one on
      // a light surface, so the dark theme needs higher alphas to stay visible
      // — a progress track or an alternating row must not vanish.
      colorFill: alphaOn(textBase, dark ? 0.18 : 0.15),
      colorFillSecondary: alphaOn(textBase, dark ? 0.12 : 0.06),
      colorFillTertiary: alphaOn(textBase, dark ? 0.08 : 0.04),
      colorFillQuaternary: alphaOn(textBase, dark ? 0.04 : 0.02),
      boxShadow: [
        BoxShadow(
          color: alphaOn(const Color(0xFF000000), dark ? 0.45 : 0.08),
          offset: const Offset(0, 6),
          blurRadius: 16,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: alphaOn(const Color(0xFF000000), dark ? 0.35 : 0.12),
          offset: const Offset(0, 3),
          blurRadius: 6,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: alphaOn(const Color(0xFF000000), dark ? 0.25 : 0.05),
          offset: const Offset(0, 9),
          blurRadius: 28,
          spreadRadius: 8,
        ),
      ],
      boxShadowSecondary: [
        BoxShadow(
          color: alphaOn(const Color(0xFF000000), dark ? 0.45 : 0.08),
          offset: const Offset(0, 6),
          blurRadius: 16,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: alphaOn(const Color(0xFF000000), dark ? 0.35 : 0.12),
          offset: const Offset(0, 3),
          blurRadius: 6,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: alphaOn(const Color(0xFF000000), dark ? 0.25 : 0.05),
          offset: const Offset(0, 9),
          blurRadius: 28,
          spreadRadius: 8,
        ),
      ],
    );
  }

  /// The seed values this token set was derived from.
  final SeedToken seed;

  /// Whether this is a dark theme. Useful for picking assets that cannot be
  /// expressed as a token, such as a logo variant.
  final bool isDark;

  /// Shades of the accent color, for primary actions and links.
  final ColorGroup primary;

  /// Shades denoting a successful outcome.
  final ColorGroup success;

  /// Shades denoting something that needs attention.
  final ColorGroup warning;

  /// Shades denoting a failure, and the palette used by destructive actions.
  final ColorGroup error;

  /// Shades denoting neutral, informational content.
  final ColorGroup info;

  /// Primary text: headings and body copy.
  final Color colorText;

  /// Secondary text: descriptions and supporting copy.
  final Color colorTextSecondary;

  /// Tertiary text: captions, placeholders and inactive icons.
  final Color colorTextTertiary;

  /// Quaternary text: disabled labels.
  final Color colorTextQuaternary;

  /// Default border for interactive elements such as inputs and buttons.
  final Color colorBorder;

  /// Lighter border for grouping non-interactive content, such as card edges.
  final Color colorBorderSecondary;

  /// Divider lines between list rows and sections.
  final Color colorSplit;

  /// Surface of content sitting on the page: cards, inputs, tables.
  final Color colorBgContainer;

  /// Surface of layers floating above the page: menus, popovers, toasts.
  /// Distinct from [colorBgContainer] in dark themes, where elevation is
  /// conveyed by a lighter surface rather than by shadow alone.
  final Color colorBgElevated;

  /// Page backdrop, one step behind [colorBgContainer].
  final Color colorBgLayout;

  /// High-contrast surface for elements that must stand out against the page,
  /// such as tooltips.
  final Color colorBgSpotlight;

  /// Scrim drawn behind modal layers to dim the content below.
  final Color colorBgMask;

  /// Strongest neutral fill, for elements needing clear separation from the
  /// surface behind them.
  final Color colorFill;

  /// Neutral fill for hover states on subtle controls.
  final Color colorFillSecondary;

  /// Light neutral fill for disabled surfaces and inactive rows.
  final Color colorFillTertiary;

  /// Faintest neutral fill, for alternating table rows and similar banding.
  final Color colorFillQuaternary;

  /// Shadow for floating layers such as menus, popovers and toasts.
  final List<BoxShadow> boxShadow;

  /// Shallower shadow for elements resting closer to the page.
  final List<BoxShadow> boxShadowSecondary;

  // --- sizing ---

  /// Tightest spacing, for gaps inside a single control. Defaults to 4.
  double get sizeXXS => seed.sizeUnit;

  /// Spacing between closely related elements, such as an icon and its label.
  /// Defaults to 8.
  double get sizeXS => seed.sizeUnit * 2;

  /// Spacing between elements in a group. Defaults to 12.
  double get sizeSM => seed.sizeUnit * 3;

  /// Standard spacing, and the usual padding inside a container.
  /// Defaults to 16.
  double get size => seed.sizeUnit * 4;

  /// Spacing between distinct groups. Defaults to 20.
  double get sizeMD => seed.sizeUnit * 5;

  /// Spacing between sections. Defaults to 24.
  double get sizeLG => seed.sizeUnit * 6;

  /// Widest spacing, for separating major regions of a page. Defaults to 32.
  double get sizeXL => seed.sizeUnit * 8;

  /// Height of a compact control, for dense layouts. Defaults to 24.
  double get controlHeightSM => seed.controlHeight * 0.75;

  /// Height of a standard control. Defaults to 32.
  double get controlHeight => seed.controlHeight;

  /// Height of a prominent control, such as a call-to-action button.
  /// Defaults to 40.
  double get controlHeightLG => seed.controlHeight * 1.25;

  /// Corner radius for small details such as tags and checkboxes.
  double get borderRadiusXS => 2;

  /// Corner radius for compact controls. Defaults to 4.
  double get borderRadiusSM => seed.borderRadius - 2;

  /// Corner radius for standard controls. Defaults to 6.
  double get borderRadius => seed.borderRadius;

  /// Corner radius for large surfaces such as cards and dialogs.
  /// Defaults to 8.
  double get borderRadiusLG => seed.borderRadius + 2;

  /// Thickness of borders and dividers.
  double get lineWidth => seed.lineWidth;

  // --- typography ---

  /// Size for secondary text such as captions and helper copy. Defaults to 12.
  double get fontSizeSM => seed.fontSize - 2;

  /// Size for body copy and control labels. Defaults to 14.
  double get fontSize => seed.fontSize;

  /// Size for subheadings and emphasised labels. Defaults to 16.
  double get fontSizeLG => seed.fontSize + 2;

  /// Size for headings. Defaults to 20.
  double get fontSizeXL => seed.fontSize + 6;

  /// Weight of ordinary text. Defaults to `FontWeight.w400`.
  FontWeight get fontWeight => seed.fontWeight;

  /// Weight of titles and other text that carries. Defaults to
  /// `FontWeight.w600`.
  FontWeight get fontWeightStrong => seed.fontWeightStrong;

  /// Line height for multi-line body copy.
  ///
  /// Do not apply it to short single-line labels: the taller line box shifts
  /// glyphs against adjacent icons.
  double get lineHeight => 1.5714285714285714;

  /// Font applied to all text in the kit. Null uses the platform default.
  String? get fontFamily => seed.fontFamily;

  /// Fonts tried, in order, for glyphs the primary font lacks.
  List<String>? get fontFamilyFallback => seed.fontFamilyFallback;

  // --- motion ---

  /// For instant feedback such as hover and press states.
  Duration get motionDurationFast => const Duration(milliseconds: 100);

  /// For state changes within a component, such as a colour or size shift.
  Duration get motionDurationMid => const Duration(milliseconds: 200);

  /// For elements entering or leaving the screen.
  Duration get motionDurationSlow => const Duration(milliseconds: 300);

  /// Symmetric easing for transitions that both start and end on screen.
  Curve get motionEaseInOut => const Cubic(0.645, 0.045, 0.355, 1);

  /// Decelerating easing for elements arriving on screen.
  Curve get motionEaseOut => const Cubic(0.215, 0.61, 0.355, 1);

  /// Sharper deceleration, for entrances that should feel brisk.
  Curve get motionEaseOutCirc => const Cubic(0.08, 0.82, 0.17, 1);

  /// Circular symmetric easing for smooth state transitions like progress.
  Curve get motionEaseInOutCirc => const Cubic(0.78, 0.14, 0.15, 0.86);

  /// Quintic decelerating easing for natural slowing entrances.
  Curve get motionEaseOutQuint => const Cubic(0.23, 1, 0.32, 1);
}
