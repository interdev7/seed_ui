import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class CompactDemo extends StatefulWidget {
  const CompactDemo({super.key});

  @override
  State<CompactDemo> createState() => _CompactDemoState();
}

class _CompactDemoState extends State<CompactDemo> {
  String _view = 'day';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Group(
          'Buttons joined into one',
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              Compact(
                children: [
                  for (final view in const ['day', 'week', 'month'])
                    Button(
                      color: _view == view
                          ? ButtonColor.primary
                          : ButtonColor.defaultColor,
                      variant: _view == view
                          ? ButtonVariant.solid
                          : ButtonVariant.outlined,
                      onPressed: () => setState(() => _view = view),
                      child: Text(view),
                    ),
                ],
              ),
              Compact(
                children: [
                  Button(icon: const Icon(Icons.chevron_left), onPressed: () {}),
                  Button(icon: const Icon(Icons.chevron_right), onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
        Group(
          'A field and the button that acts on it',
          SizedBox(
            width: 360,
            child: Compact(
              children: [
                const Expanded(child: Input(placeholder: 'Search')),
                Button(
                  color: ButtonColor.primary,
                  variant: ButtonVariant.solid,
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
        Group(
          'A choice in front of a field',
          SizedBox(
            width: 420,
            child: Compact(
              children: [
                SizedBox(
                  width: 120,
                  child: Select<String>(
                    value: const ['https://'],
                    options: const [
                      SelectOption(value: 'https://', label: Text('https://')),
                      SelectOption(value: 'http://', label: Text('http://')),
                    ],
                    onChanged: (_) {},
                  ),
                ),
                const Expanded(child: Input(placeholder: 'example.com')),
              ],
            ),
          ),
        ),
        const Group(
          'A day and a time',
          SizedBox(
            width: 420,
            child: Compact(
              children: [
                Expanded(child: DatePicker(placeholder: 'Day')),
                Expanded(child: TimePicker(placeholder: 'Time')),
              ],
            ),
          ),
        ),
        Group(
          'The whole width, shared',
          SizedBox(
            width: 420,
            child: Compact(
              block: true,
              children: [
                Button(onPressed: () {}, child: const Text('Decline')),
                Button(
                  color: ButtonColor.primary,
                  variant: ButtonVariant.solid,
                  onPressed: () {},
                  child: const Text('Accept'),
                ),
              ],
            ),
          ),
        ),
        Group(
          'Down a column',
          SizedBox(
            width: 200,
            child: Compact(
              direction: Axis.vertical,
              children: [
                Button(onPressed: () {}, child: const Text('Top')),
                Button(onPressed: () {}, child: const Text('Middle')),
                Button(onPressed: () {}, child: const Text('Bottom')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
