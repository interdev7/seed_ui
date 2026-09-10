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
  _clearMarkTests();
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

/// Records what a painter draws, so its geometry can be read back.
class _Recorder implements Canvas {
  final circles = <({Offset centre, double radius})>[];
  final lines = <({Offset from, Offset to})>[];

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      circles.add((centre: c, radius: radius));

  @override
  void drawLine(Offset from, Offset to, Paint paint) =>
      lines.add((from: from, to: to));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void _clearMarkTests() {
  group('the clear mark', () {
    test('the cross sits in the middle of the disc, whatever the box', () {
      for (final size in [
        const Size.square(16),
        // Taller than it is wide, which is what a row that stretches its
        // children hands it.
        const Size(16, 32),
        const Size(32, 16),
      ]) {
        final canvas = _Recorder();
        ClearIconPainter(const Color(0xFF000000)).paint(canvas, size);

        expect(canvas.circles, hasLength(1));
        expect(canvas.lines, hasLength(2));
        final disc = canvas.circles.single;
        for (final line in canvas.lines) {
          final middle = (line.from + line.to) / 2;
          expect(
            (middle - disc.centre).distance,
            lessThan(0.01),
            reason: 'the cross is centred on the disc at $size',
          );
          // And inside it, not spilling over the edge.
          expect((line.from - disc.centre).distance, lessThan(disc.radius));
        }
      }
    });

    test('the disc keeps to the shorter side', () {
      final canvas = _Recorder();
      ClearIconPainter(const Color(0xFF000000))
          .paint(canvas, const Size(16, 32));
      // Sixteen wide and thirty-two tall makes a mark sixteen across, not one
      // that spills out of the sides.
      expect(canvas.circles.single.radius, 8);
    });
  });
}
