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
import '../../utils/value_tag.dart';
import '../data_entry/input.dart' show InputStatus;
import '../general/compact.dart';
import 'date_picker.dart';

/// One day the field is holding, as its tag knows it.
@immutable
class DateTag {
  /// Creates a description of one tag.
  const DateTag({
    required this.date,
    required this.label,
    required this.enabled,
    required this.onRemove,
  });

  /// The day it stands for.
  final DateTime date;

  /// The day written out, by the picker's own format and the locale's
  /// figures — so a tag drawn by hand reads like the ones beside it.
  final String label;

  /// Whether the field may be used at all.
  final bool enabled;

  /// Takes this day out. Null on a barred field: a tag nobody may remove
  /// should not offer to be removed.
  final VoidCallback? onRemove;
}

/// Draws one tag in the field.
///
/// [child] is the tag the picker would have drawn. Wrap it to add something,
/// or return your own and take [DateTag.onRemove] with you — a tag that
/// cannot be removed leaves the day with no way out but the panel.
///
/// ```dart
/// tagBuilder: (context, tag, child) => holidays.contains(tag.date)
///     ? Tag(color: TagColor.gold, closable: true, onClose: tag.onRemove,
///         child: Text(tag.label))
///     : child,
/// ```
typedef DateTagBuilder = Widget Function(
  BuildContext context,
  DateTag tag,
  Widget child,
);

/// Defaults for every [MultiDatePicker] under a `ConfigProvider`.
@immutable
class MultiDatePickerDefaults {
  /// Creates a [MultiDatePickerDefaults].
  const MultiDatePickerDefaults({
    this.variant,
    this.allowClear,
    this.size,
    this.disabled,
    this.maxTagCount,
  });

  /// How pickers are filled and bordered.
  final DatePickerVariant? variant;

  /// Whether pickers carry a clear button once a date is set.
  final bool? allowClear;

  /// Which control height a picker takes, unless it names one.
  final ControlSize? size;

  /// Whether a picker is disabled, unless it says otherwise.
  final bool? disabled;

  /// How many dates are named before the rest are counted.
  final int? maxTagCount;
}

/// A field that collects any number of days.
///
/// ```dart
/// MultiDatePicker(
///   values: _shifts,
///   onChanged: (days) => setState(() => _shifts = days),
/// )
/// ```
///
/// Its own component rather than a flag on [DatePicker]: the value is a list,
/// the field carries a tag for each day rather than one line of text, and the
/// panel stays open — picking a second day is the ordinary next thing to do,
/// not a fresh start. A picker that had to be both would be worse at each.
///
/// The days come back **in order**, earliest first, whatever order they were
/// pressed in: a list of days is read as a run of dates, and one that came
/// back in the order somebody happened to tap would have to be sorted by
/// every caller.
class MultiDatePicker extends StatefulWidget {
  /// Creates a [MultiDatePicker].
  const MultiDatePicker({
    super.key,
    this.values,
    this.defaultValues,
    this.onChanged,
    this.format = 'yyyy-MM-dd',
    this.disabledDate,
    this.minDate,
    this.maxDate,
    this.maxCount,
    this.maxTagCount,
    this.allowClear,
    this.disabled,
    this.size,
    this.variant,
    this.placeholder,
    this.semanticsLabel,
    this.placement = PopoverPlacement.bottomLeft,
    this.open,
    this.onOpenChange,
    this.status,
    this.prefix,
    this.suffixIcon,
    this.onClear,
    this.footerBuilder,
    this.cellBuilder,
    this.tagBuilder,
    this.removeIcon,
    this.token,
  });

  /// The days held, earliest first.
  ///
  /// Null hands the picker to itself: it keeps what is chosen, starting from
  /// [defaultValues].
  final List<DateTime>? values;

  /// What an uncontrolled picker starts with.
  final List<DateTime>? defaultValues;

  /// Called with the whole list every time a day goes in or comes out, and
  /// with an empty list when the field is cleared.
  final ValueChanged<List<DateTime>>? onChanged;

  /// How each day is written. The grammar is [DatePicker]'s.
  final String format;

  /// Asked about every day the panel draws.
  final bool Function(DateTime day)? disabledDate;

  /// The earliest day on offer.
  final DateTime? minDate;

  /// The latest.
  final DateTime? maxDate;

  /// How many days may be held at once.
  ///
  /// Once that many are in, the rest of the panel is barred rather than
  /// silently refusing a tap — a limit nobody can see is a limit that reads
  /// as a bug.
  final int? maxCount;

  /// How many days are named in the field before the rest are counted.
  ///
  /// Null names them all, and the field grows to hold them.
  final int? maxTagCount;

  /// Whether the whole lot may be dropped at once.
  final bool? allowClear;

  /// Whether the field is barred.
  final bool? disabled;

  /// The control height, as a preset or a measurement.
  final ControlSize? size;

  /// How the field is filled and bordered.
  final DatePickerVariant? variant;

  /// What the field says while it holds nothing.
  final String? placeholder;

  /// Names a field whose label is written outside it.
  final String? semanticsLabel;

  /// Where the panel opens.
  final PopoverPlacement placement;

  /// Drives the panel from outside.
  final bool? open;

  /// Reports what the picker would have done with its panel.
  final ValueChanged<bool>? onOpenChange;

  /// Marks the field as questionable or wrong.
  final InputStatus? status;

  /// Sits before the tags.
  final Widget? prefix;

  /// Replaces the calendar mark.
  final Widget? suffixIcon;

  /// Called after the days are dropped.
  final VoidCallback? onClear;

  /// Adds a row of your own beneath the panel.
  final WidgetBuilder? footerBuilder;

  /// Draws a day cell — see [DatePicker.cellBuilder].
  final DateCellBuilder? cellBuilder;

  /// Draws one tag in the field, given the day and the tag the picker would
  /// have drawn.
  final DateTagBuilder? tagBuilder;

  /// Replaces the cross on every tag.
  ///
  /// The mark, not the target: whatever is given still sits in the same
  /// place and still removes the day, so a picture cannot be swapped in for
  /// something that does nothing.
  final Widget? removeIcon;

  /// Per-instance token overrides. The panel is [DatePicker]'s, so its
  /// numbers are too.
  final DatePickerToken? token;

  @override
  State<MultiDatePicker> createState() => _MultiDatePickerState();
}

class _MultiDatePickerState extends State<MultiDatePicker>
    implements PanelHost {
  final PopoverController _popover = PopoverController();
  final FocusNode _focus = FocusNode();
  final ValueNotifier<Rect> _anchor = ValueNotifier(Rect.zero);

  /// Rebuilt on its own: the panel lives in the overlay, where a `setState`
  /// here does not reach.
  final ValueNotifier<int> _revision = ValueNotifier(0);

  bool _open = false;
  bool _hovered = false;
  List<DateTime>? _internal;

  late DateTime _cursor;
  DatePanelMode _mode = DatePanelMode.day;
  bool _keyed = false;
  DateTime? _walk;

  List<DateTime> get _value => widget.values ?? _internal ?? const <DateTime>[];

  MultiDatePickerDefaults? get _defaults =>
      ConfigProvider.defaultsOf<MultiDatePickerDefaults>(context);

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

  int? get _maxTagCount => widget.maxTagCount ?? _defaults?.maxTagCount;

  @override
  void initState() {
    super.initState();
    _internal = _sorted(widget.defaultValues ?? const []);
    _cursor = dateOnly(_value.isEmpty ? DateTime.now() : _value.first);
    _focus.onKeyEvent = _onKey;
    if (widget.open ?? false) _obey(true);
    _popover.onClosed = () {
      if (!mounted || !_open) return;
      setState(() {
        _open = false;
        _walk = null;
      });
      widget.onOpenChange?.call(false);
    };
  }

  void _obey(bool open) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      open ? _openPanel() : _closePanel();
    });
  }

  @override
  void didUpdateWidget(MultiDatePicker old) {
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

  /// The days in order, earliest first, with the clocks dropped.
  ///
  /// Sorted on the way in rather than on the way out: a list that came back
  /// in the order somebody happened to tap would have to be sorted by every
  /// caller, and a run of dates is read in order.
  static List<DateTime> _sorted(Iterable<DateTime> days) {
    final out = days.map(dateOnly).toSet().toList()..sort();
    return out;
  }

  bool _holds(DateTime day) {
    final d = dateOnly(day);
    return _value.any((held) => held == d);
  }

  bool _isBlocked(DateTime day) {
    final d = dateOnly(day);
    final min = widget.minDate;
    final max = widget.maxDate;
    if (min != null && d.isBefore(dateOnly(min))) return true;
    if (max != null && d.isAfter(dateOnly(max))) return true;
    if (widget.disabledDate?.call(d) ?? false) return true;
    // A full list bars what is not already in it, rather than refusing the
    // tap: a limit nobody can see reads as a bug.
    final most = widget.maxCount;
    if (most != null && _value.length >= most && !_holds(d)) return true;
    return false;
  }

  void _emit(List<DateTime> next) {
    final settled = _sorted(next);
    setState(() => _internal = settled);
    widget.onChanged?.call(settled);
    // After the frame, not during it. The panel lives in the overlay and is
    // redrawn on its own; told to redraw now, it would read a `values` its
    // owner has been handed but not yet rebuilt with, and mark the list as it
    // stood one tap ago. Waiting a frame lets the owner answer first — and
    // an owner that refuses the change is then shown refusing it, which is
    // what handing the value over is for.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _repaintPanel();
    });
  }

  /// Puts a day in, or takes it out again.
  ///
  /// The panel stays open either way: picking a second day is the ordinary
  /// next thing to do, and a panel that shut after the first would make a
  /// list of five days five journeys.
  void _toggle(DateTime day) {
    if (_isBlocked(day)) return;
    final d = dateOnly(day);
    final next = [..._value];
    if (_holds(d)) {
      next.removeWhere((held) => held == d);
    } else {
      next.add(d);
    }
    _emit(next);
  }

  void _remove(DateTime day) {
    _emit([..._value]..removeWhere((held) => held == dateOnly(day)));
  }

  void _clear() {
    _emit(const []);
    widget.onClear?.call();
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
  DateTime? get panelMarked => _value.isEmpty ? null : _value.first;

  @override
  bool panelBlocks(DateTime day) => _isBlocked(day);

  @override
  bool panelChose(DateTime day) => _holds(day);

  @override
  DateCellBuilder? get panelCellBuilder => widget.cellBuilder;

  @override
  void panelPick(DateTime day) => _toggle(day);

  @override
  void panelPickMonth(int month) {
    setState(() {
      _cursor = DateTime(_cursor.year, month);
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
    widget.onOpenChange?.call(next);
    if (widget.open == null) next ? _openPanel() : _closePanel();
  }

  void _openPanel() {
    if (_open || !_enabled) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    setState(() {
      _open = true;
      _mode = DatePanelMode.day;
      _cursor = dateOnly(_value.isEmpty ? DateTime.now() : _value.first);
      _keyed = false;
      _walk = null;
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
        builder: (context, _) => _MultiPanel(state: this),
      ),
    );
  }

  void _closePanel() {
    if (!_open) return;
    _popover.close();
    setState(() {
      _open = false;
      _walk = null;
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
      // Enter takes the day and leaves the panel open, as a tap does: the
      // keyboard should be able to build the same list the pointer can.
      final at = _walk;
      if (at != null) _toggle(at);
      return KeyEventResult.handled;
    }

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

    var next = dateOnly(
      (_walk ?? (_value.isEmpty ? _cursor : _value.first)).add(by),
    );
    for (var i = 0; i < 366 && _isBlocked(next); i++) {
      next = dateOnly(next.add(by));
    }
    if (_isBlocked(next)) return KeyEventResult.handled;
    setState(() {
      _keyed = true;
      _walk = next;
      if (!isSameMonth(next, _cursor)) {
        _cursor = DateTime(next.year, next.month);
      }
    });
    _repaintPanel();
    return KeyEventResult.handled;
  }

  // A list of days has no band and no end to follow the pointer: every day
  // it holds stands on its own.
  @override
  bool panelWithin(DateTime day) => false;

  @override
  PanelCap panelCap(DateTime day) => PanelCap.none;

  @override
  void panelHover(DateTime? day) {}

  @override
  DatePickerKind get panelKind => DatePickerKind.day;

  // --------------------------------------------------------------------------
  // The field
  // --------------------------------------------------------------------------

  double _height(Token t) => _size.resolveHeight(
        small: t.controlHeightSM,
        middle: t.controlHeight,
        large: t.controlHeightLG,
      );

  double _fontSize(Token t) =>
      _size == SoftSize.large ? t.fontSizeLG : t.fontSize;

  String _write(DateTime day, SeedLocalizations words) => words.figures(
        formatDate(
          day,
          widget.format,
          months: words.shortMonths,
          weekdays: words.shortWeekdays,
          am: words.am,
          pm: words.pm,
        ),
      );

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
    final held = _value;
    final canClear = _allowClear && _enabled && held.isNotEmpty;
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

    // How many are named, and how many are left to count. Naming them all
    // and letting the field grow is the default: a picker holding three days
    // should read as three days.
    final most = _maxTagCount;
    final named = most == null || held.length <= most ? held : held.take(most);
    final rest = held.length - named.length;

    Widget tagFor(DateTime day) {
      final label = _write(day, words);
      final remove = _enabled ? () => _remove(day) : null;
      final drawn = ValueTag(
        key: ValueKey(day),
        token: t,
        fontSize: fontSize,
        enabled: _enabled,
        label: Text(label),
        onRemove: remove,
        removeIcon: widget.removeIcon,
      );
      final draw = widget.tagBuilder;
      if (draw == null) return drawn;
      return draw(
        context,
        DateTag(
          date: day,
          label: label,
          enabled: _enabled,
          onRemove: remove,
        ),
        drawn,
      );
    }

    final tags = <Widget>[
      for (final day in named) tagFor(day),
      // The count reads as the kit's other tag lines do — a `Select` holding
      // more than it shows says the same thing the same way.
      if (rest > 0)
        ValueTag(
          token: t,
          fontSize: fontSize,
          enabled: _enabled,
          label: Text('+ $rest ...'),
        ),
    ];

    final named_ = _size.explicitWidth;

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
          // A floor rather than a height: the tags wrap, so a field holding a
          // fortnight is taller than one holding a day. Fixed, the tags would
          // be clipped and the reader would be told nothing about it.
          constraints: BoxConstraints(minHeight: _height(t)),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: t.sizeSM,
            vertical: t.sizeXXS,
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: CompactSlot.radiusOf(context, r.borderRadius),
            border: Border.all(color: border, width: t.lineWidth),
          ),
          child: Row(
            // Min, with the tags merely flexible: the field is as wide as
            // what is in it and gives way when there is less. `Expanded` in a
            // row that fills its parent is how it came to take the whole page
            // whatever it was holding.
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.prefix != null) ...[
                widget.prefix!,
                SizedBox(width: t.sizeXS),
              ],
              Flexible(
                child: tags.isEmpty
                    ? Text(
                        widget.placeholder ?? words.selectDate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.colorTextTertiary,
                          fontSize: fontSize,
                          fontFamily: t.fontFamily,
                          fontFamilyFallback: t.fontFamilyFallback,
                          height: 1.0,
                          decoration: TextDecoration.none,
                        ),
                      )
                    : Wrap(
                        spacing: t.sizeXXS,
                        runSpacing: t.sizeXXS,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: tags,
                      ),
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
                  child: SizedBox(
                    height: _height(t),
                    width: fontSize,
                    child: Center(
                      child: showClear
                          ? CustomPaint(
                              size: Size.square(fontSize),
                              painter: ClearIconPainter(t.colorTextTertiary),
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
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      expanded: _open,
      label: widget.semanticsLabel,
      value: held.isEmpty
          ? null
          : held.map((day) => _write(day, words)).join(', '),
      validationResult: widget.status == InputStatus.error
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: Focus(
        focusNode: _focus,
        child:
            named_ == null ? control : SizedBox(width: named_, child: control),
      ),
    );
  }
}

/// The panel: one month, and a footer saying how many are in.
class _MultiPanel extends StatelessWidget {
  const _MultiPanel({required this.state});

  final _MultiDatePickerState state;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final words = context.seedLocale;
    final r = (state.widget.token ??
            ConfigProvider.componentOf<DatePickerToken>(context) ??
            const DatePickerToken())
        .resolve(t);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.colorBgElevated,
        borderRadius: BorderRadius.circular(r.borderRadius),
        boxShadow: t.boxShadowSecondary,
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PanelHeader(state: state, token: r),
            Container(height: t.lineWidth, color: t.colorSplit),
            Padding(
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
            ),
            Container(height: t.lineWidth, color: t.colorSplit),
            Padding(
              padding: EdgeInsets.all(t.sizeXS),
              // The panel does not close on a pick, so there has to be a way
              // to say "done" that is not "press somewhere else".
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    words.figures('${state._value.length}'),
                    style: TextStyle(
                      color: t.colorTextTertiary,
                      fontSize: t.fontSize,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => state._requestOpen(false),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        words.ok,
                        style: TextStyle(
                          color: t.primary.base,
                          fontSize: t.fontSize,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
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
