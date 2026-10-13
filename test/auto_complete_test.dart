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
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => ConfigProvider(
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 280, child: child),
          ),
        ),
      ),
    );

const _cities = [
  AutoCompleteOption(value: 'Amsterdam'),
  AutoCompleteOption(value: 'Ankara'),
  AutoCompleteOption(value: 'Athens', disabled: true),
  AutoCompleteOption(value: 'Berlin'),
];

String _text(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

/// The suggestions on screen, top to bottom.
List<String> _offered(WidgetTester tester) => [
      for (final city in ['Amsterdam', 'Ankara', 'Athens', 'Berlin'])
        if (find
            .descendant(
              of: find.byType(DropdownPanel),
              matching: find.textContaining(city, findRichText: true),
            )
            .evaluate()
            .isNotEmpty)
          city,
    ];

Future<void> _typeIn(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('focused, it offers everything; typed in, what holds the text',
      (tester) async {
    await tester.pumpWidget(_host(const AutoComplete(options: _cities)));
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(_offered(tester), ['Amsterdam', 'Ankara', 'Athens', 'Berlin']);

    await _typeIn(tester, 'AN');
    expect(_offered(tester), ['Ankara'], reason: 'whatever the case');
  });

  testWidgets('the part that matches is drawn in bold', (tester) async {
    await tester.pumpWidget(_host(const AutoComplete(options: _cities)));
    await _typeIn(tester, 'erl');
    final rich = tester.widget<RichText>(
      find.descendant(
        of: find.byType(DropdownPanel),
        matching: find.byType(RichText),
      ),
    );
    final spans = (rich.text as TextSpan).children!.first as TextSpan;
    final parts = spans.children!.cast<TextSpan>();
    expect(parts.map((p) => p.text), ['B', 'erl', 'in']);
    expect(parts[1].style!.fontWeight, FontWeight.w600);
  });

  testWidgets('a tap fills the field, reports it and puts the list away', (
    tester,
  ) async {
    final selected = <String>[];
    final changed = <String>[];
    final searched = <String>[];
    await tester.pumpWidget(
      _host(
        AutoComplete(
          options: _cities,
          onSelect: selected.add,
          onChanged: changed.add,
          onSearch: searched.add,
        ),
      ),
    );
    await _typeIn(tester, 'ber');
    await tester.tap(find.textContaining('Berlin', findRichText: true));
    await tester.pumpAndSettle();
    expect(_text(tester), 'Berlin');
    expect(selected, ['Berlin']);
    expect(changed, ['ber', 'Berlin']);
    expect(searched, ['ber'], reason: 'only what was typed is searched');
    expect(find.byType(DropdownPanel), findsNothing);
  });

  testWidgets('the keys walk past what cannot be chosen, Enter takes it', (
    tester,
  ) async {
    final selected = <String>[];
    await tester.pumpWidget(
      _host(AutoComplete(options: _cities, onSelect: selected.add)),
    );
    await _typeIn(tester, 'a'); // Amsterdam, Ankara, Athens
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // Ankara
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // past Athens
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, ['Amsterdam'], reason: 'wrapped round to the first');
  });

  testWidgets('the first is reached at once, unless told otherwise', (
    tester,
  ) async {
    final selected = <String>[];
    await tester.pumpWidget(
      _host(AutoComplete(options: _cities, onSelect: selected.add)),
    );
    await _typeIn(tester, 'ber');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, ['Berlin']);

    selected.clear();
    await tester.pumpWidget(
      _host(
        AutoComplete(
          key: const ValueKey('none'),
          options: _cities,
          defaultActiveFirstOption: false,
          onSelect: selected.add,
        ),
      ),
    );
    await _typeIn(tester, 'ber');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
  });

  testWidgets('Escape puts them away; backfill gives the typing back', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const AutoComplete(options: _cities, backfill: true)),
    );
    await _typeIn(tester, 'a'); // Amsterdam reached at once, then Ankara
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_text(tester), 'Ankara',
        reason: 'the keys write what they reach into the field');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(DropdownPanel), findsNothing);
    expect(_text(tester), 'a');
  });

  testWidgets('nothing matching: notFoundContent, or nothing at all', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const AutoComplete(options: _cities)));
    await _typeIn(tester, 'zz');
    expect(find.byType(DropdownPanel), findsNothing);

    await tester.pumpWidget(
      _host(
        const AutoComplete(
          key: ValueKey('empty'),
          options: _cities,
          notFoundContent: Text('No such city'),
        ),
      ),
    );
    await _typeIn(tester, 'zz');
    expect(find.text('No such city'), findsOneWidget);
  });

  testWidgets('suggestions fetched while open are shown as they come', (
    tester,
  ) async {
    var options = <AutoCompleteOption>[];
    late StateSetter set;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setter) {
            set = setter;
            return AutoComplete(
              options: options,
              filterOption: (_, __) => true,
              notFoundContent: const Text('Searching'),
            );
          },
        ),
      ),
    );
    await _typeIn(tester, 'mail');
    expect(find.text('Searching'), findsOneWidget);
    set(() => options = const [AutoCompleteOption(value: 'mail@seed.dev')]);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('mail@seed.dev', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('a tap away puts them away; a tap in the field does not', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const AutoComplete(options: _cities)));
    await _typeIn(tester, 'a');
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownPanel), findsOneWidget);
    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownPanel), findsNothing);
  });

  testWidgets('disabled, nothing opens', (tester) async {
    await tester.pumpWidget(
      _host(const AutoComplete(options: _cities, disabled: true)),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownPanel), findsNothing);
  });

  testWidgets('value holds the text from outside', (tester) async {
    Widget field(String v) => _host(AutoComplete(options: _cities, value: v));
    await tester.pumpWidget(field('Ank'));
    expect(_text(tester), 'Ank');
    await tester.pumpWidget(field('Berlin'));
    expect(_text(tester), 'Berlin');
  });
}
