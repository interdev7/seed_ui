import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class CollapseDemo extends StatefulWidget {
  const CollapseDemo({super.key});

  @override
  State<CollapseDemo> createState() => _CollapseDemoState();
}

class _CollapseDemoState extends State<CollapseDemo> {
  static const _text =
      'A dog is a type of domesticated animal. Known for its loyalty and '
      'faithfulness, it can be found as a welcome guest in many households.';

  List<CollapseItem> get _items => const [
    CollapseItem(
      key: '1',
      label: Text('This is panel header 1'),
      content: Text(_text),
    ),
    CollapseItem(
      key: '2',
      label: Text('This is panel header 2'),
      content: Text(_text),
    ),
    CollapseItem(
      key: '3',
      label: Text('This is panel header 3'),
      content: Text(_text),
    ),
  ];
  List<CollapseItem> get _itemsWithNoArrow => const [
    CollapseItem(
      key: '1',
      label: Text('This is panel header 1'),
      content: Text(_text),
      showArrow: false,
    ),
    CollapseItem(
      key: '2',
      label: Text('This is panel header 2'),
      content: Text(_text),
      showArrow: false,
    ),
    CollapseItem(
      key: '3',
      label: Text('This is panel header 3'),
      content: Text(_text),
      showArrow: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Basic (default open first)',
          Collapse(items: _items, defaultActiveKeys: const ['1']),
        ),
        Group('Basic (with no arrow)', Collapse(items: _itemsWithNoArrow)),
        Group(
          'Accordion (one open at a time)',
          Collapse(
            items: _items,
            accordion: true,
            defaultActiveKeys: const ['1'],
          ),
        ),
        Group(
          'Icon at the end',
          Collapse(
            items: _items,
            expandIconPosition: CollapseIconPosition.end,
            defaultActiveKeys: const ['1'],
          ),
        ),
        Group(
          'With extra & disabled panel',
          Collapse(
            defaultActiveKeys: const ['1'],
            items: [
              CollapseItem(
                key: '1',
                label: const Text('Panel with extra'),
                extra: GestureDetector(
                  onTap: () {
                    message.info("Settings info");
                  },
                  child: const Icon(Icons.settings, size: 16),
                ),
                content: const Text(_text),
              ),
              const CollapseItem(
                key: '2',
                label: Text('Disabled panel'),
                collapsible: CollapsibleTrigger.disabled,
                content: Text(_text),
              ),
              const CollapseItem(
                key: '3',
                label: Text('Only the icon toggles'),
                collapsible: CollapsibleTrigger.icon,
                content: Text(_text),
              ),
            ],
          ),
        ),
        Group(
          'Ghost',
          Collapse(items: _items, ghost: true, defaultActiveKeys: const ['1']),
        ),
        Group(
          'Borderless',
          Collapse(
            items: _items,
            bordered: false,
            defaultActiveKeys: const ['1'],
          ),
        ),
        Group(
          'Small size',
          Collapse(
            items: _items,
            size: SoftSize.small,
            defaultActiveKeys: const ['1'],
          ),
        ),
        Group(
          'Custom token (magenta header)',
          Collapse(
            items: _items,
            defaultActiveKeys: const ['1'],
            token: const CollapseToken(headerBg: Color(0x14EB2F96)),
          ),
        ),
      ],
    );
  }
}
