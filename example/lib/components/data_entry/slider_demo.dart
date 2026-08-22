import 'package:flutter/material.dart'
    hide
        Slider,
        RangeSlider,
        ThemeData,
        Checkbox,
        Radio,
        RadioGroup,
        Switch,
        Tooltip,
        Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class SliderDemo extends StatefulWidget {
  const SliderDemo({super.key});

  @override
  State<SliderDemo> createState() => _SliderDemoState();
}

class _SliderDemoState extends State<SliderDemo> {
  double _basic = 30;
  double _stepped = 40;
  double _marked = 37;
  double _onlyMarks = 20;
  double _vertical = 60;
  double _reversed = 30;
  double _disabled = 45;
  (double, double) _range = (20, 70);
  (double, double) _rangeMarked = (26, 74);
  double _last = 30;

  static const _marks = [
    SliderMark(0, Text('0°C')),
    SliderMark(26, Text('26°C')),
    SliderMark(37, Text('37°C')),
    SliderMark(100, Text('100°C')),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Basic',
          Slider(value: _basic, onChanged: (v) => setState(() => _basic = v)),
        ),

        Group(
          'A coarser step',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Slider(
                value: _stepped,
                step: 10,
                onChanged: (v) => setState(() => _stepped = v),
              ),
              const SizedBox(height: 8),
              Text(
                'step: 10 — the handle is pulled onto the nearest one',
                style: TextStyle(color: t.colorTextTertiary),
              ),
            ],
          ),
        ),

        Group(
          'Marks',
          Slider(
            value: _marked,
            marks: _marks,
            onChanged: (v) => setState(() => _marked = v),
          ),
        ),

        Group(
          'Marks only — a null step',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Slider(
                value: _onlyMarks,
                step: null,
                marks: _marks,
                onChanged: (v) => setState(() => _onlyMarks = v),
              ),
              const SizedBox(height: 8),
              Text(
                'the handle rests only on a mark, or on an end of the scale',
                style: TextStyle(color: t.colorTextTertiary),
              ),
            ],
          ),
        ),

        Group(
          'Dots on every step',
          Slider(
            value: _stepped,
            step: 20,
            dots: true,
            onChanged: (v) => setState(() => _stepped = v),
          ),
        ),

        Group(
          'included: false — a point, not an amount',
          Slider(
            value: _marked,
            marks: _marks,
            included: false,
            onChanged: (v) => setState(() => _marked = v),
          ),
        ),

        Group(
          'A range',
          RangeSlider(
            values: _range,
            onChanged: (v) => setState(() => _range = v),
          ),
        ),

        Group(
          'A range with marks',
          RangeSlider(
            values: _rangeMarked,
            marks: _marks,
            onChanged: (v) => setState(() => _rangeMarked = v),
          ),
        ),

        Group(
          'A bubble of your own',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Slider(
                value: _last,
                tooltip: (v) => '${v.round()}%',
                onChanged: (v) => setState(() => _last = v),
                onChangeComplete: (v) =>
                    message.info('settled at ${v.round()}'),
              ),
              const SizedBox(height: 8),
              Text(
                'drag it: the value follows the handle, and onChangeComplete '
                'fires once you let go',
                style: TextStyle(color: t.colorTextTertiary),
              ),
            ],
          ),
        ),

        Group(
          'Reversed — the scale starts at the far end',
          Slider(
            value: _reversed,
            reverse: true,
            onChanged: (v) => setState(() => _reversed = v),
          ),
        ),

        Group(
          'Disabled',
          Slider(
            value: _disabled,
            disabled: true,
            marks: _marks,
            onChanged: (v) => setState(() => _disabled = v),
          ),
        ),

        Group(
          'Vertical',
          SizedBox(
            height: 240,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Slider(
                  value: _vertical,
                  vertical: true,
                  onChanged: (v) => setState(() => _vertical = v),
                ),
                const SizedBox(width: 48),
                Slider(
                  value: _vertical,
                  vertical: true,
                  marks: _marks,
                  onChanged: (v) => setState(() => _vertical = v),
                ),
                const SizedBox(width: 48),
                RangeSlider(
                  values: _range,
                  vertical: true,
                  onChanged: (v) => setState(() => _range = v),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
