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

const _brand = ColorPreset(
  label: 'Brand',
  colors: [
    Color(0xFFF5222D),
    Color(0xFFFA8C16),
    Color(0xFFFADB14),
    Color(0xFF52C41A),
    Color(0xFF13C2C2),
    Color(0xFF1677FF),
    Color(0xFF722ED1),
    Color(0xFFEB2F96),
  ],
);

class ColorPickerDemo extends StatefulWidget {
  const ColorPickerDemo({super.key});

  @override
  State<ColorPickerDemo> createState() => _ColorPickerDemoState();
}

class _ColorPickerDemoState extends State<ColorPickerDemo> {
  Color? _colour = const Color(0xFF1677FF);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Group(
          'Basic',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ColorPicker(
              semanticsLabel: 'Colour',
              defaultValue: Color(0xFF1677FF),
            ),
          ),
        ),
        Group(
          'With its hex, ready colours, copying and no colour at all',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ColorPicker(
              semanticsLabel: 'Brand colour',
              value: _colour,
              showText: true,
              allowClear: true,
              canCopy: true,
              presets: const [_brand],
              onChanged: (c) => setState(() => _colour = c),
            ),
          ),
        ),
        const Group(
          'Opaque only',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ColorPicker(
              semanticsLabel: 'Opaque colour',
              defaultValue: Color(0xFF52C41A),
              showText: true,
              disabledAlpha: true,
            ),
          ),
        ),
        const Group(
          'Sizes and disabled',
          Row(
            children: [
              ColorPicker(
                semanticsLabel: 'Small',
                size: SoftSize.small,
                defaultValue: Color(0xFFFA8C16),
              ),
              SizedBox(width: 12),
              ColorPicker(
                semanticsLabel: 'Middle',
                defaultValue: Color(0xFFFA8C16),
              ),
              SizedBox(width: 12),
              ColorPicker(
                semanticsLabel: 'Large',
                size: SoftSize.large,
                defaultValue: Color(0xFFFA8C16),
              ),
              SizedBox(width: 12),
              ColorPicker(
                semanticsLabel: 'Disabled',
                disabled: true,
                defaultValue: Color(0xFFFA8C16),
              ),
            ],
          ),
        ),
        Group(
          'The panel on its own',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ColorPickerPanel(
              value: _colour,
              allowClear: true,
              presets: const [_brand],
              onChanged: (c) => setState(() => _colour = c),
            ),
          ),
        ),
      ],
    );
  }
}
