import 'package:flutter/widgets.dart';

import '../../l10n/seed_localizations.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/date_format.dart';
import '../../utils/popover.dart';
import '../data_entry/input.dart' show InputStatus;
import '../data_entry/select.dart' show ClearIconPainter;

/// How a [DatePicker] is filled and bordered.
enum DatePickerVariant {
  /// A border, on the container background.
  outlined,

  /// A tinted fill and no border.
  filled,

  /// Neither fill nor border.
  borderless,
}

/// Which panel a [DatePicker] is showing.
///
/// The header walks up — a day panel to its months, months to their years,
/// years to their decade — and picking walks back down. Reaching 1998 from
/// 2026 by tapping a chevron twenty-eight times is not a design.
enum DatePanelMode {
  /// The days of one month.
  day,

  /// The twelve months of one year.
  month,

  /// The ten years of one decade.
  year,
}

/// Defaults for every [DatePicker] under a `ConfigProvider`.
///
/// The picker's own props, not its [DatePickerToken] numbers.
@immutable
class DatePickerDefaults {
  /// Creates a [DatePickerDefaults].
  const DatePickerDefaults({
    this.variant,
    this.allowClear,
    this.showToday,
    this.size,
    this.disabled,
  });

  /// How pickers are filled and bordered.
  final DatePickerVariant? variant;

  /// Whether pickers carry a clear button once a date is set.
  final bool? allowClear;

  /// Whether the panel offers a jump to the current day.
  final bool? showToday;

  /// Which control height a [DatePicker] takes, unless it names one.
  final SoftSize? size;

  /// Whether a [DatePicker] is disabled, unless it says otherwise.
  final bool? disabled;
}

/// Per-component design tokens for [DatePicker].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(datePicker: DatePickerToken(...)))`, or per instance via
/// [DatePicker.token].
@immutable
class DatePickerToken {
  /// Creates a [DatePickerToken].
  const DatePickerToken({
    this.borderRadius,
    this.cellWidth,
    this.cellHeight,
    this.headerHeight,
  });

  /// Corner radius of the field and the panel.
  final double? borderRadius;

  /// Width of one day cell.
  final double? cellWidth;

  /// Height of one day cell.
  final double? cellHeight;

  /// Height of the panel's header row.
  final double? headerHeight;

  _ResolvedDatePickerToken _resolve(Token t) => _ResolvedDatePickerToken(
        borderRadius: borderRadius ?? t.borderRadius,
        cellWidth: cellWidth ?? t.controlHeightSM * 1.5,
        cellHeight: cellHeight ?? t.controlHeightSM,
        headerHeight: headerHeight ?? t.controlHeightLG,
      );
}

@immutable
class _ResolvedDatePickerToken {
  const _ResolvedDatePickerToken({
    required this.borderRadius,
    required this.cellWidth,
    required this.cellHeight,
    required this.headerHeight,
  });

  final double borderRadius;
  final double cellWidth;
  final double cellHeight;
  final double headerHeight;
}

/// A field that collects a calendar date.
///
/// ```dart
/// DatePicker(
///   value: _startsOn,
///   onChanged: (date) => setState(() => _startsOn = date),
/// )
/// ```
///
/// The value is a [DateTime] with the clock at midnight — Dart's own date
/// type, so nothing has to be converted on the way in or out. Use
/// [dateOnly] on a `DateTime` that carries a time.
///
/// The panel walks between three depths: the days of a month, the months of a
/// year, the years of a decade. The header is the way up and picking is the
/// way down, so a date years away is three taps rather than a long run of
/// chevrons.
class DatePicker extends StatefulWidget {
  /// Creates a [DatePicker].
  const DatePicker({
    super.key,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.format = 'yyyy-MM-dd',
    this.disabledDate,
    this.minDate,
    this.maxDate,
    this.showToday,
    this.allowClear,
    this.disabled,
    this.size,
    this.variant,
    this.placeholder,
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
  });

  /// The date shown.
  ///
  /// Null hands the picker to itself: it keeps what is chosen, starting from
  /// [defaultValue]. Supply this to drive it from outside instead.
  final DateTime? value;

  /// What an uncontrolled picker starts with. Ignored when [value] is set.
  final DateTime? defaultValue;

  /// Called with the chosen date, or null when it is cleared.
  final ValueChanged<DateTime?>? onChanged;

  /// How the date is written. See [DateFields] for the grammar.
  final String format;

  /// Which days cannot be chosen. Told each day the panel is about to draw.
  final bool Function(DateTime day)? disabledDate;

  /// The earliest day on offer. Days before it are greyed out.
  final DateTime? minDate;

  /// The latest day on offer.
  final DateTime? maxDate;

  /// Whether the panel offers a jump to the current day. Follows
  /// [DatePickerDefaults.showToday], else true.
  final bool? showToday;

  /// Whether a clear button appears once a date is set.
  final bool? allowClear;

  /// Whether the field is disabled. Follows `ConfigProvider.componentDisabled`.
  final bool? disabled;

  /// Which control height to use. Follows `ConfigProvider.componentSize`.
  final SoftSize? size;

  /// How the field is filled and bordered.
  final DatePickerVariant? variant;

  /// Shown when there is no value. Null uses the locale's own words.
  final String? placeholder;

  /// Where the panel opens against the field.
  final PopoverPlacement placement;

  /// Whether the panel is open. Null lets the picker decide for itself.
  final bool? open;

  /// Called when the panel opens or closes.
  final ValueChanged<bool>? onOpenChange;

  /// Whether the field refuses typing, leaving the panel the only way in.
  final bool inputReadOnly;

  /// Marks the field as questionable or wrong.
  final InputStatus? status;

  /// Sits before the value, inside the field.
  final Widget? prefix;

  /// Replaces the calendar mark on the trailing edge.
  final Widget? suffixIcon;

  /// Called when the clear button is pressed, after the value is dropped.
  final VoidCallback? onClear;

  /// Adds a row of your own beneath the panel's footer.
  final WidgetBuilder? footerBuilder;

  /// Per-instance token overrides.
  final DatePickerToken? token;

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  final PopoverController _popover = PopoverController();
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();

  bool _open = false;
  bool _hovered = false;

  /// What an uncontrolled picker is holding.
  DateTime? _internal;

  /// The month the panel is looking at, and how deep it is looking.
  late DateTime _cursor;
  DatePanelMode _mode = DatePanelMode.day;

  /// Rebuilt on its own: the panel lives in the overlay, where a `setState`
  /// here does not reach.
  final ValueNotifier<int> _revision = ValueNotifier(0);

  DateTime? get _value => widget.value ?? _internal;

  DatePickerDefaults? get _defaults =>
      ConfigProvider.defaultsOf<DatePickerDefaults>(context);

  bool get _disabled =>
      widget.disabled ??
      _defaults?.disabled ??
      ConfigProvider.componentDisabledOf(context) ??
      false;

  SoftSize get _size =>
      widget.size ??
      _defaults?.size ??
      ConfigProvider.componentSizeOf(context) ??
      SoftSize.middle;

  DatePickerVariant get _variant =>
      widget.variant ?? _defaults?.variant ?? DatePickerVariant.outlined;

  bool get _allowClear => widget.allowClear ?? _defaults?.allowClear ?? true;

  bool get _showToday => widget.showToday ?? _defaults?.showToday ?? true;

  bool get _enabled => !_disabled;

  @override
  void initState() {
    super.initState();
    _internal = widget.defaultValue;
    _cursor = dateOnly(_value ?? DateTime.now());
    _popover.onClosed = () {
      if (!mounted || !_open) return;
      setState(() => _open = false);
      _syncText();
      widget.onOpenChange?.call(false);
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_focus.hasFocus) _syncText();
  }

  @override
  void didUpdateWidget(DatePicker old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || old.format != widget.format) {
      _syncText();
    }
    if (widget.open != null && widget.open != old.open) {
      widget.open! ? _openPanel() : _closePanel();
    }
  }

  @override
  void dispose() {
    _popover.dispose();
    _text.dispose();
    _focus.dispose();
    _revision.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Value
  // --------------------------------------------------------------------------

  void _syncText() {
    final words = context.seedLocale;
    final value = _value;
    final next = value == null
        ? ''
        : words.figures(
            formatDate(
              value,
              widget.format,
              months: words.shortMonths,
              weekdays: words.shortWeekdays,
              am: words.am,
              pm: words.pm,
            ),
          );
    if (_text.text != next) _text.text = next;
  }

  void _commit(DateTime? date) {
    if (date == _value) return;
    if (widget.value == null) setState(() => _internal = date);
    widget.onChanged?.call(date);
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

  void _onSubmitted(String text) {
    final words = context.seedLocale;
    if (text.trim().isEmpty) {
      _commit(null);
      _requestOpen(false);
      return;
    }
    final parsed = parseDate(
      _plainFigures(text, words),
      widget.format,
      months: words.shortMonths,
      fallback: _value,
    );
    // An entry that is not a date leaves the value alone rather than clearing
    // it, so a stray keystroke cannot wipe a set date.
    if (parsed == null || _isBlocked(parsed)) {
      _syncText();
      return;
    }
    setState(() => _cursor = parsed);
    _commit(parsed);
    _requestOpen(false);
  }

  // --------------------------------------------------------------------------
  // Availability
  // --------------------------------------------------------------------------

  bool _isBlocked(DateTime day) {
    final d = dateOnly(day);
    final min = widget.minDate;
    final max = widget.maxDate;
    if (min != null && d.isBefore(dateOnly(min))) return true;
    if (max != null && d.isAfter(dateOnly(max))) return true;
    return widget.disabledDate?.call(d) ?? false;
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
      _mode = DatePanelMode.day;
      _cursor = dateOnly(_value ?? DateTime.now());
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
        listenable: _revision,
        builder: (context, _) => _DatePanel(state: this),
      ),
    );
  }

  void _closePanel() {
    if (!_open) return;
    setState(() => _open = false);
    _popover.close();
    _syncText();
  }

  /// Redraws the floating panel, which a `setState` here cannot reach.
  void _repaintPanel() => _revision.value++;

  void _pick(DateTime day) {
    if (_isBlocked(day)) return;
    setState(() => _cursor = dateOnly(day));
    _commit(dateOnly(day));
    _syncText();
    _requestOpen(false);
  }

  void _today() => _pick(dateOnly(DateTime.now()));

  void _clear() {
    _text.clear();
    _commit(null);
    widget.onClear?.call();
  }

  void _step(int months) {
    setState(() => _cursor = addMonths(_cursor, months));
    _repaintPanel();
  }

  void _stepYears(int years) {
    setState(() => _cursor = addMonths(_cursor, years * 12));
    _repaintPanel();
  }

  void _setMode(DatePanelMode mode) {
    setState(() => _mode = mode);
    _repaintPanel();
  }

  void _pickMonth(int month) {
    setState(() {
      _cursor = DateTime(_cursor.year, month);
      _mode = DatePanelMode.day;
    });
    _repaintPanel();
  }

  void _pickYear(int year) {
    setState(() {
      _cursor = DateTime(year, _cursor.month);
      _mode = DatePanelMode.month;
    });
    _repaintPanel();
  }

  // --------------------------------------------------------------------------
  // Building
  // --------------------------------------------------------------------------

  double _height(Token t) => switch (_size) {
        SoftSize.small => t.controlHeightSM,
        SoftSize.middle => t.controlHeight,
        SoftSize.large => t.controlHeightLG,
      };

  double _fontSize(Token t) =>
      _size == SoftSize.large ? t.fontSizeLG : t.fontSize;

  void _syncAnchor() {
    if (!_open) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      _popover.reposition(box.localToGlobal(Offset.zero) & box.size);
    }
  }

  /// How wide the value area has to be, whatever the field is showing.
  ///
  /// The wider of the longest the format can render and the placeholder that
  /// stands in until a date is chosen, since the field shows both at different
  /// times and must not resize between them.
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

    // The longest month name, and a date whose every figure is the widest the
    // face draws.
    final longestMonth = words.shortMonths.reduce(
      (a, b) => widthOf(a) >= widthOf(b) ? a : b,
    );
    final sample = words.figures(
      formatDate(
        DateTime(2026, words.shortMonths.indexOf(longestMonth) + 1, 28),
        widget.format,
        months: words.shortMonths,
        weekdays: words.shortWeekdays,
        am: words.am,
        pm: words.pm,
      ),
    );
    final padded = sample
        .split('')
        .map((ch) => words.digits.contains(ch) ? widest : ch)
        .join();

    final figures = widthOf(padded);
    final hint = widthOf(widget.placeholder ?? words.selectDate);
    return figures > hint ? figures : hint;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final words = context.seedLocale;
    final r = (widget.token ??
            ConfigProvider.componentOf<DatePickerToken>(context) ??
            const DatePickerToken())
        ._resolve(t);
    _syncAnchor();

    final fontSize = _fontSize(t);
    final showClear = _allowClear && _enabled && _value != null && _hovered;

    final Color fill;
    if (!_enabled) {
      fill = t.colorFillTertiary;
    } else if (_variant == DatePickerVariant.filled) {
      fill = _hovered || _open ? t.colorFillSecondary : t.colorFillTertiary;
    } else if (_variant == DatePickerVariant.borderless) {
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
    if (_variant != DatePickerVariant.outlined) {
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

    final valueWidth = _valueWidth(textStyle, words);

    return MouseRegion(
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
            borderRadius: BorderRadius.circular(r.borderRadius),
            border: Border.all(color: border, width: t.lineWidth),
          ),
          child: LayoutBuilder(
            builder: (context, available) {
              final valueArea = Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  if (_text.text.isEmpty)
                    Text(
                      widget.placeholder ?? words.selectDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle.copyWith(color: t.colorTextTertiary),
                    ),
                  field,
                ],
              );

              // Told exactly how wide to be, the field fills that. Merely
              // offered an upper bound, it takes what it needs and gives way
              // when there is less.
              final told = available.maxWidth == available.minWidth;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.prefix != null) ...[
                    widget.prefix!,
                    SizedBox(width: t.sizeXS),
                  ],
                  if (told)
                    Expanded(child: valueArea)
                  else if (available.maxWidth.isFinite)
                    Flexible(
                      child: SizedBox(width: valueWidth, child: valueArea),
                    )
                  else
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
                          painter: _CalendarIconPainter(
                            statusColor ?? t.colorTextQuaternary,
                          ),
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The floating panel: a header that walks up, a body that walks down.
class _DatePanel extends StatelessWidget {
  const _DatePanel({required this.state});

  final _DatePickerState state;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final words = context.seedLocale;
    final r = (state.widget.token ??
            ConfigProvider.componentOf<DatePickerToken>(context) ??
            const DatePickerToken())
        ._resolve(t);

    final width = r.cellWidth * 7 + t.sizeSM * 2;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.colorBgElevated,
        borderRadius: BorderRadius.circular(r.borderRadius),
        boxShadow: t.boxShadowSecondary,
      ),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(state: state, token: r),
            Container(height: t.lineWidth, color: t.colorSplit),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: t.sizeSM,
                vertical: t.sizeXS,
              ),
              child: switch (state._mode) {
                DatePanelMode.day => _DayGrid(state: state, token: r),
                DatePanelMode.month => _MonthGrid(state: state, token: r),
                DatePanelMode.year => _YearGrid(state: state, token: r),
              },
            ),
            if (state._showToday) ...[
              Container(height: t.lineWidth, color: t.colorSplit),
              Padding(
                padding: EdgeInsets.all(t.sizeXS),
                child: Center(
                  child: _Action(label: words.today, onTap: state._today),
                ),
              ),
            ],
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

/// The panel's header: chevrons either side, and the way up in the middle.
class _Header extends StatelessWidget {
  const _Header({required this.state, required this.token});

  final _DatePickerState state;
  final _ResolvedDatePickerToken token;

  @override
  Widget build(BuildContext context) {
    final words = context.seedLocale;
    final cursor = state._cursor;

    final label = switch (state._mode) {
      DatePanelMode.day =>
        '${words.shortMonths[cursor.month - 1]} ${words.figures('${cursor.year}')}',
      DatePanelMode.month => words.figures('${cursor.year}'),
      DatePanelMode.year =>
        '${words.figures('${cursor.year - cursor.year % 10}')}'
            '–${words.figures('${cursor.year - cursor.year % 10 + 9}')}',
    };

    // A day panel steps by month; the deeper panels step by year and decade,
    // so one chevron always moves one page of what is on screen.
    final back = switch (state._mode) {
      DatePanelMode.day => () => state._step(-1),
      DatePanelMode.month => () => state._stepYears(-1),
      DatePanelMode.year => () => state._stepYears(-10),
    };
    final forward = switch (state._mode) {
      DatePanelMode.day => () => state._step(1),
      DatePanelMode.month => () => state._stepYears(1),
      DatePanelMode.year => () => state._stepYears(10),
    };

    final up = switch (state._mode) {
      DatePanelMode.day => () => state._setMode(DatePanelMode.month),
      DatePanelMode.month => () => state._setMode(DatePanelMode.year),
      DatePanelMode.year => null,
    };

    return SizedBox(
      height: token.headerHeight,
      child: Row(
        children: [
          // Named, because a painted chevron says nothing to a screen
          // reader. The kit already has both words, for Tour's own buttons.
          _Chevron(back: true, onTap: back, label: words.previous),
          Expanded(
            child: _Action(label: label, onTap: up, centred: true),
          ),
          _Chevron(back: false, onTap: forward, label: words.next),
        ],
      ),
    );
  }
}

/// The six weeks of one month.
class _DayGrid extends StatelessWidget {
  const _DayGrid({required this.state, required this.token});

  final _DatePickerState state;
  final _ResolvedDatePickerToken token;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final words = context.seedLocale;
    final cursor = state._cursor;
    final today = dateOnly(DateTime.now());
    final chosen = state._value;

    final order = weekdayOrder(firstDayOfWeek: words.firstDayOfWeek);
    final days = monthGrid(
      cursor.year,
      cursor.month,
      firstDayOfWeek: words.firstDayOfWeek,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final weekday in order)
              SizedBox(
                width: token.cellWidth,
                height: token.cellHeight,
                child: Center(
                  child: Text(
                    words.shortWeekdays[weekday - 1],
                    style: TextStyle(
                      color: t.colorText,
                      fontSize: t.fontSize,
                      fontFamily: t.fontFamily,
                      fontFamilyFallback: t.fontFamilyFallback,
                      fontWeight: t.fontWeight,
                      height: 1.0,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
          ],
        ),
        for (var week = 0; week < 6; week++)
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Builder(
                  builder: (context) {
                    final day = days[week * 7 + i];
                    return _Cell(
                      label: words.figures('${day.day}'),
                      width: token.cellWidth,
                      height: token.cellHeight,
                      // Days from the months either side are drawn faintly:
                      // they are reachable, but they are not this month.
                      outside: !isSameMonth(day, cursor),
                      today: isSameDay(day, today),
                      chosen: chosen != null && isSameDay(day, chosen),
                      disabled: state._isBlocked(day),
                      onTap: () => state._pick(day),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}

/// The twelve months of one year.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.state, required this.token});

  final _DatePickerState state;
  final _ResolvedDatePickerToken token;

  @override
  Widget build(BuildContext context) {
    final words = context.seedLocale;
    final cursor = state._cursor;
    final chosen = state._value;
    final width = token.cellWidth * 7 / 3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 4; row++)
          Row(
            children: [
              for (var col = 0; col < 3; col++)
                Builder(
                  builder: (context) {
                    final month = row * 3 + col + 1;
                    return _Cell(
                      label: words.shortMonths[month - 1],
                      width: width,
                      height: token.cellHeight * 1.6,
                      outside: false,
                      today: false,
                      chosen: chosen != null &&
                          chosen.year == cursor.year &&
                          chosen.month == month,
                      disabled: false,
                      onTap: () => state._pickMonth(month),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}

/// The ten years of one decade, with the one either side.
class _YearGrid extends StatelessWidget {
  const _YearGrid({required this.state, required this.token});

  final _DatePickerState state;
  final _ResolvedDatePickerToken token;

  @override
  Widget build(BuildContext context) {
    final words = context.seedLocale;
    final cursor = state._cursor;
    final chosen = state._value;
    final start = cursor.year - cursor.year % 10;
    final width = token.cellWidth * 7 / 3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 4; row++)
          Row(
            children: [
              for (var col = 0; col < 3; col++)
                Builder(
                  builder: (context) {
                    // One year either side of the decade, so the grid fills
                    // and the neighbours are one tap away.
                    final year = start - 1 + row * 3 + col;
                    return _Cell(
                      label: words.figures('$year'),
                      width: width,
                      height: token.cellHeight * 1.6,
                      outside: year < start || year > start + 9,
                      today: false,
                      chosen: chosen != null && chosen.year == year,
                      disabled: false,
                      onTap: () => state._pickYear(year),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}

/// One cell of any of the three grids.
class _Cell extends StatefulWidget {
  const _Cell({
    required this.label,
    required this.width,
    required this.height,
    required this.outside,
    required this.today,
    required this.chosen,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final double width;
  final double height;
  final bool outside;
  final bool today;
  final bool chosen;
  final bool disabled;
  final VoidCallback onTap;

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    final Color background;
    if (widget.chosen && !widget.disabled) {
      background = t.primary.base;
    } else if (_hovered && !widget.disabled) {
      background = t.colorFillTertiary;
    } else {
      background = const Color(0x00000000);
    }

    final Color text;
    if (widget.disabled) {
      text = t.colorTextQuaternary;
    } else if (widget.chosen) {
      text = const Color(0xFFFFFFFF);
    } else if (widget.outside) {
      text = t.colorTextQuaternary;
    } else {
      text = t.colorText;
    }

    return MouseRegion(
      cursor: widget.disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.disabled ? null : widget.onTap,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Center(
            child: AnimatedContainer(
              // A pick lands at once; only the hover tint eases in. Easing
              // from the hover grey to the chosen fill shows the grey on the
              // way, which reads as a flash under the finger.
              duration: widget.chosen ? Duration.zero : t.motionDurationMid,
              curve: t.motionEaseInOut,
              width: widget.width - t.sizeXXS,
              height: t.controlHeightSM,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(t.borderRadiusSM),
                // Today is an outline, not a fill: otherwise the day that is
                // both today and the chosen one could not be told apart.
                border: widget.today && !widget.chosen
                    ? Border.all(color: t.primary.base, width: t.lineWidth)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                maxLines: 1,
                style: TextStyle(
                  color: text,
                  fontSize: t.fontSize,
                  fontFamily: t.fontFamily,
                  fontFamilyFallback: t.fontFamilyFallback,
                  fontWeight: t.fontWeight,
                  height: 1.0,
                  leadingDistribution: TextLeadingDistribution.even,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A word in the header or the footer that can be pressed.
class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.onTap,
    this.centred = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool centred;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final text = Text(
      label,
      style: TextStyle(
        color: onTap == null ? t.colorText : t.primary.base,
        fontSize: t.fontSize,
        fontFamily: t.fontFamily,
        fontFamilyFallback: t.fontFamilyFallback,
        fontWeight: t.fontWeightStrong,
        height: 1.0,
        decoration: TextDecoration.none,
      ),
    );

    return MouseRegion(
      cursor:
          onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: centred ? Center(child: text) : text,
      ),
    );
  }
}

/// One of the header's two chevrons.
class _Chevron extends StatelessWidget {
  const _Chevron({
    required this.back,
    required this.onTap,
    required this.label,
  });

  final bool back;
  final VoidCallback onTap;

  /// What a screen reader says for it.
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: t.controlHeight,
            child: Center(
              child: CustomPaint(
                size: Size.square(t.fontSize * 0.7),
                // The chevron points the way the language runs, so "back" is
                // the leading edge in either direction.
                painter: _ChevronPainter(
                  pointsLeft: back != rtl,
                  color: t.colorTextTertiary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.pointsLeft, required this.color});

  final bool pointsLeft;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    if (pointsLeft) {
      path
        ..moveTo(size.width * 0.7, 0)
        ..lineTo(size.width * 0.3, size.height / 2)
        ..lineTo(size.width * 0.7, size.height);
    } else {
      path
        ..moveTo(size.width * 0.3, 0)
        ..lineTo(size.width * 0.7, size.height / 2)
        ..lineTo(size.width * 0.3, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChevronPainter old) =>
      old.pointsLeft != pointsLeft || old.color != color;
}

/// The calendar mark on the trailing edge of the field.
class _CalendarIconPainter extends CustomPainter {
  const _CalendarIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final body = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.2,
      size.width * 0.8,
      size.height * 0.72,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(size.width * 0.1)),
      paint,
    );
    // The two rings at the top, and the line under the header.
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.08),
      Offset(size.width * 0.3, size.height * 0.28),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.08),
      Offset(size.width * 0.7, size.height * 0.28),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.44),
      Offset(size.width * 0.9, size.height * 0.44),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CalendarIconPainter old) => old.color != color;
}
