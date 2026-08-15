import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
import 'package:seed_ui_example/theme/new_year_theme.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('the New Year theme renders every component (dark: $dark)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ConfigProvider(
          theme: newYearTheme(dark: dark),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Button(onPressed: () {}, child: const Text('Open gifts')),
                    const Tag(child: Text('tag')),
                    const Alert(message: Text('alert'), showIcon: true),
                    const Card(title: Text('card'), child: Text('body')),
                    const Progress(percent: 0.6),
                    const Input(placeholder: 'wish'),
                    Checkbox(checked: true, onChanged: (_) {}),
                    Switch(value: true, onChanged: (_) {}),
                    Segmented<int>(
                      value: 1,
                      options: const [
                        SegmentedOption(value: 1, label: 'a'),
                        SegmentedOption(value: 2, label: 'b'),
                      ],
                      onChanged: (_) {},
                    ),
                    const Timeline(items: [TimelineItem(title: Text('node'))]),
                    SizedBox(
                      height: 120,
                      child: Listy(
                        items: const ['a', 'b'],
                        rowKey: (r) => r,
                        itemRender: (r, i) => Text(r),
                      ),
                    ),
                    Pagination(total: 50, onChange: (_, __) {}),
                    const Empty(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Open gifts'), findsOneWidget);
    });
  }

  testWidgets('the body face reaches the text the kit renders', (tester) async {
    await tester.pumpWidget(
      ConfigProvider(
        theme: newYearTheme(),
        child: const MaterialApp(
          home: Scaffold(body: Alert(message: Text('Ho ho ho'))),
        ),
      ),
    );

    // The kit hands its own DefaultTextStyle to message/description, so the
    // theme's font has to arrive through that rather than the widget.
    final style = tester
        .widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text('Ho ho ho'),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        )
        .style;
    expect(style.fontFamily, NewYearTypography.bundled.body);
  });

  test('the display faces keep the body face as a fallback', () {
    const type = NewYearTypography.bundled;
    for (final style in [
      type.scriptStyle(color: const Color(0xFF000000)),
      type.ornamentStyle(color: const Color(0xFF000000)),
    ]) {
      expect(style.fontFamilyFallback, contains(type.body));
    }
  });

  testWidgets('a swapped-in face reaches the theme', (tester) async {
    // Dropping a licensed font into assets and naming it here is the whole
    // customisation path — the theme itself needs no editing.
    await tester.pumpWidget(
      ConfigProvider(
        theme: newYearTheme(
          type: const NewYearTypography(body: 'JollySweater'),
        ),
        child: const MaterialApp(
          home: Scaffold(body: Alert(message: Text('Ho ho ho'))),
        ),
      ),
    );

    final style = tester
        .widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text('Ho ho ho'),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        )
        .style;
    expect(style.fontFamily, 'JollySweater');
  });

  test('every component token in the config is festive-aware', () {
    // A quick guard that the theme really covers the kit rather than a corner
    // of it: if a component gains a token, this count tells us to look.
    const config = ComponentsConfig();
    expect(config.of<ListyToken>(), isNull);
    expect(newYearTheme().components.of<ListyToken>(), isNotNull);
    expect(newYearTheme().components.of<SpinToken>(), isNotNull);
    expect(newYearTheme(dark: true).components.of<TooltipToken>(), isNotNull);
  });
}
