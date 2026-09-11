import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the package's public surface.
///
/// Every name in `lib/seed_ui.dart`'s `show` clauses is a promise: adding one
/// is cheap, removing one breaks callers. This test pins the whole list so a
/// change to it can never happen by accident — it shows up as a diff in
/// `test/public_api.txt` that a reviewer has to approve on purpose.
///
/// When a change *is* intended, delete the snapshot and re-run the test to
/// regenerate it:
///
/// ```sh
/// rm test/public_api.txt && flutter test test/public_api_test.dart
/// ```
///
/// …then read the diff before committing, and record any removed name in
/// `CHANGELOG.md` as a breaking change.
void main() {
  test('the exported API matches the recorded snapshot', () {
    final barrel = File('lib/seed_ui.dart').readAsStringSync();

    // Each `export '...' show A, B, C;` contributes its shown names. A bare
    // `export '...';` would leak a whole library, so it is rejected outright.
    final exports = RegExp(
      r"export\s+'([^']+)'\s*(?:show\s+([^;]+))?;",
      multiLine: true,
    );

    final names = <String>{};
    final bare = <String>[];

    for (final m in exports.allMatches(barrel)) {
      final shown = m.group(2);
      if (shown == null) {
        bare.add(m.group(1)!);
        continue;
      }
      names.addAll(
        shown.split(',').map((n) => n.trim()).where((n) => n.isNotEmpty),
      );
    }

    expect(
      bare,
      isEmpty,
      reason: 'lib/seed_ui.dart exports ${bare.join(', ')} without a `show` '
          'clause, which makes every public member of those libraries part '
          'of the API. Name the exports explicitly.',
    );

    final snapshot = File('test/public_api.txt');
    final actual = '${(names.toList()..sort()).join('\n')}\n';

    if (!snapshot.existsSync()) {
      snapshot.writeAsStringSync(actual);
      fail(
        'No API snapshot existed, so one was written to '
        '${snapshot.path}. Review it and commit it.',
      );
    }

    expect(
      actual,
      snapshot.readAsStringSync(),
      reason: 'The public API changed.\n\n'
          'If that was deliberate, regenerate the snapshot with\n'
          '  rm test/public_api.txt && flutter test test/public_api_test.dart\n'
          'then read the diff, and record any removed name in CHANGELOG.md '
          'as a breaking change.',
    );
  });

  test('a callback that reports a change is named onChanged', () {
    // The snapshot above lists names, so a parameter renamed or added passes
    // it silently — which is how twelve callbacks kept saying `onChange`
    // through a review that renamed the seven saying exactly `onChange`.
    //
    // Flutter's own `onFocusChange` is the exception the rule has to make
    // room for: it is their name, on their widget, reaching us through
    // `Focus`.
    final offenders = <String>[];
    for (final entity in Directory('lib/src').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        final match =
            RegExp(r'^  final .*\b(on[A-Z]\w*Change)\b;').firstMatch(lines[i]);
        if (match == null) continue;
        final name = match.group(1)!;
        if (name == 'onFocusChange' || name.startsWith('_')) continue;
        offenders.add('${entity.path}:${i + 1} $name');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'a callback reporting a change ends in `onChanged`, not '
          '`onChange` — see CONTRIBUTING.md',
    );
  });
}
