import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('tapping toggles and reports the new value', (tester) async {
    bool? seen;
    await tester.pumpWidget(
      _host(
        Switch(value: false, onChanged: (v) => seen = v),
      ),
    );

    await tester.tap(find.byType(Switch));
    expect(seen, isTrue);
  });

  testWidgets('reports false when toggled off', (tester) async {
    bool? seen;
    await tester.pumpWidget(
      _host(
        Switch(value: true, onChanged: (v) => seen = v),
      ),
    );

    await tester.tap(find.byType(Switch));
    expect(seen, isFalse);
  });

  testWidgets('disabled does not toggle', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(
        Switch(value: false, disabled: true, onChanged: (_) => calls++),
      ),
    );

    await tester.tap(find.byType(Switch));
    expect(calls, 0);
  });

  testWidgets('loading blocks toggling and shows a spinner', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(
        Switch(value: false, loading: true, onChanged: (_) => calls++),
      ),
    );

    expect(find.byType(Spinner), findsOneWidget);
    await tester.tap(find.byType(Switch));
    expect(calls, 0);
  });

  testWidgets('a controlled switch with no listener is inert', (tester) async {
    // The test this replaces asserted nothing at all — it tapped and let the
    // absence of a crash stand for the behaviour.
    await tester.pumpWidget(_host(const Switch(value: true)));
    final before = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byType(Switch),
            matching: find.byType(AnimatedContainer),
          )
          .at(0),
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    final after = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byType(Switch),
            matching: find.byType(AnimatedContainer),
          )
          .at(0),
    );
    expect(
      (after.decoration! as BoxDecoration).color,
      (before.decoration! as BoxDecoration).color,
      reason: 'nothing can change the value, so the track keeps its colour',
    );
  });

  group('a switch that drives itself', () {
    Color trackColor(WidgetTester tester) => (tester
            .widget<AnimatedContainer>(
              find
                  .descendant(
                    of: find.byType(Switch),
                    matching: find.byType(AnimatedContainer),
                  )
                  .at(0),
            )
            .decoration! as BoxDecoration)
        .color!;

    testWidgets('starts where defaultValue says and flips on its own', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const Switch(defaultValue: true)));
      await tester.pumpAndSettle();
      final on = trackColor(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(trackColor(tester), isNot(on), reason: 'it flipped itself off');

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(trackColor(tester), on, reason: 'and back on again');
    });

    testWidgets('still reports every flip', (tester) async {
      final seen = <bool>[];
      await tester.pumpWidget(
        _host(Switch(defaultValue: false, onChanged: seen.add)),
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(seen, [true, false]);
    });

    testWidgets('an owner that refuses is shown refusing', (tester) async {
      // Controlled and held at false: the switch must not flip itself on
      // behind the owner's back.
      await tester.pumpWidget(
        _host(Switch(value: false, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      final off = trackColor(tester);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(trackColor(tester), off);
    });
  });

  testWidgets('renders checked and unchecked labels', (tester) async {
    await tester.pumpWidget(
      _host(
        Switch(
          value: true,
          onChanged: (_) {},
          checkedChild: const Text('ON'),
          uncheckedChild: const Text('OFF'),
        ),
      ),
    );

    expect(find.text('ON'), findsOneWidget);
  });

  group('a switch of any height is the same switch', () {
    // The presets used to be six separate numbers that were not in
    // proportion: the small track was 1.75 of its own heights long where the
    // standard one was 2, so the two were not one switch at two sizes. Now
    // the height is the only number, and the rest follows from it.

    Future<(Size track, Size handle)> parts(
      WidgetTester tester,
      ControlSize size,
    ) async {
      await tester.pumpWidget(
        _host(Switch(value: false, size: size, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      // The track is the outermost box the switch draws; the handle is the
      // white one inside it, so they come in that order.
      final boxes = find.descendant(
        of: find.byType(Switch),
        matching: find.byType(AnimatedContainer),
      );
      expect(boxes, findsNWidgets(2), reason: 'a track and a handle');
      return (tester.getSize(boxes.at(0)), tester.getSize(boxes.at(1)));
    }

    testWidgets('the presets keep the proportions the design started with', (
      tester,
    ) async {
      for (final (size, height) in const [
        (SoftSize.small, 16.0),
        (SoftSize.middle, 22.0),
        (SoftSize.large, 28.0),
      ]) {
        final (track, handle) = await parts(tester, size);
        expect(track.height, moreOrLessEquals(height, epsilon: 0.01),
            reason: '$size is $height tall');
        expect(track.width, moreOrLessEquals(height * 2, epsilon: 0.01),
            reason: '$size is twice as long as it is tall');
        expect(handle.height, moreOrLessEquals(height * 9 / 11, epsilon: 0.01),
            reason: '$size leaves an eleventh at each end');
      }
    });

    testWidgets('a height of your own is in the same proportion', (
      tester,
    ) async {
      final (track, handle) = await parts(tester, const ControlSize.height(44));
      expect(track.height, moreOrLessEquals(44, epsilon: 0.01));
      expect(track.width, moreOrLessEquals(88, epsilon: 0.01));
      expect(handle.height, moreOrLessEquals(44 * 9 / 11, epsilon: 0.01));
    });

    testWidgets('a width of your own is kept, whatever the height says', (
      tester,
    ) async {
      final (track, _) = await parts(tester, const ControlSize.box(70, 22));
      expect(track.width, moreOrLessEquals(70, epsilon: 0.01));
      expect(track.height, moreOrLessEquals(22, epsilon: 0.01));
    });

    testWidgets('the size set for the subtree reaches it', (tester) async {
      await tester.pumpWidget(
        ConfigProvider(
          componentSize: SoftSize.large,
          child: _host(Switch(value: false, onChanged: (_) {})),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(Switch)).height,
        moreOrLessEquals(28, epsilon: 0.01),
      );
    });

    testWidgets('a token still overrides what was worked out', (tester) async {
      await tester.pumpWidget(
        _host(
          Switch(
            value: false,
            token: const SwitchToken(trackMinWidth: 80),
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(Switch)).width,
        moreOrLessEquals(80, epsilon: 0.01),
      );
    });
  });
}
