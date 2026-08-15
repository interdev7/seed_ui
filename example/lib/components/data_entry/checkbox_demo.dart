import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class CheckboxDemo extends StatefulWidget {
  const CheckboxDemo({super.key});

  @override
  State<CheckboxDemo> createState() => _CheckboxDemoState();
}

class _CheckboxDemoState extends State<CheckboxDemo> {
  bool _single = true;
  List<String> _picked = ['a'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Group(
          'Single',
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Checkbox(
                checked: _single,
                onChanged: (v) => setState(() => _single = v),
                label: const Text('I agree'),
              ),
              const Checkbox(
                checked: true,
                disabled: true,
                label: Text('Disabled checked'),
              ),
              const Checkbox(
                checked: false,
                indeterminate: true,
                label: Text('Indeterminate'),
              ),
            ],
          ),
        ),
        Group(
          'Group - horizontal',
          CheckboxGroup<String>(
            value: _picked,
            onChanged: (v) => setState(() => _picked = v),
            options: const [
              CheckboxOption(value: 'a', label: Text('Apple')),
              CheckboxOption(value: 'b', label: Text('Banana')),
              CheckboxOption(value: 'c', label: Text('Cherry'), disabled: true),
            ],
          ),
        ),
        Group(
          'Group - vertical',
          CheckboxGroup<String>(
            value: _picked,
            direction: Axis.vertical,
            onChanged: (v) => setState(() => _picked = v),
            options: const [
              CheckboxOption(value: 'a', label: Text('Apple')),
              CheckboxOption(value: 'b', label: Text('Banana')),
              CheckboxOption(value: 'c', label: Text('Cherry'), disabled: true),
            ],
          ),
        ),
        Text(
          'Selected: ${_picked.join(', ')}',
          style: TextStyle(color: context.softToken.colorTextSecondary),
        ),
      ],
    );
  }
}
