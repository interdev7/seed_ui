// Renders the package's pub.dev screenshots.
//
// Not a test — a test file only because `flutter test` is the one place a
// Flutter widget tree can be laid out, painted and read back as pixels
// without a device. It asserts nothing; it writes PNGs next to itself and
// `tool/shoot.sh` turns them into the WebPs pubspec.yaml points at.
//
//     ./tool/shoot.sh
//
// Every shot is the same scene twice, light beside dark, at the same size as
// the ones already in doc/screenshots: a pair in one slot rather than two
// slots, and a shape the gallery can render.
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' as m;
// ignore: implementation_imports
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter/widgets.dart' hide Form, Table, TableRow;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// The size of one half, in logical pixels, unless a shot names its own.
/// Doubled for the pair, and doubled again by the pixel ratio.
const _half = Size(644, 700);
const _ratio = 2.0;

/// Where the PNGs land.
const _out = 'tool/screenshots/out';

final _art = GlobalKey();

/// Real letters instead of the test font's black boxes.
///
/// `flutter test` ships a font whose every glyph is a filled rectangle, which
/// is right for layout tests and useless for a picture. These are the fonts
/// the machine already has; the shots are images, so which face they were
/// drawn with matters only to how they look.
Future<void> loadFonts() async {
  const faces = {
    'Arial': [
      ('/System/Library/Fonts/Supplemental/Arial.ttf', FontWeight.w400),
      ('/System/Library/Fonts/Supplemental/Arial Bold.ttf', FontWeight.w700),
    ],
  };
  for (final entry in faces.entries) {
    final loader = FontLoader(entry.key);
    for (final (path, _) in entry.value) {
      final file = File(path);
      if (!file.existsSync()) {
        throw StateError('no font at $path — shots would be black boxes');
      }
      loader.addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
    }
    await loader.load();
  }
}

/// One scene, shot once in each theme.
///
/// One app at a time rather than two side by side: a panel opens into the
/// overlay held by [UiKit.navigatorKey], and a key belongs to one app. The
/// two halves are joined into a single picture by `tool/shoot.sh`.
Future<void> shoot(
  WidgetTester tester,
  String name,
  Widget Function() scene, {
  Future<void> Function(WidgetTester tester)? after,
  Size size = _half,
}) async {
  await loadFonts();
  tester.view.physicalSize = size * _ratio;
  tester.view.devicePixelRatio = _ratio;
  addTearDown(tester.view.reset);

  for (final dark in [false, true]) {
    // A clean tree between the two: the overlay a panel opens into hangs off
    // a navigator that is a global key, and the second pump found the first
    // one's leavings — the dark half came out with its panel shut.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      RepaintBoundary(
        key: _art,
        child: ConfigProvider(
          theme: ThemeData(
            token: const SeedToken(fontFamily: 'Arial'),
            dark: dark,
          ),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Builder(
              builder: (context) => m.MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ConfigProvider.of(context).token.materialTheme,
                navigatorKey: UiKit.navigatorKey,
                home: Builder(
                  builder: (context) => m.Scaffold(
                    backgroundColor: context.softToken.colorBgLayout,
                    body: Padding(
                      padding: const EdgeInsets.all(24),
                      child: scene(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (after != null) {
      await after(tester);
      await tester.pumpAndSettle();
    }

    final boundary =
        _art.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    // Encoding is real async work, so it has to run outside the fake clock or
    // the future never completes.
    final bytes = (await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: _ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    }))!;

    Directory(_out).createSync(recursive: true);
    File('$_out/$name.${dark ? 'dark' : 'light'}.png').writeAsBytesSync(bytes);
  }
}

class _Order {
  const _Order(this.ref, this.customer, this.city, this.total, this.status);
  final String ref;
  final String customer;
  final String city;
  final int total;
  final String status;
}

const _orders = [
  _Order('SD-1041', 'Marguerite Yates', 'Lisbon', 1240, 'Paid'),
  _Order('SD-1042', 'Ines Kaminski', 'Kraków', 380, 'Pending'),
  _Order('SD-1043', 'Tomás Rivera', 'Valencia', 2610, 'Paid'),
  _Order('SD-1044', 'Ada Nwosu', 'Lagos', 95, 'Refunded'),
  _Order('SD-1045', 'Jun Watanabe', 'Sapporo', 1875, 'Paid'),
];

void main() {
  testWidgets('table', (tester) async {
    await shoot(
      tester,
      'table',
      size: const Size(700, 340),
      () => Table<_Order>(
        data: _orders,
        rowKey: (o) => o.ref,
        bordered: true,
        pagination: const TablePagination(defaultPageSize: 5, total: 43),
        selection: TableSelection<_Order>(
          defaultSelected: [_orders[2]],
        ),
        columns: [
          TableColumn(
            title: const Text('Order'),
            value: (o) => o.ref,
            width: 100,
            fixed: TableColumnFixed.start,
          ),
          TableColumn(
            title: const Text('Customer'),
            value: (o) => o.customer,
            sorter: (a, b) => a.customer.compareTo(b.customer),
          ),
          TableColumn(
            title: const Text('Total'),
            value: (o) => o.total,
            align: TableAlign.end,
            sorter: (a, b) => a.total.compareTo(b.total),
            summary: (context, rows) => const Text('€6 200'),
          ),
          TableColumn(
            title: const Text('Status'),
            value: (o) => o.status,
            width: 124,
            filters: const [
              TableFilter('Paid', 'Paid'),
              TableFilter('Pending', 'Pending'),
              TableFilter('Refunded', 'Refunded'),
            ],
            onFilter: (value, o) => o.status == value,
            builder: (context, o, i) => Tag(
              color: switch (o.status) {
                'Paid' => TagColor.success,
                'Pending' => TagColor.warning,
                _ => TagColor.defaultColor,
              },
              child: Text(o.status),
            ),
            summary: (context, rows) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  });

  testWidgets('date picker', (tester) async {
    await shoot(
      tester,
      'date_picker',
      size: const Size(560, 380),
      () => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 300,
          child: DatePicker(
            defaultValue: DateTime(2026, 4, 17),
            showToday: true,
            presets: [
              DatePreset.of('Today', () => DateTime(2026, 4, 17)),
              DatePreset.of('In a week', () => DateTime(2026, 4, 24)),
              DatePreset.of('Month end', () => DateTime(2026, 4, 30)),
            ],
          ),
        ),
      ),
      after: (tester) async {
        // The picture is the panel; a closed field says nothing about it.
        await tester.tap(find.byType(DatePicker));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('form', (tester) async {
    await shoot(
      tester,
      'form',
      size: const Size(560, 420),
      () => Form(
        layout: FormLayout.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormItem.text(
              name: 'name',
              label: const Text('Full name'),
              initialValue: 'Marguerite Yates',
              rules: const [FormRule.required()],
            ),
            FormItem.text(
              name: 'email',
              label: const Text('Email'),
              initialValue: 'marguerite@',
              rules: const [FormRule.email()],
            ),
            FormItem.select<String>(
              name: 'plan',
              label: const Text('Plan'),
              initialValue: 'team',
              options: const [
                SelectOption(value: 'solo', label: Text('Solo')),
                SelectOption(value: 'team', label: Text('Team')),
              ],
            ),
            FormItem.toggle(
              name: 'digest',
              label: const Text('Weekly digest'),
              initialValue: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Button(
                  color: ButtonColor.primary,
                  variant: ButtonVariant.solid,
                  onPressed: () {},
                  child: const Text('Save changes'),
                ),
                const SizedBox(width: 8),
                Button(onPressed: () {}, child: const Text('Cancel')),
              ],
            ),
          ],
        ),
      ),
    );
  });

  testWidgets('slider', (tester) async {
    await shoot(
      tester,
      'slider',
      size: const Size(560, 250),
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Slider(
            defaultValue: 62,
            marks: const [
              SliderMark(0, '0°'),
              SliderMark(50, '50°'),
              SliderMark(100, '100°'),
            ],
            zones: const [SliderZone(80, 100)],
            onChanged: (_) {},
          ),
          const SizedBox(height: 34),
          RangeSlider(
            defaultValues: const (25, 70),
            draggableTrack: true,
            onChanged: (_) {},
          ),
          const SizedBox(height: 28),
          MultiRangeSlider(
            defaultValues: const [10, 35, 60, 85],
            onChanged: (_) {},
          ),
        ],
      ),
    );
  });
}
