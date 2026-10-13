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
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child, {bool still = false}) => ConfigProvider(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: still),
          child: Scaffold(
            body: Align(alignment: Alignment.topLeft, child: child),
          ),
        ),
      ),
    );

EditableText _field(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

/// What each cell shows, empty cells as ''.
List<String> _cells(WidgetTester tester, int length) {
  final texts = tester
      .widgetList<Text>(
        find.descendant(of: find.byType(InputOtp), matching: find.byType(Text)),
      )
      .map((t) => t.data!)
      .toList();
  return [...texts, ...List.filled(length - texts.length, '')];
}

/// Types [text] where the field's cursor stands, the way a keyboard does.
Future<void> _type(WidgetTester tester, String text) async {
  final value = _field(tester).controller.value;
  final s = value.selection;
  final next = value.text.replaceRange(s.start, s.end, text);
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: s.start + text.length),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('one character to a cell, and a word when all are filled', (
    tester,
  ) async {
    final changed = <String>[];
    final done = <String>[];
    await tester.pumpWidget(
      _host(
        InputOtp(length: 4, onChanged: changed.add, onCompleted: done.add),
      ),
    );
    await tester.tap(find.byType(InputOtp));
    await tester.pump();
    for (final d in ['1', '2', '3', '4']) {
      await _type(tester, d);
    }
    expect(_cells(tester, 4), ['1', '2', '3', '4']);
    expect(changed, ['1', '12', '123', '1234']);
    expect(done, ['1234']);
  });

  testWidgets('a code pasted at once fills every cell, cleaned and cut', (
    tester,
  ) async {
    final done = <String>[];
    await tester.pumpWidget(_host(InputOtp(onCompleted: done.add)));
    await tester.tap(find.byType(InputOtp));
    await tester.pump();
    await _type(tester, '12-34 56789');
    expect(_cells(tester, 6), ['1', '2', '3', '4', '5', '6']);
    expect(done, ['123456']);
  });

  testWidgets('digits only, unless told otherwise', (tester) async {
    await tester.pumpWidget(_host(const InputOtp(length: 4)));
    await tester.tap(find.byType(InputOtp));
    await tester.pump();
    await _type(tester, 'a1b2');
    expect(_cells(tester, 4), ['1', '2', '', '']);

    await tester.pumpWidget(
      _host(
        const InputOtp(
          key: ValueKey('alnum'),
          length: 4,
          characters: InputOtpCharacters.alphanumeric,
        ),
      ),
    );
    await tester.tap(find.byType(InputOtp));
    await tester.pump();
    await _type(tester, 'a1-B');
    expect(_cells(tester, 4), ['a', '1', 'B', '']);
  });

  testWidgets('a tap on a cell puts the cursor there, and typing replaces', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const InputOtp(defaultValue: '123456')));
    final third = find.descendant(
      of: find.byType(InputOtp),
      matching: find.text('3'),
    );
    await tester.tap(third);
    await tester.pump();
    await _type(tester, '9');
    expect(_cells(tester, 6), ['1', '2', '9', '4', '5', '6']);
    await _type(tester, '8');
    expect(
      _cells(tester, 6),
      ['1', '2', '9', '8', '5', '6'],
      reason: 'the cursor moves on to the next and replaces it too, '
          'rather than pushing the rest along',
    );
  });

  testWidgets('a tap between two cells lands after the last character', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const InputOtp(length: 4, defaultValue: '12')),
    );
    // The middle of four cells is the gap between the second and the third.
    await tester.tap(find.byType(InputOtp));
    await tester.pump();
    expect(_field(tester).focusNode.hasFocus, isTrue);
    await _type(tester, '3');
    expect(_cells(tester, 4), ['1', '2', '3', '']);
  });

  testWidgets('Backspace walks back', (tester) async {
    await tester.pumpWidget(_host(const InputOtp(length: 4)));
    await tester.tap(find.byType(InputOtp));
    await tester.pump();
    await _type(tester, '12');
    final value = _field(tester).controller.value;
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: value.text.substring(0, value.text.length - 1),
        selection: const TextSelection.collapsed(offset: 1),
      ),
    );
    await tester.pump();
    expect(_cells(tester, 4), ['1', '', '', '']);
  });

  testWidgets('value holds the code from outside', (tester) async {
    Widget otp(String v) => _host(InputOtp(length: 4, value: v));
    await tester.pumpWidget(otp('12'));
    expect(_cells(tester, 4), ['1', '2', '', '']);
    await tester.pumpWidget(otp('5678'));
    expect(_cells(tester, 4), ['5', '6', '7', '8']);
  });

  testWidgets('mask hides the characters from the eye and from a reader', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const InputOtp(length: 4, defaultValue: '12', mask: '•')),
    );
    expect(_cells(tester, 4), ['•', '•', '', '']);
    expect(_field(tester).obscureText, isTrue);
  });

  testWidgets('a separator stands between the cells it is asked for', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        InputOtp(separator: (i) => i == 2 ? const Text('-') : null),
      ),
    );
    final dash = tester.getCenter(find.text('-')).dx;
    final boxes = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(InputOtp),
            matching: find.byType(Container),
          ),
        )
        .where((c) => c.decoration != null)
        .map((c) => tester.getRect(find.byWidget(c)))
        .toList();
    expect(boxes, hasLength(6));
    expect(dash, greaterThan(boxes[2].right));
    expect(dash, lessThan(boxes[3].left));
    final style = DefaultTextStyle.of(tester.element(find.text('-'))).style;
    expect(style.decoration, TextDecoration.none,
        reason: 'dressed as the field, not as the page around it');
    expect(style.fontSize, 16);
  });

  testWidgets('disabled, it takes nothing', (tester) async {
    final changed = <String>[];
    await tester.pumpWidget(
      _host(InputOtp(length: 4, disabled: true, onChanged: changed.add)),
    );
    await tester.tap(find.byType(InputOtp));
    await tester.pump();
    expect(_field(tester).focusNode.hasFocus, isFalse);
    expect(_field(tester).readOnly, isTrue);
  });

  testWidgets('cells as tall as a control, and as wide', (tester) async {
    for (final (size, side) in [
      (SoftSize.small, 24.0),
      (SoftSize.middle, 32.0),
      (SoftSize.large, 40.0),
    ]) {
      await tester.pumpWidget(_host(InputOtp(length: 1, size: size)));
      final box = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(InputOtp),
              matching: find.byType(Container),
            ),
          )
          .firstWhere((c) => c.decoration != null);
      expect(tester.getSize(find.byWidget(box)), Size(side, side));
    }
  });

  testWidgets('the platform is asked for a keypad and the code from a message',
      (tester) async {
    await tester.pumpWidget(_host(const InputOtp()));
    await tester.tap(find.byType(InputOtp));
    await tester.pump();
    final config = tester.testTextInput.setClientArgs!;
    expect((config['inputType'] as Map)['name'], 'TextInputType.number');
    expect(
      (config['autofill'] as Map)['hints'],
      [AutofillHints.oneTimeCode],
    );
  });

  testWidgets('a reader meets one field, named', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const InputOtp(semanticsLabel: 'Verification code')),
    );
    expect(find.bySemanticsLabel('Verification code'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the caret blinks while focused, and not where motion is off', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const InputOtp()));
    await tester.tap(find.byType(InputOtp));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await tester.pumpWidget(
      _host(const InputOtp(key: ValueKey('still')), still: true),
    );
    await tester.tap(find.byType(InputOtp));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
  });
}
