import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  _selectionTests();
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

  group('size takes a preset or a measurement', () {
    Future<Rect> boxAt(WidgetTester tester, ControlSize size) async {
      await tester.pumpWidget(
        ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 260,
                  child: Input(size: size, placeholder: 'Ag'),
                ),
              ),
            ),
          ),
        ),
      );
      // The height rides an AnimatedContainer, so settle before measuring.
      await tester.pumpAndSettle();
      return tester.getRect(find.byType(Input));
    }

    testWidgets('a preset still walks the theme scale', (tester) async {
      expect((await boxAt(tester, SoftSize.small)).height, 24);
      expect((await boxAt(tester, SoftSize.middle)).height, 32);
      expect((await boxAt(tester, SoftSize.large)).height, 40);
    });

    testWidgets('a measurement is taken as given', (tester) async {
      expect((await boxAt(tester, const ControlSize.height(36))).height, 36);
      // Past both ends of the preset scale, too.
      expect((await boxAt(tester, const ControlSize.height(56))).height, 56);
      expect((await boxAt(tester, const ControlSize.height(20))).height, 20);
    });

    testWidgets('a width names the width, the height staying standard',
        (tester) async {
      await tester.pumpWidget(
        const ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Wrap(
                  children: [Input(size: ControlSize.width(180))],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final size = tester.getSize(find.byType(Input));
      expect(size.width, 180);
      // One number was spent on the width, so the height keeps the middle
      // preset rather than becoming 180 tall.
      expect(size.height, (await boxAt(tester, SoftSize.middle)).height);
    });

    testWidgets('a two-dimensional size names the width too', (tester) async {
      // Both ways out of the build have to honour it: a plain field returns
      // before the search-button Row, and an earlier attempt missed that exit
      // entirely, so raw() looked like it did nothing.
      await tester.pumpWidget(
        const ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Wrap(
                  children: [Input(size: ControlSize.box(180, 36))],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final size = tester.getSize(find.byType(Input));
      expect(size.width, 180);
      expect(size.height, 36);
    });

    testWidgets('the search field honours it as well', (tester) async {
      // The other exit — the one with the button attached.
      await tester.pumpWidget(
        ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Wrap(
                  children: [
                    Input(
                      size: const ControlSize.box(220, 36),
                      search: SearchConfig(enterButton: true, onSearch: (_) {}),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(Input)).width, 220);
    });

    testWidgets('a bare height says nothing about width', (tester) async {
      // fixed() names one dimension; the field goes on filling what it is
      // offered, as a text field with nothing to measure should.
      await tester.pumpWidget(
        const ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Input(size: ControlSize.height(20))],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final size = tester.getSize(find.byType(Input));
      expect(size.height, 20);
      expect(size.width, 800);
    });
    testWidgets('the text stays centred at any height', (tester) async {
      // The padding is not what holds the height up — the box is — so an
      // unusual height neither pushes the text off centre nor overflows.
      for (final h in [20.0, 36.0, 56.0]) {
        final box = await boxAt(tester, ControlSize.height(h));
        final text = tester.getRect(find.text('Ag'));
        expect(
          text.top - box.top,
          closeTo(box.bottom - text.bottom, 0.5),
          reason: 'off centre at $h',
        );
        expect(tester.takeException(), isNull, reason: 'overflowed at $h');
      }
    });
  });
}

void _selectionTests() {
  group('the text can be selected', () {
    testWidgets('dragging across the words selects them', (tester) async {
      await tester.pumpWidget(_host(const Input(value: 'hunter22 secret')));
      await tester.pumpAndSettle();

      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      final box = tester.getRect(find.byType(EditableText));

      // Drag from just inside the leading edge to the middle.
      // A mouse: on a touch platform a drag scrolls the field, and it is a
      // long press that starts a selection. This is the pointer somebody
      // copying a password is holding.
      final drag = await tester.startGesture(
        Offset(box.left + 4, box.center.dy),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await drag.moveTo(Offset(box.center.dx, box.center.dy));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      final selection = editable.textEditingValue.selection;
      // A field that only takes focus leaves the caret where it is: the text
      // can be read and never copied.
      expect(selection.isCollapsed, isFalse);
      expect(selection.start, 0);
    });

    testWidgets('a revealed password selects like any other field',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const Input(value: 'hunter22', password: PasswordConfig()),
        ),
      );
      await tester.pumpAndSettle();

      // The eye, which is the only thing to tap besides the field itself.
      await tester.tap(find.byType(CustomPaint).last);
      await tester.pumpAndSettle();

      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editable.widget.obscureText, isFalse);

      final box = tester.getRect(find.byType(EditableText));
      // A mouse: on a touch platform a drag scrolls the field, and it is a
      // long press that starts a selection. This is the pointer somebody
      // copying a password is holding.
      final drag = await tester.startGesture(
        Offset(box.left + 4, box.center.dy),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await drag.moveTo(Offset(box.right - 4, box.center.dy));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(editable.textEditingValue.selection.isCollapsed, isFalse);
    });

    testWidgets('a tap still puts the caret in and takes focus',
        (tester) async {
      await tester.pumpWidget(_host(const Input(value: 'hunter22')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editable.widget.focusNode.hasFocus, isTrue);
    });
  });

  group('asking for the keyboard again', () {
    // Putting the keyboard away with the phone's back button hides it without
    // taking the field's focus: the framework still believes there is an
    // editing session, so tapping the field again raises no focus change and
    // nothing opens one. Somebody has to ask, and on a field that allows
    // selection the framework's own gestures ask only in some versions.

    testWidgets('a tap on a field that already has focus asks again', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const Input(placeholder: 'Name')));

      await tester.tap(find.byType(Input));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isTrue, reason: 'the first tap');

      // The keyboard goes away without the connection closing, which is what
      // the back button does.
      tester.testTextInput.hide();
      expect(tester.testTextInput.isVisible, isFalse);

      await tester.tap(find.byType(Input));
      await tester.pumpAndSettle();
      expect(
        tester.testTextInput.isVisible,
        isTrue,
        reason: 'the second tap has to ask for the keyboard again',
      );
    });

    testWidgets('and so does a tap from assistive technology', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_host(const Input(placeholder: 'Name')));

      await tester.tap(find.byType(Input));
      await tester.pumpAndSettle();
      tester.testTextInput.hide();

      tester.semantics.performAction(
        find.semantics.byLabel('Name'),
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isTrue);
      semantics.dispose();
    });

    testWidgets('a barred field is not asked to open one', (tester) async {
      await tester.pumpWidget(
        _host(const Input(placeholder: 'Name', disabled: true)),
      );
      await tester.tap(find.byType(Input), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
    });
  });

  group('the colours it is dressed in', () {
    // Five of InputToken's fields were declared, documented, resolved — and
    // never read: the border at rest, under the pointer and focused, the ink,
    // and the placeholder's grey. A border colour that could be named and
    // never took is why "how do I make the border transparent" had no answer.

    BoxDecoration boxOf(WidgetTester tester) => tester
        .widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(Input),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .map((b) => b.decoration! as BoxDecoration)
        .first;

    Color borderOf(WidgetTester tester) =>
        (boxOf(tester).border! as Border).top.color;

    testWidgets('the border takes the colour it was given, in each state', (
      tester,
    ) async {
      const rest = Color(0xFF8B5CF6);
      const hover = Color(0xFFA78BFA);
      const active = Color(0xFF6D28D9);
      await tester.pumpWidget(
        _host(
          const Input(
            placeholder: 'Name',
            token: InputToken(
              colorBorder: rest,
              hoverBorderColor: hover,
              activeBorderColor: active,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(borderOf(tester), rest);

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.byType(Input))),
      );
      await tester.pumpAndSettle();
      expect(borderOf(tester), hover);

      await tester.tap(find.byType(Input));
      await tester.pumpAndSettle();
      expect(borderOf(tester), active);
    });

    testWidgets('a transparent border and ring leave no chrome at all', (
      tester,
    ) async {
      const clear = Color(0x00000000);
      await tester.pumpWidget(
        _host(
          const Input(
            placeholder: 'Name',
            token: InputToken(
              colorBorder: clear,
              hoverBorderColor: clear,
              activeBorderColor: clear,
              focusRing: clear,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(Input));
      await tester.pumpAndSettle();

      expect(borderOf(tester), clear);
      expect(
        boxOf(tester).boxShadow?.single.color,
        clear,
        reason: 'a transparent border still glowed without focusRing',
      );
    });

    testWidgets('the halo follows the border it was given', (tester) async {
      const active = Color(0xFF6D28D9);
      await tester.pumpWidget(
        _host(
          const Input(
            placeholder: 'Name',
            token: InputToken(activeBorderColor: active),
          ),
        ),
      );
      await tester.tap(find.byType(Input));
      await tester.pumpAndSettle();
      expect(
        boxOf(tester).boxShadow?.single.color,
        active.withValues(alpha: 0.12),
      );
    });

    testWidgets('the ink and the placeholder take theirs', (tester) async {
      const ink = Color(0xFFF9FAFB);
      const grey = Color(0xFF9CA3AF);
      await tester.pumpWidget(
        _host(
          const Input(
            placeholder: 'Name',
            token: InputToken(colorText: ink, colorTextPlaceholder: grey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.text('Name')).style?.color,
        grey,
        reason: 'the placeholder',
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).style.color,
        ink,
        reason: 'the words typed into it',
      );
    });
  });
}
