import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

class InputDemo extends StatelessWidget {
  const InputDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Input(placeholder: 'Basic'),
        const SizedBox(height: 12),
        const Input(defaultValue: 'Default value'),
        const SizedBox(height: 12),
        // Search box with an attached primary button.
        Input(
          placeholder: 'Search',
          search: SearchConfig(
            enterButton: true,
            onSearch: (v) => debugPrint('search: $v'),
          ),
        ),
        const SizedBox(height: 12),
        // Character count: soft max marks a warning but does not truncate.
        const Input(
          defaultValue: 'Hello, soft!',
          count: CountConfig(show: true, max: 10),
        ),
        const SizedBox(height: 12),
        // Emoji counts as length 1 via a grapheme-counting strategy.
        Input(
          defaultValue: '🔥🔥🔥',
          count: CountConfig(show: true, strategy: (t) => t.characters.length),
        ),
        const SizedBox(height: 12),
        // Not exceed max: clip on overflow with exceedFormatter.
        Input(
          defaultValue: '🔥 soft',
          count: CountConfig(
            show: true,
            max: 6,
            strategy: (t) => t.characters.length,
            exceedFormatter: (t, max) => t.characters.take(max).toString(),
          ),
        ),
        const SizedBox(height: 12),
        const Input(
          placeholder: 'With clear',
          prefix: Icon(Icons.person_outline),
          allowClear: true,
        ),
        const SizedBox(height: 12),
        Input(
          placeholder: 'Password',
          password: PasswordConfig(
            onVisibleChange: (value) => debugPrint("is visible: $value"),
          ),
        ),
        const SizedBox(height: 12),
        const Input(placeholder: 'Error status', status: InputStatus.error),
        const SizedBox(height: 12),
        const Input(placeholder: 'Disabled', disabled: true),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: Input(placeholder: 'Small', size: SoftSize.small),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Input(placeholder: 'Large', size: SoftSize.large),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // A measurement instead of a preset.
        //
        // fixed() names a height and says nothing about width, so these still
        // fill the line — a text field has no content to measure. raw() names
        // both, and needs no SizedBox around it.
        const Row(
          children: [
            Expanded(
              child: Input(
                placeholder: 'fixed(20)',
                size: ControlSize.height(20),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Input(
                placeholder: 'fixed(36)',
                size: ControlSize.height(36),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Input(
                placeholder: 'fixed(56)',
                size: ControlSize.height(56),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Input(placeholder: 'raw(140, 24)', size: ControlSize.box(140, 24)),
            Input(placeholder: 'raw(200, 36)', size: ControlSize.box(200, 36)),
            Input(placeholder: 'raw(260, 48)', size: ControlSize.box(260, 48)),
          ],
        ),
        const SizedBox(height: 12),
        const Input(placeholder: 'Text area', maxLines: 4),
      ],
    );
  }
}
