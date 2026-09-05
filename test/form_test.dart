import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart' hide Form;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child, {double width = 400}) => ConfigProvider(
      child: m.MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: m.Scaffold(
          body: Center(child: SizedBox(width: width, child: child)),
        ),
      ),
    );

/// A field holding text, which is what most fields are.
FormItem<String> _text(
  String name, {
  Widget? label,
  List<FormRule> rules = const [],
  String? initialValue,
  String? help,
  Widget? extra,
  FormTrigger? trigger,
  bool? disabled,
}) =>
    FormItem<String>(
      name: name,
      label: label,
      rules: rules,
      initialValue: initialValue,
      help: help,
      extra: extra,
      trigger: trigger,
      disabled: disabled,
      builder: (field) => Input(
        value: field.value ?? '',
        status: field.status,
        disabled: field.disabled,
        onChanged: field.didChange,
      ),
    );

void main() {
  group('what a form holds', () {
    testWidgets('a field puts what it holds into the form', (tester) async {
      final form = FormController();
      await tester.pumpWidget(
        _host(Form(controller: form, child: _text('name'))),
      );

      await tester.enterText(find.byType(Input), 'Ann');
      await tester.pumpAndSettle();
      expect(form.value('name'), 'Ann');
      expect(form.values, {'name': 'Ann'});
    });

    testWidgets('what the form was told to start with is there at once',
        (tester) async {
      final form = FormController();
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            initialValues: const {'name': 'Ann'},
            child: _text('name'),
          ),
        ),
      );

      // In the store before anybody has typed, and in the box on screen.
      expect(form.value('name'), 'Ann');
      expect(find.text('Ann'), findsOneWidget);
    });

    testWidgets("a field's own starting value fills in where the form is quiet",
        (tester) async {
      final form = FormController();
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            initialValues: const {'a': 'from the form'},
            child: Column(
              children: [
                _text('a', initialValue: 'from the field'),
                _text('b', initialValue: 'from the field'),
              ],
            ),
          ),
        ),
      );

      expect(form.value('a'), 'from the form', reason: 'the form has the say');
      expect(form.value('b'), 'from the field');
    });

    testWidgets('setting a value from outside reaches the box', (tester) async {
      final form = FormController();
      await tester.pumpWidget(
        _host(Form(controller: form, child: _text('name'))),
      );

      form.setValue('name', 'Bart');
      await tester.pumpAndSettle();
      expect(find.text('Bart'), findsOneWidget);
    });

    testWidgets('reset puts the values and the messages back', (tester) async {
      final form = FormController();
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            initialValues: const {'name': 'Ann'},
            child: _text('name', rules: const [FormRule.required()]),
          ),
        ),
      );

      await tester.enterText(find.byType(Input), '');
      await tester.pumpAndSettle();
      expect(form.errors, isNotEmpty);

      form.reset();
      await tester.pumpAndSettle();
      expect(form.value('name'), 'Ann');
      expect(form.errors, isEmpty);
      expect(find.text('Ann'), findsOneWidget);
    });
  });

  group('what the rules make of it', () {
    Future<String?> saidOf(
      WidgetTester tester,
      List<FormRule> rules,
      String typed,
    ) async {
      final form = FormController();
      await tester.pumpWidget(
        _host(Form(controller: form, child: _text('f', rules: rules))),
      );
      await tester.enterText(find.byType(Input), typed);
      await tester.pumpAndSettle();
      await form.validate();
      await tester.pumpAndSettle();
      return form.error('f');
    }

    testWidgets('required refuses what is not there', (tester) async {
      expect(await saidOf(tester, const [FormRule.required()], ''),
          'This field is required');
      expect(
          await saidOf(tester, const [FormRule.required()], '   '), isNotNull,
          reason: 'spaces are not an answer');
      expect(await saidOf(tester, const [FormRule.required()], 'x'), isNull);
    });

    testWidgets('email and url know what they are looking at', (tester) async {
      expect(await saidOf(tester, const [FormRule.email()], 'nope'),
          'Enter a valid email address');
      expect(await saidOf(tester, const [FormRule.email()], 'a@b.co'), isNull);
      expect(await saidOf(tester, const [FormRule.url()], 'not a url'),
          'Enter a valid web address');
      expect(
          await saidOf(tester, const [FormRule.url()], 'https://a.co'), isNull);

      // An empty value is the business of `required`, not of these: a field
      // that may be left blank should not be told its blank is a bad address.
      expect(await saidOf(tester, const [FormRule.email()], ''), isNull);
    });

    testWidgets('min and max count what they are given', (tester) async {
      expect(await saidOf(tester, const [FormRule.min(3)], 'ab'), 'At least 3');
      expect(await saidOf(tester, const [FormRule.min(3)], 'abc'), isNull);
      expect(
          await saidOf(tester, const [FormRule.max(3)], 'abcd'), 'At most 3');
      expect(await saidOf(tester, const [FormRule.max(3)], 'abc'), isNull);
    });

    testWidgets('a message of your own takes the place of the kit\'s',
        (tester) async {
      expect(
        await saidOf(
          tester,
          const [FormRule.required(message: 'We need this')],
          '',
        ),
        'We need this',
      );
    });

    testWidgets('the first refusal is the one shown', (tester) async {
      // Both of these fail on 'ab': it is too short and it is not an email.
      // A field that lists everything wrong with a value at once reads as
      // scolding, so the first is the one worth reading.
      final said = await saidOf(
        tester,
        const [FormRule.min(5), FormRule.email()],
        'ab',
      );
      expect(said, 'At least 5');
    });

    testWidgets('a rule that only warns does not stand in the way',
        (tester) async {
      final form = FormController();
      var finished = false;
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            onFinish: (_) => finished = true,
            child: _text('f', rules: const [
              FormRule.min(5, warningOnly: true, message: 'Rather short'),
            ]),
          ),
        ),
      );

      await tester.enterText(find.byType(Input), 'ab');
      await tester.pumpAndSettle();
      await form.submit();
      await tester.pumpAndSettle();

      expect(finished, isTrue, reason: 'a caution is not a refusal');
      expect(form.errors, isEmpty);
      expect(find.text('Rather short'), findsOneWidget);
    });

    testWidgets('a rule of your own may take its time', (tester) async {
      final form = FormController();
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            child: _text('f', rules: [
              FormRule.custom((value) async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return value == 'taken' ? 'That one is spoken for' : null;
              }),
            ]),
          ),
        ),
      );

      await tester.enterText(find.byType(Input), 'taken');
      await tester.pumpAndSettle();
      expect(form.error('f'), 'That one is spoken for');

      await tester.enterText(find.byType(Input), 'free');
      await tester.pumpAndSettle();
      expect(form.error('f'), isNull);
    });
  });

  group('when the rules are asked', () {
    testWidgets('on change, as it is typed', (tester) async {
      final form = FormController();
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            child: _text('f', rules: const [FormRule.min(3)]),
          ),
        ),
      );

      await tester.enterText(find.byType(Input), 'ab');
      await tester.pumpAndSettle();
      expect(form.error('f'), isNotNull);
    });

    testWidgets('on submit, and not before', (tester) async {
      final form = FormController();
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            trigger: FormTrigger.submit,
            child: _text('f', rules: const [FormRule.min(3)]),
          ),
        ),
      );

      await tester.enterText(find.byType(Input), 'ab');
      await tester.pumpAndSettle();
      expect(form.error('f'), isNull, reason: 'nobody has asked yet');

      await form.submit();
      await tester.pumpAndSettle();
      expect(form.error('f'), isNotNull);
    });

    testWidgets('a field told off is watched from then on', (tester) async {
      // Whatever the trigger says: leaving a red border under a value that
      // has just been put right is the form arguing with the reader.
      final form = FormController();
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            trigger: FormTrigger.submit,
            child: _text('f', rules: const [FormRule.min(3)]),
          ),
        ),
      );

      await tester.enterText(find.byType(Input), 'ab');
      await tester.pumpAndSettle();
      await form.submit();
      await tester.pumpAndSettle();
      expect(form.error('f'), isNotNull);

      await tester.enterText(find.byType(Input), 'abc');
      await tester.pumpAndSettle();
      expect(form.error('f'), isNull, reason: 'put right, and told so');
    });
  });

  group('submitting', () {
    testWidgets('the values go where they are asked for', (tester) async {
      final form = FormController();
      Map<String, Object?>? finished;
      Map<String, String>? refused;
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            onFinish: (values) => finished = values,
            onFinishFailed: (values, errors) => refused = errors,
            child: _text('f', rules: const [FormRule.required()]),
          ),
        ),
      );

      await form.submit();
      await tester.pumpAndSettle();
      expect(finished, isNull);
      expect(refused, {'f': 'This field is required'});

      await tester.enterText(find.byType(Input), 'Ann');
      await tester.pumpAndSettle();
      await form.submit();
      await tester.pumpAndSettle();
      expect(finished, {'f': 'Ann'});
    });

    testWidgets('a form makes a controller of its own where none is given',
        (tester) async {
      Map<String, Object?>? finished;
      await tester.pumpWidget(
        _host(
          Form(
            onFinish: (values) => finished = values,
            child: Builder(
              builder: (context) => Column(
                children: [
                  _text('f'),
                  Button(
                    onPressed: Form.controllerOf(context).submit,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(Input), 'Ann');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(finished, {'f': 'Ann'});
    });

    testWidgets('every change is reported as it happens', (tester) async {
      final heard = <String>[];
      Map<String, Object?>? all;
      await tester.pumpWidget(
        _host(
          Form(
            onValuesChanged: (name, values) {
              heard.add(name);
              all = values;
            },
            child: _text('f'),
          ),
        ),
      );

      await tester.enterText(find.byType(Input), 'A');
      await tester.pumpAndSettle();
      expect(heard, ['f']);
      expect(all, {'f': 'A'});
    });
  });

  group('what submitting does besides validating', () {
    testWidgets('the keyboard goes away', (tester) async {
      final form = FormController();
      await tester.pumpWidget(
        _host(Form(controller: form, child: _text('f'))),
      );

      await tester.tap(find.byType(Input));
      await tester.pumpAndSettle();
      bool typing() => tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode
          .hasFocus;
      expect(typing(), isTrue);

      await form.submit();
      await tester.pumpAndSettle();
      expect(typing(), isFalse,
          reason: 'a form that has been sent is not being typed into');
    });

    testWidgets('unless the form would rather it stayed', (tester) async {
      final form = FormController();
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            unfocusOnSubmit: false,
            child: _text('f'),
          ),
        ),
      );

      await tester.tap(find.byType(Input));
      await tester.pumpAndSettle();
      await form.submit();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
        reason: 'a search bar being refined keeps the keyboard',
      );
    });

    testWidgets('a slow rule does not overwrite a faster one', (tester) async {
      // Two runs started on two keystrokes can finish in either order. The
      // later value has the last word, whichever answer arrives last.
      final form = FormController();
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            child: _text('f', rules: [
              FormRule.custom((value) async {
                // The shorter the value, the slower the answer.
                await Future<void>.delayed(
                  Duration(milliseconds: 200 - '$value'.length * 20),
                );
                return '$value' == 'admin' ? 'That one is spoken for' : null;
              }),
            ]),
          ),
        ),
      );

      await tester.enterText(find.byType(Input), 'admin');
      await tester.pump(const Duration(milliseconds: 10));
      await tester.enterText(find.byType(Input), 'admins');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(form.value('f'), 'admins');
      expect(form.error('f'), isNull,
          reason: 'the answer about a value nobody is holding is stale');
    });
  });

  group('a field nobody may touch', () {
    testWidgets('a barred field does not refuse the form', (tester) async {
      // It cannot be typed into, so a rule refusing it would refuse the form
      // for ever, pointing at a box the reader is not allowed to touch.
      final form = FormController();
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            child: Column(
              children: [
                _text('locked',
                    disabled: true, rules: const [FormRule.required()]),
                _text('open', rules: const [FormRule.required()]),
              ],
            ),
          ),
        ),
      );

      expect(await form.validate(), isFalse, reason: 'the open one is empty');
      expect(form.errors.keys, ['open']);

      await tester.enterText(find.byType(Input).last, 'Ann');
      await tester.pumpAndSettle();
      expect(await form.validate(), isTrue, reason: 'and nothing else refuses');
    });

    testWidgets('a message goes when the field is barred', (tester) async {
      final form = FormController();
      Widget table({required bool locked}) => _host(
            Form(
              controller: form,
              child: _text('f',
                  disabled: locked, rules: const [FormRule.required()]),
            ),
          );

      await tester.pumpWidget(table(locked: false));
      await form.validate();
      await tester.pumpAndSettle();
      expect(form.error('f'), isNotNull);

      await tester.pumpWidget(table(locked: true));
      await form.validate();
      await tester.pumpAndSettle();
      expect(form.error('f'), isNull);
      expect(find.text('This field is required'), findsNothing);
    });

    testWidgets('two fields cannot share a name', (tester) async {
      await tester.pumpWidget(
        _host(
          Form(
            child: Column(children: [_text('same'), _text('same')]),
          ),
        ),
      );
      // Silently, the second would take the first's place: only one would be
      // validated and both would write to the same value. Complained about
      // after the frame, since throwing while a field is being attached
      // leaves the tree half-built.
      await tester.pump();
      expect(tester.takeException(), isFlutterError);
    });
  });

  group('what stands around a field', () {
    testWidgets('a field that must be answered is marked', (tester) async {
      await tester.pumpWidget(
        _host(
          Form(
            child: Column(
              children: [
                _text('a',
                    label: const Text('Asked'),
                    rules: const [FormRule.required()]),
                _text('b', label: const Text('Not asked')),
              ],
            ),
          ),
        ),
      );

      // Worked out from the rules, without being told twice.
      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('or the other way about, where nearly all are required',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Form(
            requiredMark: FormRequiredMark.optional,
            child: Column(
              children: [
                _text('a',
                    label: const Text('Asked'),
                    rules: const [FormRule.required()]),
                _text('b', label: const Text('Not asked')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('*'), findsNothing);
      expect(find.text('(optional)'), findsOneWidget);
    });

    testWidgets('a label and its mark fit the column they were given',
        (tester) async {
      // The word marking a field optional stands beside the label, and in a
      // column narrow enough to be worth naming a width for the two together
      // are easily more than there is room for.
      await tester.pumpWidget(
        _host(
          Form(
            layout: FormLayout.horizontal,
            labelWidth: 60,
            colon: true,
            requiredMark: FormRequiredMark.optional,
            child: _text('f', label: const Text('Company name')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('help stands in place of what the rules would say',
        (tester) async {
      final form = FormController();
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            child: _text(
              'f',
              help: 'The server said no',
              rules: const [FormRule.required()],
            ),
          ),
        ),
      );

      await form.validate();
      await tester.pumpAndSettle();
      expect(find.text('The server said no'), findsOneWidget);
      expect(find.text('This field is required'), findsNothing);
    });

    testWidgets('extra stands beside it rather than instead', (tester) async {
      final form = FormController();
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            child: _text(
              'f',
              extra: const Text('We never show it to anybody'),
              rules: const [FormRule.required()],
            ),
          ),
        ),
      );

      await form.validate();
      await tester.pumpAndSettle();
      expect(find.text('We never show it to anybody'), findsOneWidget);
      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('a label stands above or beside, as the form says',
        (tester) async {
      Future<Rect> labelAt(FormLayout layout) async {
        await tester.pumpWidget(
          _host(
            Form(
              layout: layout,
              labelWidth: 100,
              child: _text('f', label: const Text('Name')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getRect(find.text('Name'));
      }

      final above = await labelAt(FormLayout.vertical);
      final input = tester.getRect(find.byType(Input));
      expect(above.bottom, lessThanOrEqualTo(input.top));

      final beside = await labelAt(FormLayout.horizontal);
      final field = tester.getRect(find.byType(Input));
      expect(beside.left, lessThan(field.left));
      expect(beside.top, lessThan(field.bottom));
    });

    testWidgets('a label beside its field is level with the words in it',
        (tester) async {
      Future<void> show({String? help}) => tester.pumpWidget(
            _host(
              Form(
                layout: FormLayout.horizontal,
                labelWidth: 96,
                initialValues: const {'name': 'Ann'},
                child: _text('name', label: const Text('Name'), help: help),
              ),
            ),
          );

      // Centred against the control, not reckoned from font metrics: an
      // arithmetic guess left the two a pixel or two apart.
      await show();
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('Name')).center.dy,
        closeTo(tester.getRect(find.text('Ann')).center.dy, 0.5),
      );

      // And a message under the field does not drag the label down with it:
      // the label is level with the control, not with the whole row.
      await show(help: 'Something under the field');
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.text('Name')).center.dy,
        closeTo(tester.getRect(find.text('Ann')).center.dy, 0.5),
      );
    });

    testWidgets('an inline field is given a width to lay itself out in',
        (tester) async {
      // A `Row` hands a child carrying no flex an unbounded width along its
      // main axis, and a control that fills what it is given cannot lay
      // itself out in infinity — which is a thrown assertion, not a wonky
      // pixel.
      await tester.pumpWidget(
        _host(
          Form(
            layout: FormLayout.inline,
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: _text('q', label: const Text('Find')),
                ),
                Button(onPressed: () {}, child: const Text('Search')),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final box = tester.getRect(find.byType(Input));
      expect(box.width, greaterThan(0));
      expect(box.width, lessThan(200), reason: 'the label took its share');
    });

    testWidgets('a form may bar every field at once, or one alone',
        (tester) async {
      await tester.pumpWidget(
        _host(Form(disabled: true, child: _text('f'))),
      );
      expect(tester.widget<Input>(find.byType(Input)).disabled, isTrue);

      await tester.pumpWidget(
        _host(
          Form(
            child: Column(
              children: [_text('a', disabled: true), _text('b')],
            ),
          ),
        ),
      );
      final inputs = tester.widgetList<Input>(find.byType(Input)).toList();
      expect(inputs.first.disabled, isTrue);
      expect(inputs.last.disabled, isNot(true));
    });
  });
}
