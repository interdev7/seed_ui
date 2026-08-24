import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// Anchors the boundary the illustration is captured from.
const _art = ValueKey('art');

Widget _host({
  SoftSize? componentSize,
  bool? componentDisabled,
  required Widget child,
}) =>
    ConfigProvider(
      componentSize: componentSize,
      componentDisabled: componentDisabled,
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

Future<double> _buttonHeight(WidgetTester tester, Widget tree) async {
  await tester.pumpWidget(tree);
  await tester.pumpAndSettle();
  return tester.getRect(find.byType(Button)).height;
}

void main() {
  group('componentSize', () {
    testWidgets('sets the size for everything below it', (tester) async {
      final small = await _buttonHeight(
        tester,
        _host(
          componentSize: SoftSize.small,
          child: Button(onPressed: () {}, child: const Text('Pay')),
        ),
      );
      final large = await _buttonHeight(
        tester,
        _host(
          componentSize: SoftSize.large,
          child: Button(onPressed: () {}, child: const Text('Pay')),
        ),
      );
      final unset = await _buttonHeight(
        tester,
        _host(child: Button(onPressed: () {}, child: const Text('Pay'))),
      );

      expect(small, lessThan(unset));
      expect(large, greaterThan(unset));
    });

    testWidgets('what a widget states for itself still wins', (tester) async {
      final height = await _buttonHeight(
        tester,
        _host(
          componentSize: SoftSize.small,
          child: Button(
            size: SoftSize.large,
            onPressed: () {},
            child: const Text('Pay'),
          ),
        ),
      );
      final large = await _buttonHeight(
        tester,
        _host(
          child: Button(
            size: SoftSize.large,
            onPressed: () {},
            child: const Text('Pay'),
          ),
        ),
      );
      expect(height, large);
    });

    testWidgets('carries through a provider silent about it', (tester) async {
      final nested = await _buttonHeight(
        tester,
        ConfigProvider(
          componentSize: SoftSize.large,
          child: MaterialApp(
            home: ConfigProvider(
              theme: ThemeData(),
              child: Scaffold(
                body: Center(
                  child: Button(onPressed: () {}, child: const Text('Pay')),
                ),
              ),
            ),
          ),
        ),
      );
      final direct = await _buttonHeight(
        tester,
        _host(
          componentSize: SoftSize.large,
          child: Button(onPressed: () {}, child: const Text('Pay')),
        ),
      );
      final unset = await _buttonHeight(
        tester,
        _host(child: Button(onPressed: () {}, child: const Text('Pay'))),
      );
      expect(nested, direct);
      expect(
        nested,
        isNot(unset),
        reason: 'equal to the direct case is no proof if neither took effect',
      );
    });

    testWidgets('an enclosing AvatarGroup is nearer than the screen',
        (tester) async {
      await tester.pumpWidget(
        _host(
          componentSize: SoftSize.small,
          child: const AvatarGroup(
            size: SoftSize.large,
            children: [Avatar(child: Text('A'))],
          ),
        ),
      );
      final grouped = tester.getRect(find.byType(Avatar)).height;

      await tester.pumpWidget(
        _host(
          componentSize: SoftSize.small,
          child: const Avatar(child: Text('A')),
        ),
      );
      final loose = tester.getRect(find.byType(Avatar)).height;

      // Both halves must be doing something: the loose avatar shrank to the
      // screen's size, the grouped one held the group's.
      await tester.pumpWidget(
        _host(child: const Avatar(child: Text('A'))),
      );
      final unset = tester.getRect(find.byType(Avatar)).height;

      expect(loose, lessThan(unset), reason: 'the screen reached it');
      expect(grouped, greaterThan(unset), reason: 'the group outranked it');
    });
  });

  group('componentDisabled', () {
    testWidgets('turns off the controls below it', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          componentDisabled: true,
          child: Button(onPressed: () => taps++, child: const Text('Pay')),
        ),
      );
      await tester.tap(find.byType(Button));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('a control can stay live in a disabled subtree',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          componentDisabled: true,
          child: Button(
            disabled: false,
            onPressed: () => taps++,
            child: const Text('Pay'),
          ),
        ),
      );
      await tester.tap(find.byType(Button));
      await tester.pump();
      expect(taps, 1, reason: 'its own word wins over the screen');
    });

    testWidgets('reaches a switch and a checkbox too', (tester) async {
      var switched = false;
      var checked = false;
      await tester.pumpWidget(
        _host(
          componentDisabled: true,
          child: Column(
            children: [
              Switch(value: false, onChanged: (_) => switched = true),
              Checkbox(checked: false, onChanged: (_) => checked = true),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(Switch));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(switched, isFalse);
      expect(checked, isFalse);
    });

    testWidgets('carries through a provider silent about it', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        ConfigProvider(
          componentDisabled: true,
          child: MaterialApp(
            home: ConfigProvider(
              theme: ThemeData(),
              child: Scaffold(
                body: Center(
                  child: Button(
                    onPressed: () => taps++,
                    child: const Text('Pay'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(Button));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('a per-item flag is not the screen speaking', (tester) async {
      // CheckboxOption.disabled is about that option; nothing here should make
      // the group's own options change their mind.
      await tester.pumpWidget(
        _host(
          child: CheckboxGroup(
            value: const [],
            onChanged: (_) {},
            options: const [
              CheckboxOption(value: 'a', label: Text('Apple')),
              CheckboxOption(value: 'b', label: Text('Pear'), disabled: true),
            ],
          ),
        ),
      );
      final off = tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .where((c) => c.disabled ?? false);
      expect(off.length, 1);
    });
  });
  group('ComponentDefaults', () {
    Widget host(ComponentDefaults? defaults, Widget child) => ConfigProvider(
          defaults: defaults,
          child: MaterialApp(home: Scaffold(body: Center(child: child))),
        );

    testWidgets('a default reaches every widget that did not say', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const ComponentDefaults(
            tag: TagDefaults(closable: true),
          ),
          const Tag(child: Text('beta')),
        ),
      );
      // closable adds the close button; nothing else would.
      expect(find.byType(Tag), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Tag),
          matching: find.byType(GestureDetector),
        ),
        findsWidgets,
        reason: 'a closable tag carries something to tap',
      );
    });

    testWidgets("a widget's own prop wins over the default", (tester) async {
      // The two illustrations differ only in what is painted, so the pixels
      // are the only honest witness.
      Future<Uint8List> paint(ComponentDefaults? defaults, Widget empty) async {
        await tester.pumpWidget(
          host(defaults, RepaintBoundary(key: _art, child: empty)),
        );
        await tester.pumpAndSettle();
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(_art),
        );
        // Encoding is real async work, so it has to run outside the fake
        // clock or the future never completes.
        return (await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ImageByteFormat.png);
          return data!.buffer.asUint8List();
        }))!;
      }

      const simpleEverywhere = ComponentDefaults(
        empty: EmptyDefaults(image: EmptyImage.simple),
      );

      final plain = await paint(null, const Empty());
      final defaulted = await paint(simpleEverywhere, const Empty());
      final overridden = await paint(
        simpleEverywhere,
        const Empty(image: EmptyImage.standard),
      );

      expect(defaulted, isNot(plain),
          reason: 'the default changed the drawing');
      expect(
        overridden,
        plain,
        reason: 'the widget asked for the standard one and got it',
      );
    });

    testWidgets('an Input takes allowClear from the subtree', (tester) async {
      // The clear button is a painted glyph of its own, so it shows up as one
      // more CustomPaint inside the field.
      Future<int> paints(ComponentDefaults? defaults, Widget input) async {
        await tester.pumpWidget(
          host(defaults, SizedBox(width: 300, child: input)),
        );
        await tester.enterText(find.byType(EditableText), 'typed');
        await tester.pumpAndSettle();
        return find
            .descendant(
              of: find.byType(Input),
              matching: find.byType(CustomPaint),
            )
            .evaluate()
            .length;
      }

      const clearing = ComponentDefaults(
        input: InputDefaults(allowClear: true),
      );

      final base = await paints(null, const Input());
      final defaulted = await paints(clearing, const Input());
      final refused = await paints(clearing, const Input(allowClear: false));

      expect(defaulted, greaterThan(base), reason: 'the subtree added it');
      expect(refused, base, reason: 'the input said no');
    });

    // The stateless widgets were the ones that broke silently: a prop turned
    // nullable still compiles in `prop == Something`, and simply reads false
    // ever after. These check the reading, not the type.
    testWidgets('a stateless widget reads its default, not a stale null',
        (tester) async {
      Future<Axis> axisOf(ComponentDefaults? defaults) async {
        await tester.pumpWidget(
          host(
            defaults,
            SizedBox(
              height: 300,
              width: 300,
              child: SortableList(
                onReorder: (_, __) {},
                children: const [
                  SizedBox(key: ValueKey('a'), height: 40, child: Text('a')),
                  SizedBox(key: ValueKey('b'), height: 40, child: Text('b')),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester
            .widget<CustomScrollView>(find.byType(CustomScrollView))
            .scrollDirection;
      }

      expect(await axisOf(null), Axis.vertical, reason: 'the kit default');
      expect(
        await axisOf(
          const ComponentDefaults(
            sortableList: SortableListDefaults(direction: Axis.horizontal),
          ),
        ),
        Axis.horizontal,
      );
    });

    testWidgets('a Timeline takes its mode from the subtree', (tester) async {
      Future<Offset> firstTitle(ComponentDefaults? defaults) async {
        await tester.pumpWidget(
          host(
            defaults,
            const SizedBox(
              width: 400,
              child: Timeline(
                items: [
                  TimelineItem(title: Text('one')),
                  TimelineItem(title: Text('two')),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getTopLeft(find.text('one'));
      }

      final left = await firstTitle(null);
      final right = await firstTitle(
        const ComponentDefaults(
          timeline: TimelineDefaults(mode: TimelineMode.right),
        ),
      );
      expect(
        right.dx,
        isNot(left.dx),
        reason: 'the entries changed sides',
      );
    });

    testWidgets('every registered slot answers its own lookup', (tester) async {
      // A slot that is stored but never returned by of<T>() would leave a
      // component silently on the kit's default.
      late bool ok;
      await tester.pumpWidget(
        host(
          const ComponentDefaults(
            avatar: AvatarDefaults(shape: AvatarShape.square),
            ribbon: RibbonDefaults(placement: RibbonPlacement.start),
            upload: UploadDefaults(showSize: false),
            tabs: TabsDefaults(hideAdd: true),
            steps: StepsDefaults(responsive: false),
          ),
          Builder(
            builder: (context) {
              ok = ConfigProvider.defaultsOf<AvatarDefaults>(context)?.shape ==
                      AvatarShape.square &&
                  ConfigProvider.defaultsOf<RibbonDefaults>(context)
                          ?.placement ==
                      RibbonPlacement.start &&
                  ConfigProvider.defaultsOf<UploadDefaults>(context)
                          ?.showSize ==
                      false &&
                  ConfigProvider.defaultsOf<TabsDefaults>(context)?.hideAdd ==
                      true &&
                  ConfigProvider.defaultsOf<StepsDefaults>(context)
                          ?.responsive ==
                      false;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(ok, isTrue);
    });

    testWidgets('defaults merge slot by slot through nested providers',
        (tester) async {
      late ButtonDefaults? button;
      late TagDefaults? tag;
      await tester.pumpWidget(
        ConfigProvider(
          defaults: const ComponentDefaults(
            button: ButtonDefaults(shape: ButtonShape.round),
          ),
          child: MaterialApp(
            home: ConfigProvider(
              defaults: const ComponentDefaults(
                tag: TagDefaults(closable: true),
              ),
              child: Builder(
                builder: (context) {
                  button = ConfigProvider.defaultsOf<ButtonDefaults>(context);
                  tag = ConfigProvider.defaultsOf<TagDefaults>(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(button?.shape, ButtonShape.round, reason: 'the outer one stands');
      expect(tag?.closable, isTrue);
    });

    testWidgets('the nearer provider wins where both name a component',
        (tester) async {
      late ButtonDefaults? seen;
      await tester.pumpWidget(
        ConfigProvider(
          defaults: const ComponentDefaults(
            button: ButtonDefaults(shape: ButtonShape.round),
          ),
          child: MaterialApp(
            home: ConfigProvider(
              defaults: const ComponentDefaults(
                button: ButtonDefaults(shape: ButtonShape.circle),
              ),
              child: Builder(
                builder: (context) {
                  seen = ConfigProvider.defaultsOf<ButtonDefaults>(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(seen?.shape, ButtonShape.circle);
    });
  });
}
