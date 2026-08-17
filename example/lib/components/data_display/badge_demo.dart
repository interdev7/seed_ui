import 'package:flutter/material.dart'
    hide
        Badge,
        Card,
        ThemeData,
        Checkbox,
        Radio,
        RadioGroup,
        Switch,
        Tooltip,
        Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class BadgeDemo extends StatefulWidget {
  const BadgeDemo({super.key});

  @override
  State<BadgeDemo> createState() => _BadgeDemoState();
}

class _BadgeDemoState extends State<BadgeDemo> {
  int _count = 5;
  bool _dot = false;
  bool _showZero = false;

  /// Something square to hang a badge off, so the corner is easy to see.
  Widget get _block => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: context.softToken.colorFillSecondary,
      borderRadius: BorderRadius.circular(context.softToken.borderRadius),
    ),
  );

  Widget _card(String title) => Card(
    title: Text(title),
    child: const Text('A container with something worth marking.'),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Counts',
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              Badge(count: 5, child: _block),
              Badge(count: 42, child: _block),
              Badge(count: 100, child: _block),
              Badge(count: 1200, overflowCount: 999, child: _block),
            ],
          ),
        ),
        Group(
          'Dot, and content of your own',
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              Badge(dot: true, child: _block),
              const Badge(dot: true, child: Icon(Icons.notifications_outlined)),
              Badge(content: const Text('new'), child: _block),
            ],
          ),
        ),
        Group(
          'Live',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Badge(
                    count: _count,
                    dot: _dot,
                    showZero: _showZero,
                    child: _block,
                  ),
                  const SizedBox(width: 24),
                  Button(
                    onPressed: () => setState(() => _count++),
                    child: const Text('+1'),
                  ),
                  const SizedBox(width: 8),
                  Button(
                    onPressed: _count == 0
                        ? null
                        : () => setState(() => _count--),
                    child: const Text('−1'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Switch(
                    value: _dot,
                    onChanged: (v) => setState(() => _dot = v),
                  ),
                  const SizedBox(width: 8),
                  const Text('dot'),
                  const SizedBox(width: 24),
                  Switch(
                    value: _showZero,
                    onChanged: (v) => setState(() => _showZero = v),
                  ),
                  const SizedBox(width: 8),
                  const Text('showZero'),
                ],
              ),
              const SizedBox(height: 8),
              // The point of showZero: at nought the badge disappears unless
              // the nought is itself worth saying.
              Text(
                _count == 0 && !_showZero && !_dot
                    ? 'Nothing drawn — the count is zero.'
                    : 'count: $_count',
              ),
            ],
          ),
        ),
        const Group(
          'Statuses',
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              Badge(status: BadgeStatus.neutral, text: Text('Idle')),
              Badge(status: BadgeStatus.success, text: Text('Live')),
              Badge(status: BadgeStatus.processing, text: Text('Deploying')),
              Badge(status: BadgeStatus.warning, text: Text('Degraded')),
              Badge(status: BadgeStatus.error, text: Text('Down')),
            ],
          ),
        ),
        Group(
          'Size and offset',
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              Badge(count: 8, child: _block),
              Badge(count: 8, size: SoftSize.small, child: _block),
              Badge(count: 8, offset: const Offset(-6, 6), child: _block),
            ],
          ),
        ),
        Group(
          'Custom colour, and a title for screen readers',
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              Badge(count: 9, color: const Color(0xFF722ED1), child: _block),
              Badge(count: 120, title: '120 unread messages', child: _block),
            ],
          ),
        ),
        Group('Ribbon', Ribbon(text: const Text('Hot'), child: _card('Card'))),
        Group(
          'Ribbon: leading end, and a colour',
          Ribbon(
            placement: RibbonPlacement.start,
            text: const Text('New'),
            color: const Color(0xFFFA541C),
            child: _card('Card'),
          ),
        ),
      ],
    );
  }
}
