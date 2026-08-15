import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => MaterialApp(
      navigatorKey: UiKit.navigatorKey,
      home: Scaffold(body: child),
    );

/// Runs an enter or exit animation to completion.
///
/// `pumpAndSettle` is unusable here: [Spinner] repeats forever, so the
/// tree never reaches a quiescent state. The trailing pump matters too —
/// cards are removed from a `whenComplete` callback, and the container only
/// rebuilds on the frame after that.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  testWidgets('message.success shows a card and auto-dismisses it',
      (tester) async {
    await tester.pumpWidget(_host(const SizedBox()));

    message.success('Saved', duration: const Duration(seconds: 1));
    await _settle(tester);
    expect(find.text('Saved'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await _settle(tester);
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('the returned handle dismisses a message early', (tester) async {
    await tester.pumpWidget(_host(const SizedBox()));

    final close = message.loading('Uploading…');
    await _settle(tester);
    expect(find.text('Uploading…'), findsOneWidget);

    close();
    await _settle(tester);
    expect(find.text('Uploading…'), findsNothing);
  });

  testWidgets('maxCount evicts the oldest message', (tester) async {
    await tester.pumpWidget(_host(const SizedBox()));
    message.config(maxCount: 2);

    for (final text in ['first', 'second', 'third']) {
      message.open(MessageConfig(content: text, duration: Duration.zero));
    }
    await _settle(tester);

    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    expect(find.text('third'), findsOneWidget);

    // Clean up, otherwise a live overlay leaks into the next test.
    message.destroy();
    await _settle(tester);
  });

  testWidgets('Button fires onPressed but stays inert while loading',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            Button(onPressed: () => taps++, child: const Text('tap me')),
            Button(
              loading: true,
              onPressed: () => taps++,
              child: const Text('busy'),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('tap me'));
    await tester.tap(find.text('busy'));
    await tester.pump();

    expect(taps, 1);
  });
}
