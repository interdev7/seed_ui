import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class EmptyDemo extends StatelessWidget {
  const EmptyDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Group('Default', Empty()),
        const Group('Simple image', Empty(image: EmptyImage.simple)),
        const Group(
          'Custom description',
          Empty(description: Text('No results found')),
        ),
        Group(
          'With action',
          Empty(
            description: const Text('Nothing here yet'),
            child: Button(
              variant: ButtonVariant.solid,
              color: ButtonColor.primary,
              onPressed: () => message.info('Create'),
              child: const Text('Create now'),
            ),
          ),
        ),
      ],
    );
  }
}
