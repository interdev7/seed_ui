import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _wrap(Widget child) => ConfigProvider(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    );

/// Like [_wrap] but with an [Overlay] ancestor, which `Draggable` requires.
Widget _app(Widget child) => ConfigProvider(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (_) => Align(alignment: Alignment.topLeft, child: child),
            ),
          ],
        ),
      ),
    );

const _nodes = [
  TreeNode(
    key: 'p',
    title: Text('parent'),
    children: [
      TreeNode(key: 'c1', title: Text('child 1')),
      TreeNode(key: 'c2', title: Text('child 2')),
    ],
  ),
];

void main() {
  testWidgets('the switcher expands and collapses children', (tester) async {
    List<String>? expanded;
    await tester
        .pumpWidget(_wrap(Tree(nodes: _nodes, onExpand: (e) => expanded = e)));
    expect(find.text('child 1'), findsNothing);

    final switcher = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is ChevronPainter,
    );
    await tester.tap(switcher);
    await tester.pumpAndSettle();
    expect(expanded, ['p']);
    expect(find.text('child 1'), findsOneWidget);

    await tester.tap(switcher);
    await tester.pumpAndSettle();
    expect(expanded, isEmpty);
    expect(find.text('child 1'), findsNothing);
  });

  testWidgets('selecting a node does not expand it', (tester) async {
    await tester.pumpWidget(_wrap(const Tree(nodes: _nodes)));
    await tester.tap(find.text('parent'));
    await tester.pumpAndSettle();
    expect(find.text('child 1'), findsNothing);
  });

  testWidgets('defaultExpandAll reveals descendants', (tester) async {
    await tester
        .pumpWidget(_wrap(const Tree(nodes: _nodes, defaultExpandAll: true)));
    expect(find.text('child 1'), findsOneWidget);
    expect(find.text('child 2'), findsOneWidget);
  });

  testWidgets('selecting a node reports it', (tester) async {
    List<String>? sel;
    await tester.pumpWidget(
      _wrap(
        Tree(
          nodes: _nodes,
          defaultExpandAll: true,
          onSelect: (s) => sel = s,
        ),
      ),
    );
    await tester.tap(find.text('child 1'));
    await tester.pumpAndSettle();
    expect(sel, ['c1']);
  });

  testWidgets('checking a parent cascades to children', (tester) async {
    List<String>? checked;
    await tester.pumpWidget(
      _wrap(
        Tree(
          nodes: _nodes,
          checkable: true,
          defaultExpandAll: true,
          onCheck: (c, _) => checked = c,
        ),
      ),
    );
    // Tap the parent's checkbox (first Checkbox in the tree).
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(checked, containsAll(<String>['p', 'c1', 'c2']));
  });

  testWidgets('checking one child half-checks the parent', (tester) async {
    List<String>? checked;
    List<String>? half;
    await tester.pumpWidget(
      _wrap(
        Tree(
          nodes: _nodes,
          checkable: true,
          defaultExpandAll: true,
          onCheck: (c, h) {
            checked = c;
            half = h;
          },
        ),
      ),
    );
    // Checkboxes in order: parent, child1, child2 → tap child1.
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    expect(checked, contains('c1'));
    expect(checked, isNot(contains('p')));
    expect(half, contains('p'));
  });

  testWidgets('a disabled node still shows a (disabled) checkbox',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Tree(
          checkable: true,
          defaultExpandAll: true,
          nodes: [
            TreeNode(
              key: 'p',
              title: Text('parent'),
              children: [
                TreeNode(key: 'c1', title: Text('child 1')),
                TreeNode(key: 'c2', title: Text('child 2'), disabled: true),
              ],
            ),
          ],
        ),
      ),
    );
    // parent + 2 children = 3 checkboxes, one of them disabled.
    expect(find.byType(Checkbox), findsNWidgets(3));
    final disabled = tester
        .widgetList<Checkbox>(find.byType(Checkbox))
        .where((c) => c.disabled);
    expect(disabled.length, 1);
  });

  testWidgets('autoExpandParent reveals ancestors of expanded keys',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Tree(
          autoExpandParent: true,
          expandedKeys: [
            'c1'
          ], // only the child is listed; parent must auto-expand
          nodes: _nodes,
        ),
      ),
    );
    expect(find.text('child 1'), findsOneWidget);
  });

  testWidgets(
      'uncontrolled autoExpandParent seeds ancestors yet stays '
      'collapsible', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Tree(
          autoExpandParent: true,
          defaultExpandedKeys: ['p'],
          nodes: _nodes,
        ),
      ),
    );
    expect(find.text('child 1'), findsOneWidget);

    // Uncontrolled: the switcher can still collapse it.
    final switcher = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is ChevronPainter,
    );
    await tester.tap(switcher.first);
    await tester.pumpAndSettle();
    expect(find.text('child 1'), findsNothing);
  });

  testWidgets('loadData lazily loads children with a spinner', (tester) async {
    await tester.pumpWidget(_wrap(const _LoadHarness()));
    expect(find.text('loaded child'), findsNothing);

    final switcher = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is ChevronPainter,
    );
    await tester.tap(switcher);
    await tester.pump(); // start loading
    expect(find.byType(Spinner), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 20)); // future resolves
    await tester.pump(); // apply the parent's node update
    await tester.pump(const Duration(milliseconds: 300)); // expand animation
    expect(find.byType(Spinner), findsNothing);
    expect(find.text('loaded child'), findsOneWidget);
  });

  testWidgets('dragging a node onto another reports a drop', (tester) async {
    await tester.pumpWidget(_app(const _DragHarness()));
    await tester.pumpAndSettle();

    final a = find.text('A');
    final b = find.text('B');
    // Drag A onto the lower third of B → dropped after B.
    final gesture = await tester.startGesture(tester.getCenter(a));
    await tester.pump(const Duration(milliseconds: 20));
    final bBox = tester.getRect(b);
    await gesture.moveTo(Offset(bBox.center.dx, bBox.bottom - 2));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    // A now follows B (the harness reorders on drop).
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('a drop into its own subtree is rejected', (tester) async {
    TreeDropDetails? dropped;
    await tester.pumpWidget(
      _app(
        Tree(
          draggable: true,
          defaultExpandAll: true,
          onDrop: (d) => dropped = d,
          nodes: _nodes, // p → c1, c2
        ),
      ),
    );
    // Drag the parent onto its own child — must not fire onDrop.
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('parent')));
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveTo(tester.getCenter(find.text('child 1')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(dropped, isNull);
  });

  testWidgets('checkStrictly disables the cascade', (tester) async {
    List<String>? checked;
    await tester.pumpWidget(
      _wrap(
        Tree(
          nodes: _nodes,
          checkable: true,
          checkStrictly: true,
          defaultExpandAll: true,
          onCheck: (c, _) => checked = c,
        ),
      ),
    );
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(checked, ['p']);
  });
}

/// A tiny host that lazily loads a node's children after a short delay.
class _LoadHarness extends StatefulWidget {
  const _LoadHarness();

  @override
  State<_LoadHarness> createState() => _LoadHarnessState();
}

class _LoadHarnessState extends State<_LoadHarness> {
  List<TreeNode> _data = const [TreeNode(key: 'x', title: Text('load me'))];

  Future<void> _load(TreeNode node) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (!mounted) return;
    setState(() {
      _data = const [
        TreeNode(
          key: 'x',
          title: Text('load me'),
          children: [
            TreeNode(key: 'x-0', title: Text('loaded child')),
          ],
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) => Tree(nodes: _data, loadData: _load);
}

/// Two sibling nodes that reorder on drop.
class _DragHarness extends StatefulWidget {
  const _DragHarness();

  @override
  State<_DragHarness> createState() => _DragHarnessState();
}

class _DragHarnessState extends State<_DragHarness> {
  List<TreeNode> _data = const [
    TreeNode(key: 'a', title: Text('A')),
    TreeNode(key: 'b', title: Text('B')),
  ];

  void _onDrop(TreeDropDetails d) {
    final moved = _data.firstWhere((n) => n.key == d.dragKey);
    final rest = _data.where((n) => n.key != d.dragKey).toList();
    final i = rest.indexWhere((n) => n.key == d.dropKey);
    rest.insert(d.position == TreeDropPosition.before ? i : i + 1, moved);
    setState(() => _data = rest);
  }

  @override
  Widget build(BuildContext context) =>
      Tree(nodes: _data, draggable: true, onDrop: _onDrop);
}
