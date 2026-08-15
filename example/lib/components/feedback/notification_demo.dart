import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:seed_ui/seed_ui.dart';
import '../group.dart';

class NotificationDemo extends StatefulWidget {
  const NotificationDemo({super.key});

  @override
  State<NotificationDemo> createState() => _NotificationDemoState();
}

class _NotificationDemoState extends State<NotificationDemo> {
  bool _stackEnabled = true;
  int _stackThreshold = 3;
  NotificationPlacement _placement = NotificationPlacement.topRight;

  void _applyConfig() {
    notification.config(
      stack: _stackEnabled,
      stackThreshold: _stackThreshold,
      placement: _placement,
    );
  }

  void _openBatch(int count) {
    _applyConfig();
    for (int i = 1; i <= count; i++) {
      notification.open(
        NotificationConfig(
          message: Text('Notification #$i'),
          description: Text(
            'This is stacked notification card number $i in the deck.',
          ),
          duration: Duration.zero,
          placement: _placement,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Interactive Controls Group
        Group(
          'Notification Stack Configuration 🥞',
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Enable Stack Deck (Grouping):',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: token.colorText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: _stackEnabled,
                      onChanged: (val) {
                        setState(() {
                          _stackEnabled = val;
                          _applyConfig();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  children: [
                    Text(
                      'Stack Threshold:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: token.colorText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Segmented<int>(
                      size: SoftSize.small,
                      options: const [
                        SegmentedOption(value: 2, label: '2 Cards'),
                        SegmentedOption(value: 3, label: '3 Cards (Default)'),
                        SegmentedOption(value: 4, label: '4 Cards'),
                        SegmentedOption(value: 5, label: '5 Cards'),
                      ],
                      value: _stackThreshold,
                      onChanged: (val) {
                        setState(() {
                          _stackThreshold = val;
                          _applyConfig();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  children: [
                    Text(
                      'Placement Corner:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: token.colorText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Segmented<NotificationPlacement>(
                      size: SoftSize.small,
                      options: const [
                        SegmentedOption(
                          value: NotificationPlacement.topRight,
                          label: 'topRight',
                        ),
                        SegmentedOption(
                          value: NotificationPlacement.topLeft,
                          label: 'topLeft',
                        ),
                        SegmentedOption(
                          value: NotificationPlacement.bottomRight,
                          label: 'bottomRight',
                        ),
                        SegmentedOption(
                          value: NotificationPlacement.bottomLeft,
                          label: 'bottomLeft',
                        ),
                      ],
                      value: _placement,
                      onChanged: (val) {
                        setState(() {
                          _placement = val;
                          _applyConfig();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Button(
                      variant: ButtonVariant.solid,
                      color: ButtonColor.primary,
                      onPressed: () => _openBatch(5),
                      child: const Text('Open 5 Cards (Stack Test 🥞)'),
                    ),
                    Button(
                      onPressed: () => _openBatch(1),
                      child: const Text('Add 1 Notification'),
                    ),
                    Button(
                      variant: ButtonVariant.outlined,
                      color: ButtonColor.danger,
                      onPressed: () => notification.destroy(),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Group(
          'Notification Types & Shorthands',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Button(
                onPressed: () => notification.success(
                  'Done',
                  description: 'Your file was uploaded to the server.',
                ),
                child: const Text('success'),
              ),
              Button(
                onPressed: () => notification.error(
                  'Failed',
                  description: 'Could not reach the server.',
                ),
                child: const Text('error'),
              ),
              Button(
                onPressed: () => notification.info('Headline only'),
                child: const Text('headline only'),
              ),
              Button(
                onPressed: () => notification.warning(
                  'Bottom left',
                  description: 'placement: bottomLeft',
                  placement: NotificationPlacement.bottomLeft,
                ),
                child: const Text('bottomLeft'),
              ),
              Button(
                onPressed: () {
                  late final NotificationHandle close;
                  close = notification.open(
                    NotificationConfig(
                      message: const Text('Please confirm'),
                      description: const Text(
                        'Delete this file? This cannot be undone.',
                      ),
                      type: StatusType.warning,
                      duration: Duration.zero,
                      actions: [
                        Button(
                          size: SoftSize.small,
                          onPressed: () => close(),
                          child: const Text('Cancel'),
                        ),
                        Button(
                          size: SoftSize.small,
                          variant: ButtonVariant.solid,
                          color: ButtonColor.danger,
                          onPressed: () {
                            close();
                            message.success('Deleted');
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('with actions'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
