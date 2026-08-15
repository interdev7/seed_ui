import 'dart:async';

import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      navigatorKey: UiKit.navigatorKey,
      home: Scaffold(body: Center(child: child)),
    );

/// Places the trigger at an arbitrary corner to test viewport clamping.
Widget _hostAt(Widget child, Alignment alignment) => MaterialApp(
      navigatorKey: UiKit.navigatorKey,
      home: Scaffold(body: Align(alignment: alignment, child: child)),
    );

/// See `message_test.dart`: `pumpAndSettle` is unusable with the kit's
/// perpetual animations. The trailing pump lets the overlay rebuild after the
/// exit animation completes.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump();
}

void main() {
  testWidgets('tapping the trigger opens the bubble', (tester) async {
    await tester.pumpWidget(
      _host(
        Popconfirm(
          title: const Text('Delete this item?'),
          onOk: () {},
          child: const Text('trigger'),
        ),
      ),
    );

    expect(find.text('Delete this item?'), findsNothing);
    await tester.tap(find.text('trigger'));
    await _settle(tester);
    expect(find.text('Delete this item?'), findsOneWidget);
  });

  testWidgets('opens even when the trigger has its own gesture handler',
      (tester) async {
    // Regression: a Button owns a GestureDetector that wins the arena, so
    // an outer onTap would never fire. The trigger's own tap must still run.
    var triggerTapped = false;
    await tester.pumpWidget(
      _host(
        Popconfirm(
          title: const Text('Delete this item?'),
          onOk: () {},
          child: Button(
            onPressed: () => triggerTapped = true,
            child: const Text('trigger'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await _settle(tester);

    expect(triggerTapped, isTrue);
    expect(find.text('Delete this item?'), findsOneWidget);
  });

  testWidgets('confirm fires onOk and closes', (tester) async {
    var confirmed = false;
    await tester.pumpWidget(
      _host(
        Popconfirm(
          title: const Text('Sure?'),
          onOk: () => confirmed = true,
          child: const Text('trigger'),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await _settle(tester);
    await tester.tap(find.text('OK'));
    await _settle(tester);

    expect(confirmed, isTrue);
    expect(find.text('Sure?'), findsNothing);
  });

  testWidgets('cancel fires onCancel and closes', (tester) async {
    var cancelled = false;
    await tester.pumpWidget(
      _host(
        Popconfirm(
          title: const Text('Sure?'),
          onCancel: () => cancelled = true,
          onOk: () {},
          child: const Text('trigger'),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await _settle(tester);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);

    expect(cancelled, isTrue);
    expect(find.text('Sure?'), findsNothing);
  });

  testWidgets('an outside tap dismisses the bubble', (tester) async {
    await tester.pumpWidget(
      _host(
        Popconfirm(
          title: const Text('Sure?'),
          onOk: () {},
          child: const Text('trigger'),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await _settle(tester);
    expect(find.text('Sure?'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await _settle(tester);
    expect(find.text('Sure?'), findsNothing);
  });

  testWidgets('an async onOk holds the bubble open until it settles',
      (tester) async {
    final gate = Completer<void>();
    await tester.pumpWidget(
      _host(
        Popconfirm(
          title: const Text('Saving?'),
          onOk: () => gate.future,
          child: const Text('trigger'),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await _settle(tester);
    await tester.tap(find.text('OK'));
    await tester.pump();

    // Still open while the handler runs.
    expect(find.text('Saving?'), findsOneWidget);

    gate.complete();
    await _settle(tester);
    expect(find.text('Saving?'), findsNothing);
  });

  testWidgets('disabled never opens the bubble', (tester) async {
    var confirmed = false;
    await tester.pumpWidget(
      _host(
        Popconfirm(
          title: const Text('Sure?'),
          disabled: true,
          onOk: () => confirmed = true,
          child: const Text('trigger'),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await _settle(tester);
    expect(find.text('Sure?'), findsNothing);
    expect(confirmed, isFalse);
  });

  testWidgets('the bubble stays within the viewport at every corner',
      (tester) async {
    const alignments = [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ];

    for (final alignment in alignments) {
      await tester.pumpWidget(
        _hostAt(
          Popconfirm(
            title: const Text('Delete this item?'),
            description: const Text('This action cannot be undone.'),
            onOk: () {},
            child: const Text('trigger'),
          ),
          alignment,
        ),
      );

      await tester.tap(find.text('trigger'));
      await _settle(tester);

      final bubble = tester.getRect(find.text('Delete this item?'));
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(
        bubble.left,
        greaterThanOrEqualTo(0),
        reason: 'off left at $alignment',
      );
      expect(
        bubble.top,
        greaterThanOrEqualTo(0),
        reason: 'off top at $alignment',
      );
      expect(
        bubble.right,
        lessThanOrEqualTo(screen.width),
        reason: 'off right at $alignment',
      );
      expect(
        bubble.bottom,
        lessThanOrEqualTo(screen.height),
        reason: 'off bottom at $alignment',
      );

      await tester.tapAt(const Offset(1, 1));
      await _settle(tester);
    }
  });

  testWidgets('right placement stays on screen when neither side has room',
      (tester) async {
    // A wide bubble on a trigger centred horizontally fits on neither side,
    // so the main-axis position must be clamped, not just flipped.
    await tester.pumpWidget(
      _hostAt(
        Popconfirm(
          title: const Text(
              'A deliberately long confirmation question that is wide'),
          description:
              const Text('With a second line of detail to widen the bubble.'),
          placement: PopoverPlacement.right,
          onOk: () {},
          child: const Text('trigger'),
        ),
        Alignment.center,
      ),
    );

    await tester.tap(find.text('trigger'));
    await _settle(tester);

    final bubble = tester.getRect(
      find.text('A deliberately long confirmation question that is wide'),
    );
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(bubble.left, greaterThanOrEqualTo(0));
    expect(bubble.right, lessThanOrEqualTo(screen.width));

    await tester.tapAt(const Offset(1, 1));
    await _settle(tester);
  });

  testWidgets('an arrow is drawn by default and suppressed by arrow: false',
      (tester) async {
    Finder arrow() => find.byKey(const Key('softPopoverArrow'));

    await tester.pumpWidget(
      _host(
        Popconfirm(
          title: const Text('Sure?'),
          onOk: () {},
          child: const Text('with-arrow'),
        ),
      ),
    );
    await tester.tap(find.text('with-arrow'));
    await _settle(tester);
    expect(arrow(), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await _settle(tester);

    await tester.pumpWidget(
      _host(
        Popconfirm(
          title: const Text('Sure?'),
          arrow: false,
          onOk: () {},
          child: const Text('no-arrow'),
        ),
      ),
    );
    await tester.tap(find.text('no-arrow'));
    await _settle(tester);
    expect(arrow(), findsNothing);

    await tester.tapAt(const Offset(5, 5));
    await _settle(tester);
  });

  testWidgets('scrolling the page dismisses an open popconfirm',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: Scaffold(
          body: ListView(
            children: [
              const SizedBox(height: 40),
              Popconfirm(
                title: const Text('Sure?'),
                onOk: () {},
                child: const Text('trigger'),
              ),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await _settle(tester);
    expect(find.text('Sure?'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await _settle(tester);
    expect(find.text('Sure?'), findsNothing);
  });

  testWidgets('showCancel: false hides the cancel button', (tester) async {
    await tester.pumpWidget(
      _host(
        Popconfirm(
          title: const Text('Sure?'),
          showCancel: false,
          onOk: () {},
          child: const Text('trigger'),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await _settle(tester);
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });
}
