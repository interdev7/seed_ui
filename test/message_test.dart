import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      navigatorKey: UiKit.navigatorKey,
      home: Scaffold(body: child),
    );

/// Runs an enter or exit animation to completion.
///
/// `pumpAndSettle` is unusable here: [Spinner] repeats forever, so the
/// tree never reaches a quiescent state. The trailing pump matters too —
/// cards are removed from a `whenComplete` callback, and the container only
/// rebuilds on the frame after that.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  testWidgets('message.success shows a card and auto-dismisses it',
      (tester) async {
    await tester.pumpWidget(_host(const SizedBox()));

    message.success('Saved', duration: const Duration(seconds: 1));
    await _settle(tester);
    expect(find.text('Saved'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await _settle(tester);
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('the returned handle dismisses a message early', (tester) async {
    await tester.pumpWidget(_host(const SizedBox()));

    final close = message.loading('Uploading…');
    await _settle(tester);
    expect(find.text('Uploading…'), findsOneWidget);

    close();
    await _settle(tester);
    expect(find.text('Uploading…'), findsNothing);
  });

  testWidgets('maxCount evicts the oldest message', (tester) async {
    await tester.pumpWidget(_host(const SizedBox()));
    message.config(maxCount: 2);

    for (final text in ['first', 'second', 'third']) {
      message.open(
        MessageConfig(content: Text(text), duration: Duration.zero),
      );
    }
    await _settle(tester);

    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    expect(find.text('third'), findsOneWidget);

    // Clean up, otherwise a live overlay leaks into the next test.
    message.destroy();
    await _settle(tester);
  });

  testWidgets('Button fires onPressed but stays inert while loading',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            Button(onPressed: () => taps++, child: const Text('tap me')),
            Button(
              loading: true,
              onPressed: () => taps++,
              child: const Text('busy'),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('tap me'));
    await tester.tap(find.text('busy'));
    await tester.pump();

    expect(taps, 1);
  });

  group('Placement', () {
    /// Drains every open toast and puts the defaults back.
    ///
    /// The stack is a singleton that outlives the widget tree, and its overlay
    /// entry is only released once the last card has finished its exit
    /// animation — so the frames have to be pumped, not just requested.
    Future<void> reset(WidgetTester tester) async {
      message.destroy();
      await _settle(tester);
      message.config(placement: MessagePlacement.top, offset: 24);
    }

    double half(WidgetTester tester) =>
        tester.getSize(find.byType(MaterialApp)).height / 2;

    testWidgets('a toast sits near the top by default', (tester) async {
      await tester.pumpWidget(_host(const SizedBox()));

      message.info('Top', duration: Duration.zero);
      await _settle(tester);
      expect(tester.getCenter(find.text('Top')).dy, lessThan(half(tester)));

      await reset(tester);
    });

    testWidgets('placement: bottom anchors it to the other edge',
        (tester) async {
      await tester.pumpWidget(_host(const SizedBox()));

      message.info(
        'Bottom',
        duration: Duration.zero,
        placement: MessagePlacement.bottom,
      );
      await _settle(tester);
      expect(
        tester.getCenter(find.text('Bottom')).dy,
        greaterThan(half(tester)),
      );

      await reset(tester);
    });

    testWidgets('the two edges keep separate stacks', (tester) async {
      await tester.pumpWidget(_host(const SizedBox()));

      message.info('Up', duration: Duration.zero);
      message.info(
        'Down',
        duration: Duration.zero,
        placement: MessagePlacement.bottom,
      );
      await _settle(tester);

      // Neither reorders the other: each stays on its own side.
      expect(tester.getCenter(find.text('Up')).dy, lessThan(half(tester)));
      expect(tester.getCenter(find.text('Down')).dy, greaterThan(half(tester)));

      await reset(tester);
    });

    testWidgets('a bottom stack grows away from its edge', (tester) async {
      await tester.pumpWidget(_host(const SizedBox()));

      message.info(
        'First',
        duration: Duration.zero,
        placement: MessagePlacement.bottom,
      );
      await _settle(tester);
      message.info(
        'Second',
        duration: Duration.zero,
        placement: MessagePlacement.bottom,
      );
      await _settle(tester);

      // The one already on screen keeps its place and the newcomer stacks
      // beyond it — the same rule as at the top, mirrored.
      expect(
        tester.getCenter(find.text('Second')).dy,
        lessThan(tester.getCenter(find.text('First')).dy),
      );

      await reset(tester);
    });

    testWidgets('config sets the default edge for later calls', (tester) async {
      await tester.pumpWidget(_host(const SizedBox()));
      message.config(placement: MessagePlacement.bottom);

      message.info('Default', duration: Duration.zero);
      await _settle(tester);
      expect(
        tester.getCenter(find.text('Default')).dy,
        greaterThan(half(tester)),
      );

      await reset(tester);
    });

    testWidgets('offset pushes it further from its edge', (tester) async {
      await tester.pumpWidget(_host(const SizedBox()));

      message.info('Near', duration: Duration.zero);
      await _settle(tester);
      final near = tester.getCenter(find.text('Near')).dy;
      message.destroy();
      await _settle(tester);

      message.config(offset: 200);
      message.info('Far', duration: Duration.zero);
      await _settle(tester);
      expect(tester.getCenter(find.text('Far')).dy, greaterThan(near));

      await reset(tester);
    });

    testWidgets('a reused key replaces a toast on the other edge too',
        (tester) async {
      await tester.pumpWidget(_host(const SizedBox()));

      message.info('Old', duration: Duration.zero, key: 'k');
      await _settle(tester);
      message.info(
        'New',
        duration: Duration.zero,
        key: 'k',
        placement: MessagePlacement.bottom,
      );
      await _settle(tester);

      // Reusing a key says "this supersedes that", which holds across edges.
      expect(find.text('Old'), findsNothing);
      expect(find.text('New'), findsOneWidget);

      await reset(tester);
    });
  });

  testWidgets('config is safe to call from dispose', (tester) async {
    // The exact shape that crashed: a page restores the default on its way
    // out while a toast is still on screen. dispose runs during unmount, when
    // the framework has the tree locked and refuses a rebuild request.
    await tester.pumpWidget(_host(const _ResetsOnDispose()));

    message.info('Still here', duration: Duration.zero);
    await _settle(tester);
    expect(find.text('Still here'), findsOneWidget);

    // Tear the page down with the toast still open.
    await tester.pumpWidget(_host(const SizedBox()));
    await _settle(tester);

    expect(tester.takeException(), isNull);

    message.destroy();
    await _settle(tester);
    message.config(placement: MessagePlacement.top, offset: 24);
  });
}

/// A page that puts the global message defaults back when it leaves.
class _ResetsOnDispose extends StatefulWidget {
  const _ResetsOnDispose();

  @override
  State<_ResetsOnDispose> createState() => _ResetsOnDisposeState();
}

class _ResetsOnDisposeState extends State<_ResetsOnDispose> {
  @override
  void initState() {
    super.initState();
    message.config(placement: MessagePlacement.bottom, offset: 48);
  }

  @override
  void dispose() {
    message.config(placement: MessagePlacement.top, offset: 24);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
