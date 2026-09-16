import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every widget that takes a `token` has to read it.
///
/// A component collects a per-instance token, documents it, and then resolves
/// its own from the `ConfigProvider` alone — and the token named on the widget
/// does nothing whatever. It is invisible from outside: the field is there,
/// the doc comment is there, and only the pixels disagree. `Radio` shipped
/// that way, and a pixel probe per field is a slow way to find the next one.
///
/// This reads the source instead. A component passes when the file that
/// declares `final XToken? token;` also asks for it first — `token ?? …` or
/// `widget.token ?? …` ahead of the provider.
void main() {
  test('a component that takes a token reads it before the provider', () {
    final deaf = <String>[];

    final components = Directory('lib/src/components')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in components) {
      final source = file.readAsStringSync();
      for (final match
          in RegExp(r'\n  final (\w+Token)\? token;').allMatches(source)) {
        final token = match.group(1)!;
        // Either spelling of the read, and either way of falling back: the
        // provider next, or a bare default where there is no provider entry.
        final reads = RegExp(
          r'(widget\.token|\btoken)\s*\?\?\s*\n?\s*'
          '(ConfigProvider\\.componentOf<$token>|const $token)',
        );
        if (!reads.hasMatch(source)) {
          deaf.add('${file.path.split('/').last}: $token is taken and '
              'never read');
        }
      }
    }

    expect(
      deaf,
      isEmpty,
      reason: 'these take a token and resolve without it, so naming one on '
          'the widget does nothing:\n${deaf.join("\n")}',
    );
  });
}
