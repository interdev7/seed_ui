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
  int _cleared = 0;

  String _say(DateTime? d) =>
      d == null ? 'nothing chosen' : formatDate(d, 'EEE, d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    Widget row(Widget picker, DateTime? value) => Row(
      children: [
        SizedBox(width: 220, child: picker),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            _say(value),
            style: TextStyle(color: t.colorTextSecondary),
          ),
        ),
      ],
    );

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
        const Group(
          'Three depths',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 220, child: DatePicker()),
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
              for (final size in SoftSize.values)
                SizedBox(width: 200, child: DatePicker(size: size)),
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
                SizedBox(width: 200, child: DatePicker(variant: variant)),
            ],
          ),
        ),
        Group(
          'Marked as questionable or wrong',
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 200,
                child: DatePicker(
                  defaultValue: DateTime(2026, 3, 4),
                  status: InputStatus.warning,
                ),
              ),
              SizedBox(
                width: 200,
                child: DatePicker(
                  defaultValue: DateTime(2026, 3, 4),
                  status: InputStatus.error,
                ),
              ),
            ],
          ),
        ),
        Group(
          'onClear',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 220,
                child: DatePicker(
                  defaultValue: DateTime(2026, 3, 4),
                  onClear: () => setState(() => _cleared++),
                ),
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
              SizedBox(
                width: 220,
                child: DatePicker(defaultValue: DateTime(2024, 2, 29)),
              ),
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
              const SizedBox(width: 220, child: DatePicker()),
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
          SizedBox(
            width: 220,
            child: DatePicker(defaultValue: null, value: null, disabled: true),
          ),
        ),
      ],
    );
  }
}
