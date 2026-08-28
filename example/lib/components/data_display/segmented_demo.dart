import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class SegmentedDemo extends StatefulWidget {
  const SegmentedDemo({super.key});

  @override
  State<SegmentedDemo> createState() => _SegmentedDemoState();
}

class _SegmentedDemoState extends State<SegmentedDemo> {
  String _view = 'list';
  int _density = 1;
  bool _scrollButtons = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Group(
          'Text',
          Segmented<String>(
            value: _view,
            onChanged: (v) => setState(() => _view = v),
            options: const [
              SegmentedOption(value: 'list', label: 'List'),
              SegmentedOption(value: 'grid', label: 'Grid'),
              SegmentedOption(value: 'map', label: 'Map'),
            ],
          ),
        ),
        Group(
          'Icons',
          Segmented<String>(
            value: _view,
            onChanged: (v) => setState(() => _view = v),
            options: const [
              SegmentedOption(value: 'list', icon: Icon(Icons.view_list)),
              SegmentedOption(value: 'grid', icon: Icon(Icons.grid_view)),
              SegmentedOption(value: 'map', icon: Icon(Icons.map_outlined)),
            ],
          ),
        ),
        Group(
          "Sizes · all sizes",
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Group(
                'large',
                Segmented<int>(
                  value: _density,
                  size: SoftSize.large,
                  onChanged: (v) => setState(() => _density = v),
                  options: const [
                    SegmentedOption(value: 0, label: 'Compact'),
                    SegmentedOption(value: 1, label: 'Cozy'),
                    SegmentedOption(value: 2, label: 'Comfortable'),
                  ],
                ),
              ),
              Group(
                'middle',
                Segmented<int>(
                  value: _density,
                  size: SoftSize.middle,
                  onChanged: (v) => setState(() => _density = v),
                  options: const [
                    SegmentedOption(value: 0, label: 'Compact'),
                    SegmentedOption(value: 1, label: 'Cozy'),
                    SegmentedOption(value: 2, label: 'Comfortable'),
                  ],
                ),
              ),
              Group(
                'small',
                Segmented<int>(
                  value: _density,
                  size: SoftSize.small,
                  onChanged: (v) => setState(() => _density = v),
                  options: const [
                    SegmentedOption(value: 0, label: 'Compact'),
                    SegmentedOption(value: 1, label: 'Cozy'),
                    SegmentedOption(value: 2, label: 'Comfortable'),
                    SegmentedOption(value: 3, label: 'Extra'),
                    SegmentedOption(value: 4, label: 'Extra Large'),
                    SegmentedOption(value: 5, label: 'Block'),
                    SegmentedOption(value: 6, label: 'Round'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Group(
          "Block · all sizes",
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Group(
                'large',
                Segmented<int>(
                  value: _density,
                  block: true,
                  size: SoftSize.large,
                  onChanged: (v) => setState(() => _density = v),
                  options: const [
                    SegmentedOption(value: 0, label: 'Compact'),
                    SegmentedOption(value: 1, label: 'Cozy'),
                    SegmentedOption(value: 2, label: 'Comfortable'),
                  ],
                ),
              ),
              Group(
                'middle',
                Segmented<int>(
                  value: _density,
                  block: true,
                  size: SoftSize.middle,
                  onChanged: (v) => setState(() => _density = v),
                  options: const [
                    SegmentedOption(value: 0, label: 'Compact'),
                    SegmentedOption(value: 1, label: 'Cozy'),
                    SegmentedOption(value: 2, label: 'Comfortable'),
                  ],
                ),
              ),
              Group(
                'small',
                Segmented<int>(
                  value: _density,
                  block: true,
                  size: SoftSize.small,
                  onChanged: (v) => setState(() => _density = v),
                  options: const [
                    SegmentedOption(value: 0, label: 'Compact'),
                    SegmentedOption(value: 1, label: 'Cozy'),
                    SegmentedOption(value: 2, label: 'Comfortable'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Group(
          'Too many to fit',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Deliberately boxed narrower than the run needs, which is what
              // a phone does to it.
              SizedBox(
                width: 260,
                child: Segmented<int>(
                  value: _density,
                  size: SoftSize.small,
                  scrollButtons: _scrollButtons,
                  onChanged: (v) => setState(() => _density = v),
                  options: const [
                    SegmentedOption(value: 0, label: 'Compact'),
                    SegmentedOption(value: 1, label: 'Cozy'),
                    SegmentedOption(value: 2, label: 'Comfortable'),
                    SegmentedOption(value: 3, label: 'Extra'),
                    SegmentedOption(value: 4, label: 'Extra Large'),
                    SegmentedOption(value: 5, label: 'Block'),
                    SegmentedOption(value: 6, label: 'Round'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Segmented<bool>(
                size: SoftSize.small,
                value: _scrollButtons,
                options: const [
                  SegmentedOption(value: true, label: 'scrollButtons: true'),
                  SegmentedOption(value: false, label: 'false'),
                ],
                onChanged: (v) => setState(() => _scrollButtons = v),
              ),
              const SizedBox(height: 8),
              const Text(
                'An arrow appears on whichever end has something hidden, and '
                'each tap brings on one more segment. Both show when there is '
                'more in either direction; each goes when its end runs out.',
              ),
            ],
          ),
        ),
        Group(
          'Vertical',
          Segmented<String>(
            value: _view,
            direction: Axis.vertical,
            onChanged: (v) => setState(() => _view = v),
            options: const [
              SegmentedOption(value: 'list', label: 'List'),
              SegmentedOption(value: 'grid', label: 'Grid'),
              SegmentedOption(value: 'map', label: 'Map'),
            ],
          ),
        ),
      ],
    );
  }
}
