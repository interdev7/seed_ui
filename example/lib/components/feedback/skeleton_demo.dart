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

class SkeletonDemo extends StatefulWidget {
  const SkeletonDemo({super.key});

  @override
  State<SkeletonDemo> createState() => _SkeletonDemoState();
}

class _SkeletonDemoState extends State<SkeletonDemo> {
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Group('Basic', Skeleton()),
        const Group(
          'With an avatar, and the light on',
          Skeleton(active: true, avatar: SkeletonAvatar()),
        ),
        const Group(
          'Rows and widths of your own, round ends',
          Skeleton(
            round: true,
            title: SkeletonTitle(width: 0.5),
            paragraph: SkeletonParagraph(rows: 4, widths: [1, 1, 0.8, 0.4]),
          ),
        ),
        Group(
          'Swapped for the content once it is loaded',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Switch(
                    semanticsLabel: 'Loaded',
                    value: !_loading,
                    onChanged: (v) => setState(() => _loading = !v),
                  ),
                  const SizedBox(width: 8),
                  const Text('Loaded'),
                ],
              ),
              const SizedBox(height: 16),
              Skeleton(
                loading: _loading,
                avatar: const SkeletonAvatar(),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Avatar(child: Text('A')),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Ada Lovelace — wrote the first program for a machine '
                        'that had not been built yet.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Group(
          'Blocks of other shapes',
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SkeletonButton(),
              SkeletonButton(shape: ButtonShape.round),
              SkeletonButton(shape: ButtonShape.circle),
              SkeletonAvatar(),
              SkeletonAvatar(shape: AvatarShape.square),
              SkeletonInput(),
              SkeletonImage(),
              SkeletonNode(
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Icon(Icons.insert_chart_outlined, size: 40),
                ),
              ),
            ],
          ),
        ),
        const Group(
          'Sizes',
          Wrap(
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SkeletonButton(size: SoftSize.small),
              SkeletonButton(),
              SkeletonButton(size: SoftSize.large),
            ],
          ),
        ),
      ],
    );
  }
}
