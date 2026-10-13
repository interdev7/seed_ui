import 'package:flutter/material.dart'
    hide
        ThemeData,
        Checkbox,
        Radio,
        RadioGroup,
        Switch,
        Tooltip,
        Drawer,
        Divider;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

const _words = ['terrible', 'bad', 'normal', 'good', 'wonderful'];

class RateDemo extends StatefulWidget {
  const RateDemo({super.key});

  @override
  State<RateDemo> createState() => _RateDemoState();
}

class _RateDemoState extends State<RateDemo> {
  double _stars = 3;
  double? _hover;

  @override
  Widget build(BuildContext context) {
    final shown = (_hover ?? _stars).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Group(
          'Basic',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Rate(semanticsLabel: 'Rating', defaultValue: 3),
          ),
        ),
        const Group(
          'Half stars',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Rate(
              semanticsLabel: 'Half rating',
              allowHalf: true,
              defaultValue: 2.5,
            ),
          ),
        ),
        Group(
          'With words',
          Row(
            children: [
              Rate(
                semanticsLabel: 'Rating with words',
                value: _stars,
                tooltips: _words,
                onChanged: (v) => setState(() => _stars = v),
                onHoverChanged: (v) => setState(() => _hover = v),
              ),
              const SizedBox(width: 16),
              Text(shown == 0 ? '' : _words[shown - 1]),
            ],
          ),
        ),
        const Group(
          'Read-only and disabled',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Rate(
                semanticsLabel: 'Average rating',
                readOnly: true,
                allowHalf: true,
                defaultValue: 4.5,
              ),
              SizedBox(height: 12),
              Rate(
                semanticsLabel: 'Disabled rating',
                disabled: true,
                defaultValue: 2,
              ),
            ],
          ),
        ),
        Group(
          'A character of your own',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Rate(
                semanticsLabel: 'Love',
                defaultValue: 3,
                character: (_) => const Icon(Icons.favorite),
                token: const RateToken(starColor: Color(0xFFFF4D4F)),
              ),
              const SizedBox(height: 12),
              Rate(
                semanticsLabel: 'Letters',
                count: 10,
                defaultValue: 6,
                allowHalf: true,
                character: (_) => const Text('A'),
              ),
            ],
          ),
        ),
        const Group(
          'Sizes',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Rate(
                semanticsLabel: 'Small',
                size: SoftSize.small,
                defaultValue: 3,
              ),
              SizedBox(height: 8),
              Rate(semanticsLabel: 'Middle', defaultValue: 3),
              SizedBox(height: 8),
              Rate(
                semanticsLabel: 'Large',
                size: SoftSize.large,
                defaultValue: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
