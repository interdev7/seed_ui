import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

class ResultDemo extends StatelessWidget {
  const ResultDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final e in const [
          (
            StatusType.success,
            'Payment received',
            'Order 2017182818828182881 is being processed.',
          ),
          (
            StatusType.info,
            'Your account is under review',
            'We will email you once it is approved.',
          ),
          (
            StatusType.warning,
            'Storage almost full',
            'Free up space to keep syncing.',
          ),
          (
            StatusType.error,
            'Submission failed',
            'Please check the form and try again.',
          ),
        ])
          Result(
            status: e.$1,
            title: Text(e.$2),
            subTitle: Text(e.$3),
            extra: [
              Button(
                variant: ButtonVariant.solid,
                color: ButtonColor.primary,
                onPressed: () {},
                child: const Text('Primary'),
              ),
              Button(onPressed: () {}, child: const Text('Secondary')),
            ],
          ),
      ],
    );
  }
}
