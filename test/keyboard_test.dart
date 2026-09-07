import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => ConfigProvider(
      theme: ThemeData(),
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

/// Whether the control under [finder] wears the focus halo.
bool _haloed(WidgetTester tester, Finder finder) {
  for (final w in tester.widgetList(finder)) {
    final decoration = switch (w) {
      Container(:final decoration) => decoration,
      AnimatedContainer(:final decoration) => decoration,
      DecoratedBox(:final decoration) => decoration,
      _ => null,
    };
    if (decoration is BoxDecoration) {
      final shadows = decoration.boxShadow;
      if (shadows != null && shadows.any((s) => s.spreadRadius == 3)) {
        return true;
      }
    }
  }
  return false;
}

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();
}

void main() {
  group('a button', () {
    testWidgets('is reached by tab and pressed by space and enter',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(Button(onPressed: () => taps++, child: const Text('Go'))),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(taps, 1, reason: 'space');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 2, reason: 'enter');
    });

    testWidgets('shows a halo once the keyboard put the focus there',
        (tester) async {
      await tester.pumpWidget(
        _host(Button(onPressed: () {}, child: const Text('Go'))),
      );
      final box = find.ancestor(
        of: find.text('Go'),
        matching: find.byType(AnimatedContainer),
      );
      expect(_haloed(tester, box), isFalse);
      await _tab(tester);
      expect(_haloed(tester, box), isTrue);
    });

    testWidgets('one that does nothing is not a stop on the way round',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              const Button(child: Text('Dead')),
              Button(onPressed: () => taps++, child: const Text('Live')),
            ],
          ),
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      // The first tab landed on the live one, having skipped the dead.
      expect(taps, 1);
    });

    testWidgets('a disabled one cannot be pressed from the keyboard',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Button(
            disabled: true,
            onPressed: () => taps++,
            child: const Text('Go'),
          ),
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(taps, 0);
    });

    testWidgets('takes the focus at once when told to', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Button(
            autofocus: true,
            onPressed: () => taps++,
            child: const Text('Go'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  group('a checkbox', () {
    testWidgets('is ticked from the keyboard', (tester) async {
      var checked = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => Checkbox(
              checked: checked,
              onChanged: (v) => setState(() => checked = v),
              label: const Text('Tick'),
            ),
          ),
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(checked, isTrue);
    });

    testWidgets('the halo sits on the box, not on the words', (tester) async {
      await tester.pumpWidget(
        _host(
          Checkbox(checked: false, onChanged: (_) {}, label: const Text('T')),
        ),
      );
      await _tab(tester);
      expect(_haloed(tester, find.byType(AnimatedContainer)), isTrue);
    });
  });

  group('a radio button', () {
    testWidgets('is chosen from the keyboard', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _host(
          Radio<String>(
            value: 'a',
            groupValue: picked,
            onChanged: (v) => picked = v,
            child: const Text('A'),
          ),
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(picked, 'a');
    });
  });

  group('a switch', () {
    testWidgets('is flipped from the keyboard', (tester) async {
      var on = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => Switch(
              value: on,
              onChanged: (v) => setState(() => on = v),
            ),
          ),
        ),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(on, isTrue);
    });

    testWidgets('wears the halo on its track', (tester) async {
      await tester.pumpWidget(_host(Switch(value: false, onChanged: (_) {})));
      await _tab(tester);
      expect(_haloed(tester, find.byType(AnimatedContainer)), isTrue);
    });
  });

  testWidgets('the tab order runs down the page', (tester) async {
    final pressed = <String>[];
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            for (final label in ['one', 'two', 'three'])
              Button(
                onPressed: () => pressed.add(label),
                child: Text(label),
              ),
          ],
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
    }
    expect(pressed, ['one', 'two', 'three']);
  });
}
