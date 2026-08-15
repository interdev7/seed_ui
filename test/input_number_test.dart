import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

Finder _carets() => find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == '_ChevronPainter',
    );

/// The spinner is hidden until the InputNumber is hovered.
Future<void> _hover(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getCenter(find.byType(InputNumber)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the stepper is clipped to the input\'s rounded corner',
      (tester) async {
    // The spinner sits flush against the right edge, so its hover and pressed
    // fills would otherwise square off the top-right and bottom-right corners
    // and paint outside the border.
    await tester.pumpWidget(
      _host(
        ConfigProvider(
          theme: ThemeData.light,
          child:
              const SizedBox(width: 200, child: InputNumber(defaultValue: 1)),
        ),
      ),
    );
    await _hover(tester);

    final clip = tester.widget<ClipRRect>(
      find.ancestor(of: _carets().first, matching: find.byType(ClipRRect)).last,
    );
    final radius = clip.borderRadius as BorderRadius;
    expect(radius.topRight.x, greaterThan(0));
    expect(radius.bottomRight.x, greaterThan(0));
    // Inside the border, so a touch tighter than the box's own corner.
    expect(radius.topRight.x, lessThan(ThemeData.light.token.borderRadius));
  });

  testWidgets('hovering a stepper lights the chevron, it does not wash the box',
      (tester) async {
    // A hover is answered on the chevron; the background is only washed
    // while the handle is pressed, and faintly.
    await tester.pumpWidget(
      _host(
        ConfigProvider(
          theme: ThemeData.light,
          child:
              const SizedBox(width: 200, child: InputNumber(defaultValue: 1)),
        ),
      ),
    );
    // One pointer for the whole test: the helper's would collide with a second.
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(InputNumber)));
    await tester.pumpAndSettle();

    Color chevronColour() =>
        (tester.widgetList<CustomPaint>(_carets()).first.painter as dynamic)
            .color as Color;
    // The button paints its background through `color:`, which Flutter turns
    // into a BoxDecoration — a transparent one means nothing is drawn.
    Color? boxColour() {
      final box = tester
          .widgetList<AnimatedContainer>(
            find.ancestor(
              of: _carets().first,
              matching: find.byType(AnimatedContainer),
            ),
          )
          .first
          .decoration;
      return box is BoxDecoration ? box.color : null;
    }

    final resting = chevronColour();

    await gesture.moveTo(tester.getCenter(_carets().first));
    await tester.pumpAndSettle();

    expect(
      chevronColour(),
      isNot(resting),
      reason: 'the chevron should pick up the accent',
    );
    expect(chevronColour(), ThemeData.light.token.primary.base);
    final fill = boxColour();
    expect(
      fill == null || fill.a == 0,
      isTrue,
      reason: 'no grey block behind it, got $fill',
    );
  });

  testWidgets('steppers add and remove the step', (tester) async {
    num? value = 3;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => InputNumber(
            value: value,
            step: 2,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await _hover(tester);

    final carets = _carets();
    expect(carets, findsNWidgets(2));

    await tester.tap(carets.at(0)); // up
    await tester.pump();
    expect(value, 5);

    await tester.tap(carets.at(1)); // down
    await tester.pump();
    expect(value, 3);
  });

  testWidgets('clamps to min and max', (tester) async {
    num? value = 9;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => InputNumber(
            value: value,
            min: 0,
            max: 10,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await _hover(tester);
    final up = _carets().at(0);
    await tester.tap(up);
    await tester.pump();
    expect(value, 10);
    await tester.tap(up); // already at max — stays
    await tester.pump();
    expect(value, 10);
  });

  testWidgets('typing a value commits on submit, clamped', (tester) async {
    num? value;
    await tester.pumpWidget(
      _host(
        InputNumber(min: 0, max: 100, onChanged: (v) => value = v),
      ),
    );
    await tester.enterText(find.byType(EditableText), '250');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(value, 100); // clamped
  });

  testWidgets('spinner mode puts a minus and a plus around the value',
      (tester) async {
    num? value = 3;
    await tester.pumpWidget(
      _host(
        ConfigProvider(
          theme: ThemeData.light,
          child: StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 200,
              child: InputNumber(
                mode: InputNumberMode.spinner,
                value: value,
                min: 1,
                max: 10,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      ),
    );

    // Two signs, one on each side of a centred value — no stacked handles.
    final signs = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == '_SignPainter',
    );
    expect(signs, findsNWidgets(2));
    expect(_carets(), findsNothing);

    final field = tester.getRect(find.byType(EditableText));
    final minus = tester.getRect(signs.first);
    final plus = tester.getRect(signs.last);
    expect(minus.center.dx, lessThan(field.center.dx));
    expect(plus.center.dx, greaterThan(field.center.dx));

    await tester.tap(signs.last);
    await tester.pump();
    expect(value, 4);

    await tester.tap(signs.first);
    await tester.pump();
    expect(value, 3);
  });

  testWidgets('no controls hides the steppers', (tester) async {
    await tester.pumpWidget(
      _host(
        const InputNumber(defaultValue: 1, controls: false),
      ),
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_ChevronPainter',
      ),
      findsNothing,
    );
  });

  testWidgets('a spinner keeps its own width in a stretching parent',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InputNumber(mode: InputNumberMode.spinner, defaultValue: 3),
              InputNumber(defaultValue: 3),
            ],
          ),
        ),
      ),
    );

    // The spinner is a stepper: as wide as its buttons and the number.
    final spinner = tester.getRect(find.byType(SizedBox).at(1));
    expect(spinner.width, lessThan(300), reason: 'got ${spinner.width}');

    // A plain number field is a text field, and still fills the width.
    expect(tester.getRect(find.byType(InputNumber).last).width, 600);
  });

  testWidgets('spinnerWidth widens it', (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InputNumber(
                mode: InputNumberMode.spinner,
                defaultValue: 3,
                token: InputNumberToken(spinnerWidth: 240),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester
          .getRect(
            find
                .descendant(
                  of: find.byType(InputNumber),
                  matching: find.byType(SizedBox),
                )
                .first,
          )
          .width,
      240,
    );
  });
}
