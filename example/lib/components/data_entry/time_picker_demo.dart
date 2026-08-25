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
          Row(
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
          Row(
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
      ],
    );
  }
}
