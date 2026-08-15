import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class ButtonDemo extends StatelessWidget {
  const ButtonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final color in const [
          (ButtonColor.defaultColor, 'default'),
          (ButtonColor.primary, 'primary'),
          (ButtonColor.danger, 'danger'),
        ])
          Group(
            'color: ${color.$2}',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final variant in ButtonVariant.values)
                  Button(
                    variant: variant,
                    color: color.$1,
                    onPressed: () {},
                    child: Text(variant.name),
                  ),
              ],
            ),
          ),
        Group(
          'Sizes',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final size in SoftSize.values)
                Button(
                  variant: ButtonVariant.solid,
                  color: ButtonColor.primary,
                  size: size,
                  onPressed: () {},
                  child: Text(size.name),
                ),
            ],
          ),
        ),
        Group(
          'Loading / disabled / icon',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Button(
                variant: ButtonVariant.solid,
                color: ButtonColor.primary,
                loading: true,
                onPressed: () {},
                child: const Text('Loading'),
              ),
              const Button(disabled: true, child: Text('Disabled')),
              Button(
                variant: ButtonVariant.solid,
                color: ButtonColor.primary,
                shape: ButtonShape.circle,
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Button(
          variant: ButtonVariant.solid,
          color: ButtonColor.primary,
          block: true,
          onPressed: () {},
          child: const Text('Block'),
        ),
      ],
    );
  }
}
