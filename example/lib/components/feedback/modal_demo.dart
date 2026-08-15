import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

class ModalDemo extends StatelessWidget {
  const ModalDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Button(
          onPressed: () async {
            final ok = await Modal.confirm(
              title: 'Delete file?',
              content: 'This action cannot be undone.',
              okText: 'Delete',
              danger: true,
            );
            if (ok) message.success('Deleted');
          },
          child: const Text('confirm'),
        ),
        Button(
          onPressed: () => Modal.info(
            title: 'Heads up',
            content: 'Nothing here needs your decision.',
          ),
          child: const Text('info'),
        ),
        Button(
          onPressed: () => Modal.success(
            title: 'All done',
            content: 'Your changes have been published.',
          ),
          child: const Text('success'),
        ),
        Button(
          onPressed: () => Modal.error(
            title: 'Upload failed',
            content: 'The server rejected the file.',
          ),
          child: const Text('error'),
        ),
        Button(
          onPressed: () => Modal.confirm(
            title: 'Saving…',
            content: 'The dialog stays open until the work finishes.',
            onOk: () async {
              await Future<void>.delayed(const Duration(seconds: 2));
              message.success('Saved');
              return true;
            },
          ),
          child: const Text('async onOk'),
        ),
        Button(
          onPressed: () => Modal.confirm(
            title: 'Centered',
            content: 'centered: true',
            centered: true,
          ),
          child: const Text('centered'),
        ),
        Button(
          onPressed: () =>
              Modal.confirm(title: 'Pinned', content: 'top: 100', top: 100),
          child: const Text('top: 100'),
        ),
        Button(
          onPressed: () => Modal.confirm(
            title: 'Deliberate choice',
            content: 'The mask and Escape are disabled here.',
            maskClosable: false,
          ),
          child: const Text('not mask-closable'),
        ),
        Button(
          onPressed: () => Modal.confirm(
            title: 'Custom Barrier Color',
            content: 'This modal uses a custom dark green barrierColor.',
            barrierColor: const Color(0x991C3E20),
          ),
          child: const Text('barrierColor'),
        ),
      ],
    );
  }
}
