/// The machinery behind the package's screenshots.
///
/// Not a test — a library only a test can use, because `flutter test` is the
/// one place a Flutter widget tree can be laid out, painted and read back as
/// pixels without a device. `shoot_test.dart` draws the pictures pub.dev
/// shows; `audit_test.dart` draws the rest of the kit to be looked at.
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
/// Where the PNGs land. Set it before shooting to put them elsewhere.
String outDir = 'tool/screenshots/out';

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
  bool settle = true,
}) async {
  // `flutter_test` turns blur off so goldens stay stable across platforms,
  // which draws every shadow as a hard-edged slab. Right for a test, wrong
  // for a picture: a panel came out sitting on three grey rectangles. Put
  // back at the end, or the harness fails the framework's own invariants.
  debugDisableShadows = false;

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
    // A scene that never stops moving — a spinner, a countdown — cannot be
    // settled, so it is simply given a few frames to get going.
    Future<void> rest() async {
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 240));
      }
    }

    await rest();
    if (after != null) {
      await after(tester);
      await rest();
    }

    // A picture that runs off the bottom of its frame shows the reader half a
    // component and says nothing about the rest. Asked of the scene rather
    // than of my eyes: if the scene's own scroll view can be scrolled, it is
    // taller than the size it was given.
    //
    // Its own, not every one: a `Listy` in a box of its own is *meant* to
    // scroll, and flagging it would be flagging the thing being photographed.
    final scrollables = tester.stateList<ScrollableState>(
      find.byType(Scrollable),
    );
    if (scrollables.isNotEmpty) {
      final outermost = scrollables.first.position;
      if (outermost.hasContentDimensions && outermost.maxScrollExtent > 0.5) {
        fail(
          'the "$name" scene is ${outermost.maxScrollExtent.round()}px taller '
          'than its frame, so the bottom of it is not in the picture — give '
          'shoot() a taller size',
        );
      }
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

    Directory(outDir).createSync(recursive: true);
    File('$outDir/$name.${dark ? 'dark' : 'light'}.png')
        .writeAsBytesSync(bytes);
  }

  debugDisableShadows = true;
}
