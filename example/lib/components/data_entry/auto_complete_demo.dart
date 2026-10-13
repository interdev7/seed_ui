import 'dart:async';

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

const _cities = [
  'Amsterdam',
  'Ankara',
  'Athens',
  'Barcelona',
  'Belgrade',
  'Berlin',
  'Bratislava',
  'Brussels',
  'Bucharest',
  'Budapest',
  'Copenhagen',
  'Dublin',
  'Helsinki',
  'Kyiv',
  'Lisbon',
  'Ljubljana',
  'London',
  'Madrid',
  'Oslo',
  'Paris',
  'Prague',
  'Riga',
  'Rome',
  'Sofia',
  'Stockholm',
  'Tallinn',
  'Vienna',
  'Vilnius',
  'Warsaw',
  'Zagreb',
];

class AutoCompleteDemo extends StatefulWidget {
  const AutoCompleteDemo({super.key});

  @override
  State<AutoCompleteDemo> createState() => _AutoCompleteDemoState();
}

class _AutoCompleteDemoState extends State<AutoCompleteDemo> {
  List<AutoCompleteOption> _mail = const [];
  bool _searching = false;
  Timer? _wait;

  @override
  void dispose() {
    _wait?.cancel();
    super.dispose();
  }

  // As a server would: a moment, then the addresses for what was typed.
  void _suggestMail(String text) {
    _wait?.cancel();
    if (text.isEmpty || text.contains('@')) {
      setState(() {
        _mail = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _wait = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _mail = [
          for (final domain in ['gmail.com', 'outlook.com', 'proton.me'])
            AutoCompleteOption(value: '$text@$domain'),
        ];
      });
    });
  }

  Widget _field(Widget child) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: SizedBox(width: 280, child: child),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Basic — a city',
          _field(
            AutoComplete(
              placeholder: 'City',
              semanticsLabel: 'City',
              allowClear: true,
              options: [for (final c in _cities) AutoCompleteOption(value: c)],
              onSelect: (c) => message.info(c),
            ),
          ),
        ),
        Group(
          'Fetched as you type',
          _field(
            AutoComplete(
              placeholder: 'E-mail',
              semanticsLabel: 'E-mail',
              options: _mail,
              filterOption: (_, __) => true,
              onSearch: _suggestMail,
              notFoundContent: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Searching…'),
                    )
                  : null,
            ),
          ),
        ),
        Group(
          'Labels of your own, and backfill',
          _field(
            const AutoComplete(
              placeholder: 'Capital',
              semanticsLabel: 'Capital',
              backfill: true,
              options: [
                AutoCompleteOption(
                  value: 'Paris',
                  label: _Place('Paris', 'France'),
                ),
                AutoCompleteOption(
                  value: 'Prague',
                  label: _Place('Prague', 'Czechia'),
                ),
                AutoCompleteOption(
                  value: 'Pristina',
                  label: _Place('Pristina', 'Kosovo'),
                  disabled: true,
                ),
              ],
            ),
          ),
        ),
        Group(
          'Status',
          _field(
            const AutoComplete(
              placeholder: 'Required',
              semanticsLabel: 'Required city',
              status: InputStatus.error,
              options: [],
            ),
          ),
        ),
      ],
    );
  }
}

class _Place extends StatelessWidget {
  const _Place(this.city, this.country);

  final String city;
  final String country;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(city)),
      Text(
        country,
        style: TextStyle(color: context.softToken.colorTextTertiary),
      ),
    ],
  );
}
