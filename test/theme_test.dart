import 'dart:io';

import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

void main() {
  test('default seed leaves fonts to the platform', () {
    const seed = SeedToken();
    // A null primary uses the OS UI font (San Francisco, Roboto, …); a null
    // fallback avoids the wide-space bug that emoji fonts can trigger.
    expect(seed.fontFamily, isNull);
    expect(seed.fontFamilyFallback, isNull);
  });

  test('the dark theme rebuilds the ramps from a dark base', () {
    final light = ThemeData().token;
    final dark = ThemeData(dark: true).token;

    expect(light.isDark, isFalse);
    expect(dark.isDark, isTrue);
    // Surfaces invert: the page and container darken.
    expect(
      dark.colorBgContainer.computeLuminance(),
      lessThan(light.colorBgContainer.computeLuminance()),
    );
    // Text lightens so it reads on the dark surface.
    expect(
      dark.colorText.computeLuminance(),
      greaterThan(light.colorText.computeLuminance()),
    );
  });

  testWidgets('a component picks up the theme from the provider',
      (tester) async {
    Future<Color> bg(bool dark) async {
      await tester.pumpWidget(
        ConfigProvider(
          theme: ThemeData(dark: dark),
          child: MaterialApp(
            home: Builder(
              builder: (context) => ColoredBox(
                key: const Key('probe'),
                color: context.softToken.colorBgContainer,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      return tester.widget<ColoredBox>(find.byKey(const Key('probe'))).color;
    }

    final lightBg = await bg(false);
    final darkBg = await bg(true);
    expect(darkBg.computeLuminance(), lessThan(lightBg.computeLuminance()));
  });

  test('dark status tints stay dark so light text reads on them', () {
    final dark = ThemeData(dark: true).token;
    // Regression: the palette must blend into the dark surface, not the seed's
    // light background, or these tints come out pale and white text vanishes.
    for (final group in [dark.success, dark.error, dark.info, dark.warning]) {
      expect(
        group.bg.computeLuminance(),
        lessThan(0.2),
        reason: 'a status bg tint is too light for white text',
      );
    }
  });

  test('dark neutral fills are stronger than light ones', () {
    final light = ThemeData().token;
    final dark = ThemeData(dark: true).token;
    // A faint overlay reads weaker on dark, so the dark alphas must be higher —
    // otherwise a progress track disappears.
    expect(dark.colorFillSecondary.a, greaterThan(light.colorFillSecondary.a));
  });

  test('a derived token exposes the seed fallback', () {
    final token = Token.derive(
      const SeedToken(fontFamilyFallback: ['Inter']),
    );
    expect(token.fontFamilyFallback, ['Inter']);
  });

  test('copyWith overrides the fallback', () {
    const seed = SeedToken();
    final custom = seed.copyWith(fontFamilyFallback: ['Inter']);
    expect(custom.fontFamilyFallback, ['Inter']);
    expect(custom.fontFamily, isNull);
  });

  testWidgets('a custom fallback reaches a rendered button label',
      (tester) async {
    await tester.pumpWidget(
      ConfigProvider(
        theme: ThemeData(
          token: const SeedToken(fontFamilyFallback: ['Inter']),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Button(onPressed: () {}, child: const Text('Tap')),
            ),
          ),
        ),
      ),
    );

    // The button injects its style through a DefaultTextStyle above the label,
    // so read the resolved style at the Text's location.
    final style =
        DefaultTextStyle.of(tester.element(find.text('Tap').hitTestable()))
            .style;
    expect(style.fontFamilyFallback, ['Inter']);
  });

  testWidgets('ComponentsConfig provides typed component token lookup',
      (tester) async {
    await tester.pumpWidget(
      ConfigProvider(
        theme: ThemeData(
          components: const ComponentsConfig(
            avatar: AvatarToken(colorTextPlaceholder: Colors.white),
            button: ButtonToken(controlHeight: 40),
          ),
        ),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final avatarToken =
                  ConfigProvider.componentOf<AvatarToken>(context);
              final buttonToken =
                  ConfigProvider.componentOf<ButtonToken>(context);
              expect(avatarToken?.colorTextPlaceholder, Colors.white);
              expect(buttonToken?.controlHeight, 40);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  });

  // A component whose token never reaches ComponentsConfig cannot be themed
  // through `theme.components` at all — a gap that is silent at the call site,
  // so it is checked against the source instead.
  test('ComponentsConfig knows every component token', () {
    final declared = <String>{};
    for (final entity
        in Directory('lib/src/components').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      for (final match
          in RegExp(r'^class ([A-Za-z]\w*Token) \{', multiLine: true)
              .allMatches(entity.readAsStringSync())) {
        declared.add(match.group(1)!);
      }
    }

    final config =
        File('lib/src/theme/components_config.dart').readAsStringSync();
    final wired = RegExp(r'(\w+Token)\?')
        .allMatches(config)
        .map((m) => m.group(1)!)
        .toSet();

    expect(declared, isNotEmpty);
    expect(
      declared.difference(wired),
      isEmpty,
      reason: 'these tokens are missing from ComponentsConfig',
    );
  });

  test('a default seed keeps the classic Ant surfaces', () {
    final light = ThemeData.light.token;
    expect(light.colorBgContainer, const Color(0xFFFFFFFF));
    expect(light.colorBgLayout, const Color(0xFFF5F5F5));
    expect(light.colorBorder, const Color(0xFFD9D9D9));
    expect(light.colorBorderSecondary, const Color(0xFFF0F0F0));

    final dark = ThemeData.dark.token;
    expect(dark.colorBgContainer, const Color(0xFF141414));
    expect(dark.colorBgElevated, const Color(0xFF1F1F1F));
    expect(dark.colorBgLayout, const Color(0xFF000000));
    expect(dark.colorBorder, const Color(0xFF424242));
  });

  test('a seed that names its own background tints the surfaces', () {
    // Light scheme, warm paper.
    final paper = ThemeData(
      token: const SeedToken(
        colorBgBase: Color(0xFFFFFCF6),
        colorTextBase: Color(0xFF2A1D18),
      ),
    ).token;
    expect(paper.colorBgContainer, const Color(0xFFFFFCF6));
    expect(
      paper.colorBgLayout.g,
      lessThan(paper.colorBgContainer.g),
      reason: 'the page sits a touch deeper than a panel',
    );
    expect(
      paper.colorBorder.r,
      greaterThan(paper.colorBorder.b),
      reason: 'borders inherit the warmth of the ink',
    );

    // Dark scheme, spruce night: the seed is honoured because it is dark too.
    final night = ThemeData(
      dark: true,
      token: const SeedToken(
        colorBgBase: Color(0xFF101C17),
        colorTextBase: Color(0xFFF2EDE6),
      ),
    ).token;
    expect(night.colorBgContainer, const Color(0xFF101C17));
    expect(
      night.colorBgElevated.g,
      greaterThan(night.colorBgContainer.g),
      reason: 'floating surfaces lift off the page',
    );
  });

  test('a light background is ignored by a dark scheme', () {
    // The default seed is white paper; asking for dark must not paint the page
    // white, so the classic dark surfaces stand in.
    final dark = ThemeData(
      dark: true,
      token: const SeedToken(colorPrimary: Color(0xFF1B7A4B)),
    ).token;
    expect(dark.colorBgContainer, const Color(0xFF141414));
  });

  group('System status bar', () {
    SystemUiOverlayStyle? styleOf(WidgetTester tester) {
      final regions = tester.widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      );
      return regions.isEmpty ? null : regions.first.value;
    }

    testWidgets('a dark theme asks for light status-bar icons', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          theme: ThemeData(dark: true),
          child: const SizedBox(),
        ),
      );

      final style = styleOf(tester);
      expect(style, isNotNull);
      // Android names the icons, iOS names the background they sit on, so the
      // two are inverses.
      expect(style!.statusBarIconBrightness, Brightness.light);
      expect(style.statusBarBrightness, Brightness.dark);
    });

    testWidgets('a light theme asks for dark status-bar icons', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(child: const SizedBox()),
      );

      final style = styleOf(tester);
      expect(style, isNotNull);
      expect(style!.statusBarIconBrightness, Brightness.dark);
      expect(style.statusBarBrightness, Brightness.light);
    });

    testWidgets('the bar colour is left to the app', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          theme: ThemeData(dark: true),
          child: const SizedBox(),
        ),
      );

      // Only legibility is claimed; a translucent or coloured bar the app set
      // must survive.
      expect(styleOf(tester)!.statusBarColor, isNull);
    });

    testWidgets('an app driving its own chrome can opt out', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          theme: ThemeData(dark: true),
          systemOverlayStyle: false,
          child: const SizedBox(),
        ),
      );

      expect(styleOf(tester), isNull);
    });
  });
}
