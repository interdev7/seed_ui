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

const _text = Text(
  'A divider separates blocks of content, and a title in it says what the '
  'next block is about.',
);

class DividerDemo extends StatelessWidget {
  const DividerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Horizontal',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_text, Divider(), _text],
          ),
        ),
        Group(
          'Dashed and dotted',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _text,
              Divider(variant: DividerVariant.dashed),
              _text,
              Divider(variant: DividerVariant.dotted),
              _text,
            ],
          ),
        ),
        Group(
          'With a title',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Divider(child: Text('Centre')),
              Divider(
                titlePlacement: DividerTitlePlacement.start,
                child: Text('Start'),
              ),
              Divider(
                titlePlacement: DividerTitlePlacement.end,
                child: Text('End'),
              ),
              Divider(
                titlePlacement: DividerTitlePlacement.start,
                titleMargin: 0,
                child: Text('Start, flush with the edge'),
              ),
            ],
          ),
        ),
        Group('A plain title', Divider(plain: true, child: Text('Plain text'))),
        Group(
          'Sizes',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _text,
              Divider(size: SoftSize.small),
              _text,
              Divider(size: SoftSize.large),
              _text,
            ],
          ),
        ),
        Group(
          'Vertical',
          Row(
            children: [
              Text('Edit'),
              Divider(orientation: DividerOrientation.vertical),
              Text('Share'),
              Divider(orientation: DividerOrientation.vertical),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }
}
