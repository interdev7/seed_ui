import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

class TooltipDemo extends StatelessWidget {
  const TooltipDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final placement in [
          PopoverPlacement.top,
          PopoverPlacement.bottom,
          PopoverPlacement.left,
          PopoverPlacement.right,
        ])
          Tooltip(
            message: 'Tooltip on the ${placement.name}',
            placement: placement,
            child: Button(onPressed: () {}, child: Text(placement.name)),
          ),
        const Tooltip(
          message: 'Hover or tap to reveal the hint.',
          child: Icon(Icons.info_outline),
        ),
        Tooltip(
          message: 'Tap trigger, no arrow',
          trigger: TooltipTrigger.tap,
          arrow: false,
          child: Button(onPressed: () {}, child: const Text('trigger: tap')),
        ),
        Tooltip(
          message: 'Long-press me',
          trigger: TooltipTrigger.longPress,
          child: Button(
            onPressed: () {},
            child: const Text('trigger: longPress'),
          ),
        ),
      ],
    );
  }
}
