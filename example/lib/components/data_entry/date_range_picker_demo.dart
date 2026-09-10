import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class DateRangePickerDemo extends StatefulWidget {
  const DateRangePickerDemo({super.key});

  @override
  State<DateRangePickerDemo> createState() => _DateRangePickerDemoState();
}

class _DateRangePickerDemoState extends State<DateRangePickerDemo> {
  DateRange? _holiday;
  DateRange? _bounded;
  DateRange? _sized;
  DateRange? _preset;

  String _say(DateRange? r) => r == null
      ? 'nothing chosen'
      : '${formatDate(r.start, 'd MMM')} to ${formatDate(r.end, 'd MMM yyyy')}'
            ' — ${r.days} days';

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    // A Wrap rather than a Row: on a narrow page the read-out goes under the
    // field instead of squeezing it.
    Widget row(Widget picker, DateRange? value) => Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: picker,
        ),
        Text(_say(value), style: TextStyle(color: t.colorTextSecondary)),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'A stretch of days',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row(
                DateRangePicker(
                  value: _holiday,
                  onChanged: (v) => setState(() => _holiday = v),
                ),
                _holiday,
              ),
              const SizedBox(height: 8),
              const Text(
                'Two months side by side, because a range that crosses one is '
                'the ordinary case. Press a day, then move the pointer: the '
                'band follows before you take it. Nothing is handed back '
                'until both ends are in — one end is not a range.',
              ),
            ],
          ),
        ),
        Group(
          'How short and how long',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row(
                DateRangePicker(
                  value: _bounded,
                  minDays: 3,
                  maxDays: 10,
                  onChanged: (v) => setState(() => _bounded = v),
                ),
                _bounded,
              ),
              const SizedBox(height: 8),
              const Text(
                'Between three and ten days. Put one end down and watch the '
                'rest of the month: the days that would make too short or too '
                'long a range are greyed while you choose, rather than '
                'refused after you have tapped.',
              ),
            ],
          ),
        ),
        Group(
          'Named stretches',
          row(
            DateRangePicker(
              value: _preset,
              onChanged: (v) => setState(() => _preset = v),
              presets: [
                DateRangePreset.of('The last seven days', () {
                  final today = dateOnly(DateTime.now());
                  return DateRange(
                    today.subtract(const Duration(days: 6)),
                    today,
                  );
                }),
                DateRangePreset.of('The last thirty', () {
                  final today = dateOnly(DateTime.now());
                  return DateRange(
                    today.subtract(const Duration(days: 29)),
                    today,
                  );
                }),
                DateRangePreset.of('This month so far', () {
                  final today = dateOnly(DateTime.now());
                  return DateRange(DateTime(today.year, today.month), today);
                }),
              ],
            ),
            _preset,
          ),
        ),
        Group(
          'Weekdays only, inside one year',
          row(
            DateRangePicker(
              value: _sized,
              minDate: DateTime(DateTime.now().year),
              maxDate: DateTime(DateTime.now().year, 12, 31),
              disabledDate: (d) =>
                  d.weekday == DateTime.saturday ||
                  d.weekday == DateTime.sunday,
              onChanged: (v) => setState(() => _sized = v),
            ),
            _sized,
          ),
        ),
        Group(
          'Sizes',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              for (final size in SoftSize.values) DateRangePicker(size: size),
            ],
          ),
        ),
        Group(
          'Variants',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              for (final variant in DatePickerVariant.values)
                DateRangePicker(variant: variant),
            ],
          ),
        ),
        const Group(
          'Marked as wrong, and barred',
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              DateRangePicker(status: InputStatus.error),
              DateRangePicker(disabled: true),
            ],
          ),
        ),
      ],
    );
  }
}
