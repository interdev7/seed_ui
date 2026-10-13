// Takes a fingerprint of how every demo page looks, light and dark.
//
// A measuring instrument, not a gate: Linux and macOS draw text a pixel apart,
// so a fingerprint taken on one machine only means anything beside another
// taken on the same one. It is for changes that must not move a pixel — the
// constants a component wrote for itself moved into the theme, say — taken
// before, then after, and compared.
//
//     flutter test tool/look_test.dart --dart-define=look=record
//     flutter test tool/look_test.dart --dart-define=look=compare
//
// `record` writes tool/look.txt; `compare` reads it and fails on every page
// that no longer looks the same, naming it and the theme it was drawn in.

// It runs under `flutter test`, as a test does, and moves the countdown's
// clock the way a test would; it only lives outside test/ so CI leaves it be.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart' as m;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';
// ignore: implementation_imports
import 'package:seed_ui/src/components/data_display/countdown.dart'
    show countdownClock;
import 'package:seed_ui_example/main.dart' show demos;

const _mode = String.fromEnvironment('look', defaultValue: 'compare');
const _file = 'tool/look.txt';

/// A fingerprint that means the same thing from one run to the next — not
/// `Object.hash`, which is seeded afresh in every process.
int _fnv(List<int> bytes) {
  var h = 0x811c9dc5;
  for (final b in bytes) {
    h = ((h ^ b) * 0x01000193) & 0xffffffff;
  }
  return h;
}

void main() {
  testWidgets('every page, light and dark', (tester) async {
    // A clock that does not move, so a countdown reads the same every run.
    countdownClock = () => DateTime(2026, 1, 1, 12);
    addTearDown(() => countdownClock = DateTime.now);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final seen = <String, int>{};
    for (final dark in [false, true]) {
      for (final demo in demos) {
        // The countdown page counts to a moment it sets from the wall clock
        // as it is built, so how much is left depends on the second the run
        // lands in: no fingerprint of it means the same thing twice. Its
        // looks are held by its own tests.
        if (demo.id == 'countdown') continue;
        const key = Key('page');
        Widget app() => ConfigProvider(
          theme: ThemeData(dark: dark),
          child: m.MaterialApp(
            navigatorKey: UiKit.navigatorKey,
            home: m.Scaffold(
              body: SingleChildScrollView(
                child: RepaintBoundary(
                  key: key,
                  child: Builder(builder: demo.builder),
                ),
              ),
            ),
          ),
        );

        // As tall as the page is, so all of it is drawn.
        tester.view.physicalSize = const Size(1280, 1600);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(app());
        await tester.pump(const Duration(milliseconds: 600));
        if (tester.takeException() != null) continue;
        final tall = tester.getSize(find.byKey(key)).height;
        tester.view.physicalSize = Size(1280, tall.clamp(1, 30000));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        tester.takeException();

        final hash = await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(key),
          );
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ImageByteFormat.rawRgba);
          image.dispose();
          return _fnv(data!.buffer.asUint8List());
        });
        seen['${demo.id} ${dark ? 'dark' : 'light'}'] = hash!;
      }
    }

    if (_mode == 'record') {
      File(_file).writeAsStringSync(
        '${[for (final e in seen.entries) '${e.key} ${e.value}'].join('\n')}\n',
      );
      // ignore: avoid_print
      print('recorded ${seen.length} pages to $_file');
      return;
    }

    final before = {
      for (final line in File(_file).readAsLinesSync())
        if (line.trim().isNotEmpty)
          line.substring(0, line.lastIndexOf(' ')): int.parse(
            line.substring(line.lastIndexOf(' ') + 1),
          ),
    };
    final moved = [
      for (final e in seen.entries)
        if (before[e.key] != e.value) e.key,
    ];
    // ignore: avoid_print
    print('compared ${seen.length} pages: ${moved.length} changed');
    for (final page in moved) {
      // ignore: avoid_print
      print('  changed: $page');
    }
    expect(moved, isEmpty, reason: 'these pages no longer look the same');
  });
}
