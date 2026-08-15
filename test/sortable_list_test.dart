import 'package:flutter/material.dart' hide ThemeData;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

// SortableList (via SliverReorderableList) needs Overlay + Localizations, which
// MaterialApp provides.
Widget _app(Widget child) => MaterialApp(
      home: Scaffold(body: ConfigProvider(child: child)),
    );

class _Harness extends StatefulWidget {
  const _Harness({required this.direction});
  final Axis direction;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final items = ['001', '002', '003'];

  @override
  Widget build(BuildContext context) {
    final list = SortableList(
      direction: widget.direction,
      onReorder: (from, to) =>
          setState(() => items.insert(to, items.removeAt(from))),
      children: [
        for (final i in items)
          KeyedSubtree(
            key: ValueKey(i),
            child: SizedBox(width: 80, height: 40, child: Text(i)),
          ),
      ],
    );
    return widget.direction == Axis.horizontal
        ? SizedBox(height: 60, child: list)
        : SizedBox(width: 200, child: list);
  }
}

void main() {
  testWidgets('renders every item with a grip handle', (tester) async {
    await tester.pumpWidget(_app(const _Harness(direction: Axis.vertical)));
    expect(find.text('001'), findsOneWidget);
    expect(find.text('002'), findsOneWidget);
    expect(find.text('003'), findsOneWidget);
    // One grip (HolderPainter) per item.
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is HolderPainter,
      ),
      findsNWidgets(3),
    );
  });

  testWidgets('dragging the handle reorders vertically', (tester) async {
    await tester.pumpWidget(_app(const _Harness(direction: Axis.vertical)));
    // Order is 001, 002, 003 top to bottom.
    expect(
      tester.getCenter(find.text('001')).dy,
      lessThan(tester.getCenter(find.text('003')).dy),
    );

    // Drag the last item's handle up past the first, in small steps so the
    // reorder logic registers each shift.
    final handles = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is HolderPainter,
    );
    final gesture = await tester.startGesture(tester.getCenter(handles.at(2)));
    await tester.pump(const Duration(milliseconds: 30));
    for (var i = 0; i < 16; i++) {
      await gesture.moveBy(const Offset(0, -8));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    // 003 is now above 001.
    expect(
      tester.getCenter(find.text('003')).dy,
      lessThan(tester.getCenter(find.text('001')).dy),
    );
  });

  testWidgets('horizontal direction renders every item', (tester) async {
    await tester.pumpWidget(_app(const _Harness(direction: Axis.horizontal)));
    expect(find.text('001'), findsOneWidget);
    expect(find.text('002'), findsOneWidget);
    expect(find.text('003'), findsOneWidget);
    // The items occupy distinct horizontal positions.
    expect(
      tester.getCenter(find.text('001')).dx,
      isNot(tester.getCenter(find.text('003')).dx),
    );
  });
}
