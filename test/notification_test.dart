import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host() => MaterialApp(
      navigatorKey: UiKit.navigatorKey,
      home: const Scaffold(body: SizedBox()),
    );

/// See the note in `message_test.dart`: `pumpAndSettle` cannot be used
/// because [Spinner] never stops animating.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  testWidgets('notification.success renders headline and description',
      (tester) async {
    await tester.pumpWidget(_host());

    notification.success(
      'Done',
      description: 'Your file was uploaded.',
      duration: Duration.zero,
    );
    await _settle(tester);

    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Your file was uploaded.'), findsOneWidget);

    notification.destroy();
    await _settle(tester);
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('the close button dismisses a notification', (tester) async {
    await tester.pumpWidget(_host());

    notification.info('Dismiss me', duration: Duration.zero);
    await _settle(tester);
    expect(find.text('Dismiss me'), findsOneWidget);

    // The close cross is the last CustomPaint in the card.
    await tester.tap(find.byType(CustomPaint).last);
    await _settle(tester);
    expect(find.text('Dismiss me'), findsNothing);
  });

  testWidgets('destroy(key) closes only the matching notification',
      (tester) async {
    await tester.pumpWidget(_host());

    notification.open(
      const NotificationConfig(
        message: Text('first'),
        duration: Duration.zero,
        key: 'a',
      ),
    );
    notification.open(
      const NotificationConfig(
        message: Text('second'),
        duration: Duration.zero,
        key: 'b',
      ),
    );
    await _settle(tester);

    notification.destroy('a');
    await _settle(tester);

    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);

    notification.destroy();
    await _settle(tester);
  });

  testWidgets('each placement keeps an independent stack', (tester) async {
    await tester.pumpWidget(_host());

    notification.info(
      'top right',
      duration: Duration.zero,
      placement: NotificationPlacement.topRight,
    );
    notification.info(
      'bottom left',
      duration: Duration.zero,
      placement: NotificationPlacement.bottomLeft,
    );
    await _settle(tester);

    expect(find.text('top right'), findsOneWidget);
    expect(find.text('bottom left'), findsOneWidget);

    notification.destroy();
    await _settle(tester);
    expect(find.text('top right'), findsNothing);
    expect(find.text('bottom left'), findsNothing);
  });

  testWidgets('a narrow viewport shrinks the card instead of clipping it',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    notification.info('narrow', duration: Duration.zero);
    await _settle(tester);

    // 320 minus the corner offsets leaves less than the nominal card width.
    final box = tester.getRect(find.text('narrow'));
    expect(box.left, greaterThanOrEqualTo(0));
    expect(box.right, lessThanOrEqualTo(320));

    notification.destroy();
    await _settle(tester);
  });

  testWidgets('a notification auto-dismisses after its duration',
      (tester) async {
    await tester.pumpWidget(_host());

    notification.warning('fleeting', duration: const Duration(seconds: 1));
    await _settle(tester);
    expect(find.text('fleeting'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await _settle(tester);
    expect(find.text('fleeting'), findsNothing);
  });

  testWidgets('stacks notifications when count exceeds threshold (>3)',
      (tester) async {
    await tester.pumpWidget(_host());

    for (int i = 1; i <= 5; i++) {
      notification.info('Item #$i', duration: Duration.zero);
    }
    await _settle(tester);

    expect(find.text('Item #1'), findsOneWidget);
    expect(find.text('Item #2'), findsOneWidget);
    expect(find.text('Item #3'), findsOneWidget);

    notification.destroy();
    await _settle(tester);
  });
}
