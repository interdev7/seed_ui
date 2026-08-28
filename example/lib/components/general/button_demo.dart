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
          'Sizes · a measurement of your own',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Button(
                    variant: ButtonVariant.solid,
                    color: ButtonColor.primary,
                    size: const ControlSize.height(54),
                    onPressed: () {},
                    child: const Text('height(54)'),
                  ),
                  Button(
                    variant: ButtonVariant.solid,
                    color: ButtonColor.primary,
                    size: const ControlSize.height(20),
                    onPressed: () {},
                    child: const Text('height(20)'),
                  ),
                  // A circle has one measurement: the height is the diameter.
                  Button(
                    variant: ButtonVariant.solid,
                    color: ButtonColor.primary,
                    size: const ControlSize.height(54),
                    shape: ButtonShape.circle,
                    icon: const Icon(Icons.search),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Button(
                    size: const ControlSize.box(200, 36),
                    onPressed: () {},
                    child: const Text('box(200, 36)'),
                  ),
                  Button(
                    size: const ControlSize.width(160),
                    onPressed: () {},
                    child: const Text('width(160)'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'A measurement names a height; the type, the corners and the '
                'padding come from the preset it is nearest to, so a button '
                'sized by hand still looks like one of the family.',
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
          size: SoftSize.large,
          onPressed: () {},
          child: const Text('Block'),
        ),
      ],
    );
  }
}
