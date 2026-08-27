import 'package:flutter/material.dart'
    hide Badge, ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class FloatButtonDemo extends StatefulWidget {
  const FloatButtonDemo({super.key});

  @override
  State<FloatButtonDemo> createState() => _FloatButtonDemoState();
}

class _FloatButtonDemoState extends State<FloatButtonDemo> {
  static const _layouts = <(String, FloatButtonLayout)>[
    ('vertical', FloatButtonLayout.vertical()),
    ('horizontal', FloatButtonLayout.horizontal()),
    ('fan', FloatButtonLayout.fan()),
    ('grid(2)', FloatButtonLayout.grid(2)),
  ];

  String _layout = 'fan';
  double _jitter = 0;
  FloatButtonLabelPlacement _labels = FloatButtonLabelPlacement.auto;
  bool _open = false;

  FloatButtonLayout get _chosen => _layout == 'fan'
      ? FloatButtonLayout.fan(jitter: _jitter, seed: 7)
      : _layouts.firstWhere((e) => e.$1 == _layout).$2;

  /// A stage with room for a group to open into, parked bottom right the way
  /// a float button really is.
  Widget _stage(Widget group) => Container(
    height: 260,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0x22000000)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Stack(children: [Positioned(right: 16, bottom: 16, child: group)]),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Group(
          'On its own',
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              FloatButton(icon: const Icon(Icons.search), onPressed: () {}),
              FloatButton(
                icon: const Icon(Icons.person),
                color: ButtonColor.primary,
                onPressed: () {},
              ),
              FloatButton(
                icon: const Icon(Icons.search),
                shape: ButtonShape.defaultShape,
                onPressed: () {},
              ),
              // No badge prop: Badge already wraps.
              Badge(
                count: 5,
                child: FloatButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        Group(
          'A label rides outside the button',
          Padding(
            padding: const EdgeInsets.only(left: 96, top: 8, bottom: 8),
            child: Wrap(
              spacing: 96,
              runSpacing: 24,
              children: [
                FloatButton(
                  icon: const Icon(Icons.person),
                  label: const Text('Profile'),
                  onPressed: () {},
                ),
                FloatButton(
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                  labelPlacement: FloatButtonLabelPlacement.right,
                  color: ButtonColor.primary,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
        Group(
          'Layouts',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Segmented<String>(
                size: SoftSize.small,
                value: _layout,
                options: [
                  for (final l in _layouts)
                    SegmentedOption(value: l.$1, label: l.$1),
                ],
                onChanged: (v) => setState(() => _layout = v),
              ),
              const SizedBox(height: 12),
              _stage(
                FloatButtonGroup(
                  layout: _chosen,
                  color: ButtonColor.primary,
                  labelPlacement: _labels,
                  children: [
                    for (final name in const ['Edit', 'Share', 'Copy', 'Bin'])
                      FloatButton(
                        icon: const Icon(Icons.person),
                        label: Text(name),
                        onPressed: () {},
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The group reads its direction off the trigger: parked bottom '
                'right, it opens up and to the left.',
              ),
            ],
          ),
        ),
        Group(
          'Scatter — a fan with jitter',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Segmented<double>(
                size: SoftSize.small,
                value: _jitter,
                options: const [
                  SegmentedOption(value: 0.0, label: 'jitter: 0'),
                  SegmentedOption(value: 0.5, label: '0.5'),
                  SegmentedOption(value: 1.0, label: '1'),
                ],
                onChanged: (v) => setState(() {
                  _jitter = v;
                  _layout = 'fan';
                }),
              ),
              const SizedBox(height: 8),
              const Text(
                'The same seed gives the same arrangement every time it opens, '
                'and the stray is capped at half the gap so items cannot meet.',
              ),
            ],
          ),
        ),
        Group(
          'Where the labels hang',
          Segmented<FloatButtonLabelPlacement>(
            size: SoftSize.small,
            value: _labels,
            options: [
              for (final p in FloatButtonLabelPlacement.values)
                SegmentedOption(value: p, label: p.name),
            ],
            onChanged: (v) => setState(() => _labels = v),
          ),
        ),
        Group(
          'Opened from outside',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Button(
                onPressed: () => setState(() => _open = !_open),
                child: Text(_open ? 'Close it' : 'Open it'),
              ),
              const SizedBox(height: 12),
              _stage(
                FloatButtonGroup(
                  open: _open,
                  onOpenChange: (v) => setState(() => _open = v),
                  layout: const FloatButtonLayout.vertical(),
                  children: [
                    FloatButton(
                      icon: const Icon(Icons.person),
                      onPressed: () {},
                    ),
                    FloatButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Group(
          'Opened by hovering',
          _stage(
            FloatButtonGroup(
              trigger: FloatButtonTrigger.hover,
              layout: const FloatButtonLayout.horizontal(),
              children: [
                FloatButton(icon: const Icon(Icons.person), onPressed: () {}),
                FloatButton(icon: const Icon(Icons.search), onPressed: () {}),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
