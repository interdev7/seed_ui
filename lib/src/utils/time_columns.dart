import 'package:flutter/widgets.dart';

import '../theme/config_provider.dart';
import 'time_format.dart';

/// Which times a [TimePicker] refuses to offer.
///
/// Each callback names the values that are **not** available, and the later
/// ones are told what has been chosen so far, so "no minutes before half past,
/// but only in the opening hour" is expressible.
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

/// The scrolling columns a time is picked from.
///
/// Shared, because a time is picked the same way wherever it is asked for:
/// `TimePicker` shows these on their own, and a `DatePicker` told to collect
/// a time shows them beside the calendar. The columns know nothing about
/// either — they are handed a time and hand one back.
class TimeColumns extends StatelessWidget {
  /// Creates the columns.
  const TimeColumns({
    required this.fields,
    required this.value,
    required this.onChanged,
    required this.cellHeight,
    required this.columnWidth,
    required this.visibleRows,
    this.hourStep = 1,
    this.minuteStep = 1,
    this.secondStep = 1,
    this.disabledTime,
    this.hideDisabledOptions = false,
    super.key,
  });

  /// Which columns the format asks for.
  final TimeFields fields;

  /// The time on show, or null where nothing has been picked.
  final Duration? value;

  /// Called with the whole time whenever any one column is picked from.
  final ValueChanged<Duration> onChanged;

  /// How tall one value stands.
  final double cellHeight;

  /// How wide one column stands.
  final double columnWidth;

  /// How many values are on show at once.
  final int visibleRows;

  /// How far apart the hours stand.
  final int hourStep;

  /// How far apart the minutes stand.
  final int minuteStep;

  /// How far apart the seconds stand.
  final int secondStep;

  /// Which values are refused.
  final DisabledTime? disabledTime;

  /// Whether a refused value is left out rather than greyed.
  final bool hideDisabledOptions;

  List<int> _blockedHours() => disabledTime?.hours?.call() ?? const [];

  List<int> _blockedMinutes(int hour) =>
      disabledTime?.minutes?.call(hour) ?? const [];

  List<int> _blockedSeconds(int hour, int minute) =>
      disabledTime?.seconds?.call(hour, minute) ?? const [];

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final words = context.seedLocale;
    final draft = value;

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
          cellHeight: cellHeight,
          columnWidth: columnWidth,
          visibleRows: visibleRows,
          values: [for (var h = 0; h < 24; h += hourStep) h],
          selected: hour,
          label: fields.meridiem
              ? (h) => words.figures(
                    '${h % 12 == 0 ? 12 : h % 12}'.padLeft(2, '0'),
                  )
              : (h) => words.figures('$h'.padLeft(2, '0')),
          // A 12-hour panel splits the day across two columns, so the hour
          // column shows one half at a time.
          keep: fields.meridiem
              ? (h) => (hour ?? 0) < 12 ? h < 12 : h >= 12
              : null,
          disabled: _blockedHours(),
          hideDisabled: hideDisabledOptions,
          onPick: (h) => onChanged(compose(h: h)),
        ),
      if (fields.minute)
        _Column(
          cellHeight: cellHeight,
          columnWidth: columnWidth,
          visibleRows: visibleRows,
          values: [for (var m = 0; m < 60; m += minuteStep) m],
          selected: minute,
          label: (m) => words.figures('$m'.padLeft(2, '0')),
          disabled: _blockedMinutes(hour ?? 0),
          hideDisabled: hideDisabledOptions,
          onPick: (m) => onChanged(compose(m: m)),
        ),
      if (fields.second)
        _Column(
          cellHeight: cellHeight,
          columnWidth: columnWidth,
          visibleRows: visibleRows,
          values: [for (var s = 0; s < 60; s += secondStep) s],
          selected: second,
          label: (s) => words.figures('$s'.padLeft(2, '0')),
          disabled: _blockedSeconds(hour ?? 0, minute ?? 0),
          hideDisabled: hideDisabledOptions,
          onPick: (s) => onChanged(compose(s: s)),
        ),
      if (fields.meridiem)
        _Column(
          cellHeight: cellHeight,
          columnWidth: columnWidth,
          visibleRows: visibleRows,
          values: const [0, 1],
          selected: (hour ?? 0) >= 12 ? 1 : 0,
          label: (i) => i == 0 ? words.am : words.pm,
          disabled: const [],
          hideDisabled: false,
          onPick: (i) {
            final base = (hour ?? 0) % 12;
            onChanged(compose(h: base + (i == 1 ? 12 : 0)));
          },
        ),
    ];

    return SizedBox(
      height: cellHeight * visibleRows,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < columns.length; i++) ...[
            if (i > 0) Container(width: t.lineWidth, color: t.colorSplit),
            columns[i],
          ],
        ],
      ),
    );
  }
}

/// One scrolling column of values.
class _Column extends StatefulWidget {
  const _Column({
    required this.cellHeight,
    required this.columnWidth,
    required this.visibleRows,
    required this.values,
    required this.selected,
    required this.label,
    required this.disabled,
    required this.hideDisabled,
    required this.onPick,
    this.keep,
  });

  final double cellHeight;
  final double columnWidth;
  final int visibleRows;
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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _revealSelected(instant: true));
  }

  @override
  void didUpdateWidget(_Column old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) _revealSelected();
  }

  /// Brings the chosen value to the top of the column.
  ///
  /// [instant] on the first build, where there is nothing to animate from;
  /// a glide afterwards, so a pick reads as the column moving rather than
  /// the values jumping under the finger.
  void _revealSelected({bool instant = false}) {
    if (!mounted || !_scroll.hasClients) return;
    final index = _shown.indexOf(widget.selected ?? -1);
    if (index < 0) return;
    final target = (index * widget.cellHeight).clamp(
      _scroll.position.minScrollExtent,
      _scroll.position.maxScrollExtent,
    );
    if ((target - _scroll.offset).abs() < 0.5) return;
    if (instant) {
      _scroll.jumpTo(target);
      return;
    }
    final t = context.softToken;
    _scroll.animateTo(
      target,
      duration: t.motionDurationMid,
      curve: t.motionEaseInOut,
    );
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
      width: widget.columnWidth,
      child: ListView.builder(
        controller: _scroll,
        // Room below the run, so even the last value can come to rest at the
        // top of the column.
        padding: EdgeInsets.only(
          bottom: widget.cellHeight * (widget.visibleRows - 1),
        ),
        itemCount: values.length,
        itemBuilder: (context, i) {
          final value = values[i];
          final chosen = value == widget.selected;
          final blocked = widget.disabled.contains(value);
          return SizedBox(
            height: widget.cellHeight,
            child: _Cell(
              label: widget.label(value),
              chosen: chosen,
              disabled: blocked,
              height: widget.cellHeight,
              radius: t.borderRadiusSM,
              textInset:
                  (widget.columnWidth - widget.cellHeight) / 2 - t.sizeXXS,
              onTap: blocked ? null : () => widget.onPick(value),
            ),
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
    required this.textInset,
    required this.onTap,
  });

  final String label;
  final bool chosen;
  final bool disabled;
  final double height;
  final double radius;

  /// How far in from the pill's start the digits begin, so a column reads as
  /// one straight edge rather than a centred ragged one.
  final double textInset;

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
    if (widget.disabled) {
      background = const Color(0x00000000);
    } else if (widget.chosen) {
      // The same tint a chosen row takes in a Select's list, so a panel and a
      // dropdown do not disagree about what "chosen" looks like.
      background = t.primary.bg;
    } else if (_hovered) {
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
          // The gap between one value and the next is horizontal: the pill is
          // inset from the column's sides, and the rows sit flush.
          padding: EdgeInsets.symmetric(horizontal: t.sizeXXS),
          child: AnimatedContainer(
            // Hover fades in, but a pick lands at once: easing from the hover
            // grey to the chosen tint shows a grey stage on the way, which
            // reads as a flash under the finger.
            duration: widget.chosen ? Duration.zero : t.motionDurationMid,
            curve: t.motionEaseInOut,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(widget.radius),
            ),
            alignment: AlignmentDirectional.centerStart,
            padding: EdgeInsetsDirectional.only(start: widget.textInset),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.disabled ? t.colorTextQuaternary : t.colorText,
                fontSize: t.fontSize,
                fontFamily: t.fontFamily,
                fontFamilyFallback: t.fontFamilyFallback,
                fontWeight: t.fontWeight,
                height: 1.0,
                // Without an even split the glyphs sit off the row's centre —
                // the whole column then reads as crooked.
                leadingDistribution: TextLeadingDistribution.even,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
