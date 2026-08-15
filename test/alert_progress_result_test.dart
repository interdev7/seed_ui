import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('Alert', () {
    testWidgets('renders message and description', (tester) async {
      await tester.pumpWidget(
        _host(
          const Alert(
            message: Text('Saved'),
            description: Text('Your changes are live.'),
            type: StatusType.success,
            showIcon: true,
          ),
        ),
      );

      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Your changes are live.'), findsOneWidget);
    });

    testWidgets('closable removes the alert and fires onClose', (tester) async {
      var closed = false;
      await tester.pumpWidget(
        _host(
          Alert(
            message: const Text('Dismiss me'),
            closable: true,
            onClose: () => closed = true,
          ),
        ),
      );

      expect(find.text('Dismiss me'), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == 'CrossPainter',
        ),
      );
      await tester.pump();

      expect(find.text('Dismiss me'), findsNothing);
      expect(closed, isTrue);
    });

    testWidgets('renders a trailing action', (tester) async {
      await tester.pumpWidget(
        _host(
          Alert(
            message: const Text('Update available'),
            action: Button(
              size: SoftSize.small,
              onPressed: () {},
              child: const Text('Reload'),
            ),
          ),
        ),
      );

      expect(find.text('Reload'), findsOneWidget);
    });
  });

  group('Progress', () {
    testWidgets('line shows the percentage', (tester) async {
      await tester.pumpWidget(_host(const Progress(percent: 0.42)));
      expect(find.text('42%'), findsOneWidget);
    });

    testWidgets('showInfo: false hides the label', (tester) async {
      await tester
          .pumpWidget(_host(const Progress(percent: 0.42, showInfo: false)));
      expect(find.text('42%'), findsNothing);
    });

    testWidgets('a full circle renders without the percentage', (tester) async {
      await tester.pumpWidget(
        _host(
          const Progress(
            type: ProgressType.circle,
            percent: 1,
            status: StatusType.success,
          ),
        ),
      );
      // At 100% success a glyph replaces the number.
      expect(find.text('100%'), findsNothing);
    });

    testWidgets('supports dashboard type, gradient, steps, and custom format',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Progress(
            type: ProgressType.dashboard,
            percent: 0.75,
            gradient: const LinearGradient(colors: [Colors.red, Colors.yellow]),
            format: (p) => Text('Done ${(p * 100).round()} / 100'),
          ),
        ),
      );
      expect(find.text('Done 75 / 100'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          const Progress(
            type: ProgressType.dashboard,
            percent: 0.3,
            gapDegree: 90,
            gapPlacement: GapPlacement.top,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('30%'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          const Progress(
            type: ProgressType.circle,
            percent: 0.6,
            steps: ProgressSteps(5),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('60%'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          const Progress(
            type: ProgressType.circle,
            percent: 0.8,
            steps: ProgressSteps(5, gap: 7),
            strokeWidth: 20,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('80%'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          const Progress(
            percent: 0.4,
            strokeWidth: 14,
            borderRadius: ProgressBorderRadius.fixed(6),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('triggers onDone callback exactly once when complete',
        (tester) async {
      int doneCount = 0;
      await tester.pumpWidget(
        _host(
          Progress(
            percent: 1.0,
            onDone: () {
              doneCount++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(doneCount, equals(1));

      // Rebuild while still at 1.0 should not trigger onDone again
      await tester.pumpWidget(
        _host(
          Progress(
            percent: 1.0,
            onDone: () {
              doneCount++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(doneCount, equals(1));
    });

    testWidgets('triggers onProgressChange when percent updates',
        (tester) async {
      double? changedPercent;
      await tester.pumpWidget(
        _host(
          Progress(
            percent: 0.2,
            onProgressChange: (p) => changedPercent = p,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _host(
          Progress(
            percent: 0.7,
            onProgressChange: (p) => changedPercent = p,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(changedPercent, equals(0.7));
    });

    testWidgets('triggers onStepChange when active step updates',
        (tester) async {
      int? currentStep;
      int? totalSteps;
      await tester.pumpWidget(
        _host(
          Progress(
            percent: 0.2,
            steps: ProgressSteps(
              5,
              onStepChange: (step, total) {
                currentStep = step;
                totalSteps = total;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _host(
          Progress(
            percent: 0.8,
            steps: ProgressSteps(
              5,
              onStepChange: (step, total) {
                currentStep = step;
                totalSteps = total;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(currentStep, equals(4));
      expect(totalSteps, equals(5));
    });

    testWidgets('supports percentPosition for inner and outer info placement',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const Progress(
            percent: 0.5,
            strokeWidth: 20,
            percentPosition:
                PercentPosition.inner(align: PercentInfoAlign.center),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('50%'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          const Progress(
            percent: 0.6,
            percentPosition:
                PercentPosition.outer(align: PercentInfoAlign.start),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('60%'), findsOneWidget);
    });

    test('rejects an out-of-range percent', () {
      expect(() => Progress(percent: 1.5), throwsAssertionError);
    });
  });

  group('Result', () {
    testWidgets('renders title, subtitle and actions', (tester) async {
      await tester.pumpWidget(
        _host(
          Result(
            status: StatusType.success,
            title: const Text('Payment received'),
            subTitle: const Text('Order is being processed.'),
            extra: [
              Button(
                variant: ButtonVariant.solid,
                color: ButtonColor.primary,
                onPressed: () {},
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Payment received'), findsOneWidget);
      expect(find.text('Order is being processed.'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });
  });

  group('Progress child', () {
    testWidgets('a child takes the middle of a ring', (tester) async {
      await tester.pumpWidget(
        _host(
          const Progress(
            type: ProgressType.circle,
            percent: 0.6,
            child: Text('go'),
          ),
        ),
      );

      expect(find.text('go'), findsOneWidget);
      // It replaces the percentage, it does not sit beside it.
      expect(find.text('60%'), findsNothing);
    });

    testWidgets('a child stands in for the label on a bar', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            child: Progress(percent: 0.4, child: Text('go')),
          ),
        ),
      );

      expect(find.text('go'), findsOneWidget);
      expect(find.text('40%'), findsNothing);
    });

    testWidgets('copyWith replaces only what it is given', (tester) async {
      const original = Progress(
        percent: 0.2,
        type: ProgressType.dashboard,
        strokeWidth: 9,
        color: Color(0xFF112233),
      );
      final copy = original.copyWith(percent: 0.8, child: const Text('go'));

      expect(copy.percent, 0.8);
      expect(copy.child, isNotNull);
      expect(copy.type, ProgressType.dashboard);
      expect(copy.strokeWidth, 9);
      expect(copy.color, const Color(0xFF112233));
    });
  });
}
