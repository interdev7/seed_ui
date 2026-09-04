import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:flutter/rendering.dart'
    show ContainerLayer, OpacityLayer, PaintingContext, PaintingContextCallback;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => ConfigProvider(
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  testWidgets('a card with a title and a body, opened by tapping',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const Popover(
          trigger: PopoverTrigger.tap,
          title: Text('Title'),
          content: Text('Some content here.'),
          child: Text('trigger'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Title'), findsNothing);
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Some content here.'), findsOneWidget);

    // Tapping the trigger again puts it away.
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
    expect(find.text('Title'), findsNothing);
  });

  testWidgets('hovering opens it after a pause, and leaving closes it',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const Popover(
          content: Text('On hover'),
          child: Text('trigger'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.hover(tester.getCenter(find.text('trigger'))),
    );
    await tester.pump();
    expect(find.text('On hover'), findsNothing, reason: 'not yet — a pause');

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.text('On hover'), findsOneWidget);

    await tester.sendEventToBinding(pointer.hover(const Offset(5, 5)));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.text('On hover'), findsNothing);
  });

  testWidgets('a click on a hovered trigger reaches what is under it',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        Popover(
          content: const Text('On hover'),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const Text('trigger'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.hover(tester.getCenter(find.text('trigger'))),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.text('On hover'), findsOneWidget);

    // What dismisses the card covers the page, and the trigger is cut out of
    // it: a card that opened on its own from a hover must not eat the click
    // the hand came to make.
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('a pointer that reaches the card keeps it open', (tester) async {
    // Without this a hover popover could not hold a link or a button: the card
    // would close on the way to it.
    await tester.pumpWidget(
      _host(
        const Popover(
          placement: PopoverPlacement.bottom,
          content: Text('Reachable'),
          child: Text('trigger'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.hover(tester.getCenter(find.text('trigger'))),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.text('Reachable'), findsOneWidget);

    // Off the trigger and onto the card.
    await tester.sendEventToBinding(pointer.hover(const Offset(5, 5)));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.sendEventToBinding(
      pointer.hover(tester.getCenter(find.text('Reachable'))),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Reachable'), findsOneWidget);
  });

  testWidgets('long press opens it when asked', (tester) async {
    await tester.pumpWidget(
      _host(
        const Popover(
          trigger: PopoverTrigger.longPress,
          content: Text('Held'),
          child: Text('trigger'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
    expect(find.text('Held'), findsNothing, reason: 'a tap is not a press');

    await tester.longPress(find.text('trigger'));
    await tester.pumpAndSettle();
    expect(find.text('Held'), findsOneWidget);
  });

  testWidgets('controlled: the caller owns it', (tester) async {
    var open = false;
    final changes = <bool>[];

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Popover(
            open: open,
            trigger: PopoverTrigger.tap,
            onOpenChange: (v) {
              changes.add(v);
              setState(() => open = v);
            },
            content: const Text('Controlled'),
            child: const Text('trigger'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
    expect(changes, [true]);
    expect(find.text('Controlled'), findsOneWidget);

    // A tap outside asks to close, and the caller agrees.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(changes, [true, false]);
    expect(find.text('Controlled'), findsNothing);
  });

  testWidgets('defaultOpen starts it open', (tester) async {
    await tester.pumpWidget(
      _host(
        const Popover(
          defaultOpen: true,
          trigger: PopoverTrigger.tap,
          content: Text('Already up'),
          child: Text('trigger'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Already up'), findsOneWidget);
  });

  testWidgets('the caret and the card share a colour', (tester) async {
    const colour = Color(0xFF112233);
    await tester.pumpWidget(
      _host(
        const Popover(
          trigger: PopoverTrigger.tap,
          color: colour,
          content: Text('Coloured'),
          child: Text('trigger'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();

    final card = tester
        .widgetList<Container>(
          find.ancestor(
            of: find.text('Coloured'),
            matching: find.byType(Container),
          ),
        )
        .first;
    expect((card.decoration! as BoxDecoration).color, colour);

    // The caret is painted in the same colour, so the two read as one shape.
    expect(find.byKey(const Key('softPopoverArrow')), findsOneWidget);
  });

  testWidgets('arrow: false leaves the caret off', (tester) async {
    await tester.pumpWidget(
      _host(
        const Popover(
          trigger: PopoverTrigger.tap,
          arrow: false,
          content: Text('No caret'),
          child: Text('trigger'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();

    expect(find.text('No caret'), findsOneWidget);
    expect(find.byKey(const Key('softPopoverArrow')), findsNothing);
  });

  testWidgets('tokens reach the card', (tester) async {
    await tester.pumpWidget(
      _host(
        const Popover(
          trigger: PopoverTrigger.tap,
          token: PopoverToken(minWidth: 300, borderRadius: 2),
          content: Text('Wide'),
          child: Text('trigger'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();

    final card = tester
        .widgetList<Container>(
          find.ancestor(
            of: find.text('Wide'),
            matching: find.byType(Container),
          ),
        )
        .first;
    expect(card.constraints!.minWidth, 300);
    expect(
      (card.decoration! as BoxDecoration).borderRadius,
      BorderRadius.circular(2),
    );
  });

  group('Arrival', () {
    testWidgets('simple is a fade and a grow — no rasterising', (tester) async {
      await tester.pumpWidget(
        _host(
          const Popover(
            trigger: PopoverTrigger.tap,
            content: Text('Plain'),
            child: Text('trigger'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.byType(SnapshotWidget), findsNothing);
      expect(find.byType(ScaleTransition), findsWidgets);
    });

    testWidgets('genie draws the card as a sheet while it arrives',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const Popover(
            trigger: PopoverTrigger.tap,
            animation: PopoverAnimation.genie,
            placement: PopoverPlacement.bottom,
            content: Text('Poured'),
            child: Text('trigger'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final snapshot =
          tester.widget<SnapshotWidget>(find.byType(SnapshotWidget));
      expect(
        snapshot.controller.allowSnapshotting,
        isTrue,
        reason: 'the sheet is a picture while it is being poured',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('and gives the card back once it has arrived', (tester) async {
      // Rasterising costs a picture per frame and freezes the contents, so it
      // stops the moment the card is in place — otherwise a genie popover
      // could hold nothing you could press.
      var pressed = 0;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => Popover(
              trigger: PopoverTrigger.tap,
              animation: PopoverAnimation.genie,
              placement: PopoverPlacement.bottom,
              content: GestureDetector(
                onTap: () => pressed++,
                child: const Text('press me'),
              ),
              child: const Text('trigger'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      final snapshot =
          tester.widget<SnapshotWidget>(find.byType(SnapshotWidget));
      expect(snapshot.controller.allowSnapshotting, isFalse);

      await tester.tap(find.text('press me'));
      await tester.pumpAndSettle();
      expect(pressed, 1);
    });

    testWidgets('closing from a rebuild of the owner is not a crash',
        (tester) async {
      // A controlled popover closes from didUpdateWidget, so the controller
      // reports the change mid-build. Anything the genie does about it then —
      // stop rasterising, hand the shadow back — has to wait for the frame to
      // end rather than mark itself dirty.
      Widget host(bool open) => _host(
            Popover(
              open: open,
              animation: PopoverAnimation.genie,
              placement: PopoverPlacement.bottom,
              content: const Text('Poured'),
              child: const Text('trigger'),
            ),
          );

      await tester.pumpWidget(host(true));
      await tester.pumpAndSettle();

      await tester.pumpWidget(host(false));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Poured'), findsNothing);
    });

    testWidgets('a settled card is not given a second shadow', (tester) async {
      // Rasterising stops the moment the surface lands, and from then on the
      // painter's plain path runs on every frame. Casting a shadow there as
      // well stacks it on the one the settled card draws itself: the shadow
      // jumps wider when the pour ends and back when closing starts.
      await tester.pumpWidget(
        _host(
          const Popover(
            trigger: PopoverTrigger.tap,
            animation: PopoverAnimation.genie,
            placement: PopoverPlacement.bottom,
            content: Text('Poured'),
            child: Text('trigger'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('trigger'));

      SnapshotPainter painterNow() =>
          tester.widget<SnapshotWidget>(find.byType(SnapshotWidget)).painter;

      int shadowsDrawnBy(SnapshotPainter painter) {
        final canvas = _CountingCanvas();
        painter.paint(
          _RecordingContext(canvas),
          Offset.zero,
          const Size(200, 100),
          (context, offset) {},
        );
        return canvas.shadows;
      }

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        shadowsDrawnBy(painterNow()),
        3,
        reason: 'mid-pour the card has no shadow of its own to draw',
      );

      await tester.pumpAndSettle();
      expect(
        shadowsDrawnBy(painterNow()),
        0,
        reason: 'the settled card draws its own, and one is enough',
      );
    });

    testWidgets('the pour keeps one painter, however often the layer rebuilds',
        (tester) async {
      // A painter listens to the animation from its constructor, and the
      // framework never disposes a replaced one — it only drops its own
      // listener. Building a fresh painter per frame would leave a listener on
      // the controller behind for each one.
      await tester.pumpWidget(
        _host(
          const Popover(
            trigger: PopoverTrigger.tap,
            animation: PopoverAnimation.genie,
            placement: PopoverPlacement.bottom,
            content: Text('Poured'),
            child: Text('trigger'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      Object painterNow() =>
          tester.widget<SnapshotWidget>(find.byType(SnapshotWidget)).painter;

      final first = painterNow();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        expect(painterNow(), same(first));
      }
      await tester.pumpAndSettle();
      expect(painterNow(), same(first));
    });

    testWidgets('a settled card is painted without a layer of its own',
        (tester) async {
      // The painter still runs on every frame once the surface has landed.
      // Painting through an opacity of 255 there leaves a compositing layer
      // under the popover for as long as it is open, for nothing.
      await tester.pumpWidget(
        _host(
          const Popover(
            trigger: PopoverTrigger.tap,
            animation: PopoverAnimation.genie,
            placement: PopoverPlacement.bottom,
            content: Text('Poured'),
            child: Text('trigger'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('trigger'));

      int layersFor({required bool settled}) {
        final context = _RecordingContext(_CountingCanvas());
        tester
            .widget<SnapshotWidget>(find.byType(SnapshotWidget))
            .painter
            .paint(
              context,
              Offset.zero,
              const Size(200, 100),
              (context, offset) {},
            );
        return context.opacityLayers;
      }

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(layersFor(settled: false), 1, reason: 'mid-pour it is a fade');

      await tester.pumpAndSettle();
      expect(layersFor(settled: true), 0);
    });

    testWidgets('the card gives up its own shadow while it is poured',
        (tester) async {
      // The picture is the card's own size, so a shadow the card draws is
      // cropped to it: what is left is a hard grey band around the sheet, on
      // top of the one the sheet casts. Only one of the two may draw it, and
      // they swap on the same frame as the rasterising does.
      await tester.pumpWidget(
        _host(
          const Popover(
            trigger: PopoverTrigger.tap,
            animation: PopoverAnimation.genie,
            placement: PopoverPlacement.bottom,
            content: Text('Poured'),
            child: Text('trigger'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      List<BoxShadow>? shadowOfCard() => (tester
              .widgetList<Container>(find.byType(Container))
              .firstWhere(
                (c) =>
                    c.decoration is BoxDecoration &&
                    (c.decoration! as BoxDecoration).borderRadius != null,
              )
              .decoration! as BoxDecoration)
          .boxShadow;

      await tester.tap(find.text('trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        shadowOfCard(),
        anyOf(isNull, isEmpty),
        reason: 'the card is drawing a shadow the picture will crop',
      );

      await tester.pumpAndSettle();
      expect(
        shadowOfCard(),
        isNotEmpty,
        reason: 'the settled card draws its own shadow again',
      );
    });
  });

  testWidgets('the genie takes longer than the fade', (tester) async {
    // A genie at the pace of a fade is over before the eye reads the shape.
    Future<Duration> lengthOf(PopoverAnimation animation) async {
      await tester.pumpWidget(
        _host(
          Popover(
            key: ValueKey<PopoverAnimation>(animation),
            trigger: PopoverTrigger.tap,
            animation: animation,
            content: const Text('Timed'),
            child: const Text('trigger'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('trigger'));
      await tester.pump();

      var elapsed = Duration.zero;
      const step = Duration(milliseconds: 20);
      while (
          tester.binding.hasScheduledFrame && elapsed.inMilliseconds < 2000) {
        await tester.pump(step);
        elapsed += step;
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      return elapsed;
    }

    final simple = await lengthOf(PopoverAnimation.simple);
    final genie = await lengthOf(PopoverAnimation.genie);
    expect(genie, greaterThan(simple));
  });

  testWidgets('the pace is the caller\'s to set', (tester) async {
    Future<Duration> lengthOf(Popover popover) async {
      await tester.pumpWidget(_host(popover));
      await tester.pumpAndSettle();
      await tester.tap(find.text('trigger'));
      await tester.pump();

      var elapsed = Duration.zero;
      const step = Duration(milliseconds: 20);
      while (
          tester.binding.hasScheduledFrame && elapsed.inMilliseconds < 3000) {
        await tester.pump(step);
        elapsed += step;
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      return elapsed;
    }

    final quick = await lengthOf(
      const Popover(
        key: ValueKey('quick'),
        trigger: PopoverTrigger.tap,
        duration: Duration(milliseconds: 100),
        content: Text('Paced'),
        child: Text('trigger'),
      ),
    );
    final slow = await lengthOf(
      const Popover(
        key: ValueKey('slow'),
        trigger: PopoverTrigger.tap,
        duration: Duration(milliseconds: 900),
        content: Text('Paced'),
        child: Text('trigger'),
      ),
    );

    expect(slow.inMilliseconds, greaterThan(quick.inMilliseconds + 400));
  });

  testWidgets('a curve of your own shapes the arrival', (tester) async {
    // Read off the transition the simple arrival is built from.
    Future<double> scaleAt(Curve curve) async {
      await tester.pumpWidget(
        _host(
          Popover(
            key: ValueKey<Curve>(curve),
            trigger: PopoverTrigger.tap,
            duration: const Duration(milliseconds: 400),
            curve: curve,
            content: const Text('Curved'),
            child: const Text('trigger'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('trigger'));
      // One frame puts the layer up, the next starts it: the controller is
      // made when the layer first builds.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 100));

      // The card is drawn scaled, so its painted width is how far the
      // arrival has got.
      final value = tester.getRect(find.text('Curved')).width;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      return value;
    }

    // A quarter of the way in, an ease-out is well ahead of an ease-in.
    expect(
      await scaleAt(Curves.easeOutCubic),
      greaterThan(await scaleAt(Curves.easeInCubic)),
    );
  });
}

/// Counts the shadows a painter casts, without an image to compare.
class _CountingCanvas implements Canvas {
  int shadows = 0;

  @override
  void drawRect(Rect rect, Paint paint) => shadows++;

  @override
  void drawPath(Path path, Paint paint) => shadows++;

  @override
  void noSuchMethod(Invocation invocation) {}
}

class _RecordingContext extends PaintingContext {
  _RecordingContext(this._canvas) : super(ContainerLayer(), Rect.largest);

  final Canvas _canvas;
  int opacityLayers = 0;

  @override
  Canvas get canvas => _canvas;

  @override
  OpacityLayer pushOpacity(
    Offset offset,
    int alpha,
    PaintingContextCallback painter, {
    OpacityLayer? oldLayer,
  }) {
    opacityLayers++;
    return OpacityLayer(alpha: alpha, offset: offset);
  }
}
