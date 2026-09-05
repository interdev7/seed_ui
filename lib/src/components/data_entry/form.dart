import 'dart:async';

import 'package:flutter/widgets.dart' hide Form, FormField, RadioGroup;

import '../../l10n/seed_localizations.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../data_entry/checkbox.dart' show Checkbox;
import '../data_entry/date_picker.dart' show DatePicker;
import '../data_entry/input.dart' show Input, InputStatus, PasswordConfig;
import '../data_entry/input_number.dart' show InputNumber;
import '../data_entry/radio.dart' show RadioGroup, RadioOption, RadioOptionType;
import '../data_entry/select.dart'
    show Select, SelectMode, SelectOption, SelectStatus;
import '../data_entry/slider.dart' show Slider, SliderMark;
import '../data_entry/switch.dart' show Switch;
import '../data_entry/time_picker.dart' show TimePicker;

/// Where a field's label stands in relation to what it labels.
enum FormLayout {
  /// Label beside the field, in a column of its own.
  horizontal,

  /// Label above the field.
  vertical,

  /// Label beside the field, with the fields themselves in a row — for a
  /// search bar rather than a page of questions.
  inline,
}

/// How a field that must be answered is marked.
enum FormRequiredMark {
  /// A star before the label of each field that is required.
  required,

  /// A word after the label of each field that is *not*, for a form where
  /// nearly everything must be answered and the exceptions are the news.
  optional,

  /// Nothing either way.
  none,
}

/// What a rule found wrong with a value, if anything.
///
/// A message means the value is not good enough; null means it is. A rule
/// that only wants to warn says so with [FormRule.warningOnly], and the form
/// still submits.
typedef FormValidator = FutureOr<String?> Function(Object? value);

/// One thing a value has to satisfy.
///
/// Built from the named constructors rather than by hand: each carries a
/// message of its own where you give one and the kit's own words in eleven
/// languages where you do not.
///
/// ```dart
/// rules: const [FormRule.required(), FormRule.email()]
/// ```
@immutable
class FormRule {
  const FormRule._(
    this._check, {
    this.message,
    this.warningOnly = false,
    int count = 0,
    RegExp? pattern,
    FormValidator? validator,
  })  : _count = count,
        _pattern = pattern,
        _validator = validator;

  /// The value has to be there: not null, not an empty string, not an empty
  /// list, and not a false checkbox.
  const FormRule.required({String? message, bool warningOnly = false})
      : this._(_Check.required, message: message, warningOnly: warningOnly);

  /// The value has to have at least [count] characters or items, or be at
  /// least that number.
  const FormRule.min(int count, {String? message, bool warningOnly = false})
      : this._(_Check.min,
            count: count, message: message, warningOnly: warningOnly);

  /// The value has to have at most [count] characters or items, or be at most
  /// that number.
  const FormRule.max(int count, {String? message, bool warningOnly = false})
      : this._(_Check.max,
            count: count, message: message, warningOnly: warningOnly);

  /// The value has to match [pattern].
  const FormRule.pattern(RegExp pattern,
      {String? message, bool warningOnly = false})
      : this._(_Check.pattern,
            pattern: pattern, message: message, warningOnly: warningOnly);

  /// The value has to look like an email address.
  const FormRule.email({String? message, bool warningOnly = false})
      : this._(_Check.email, message: message, warningOnly: warningOnly);

  /// The value has to look like a web address.
  const FormRule.url({String? message, bool warningOnly = false})
      : this._(_Check.url, message: message, warningOnly: warningOnly);

  /// Anything you like, including something that has to be asked of a server.
  ///
  /// Return null where the value is good and a message where it is not.
  const FormRule.custom(FormValidator validator,
      {String? message, bool warningOnly = false})
      : this._(_Check.custom,
            validator: validator, message: message, warningOnly: warningOnly);

  final _Check _check;
  final int _count;
  final RegExp? _pattern;
  final FormValidator? _validator;

  /// What to say when the value does not satisfy this rule.
  ///
  /// The kit's own words where none is given, in whichever language the app
  /// is running in.
  final String? message;

  /// Whether failing this rule is a caution rather than a refusal: the field
  /// is marked, and the form still submits.
  final bool warningOnly;

  /// Whether a field carrying this rule must be answered, which is what the
  /// mark beside its label says.
  bool get _demands => _check == _Check.required;

  /// What this rule makes of [value], in the words of [words].
  FutureOr<String?> _test(Object? value, SeedLocalizations words) {
    switch (_check) {
      case _Check.required:
        final empty = value == null ||
            (value is String && value.trim().isEmpty) ||
            (value is Iterable && value.isEmpty) ||
            (value is bool && !value);
        return empty ? (message ?? words.formRequired) : null;
      case _Check.min:
        final size = _sizeOf(value);
        if (size == null || size >= _count) return null;
        return message ?? words.formTooShort.replaceAll('{n}', '$_count');
      case _Check.max:
        final size = _sizeOf(value);
        if (size == null || size <= _count) return null;
        return message ?? words.formTooLong.replaceAll('{n}', '$_count');
      case _Check.pattern:
        if (value == null || '$value'.isEmpty) return null;
        return _pattern!.hasMatch('$value')
            ? null
            : (message ?? words.formInvalid);
      case _Check.email:
        if (value == null || '$value'.isEmpty) return null;
        return _email.hasMatch('$value')
            ? null
            : (message ?? words.formInvalidEmail);
      case _Check.url:
        if (value == null || '$value'.isEmpty) return null;
        final parsed = Uri.tryParse('$value');
        final ok = parsed != null &&
            parsed.hasScheme &&
            parsed.host.isNotEmpty &&
            (parsed.isScheme('http') || parsed.isScheme('https'));
        return ok ? null : (message ?? words.formInvalidUrl);
      case _Check.custom:
        return _validator!(value);
    }
  }

  /// How big a value is, for a rule that counts: the length of a string or a
  /// list, or the number itself. Null where the value cannot be counted, and
  /// a rule that cannot count says nothing rather than guessing.
  static num? _sizeOf(Object? value) => switch (value) {
        null => null,
        final String s => s.length,
        final Iterable<Object?> l => l.length,
        final num n => n,
        _ => null,
      };

  // Deliberately loose: a pattern strict enough to be interesting rejects
  // addresses that work, and the only test that settles it is sending mail.
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}

enum _Check { required, min, max, pattern, email, url, custom }

/// What a field is doing and what may be done to it.
///
/// Handed to [FormItem.builder], which is where a field of any kind is wired
/// up: read [value], report a change through [didChange], and pass [status]
/// to a control that can show one.
@immutable
class FormFieldHandle<T> {
  /// Creates a [FormFieldHandle].
  const FormFieldHandle({
    required this.value,
    required this.error,
    required this.warning,
    required this.didChange,
    required this.validate,
    required this.disabled,
  });

  /// What the field holds now.
  final T? value;

  /// What is wrong with it, if anything.
  final String? error;

  /// What is questionable about it — a rule that only warns.
  final String? warning;

  /// Whether the field is barred from being changed.
  final bool disabled;

  /// Reports a new value to the form.
  final ValueChanged<T?> didChange;

  /// Asks the rules about the value now, whatever the form's trigger says.
  final Future<bool> Function() validate;

  /// What to hand a control that can recolour itself — [Input], [Select],
  /// [InputNumber] and the pickers all take one.
  InputStatus? get status => error != null
      ? InputStatus.error
      : (warning != null ? InputStatus.warning : null);
}

/// When a field's rules are asked.
enum FormTrigger {
  /// As the value changes.
  change,

  /// When the field is left.
  blur,

  /// Only when the form is submitted.
  submit,
}

/// The values a form holds, and everything that can be done to them.
///
/// Made outside the widget and handed to it, so a caller can read a value,
/// set one, or submit from anywhere — a button in a dialog's footer, say,
/// which is nowhere near the form itself.
///
/// ```dart
/// final form = FormController();
/// // …
/// Form(controller: form, child: …)
/// Button(onPressed: form.submit, child: const Text('Save'))
/// ```
class FormController extends ChangeNotifier {
  /// Creates a [FormController].
  FormController({Map<String, Object?>? initialValues})
      : _initial = {...?initialValues},
        _values = {...?initialValues};

  final Map<String, Object?> _initial;
  final Map<String, Object?> _values;
  final Map<String, String> _errors = {};
  final Map<String, String> _warnings = {};
  final Set<String> _touched = {};
  final Map<String, _Field> _fields = {};

  /// Called by the form it is handed to, so `submit` can put the keyboard
  /// away before it starts.
  VoidCallback? _onSubmitStart;

  /// Called by the form it is handed to, so `submit` can do what the form's
  /// own `onFinish` would.
  void Function(Map<String, Object?> values)? _onFinish;
  void Function(Map<String, Object?> values, Map<String, String> errors)?
      _onFinishFailed;

  /// Every value the form holds, by field name.
  Map<String, Object?> get values => Map.unmodifiable(_values);

  /// What one field holds.
  Object? value(String name) => _values[name];

  /// What is wrong with one field, if anything.
  String? error(String name) => _errors[name];

  /// Whether a field has been touched by the reader rather than only set.
  bool touched(String name) => _touched.contains(name);

  /// Every message standing against the form now.
  Map<String, String> get errors => Map.unmodifiable(_errors);

  /// Sets one field, as though the reader had.
  void setValue(String name, Object? value) {
    _values[name] = value;
    notifyListeners();
  }

  /// Sets several at once.
  void setValues(Map<String, Object?> values) {
    _values.addAll(values);
    notifyListeners();
  }

  /// Puts the form back to the values it began with, and forgets every
  /// message and every touch.
  void reset() {
    _values
      ..clear()
      ..addAll(_initial);
    _errors.clear();
    _warnings.clear();
    _touched.clear();
    notifyListeners();
  }

  /// Asks every field's rules, and reports whether the form may be submitted.
  ///
  /// A rule that only warns marks its field and does not stand in the way.
  Future<bool> validate() async {
    var ok = true;
    for (final field in _fields.values.toList()) {
      if (!await field.validate()) ok = false;
    }
    notifyListeners();
    return ok;
  }

  /// Asks one field's rules.
  Future<bool> validateField(String name) async {
    final field = _fields[name];
    if (field == null) return true;
    final ok = await field.validate();
    notifyListeners();
    return ok;
  }

  /// Validates, then hands the values to the form's `onFinish` — or the
  /// messages to its `onFinishFailed`.
  Future<void> submit() async {
    // The keyboard goes away first, before anything is decided: a form that
    // has been sent is a form nobody is typing into, and a message that
    // appears behind a keyboard is a message nobody reads.
    _onSubmitStart?.call();
    final ok = await validate();
    if (ok) {
      _onFinish?.call(values);
    } else {
      _onFinishFailed?.call(values, errors);
    }
  }

  void _register(String name, _Field field) {
    // Complained about after the frame rather than during it: a field
    // registers while it is being attached to the tree, and throwing there
    // leaves the tree half-built — Flutter then trips over an assertion of
    // its own and the real message is lost among the wreckage.
    if (_fields.containsKey(name)) {
      assert(() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          throw FlutterError(
            'Two fields in this form are called "$name". The second took the '
            "first's place: only one of them is validated, and both write to "
            'the same value.',
          );
        });
        return true;
      }());
    }
    _fields[name] = field;
    // A field arriving with nothing in the store takes what it was told to
    // start with, so `values` is whole from the first frame rather than
    // filling in as the fields happen to build.
    if (!_values.containsKey(name) && field.initialValue != null) {
      _values[name] = field.initialValue;
      _initial.putIfAbsent(name, () => field.initialValue);
    }
  }

  void _unregister(String name, _Field field) {
    if (identical(_fields[name], field)) _fields.remove(name);
  }

  /// Told by a field that something about it has changed. Fields are not
  /// `ChangeNotifier`s of their own: what listens to a form listens to the
  /// form.
  void _announce() => notifyListeners();

  void _report(String name, {String? error, String? warning}) {
    if (error == null) {
      _errors.remove(name);
    } else {
      _errors[name] = error;
    }
    if (warning == null) {
      _warnings.remove(name);
    } else {
      _warnings[name] = warning;
    }
  }

  @override
  void dispose() {
    _fields.clear();
    super.dispose();
  }
}

/// What a field must be able to do for the controller that holds it.
abstract class _Field {
  Object? get initialValue;
  Future<bool> validate();
}

/// A form: a set of named fields, the values they hold, and the rules they
/// answer to.
///
/// The layout, the marks and the words around the fields are the form's
/// business; what each field *is* stays the caller's, through
/// [FormItem.builder]. Nothing is guessed from the widget you put in a field,
/// because guessing is how a form ends up unable to hold the one control you
/// need.
///
/// ```dart
/// Form(
///   controller: form,
///   onFinish: (values) => save(values),
///   child: Column(
///     children: [
///       FormItem<String>(
///         name: 'email',
///         label: const Text('Email'),
///         rules: const [FormRule.required(), FormRule.email()],
///         builder: (field) => Input(
///           value: field.value,
///           status: field.status,
///           onChanged: field.didChange,
///         ),
///       ),
///     ],
///   ),
/// )
/// ```
class Form extends StatefulWidget {
  /// Creates a [Form].
  const Form({
    super.key,
    required this.child,
    this.controller,
    this.layout = FormLayout.vertical,
    this.labelWidth,
    this.labelAlign = TextAlign.start,
    this.colon = false,
    this.requiredMark = FormRequiredMark.required,
    this.disabled = false,
    this.trigger = FormTrigger.change,
    this.unfocusOnSubmit = true,
    this.initialValues,
    this.onFinish,
    this.onFinishFailed,
    this.onValuesChanged,
    this.token,
  });

  /// The fields, and whatever else stands among them.
  final Widget child;

  /// The values and the doing. Left null the form makes one of its own, which
  /// is enough for a form whose only exit is its own submit button.
  final FormController? controller;

  /// Where the labels stand.
  final FormLayout layout;

  /// How wide the column of labels is, where they stand beside their fields.
  ///
  /// Null lets each label take the width it wants, which lines nothing up;
  /// name a width and the fields begin at the same place down the form.
  final double? labelWidth;

  /// How a label sits in its column.
  final TextAlign labelAlign;

  /// Whether a colon follows each label.
  final bool colon;

  /// How a field that must be answered is marked.
  final FormRequiredMark requiredMark;

  /// Bars every field in the form.
  final bool disabled;

  /// When a field's rules are asked, unless the field says otherwise.
  final FormTrigger trigger;

  /// Whether submitting puts the keyboard away.
  ///
  /// A form that has been sent is a form nobody is typing into, and on a
  /// phone a message that appears behind a keyboard is a message nobody
  /// reads. Turn it off for a form that is submitted over and over — a search
  /// bar somebody is refining.
  final bool unfocusOnSubmit;

  /// What the fields start with, by name. A field's own `initialValue` fills
  /// in where this says nothing.
  final Map<String, Object?>? initialValues;

  /// Called with the values once they have all passed.
  final void Function(Map<String, Object?> values)? onFinish;

  /// Called with the values and the messages when they have not.
  final void Function(
    Map<String, Object?> values,
    Map<String, String> errors,
  )? onFinishFailed;

  /// Called whenever any field changes, with the name that changed and every
  /// value the form now holds.
  final void Function(String name, Map<String, Object?> values)?
      onValuesChanged;

  /// Per-instance token overrides.
  final FormToken? token;

  /// The controller of the form this context stands in, for a widget that
  /// wants to read a value or submit without being handed one.
  static FormController controllerOf(BuildContext context) =>
      _scopeOf(context).controller;

  static _FormScope _scopeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_FormScope>();
    assert(scope != null, 'A FormItem has to stand inside a Form.');
    return scope!;
  }

  @override
  State<Form> createState() => _FormState();
}

class _FormState extends State<Form> {
  FormController? _own;
  FormController get _controller => widget.controller ?? (_own ??= _make());

  FormController _make() => FormController(initialValues: widget.initialValues);

  @override
  void initState() {
    super.initState();
    _wire();
  }

  @override
  void didUpdateWidget(Form old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) _wire();
  }

  /// Hands the controller what `submit` needs to finish the job.
  void _wire() {
    final controller = _controller;
    controller._onSubmitStart = () {
      if (widget.unfocusOnSubmit && mounted) FocusScope.of(context).unfocus();
    };
    controller._onFinish = (values) => widget.onFinish?.call(values);
    controller._onFinishFailed =
        (values, errors) => widget.onFinishFailed?.call(values, errors);
    // A controller made outside the form is told what to start with here,
    // where the form is the one that knows.
    final start = widget.initialValues;
    if (start != null) {
      for (final entry in start.entries) {
        controller._initial.putIfAbsent(entry.key, () => entry.value);
        if (!controller._values.containsKey(entry.key)) {
          controller._values[entry.key] = entry.value;
        }
      }
    }
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<FormToken>(context) ??
            const FormToken())
        ._resolve(t);
    return _FormScope(
      controller: _controller,
      layout: widget.layout,
      labelWidth: widget.labelWidth,
      labelAlign: widget.labelAlign,
      colon: widget.colon,
      requiredMark: widget.requiredMark,
      disabled: widget.disabled,
      trigger: widget.trigger,
      onValuesChanged: widget.onValuesChanged,
      style: r,
      child: widget.child,
    );
  }
}

/// What a [FormItem] reads off the form it stands in.
class _FormScope extends InheritedWidget {
  const _FormScope({
    required this.controller,
    required this.layout,
    required this.labelWidth,
    required this.labelAlign,
    required this.colon,
    required this.requiredMark,
    required this.disabled,
    required this.trigger,
    required this.onValuesChanged,
    required this.style,
    required super.child,
  });

  final FormController controller;
  final FormLayout layout;
  final double? labelWidth;
  final TextAlign labelAlign;
  final bool colon;
  final FormRequiredMark requiredMark;
  final bool disabled;
  final FormTrigger trigger;
  final void Function(String name, Map<String, Object?> values)?
      onValuesChanged;
  final _ResolvedFormToken style;

  @override
  bool updateShouldNotify(_FormScope old) =>
      controller != old.controller ||
      layout != old.layout ||
      labelWidth != old.labelWidth ||
      labelAlign != old.labelAlign ||
      colon != old.colon ||
      requiredMark != old.requiredMark ||
      disabled != old.disabled ||
      trigger != old.trigger ||
      style != old.style;
}

/// One field of a [Form]: a label, a control, and whatever the rules have to
/// say about it.
///
/// The control is built by [builder] rather than handed over as a widget,
/// because a form has to put the value *into* it and take changes back out,
/// and Flutter has no way to reach into a widget somebody else built.
class FormItem<T> extends StatefulWidget {
  /// Creates a [FormItem].
  const FormItem({
    super.key,
    required this.name,
    required this.builder,
    this.label,
    this.rules = const [],
    this.initialValue,
    this.help,
    this.extra,
    this.required,
    this.trigger,
    this.disabled,
  });

  /// What this field is called in the form's values.
  final String name;

  /// Builds the control, given what the field holds and what may be done.
  final Widget Function(FormFieldHandle<T> field) builder;

  /// What stands beside or above the control.
  final Widget? label;

  /// What the value has to satisfy.
  final List<FormRule> rules;

  /// What the field starts with, where the form was told nothing about it.
  final T? initialValue;

  /// A word under the field, in place of whatever the rules would say.
  ///
  /// Given one, the field shows this and never a rule's message — for a form
  /// whose messages come from somewhere else entirely, a server say.
  final String? help;

  /// A word under the field, beside whatever the rules say rather than in
  /// place of it: a hint about what to enter.
  final Widget? extra;

  /// Whether to mark the field as one that must be answered.
  ///
  /// Worked out from the rules where nothing is said, so a field with a
  /// `FormRule.required()` is marked without being told twice.
  final bool? required;

  /// When this field's rules are asked, where it differs from the form's.
  final FormTrigger? trigger;

  /// Bars this field alone.
  final bool? disabled;

  /// A field of words, drawn with [Input].
  ///
  /// A static method rather than a named constructor: a constructor of
  /// `FormItem<T>` cannot fix what `T` is — it would still be inferred from
  /// the call site and land on `Object?` — where a static one names the type
  /// outright and hands it back settled.
  static FormItem<String> text({
    Key? key,
    required String name,
    Widget? label,
    List<FormRule> rules = const [],
    String? initialValue,
    String? help,
    Widget? extra,
    bool? required,
    FormTrigger? trigger,
    bool? disabled,
    String? placeholder,
    PasswordConfig? password,
    Widget? prefix,
    Widget? suffix,
    int? maxLines,
    ValueChanged<String>? onSubmitted,
  }) =>
      FormItem<String>(
        key: key,
        name: name,
        label: label,
        rules: rules,
        initialValue: initialValue,
        help: help,
        extra: extra,
        required: required,
        trigger: trigger,
        disabled: disabled,
        builder: (field) => Input(
          value: field.value ?? '',
          status: field.status,
          disabled: field.disabled,
          placeholder: placeholder,
          password: password,
          prefix: prefix,
          suffix: suffix,
          maxLines: maxLines,
          onSubmitted: onSubmitted,
          onChanged: field.didChange,
        ),
      );

  /// A field of numbers, drawn with [InputNumber].
  static FormItem<num> number({
    Key? key,
    required String name,
    Widget? label,
    List<FormRule> rules = const [],
    num? initialValue,
    String? help,
    Widget? extra,
    bool? required,
    FormTrigger? trigger,
    bool? disabled,
    num? min,
    num? max,
    num step = 1,
    int? precision,
    String? placeholder,
  }) =>
      FormItem<num>(
        key: key,
        name: name,
        label: label,
        rules: rules,
        initialValue: initialValue,
        help: help,
        extra: extra,
        required: required,
        trigger: trigger,
        disabled: disabled,
        builder: (field) => InputNumber(
          value: field.value,
          status: field.status,
          disabled: field.disabled,
          min: min,
          max: max,
          step: step,
          precision: precision,
          placeholder: placeholder,
          onChanged: field.didChange,
        ),
      );

  /// A field that is ticked or not, drawn with [Checkbox].
  static FormItem<bool> check({
    Key? key,
    required String name,
    Widget? label,
    Widget? title,
    List<FormRule> rules = const [],
    bool? initialValue,
    String? help,
    Widget? extra,
    bool? required,
    FormTrigger? trigger,
    bool? disabled,
  }) =>
      FormItem<bool>(
        key: key,
        name: name,
        label: label,
        rules: rules,
        initialValue: initialValue,
        help: help,
        extra: extra,
        required: required,
        trigger: trigger,
        disabled: disabled,
        builder: (field) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: Checkbox(
            checked: field.value ?? false,
            disabled: field.disabled,
            label: title,
            onChanged: field.didChange,
          ),
        ),
      );

  /// A field that is on or off, drawn with [Switch].
  static FormItem<bool> toggle({
    Key? key,
    required String name,
    Widget? label,
    List<FormRule> rules = const [],
    bool? initialValue,
    String? help,
    Widget? extra,
    bool? required,
    FormTrigger? trigger,
    bool? disabled,
    Widget? checkedChild,
    Widget? uncheckedChild,
  }) =>
      FormItem<bool>(
        key: key,
        name: name,
        label: label,
        rules: rules,
        initialValue: initialValue,
        help: help,
        extra: extra,
        required: required,
        trigger: trigger,
        disabled: disabled,
        builder: (field) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: Switch(
            value: field.value ?? false,
            disabled: field.disabled,
            checkedChild: checkedChild,
            uncheckedChild: uncheckedChild,
            onChanged: field.didChange,
          ),
        ),
      );

  /// A field holding a date, drawn with [DatePicker].
  static FormItem<DateTime> date({
    Key? key,
    required String name,
    Widget? label,
    List<FormRule> rules = const [],
    DateTime? initialValue,
    String? help,
    Widget? extra,
    bool? required,
    FormTrigger? trigger,
    bool? disabled,
    DateTime? minDate,
    DateTime? maxDate,
    String format = 'yyyy-MM-dd',
    String? placeholder,
  }) =>
      FormItem<DateTime>(
        key: key,
        name: name,
        label: label,
        rules: rules,
        initialValue: initialValue,
        help: help,
        extra: extra,
        required: required,
        trigger: trigger,
        disabled: disabled,
        builder: (field) => DatePicker(
          value: field.value,
          status: field.status,
          disabled: field.disabled,
          minDate: minDate,
          maxDate: maxDate,
          format: format,
          placeholder: placeholder,
          onChanged: field.didChange,
        ),
      );

  /// A field holding a time of day, drawn with [TimePicker].
  static FormItem<Duration> time({
    Key? key,
    required String name,
    Widget? label,
    List<FormRule> rules = const [],
    Duration? initialValue,
    String? help,
    Widget? extra,
    bool? required,
    FormTrigger? trigger,
    bool? disabled,
    String format = 'HH:mm:ss',
    String? placeholder,
  }) =>
      FormItem<Duration>(
        key: key,
        name: name,
        label: label,
        rules: rules,
        initialValue: initialValue,
        help: help,
        extra: extra,
        required: required,
        trigger: trigger,
        disabled: disabled,
        builder: (field) => TimePicker(
          value: field.value,
          status: field.status,
          disabled: field.disabled,
          format: format,
          placeholder: placeholder,
          onChanged: field.didChange,
        ),
      );

  /// A field holding one choice, drawn with [Select].
  ///
  /// A `Select` holds a list whatever its mode, so this unwraps it: the field
  /// is of the value's own type, and the list is the control's business
  /// rather than the form's.
  static FormItem<V> select<V>({
    Key? key,
    required String name,
    required List<SelectOption<V>> options,
    Widget? label,
    List<FormRule> rules = const [],
    V? initialValue,
    String? help,
    Widget? extra,
    bool? required,
    FormTrigger? trigger,
    bool? disabled,
    String? placeholder,
    bool showSearch = false,
    bool allowClear = false,
  }) =>
      FormItem<V>(
        key: key,
        name: name,
        label: label,
        rules: rules,
        initialValue: initialValue,
        help: help,
        extra: extra,
        required: required,
        trigger: trigger,
        disabled: disabled,
        builder: (field) => Select<V>(
          value: [if (field.value != null) field.value as V],
          status: field.status == null ? null : SelectStatus.error,
          disabled: field.disabled,
          options: options,
          placeholder: placeholder,
          showSearch: showSearch,
          allowClear: allowClear,
          onChanged: (chosen) => field.didChange(chosen.firstOrNull),
        ),
      );

  /// A field holding several choices, drawn with [Select].
  static FormItem<List<V>> selectMany<V>({
    Key? key,
    required String name,
    required List<SelectOption<V>> options,
    Widget? label,
    List<FormRule> rules = const [],
    List<V>? initialValue,
    String? help,
    Widget? extra,
    bool? required,
    FormTrigger? trigger,
    bool? disabled,
    String? placeholder,
    bool showSearch = false,
    bool allowClear = false,
  }) =>
      FormItem<List<V>>(
        key: key,
        name: name,
        label: label,
        rules: rules,
        initialValue: initialValue,
        help: help,
        extra: extra,
        required: required,
        trigger: trigger,
        disabled: disabled,
        builder: (field) => Select<V>(
          value: field.value ?? const [],
          status: field.status == null ? null : SelectStatus.error,
          disabled: field.disabled,
          mode: SelectMode.multiple,
          options: options,
          placeholder: placeholder,
          showSearch: showSearch,
          allowClear: allowClear,
          onChanged: field.didChange,
        ),
      );

  /// A field holding one of a few choices, drawn with [RadioGroup].
  static FormItem<V> radio<V>({
    Key? key,
    required String name,
    required List<RadioOption<V>> options,
    Widget? label,
    List<FormRule> rules = const [],
    V? initialValue,
    String? help,
    Widget? extra,
    bool? required,
    FormTrigger? trigger,
    bool? disabled,
    Axis? direction,
    RadioOptionType? optionType,
  }) =>
      FormItem<V>(
        key: key,
        name: name,
        label: label,
        rules: rules,
        initialValue: initialValue,
        help: help,
        extra: extra,
        required: required,
        trigger: trigger,
        disabled: disabled,
        builder: (field) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: RadioGroup<V>(
            value: field.value,
            disabled: field.disabled,
            options: options,
            direction: direction,
            optionType: optionType,
            onChanged: field.didChange,
          ),
        ),
      );

  /// A field holding a number chosen by dragging, drawn with [Slider].
  static FormItem<double> slider({
    Key? key,
    required String name,
    Widget? label,
    List<FormRule> rules = const [],
    double? initialValue,
    String? help,
    Widget? extra,
    bool? required,
    FormTrigger? trigger,
    bool? disabled,
    double min = 0,
    double max = 100,
    double step = 1,
    List<SliderMark> marks = const [],
  }) =>
      FormItem<double>(
        key: key,
        name: name,
        label: label,
        rules: rules,
        initialValue: initialValue,
        help: help,
        extra: extra,
        required: required,
        trigger: trigger,
        disabled: disabled,
        builder: (field) => Slider(
          value: field.value ?? min,
          disabled: field.disabled,
          min: min,
          max: max,
          step: step,
          marks: marks,
          onChanged: field.didChange,
        ),
      );

  @override
  State<FormItem<T>> createState() => _FormItemState<T>();
}

class _FormItemState<T> extends State<FormItem<T>> implements _Field {
  _FormScope? _scope;
  String? _error;
  String? _warning;
  bool _asked = false;

  @override
  Object? get initialValue => widget.initialValue;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = Form._scopeOf(context);
    if (identical(scope.controller, _scope?.controller)) {
      _scope = scope;
      return;
    }
    _scope?.controller._unregister(widget.name, this);
    _scope = scope;
    scope.controller._register(widget.name, this);
  }

  @override
  void dispose() {
    _scope?.controller._unregister(widget.name, this);
    super.dispose();
  }

  FormTrigger get _trigger => widget.trigger ?? _scope!.trigger;

  bool get _disabled => widget.disabled ?? _scope!.disabled;

  bool get _demanded =>
      widget.required ?? widget.rules.any((rule) => rule._demands);

  /// Which run of the rules is the current one.
  ///
  /// A rule may take its time — asking a server, say — and two runs started
  /// on two keystrokes can finish in either order. Without this the slower
  /// answer, about a value the reader has already changed, lands last and
  /// stands: measured, a field showed 'taken' about a name that was no longer
  /// in the box.
  int _run = 0;

  @override
  Future<bool> validate() async {
    // A barred field is not being asked, so its rules have no standing: a
    // required one the reader cannot type into would refuse the form for
    // ever, pointing at a box they are not allowed to touch.
    if (_disabled) {
      _scope!.controller._report(widget.name);
      if (mounted && (_error != null || _warning != null)) {
        setState(() {
          _error = null;
          _warning = null;
        });
      }
      return true;
    }
    final mine = ++_run;
    final words = context.seedLocale;
    final value = _scope!.controller._values[widget.name];
    String? error;
    String? warning;
    for (final rule in widget.rules) {
      final said = await rule._test(value, words);
      if (said == null) continue;
      if (rule.warningOnly) {
        warning ??= said;
      } else {
        error = said;
        // The first refusal is the one worth reading; a field that lists
        // everything wrong with a value at once reads as scolding.
        break;
      }
    }
    // Nothing to say if the reader has moved on: a later run is already
    // asking about a later value, and it has the last word.
    if (mine != _run) return error == null;
    _scope!.controller._report(widget.name, error: error, warning: warning);
    _asked = true;
    if (mounted && (error != _error || warning != _warning)) {
      setState(() {
        _error = error;
        _warning = warning;
      });
    } else {
      _error = error;
      _warning = warning;
    }
    return error == null;
  }

  void _didChange(T? value) {
    final scope = _scope!;
    scope.controller._values[widget.name] = value;
    scope.controller._touched.add(widget.name);
    scope.onValuesChanged?.call(widget.name, scope.controller.values);
    // Once a field has been told off it is checked again as it is typed in,
    // whatever the trigger says: leaving a red border under a value that has
    // just been put right is the form arguing with the reader.
    if (_trigger == FormTrigger.change || _asked) {
      unawaited(validate().then((_) {
        if (mounted) scope.controller._announce();
      }));
    } else {
      scope.controller._announce();
    }
  }

  void _didLeave() {
    if (_trigger == FormTrigger.blur) unawaited(validate());
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope!;
    final t = context.softToken;
    final r = scope.style;

    return AnimatedBuilder(
      animation: scope.controller,
      builder: (context, _) {
        final control = Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (has) {
            if (!has) _didLeave();
          },
          child: widget.builder(
            FormFieldHandle<T>(
              value: scope.controller._values[widget.name] as T?,
              error: widget.help == null ? _error : null,
              warning: _warning,
              disabled: _disabled,
              didChange: _didChange,
              validate: validate,
            ),
          ),
        );

        final message = widget.help ?? _error ?? _warning;
        final under = message == null && widget.extra == null
            ? null
            : Padding(
                padding: EdgeInsets.only(top: r.messageGap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message != null)
                      Text(
                        message,
                        style: TextStyle(
                          color: widget.help != null
                              ? r.extraColor
                              : (_error != null
                                  ? r.errorColor
                                  : r.warningColor),
                          fontSize: r.messageFontSize,
                        ),
                      ),
                    if (widget.extra != null)
                      DefaultTextStyle.merge(
                        style: TextStyle(
                          color: r.extraColor,
                          fontSize: r.messageFontSize,
                        ),
                        child: widget.extra!,
                      ),
                  ],
                ),
              );

        final label = _label(scope, r, t);
        final beside = scope.layout != FormLayout.vertical && label != null;

        final field = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [control, if (under != null) under],
        );

        final inline = scope.layout == FormLayout.inline;
        final body = beside
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The label is centred against the *control*, not against
                  // the control and whatever is written under it: a message
                  // appearing would otherwise drag the label down the row.
                  // Centred rather than reckoned from font metrics, which
                  // left the two a pixel or so apart — and by the row's own
                  // alignment rather than an `IntrinsicHeight`, which asks
                  // its children how tall they would like to be and every
                  // control built on a `LayoutBuilder` refuses to say.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: inline ? MainAxisSize.min : MainAxisSize.max,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.only(end: r.labelGap),
                        child: SizedBox(
                          width: scope.labelWidth,
                          child: label,
                        ),
                      ),
                      // Flexible even where the row shrink-wraps: a `Row`
                      // hands a child that carries no flex an *unbounded*
                      // width along its main axis, and a control that fills
                      // what it is given cannot lay itself out in infinity.
                      // Loose rather than tight, so an inline form is still
                      // as wide as its fields rather than as wide as the
                      // page.
                      if (inline)
                        Flexible(child: control)
                      else
                        Expanded(child: control),
                    ],
                  ),
                  if (under != null)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: (scope.labelWidth ?? 0) + r.labelGap,
                      ),
                      child: under,
                    ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: r.labelGap),
                      child: label,
                    ),
                  field,
                ],
              );

        return Padding(
          padding: EdgeInsets.only(bottom: r.itemGap),
          child: body,
        );
      },
    );
  }

  /// The label, its mark, and its colon.
  Widget? _label(_FormScope scope, _ResolvedFormToken r, Token t) {
    if (widget.label == null) return null;
    final mark = scope.requiredMark;
    final words = context.seedLocale;
    return DefaultTextStyle.merge(
      style: TextStyle(color: r.labelColor, fontSize: r.labelFontSize),
      textAlign: scope.labelAlign,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_demanded && mark == FormRequiredMark.required) ...[
            Text(
              '*',
              style: TextStyle(color: r.errorColor, fontSize: r.labelFontSize),
            ),
            SizedBox(width: t.sizeXXS),
          ],
          Flexible(child: widget.label!),
          if (scope.colon) const Text(':'),
          if (!_demanded && mark == FormRequiredMark.optional) ...[
            SizedBox(width: t.sizeXXS),
            // Flexible as well as the label: in a column narrow enough to be
            // worth naming a width for, the label and this word together are
            // easily more than there is room for, and a mark that pushed the
            // row past its column would be worse than no mark.
            Flexible(
              child: Text(
                words.formOptional,
                style: TextStyle(
                  color: r.extraColor,
                  fontSize: r.messageFontSize,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Per-component design tokens for [Form].
///
/// Every field is an override; a null one falls back to the value derived
/// from the global theme.
@immutable
class FormToken {
  /// Creates a [FormToken].
  const FormToken({
    this.labelColor,
    this.labelFontSize,
    this.errorColor,
    this.warningColor,
    this.extraColor,
    this.messageFontSize,
    this.labelGap,
    this.messageGap,
    this.itemGap,
  });

  /// The colour of a field's label.
  final Color? labelColor;

  /// How big a label's words are.
  final double? labelFontSize;

  /// The colour of a message that refuses a value, and of the required mark.
  final Color? errorColor;

  /// The colour of a message that only cautions.
  final Color? warningColor;

  /// The colour of a hint, and of the word marking a field as optional.
  final Color? extraColor;

  /// How big a message under a field is.
  final double? messageFontSize;

  /// The gap between a label and what it labels.
  final double? labelGap;

  /// The gap between a control and the message under it.
  final double? messageGap;

  /// The gap between one field and the next.
  final double? itemGap;

  _ResolvedFormToken _resolve(Token t) => _ResolvedFormToken(
        labelColor: labelColor ?? t.colorText,
        labelFontSize: labelFontSize ?? t.fontSize,
        errorColor: errorColor ?? t.error.base,
        warningColor: warningColor ?? t.warning.base,
        extraColor: extraColor ?? t.colorTextTertiary,
        messageFontSize: messageFontSize ?? t.fontSizeSM,
        labelGap: labelGap ?? t.sizeXS,
        messageGap: messageGap ?? t.sizeXXS,
        itemGap: itemGap ?? t.size,
      );
}

@immutable
class _ResolvedFormToken {
  const _ResolvedFormToken({
    required this.labelColor,
    required this.labelFontSize,
    required this.errorColor,
    required this.warningColor,
    required this.extraColor,
    required this.messageFontSize,
    required this.labelGap,
    required this.messageGap,
    required this.itemGap,
  });

  final Color labelColor;
  final double labelFontSize;
  final Color errorColor;
  final Color warningColor;
  final Color extraColor;
  final double messageFontSize;
  final double labelGap;
  final double messageGap;
  final double itemGap;

  @override
  bool operator ==(Object other) =>
      other is _ResolvedFormToken &&
      other.labelColor == labelColor &&
      other.labelFontSize == labelFontSize &&
      other.errorColor == errorColor &&
      other.warningColor == warningColor &&
      other.extraColor == extraColor &&
      other.messageFontSize == messageFontSize &&
      other.labelGap == labelGap &&
      other.messageGap == messageGap &&
      other.itemGap == itemGap;

  @override
  int get hashCode => Object.hash(
        labelColor,
        labelFontSize,
        errorColor,
        warningColor,
        extraColor,
        messageFontSize,
        labelGap,
        messageGap,
        itemGap,
      );
}
