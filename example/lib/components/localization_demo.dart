import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../main.dart' show LocaleController, demoLanguages;
import 'group.dart';

class LocalizationDemo extends StatelessWidget {
  const LocalizationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = LocaleController.of(context).locale;
    // The same lookup the components make. Everything on this page follows the
    // picker in the header.
    final words = context.seedLocale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'The language in scope',
          Text(
            'Switch it with the picker in the header. '
            '${demoLanguages[locale.languageCode] ?? locale.languageCode} '
            '(${locale.languageCode})',
          ),
        ),
        Group(
          'Every word the kit says on its own account',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final row in [
                ('ok', words.ok, 'Modal, Popconfirm'),
                ('cancel', words.cancel, 'Modal, Popconfirm'),
                ('previous', words.previous, 'Tour'),
                ('next', words.next, 'Tour'),
                ('finish', words.finish, 'Tour, on the last step'),
                ('noData', words.noData, 'Empty'),
                ('noMoreItems', words.noMoreItems, 'Listy'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          row.$1,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          row.$2,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          row.$3,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.softToken.colorTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Group(
          'In place: a popconfirm',
          Align(
            alignment: Alignment.centerLeft,
            child: Popconfirm(
              title: const Text('Delete this item?'),
              onOk: () {},
              child: Button(onPressed: () {}, child: const Text('Delete')),
            ),
          ),
        ),
        Group(
          'In place: a modal',
          Align(
            alignment: Alignment.centerLeft,
            child: Button(
              onPressed: () => Modal.confirm(
                title: 'Delete this item?',
                content: 'The buttons below take their words from the locale.',
              ),
              child: const Text('Open a confirm'),
            ),
          ),
        ),
        const Group('In place: an empty list', Empty()),
        Group(
          'A word replaced, for one subtree only',
          // Empty rather than a popconfirm: a provider placed here reaches
          // what is drawn here, but a popconfirm draws into the navigator's
          // overlay, above this page. Overriding for an overlay means putting
          // the provider above MaterialApp.
          ConfigProvider(
            locale: words.copyWith(noData: '${words.noData} — nothing at all'),
            child: const Empty(),
          ),
        ),
      ],
    );
  }
}
