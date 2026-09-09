import 'package:flutter/semantics.dart' show SemanticsValidationResult;
import 'package:flutter/services.dart'
    show KeyEvent, KeyUpEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../../l10n/seed_localizations.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/popover.dart';
import '../../utils/size_resolver.dart';
import '../../utils/time_columns.dart';
import '../../utils/time_format.dart';
import '../data_entry/input.dart' show InputStatus;
import '../data_entry/select.dart' show ClearIconPainter;
import '../general/compact.dart';

/// How a [TimePicker] is filled and bordered.
enum TimePickerVariant {
  /// A border, on the container background.
  outlined,

  /// A tinted fill and no border.
  filled,

  /// Neither fill nor border.
  borderless,
}

/// Defaults for every [TimePicker] under a `ConfigProvider`.
///
/// The picker's own props, not its [TimePickerToken] numbers.
@immutable
class TimePickerDefaults {
  /// Creates a [TimePickerDefaults].
  const TimePickerDefaults({
    this.variant,
    this.allowClear,
    this.showNow,
    this.needConfirm,
    this.size,
    this.disabled,
  });

  /// How pickers are filled and bordered.
  final TimePickerVariant? variant;

  /// Whether pickers carry a clear button once a time is set.
  final bool? allowClear;

  /// Whether the panel offers a jump to the current time.
  final bool? showNow;

  /// Whether a choice is only committed on OK.
  final bool? needConfirm;

  /// Which control height a [TimePicker] takes, unless it names one.
  ///
  /// Nearer than `ConfigProvider.componentSize`, so this wins where both
  /// are set: small buttons on an otherwise normal screen.
  final ControlSize? size;

  /// Whether a [TimePicker] is disabled, unless it says otherwise.
  ///
  /// Nearer than `ConfigProvider.componentDisabled`, and beaten in turn by
  /// the widget's own word.
  final bool? disabled;
}

/// Per-component design tokens for [TimePicker].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(timePicker: TimePickerToken(...)))`, or per instance via
/// [TimePicker.token].
@immutable
class TimePickerToken {
  /// Creates a [TimePickerToken].
  const TimePickerToken({
    this.borderRadius,
    this.cellHeight,
    this.columnWidth,
    this.visibleRows,
  });

  /// Corner radius of the field and the panel.
  final double? borderRadius;

  /// Height of one row in a column.
  final double? cellHeight;

  /// Width of one column.
  final double? columnWidth;

  /// How many rows the panel is tall.
  final int? visibleRows;

  _ResolvedTimePickerToken _resolve(Token t) => _ResolvedTimePickerToken(
        borderRadius: borderRadius ?? t.borderRadius,
        cellHeight: cellHeight ?? t.controlHeight - t.sizeXXS,
        columnWidth: columnWidth ?? t.controlHeightLG * 1.4,
        visibleRows: visibleRows ?? 8,
      );
}

@immutable
class _ResolvedTimePickerToken {
  const _ResolvedTimePickerToken({
    required this.borderRadius,
    required this.cellHeight,
    required this.columnWidth,
    required this.visibleRows,
  });

  final double borderRadius;
  final double cellHeight;
  final double columnWidth;
  final int visibleRows;
}

/// A field that collects a time of day.
///
/// ```dart
/// TimePicker(
///   value: _opensAt,
///   format: 'HH:mm',
///   onChanged: (time) => setState(() => _opensAt = time),
/// )
/// ```
///
/// The value is a [Duration] since midnight — the kit's convention, since Dart
/// has no time-of-day type outside Material, which this package is built
/// without. `Duration(hours: 9, minutes: 30)` is half past nine.
///
/// **The format decides the columns.** `'HH:mm'` shows hours and minutes and
/// hands back a value with no seconds in it; `'h:mm a'` shows a meridiem
/// column and reads as a 12-hour clock. A panel offering a column the format
/// would then discard would be collecting something it does not keep.
class TimePicker extends StatefulWidget {
  /// Creates a [TimePicker].
  const TimePicker({
    super.key,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.format = 'HH:mm:ss',
    this.hourStep = 1,
    this.minuteStep = 1,
    this.secondStep = 1,
    this.disabledTime,
    this.hideDisabledOptions = false,
    this.showNow,
    this.needConfirm,
    this.allowClear,
    this.disabled,
    this.size,
    this.variant,
    this.placeholder,
    this.semanticsLabel,
    this.placement = PopoverPlacement.bottomLeft,
    this.open,
    this.onOpenChange,
    this.inputReadOnly = false,
    this.status,
    this.prefix,
    this.suffixIcon,
    this.onClear,
    this.footerBuilder,
    this.token,
  })  : assert(hourStep > 0 && 24 % hourStep == 0,
            'hourStep must divide 24 evenly'),
        assert(minuteStep > 0 && 60 % minuteStep == 0,
            'minuteStep must divide 60 evenly'),
        assert(secondStep > 0 && 60 % secondStep == 0,
            'secondStep must divide 60 evenly');

  /// The time shown, as a duration since midnight.
  ///
  /// Null hands the picker to itself: it keeps what is chosen, starting from
  /// [defaultValue]. Supply this to drive it from outside instead.
  final Duration? value;

  /// What an uncontrolled picker starts with. Ignored when [value] is set.
  final Duration? defaultValue;

  /// Called with the chosen time, or null when it is cleared.
  final ValueChanged<Duration?>? onChanged;

  /// How the time is written, and so which columns the panel offers. See
  /// [TimeFields] for the grammar.
  final String format;

  /// Interval between the hours offered.
  final int hourStep;

  /// Interval between the minutes offered.
  final int minuteStep;

  /// Interval between the seconds offered.
  final int secondStep;

  /// Which times cannot be chosen.
  final DisabledTime? disabledTime;

  /// Whether unavailable values are hidden rather than greyed out.
  final bool hideDisabledOptions;

  /// Whether the panel offers a jump to the current time. Follows
  /// [TimePickerDefaults.showNow], else true.
  final bool? showNow;

  /// Whether a choice is only committed when OK is pressed.
  ///
  /// Null follows [TimePickerDefaults.needConfirm], and then the panel's own
  /// judgement: a panel with more than one column asks for confirmation, since
  /// a half-set time is not one the caller wants to hear about.
  final bool? needConfirm;

  /// Whether a clear button appears once a time is set.
  final bool? allowClear;

  /// Whether the field is disabled. Follows `ConfigProvider.componentDisabled`.
  final bool? disabled;

  /// Which control height to use. Follows `ConfigProvider.componentSize`.
  final ControlSize? size;

  /// How the field is filled and bordered.
  final TimePickerVariant? variant;

  /// Shown when there is no value. Null uses the locale's own words.
  final String? placeholder;

  /// What a screen reader calls the field.
  ///
  /// The placeholder names one that stands on its own; give this where the
  /// name is written outside it — a `Form` field's label, say.
  final String? semanticsLabel;

  /// Where the panel opens against the field.
  final PopoverPlacement placement;

  /// Whether the panel is open. Null lets the picker decide for itself.
  final bool? open;

  /// Called when the panel opens or closes.
  final ValueChanged<bool>? onOpenChange;

  /// Whether the field refuses typing, leaving the panel the only way in.
  final bool inputReadOnly;

  /// Marks the field as questionable or wrong.
  ///
  /// The same two states the kit's other fields carry, drawn the same way —
  /// see [InputStatus].
  final InputStatus? status;

  /// Sits before the value, inside the field.
  final Widget? prefix;

  /// Replaces the clock face on the trailing edge.
  final Widget? suffixIcon;

  /// Called when the clear button is pressed, after the value is dropped.
  final VoidCallback? onClear;

  /// Adds a row of your own beneath the panel's footer — a preset time, a
  /// note, whatever the screen needs.
  final WidgetBuilder? footerBuilder;

  /// Per-instance token overrides.
  final TimePickerToken? token;

  @override
  State<TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  final PopoverController _popover = PopoverController();

  /// Bumped whenever the panel's contents change. The panel is built into the
  /// overlay, a tree of its own, so `setState` here does not reach it.
  final ValueNotifier<int> _panelRevision = ValueNotifier<int>(0);
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();

  bool _open = false;
  bool _hovered = false;

  /// What an uncontrolled picker is holding. Unused once [TimePicker.value]
  /// is supplied.
  Duration? _internal;

  /// The time in force, whoever is keeping it.
  Duration? get _value => widget.value ?? _internal;

  /// What the panel is showing while it is being worked on. Committed to
  /// [TimePicker.onChanged] on OK, or immediately when no confirmation is
  /// asked for.
  Duration? _draft;

  TimeFields get _fields => TimeFields.of(widget.format);

  TimePickerDefaults? get _defaults =>
      ConfigProvider.defaultsOf<TimePickerDefaults>(context);

  bool get _disabled =>
      widget.disabled ??
      _defaults?.disabled ??
      ConfigProvider.componentDisabledOf(context) ??
      false;

  ControlSize get _size =>
      widget.size ??
      _defaults?.size ??
      ConfigProvider.componentSizeOf(context) ??
      SoftSize.middle;

  TimePickerVariant get _variant =>
      widget.variant ?? _defaults?.variant ?? TimePickerVariant.outlined;

  bool get _allowClear => widget.allowClear ?? _defaults?.allowClear ?? true;

  bool get _showNow => widget.showNow ?? _defaults?.showNow ?? true;

  /// More than one column means a half-set time is easy to land on, so the
  /// choice waits for OK unless told otherwise.
  bool get _needConfirm {
    final asked = widget.needConfirm ?? _defaults?.needConfirm;
    if (asked != null) return asked;
    final f = _fields;
    final columns = (f.hour ? 1 : 0) + (f.minute ? 1 : 0) + (f.second ? 1 : 0);
    return columns > 1;
  }

  bool get _enabled => !_disabled;

  @override
  void initState() {
    super.initState();
    _internal = widget.defaultValue;
    _focus.onKeyEvent = _onKey;
    _draft = _value;
    // Reports a layer that closed itself — an outside tap, a route change.
    // It must not close the layer again: it is already gone, and asking twice
    // takes the overlay entry out from under itself.
    // Born open: the same deferral, since the first build is a build too.
    if (widget.open ?? false) _obey(true);
    _popover.onClosed = () {
      if (!mounted || !_open) return;
      setState(() => _open = false);
      _syncText();
      widget.onOpenChange?.call(false);
    };
  }

  /// Opens or closes the panel after the frame.
  ///
  /// Mounting the overlay entry marks the Overlay as needing to build, and
  /// both callers reach here during a build — `didUpdateWidget` runs inside
  /// one, and so does the first frame. Doing it there throws.
  void _obey(bool open) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      open ? _openPanel() : _closePanel();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The text is written through the locale, which is an inherited lookup —
    // legal here, not in initState.
    if (!_focus.hasFocus) _syncText();
  }

  @override
  void didUpdateWidget(TimePicker old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || old.format != widget.format) {
      _draft = _value;
      _syncText();
    }
    if (widget.open != null && widget.open != old.open) {
      _obey(widget.open!);
    }
  }

  @override
  void dispose() {
    _popover.dispose();
    _panelRevision.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Value
  // --------------------------------------------------------------------------

  /// Writes the field from what the panel is showing.
  ///
  /// While the panel is open that is the draft, so a pick reads back at once
  /// even when the value itself waits for OK. Closing without confirming puts
  /// the committed value back.
  void _syncText() {
    final words = context.seedLocale;
    final value = _open ? (_draft ?? _value) : _value;
    final next = value == null
        ? ''
        : words.figures(
            formatTime(value, widget.format, am: words.am, pm: words.pm),
          );
    if (_text.text != next) _text.text = next;
  }

  /// Turns the locale's own figures back into plain digits.
  String _plainFigures(String text, SeedLocalizations words) {
    if (words.digits == SeedLocalizations.latinDigits) return text;
    final out = StringBuffer();
    for (final ch in text.split('')) {
      final at = words.digits.indexOf(ch);
      out.write(at >= 0 ? '$at' : ch);
    }
    return out.toString();
  }

  void _commit(Duration? time) {
    if (time == _value) return;
    if (widget.value == null) setState(() => _internal = time);
    widget.onChanged?.call(time);
  }

  /// Reads what was typed. An unreadable entry leaves the value alone rather
  /// than clearing it, so a stray keystroke cannot wipe a set time.
  void _onSubmitted(String text) {
    final words = context.seedLocale;
    if (text.trim().isEmpty) {
      _commit(null);
      _requestOpen(false);
      return;
    }
    // The field shows the locale's own figures, so they have to come back
    // to plain digits before the parser — which counts on ASCII — sees them.
    final plain = _plainFigures(text, words);
    final parsed = parseTime(plain, widget.format, am: words.am, pm: words.pm);
    if (parsed == null) {
      _syncText();
      return;
    }
    final settled = normalizeTime(parsed, _fields);
    if (_isDisabled(settled)) {
      _syncText();
      return;
    }
    setState(() => _draft = settled);
    _commit(settled);
    _requestOpen(false);
  }

  // --------------------------------------------------------------------------
  // Availability
  // --------------------------------------------------------------------------

  List<int> _blockedHours() => widget.disabledTime?.hours?.call() ?? const [];

  List<int> _blockedMinutes(int hour) =>
      widget.disabledTime?.minutes?.call(hour) ?? const [];

  List<int> _blockedSeconds(int hour, int minute) =>
      widget.disabledTime?.seconds?.call(hour, minute) ?? const [];

  bool _isDisabled(Duration time) {
    final h = time.inHours;
    final m = time.inMinutes % 60;
    final s = time.inSeconds % 60;
    if (_blockedHours().contains(h)) return true;
    if (_fields.minute && _blockedMinutes(h).contains(m)) return true;
    if (_fields.second && _blockedSeconds(h, m).contains(s)) return true;
    return false;
  }

  // --------------------------------------------------------------------------
  // Panel
  // --------------------------------------------------------------------------

  void _requestOpen(bool next) {
    if (next == _open) return;
    widget.onOpenChange?.call(next);
    if (widget.open == null) next ? _openPanel() : _closePanel();
  }

  void _openPanel() {
    if (_open || !_enabled) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    setState(() {
      _open = true;
      _draft = _value;
    });
    final token = context.softToken;
    _popover.open(
      placement: widget.placement,
      anchorRect: anchor,
      gap: token.sizeXXS,
      onDismiss: () => _requestOpen(false),
      dismissExcludesAnchor: true,
      anchorContext: context,
      onScrollDismiss: () => _requestOpen(false),
      builder: (context) => ListenableBuilder(
        listenable: _panelRevision,
        builder: (context, _) => _TimePanel(state: this),
      ),
    );
  }

  void _closePanel() {
    if (!_open) return;
    setState(() => _open = false);
    _popover.close();
    _syncText();
  }

  /// A column's choice. Commits straight away unless OK is being waited for.
  void _pick(Duration time) {
    setState(() => _draft = time);
    _panelRevision.value++;
    _syncText();
    if (!_needConfirm) {
      _commit(time);
      if (!_fields.minute && !_fields.second) _requestOpen(false);
    }
  }

  // --- the keyboard ---

  /// Which column the arrows step: hours, minutes or seconds, counted among
  /// the ones the format actually shows.
  int _unit = 0;

  /// The columns on show, biggest first.
  List<Duration> get _units => [
        if (_fields.hour) const Duration(hours: 1),
        if (_fields.minute) const Duration(minutes: 1),
        if (_fields.second) const Duration(seconds: 1),
      ];

  /// Steps the column the keyboard is on, wrapping within the day.
  ///
  /// A time is a ring, not a run: stepping back from midnight lands on the
  /// last hour of the same day rather than stopping, which is what every
  /// clock does and what the panel's own columns do.
  void _step(int delta) {
    final units = _units;
    if (units.isEmpty) return;
    final by = units[_unit.clamp(0, units.length - 1)] * delta;
    final from = _draft ?? _value ?? Duration.zero;
    var next = normalizeTime(from + by, _fields);
    for (var guard = 0; _isDisabled(next) && guard < 60; guard++) {
      next = normalizeTime(next + by, _fields);
    }
    if (_isDisabled(next)) return;
    _pick(next);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final ltr = Directionality.maybeOf(context) != TextDirection.rtl;

    if (!_open) {
      if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        if (!_enabled) return KeyEventResult.ignored;
        _requestOpen(true);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.escape) {
      _requestOpen(false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _confirm();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _step(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _step(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowLeft) {
      final onward = (key == LogicalKeyboardKey.arrowRight) == ltr;
      final units = _units;
      if (units.isEmpty) return KeyEventResult.handled;
      setState(() {
        _unit = (_unit + (onward ? 1 : -1)).clamp(0, units.length - 1);
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _confirm() {
    final draft = _draft;
    if (draft != null) _commit(draft);
    _requestOpen(false);
  }

  void _now() {
    final n = DateTime.now();
    final time = normalizeTime(
      Duration(hours: n.hour, minutes: n.minute, seconds: n.second),
      _fields,
    );
    setState(() => _draft = time);
    _panelRevision.value++;
    _syncText();
    if (!_needConfirm) {
      _commit(time);
      _requestOpen(false);
    }
  }

  void _clear() {
    setState(() => _draft = null);
    _text.clear();
    _commit(null);
    widget.onClear?.call();
  }

  // --------------------------------------------------------------------------
  // Building
  // --------------------------------------------------------------------------

  double _height(Token t) => _size.resolveHeight(
        small: t.controlHeightSM,
        middle: t.controlHeight,
        large: t.controlHeightLG,
      );

  /// A preset carries a type size of its own; a dimension names only
  /// itself, so the standard one stands.
  double _fontSize(Token t) =>
      _size == SoftSize.large ? t.fontSizeLG : t.fontSize;

  /// How wide the value area has to be, whatever the field is showing.
  ///
  /// The wider of two things, because the field shows both at different times
  /// and must not resize between them: the longest the format can render, and
  /// the placeholder that stands in until a time is chosen. Sizing to the
  /// figures alone cut the placeholder off with an ellipsis; sizing to the
  /// placeholder alone would make every picker as wide as the locale's own
  /// wording, since one is always supplied.
  ///
  /// A shorter placeholder is the lever for a narrower field.
  ///
  /// Measured with the widest digit the face draws, since a proportional font
  /// does not give every figure the same width.
  double _valueWidth(TextStyle style, SeedLocalizations words) {
    double widthOf(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      return painter.width;
    }

    var widest = '0';
    var widestWidth = 0.0;
    for (var d = 0; d < 10; d++) {
      final glyph = words.digit(d);
      final w = widthOf(glyph);
      if (w > widestWidth) {
        widestWidth = w;
        widest = glyph;
      }
    }

    // A time with every field at its longest, then every figure swapped for
    // the widest one the face has.
    final sample = words.figures(
      formatTime(
        const Duration(hours: 23, minutes: 58, seconds: 59),
        widget.format,
        am: words.am,
        pm: words.pm,
      ),
    );
    final padded = sample
        .split('')
        .map((ch) => words.digits.contains(ch) ? widest : ch)
        .join();

    final placeholder = widget.placeholder ?? words.selectTime;
    final figures = widthOf(padded);
    final hint = widthOf(placeholder);
    return figures > hint ? figures : hint;
  }

  void _syncAnchor() {
    if (!_open) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      _popover.reposition(box.localToGlobal(Offset.zero) & box.size);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final words = context.seedLocale;
    final r = (widget.token ??
            ConfigProvider.componentOf<TimePickerToken>(context) ??
            const TimePickerToken())
        ._resolve(t);
    _syncAnchor();

    final fontSize = _fontSize(t);
    final showClear = _allowClear && _enabled && _value != null && _hovered;

    final Color fill;
    if (!_enabled) {
      fill = t.colorFillTertiary;
    } else if (_variant == TimePickerVariant.filled) {
      fill = _hovered || _open ? t.colorFillSecondary : t.colorFillTertiary;
    } else if (_variant == TimePickerVariant.borderless) {
      fill = const Color(0x00000000);
    } else {
      fill = t.colorBgContainer;
    }

    final statusColor = switch (widget.status) {
      InputStatus.error => t.error.base,
      InputStatus.warning => t.warning.base,
      null => null,
    };

    final Color border;
    if (_variant != TimePickerVariant.outlined) {
      border = const Color(0x00000000);
    } else if (statusColor != null) {
      border = statusColor;
    } else if (!_enabled) {
      border = t.colorBorder;
    } else if (_open) {
      border = t.primary.base;
    } else if (_hovered) {
      border = t.primary.hover;
    } else {
      border = t.colorBorder;
    }

    final textStyle = TextStyle(
      color: _enabled ? t.colorText : t.colorTextQuaternary,
      fontSize: fontSize,
      fontFamily: t.fontFamily,
      fontFamilyFallback: t.fontFamilyFallback,
      height: 1.0,
      // Pin the line box to the font size and split its leading evenly.
      // Without the even split the glyphs sit above the middle of the
      // box, and the whole field reads as set too high.
      leadingDistribution: TextLeadingDistribution.even,
      decoration: TextDecoration.none,
    );

    final field = EditableText(
      controller: _text,
      focusNode: _focus,
      readOnly: widget.inputReadOnly || !_enabled,
      showCursor: !widget.inputReadOnly && _enabled,
      style: textStyle,
      strutStyle: StrutStyle.fromTextStyle(textStyle, forceStrutHeight: true),
      cursorColor: t.primary.base,
      backgroundCursorColor: t.colorTextQuaternary,
      cursorWidth: 1.5,
      maxLines: 1,
      keyboardType: TextInputType.datetime,
      onSubmitted: _onSubmitted,
      onTapOutside: (_) => _onSubmitted(_text.text),
      rendererIgnoresPointer: true,
      enableInteractiveSelection: !widget.inputReadOnly,
    );

    // Given a width the field fills it, as a form field should; left
    // unbounded it takes what the format needs, so a picker can stand in a
    // Row without being measured by hand.
    final valueWidth = _valueWidth(textStyle, words);

    // A two-dimensional size names a width as well; anything else leaves the
    // field to size itself from the format.
    final named = _size.explicitWidth;

    final control = MouseRegion(
      cursor:
          _enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled ? () => _requestOpen(!_open) : null,
        child: AnimatedContainer(
          duration: t.motionDurationMid,
          curve: t.motionEaseInOut,
          height: _height(t),
          padding: EdgeInsetsDirectional.symmetric(horizontal: t.sizeSM),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: CompactSlot.radiusOf(context, r.borderRadius),
            border: Border.all(color: border, width: t.lineWidth),
          ),
          child: LayoutBuilder(
            builder: (context, available) {
              final valueArea = Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  if (_text.text.isEmpty)
                    Text(
                      widget.placeholder ?? words.selectTime,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle.copyWith(color: t.colorTextTertiary),
                    ),
                  field,
                ],
              );

              // Told exactly how wide to be — a SizedBox, a stretched
              // Column — the field fills that, as a form field should.
              // Merely offered an upper bound, as a Wrap or a Row offers,
              // it takes what it needs and no more: `hasBoundedWidth` is
              // true for both, and treating them alike stretched every
              // picker across its parent.
              final told = available.maxWidth == available.minWidth;
              final room = available.maxWidth;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.prefix != null) ...[
                    widget.prefix!,
                    SizedBox(width: t.sizeXS),
                  ],
                  if (told)
                    Expanded(child: valueArea)
                  else if (room.isFinite)
                    // Offered a bound: take what the format needs, but give
                    // way when the affixes and the chrome leave less than
                    // that. Clamping to the room alone is not enough — the
                    // padding, the gap and the icon come out of it too.
                    Flexible(
                      child: SizedBox(width: valueWidth, child: valueArea),
                    )
                  else
                    // No bound at all, so nothing to give way to.
                    SizedBox(width: valueWidth, child: valueArea),
                  SizedBox(width: t.sizeXS),
                  if (showClear)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _clear,
                      child: CustomPaint(
                        size: Size.square(fontSize),
                        painter: ClearIconPainter(t.colorTextTertiary),
                      ),
                    )
                  else
                    widget.suffixIcon ??
                        CustomPaint(
                          size: Size.square(fontSize),
                          painter: _ClockIconPainter(
                              statusColor ?? t.colorTextQuaternary),
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );

    final sized =
        named == null ? control : SizedBox(width: named, child: control);

    // What it is, what it is called, what it holds and whether its panel is
    // open. A picker said none of it: a reader met a box with no name and no
    // news of the value inside.
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticsLabel ?? widget.placeholder,
      // No `value` here: the field inside is an editable, and what it holds
      // is already spoken. Naming it twice would say it twice.
      expanded: _open,
      validationResult: widget.status == InputStatus.error
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: sized,
    );
  }
}

/// The floating panel: one scrolling column per field the format names, and a
/// footer.
class _TimePanel extends StatelessWidget {
  const _TimePanel({required this.state});

  final _TimePickerState state;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final words = context.seedLocale;
    final r = (state.widget.token ??
            ConfigProvider.componentOf<TimePickerToken>(context) ??
            const TimePickerToken())
        ._resolve(t);
    return IntrinsicWidth(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.colorBgElevated,
          borderRadius: BorderRadius.circular(r.borderRadius),
          boxShadow: t.boxShadowSecondary,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The columns are inset from the panel's own top and bottom, so
            // the first value does not sit against its edge.
            Padding(
              padding: EdgeInsets.symmetric(vertical: t.sizeXXS),
              child: TimeColumns(
                fields: state._fields,
                value: state._draft,
                onChanged: state._pick,
                cellHeight: r.cellHeight,
                columnWidth: r.columnWidth,
                visibleRows: r.visibleRows,
                hourStep: state.widget.hourStep,
                minuteStep: state.widget.minuteStep,
                secondStep: state.widget.secondStep,
                disabledTime: state.widget.disabledTime,
                hideDisabledOptions: state.widget.hideDisabledOptions,
              ),
            ),
            Container(height: t.lineWidth, color: t.colorSplit),
            Padding(
              padding: EdgeInsets.all(t.sizeXS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (state._showNow)
                    _FooterAction(
                      label: words.now,
                      onTap: state._now,
                      accent: true,
                    )
                  else
                    const SizedBox.shrink(),
                  if (state._needConfirm)
                    _FooterAction(
                      label: words.ok,
                      onTap: state._confirm,
                      accent: false,
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
            if (state.widget.footerBuilder != null) ...[
              Container(height: t.lineWidth, color: t.colorSplit),
              state.widget.footerBuilder!(context),
            ],
          ],
        ),
      ),
    );
  }
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({
    required this.label,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: t.sizeXS,
            vertical: t.sizeXXS,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: accent ? t.primary.base : t.colorText,
              fontSize: t.fontSize,
              fontFamily: t.fontFamily,
              fontFamilyFallback: t.fontFamilyFallback,
              height: 1.0,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}

/// The clock face on the trailing edge of the field.
class _ClockIconPainter extends CustomPainter {
  const _ClockIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;
    final centre = size.center(Offset.zero);
    canvas.drawCircle(centre, size.width * 0.42, paint);
    // Hands at ten past ten, the way a clock is drawn when it is standing in
    // for the idea of one.
    canvas.drawLine(centre, centre + Offset(0, -size.height * 0.24), paint);
    canvas.drawLine(centre, centre + Offset(size.width * 0.18, 0), paint);
  }

  @override
  bool shouldRepaint(_ClockIconPainter old) => old.color != color;
}
