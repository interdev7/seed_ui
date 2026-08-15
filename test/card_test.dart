import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _wrap(Widget child) => ConfigProvider(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: child),
      ),
    );

void main() {
  testWidgets('renders title, extra and body', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Card(
          title: Text('Title'),
          extra: Text('Extra'),
          child: Text('Body'),
        ),
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Extra'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('loading hides the body content', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Card(
          loading: true,
          child: Text('Body'),
        ),
      ),
    );

    expect(find.text('Body'), findsNothing);
  });

  testWidgets('actions render each entry', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Card(
          actions: [Text('One'), Text('Two'), Text('Three')],
          child: Text('Body'),
        ),
      ),
    );

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
  });

  testWidgets('tabList switches content via onTabChange', (tester) async {
    String active = 'a';
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => Card(
            activeTabKey: active,
            onTabChange: (k) => setState(() => active = k),
            tabList: const [
              CardTab(key: 'a', label: Text('A')),
              CardTab(key: 'b', label: Text('B')),
            ],
            child: Text('Content $active'),
          ),
        ),
      ),
    );

    expect(find.text('Content a'), findsOneWidget);
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(find.text('Content b'), findsOneWidget);
  });

  testWidgets('CardMeta shows avatar, title and description', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 300,
          child: Card(
            child: CardMeta(
              avatar: SizedBox(width: 32, height: 32),
              title: Text('Meta title'),
              description: Text('Meta description'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Meta title'), findsOneWidget);
    expect(find.text('Meta description'), findsOneWidget);
  });
}
