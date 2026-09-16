import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart' hide Table;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
import 'package:seed_ui_example/components/data_display/table_demo.dart';
import 'package:seed_ui_example/components/group.dart';

/// Groups whose table is meant to run past the screen, and why.
///
/// Two of them are *about* a table wider than its box; the third is drawn to
/// the width of its own columns so that a width asked for is the width drawn.
/// Everywhere else a table that needs sideways dragging on a phone is a demo
/// that forgot `showFrom`.
const _byDesign = {
  'Wider than its box',
  'As wide as it needs',
  'Borders you can drag',
};

/// How much a table may still hide once its columns are all on their floor.
/// A table cannot squeeze below that, and one column's worth of chevron is
/// enough to put a three-column table a few pixels over.
const _slack = 16.0;

void main() {
  testWidgets('no table in the demo needs dragging on a phone', (tester) async {
    // Tall, so the whole page lays out in one pass and every table is
    // measured — a scroll view builds only what it shows.
    tester.view.physicalSize = const Size(390, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ConfigProvider(
        child: m.MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: const m.Scaffold(
            body: SingleChildScrollView(child: TableDemo()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final past = <String>[];
    for (final element in find.byType(Scrollable).evaluate()) {
      final state = (element as StatefulElement).state as ScrollableState;
      if (state.widget.axis != Axis.horizontal) continue;
      if (!state.position.hasContentDimensions) continue;
      final hidden = state.position.maxScrollExtent;
      if (hidden <= _slack) continue;

      // Which group it belongs to, and whether a table put it there: a
      // `Segmented` too long for the screen scrolls as well, and that is its
      // own answer to being narrow — it grows a pair of arrows.
      var table = false;
      var group = '?';
      element.visitAncestorElements((a) {
        final w = a.widget;
        if (w is Table) table = true;
        if (w is Group && w.label is String && group == '?') {
          group = w.label as String;
        }
        return true;
      });
      if (!table || _byDesign.contains(group)) continue;
      past.add('"$group" hides ${hidden.round()} px past the right edge');
    }

    expect(
      past,
      isEmpty,
      reason:
          'a phone cannot show these, and dragging sideways is not an '
          'answer — give the columns that carry least a `showFrom`:\n'
          '${past.join("\n")}',
    );
  });
}
