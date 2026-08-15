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
