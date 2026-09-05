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
          'A shadow, a hold, and the noise it makes',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Button(
                    variant: ButtonVariant.solid,
                    color: ButtonColor.primary,
                    // Nothing is cast until the token names what to cast.
                    token: ButtonToken(
                      shadow: context.softToken.boxShadowSecondary,
                    ),
                    onPressed: () {},
                    child: const Text('Lifted'),
                  ),
                  Button(
                    onPressed: () => message.info('Tapped'),
                    onLongPress: () => message.success('Held'),
                    child: const Text('Tap or hold'),
                  ),
                  Button(
                    // Fires often enough that a click each time would be a
                    // nuisance.
                    feedback: false,
                    onPressed: () {},
                    child: const Text('Quiet'),
                  ),
                  Button(
                    // A hold and nothing else: it does something, so it is
                    // not disabled and does not look it.
                    onLongPress: () => message.success('Held'),
                    child: const Text('Hold only'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'A shadow is cast only where the token names one, and only by '
                'the variants that stand on a ground of their own. A hold is '
                'its own callback, not a second reading of the tap. And a tap '
                'makes the noise the platform makes, unless the button says '
                'otherwise.',
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
