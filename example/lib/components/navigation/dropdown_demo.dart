import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

/// What the menu below reports. An enum, so the handler is checked against
/// the items and a forgotten case will not compile.
enum MenuAction { profile, settings, more, help, about, logout }

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

  // Hoisted and shared by five dropdowns, so there is no call site for a type
  // to be inferred from — and a list mixing items with dividers cannot infer
  // one anyway, since Dart settles a list's element type before the menu's.
  // Named here, it is checked everywhere the menu is used.
  static const _menu = <DropdownEntry<MenuAction>>[
    DropdownItem(
      value: MenuAction.profile,
      label: 'Profile',
      icon: Icon(Icons.person),
    ),
    DropdownItem(
      value: MenuAction.settings,
      label: 'Settings',
      icon: Icon(Icons.settings),
    ),
    DropdownDivider(),
    DropdownItem(
      value: MenuAction.more,
      label: 'More',
      children: [
        DropdownItem(value: MenuAction.help, label: 'Help'),
        DropdownItem(value: MenuAction.about, label: 'About'),
      ],
    ),
    DropdownDivider(),
    DropdownItem(
      value: MenuAction.logout,
      label: 'Log out',
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
            // Exhaustive, because the menu carries its type: drop a case and
            // this stops compiling. It is also what proves the annotation on
            // _menu is doing work — weaken it to a bare <DropdownEntry> and
            // the switch loses its subject.
            onItemTap: (action) => message.info(switch (action) {
              MenuAction.profile => 'Your profile',
              MenuAction.settings => 'Settings',
              MenuAction.more => 'More',
              MenuAction.help => 'Help',
              MenuAction.about => 'About',
              MenuAction.logout => 'Logged out',
              null => 'Nothing',
            }),
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
            onItemTap: (action) => message.info('Tapped: ${action?.name}'),
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
            onItemTap: (action) => message.info('Tapped: ${action?.name}'),
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
            onItemTap: (action) => message.info('Tapped: ${action?.name}'),
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
                label: 'Account',
                children: [
                  DropdownItem(value: 'billing', label: 'Billing'),
                  DropdownItem(value: 'team', label: 'Team'),
                ],
              ),
              DropdownGroup(
                label: 'Danger zone',
                children: [
                  DropdownItem(
                    value: 'delete',
                    label: 'Delete account',
                    danger: true,
                  ),
                ],
              ),
            ],
            child: Button(onPressed: () {}, child: const Text('Grouped')),
          ),
        ),
        Group(
          'itemBuilder (a row drawn by the caller)',
          Dropdown(
            trigger: const [DropdownTrigger.click],
            menu: _menu,
            // The row's height, highlight, submenu caret and tap stay with
            // the menu; this draws what is inside it. `hovered` is the one
            // thing the item itself cannot say.
            itemBuilder: (context, item, hovered) => Row(
              children: [
                if (item.icon != null) ...[
                  item.icon!,
                  const SizedBox(width: 8),
                ],
                Expanded(child: Text(item.label ?? '')),
                if (hovered) const Text('↵', style: TextStyle(fontSize: 12)),
              ],
            ),
            onItemTap: (action) => message.info('Tapped: ${action?.name}'),
            child: Button(onPressed: () {}, child: const Text('Drawn by me')),
          ),
        ),
        Group(
          'popupRender (menu + custom footer)',
          Dropdown(
            trigger: const [DropdownTrigger.click],
            menu: [
              for (final item in _items) DropdownItem(value: item, label: item),
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
        Group(
          'popupRender (a surface of your own)',
          Dropdown(
            trigger: const [DropdownTrigger.click],
            // For a surface the token cannot describe — a gradient, here.
            // A plain colour, corners, a border and a shadow are all token
            // fields; reach for this only past them. The chrome is blanked
            // first, since the panel is drawn around what this returns, and
            // nothing is clipped at a radius of zero, so the shadow below is
            // not cut off at the panel's edge.
            //
            // A flat menu on purpose: popupRender dresses the panel it is
            // handed, and a submenu opens a panel of its own, which wears the
            // token — blanked here. Style a nested menu through the token
            // instead, as the group below does.
            token: const DropdownToken(
              menuBg: Color(0x00000000),
              borderRadius: 0,
              shadow: [],
            ),
            menu: const [
              DropdownItem(
                value: MenuAction.profile,
                label: 'Profile',
                icon: Icon(Icons.person),
              ),
              DropdownItem(
                value: MenuAction.settings,
                label: 'Settings',
                icon: Icon(Icons.settings),
              ),
              DropdownItem(
                value: MenuAction.logout,
                label: 'Log out',
                icon: Icon(Icons.logout),
                danger: true,
              ),
            ],
            onItemTap: (action) => message.info('Tapped: ${action?.name}'),
            popupRender: (context, menu) {
              final t = context.softToken;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [t.primary.bg, t.colorBgElevated],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: t.primary.border),
                  boxShadow: [
                    BoxShadow(
                      color: t.primary.base.withValues(alpha: 0.24),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: menu,
              );
            },
            child: Button(
              onPressed: () {},
              child: const Text('A surface of my own'),
            ),
          ),
        ),
        Group(
          'gap (how far a panel stands off)',
          Row(
            children: [
              for (final gap in const [0.0, 4.0, 20.0]) ...[
                Dropdown(
                  trigger: const [DropdownTrigger.click],
                  // The same distance twice over: this menu from its button,
                  // and the submenu under `More` from its row. At zero the two
                  // surfaces touch and read as one.
                  token: DropdownToken(gap: gap),
                  menu: _menu,
                  onItemTap: (a) => message.info('Tapped: ${a?.name}'),
                  child: Button(
                    onPressed: () {},
                    child: Text('gap: ${gap.toInt()}'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),
        ),
        Group(
          'One look for every menu (ComponentsConfig)',
          // Said once, on the provider, and every menu under it wears it —
          // no popupRender, no token at the call site. Background, corners,
          // border and shadow are all the token's, so most house styles
          // never need a builder at all.
          ConfigProvider(
            theme: ThemeData(
              components: ComponentsConfig(
                dropdown: DropdownToken(
                  menuBg: context.softToken.primary.bg,
                  borderRadius: 20,
                  gap: 7,
                  border: BorderSide(color: context.softToken.primary.border),
                  shadow: [
                    BoxShadow(
                      color: context.softToken.primary.base.withValues(
                        alpha: .24,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
            child: Row(
              children: [
                Dropdown(
                  trigger: const [DropdownTrigger.click],
                  menu: _menu,
                  onItemTap: (a) => message.info('Tapped: ${a?.name}'),
                  child: Button(
                    onPressed: () {},
                    child: const Text('One menu'),
                  ),
                ),
                const SizedBox(width: 12),
                Dropdown(
                  trigger: const [DropdownTrigger.click],
                  menu: _menu,
                  onItemTap: (a) => message.info('Tapped: ${a?.name}'),
                  child: Button(
                    onPressed: () {},
                    child: const Text('And another'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
