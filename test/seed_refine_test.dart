import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

const _brand = Color(0xFFFFD500);

/// The token in force wherever [child] is built.
Future<Token> _tokenUnder(WidgetTester tester, Widget child) async {
  late Token seen;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(
        builder: (context) => child,
      ),
    ),
  );
  await tester.pumpAndSettle();
  seen = tester.state<TestReaderState>(find.byType(TestReader)).token;
  return seen;
}

/// Reads the token where it stands, so a test can look at it.
class TestReader extends StatefulWidget {
  const TestReader({super.key});

  @override
  State<TestReader> createState() => TestReaderState();
}

class TestReaderState extends State<TestReader> {
  late Token token;

  @override
  Widget build(BuildContext context) {
    token = context.softToken;
    return const SizedBox();
  }
}

void main() {
  group('a nested theme that changes one thing', () {
    testWidgets('keeps the font the app set', (tester) async {
      // `token:` replaces the seed outright, which is the trap: a fresh
      // SeedToken is all defaults, so naming a colour drops the font.
      final token = await _tokenUnder(
        tester,
        ConfigProvider(
          theme: ThemeData(
            token: const SeedToken(fontFamily: 'Georgia', borderRadius: 16),
          ),
          child: ConfigProvider(
            theme: ThemeData(
              refineSeed: (seed) => seed.copyWith(colorPrimary: _brand),
            ),
            child: const TestReader(),
          ),
        ),
      );

      expect(token.primary.base, _brand, reason: 'what it asked for');
      expect(token.fontFamily, 'Georgia', reason: 'kept from the app');
      expect(token.borderRadius, 16, reason: 'kept from the app');
    });

    testWidgets('and a bare token: still replaces the lot', (tester) async {
      // The old way, kept working — and kept honest about what it does.
      final token = await _tokenUnder(
        tester,
        ConfigProvider(
          theme: ThemeData(
            token: const SeedToken(fontFamily: 'Georgia', borderRadius: 16),
          ),
          child: ConfigProvider(
            theme: ThemeData(token: const SeedToken(colorPrimary: _brand)),
            child: const TestReader(),
          ),
        ),
      );
      expect(token.primary.base, _brand);
      expect(token.fontFamily, isNull, reason: 'a fresh seed is all defaults');
    });

    testWidgets('works with no theme above it at all', (tester) async {
      final token = await _tokenUnder(
        tester,
        ConfigProvider(
          theme: ThemeData(
            refineSeed: (seed) => seed.copyWith(colorPrimary: _brand),
          ),
          child: const TestReader(),
        ),
      );
      expect(token.primary.base, _brand);
    });

    testWidgets('survives a provider nested inside it', (tester) async {
      // Like `refine`: a subtree asked to be yellow stays yellow.
      final token = await _tokenUnder(
        tester,
        ConfigProvider(
          theme: ThemeData(
            refineSeed: (seed) => seed.copyWith(colorPrimary: _brand),
          ),
          child: ConfigProvider(
            theme: ThemeData.dark,
            child: const TestReader(),
          ),
        ),
      );
      expect(token.isDark, isTrue, reason: 'the lights went out');
      // In the dark the base shade is generated rather than the seed itself,
      // so what is checked is what the palette was built from.
      expect(
        token.seed.colorPrimary,
        _brand,
        reason: 'and it is still built from yellow',
      );
    });

    testWidgets('three deep, through a provider that says nothing', (
      tester,
    ) async {
      // The middle provider states a theme of its own but says nothing about
      // the seed, so it has to carry the refinement on rather than let it
      // stop there.
      final token = await _tokenUnder(
        tester,
        ConfigProvider(
          theme: ThemeData(
            refineSeed: (seed) => seed.copyWith(colorPrimary: _brand),
          ),
          child: ConfigProvider(
            theme: ThemeData(
              components: const ComponentsConfig(tag: TagToken(fontSize: 11)),
            ),
            child: ConfigProvider(
              theme: ThemeData.dark,
              child: const TestReader(),
            ),
          ),
        ),
      );
      expect(token.isDark, isTrue);
      expect(token.seed.colorPrimary, _brand);
    });

    testWidgets('the nearer refinement wins where both name one', (
      tester,
    ) async {
      const green = Color(0xFF52C41A);
      final token = await _tokenUnder(
        tester,
        ConfigProvider(
          theme: ThemeData(
            refineSeed: (seed) => seed.copyWith(colorPrimary: _brand),
          ),
          child: ConfigProvider(
            theme: ThemeData(
              refineSeed: (seed) => seed.copyWith(colorPrimary: green),
            ),
            child: const TestReader(),
          ),
        ),
      );
      expect(token.primary.base, green);
    });

    testWidgets('runs before the palette, refine after it', (tester) async {
      const ink = Color(0xFF123456);
      final token = await _tokenUnder(
        tester,
        ConfigProvider(
          theme: ThemeData(
            refineSeed: (seed) => seed.copyWith(colorPrimary: _brand),
            refine: (t) => t.copyWith(colorTextQuaternary: ink),
          ),
          child: const TestReader(),
        ),
      );
      expect(token.primary.base, _brand, reason: 'the seed was changed first');
      expect(token.colorTextQuaternary, ink, reason: 'then the tokens');
    });
  });
}
