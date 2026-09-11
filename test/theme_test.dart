import 'dart:io';

import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

void main() {
  _refinementTests();

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
  test('every defaults a component asks for can be supplied', () {
    // A defaults class a component reads but nobody can pass is a promise
    // with no way to keep it. Three of them shipped that way: the component
    // asked `defaultsOf<XDefaults>` and `ComponentDefaults` had no slot to
    // put one in, so the answer was always null.
    //
    // Asked of what the components actually read rather than of every class
    // whose name ends in Defaults: `TableColumnDefaults` is defaults for a
    // table's columns, handed to the table itself, and has no business in a
    // subtree.
    final asked = <String>{};
    for (final entity
        in Directory('lib/src/components').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      for (final match in RegExp(r'defaultsOf<(\w+)>')
          .allMatches(entity.readAsStringSync())) {
        asked.add(match.group(1)!);
      }
    }

    final config =
        File('lib/src/theme/component_defaults.dart').readAsStringSync();
    final reachable = RegExp(r'T == (\w+Defaults)')
        .allMatches(config)
        .map((m) => m.group(1)!)
        .toSet();

    expect(asked, isNotEmpty);
    expect(
      asked.difference(reachable),
      isEmpty,
      reason: 'these defaults cannot be supplied through ComponentDefaults',
    );

    // And a slot whose class nobody outside the package can name is the same
    // promise from the other end: `ComponentDefaults(badge: ...)` cannot be
    // written where `BadgeDefaults` is not exported. Seven shipped that way.
    final barrel = File('lib/seed_ui.dart').readAsStringSync();
    expect(
      reachable.where((name) => !RegExp('\\b$name\\b').hasMatch(barrel)),
      isEmpty,
      reason: 'these defaults are not exported, so nobody can write one',
    );
  });

  test('the theming document lists every defaults slot and its fields', () {
    // The table in doc/theming.md is the only place a caller finds out what
    // can be set for a subtree. It had drifted: eight components missing, and
    // the `size`/`disabled` fields listed in prose that had stopped matching.
    final config =
        File('lib/src/theme/component_defaults.dart').readAsStringSync();
    final slots = RegExp(r'T == (\w+)Defaults')
        .allMatches(config)
        .map((m) => m.group(1)!)
        .toList();

    final fields = <String, List<String>>{};
    for (final entity
        in Directory('lib/src/components').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      for (final match
          in RegExp(r'class (\w+Defaults) \{(.*?)\n\}', dotAll: true)
              .allMatches(entity.readAsStringSync())) {
        fields[match.group(1)!] = RegExp(r'final [\w<>,?. ]+\??\s(\w+);')
            .allMatches(match.group(2)!)
            .map((m) => m.group(1)!)
            .toList();
      }
    }

    final doc = File('doc/theming.md').readAsStringSync();
    final missing = <String>[];
    for (final slot in slots) {
      // The slot is named for the field on ComponentDefaults; the component
      // it stands for is the same word, but `switch` is not a name in Dart.
      final name = slot == 'SwitchControl' ? 'Switch' : slot;
      final row = RegExp('^\\| `$name` \\| (.*) \\|\$', multiLine: true)
          .firstMatch(doc);
      if (row == null) {
        missing.add('$name has no row');
        continue;
      }
      for (final field in fields['${slot}Defaults'] ?? const <String>[]) {
        if (!row.group(1)!.contains('`$field`')) {
          missing.add('$name is missing $field');
        }
      }
    }
    expect(missing, isEmpty, reason: 'doc/theming.md is behind the code');
  });

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
        const ConfigProvider(child: SizedBox()),
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
  group('providers nest', () {
    Widget button() => Button(
          size: SoftSize.large,
          onPressed: () {},
          child: const Text('Pay'),
        );

    Future<double> heightUnder(WidgetTester tester, Widget tree) async {
      await tester.pumpWidget(tree);
      await tester.pumpAndSettle();
      return tester.getRect(find.byType(Button)).height;
    }

    testWidgets(
        'an inner provider silent about a component keeps the outer '
        "one's token", (tester) async {
      const outer = ComponentsConfig(button: ButtonToken(controlHeightLG: 52));

      final alone = await heightUnder(
        tester,
        ConfigProvider(
          theme: ThemeData(components: outer),
          child: MaterialApp(home: Scaffold(body: Center(child: button()))),
        ),
      );

      // A second provider deeper — a theme switcher, a corner that recolours
      // itself — carrying a theme and nothing else. Stopping the search at the
      // nearest provider is what made a token set once at the top of an app
      // fail to reach a button two providers down.
      final nested = await heightUnder(
        tester,
        ConfigProvider(
          theme: ThemeData(components: outer),
          child: MaterialApp(
            home: ConfigProvider(
              theme: ThemeData(),
              child: Scaffold(body: Center(child: button())),
            ),
          ),
        ),
      );

      expect(alone, 52);
      expect(nested, alone, reason: 'the inner one said nothing about buttons');
    });

    testWidgets('an inner provider that does name one still wins', (
      tester,
    ) async {
      final height = await heightUnder(
        tester,
        ConfigProvider(
          theme: ThemeData(
            components: const ComponentsConfig(
              button: ButtonToken(controlHeightLG: 52),
            ),
          ),
          child: MaterialApp(
            home: ConfigProvider(
              theme: ThemeData(
                components: const ComponentsConfig(
                  button: ButtonToken(controlHeightLG: 64),
                ),
              ),
              child: Scaffold(body: Center(child: button())),
            ),
          ),
        ),
      );
      expect(height, 64, reason: 'the nearer word on the matter');
    });

    testWidgets('a change to the outer one reaches through the inner', (
      tester,
    ) async {
      Widget tree(double height) => ConfigProvider(
            theme: ThemeData(
              components: ComponentsConfig(
                button: ButtonToken(controlHeightLG: height),
              ),
            ),
            child: MaterialApp(
              home: ConfigProvider(
                theme: ThemeData(),
                child: Scaffold(body: Center(child: button())),
              ),
            ),
          );

      expect(await heightUnder(tester, tree(52)), 52);
      // Depending on every provider consulted, not merely the nearest, is what
      // makes this rebuild.
      expect(await heightUnder(tester, tree(60)), 60);
    });
  });

  group('a nested theme inherits', () {
    const pink = Color(0xFFEB2F96);

    /// Reads the resolved config from inside [inner], nested under [outer].
    Future<T> under<T>(
      WidgetTester tester,
      ThemeData? outer,
      ThemeData? inner,
      T Function(BuildContext context) read,
    ) async {
      late T seen;
      await tester.pumpWidget(
        ConfigProvider(
          theme: outer,
          child: ConfigProvider(
            theme: inner,
            child: Builder(
              builder: (context) {
                seen = read(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      return seen;
    }

    testWidgets('a theme naming only components keeps the palette above it',
        (tester) async {
      final colour = await under(
        tester,
        ThemeData(token: const SeedToken(colorPrimary: pink)),
        ThemeData(
          components: const ComponentsConfig(
            button: ButtonToken(borderRadius: 16),
          ),
        ),
        (context) => context.softToken.primary.base,
      );
      expect(
        colour,
        pink,
        reason: 'saying something about buttons is not a word about colour',
      );
    });

    testWidgets('a theme naming only a palette keeps the brightness above it',
        (tester) async {
      final dark = await under(
        tester,
        ThemeData.dark,
        ThemeData(token: const SeedToken(colorPrimary: pink)),
        (context) => context.softToken.isDark,
      );
      expect(dark, isTrue, reason: 'the lights were never asked to come on');
    });

    testWidgets('a theme naming only the brightness keeps the palette',
        (tester) async {
      final token = await under(
        tester,
        ThemeData(token: const SeedToken(colorPrimary: pink)),
        ThemeData.dark,
        (context) => context.softToken,
      );
      expect(token.isDark, isTrue);
      expect(
        token.primary.base,
        isNot(ThemeData(token: const SeedToken(colorPrimary: pink))
            .token
            .primary
            .base),
        reason: 'the same seed in the dark is a different shade',
      );
      // Derived from the inherited seed rather than the default blue.
      expect(
        token.primary.base,
        Token.derive(const SeedToken(colorPrimary: pink), dark: true)
            .primary
            .base,
      );
    });

    testWidgets('a ready-made token is taken as final', (tester) async {
      final ready = ThemeData(token: const SeedToken(colorPrimary: pink)).token;
      final dark = await under(
        tester,
        ThemeData.dark,
        ThemeData.raw(ready),
        (context) => context.softToken.isDark,
      );
      expect(dark, isFalse, reason: 'ThemeData.raw does not re-derive');
    });

    testWidgets('component tokens from both providers are in scope',
        (tester) async {
      final tokens = await under(
        tester,
        ThemeData(
          components: const ComponentsConfig(
            button: ButtonToken(controlHeightLG: 52),
          ),
        ),
        ThemeData(
          components: const ComponentsConfig(card: CardToken(headerHeight: 30)),
        ),
        (context) => (
          ConfigProvider.componentOf<ButtonToken>(context)?.controlHeightLG,
          ConfigProvider.componentOf<CardToken>(context)?.headerHeight,
        ),
      );
      expect(tokens.$1, 52, reason: 'the outer one is still there');
      expect(tokens.$2, 30);
    });

    testWidgets('emptyBuilder carries through a provider silent about it',
        (tester) async {
      late EmptyBuilder? seen;
      await tester.pumpWidget(
        ConfigProvider(
          emptyBuilder: (context, slot) => const Text('nothing here'),
          child: ConfigProvider(
            theme: ThemeData(),
            child: Builder(
              builder: (context) {
                seen = ConfigProvider.emptyBuilderOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(seen, isNotNull);
    });

    testWidgets('the locale carries through, and the nearer one still wins',
        (tester) async {
      late String inherited;
      late String nearer;
      await tester.pumpWidget(
        ConfigProvider(
          locale: const SeedLocalizations().copyWith(noData: 'OUTER'),
          child: Column(
            children: [
              ConfigProvider(
                theme: ThemeData(),
                child: Builder(
                  builder: (context) {
                    inherited = context.seedLocale.noData;
                    return const SizedBox();
                  },
                ),
              ),
              ConfigProvider(
                locale: const SeedLocalizations().copyWith(noData: 'INNER'),
                child: Builder(
                  builder: (context) {
                    nearer = context.seedLocale.noData;
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      );
      expect(inherited, 'OUTER');
      expect(nearer, 'INNER');
    });
  });
}

void _refinementTests() {
  group('a value the design names outright', () {
    const ink = Color(0xFF9CA3AF);

    test('refine has the last word on a derived token', () {
      final theme = ThemeData(
        token: const SeedToken(colorPrimary: Color(0xFFEB2F96)),
        refine: (t) => t.copyWith(colorTextQuaternary: ink),
      );
      expect(theme.token.colorTextQuaternary, ink);
      // And nothing else moved with it.
      expect(
        theme.token.colorText,
        Token.derive(const SeedToken(colorPrimary: Color(0xFFEB2F96)))
            .colorText,
      );
    });

    test('it is told which way the lights are, so one line names both', () {
      Token refine(Token t) => t.copyWith(
            colorTextQuaternary:
                t.isDark ? const Color(0xFF4F4F4F) : const Color(0xFFBFBFBF),
          );
      expect(
        ThemeData(refine: refine).token.colorTextQuaternary,
        const Color(0xFFBFBFBF),
      );
      expect(
        ThemeData(dark: true, refine: refine).token.colorTextQuaternary,
        const Color(0xFF4F4F4F),
      );
    });

    testWidgets('it survives a nested provider flipping the lights',
        (tester) async {
      late Token inner;
      await tester.pumpWidget(
        ConfigProvider(
          theme: ThemeData(
            token: const SeedToken(colorPrimary: Color(0xFFEB2F96)),
            refine: (t) => t.copyWith(colorTextQuaternary: ink),
          ),
          child: ConfigProvider(
            theme: ThemeData(dark: true),
            child: Builder(
              builder: (context) {
                inner = context.softToken;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(inner.isDark, isTrue, reason: 'the lights went out');
      expect(
        inner.colorTextQuaternary,
        ink,
        reason: 're-derived, then refined again',
      );
    });

    testWidgets('a nested refinement wins over the one above it',
        (tester) async {
      late Token inner;
      await tester.pumpWidget(
        ConfigProvider(
          // A seed above, so the nested theme re-derives from it rather than
          // keeping its own tokens whole — which is the path where whose
          // refinement it is actually decides something.
          theme: ThemeData(
            token: const SeedToken(colorPrimary: Color(0xFFEB2F96)),
            refine: (t) => t.copyWith(colorTextQuaternary: ink),
          ),
          child: ConfigProvider(
            theme: ThemeData(
              dark: true,
              refine: (t) => t.copyWith(
                colorTextQuaternary: const Color(0xFF112233),
              ),
            ),
            child: Builder(
              builder: (context) {
                inner = context.softToken;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(inner.colorTextQuaternary, const Color(0xFF112233));
    });

    testWidgets('a disabled control is written in the ink it names',
        (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          theme: ThemeData(
            refine: (t) => t.copyWith(colorTextQuaternary: ink),
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: Center(child: Button(child: Text('Nothing doing'))),
            ),
          ),
        ),
      );
      final style = DefaultTextStyle.of(
        tester.element(find.text('Nothing doing')),
      ).style;
      expect(style.color, ink);
    });
  });
}
