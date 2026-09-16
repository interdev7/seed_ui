// Lists the controls a screen reader would announce as "button" and nothing
// else.
//
// Run from the example, whose pages already cover every component:
//
//     cd example && flutter test tool/unnamed_controls_test.dart
//
// A report rather than a gate, for now: the kit's own chrome is named, and
// what is left is a list being worked through. When it reaches nothing this
// becomes a test in example/test and stays there.
//
// Every demo page is walked rather than a list of widgets kept by hand: a
// list is a thing somebody has to remember to add to, and the page a new
// component ships with is written anyway. The cross on an `Upload` row, the
// arrows on a `Pagination` and the crosses that empty the four pickers were
// all found this way.
import 'package:flutter/material.dart' as m;
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
import 'package:seed_ui_example/main.dart' show demos;

/// A control a screen reader would announce as "button" and nothing else.
///
/// Every demo page is walked rather than a list of widgets kept by hand: a
/// list is a thing somebody has to remember to add to, and the page a new
/// component ships with is written anyway. The kit's own cross on an `Upload`
/// row and the arrows on a `Pagination` were both found this way — they were
/// buttons with a glyph on them and no words anywhere underneath.
class _Unnamed {
  _Unnamed(this.page, this.rect, this.actions);

  final String page;
  final Rect rect;
  final String actions;

  @override
  String toString() =>
      '$page: a ${rect.width.round()}x${rect.height.round()} '
      'node does [$actions] and has no name';
}

/// Whether this node, or anything merged under it, says a word.
bool _hasName(SemanticsNode node) {
  final data = node.getSemanticsData();
  if (data.label.trim().isNotEmpty) return true;
  if (data.tooltip.trim().isNotEmpty) return true;
  if (data.value.trim().isNotEmpty) return true;
  var named = false;
  node.visitChildren((child) {
    named = named || _hasName(child);
    return true;
  });
  return named;
}

void main() {
  // The actions a person performs on purpose. Scrolling and focusing happen
  // to a control rather than being asked of it by name, and a scroll view
  // with no name of its own is not a defect.
  const doing = <SemanticsAction>[
    SemanticsAction.tap,
    SemanticsAction.longPress,
    SemanticsAction.increase,
    SemanticsAction.decrease,
  ];

  testWidgets('what a person can act on and cannot hear named', (tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final handle = tester.ensureSemantics();
    final unnamed = <_Unnamed>[];

    for (final demo in demos) {
      await tester.pumpWidget(
        ConfigProvider(
          child: m.MaterialApp(
            navigatorKey: UiKit.navigatorKey,
            home: m.Scaffold(
              body: SingleChildScrollView(
                child: Builder(builder: demo.builder),
              ),
            ),
          ),
        ),
      );
      // Not pumpAndSettle: several pages end on something that never settles
      // — a spinner, a countdown, a table still loading.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // Whatever a page throws is a matter for that page's own test — two
      // of them want the app's own shell around them and say so.
      // Whatever a page throws is a matter for that page's own test — two
      // of them want the app's own shell around them and say so.
      if (tester.takeException() != null) continue;

      // The semantics live on the view's own pipeline owner, a child of the
      // root one — the root itself has none.
      SemanticsNode? root;
      tester.binding.rootPipelineOwner.visitChildren((owner) {
        root ??= owner.semanticsOwner?.rootSemanticsNode;
      });
      final tree = root;
      if (tree == null) continue;

      void walk(SemanticsNode node, {required bool namedAbove}) {
        final data = node.getSemanticsData();
        final named = namedAbove || data.label.trim().isNotEmpty;
        final acts = doing.where(data.hasAction).toList();
        // A control wrapped in both a `Semantics` and a `GestureDetector`
        // leaves an inner node carrying the tap and no words: the reader
        // announces the named one above it, so it is not a defect.
        if (acts.isNotEmpty && !named && !_hasName(node)) {
          unnamed.add(
            _Unnamed(demo.id, node.rect, acts.map((a) => a.name).join(', ')),
          );
        }
        node.visitChildren((child) {
          walk(child, namedAbove: named);
          return true;
        });
      }

      walk(tree, namedAbove: false);
    }

    handle.dispose();
    // What this finds is a control carrying a glyph and no words: a reader
    // meets it and can say only "button". Give it a `semanticsLabel`, or a
    // `Semantics(label:)` around it — in the kit where every caller would
    // otherwise repeat the same word, in the demo where the word is the
    // caller's to choose.
    expect(
      unnamed,
      isEmpty,
      reason:
          'controls a person can act on but not hear named:\n'
          '${unnamed.join("\n")}',
    );
  });
}
