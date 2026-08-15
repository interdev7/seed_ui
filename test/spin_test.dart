import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('Spin', () {
    testWidgets('renders standalone spin indicator', (tester) async {
      await tester.pumpWidget(_host(const Spin()));
      expect(find.byType(Spin), findsOneWidget);
    });

    testWidgets('renders tip text when provided', (tester) async {
      await tester.pumpWidget(
        _host(
          const Spin(
            tip: Text('Loading data...'),
          ),
        ),
      );
      expect(find.text('Loading data...'), findsOneWidget);
    });

    testWidgets('wraps child and shows overlay when spinning is true',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const Spin(
            spinning: true,
            tip: Text('Please wait...'),
            child: Text('Container Content'),
          ),
        ),
      );

      expect(find.text('Container Content'), findsOneWidget);
      expect(find.text('Please wait...'), findsOneWidget);

      final absorbPointers =
          tester.widgetList<AbsorbPointer>(find.byType(AbsorbPointer));
      expect(absorbPointers.any((ap) => ap.absorbing), isTrue);
    });

    testWidgets('hides overlay when spinning is false', (tester) async {
      await tester.pumpWidget(
        _host(
          const Spin(
            spinning: false,
            tip: Text('Please wait...'),
            child: Text('Container Content'),
          ),
        ),
      );

      expect(find.text('Container Content'), findsOneWidget);

      final animatedOpacity =
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).last);
      expect(animatedOpacity.opacity, equals(0.0));

      final absorbPointers =
          tester.widgetList<AbsorbPointer>(find.byType(AbsorbPointer));
      expect(absorbPointers.any((ap) => ap.absorbing), isFalse);
    });

    testWidgets('renders custom indicator widget', (tester) async {
      await tester.pumpWidget(
        _host(
          const Spin(
            indicator: Icon(Icons.sync),
          ),
        ),
      );

      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('delays spinning indicator when delay duration is specified',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const Spin(
            spinning: true,
            delay: Duration(milliseconds: 500),
            tip: Text('Syncing...'),
            child: Text('Content'),
          ),
        ),
      );

      // Initially before delay, spin opacity is 0.0
      expect(find.text('Content'), findsOneWidget);
      var animatedOpacity =
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).last);
      expect(animatedOpacity.opacity, equals(0.0));

      // Advance clock past delay
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));

      // Spin opacity is now 1.0
      animatedOpacity =
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).last);
      expect(animatedOpacity.opacity, equals(1.0));
    });

    testWidgets('renders fullscreen overlay when fullscreen is true',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const Spin(
            fullscreen: true,
            tip: Text('Fullscreen loading...'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Fullscreen loading...'), findsOneWidget);
    });

    testWidgets('renders Progress circle when percent is provided',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const Spin(
            percent: 50,
            tip: Text('50% loading...'),
          ),
        ),
      );

      expect(find.text('50% loading...'), findsOneWidget);
      expect(find.byType(Progress), findsOneWidget);
    });
  });
}
