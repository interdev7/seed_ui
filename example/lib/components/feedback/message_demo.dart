import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class MessageDemo extends StatefulWidget {
  const MessageDemo({super.key});

  @override
  State<MessageDemo> createState() => _MessageDemoState();
}

class _MessageDemoState extends State<MessageDemo> {
  MessagePlacement _defaultPlacement = MessagePlacement.top;

  @override
  void dispose() {
    // `message` is global, so a default set here would follow the user to
    // every other page. Put it back on the way out.
    message.config(placement: MessagePlacement.top, offset: 24);
    super.dispose();
  }

  void _setDefault(MessagePlacement placement) {
    setState(() => _defaultPlacement = placement);
    message.config(placement: placement);
    message.info('Later toasts will appear here');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Group(
          'Types',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Button(
                onPressed: () => message.success('Saved'),
                child: const Text('success'),
              ),
              Button(
                onPressed: () => message.error('Something went wrong'),
                child: const Text('error'),
              ),
              Button(
                onPressed: () => message.warning('Check your input'),
                child: const Text('warning'),
              ),
              Button(
                onPressed: () => message.info('Just so you know'),
                child: const Text('info'),
              ),
              Button(
                onPressed: () {
                  final close = message.loading('Loading…');
                  Future.delayed(const Duration(seconds: 2), () {
                    close();
                    message.success('Done');
                  });
                },
                child: const Text('loading → success'),
              ),
            ],
          ),
        ),
        Group(
          'Placement',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Button(
                    onPressed: () => message.info(
                      'Anchored to the top',
                      placement: MessagePlacement.top,
                    ),
                    child: const Text('top'),
                  ),
                  Button(
                    onPressed: () => message.info(
                      'Anchored to the bottom',
                      placement: MessagePlacement.bottom,
                    ),
                    child: const Text('bottom'),
                  ),
                  Button(
                    // Each edge keeps its own stack, so these two never
                    // reorder one another.
                    onPressed: () {
                      message.success('Up here');
                      message.warning(
                        'And down here',
                        placement: MessagePlacement.bottom,
                      );
                    },
                    child: const Text('both at once'),
                  ),
                  Button(
                    // Whatever is already on screen keeps its place; the
                    // newcomer stacks beyond it.
                    onPressed: () {
                      for (var i = 1; i <= 3; i++) {
                        message.info(
                          'Stacked $i',
                          placement: MessagePlacement.bottom,
                        );
                      }
                    },
                    child: const Text('stack of three'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Default for calls that do not name an edge:'),
              const SizedBox(height: 8),
              Segmented<MessagePlacement>(
                value: _defaultPlacement,
                onChanged: _setDefault,
                options: const [
                  SegmentedOption(value: MessagePlacement.top, label: 'top'),
                  SegmentedOption(
                    value: MessagePlacement.bottom,
                    label: 'bottom',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
