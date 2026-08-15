import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

class PopconfirmDemo extends StatelessWidget {
  const PopconfirmDemo({super.key});

  Widget _buildGridButton(PopoverPlacement placement) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Popconfirm(
          title: 'Title',
          placement: placement,
          onOk: () {},
          child: Button(
            onPressed: () {},
            child: Text(placement.name.toUpperCase()),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 140.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Popconfirm(
                title: 'Delete this item?',
                description: 'This action cannot be undone.',
                okText: 'Delete',
                danger: true,
                onOk: () => message.success('Deleted'),
                onCancel: () => message.info('Cancelled'),
                child: Button(
                  variant: ButtonVariant.solid,
                  color: ButtonColor.danger,
                  onPressed: () {},
                  child: const Text('Delete'),
                ),
              ),
              Popconfirm(
                title: 'Publish now?',
                placement: PopoverPlacement.right,
                onOk: () async {
                  await Future<void>.delayed(const Duration(seconds: 1));
                  message.success('Published');
                },
                child: Button(
                  onPressed: () {},
                  child: const Text('Publish (async)'),
                ),
              ),
              Popconfirm(
                title: 'No arrow',
                arrow: false,
                onOk: () {},
                child: Button(
                  onPressed: () {},
                  child: const Text('arrow: false'),
                ),
              ),
              Popconfirm(
                title: 'With Barrier Color',
                barrierColor: const Color(0x7F000000),
                onOk: () => message.success('Confirmed'),
                child: Button(
                  onPressed: () {},
                  child: const Text('barrierColor'),
                ),
              ),
            ],
          ),
          const Divider(height: 40),
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxWidth * 0.7,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FlexColumnWidth(),
                      2: IntrinsicColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        children: [
                          _buildGridButton(PopoverPlacement.topLeft),
                          _buildGridButton(PopoverPlacement.top),
                          _buildGridButton(PopoverPlacement.topRight),
                        ],
                      ),
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildGridButton(PopoverPlacement.leftTop),
                                const SizedBox(height: 12),
                                _buildGridButton(PopoverPlacement.left),
                                const SizedBox(height: 12),
                                _buildGridButton(PopoverPlacement.leftBottom),
                              ],
                            ),
                          ),
                          const SizedBox.shrink(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildGridButton(PopoverPlacement.rightTop),
                                const SizedBox(height: 12),
                                _buildGridButton(PopoverPlacement.right),
                                const SizedBox(height: 12),
                                _buildGridButton(PopoverPlacement.rightBottom),
                              ],
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          _buildGridButton(PopoverPlacement.bottomLeft),
                          _buildGridButton(PopoverPlacement.bottom),
                          _buildGridButton(PopoverPlacement.bottomRight),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
