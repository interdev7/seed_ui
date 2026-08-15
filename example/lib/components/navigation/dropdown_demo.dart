import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class DropdownDemo extends StatefulWidget {
  const DropdownDemo({super.key});

  @override
  State<DropdownDemo> createState() => _DropdownDemoState();
}

class _DropdownDemoState extends State<DropdownDemo> {
  bool _clickOpen = false;
  bool _barrierOpen = false;
  final _newItem = TextEditingController();
  final List<String> _items = ['Item 1', 'Item 2'];

  @override
  void dispose() {
    _newItem.dispose();
    super.dispose();
  }

  static const _menu = <DropdownEntry>[
    DropdownItem(
      key: 'profile',
      label: Text('Profile'),
      icon: Icon(Icons.person),
    ),
    DropdownItem(
      key: 'settings',
      label: Text('Settings'),
      icon: Icon(Icons.settings),
    ),
    DropdownDivider(),
    DropdownItem(
      key: 'more',
      label: Text('More'),
      children: [
        DropdownItem(key: 'help', label: Text('Help')),
        DropdownItem(key: 'about', label: Text('About')),
      ],
    ),
    DropdownDivider(),
    DropdownItem(
      key: 'logout',
      label: Text('Log out'),
      icon: Icon(Icons.logout),
      danger: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Group(
          'Hover',
          Dropdown(
            menu: _menu,
            onItemTap: (k) => message.info('Tapped: $k'),
            child: Button(onPressed: () {}, child: const Text('Hover me')),
          ),
        ),
        Group(
          'With Barrier Color (click)',
          Dropdown(
            trigger: const [],
            open: _barrierOpen,
            onOpenChange: (v) => setState(() => _barrierOpen = v),
            barrierColor: const Color.fromARGB(126, 105, 197, 102), // 50% black
            menu: _menu,
            arrow: true,
            onItemTap: (k) => message.info('Tapped: $k'),
            child: Button(
              onPressed: () => setState(() => _barrierOpen = !_barrierOpen),
              child: const Text('Click me (Barrier)'),
            ),
          ),
        ),
        Group(
          'Click (controlled)',
          // A button trigger owns its own tap, so drive the menu's open state
          // from the button rather than the Dropdown's internal gesture.
          Dropdown(
            trigger: const [],
            open: _clickOpen,
            onOpenChange: (v) => setState(() => _clickOpen = v),
            menu: _menu,
            arrow: true,
            onItemTap: (k) => message.info('Tapped: $k'),
            child: Button(
              variant: ButtonVariant.solid,
              color: ButtonColor.primary,
              onPressed: () => setState(() => _clickOpen = !_clickOpen),
              child: const Text('Click me'),
            ),
          ),
        ),
        Group(
          'Context menu (right-click / long-press)',
          Dropdown(
            trigger: const [DropdownTrigger.contextMenu],
            menu: _menu,
            onItemTap: (k) => message.info('Tapped: $k'),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.softToken.colorFillTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Right-click here'),
            ),
          ),
        ),
        Group(
          'Grouped items (hover)',
          Dropdown(
            menu: const [
              DropdownGroup(
                label: Text('Account'),
                children: [
                  DropdownItem(key: 'billing', label: Text('Billing')),
                  DropdownItem(key: 'team', label: Text('Team')),
                ],
              ),
              DropdownGroup(
                label: Text('Danger zone'),
                children: [
                  DropdownItem(
                    key: 'delete',
                    label: Text('Delete account'),
                    danger: true,
                  ),
                ],
              ),
            ],
            child: Button(onPressed: () {}, child: const Text('Grouped')),
          ),
        ),
        Group(
          'popupRender (menu + custom footer)',
          Dropdown(
            menu: [
              for (final item in _items)
                DropdownItem(key: item, label: Text(item)),
            ],
            onItemTap: (k) => message.info('Tapped: $k'),
            // A custom popup body has no anchor width to match, so give it an
            // explicit width (such as `width: 300` on the Select) instead
            // of letting the Expanded input stretch across the viewport.
            popupRender: (context, menu) => SizedBox(
              width: 240,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  menu,
                  Container(height: 1, color: context.softToken.colorSplit),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Input(
                            controller: _newItem,
                            size: SoftSize.small,
                            placeholder: 'New item',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Button(
                          variant: ButtonVariant.text,
                          color: ButtonColor.primary,
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final text = _newItem.text.trim();
                            if (text.isEmpty) return;
                            setState(() {
                              _items.add(text);
                              _newItem.clear();
                            });
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            child: Button(onPressed: () {}, child: const Text('popupRender')),
          ),
        ),
      ],
    );
  }
}
