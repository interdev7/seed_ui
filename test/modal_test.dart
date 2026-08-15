// An overlay's `open`/`confirm` returns a Future that completes when the
// entry closes. These tests drive frames and assert on what is on screen,
// so awaiting it here would deadlock the test.
// ignore_for_file: unawaited_futures

/// Every opener returns a future that only completes once the modal closes.
/// If a dismissal path regresses, an `await` below would otherwise hang until
/// the default two-minute timeout, so the whole file fails fast instead.
@Timeout(Duration(seconds: 10))
library;

import 'dart:async';

import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host() => MaterialApp(
      navigatorKey: UiKit.navigatorKey,
      home: const Scaffold(body: SizedBox()),
    );

/// See the note in `message_test.dart`: `pumpAndSettle` cannot be used
/// because a loading [Spinner] never stops animating.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  testWidgets('confirm resolves true when confirmed', (tester) async {
    await tester.pumpWidget(_host());

    final future = Modal.confirm(title: 'Delete?', content: 'Forever.');
    await _settle(tester);
    expect(find.text('Delete?'), findsOneWidget);
    expect(find.text('Forever.'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await _settle(tester);

    expect(await future, isTrue);
    expect(find.text('Delete?'), findsNothing);
  });

  testWidgets('confirm resolves false when cancelled', (tester) async {
    await tester.pumpWidget(_host());

    final future = Modal.confirm(title: 'Delete?');
    await _settle(tester);

    await tester.tap(find.text('Cancel'));
    await _settle(tester);

    expect(await future, isFalse);
    expect(find.text('Delete?'), findsNothing);
  });

  testWidgets('tapping the mask dismisses, unless maskClosable is false',
      (tester) async {
    await tester.pumpWidget(_host());

    Modal.confirm(title: 'Closable');
    await _settle(tester);
    // The mask covers the whole screen; its top-left corner is clear of the
    // dialog, which is centred horizontally.
    await tester.tapAt(const Offset(5, 5));
    await _settle(tester);
    expect(find.text('Closable'), findsNothing);

    Modal.confirm(title: 'Sticky', maskClosable: false);
    await _settle(tester);
    await tester.tapAt(const Offset(5, 5));
    await _settle(tester);
    expect(find.text('Sticky'), findsOneWidget);

    Modal.destroyAll();
    await _settle(tester);
  });

  testWidgets('escape dismisses the modal', (tester) async {
    await tester.pumpWidget(_host());

    final future = Modal.confirm(title: 'Press escape');
    await _settle(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);

    expect(await future, isFalse);
    expect(find.text('Press escape'), findsNothing);
  });

  testWidgets('an async onOk holds the modal open until it settles',
      (tester) async {
    await tester.pumpWidget(_host());

    final gate = Completer<void>();
    final future = Modal.confirm(
      title: 'Saving',
      onOk: () async {
        await gate.future;
        return true;
      },
    );
    await _settle(tester);

    await tester.tap(find.text('OK'));
    await tester.pump();

    // Still open while the handler runs.
    expect(find.text('Saving'), findsOneWidget);

    gate.complete();
    await _settle(tester);

    expect(await future, isTrue);
    expect(find.text('Saving'), findsNothing);
  });

  testWidgets('onOk returning false vetoes the close', (tester) async {
    await tester.pumpWidget(_host());

    var calls = 0;
    Modal.confirm(
      title: 'Validate',
      onOk: () {
        calls++;
        return false;
      },
    );
    await _settle(tester);

    await tester.tap(find.text('OK'));
    await _settle(tester);

    expect(calls, 1);
    expect(find.text('Validate'), findsOneWidget);

    Modal.destroyAll();
    await _settle(tester);
  });

  testWidgets('info hides the cancel button', (tester) async {
    await tester.pumpWidget(_host());

    Modal.info(title: 'Heads up', content: 'Nothing to decide.');
    await _settle(tester);

    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);

    Modal.destroyAll();
    await _settle(tester);
  });

  testWidgets('modals stack, and destroyAll clears every layer',
      (tester) async {
    await tester.pumpWidget(_host());

    Modal.confirm(title: 'outer');
    await _settle(tester);
    Modal.error(title: 'inner');
    await _settle(tester);

    expect(find.text('outer'), findsOneWidget);
    expect(find.text('inner'), findsOneWidget);

    Modal.destroyAll();
    await _settle(tester);

    expect(find.text('outer'), findsNothing);
    expect(find.text('inner'), findsNothing);
  });

  testWidgets('centered sits lower than the default placement', (tester) async {
    await tester.pumpWidget(_host());

    Modal.confirm(title: 'anchored');
    await _settle(tester);
    final anchored = tester.getCenter(find.text('anchored')).dy;
    Modal.destroyAll();
    await _settle(tester);

    Modal.confirm(title: 'centered', centered: true);
    await _settle(tester);
    final centered = tester.getCenter(find.text('centered')).dy;
    Modal.destroyAll();
    await _settle(tester);

    expect(centered, greaterThan(anchored));
  });

  testWidgets('top pins the dialog at an explicit offset', (tester) async {
    await tester.pumpWidget(_host());

    Modal.confirm(title: 'pinned', top: 100);
    await _settle(tester);

    // The title sits just inside the dialog's top padding.
    final top = tester.getTopLeft(find.text('pinned')).dy;
    expect(top, greaterThanOrEqualTo(100));
    expect(top, lessThan(160));

    Modal.destroyAll();
    await _settle(tester);
  });

  testWidgets('a narrow viewport shrinks the dialog', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    Modal.confirm(title: 'narrow');
    await _settle(tester);

    final box = tester.getRect(find.text('narrow'));
    expect(box.left, greaterThanOrEqualTo(0));
    expect(box.right, lessThanOrEqualTo(320));

    Modal.destroyAll();
    await _settle(tester);
  });
}
