import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui_example/theme/new_year_theme.dart';
import 'package:yaml/yaml.dart';

/// The character ranges a font's `cmap` table claims to draw.
///
/// Only format 4 (BMP) is read, which is all that matters here: Latin and
/// Cyrillic both live in the basic plane.
List<(int, int)> _coverage(File file) {
  final d = ByteData.sublistView(file.readAsBytesSync());
  final tables = d.getUint16(4);

  for (var i = 0; i < tables; i++) {
    final entry = 12 + 16 * i;
    final tag = String.fromCharCodes(
      Uint8List.sublistView(ByteData.sublistView(d, entry, entry + 4)),
    );
    if (tag != 'cmap') continue;

    final cmap = d.getUint32(entry + 8);
    final subtables = d.getUint16(cmap + 2);
    var widest = <(int, int)>[];

    for (var j = 0; j < subtables; j++) {
      final sub = cmap + d.getUint32(cmap + 4 + 8 * j + 4);
      if (d.getUint16(sub) != 4) continue;

      final segX2 = d.getUint16(sub + 6);
      final ends = [
        for (var k = 0; k < segX2 ~/ 2; k++) d.getUint16(sub + 14 + 2 * k),
      ];
      final startsAt = sub + 16 + segX2;
      final starts = [
        for (var k = 0; k < segX2 ~/ 2; k++) d.getUint16(startsAt + 2 * k),
      ];
      final ranges = [
        for (var k = 0; k < starts.length; k++) (starts[k], ends[k]),
      ];
      if (ranges.length > widest.length) widest = ranges;
    }
    return widest;
  }
  return const [];
}

bool _draws(List<(int, int)> coverage, int codePoint) =>
    coverage.any((r) => r.$1 <= codePoint && codePoint <= r.$2);

void main() {
  // The whole point of this font set: a bilingual greeting must not change
  // typeface halfway through. Plenty of holiday faces are Latin-only, and the
  // gap is invisible until someone types Cyrillic — so it is asserted from the
  // font files themselves.
  test('every bundled face draws Latin and Cyrillic', () {
    const type = NewYearTypography.bundled;
    final files = {
      type.body: 'assets/fonts/Nunito-Regular.ttf',
      type.script: 'assets/fonts/MarckScript-Regular.ttf',
      type.ornament: 'assets/fonts/RuslanDisplay-Regular.ttf',
    };

    for (final entry in files.entries) {
      final file = File(entry.value);
      expect(file.existsSync(), isTrue, reason: '${entry.value} is missing');

      final coverage = _coverage(file);
      expect(coverage, isNotEmpty, reason: '${entry.key}: unreadable cmap');
      for (final sample in {
        'A': 0x41,
        'А': 0x410,
        'Ё': 0x401,
        'я': 0x44F,
      }.entries) {
        expect(
          _draws(coverage, sample.value),
          isTrue,
          reason: '${entry.key} cannot draw "${sample.key}"',
        );
      }
    }
  });

  test('the bundled faces are the ones the app declares', () {
    final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync());
    final declared = {
      for (final family in pubspec['flutter']['fonts'] as YamlList)
        family['family'] as String,
    };
    const type = NewYearTypography.bundled;
    expect(declared, containsAll([type.body, type.script, type.ornament]));
  });
}
