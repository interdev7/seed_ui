import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      navigatorKey: UiKit.navigatorKey,
      home: Scaffold(body: Center(child: child)),
    );

const _options = [
  SelectOption(value: 'apple', filterText: 'Apple'),
  SelectOption(value: 'banana', filterText: 'Banana'),
  SelectOption(value: 'cherry', filterText: 'Cherry', disabled: true),
];

void main() {
  testWidgets('opens and selects a single value', (tester) async {
    List<String>? seen;
    await tester.pumpWidget(
      _host(
        Select<String>(
          placeholder: 'Pick',
          options: _options,
          onChanged: (v) => seen = v,
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(find.text('Banana'), findsOneWidget);

    await tester.tap(find.text('Banana'));
    await tester.pumpAndSettle();
    expect(seen, ['banana']);
    // The dropdown closed and the box shows the chosen label.
    expect(find.text('Apple'), findsNothing);
    expect(find.text('Banana'), findsOneWidget);
  });

  testWidgets('a disabled option cannot be selected', (tester) async {
    List<String>? seen;
    await tester.pumpWidget(
      _host(
        Select<String>(
          placeholder: 'Pick',
          options: _options,
          onChanged: (v) => seen = v,
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cherry'));
    await tester.pumpAndSettle();
    expect(seen, isNull);
  });

  testWidgets('selects the tapped option, not a neighbour', (tester) async {
    List<String>? seen;
    await tester.pumpWidget(
      _host(
        Select<String>(
          placeholder: 'Pick',
          options: _options,
          onChanged: (v) => seen = v,
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    // Tap the last enabled option; must select exactly it.
    await tester.tap(find.text('Banana'));
    await tester.pumpAndSettle();
    expect(seen, ['banana']);
  });

  testWidgets('search filters the options', (tester) async {
    await tester.pumpWidget(
      _host(
        const Select<String>(
          placeholder: 'Pick',
          showSearch: true,
          options: _options,
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'ban');
    await tester.pumpAndSettle();

    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('Apple'), findsNothing);
  });

  testWidgets('typing filters live and the filtered option is selectable',
      (tester) async {
    List<String>? seen;
    await tester.pumpWidget(
      _host(
        Select<String>(
          placeholder: 'Pick',
          showSearch: true,
          options: const [
            SelectOption(value: 'Red'),
            SelectOption(value: 'Blue'),
            SelectOption(value: 'Green'),
          ],
          onChanged: (v) => seen = v,
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'r');
    await tester.pumpAndSettle();

    // Red matches 'r' and shows in the dropdown; Blue does not.
    expect(find.text('Red'), findsOneWidget);
    expect(find.text('Blue'), findsNothing);

    await tester.tap(find.text('Red'));
    await tester.pumpAndSettle();
    expect(seen, ['Red']);
  });

  testWidgets('search config sorts the options', (tester) async {
    await tester.pumpWidget(
      _host(
        Select<String>(
          placeholder: 'Pick',
          options: const [
            SelectOption(value: 'c', filterText: 'Cherry'),
            SelectOption(value: 'a', filterText: 'Apple'),
            SelectOption(value: 'b', filterText: 'Banana'),
          ],
          search: SelectSearch<String>(
            filterSort: (x, y) => x.filterText!.compareTo(y.filterText!),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    final apple = tester.getTopLeft(find.text('Apple')).dy;
    final banana = tester.getTopLeft(find.text('Banana')).dy;
    final cherry = tester.getTopLeft(find.text('Cherry')).dy;
    expect(apple < banana && banana < cherry, isTrue);
  });

  testWidgets('single select shows no tick in the dropdown', (tester) async {
    Finder ticks() => find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == 'CheckPainter',
        );

    await tester.pumpWidget(
      _host(
        const Select<String>(placeholder: 'Pick', options: _options),
      ),
    );
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    // Pick a value; single-select marks it by highlight, not a tick.
    await tester.tap(find.text('Banana'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Banana')); // reopen
    await tester.pumpAndSettle();
    expect(ticks(), findsNothing);
  });

  testWidgets('multiple toggles values and removes tags', (tester) async {
    List<String> value = const [];
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Select<String>(
            value: value,
            mode: SelectMode.multiple,
            placeholder: 'Pick',
            options: _options,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apple'));
    await tester.pumpAndSettle();
    expect(value, ['apple']);

    // Dropdown stays open for a second pick.
    await tester.tap(find.text('Banana'));
    await tester.pumpAndSettle();
    expect(value, ['apple', 'banana']);
  });

  testWidgets('removing a tag works while the dropdown is open',
      (tester) async {
    List<String> value = const ['apple', 'banana'];
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Select<String>(
            value: value,
            mode: SelectMode.multiple,
            placeholder: 'Pick',
            options: _options,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );

    // Open the dropdown (tap a tag label, which the box handles), then remove
    // a tag via its close cross.
    await tester.tap(find.text('Apple').first);
    await tester.pumpAndSettle();
    final cross = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == 'CrossPainter',
    );
    expect(cross, findsWidgets);
    await tester.tap(cross.first);
    await tester.pump();
    // A tag was removed — the dropdown did not swallow the tap.
    expect(value.length, 1);
  });

  testWidgets('allowClear empties the selection', (tester) async {
    List<String> value = const ['apple'];
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Select<String>(
            value: value,
            allowClear: true,
            placeholder: 'Pick',
            options: _options,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );

    // Hovering the box reveals the clear button.
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('Apple')));
    await tester.pumpAndSettle();

    final clear = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == 'ClearIconPainter',
    );
    expect(clear, findsOneWidget);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(value, isEmpty);
  });

  testWidgets('itemRender customises the selected label', (tester) async {
    await tester.pumpWidget(
      _host(
        Select<String>(
          value: const ['apple'],
          options: _options,
          itemRender: (option) => Text('★ ${option.filterText}'),
        ),
      ),
    );
    expect(find.text('★ Apple'), findsOneWidget);
  });

  testWidgets('optionRender customises the dropdown rows', (tester) async {
    await tester.pumpWidget(
      _host(
        Select<String>(
          placeholder: 'Pick',
          options: _options,
          optionRender: (option, selected) => Text('» ${option.filterText}'),
        ),
      ),
    );
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(find.text('» Banana'), findsOneWidget);
  });

  testWidgets('tags mode filters existing options while typing',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const Select<String>(
          mode: SelectMode.tags,
          placeholder: 'Add',
          options: [
            SelectOption(value: 'red', filterText: 'Red'),
            SelectOption(value: 'green', filterText: 'Green'),
            SelectOption(value: 'blue', filterText: 'Blue'),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'gre');
    await tester.pumpAndSettle();

    // The existing Green option filters in (not just a "create" row).
    expect(find.text('Green'), findsOneWidget);
    expect(find.text('Red'), findsNothing);
  });

  testWidgets('tags mode creates a new value on submit', (tester) async {
    List<String> value = const [];
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Select<String>(
            value: value,
            mode: SelectMode.tags,
            placeholder: 'Add',
            options: const [SelectOption(value: 'red', filterText: 'Red')],
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'custom');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(value, ['custom']);
  });

  group('size takes a preset or a measurement', () {
    Widget host(Widget child) => ConfigProvider(
          child: MaterialApp(
            navigatorKey: UiKit.navigatorKey,
            home: Scaffold(body: Center(child: child)),
          ),
        );

    const options = [SelectOption(value: 1, label: Text('one'))];

    testWidgets('a preset still walks the theme scale', (tester) async {
      Future<double> heightOf(ControlSize size) async {
        await tester.pumpWidget(
          host(
            SizedBox(
              width: 300,
              child: Select<int>(size: size, options: options),
            ),
          ),
        );
        // The height rides an AnimatedContainer, so settle before measuring.
        await tester.pumpAndSettle();
        return tester.getSize(find.byType(Select<int>)).height;
      }

      expect(await heightOf(SoftSize.small),
          lessThan(await heightOf(SoftSize.large)));
    });

    testWidgets('a two-dimensional size names both', (tester) async {
      // A loose parent, so the field is free to take the width it was given.
      await tester.pumpWidget(
        host(
          const Wrap(
            children: [
              Select<int>(size: ControlSize.raw(180, 36), options: options),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final size = tester.getSize(find.byType(Select<int>));
      expect(size.width, 180);
      // The border sits outside the named height.
      expect(size.height, closeTo(36, 2));
    });
  });

  group('width', () {
    const options = [
      SelectOption(value: 1, label: Text('Apple')),
      SelectOption(value: 2, label: Text('A considerably longer fruit name')),
    ];

    Future<double> widthUnder(WidgetTester tester, Widget parent) async {
      await tester.pumpWidget(
        ConfigProvider(
          child: MaterialApp(
            navigatorKey: UiKit.navigatorKey,
            home: Scaffold(body: Center(child: parent)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(Select<int>)).width;
    }

    testWidgets('it fills the width it is given', (tester) async {
      // A select has no format promising what it can hold, and in tags mode
      // the chips decide their own size, so it fills rather than measuring.
      expect(
        await widthUnder(
          tester,
          const SizedBox(width: 300, child: Select<int>(options: options)),
        ),
        300,
      );
      expect(
        await widthUnder(
          tester,
          const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Select<int>(options: options)],
          ),
        ),
        800,
      );
    });

    testWidgets('with no width at all it does not throw', (tester) async {
      // It used to: the value area was Expanded, which needs a width from
      // above. With nothing to fill it falls back to its widest label.
      final width = await widthUnder(
        tester,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Select<int>(options: options)],
        ),
      );
      expect(tester.takeException(), isNull);
      expect(width, greaterThan(0));
      expect(width, lessThan(800), reason: 'its labels, not the page');
    });
  });
}
