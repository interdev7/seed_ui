import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class AlertDemo extends StatelessWidget {
  const AlertDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Types',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final type in StatusType.values) ...[
                Alert(
                  type: type,
                  message: Text('${type.name} alert'),
                  showIcon: true,
                  closable: true,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),

        Group(
          'With description and action',
          Alert(
            type: StatusType.warning,
            message: const Text('With description and action'),
            description: const Text(
              'A longer explanation of what needs attention.',
            ),
            showIcon: true,
            action: Button(
              size: SoftSize.small,
              onPressed: () {},
              child: const Text('Fix'),
            ),
          ),
        ),

        // message and description are widgets, so anything composes: spans,
        // links, lists, whole layouts.
        const Group(
          'Rich message',
          Alert(
            type: StatusType.info,
            showIcon: true,
            message: Row(
              children: [
                Text('Build '),
                Tag(color: TagColor.processing, child: Text('#1287')),
                Text(' is running'),
              ],
            ),
            description: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Started 2 minutes ago by @interdev7.'),
                SizedBox(height: 8),
                Progress(percent: 0.62, size: SoftSize.small),
              ],
            ),
          ),
        ),

        // The alert seeds a DefaultTextStyle, so a child that sets its own
        // style wins — here a monospace, tinted line inside the description.
        Group(
          'Styled child overrides the default',
          Alert(
            type: StatusType.error,
            showIcon: true,
            message: const Text('Deploy failed'),
            description: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('The health check never came back:'),
                const SizedBox(height: 4),
                Text(
                  'GET /healthz — 504 Gateway Timeout',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: t.fontSizeSM,
                    color: t.error.text,
                  ),
                ),
              ],
            ),
          ),
        ),

        const Group(
          'Without icon',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Alert(message: Text('Plain notice, no icon')),
              SizedBox(height: 8),
              Alert(
                type: StatusType.success,
                message: Text('Saved'),
                description: Text('Your changes are live.'),
              ),
            ],
          ),
        ),

        Group(
          'Custom icon',
          Alert(
            type: StatusType.info,
            showIcon: true,
            icon: Icon(Icons.rocket_launch, size: 24, color: t.primary.base),
            message: const Text('New version available'),
            description: const Text('Restart the app to pick up 2.4.0.'),
          ),
        ),

        // A banner spans its container edge to edge: square corners, no border.
        const Group(
          'Banner',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Alert(
                banner: true,
                type: StatusType.warning,
                message: Text('Scheduled maintenance tonight, 02:00–04:00 UTC'),
                showIcon: true,
              ),
              SizedBox(height: 8),
              Alert(
                banner: true,
                type: StatusType.error,
                message: Text('Connection lost'),
                description: Text('Retrying every 5 seconds.'),
                showIcon: true,
                closable: true,
              ),
            ],
          ),
        ),

        Group(
          'Closable with onClose',
          Alert(
            type: StatusType.info,
            message: const Text('Dismiss me'),
            description: const Text('onClose fires after the alert is gone.'),
            closable: true,
            showIcon: true,
            onClose: () => message.info('Alert closed'),
          ),
        ),

        Group(
          'Gradient',
          Alert(
            message: const Text('Festive announcement 🎉'),
            description: const Text('A gradient replaces the tinted fill.'),
            showIcon: true,
            gradient: LinearGradient(
              colors: [t.primary.bg, t.success.bg],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),

        // Per-instance token overrides; pass the same AlertToken to
        // ConfigProvider(components: ...) to restyle every alert at once.
        const Group(
          'Token override',
          Alert(
            type: StatusType.success,
            message: Text('Roomier and rounder'),
            description: Text(
              'padding, borderRadius and icon size overridden.',
            ),
            showIcon: true,
            token: AlertToken(
              withDescriptionPadding: EdgeInsets.all(20),
              borderRadius: 20,
              withDescriptionIconSize: 32,
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
