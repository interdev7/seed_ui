import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/popover.dart';
import '../../utils/time_format.dart';
import '../data_entry/select.dart' show ClearIconPainter;

/// How a [TimePicker] is filled and bordered.
enum TimePickerVariant {
  /// A border, on the container background.
  outlined,

  /// A tinted fill and no border.
  filled,

  /// Neither fill nor border.
  borderless,
}

/// Which times a [TimePicker] refuses to offer.
///
/// Mirrors antd's `disabledTime`: each callback names the values that are
/// **not** available, and the later ones are told what has been chosen so far,
/// so "no minutes before half past, but only in the opening hour" is
/// expressible.
///
/// ```dart
/// DisabledTime(
///   hours: () => [for (var h = 0; h < 9; h++) h],
///   minutes: (hour) => hour == 9 ? [for (var m = 0; m < 30; m++) m] : const [],
/// )
/// ```
@immutable
class DisabledTime {
  /// Creates a [DisabledTime].
  const DisabledTime({this.hours, this.minutes, this.seconds});

  /// Hours that cannot be chosen.
  final List<int> Function()? hours;

  /// Minutes that cannot be chosen, given the hour.
  final List<int> Function(int hour)? minutes;

  /// Seconds that cannot be chosen, given the hour and minute.
  final List<int> Function(int hour, int minute)? seconds;
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
  });

  /// How pickers are filled and bordered.
  final TimePickerVariant? variant;

  /// Whether pickers carry a clear button once a time is set.
  final bool? allowClear;

  /// Whether the panel offers a jump to the current time.
  final bool? showNow;

  /// Whether a choice is only committed on OK.
  final bool? needConfirm;
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
        cellHeight: cellHeight ?? t.controlHeightSM,
        columnWidth: columnWidth ?? 56,
        visibleRows: visibleRows ?? 7,
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
    this.placement = PopoverPlacement.bottomLeft,
    this.open,
    this.onOpenChange,
    this.inputReadOnly = false,
    this.token,
  })  : assert(hourStep > 0 && 24 % hourStep == 0,
            'hourStep must divide 24 evenly'),
        assert(minuteStep > 0 && 60 % minuteStep == 0,
            'minuteStep must divide 60 evenly'),
        assert(secondStep > 0 && 60 % secondStep == 0,
            'secondStep must divide 60 evenly');

  /// The time shown, as a duration since midnight. Null shows the placeholder.
  final Duration? value;

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
  final SoftSize? size;

  /// How the field is filled and bordered.
  final TimePickerVariant? variant;

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

  /// Per-instance token overrides.
  final TimePickerToken? token;

  @override
  State<TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  final PopoverController _popover = PopoverController();
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();

  bool _open = false;
  bool _hovered = false;

  /// What the panel is showing while it is being worked on. Committed to
  /// [TimePicker.onChanged] on OK, or immediately when no confirmation is
  /// asked for.
  Duration? _draft;

  TimeFields get _fields => TimeFields.of(widget.format);

  TimePickerDefaults? get _defaults =>
      ConfigProvider.defaultsOf<TimePickerDefaults>(context);

  bool get _disabled =>
      widget.disabled ?? ConfigProvider.componentDisabledOf(context) ?? false;

  SoftSize get _size =>
      widget.size ?? ConfigProvider.componentSizeOf(context) ?? SoftSize.middle;

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
    _draft = widget.value;
    // Reports a layer that closed itself — an outside tap, a route change.
    // It must not close the layer again: it is already gone, and asking twice
    // takes the overlay entry out from under itself.
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
    // The text is written through the locale, which is an inherited lookup —
    // legal here, not in initState.
    if (!_focus.hasFocus) _syncText();
  }

  @override
  void didUpdateWidget(TimePicker old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || old.format != widget.format) {
      _draft = widget.value;
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
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Value
  // --------------------------------------------------------------------------

  void _syncText() {
    final words = context.seedLocale;
    final value = widget.value;
    final next = value == null
        ? ''
        : formatTime(value, widget.format, am: words.am, pm: words.pm);
    if (_text.text != next) _text.text = next;
  }

  void _commit(Duration? time) {
    if (time == widget.value) return;
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
    final parsed = parseTime(text, widget.format, am: words.am, pm: words.pm);
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
      _draft = widget.value;
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
      builder: (context) => _TimePanel(state: this),
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
    if (!_needConfirm) {
      _commit(time);
      if (!_fields.minute && !_fields.second) _requestOpen(false);
    }
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
    if (!_needConfirm) {
      _commit(time);
      _requestOpen(false);
    }
  }

  void _clear() {
    setState(() => _draft = null);
    _text.clear();
    _commit(null);
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
    final showClear =
        _allowClear && _enabled && widget.value != null && _hovered;

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

    final Color border;
    if (_variant != TimePickerVariant.outlined) {
      border = const Color(0x00000000);
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
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    if (_text.text.isEmpty)
                      Text(
                        widget.placeholder ?? words.selectTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle.copyWith(
                          color: t.colorTextTertiary,
                        ),
                      ),
                    field,
                  ],
                ),
              ),
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
                CustomPaint(
                  size: Size.square(fontSize),
                  painter: _ClockIconPainter(
                    _enabled ? t.colorTextQuaternary : t.colorTextQuaternary,
                  ),
                ),
            ],
          ),
        ),
      ),
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
    final fields = state._fields;
    final draft = state._draft;

    final hour = draft?.inHours;
    final minute = draft == null ? null : draft.inMinutes % 60;
    final second = draft == null ? null : draft.inSeconds % 60;

    Duration compose({int? h, int? m, int? s}) => Duration(
          hours: h ?? hour ?? 0,
          minutes: m ?? minute ?? 0,
          seconds: s ?? second ?? 0,
        );

    final columns = <Widget>[
      if (fields.hour)
        _Column(
          token: r,
          values: [
            for (var h = 0; h < 24; h += state.widget.hourStep) h,
          ],
          selected: hour,
          label: fields.meridiem
              ? (h) => '${h % 12 == 0 ? 12 : h % 12}'.padLeft(2, '0')
              : (h) => '$h'.padLeft(2, '0'),
          // A 12-hour panel splits the day across two columns, so the hour
          // column shows one half at a time.
          keep: fields.meridiem
              ? (h) => (hour ?? 0) < 12 ? h < 12 : h >= 12
              : null,
          disabled: state._blockedHours(),
          hideDisabled: state.widget.hideDisabledOptions,
          onPick: (h) => state._pick(compose(h: h)),
        ),
      if (fields.minute)
        _Column(
          token: r,
          values: [
            for (var m = 0; m < 60; m += state.widget.minuteStep) m,
          ],
          selected: minute,
          label: (m) => '$m'.padLeft(2, '0'),
          disabled: state._blockedMinutes(hour ?? 0),
          hideDisabled: state.widget.hideDisabledOptions,
          onPick: (m) => state._pick(compose(m: m)),
        ),
      if (fields.second)
        _Column(
          token: r,
          values: [
            for (var s = 0; s < 60; s += state.widget.secondStep) s,
          ],
          selected: second,
          label: (s) => '$s'.padLeft(2, '0'),
          disabled: state._blockedSeconds(hour ?? 0, minute ?? 0),
          hideDisabled: state.widget.hideDisabledOptions,
          onPick: (s) => state._pick(compose(s: s)),
        ),
      if (fields.meridiem)
        _Column(
          token: r,
          values: const [0, 1],
          selected: (hour ?? 0) >= 12 ? 1 : 0,
          label: (i) => i == 0 ? words.am : words.pm,
          disabled: const [],
          hideDisabled: false,
          onPick: (i) {
            final base = (hour ?? 0) % 12;
            state._pick(compose(h: base + (i == 1 ? 12 : 0)));
          },
        ),
    ];

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
            height: r.cellHeight * r.visibleRows,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < columns.length; i++) ...[
                  if (i > 0) Container(width: t.lineWidth, color: t.colorSplit),
                  columns[i],
                ],
              ],
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
        ],
      ),
    );
  }
}

/// One scrolling column of values.
class _Column extends StatefulWidget {
  const _Column({
    required this.token,
    required this.values,
    required this.selected,
    required this.label,
    required this.disabled,
    required this.hideDisabled,
    required this.onPick,
    this.keep,
  });

  final _ResolvedTimePickerToken token;
  final List<int> values;
  final int? selected;
  final String Function(int) label;
  final List<int> disabled;
  final bool hideDisabled;
  final ValueChanged<int> onPick;

  /// Narrows the column further — the half-day filter of a 12-hour panel.
  final bool Function(int)? keep;

  @override
  State<_Column> createState() => _ColumnState();
}

class _ColumnState extends State<_Column> {
  late final ScrollController _scroll = ScrollController();

  List<int> get _shown => [
        for (final v in widget.values)
          if ((widget.keep?.call(v) ?? true) &&
              !(widget.hideDisabled && widget.disabled.contains(v)))
            v,
      ];

  @override
  void initState() {
    super.initState();
    // Bring the current value into view once the column has a size to scroll.
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  @override
  void didUpdateWidget(_Column old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) _revealSelected();
  }

  void _revealSelected() {
    if (!mounted || !_scroll.hasClients) return;
    final index = _shown.indexOf(widget.selected ?? -1);
    if (index < 0) return;
    final target = (index * widget.token.cellHeight).clamp(
      _scroll.position.minScrollExtent,
      _scroll.position.maxScrollExtent,
    );
    _scroll.jumpTo(target);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final values = _shown;
    return SizedBox(
      width: widget.token.columnWidth,
      child: ListView.builder(
        controller: _scroll,
        padding: EdgeInsets.zero,
        itemCount: values.length,
        itemExtent: widget.token.cellHeight,
        itemBuilder: (context, i) {
          final value = values[i];
          final chosen = value == widget.selected;
          final blocked = widget.disabled.contains(value);
          return _Cell(
            label: widget.label(value),
            chosen: chosen,
            disabled: blocked,
            height: widget.token.cellHeight,
            radius: t.borderRadiusSM,
            onTap: blocked ? null : () => widget.onPick(value),
          );
        },
      ),
    );
  }
}

class _Cell extends StatefulWidget {
  const _Cell({
    required this.label,
    required this.chosen,
    required this.disabled,
    required this.height,
    required this.radius,
    required this.onTap,
  });

  final String label;
  final bool chosen;
  final bool disabled;
  final double height;
  final double radius;
  final VoidCallback? onTap;

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final Color background;
    if (widget.chosen) {
      background = t.colorFillSecondary;
    } else if (_hovered && !widget.disabled) {
      background = t.colorFillTertiary;
    } else {
      background = const Color(0x00000000);
    }

    return MouseRegion(
      cursor: widget.disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: t.sizeXXS / 2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(widget.radius),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: widget.disabled ? t.colorTextQuaternary : t.colorText,
                  fontSize: t.fontSize,
                  fontFamily: t.fontFamily,
                  fontFamilyFallback: t.fontFamilyFallback,
                  fontWeight: widget.chosen ? FontWeight.w600 : FontWeight.w400,
                  height: 1.0,
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
