import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('shows the placeholder while empty, hides it once typed',
      (tester) async {
    await tester.pumpWidget(_host(const Input(placeholder: 'Username')));

    expect(find.text('Username'), findsOneWidget);

    await tester.enterText(find.byType(Input), 'ann');
    await tester.pump();
    expect(find.text('Username'), findsNothing);
  });

  testWidgets('reports edits through onChanged', (tester) async {
    String? seen;
    await tester.pumpWidget(_host(Input(onChanged: (v) => seen = v)));

    await tester.enterText(find.byType(Input), 'hello');
    expect(seen, 'hello');
  });

  testWidgets('a controller reads and drives the value', (tester) async {
    final controller = TextEditingController(text: 'start');
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(Input(controller: controller)));

    expect(find.text('start'), findsOneWidget);

    await tester.enterText(find.byType(Input), 'edited');
    expect(controller.text, 'edited');
  });

  testWidgets('disabled blocks editing', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester
        .pumpWidget(_host(Input(controller: controller, disabled: true)));

    await tester.enterText(find.byType(Input), 'nope');
    expect(controller.text, isEmpty);
  });

  testWidgets('allowClear empties the field when tapped', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester
        .pumpWidget(_host(Input(controller: controller, allowClear: true)));

    // The clear button only shows while focused and non-empty.
    await tester.tap(find.byType(Input));
    await tester.enterText(find.byType(Input), 'clear me');
    await tester.pump();

    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == 'ClearIconPainter',
      ),
    );
    await tester.pump();
    expect(controller.text, isEmpty);
  });

  testWidgets('obscureText masks the value and toggles with the reveal button',
      (tester) async {
    await tester.pumpWidget(_host(const Input(password: PasswordConfig())));
    await tester.enterText(find.byType(Input), 'secret');
    await tester.pump();

    bool masked() =>
        tester.widget<EditableText>(find.byType(EditableText)).obscureText;
    expect(masked(), isTrue);

    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_EyePainter',
      ),
    );
    await tester.pump();
    expect(masked(), isFalse);
  });

  testWidgets('maxLength caps the input', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(Input(controller: controller, maxLength: 3)));

    await tester.enterText(find.byType(Input), 'abcdef');
    expect(controller.text, 'abc');
  });
}
