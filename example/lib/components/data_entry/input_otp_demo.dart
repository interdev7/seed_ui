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

class InputOtpDemo extends StatelessWidget {
  const InputOtpDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Basic — six digits',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InputOtp(
              semanticsLabel: 'Verification code',
              onCompleted: (code) => message.success('Code $code'),
            ),
          ),
        ),
        const Group(
          'Letters and digits, with a separator',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InputOtp(
              length: 8,
              semanticsLabel: 'Licence key',
              characters: InputOtpCharacters.alphanumeric,
              separator: _dash,
            ),
          ),
        ),
        const Group(
          'Masked',
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InputOtp(
              length: 4,
              mask: '•',
              semanticsLabel: 'PIN',
              defaultValue: '12',
            ),
          ),
        ),
        const Group(
          'Sizes',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputOtp(
                length: 4,
                size: SoftSize.small,
                semanticsLabel: 'Small code',
              ),
              SizedBox(height: 12),
              InputOtp(length: 4, semanticsLabel: 'Middle code'),
              SizedBox(height: 12),
              InputOtp(
                length: 4,
                size: SoftSize.large,
                semanticsLabel: 'Large code',
              ),
            ],
          ),
        ),
        const Group(
          'Status and disabled',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputOtp(
                length: 4,
                status: InputStatus.error,
                defaultValue: '1234',
                semanticsLabel: 'Wrong code',
              ),
              SizedBox(height: 12),
              InputOtp(
                length: 4,
                status: InputStatus.warning,
                semanticsLabel: 'Questionable code',
              ),
              SizedBox(height: 12),
              InputOtp(
                length: 4,
                disabled: true,
                defaultValue: '12',
                semanticsLabel: 'Disabled code',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget? _dash(int index) => index == 3 ? const Text('–') : null;
