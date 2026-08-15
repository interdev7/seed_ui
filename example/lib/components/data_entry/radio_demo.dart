import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class RadioDemo extends StatefulWidget {
  const RadioDemo({super.key});

  @override
  State<RadioDemo> createState() => _RadioDemoState();
}

class _RadioDemoState extends State<RadioDemo> {
  String _plan = 'free';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Group(
          'Horizontal',
          RadioGroup<String>(
            value: _plan,
            onChanged: (v) => setState(() => _plan = v),
            options: const [
              RadioOption(value: 'auto', label: Text('Auto')),
              RadioOption(value: 'free', label: Text('Free')),
              RadioOption(value: 'pro', label: Text('Pro')),
              RadioOption(value: 'team', label: Text('Team'), disabled: true),
            ],
          ),
        ),
        Group(
          'Vertical',
          RadioGroup<String>(
            value: _plan,
            direction: Axis.vertical,
            onChanged: (v) => setState(() => _plan = v),
            options: const [
              RadioOption(value: 'auto', label: Text('Auto — 1 project')),
              RadioOption(value: 'free', label: Text('Free — 1 project')),
              RadioOption(
                value: 'pro',
                label: Text('Pro — unlimited projects'),
              ),
              RadioOption(
                value: 'team',
                label: Text('Team — shared workspace'),
              ),
            ],
          ),
        ),
        Group(
          'Buttons — solid',
          RadioGroup<String>(
            value: _plan,
            optionType: RadioOptionType.button,
            buttonStyle: RadioButtonStyle.solid,
            onChanged: (v) => setState(() => _plan = v),
            options: const [
              RadioOption(value: 'auto', label: Text('Auto')),
              RadioOption(value: 'free', label: Text('Free')),
              RadioOption(value: 'pro', label: Text('Pro')),
              RadioOption(value: 'team', label: Text('Team')),
            ],
          ),
        ),
        Group(
          'Buttons — block · large',
          RadioGroup<String>(
            value: _plan,
            optionType: RadioOptionType.button,
            block: true,
            size: SoftSize.large,
            onChanged: (v) => setState(() => _plan = v),
            options: const [
              RadioOption(value: 'auto', label: Text('Auto')),
              RadioOption(value: 'free', label: Text('Free')),
              RadioOption(value: 'pro', label: Text('Pro')),
              RadioOption(value: 'team', label: Text('Team')),
            ],
          ),
        ),
        Text(
          'Selected: $_plan',
          style: TextStyle(color: context.softToken.colorTextSecondary),
        ),
      ],
    );
  }
}
