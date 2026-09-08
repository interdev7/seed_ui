import 'package:flutter/material.dart' hide ThemeData, Form, Switch;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => ConfigProvider(
      theme: ThemeData(),
      child: MaterialApp(
        home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
      ),
    );

/// Runs [body] with the semantics tree switched on.
///
/// The handle has to be let go before the test ends — a tearDown runs after
/// the check that would catch it, so it is done here by hand.
Future<void> reading(WidgetTester tester, Future<void> Function() body) async {
  final handle = tester.ensureSemantics();
  try {
    await body();
  } finally {
    handle.dispose();
  }
}

void main() {
  group('a text field', () {
    testWidgets('is a text field, and says what it is called', (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(
          _host(const Input(semanticsLabel: 'Email')),
        );
        final node = tester.getSemantics(find.byType(EditableText));
        expect(
          node.flagsCollection.isTextField,
          isTrue,
          reason: 'a screen reader is told what kind of thing this is',
        );
        expect(node.label, 'Email');
      });
    });

    testWidgets('a placeholder names a field that stands on its own',
        (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(_host(const Input(placeholder: 'Search')));
        expect(tester.getSemantics(find.byType(EditableText)).label, 'Search');
      });
    });

    testWidgets(
        'says it is in trouble, so the red border is not the only '
        'way the news arrives', (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(_host(const Input(semanticsLabel: 'Email')));
        expect(
          tester.getSemantics(find.byType(EditableText)).validationResult,
          SemanticsValidationResult.none,
        );

        await tester.pumpWidget(
          _host(
            const Input(semanticsLabel: 'Email', status: InputStatus.error),
          ),
        );
        expect(
          tester.getSemantics(find.byType(EditableText)).validationResult,
          SemanticsValidationResult.invalid,
        );
      });
    });

    testWidgets('a warning is not an error', (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(
          _host(const Input(status: InputStatus.warning)),
        );
        expect(
          tester.getSemantics(find.byType(EditableText)).validationResult,
          SemanticsValidationResult.none,
        );
      });
    });
  });

  group('a form field', () {
    Future<SemanticsNode> pump(
      WidgetTester tester,
      FormController form, {
      Widget label = const Text('Email'),
    }) async {
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            child: Column(
              children: [
                FormItem.text(
                  name: 'email',
                  label: label,
                  rules: const [FormRule.required()],
                ),
              ],
            ),
          ),
        ),
      );
      return tester.getSemantics(find.byType(EditableText));
    }

    testWidgets('takes its name from the label written beside it',
        (tester) async {
      await reading(tester, () async {
        final form = FormController();
        addTearDown(form.dispose);
        // A label beside a box is not part of the box: without this a reader
        // hears "text field" and has to guess which one.
        expect((await pump(tester, form)).label, 'Email');
      });
    });

    testWidgets('is marked invalid once the rules have refused it',
        (tester) async {
      await reading(tester, () async {
        final form = FormController();
        addTearDown(form.dispose);
        expect(
          (await pump(tester, form)).validationResult,
          SemanticsValidationResult.none,
        );

        await form.validate();
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(find.byType(EditableText)).validationResult,
          SemanticsValidationResult.invalid,
        );
      });
    });

    testWidgets('a label built of widgets is left unread rather than guessed',
        (tester) async {
      await reading(tester, () async {
        final form = FormController();
        addTearDown(form.dispose);
        final node = await pump(
          tester,
          form,
          label: const Row(children: [Icon(Icons.mail), Text('Email')]),
        );
        // Half a label in a reader's ear is worse than none: the field keeps
        // whatever the control itself says.
        expect(node.label, isNot('Email'));
      });
    });
  });
}
