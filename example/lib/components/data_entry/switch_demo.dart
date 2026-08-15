import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

class SwitchDemo extends StatefulWidget {
  const SwitchDemo({super.key});

  @override
  State<SwitchDemo> createState() => _SwitchDemoState();
}

class _SwitchDemoState extends State<SwitchDemo> {
  bool _a = true;
  bool _b = false;
  bool _c = true;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Switch(value: _a, onChanged: (v) => setState(() => _a = v)),
        Switch(
          value: _b,
          size: SwitchSize.small,
          onChanged: (v) => setState(() => _b = v),
        ),
        Switch(
          value: _c,
          onChanged: (v) => setState(() => _c = v),
          checkedChild: const Text('ON'),
          uncheckedChild: const Text('OFF'),
        ),
        const Switch(value: true, disabled: true),
        const Switch(value: true, loading: true),
      ],
    );
  }
}
