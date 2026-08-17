import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
// The kit hides Material's ThemeData; this test needs it to pick a platform.
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
// The add button's glyph lives with the kit's other icons and is internal to
// it rather than part of the surface.
import 'package:seed_ui/src/icons/icons.dart' show PlusPainter;

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

const _items = [
  TabItem(key: 'a', label: Text('Alpha'), content: Text('Panel A')),
  TabItem(key: 'b', label: Text('Beta'), content: Text('Panel B')),
  TabItem(
    key: 'c',
    label: Text('Gamma'),
    disabled: true,
    content: Text('Panel C'),
  ),
];

void main() {
  testWidgets('shows the first panel and switches on tab tap', (tester) async {
    await tester.pumpWidget(_host(const Tabs(items: _items)));
    expect(find.text('Panel A'), findsOneWidget);
    expect(find.text('Panel B'), findsNothing);

    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(find.text('Panel B'), findsOneWidget);
  });

  testWidgets('reports onChange with the new key', (tester) async {
    String? changed;
    await tester.pumpWidget(
      _host(
        Tabs(items: _items, onChange: (k) => changed = k),
      ),
    );
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(changed, 'b');
  });

  testWidgets('a disabled tab does not switch', (tester) async {
    await tester.pumpWidget(_host(const Tabs(items: _items)));
    await tester.tap(find.text('Gamma'));
    await tester.pumpAndSettle();
    expect(find.text('Panel A'), findsOneWidget);
    expect(find.text('Panel C'), findsNothing);
  });

  testWidgets('controlled activeKey is honoured', (tester) async {
    await tester.pumpWidget(
      _host(
        const Tabs(items: _items, activeKey: 'b'),
      ),
    );
    expect(find.text('Panel B'), findsOneWidget);
    // Without onChange the controlled key does not move.
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(find.text('Panel B'), findsOneWidget);
  });

  testWidgets('editable card fires onEdit for add and remove', (tester) async {
    final events = <String>[];
    await tester.pumpWidget(
      _host(
        Tabs(
          type: TabsType.editableCard,
          items: _items,
          onEdit: (key, action) => events.add('${action.name}:$key'),
        ),
      ),
    );

    // Close button on the first tab.
    final cross = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == 'CrossPainter',
    );
    expect(cross, findsWidgets);
    await tester.tap(cross.first);
    await tester.pump();
    expect(events.any((e) => e.startsWith('remove:')), isTrue);

    // Add button.
    final plus = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is PlusPainter,
    );
    expect(plus, findsOneWidget);
    await tester.tap(plus);
    await tester.pump();
    expect(events, contains('add:null'));
  });

  testWidgets('controller drives switching and notifies listeners',
      (tester) async {
    final controller = TabsController(items: _items);
    var notifications = 0;
    controller.addListener(() => notifications++);

    await tester.pumpWidget(_host(Tabs(controller: controller)));
    expect(find.text('Panel A'), findsOneWidget);

    controller.select('b');
    await tester.pumpAndSettle();
    expect(find.text('Panel B'), findsOneWidget);
    expect(controller.activeKey, 'b');
    expect(notifications, 1);
  });

  testWidgets('controller.setTitle updates a tab label live', (tester) async {
    final controller = TabsController(items: _items);
    await tester.pumpWidget(_host(Tabs(controller: controller)));
    expect(find.text('Alpha'), findsOneWidget);

    controller.setTitle('a', 'Renamed');
    await tester.pumpAndSettle();
    expect(find.text('Renamed'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
  });

  testWidgets('onCreateTab seeds the new tab; null fields autoincrement',
      (tester) async {
    final controller = TabsController(
      items: const [
        TabItem(key: '1', label: Text('Tab 1'), content: Text('One')),
      ],
    );
    await tester.pumpWidget(
      _host(
        Tabs(
          type: TabsType.editableCard,
          controller: controller,
          onCreateTab: (index) => index == 1
              ? const CreateTabData(
                  label: Text('News'),
                  key: 'news',
                  content: Text('News!'),
                )
              : null,
        ),
      ),
    );

    final plus = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is PlusPainter,
    );
    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(controller.items.length, 2);
    expect(controller.activeKey, 'news');
    expect(find.text('News!'), findsOneWidget);

    // A second add with onCreateTab returning null falls back to autoincrement.
    await tester.tap(plus);
    await tester.pump();
    expect(controller.items.length, 3);
    expect(controller.items.last.key, isNot('news'));
  });

  testWidgets('controller.remove closes a tab and moves the active tab',
      (tester) async {
    final controller = TabsController(items: _items, activeKey: 'b');
    await tester.pumpWidget(_host(Tabs(controller: controller)));
    controller.remove('b');
    await tester.pumpAndSettle();
    expect(controller.items.any((e) => e.key == 'b'), isFalse);
    expect(controller.activeKey, isNotNull);
  });

  group('Snapping', () {
    List<TabItem> longRun() => [
          for (var i = 1; i <= 12; i++)
            TabItem(
              key: '$i',
              label: Text('Section number $i'),
              content: Text('Panel $i'),
            ),
        ];

    Future<double> flingAndSettle(WidgetTester tester,
        {required bool snap}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: Tabs(items: longRun(), snap: snap),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(
          find.text('Section number 1'), const Offset(-140, 0), 600);
      await tester.pumpAndSettle();

      final bar = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      return bar.controller!.offset;
    }

    testWidgets('off by default, so a fling stops where it stops',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 300, child: Tabs(items: longRun())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bar = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(bar.physics, isNull);
    });

    testWidgets('snap: true installs the snapping physics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: Tabs(items: longRun(), snap: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bar = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(bar.physics, isNotNull);
    });

    testWidgets('the end of the run stops at the end, not before it', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: Tabs(items: longRun(), snap: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bar = find.byType(SingleChildScrollView);
      final controller = tester.widget<SingleChildScrollView>(bar).controller!;

      // Throw past the end. No tab begins at the maximum, so insisting on a
      // tab boundary here would haul the bar back to the last one before it
      // and strand the final tabs beyond the trailing edge.
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await tester.fling(bar, const Offset(-300, 0), 3000);
      await tester.pumpAndSettle();

      expect(
        controller.position.pixels,
        moreOrLessEquals(controller.position.maxScrollExtent),
      );
      // Which is to say the last tab is wholly in view.
      final last = find.text('Section number ${longRun().length}');
      expect(
        tester.getTopRight(last).dx,
        lessThanOrEqualTo(tester.getTopRight(bar).dx + 0.5),
      );
    });

    testWidgets('a fling comes to rest on a tab boundary', (tester) async {
      final settled = await flingAndSettle(tester, snap: true);

      // Every tab in this run is the same width, so a boundary is a whole
      // multiple of one. Measure that from the rendered tabs rather than
      // assuming it.
      final first = tester.getTopLeft(find.text('Section number 2')).dx -
          tester.getTopLeft(find.text('Section number 1')).dx;
      final remainder = settled % first;
      expect(
        remainder < 1.0 || (first - remainder) < 1.0,
        isTrue,
        reason: 'settled at $settled, which is not a multiple of $first',
      );
    });
  });
  testWidgets('the end of a snapping run is a place the bar can rest', (
    tester,
  ) async {
    // Bouncing physics: the pull back from the end is invisible under the
    // clamping kind, which stops dead at the maximum on its own.
    await tester.pumpWidget(
      MaterialApp(
        theme: material.ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: Tabs(
                snap: true,
                items: [
                  for (var i = 1; i <= 14; i++)
                    TabItem(
                      key: '$i',
                      label: Text('Section $i'),
                      content: Text('Panel $i'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bar = find.byType(SingleChildScrollView).first;
    final position =
        tester.widget<SingleChildScrollView>(bar).controller!.position;
    // No tab begins at the maximum, so this is the case that used to strand
    // the last tabs off the trailing edge.
    expect(
      position.maxScrollExtent % 100,
      isNot(0),
      reason: 'the run must not end on a round boundary for this to bite',
    );

    for (var i = 0; i < 12; i++) {
      await tester.fling(bar, const Offset(-300, 0), 3000);
      await tester.pumpAndSettle();
    }
    expect(position.pixels, moreOrLessEquals(position.maxScrollExtent));

    // And having got there, tapping a tab near the end must not haul the bar
    // back to the last boundary before the maximum.
    await tester.tap(find.text('Section 13'));
    await tester.pumpAndSettle();
    expect(position.pixels, moreOrLessEquals(position.maxScrollExtent));
  });
}
