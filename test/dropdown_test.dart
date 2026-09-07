import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      navigatorKey: UiKit.navigatorKey,
      home: Scaffold(body: Center(child: child)),
    );

const List<DropdownEntry<String>> _menu = [
  DropdownItem(value: 'edit', label: 'Edit'),
  DropdownDivider(),
  DropdownItem(value: 'delete', label: 'Delete', danger: true),
  DropdownItem(value: 'off', label: 'Off', disabled: true),
];

enum _Action { edit, remove }

void main() {
  testWidgets('a menu types itself from its items', (tester) async {
    // Nothing below names a type, and what comes back is an _Action rather
    // than an Object? to be interrogated at the other end.
    _Action? tapped;
    await tester.pumpWidget(
      _host(
        Dropdown(
          trigger: const [DropdownTrigger.click],
          open: true,
          menu: const [
            DropdownItem(value: _Action.edit, label: 'Edit'),
            DropdownItem(value: _Action.remove, label: 'Delete'),
          ],
          onItemTap: (value) => tapped = value,
          child: const Text('Open'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(tapped, _Action.remove);
  });

  testWidgets('a divider asks for the type to be named once', (tester) async {
    // A divider carries no value, and Dart settles a list's element type
    // before the menu's, so a mixed literal has nothing to go on and falls to
    // Object. Naming the type on the Dropdown puts it back — one place, and
    // the items and the handler are checked against it from there.
    _Action? tapped;
    await tester.pumpWidget(
      _host(
        Dropdown<_Action>(
          trigger: const [DropdownTrigger.click],
          open: true,
          menu: const [
            DropdownItem(value: _Action.edit, label: 'Edit'),
            DropdownDivider(),
            DropdownItem(value: _Action.remove, label: 'Delete'),
          ],
          onItemTap: (value) => tapped = value,
          child: const Text('Open'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(tapped, _Action.remove);
  });

  test('a submenu carries its parent\'s type', () {
    const menu = <DropdownEntry<_Action>>[
      DropdownItem(
        value: _Action.edit,
        children: [DropdownItem(value: _Action.remove)],
      ),
    ];
    final parent = menu.first as DropdownItem<_Action>;
    expect(parent.children!.first, isA<DropdownItem<_Action>>());
  });

  testWidgets('click trigger opens the menu and reports the tapped key',
      (tester) async {
    Object? tapped;
    await tester.pumpWidget(
      _host(
        Dropdown(
          trigger: const [DropdownTrigger.click],
          menu: _menu,
          onItemTap: (k) => tapped = k,
          child: const Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(tapped, 'delete');
    // Closed after selecting.
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('a disabled item does not fire or close', (tester) async {
    Object? tapped;
    await tester.pumpWidget(
      _host(
        Dropdown(
          trigger: const [DropdownTrigger.click],
          menu: _menu,
          onItemTap: (k) => tapped = k,
          child: const Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    expect(tapped, isNull);
    expect(find.text('Edit'), findsOneWidget); // still open
  });

  testWidgets('an outside tap closes a click menu', (tester) async {
    await tester.pumpWidget(
      _host(
        const Dropdown(
          trigger: [DropdownTrigger.click],
          menu: _menu,
          child: Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('popupRender wraps the default menu', (tester) async {
    await tester.pumpWidget(
      _host(
        Dropdown(
          trigger: const [DropdownTrigger.click],
          menu: _menu,
          popupRender: (context, menu) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [menu, const Text('Footer')],
          ),
          child: const Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    // Both the default menu and the appended footer render.
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Footer'), findsOneWidget);
  });

  testWidgets('menu updates live while open, without reopening',
      (tester) async {
    Widget build(List<String> items) => _host(
          Dropdown(
            trigger: const [],
            open: true,
            menu: [
              for (final i in items) DropdownItem(value: i, label: i),
            ],
            child: const Text('Open'),
          ),
        );

    await tester.pumpWidget(build(['One']));
    await tester.pumpAndSettle();
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsNothing);

    // Grow the menu while it stays open; the overlay must reflect it at once.
    await tester.pumpWidget(build(['One', 'Two']));
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsOneWidget);
  });

  testWidgets('custom content renders and can close itself', (tester) async {
    await tester.pumpWidget(
      _host(
        // Never: built from content, so it has no items and no value to
        // report.
        Dropdown<Never>(
          trigger: const [DropdownTrigger.click],
          content: (context, close) => DropdownPanel(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: close,
                child: const Text('Custom body'),
              ),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Custom body'), findsOneWidget);

    await tester.tap(find.text('Custom body'));
    await tester.pumpAndSettle();
    expect(find.text('Custom body'), findsNothing);
  });
  group('a submenu parent', () {
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }

    /// The direction comes from the app's locale, as it does in a real one.
    /// Wrapping `home` in a Directionality would not reach the menu: it is
    /// drawn in the navigator's overlay, above anything inside `home`.
    Widget host(TextDirection direction) => MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          locale: Locale(direction == TextDirection.rtl ? 'ar' : 'en'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ar')],
          home: Scaffold(
            body: Center(
              // Keyed by direction: without it the same element is reused between
              // runs and carries its open state across.
              child: Dropdown(
                key: ValueKey(direction),
                trigger: const [DropdownTrigger.click],
                menu: const [
                  DropdownItem(
                    value: 'more',
                    label: 'More',
                    children: [DropdownItem(value: 'help', label: 'Help')],
                  ),
                ],
                child: const Text('open'),
              ),
            ),
          ),
        );

    testWidgets('opens on a tap, since a touch screen cannot hover', (
      tester,
    ) async {
      await tester.pumpWidget(host(TextDirection.ltr));
      await tester.tap(find.text('open'));
      await settle(tester);
      expect(find.text('More'), findsOneWidget);

      await tester.tap(find.text('More'));
      await settle(tester);
      expect(find.text('Help'), findsOneWidget);

      // And tapping again puts it away.
      await tester.tap(find.text('More'));
      await settle(tester);
      expect(find.text('Help'), findsNothing);
    });

    Future<double> submenuVsParent(
      WidgetTester tester,
      TextDirection direction,
    ) async {
      await tester.pumpWidget(host(direction));
      await tester.tap(find.text('open'));
      await settle(tester);
      expect(find.text('More'), findsOneWidget, reason: 'the menu opened');
      await tester.tap(find.text('More'));
      await settle(tester);
      return tester.getCenter(find.text('Help')).dx -
          tester.getCenter(find.text('More')).dx;
    }

    testWidgets('opens to the right when the menu reads that way', (
      tester,
    ) async {
      expect(
        await submenuVsParent(tester, TextDirection.ltr),
        greaterThan(0),
      );
    });

    testWidgets('and to the left when it reads the other', (tester) async {
      // Out to the side the menu reads towards, so it opens away from the
      // parent rather than back over it.
      expect(await submenuVsParent(tester, TextDirection.rtl), lessThan(0));
    });
  });

  group('drawing a row yourself', () {
    testWidgets('the builder draws every row, submenus included',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Dropdown<String>(
            trigger: const [],
            open: true,
            menu: const [
              DropdownItem(
                value: 'more',
                label: 'More',
                children: [DropdownItem(value: 'help', label: 'Help')],
              ),
            ],
            itemBuilder: (context, item, hovered) => Text('<${item.label}>'),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('<More>'), findsOneWidget);
      expect(find.text('More'), findsNothing);

      await tester.tap(find.text('<More>'));
      await tester.pumpAndSettle();
      expect(find.text('<Help>'), findsOneWidget);
    });

    testWidgets('the builder is told the pointer is over the row',
        (tester) async {
      await tester.pumpWidget(
        _host(
          Dropdown<String>(
            trigger: const [],
            open: true,
            menu: const [DropdownItem(value: 'edit', label: 'Edit')],
            itemBuilder: (context, item, hovered) =>
                Text(hovered ? 'over' : 'away'),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('away'), findsOneWidget);

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('away'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('over'), findsOneWidget);
    });

    testWidgets('a built row is dressed like any other', (tester) async {
      await tester.pumpWidget(
        _host(
          Dropdown<String>(
            trigger: const [],
            open: true,
            menu: const [
              DropdownItem(value: 'off', label: 'Off', disabled: true),
            ],
            itemBuilder: (context, item, hovered) => Text(item.label ?? ''),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The colour comes from the row around the builder, so a builder that
      // returns bare words still greys out when the item is barred.
      final style = tester.widget<Text>(find.text('Off')).style;
      final merged = DefaultTextStyle.of(
        tester.element(find.text('Off')),
      ).style;
      expect(style?.color ?? merged.color, isNotNull);
      expect(
        style?.color ?? merged.color,
        ThemeData().token.colorTextQuaternary,
      );
    });

    testWidgets('without a builder the menu draws the words it was given',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const Dropdown<String>(
            trigger: [],
            open: true,
            menu: [DropdownItem(value: 'edit', label: 'Edit')],
            child: Text('Open'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('a long label is cut rather than overflowing', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 120,
            child: Dropdown<String>(
              trigger: [],
              open: true,
              menu: [
                DropdownItem(
                  value: 'x',
                  label: 'A label far too long for the room it is given',
                ),
              ],
              child: Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(
        find.text('A label far too long for the room it is given'),
      );
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.maxLines, 1);
    });
  });

  group('a token on the dropdown itself', () {
    Future<void> open(WidgetTester tester, DropdownToken? token) =>
        tester.pumpWidget(
          _host(
            Dropdown<String>(
              trigger: const [],
              open: true,
              token: token,
              menu: const [DropdownItem(value: 'a', label: 'A')],
              child: const Text('Open'),
            ),
          ),
        );

    BoxDecoration panel(WidgetTester tester) => tester
        .widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(DropdownPanel),
                matching: find.byType(DecoratedBox),
              )
              .first,
        )
        .decoration as BoxDecoration;

    testWidgets('rounds the panel it belongs to', (tester) async {
      await open(tester, null);
      await tester.pumpAndSettle();
      final byDefault = (panel(tester).borderRadius! as BorderRadius).topLeft.x;

      await open(tester, const DropdownToken(borderRadius: 20));
      await tester.pumpAndSettle();
      expect((panel(tester).borderRadius! as BorderRadius).topLeft.x, 20);
      expect(byDefault, isNot(20));
    });

    testWidgets('colours the panel it belongs to', (tester) async {
      await open(tester, const DropdownToken(menuBg: Color(0xFF00FF00)));
      await tester.pumpAndSettle();
      expect(panel(tester).color, const Color(0xFF00FF00));
    });

    testWidgets('insets the menu by the padding it names', (tester) async {
      await open(tester, const DropdownToken(padding: EdgeInsets.all(17)));
      await tester.pumpAndSettle();
      final padding = tester.widgetList<Padding>(
        find.descendant(
          of: find.byType(DropdownMenuList<String>),
          matching: find.byType(Padding),
        ),
      );
      expect(
        padding.map((p) => p.padding),
        contains(const EdgeInsets.all(17)),
      );
    });

    testWidgets('paints the hovered row the colour it names', (tester) async {
      await open(tester, const DropdownToken(itemHoverBg: Color(0xFF0000FF)));
      await tester.pumpAndSettle();
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('A'))),
      );
      await tester.pumpAndSettle();
      final row = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text('A'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(
        (row.decoration! as BoxDecoration).color,
        const Color(0xFF0000FF),
      );
    });

    testWidgets('reaches a submenu as well', (tester) async {
      await tester.pumpWidget(
        _host(
          const Dropdown<String>(
            trigger: [],
            open: true,
            token: DropdownToken(menuBg: Color(0xFF00FF00)),
            menu: [
              DropdownItem(
                value: 'more',
                label: 'More',
                children: [DropdownItem(value: 'help', label: 'Help')],
              ),
            ],
            child: Text('Open'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      final panels = tester.widgetList<DropdownPanel>(
        find.byType(DropdownPanel),
      );
      expect(panels.length, 2);
      expect(
        panels.every((p) => p.token?.menuBg == const Color(0xFF00FF00)),
        isTrue,
      );
    });
  });

  group('a surface of your own', () {
    const blank = DropdownToken(
      menuBg: Color(0x00000000),
      borderRadius: 0,
      shadow: [],
    );

    Future<void> open(WidgetTester tester, DropdownToken? token) =>
        tester.pumpWidget(
          _host(
            Dropdown<String>(
              trigger: const [],
              open: true,
              token: token,
              menu: const [DropdownItem(value: 'a', label: 'A')],
              popupRender: (context, menu) => DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFFFF00FF)),
                child: menu,
              ),
              child: const Text('Open'),
            ),
          ),
        );

    BoxDecoration panel(WidgetTester tester) => tester
        .widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(DropdownPanel),
                matching: find.byType(DecoratedBox),
              )
              .first,
        )
        .decoration as BoxDecoration;

    testWidgets('the chrome casts nothing when told to cast nothing',
        (tester) async {
      await open(tester, null);
      await tester.pumpAndSettle();
      expect(panel(tester).boxShadow, isNotEmpty);

      await open(tester, blank);
      await tester.pumpAndSettle();
      final blanked = panel(tester);
      expect(blanked.boxShadow, isEmpty);
      expect(blanked.color, const Color(0x00000000));
      expect((blanked.borderRadius! as BorderRadius).topLeft.x, 0);
    });

    testWidgets('a blanked panel does not clip what was drawn in its place',
        (tester) async {
      await open(tester, blank);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(DropdownPanel),
          matching: find.byType(ClipRRect),
        ),
        findsNothing,
      );
      // The caller's own surface is still there, and so is the menu in it.
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('a rounded panel still clips its rows', (tester) async {
      await open(tester, null);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(DropdownPanel),
          matching: find.byType(ClipRRect),
        ),
        findsOneWidget,
      );
    });
  });

  group('one look for every menu', () {
    // What a design says once, on the provider, rather than at each call.
    const house = ComponentsConfig(
      dropdown: DropdownToken(
        menuBg: Color(0xFFEFF6FF),
        borderRadius: 20,
        border: BorderSide(color: Color(0xFF93C5FD)),
        shadow: [BoxShadow(color: Color(0x3D2563EB), blurRadius: 24)],
      ),
    );

    testWidgets('a panel wears what the provider dressed it in',
        (tester) async {
      // The provider sits *inside* the app, below the overlay the menu is
      // mounted in: what a screen says about its own menus has to reach them.
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: Scaffold(
            body: ConfigProvider(
              theme: ThemeData(components: house),
              child: const Center(
                child: Dropdown<String>(
                  trigger: [],
                  open: true,
                  menu: [DropdownItem(value: 'a', label: 'A')],
                  child: Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final d = tester
          .widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(DropdownPanel),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .decoration as BoxDecoration;
      expect(d.color, const Color(0xFFEFF6FF));
      expect((d.borderRadius! as BorderRadius).topLeft.x, 20);
      expect(
          d.border,
          const Border.fromBorderSide(
            BorderSide(color: Color(0xFF93C5FD)),
          ));
      expect(d.boxShadow, isNotEmpty);
    });

    testWidgets('no border unless one is asked for', (tester) async {
      await tester.pumpWidget(
        _host(
          const Dropdown<String>(
            trigger: [],
            open: true,
            menu: [DropdownItem(value: 'a', label: 'A')],
            child: Text('Open'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final d = tester
          .widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(DropdownPanel),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .decoration as BoxDecoration;
      expect(d.border, isNull);
    });
  });

  group('a submenu', () {
    Widget tree(Widget child) => MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: Scaffold(body: Center(child: child)),
        );

    const nested = [
      DropdownItem(
        value: 'more',
        label: 'More',
        children: [DropdownItem(value: 'help', label: 'Help')],
      ),
    ];

    Future<void> openBoth(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
    }

    List<BoxDecoration> panels(WidgetTester tester) => tester
        .widgetList<DropdownPanel>(find.byType(DropdownPanel))
        .map(
          (p) => tester
              .widget<DecoratedBox>(
                find
                    .descendant(
                      of: find.byWidget(p),
                      matching: find.byType(DecoratedBox),
                    )
                    .first,
              )
              .decoration as BoxDecoration,
        )
        .toList();

    testWidgets('is dressed by the provider its parent stood in',
        (tester) async {
      await tester.pumpWidget(
        tree(
          ConfigProvider(
            theme: ThemeData(
              components: const ComponentsConfig(
                dropdown: DropdownToken(menuBg: Color(0xFF123456)),
              ),
            ),
            child: const Dropdown<String>(
              trigger: [],
              open: true,
              menu: nested,
              child: Text('Open'),
            ),
          ),
        ),
      );
      await openBoth(tester);
      final seen = panels(tester);
      expect(seen.length, 2);
      expect(
        seen.every((d) => d.color == const Color(0xFF123456)),
        isTrue,
        reason: 'both the menu and the submenu wear it',
      );
    });

    testWidgets('stands off the panel it came from, not the row inside it',
        (tester) async {
      // A row is inset from the panel by its padding. Counted from the row, a
      // gap is that much smaller than it reads, and a padding wider than the
      // gap drops the submenu on top of the menu it came from.
      Future<double> clearance(double gap) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          tree(
            Dropdown<String>(
              trigger: const [],
              open: true,
              token: DropdownToken(gap: gap, padding: const EdgeInsets.all(12)),
              menu: nested,
              child: const Text('Open'),
            ),
          ),
        );
        await openBoth(tester);
        final panels = find.byType(DropdownPanel);
        return tester.getRect(panels.at(1)).left -
            tester.getRect(panels.at(0)).right;
      }

      expect(await clearance(0), moreOrLessEquals(0, epsilon: 0.01));
      expect(await clearance(4), moreOrLessEquals(4, epsilon: 0.01));
      expect(await clearance(40), moreOrLessEquals(40, epsilon: 0.01));
    });

    testWidgets('lines up with the row it belongs to', (tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        tree(
          const Dropdown<String>(
            trigger: [],
            open: true,
            // Rows above it, so a submenu pinned to the top of the panel
            // instead of to its own row is plain to see.
            menu: [
              DropdownItem(value: 'one', label: 'One'),
              DropdownItem(value: 'two', label: 'Two'),
              DropdownItem(value: 'three', label: 'Three'),
              ...nested,
            ],
            child: Text('Open'),
          ),
        ),
      );
      await openBoth(tester);
      // Measured from the panel sideways, but still level with its own row:
      // taking the panel's rect wholesale would have pinned it to the top of
      // the menu instead.
      final parent = tester.getRect(find.byType(DropdownPanel).at(0));
      final sub = tester.getRect(find.byType(DropdownPanel).at(1));
      final row = tester.getRect(find.text('More'));
      expect(sub.top, moreOrLessEquals(row.top, epsilon: 12));
      expect(sub.left, greaterThanOrEqualTo(parent.right));
    });

    testWidgets('the menu itself stands off its trigger by the same word',
        (tester) async {
      Future<double> distance(double gap) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          tree(
            Dropdown<String>(
              trigger: const [],
              open: true,
              token: DropdownToken(gap: gap),
              menu: const [DropdownItem(value: 'a', label: 'A')],
              child: const Text('Open'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getRect(find.byType(DropdownPanel)).top -
            tester.getRect(find.text('Open')).bottom;
      }

      expect(await distance(40) - await distance(0),
          moreOrLessEquals(40, epsilon: 0.5));
    });
  });

  testWidgets('a gradient in the token washes every panel of the menu',
      (tester) async {
    const wash = LinearGradient(colors: [Color(0xFF112233), Color(0xFF445566)]);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: Scaffold(
          body: Center(
            child: ConfigProvider(
              theme: ThemeData(
                components: const ComponentsConfig(
                  dropdown: DropdownToken(gradient: wash),
                ),
              ),
              child: const Dropdown<String>(
                trigger: [],
                open: true,
                menu: [
                  DropdownItem(
                    value: 'more',
                    label: 'More',
                    children: [DropdownItem(value: 'help', label: 'Help')],
                  ),
                ],
                child: Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    final washes = tester
        .widgetList<DropdownPanel>(find.byType(DropdownPanel))
        .map(
          (p) => (tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byWidget(p),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration as BoxDecoration)
              .gradient,
        )
        .toList();
    expect(washes.length, 2);
    expect(washes.every((g) => g == wash), isTrue);
  });
}
