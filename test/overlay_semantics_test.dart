// The openers return futures that complete when the overlay closes; awaiting
// them here would wait for a close the test never asks for.
// ignore_for_file: unawaited_futures

import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// What opens over a page, held to the rule the demo's gate holds pages to:
/// nothing a person can act on may reach a screen reader without words.
///
/// The page gate walks every demo page, and every one of them has its dialogs
/// shut. A cross on a modal, a drawer or a tour was a button nobody could hear
/// named, and the gate could not see it because it was never open.

Widget _host(Widget body) => MaterialApp(
      navigatorKey: UiKit.navigatorKey,
      home: Scaffold(body: Center(child: body)),
    );

/// Lets an overlay arrive without waiting for one that never settles.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();
}

/// Every node that answers a tap and has no words, its own or beneath it.
List<String> _unnamed(WidgetTester tester) {
  bool worded(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.label.trim().isNotEmpty ||
        data.tooltip.isNotEmpty ||
        data.value.isNotEmpty) {
      return true;
    }
    var any = false;
    node.visitChildren((child) {
      any = worded(child);
      return !any;
    });
    return any;
  }

  final out = <String>[];
  void walk(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.hasAction(SemanticsAction.tap) && !worded(node)) {
      out.add('${node.rect.width.round()}x${node.rect.height.round()} '
          'at ${node.rect.topLeft}');
    }
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(tester.semantics
      .find(find.byType(MaterialApp))
      .owner!
      .rootSemanticsNode!);
  return out;
}

void main() {
  testWidgets('a modal', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(const SizedBox()));
    Modal.open(const ModalConfig(title: Text('Title'), content: Text('Body')));
    await _settle(tester);
    expect(_unnamed(tester), isEmpty);
    semantics.dispose();
  });

  testWidgets('a drawer', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(const SizedBox()));
    Drawer.open(const DrawerConfig(title: Text('Title'), child: Text('Body')));
    await _settle(tester);
    expect(_unnamed(tester), isEmpty);
    semantics.dispose();
  });

  testWidgets('a tour', (tester) async {
    final semantics = tester.ensureSemantics();
    final target = GlobalKey();
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(key: target, width: 40, height: 40),
            Tour(
              open: true,
              steps: [
                TourStep(
                  target: target,
                  title: const Text('Step'),
                  description: const Text('What it is for'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await _settle(tester);
    expect(_unnamed(tester), isEmpty);
    semantics.dispose();
  });

  /// Opens what [open] opens, then holds it to the rule.
  Future<void> heldToIt(
    WidgetTester tester,
    Widget page, {
    Future<void> Function()? open,
  }) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(page));
    await _settle(tester);
    await open?.call();
    await _settle(tester);
    expect(_unnamed(tester), isEmpty);
    semantics.dispose();
  }

  testWidgets('a notification', (tester) async {
    await heldToIt(
      tester,
      const SizedBox(),
      open: () async => notification.success(
        'Saved',
        description: 'Everything is where you left it.',
        duration: Duration.zero,
      ),
    );
  });

  testWidgets('a message', (tester) async {
    await heldToIt(
      tester,
      const SizedBox(),
      open: () async =>
          message.success('Saved', duration: const Duration(seconds: 30)),
    );
    await tester.pump(const Duration(seconds: 31));
  });

  testWidgets('a popconfirm', (tester) async {
    await heldToIt(
      tester,
      Popconfirm(
        title: const Text('Delete this item?'),
        onOk: () {},
        child: const Text('Delete'),
      ),
      open: () => tester.tap(find.text('Delete')),
    );
  });

  testWidgets('a dropdown menu', (tester) async {
    await heldToIt(
      tester,
      const Dropdown<String>(
        open: true,
        menu: [
          DropdownItem(value: 'edit', label: 'Edit'),
          DropdownItem(value: 'remove', label: 'Delete', disabled: true),
        ],
        child: Text('Actions'),
      ),
    );
  });

  testWidgets("a select's panel", (tester) async {
    await heldToIt(
      tester,
      SizedBox(
        width: 240,
        child: Select<String>(
          placeholder: 'Fruit',
          options: const [
            SelectOption(value: 'a', label: Text('Apple')),
            SelectOption(value: 'b', label: Text('Banana')),
          ],
          onChanged: (_) {},
        ),
      ),
      open: () => tester.tap(find.text('Fruit')),
    );
  });

  testWidgets("a date picker's panel", (tester) async {
    await heldToIt(
      tester,
      SizedBox(
        width: 240,
        child: DatePicker(placeholder: 'Day', onChanged: (_) {}),
      ),
      open: () => tester.tap(find.text('Day')),
    );
  });

  testWidgets("a range picker's panel", (tester) async {
    await heldToIt(
      tester,
      SizedBox(
        width: 320,
        child: DateRangePicker(onChanged: (_) {}),
      ),
      open: () => tester.tap(find.byType(DateRangePicker)),
    );
  });

  testWidgets("a time picker's panel", (tester) async {
    await heldToIt(
      tester,
      SizedBox(
        width: 240,
        child: TimePicker(placeholder: 'Time', onChanged: (_) {}),
      ),
      open: () => tester.tap(find.text('Time')),
    );
  });
}
