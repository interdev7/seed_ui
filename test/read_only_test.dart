import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart'
    hide
        ThemeData,
        Checkbox,
        Radio,
        RadioGroup,
        Switch,
        Tooltip,
        Drawer,
        Form,
        FormField;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// A value shown back and not open to change, across every control a form
/// is built from.
///
/// `readOnly` is not `disabled`. A disabled control is greyed as if its value
/// did not matter; a read-only one keeps its colours, because showing the
/// value is the point — a form in a view that is not for editing. What it
/// shares with disabled is that nothing a person does changes it: not a tap,
/// not a key, not a screen reader's double-tap.

Widget _host(Widget child) => MaterialApp(
      navigatorKey: UiKit.navigatorKey,
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const Key('shot'),
            child: Padding(padding: const EdgeInsets.all(8), child: child),
          ),
        ),
      ),
    );

/// The control as it is drawn, as a hash of its pixels.
Future<int> _shot(WidgetTester tester) async {
  final hash = await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('shot')),
    );
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ImageByteFormat.rawRgba);
    image.dispose();
    return Object.hashAll(data!.buffer.asUint32List());
  });
  return hash!;
}

/// Lets an opening panel arrive without waiting on one that never settles.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

/// Whether anything in the tree is marked read-only for a screen reader.
bool _heardAsReadOnly(WidgetTester tester) {
  var found = false;
  void walk(SemanticsNode node) {
    if (node.getSemanticsData().flagsCollection.isReadOnly) found = true;
    node.visitChildren((child) {
      walk(child);
      return !found;
    });
  }

  walk(tester.semantics
      .find(find.byType(MaterialApp))
      .owner!
      .rootSemanticsNode!);
  return found;
}

/// Holds [build] to the three things read-only means.
///
/// [build] is handed whether to be read-only and what to call when it would
/// change. [act] does to it what a person would.
Future<void> _heldToIt(
  WidgetTester tester,
  Widget Function(bool readOnly, VoidCallback changed) build, {
  required Future<void> Function() act,
  bool looksTheSame = true,
}) async {
  final semantics = tester.ensureSemantics();

  await tester.pumpWidget(_host(build(false, () {})));
  await tester.pump(const Duration(milliseconds: 400));
  final live = await _shot(tester);

  var changes = 0;
  await tester.pumpWidget(_host(build(true, () => changes++)));
  await tester.pump(const Duration(milliseconds: 400));
  if (looksTheSame) {
    expect(await _shot(tester), live, reason: 'read-only is not a look');
  }
  expect(_heardAsReadOnly(tester), isTrue, reason: 'and a reader is told');

  final texts = find.byType(Text).evaluate().length;
  await act();
  await _settle(tester);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyEvent(LogicalKeyboardKey.space);
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  await _settle(tester);

  expect(changes, 0, reason: 'nothing a person did changed it');
  expect(
    find.byType(Text).evaluate().length,
    texts,
    reason: 'and nothing opened',
  );
  semantics.dispose();
}

void main() {
  testWidgets('a checkbox', (tester) async {
    await _heldToIt(
      tester,
      (readOnly, changed) => Checkbox(
        checked: true,
        readOnly: readOnly,
        onChanged: (_) => changed(),
        label: const Text('Remember me'),
      ),
      act: () => tester.tap(find.text('Remember me')),
    );
  });

  testWidgets('a group of checkboxes', (tester) async {
    await _heldToIt(
      tester,
      (readOnly, changed) => CheckboxGroup<String>(
        value: const ['a'],
        readOnly: readOnly,
        onChanged: (_) => changed(),
        options: const [
          CheckboxOption(value: 'a', label: Text('Apple')),
          CheckboxOption(value: 'b', label: Text('Banana')),
        ],
      ),
      act: () => tester.tap(find.text('Banana')),
    );
  });

  testWidgets('a switch', (tester) async {
    await _heldToIt(
      tester,
      (readOnly, changed) => Switch(
        value: true,
        readOnly: readOnly,
        semanticsLabel: 'Wi-Fi',
        onChanged: (_) => changed(),
      ),
      act: () => tester.tap(find.byType(Switch)),
    );
  });

  testWidgets('a radio on its own', (tester) async {
    await _heldToIt(
      tester,
      (readOnly, changed) => Radio<String>(
        value: 'b',
        groupValue: 'a',
        readOnly: readOnly,
        onChanged: (_) => changed(),
        child: const Text('Yearly'),
      ),
      act: () => tester.tap(find.text('Yearly')),
    );
  });

  testWidgets('a group of radios', (tester) async {
    await _heldToIt(
      tester,
      (readOnly, changed) => RadioGroup<String>(
        value: 'a',
        readOnly: readOnly,
        onChanged: (_) => changed(),
        options: const [
          RadioOption(value: 'a', label: Text('Monthly')),
          RadioOption(value: 'b', label: Text('Yearly')),
        ],
      ),
      act: () => tester.tap(find.text('Yearly')),
    );
  });

  testWidgets('a group of radios drawn as buttons', (tester) async {
    await _heldToIt(
      tester,
      (readOnly, changed) => RadioGroup<String>(
        value: 'a',
        readOnly: readOnly,
        optionType: RadioOptionType.button,
        onChanged: (_) => changed(),
        options: const [
          RadioOption(value: 'a', label: Text('Monthly')),
          RadioOption(value: 'b', label: Text('Yearly')),
        ],
      ),
      act: () => tester.tap(find.text('Yearly').first),
    );
  });

  testWidgets('a segmented control', (tester) async {
    await _heldToIt(
      tester,
      (readOnly, changed) => Segmented<String>(
        value: 'a',
        readOnly: readOnly,
        onChanged: (_) => changed(),
        options: const [
          SegmentedOption(value: 'a', label: 'Day'),
          SegmentedOption(value: 'b', label: 'Week'),
        ],
      ),
      act: () => tester.tap(find.text('Week')),
    );
  });

  testWidgets('a select', (tester) async {
    await _heldToIt(
      tester,
      (readOnly, changed) => SizedBox(
        width: 220,
        child: Select<String>(
          value: const ['a'],
          readOnly: readOnly,
          allowClear: true,
          onChanged: (_) => changed(),
          options: const [
            SelectOption(value: 'a', label: Text('Apple')),
            SelectOption(value: 'b', label: Text('Banana')),
          ],
        ),
      ),
      act: () => tester.tap(find.byType(Select<String>)),
    );
  });

  testWidgets('a select of several takes no tag away', (tester) async {
    var changes = 0;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 260,
          child: Select<String>(
            mode: SelectMode.multiple,
            value: const ['a', 'b'],
            readOnly: true,
            onChanged: (_) => changes++,
            options: const [
              SelectOption(value: 'a', label: Text('Apple')),
              SelectOption(value: 'b', label: Text('Banana')),
            ],
          ),
        ),
      ),
    );
    final crosses = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == 'CrossPainter',
    );
    expect(crosses, findsNothing, reason: 'a tag offers no cross to remove it');
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(changes, 0);
  });

  testWidgets('a date picker', (tester) async {
    await _heldToIt(
      tester,
      (readOnly, changed) => SizedBox(
        width: 220,
        child: DatePicker(
          value: DateTime(2026, 3, 14),
          readOnly: readOnly,
          onChanged: (_) => changed(),
        ),
      ),
      act: () => tester.tap(find.byType(DatePicker)),
    );
  });

  testWidgets('a range picker', (tester) async {
    await _heldToIt(
      tester,
      (readOnly, changed) => SizedBox(
        width: 320,
        child: DateRangePicker(
          value: DateRange(DateTime(2026, 3, 14), DateTime(2026, 3, 20)),
          readOnly: readOnly,
          onChanged: (_) => changed(),
        ),
      ),
      act: () => tester.tap(find.byType(DateRangePicker)),
    );
  });

  testWidgets('a picker of several days', (tester) async {
    await _heldToIt(
      tester,
      (readOnly, changed) => SizedBox(
        width: 320,
        child: MultiDatePicker(
          values: [DateTime(2026, 3, 14)],
          readOnly: readOnly,
          onChanged: (_) => changed(),
        ),
      ),
      act: () => tester.tap(find.byType(MultiDatePicker)),
      // Each day's cross goes, as it does when disabled: a cross is a way to
      // change the value, and there is none.
      looksTheSame: false,
    );
  });

  testWidgets('a time picker', (tester) async {
    await _heldToIt(
      tester,
      (readOnly, changed) => SizedBox(
        width: 220,
        child: TimePicker(
          value: const Duration(hours: 9, minutes: 30),
          readOnly: readOnly,
          onChanged: (_) => changed(),
        ),
      ),
      act: () => tester.tap(find.byType(TimePicker)),
    );
  });

  testWidgets('an upload lets a file be looked at, not added or removed', (
    tester,
  ) async {
    UploadActions? offered;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 320,
          child: Upload<String>(
            readOnly: true,
            items: const [
              UploadItem(name: 'report.pdf', status: UploadStatus.error),
            ],
            onPick: () async {},
            onRemove: (_) {},
            onRetry: (_) {},
            onPreview: (_) {},
            onDownload: (_) {},
            itemBuilder: (item, actions) {
              offered = actions;
              return Text(item.name);
            },
          ),
        ),
      ),
    );

    expect(find.text('Choose a file'), findsNothing, reason: 'no trigger');
    expect(offered!.remove, isNull);
    expect(offered!.retry, isNull);
    expect(offered!.preview, isNotNull, reason: 'looking is not changing');
    expect(offered!.download, isNotNull);
  });

  group('a form', () {
    testWidgets('read-only takes every field with it', (tester) async {
      final form = FormController();
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: Form(
              controller: form,
              readOnly: true,
              initialValues: const {'name': 'Ada', 'news': true},
              child: Column(
                children: [
                  FormItem.text(name: 'name', label: const Text('Name')),
                  FormItem.check(name: 'news', label: const Text('News')),
                ],
              ),
            ),
          ),
        ),
      );

      final input = tester.widget<EditableText>(find.byType(EditableText));
      expect(input.readOnly, isTrue);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).readOnly, isTrue);
    });

    testWidgets('a field the reader cannot fill does not refuse the form', (
      tester,
    ) async {
      final form = FormController();
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: Form(
              controller: form,
              readOnly: true,
              child: FormItem.text(
                name: 'name',
                rules: const [FormRule.required()],
              ),
            ),
          ),
        ),
      );

      expect(await form.validate(), isTrue);
      await tester.pump();
      expect(find.text('This field is required'), findsNothing);
    });

    testWidgets('one field may say otherwise for itself', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: Form(
              readOnly: true,
              child: Column(
                children: [
                  FormItem.text(name: 'shown'),
                  FormItem.text(name: 'open', readOnly: false),
                ],
              ),
            ),
          ),
        ),
      );

      final fields = tester
          .widgetList<EditableText>(find.byType(EditableText))
          .map((e) => e.readOnly)
          .toList();
      expect(fields, [true, false]);
    });
  });
}
