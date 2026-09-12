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
import '../data_entry/input.dart' show InputStatus;
import '../general/compact.dart';
import 'date_picker.dart';

/// Two dates and everything between them.
///
/// Both ends are days at midnight, and [start] never comes after [end] — a
/// range built the other way round turns itself over, since a reader dragging
/// backwards through a calendar means the same stretch of time.
@immutable
class DateRange {
  /// Creates a range, putting the two ends in order.
  DateRange(DateTime start, DateTime end)
      : start = dateOnly(start.isAfter(end) ? end : start),
        end = dateOnly(start.isAfter(end) ? start : end);

  /// The day the range opens on.
  final DateTime start;

  /// The day it closes on, which is inside the range.
  final DateTime end;

  /// How many days the range covers, both ends counted.
  int get days => end.difference(start).inDays + 1;

  /// Whether this day falls inside the range, ends included.
  bool holds(DateTime day) {
    final d = dateOnly(day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange($start – $end)';
}

/// A named stretch of time on the rail beside the panel.
///
/// The range is asked for when the preset is taken rather than when the panel
/// is built, so "the last seven days" means seven days ending today rather
/// than seven days ending whenever the field was drawn.
class DateRangePreset {
  /// A preset standing for a range that is already known.
  const DateRangePreset(this.label, DateRange range)
      : _range = range,
        _asked = null;

  /// A preset that works its range out when it is taken.
  const DateRangePreset.of(this.label, DateRange Function() range)
      : _asked = range,
        _range = null;

  /// What the rail calls it.
  final String label;

  final DateRange? _range;
  final DateRange Function()? _asked;

  /// The stretch this preset stands for, now.
  DateRange get range => _range ?? _asked!();
}

/// Defaults for every [DateRangePicker] under a `ConfigProvider`.
@immutable
class DateRangePickerDefaults {
  /// Creates a [DateRangePickerDefaults].
  const DateRangePickerDefaults({
    this.variant,
    this.allowClear,
    this.size,
    this.disabled,
  });

  /// How pickers are filled and bordered.
  final DatePickerVariant? variant;

  /// Whether pickers carry a clear button once a range is set.
  final bool? allowClear;

  /// Which control height a picker takes, unless it names one.
  final ControlSize? size;

  /// Whether a picker is disabled, unless it says otherwise.
  final bool? disabled;
}

/// A field that collects a stretch of days.
///
/// ```dart
/// DateRangePicker(
///   value: _holiday,
///   onChanged: (range) => setState(() => _holiday = range),
/// )
/// ```
///
/// Its own component rather than a flag on [DatePicker]: a range is picked in
/// two goes, the second constrained by the first, and it is drawn as a band
/// rather than a mark. Bolting that onto a picker that collects one date
/// would leave both harder to read.
///
/// The panel shows two months side by side, because a range that crosses a
/// month is the ordinary case and turning the page mid-drag loses the thread.
class DateRangePicker extends StatefulWidget {
  /// Creates a [DateRangePicker].
  const DateRangePicker({
    super.key,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.format = 'yyyy-MM-dd',
    this.disabledDate,
    this.minDate,
    this.maxDate,
    this.minDays,
    this.maxDays,
    this.allowClear,
    this.disabled,
    this.size,
    this.variant,
    this.startPlaceholder,
    this.endPlaceholder,
    this.semanticsLabel,
    this.placement = PopoverPlacement.bottomLeft,
    this.open,
    this.onOpenChanged,
    this.status,
    this.prefix,
    this.suffixIcon,
    this.onClear,
    this.footerBuilder,
    this.presets = const [],
    this.cellBuilder,
    this.token,
  });

  /// The range shown.
  ///
  /// Null hands the picker to itself: it keeps what is chosen, starting from
  /// [defaultValue].
  final DateRange? value;

  /// What an uncontrolled picker starts with.
  final DateRange? defaultValue;

  /// Called with the whole range once both ends are in, and with null when
  /// the field is cleared. Never called halfway: one end is not a range.
  final ValueChanged<DateRange?>? onChanged;

  /// How each end is written out. The grammar is [DatePicker]'s.
  final String format;

  /// Asked about every day the panel draws.
  final bool Function(DateTime day)? disabledDate;

  /// The earliest day on offer.
  final DateTime? minDate;

  /// The latest.
  final DateTime? maxDate;

  /// How short and how long a range may be, in days, both ends counted.
  ///
  /// Told while the second end is being chosen, so the days that would make
  /// too short or too long a range are barred rather than refused after the
  /// fact.
  /// The shortest range allowed.
  final int? minDays;

  /// The longest.
  final int? maxDays;

  /// Whether a set range may be dropped.
  final bool? allowClear;

  /// Whether the field is barred.
  final bool? disabled;

  /// The control height, as a preset or a measurement.
  final ControlSize? size;

  /// How the field is filled and bordered.
  final DatePickerVariant? variant;

  /// What the leading half says while it is empty. The locale's own word by
  /// default.
  final String? startPlaceholder;

  /// And the trailing half.
  final String? endPlaceholder;

  /// Names a field whose label is written outside it.
  final String? semanticsLabel;

  /// Where the panel opens.
  final PopoverPlacement placement;

  /// Drives the panel from outside.
  final bool? open;

  /// Reports what the picker would have done with its panel.
  final ValueChanged<bool>? onOpenChanged;

  /// Marks the field as questionable or wrong.
  final InputStatus? status;

  /// Sits before the value.
  final Widget? prefix;

  /// Replaces the calendar mark.
  final Widget? suffixIcon;

  /// Called after the range is dropped.
  final VoidCallback? onClear;

  /// Adds a row of your own beneath the panel.
  final WidgetBuilder? footerBuilder;

  /// Named stretches on a rail beside the panel.
  final List<DateRangePreset> presets;

  /// Draws a day cell, given what the panel knows about it and the mark the
  /// panel would have drawn.
  final DateCellBuilder? cellBuilder;

  /// Per-instance token overrides. The panel is [DatePicker]'s, so its
  /// numbers are too.
  final DatePickerToken? token;

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

/// Which end the panel is waiting for.
enum _Half { start, end }

class _DateRangePickerState extends State<DateRangePicker>
    implements PanelHost {
  final PopoverController _popover = PopoverController();
  final FocusNode _focus = FocusNode();
  final ValueNotifier<Rect> _anchor = ValueNotifier(Rect.zero);

  /// Rebuilt on its own: the panel lives in the overlay, where a `setState`
  /// here does not reach.
  final ValueNotifier<int> _revision = ValueNotifier(0);

  bool _open = false;
  bool _hovered = false;
  DateRange? _internal;

  /// The end being chosen, and the one already down.
  ///
  /// A range is picked in two goes. The first tap puts an anchor down and the
  /// panel then draws from it to wherever the pointer is, so the reader sees
  /// the stretch they are about to take before they take it.
  _Half _half = _Half.start;
  DateTime? _anchorDay;
  DateTime? _preview;

  /// The month the left pane looks at. The right is always the next one: two
  /// panes showing the same month would be a wasted half.
  late DateTime _cursor;
  DatePanelMode _mode = DatePanelMode.day;

  /// Which pane the deeper modes belong to, so picking a month in the right
  /// pane moves the right pane.
  bool _deepIsRight = false;

  bool _keyed = false;

  /// The day the keyboard rests on. Walking is not picking: a reader stepping
  /// through the month with the arrows has not chosen anything until they
  /// press enter.
  DateTime? _walk;

  DateRange? get _value => widget.value ?? _internal;

  DateRangePickerDefaults? get _defaults =>
      ConfigProvider.defaultsOf<DateRangePickerDefaults>(context);

  bool get _disabled =>
      widget.disabled ??
      _defaults?.disabled ??
      ConfigProvider.componentDisabledOf(context) ??
      false;

  bool get _enabled => !_disabled;

  ControlSize get _size =>
      widget.size ??
      _defaults?.size ??
      ConfigProvider.componentSizeOf(context) ??
      SoftSize.middle;

  DatePickerVariant get _variant =>
      widget.variant ?? _defaults?.variant ?? DatePickerVariant.outlined;

  bool get _allowClear => widget.allowClear ?? _defaults?.allowClear ?? true;

  @override
  void initState() {
    super.initState();
    _internal = widget.defaultValue;
    _cursor = dateOnly(_value?.start ?? DateTime.now());
    _focus.onKeyEvent = _onKey;
    if (widget.open ?? false) _obey(true);
    _popover.onClosed = () {
      if (!mounted || !_open) return;
      setState(() {
        _open = false;
        _half = _Half.start;
        _anchorDay = null;
        _preview = null;
        _walk = null;
      });
      widget.onOpenChanged?.call(false);
    };
  }

  void _obey(bool open) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      open ? _openPanel() : _closePanel();
    });
  }

  @override
  void didUpdateWidget(DateRangePicker old) {
    super.didUpdateWidget(old);
    if (widget.open != null && widget.open != old.open) _obey(widget.open!);
  }

  @override
  void dispose() {
    _popover.dispose();
    _focus.dispose();
    _anchor.dispose();
    _revision.dispose();
    super.dispose();
  }

  void _repaintPanel() => _revision.value++;

  // --------------------------------------------------------------------------
  // Availability
  // --------------------------------------------------------------------------

  bool _isBlocked(DateTime day) {
    final d = dateOnly(day);
    final min = widget.minDate;
    final max = widget.maxDate;
    if (min != null && d.isBefore(dateOnly(min))) return true;
    if (max != null && d.isAfter(dateOnly(max))) return true;
    if (widget.disabledDate?.call(d) ?? false) return true;
    // While the second end is being chosen, a day that would make a range
    // too short or too long is barred rather than refused afterwards: a
    // refusal that arrives after the tap is a refusal nobody saw coming.
    final from = _anchorDay;
    if (from == null || _half != _Half.end) return false;
    final span = d.difference(from).inDays.abs() + 1;
    if (widget.minDays != null && span < widget.minDays!) return true;
    if (widget.maxDays != null && span > widget.maxDays!) return true;
    return false;
  }

  // --------------------------------------------------------------------------
  // Picking
  // --------------------------------------------------------------------------

  /// The stretch the panel is drawing: the range it holds, or the one being
  /// dragged out from the anchor towards the pointer.
  DateRange? get _drawn {
    final from = _anchorDay;
    if (from != null) {
      final to = _preview;
      return to == null ? DateRange(from, from) : DateRange(from, to);
    }
    return _value;
  }

  void _pick(DateTime day) {
    if (_isBlocked(day)) return;
    final d = dateOnly(day);
    if (_half == _Half.start) {
      setState(() {
        _anchorDay = d;
        _preview = d;
        _half = _Half.end;
      });
      _repaintPanel();
      return;
    }
    final from = _anchorDay!;
    final range = DateRange(from, d);
    setState(() {
      _anchorDay = null;
      _preview = null;
      _walk = null;
      _half = _Half.start;
      _internal = range;
    });
    widget.onChanged?.call(range);
    _requestOpen(false);
  }

  void _clear() {
    setState(() {
      _internal = null;
      _anchorDay = null;
      _preview = null;
      _half = _Half.start;
    });
    widget.onChanged?.call(null);
    widget.onClear?.call();
  }

  void _takePreset(DateRangePreset preset) {
    final range = preset.range;
    if (_isBlocked(range.start) || _isBlocked(range.end)) return;
    setState(() {
      _internal = range;
      _anchorDay = null;
      _preview = null;
      _half = _Half.start;
      _cursor = dateOnly(range.start);
    });
    widget.onChanged?.call(range);
    _requestOpen(false);
  }

  // --------------------------------------------------------------------------
  // What the panel asks
  // --------------------------------------------------------------------------

  @override
  DateTime get panelCursor => _cursor;

  @override
  DatePanelMode get panelMode => _mode;

  @override
  bool get panelKeyed => _keyed;

  @override
  DateTime? get panelResting => _keyed ? _walk : null;

  @override
  DateTime? get panelMarked => _drawn?.start;

  @override
  bool panelBlocks(DateTime day) => _isBlocked(day);

  @override
  bool panelChose(DateTime day) {
    final range = _drawn;
    if (range == null) return false;
    return isSameDay(day, range.start) || isSameDay(day, range.end);
  }

  @override
  bool panelWithin(DateTime day) {
    final range = _drawn;
    if (range == null) return false;
    return range.holds(day) && !panelChose(day);
  }

  @override
  PanelCap panelCap(DateTime day) {
    final range = _drawn;
    if (range == null) return PanelCap.none;
    final atStart = isSameDay(day, range.start);
    final atEnd = isSameDay(day, range.end);
    if (atStart && atEnd) return PanelCap.both;
    if (atStart) return PanelCap.start;
    if (atEnd) return PanelCap.end;
    return PanelCap.none;
  }

  @override
  DateCellBuilder? get panelCellBuilder => widget.cellBuilder;

  // A range is a stretch of days either way; there is no week or quarter
  // picker to be a range of yet.
  @override
  DatePickerKind get panelKind => DatePickerKind.day;

  @override
  void panelHover(DateTime? day) {
    // Only while an end is being dragged out: a pointer wandering over a
    // settled range should not redraw it.
    if (_half != _Half.end || _anchorDay == null) return;
    if (day != null && _isBlocked(day)) return;
    if (day == null || isSameDay(day, _preview ?? day)) {
      if (day == null) return;
    }
    _preview = day;
    _repaintPanel();
  }

  @override
  void panelPick(DateTime day) => _pick(day);

  @override
  void panelPickMonth(int month) {
    setState(() {
      final year = _cursor.year;
      _cursor = _deepIsRight
          ? addMonths(DateTime(year, month), -1)
          : DateTime(year, month);
      _mode = DatePanelMode.day;
    });
    _repaintPanel();
  }

  @override
  void panelPickYear(int year) {
    setState(() {
      _cursor = DateTime(year, _cursor.month);
      _mode = DatePanelMode.month;
    });
    _repaintPanel();
  }

  @override
  void panelStep(int pages) {
    setState(() => _cursor = addMonths(_cursor, pages));
    _repaintPanel();
  }

  @override
  void panelStepYears(int years) {
    setState(() => _cursor = addMonths(_cursor, years * 12));
    _repaintPanel();
  }

  @override
  void panelSetMode(DatePanelMode mode) {
    setState(() => _mode = mode);
    _repaintPanel();
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
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    setState(() {
      _open = true;
      _mode = DatePanelMode.day;
      _half = _Half.start;
      _anchorDay = null;
      _preview = null;
      _cursor = dateOnly(_value?.start ?? DateTime.now());
      _keyed = false;
    });
    _syncAnchor();
    final token = context.softToken;
    _popover.open(
      placement: widget.placement,
      anchorRect: _anchor.value,
      gap: token.sizeXXS,
      onDismiss: () => _requestOpen(false),
      dismissExcludesAnchor: true,
      anchorContext: context,
      onScrollDismiss: () => _requestOpen(false),
      builder: (context) => ListenableBuilder(
        listenable: _revision,
        builder: (context, _) => _RangePanel(state: this),
      ),
    );
  }

  void _closePanel() {
    if (!_open) return;
    _popover.close();
    setState(() {
      _open = false;
      _half = _Half.start;
      _anchorDay = null;
      _preview = null;
    });
  }

  void _syncAnchor() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (_anchor.value != rect) _anchor.value = rect;
  }

  // --------------------------------------------------------------------------
  // Keyboard
  // --------------------------------------------------------------------------

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (!_open) {
      if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.enter) {
        _requestOpen(true);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.escape) {
      _requestOpen(false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter) {
      final at = _walk;
      if (at != null) _pick(at);
      return KeyEventResult.handled;
    }

    // The keyboard walks the day it would take next: the anchor while the
    // range is still to be opened, the far end once it is.
    final ltr = Directionality.of(context) == TextDirection.ltr;
    Duration? by;
    if (key == LogicalKeyboardKey.arrowLeft) {
      by = Duration(days: ltr ? -1 : 1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      by = Duration(days: ltr ? 1 : -1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      by = const Duration(days: -7);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      by = const Duration(days: 7);
    }
    if (by == null) return KeyEventResult.ignored;

    var next = dateOnly((_walk ?? _value?.start ?? _cursor).add(by));
    // A barred day is stepped over rather than stopped at, up to a year out,
    // which is further than any run of blocked days a calendar draws.
    for (var i = 0; i < 366 && _isBlocked(next); i++) {
      next = dateOnly(next.add(by));
    }
    if (_isBlocked(next)) return KeyEventResult.handled;
    setState(() {
      _keyed = true;
      _walk = next;
      // With an anchor already down the band follows the walk, so the reader
      // sees the stretch they would take. With none it follows nothing:
      // there is no range yet to draw.
      if (_anchorDay != null) _preview = next;
      if (!isSameMonth(next, _cursor) &&
          !isSameMonth(next, addMonths(_cursor, 1))) {
        _cursor = DateTime(next.year, next.month);
      }
    });
    _repaintPanel();
    return KeyEventResult.handled;
  }

  // --------------------------------------------------------------------------
  // The field
  // --------------------------------------------------------------------------

  double _height(Token t) => _size.resolveHeight(
        small: t.controlHeightSM,
        middle: t.controlHeight,
        large: t.controlHeightLG,
      );

  /// A preset carries a type size of its own; a measurement names only
  /// itself, so the standard one stands.
  double _fontSize(Token t) =>
      _size == SoftSize.large ? t.fontSizeLG : t.fontSize;

  String _write(DateTime? day, SeedLocalizations words) => day == null
      ? ''
      : words.figures(
          formatDate(
            day,
            widget.format,
            months: words.shortMonths,
            weekdays: words.shortWeekdays,
            am: words.am,
            pm: words.pm,
          ),
        );

  /// How wide one half needs to be: the longest the format can write, or the
  /// placeholder, whichever asks for more.
  double _halfWidth(TextStyle style, SeedLocalizations words) {
    double measure(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      return painter.width;
    }

    // A date wide in every field, so no real one comes out longer.
    final widest = _write(DateTime(2026, 12, 28, 23, 59, 59), words);
    final longest = [
      measure(widest),
      measure(widget.startPlaceholder ?? words.startDate),
      measure(widget.endPlaceholder ?? words.endDate),
    ].reduce((a, b) => a > b ? a : b);
    // The room inside the tint counts: without it the half is exactly as wide
    // as its longest word and the padding pushes it into an ellipsis.
    return longest + _litPad * 2;
  }

  /// How much room the tint keeps around the words in it.
  double get _litPad => context.softToken.sizeXXS;

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
    final canClear = _allowClear && _enabled && _value != null;
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
      fontWeight: t.fontWeight,
      height: 1.0,
      leadingDistribution: TextLeadingDistribution.even,
      decoration: TextDecoration.none,
    );

    final drawn = _drawn;
    final halfWidth = _halfWidth(textStyle, words);

    // What each half actually gets, and it is the same for both — which is
    // what puts the arrow exactly between them. Two halves of different
    // widths would leave the mark nearer one date than the other, and a mark
    // meaning "from here to there" has to sit in the middle to say it.
    //
    // Told a width, the halves share whatever is left after the furniture,
    // however wide that is: the field fills what it was given rather than
    // hugging the start and leaving the arrow off-centre. Merely offered an
    // upper bound, they take what the format needs and give way when there is
    // less — the same rule the single picker follows.
    double share(BoxConstraints room) {
      if (!room.hasBoundedWidth) return halfWidth;
      final furniture = t.sizeSM * 2 +
          t.lineWidth * 2 +
          fontSize * 2 +
          t.sizeXS * 3 +
          (widget.prefix != null ? t.sizeXS : 0);
      final each = (room.maxWidth - furniture) / 2;
      if (each <= 0) return 0;
      final told = room.maxWidth == room.minWidth;
      if (told) return each;
      return each < halfWidth ? each : halfWidth;
    }

    Widget half(String written, String placeholder, double width,
            {required bool lit}) =>
        SizedBox(
          width: width,
          child: DecoratedBox(
            // The half being filled in is marked, so a reader who has put one
            // end down can see which one the panel is waiting for.
            decoration: BoxDecoration(
              color: lit ? t.primary.bg : const Color(0x00000000),
              borderRadius: BorderRadius.circular(t.borderRadiusSM),
            ),
            // Room inside the tint. Without it the mark is drawn hard against
            // the letters, which reads as a box that is too small for what is
            // in it rather than as the half being pointed at.
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _litPad,
                vertical: _litPad / 2,
              ),
              child: Text(
                written.isEmpty ? placeholder : written,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // Centred in its half, so the mark between them is as far from
                // one date as from the other. Pushed to the start, as a single
                // field's value is, the left date sits away from the mark and
                // the right one against it — and a mark meaning "from here to
                // there" stops reading as between them at all.
                textAlign: TextAlign.center,
                style: written.isEmpty
                    ? textStyle.copyWith(color: t.colorTextTertiary)
                    : textStyle,
              ),
            ),
          ),
        );

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
            builder: (context, room) {
              final each = share(room);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.prefix != null) ...[
                    widget.prefix!,
                    SizedBox(width: t.sizeXS),
                  ],
                  half(
                    _write(drawn?.start, words),
                    widget.startPlaceholder ?? words.startDate,
                    each,
                    lit: _open && _half == _Half.start,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: t.sizeXS),
                    child: SizedBox(
                      width: fontSize,
                      height: fontSize,
                      child: CustomPaint(
                        painter: RangeArrowPainter(t.colorTextQuaternary),
                      ),
                    ),
                  ),
                  half(
                    _write(
                      // While the second end is being dragged out the far end is
                      // the one under the pointer, so the field reads as the
                      // panel draws.
                      _anchorDay == null ? drawn?.end : _preview,
                      words,
                    ),
                    widget.endPlaceholder ?? words.endDate,
                    each,
                    lit: _open && _half == _Half.end,
                  ),
                  SizedBox(width: t.sizeXS),
                  if (canClear)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_hovered || _open) {
                          _clear();
                        } else {
                          _requestOpen(!_open);
                        }
                      },
                      // As tall as the field: see `DatePicker`, where the same
                      // slot is built the same way and for the same reason.
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

    return Semantics(
      button: true,
      enabled: _enabled,
      expanded: _open,
      label: widget.semanticsLabel,
      value: drawn == null
          ? null
          : '${_write(drawn.start, words)} – ${_write(drawn.end, words)}',
      validationResult: widget.status == InputStatus.error
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: Focus(
        focusNode: _focus,
        child: named == null ? control : SizedBox(width: named, child: control),
      ),
    );
  }
}

/// Two months side by side, with the rail and the footer beneath them.
class _RangePanel extends StatelessWidget {
  const _RangePanel({required this.state});

  final _DateRangePickerState state;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (state.widget.token ??
            ConfigProvider.componentOf<DatePickerToken>(context) ??
            const DatePickerToken())
        .resolve(t);

    final presets = state.widget.presets;
    final paneWidth = r.gridWidth + t.sizeSM * 2;
    // What the panel would like: two months, the line between them, and the
    // rail where there is one.
    final wants = paneWidth * 2 +
        t.lineWidth +
        (presets.isEmpty ? 0 : r.presetsWidth + t.lineWidth);
    // What a popover can actually give it, which on a phone is the window
    // less the inset it keeps from the edges.
    final room = MediaQuery.sizeOf(context).width - t.sizeSM * 2;
    // Under rather than beside. A month that does not fit is a month nobody
    // can see: the second pane cannot be scrolled to sideways, since the
    // panel is as wide as it is drawn.
    final stacked = room < wants;

    Widget panes;
    if (state._mode != DatePanelMode.day) {
      // The deeper panels belong to one pane: months and years are steps on
      // the way to a day, and two decades side by side would be two ways of
      // answering the same question.
      panes = _Pane(state: state, token: r, right: false);
    } else if (stacked) {
      panes = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Pane(state: state, token: r, right: false),
          Container(height: t.lineWidth, color: t.colorSplit),
          _Pane(state: state, token: r, right: true),
        ],
      );
    } else {
      panes = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Pane(state: state, token: r, right: false),
          Container(width: t.lineWidth, color: t.colorSplit),
          _Pane(state: state, token: r, right: true),
        ],
      );
    }

    final calendar = IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          panes,
          if (state.widget.footerBuilder != null) ...[
            Container(height: t.lineWidth, color: t.colorSplit),
            state.widget.footerBuilder!(context),
          ],
        ],
      ),
    );

    // Stacked, the panel is one month wide, and a rail beside it would take
    // back the room the stacking just found. It goes above instead, laid
    // along rather than down.
    if (stacked && presets.isNotEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: t.colorBgElevated,
          borderRadius: BorderRadius.circular(r.borderRadius),
          boxShadow: t.boxShadowSecondary,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: paneWidth,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: t.sizeXS,
                  vertical: t.sizeXS,
                ),
                child: Row(
                  spacing: t.sizeXS,
                  children: [
                    for (final preset in presets)
                      _RangeTile(state: state, preset: preset, inline: true),
                  ],
                ),
              ),
            ),
            Container(height: t.lineWidth, color: t.colorSplit),
            calendar,
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.colorBgElevated,
        borderRadius: BorderRadius.circular(r.borderRadius),
        boxShadow: t.boxShadowSecondary,
      ),
      child: presets.isEmpty
          ? calendar
          : IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RangeRail(state: state, token: r),
                  Container(width: t.lineWidth, color: t.colorSplit),
                  calendar,
                ],
              ),
            ),
    );
  }
}

/// One month of the two, with its own header.
class _Pane extends StatelessWidget {
  const _Pane({required this.state, required this.token, required this.right});

  final _DateRangePickerState state;
  final DatePanelStyle token;
  final bool right;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final host = right ? _RightPane(state) : state;
    return SizedBox(
      width: token.gridWidth + t.sizeSM * 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHeader(state: host, token: token, back: !right, forward: right),
          Container(height: t.lineWidth, color: t.colorSplit),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.sizeSM,
              vertical: t.sizeXS,
            ),
            child: switch (state._mode) {
              DatePanelMode.day => DayGrid(state: host, token: token),
              // A range picker never asks for a quarter, so the depth never
              // comes up; the switch names it because the panel's modes are
              // shared and a silent fall-through is how a mode goes missing.
              DatePanelMode.quarter => QuarterGrid(state: host, token: token),
              DatePanelMode.month => MonthGrid(state: host, token: token),
              DatePanelMode.year => YearGrid(state: host, token: token),
            },
          ),
        ],
      ),
    );
  }
}

/// The right-hand month: everything the left pane says, one month on.
///
/// A view rather than a second state — the range, the blocks and the picking
/// are the picker's, and only the month on show differs.
class _RightPane implements PanelHost {
  _RightPane(this._it);

  final _DateRangePickerState _it;

  @override
  DateTime get panelCursor => addMonths(_it._cursor, 1);

  @override
  DatePanelMode get panelMode => _it.panelMode;

  @override
  bool get panelKeyed => _it.panelKeyed;

  @override
  DateTime? get panelResting => _it.panelResting;

  @override
  DateTime? get panelMarked => _it.panelMarked;

  @override
  bool panelBlocks(DateTime day) => _it.panelBlocks(day);

  @override
  bool panelChose(DateTime day) => _it.panelChose(day);

  @override
  bool panelWithin(DateTime day) => _it.panelWithin(day);

  @override
  PanelCap panelCap(DateTime day) => _it.panelCap(day);

  @override
  DateCellBuilder? get panelCellBuilder => _it.panelCellBuilder;

  @override
  DatePickerKind get panelKind => _it.panelKind;

  @override
  void panelHover(DateTime? day) => _it.panelHover(day);

  @override
  void panelPick(DateTime day) => _it.panelPick(day);

  @override
  void panelPickMonth(int month) {
    _it._deepIsRight = true;
    _it.panelPickMonth(month);
  }

  @override
  void panelPickYear(int year) => _it.panelPickYear(year);

  @override
  void panelStep(int pages) => _it.panelStep(pages);

  @override
  void panelStepYears(int years) => _it.panelStepYears(years);

  @override
  void panelSetMode(DatePanelMode mode) {
    _it._deepIsRight = true;
    _it.panelSetMode(mode);
  }
}

/// The rail of named stretches.
class _RangeRail extends StatelessWidget {
  const _RangeRail({required this.state, required this.token});

  final _DateRangePickerState state;
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
              _RangeTile(state: state, preset: preset),
          ],
        ),
      ),
    );
  }
}

class _RangeTile extends StatefulWidget {
  const _RangeTile({
    required this.state,
    required this.preset,
    this.inline = false,
  });

  final _DateRangePickerState state;
  final DateRangePreset preset;

  /// Whether it stands in a row along the top rather than down a rail. A
  /// stacked panel is one month wide, and a rail beside it would take back
  /// the room the stacking just found.
  final bool inline;

  @override
  State<_RangeTile> createState() => _RangeTileState();
}

class _RangeTileState extends State<_RangeTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final range = widget.preset.range;
    final blocked = widget.state._isBlocked(range.start) ||
        widget.state._isBlocked(range.end);

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
          onTap: blocked ? null : () => widget.state._takePreset(widget.preset),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: t.sizeSM,
              vertical: t.sizeXXS,
            ),
            decoration: BoxDecoration(
              color: widget.inline
                  ? (blocked ? t.colorFillQuaternary : t.colorFillTertiary)
                  : (_hovered && !blocked ? t.colorFillTertiary : null),
              borderRadius: widget.inline
                  ? BorderRadius.circular(t.borderRadiusSM)
                  : null,
              border: widget.inline && _hovered && !blocked
                  ? Border.all(color: t.primary.border, width: t.lineWidth)
                  : null,
            ),
            child: Text(
              widget.preset.label,
              style: TextStyle(
                fontFamily: t.fontFamily,
                fontFamilyFallback: t.fontFamilyFallback,
                fontSize: t.fontSize,
                height: t.lineHeight,
                color: blocked ? t.colorTextQuaternary : t.colorText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
