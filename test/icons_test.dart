import 'package:flutter/material.dart' hide ThemeData;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
// Several icons are internal to the kit — they back a component's chrome
// rather than being part of the public surface — so they are reached through
// the implementation library rather than the barrel.
import 'package:seed_ui/src/icons/icons.dart'
    show
        ClearIconPainter,
        DownloadPainter,
        PaperclipPainter,
        PlusPainter,
        RetryPainter,
        TreeLeafIconPainter;

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

  group('Glyph geometry', () {
    const blue = Color(0xFF1677FF);

    testWidgets('a paperclip fills its box and stays inside it',
        (tester) async {
      _expectFitsBox(PaperclipPainter(blue));
    });

    testWidgets('a paperclip turns its loop downward', (tester) async {
      // The bottom arc once curved the wrong way, folding the lower half of
      // the clip back into the strokes above it. That still fits the box, so
      // bounds alone do not catch it — the loop has to reach the floor.
      final canvas = _PathCanvas();
      PaperclipPainter(blue).paint(canvas, const Size.square(16));

      var bottom = 0.0;
      for (final path in canvas.paths) {
        final b = path.getBounds().bottom;
        if (b > bottom) bottom = b;
      }
      expect(bottom, greaterThan(16 * 0.8));
    });

    testWidgets('plus, download and retry do too', (tester) async {
      _expectFitsBox(PlusPainter(blue));
      _expectFitsBox(DownloadPainter(blue));
      _expectFitsBox(RetryPainter(blue));
    });
  });
}

/// Records the shapes a painter draws, so its geometry can be measured
/// instead of eyeballed.
class _PathCanvas implements Canvas {
  final List<Path> paths = [];

  @override
  void drawPath(Path path, Paint paint) => paths.add(path);

  @override
  void drawLine(Offset a, Offset b, Paint paint) =>
      paths.add(Path()..addRect(Rect.fromPoints(a, b)));

  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) =>
      paths.add(Path()..addArc(rect, startAngle, sweepAngle));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void _expectFitsBox(CustomPainter painter, {double side = 16}) {
  final canvas = _PathCanvas();
  painter.paint(canvas, Size.square(side));
  expect(canvas.paths, isNotEmpty, reason: 'painter drew nothing');

  var bounds = canvas.paths.first.getBounds();
  for (final p in canvas.paths.skip(1)) {
    bounds = bounds.expandToInclude(p.getBounds());
  }

  // A glyph that spills past its box is clipped by whatever sizes it, which
  // is how half a paperclip reaches the screen.
  expect(bounds.left, greaterThanOrEqualTo(-0.01));
  expect(bounds.top, greaterThanOrEqualTo(-0.01));
  expect(bounds.right, lessThanOrEqualTo(side + 0.01));
  expect(bounds.bottom, lessThanOrEqualTo(side + 0.01));

  // …and one that hugs the middle reads as a dot. It should use its box.
  expect(bounds.width, greaterThan(side * 0.3));
  expect(bounds.height, greaterThan(side * 0.3));
}
