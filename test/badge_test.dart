import 'package:flutter/material.dart'
    hide Badge, ThemeData, Checkbox, Radio, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

/// The pill and the dot are the only boxes the badge decorates, so finding a
/// decorated box under the badge is enough to say whether it drew one.
Iterable<BoxDecoration> _decorations(WidgetTester tester) => tester
    .widgetList<Container>(find.descendant(
      of: find.byType(Badge),
      matching: find.byType(Container),
    ))
    .map((c) => c.decoration)
    .whereType<BoxDecoration>();

/// The count is drawn a digit at a time, each in its own reel, so the number
/// has to be read back off the row rather than found whole.
String _number(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(of: find.byType(Badge), matching: find.byType(Text)),
    )
    .map((t) => t.data ?? '')
    .join();

void main() {
  group('Badge', () {
    testWidgets('a count of zero is left out, and shown when asked for', (
      tester,
    ) async {
      await tester
          .pumpWidget(_host(const Badge(count: 0, child: Icon(Icons.mail))));
      expect(find.text('0'), findsNothing);

      await tester.pumpWidget(
        _host(const Badge(count: 0, showZero: true, child: Icon(Icons.mail))),
      );
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('a count past the overflow reads as a ceiling, not a number', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const Badge(count: 100)));
      expect(_number(tester), '99+');

      // The boundary itself is still a number: 99 is not more than 99.
      await tester.pumpWidget(_host(const Badge(count: 99)));
      expect(_number(tester), '99');

      await tester.pumpWidget(_host(const Badge(count: 12, overflowCount: 9)));
      expect(_number(tester), '9+');
    });

    testWidgets('content stands in for the count, overflow and all', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Badge(count: 500, content: Text('new'))),
      );
      expect(find.text('new'), findsOneWidget);
      expect(_number(tester), 'new');
    });

    testWidgets('content needs no count to go with it', (tester) async {
      // The commoner way to use it, and the one that has no number to render.
      await tester.pumpWidget(
        _host(const Badge(content: Text('new'), child: Icon(Icons.mail))),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('new'), findsOneWidget);

      // Standalone too, where there is no child to fall back on either.
      await tester.pumpWidget(_host(const Badge(content: Text('beta'))));
      expect(tester.takeException(), isNull);
      expect(find.text('beta'), findsOneWidget);
    });

    testWidgets('a dot needs no count either', (tester) async {
      await tester.pumpWidget(
        _host(const Badge(dot: true, child: Icon(Icons.mail))),
      );
      expect(tester.takeException(), isNull);
    });

    group('the digits roll', () {
      /// Leaves the reels mid-roll, where both faces are on screen.
      Future<void> rollFrom(WidgetTester tester, int from, int to) async {
        await tester.pumpWidget(_host(Badge(count: from)));
        await tester.pumpWidget(_host(Badge(count: to)));
        await tester.pump(const Duration(milliseconds: 120));
      }

      testWidgets('a count that grows brings the new digit up from below', (
        tester,
      ) async {
        await rollFrom(tester, 5, 6);
        expect(_number(tester), contains('5'), reason: 'still on its way out');
        expect(
          tester.getTopLeft(find.text('6')).dy,
          greaterThan(tester.getTopLeft(find.text('5')).dy),
        );
        await tester.pumpAndSettle();
        expect(_number(tester), '6');
      });

      testWidgets('a count that shrinks brings it down from above', (
        tester,
      ) async {
        await rollFrom(tester, 6, 5);
        expect(
          tester.getTopLeft(find.text('5')).dy,
          lessThan(tester.getTopLeft(find.text('6')).dy),
        );
        await tester.pumpAndSettle();
        expect(_number(tester), '5');
      });

      testWidgets('ticking over rolls the units on, not nine back', (
        tester,
      ) async {
        await rollFrom(tester, 9, 10);
        // The units reel goes 9 to 0. Reduced to 0..9 that is nine steps
        // backwards; a counter ticking over takes one step forward, so the 0
        // must arrive from below like any other increase.
        expect(
          tester.getTopLeft(find.text('0')).dy,
          greaterThan(tester.getTopLeft(find.text('9')).dy),
        );
        await tester.pumpAndSettle();
        expect(_number(tester), '10');
      });

      testWidgets('at rest each place shows one digit and builds one', (
        tester,
      ) async {
        await tester.pumpWidget(_host(const Badge(count: 7)));
        await tester.pumpAndSettle();
        // The face rolling in is clipped, but it would still be read aloud.
        expect(_number(tester), '7');
      });
    });

    testWidgets('a rolling place never shifts its neighbours', (tester) async {
      // Every reel is a fixed cell, so the tens must not stir while the units
      // turn. Under the test font all digits measure the same and this would
      // hold either way; it is the proportional fonts it is written for.
      await tester.pumpWidget(_host(const Badge(count: 11)));
      await tester.pumpAndSettle();
      final tens = tester.getTopLeft(find.text('1').first);

      await tester.pumpWidget(_host(const Badge(count: 12)));
      for (final _ in [1, 2, 3]) {
        await tester.pump(const Duration(milliseconds: 80));
        expect(tester.getTopLeft(find.text('1').first), tens);
      }
      await tester.pumpAndSettle();
      expect(_number(tester), '12');
      expect(tester.getTopLeft(find.text('1')), tens);
    });

    testWidgets('a single digit keeps the pill round', (tester) async {
      await tester.pumpWidget(_host(const Badge(count: 7)));
      final round = tester.getSize(find.byType(Badge));
      expect(round.width, round.height);

      // A second digit is what earns the padding that makes it a lozenge.
      await tester.pumpWidget(_host(const Badge(count: 77)));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(Badge)).width,
        greaterThan(round.width),
      );
    });

    testWidgets('a badge on its way out keeps the count it was showing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Badge(count: 3, child: Icon(Icons.mail))),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _host(const Badge(count: 0, child: Icon(Icons.mail))),
      );
      await tester.pump(const Duration(milliseconds: 80));
      // Redrawing it as the 0 that hid it would set the reel rolling as it
      // left — a number changing while it goes, which it is not doing.
      expect(_number(tester), '3');
    });

    testWidgets('a count reaching zero retreats, and then is gone', (
      tester,
    ) async {
      // The pill is measured, not the ScaleTransition: a transform leaves the
      // box it wraps the size it always was, and only the painted rect shrinks.
      Rect pill() => tester.getRect(
            find
                .descendant(
                    of: find.byType(Badge), matching: find.byType(Container))
                .first,
          );

      await tester.pumpWidget(
        _host(const Badge(count: 1, child: Icon(Icons.mail))),
      );
      await tester.pumpAndSettle();
      final full = pill().height;

      await tester.pumpWidget(
        _host(const Badge(count: 0, child: Icon(Icons.mail))),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        pill().height,
        lessThan(full),
        reason: 'on its way out, not gone at a stroke',
      );

      await tester.pumpAndSettle();
      // And once out it must leave the tree: a badge scaled to nothing is
      // still read aloud.
      expect(_number(tester), isEmpty);
    });

    testWidgets('a dot says nothing', (tester) async {
      await tester.pumpWidget(
        _host(const Badge(dot: true, count: 7, child: Icon(Icons.mail))),
      );
      expect(find.text('7'), findsNothing);
      expect(
          _decorations(tester).any((d) => d.shape == BoxShape.circle), isTrue);
    });

    testWidgets('without a child the badge is the whole widget', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const Badge(count: 5)));
      // Nothing to pin it to, so nothing is offset into a corner.
      expect(
        find.descendant(
          of: find.byType(Badge),
          matching: find.byType(FractionalTranslation),
        ),
        findsNothing,
      );
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('with nothing to say it takes no room', (tester) async {
      await tester.pumpWidget(_host(const Badge()));
      expect(tester.getSize(find.byType(Badge)), Size.zero);
    });

    testWidgets('a status draws its dot, and its text beside it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Badge(status: BadgeStatus.success, text: Text('Live'))),
      );
      expect(find.text('Live'), findsOneWidget);

      final dot =
          _decorations(tester).firstWhere((d) => d.shape == BoxShape.circle);
      expect(dot.color, isNotNull);
      // A status dot sits flush in a line of text: no ring around it.
      expect(dot.border, isNull);
    });

    testWidgets('a processing status keeps a ring running, and stops it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Badge(status: BadgeStatus.processing, text: Text('Busy'))),
      );
      // A repeating animation never settles; pumpAndSettle would time out.
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.descendant(
          of: find.byType(Badge),
          matching: find.byType(ScaleTransition),
        ),
        findsOneWidget,
      );

      // Tearing it down must not leave the ticker running.
      await tester.pumpWidget(_host(const SizedBox.shrink()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('colour overrides the fill, for a status as for a count', (
      tester,
    ) async {
      const cyan = Color(0xFF13C2C2);
      await tester.pumpWidget(_host(const Badge(count: 3, color: cyan)));
      expect(_decorations(tester).map((d) => d.color), contains(cyan));

      await tester.pumpWidget(
        _host(const Badge(status: BadgeStatus.error, color: cyan)),
      );
      expect(_decorations(tester).map((d) => d.color), contains(cyan));
    });

    testWidgets('small is shorter than the default', (tester) async {
      await tester.pumpWidget(_host(const Badge(count: 8)));
      final tall = tester.getSize(find.byType(Badge)).height;

      await tester
          .pumpWidget(_host(const Badge(count: 8, size: SoftSize.small)));
      expect(tester.getSize(find.byType(Badge)).height, lessThan(tall));
    });

    testWidgets('a title is what assistive technology hears', (tester) async {
      await tester.pumpWidget(
        _host(const Badge(count: 120, title: '120 unread messages')),
      );
      expect(
        find.bySemanticsLabel('120 unread messages'),
        findsOneWidget,
        reason: 'the raw "99+" is not what the count means',
      );
    });

    testWidgets('tokens come from the provider, and the instance wins', (
      tester,
    ) async {
      const fromProvider = Color(0xFF722ED1);
      const fromInstance = Color(0xFFFA8C16);

      Widget under(BadgeToken? instance) => ConfigProvider(
            theme: ThemeData(
              components:
                  const ComponentsConfig(badge: BadgeToken(bg: fromProvider)),
            ),
            child: _host(Badge(count: 1, token: instance)),
          );

      await tester.pumpWidget(under(null));
      expect(_decorations(tester).map((d) => d.color), contains(fromProvider));

      await tester.pumpWidget(under(const BadgeToken(bg: fromInstance)));
      expect(_decorations(tester).map((d) => d.color), contains(fromInstance));
    });
  });

  group('Ribbon', () {
    testWidgets('the band hangs off the end it was given', (tester) async {
      Future<double> bandCentre(RibbonPlacement placement) async {
        await tester.pumpWidget(
          _host(
            SizedBox(
              width: 300,
              height: 120,
              child: Ribbon(
                placement: placement,
                text: const Text('Hot'),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
        return tester.getCenter(find.text('Hot')).dx;
      }

      final atEnd = await bandCentre(RibbonPlacement.end);
      final atStart = await bandCentre(RibbonPlacement.start);
      final middle = tester.getCenter(find.byType(Ribbon)).dx;

      expect(atEnd, greaterThan(middle));
      expect(atStart, lessThan(middle));
    });

    testWidgets('the fold sits under the band, on its outer side', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 200,
            height: 100,
            child: Ribbon(text: Text('Sale'), child: SizedBox.expand()),
          ),
        ),
      );

      final fold = find.descendant(
        of: find.byType(Ribbon),
        matching: find.byType(CustomPaint),
      );
      expect(fold, findsWidgets, reason: 'the fold is painted, not decorated');

      final band = tester.getRect(find.text('Sale'));
      final tail = tester.getRect(fold.last);
      // Below the band — it is the band turning the corner, not a second
      // label beside it.
      expect(tail.top, greaterThanOrEqualTo(band.bottom - 1));
      // And hard against the trailing end, which is the end it runs off.
      expect(tail.right, greaterThan(band.right));
    });

    testWidgets('tokens come from the provider, and the instance wins', (
      tester,
    ) async {
      const fromProvider = Color(0xFF722ED1);
      const fromInstance = Color(0xFFFA8C16);

      Color bandColour() => tester
          .widgetList<Container>(find.descendant(
            of: find.byType(Ribbon),
            matching: find.byType(Container),
          ))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .first
          .color!;

      Widget under(RibbonToken? instance) => ConfigProvider(
            theme: ThemeData(
              components:
                  const ComponentsConfig(ribbon: RibbonToken(bg: fromProvider)),
            ),
            child: _host(
              SizedBox(
                width: 200,
                height: 100,
                child: Ribbon(
                  token: instance,
                  text: const Text('x'),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          );

      await tester.pumpWidget(under(null));
      expect(bandColour(), fromProvider);

      await tester.pumpWidget(under(const RibbonToken(bg: fromInstance)));
      expect(bandColour(), fromInstance);
    });
  });
}
