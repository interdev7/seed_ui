import 'dart:math' as math;
import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// Records the shapes a painter draws.
class _PathCanvas implements Canvas {
  final List<Path> paths = [];
  final List<Rect> rects = [];

  @override
  void drawPath(Path path, Paint paint) => paths.add(path);

  @override
  void drawRect(Rect rect, Paint paint) => rects.add(rect);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// A page with two targets and a tour over it.
class _Host extends StatefulWidget {
  const _Host({
    required this.steps,
    this.controller,
    this.type = TourType.normal,
    this.mask = const TourMask(),
    this.gap = const TourGap(),
    this.disabledInteraction = false,
    this.closable = true,
    this.closeIcon,
    this.dismissible = true,
    this.duration,
    this.curve,
    this.token,
    this.onTargetTap,
    this.onClose,
    this.onFinish,
    this.onChange,
  });

  final List<TourStep> Function(GlobalKey a, GlobalKey b) steps;
  final TourController? controller;
  final TourType type;
  final TourMask mask;
  final TourGap gap;
  final bool disabledInteraction;
  final bool closable;
  final Widget? closeIcon;
  final bool dismissible;
  final Duration? duration;
  final Curve? curve;
  final TourToken? token;
  final VoidCallback? onTargetTap;
  final VoidCallback? onClose;
  final VoidCallback? onFinish;
  final ValueChanged<int>? onChange;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final GlobalKey _a = GlobalKey();
  final GlobalKey _b = GlobalKey();
  late final TourController _own = TourController();

  TourController get controller => widget.controller ?? _own;

  @override
  void dispose() {
    _own.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConfigProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 40,
                top: 80,
                child: GestureDetector(
                  key: _a,
                  onTap: widget.onTargetTap,
                  child: Container(width: 120, height: 40, color: Colors.blue),
                ),
              ),
              Positioned(
                left: 400,
                top: 400,
                child: SizedBox(key: _b, width: 100, height: 30),
              ),
              // Positioned so the tour cannot shrink the Stack: an
              // unpositioned zero-size child would, and the targets would stop
              // hit-testing.
              Positioned(
                left: 0,
                top: 0,
                child: Tour(
                  controller: controller,
                  type: widget.type,
                  mask: widget.mask,
                  gap: widget.gap,
                  closable: widget.closable,
                  closeIcon: widget.closeIcon,
                  dismissible: widget.dismissible,
                  duration: widget.duration,
                  curve: widget.curve,
                  token: widget.token,
                  disabledInteraction: widget.disabledInteraction,
                  onClose: widget.onClose,
                  onFinish: widget.onFinish,
                  onChange: widget.onChange,
                  steps: widget.steps(_a, _b),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<TourStep> _twoSteps(GlobalKey a, GlobalKey b) => [
      TourStep(
        target: a,
        title: const Text('First'),
        description: const Text('The first thing'),
      ),
      TourStep(target: b, title: const Text('Second')),
    ];

Future<TourController> open(WidgetTester tester, Widget host) async {
  await tester.pumpWidget(host);
  final state = tester.state<_HostState>(find.byType(_Host));
  state.controller.open();
  await tester.pumpAndSettle();
  return state.controller;
}

void main() {
  testWidgets('a tour takes no room until it is opened', (tester) async {
    await tester.pumpWidget(const _Host(steps: _twoSteps));
    expect(tester.getSize(find.byType(Tour)), Size.zero);
    expect(find.text('First'), findsNothing);

    final state = tester.state<_HostState>(find.byType(_Host));
    state.controller.open();
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
  });

  testWidgets('the mask cuts a hole over the step\'s target', (tester) async {
    await open(tester, const _Host(steps: _twoSteps));

    final target = tester.getRect(find.byType(GestureDetector).first);
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .firstWhere((p) => p.runtimeType.toString() == '_MaskPainter');

    // The hole is the target plus the gap's offset, all round.
    final hole = (painter as dynamic).hole as RRect;
    expect(hole.left, closeTo(target.left - 6, 0.5));
    expect(hole.top, closeTo(target.top - 6, 0.5));
    expect(hole.right, closeTo(target.right + 6, 0.5));
    expect(hole.bottom, closeTo(target.bottom + 6, 0.5));
  });

  testWidgets('the hole follows the step', (tester) async {
    final controller = await open(tester, const _Host(steps: _twoSteps));

    RRect holeNow() => (tester
                .widgetList<CustomPaint>(find.byType(CustomPaint))
                .map((p) => p.painter)
                .firstWhere((p) => p.runtimeType.toString() == '_MaskPainter')
            as dynamic)
        .hole as RRect;

    final first = holeNow();
    controller.next();
    await tester.pumpAndSettle();
    expect(holeNow(), isNot(first));
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('the buttons walk the steps and finish the tour', (tester) async {
    var finished = 0, closed = 0;
    final changes = <int>[];
    await open(
      tester,
      _Host(
        steps: _twoSteps,
        onFinish: () => finished++,
        onClose: () => closed++,
        onChange: changes.add,
      ),
    );

    // First step: nothing to go back to.
    expect(find.text('Previous'), findsNothing);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(changes, [1]);
    expect(find.text('Previous'), findsOneWidget);
    // The last step offers to finish rather than to move on.
    expect(find.text('Finish'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(finished, 1);
    expect(closed, 1, reason: 'finishing closes the tour');
    expect(find.text('Second'), findsNothing);
  });

  testWidgets('the close button and a tap on the mask both dismiss it',
      (tester) async {
    var closed = 0;
    final controller = await open(
      tester,
      _Host(steps: _twoSteps, onClose: () => closed++),
    );

    // A tap on the dimmed page, well away from the target.
    await tester.tapAt(const Offset(700, 550));
    await tester.pumpAndSettle();
    expect(closed, 1);
    expect(controller.isOpen, isFalse);

    controller.open();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('softTourClose')));
    await tester.pumpAndSettle();
    expect(closed, 2);
  });

  testWidgets('the target stays live through the hole, unless told otherwise',
      (tester) async {
    var taps = 0;
    await open(
      tester,
      _Host(steps: _twoSteps, onTargetTap: () => taps++),
    );

    // The hole leaves the target's own gesture detector exposed.
    await tester.tapAt(const Offset(100, 100));
    await tester.pumpAndSettle();
    expect(taps, 1, reason: 'a tour can walk you through a real interaction');

    await open(
      tester,
      _Host(
        steps: _twoSteps,
        disabledInteraction: true,
        onTargetTap: () => taps++,
      ),
    );
    await tester.tapAt(const Offset(100, 100));
    await tester.pumpAndSettle();
    expect(taps, 1, reason: 'disabledInteraction blocks the target');
  });

  testWidgets('a step with no target sits in the middle, with no hole',
      (tester) async {
    await open(
      tester,
      _Host(
        steps: (a, b) => const [
          TourStep(title: Text('Welcome'), description: Text('Shall we?')),
        ],
      ),
    );

    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .firstWhere((p) => p.runtimeType.toString() == '_MaskPainter');
    expect((painter as dynamic).hole, isNull);

    final panel = tester.getRect(find.text('Welcome'));
    final screen = tester.getRect(find.byType(MaterialApp));
    expect(panel.center.dx, closeTo(screen.center.dx, 60));
  });

  testWidgets('mask: none leaves the page undimmed', (tester) async {
    await open(tester, const _Host(steps: _twoSteps, mask: TourMask.none));

    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .where((p) => p.runtimeType.toString() == '_MaskPainter');
    expect(painters, isEmpty, reason: 'nothing to paint without a mask');
    // The panel is still there.
    expect(find.text('First'), findsOneWidget);
  });

  testWidgets('gap sets the room round the target and its corners',
      (tester) async {
    await open(
      tester,
      const _Host(
        steps: _twoSteps,
        gap: TourGap(offsetX: 20, offsetY: 2, radius: 12),
      ),
    );

    final target = tester.getRect(find.byType(GestureDetector).first);
    final hole = (tester
                .widgetList<CustomPaint>(find.byType(CustomPaint))
                .map((p) => p.painter)
                .firstWhere((p) => p.runtimeType.toString() == '_MaskPainter')
            as dynamic)
        .hole as RRect;

    expect(hole.left, closeTo(target.left - 20, 0.5));
    expect(hole.top, closeTo(target.top - 2, 0.5));
    expect(hole.tlRadiusX, 12);
  });

  testWidgets('a primary tour paints its panel in the accent', (tester) async {
    await open(tester, const _Host(steps: _twoSteps, type: TourType.primary));

    final panel =
        tester.widgetList<Container>(find.byType(Container)).firstWhere(
              (c) =>
                  c.decoration is BoxDecoration &&
                  (c.decoration! as BoxDecoration).borderRadius != null &&
                  (c.decoration! as BoxDecoration).boxShadow != null,
            );

    expect(
      (panel.decoration! as BoxDecoration).color!.toARGB32(),
      ThemeData.light.token.primary.base.toARGB32(),
    );
  });

  testWidgets('closable: false drops the close button', (tester) async {
    await open(tester, const _Host(steps: _twoSteps, closable: false));
    expect(find.byKey(const Key('softTourClose')), findsNothing);
  });

  testWidgets('one dot per step, the current one apart', (tester) async {
    await open(tester, const _Host(steps: _twoSteps));

    final dots = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .where(
          (c) => (c.decoration as BoxDecoration?)?.shape == BoxShape.circle,
        )
        .toList();
    expect(dots.length, 2);
    expect(
      (dots[0].decoration! as BoxDecoration).color,
      isNot((dots[1].decoration! as BoxDecoration).color),
    );
  });

  testWidgets('the controller drives it from outside', (tester) async {
    final controller = TourController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_Host(steps: _twoSteps, controller: controller));
    expect(find.text('First'), findsNothing);

    controller.open();
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);

    controller.next();
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);

    controller.close();
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsNothing);
    expect(controller.current, 1, reason: 'closing keeps its place');
  });

  testWidgets('a panel hugs its content, up to the ceiling', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<double> widthOf(String description) async {
      await open(
        tester,
        _Host(
          steps: (a, b) => [
            TourStep(
              target: a,
              title: const Text('Title'),
              description: Text(description),
            ),
          ],
        ),
      );
      // The panel is the box painted behind the text.
      return tester
          .getRect(
            find
                .ancestor(
                  of: find.text('Title'),
                  matching: find.byType(Container),
                )
                .last,
          )
          .width;
    }

    final short = await widthOf('Short.');
    final long = await widthOf(
        'A description long enough to need a good deal more room than the '
        'short one, and then some more on top of that.');

    expect(short, lessThan(long), reason: 'a small step gets a small panel');
    expect(long, lessThanOrEqualTo(520 + 0.5), reason: '520 is the ceiling');
  });

  testWidgets('a panel crosses to the other axis rather than cover its target',
      (tester) async {
    // A phone: a panel this wide fits neither left nor right of the target,
    // and clamping it into the viewport would lay it over the very thing it
    // points at.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await open(
      tester,
      _Host(
        steps: (a, b) => [
          TourStep(
            target: a,
            placement: TourPlacement.rightTop,
            title: const Text('First'),
            description: const Text('Click to see other actions.'),
          ),
        ],
      ),
    );

    final target = tester.getRect(find.byType(GestureDetector).first);
    final panel = tester.getRect(
      find
          .ancestor(
            of: find.text('First'),
            matching: find.byType(Container),
          )
          .last,
    );

    expect(panel.overlaps(target), isFalse);
    expect(
      panel.top,
      greaterThanOrEqualTo(target.bottom),
      reason: 'no room either side, so it goes below',
    );
  });

  testWidgets('a centred panel keeps clear of the screen edges',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await open(
      tester,
      _Host(
        steps: (a, b) => const [
          TourStep(
            title: Text('Welcome'),
            description: Text(
              'A description long enough to want more room than this screen '
              'has, so the panel is held back by its margin rather than the '
              'ceiling.',
            ),
          ),
        ],
      ),
    );

    final panel = tester.getRect(
      find
          .ancestor(
            of: find.text('Welcome'),
            matching: find.byType(Container),
          )
          .last,
    );

    expect(panel.left, greaterThanOrEqualTo(8 - 0.5));
    expect(panel.right, lessThanOrEqualTo(390 - 8 + 0.5));
  });

  testWidgets('opening again starts over; resuming carries on', (tester) async {
    final controller = await open(tester, const _Host(steps: _twoSteps));

    controller.next();
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);

    controller.close();
    await tester.pumpAndSettle();
    expect(controller.current, 1, reason: 'closing keeps its place');

    // "Begin tour" means begin, not carry on.
    controller.open();
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    expect(controller.current, 0);

    // Carrying on is the other intent, and it is spelt out.
    controller.next();
    controller.close();
    await tester.pumpAndSettle();
    controller.resume();
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);
  });

  group('Step buttons', () {
    testWidgets('a label and a press hook, on top of the tour\'s own move',
        (tester) async {
      var pressed = 0;
      final changes = <int>[];
      await open(
        tester,
        _Host(
          onChange: changes.add,
          steps: (a, b) => [
            TourStep(
              target: a,
              title: const Text('First'),
              nextButton: TourButton(
                label: const Text('Got it'),
                onPressed: () => pressed++,
              ),
            ),
            TourStep(
              target: b,
              title: const Text('Second'),
              prevButton: const TourButton(label: Text('Back')),
            ),
          ],
        ),
      );

      expect(find.text('Next'), findsNothing);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      // The hook runs as well as the move, not instead of it.
      expect(pressed, 1);
      expect(changes, [1]);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('a disabled button will not let the step be left',
        (tester) async {
      final changes = <int>[];
      await open(
        tester,
        _Host(
          onChange: changes.add,
          steps: (a, b) => [
            TourStep(
              target: a,
              title: const Text('First'),
              nextButton: const TourButton(disabled: true),
            ),
            TourStep(target: b, title: const Text('Second')),
          ],
        ),
      );

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      expect(find.text('First'), findsOneWidget);
    });

    testWidgets('the look is the caller\'s to change', (tester) async {
      await open(
        tester,
        _Host(
          steps: (a, b) => [
            TourStep(
              target: a,
              title: const Text('First'),
              nextButton: const TourButton(
                variant: ButtonVariant.outlined,
                color: ButtonColor.danger,
                icon: Icon(Icons.delete),
              ),
            ),
          ],
        ),
      );

      final button = tester.widget<Button>(find.byType(Button).last);
      expect(button.variant, ButtonVariant.outlined);
      expect(button.color, ButtonColor.danger);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('a button of your own, driven by the tour\'s own action',
        (tester) async {
      var pressed = 0;
      final changes = <int>[];
      await open(
        tester,
        _Host(
          onChange: changes.add,
          steps: (a, b) => [
            TourStep(
              target: a,
              title: const Text('First'),
              nextButton: TourButton.custom(
                (context, act) => GestureDetector(
                  onTap: act,
                  child: const Text('Take the tour'),
                ),
                onPressed: () => pressed++,
              ),
            ),
            TourStep(target: b, title: const Text('Second')),
          ],
        ),
      );

      // No Button of ours in sight — the widget is the caller's.
      expect(find.text('Next'), findsNothing);
      await tester.tap(find.text('Take the tour'));
      await tester.pumpAndSettle();

      expect(changes, [1], reason: 'the tour still moves on');
      expect(pressed, 1, reason: 'and the hook still fires');
    });

    testWidgets('a custom button is handed no action while disabled',
        (tester) async {
      VoidCallback? handed;
      await open(
        tester,
        _Host(
          steps: (a, b) => [
            TourStep(
              target: a,
              title: const Text('First'),
              nextButton: TourButton.custom(
                (context, act) {
                  handed = act;
                  return const Text('Waiting');
                },
                disabled: true,
              ),
            ),
            TourStep(target: b, title: const Text('Second')),
          ],
        ),
      );

      expect(handed, isNull, reason: 'so the widget can read as off');
    });
  });

  testWidgets('what a caller builds inherits a real text style',
      (tester) async {
    // The overlay sits outside any Material ancestor, where Flutter falls back
    // to a 48px debug style with yellow underlines.
    late TextStyle seen;
    await open(
      tester,
      _Host(
        steps: (a, b) => [
          TourStep(
            target: a,
            title: const Text('First'),
            nextButton: TourButton.custom((context, act) {
              seen = DefaultTextStyle.of(context).style;
              return const Text('Go');
            }),
          ),
        ],
      ),
    );

    expect(seen.fontSize, ThemeData.light.token.fontSize);
    expect(seen.decoration, TextDecoration.none);
  });

  testWidgets('the highlight travels between steps rather than jumping',
      (tester) async {
    final controller = await open(tester, const _Host(steps: _twoSteps));

    RRect hole() => (tester
                .widgetList<CustomPaint>(find.byType(CustomPaint))
                .map((p) => p.painter)
                .firstWhere((p) => p.runtimeType.toString() == '_MaskPainter')
            as dynamic)
        .hole as RRect;

    final from = hole();
    controller.next();
    await tester.pump();

    // Halfway there: the spotlight is between the two targets, not on either.
    await tester.pump(const Duration(milliseconds: 150));
    final travelling = hole();
    expect(travelling.left, isNot(closeTo(from.left, 1)));

    await tester.pumpAndSettle();
    final to = hole();
    expect(travelling.left, greaterThan(from.left));
    expect(travelling.left, lessThan(to.left));
    expect(travelling.top, greaterThan(from.top));
    expect(travelling.top, lessThan(to.top));
  });

  testWidgets('a tour opens on its first step without sliding in',
      (tester) async {
    // Nothing to travel from: the spotlight is on the target from the first
    // frame it is drawn.
    await tester.pumpWidget(const _Host(steps: _twoSteps));
    final state = tester.state(find.byType(_Host)) as dynamic;
    state.controller.open();
    await tester.pump();
    await tester.pump();

    final hole = (tester
                .widgetList<CustomPaint>(find.byType(CustomPaint))
                .map((p) => p.painter)
                .firstWhere((p) => p.runtimeType.toString() == '_MaskPainter')
            as dynamic)
        .hole as RRect;
    final target = tester.getRect(find.byType(GestureDetector).first);
    expect(hole.left, closeTo(target.left - 6, 0.5));
  });

  testWidgets('the travel is the caller\'s to time', (tester) async {
    // Zero means the highlight is where it belongs on the next frame.
    final controller = TourController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _Host(
        controller: controller,
        steps: _twoSteps,
        token: const TourToken(travelDuration: Duration.zero),
      ),
    );
    controller.open();
    await tester.pumpAndSettle();

    RRect hole() => (tester
                .widgetList<CustomPaint>(find.byType(CustomPaint))
                .map((p) => p.painter)
                .firstWhere((p) => p.runtimeType.toString() == '_MaskPainter')
            as dynamic)
        .hole as RRect;

    controller.next();
    await tester.pump();
    await tester.pump();

    expect(
      hole().left,
      greaterThan(300),
      reason: 'straight onto the second target, no travel: ${hole().left}',
    );
  });

  testWidgets('a close icon of your own', (tester) async {
    await open(
      tester,
      const _Host(
        closeIcon: Icon(Icons.keyboard_arrow_down),
        steps: _twoSteps,
      ),
    );

    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    // Still the close button: it dismisses the tour.
    await tester.tap(find.byKey(const Key('softTourClose')));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsNothing);
  });

  testWidgets('the spotlight opens out of the middle after a welcome step',
      (tester) async {
    final controller = await open(
      tester,
      _Host(
        steps: (a, b) => [
          const TourStep(title: Text('Welcome')),
          TourStep(target: a, title: const Text('First')),
        ],
      ),
    );

    RRect? hole() {
      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .where((p) => p.runtimeType.toString() == '_MaskPainter');
      return painters.isEmpty
          ? null
          : (painters.first as dynamic).hole as RRect?;
    }

    // Nothing to point at yet.
    expect(hole(), isNull);

    controller.next();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    // Halfway there the hole exists but has not arrived: it is opening out of
    // the middle of the screen rather than appearing on the target outright.
    final travelling = hole();
    final target = tester.getRect(find.byType(GestureDetector).first);
    expect(travelling, isNotNull);
    expect(travelling!.width, lessThan(target.width + 12));
    expect(travelling.left, greaterThan(target.left));

    await tester.pumpAndSettle();
    expect(hole()!.left, closeTo(target.left - 6, 0.5));
  });

  testWidgets('dismissible: false keeps the tour up, and still eats the tap',
      (tester) async {
    var closed = 0;
    var behind = 0;
    final controller = await open(
      tester,
      _Host(
        steps: _twoSteps,
        dismissible: false,
        onClose: () => closed++,
        onTargetTap: () => behind++,
      ),
    );

    // A tap on the dimmed page, well away from the target.
    await tester.tapAt(const Offset(700, 550));
    await tester.pumpAndSettle();
    expect(closed, 0);
    expect(controller.isOpen, isTrue);

    // The mask still swallows it: nothing behind the tour was pressed.
    expect(behind, 0);

    // The buttons are the way out.
    await tester.tap(find.byKey(const Key('softTourClose')));
    await tester.pumpAndSettle();
    expect(closed, 1);
  });

  testWidgets('a single step can refuse to be dismissed', (tester) async {
    var closed = 0;
    await open(
      tester,
      _Host(
        onClose: () => closed++,
        steps: (a, b) => [
          TourStep(
            target: a,
            title: const Text('First'),
            dismissible: false,
          ),
          TourStep(target: b, title: const Text('Second')),
        ],
      ),
    );

    await tester.tapAt(const Offset(700, 550));
    await tester.pumpAndSettle();
    expect(closed, 0, reason: 'this step holds on');

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(700, 550));
    await tester.pumpAndSettle();
    expect(closed, 1, reason: 'the next one does not');
  });

  group('Moving between steps', () {
    Rect panelIn(WidgetTester tester) => tester.getRect(
          find
              .ancestor(
                of: find.byKey(const Key('softTourClose')),
                matching: find.byType(Container),
              )
              .last,
        );

    testWidgets('one panel travels; it is not swapped for another',
        (tester) async {
      final controller = await open(tester, const _Host(steps: _twoSteps));

      final from = panelIn(tester);
      controller.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // A cross-fade would show two panels at once over the mask.
      expect(find.byKey(const Key('softTourClose')), findsOneWidget);
      final travelling = panelIn(tester);

      await tester.pumpAndSettle();
      final to = panelIn(tester);
      expect(to.center, isNot(from.center));
      expect(travelling.center, isNot(from.center));
      expect(travelling.center, isNot(to.center));
    });

    testWidgets('a change of placement does not teleport the panel',
        (tester) async {
      // The rule changes in one frame; laying the panel out from the new rule
      // put it at its destination for that frame — the flash — before easing
      // the rest of the way.
      final controller = TourController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _Host(
          controller: controller,
          steps: (a, b) => [
            TourStep(
              target: a,
              title: const Text('First'),
              placement: TourPlacement.bottom,
            ),
            TourStep(
              target: b,
              title: const Text('Second'),
              placement: TourPlacement.rightTop,
            ),
          ],
        ),
      );
      controller.open();
      await tester.pumpAndSettle();

      final before = panelIn(tester);
      controller.next();
      await tester.pump();

      final first = panelIn(tester);
      expect(first.left, closeTo(before.left, 1));
      expect(first.top, closeTo(before.top, 1));

      await tester.pumpAndSettle();
      expect(panelIn(tester).center, isNot(before.center));
    });

    testWidgets('the journey is smooth, whatever the panel does on the way',
        (tester) async {
      // The panel resizes for the new text and the layout may change its mind
      // about which side of the target to sit on. Neither is a new journey:
      // treating them as one threw the panel hundreds of pixels in a frame.
      final controller = TourController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _Host(
          controller: controller,
          steps: (a, b) => [
            TourStep(
              target: a,
              title: const Text('First'),
              description: const Text('Short.'),
            ),
            TourStep(
              target: b,
              title: const Text('Second'),
              placement: TourPlacement.rightTop,
              description: const Text(
                'A much longer description, so the panel changes size while it '
                'is on its way to the other side of the page.',
              ),
            ),
          ],
        ),
      );
      controller.open();
      await tester.pumpAndSettle();

      final from = panelIn(tester).topLeft;
      controller.next();

      var previous = from;
      var biggest = 0.0;
      for (var i = 0; i < 14; i++) {
        await tester.pump(const Duration(milliseconds: 25));
        final now = panelIn(tester).topLeft;
        biggest = math.max(biggest, (now - previous).distance);
        previous = now;
      }
      await tester.pumpAndSettle();

      final total = (panelIn(tester).topLeft - from).distance;
      expect(total, greaterThan(100), reason: 'it did travel');
      expect(
        biggest,
        lessThan(total * 0.35),
        reason: 'one frame moved $biggest of $total — that is a lurch',
      );
    });

    testWidgets('a step with no target is travelled to, not swapped in',
        (tester) async {
      final controller = await open(
        tester,
        _Host(
          steps: (a, b) => [
            TourStep(target: a, title: const Text('First')),
            const TourStep(title: Text('Welcome')),
          ],
        ),
      );

      controller.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byKey(const Key('softTourClose')), findsOneWidget);

      await tester.pumpAndSettle();
      final panel = panelIn(tester);
      final screen = tester.getRect(find.byType(MaterialApp));
      expect(panel.center.dx, closeTo(screen.center.dx, 2));
      expect(panel.center.dy, closeTo(screen.center.dy, 2));
    });
  });

  group('Timing', () {
    Rect panelIn(WidgetTester tester) => tester.getRect(
          find
              .ancestor(
                of: find.byKey(const Key('softTourClose')),
                matching: find.byType(Container),
              )
              .last,
        );

    testWidgets('duration on the widget times the journey', (tester) async {
      final controller = TourController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _Host(
          controller: controller,
          steps: _twoSteps,
          duration: const Duration(seconds: 2),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();

      final from = panelIn(tester).topLeft;
      controller.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // A tenth of the way through two seconds: barely started.
      final early = panelIn(tester).topLeft;
      await tester.pumpAndSettle();
      final to = panelIn(tester).topLeft;

      final travelled = (early - from).distance;
      final total = (to - from).distance;
      expect(total, greaterThan(100));
      expect(
        travelled,
        lessThan(total * 0.4),
        reason: 'two seconds, so 300ms is early: $travelled of $total',
      );
    });

    testWidgets('zero moves everything in one frame', (tester) async {
      final controller = TourController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _Host(
          controller: controller,
          steps: _twoSteps,
          duration: Duration.zero,
        ),
      );
      controller.open();
      await tester.pumpAndSettle();

      final from = panelIn(tester).topLeft;
      controller.next();
      await tester.pump();
      await tester.pump();

      expect(panelIn(tester).topLeft, isNot(from));
      // And it is already where it belongs, not part way.
      final settled = panelIn(tester).topLeft;
      await tester.pumpAndSettle();
      expect(panelIn(tester).topLeft, settled);
    });

    testWidgets('the widget wins over the token', (tester) async {
      final controller = TourController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _Host(
          controller: controller,
          steps: _twoSteps,
          duration: Duration.zero,
          token: const TourToken(travelDuration: Duration(seconds: 5)),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();

      final from = panelIn(tester).topLeft;
      controller.next();
      await tester.pump();
      await tester.pump();
      final settled = panelIn(tester).topLeft;

      await tester.pumpAndSettle();
      expect(
        panelIn(tester).topLeft,
        settled,
        reason: 'zero from the widget, not five seconds from the token',
      );
      expect(settled, isNot(from));
    });

    testWidgets('curve on the widget shapes the journey', (tester) async {
      Future<double> quarterWay(Curve curve) async {
        final controller = TourController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _Host(
            controller: controller,
            steps: _twoSteps,
            duration: const Duration(milliseconds: 400),
            curve: curve,
          ),
        );
        controller.open();
        await tester.pumpAndSettle();

        final from = panelIn(tester).topLeft;
        controller.next();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final at = panelIn(tester).topLeft;
        await tester.pumpAndSettle();
        return (at - from).distance / (panelIn(tester).topLeft - from).distance;
      }

      // A linear quarter is a quarter of the way; an ease-in one is not.
      expect(await quarterWay(Curves.linear), closeTo(0.25, 0.08));
      expect(await quarterWay(Curves.easeInCubic), lessThan(0.1));
    });
  });

  group('The caret', () {
    /// The caret as drawn this frame: where it points from, and which way.
    (Offset, Object)? caret(WidgetTester tester) {
      final found = find.byKey(const Key('softTourArrow'));
      if (found.evaluate().isEmpty) return null;
      final painter = tester.widget<CustomPaint>(found).painter! as dynamic;
      return (painter.geometry.base as Offset, painter.geometry.side as Object);
    }

    Widget host(TourController controller, TourPlacement second) => _Host(
          controller: controller,
          steps: (a, b) => [
            TourStep(
              target: a,
              title: const Text('First'),
              placement: TourPlacement.bottom,
            ),
            TourStep(
              target: b,
              title: const Text('Second'),
              placement: second,
            ),
          ],
        );

    testWidgets(
        'travels with the panel, and turns halfway when it changes side',
        (tester) async {
      // A caret cannot change edges gradually. Left alone it jumped from one
      // edge of the panel to the other in a single frame.
      final controller = TourController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(host(controller, TourPlacement.left));
      controller.open();
      await tester.pumpAndSettle();

      final from = caret(tester)!;
      controller.next();

      var previous = from.$1;
      var biggest = 0.0;
      final sides = <Object>{};
      for (var i = 0; i < 14; i++) {
        await tester.pump(const Duration(milliseconds: 25));
        final now = caret(tester)!;
        biggest = math.max(biggest, (now.$1 - previous).distance);
        previous = now.$1;
        sides.add(now.$2);
      }
      await tester.pumpAndSettle();

      final to = caret(tester)!;
      final total = (to.$1 - from.$1).distance;
      expect(total, greaterThan(100), reason: 'it did travel');
      expect(
        biggest,
        lessThan(total * 0.35),
        reason: 'one frame moved $biggest of $total — that is a teleport',
      );

      // It did change edges, once.
      expect(sides.length, 2);
      expect(to.$2, isNot(from.$2));
    });

    testWidgets('keeps to one side when the steps agree', (tester) async {
      final controller = TourController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(host(controller, TourPlacement.bottom));
      controller.open();
      await tester.pumpAndSettle();

      final from = caret(tester)!;
      controller.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      final travelling = caret(tester)!;

      await tester.pumpAndSettle();
      final to = caret(tester)!;

      expect(travelling.$2, from.$2, reason: 'no reason to turn');
      expect(travelling.$1.dx, greaterThan(from.$1.dx));
      expect(travelling.$1.dx, lessThan(to.$1.dx));
    });
  });

  group('Changing over the contents', () {
    double opacityOf(WidgetTester tester, String text) {
      final found = find.ancestor(
        of: find.text(text),
        matching: find.byType(FadeTransition),
      );
      if (found.evaluate().isEmpty) return 0;
      return tester.widget<FadeTransition>(found.first).opacity.value;
    }

    testWidgets('the panel\'s text crosses over rather than being replaced',
        (tester) async {
      final controller = await open(tester, const _Host(steps: _twoSteps));

      controller.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Both are on screen mid-way, one going and one coming.
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      final going = opacityOf(tester, 'First');
      final coming = opacityOf(tester, 'Second');
      expect(going, lessThan(1));
      expect(going, greaterThan(0));
      expect(coming, greaterThan(0));
      expect(coming, lessThan(1));

      await tester.pumpAndSettle();
      expect(find.text('First'), findsNothing);
      expect(opacityOf(tester, 'Second'), 1);
    });

    testWidgets('the panel is the size of the step arriving, not of both',
        (tester) async {
      final controller = TourController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _Host(
          controller: controller,
          steps: (a, b) => [
            TourStep(
              target: a,
              title: const Text('First'),
              description: const Text(
                'A rather long description that makes this panel tall, so the '
                'one after it is shorter by some way.',
              ),
            ),
            TourStep(target: b, title: const Text('Second')),
          ],
        ),
      );
      controller.open();
      await tester.pumpAndSettle();

      Rect panel() => tester.getRect(
            find
                .ancestor(
                  of: find.byKey(const Key('softTourClose')),
                  matching: find.byType(Container),
                )
                .last,
          );

      final tall = panel().height;
      controller.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      final crossing = panel().height;

      await tester.pumpAndSettle();
      final short = panel().height;

      // The card eases between the two sizes — it is on its way, not at
      // either end — and the outgoing text, taller than the card it is
      // leaving, is clipped rather than holding the card open.
      expect(short, lessThan(tall));
      expect(crossing, lessThan(tall));
      expect(crossing, greaterThan(short));
    });
  });

  testWidgets('a wide step leaving a narrow one does not overflow',
      (tester) async {
    // The outgoing copy was being squeezed into the arriving panel's box: its
    // footer — dots on one side, buttons on the other — did not fit, and the
    // crossing ended in overflow stripes.
    final controller = TourController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _Host(
        controller: controller,
        steps: (a, b) => [
          TourStep(
            target: a,
            title:
                const Text('A step with a long title and a long description'),
            description: const Text(
              'Long enough that the panel is wide, with a footer that needs '
              'every pixel of it.',
            ),
          ),
          TourStep(target: b, title: const Text('Ok')),
        ],
      ),
    );
    controller.open();
    await tester.pumpAndSettle();

    controller.next();
    for (final ms in [16, 60, 120, 200, 320]) {
      await tester.pump(Duration(milliseconds: ms));
      expect(tester.takeException(), isNull, reason: 'at +${ms}ms');
    }
  });

  testWidgets('the card eases into the size the next step wants',
      (tester) async {
    final controller = TourController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _Host(
        controller: controller,
        steps: (a, b) => [
          TourStep(target: a, title: const Text('Hi')),
          TourStep(
            target: b,
            title: const Text('Second'),
            description: const Text(
              'Wider now, by a good margin over the step before it.',
            ),
          ),
        ],
      ),
    );
    controller.open();
    await tester.pumpAndSettle();

    Rect panel() => tester.getRect(
          find
              .ancestor(
                of: find.byKey(const Key('softTourClose')),
                matching: find.byType(Container),
              )
              .last,
        );

    final narrow = panel().width;
    controller.next();

    final widths = <double>[];
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 25));
      widths.add(panel().width);
    }
    await tester.pumpAndSettle();
    final wide = panel().width;

    expect(wide, greaterThan(narrow + 50), reason: 'the steps differ');
    // It passes through the sizes between rather than jumping to the last:
    // the card itself grows, corners and all, not an invisible box round it.
    final between = widths.where((w) => w > narrow + 1 && w < wide - 1);
    expect(between.length, greaterThan(4), reason: 'widths $widths');
  });

  group('Reaching the target', () {
    /// A page taller than the screen, with a target near the bottom.
    Future<ScrollController> pump(
      WidgetTester tester, {
      bool scrollIntoView = true,
      TourController? controller,
    }) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final near = GlobalKey();
      final far = GlobalKey();
      final scroller = ScrollController();
      addTearDown(scroller.dispose);

      await tester.pumpWidget(
        ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  SingleChildScrollView(
                    controller: scroller,
                    child: Column(
                      children: [
                        const SizedBox(height: 100),
                        SizedBox(key: near, width: 120, height: 40),
                        const SizedBox(height: 2000),
                        SizedBox(key: far, width: 120, height: 40),
                        const SizedBox(height: 600),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Tour(
                      controller: controller,
                      scrollIntoView: scrollIntoView,
                      steps: [
                        TourStep(target: near, title: const Text('Near')),
                        TourStep(target: far, title: const Text('Far below')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return scroller;
    }

    RRect? holeIn(WidgetTester tester) {
      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .where((p) => p.runtimeType.toString() == '_MaskPainter');
      return painters.isEmpty
          ? null
          : (painters.first as dynamic).hole as RRect?;
    }

    testWidgets('a step below the fold brings the page to it', (tester) async {
      final controller = TourController();
      addTearDown(controller.dispose);
      final scroller = await pump(tester, controller: controller);

      controller.open();
      await tester.pumpAndSettle();
      expect(scroller.offset, 0, reason: 'the first target is already in view');

      controller.next();
      await tester.pumpAndSettle();
      expect(scroller.offset, greaterThan(1000));

      // And the spotlight is on the target where it now is, not where it was.
      final target = tester.getRect(find.text('Far below'));
      final hole = holeIn(tester)!;
      expect(hole.top, lessThan(600), reason: 'the hole is on screen');
      expect(target.top, lessThan(600));
    });

    testWidgets('the spotlight follows a page scrolled under it',
        (tester) async {
      final controller = TourController();
      addTearDown(controller.dispose);
      final scroller = await pump(tester, controller: controller);

      controller.open();
      await tester.pumpAndSettle();
      final before = holeIn(tester)!.top;

      scroller.jumpTo(60);
      await tester.pump();
      // One frame to notice the target has moved, one to redraw.
      await tester.pump();

      expect(
        holeIn(tester)!.top,
        closeTo(before - 60, 1),
        reason: 'the target moved, so the spotlight did',
      );
    });

    testWidgets('scrollIntoView: false leaves the page where it is',
        (tester) async {
      final controller = TourController();
      addTearDown(controller.dispose);
      final scroller =
          await pump(tester, scrollIntoView: false, controller: controller);

      controller.open();
      await tester.pumpAndSettle();
      controller.next();
      await tester.pumpAndSettle();

      expect(scroller.offset, 0);
    });
  });

  group('Painting the mask', () {
    testWidgets('the hole is cut by a fill rule, not by a path operation',
        (tester) async {
      // `Path.combine` needs a renderer that can do path operations, and on
      // the web that is not a given: the mask came out solid, with nothing lit.
      await open(tester, const _Host(steps: _twoSteps));

      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .firstWhere((p) => p.runtimeType.toString() == '_MaskPainter')!;

      final canvas = _PathCanvas();
      painter.paint(canvas, const Size(800, 600));

      expect(canvas.paths, hasLength(1), reason: 'one shape, one fill');
      final path = canvas.paths.single;
      expect(path.fillType, PathFillType.evenOdd);

      // The target's middle is outside the fill; a corner of the screen is in.
      final target = tester.getRect(find.byType(GestureDetector).first);
      expect(
        path.contains(target.center),
        isFalse,
        reason: 'the hole is not painted over',
      );
      expect(path.contains(const Offset(700, 550)), isTrue);
    });

    testWidgets('with nothing to point at the page is covered', (tester) async {
      await open(
        tester,
        _Host(steps: (a, b) => const [TourStep(title: Text('Welcome'))]),
      );

      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .firstWhere((p) => p.runtimeType.toString() == '_MaskPainter')!;

      final canvas = _PathCanvas();
      painter.paint(canvas, const Size(800, 600));
      expect(canvas.paths, isEmpty, reason: 'a plain rect, no shape needed');
      expect(canvas.rects, hasLength(1));
    });
  });
}
