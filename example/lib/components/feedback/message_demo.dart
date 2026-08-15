import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

class MessageDemo extends StatelessWidget {
  const MessageDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
    );
  }
}
