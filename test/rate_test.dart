import 'dart:ui' show SemanticsAction;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart'
    hide
        ThemeData,
        Checkbox,
        Radio,
        RadioGroup,
        Switch,
        Tooltip,
        Drawer,
        Divider;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    ConfigProvider(
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Align(alignment: Alignment.topLeft, child: child),
          ),
        ),
      ),
    );

/// How much of the stars is lit, star by star order not kept: the sum.
double _lit(WidgetTester tester) => tester
    .widgetList<Align>(
      find.descendant(of: find.byType(Rate), matching: find.byType(Align)),
    )
    .where((a) => a.widthFactor != null)
    .fold(0.0, (sum, a) => sum + a.widthFactor!);

/// The box of star [i], first star first.
Rect _star(WidgetTester tester, int i) {
  final boxes = tester
      .widgetList<SizedBox>(
        find.descendant(of: find.byType(Rate), matching: find.byType(SizedBox)),
      )
      .where((b) => b.width != null && b.width == b.height)
      .map((b) => tester.getRect(find.byWidget(b)))
      .toList()
    ..sort((a, b) => a.left.compareTo(b.left));
  // Each star draws its glyph twice when lit; one box per position.
  final seen = <double>{};
  return boxes.where((b) => seen.add(b.left)).toList()[i];
}

void main() {
  testWidgets('a tap gives that many stars', (tester) async {
    final told = <double>[];
    await tester.pumpWidget(_host(Rate(onChanged: told.add)));
    await tester.tapAt(_star(tester, 2).center);
    await tester.pump();
    expect(told, [3]);
    expect(_lit(tester), 3);
  });

  testWidgets('the rating given, tapped again, is taken back', (
    tester,
  ) async {
    final told = <double>[];
    await tester.pumpWidget(_host(Rate(defaultValue: 3, onChanged: told.add)));
    await tester.tapAt(_star(tester, 2).center);
    await tester.pump();
    expect(told, [0]);

    await tester.pumpWidget(
      _host(
        Rate(
          key: const ValueKey('kept'),
          defaultValue: 3,
          allowClear: false,
          onChanged: told.add,
        ),
      ),
    );
    await tester.tapAt(_star(tester, 2).center);
    await tester.pump();
    expect(told.last, 3);
  });

  testWidgets('allowHalf: the first half of a star gives half of it', (
    tester,
  ) async {
    final told = <double>[];
    await tester.pumpWidget(
      _host(Rate(allowHalf: true, onChanged: told.add)),
    );
    final second = _star(tester, 1);
    await tester.tapAt(second.centerLeft + const Offset(2, 0));
    await tester.pump();
    await tester.tapAt(second.centerRight - const Offset(2, 0));
    await tester.pump();
    expect(told, [1.5, 2]);
  });

  testWidgets('read the other way, the first half is the right one', (
    tester,
  ) async {
    final told = <double>[];
    await tester.pumpWidget(
      _host(
        Rate(allowHalf: true, onChanged: told.add),
        direction: TextDirection.rtl,
      ),
    );
    // The first star stands at the right in a right-to-left row.
    final first = _star(tester, 4);
    await tester.tapAt(first.centerRight - const Offset(2, 0));
    await tester.pump();
    expect(told, [0.5]);
  });

  testWidgets('the pointer shows what a tap would give, and takes it back', (
    tester,
  ) async {
    final hovered = <double?>[];
    await tester.pumpWidget(
      _host(Rate(defaultValue: 1, onHoverChanged: hovered.add)),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: _star(tester, 3).center);
    await tester.pumpAndSettle();
    expect(_lit(tester), 4);
    expect(hovered.last, 4);

    await mouse.moveTo(const Offset(700, 500));
    await tester.pumpAndSettle();
    expect(_lit(tester), 1);
    expect(hovered.last, isNull);
    await mouse.removePointer();
  });

  testWidgets('the keys move it a star, or half of one', (tester) async {
    final told = <double>[];
    await tester.pumpWidget(_host(Rate(defaultValue: 2, onChanged: told.add)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(told, [3, 2, 5, 0]);

    told.clear();
    await tester.pumpWidget(
      _host(
        Rate(
          key: const ValueKey('half'),
          allowHalf: true,
          defaultValue: 2,
          onChanged: told.add,
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(told, [2.5]);
  });

  testWidgets('disabled or read-only, it takes nothing', (tester) async {
    for (final rate in [
      (List<double> t) =>
          Rate(defaultValue: 2, disabled: true, onChanged: t.add),
      (List<double> t) =>
          Rate(defaultValue: 2, readOnly: true, onChanged: t.add),
    ]) {
      final told = <double>[];
      await tester.pumpWidget(_host(rate(told)));
      await tester.tapAt(_star(tester, 4).center);
      await tester.pump();
      expect(told, isEmpty);
      expect(_lit(tester), 2);
    }
  });

  testWidgets('value holds the rating from outside', (tester) async {
    await tester.pumpWidget(_host(const Rate(value: 2)));
    await tester.tapAt(_star(tester, 4).center);
    await tester.pump();
    expect(_lit(tester), 2, reason: 'held, it waits to be told');
    await tester.pumpWidget(_host(const Rate(value: 4)));
    expect(_lit(tester), 4);
  });

  testWidgets('a reader hears a slider, and can move it', (tester) async {
    final handle = tester.ensureSemantics();
    final told = <double>[];
    await tester.pumpWidget(
      _host(
          Rate(defaultValue: 3, semanticsLabel: 'Rating', onChanged: told.add)),
    );
    final node = tester.getSemantics(find.byType(Rate));
    expect(node.label, 'Rating');
    expect(node.value, '3 / 5');
    expect(node.increasedValue, '4 / 5');
    node.owner!.performAction(node.id, SemanticsAction.increase);
    await tester.pump();
    expect(told, [4]);
    handle.dispose();
  });

  testWidgets('a character of your own, coloured as a star', (tester) async {
    await tester.pumpWidget(
      _host(Rate(count: 3, defaultValue: 1, character: (i) => Text('$i'))),
    );
    expect(find.text('0'), findsNWidgets(2), reason: 'lit over unlit');
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('a word for each star under the pointer', (tester) async {
    await tester.pumpWidget(
      _host(const Rate(tooltips: ['bad', 'poor', 'fine', 'good', 'great'])),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: _star(tester, 3).center);
    await tester.pumpAndSettle();
    expect(find.text('good'), findsOneWidget);
    await mouse.removePointer();
    await tester.pumpAndSettle();
  });

  testWidgets('stars as big as the size says', (tester) async {
    for (final (size, side) in [
      (SoftSize.small, 16.0),
      (SoftSize.middle, 20.0),
      (SoftSize.large, 24.0),
    ]) {
      await tester.pumpWidget(_host(Rate(size: size)));
      expect(_star(tester, 0).size, Size(side, side));
    }
  });
}
