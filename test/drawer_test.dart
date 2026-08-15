// An overlay's `open`/`confirm` returns a Future that completes when the
// entry closes. These tests drive frames and assert on what is on screen,
// so awaiting it here would deadlock the test.
// ignore_for_file: unawaited_futures

/// Drawer.open returns a future that completes only once the drawer closes.
/// A regression in any dismissal path would otherwise turn `await` into a
/// hang, so the whole file fails fast on a deadline.
@Timeout(Duration(seconds: 10))
library;

// Material also exports a `Drawer`; hide it so the kit's getter wins.
import 'package:flutter/material.dart' hide Drawer;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host() => MaterialApp(
      navigatorKey: UiKit.navigatorKey,
      home: const Scaffold(body: SizedBox()),
    );

/// See `message_test.dart`: `pumpAndSettle` cannot be used with the kit's
/// perpetual animations. The trailing pump lets the overlay rebuild after the
/// exit animation completes.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  testWidgets('open renders the title and content', (tester) async {
    await tester.pumpWidget(_host());

    Drawer.open(
      const DrawerConfig(
        title: 'Filters',
        child: Text('body'),
      ),
    );
    await _settle(tester);

    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);

    Drawer.destroyAll();
    await _settle(tester);
    expect(find.text('Filters'), findsNothing);
  });

  testWidgets('open completes its future when the drawer closes',
      (tester) async {
    await tester.pumpWidget(_host());

    var closed = false;
    Drawer.open(const DrawerConfig(child: Text('body')))
        .then((_) => closed = true);
    await _settle(tester);
    expect(closed, isFalse);

    Drawer.destroyAll();
    await _settle(tester);
    expect(closed, isTrue);
  });

  testWidgets('tapping the mask dismisses, unless maskClosable is false',
      (tester) async {
    await tester.pumpWidget(_host());

    // A right-placed drawer leaves the left edge of the screen clear.
    Drawer.open(const DrawerConfig(child: Text('closable')));
    await _settle(tester);
    await tester.tapAt(const Offset(5, 300));
    await _settle(tester);
    expect(find.text('closable'), findsNothing);

    Drawer.open(
      const DrawerConfig(
        child: Text('sticky'),
        maskClosable: false,
      ),
    );
    await _settle(tester);
    await tester.tapAt(const Offset(5, 300));
    await _settle(tester);
    expect(find.text('sticky'), findsOneWidget);

    Drawer.destroyAll();
    await _settle(tester);
  });

  testWidgets('escape dismisses the drawer', (tester) async {
    await tester.pumpWidget(_host());

    var closed = false;
    Drawer.open(const DrawerConfig(child: Text('body')))
        .then((_) => closed = true);
    await _settle(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);

    expect(closed, isTrue);
    expect(find.text('body'), findsNothing);
  });

  testWidgets('the close button dismisses the drawer', (tester) async {
    await tester.pumpWidget(_host());

    Drawer.open(
      const DrawerConfig(
        title: 'Panel',
        child: Text('body'),
      ),
    );
    await _settle(tester);

    await tester.tap(find.byType(CustomPaint).last);
    await _settle(tester);
    expect(find.text('Panel'), findsNothing);
  });

  testWidgets('onClose fires on dismissal', (tester) async {
    await tester.pumpWidget(_host());

    var calls = 0;
    Drawer.open(
      DrawerConfig(
        child: const Text('body'),
        onClose: () => calls++,
      ),
    );
    await _settle(tester);

    Drawer.destroyAll();
    await _settle(tester);
    expect(calls, 1);
  });

  testWidgets('each placement anchors to its edge', (tester) async {
    await tester.pumpWidget(_host());
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;

    for (final (placement, check) in <(DrawerPlacement, bool Function(Rect))>[
      (DrawerPlacement.left, (r) => r.left == 0),
      (DrawerPlacement.right, (r) => r.right == size.width),
      (DrawerPlacement.top, (r) => r.top == 0),
      (DrawerPlacement.bottom, (r) => r.bottom == size.height),
    ]) {
      Drawer.open(DrawerConfig(placement: placement, child: const Text('p')));
      await _settle(tester);

      final panel = tester.getRect(
        find.ancestor(
          of: find.text('p'),
          matching: find.byType(SafeArea),
        ),
      );
      expect(
        check(panel),
        isTrue,
        reason: 'placement $placement anchored wrong: $panel',
      );

      Drawer.destroyAll();
      await _settle(tester);
    }
  });

  testWidgets('size is capped to the viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    Drawer.open(const DrawerConfig(size: 9999, child: Text('wide')));
    await _settle(tester);

    final panel = tester.getRect(
      find.ancestor(of: find.text('wide'), matching: find.byType(SafeArea)),
    );
    expect(panel.width, lessThanOrEqualTo(320));

    Drawer.destroyAll();
    await _settle(tester);
  });
}
