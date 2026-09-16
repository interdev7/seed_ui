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
                    semanticsLabel: 'Search',
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
                semanticsLabel: 'Search',
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
        const Group('The words on a solid fill', _Ink()),
      ],
    );
  }
}

/// What a solid button writes its label in, and the three ways to say it.
class _Ink extends StatelessWidget {
  const _Ink();

  /// A pair of buttons under one brand colour, so the ink can be compared.
  Widget _brand(String says, Color brand, {TokenRefinement? refineTokens}) =>
      Builder(
        builder: (context) {
          final t = context.softToken;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConfigProvider(
                  // `refineSeed` rather than `token:`: it is handed the seed
                  // already in force, so naming a colour changes the colour and
                  // keeps the font, the radii and everything else the app set.
                  theme: ThemeData(
                    refineSeed: (seed) => seed.copyWith(colorPrimary: brand),
                    refineTokens: refineTokens,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Button(
                        variant: ButtonVariant.solid,
                        color: ButtonColor.primary,
                        icon: const Icon(Icons.bolt),
                        onPressed: () {},
                        child: const Text('Pay now'),
                      ),
                      Button(
                        variant: ButtonVariant.outlined,
                        color: ButtonColor.primary,
                        onPressed: () {},
                        child: const Text('Later'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  says,
                  style: TextStyle(
                    fontSize: t.fontSizeSM,
                    color: t.colorTextSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A solid button writes its label in the ink its fill asks for — '
          'black or white, whichever reads on it. Nothing to say for it: a '
          'yellow brand gets black words on its own.',
          style: TextStyle(color: t.colorTextSecondary),
        ),
        const SizedBox(height: 16),
        _brand('colorPrimary: #1677FF — dark fill, white words', _blue),
        _brand('colorPrimary: #FFD500 — light fill, black words', _yellow),
        _brand(
          'refineTokens: (t) => t.copyWith(primary: t.primary.withInk(white)) — '
          'the arithmetic overruled, for everything drawn on primary',
          _yellow,
          refineTokens: (t) => t.copyWith(primary: t.primary.withInk(_white)),
        ),
        Text(
          'And for one label alone, say it on the label: a style on the Text '
          'beats what the button set for it.',
          style: TextStyle(color: t.colorTextSecondary),
        ),
        const SizedBox(height: 8),
        ConfigProvider(
          theme: ThemeData(
            refineSeed: (seed) => seed.copyWith(colorPrimary: _yellow),
          ),
          child: Button(
            variant: ButtonVariant.solid,
            color: ButtonColor.primary,
            icon: const Icon(Icons.bolt, color: Color(0xFF7A4F01)),
            onPressed: () {},
            child: const Text(
              'Brown, on this one button',
              style: TextStyle(color: Color(0xFF7A4F01)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'A colour named on the spot is treated the same, having no theme '
          'slot to look an ink up in:',
          style: TextStyle(color: t.colorTextSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final colour in const [
              Color(0xFFFFD500),
              Color(0xFFC6FF00),
              Color(0xFF7C3AED),
              Color(0xFFFFD6E7),
            ])
              Button(
                variant: ButtonVariant.solid,
                color: ButtonColor(colour),
                onPressed: () {},
                child: const Text('Pay'),
              ),
          ],
        ),
      ],
    );
  }
}

const Color _blue = Color(0xFF1677FF);
const Color _yellow = Color(0xFFFFD500);
const Color _white = Color(0xFFFFFFFF);
