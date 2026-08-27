import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class InputNumberDemo extends StatefulWidget {
  const InputNumberDemo({super.key});

  @override
  State<InputNumberDemo> createState() => _InputNumberDemoState();
}

class _InputNumberDemoState extends State<InputNumberDemo> {
  num? _qty = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Basic (controlled)',
          InputNumber(value: _qty, onChanged: (v) => setState(() => _qty = v)),
        ),
        const Group(
          'Min / max / step',
          InputNumber(defaultValue: 0, min: 0, max: 10, step: 2),
        ),
        const Group(
          'Precision (2 decimals)',
          InputNumber(defaultValue: 1.5, step: 0.1, precision: 2),
        ),
        const Group(
          'Prefix & formatter (currency)',
          InputNumber(
            defaultValue: 1000,
            prefix: Text(r'$'),
            // formatter/parser turn 1000 <-> "1,000".
            formatter: _thousands,
            parser: _unThousands,
          ),
        ),
        const Group(
          'Spinner mode — a minus, the value, a plus',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InputNumber(
                mode: InputNumberMode.spinner,
                defaultValue: 3,
                min: 1,
                max: 10,
              ),
              SizedBox(height: 8),
              InputNumber(
                mode: InputNumberMode.spinner,
                defaultValue: 1,
                min: 1,
                max: 10,
                size: SoftSize.large,
              ),
              SizedBox(height: 8),
              // It keeps its own width whatever the parent offers; widen it
              // through the token when the numbers are long.
              InputNumber(
                mode: InputNumberMode.spinner,
                defaultValue: 1000,
                step: 100,
                token: InputNumberToken(spinnerWidth: 220),
              ),
            ],
          ),
        ),
        const Group(
          'No controls',
          InputNumber(defaultValue: 42, controls: false),
        ),
        const Group(
          'Sizes',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InputNumber(defaultValue: 1, size: SoftSize.small),
              SizedBox(height: 8),
              InputNumber(defaultValue: 1, size: SoftSize.large),
            ],
          ),
        ),
        const Group(
          'A measurement instead of a preset',
          // fixed() names a height; the field goes on filling the width, as a
          // text field with nothing to measure should. raw() names both and
          // needs no SizedBox — in spinner mode it beats spinnerWidth too.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 220,
                child: InputNumber(
                  defaultValue: 1,
                  size: ControlSize.fixed(44),
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  InputNumber(defaultValue: 1, size: ControlSize.raw(160, 36)),
                  InputNumber(
                    defaultValue: 1,
                    mode: InputNumberMode.spinner,
                    size: ControlSize.raw(180, 44),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Group('Disabled', InputNumber(defaultValue: 5, disabled: true)),
      ],
    );
  }

  static String _thousands(num v) {
    final s = v.toInt().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  static num? _unThousands(String t) => num.tryParse(t.replaceAll(',', ''));
}
