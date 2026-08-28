import 'package:flutter/material.dart' hide ThemeData;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => ConfigProvider(
      theme: ThemeData(),
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('renders button with label', (tester) async {
    await tester.pumpWidget(
      _host(
        const Button(child: Text('Submit')),
      ),
    );
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('handles taps', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      _host(
        Button(
          onPressed: () => tapped = true,
          child: const Text('Tap Me'),
        ),
      ),
    );

    await tester.tap(find.text('Tap Me'));
    expect(tapped, isTrue);
  });

  testWidgets('disabled button ignores taps', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      _host(
        Button(
          onPressed: () => tapped = true,
          disabled: true,
          child: const Text('Disabled'),
        ),
      ),
    );

    await tester.tap(find.text('Disabled'));
    expect(tapped, isFalse);
  });

  testWidgets('shows loading indicator when loading', (tester) async {
    await tester.pumpWidget(
      _host(
        const Button(
          loading: true,
          child: Text('Loading'),
        ),
      ),
    );
    expect(find.byType(Spinner), findsOneWidget);
  });

  testWidgets('renders button with gradient background', (tester) async {
    await tester.pumpWidget(
      _host(
        const Button(
          gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
          child: Text('Gradient Button'),
        ),
      ),
    );
    expect(find.text('Gradient Button'), findsOneWidget);
  });

  testWidgets('a button waking up does not flash grey', (tester) async {
    // The disabled fill is a few per cent of black. Animated straight to an
    // opaque colour, the midpoint of that lerp is a half-transparent mid-grey
    // — a visible flash. Composited onto the surface first, the whole
    // animation stays light.
    var enabled = false;
    await tester.pumpWidget(
      ConfigProvider(
        theme: ThemeData.light,
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  Button(
                    onPressed: enabled ? () {} : null,
                    child: const Text('Back'),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => enabled = !enabled),
                    child: const Text('flip'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    double luminance() {
      final decoration = tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.text('Back'),
              matching: find.byType(DecoratedBox),
            ),
          )
          .first
          .decoration as BoxDecoration;
      return Color.alphaBlend(decoration.color!, const Color(0xFFFFFFFF))
          .computeLuminance();
    }

    final disabled = luminance();
    await tester.tap(find.text('flip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final midway = luminance();
    await tester.pump(const Duration(milliseconds: 300));
    final live = luminance();

    expect(live, greaterThan(disabled));
    expect(
      midway,
      greaterThanOrEqualTo(disabled - 0.02),
      reason: 'the fill dipped to $midway on the way from $disabled to $live',
    );
  });

  group('size takes a preset or a measurement', () {
    Future<Size> boxOf(
      WidgetTester tester,
      ControlSize? size, {
      ButtonShape shape = ButtonShape.defaultShape,
      bool iconOnly = false,
    }) async {
      await tester.pumpWidget(
        _host(
          Button(
            size: size,
            shape: shape,
            icon: const Icon(Icons.search),
            onPressed: () {},
            child: iconOnly ? null : const Text('Go'),
          ),
        ),
      );
      // The box rides an AnimatedContainer, so settle before measuring.
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(Button));
    }

    double fontOf(WidgetTester tester) =>
        DefaultTextStyle.of(tester.element(find.byType(Icon))).style.fontSize!;

    testWidgets('a preset still walks the theme scale', (tester) async {
      expect((await boxOf(tester, SoftSize.small)).height, 24);
      expect((await boxOf(tester, null)).height, 32);
      expect((await boxOf(tester, SoftSize.large)).height, 40);
    });

    testWidgets('a height is taken as given', (tester) async {
      expect((await boxOf(tester, const ControlSize.height(54))).height, 54);
      // Past both ends of the preset scale, too.
      expect((await boxOf(tester, const ControlSize.height(18))).height, 18);
    });

    testWidgets('a circle is as wide as it is tall', (tester) async {
      // The case that sent us here: a round icon button sized by hand.
      expect(
        await boxOf(
          tester,
          const ControlSize.height(54),
          shape: ButtonShape.circle,
          iconOnly: true,
        ),
        const Size(54, 54),
      );
      // Two dimensions on a circle would make an oval, so it takes the larger
      // side — as an Avatar does.
      expect(
        await boxOf(
          tester,
          const ControlSize.box(60, 30),
          shape: ButtonShape.circle,
          iconOnly: true,
        ),
        const Size(60, 60),
      );
    });

    testWidgets('a two-dimensional size names the width too', (tester) async {
      expect(
        await boxOf(tester, const ControlSize.box(200, 36)),
        const Size(200, 36),
      );
    });

    testWidgets('a width alone leaves the height to the presets',
        (tester) async {
      expect(
        await boxOf(tester, const ControlSize.width(180)),
        const Size(180, 32),
      );
    });

    testWidgets('the type follows the height it is given', (tester) async {
      // A measurement names a height and nothing else; the rest comes from
      // the preset it is nearest to, so a hand-sized button still looks like
      // one of the family.
      await boxOf(tester, const ControlSize.height(54));
      final big = fontOf(tester);
      await boxOf(tester, const ControlSize.height(20));
      final small = fontOf(tester);

      await boxOf(tester, SoftSize.large);
      expect(big, fontOf(tester), reason: '54 is nearest the large preset');
      await boxOf(tester, SoftSize.small);
      expect(small, fontOf(tester), reason: '20 is nearest the small one');
      expect(small, lessThan(big));
    });

    testWidgets('a theme that moves its scale carries the type with it',
        (tester) async {
      // The preset is chosen by distance against the theme's own heights, not
      // against numbers written down here.
      Future<double> fontUnder(ButtonToken token) async {
        await tester.pumpWidget(
          ConfigProvider(
            theme: ThemeData(components: ComponentsConfig(button: token)),
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Button(
                    size: const ControlSize.height(54),
                    icon: const Icon(Icons.search),
                    onPressed: () {},
                    child: const Text('Go'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return fontOf(tester);
      }

      // Large moved out of reach, so 54 is nearest the middle preset.
      expect(await fontUnder(const ButtonToken(controlHeightLG: 90)), 14);
      // Small moved up to meet it, so now 54 is nearest that one — which a
      // scale written down in the component rather than read from the theme
      // could not follow.
      expect(await fontUnder(const ButtonToken(controlHeightSM: 50)), 12);
    });
  });
}
