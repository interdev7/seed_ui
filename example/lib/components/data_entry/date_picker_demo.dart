import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class DatePickerDemo extends StatefulWidget {
  const DatePickerDemo({super.key});

  @override
  State<DatePickerDemo> createState() => _DatePickerDemoState();
}

class _DatePickerDemoState extends State<DatePickerDemo> {
  DateTime? _basic = DateTime(2026, 3, 4);
  DateTime? _named;
  DateTime? _bounded;
  DateTime? _weekdays;
  DateTime? _at;
  DateTime? _preset;
  DateTime? _week;
  DateTime? _quarter;
  DateTime? _month;
  List<DateTime> _shifts = [];
  int _cleared = 0;
  bool _driven = false;

  String _say(DateTime? d) =>
      d == null ? 'nothing chosen' : formatDate(d, 'EEE, d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    Widget row(Widget picker, DateTime? value) => Row(
      children: [
        picker,
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            _say(value),
            style: TextStyle(color: t.colorTextSecondary),
          ),
        ),
      ],
    );

    final weekSaid = _week == null
        ? 'nothing'
        : '${formatDate(_week!, 'EEE, d MMM yyyy')} onwards';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'A date',
          row(
            DatePicker(
              value: _basic,
              onChanged: (v) => setState(() => _basic = v),
            ),
            _basic,
          ),
        ),
        Group(
          'Written another way',
          // The format decides how it reads; MMM takes the locale's own name.
          row(
            DatePicker(
              value: _named,
              format: 'd MMM yyyy',
              onChanged: (v) => setState(() => _named = v),
            ),
            _named,
          ),
        ),
        Group(
          'A time as well as a date',
          // Nothing is handed back until Ok: a date whose time is still
          // being chosen is half an answer.
          Row(
            children: [
              DatePicker(
                showTime: true,
                format: 'yyyy-MM-dd HH:mm',
                value: _at,
                onChanged: (v) => setState(() => _at = v),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  _at == null
                      ? 'nothing chosen'
                      : formatDate(_at!, 'EEE, d MMM yyyy [at] HH:mm'),
                  style: TextStyle(color: t.colorTextSecondary),
                ),
              ),
            ],
          ),
        ),
        Group(
          'Named dates on a rail',
          // `DatePreset.of` is asked for its date when it is taken, so these
          // stay right however long the panel is left open.
          row(
            DatePicker(
              value: _preset,
              onChanged: (v) => setState(() => _preset = v),
              presets: [
                const DatePreset.of('Today', DateTime.now),
                DatePreset.of(
                  'A week from now',
                  () => DateTime.now().add(const Duration(days: 7)),
                ),
                DatePreset.of(
                  'A month from now',
                  () => DateTime.now().add(const Duration(days: 30)),
                ),
                DatePreset('The last day of 2026', DateTime(2026, 12, 31)),
              ],
            ),
            _preset,
          ),
        ),
        Group(
          'A week, a month, a quarter, a year',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  DatePicker(
                    picker: DatePickerKind.week,
                    value: _week,
                    onChanged: (v) => setState(() => _week = v),
                  ),
                  DatePicker(
                    picker: DatePickerKind.month,
                    value: _month,
                    onChanged: (v) => setState(() => _month = v),
                  ),
                  SizedBox(
                    width: 200,
                    child: DatePicker(
                      picker: DatePickerKind.quarter,
                      value: _quarter,
                      onChanged: (v) => setState(() => _quarter = v),
                    ),
                  ),
                  const SizedBox(
                    width: 200,
                    child: DatePicker(picker: DatePickerKind.year),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'The value stays a DateTime — the first day of whatever was '
                'chosen. Press any day in a week and the whole row is taken: '
                'one press on any of them is the same answer. A month picker '
                'has no days to offer, so it shows none.\n\n'
                'The week reads back as $weekSaid.',
                style: TextStyle(color: t.colorTextSecondary),
              ),
            ],
          ),
        ),
        Group(
          'A cell drawn by the caller',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DatePicker(
                token: const DatePickerToken(mainAxisSpacing: 15),
                // Wrapping the panel's own mark rather than replacing it:
                // the cell keeps chosen, today, hovered and barred for
                // nothing.
                cellBuilder: (context, cell, child) => Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomLeft,
                  children: [
                    child,
                    if (cell.date.day % 7 == 3)
                      Positioned(
                        top: 2,
                        right: -2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: t.primary.base,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            // filed
                            Icons.check_circle_sharp,
                            size: 13,
                            color: t.colorTextSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A dot under the days with something booked. The builder is '
                'handed what the panel would have drawn, so nothing about '
                'chosen or today has to be worked out again.',
              ),
            ],
          ),
        ),
        Group(
          'Any number of days',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MultiDatePicker(
                values: _shifts,
                maxCount: 5,
                maxTagCount: 3,
                placeholder: 'Pick your shifts',
                onChanged: (v) => setState(() => _shifts = v),
              ),
              const SizedBox(height: 12),
              // The same days kept to one line. No width given here either:
              // the line takes what the tags need, and hides what will not
              // fit only once the room actually runs out.
              MultiDatePicker(
                values: _shifts,
                maxCount: 5,
                maxTagCountResponsive: true,
                placeholder: 'The same days, on one line',
                onChanged: (v) => setState(() => _shifts = v),
              ),
              const SizedBox(height: 8),
              Text(
                'The panel stays open, so a second day is one more tap, and '
                'pressing a day already in takes it out. Five at most: once '
                'the list is full the rest of the month is barred rather than '
                'refusing a tap that looked available.\n\n'
                '${_shifts.length} in, and they come back earliest first '
                'whatever order you press them in.',
                style: TextStyle(color: t.colorTextSecondary),
              ),
            ],
          ),
        ),
        const Group(
          'Three depths',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DatePicker(),
              SizedBox(height: 8),
              Text(
                'Open it and press the month in the header: the panel goes up '
                'to the months, then to the years. Picking walks back down, so '
                'a date years away is three taps.',
              ),
            ],
          ),
        ),
        Group(
          'Inside a range only',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row(
                DatePicker(
                  value: _bounded,
                  minDate: DateTime(2026, 3, 10),
                  maxDate: DateTime(2026, 3, 24),
                  defaultValue: DateTime(2026, 3, 12),
                  onChanged: (v) => setState(() => _bounded = v),
                ),
                _bounded,
              ),
              const SizedBox(height: 8),
              const Text('Only the 10th to the 24th of March 2026.'),
            ],
          ),
        ),
        Group(
          'Weekdays only',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row(
                DatePicker(
                  value: _weekdays,
                  disabledDate: (d) =>
                      d.weekday == DateTime.saturday ||
                      d.weekday == DateTime.sunday,
                  onChanged: (v) => setState(() => _weekdays = v),
                ),
                _weekdays,
              ),
              const SizedBox(height: 8),
              const Text(
                'Blocked days are greyed rather than hidden, so the shape of '
                'the month stays readable. Today obeys the same rule.',
              ),
            ],
          ),
        ),
        const Group(
          'It sizes itself',
          // No SizedBox: with no width from above the field takes the wider
          // of the format and the placeholder.
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              DatePicker(format: 'yyyy-MM-dd', placeholder: ''),
              DatePicker(format: 'd MMM yyyy', placeholder: ''),
              DatePicker(),
            ],
          ),
        ),
        Group(
          'Sizes',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              for (final size in SoftSize.values) DatePicker(size: size),
            ],
          ),
        ),
        Group(
          'A measurement instead of a preset',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  DatePicker(size: ControlSize.height(28), placeholder: ''),
                  DatePicker(size: ControlSize.height(44), placeholder: ''),
                  DatePicker(size: ControlSize.box(240, 36)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'height(28) and height(44) name a height; box(240, 36) names '
                'both. A preset carries a type size of its own — a bare '
                'measurement names only itself, so the standard type stands.',
                style: TextStyle(color: t.colorTextSecondary),
              ),
            ],
          ),
        ),
        const Group(
          'A trimmed panel',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  DatePicker(showToday: false, placeholder: 'no Today'),
                  DatePicker(
                    allowClear: false,
                    defaultValue: null,
                    placeholder: 'no clear',
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text('The footer and the clear button are both optional.'),
            ],
          ),
        ),
        Group(
          'A prefix, a suffix and a footer of your own',
          DatePicker(
            prefix: Text('on', style: TextStyle(color: t.colorTextSecondary)),
            suffixIcon: Icon(
              Icons.event_outlined,
              size: 16,
              color: t.colorTextQuaternary,
            ),
            footerBuilder: (context) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Bookings open 30 days ahead',
                style: TextStyle(fontSize: 12, color: t.colorTextSecondary),
              ),
            ),
          ),
        ),
        Group(
          'Opened from outside',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DatePicker(
                    open: _driven,
                    onOpenChanged: (v) => setState(() => _driven = v),
                  ),
                  const SizedBox(width: 12),
                  Button(
                    onPressed: () => setState(() => _driven = !_driven),
                    child: Text(_driven ? 'Close it' : 'Open it'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'With open supplied the picker stops deciding for itself and '
                'reports what it would have done through onOpenChanged.',
              ),
            ],
          ),
        ),
        Group(
          'Where the panel opens',
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final placement in [
                PopoverPlacement.bottomLeft,
                PopoverPlacement.bottomRight,
                PopoverPlacement.topLeft,
              ])
                DatePicker(placement: placement, placeholder: placement.name),
            ],
          ),
        ),
        const Group('Panel only, no typing', DatePicker(inputReadOnly: true)),
        const Group(
          'Its own tokens',
          // Per instance, without touching the theme.
          DatePicker(
            token: DatePickerToken(
              borderRadius: 16,
              cellWidth: 44,
              cellHeight: 30,
            ),
          ),
        ),
        Group(
          'Variants',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              for (final variant in DatePickerVariant.values)
                DatePicker(variant: variant),
            ],
          ),
        ),
        Group(
          'Marked as questionable or wrong',
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              DatePicker(
                defaultValue: DateTime(2026, 3, 4),
                status: InputStatus.warning,
              ),
              DatePicker(
                defaultValue: DateTime(2026, 3, 4),
                status: InputStatus.error,
              ),
            ],
          ),
        ),
        Group(
          'onClear',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DatePicker(
                defaultValue: DateTime(2026, 3, 4),
                onClear: () => setState(() => _cleared++),
              ),
              const SizedBox(height: 8),
              Text(
                _cleared == 0
                    ? 'Hover the field and press the cross.'
                    : 'Cleared $_cleared time(s).',
              ),
            ],
          ),
        ),
        Group(
          'A leap year',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DatePicker(defaultValue: DateTime(2024, 2, 29)),
              const SizedBox(height: 8),
              Text(
                'February 2024 has a 29th; 2100 will not. The kit asks '
                'DateTime rather than working the century rules out itself.',
                style: TextStyle(color: t.colorTextSecondary),
              ),
            ],
          ),
        ),
        Group(
          'In another language',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DatePicker(),
              const SizedBox(height: 8),
              Text(
                'Switch the language in the header. The month and weekday '
                'names, the figures, and which day the week starts on all '
                'follow — Japanese and Hebrew weeks start on Sunday, Arabic '
                'ones on Saturday.',
                style: TextStyle(color: t.colorTextSecondary),
              ),
            ],
          ),
        ),
        const Group(
          'Disabled',
          DatePicker(defaultValue: null, value: null, disabled: true),
        ),
      ],
    );
  }
}
