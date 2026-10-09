import 'package:flutter/material.dart'
    hide Badge, Tooltip, ThemeData, Switch, Checkbox, Radio, Drawer, Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// What moves on its own repaints itself, and nothing beside it.
///
/// A spinner turns sixty times a second. On the layer it shared with
/// everything around it, each turn repainted all of that — a page, while one
/// button was loading — and the battery paid for pixels nobody saw change.
/// Measured with a neighbour that counts how often it is painted: it should
/// be painted once, when it appears, and never again.

/// Counts its own paints: a neighbour that never changes.
class _Counter extends CustomPainter {
  int paints = 0;

  @override
  void paint(Canvas canvas, Size size) => paints++;

  @override
  bool shouldRepaint(_Counter old) => false;
}

void main() {
  final cases = <(String, Widget)>[
    ('a spinner', const Spinner(size: 20, color: Color(0xFF1677FF))),
    (
      'a loading button',
      Button(loading: true, onPressed: () {}, child: const Text('Saving')),
    ),
    (
      'a spin over content',
      const Spin(spinning: true, child: SizedBox(width: 100, height: 60)),
    ),
    (
      'a badge that is processing',
      const Badge(status: BadgeStatus.processing, text: Text('Live')),
    ),
    // Not a countdown to the millisecond. It has a layer of its own, which
    // keeps a frame whose figures are as wide as the last from reaching its
    // neighbours; but proportional figures change width as they count, a
    // change of width is a change of layout, and a layout repaints what is
    // laid out around it. Figures of one width would end that, and would
    // change how the figures look — so they are not the kit's to choose.
  ];

  for (final (name, widget) in cases) {
    testWidgets('$name repaints only itself', (tester) async {
      final neighbour = _Counter();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CustomPaint(size: const Size(200, 200), painter: neighbour),
                widget,
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final settled = neighbour.paints;

      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(
        neighbour.paints - settled,
        0,
        reason: 'a second of animation repainted what stood beside it',
      );
    });
  }
}
