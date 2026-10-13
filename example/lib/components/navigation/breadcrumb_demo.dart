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

class BreadcrumbDemo extends StatelessWidget {
  const BreadcrumbDemo({super.key});

  void _go(String? where) => message.info('Go to $where');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Basic',
          Breadcrumb<String>(
            onItemTap: _go,
            items: const [
              BreadcrumbItem(value: 'Home', label: 'Home'),
              BreadcrumbItem(value: 'Projects', label: 'Projects'),
              BreadcrumbItem(label: 'Seed'),
            ],
          ),
        ),
        Group(
          'With icons',
          Breadcrumb<String>(
            onItemTap: _go,
            items: const [
              BreadcrumbItem(
                value: 'Home',
                icon: Icon(Icons.home_outlined),
                semanticsLabel: 'Home',
              ),
              BreadcrumbItem(
                value: 'Users',
                label: 'Users',
                icon: Icon(Icons.person_outline),
              ),
              BreadcrumbItem(label: 'Ada Lovelace'),
            ],
          ),
        ),
        Group(
          'A separator of your own',
          Breadcrumb<String>(
            onItemTap: _go,
            separator: const Icon(Icons.chevron_right, size: 16),
            items: const [
              BreadcrumbItem(value: 'Settings', label: 'Settings'),
              BreadcrumbItem(value: 'Account', label: 'Account'),
              BreadcrumbItem(label: 'Security'),
            ],
          ),
        ),
        Group(
          'A menu on a crumb',
          Breadcrumb<String>(
            onItemTap: _go,
            items: const [
              BreadcrumbItem(value: 'Home', label: 'Home'),
              BreadcrumbItem(
                value: 'Seed',
                label: 'Seed',
                menu: [
                  DropdownItem(value: 'Atlas', label: 'Atlas'),
                  DropdownItem(value: 'Orbit', label: 'Orbit'),
                  DropdownItem(value: 'Harbor', label: 'Harbor'),
                ],
              ),
              BreadcrumbItem(label: 'Settings'),
            ],
          ),
        ),
        Group(
          'A long path, folded',
          Breadcrumb<String>(
            onItemTap: _go,
            maxItems: 4,
            items: const [
              BreadcrumbItem(value: 'Home', label: 'Home'),
              BreadcrumbItem(value: 'Company', label: 'Company'),
              BreadcrumbItem(value: 'Finance', label: 'Finance'),
              BreadcrumbItem(value: 'Reports', label: 'Reports'),
              BreadcrumbItem(value: '2026', label: '2026'),
              BreadcrumbItem(label: 'March'),
            ],
          ),
        ),
      ],
    );
  }
}
