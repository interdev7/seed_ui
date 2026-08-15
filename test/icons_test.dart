import 'package:flutter/material.dart' hide ThemeData;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
// Several icons are internal to the kit — they back a component's chrome
// rather than being part of the public surface — so they are reached through
// the implementation library rather than the barrel.
import 'package:seed_ui/src/icons/icons.dart'
    show ClearIconPainter, TreeLeafIconPainter;

Widget _host(Widget child) => ConfigProvider(
      theme: ThemeData(),
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('renders Spinner', (tester) async {
    await tester.pumpWidget(
      _host(
        const Spinner(color: Colors.blue, size: 24),
      ),
    );
    expect(find.byType(Spinner), findsOneWidget);
  });

  testWidgets('renders ClearIconPainter', (tester) async {
    await tester.pumpWidget(
      _host(
        CustomPaint(painter: ClearIconPainter(Colors.blue)),
      ),
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is ClearIconPainter,
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders SearchIcon', (tester) async {
    await tester.pumpWidget(
      _host(
        const SearchIcon(color: Colors.blue),
      ),
    );
    expect(find.byType(SearchIcon), findsOneWidget);
  });

  testWidgets('renders TreeLeafIconPainter', (tester) async {
    await tester.pumpWidget(
      _host(
        CustomPaint(painter: TreeLeafIconPainter(Colors.blue)),
      ),
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is TreeLeafIconPainter,
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders UserIcon', (tester) async {
    await tester.pumpWidget(
      _host(
        const UserIcon(color: Colors.blue),
      ),
    );
    expect(find.byType(UserIcon), findsOneWidget);
  });
}
