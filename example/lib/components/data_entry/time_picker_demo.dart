import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class TimePickerDemo extends StatefulWidget {
  const TimePickerDemo({super.key});

  @override
  State<TimePickerDemo> createState() => _TimePickerDemoState();
}

class _TimePickerDemoState extends State<TimePickerDemo> {
  Duration? _basic = const Duration(hours: 9, minutes: 30);
  Duration? _seconds;
  int _cleared = 0;
  bool _driven = false;
  Duration? _twelve;
  Duration? _stepped;
  Duration? _blocked;
  Duration? _instant;

  /// What a form would actually hold on to.
  String _say(Duration? t) =>
      t == null ? 'nothing chosen' : formatTime(t, 'HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    Widget row(Widget picker, Duration? value) => Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
          'It sizes itself',
          // No SizedBox anywhere here. With no width from above the field
          // takes the wider of two things: the longest the format can show,
          // and the placeholder that stands in until a time is chosen.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wrap, not Row: each picker takes its own width, so a row of
              // them can only overflow once the page is narrow enough.
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final f in ['HH', 'HH:mm', 'HH:mm:ss'])
                    TimePicker(format: f, placeholder: f),
                ],
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  TimePicker(format: 'HH:mm'),
                  TimePicker(
                    format: 'HH:mm',
                    placeholder: 'Choose an opening time',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Above: nothing to say while empty, so the figures decide. '
                'Below: the placeholder is wider, so it does — a shorter one '
                'is the lever for a narrower field.',
              ),
            ],
          ),
        ),
        Group(
          'Hours and minutes',
          row(
            TimePicker(
              value: _basic,
              format: 'HH:mm',
              onChanged: (v) => setState(() => _basic = v),
            ),
            _basic,
          ),
        ),
        Group(
          'Hours, minutes and seconds',
          // The default format: three columns, and the value keeps its
          // seconds.
          row(
            TimePicker(
              value: _seconds,
              onChanged: (v) => setState(() => _seconds = v),
            ),
            _seconds,
          ),
        ),
        Group(
          'A 12-hour clock',
          // The format grows a meridiem column and reads the hours 1-12.
          row(
            TimePicker(
              value: _twelve,
              format: 'h:mm a',
              onChanged: (v) => setState(() => _twelve = v),
            ),
            _twelve,
          ),
        ),
        Group(
          'Every quarter hour',
          row(
            TimePicker(
              value: _stepped,
              format: 'HH:mm',
              minuteStep: 15,
              onChanged: (v) => setState(() => _stepped = v),
            ),
            _stepped,
          ),
        ),
        Group(
          'Opening hours only',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row(
                TimePicker(
                  value: _blocked,
                  format: 'HH:mm',
                  disabledTime: DisabledTime(
                    hours: () => [
                      for (var h = 0; h < 24; h++)
                        if (h < 9 || h > 17) h,
                    ],
                    minutes: (hour) => hour == 17
                        ? [for (var m = 1; m < 60; m++) m]
                        : const [],
                  ),
                  onChanged: (v) => setState(() => _blocked = v),
                ),
                _blocked,
              ),
              const SizedBox(height: 8),
              const Text('Nine to five, and nothing past 17:00.'),
            ],
          ),
        ),
        Group(
          'One column commits at once',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row(
                TimePicker(
                  value: _instant,
                  format: 'HH',
                  onChanged: (v) => setState(() => _instant = v),
                ),
                _instant,
              ),
              const SizedBox(height: 8),
              const Text(
                'With more than one column the panel waits for OK: an hour '
                'with no minute yet is not a time worth reporting.',
              ),
            ],
          ),
        ),
        Group(
          'Sizes',
          Column(
            spacing: 10,
            children: [
              for (final size in SoftSize.values) ...[
                SizedBox(
                  width: 160,
                  child: TimePicker(size: size, format: 'HH:mm'),
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),
        ),
        Group(
          'Variants',
          Column(
            spacing: 10,
            children: [
              for (final variant in TimePickerVariant.values) ...[
                SizedBox(
                  width: 160,
                  child: TimePicker(variant: variant, format: 'HH:mm'),
                ),
                const SizedBox(width: 12),
              ],
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
                  TimePicker(
                    format: 'HH:mm',
                    size: ControlSize.fixed(28),
                    placeholder: '',
                  ),
                  TimePicker(
                    format: 'HH:mm',
                    size: ControlSize.fixed(44),
                    placeholder: '',
                  ),
                  TimePicker(format: 'HH:mm', size: ControlSize.raw(200, 36)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'fixed(28) and fixed(44) name a height; raw(200, 36) names '
                'both. A bare measurement says nothing about type, so the '
                'standard size stands.',
                style: TextStyle(color: t.colorTextSecondary),
              ),
            ],
          ),
        ),
        const Group(
          'Coarser steps',
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 200,
                child: TimePicker(
                  format: 'HH:mm',
                  hourStep: 2,
                  placeholder: 'every 2 hours',
                ),
              ),
              SizedBox(
                width: 220,
                child: TimePicker(
                  minuteStep: 30,
                  secondStep: 15,
                  placeholder: 'coarse throughout',
                ),
              ),
            ],
          ),
        ),
        Group(
          'Hidden rather than greyed',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 200,
                child: TimePicker(
                  format: 'HH:mm',
                  hideDisabledOptions: true,
                  disabledTime: DisabledTime(
                    hours: () => [
                      for (var h = 0; h < 24; h++)
                        if (h < 9 || h > 17) h,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The same nine-to-five, with the unavailable hours off the '
                'list instead of dimmed.',
              ),
            ],
          ),
        ),
        Group(
          'A trimmed panel',
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              const SizedBox(
                width: 200,
                child: TimePicker(
                  format: 'HH:mm',
                  showNow: false,
                  placeholder: 'no Now',
                ),
              ),
              SizedBox(
                width: 200,
                child: TimePicker(
                  format: 'HH',
                  needConfirm: true,
                  placeholder: 'waits for OK',
                  onChanged: (time) => debugPrint("Confirmed time: $time"),
                ),
              ),
              const SizedBox(
                width: 200,
                child: TimePicker(
                  format: 'HH:mm',
                  allowClear: false,
                  defaultValue: Duration(hours: 9),
                ),
              ),
            ],
          ),
        ),
        Group(
          'Opened from outside',
          Row(
            children: [
              SizedBox(
                width: 200,
                child: TimePicker(
                  format: 'HH:mm',
                  open: _driven,
                  onOpenChange: (v) => setState(() => _driven = v),
                ),
              ),
              const SizedBox(width: 12),
              Button(
                onPressed: () => setState(() => _driven = !_driven),
                child: Text(_driven ? 'Close it' : 'Open it'),
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
                SizedBox(
                  width: 200,
                  child: TimePicker(
                    format: 'HH:mm',
                    placement: placement,
                    placeholder: placement.name,
                  ),
                ),
            ],
          ),
        ),
        const Group(
          'Its own tokens',
          SizedBox(
            width: 220,
            child: TimePicker(
              format: 'HH:mm',
              token: TimePickerToken(
                borderRadius: 16,
                cellHeight: 34,
                columnWidth: 72,
                visibleRows: 5,
              ),
            ),
          ),
        ),
        const Group(
          'Disabled',
          SizedBox(
            width: 220,
            child: TimePicker(
              value: Duration(hours: 9, minutes: 30),
              format: 'HH:mm',
              disabled: true,
            ),
          ),
        ),
        const Group(
          'Panel only, no typing',
          SizedBox(
            width: 220,
            child: TimePicker(format: 'HH:mm', inputReadOnly: true),
          ),
        ),
        const Group(
          'Left to itself',
          // No value and no onChanged: the picker keeps what it is given,
          // starting from defaultValue.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 220,
                child: TimePicker(
                  format: 'HH:mm',
                  defaultValue: Duration(hours: 7, minutes: 15),
                ),
              ),
              SizedBox(height: 8),
              Text('Nothing above is holding this one — it keeps its own.'),
            ],
          ),
        ),
        const Group(
          'Marked as questionable or wrong',
          Column(
            spacing: 10,
            children: [
              SizedBox(
                width: 200,
                child: TimePicker(
                  format: 'HH:mm',
                  defaultValue: Duration(hours: 3),
                  status: InputStatus.warning,
                ),
              ),
              SizedBox(
                width: 200,
                child: TimePicker(
                  format: 'HH:mm',
                  defaultValue: Duration(hours: 2),
                  status: InputStatus.error,
                ),
              ),
            ],
          ),
        ),
        Group(
          'A prefix, a suffix and a footer of your own',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 260,
                child: TimePicker(
                  format: 'HH:mm',
                  prefix: Text(
                    'from',
                    style: TextStyle(color: t.colorTextSecondary),
                  ),
                  suffixIcon: Icon(
                    Icons.schedule,
                    size: 16,
                    color: t.colorTextQuaternary,
                  ),
                  footerBuilder: (context) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Opening hours are 09:00 to 18:00',
                      style: TextStyle(
                        fontSize: 12,
                        color: t.colorTextSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('The footer sits under the panel\'s own row.'),
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
                child: TimePicker(
                  format: 'HH:mm',
                  defaultValue: const Duration(hours: 12),
                  onClear: () => setState(() => _cleared++),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _cleared == 0
                    ? 'Hover the field and press the cross.'
                    : 'Cleared \$_cleared time(s).',
              ),
            ],
          ),
        ),
        Group(
          'In another language',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 220, child: TimePicker(format: 'HH:mm')),
              const SizedBox(height: 8),
              Text(
                'Switch the language in the header. The words and the figures '
                'both follow — under Arabic the panel counts in '
                'Arabic-Indic digits, and a time typed back in them is read '
                'correctly.',
                style: TextStyle(color: t.colorTextSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
