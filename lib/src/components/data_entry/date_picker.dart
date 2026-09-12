import 'package:flutter/semantics.dart' show SemanticsValidationResult;
import 'package:flutter/services.dart'
    show KeyEvent, KeyUpEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../l10n/seed_localizations.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/date_format.dart';
import '../../utils/popover.dart';
import '../../utils/size_resolver.dart';
import '../../utils/time_columns.dart';
import '../../utils/time_format.dart';
import '../data_entry/input.dart' show InputStatus;
import '../general/compact.dart';

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

  /// The four quarters of one year.
  quarter,

  /// The twelve months of one year.
  month,

  /// The ten years of one decade.
  year,
}

/// A named date on the rail beside the panel — "Today", "This time last
/// year", whatever the form is about.
///
/// The date is asked for when the preset is taken rather than when the panel
/// is built: a picker opened at one minute to midnight and tapped a minute
/// later would otherwise hand back yesterday.
class DatePreset {
  /// A preset standing for a date that is already known.
  const DatePreset(this.label, DateTime date)
      : _date = date,
        _asked = null;

  /// A preset that works its date out when it is taken — anything reckoned
  /// from the clock, which is most of them.
  const DatePreset.of(this.label, DateTime Function() date)
      : _asked = date,
        _date = null;

  /// What the rail calls it.
  final String label;

  final DateTime? _date;
  final DateTime Function()? _asked;

  /// The date this preset stands for, now.
  DateTime get date => dateOnly(_date ?? _asked!());
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
  final ControlSize? size;

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
    this.presetsWidth,
    this.timeColumnWidth,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
  });

  /// Corner radius of the field and the panel.
  final double? borderRadius;

  /// Width of one day cell.
  final double? cellWidth;

  /// Height of one day cell, pill and the air around it both.
  final double? cellHeight;

  /// Height of the panel's header row.
  final double? headerHeight;

  /// How wide the rail of presets stands, where there is one.
  final double? presetsWidth;

  /// How wide one column of the time panel stands.
  final double? timeColumnWidth;

  /// The air between one week of the grid and the next.
  ///
  /// Added around the cell rather than taken out of it: [cellHeight] is how
  /// tall a day stands, and a gap that ate into it would shrink the days
  /// instead of parting them. A wider gap makes the panel taller, which is
  /// what asking for more air between rows means.
  final double? mainAxisSpacing;

  /// The air between one day of the grid and the next.
  ///
  /// Added around the cell, as [mainAxisSpacing] is. A range's band still
  /// spans the gap: it is drawn across the whole pitch — the day and the air
  /// beside it — so a stretch of days joins up rather than coming out in
  /// pieces.
  final double? crossAxisSpacing;

  /// Settles every number against the theme.
  DatePanelStyle resolve(Token t) => DatePanelStyle(
        borderRadius: borderRadius ?? t.borderRadius,
        cellWidth: cellWidth ?? t.controlHeightSM * 1.5,
        // A shade taller than the pill inside it, so the weeks have a line
        // of air between them. The same height and the rows touch: with a
        // range drawn across them, a month reads as one grey block rather
        // than six weeks.
        // The height of a day, not of a day and the air around it: the air
        // is `mainAxisSpacing`, added on top.
        cellHeight: cellHeight ?? t.controlHeightSM,
        headerHeight: headerHeight ?? t.controlHeightLG,
        presetsWidth: presetsWidth ?? t.controlHeightLG * 3,
        timeColumnWidth: timeColumnWidth ?? t.controlHeightSM * 2,
        mainAxisSpacing: mainAxisSpacing ?? t.sizeXXS,
        crossAxisSpacing: crossAxisSpacing ?? t.sizeXXS,
      );
}

/// A [DatePickerToken] with every number settled against the theme: what
/// the panel is actually drawn with.
@immutable
class DatePanelStyle {
  /// Creates a settled token.
  const DatePanelStyle({
    required this.borderRadius,
    required this.cellWidth,
    required this.cellHeight,
    required this.headerHeight,
    required this.presetsWidth,
    required this.timeColumnWidth,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
  });

  /// Corner radius of the field and the panel.
  final double borderRadius;

  /// Width of one day cell.
  final double cellWidth;

  /// Height of one day cell.
  final double cellHeight;

  /// Height of the panel's header row.
  final double headerHeight;

  /// How wide the rail of presets stands.
  final double presetsWidth;

  /// How wide one column of the time panel stands.
  final double timeColumnWidth;

  /// The air between one week of the grid and the next.
  final double mainAxisSpacing;

  /// The air between one day of the grid and the next.
  final double crossAxisSpacing;

  /// How much room one day takes in the grid, its share of the air included.
  ///
  /// The band a range draws spans this rather than [cellWidth], so a stretch
  /// of days reads as one band and not as a row of separate ones.
  double get dayPitchWidth => cellWidth + crossAxisSpacing;

  /// And how much room one week takes.
  double get dayPitchHeight => cellHeight + mainAxisSpacing;

  /// How wide the seven days come to, air and all.
  double get gridWidth => dayPitchWidth * 7;
}

/// What a [DatePicker] collects.
///
/// The value is a [DateTime] whichever it is — the first day of the thing
/// chosen. A week is its first day, counted from wherever the locale starts
/// its weeks; a quarter is the first day of its first month. Nothing here
/// needs a type of its own: a week is a day you can add seven to.
enum DatePickerKind {
  /// One day.
  day,

  /// A whole week, taken by pressing any day in it.
  week,

  /// A whole month.
  month,

  /// A quarter of a year.
  quarter,

  /// A whole year.
  year,
}

/// What a day on the panel knows about itself.
///
/// Handed to a [DateCellBuilder] along with the mark the panel would have
/// drawn, so a caller can put something of their own beside it — a dot under
/// a day with something booked, a price, a count — without working out for
/// themselves what "chosen" or "today" look like.
@immutable
class DateCell {
  /// Creates a description of one day cell.
  const DateCell({
    required this.date,
    required this.today,
    required this.chosen,
    required this.within,
    required this.outside,
    required this.disabled,
    required this.resting,
  });

  /// The day this cell stands for.
  final DateTime date;

  /// Whether it is today.
  final bool today;

  /// Whether the picker holds it — an end of a range counts.
  final bool chosen;

  /// Whether it lies between the two ends of a range.
  final bool within;

  /// Whether it belongs to the month either side rather than this one.
  final bool outside;

  /// Whether it cannot be chosen.
  final bool disabled;

  /// Whether the keyboard is resting on it.
  final bool resting;
}

/// Draws a day cell.
///
/// [child] is what the panel would have drawn — the pill, its fill, the band
/// under a range. Wrap it rather than replacing it and a cell keeps every
/// state the panel gives it for nothing:
///
/// ```dart
/// cellBuilder: (context, cell, child) => Stack(
///   alignment: Alignment.bottomCenter,
///   children: [
///     child,
///     if (bookings.containsKey(cell.date)) const _Dot(),
///   ],
/// )
/// ```
typedef DateCellBuilder = Widget Function(
  BuildContext context,
  DateCell cell,
  Widget child,
);

/// What the panel needs of whatever is driving it.
///
/// Two pickers drive the same panel: one collecting a date, one collecting a
/// range. Everything the grids and the header ask about — which month is on
/// show, which days are marked, what a tap means — is asked through this, so
/// the panel is written once and the difference between the two lives where
/// it belongs, in the pickers.
abstract class PanelHost {
  /// The month the panel is looking at.
  DateTime get panelCursor;

  /// How deep it is looking: days, months or years.
  DatePanelMode get panelMode;

  /// Whether the keyboard has been used, which is when a resting mark shows.
  bool get panelKeyed;

  /// The day the keyboard rests on, where there is one.
  DateTime? get panelResting;

  /// Whether this day cannot be chosen.
  bool panelBlocks(DateTime day);

  /// Whether this day is one the picker holds — an end of a range counts.
  bool panelChose(DateTime day);

  /// The date the month and year grids mark, where there is one. A range
  /// marks the end it is waiting on.
  DateTime? get panelMarked;

  /// Whether this day lies between the two ends of a range, ends excluded.
  bool panelWithin(DateTime day) => false;

  /// Which end of a range this day is, where it is one.
  PanelCap panelCap(DateTime day) => PanelCap.none;

  /// A day the pointer is over, so a range being drawn can follow it.
  void panelHover(DateTime? day) {}

  /// Draws a day cell, where the caller has something to add to it.
  DateCellBuilder? get panelCellBuilder => null;

  /// What the picker is collecting, which decides what a day cell means: in a
  /// week picker every day of a row is one press on the same answer.
  DatePickerKind get panelKind => DatePickerKind.day;

  /// Takes this day.
  void panelPick(DateTime day);

  /// Takes this month, which walks the panel back down to its days.
  void panelPickMonth(int month);

  /// Takes this year, which walks the panel down to its months.
  void panelPickYear(int year);

  /// Moves on by [pages] of whatever is on screen.
  void panelStep(int pages);

  /// Moves on by whole years.
  void panelStepYears(int years);

  /// Goes up a depth, or back down.
  void panelSetMode(DatePanelMode mode);
}

/// Which end of a range a day is.
enum PanelCap {
  /// Neither end.
  none,

  /// Where the range begins.
  start,

  /// Where it finishes.
  end,

  /// Both, for a range of one day.
  both,
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
    this.semanticsLabel,
    this.placement = PopoverPlacement.bottomLeft,
    this.open,
    this.onOpenChanged,
    this.inputReadOnly = false,
    this.status,
    this.prefix,
    this.suffixIcon,
    this.onClear,
    this.footerBuilder,
    this.showTime = false,
    this.disabledTime,
    this.presets = const [],
    this.cellBuilder,
    this.picker = DatePickerKind.day,
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
  final ControlSize? size;

  /// How the field is filled and bordered.
  final DatePickerVariant? variant;

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
  final ValueChanged<bool>? onOpenChanged;

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

  /// Whether the panel collects a time of day as well as a date.
  ///
  /// The columns stand beside the calendar and the value keeps its clock, so
  /// a day picked twice does not lose the hour chosen in between. Nothing is
  /// handed back until **Ok**: a date whose time is still being chosen is
  /// half an answer.
  ///
  /// A [format] that names no time is given `HH:mm:ss`, since a picker that
  /// collected a time and then wrote it nowhere would look broken.
  final bool showTime;

  /// Which values the time columns refuse.
  final DisabledTime? disabledTime;

  /// Named dates on a rail beside the panel.
  ///
  /// Empty by default, and the rail is not drawn at all where it is empty.
  final List<DatePreset> presets;

  /// Draws a day cell, given what the panel knows about it and the mark the
  /// panel would have drawn.
  final DateCellBuilder? cellBuilder;

  /// What the picker collects: a day, a week, a month, a quarter or a year.
  ///
  /// The value stays a [DateTime] — the first day of whatever was chosen — so
  /// nothing has to be converted on the way out and a week can be walked with
  /// arithmetic rather than with a type of its own.
  ///
  /// A [format] left alone is chosen to suit: `yyyy-[W]ww` for a week,
  /// `yyyy-MM` for a month, `yyyy-[Q]Q` for a quarter, `yyyy` for a year.
  final DatePickerKind picker;

  /// Per-instance token overrides.
  final DatePickerToken? token;

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> implements PanelHost {
  @override
  DateTime get panelCursor => _cursor;

  @override
  DatePanelMode get panelMode => _mode;

  @override
  bool get panelKeyed => _keyed;

  @override
  DateTime? get panelResting => _cursor;

  @override
  bool panelBlocks(DateTime day) => _isBlocked(day);

  @override
  bool panelChose(DateTime day) {
    final at = _shown;
    if (at == null) return false;
    // Every day of the row, for a picker collecting weeks: one press on any
    // of them is the same answer, so marking one and not the rest would say
    // the others were something else.
    if (widget.picker == DatePickerKind.week) {
      return _settle(day) == _settle(at);
    }
    return isSameDay(day, at);
  }

  @override
  void panelPick(DateTime day) => _pick(day);

  @override
  void panelPickMonth(int month) => _pickMonth(month);

  @override
  void panelPickYear(int year) => _pickYear(year);

  @override
  void panelStep(int pages) => _step(pages);

  @override
  void panelStepYears(int years) => _stepYears(years);

  @override
  void panelSetMode(DatePanelMode mode) => _setMode(mode);

  @override
  DateTime? get panelMarked => _shown;

  // A single date has no band to draw and no end to follow the pointer.
  @override
  bool panelWithin(DateTime day) => false;

  @override
  PanelCap panelCap(DateTime day) => PanelCap.none;

  @override
  void panelHover(DateTime? day) {}

  @override
  DateCellBuilder? get panelCellBuilder => widget.cellBuilder;

  @override
  DatePickerKind get panelKind => widget.picker;

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

  ControlSize get _size =>
      widget.size ??
      _defaults?.size ??
      ConfigProvider.componentSizeOf(context) ??
      SoftSize.middle;

  DatePickerVariant get _variant =>
      widget.variant ?? _defaults?.variant ?? DatePickerVariant.outlined;

  bool get _allowClear => widget.allowClear ?? _defaults?.allowClear ?? true;

  bool get _showToday => widget.showToday ?? _defaults?.showToday ?? true;

  bool get _enabled => !_disabled;

  /// The format the picker actually reads and writes.
  ///
  /// A picker told to collect a time and given a format that names none would
  /// take the hour and throw it away, so the clock is added on.
  /// Whether the caller left the format alone, in which case the picker
  /// chooses one to suit what it collects. A week written `yyyy-MM-dd` would
  /// name a day and mean seven of them.
  static const _defaultFormat = 'yyyy-MM-dd';

  String get _kindFormat => switch (widget.picker) {
        DatePickerKind.day => _defaultFormat,
        DatePickerKind.week => 'yyyy-[W]ww',
        DatePickerKind.month => 'yyyy-MM',
        DatePickerKind.quarter => 'yyyy-[Q]Q',
        DatePickerKind.year => 'yyyy',
      };

  String get _format {
    if (widget.format == _defaultFormat &&
        widget.picker != DatePickerKind.day) {
      return _kindFormat;
    }
    if (!widget.showTime) return widget.format;
    final fields = TimeFields.of(widget.format);
    if (fields.hour || fields.minute || fields.second) return widget.format;
    return '${widget.format} HH:mm:ss';
  }

  TimeFields get _timeFields => TimeFields.of(_format);

  /// What the panel is standing on: the draft while a time is being chosen,
  /// and the value itself otherwise.
  DateTime? get _shown => _draft ?? _value;

  /// The date and time being put together, held back until **Ok**.
  ///
  /// Only a panel that collects a time keeps one: a date on its own is
  /// finished the moment it is tapped, and there would be nothing to confirm.
  DateTime? _draft;

  /// The depth the panel opens at and comes back to. A month picker has no
  /// business showing days, and one that walked up to the years has to know
  /// where down is.
  DatePanelMode get _floor => switch (widget.picker) {
        DatePickerKind.day || DatePickerKind.week => DatePanelMode.day,
        DatePickerKind.month => DatePanelMode.month,
        DatePickerKind.quarter => DatePanelMode.quarter,
        DatePickerKind.year => DatePanelMode.year,
      };

  /// The clock the draft is carrying, or midnight where there is none.
  Duration get _draftTime {
    final at = _shown;
    if (at == null) return Duration.zero;
    return Duration(hours: at.hour, minutes: at.minute, seconds: at.second);
  }

  @override
  void initState() {
    super.initState();
    _internal = widget.defaultValue;
    _cursor = dateOnly(_value ?? DateTime.now());
    _focus.onKeyEvent = _onKey;
    // Born open: the same deferral, since the first build is a build too.
    if (widget.open ?? false) _obey(true);
    _popover.onClosed = () {
      if (!mounted || !_open) return;
      setState(() => _open = false);
      _syncText();
      widget.onOpenChanged?.call(false);
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
    if (!_focus.hasFocus) _syncText();
  }

  @override
  void didUpdateWidget(DatePicker old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || old.format != widget.format) {
      _syncText();
    }
    if (widget.open != null && widget.open != old.open) {
      _obey(widget.open!);
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
              _format,
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
    // The picker's own value is kept in step whether or not somebody else is
    // driving it. It is only the fallback for `value` — `value ?? _internal` —
    // and a stale one shows through the moment `value` goes null again, which
    // is exactly what clearing does. A picker cleared once, given a date, and
    // cleared again handed back null and then went on showing the date it had
    // been holding all along.
    setState(() => _internal = date);
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
      _format,
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
    widget.onOpenChanged?.call(next);
    if (widget.open == null) next ? _openPanel() : _closePanel();
  }

  void _openPanel() {
    if (_open || !_enabled) return;
    // Started from the value rather than from nothing: a picker reopened on
    // a date it already holds should mark it, and the clock beside it.
    if (widget.showTime) _draft = _value;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    setState(() {
      _open = true;
      _mode = _floor;
      _cursor = dateOnly(_value ?? DateTime.now());
      // A panel just opened has no day walked to yet.
      _keyed = false;
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
    _draft = null;
    if (!_open) return;
    setState(() => _open = false);
    _popover.close();
    _syncText();
  }

  /// Redraws the floating panel, which a `setState` here cannot reach.
  void _repaintPanel() => _revision.value++;

  // --- the keyboard ---

  /// Whether the cursor came from a key rather than from paging the panel.
  ///
  /// The month cursor is also the day the keyboard rests on, and marking a
  /// day nobody has walked to would put a grey box on the panel the moment it
  /// opened.
  bool _keyed = false;

  /// Moves the day the keyboard rests on, skipping the days that are barred.
  ///
  /// The month follows the cursor: stepping off the end of a month shows the
  /// next one, which is what the arrow means.
  void _walk(Duration by) {
    var next = dateOnly(_cursor.add(by));
    // A run of blocked days is stepped over rather than stopped at, up to a
    // year — beyond that the calendar has nothing to offer and the cursor
    // stays put.
    for (var guard = 0; _isBlocked(next) && guard < 366; guard++) {
      next = dateOnly(next.add(
          by.isNegative ? const Duration(days: -1) : const Duration(days: 1)));
    }
    if (_isBlocked(next)) return;
    setState(() {
      _cursor = next;
      _keyed = true;
    });
    _repaintPanel();
  }

  void _walkMonths(int months) {
    setState(() {
      _cursor = addMonths(_cursor, months);
      _keyed = true;
    });
    _repaintPanel();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final ltr = Directionality.maybeOf(context) != TextDirection.rtl;

    if (!_open) {
      // A downward arrow opens the panel, as it does on a menu; so does
      // Enter, since there is nothing else for it to do on a field whose
      // whole purpose is the panel.
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
      _pick(_cursor);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _walk(const Duration(days: 7));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _walk(const Duration(days: -7));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _walk(Duration(days: ltr ? 1 : -1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _walk(Duration(days: ltr ? -1 : 1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      _walkMonths(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      _walkMonths(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// The value a day stands for, given what the picker collects. A week is
  /// its first day, a quarter the first day of its first month: the answer is
  /// always a date, so nothing has to be converted on the way out.
  DateTime _settle(DateTime day) {
    final d = dateOnly(day);
    return switch (widget.picker) {
      DatePickerKind.day => d,
      DatePickerKind.week =>
        startOfWeek(d, firstDayOfWeek: context.seedLocale.firstDayOfWeek),
      DatePickerKind.month => DateTime(d.year, d.month),
      DatePickerKind.quarter => startOfQuarter(d),
      DatePickerKind.year => DateTime(d.year),
    };
  }

  void _pick(DateTime day) {
    if (_isBlocked(day)) return;
    setState(() => _cursor = dateOnly(day));
    if (widget.showTime) {
      // The clock the draft was already carrying, so a day picked twice does
      // not lose the hour chosen in between.
      final clock = _draftTime;
      setState(() => _draft = dateOnly(day).add(clock));
      _repaintPanel();
      return;
    }
    _commit(_settle(day));
    _syncText();
    _requestOpen(false);
  }

  /// Puts a time on the draft, leaving the day where it is.
  void _pickTime(Duration clock) {
    final day = dateOnly(_shown ?? _cursor);
    setState(() => _draft = day.add(clock));
    _repaintPanel();
  }

  /// Hands the draft over and puts the panel away.
  void _confirm() {
    final at = _draft;
    if (at == null) {
      _requestOpen(false);
      return;
    }
    _commit(at);
    _syncText();
    _requestOpen(false);
  }

  void _today() {
    if (!widget.showTime) {
      _pick(dateOnly(DateTime.now()));
      return;
    }
    // "Now" rather than "Today" where there is a clock to set: a footer that
    // moved the day and left the hour at midnight would be half an answer.
    final now = DateTime.now();
    if (_isBlocked(now)) return;
    setState(
      () => _draft = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
      ),
    );
    setState(() => _cursor = dateOnly(now));
    _repaintPanel();
  }

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
    if (widget.picker == DatePickerKind.month) {
      _pick(DateTime(_cursor.year, month));
      return;
    }
    setState(() {
      _cursor = DateTime(_cursor.year, month);
      _mode = DatePanelMode.day;
    });
    _repaintPanel();
  }

  void _pickYear(int year) {
    if (widget.picker == DatePickerKind.year) {
      _pick(DateTime(year));
      return;
    }
    if (widget.picker == DatePickerKind.quarter) {
      setState(() {
        _cursor = DateTime(year, _cursor.month);
        _mode = DatePanelMode.quarter;
      });
      _repaintPanel();
      return;
    }
    setState(() {
      _cursor = DateTime(year, _cursor.month);
      _mode = DatePanelMode.month;
    });
    _repaintPanel();
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
        _format,
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
        .resolve(t);
    _syncAnchor();

    final fontSize = _fontSize(t);
    // Whether there is anything to clear at all, and whether the mark for it
    // is on show. Two questions, because the target must not come and go with
    // the paint: a mark drawn only once `_hovered` has been through a
    // rebuild is a mark that is not there yet when the pointer arrives and
    // clicks in the same frame — a mouse coming straight from the panel, or
    // from the control beside it. The first click went to whatever the slot
    // held before, which opened the panel, and only the second one cleared.
    //
    // So the slot holds one target either way and decides what to do when it
    // is tapped, by which time `_hovered` is set whether or not a frame has
    // been painted.
    final canClear = _allowClear && _enabled && _value != null;
    // Open as well as hovered, as a Select's mark is: the panel covers the
    // pointer's way back to the field on a touchscreen, where there is no
    // hovering to be done.
    final showClear = canClear && (_hovered || _open);

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
                  if (canClear)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // Asked at the moment of the tap rather than settled
                      // when the slot was built.
                      onTap: () {
                        if (_hovered || _open) {
                          _clear();
                        } else {
                          _requestOpen(!_open);
                        }
                      },
                      // As tall as the field. The mark is drawn at the type
                      // size, so the target used to be fourteen pixels tall
                      // in the middle of a box more than twice that — aim a
                      // little high or a little low and the click went to the
                      // field instead, which opened the panel and looked
                      // exactly like a clear that had not worked. The glyph
                      // is the size it always was, and so is the slot: only
                      // what takes the pointer grew, and it grew where there
                      // was already room.
                      child: SizedBox(
                        height: _height(t),
                        width: fontSize,
                        child: Center(
                          child: showClear
                              ? CustomPaint(
                                  size: Size.square(fontSize),
                                  painter:
                                      ClearIconPainter(t.colorTextTertiary),
                                )
                              : widget.suffixIcon ??
                                  CustomPaint(
                                    size: Size.square(fontSize),
                                    painter: CalendarIconPainter(
                                      statusColor ?? t.colorTextQuaternary,
                                    ),
                                  ),
                        ),
                      ),
                    )
                  else
                    widget.suffixIcon ??
                        CustomPaint(
                          size: Size.square(fontSize),
                          painter: CalendarIconPainter(
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
        .resolve(t);

    final presets = state.widget.presets;
    // The columns stand beside the days and nowhere else: the months of a
    // year and the years of a decade are steps on the way to a day, and an
    // hour picked against them would belong to no date yet.
    final withTime = state.widget.showTime && state._mode == DatePanelMode.day;

    final grid = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: t.sizeSM,
        vertical: t.sizeXS,
      ),
      child: switch (state._mode) {
        DatePanelMode.day => DayGrid(state: state, token: r),
        DatePanelMode.quarter => QuarterGrid(state: state, token: r),
        DatePanelMode.month => MonthGrid(state: state, token: r),
        DatePanelMode.year => YearGrid(state: state, token: r),
      },
    );

    // Measured, not named. A popover hands its child loose constraints as
    // wide as the screen, and a column that stretches takes what it is
    // offered rather than what it needs — which is why a panel left alone
    // opens at full width. `IntrinsicWidth` asks the other question: how wide
    // do the children need to be, and stretch them to that.
    //
    // Adding the parts up instead would work today and rot tomorrow: the
    // number would have to know how many time columns the format asks for,
    // how wide a token says they are, and how many lines stand between them —
    // and it would still be wrong the first time a `footerBuilder` put
    // something wider underneath. The widths live in the widgets that own
    // them; nobody using the kit should have to add them up, this file
    // included.
    final calendar = IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHeader(state: state, token: r),
          Container(height: t.lineWidth, color: t.colorSplit),
          if (withTime)
            IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  grid,
                  Container(width: t.lineWidth, color: t.colorSplit),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: t.sizeXS),
                    // Seven rows deep: the six weeks and the row of weekday
                    // names above them, so the columns finish where the
                    // calendar does rather than leaving one side long.
                    child: TimeColumns(
                      fields: state._timeFields,
                      value: state._draftTime,
                      onChanged: state._pickTime,
                      cellHeight: r.cellHeight,
                      columnWidth: r.timeColumnWidth,
                      visibleRows: 7,
                      disabledTime: state.widget.disabledTime,
                    ),
                  ),
                ],
              ),
            )
          else
            grid,
          if (state._showToday || withTime) ...[
            Container(height: t.lineWidth, color: t.colorSplit),
            Padding(
              padding: EdgeInsets.all(t.sizeXS),
              // With a clock to set there are two things to say — where to
              // jump to, and that the answer is finished — so they take an
              // end each. Without one there is only Today, in the middle as
              // it always was.
              child: withTime
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (state._showToday)
                          _Action(label: words.now, onTap: state._today)
                        else
                          const SizedBox.shrink(),
                        _Action(label: words.ok, onTap: state._confirm),
                      ],
                    )
                  : Center(
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
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.colorBgElevated,
        borderRadius: BorderRadius.circular(r.borderRadius),
        boxShadow: t.boxShadowSecondary,
      ),
      // The rail leads, and it leads on the side the page reads from: a list
      // of names standing after the calendar in Arabic would be as odd as
      // one standing before it in English.
      child: presets.isEmpty
          ? calendar
          : IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PresetRail(state: state, token: r),
                  Container(width: t.lineWidth, color: t.colorSplit),
                  calendar,
                ],
              ),
            ),
    );
  }
}

/// The rail of named dates beside the panel.
///
/// As tall as the calendar and no taller — a long list scrolls inside it
/// rather than making the panel grow past the calendar it belongs to.
class _PresetRail extends StatelessWidget {
  const _PresetRail({required this.state, required this.token});

  final _DatePickerState state;

  /// The settled numbers the panel is drawn with.
  final DatePanelStyle token;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    return SizedBox(
      width: token.presetsWidth,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: t.sizeXS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final preset in state.widget.presets)
              _PresetTile(state: state, preset: preset),
          ],
        ),
      ),
    );
  }
}

class _PresetTile extends StatefulWidget {
  const _PresetTile({required this.state, required this.preset});

  final _DatePickerState state;
  final DatePreset preset;

  @override
  State<_PresetTile> createState() => _PresetTileState();
}

class _PresetTileState extends State<_PresetTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    // Asked now rather than kept: a preset reckoned from the clock has to be
    // read at the moment it is drawn, or a panel left open over midnight
    // would grey the wrong entry.
    final date = widget.preset.date;
    // A preset that lands on a day the calendar bars is greyed and does
    // nothing, exactly as Today is — a name on a rail that reached a blocked
    // day would be a way round the block.
    final blocked = widget.state._isBlocked(date);

    return Semantics(
      button: true,
      enabled: !blocked,
      child: MouseRegion(
        cursor:
            blocked ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Asked again here rather than handed the date the tile was drawn
          // with: a panel left open over midnight would otherwise take
          // yesterday.
          onTap: blocked ? null : () => widget.state._pick(widget.preset.date),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: t.sizeSM,
              vertical: t.sizeXXS,
            ),
            color: _hovered && !blocked ? t.colorFillTertiary : null,
            child: Text(
              widget.preset.label,
              style: TextStyle(
                fontSize: t.fontSize,
                height: t.lineHeight,
                fontFamily: t.fontFamily,
                fontFamilyFallback: t.fontFamilyFallback,
                color: blocked ? t.colorTextQuaternary : t.colorText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The panel's header: chevrons either side, and the way up in the middle.
/// The panel's header: chevrons either side, and the way up in the middle.
class PanelHeader extends StatelessWidget {
  /// Creates the header.
  const PanelHeader({
    required this.state,
    required this.token,
    this.back = true,
    this.forward = true,
    super.key,
  });

  /// Which chevrons this header carries. A range panel puts the backward one
  /// on its left month and the forward one on its right, since the two move
  /// together and a chevron between them would say nothing.
  /// Whether the backward chevron is drawn.
  final bool back;

  /// Whether the forward one is.
  final bool forward;

  /// Whatever is driving the panel.
  final PanelHost state;

  /// The settled numbers the panel is drawn with.
  final DatePanelStyle token;

  @override
  Widget build(BuildContext context) {
    final words = context.seedLocale;
    final cursor = state.panelCursor;

    final label = switch (state.panelMode) {
      DatePanelMode.day =>
        '${words.shortMonths[cursor.month - 1]} ${words.figures('${cursor.year}')}',
      DatePanelMode.quarter ||
      DatePanelMode.month =>
        words.figures('${cursor.year}'),
      DatePanelMode.year =>
        '${words.figures('${cursor.year - cursor.year % 10}')}'
            '–${words.figures('${cursor.year - cursor.year % 10 + 9}')}',
    };

    // A day panel steps by month; the deeper panels step by year and decade,
    // so one chevron always moves one page of what is on screen.
    final backward = switch (state.panelMode) {
      DatePanelMode.day => () => state.panelStep(-1),
      DatePanelMode.quarter || DatePanelMode.month => () =>
          state.panelStepYears(-1),
      DatePanelMode.year => () => state.panelStepYears(-10),
    };
    final onward = switch (state.panelMode) {
      DatePanelMode.day => () => state.panelStep(1),
      DatePanelMode.quarter || DatePanelMode.month => () =>
          state.panelStepYears(1),
      DatePanelMode.year => () => state.panelStepYears(10),
    };

    final up = switch (state.panelMode) {
      DatePanelMode.day => () => state.panelSetMode(DatePanelMode.month),
      // A quarter panel has nowhere deeper to be: its header is the year, and
      // the way up from a year is the decade.
      DatePanelMode.quarter || DatePanelMode.month => () =>
          state.panelSetMode(DatePanelMode.year),
      DatePanelMode.year => null,
    };

    return SizedBox(
      height: token.headerHeight,
      child: Row(
        children: [
          // Named, because a painted chevron says nothing to a screen
          // reader. The kit already has both words, for Tour's own buttons.
          if (back)
            _Chevron(back: true, onTap: backward, label: words.previous)
          else
            SizedBox(width: token.headerHeight),
          Expanded(
            child: _Action(label: label, onTap: up, centred: true),
          ),
          if (forward)
            _Chevron(back: false, onTap: onward, label: words.next)
          else
            SizedBox(width: token.headerHeight),
        ],
      ),
    );
  }
}

/// The six weeks of one month.
/// The six weeks of one month.
///
/// Built against a [PanelHost], so the picker collecting a date and the one
/// collecting a range draw the same grid and differ only in what they say
/// about each day.
class DayGrid extends StatelessWidget {
  /// Creates the grid.
  const DayGrid({required this.state, required this.token, super.key});

  /// Whatever is driving the panel.
  final PanelHost state;

  /// The settled numbers the panel is drawn with.
  final DatePanelStyle token;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final words = context.seedLocale;
    final cursor = state.panelCursor;
    final today = dateOnly(DateTime.now());

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
                width: token.dayPitchWidth,
                height: token.dayPitchHeight,
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
                    final cell = _Cell(
                      label: words.figures('${day.day}'),
                      width: token.dayPitchWidth,
                      height: token.dayPitchHeight,
                      markHeight: token.cellHeight,
                      inset: token.crossAxisSpacing,
                      // Days from the months either side are drawn faintly:
                      // they are reachable, but they are not this month.
                      outside: !isSameMonth(day, cursor),
                      today: isSameDay(day, today),
                      chosen: state.panelChose(day),
                      within: state.panelWithin(day),
                      cap: state.panelCap(day),
                      onHover: (over) => state.panelHover(over ? day : null),
                      resting: state.panelKeyed &&
                          state.panelResting != null &&
                          isSameDay(day, state.panelResting!),
                      disabled: state.panelBlocks(day),
                      onTap: () => state.panelPick(day),
                    );
                    final draw = state.panelCellBuilder;
                    if (draw == null) return cell;
                    // Handed what the panel would have drawn, so a caller
                    // adding a dot under a day does not have to work out for
                    // themselves what chosen or today look like.
                    return draw(
                      context,
                      DateCell(
                        date: day,
                        today: isSameDay(day, today),
                        chosen: state.panelChose(day),
                        within: state.panelWithin(day),
                        outside: !isSameMonth(day, cursor),
                        disabled: state.panelBlocks(day),
                        resting: state.panelKeyed &&
                            state.panelResting != null &&
                            isSameDay(day, state.panelResting!),
                      ),
                      cell,
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
/// The four quarters of one year.
class QuarterGrid extends StatelessWidget {
  /// Creates the grid.
  const QuarterGrid({required this.state, required this.token, super.key});

  /// Whatever is driving the panel.
  final PanelHost state;

  /// The settled numbers the panel is drawn with.
  final DatePanelStyle token;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final words = context.seedLocale;
    final cursor = state.panelCursor;
    final chosen = state.panelMarked;
    final width = token.gridWidth / 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 2; row++)
          Row(
            children: [
              for (var col = 0; col < 2; col++)
                Builder(
                  builder: (context) {
                    final quarter = row * 2 + col + 1;
                    final first = DateTime(cursor.year, (quarter - 1) * 3 + 1);
                    return _Cell(
                      label: words.quarters[quarter - 1],
                      width: width,
                      height: token.cellHeight * 2.4,
                      markHeight: t.controlHeightSM,
                      inset: token.crossAxisSpacing,
                      outside: false,
                      today: false,
                      chosen: chosen != null &&
                          chosen.year == cursor.year &&
                          quarterOf(chosen) == quarter,
                      disabled: state.panelBlocks(first),
                      onTap: () => state.panelPick(first),
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
class MonthGrid extends StatelessWidget {
  /// Creates the grid.
  const MonthGrid({required this.state, required this.token, super.key});

  /// Whatever is driving the panel.
  final PanelHost state;

  /// The settled numbers the panel is drawn with.
  final DatePanelStyle token;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final words = context.seedLocale;
    final cursor = state.panelCursor;
    final chosen = state.panelMarked;
    final width = token.gridWidth / 3;

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
                      markHeight: t.controlHeightSM,
                      inset: token.crossAxisSpacing,
                      outside: false,
                      today: false,
                      chosen: chosen != null &&
                          chosen.year == cursor.year &&
                          chosen.month == month,
                      disabled: false,
                      onTap: () => state.panelPickMonth(month),
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
/// The ten years of one decade, with the one either side.
class YearGrid extends StatelessWidget {
  /// Creates the grid.
  const YearGrid({required this.state, required this.token, super.key});

  /// Whatever is driving the panel.
  final PanelHost state;

  /// The settled numbers the panel is drawn with.
  final DatePanelStyle token;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final words = context.seedLocale;
    final cursor = state.panelCursor;
    final chosen = state.panelMarked;
    final start = cursor.year - cursor.year % 10;
    final width = token.gridWidth / 3;

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
                      markHeight: t.controlHeightSM,
                      inset: token.crossAxisSpacing,
                      outside: year < start || year > start + 9,
                      today: false,
                      chosen: chosen != null && chosen.year == year,
                      disabled: false,
                      onTap: () => state.panelPickYear(year),
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
    this.resting = false,
    this.within = false,
    this.cap = PanelCap.none,
    this.onHover,
    required this.markHeight,
    required this.inset,
  });

  final String label;
  final double width;
  final double height;
  final bool outside;
  final bool today;
  final bool chosen;

  /// Whether the keyboard is resting on this cell: the mark the pointer
  /// leaves, so a reader who swaps hands sees one thing.
  final bool resting;
  final bool disabled;
  final VoidCallback onTap;

  /// Whether this day lies inside a range, between its two ends.
  final bool within;

  /// Which end of a range this day is, where it is one.
  final PanelCap cap;

  /// Told when the pointer comes and goes, so a range being drawn can
  /// follow it.
  final ValueChanged<bool>? onHover;

  /// How tall the mark inside the cell stands. What is left over is the air
  /// between this row and the next.
  final double markHeight;

  /// How much of the cell's width the mark gives up, half at each side. The
  /// band under a range keeps the whole width, so a stretch joins up.
  final double inset;

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    // The band under a range: its ends are rounded, its middle is not, so a
    // run of days reads as one stretch rather than a row of separate marks.
    final capped = widget.cap != PanelCap.none;
    final banded = widget.within || capped;
    final band =
        banded && !widget.disabled ? t.primary.bg : const Color(0x00000000);
    final round = Radius.circular(t.borderRadiusSM);
    final capStart = widget.cap == PanelCap.start || widget.cap == PanelCap.both
        ? round
        : Radius.zero;
    final capEnd = widget.cap == PanelCap.end || widget.cap == PanelCap.both
        ? round
        : Radius.zero;

    final Color background;
    if (widget.chosen && !widget.disabled) {
      background = t.primary.base;
    } else if ((_hovered || widget.resting) && !widget.disabled) {
      // Grey is the hover of a day standing on the panel's own ground. A day
      // already inside a band has the band under it, and grey over that is a
      // flash of the wrong colour every time the pointer crosses one.
      background = banded ? t.primary.bgHover : t.colorFillTertiary;
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
      onEnter: (_) {
        setState(() => _hovered = true);
        widget.onHover?.call(true);
      },
      onExit: (_) {
        setState(() => _hovered = false);
        widget.onHover?.call(false);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.disabled ? null : widget.onTap,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Center(
            // The band runs the whole width of the cell so the days inside a
            // range join up sideways, with the gap the pills leave closed —
            // but only as tall as a pill, so the weeks keep the gap between
            // them. Full height and one week would run into the next, and a
            // month of days would read as a single grey block.
            child: SizedBox(
              width: widget.width,
              height: widget.markHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: band,
                  borderRadius: BorderRadiusDirectional.horizontal(
                    start: capStart,
                    end: capEnd,
                  ),
                ),
                child: Center(
                  child: AnimatedContainer(
                    // A pick lands at once; only the hover tint eases in. Easing
                    // from the hover grey to the chosen fill shows the grey on the
                    // way, which reads as a flash under the finger.
                    duration:
                        widget.chosen ? Duration.zero : t.motionDurationMid,
                    curve: t.motionEaseInOut,
                    width: widget.width - widget.inset,
                    height: widget.markHeight,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(t.borderRadiusSM),
                      // Today is an outline, not a fill: otherwise the day that is
                      // both today and the chosen one could not be told apart.
                      border: widget.today && !widget.chosen
                          ? Border.all(
                              color: t.primary.base, width: t.lineWidth)
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
/// The calendar mark a picker wears while it holds nothing to clear.
class CalendarIconPainter extends CustomPainter {
  /// Creates the mark.
  const CalendarIconPainter(this.color);

  /// What it is drawn in.
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
  bool shouldRepaint(CalendarIconPainter old) => old.color != color;
}
