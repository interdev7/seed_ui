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
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('100'), findsNothing);

      // The boundary itself is still a number: 99 is not more than 99.
      await tester.pumpWidget(_host(const Badge(count: 99)));
      expect(find.text('99'), findsOneWidget);

      await tester.pumpWidget(_host(const Badge(count: 12, overflowCount: 9)));
      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('content stands in for the count, overflow and all', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Badge(count: 500, content: Text('new'))),
      );
      expect(find.text('new'), findsOneWidget);
      expect(find.text('99+'), findsNothing);
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
      // Nothing to pin it to, so no stacking: the badge is drawn plainly.
      expect(
        find.descendant(of: find.byType(Badge), matching: find.byType(Stack)),
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
