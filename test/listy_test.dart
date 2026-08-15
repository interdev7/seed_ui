import 'dart:async';

import 'package:flutter/material.dart' hide Card, ThemeData;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => ConfigProvider(
      theme: ThemeData.light,
      child: MaterialApp(home: Scaffold(body: child)),
    );

enum _Section { first, second }

class _Row {
  const _Row(this.id, this.name, this.group);
  final String id;
  final String name;
  final String group;
}

/// Pumps frames until [work] finishes — a scroll walk only advances while the
/// tester is producing frames.
Future<void> _drive(WidgetTester tester, Future<void> work) async {
  var done = false;
  unawaited(work.then((_) => done = true));
  for (var i = 0; i < 30 && !done; i++) {
    await tester.pump();
  }
  expect(done, isTrue, reason: 'scrollTo did not settle');
  // One more frame so the rows around the final position are built.
  await tester.pump();
}

List<_Row> _rows(int count) => List.generate(
      count,
      (i) => _Row('id-$i', 'Row $i', i.isEven ? 'Even' : 'Odd'),
    );

void main() {
  group('Listy', () {
    testWidgets('renders rows and builds only the visible ones',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Listy(
            height: 200,
            items: _rows(500),
            rowKey: (r) => r.id,
            itemRender: (r, index) => Text(r.name),
          ),
        ),
      );

      expect(find.text('Row 0'), findsOneWidget);
      // Far-away rows are never mounted — the point of a lazy list.
      expect(find.text('Row 400'), findsNothing);
    });

    testWidgets('groups items and renders a header per section',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Listy(
            height: 300,
            items: _rows(6),
            rowKey: (r) => r.id,
            groupKey: (r) => r.group,
            groupTitle: (key, items) => Text('$key (${items.length})'),
            itemRender: (r, index) => Text(r.name),
          ),
        ),
      );

      expect(find.text('Even (3)'), findsOneWidget);
      expect(find.text('Odd (3)'), findsOneWidget);
    });

    testWidgets('sticky keeps a group header pinned while its section scrolls',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Listy(
            height: 200,
            sticky: true,
            items: _rows(40),
            rowKey: (r) => r.id,
            groupKey: (r) => r.group,
            groupTitle: (key, items) => Text('G:$key'),
            itemRender: (r, index) => Text(r.name),
          ),
        ),
      );

      final header = find.text('G:Even');
      final before = tester.getTopLeft(header).dy;

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
      await tester.pump();

      expect(header, findsOneWidget);
      expect(tester.getTopLeft(header).dy, closeTo(before, 0.5));
    });

    testWidgets('scrollTo reaches an item that was never built',
        (tester) async {
      final controller = ListyController();
      await tester.pumpWidget(
        _host(
          Listy(
            height: 200,
            controller: controller,
            items: _rows(500),
            rowKey: (r) => r.id,
            itemRender: (r, index) => SizedBox(height: 40, child: Text(r.name)),
          ),
        ),
      );

      expect(find.text('Row 300'), findsNothing);

      // The walk needs frames to build each estimate it lands on, so drive
      // them until it reports back rather than awaiting a future that only
      // completes while the tester pumps.
      await _drive(
        tester,
        controller.scrollTo(const ListyScrollTo.item('id-300')),
      );

      expect(find.text('Row 300'), findsOneWidget);
    });

    testWidgets('scrollTo(align: top) clears the pinned group header',
        (tester) async {
      final controller = ListyController();
      await tester.pumpWidget(
        _host(
          Listy(
            height: 240,
            sticky: true,
            controller: controller,
            items: _rows(200),
            rowKey: (r) => r.id,
            groupKey: (r) => r.group,
            groupTitle: (key, items) => Text('G:$key'),
            itemRender: (r, index) => SizedBox(height: 40, child: Text(r.name)),
          ),
        ),
      );

      await _drive(
        tester,
        controller.scrollTo(
          const ListyScrollTo.item('id-100', align: ListyScrollAlign.top),
        ),
      );

      final row = find.text('Row 100');
      expect(row, findsOneWidget);

      // Flush under the header: the row's own box starts exactly where the
      // pinned header's box ends — no overlap, and no gap either.
      final rowBox = find
          .ancestor(of: row, matching: find.byType(AnimatedContainer))
          .first;
      final headerBox = find
          .ancestor(of: find.text('G:Even'), matching: find.byType(SizedBox))
          .first;
      expect(
        tester.getTopLeft(rowBox).dy,
        closeTo(tester.getBottomLeft(headerBox).dy, 1),
      );
    });

    testWidgets('scrollTo lands on a group header', (tester) async {
      final controller = ListyController();
      await tester.pumpWidget(
        _host(
          Listy(
            height: 200,
            sticky: true,
            controller: controller,
            items: _rows(200),
            rowKey: (r) => r.id,
            groupKey: (r) => r.group,
            groupTitle: (key, items) => Text('G:$key'),
            itemRender: (r, index) => SizedBox(height: 40, child: Text(r.name)),
          ),
        ),
      );

      await _drive(
        tester,
        controller.scrollTo(const ListyScrollTo.group('Odd')),
      );

      expect(find.text('G:Odd'), findsOneWidget);
    });

    testWidgets('an animated scrollTo never teleports', (tester) async {
      final controller = ListyController();
      final scroll = ScrollController();
      await tester.pumpWidget(
        _host(
          Listy(
            height: 200,
            controller: controller,
            scrollController: scroll,
            items: _rows(400),
            rowKey: (r) => r.id,
            itemRender: (r, index) => SizedBox(height: 40, child: Text(r.name)),
          ),
        ),
      );

      final samples = <double>[scroll.offset];
      var done = false;
      unawaited(
        controller
            .scrollTo(
              const ListyScrollTo.item('id-300', align: ListyScrollAlign.top),
              duration: const Duration(milliseconds: 400),
            )
            .then((_) => done = true),
      );
      for (var i = 0; i < 90; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        samples.add(scroll.offset);
        if (done && scroll.position.isScrollingNotifier.value == false) break;
      }

      expect(find.text('Row 300'), findsOneWidget);
      expect(samples.length, greaterThan(10));

      // No single frame may cover a big share of the trip — that is what a
      // jump looks like.
      final travelled = (samples.last - samples.first).abs();
      var biggestStep = 0.0;
      for (var i = 1; i < samples.length; i++) {
        final step = (samples[i] - samples[i - 1]).abs();
        if (step > biggestStep) biggestStep = step;
      }
      expect(biggestStep, lessThan(travelled / 4));
    });

    testWidgets('an animated scrollTo lands exactly where a jump would',
        (tester) async {
      Future<double> land(Duration duration) async {
        final controller = ListyController();
        final scroll = ScrollController();
        await tester.pumpWidget(
          _host(
            Listy(
              height: 280,
              sticky: true,
              controller: controller,
              scrollController: scroll,
              items: _rows(200),
              rowKey: (r) => r.id,
              groupKey: (r) => r.group,
              groupTitle: (key, items) => Text('G:$key'),
              itemRender: (r, index) =>
                  SizedBox(height: 40, child: Text(r.name)),
            ),
          ),
        );

        var done = false;
        unawaited(
          controller
              .scrollTo(
                const ListyScrollTo.item('id-150', align: ListyScrollAlign.top),
                duration: duration,
              )
              .then((_) => done = true),
        );
        for (var i = 0; i < 120 && !done; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.pump(const Duration(milliseconds: 400));
        return scroll.offset;
      }

      // The exact offset is only trustworthy from close by, so an animated
      // trip has to keep re-aiming — otherwise it stops short of the top.
      final jumped = await land(Duration.zero);
      final glided = await land(const Duration(milliseconds: 300));
      expect(glided, closeTo(jumped, 1));
    });

    testWidgets('scrollTo(offset) moves the scroll position', (tester) async {
      final controller = ListyController();
      final scroll = ScrollController();
      await tester.pumpWidget(
        _host(
          Listy(
            height: 200,
            controller: controller,
            scrollController: scroll,
            items: _rows(200),
            rowKey: (r) => r.id,
            itemRender: (r, index) => SizedBox(height: 40, child: Text(r.name)),
          ),
        ),
      );

      await _drive(
        tester,
        controller.scrollTo(const ListyScrollTo.offset(500)),
      );

      expect(scroll.offset, 500);
    });

    testWidgets('onScroll reports the metrics', (tester) async {
      ScrollMetrics? seen;
      await tester.pumpWidget(
        _host(
          Listy(
            height: 200,
            items: _rows(100),
            rowKey: (r) => r.id,
            onScroll: (metrics) => seen = metrics,
            itemRender: (r, index) => SizedBox(height: 40, child: Text(r.name)),
          ),
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pump();

      expect(seen, isNotNull);
      expect(seen!.pixels, greaterThan(0));
    });

    testWidgets('loadMore fires once when the end comes within threshold',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          Listy(
            height: 200,
            items: _rows(20),
            rowKey: (r) => r.id,
            loadMore: ListyLoadMore(onLoad: () => calls++, threshold: 100),
            itemRender: (r, index) => SizedBox(height: 40, child: Text(r.name)),
          ),
        ),
      );

      expect(calls, 0);

      // Several scroll frames near the end must still only ask for one page.
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -50));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('loadMore fires when the rows do not fill the viewport',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          Listy(
            height: 400,
            items: _rows(2),
            rowKey: (r) => r.id,
            loadMore: ListyLoadMore(onLoad: () => calls++),
            itemRender: (r, index) => SizedBox(height: 40, child: Text(r.name)),
          ),
        ),
      );
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('loadMore stays quiet while loading and once exhausted',
        (tester) async {
      var calls = 0;
      Widget build({required bool loading, required bool hasMore}) => _host(
            Listy(
              height: 200,
              items: _rows(20),
              rowKey: (r) => r.id,
              loadMore: ListyLoadMore(
                onLoad: () => calls++,
                loading: loading,
                hasMore: hasMore,
              ),
              itemRender: (r, index) =>
                  SizedBox(height: 40, child: Text(r.name)),
            ),
          );

      await tester.pumpWidget(build(loading: true, hasMore: true));
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pump();
      expect(calls, 0, reason: 'a page is already in flight');
      expect(find.byType(Spinner), findsOneWidget);

      await tester.pumpWidget(build(loading: false, hasMore: false));
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pump();
      expect(calls, 0, reason: 'nothing left to fetch');
      expect(find.text('No more items'), findsOneWidget);
    });

    testWidgets('header follows the pull and fires onRefresh on release',
        (tester) async {
      var refreshes = 0;
      final seen = <double>[];
      await tester.pumpWidget(
        _host(
          Listy(
            height: 200,
            items: _rows(3),
            rowKey: (r) => r.id,
            header: ListyHeader(
              triggerExtent: 60,
              onRefresh: () async => refreshes++,
              builder: (context, pull) {
                seen.add(pull.extent);
                return SizedBox(
                  height: pull.refreshing ? 40 : pull.extent,
                  child: Text(pull.armed ? 'release' : 'pull'),
                );
              },
            ),
            itemRender: (r, index) => SizedBox(height: 40, child: Text(r.name)),
          ),
        ),
      );

      // Drag past the trigger and hold: the header sees the distance.
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Row 0')));
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();

      expect(
        seen.any((e) => e > 60),
        isTrue,
        reason: 'the header should be told how far it was pulled',
      );
      expect(find.text('release'), findsOneWidget);

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(refreshes, 1);
    });

    testWidgets('refreshes under bouncing physics too', (tester) async {
      var refreshes = 0;
      await tester.pumpWidget(
        _host(
          Listy(
            height: 200,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            items: _rows(3),
            rowKey: (r) => r.id,
            header: ListyHeader(
              triggerExtent: 60,
              onRefresh: () async => refreshes++,
              builder: (context, pull) => SizedBox(height: pull.extent),
            ),
            itemRender: (r, index) => SizedBox(height: 40, child: Text(r.name)),
          ),
        ),
      );

      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Row 0')));
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(refreshes, 1);
    });

    testWidgets('pulling back under the trigger calls the refresh off',
        (tester) async {
      for (final physics in <ScrollPhysics?>[
        null,
        const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      ]) {
        var refreshes = 0;
        ListyPull? last;
        await tester.pumpWidget(
          _host(
            Listy(
              height: 200,
              physics: physics,
              items: _rows(3),
              rowKey: (r) => r.id,
              header: ListyHeader(
                triggerExtent: 60,
                onRefresh: () async => refreshes++,
                builder: (context, pull) {
                  last = pull;
                  return SizedBox(height: pull.extent);
                },
              ),
              itemRender: (r, index) =>
                  SizedBox(height: 40, child: Text(r.name)),
            ),
          ),
        );

        final gesture =
            await tester.startGesture(tester.getCenter(find.text('Row 0')));
        await gesture.moveBy(const Offset(0, 120));
        await tester.pump();
        expect(last?.armed, isTrue, reason: 'physics: $physics');

        // Changed our mind. Bouncing physics resist the way back, so keep
        // going until the pull itself reports the refresh is off again.
        for (var i = 0; i < 12 && (last?.armed ?? false); i++) {
          await gesture.moveBy(const Offset(0, -40));
          await tester.pump();
        }
        expect(last?.armed, isFalse, reason: 'physics: $physics');

        await gesture.up();
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }

        expect(refreshes, 0, reason: 'physics: $physics');
      }
    });

    testWidgets('a short pull does not refresh', (tester) async {
      var refreshes = 0;
      await tester.pumpWidget(
        _host(
          Listy(
            height: 200,
            items: _rows(3),
            rowKey: (r) => r.id,
            header: ListyHeader(
              triggerExtent: 200,
              onRefresh: () async => refreshes++,
              builder: (context, pull) => SizedBox(height: pull.extent),
            ),
            itemRender: (r, index) => SizedBox(height: 40, child: Text(r.name)),
          ),
        ),
      );

      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Row 0')));
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));

      expect(refreshes, 0);
    });

    // A row keyed by a string id and sections keyed by an enum is ordinary, and
    // it only compiles while the two keys keep their own type parameters —
    // sharing one collapses both to Object.
    testWidgets('row and group keys keep their own types', (tester) async {
      final rows = [
        const _Row('id-0', 'Row 0', 'x'),
        const _Row('id-1', 'Row 1', 'x'),
      ];

      await tester.pumpWidget(
        _host(
          Listy(
            height: 200,
            items: rows,
            rowKey: (r) => r.id,
            groupKey: (r) => _Section.values[rows.indexOf(r) % 2],
            groupTitle: (section, items) => Text('S:${section.name}'),
            itemRender: (r, index) => Text(r.name),
          ),
        ),
      );

      expect(find.text('S:first'), findsOneWidget);
      expect(find.text('S:second'), findsOneWidget);
    });

    testWidgets('a pinned header coexists with sticky group headers',
        (tester) async {
      await tester.pumpWidget(
        _host(
          ConfigProvider(
            theme: ThemeData.light,
            components: const [ListyToken(itemPaddingBlock: 6)],
            child: Listy(
              height: 240,
              sticky: true,
              items: _rows(40),
              rowKey: (r) => r.id,
              header: ListyHeader(
                pinned: true,
                extent: 44,
                builder: (context, pull) => const Text('toolbar'),
              ),
              groupHeaderExtent: 40,
              groupKey: (r) => r.group,
              groupTitle: (key, items) => Text('G:$key'),
              itemRender: (r, index) => Text(r.name),
            ),
          ),
        ),
      );

      expect(find.text('toolbar'), findsOneWidget);
      final toolbarTop = tester.getTopLeft(find.text('toolbar')).dy;

      // Tokens from ConfigProvider reach the rows — checked before scrolling,
      // while the first row is still built.
      final container = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text('Row 0'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect((container.padding as EdgeInsets).top, 6);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump();

      // The toolbar stays put, and a section header pins under it.
      expect(
        tester.getTopLeft(find.text('toolbar')).dy,
        closeTo(toolbarTop, 1),
      );
      expect(find.textContaining('G:'), findsWidgets);
    });

    testWidgets('styles replace the row, header and root surfaces',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Listy(
            height: 240,
            items: _rows(6),
            rowKey: (r) => r.id,
            groupKey: (r) => r.group,
            groupTitle: (key, items) => Text('G:$key'),
            styles: const ListyStyles(
              root: BoxDecoration(color: Color(0xFF101010)),
              // An empty decoration is how the default hairline is dropped.
              item: BoxDecoration(),
              itemHovered: BoxDecoration(color: Color(0xFF202020)),
              groupHeader: BoxDecoration(color: Color(0xFF303030)),
              itemPadding: EdgeInsets.all(7),
              groupHeaderPadding: EdgeInsets.all(9),
            ),
            itemRender: (r, index) => Text(r.name),
          ),
        ),
      );

      final row = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text('Row 0'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(row.padding, const EdgeInsets.all(7));
      expect(
        (row.decoration as BoxDecoration).border,
        isNull,
        reason: 'the default hairline should be gone',
      );

      final header = tester.widget<Container>(
        find
            .ancestor(of: find.text('G:Even'), matching: find.byType(Container))
            .first,
      );
      expect(
        (header.decoration as BoxDecoration).color,
        const Color(0xFF303030),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              (w.decoration as BoxDecoration).color == const Color(0xFF101010),
        ),
        findsOneWidget,
      );
    });

    testWidgets('token overrides the row padding', (tester) async {
      await tester.pumpWidget(
        _host(
          Listy(
            height: 200,
            items: _rows(3),
            rowKey: (r) => r.id,
            token:
                const ListyToken(itemPaddingBlock: 30, itemPaddingInline: 40),
            itemRender: (r, index) => Text(r.name),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text('Row 0'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(
        container.padding,
        const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
      );
    });
  });
}
