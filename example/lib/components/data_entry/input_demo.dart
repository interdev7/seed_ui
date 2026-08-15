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
        const Input(placeholder: 'Text area', maxLines: 4),
      ],
    );
  }
}
