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

/// A rule that may look at the rest of the form as well as its own value.
///
/// [values] is every value the form holds, by field name, so a rule about two
/// fields — a confirmation, an end that must follow a start — can be written
/// where it belongs rather than reached for through a controller held outside.
typedef FormCrossValidator = FutureOr<String?> Function(
  Object? value,
  Map<String, Object?> values,
);

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
    FormCrossValidator? crossValidator,
    String? other,
  })  : _count = count,
        _pattern = pattern,
        _validator = validator,
        _crossValidator = crossValidator,
        _other = other;

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
  /// The value has to be the same as another field's.
  ///
  /// The everyday dependent rule — a password confirmed, an email typed
  /// twice. Name the field it must match in [FormItem.dependsOn] too, or the
  /// message will stand until this field is touched again.
  const FormRule.matches(String other,
      {String? message, bool warningOnly = false})
      : this._(_Check.matches,
            message: message, warningOnly: warningOnly, other: other);

  /// A rule of your own that may read the whole form.
  const FormRule.against(FormCrossValidator validator,
      {String? message, bool warningOnly = false})
      : this._(_Check.against,
            message: message,
            warningOnly: warningOnly,
            crossValidator: validator);

  /// A rule of your own: anything that can say what is wrong, or nothing.
  const FormRule.custom(FormValidator validator,
      {String? message, bool warningOnly = false})
      : this._(_Check.custom,
            validator: validator, message: message, warningOnly: warningOnly);

  final _Check _check;
  final int _count;
  final RegExp? _pattern;
  final FormValidator? _validator;
  final FormCrossValidator? _crossValidator;

  /// The field this one is measured against, for a rule that compares.
  final String? _other;

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
  /// Whether this rule needs the rest of the form to answer.
  bool get _crosses => _check == _Check.matches || _check == _Check.against;

  FutureOr<String?> _test(
    Object? value,
    Map<String, Object?> values,
    SeedLocalizations words,
  ) {
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
      case _Check.matches:
        // Two empties are the same as each other, and an empty box is
        // `required`'s business rather than this rule's.
        final theirs = values[_other!];
        final mine = value;
        final bothEmpty = _blank(mine) && _blank(theirs);
        if (bothEmpty || mine == theirs) return null;
        return message ?? words.formMismatch;
      case _Check.against:
        return _crossValidator!(value, values);
    }
  }

  static bool _blank(Object? value) =>
      value == null || (value is String && value.isEmpty);

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

enum _Check {
  required,
  min,
  max,
  pattern,
  email,
  url,
  custom,
  matches,
  against
}

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
    this.semanticsLabel,
  });

  /// What the field holds now.
  final T? value;

  /// What is wrong with it, if anything.
  final String? error;

  /// What is questionable about it — a rule that only warns.
  final String? warning;

  /// Whether the field is barred from being changed.
  final bool disabled;

  /// What a screen reader should call the control, taken from the field's
  /// own [FormItem.label] where that label is words.
  ///
  /// A label written beside a box is not part of the box: a reader hearing
  /// "text field" and nothing else has to guess which one it is. Hand this to
  /// whatever you build — `Input`, `Select` and the pickers all take a
  /// `semanticsLabel` — and the field says its name.
  final String? semanticsLabel;

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

  /// The rows of every repeating field, in the order they stand.
  ///
  /// A row is known by a key of its own, never by its place. Naming a row's
  /// fields after its index looks tidy until a row in the middle is taken
  /// out: every row below it is renumbered, and the values slide up into the
  /// names the rows above them were using. Keys do not move, so a removal
  /// removes exactly one row's worth of anything.
  final Map<String, List<Object>> _rows = {};
  int _nextRow = 0;

  /// The rows of one repeating field.
  List<Object> _rowsOf(String name) => _rows[name] ??= [];

  Object _freshRow() => '#${_nextRow++}';

  /// Puts a row in, at [at] or at the end, and hands back its key.
  Object _addRow(String name, {int? at, Object? seed}) {
    final rows = _rowsOf(name);
    final key = _freshRow();
    rows.insert(at == null ? rows.length : at.clamp(0, rows.length), key);
    if (seed != null) _values['$name.$key'] = seed;
    notifyListeners();
    return key;
  }

  /// Takes a row out, and everything it was holding with it.
  void _removeRow(String name, Object key) {
    if (!_rowsOf(name).remove(key)) return;
    final prefix = '$name.$key';
    for (final held in [
      for (final k in _values.keys)
        if (k == prefix || k.startsWith('$prefix.')) k,
    ]) {
      _values.remove(held);
      _errors.remove(held);
      _warnings.remove(held);
      _touched.remove(held);
    }
    notifyListeners();
  }

  /// Moves a row, carrying what it holds — which costs nothing, since what
  /// it holds is filed under its key and the key is what moves.
  void _moveRow(String name, int from, int to) {
    final rows = _rowsOf(name);
    if (from < 0 || from >= rows.length) return;
    final key = rows.removeAt(from);
    rows.insert(to.clamp(0, rows.length), key);
    notifyListeners();
  }

  /// Called by the form it is handed to, so `submit` can put the keyboard
  /// away before it starts.
  VoidCallback? _onSubmitStart;

  /// Called by the form it is handed to, so `submit` can do what the form's
  /// own `onFinish` would.
  void Function(Map<String, Object?> values)? _onFinish;
  void Function(Map<String, Object?> values, Map<String, String> errors)?
      _onFinishFailed;

  /// Every value the form holds, by field name.
  ///
  /// A repeating field comes out as a list, in the order its rows stand: the
  /// flat names are how the form keeps them, not how anybody reading the
  /// values should have to think about them.
  Map<String, Object?> get values {
    if (_rows.isEmpty) return Map.unmodifiable(_values);
    final out = <String, Object?>{};
    final claimed = <String>{};
    for (final entry in _rows.entries) {
      final name = entry.key;
      out[name] = [
        for (final key in entry.value) _rowValue('$name.$key', claimed),
      ];
    }
    for (final held in _values.entries) {
      if (claimed.contains(held.key)) continue;
      if (_rows.containsKey(held.key)) continue;
      out[held.key] = held.value;
    }
    return Map.unmodifiable(out);
  }

  /// What one row of a repeating field holds: the value filed under the row
  /// itself where the row is a single field, and a map of its parts where it
  /// has several.
  Object? _rowValue(String prefix, Set<String> claimed) {
    if (_values.containsKey(prefix)) {
      claimed.add(prefix);
      return _values[prefix];
    }
    final under = <String, Object?>{};
    for (final held in _values.entries) {
      if (!held.key.startsWith('$prefix.')) continue;
      claimed.add(held.key);
      under[held.key.substring(prefix.length + 1)] = held.value;
    }
    return under.isEmpty ? null : under;
  }

  /// The rows of a repeating field, for a rule that counts them.
  List<Object?> listValue(String name) {
    final claimed = <String>{};
    return [for (final key in _rowsOf(name)) _rowValue('$name.$key', claimed)];
  }

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
    _echo(name);
    notifyListeners();
  }

  /// Sets several at once.
  void setValues(Map<String, Object?> values) {
    _values.addAll(values);
    for (final name in values.keys) {
      _echo(name);
    }
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
    _rows.clear();
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

  /// Asks again every field that leans on [changed].
  ///
  /// A rule about two fields is stale the moment either of them moves, and
  /// the one holding the message is usually the one nobody is touching:
  /// change a password and the confirmation below it still says they differ.
  /// Only fields that have already been asked, so a form nobody has answered
  /// stays quiet.
  void _echo(String changed) {
    for (final entry in _fields.entries.toList()) {
      if (entry.key == changed) continue;
      final field = entry.value;
      if (!field.dependsOn.contains(changed)) continue;
      if (!field.asked) continue;
      unawaited(field.validate().then((_) => notifyListeners()));
    }
  }

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

  /// The fields this one is measured against.
  List<String> get dependsOn;

  /// Whether this field has been asked its rules yet.
  ///
  /// A field that has never been asked is not asked because its neighbour
  /// moved: a form nobody has submitted would light up red around a box the
  /// reader has not reached.
  bool get asked;
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
    this.maxWidth,
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

  /// How wide the form is allowed to run.
  ///
  /// A form fills what it is given, and what a wide page gives it is the whole
  /// window — a line of boxes a thousand pixels long, with one word in each
  /// and the eye travelling the rest. Naming a width caps the form and leaves
  /// it against the leading edge; the page around it stays as wide as it
  /// likes.
  ///
  /// Null fills the parent, which is right where the parent has a width of
  /// its own already.
  final double? maxWidth;

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
      // Against the leading edge rather than centred: a form is read down its
      // left-hand side, and one floated into the middle of a wide page leaves
      // the labels nowhere in particular. `Align` rather than `SizedBox`, so
      // a narrow window still gets the whole of what it has.
      child: widget.maxWidth == null
          ? widget.child
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxWidth!),
                child: widget.child,
              ),
            ),
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

/// One row of a repeating field.
///
/// A row is known by a key handed out when it was added, never by where it
/// stands. Its fields are named after that key, so taking a row out of the
/// middle leaves every other row's values exactly where they were.
@immutable
class FormListEntry {
  const FormListEntry._(this._list, this.key, this.index);

  final String _list;

  /// What this row is known by, for as long as it stands.
  ///
  /// Use it as the widget key of whatever you build for the row: a row built
  /// under its index keeps the state of the row that used to stand there.
  final Object key;

  /// Where the row stands now, counting from zero.
  final int index;

  /// The name of a row that is a single field.
  String get name => '$_list.$key';

  /// The name of one field inside a row that has several.
  String field(String part) => '$_list.$key.$part';

  @override
  bool operator ==(Object other) =>
      other is FormListEntry && other._list == _list && other.key == key;

  @override
  int get hashCode => Object.hash(_list, key);
}

/// What a repeating field is holding and what may be done to it.
class FormListHandle {
  const FormListHandle._({
    required this.entries,
    required this.error,
    required this.add,
    required this.addAt,
    required this.remove,
    required this.move,
  });

  /// The rows, in the order they stand.
  final List<FormListEntry> entries;

  /// What is wrong with the list itself — too few rows, say. What is wrong
  /// with a row is the row's own field's business.
  final String? error;

  /// Adds a row at the end, holding [seed] where the row is a single field.
  final void Function([Object? seed]) add;

  /// Adds a row at a given place — `addAt(0)` puts one at the head.
  final void Function(int at, [Object? seed]) addAt;

  /// Takes a row out, and everything it holds with it.
  final void Function(FormListEntry entry) remove;

  /// Moves a row, carrying what it holds.
  final void Function(int from, int to) move;
}

/// A field that repeats: a list of rows the reader adds to and takes from.
///
/// ```dart
/// FormList(
///   name: 'passengers',
///   initialCount: 1,
///   rules: [FormRule.min(2, message: 'Two passengers at least')],
///   builder: (context, list) => Column(
///     children: [
///       for (final row in list.entries)
///         Row(
///           key: ValueKey(row.key),
///           children: [
///             Expanded(child: FormItem.text(name: row.name)),
///             Button(
///               onPressed: () => list.remove(row),
///               child: const Text('Remove'),
///             ),
///           ],
///         ),
///       Button(onPressed: list.add, child: const Text('Add')),
///     ],
///   ),
/// )
/// ```
///
/// The rows come out of [FormController.values] as a list under [name], in
/// the order they stand. A row built of one field holds its value directly;
/// a row of several — `row.field('name')`, `row.field('age')` — comes out as
/// a map.
///
/// The list's own rules count the rows: `FormRule.min(2)` asks for two of
/// them. A rule about what is *in* a row belongs to that row's field.
class FormList extends StatefulWidget {
  /// Creates a [FormList].
  const FormList({
    super.key,
    required this.name,
    required this.builder,
    this.rules = const [],
    this.initialCount = 0,
    this.label,
    this.help,
    this.extra,
  });

  /// What the list is called in the form's values.
  final String name;

  /// Builds the rows, given what stands and what may be done.
  final Widget Function(BuildContext context, FormListHandle list) builder;

  /// What the list has to satisfy — how many rows, at least or at most.
  final List<FormRule> rules;

  /// How many rows a list nobody has touched begins with.
  ///
  /// A form told `initialValues` for this name begins with those instead: the
  /// count is what to do when there is nothing to go on.
  final int initialCount;

  /// What stands above the list.
  final Widget? label;

  /// A word under the list, in place of whatever the rules would say.
  final String? help;

  /// A word under the list, beside whatever the rules say.
  final Widget? extra;

  @override
  State<FormList> createState() => _FormListState();
}

class _FormListState extends State<FormList> implements _Field {
  _FormScope? _scope;
  String? _error;
  String? _warning;
  bool _seeded = false;

  // A list's rows are the list's value; there is nothing separate to start
  // it with.
  @override
  Object? get initialValue => null;

  // A list is not compared with anything, and it is asked whenever the form
  // is: there is no message of its own to leave standing.
  @override
  List<String> get dependsOn => const [];

  @override
  bool get asked => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = Form._scopeOf(context);
    if (!identical(scope.controller, _scope?.controller)) {
      _scope?.controller._unregister(widget.name, this);
      _scope = scope;
      scope.controller._register(widget.name, this);
    } else {
      _scope = scope;
    }
    _seed();
  }

  /// Fills a list nobody has said anything about.
  ///
  /// Whatever the form was told to start with comes first — a list of values
  /// under this name becomes a row each — and [FormList.initialCount] is the
  /// fallback for a list with nothing to go on. Done once: a rebuild is not
  /// a reason to put the rows back that the reader has just taken out.
  void _seed() {
    if (_seeded) return;
    _seeded = true;
    final controller = _scope!.controller;
    if (controller._rowsOf(widget.name).isNotEmpty) return;
    final told = controller._values[widget.name];
    if (told is List) {
      controller._values.remove(widget.name);
      for (final value in told) {
        _spread(controller, controller._addRow(widget.name), value);
      }
      return;
    }
    for (var i = 0; i < widget.initialCount; i++) {
      controller._addRow(widget.name);
    }
  }

  /// Files one row's starting value: straight under the row where it is a
  /// single value, and part by part where it is a map.
  void _spread(FormController controller, Object key, Object? value) {
    final prefix = '${widget.name}.$key';
    if (value is Map) {
      for (final part in value.entries) {
        controller._values['$prefix.${part.key}'] = part.value;
      }
      return;
    }
    if (value != null) controller._values[prefix] = value;
  }

  @override
  void dispose() {
    _scope?.controller._unregister(widget.name, this);
    super.dispose();
  }

  @override
  Future<bool> validate() async {
    final controller = _scope!.controller;
    final words = context.seedLocale;
    final value = controller.listValue(widget.name);
    String? error;
    String? warning;
    for (final rule in widget.rules) {
      final said = await rule._test(value, controller.values, words);
      if (said == null) continue;
      if (rule.warningOnly) {
        warning ??= said;
      } else {
        error = said;
        break;
      }
    }
    controller._report(widget.name, error: error, warning: warning);
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

  @override
  Widget build(BuildContext context) {
    final scope = _scope!;
    final r = scope.style;

    return AnimatedBuilder(
      animation: scope.controller,
      builder: (context, _) {
        final controller = scope.controller;
        final keys = controller._rowsOf(widget.name);
        final handle = FormListHandle._(
          entries: [
            for (var i = 0; i < keys.length; i++)
              FormListEntry._(widget.name, keys[i], i),
          ],
          error: widget.help == null ? _error : null,
          add: ([Object? seed]) => controller._addRow(widget.name, seed: seed),
          addAt: (int at, [Object? seed]) =>
              controller._addRow(widget.name, at: at, seed: seed),
          remove: (entry) => controller._removeRow(widget.name, entry.key),
          move: (from, to) => controller._moveRow(widget.name, from, to),
        );

        final message = widget.help ?? _error ?? _warning;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null)
              DefaultTextStyle.merge(
                style: TextStyle(
                  color: r.labelColor,
                  fontSize: r.labelFontSize,
                ),
                child: widget.label!,
              ),
            widget.builder(context, handle),
            if (message != null || widget.extra != null)
              Padding(
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
              ),
          ],
        );
      },
    );
  }
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
    this.dependsOn = const [],
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

  /// The fields this one is measured against.
  ///
  /// A rule comparing two fields is stale the moment either moves, and the
  /// message is usually on the field nobody is touching — change a password
  /// and the confirmation under it still says they differ. Naming what this
  /// field leans on has it asked again whenever one of them changes.
  ///
  /// Only once this field has been asked at least once, so a form nobody has
  /// answered does not light up around a box the reader has not reached.
  ///
  /// ```dart
  /// FormItem.text(
  ///   name: 'confirm',
  ///   dependsOn: const ['password'],
  ///   rules: const [FormRule.matches('password')],
  /// )
  /// ```
  final List<String> dependsOn;

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
    List<String> dependsOn = const [],
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
        dependsOn: dependsOn,
        disabled: disabled,
        builder: (field) => Input(
          value: field.value ?? '',
          status: field.status,
          disabled: field.disabled,
          semanticsLabel: field.semanticsLabel,
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
    List<String> dependsOn = const [],
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
        dependsOn: dependsOn,
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
    List<String> dependsOn = const [],
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
        dependsOn: dependsOn,
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
    List<String> dependsOn = const [],
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
        dependsOn: dependsOn,
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
    List<String> dependsOn = const [],
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
        dependsOn: dependsOn,
        disabled: disabled,
        builder: (field) => DatePicker(
          semanticsLabel: field.semanticsLabel,
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
    List<String> dependsOn = const [],
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
        dependsOn: dependsOn,
        disabled: disabled,
        builder: (field) => TimePicker(
          semanticsLabel: field.semanticsLabel,
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
    List<String> dependsOn = const [],
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
        dependsOn: dependsOn,
        disabled: disabled,
        builder: (field) => Select<V>(
          semanticsLabel: field.semanticsLabel,
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
    List<String> dependsOn = const [],
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
        dependsOn: dependsOn,
        disabled: disabled,
        builder: (field) => Select<V>(
          semanticsLabel: field.semanticsLabel,
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
    List<String> dependsOn = const [],
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
        dependsOn: dependsOn,
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
    List<String> dependsOn = const [],
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
        dependsOn: dependsOn,
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
  List<String> get dependsOn => widget.dependsOn;

  @override
  bool get asked => _asked;

  /// Complains about a rule that compares without saying what it leans on.
  ///
  /// The rule works — it is asked, and it refuses — but its message goes
  /// stale the moment the other field moves, and the field holding it is the
  /// one nobody is touching. That is a hard thing to find by looking.
  void _checkDependencies() {
    assert(() {
      for (final rule in widget.rules) {
        if (!rule._crosses) continue;
        final other = rule._other;
        if (other == null || widget.dependsOn.contains(other)) continue;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          throw FlutterError(
            'The field "${widget.name}" has a rule measuring it against '
            '"$other", but does not name "$other" in dependsOn. Its message '
            'will stand until "${widget.name}" is touched again, however '
            '"$other" changes.',
          );
        });
      }
      return true;
    }());
  }

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
    _checkDependencies();
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
      final said = await rule._test(value, _scope!.controller.values, words);
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
    scope.controller._echo(widget.name);
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
              // Only where the label is words. A label built of widgets —
              // an icon and a phrase, a link — has no one string to read
              // out, and guessing at one would put half a label in a
              // reader's ear.
              semanticsLabel:
                  widget.label is Text ? (widget.label! as Text).data : null,
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
