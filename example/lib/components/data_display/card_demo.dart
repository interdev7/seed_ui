import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class CardDemo extends StatefulWidget {
  const CardDemo({super.key});

  @override
  State<CardDemo> createState() => _CardDemoState();
}

class _CardDemoState extends State<CardDemo> {
  bool _loading = true;
  String _tab = 'a';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Basic',
          Card(
            title: const Text('Card title'),
            extra: Button(
              variant: ButtonVariant.text,
              onPressed: () {},
              child: const Text('More'),
            ),
            child: const Text('Card content\nsecond line of content'),
          ),
        ),
        const Group(
          'No header',
          Card(child: Text('A card with a body but no header.')),
        ),
        Group(
          'Cover',
          Card(
            hoverable: true,
            cover: Container(
              height: 140,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1677FF), Color(0xFF69B1FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            child: const CardMeta(
              title: Text('Europe Street beat'),
              description: Text('www.instagram.com'),
            ),
          ),
        ),
        const Group(
          'Borderless',
          Card(
            variant: CardVariant.borderless,
            title: Text('Borderless'),
            child: Text('No border around this card.'),
          ),
        ),
        const Group(
          'Small size',
          Card(
            size: SoftSize.small,
            title: Text('Small card'),
            extra: Text('More'),
            child: Text('Tighter header and body padding.'),
          ),
        ),
        const Group(
          'Hoverable',
          Card(
            hoverable: true,
            title: Text('Hover me'),
            child: Text('Lifts with a shadow on pointer hover.'),
          ),
        ),
        const Group(
          'Inner card',
          Card(
            title: Text('Outer'),
            child: Card(
              type: CardType.inner,
              title: Text('Inner card'),
              child: Text('Nested inside another card.'),
            ),
          ),
        ),
        Group(
          'Loading',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                title: const Text('Loading card'),
                loading: _loading,
                child: const CardMeta(
                  title: Text('Card title'),
                  description: Text('This is the card description.'),
                ),
              ),
              const SizedBox(height: 12),
              Button(
                onPressed: () => setState(() => _loading = !_loading),
                child: Text(_loading ? 'Finish loading' : 'Reload'),
              ),
            ],
          ),
        ),
        const Group(
          'Meta with avatar',
          Card(
            child: CardMeta(
              avatar: CircleAvatar(child: Text('A')),
              title: Text('Card title'),
              description: Text('This is the description'),
            ),
          ),
        ),
        const Group(
          'Actions',
          Card(
            title: Text('With actions'),
            actions: [
              Icon(Icons.settings, size: 18),
              Icon(Icons.edit, size: 18),
              Icon(Icons.more_horiz, size: 18),
            ],
            child: Text('A card with a divided action bar below.'),
          ),
        ),
        Group(
          'Tab list',
          Card(
            title: const Text('Card with tabs'),
            extra: const Text('More'),
            activeTabKey: _tab,
            onTabChange: (k) => setState(() => _tab = k),
            tabList: const [
              CardTab(key: 'a', label: Text('Article')),
              CardTab(key: 'b', label: Text('App')),
              CardTab(key: 'c', label: Text('Project')),
            ],
            child: Text('Content of tab "$_tab".'),
          ),
        ),
        Group(
          'Tab list (without title)',
          Card(
            extra: const Text('More'),
            activeTabKey: _tab,
            onTabChange: (k) => setState(() => _tab = k),
            tabList: const [
              CardTab(key: 'a', label: Text('Article')),
              CardTab(key: 'b', label: Text('App')),
              CardTab(key: 'c', label: Text('Project')),
            ],
            child: Text('Content of tab "$_tab".'),
          ),
        ),
      ],
    );
  }
}
