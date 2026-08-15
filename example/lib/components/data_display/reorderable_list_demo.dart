// reorderable_list_demo.dart
import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class ReorderableListDemo extends StatefulWidget {
  const ReorderableListDemo({super.key});

  @override
  State<ReorderableListDemo> createState() => _ReorderableListDemoState();
}

class _ReorderableListDemoState extends State<ReorderableListDemo> {
  final _rows = ['001', '002', '003', '004', '005'];
  final _cols = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    Widget card(String label, {double? width, double? height}) => Container(
      width: width,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: t.size, vertical: t.sizeSM),
      decoration: BoxDecoration(
        color: t.colorBgContainer,
        border: Border.all(color: t.colorBorderSecondary),
        borderRadius: BorderRadius.circular(t.borderRadius),
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(color: t.colorText)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Vertical (drag the handle)',
          SortableList(
            gap: t.sizeXS,
            onReorder: (from, to) =>
                setState(() => _rows.insert(to, _rows.removeAt(from))),
            children: [
              for (final r in _rows)
                KeyedSubtree(key: ValueKey(r), child: card(r)),
            ],
          ),
        ),
        Group(
          'Horizontal with custom lift builder',
          SizedBox(
            height: 48,
            child: SortableList(
              direction: Axis.horizontal,
              gap: t.sizeXS,
              onReorder: (from, to) =>
                  setState(() => _cols.insert(to, _cols.removeAt(from))),
              children: [
                for (final c in _cols)
                  KeyedSubtree(key: ValueKey(c), child: card(c, width: 88)),
              ],
              liftBuilder: (context, child, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  child: child,
                  builder: (context, child) {
                    final scale = 1.0 + 0.05 * animation.value;
                    final angle = 0.02 * (animation.value - 0.5);
                    return Transform.scale(
                      scale: scale,
                      child: Transform.rotate(
                        angle: angle,
                        child: Container(
                          decoration: BoxDecoration(
                            color: t.primary.base.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: t.primary.base.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: child,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
