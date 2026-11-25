// An overlay's `open`/`confirm` returns a Future that completes when the
// entry closes. These tests drive frames and assert on what is on screen,
// so awaiting it here would deadlock the test.
// ignore_for_file: unawaited_futures

/// Drawer.open returns a future that completes only once the drawer closes.
/// A regression in any dismissal path would otherwise turn `await` into a
/// hang, so the whole file fails fast on a deadline.
@Timeout(Duration(seconds: 10))
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// Material also exports a `Drawer`; hide it so the kit's getter wins.
import 'package:material_ui/material_ui.dart' hide Drawer, Divider;
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
      const DrawerConfig(title: Text('Filters'), child: Text('body')),
    );
    await _settle(tester);

    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);

    Drawer.destroyAll();
    await _settle(tester);
    expect(find.text('Filters'), findsNothing);
  });

  testWidgets('open completes its future when the drawer closes', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    var closed = false;
    Drawer.open(
      const DrawerConfig(child: Text('body')),
    ).then((_) => closed = true);
    await _settle(tester);
    expect(closed, isFalse);

    Drawer.destroyAll();
    await _settle(tester);
    expect(closed, isTrue);
  });

  testWidgets('tapping the mask dismisses, unless maskClosable is false', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    // A right-placed drawer leaves the left edge of the screen clear.
    Drawer.open(const DrawerConfig(child: Text('closable')));
    await _settle(tester);
    await tester.tapAt(const Offset(5, 300));
    await _settle(tester);
    expect(find.text('closable'), findsNothing);

    Drawer.open(const DrawerConfig(child: Text('sticky'), maskClosable: false));
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
    Drawer.open(
      const DrawerConfig(child: Text('body')),
    ).then((_) => closed = true);
    await _settle(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);

    expect(closed, isTrue);
    expect(find.text('body'), findsNothing);
  });

  testWidgets('the close button dismisses the drawer', (tester) async {
    await tester.pumpWidget(_host());

    Drawer.open(const DrawerConfig(title: Text('Panel'), child: Text('body')));
    await _settle(tester);

    await tester.tap(find.byType(CustomPaint).last);
    await _settle(tester);
    expect(find.text('Panel'), findsNothing);
  });

  testWidgets('onClose fires on dismissal', (tester) async {
    await tester.pumpWidget(_host());

    var calls = 0;
    Drawer.open(
      DrawerConfig(child: const Text('body'), onClose: () => calls++),
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
        find.ancestor(of: find.text('p'), matching: find.byType(SafeArea)),
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

  testWidgets('a bottom drawer rides on top of the keyboard', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host());

    Drawer.open(
      const DrawerConfig(
        placement: DrawerPlacement.bottom,
        size: 400,
        child: SizedBox.expand(key: Key('body')),
      ),
    );
    await _settle(tester);

    // The panel ends where the keyboard begins, and keeps its size.
    final body = tester.getRect(find.byKey(const Key('body')));
    expect(body.bottom, lessThanOrEqualTo(1200 - 300));
    expect(body.bottom, greaterThan(1200 - 300 - 40));

    Drawer.destroyAll();
    await _settle(tester);
  });

  testWidgets(
    'a bottom drawer taller than the room above the keyboard shrinks',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 600);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host());

      Drawer.open(
        const DrawerConfig(
          placement: DrawerPlacement.bottom,
          size: 700,
          child: SizedBox.expand(key: Key('body')),
        ),
      );
      await _settle(tester);

      final body = tester.getRect(find.byKey(const Key('body')));
      expect(body.top, greaterThanOrEqualTo(0));
      expect(body.bottom, lessThanOrEqualTo(1000 - 600));
      expect(tester.takeException(), isNull);

      Drawer.destroyAll();
      await _settle(tester);
    },
  );

  testWidgets('a side drawer ignores the keyboard', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host());

    Drawer.open(const DrawerConfig(child: SizedBox.expand(key: Key('body'))));
    await _settle(tester);

    final body = tester.getRect(find.byKey(const Key('body')));
    expect(body.bottom, greaterThan(1200 - 300));

    Drawer.destroyAll();
    await _settle(tester);
  });
}
