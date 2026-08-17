import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class TabsDemo extends StatefulWidget {
  const TabsDemo({super.key});

  @override
  State<TabsDemo> createState() => _TabsDemoState();
}

class _TabsDemoState extends State<TabsDemo> {
  List<TabItem> _editItems = const [
    TabItem(key: '1', label: Text('Tab 1'), content: Text('Content of Tab 1')),
    TabItem(key: '2', label: Text('Tab 2'), content: Text('Content of Tab 2')),
    TabItem(key: '3', label: Text('Tab 3'), content: Text('Content of Tab 3')),
  ];
  String _editActive = '1';
  int _newTab = 4;
  bool _snap = true;

  /// A run long enough to actually scroll, so the difference is visible.
  static final _longRun = [
    for (var i = 1; i <= 14; i++)
      TabItem(
        key: 'long$i',
        label: Text('Section number $i'),
        content: Text('Panel $i'),
      ),
  ];

  static const _items = [
    TabItem(
      key: '1',
      label: Text('Tab 1'),
      icon: Icon(Icons.home),
      content: Text('Content of Tab 1'),
    ),
    TabItem(key: '2', label: Text('Tab 2'), content: Text('Content of Tab 2')),
    TabItem(
      key: '3',
      label: Text('Disabled'),
      disabled: true,
      icon: Icon(Icons.lock),
      content: Text('Content of Tab 3'),
    ),
    TabItem(key: '4', label: Text('Tab 4'), content: Text('Content of Tab 4')),
  ];

  SoftSize size = SoftSize.middle;

  final _controller = TabsController(
    items: const [
      TabItem(
        key: '1',
        label: Text('Tab 1'),
        content: Text('Content of Tab 1'),
      ),
      TabItem(
        key: '2',
        label: Text('Tab 2'),
        content: Text('Content of Tab 2'),
      ),
    ],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: RadioGroup(
            value: size,
            optionType: RadioOptionType.button,
            options: const [
              RadioOption(value: SoftSize.small, label: Text('Small')),
              RadioOption(value: SoftSize.middle, label: Text('Middle')),
              RadioOption(value: SoftSize.large, label: Text('Large')),
            ],
            onChanged: (v) {
              setState(() {
                size = v;
              });
            },
          ),
        ),
        Group('Line (default)', Tabs(items: _items, size: size)),
        Group('Card', Tabs(type: TabsType.card, items: _items, size: size)),
        Group(
          'Card',
          Tabs(
            type: TabsType.card,
            items: _items,
            size: size,
            tabPosition: TabPosition.left,
          ),
        ),
        Group(
          'Custom token (magenta ink bar)',
          Tabs(
            items: _items,
            size: size,
            token: const TabsToken(
              inkBarColor: Color(0xFFEB2F96),
              itemSelectedColor: Color(0xFFEB2F96),
              itemHoverColor: Color(0xFFF759AB),
            ),
          ),
        ),
        Group(
          'Extra content (right)',
          Tabs(
            items: _items,
            size: size,
            tabBarExtraContent: TabBarExtra.right(
              Button(onPressed: () {}, child: const Text('Extra')),
            ),
          ),
        ),
        Group(
          'Extra content (left & right)',
          Tabs(
            items: _items,
            size: size,
            tabBarExtraContent: TabBarExtra(
              left: Button(onPressed: () {}, child: const Text('Left')),
              right: Button(onPressed: () {}, child: const Text('Right')),
            ),
          ),
        ),
        Group(
          'Position: left',
          SizedBox(
            height: 160,
            child: Tabs(
              tabPosition: TabPosition.left,
              items: _items,
              size: size,
            ),
          ),
        ),
        Group(
          'Position: right',
          SizedBox(
            height: 160,
            child: Tabs(
              tabPosition: TabPosition.right,
              items: _items,
              size: size,
            ),
          ),
        ),
        Group(
          'Scrollable vertical (centre the selected tab)',
          SizedBox(
            height: 160,
            child: Tabs(
              tabPosition: TabPosition.left,
              scrollAlign: TabScrollAlign.center,
              size: size,
              items: [
                for (var i = 1; i <= 12; i++)
                  TabItem(
                    key: '$i',
                    label: Text('Tab $i'),
                    content: Text('Content of Tab $i'),
                  ),
              ],
            ),
          ),
        ),
        Group(
          'Content position: center',
          Tabs(
            items: _items,
            size: size,
            contentPosition: TabContentPosition.center,
          ),
        ),
        Group(
          'Controller (add via onCreateTab, rename, close)',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tabs(
                type: TabsType.editableCard,
                controller: _controller,
                size: size,
                onCreateTab: (index) => CreateTabData(
                  label: Text('New ${index + 1}'),
                  content: Text('Fresh tab #${index + 1}'),
                ),
              ),
              const SizedBox(height: 8),
              Button(
                onPressed: () {
                  final key = _controller.activeKey;
                  if (key != null) {
                    _controller.setTitle(
                      key,
                      'Renamed ${DateTime.now().second}',
                    );
                  }
                },
                child: const Text('Rename active tab'),
              ),
            ],
          ),
        ),
        Group(
          'Snapping a long run',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fling the bar sideways. With snapping on it settles with a '
                'tab against the leading edge; with it off it stops wherever '
                'the throw ended, often mid-label.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Switch(
                    value: _snap,
                    onChanged: (v) => setState(() => _snap = v),
                  ),
                  const SizedBox(width: 8),
                  Text(_snap ? 'snap: true' : 'snap: false'),
                ],
              ),
              const SizedBox(height: 12),
              // Boxed narrower than the run so there is something to scroll.
              SizedBox(
                width: 320,
                child: Tabs(
                  // Rebuild the bar outright when the flag flips: scroll
                  // physics are read when the view is created, so a live
                  // change would otherwise not take until the next fling.
                  key: ValueKey(_snap),
                  items: _longRun,
                  size: size,
                  snap: _snap,
                ),
              ),
            ],
          ),
        ),
        Group(
          'Editable card (add / close)',
          Tabs(
            type: TabsType.editableCard,
            items: _editItems,
            size: size,
            activeKey: _editActive,
            onChange: (k) => setState(() => _editActive = k),
            onEdit: (key, action) => setState(() {
              if (action == TabEditAction.add) {
                final k = '${_newTab++}';
                _editItems = [
                  ..._editItems,
                  TabItem(
                    key: k,
                    label: Text('Tab $k'),
                    content: Text('New $k'),
                  ),
                ];
                _editActive = k;
              } else if (key != null) {
                _editItems = _editItems.where((e) => e.key != key).toList();
                if (_editActive == key && _editItems.isNotEmpty) {
                  _editActive = _editItems.first.key;
                }
              }
            }),
          ),
        ),
      ],
    );
  }
}
