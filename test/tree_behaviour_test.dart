import 'dart:async';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart'
    hide Checkbox, ThemeData, Tooltip, Badge, Card, Drawer;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// What a tree does, held still while the way it is built changes underneath.
///
/// Every test here runs once per mode a tree can be drawn in. A tree is laid
/// out in full, or — given a [Tree.height] — as a scrolling list that builds
/// only the rows on screen, for trees of thousands of nodes. The second is
/// held to everything the first does: the same rows in the same order, the
/// same answers to a tap, a key and a drag, and the same pixels.

/// The modes a tree is drawn in. Laid out in full, and built lazily in a
/// window [height] tall.
enum _Mode { full, lazy }

const double _window = 400;

/// A tree in [mode]: everything else as given.
Tree _tree(
  _Mode mode, {
  required List<TreeNode> nodes,
  bool checkable = false,
  bool selectable = true,
  bool multiple = false,
  bool checkStrictly = false,
  bool? showLine,
  bool? showLeafIcon,
  bool? showIcon,
  bool? blockNode,
  bool? disabled,
  Future<void> Function(TreeNode node)? loadData,
  List<String>? defaultCheckedKeys,
  void Function(List<String>, List<String>)? onCheck,
  List<String>? selectedKeys,
  List<String>? defaultSelectedKeys,
  ValueChanged<List<String>>? onSelect,
  List<String>? expandedKeys,
  List<String>? defaultExpandedKeys,
  ValueChanged<List<String>>? onExpand,
  bool defaultExpandAll = false,
  bool draggable = false,
  ValueChanged<TreeDropDetails>? onDrop,
}) =>
    Tree(
      height: mode == _Mode.lazy ? _window : null,
      nodes: nodes,
      checkable: checkable,
      selectable: selectable,
      multiple: multiple,
      checkStrictly: checkStrictly,
      showLine: showLine,
      showLeafIcon: showLeafIcon,
      showIcon: showIcon,
      blockNode: blockNode,
      disabled: disabled,
      loadData: loadData,
      defaultCheckedKeys: defaultCheckedKeys,
      onCheck: onCheck,
      selectedKeys: selectedKeys,
      defaultSelectedKeys: defaultSelectedKeys,
      onSelect: onSelect,
      expandedKeys: expandedKeys,
      defaultExpandedKeys: defaultExpandedKeys,
      onExpand: onExpand,
      defaultExpandAll: defaultExpandAll,
      draggable: draggable,
      onDrop: onDrop,
    );

/// A page the tree stands at the top of, in a box as tall as the lazy
/// window, so both modes are measured against the same frame.
Widget _host(Widget tree, {TextDirection direction = TextDirection.ltr}) =>
    ConfigProvider(
      child: MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Align(
              alignment: AlignmentDirectional.topStart,
              child: RepaintBoundary(
                key: const Key('shot'),
                child: SizedBox(width: 320, height: _window, child: tree),
              ),
            ),
          ),
        ),
      ),
    );

/// Two levels, three parents, with a third level under the first child.
final _nodes = [
  const TreeNode(
    key: 'a',
    title: Text('Alpha'),
    children: [
      TreeNode(
        key: 'a1',
        title: Text('Alpha one'),
        children: [
          TreeNode(key: 'a1x', title: Text('Alpha one x')),
          TreeNode(key: 'a1y', title: Text('Alpha one y')),
        ],
      ),
      TreeNode(key: 'a2', title: Text('Alpha two')),
    ],
  ),
  const TreeNode(
    key: 'b',
    title: Text('Beta'),
    icon: Icon(Icons.folder),
    children: [
      TreeNode(key: 'b1', title: Text('Beta one'), disabled: true),
      TreeNode(key: 'b2', title: Text('Beta two')),
    ],
  ),
  const TreeNode(key: 'c', title: Text('Gamma')),
];

/// A last branch with a branch inside it that is not its last.
const _last = TreeNode(
  key: 'z',
  title: Text('Omega'),
  children: [
    TreeNode(
      key: 'z1',
      title: Text('Omega one'),
      children: [TreeNode(key: 'z1a', title: Text('Omega one a'))],
    ),
    TreeNode(key: 'z2', title: Text('Omega two')),
  ],
);

/// The titles on show, top to bottom, as a reader meets them.
List<String> _rows(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(
        find.descendant(of: find.byType(Tree), matching: find.byType(Text)),
      )
      .where((t) => t.data != null)
      .toList();
  final placed = [
    for (final t in texts) (t.data!, tester.getTopLeft(find.byWidget(t)).dy),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final p in placed) p.$1];
}

Finder _switcherOf(String title) => find.descendant(
      of: find.ancestor(of: find.text(title), matching: find.byType(Row)).last,
      matching: find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is ChevronPainter,
      ),
    );

void main() {
  _pixelTests();
  for (final mode in _Mode.values) {
    group('$mode', () {
      testWidgets('shows the rows that are open, in reading order', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(_tree(mode, nodes: _nodes, defaultExpandedKeys: ['a', 'a1'])),
        );
        await tester.pumpAndSettle();
        expect(_rows(tester), [
          'Alpha',
          'Alpha one',
          'Alpha one x',
          'Alpha one y',
          'Alpha two',
          'Beta',
          'Gamma',
        ]);
      });

      testWidgets('the switcher opens and shuts a branch, and says so', (
        tester,
      ) async {
        final told = <List<String>>[];
        await tester.pumpWidget(
          _host(_tree(mode, nodes: _nodes, onExpand: told.add)),
        );
        await tester.tap(_switcherOf('Beta'));
        await tester.pumpAndSettle();
        expect(
            _rows(tester), ['Alpha', 'Beta', 'Beta one', 'Beta two', 'Gamma']);

        await tester.tap(_switcherOf('Beta'));
        await tester.pumpAndSettle();
        expect(_rows(tester), ['Alpha', 'Beta', 'Gamma']);
        expect(told, [
          ['b'],
          <String>[],
        ]);
      });

      testWidgets('a controlled tree shows what it is told', (tester) async {
        await tester.pumpWidget(
          _host(_tree(mode, nodes: _nodes, expandedKeys: ['b'])),
        );
        await tester.pumpAndSettle();
        expect(
            _rows(tester), ['Alpha', 'Beta', 'Beta one', 'Beta two', 'Gamma']);
      });

      testWidgets('selecting one, and several', (tester) async {
        final told = <List<String>>[];
        await tester.pumpWidget(
          _host(
            _tree(
              mode,
              nodes: _nodes,
              multiple: true,
              defaultExpandAll: true,
              onSelect: told.add,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Alpha two'));
        await tester.pump();
        await tester.tap(find.text('Gamma'));
        await tester.pump();
        await tester.tap(find.text('Beta one')); // disabled: no answer
        await tester.pump();
        expect(told, [
          ['a2'],
          ['a2', 'c'],
        ]);
      });

      testWidgets('checking cascades down and half-checks up', (tester) async {
        final told = <(List<String>, List<String>)>[];
        await tester.pumpWidget(
          _host(
            _tree(
              mode,
              nodes: _nodes,
              checkable: true,
              defaultExpandAll: true,
              onCheck: (c, h) => told.add((c..sort(), h..sort())),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find
                .ancestor(
                  of: find.text('Alpha one'),
                  matching: find.byType(Row),
                )
                .last,
            matching: find.byType(Checkbox),
          ),
        );
        await tester.pump();
        expect(told.single.$1, ['a1', 'a1x', 'a1y']);
        expect(told.single.$2, ['a'], reason: 'the parent is half-checked');
      });

      testWidgets('checkStrictly checks the one alone', (tester) async {
        final told = <List<String>>[];
        await tester.pumpWidget(
          _host(
            _tree(
              mode,
              nodes: _nodes,
              checkable: true,
              checkStrictly: true,
              defaultExpandAll: true,
              onCheck: (c, _) => told.add(c),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find
                .ancestor(of: find.text('Alpha'), matching: find.byType(Row))
                .last,
            matching: find.byType(Checkbox),
          ),
        );
        await tester.pump();
        expect(told.single, ['a']);
      });

      testWidgets('the keys walk, open, shut and choose', (tester) async {
        final selected = <List<String>>[];
        final expanded = <List<String>>[];
        await tester.pumpWidget(
          _host(
            _tree(
              mode,
              nodes: _nodes,
              onSelect: selected.add,
              onExpand: expanded.add,
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // Alpha
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); // open it
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); // Alpha one
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // Alpha two
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft); // to Alpha
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft); // shut it
        await tester.pumpAndSettle();

        expect(selected, [
          ['a2'],
        ]);
        expect(expanded, [
          ['a'],
          <String>[],
        ]);
        expect(_rows(tester), ['Alpha', 'Beta', 'Gamma']);
      });

      testWidgets('a branch loads its children the first time it opens', (
        tester,
      ) async {
        final done = Completer<void>();
        var nodes = const [TreeNode(key: 'r', title: Text('Remote'))];
        late StateSetter set;
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (context, setState) {
                set = setState;
                return _tree(
                  mode,
                  nodes: nodes,
                  loadData: (node) async {
                    await done.future;
                    set(() {
                      nodes = const [
                        TreeNode(
                          key: 'r',
                          title: Text('Remote'),
                          children: [
                            TreeNode(key: 'r1', title: Text('Fetched')),
                          ],
                        ),
                      ];
                    });
                  },
                );
              },
            ),
          ),
        );
        await tester.tap(_switcherOf('Remote'));
        await tester.pump();
        expect(find.byType(Spinner), findsOneWidget);

        done.complete();
        await tester.pumpAndSettle();
        expect(find.byType(Spinner), findsNothing);
        expect(_rows(tester), ['Remote', 'Fetched']);
      });

      testWidgets('a node dragged onto another is reported', (tester) async {
        final drops = <TreeDropDetails>[];
        await tester.pumpWidget(
          _host(
            _tree(
              mode,
              nodes: _nodes,
              draggable: true,
              onDrop: drops.add,
            ),
          ),
        );
        final from = tester.getCenter(find.text('Gamma'));
        final to = tester.getCenter(find.text('Alpha'));
        final gesture = await tester.startGesture(from);
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.moveTo(Offset(to.dx, to.dy));
        await tester.pump();
        await gesture.moveTo(to);
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(drops.single.dragKey, 'c');
        expect(drops.single.dropKey, 'a');
        expect(drops.single.position, TreeDropPosition.inside);
      });
    });
  }
}

/// The tree as drawn, as a fingerprint of its pixels.
Future<int> _shot(WidgetTester tester) async {
  final hash = await tester.runAsync(() async {
    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('shot')));
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ImageByteFormat.rawRgba);
    image.dispose();
    var h = 0x811c9dc5;
    for (final b in data!.buffer.asUint8List()) {
      h = ((h ^ b) * 0x01000193) & 0xffffffff;
    }
    return h;
  });
  return hash!;
}

void _pixelTests() {
  group('the same pixels either way', () {
    final looks = <String, Tree Function(_Mode)>{
      'open, plain': (m) =>
          _tree(m, nodes: _nodes, defaultExpandedKeys: ['a', 'a1']),
      'with guide lines and leaf marks': (m) => _tree(
            m,
            nodes: _nodes,
            defaultExpandAll: true,
            showLine: true,
            showLeafIcon: true,
          ),
      'checkable, half-checked': (m) => _tree(
            m,
            nodes: _nodes,
            checkable: true,
            defaultExpandAll: true,
            defaultCheckedKeys: ['a1x'],
          ),
      'selected, with icons': (m) => _tree(
            m,
            nodes: _nodes,
            defaultExpandAll: true,
            showIcon: true,
            defaultSelectedKeys: ['a2'],
          ),
      'block rows': (m) => _tree(
            m,
            nodes: _nodes,
            defaultExpandAll: true,
            blockNode: true,
            defaultSelectedKeys: ['b2'],
          ),
      'disabled': (m) =>
          _tree(m, nodes: _nodes, defaultExpandAll: true, disabled: true),
      'draggable': (m) =>
          _tree(m, nodes: _nodes, defaultExpandAll: true, draggable: true),
    };

    for (final MapEntry(key: name, value: build) in looks.entries) {
      for (final direction in TextDirection.values) {
        testWidgets('at rest: $name, $direction', (tester) async {
          final shots = <_Mode, int>{};
          for (final mode in _Mode.values) {
            // A fresh tree each time: one built in the same place would take
            // over the last one's state, open branches and all.
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(
              _host(build(mode), direction: direction),
            );
            await tester.pumpAndSettle();
            shots[mode] = await _shot(tester);
          }
          expect(shots[_Mode.lazy], shots[_Mode.full]);
        });
      }
    }

    for (final (what, start, branch, lines) in [
      ('opening', <String>[], 'Alpha', false),
      ('closing', ['a', 'a1'], 'Alpha', false),
      ('opening a branch with an open one in it', ['a1'], 'Alpha', false),
      // With the guides drawn, every row in the moving branch has to know
      // which of its ancestors were last of their line.
      ('opening, with guide lines', ['a1'], 'Alpha', true),
      ('closing, with guide lines', ['a', 'a1', 'b'], 'Alpha', true),
      // The last branch of all, two levels deep: the one place a guide that
      // ought to stop would be drawn on down if the moving rows were wrong.
      ('opening the last branch, with guide lines', ['z1'], 'Omega', true),
    ]) {
      testWidgets('every frame of $what', (tester) async {
        final frames = <_Mode, List<int>>{};
        for (final mode in _Mode.values) {
          // A fresh tree each time: one built in the same place would take
          // over the last one's state, open branches and all.
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(
            _host(
              _tree(
                mode,
                nodes: [..._nodes, _last],
                defaultExpandedKeys: start,
                showLine: lines,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(_switcherOf(branch));
          final shots = <int>[];
          for (var i = 0; i < 16; i++) {
            await tester.pump(const Duration(milliseconds: 16));
            shots.add(await _shot(tester));
          }
          await tester.pumpAndSettle();
          shots.add(await _shot(tester));
          frames[mode] = shots;
        }
        expect(frames[_Mode.lazy], frames[_Mode.full]);
      });
    }
  });

  group('turned round part-way', () {
    testWidgets('a branch shut again before it has finished opening', (
      tester,
    ) async {
      final frames = <_Mode, List<int>>{};
      for (final mode in _Mode.values) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          _host(_tree(mode, nodes: _nodes, defaultExpandedKeys: ['a1'])),
        );
        await tester.pumpAndSettle();
        await tester.tap(_switcherOf('Alpha'));
        final shots = <int>[];
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          shots.add(await _shot(tester));
        }
        await tester.tap(_switcherOf('Alpha'));
        for (var i = 0; i < 14; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          shots.add(await _shot(tester));
        }
        await tester.pumpAndSettle();
        shots.add(await _shot(tester));
        frames[mode] = shots;
      }
      expect(frames[_Mode.lazy], frames[_Mode.full]);
    });
  });

  group('a lazy tree builds what it shows', () {
    final big = [
      TreeNode(
        key: 'root',
        title: const Text('Folder'),
        children: [
          for (var i = 0; i < 5000; i++)
            TreeNode(key: 'f$i', title: Text('file $i')),
        ],
      ),
    ];

    testWidgets('five thousand files, a screenful of rows', (tester) async {
      await tester.pumpWidget(
        _host(_tree(_Mode.lazy, nodes: big, defaultExpandAll: true)),
      );
      await tester.pumpAndSettle();
      final built = find
          .descendant(of: find.byType(Tree), matching: find.byType(Text))
          .evaluate()
          .length;
      expect(built, lessThan(40), reason: 'a window of 400 holds ~17 rows');
    });

    testWidgets('opening them builds no more than the window', (tester) async {
      await tester.pumpWidget(_host(_tree(_Mode.lazy, nodes: big)));
      await tester.tap(_switcherOf('Folder'));
      await tester.pump(const Duration(milliseconds: 50));
      final built = find
          .descendant(of: find.byType(Tree), matching: find.byType(Text))
          .evaluate()
          .length;
      expect(built, lessThan(40));
      await tester.pumpAndSettle();
      expect(find.text('file 0'), findsOneWidget);
    });

    testWidgets('the arrow keys bring the row they reach into view', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_tree(_Mode.lazy, nodes: big, defaultExpandAll: true)),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }
      await tester.pump();
      // Folder is the first row; forty presses later the keyboard is on
      // file 38, which was never built until it was scrolled to.
      expect(find.text('file 38'), findsOneWidget);
      final row = tester.getRect(find.text('file 38'));
      expect(row.bottom, lessThanOrEqualTo(_window + 1));
    });
  });
}
