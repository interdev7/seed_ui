import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// A ring of progress round a float button, a button that takes a page back
/// to its top, and a button a hand can carry out of the way.

Widget _host(Widget child) => ConfigProvider(
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: Scaffold(body: child),
      ),
    );

/// The painter a float button's ring is drawn with, by its type's name: it is
/// the kit's own, and a test has no business importing it.
Finder _ring() => find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.foregroundPainter.runtimeType.toString() == '_ProgressRingPainter',
    );

void main() {
  group('a ring of progress', () {
    testWidgets('none unasked, and nothing else changed', (tester) async {
      await tester.pumpWidget(
        _host(Center(child: FloatButton(onPressed: () {}))),
      );
      expect(_ring(), findsNothing);
    });

    testWidgets('round a round button and a square one', (tester) async {
      for (final shape in [ButtonShape.circle, ButtonShape.defaultShape]) {
        await tester.pumpWidget(
          _host(
            Center(
              child: FloatButton(
                shape: shape,
                progress: 0.4,
                onPressed: () {},
              ),
            ),
          ),
        );
        expect(_ring(), findsOneWidget, reason: '$shape');
        // The ring sits on the button's own edge, not round the outside.
        expect(
          tester.getSize(_ring()),
          tester.getSize(find.byType(Button)),
          reason: '$shape',
        );
      }
    });

    testWidgets('a reader is told the figure', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Center(
            child: FloatButton(
              progress: 0.25,
              semanticsLabel: 'Upload',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Upload'),
        findsOneWidget,
      );
      expect(tester.getSemantics(find.bySemanticsLabel('Upload')).value, '25%');
      semantics.dispose();
    });

    testWidgets('below nothing and beyond all, it holds at the ends', (
      tester,
    ) async {
      for (final wild in [-1.0, 3.0]) {
        await tester.pumpWidget(
          _host(Center(child: FloatButton(progress: wild, onPressed: () {}))),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('back to the top', () {
    /// A long page with a back-to-top button over it.
    Widget page(
      ScrollController controller, {
      double visibilityHeight = 400,
      bool showProgress = false,
      VoidCallback? onPressed,
      Duration duration = const Duration(milliseconds: 450),
    }) =>
        _host(
          Stack(
            children: [
              ListView(
                controller: controller,
                children: [
                  for (var i = 0; i < 100; i++)
                    SizedBox(height: 50, child: Text('row $i')),
                ],
              ),
              Positioned(
                right: 24,
                bottom: 24,
                child: BackTop(
                  controller: controller,
                  visibilityHeight: visibilityHeight,
                  showProgress: showProgress,
                  onPressed: onPressed,
                  duration: duration,
                ),
              ),
            ],
          ),
        );

    double opacity(WidgetTester tester) => tester
        .widget<AnimatedOpacity>(
          find.descendant(
            of: find.byType(BackTop),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    testWidgets('it comes once the page is far enough down', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(page(controller));
      expect(opacity(tester), 0);

      controller.jumpTo(300);
      await tester.pump();
      expect(opacity(tester), 0, reason: 'not yet 400 down');

      controller.jumpTo(450);
      await tester.pump();
      expect(opacity(tester), 1);
    });

    testWidgets('while it is away, a hand and a reader pass it by', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var pressed = 0;
      await tester.pumpWidget(page(controller, onPressed: () => pressed++));
      expect(find.bySemanticsLabel('Back to top'), findsNothing);

      await tester.tap(find.byType(BackTop), warnIfMissed: false);
      await tester.pump();
      expect(pressed, 0);

      controller.jumpTo(800);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Back to top'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a press takes the page back up, over its duration', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var pressed = 0;
      await tester.pumpWidget(page(controller, onPressed: () => pressed++));
      controller.jumpTo(2000);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackTop));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.offset, greaterThan(0),
          reason: 'on its way, not there');
      expect(controller.offset, lessThan(2000));

      await tester.pumpAndSettle();
      expect(controller.offset, 0);
      expect(pressed, 1);
    });

    testWidgets('where motion is turned down, it goes at once', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: page(controller),
        ),
      );
      controller.jumpTo(2000);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackTop));
      await tester.pump();
      expect(controller.offset, 0);
    });

    testWidgets('its ring is how far down the page is', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        page(controller, showProgress: true, visibilityHeight: 0),
      );
      final max = controller.position.maxScrollExtent;
      controller.jumpTo(max / 2);
      await tester.pump();
      final button = tester.widget<FloatButton>(
        find.descendant(
          of: find.byType(BackTop),
          matching: find.byType(FloatButton),
        ),
      );
      expect(button.progress, closeTo(0.5, 0.001));
    });

    testWidgets('a page too short to scroll is at nothing, not at all', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          Stack(
            children: [
              ListView(
                controller: controller,
                children: const [SizedBox(height: 50, child: Text('one'))],
              ),
              BackTop(
                controller: controller,
                visibilityHeight: 0,
                showProgress: true,
              ),
            ],
          ),
        ),
      );
      final button = tester.widget<FloatButton>(
        find.descendant(
          of: find.byType(BackTop),
          matching: find.byType(FloatButton),
        ),
      );
      expect(button.progress, 0);
    });

    testWidgets('given no controller, it takes the screen\'s', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          PrimaryScrollController(
            controller: controller,
            child: Stack(
              children: [
                ListView(
                  primary: true,
                  children: [
                    for (var i = 0; i < 100; i++)
                      SizedBox(height: 50, child: Text('row $i')),
                  ],
                ),
                const Positioned(right: 24, bottom: 24, child: BackTop()),
              ],
            ),
          ),
        ),
      );
      controller.jumpTo(1000);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackTop));
      await tester.pumpAndSettle();
      expect(controller.offset, 0);
    });
  });

  group('carried by hand', () {
    Widget carried({
      bool draggable = true,
      Offset? offset,
      ValueChanged<Offset>? onOffsetChanged,
      VoidCallback? onPressed,
    }) =>
        _host(
          Stack(
            children: [
              Positioned(
                right: 24,
                bottom: 24,
                child: FloatButton(
                  key: const Key('fab'),
                  draggable: draggable,
                  offset: offset,
                  onOffsetChanged: onOffsetChanged,
                  onPressed: onPressed ?? () {},
                ),
              ),
            ],
          ),
        );

    Rect at(WidgetTester tester) => tester.getRect(find.byType(Button));

    testWidgets('a press is still a press', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(carried(onPressed: () => pressed++));
      await tester.tap(find.byType(Button));
      await tester.pump();
      expect(pressed, 1);
    });

    testWidgets('a drag carries it, and says how far', (tester) async {
      final told = <Offset>[];
      var pressed = 0;
      await tester.pumpWidget(
        carried(onOffsetChanged: told.add, onPressed: () => pressed++),
      );
      final before = at(tester);
      await tester.drag(find.byType(Button), const Offset(-120, -200));
      await tester.pumpAndSettle();

      final moved = at(tester).topLeft - before.topLeft;
      // Under the finger the whole way, the slop included: a button that
      // trailed the finger by the pixels it took to tell a drag from a press
      // would feel like it was slipping.
      expect((moved - const Offset(-120, -200)).distance, lessThan(1));
      expect(told.last, moved);
      expect(pressed, 0, reason: 'a drag is not a press');
    });

    testWidgets('it is kept on the screen', (tester) async {
      await tester.pumpWidget(carried());
      await tester.drag(find.byType(Button), const Offset(4000, 4000));
      await tester.pumpAndSettle();
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      final rect = at(tester);
      expect(rect.right, lessThanOrEqualTo(screen.width + 0.01));
      expect(rect.bottom, lessThanOrEqualTo(screen.height + 0.01));

      await tester.drag(find.byType(Button), const Offset(-9000, -9000));
      await tester.pumpAndSettle();
      expect(at(tester).left, greaterThanOrEqualTo(-0.01));
      expect(at(tester).top, greaterThanOrEqualTo(-0.01));
    });

    testWidgets('held where it is told, it waits to be told again', (
      tester,
    ) async {
      final told = <Offset>[];
      await tester.pumpWidget(
        carried(offset: Offset.zero, onOffsetChanged: told.add),
      );
      final before = at(tester);
      await tester.drag(find.byType(Button), const Offset(-100, 0));
      await tester.pumpAndSettle();
      expect(told, isNotEmpty);
      expect(at(tester), before, reason: 'controlled: it moves when told');

      await tester.pumpWidget(
        carried(offset: told.last, onOffsetChanged: told.add),
      );
      expect(at(tester).left, lessThan(before.left));
    });

    testWidgets('a quick hand loses no ground, held or free', (tester) async {
      // A mouse reports more often than the screen draws: several moves can
      // land before the owner of a held button has rebuilt with the last one.
      // Each has to count, or the button falls behind the pointer.
      for (final held in [false, true]) {
        var offset = Offset.zero;
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, setState) => Stack(
                children: [
                  Positioned(
                    right: 24,
                    bottom: 24,
                    child: FloatButton(
                      draggable: true,
                      offset: held ? offset : null,
                      onOffsetChanged: (o) => setState(() => offset = o),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        final before = at(tester);
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Button)),
          kind: PointerDeviceKind.mouse,
        );
        // Thirty moves of ten pixels, three to a frame.
        for (var frame = 0; frame < 10; frame++) {
          for (var i = 0; i < 3; i++) {
            await gesture.moveBy(const Offset(-10, -5));
          }
          await tester.pump();
        }
        await gesture.up();
        await tester.pump();
        final moved = at(tester).topLeft - before.topLeft;
        expect(
          (moved - const Offset(-300, -150)).distance,
          lessThan(1),
          reason: held ? 'held' : 'free',
        );
      }
    });

    testWidgets('not draggable, a drag does nothing', (tester) async {
      await tester.pumpWidget(carried(draggable: false));
      final before = at(tester);
      await tester.drag(find.byType(Button), const Offset(-100, -100));
      await tester.pumpAndSettle();
      expect(at(tester), before);
    });

    testWidgets('a group is shut as it is carried, and opens where it is put',
        (tester) async {
      var open = false;
      await tester.pumpWidget(
        _host(
          Stack(
            children: [
              Positioned(
                right: 24,
                bottom: 24,
                child: StatefulBuilder(
                  builder: (context, setState) => FloatButtonGroup<String>(
                    draggable: true,
                    open: open,
                    onOpenChanged: (v) => setState(() => open = v),
                    items: const [
                      FloatButtonItem(value: 'a', icon: Icon(Icons.edit)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      final trigger = find.byType(FloatButton).first;
      await tester.tap(trigger);
      await tester.pumpAndSettle();
      expect(open, isTrue);

      await tester.drag(trigger, const Offset(-200, -150));
      await tester.pumpAndSettle();
      expect(open, isFalse, reason: 'a fan left open would hang from nothing');

      final put = tester.getCenter(find.byType(FloatButton).first);
      await tester.tap(find.byType(FloatButton).first);
      await tester.pumpAndSettle();
      final item = tester.getCenter(find.byIcon(Icons.edit));
      expect((item - put).distance, lessThan(150),
          reason: 'it opens from the trigger, where it now is');
    });
  });
}
