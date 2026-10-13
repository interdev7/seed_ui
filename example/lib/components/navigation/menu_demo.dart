import 'package:flutter/material.dart'
    hide
        ThemeData,
        Checkbox,
        Radio,
        RadioGroup,
        Switch,
        Tooltip,
        Drawer,
        Divider,
        Badge;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

const _items = <MenuEntry<String>>[
  MenuItem(value: 'mail', label: 'Mail', icon: Icon(Icons.mail_outline)),
  MenuItem(
    value: 'calendar',
    label: 'Calendar',
    icon: Icon(Icons.calendar_today_outlined),
    extra: Badge(count: 3),
  ),
  MenuItem(
    value: 'settings',
    label: 'Settings',
    icon: Icon(Icons.settings_outlined),
    children: [
      MenuItem(value: 'profile', label: 'Profile'),
      MenuItem(value: 'security', label: 'Security'),
      MenuItem(
        value: 'advanced',
        label: 'Advanced',
        children: [
          MenuItem(value: 'logs', label: 'Logs'),
          MenuItem(value: 'flags', label: 'Feature flags'),
        ],
      ),
    ],
  ),
  MenuDivider(),
  MenuGroup(
    label: 'Account',
    children: [
      MenuItem(value: 'billing', label: 'Billing', icon: Icon(Icons.payment)),
      MenuItem(value: 'archived', label: 'Archived', disabled: true),
      MenuItem(
        value: 'delete',
        label: 'Delete account',
        icon: Icon(Icons.delete_outline),
        danger: true,
      ),
    ],
  ),
];

class MenuDemo extends StatefulWidget {
  const MenuDemo({super.key});

  @override
  State<MenuDemo> createState() => _MenuDemoState();
}

class _MenuDemoState extends State<MenuDemo> {
  String _selected = 'mail';
  bool _collapsed = false;

  void _select(String v) => setState(() => _selected = v);

  Widget _panel(Widget menu) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: context.softToken.colorBorderSecondary),
      borderRadius: BorderRadius.circular(8),
    ),
    child: menu,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Inline — a sidebar',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 260,
              child: _panel(
                Menu<String>(
                  items: _items,
                  selectedValue: _selected,
                  defaultOpenValues: const {'settings'},
                  onSelect: _select,
                ),
              ),
            ),
          ),
        ),
        Group(
          'Collapsed to its icons',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Switch(
                    semanticsLabel: 'Collapsed',
                    value: _collapsed,
                    onChanged: (v) => setState(() => _collapsed = v),
                  ),
                  const SizedBox(width: 8),
                  const Text('Collapsed'),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(
                  width: _collapsed ? null : 260,
                  child: _panel(
                    Menu<String>(
                      items: _items,
                      inlineCollapsed: _collapsed,
                      selectedValue: _selected,
                      onSelect: _select,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Group(
          'Vertical — submenus float out',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 260,
              child: _panel(
                Menu<String>(
                  mode: MenuMode.vertical,
                  items: _items,
                  selectedValue: _selected,
                  onSelect: _select,
                ),
              ),
            ),
          ),
        ),
        Group(
          'Horizontal — a top bar',
          Menu<String>(
            mode: MenuMode.horizontal,
            items: _items,
            selectedValue: _selected,
            onSelect: _select,
          ),
        ),
        Group(
          'Accordion — one submenu open at a time',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 260,
              child: _panel(
                const Menu<String>(
                  accordion: true,
                  items: [
                    MenuItem(
                      value: 'a',
                      label: 'Navigation one',
                      icon: Icon(Icons.explore_outlined),
                      children: [
                        MenuItem(value: 'a1', label: 'Option 1'),
                        MenuItem(value: 'a2', label: 'Option 2'),
                      ],
                    ),
                    MenuItem(
                      value: 'b',
                      label: 'Navigation two',
                      icon: Icon(Icons.apps),
                      children: [
                        MenuItem(value: 'b1', label: 'Option 3'),
                        MenuItem(value: 'b2', label: 'Option 4'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
