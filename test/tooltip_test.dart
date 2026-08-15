import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      navigatorKey: UiKit.navigatorKey,
      home: Scaffold(body: Center(child: child)),
    );

/// See `message_test.dart`: `pumpAndSettle` is unusable with the kit's
/// animations. The trailing pump lets the overlay rebuild after exit.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump();
}

Future<TestGesture> _hover(WidgetTester tester, Finder target) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getCenter(target));
  return gesture;
}

void main() {
  testWidgets('appears after the wait duration on hover', (tester) async {
    await tester.pumpWidget(
      _host(
        const Tooltip(message: 'Search', child: Text('trigger')),
      ),
    );

    await _hover(tester, find.text('trigger'));
    // Not yet: the wait duration has not elapsed.
    await tester.pump();
    expect(find.text('Search'), findsNothing);

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('hides when the pointer leaves', (tester) async {
    await tester.pumpWidget(
      _host(
        const Tooltip(message: 'Search', child: Text('trigger')),
      ),
    );

    final gesture = await _hover(tester, find.text('trigger'));
    await tester.pump(const Duration(milliseconds: 150));
    await _settle(tester);
    expect(find.text('Search'), findsOneWidget);

    await gesture.moveTo(const Offset(500, 500));
    await _settle(tester);
    expect(find.text('Search'), findsNothing);
  });

  testWidgets('trigger: tap toggles on a mouse click', (tester) async {
    await tester.pumpWidget(
      _host(
        const Tooltip(
          message: 'Search',
          trigger: TooltipTrigger.tap,
          child: Text('trigger'),
        ),
      ),
    );

    await tester.tap(find.text('trigger'), kind: PointerDeviceKind.mouse);
    await _settle(tester);
    expect(find.text('Search'), findsOneWidget);

    // A second click hides it.
    await tester.tap(find.text('trigger'), kind: PointerDeviceKind.mouse);
    await _settle(tester);
    expect(find.text('Search'), findsNothing);
  });

  testWidgets('trigger: longPress shows on a long-press', (tester) async {
    await tester.pumpWidget(
      _host(
        const Tooltip(
          message: 'Search',
          trigger: TooltipTrigger.longPress,
          showDuration: Duration(milliseconds: 400),
          child: Text('trigger'),
        ),
      ),
    );

    await tester.longPress(find.text('trigger'));
    await _settle(tester);
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('arrow: false draws no caret', (tester) async {
    await tester.pumpWidget(
      _host(
        const Tooltip(
          message: 'Search',
          arrow: false,
          trigger: TooltipTrigger.tap,
          child: Text('trigger'),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await _settle(tester);
    expect(find.text('Search'), findsOneWidget);
    // The caret painter is absent.
    expect(
      find.byKey(const Key('softPopoverArrow')),
      findsNothing,
    );
  });

  testWidgets('arrow is drawn by default', (tester) async {
    await tester.pumpWidget(
      _host(
        const Tooltip(
          message: 'Search',
          trigger: TooltipTrigger.tap,
          child: Text('trigger'),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await _settle(tester);
    expect(
      find.byKey(const Key('softPopoverArrow')),
      findsOneWidget,
    );
  });

  testWidgets('a touch tap shows the tooltip and auto-hides', (tester) async {
    await tester.pumpWidget(
      _host(
        const Tooltip(
          message: 'Search',
          showDuration: Duration(milliseconds: 500),
          child: Text('trigger'),
        ),
      ),
    );

    // tester.tap defaults to a touch pointer.
    await tester.tap(find.text('trigger'));
    await _settle(tester);
    expect(find.text('Search'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await _settle(tester);
    expect(find.text('Search'), findsNothing);
  });

  testWidgets('a touch tap shows the tooltip and still taps the child',
      (tester) async {
    // Regression: on a touchscreen there is no hover, so the tooltip must open
    // on tap — without swallowing the tap the button needs.
    var tapped = 0;
    await tester.pumpWidget(
      _host(
        Tooltip(
          message: 'Search',
          child: Button(
            onPressed: () => tapped++,
            child: const Text('trigger'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await _settle(tester);

    expect(tapped, 1);
    expect(find.text('Search'), findsOneWidget);
  });
}
