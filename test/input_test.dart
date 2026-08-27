import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('shows the placeholder while empty, hides it once typed',
      (tester) async {
    await tester.pumpWidget(_host(const Input(placeholder: 'Username')));

    expect(find.text('Username'), findsOneWidget);

    await tester.enterText(find.byType(Input), 'ann');
    await tester.pump();
    expect(find.text('Username'), findsNothing);
  });

  testWidgets('reports edits through onChanged', (tester) async {
    String? seen;
    await tester.pumpWidget(_host(Input(onChanged: (v) => seen = v)));

    await tester.enterText(find.byType(Input), 'hello');
    expect(seen, 'hello');
  });

  testWidgets('a controller reads and drives the value', (tester) async {
    final controller = TextEditingController(text: 'start');
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(Input(controller: controller)));

    expect(find.text('start'), findsOneWidget);

    await tester.enterText(find.byType(Input), 'edited');
    expect(controller.text, 'edited');
  });

  testWidgets('disabled blocks editing', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester
        .pumpWidget(_host(Input(controller: controller, disabled: true)));

    await tester.enterText(find.byType(Input), 'nope');
    expect(controller.text, isEmpty);
  });

  testWidgets('allowClear empties the field when tapped', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester
        .pumpWidget(_host(Input(controller: controller, allowClear: true)));

    // The clear button only shows while focused and non-empty.
    await tester.tap(find.byType(Input));
    await tester.enterText(find.byType(Input), 'clear me');
    await tester.pump();

    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == 'ClearIconPainter',
      ),
    );
    await tester.pump();
    expect(controller.text, isEmpty);
  });

  testWidgets('obscureText masks the value and toggles with the reveal button',
      (tester) async {
    await tester.pumpWidget(_host(const Input(password: PasswordConfig())));
    await tester.enterText(find.byType(Input), 'secret');
    await tester.pump();

    bool masked() =>
        tester.widget<EditableText>(find.byType(EditableText)).obscureText;
    expect(masked(), isTrue);

    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_EyePainter',
      ),
    );
    await tester.pump();
    expect(masked(), isFalse);
  });

  testWidgets('maxLength caps the input', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(Input(controller: controller, maxLength: 3)));

    await tester.enterText(find.byType(Input), 'abcdef');
    expect(controller.text, 'abc');
  });

  group('size takes a preset or a measurement', () {
    Future<Rect> boxAt(WidgetTester tester, ControlSize size) async {
      await tester.pumpWidget(
        ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 260,
                  child: Input(size: size, placeholder: 'Ag'),
                ),
              ),
            ),
          ),
        ),
      );
      // The height rides an AnimatedContainer, so settle before measuring.
      await tester.pumpAndSettle();
      return tester.getRect(find.byType(Input));
    }

    testWidgets('a preset still walks the theme scale', (tester) async {
      expect((await boxAt(tester, SoftSize.small)).height, 24);
      expect((await boxAt(tester, SoftSize.middle)).height, 32);
      expect((await boxAt(tester, SoftSize.large)).height, 40);
    });

    testWidgets('a measurement is taken as given', (tester) async {
      expect((await boxAt(tester, const ControlSize.height(36))).height, 36);
      // Past both ends of the preset scale, too.
      expect((await boxAt(tester, const ControlSize.height(56))).height, 56);
      expect((await boxAt(tester, const ControlSize.height(20))).height, 20);
    });

    testWidgets('a two-dimensional size names the width too', (tester) async {
      // Both ways out of the build have to honour it: a plain field returns
      // before the search-button Row, and an earlier attempt missed that exit
      // entirely, so raw() looked like it did nothing.
      await tester.pumpWidget(
        const ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Wrap(
                  children: [Input(size: ControlSize.box(180, 36))],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final size = tester.getSize(find.byType(Input));
      expect(size.width, 180);
      expect(size.height, 36);
    });

    testWidgets('the search field honours it as well', (tester) async {
      // The other exit — the one with the button attached.
      await tester.pumpWidget(
        ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Wrap(
                  children: [
                    Input(
                      size: const ControlSize.box(220, 36),
                      search: SearchConfig(enterButton: true, onSearch: (_) {}),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(Input)).width, 220);
    });

    testWidgets('a bare height says nothing about width', (tester) async {
      // fixed() names one dimension; the field goes on filling what it is
      // offered, as a text field with nothing to measure should.
      await tester.pumpWidget(
        const ConfigProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Input(size: ControlSize.height(20))],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final size = tester.getSize(find.byType(Input));
      expect(size.height, 20);
      expect(size.width, 800);
    });
    testWidgets('the text stays centred at any height', (tester) async {
      // The padding is not what holds the height up — the box is — so an
      // unusual height neither pushes the text off centre nor overflows.
      for (final h in [20.0, 36.0, 56.0]) {
        final box = await boxAt(tester, ControlSize.height(h));
        final text = tester.getRect(find.text('Ag'));
        expect(
          text.top - box.top,
          closeTo(box.bottom - text.bottom, 0.5),
          reason: 'off centre at $h',
        );
        expect(tester.takeException(), isNull, reason: 'overflowed at $h');
      }
    });
  });
}
