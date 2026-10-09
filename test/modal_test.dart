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

  group('where the cross stands, and what makes room for it', () {
    Finder cross() => find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == 'CrossPainter',
        );

    /// Opens a modal whose body is a box that takes all the width it is given.
    Future<void> open(
      WidgetTester tester, {
      ClosePlacement? placement,
      bool title = true,
      bool closable = true,
      TextDirection direction = TextDirection.ltr,
    }) async {
      // One at a time: a second open stacks over the first, and the probes
      // measure the one that is there.
      Modal.destroyAll();
      await _settle(tester);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          builder: (context, child) =>
              Directionality(textDirection: direction, child: child!),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      Modal.open(
        ModalConfig(
          title: title
              ? const Text(
                  'A title long enough to reach the corner of the card')
              : null,
          content: const SizedBox(
            key: Key('body'),
            width: double.infinity,
            height: 40,
          ),
          closable: closable,
          closePlacement: placement ?? ClosePlacement.beside,
        ),
      );
      await _settle(tester);
    }

    double bodyWidth(WidgetTester tester) =>
        tester.getSize(find.byKey(const Key('body'))).width;

    testWidgets('beside, the default, narrows the content all the way down', (
      tester,
    ) async {
      await open(tester, closable: false);
      final whole = bodyWidth(tester);

      await open(tester);
      expect(bodyWidth(tester), lessThan(whole));
    });

    testWidgets('in the corner the content has the full width', (
      tester,
    ) async {
      await open(tester, closable: false);
      final whole = bodyWidth(tester);

      await open(tester, placement: ClosePlacement.corner);
      expect(bodyWidth(tester), whole);
    });

    testWidgets('in the corner the title still keeps clear of the cross', (
      tester,
    ) async {
      await open(tester, placement: ClosePlacement.corner);

      final title = tester.getRect(
        find.text('A title long enough to reach the corner of the card'),
      );
      final x = tester.getRect(cross());
      expect(
        title.right,
        lessThanOrEqualTo(x.left),
        reason: 'a title running under the cross is half a title',
      );
    });

    testWidgets('the cross itself does not move between the two', (
      tester,
    ) async {
      await open(tester);
      final beside = tester.getRect(cross());

      await open(tester, placement: ClosePlacement.corner);
      expect(tester.getRect(cross()), beside);
    });

    testWidgets('in a right-to-left dialog the corner is the left one', (
      tester,
    ) async {
      await open(
        tester,
        placement: ClosePlacement.corner,
        direction: TextDirection.rtl,
      );

      final body = tester.getRect(find.byKey(const Key('body')));
      final x = tester.getRect(cross());
      expect(x.left, closeTo(body.left, 0.5));
    });

    testWidgets('the cross in the corner still closes it', (tester) async {
      await tester.pumpWidget(_host());
      final future = Modal.open(
        const ModalConfig(
          title: Text('Title'),
          closePlacement: ClosePlacement.corner,
        ),
      );
      await _settle(tester);

      await tester.tap(find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == 'CrossPainter',
      ));
      await _settle(tester);

      expect(await future, isFalse);
    });
  });
}
