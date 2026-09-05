import 'package:flutter/widgets.dart' hide Form, RadioGroup;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class FormDemo extends StatefulWidget {
  const FormDemo({super.key});

  @override
  State<FormDemo> createState() => _FormDemoState();
}

class _FormDemoState extends State<FormDemo> {
  final _signup = FormController();
  final _profile = FormController(
    initialValues: const {'name': 'Ann Whitfield', 'city': 'Bristol'},
  );
  final _search = FormController();
  final _own = FormController();
  final _every = FormController(
    initialValues: const {'seats': 3, 'budget': 40.0, 'billing': 'monthly'},
  );
  String? _fromTheServer;
  int _filled = 0;

  Map<String, Object?>? _saved;

  @override
  void dispose() {
    _signup.dispose();
    _profile.dispose();
    _search.dispose();
    _own.dispose();
    _every.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Group(
          'A form that asks and refuses',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                controller: _signup,
                // Word of every change: for a count beside the form, or a
                // button that stays dead until it is worth pressing.
                onValuesChanged: (name, values) => setState(
                  () => _filled = values.values
                      .where((v) => v != null && '$v'.isNotEmpty && v != false)
                      .length,
                ),
                onFinish: (values) => setState(() => _saved = values),
                onFinishFailed: (_, errors) =>
                    message.error('${errors.length} to put right'),
                child: Column(
                  children: [
                    // The common kinds, named for what they hold: no type
                    // to write, no control to wire, and the same rules and
                    // words as any other field.
                    FormItem.text(
                      name: 'email',
                      label: const Text('Email'),
                      rules: const [FormRule.required(), FormRule.email()],
                      placeholder: 'you@example.com',
                    ),
                    FormItem.text(
                      name: 'password',
                      label: const Text('Password'),
                      extra: const Text('Eight characters at the very least'),
                      rules: const [FormRule.required(), FormRule.min(8)],
                      password: const PasswordConfig(),
                    ),
                    FormItem.text(
                      name: 'handle',
                      label: const Text('Handle'),
                      placeholder: 'try "admin"',
                      // A rule that has to ask somebody: an ordinary rule
                      // that happens to return a future.
                      rules: [
                        const FormRule.required(),
                        FormRule.custom((value) async {
                          await Future<void>.delayed(
                            const Duration(milliseconds: 300),
                          );
                          return '$value' == 'admin'
                              ? 'That one is spoken for'
                              : null;
                        }),
                      ],
                    ),
                    FormItem<String>(
                      name: 'about',
                      label: const Text('About you'),
                      rules: const [
                        FormRule.max(
                          40,
                          warningOnly: true,
                          message: 'Longer than most people read',
                        ),
                      ],
                      builder: (field) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Input(
                            value: field.value ?? '',
                            status: field.status,
                            onChanged: field.didChange,
                            // Enter asks this field alone, without submitting
                            // the form around it.
                            onSubmitted: (_) => field.validate(),
                          ),
                          // The handle carries the two apart, for a field
                          // that wants to draw them differently: a refusal in
                          // red, a caution in its own words.
                          if (field.error != null || field.warning != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                field.error ?? 'Careful: ${field.warning}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: field.error != null
                                      ? context.softToken.error.base
                                      : context.softToken.warning.base,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    FormItem.check(
                      name: 'terms',
                      title: const Text('I have read the terms'),
                      rules: const [
                        FormRule.required(message: 'You have to agree'),
                      ],
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Button(
                    variant: ButtonVariant.solid,
                    color: ButtonColor.primary,
                    onPressed: _signup.submit,
                    child: const Text('Sign up'),
                  ),
                  Button(
                    onPressed: () => setState(() {
                      _signup.reset();
                      _saved = null;
                    }),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _saved == null
                    ? '$_filled of 6 answered. Submit with the fields empty: every one is refused, and '
                        'the first thing wrong with a value is the only thing '
                        'said about it. Put one right and the message goes as '
                        'you type — a field that has been told off is watched '
                        'from then on.'
                    : 'Sent: $_saved',
              ),
            ],
          ),
        ),
        Group(
          'Labels beside the fields',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                controller: _profile,
                layout: FormLayout.horizontal,
                labelWidth: 96,
                // Against the field rather than away from it, which only
                // means anything once labelWidth has given the column a width
                // to sit in.
                labelAlign: TextAlign.end,
                colon: true,
                requiredMark: FormRequiredMark.optional,
                child: Column(
                  children: [
                    FormItem<String>(
                      name: 'name',
                      label: const Text('Name'),
                      rules: const [FormRule.required()],
                      builder: (field) => Input(
                        value: field.value ?? '',
                        status: field.status,
                        onChanged: field.didChange,
                      ),
                    ),
                    FormItem<String>(
                      name: 'city',
                      label: const Text('City'),
                      builder: (field) => Input(
                        value: field.value ?? '',
                        status: field.status,
                        onChanged: field.didChange,
                      ),
                    ),
                    FormItem<String>(
                      name: 'site',
                      label: const Text('Site'),
                      rules: const [FormRule.url()],
                      builder: (field) => Input(
                        value: field.value ?? '',
                        status: field.status,
                        placeholder: 'https://…',
                        onChanged: field.didChange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Button(
                    onPressed: () => _profile.setValues(const {
                      'name': 'Bartholomew Considine',
                      'city': 'Galway',
                    }),
                    child: const Text('Fill from a record'),
                  ),
                  Button(
                    onPressed: _profile.reset,
                    child: const Text('Back to how it was'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'labelWidth lines the labels up, so the fields begin at the '
                'same place. This form marks what need not be answered rather '
                'than what must, for a page where nearly everything is '
                'required. Fill from a record: the boxes follow, because the '
                'form holds the values and the controls only show them.',
              ),
            ],
          ),
        ),
        Group(
          'Every kind of field, named for what it holds',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                controller: _every,
                layout: FormLayout.horizontal,
                labelWidth: 110,
                labelAlign: TextAlign.end,
                onFinish: (values) => message.success('Booked: $values'),
                child: Column(
                  children: [
                    // Ten kinds, one per control. Each names its own type, so
                    // there is no <String> to write and no Object? to cast,
                    // and each draws the kit's own control — so the three
                    // lines every field used to repeat (value, status,
                    // onChanged) are gone.
                    FormItem.select<String>(
                      name: 'role',
                      label: const Text('Role'),
                      rules: const [FormRule.required()],
                      placeholder: 'Pick one',
                      options: const [
                        SelectOption(value: 'reader', label: Text('Reader')),
                        SelectOption(value: 'author', label: Text('Author')),
                        SelectOption(value: 'owner', label: Text('Owner')),
                      ],
                    ),
                    FormItem.selectMany<String>(
                      name: 'rooms',
                      label: const Text('Rooms'),
                      placeholder: 'Any number of them',
                      showSearch: true,
                      options: const [
                        SelectOption(value: 'north', label: Text('North')),
                        SelectOption(value: 'south', label: Text('South')),
                        SelectOption(value: 'library', label: Text('Library')),
                      ],
                    ),
                    FormItem.date(
                      name: 'start',
                      label: const Text('Starts'),
                      rules: const [FormRule.required()],
                    ),
                    FormItem.time(name: 'at', label: const Text('At')),
                    FormItem.number(
                      name: 'seats',
                      label: const Text('Seats'),
                      min: 0,
                      max: 99,
                      // min and max here count the number itself, where for a
                      // string they would count its letters.
                      rules: const [FormRule.min(1), FormRule.max(20)],
                    ),
                    FormItem.radio<String>(
                      name: 'billing',
                      label: const Text('Billing'),
                      options: const [
                        RadioOption(value: 'monthly', label: Text('Monthly')),
                        RadioOption(value: 'yearly', label: Text('Yearly')),
                      ],
                    ),
                    FormItem.slider(
                      name: 'budget',
                      label: const Text('Budget'),
                      rules: const [
                        FormRule.min(20, message: 'Twenty at the very least'),
                      ],
                    ),
                    FormItem.toggle(
                      name: 'notify',
                      label: const Text('Tell me'),
                    ),
                    FormItem.check(
                      name: 'agreed',
                      label: const Text('Terms'),
                      title: const Text('I agree to them'),
                      rules: const [
                        FormRule.required(message: 'You have to agree'),
                      ],
                    ),
                    // And the general kind, for a control the kit has never
                    // heard of: here a pair of tags standing in for one.
                    FormItem<String>(
                      name: 'mood',
                      label: const Text('Mood'),
                      builder: (field) => Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Wrap(
                          spacing: 8,
                          children: [
                            for (final mood in ['calm', 'busy'])
                              CheckableTag(
                                checked: field.value == mood,
                                onChanged: (on) =>
                                    field.didChange(on ? mood : null),
                                child: Text(mood),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Button(
                variant: ButtonVariant.solid,
                color: ButtonColor.primary,
                onPressed: _every.submit,
                child: const Text('Book it'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ten kinds, one per control: text, number, check, toggle, '
                'date, time, select, selectMany, radio and slider. Each names '
                'its own type — no <String> at the call site and no Object? in '
                'the handle — and draws the kit control that suits it, so the '
                'three lines every field used to repeat have gone. The last '
                'field is the general FormItem with a builder, which is what '
                'a control the kit has never heard of still uses.\n\n'
                'Note select against selectMany: a Select holds a list '
                'whatever its mode, and the single kind unwraps it, so the '
                'field is of the value\'s own type rather than a list of one.',
              ),
            ],
          ),
        ),
        Group(
          'What one field may say for itself',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                controller: _own,
                // Every field is checked as it is typed…
                trigger: FormTrigger.change,
                child: Column(
                  children: [
                    FormItem<String>(
                      name: 'nickname',
                      label: const Text('Nickname'),
                      // The form was told nothing about this one, so the
                      // field says what it starts with.
                      initialValue: 'anon',
                      builder: (field) => Input(
                        value: field.value ?? '',
                        status: field.status,
                        onChanged: field.didChange,
                      ),
                    ),
                    FormItem<String>(
                      name: 'coupon',
                      label: const Text('Coupon'),
                      // …except this one, which is left alone until you
                      // leave it: a code half-typed is not a code that is
                      // wrong.
                      trigger: FormTrigger.blur,
                      rules: const [FormRule.min(6)],
                      extra: const Text('Checked when you leave the field'),
                      builder: (field) => Input(
                        value: field.value ?? '',
                        status: field.status,
                        onChanged: field.didChange,
                      ),
                    ),
                    FormItem<String>(
                      name: 'postcode',
                      label: const Text('Postcode'),
                      // Two rules that count and match rather than demand:
                      // an empty box is `required`'s business, so leaving
                      // this one blank is allowed.
                      rules: [
                        const FormRule.max(8),
                        FormRule.pattern(
                          RegExp(r'^[A-Za-z0-9 ]*$'),
                          message: 'Letters and numbers only',
                        ),
                      ],
                      builder: (field) => Input(
                        value: field.value ?? '',
                        status: field.status,
                        onChanged: field.didChange,
                      ),
                    ),
                    FormItem<String>(
                      name: 'company',
                      label: const Text('Company'),
                      // Marked as expected without a rule enforcing it: the
                      // star is a matter of what the page asks for, and the
                      // rules are a matter of what it will accept.
                      required: true,
                      builder: (field) => Input(
                        value: field.value ?? '',
                        status: field.status,
                        onChanged: field.didChange,
                      ),
                    ),
                    FormItem<String>(
                      name: 'account',
                      label: const Text('Account'),
                      // A message from somewhere else entirely, standing in
                      // place of whatever the rules would have said.
                      help: _fromTheServer,
                      rules: const [FormRule.required()],
                      builder: (field) => Input(
                        value: field.value ?? '',
                        status: field.status,
                        onChanged: field.didChange,
                      ),
                    ),
                    FormItem<String>(
                      name: 'plan',
                      label: const Text('Plan'),
                      // Barred, and so not asked: a required field nobody may
                      // type into would refuse the form for ever.
                      disabled: true,
                      initialValue: 'Settled when you pay',
                      rules: const [FormRule.required()],
                      builder: (field) => Input(
                        value: field.value ?? '',
                        disabled: field.disabled,
                        onChanged: field.didChange,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Button(
                    onPressed: () => setState(
                      () => _fromTheServer = 'We have no such account',
                    ),
                    child: const Text('Let the server refuse it'),
                  ),
                  Button(
                    onPressed: () => setState(() => _fromTheServer = null),
                    child: const Text('Take it back'),
                  ),
                  Button(
                    // One field rather than the lot: the coupon is checked
                    // when you leave it, and this asks without waiting.
                    onPressed: () => _own.validateField('coupon'),
                    child: const Text('Check the coupon'),
                  ),
                  Button(
                    // Every field at once, without submitting: for a wizard
                    // asking whether this step may be left.
                    onPressed: () async => message.info(
                      await _own.validate() ? 'All well' : 'Not yet',
                    ),
                    child: const Text('Check them all'),
                  ),
                  Button(
                    // A value put in from outside, as a record would.
                    onPressed: () => _own.setValue('company', 'Seed Ltd'),
                    child: const Text('Fill the company'),
                  ),
                  Button(
                    variant: ButtonVariant.solid,
                    color: ButtonColor.primary,
                    onPressed: () async {
                      await _own.submit();
                      if (!mounted) return;
                      // `touched` tells a field somebody has been at from one
                      // merely filled in from a record.
                      message.info(
                        _own.touched('company')
                            ? 'You typed the company yourself'
                            : 'The company was filled in for you',
                      );
                    },
                    child: const Text('Try it'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Nickname starts from the field rather than the form. Coupon '
                'is checked when you leave it, in a form that checks '
                'everything else as you type. Company wears the star without '
                'a rule behind it — what the page asks for and what it will '
                'accept are two questions. Account shows whatever the server '
                'says instead of what the rules would. Plan is barred, so its '
                'required rule is not asked: a field nobody may type into '
                'would refuse the form for ever. The buttons show the rest of '
                'the controller: validateField asks one field, setValue puts '
                'a value in as a record would, and touched tells a field '
                'somebody has typed into from one that was filled in for '
                'them.',
              ),
            ],
          ),
        ),
        Group(
          'A form in a line',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                controller: _search,
                layout: FormLayout.inline,
                trigger: FormTrigger.submit,
                // The keyboard stays up: this is a search somebody refines,
                // not a form they are done with.
                unfocusOnSubmit: false,
                // One form's own tokens, for a bar that has no room for the
                // gap a page of questions wants.
                token: const FormToken(itemGap: 0),
                onFinish: (values) => message.success('Looking for $values'),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 200,
                      child: FormItem<String>(
                        name: 'q',
                        label: const Text('Find'),
                        rules: const [FormRule.required()],
                        builder: (field) => Input(
                          value: field.value ?? '',
                          status: field.status,
                          onChanged: field.didChange,
                          // Enter searches, as it would anywhere else.
                          onSubmitted: (_) => _search.submit(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      variant: ButtonVariant.solid,
                      color: ButtonColor.primary,
                      onPressed: _search.submit,
                      child: const Text('Search'),
                    ),
                  ],
                ),
              ),
              const Text(
                'Asked only on submit: nothing is refused while it is being '
                'typed, which is what a search bar wants — and the keyboard '
                'stays up afterwards, since a search is refined rather than '
                'finished. Its own FormToken closes the gap a page of '
                'questions would want under each field.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
