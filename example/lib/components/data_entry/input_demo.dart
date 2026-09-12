import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

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
            onVisibleChanged: (value) => debugPrint("is visible: $value"),
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
        // height() names a height and says nothing about width, so these still
        // fill the line — a text field has no content to measure. box() names
        // both, and needs no SizedBox around it.
        const Row(
          children: [
            Expanded(
              child: Input(
                placeholder: 'height(20)',
                size: ControlSize.height(20),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Input(
                placeholder: 'height(36)',
                size: ControlSize.height(36),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Input(
                placeholder: 'height(56)',
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
            Input(placeholder: 'box(140, 24)', size: ControlSize.box(140, 24)),
            Input(placeholder: 'box(200, 36)', size: ControlSize.box(200, 36)),
            Input(placeholder: 'box(260, 48)', size: ControlSize.box(260, 48)),
            // width() is the other half of box(): it names the width and
            // leaves the height to the preset scale.
            Input(placeholder: 'width(160)', size: ControlSize.width(160)),
          ],
        ),
        const SizedBox(height: 12),
        const Input(placeholder: 'Text area', maxLines: 4),
        const SizedBox(height: 24),
        const Group('What it is drawn with', _Look()),
      ],
    );
  }
}

/// Every colour and number an [Input] draws with, and how to say it.
///
/// Nothing here is a prop on the widget: they are `InputToken` fields, and the
/// same token can be handed to one field through `token:` or to every field in
/// a subtree through `ConfigProvider`.
class _Look extends StatelessWidget {
  const _Look();

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    Widget row(String says, Widget field, {String? note}) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field,
          const SizedBox(height: 6),
          Text(
            says,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: t.fontSizeSM,
              color: t.colorTextSecondary,
            ),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                note,
                style: TextStyle(
                  fontSize: t.fontSizeSM,
                  color: t.colorTextTertiary,
                ),
              ),
            ),
        ],
      ),
    );

    const clear = Color(0x00000000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(
          'InputToken(colorBorder: …, hoverBorderColor: …, '
          'activeBorderColor: …)',
          const Input(
            placeholder: 'A border of your own',
            token: InputToken(
              colorBorder: Color(0xFF8B5CF6),
              hoverBorderColor: Color(0xFFA78BFA),
              activeBorderColor: Color(0xFF6D28D9),
            ),
          ),
          note: 'Three states: at rest, under the pointer, and focused.',
        ),
        row(
          'InputToken(colorBorder: Color(0x00000000), … , '
          'focusRing: Color(0x00000000))',
          Input(
            placeholder: 'No border at all',
            token: InputToken(
              colorBorder: clear,
              hoverBorderColor: clear,
              activeBorderColor: clear,
              focusRing: clear,
              colorBgContainer: t.colorFillQuaternary,
            ),
          ),
          note:
              'All four: a transparent border still leaves the halo that '
              'appears on focus, and focusRing is what turns that off.',
        ),
        row(
          'InputToken(borderRadius: 999, paddingInline: 20)',
          const Input(
            placeholder: 'A pill',
            token: InputToken(borderRadius: 999, paddingInline: 20),
            allowClear: true,
          ),
          note:
              'The radius and the inset either side of the words. '
              'paddingBlock is the one above and below, and only a text area '
              'has any.',
        ),
        row(
          'InputToken(colorBgContainer: …, colorText: …, '
          'colorTextPlaceholder: …)',
          const Input(
            placeholder: 'Its own fill and ink',
            token: InputToken(
              colorBgContainer: Color(0xFF1F2937),
              colorText: Color(0xFFF9FAFB),
              colorTextPlaceholder: Color(0xFF9CA3AF),
              colorBorder: Color(0xFF374151),
              activeBorderColor: Color(0xFF60A5FA),
              focusRing: Color(0x3360A5FA),
            ),
          ),
          note: 'A field that keeps its own colours whatever the theme does.',
        ),
        row(
          'InputToken(fontSize: 20)',
          const Input(
            placeholder: 'Bigger words',
            token: InputToken(fontSize: 20),
            size: ControlSize.height(52),
          ),
          note:
              'The type alone. fontSizeSM and fontSizeLG are the same thing '
              'for the small and large presets, so one token can cover all '
              'three sizes.',
        ),
        row(
          'ConfigProvider(theme: ThemeData(components: ComponentsConfig('
          'input: InputToken(…))))',
          ConfigProvider(
            theme: ThemeData(
              components: const ComponentsConfig(
                input: InputToken(
                  borderRadius: 2,
                  colorBorder: Color(0xFF94A3B8),
                ),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Input(placeholder: 'Every field below here'),
                SizedBox(height: 8),
                Input(placeholder: '…without naming a token on either'),
              ],
            ),
          ),
          note:
              'The same token, said once for a whole subtree. A field that '
              'names its own token still wins.',
        ),
      ],
    );
  }
}
