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
}
