import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child, {EmptyBuilder? emptyBuilder}) => ConfigProvider(
      emptyBuilder: emptyBuilder,
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  testWidgets('Empty shows the default description', (tester) async {
    await tester.pumpWidget(_host(const Empty()));
    expect(find.text('No data'), findsOneWidget);
  });

  testWidgets('a Select with no options falls back to Empty', (tester) async {
    await tester.pumpWidget(
      _host(
        const Select<String>(placeholder: 'Pick', options: []),
      ),
    );
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(find.text('No data'), findsOneWidget);
  });

  testWidgets('ConfigProvider.emptyBuilder overrides the default',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const Select<String>(placeholder: 'Pick', options: []),
        emptyBuilder: (context, slot) => const Text('Nothing custom'),
      ),
    );
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing custom'), findsOneWidget);
    expect(find.text('No data'), findsNothing);
  });

  testWidgets('notFoundContent wins over emptyBuilder', (tester) async {
    await tester.pumpWidget(
      _host(
        const Select<String>(
          placeholder: 'Pick',
          options: [],
          notFoundContent: Text('Per-field empty'),
        ),
        emptyBuilder: (context, slot) => const Text('Global empty'),
      ),
    );
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(find.text('Per-field empty'), findsOneWidget);
    expect(find.text('Global empty'), findsNothing);
  });
  testWidgets('a Listy with no rows shows the placeholder', (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          height: 200,
          child: Listy<String, String, String>(
            items: const [],
            itemRender: (item, index) => Text(item),
          ),
        ),
      ),
    );
    expect(find.text('No data'), findsOneWidget);
  });

  testWidgets('emptyContent wins over emptyBuilder for a Listy',
      (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          height: 200,
          child: Listy<String, String, String>(
            items: const [],
            emptyContent: const Text('Nothing here yet'),
            itemRender: (item, index) => Text(item),
          ),
        ),
        emptyBuilder: (context, slot) => const Text('Global empty'),
      ),
    );
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Global empty'), findsNothing);
  });

  testWidgets('emptyBuilder is told which component is asking', (tester) async {
    final asked = <EmptySlot>[];
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            SizedBox(
              height: 150,
              child: Listy<String, String, String>(
                items: const [],
                itemRender: (item, index) => Text(item),
              ),
            ),
            const Select<String>(placeholder: 'Pick', options: []),
          ],
        ),
        emptyBuilder: (context, slot) {
          asked.add(slot);
          return Text('empty:${slot.name}');
        },
      ),
    );
    expect(find.text('empty:listy'), findsOneWidget);

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(find.text('empty:select'), findsOneWidget);

    expect(asked, contains(EmptySlot.listy));
    expect(
      asked,
      contains(EmptySlot.select),
      reason: 'one builder has to be able to tell the two apart',
    );
  });

  testWidgets('a list still fetching its first page is not empty yet',
      (tester) async {
    Widget listy({required bool loading, required bool hasMore}) => _host(
          SizedBox(
            height: 200,
            child: Listy<String, String, String>(
              items: const [],
              itemRender: (item, index) => Text(item),
              loadMore: ListyLoadMore(
                onLoad: () {},
                loading: loading,
                hasMore: hasMore,
              ),
            ),
          ),
        );

    await tester.pumpWidget(listy(loading: true, hasMore: true));
    expect(find.text('No data'), findsNothing, reason: 'a page is in flight');

    await tester.pumpWidget(listy(loading: false, hasMore: true));
    await tester.pump();
    expect(find.text('No data'), findsNothing, reason: 'more is still coming');

    await tester.pumpWidget(listy(loading: false, hasMore: false));
    await tester.pump();
    expect(find.text('No data'), findsOneWidget);
  });

  testWidgets('an empty list does not say it twice', (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          height: 200,
          child: Listy<String, String, String>(
            items: const [],
            itemRender: (item, index) => Text(item),
            loadMore: ListyLoadMore(
              onLoad: () {},
              hasMore: false,
            ),
          ),
        ),
      ),
    );
    expect(find.text('No data'), findsOneWidget);

    // The placeholder fills the viewport, so an end marker underneath it would
    // sit just below the fold and never be built — looking for it where it
    // stands is the only way to tell it is gone.
    await tester.drag(
      find.byType(Listy<String, String, String>),
      const Offset(0, -300),
    );
    await tester.pump();
    expect(
      find.text('No more items'),
      findsNothing,
      reason: 'the end marker under a "no data" placeholder reads as a stutter',
    );
  });

  testWidgets('the header survives an empty result', (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          height: 200,
          child: Listy<String, String, String>(
            items: const [],
            itemRender: (item, index) => Text(item),
            header: ListyHeader(
              pinned: true,
              extent: 44,
              onRefresh: () async {},
              builder: (context, pull) => const Text('toolbar'),
            ),
          ),
        ),
      ),
    );
    // Pulling to refresh is most needed exactly when nothing came back.
    expect(find.text('toolbar'), findsOneWidget);
    expect(find.text('No data'), findsOneWidget);
  });
}
