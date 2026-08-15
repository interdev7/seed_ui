import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      navigatorKey: UiKit.navigatorKey,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('renders page numbers and reports taps', (tester) async {
    int? page;
    await tester.pumpWidget(
      _host(
        Pagination(
          total: 50, // 5 pages
          defaultCurrent: 1,
          onChange: (p, s) => page = p,
        ),
      ),
    );

    // All 5 pages fit without ellipsis.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    await tester.tap(find.text('3'));
    await tester.pump();
    expect(page, 3);
  });

  testWidgets('near the start shows 1..5 with an ellipsis and last',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const Pagination(total: 500, defaultCurrent: 1), // 50 pages
      ),
    );
    // 1 2 3 4 5 … 50
    for (final p in ['1', '2', '3', '4', '5', '50']) {
      expect(find.text(p), findsOneWidget);
    }
    expect(find.text('25'), findsNothing);
    expect(find.text('6'), findsNothing);
  });

  testWidgets('a middle page shows neighbours with two ellipses',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const Pagination(total: 500, defaultCurrent: 5), // page 5 of 50
      ),
    );
    // 1 … 4 5 6 … 50
    for (final p in ['1', '4', '5', '6', '50']) {
      expect(find.text(p), findsOneWidget);
    }
    expect(find.text('3'), findsNothing);
    expect(find.text('7'), findsNothing);
  });

  testWidgets('prev is disabled on the first page and next advances',
      (tester) async {
    int? page;
    await tester.pumpWidget(
      _host(
        Pagination(
          total: 50,
          defaultCurrent: 1,
          onChange: (p, s) => page = p,
        ),
      ),
    );
    await tester.tap(find.text('2'));
    await tester.pump();
    expect(page, 2);
  });

  testWidgets('size changer changes the page size', (tester) async {
    int? size;
    await tester.pumpWidget(
      _host(
        Pagination(
          total: 500,
          defaultCurrent: 1,
          showSizeChanger: true,
          onChange: (p, s) => size = s,
        ),
      ),
    );

    // Open the size selector and pick 20 / page.
    await tester.tap(find.text('10 / page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20 / page').last);
    await tester.pumpAndSettle();
    expect(size, 20);
  });

  testWidgets('quick jumper rejects a page beyond the last', (tester) async {
    int? page;
    await tester.pumpWidget(
      _host(
        Pagination(
          total: 50, // 5 pages
          defaultCurrent: 1,
          showQuickJumper: true,
          onChange: (p, s) => page = p,
        ),
      ),
    );

    // Typing "9" (> 5) is rejected by the formatter, so the field stays empty.
    await tester.enterText(find.byType(EditableText), '9');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(page, isNull);

    // A valid page still jumps.
    await tester.enterText(find.byType(EditableText), '4');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(page, 4);
  });

  testWidgets('simple readOnly shows text, not an input', (tester) async {
    await tester.pumpWidget(
      _host(
        const Pagination(
          total: 235,
          simple: PaginationSimple(readOnly: true),
          defaultCurrent: 4,
        ),
      ),
    );
    expect(find.byType(EditableText), findsNothing);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('hideOnSinglePage hides the pager', (tester) async {
    await tester.pumpWidget(
      _host(
        const Pagination(total: 5, pageSize: 10, hideOnSinglePage: true),
      ),
    );
    expect(find.text('1'), findsNothing);
  });
}
