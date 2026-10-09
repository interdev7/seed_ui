import 'package:flutter/material.dart'
    hide
        Checkbox,
        Radio,
        RadioGroup,
        Switch,
        ThemeData,
        Tooltip,
        Badge,
        Drawer,
        Card,
        Slider,
        RangeSlider;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// One control, one stop for a screen reader.
///
/// A control that announces itself — a `Semantics` with a tap, a [Pressable],
/// a focus detector — and then wraps a `GestureDetector` for the pointer gets
/// a second node out of the detector, with a tap of its own. A reader lands
/// on both: "button", with no name, and then the words. The button the kit
/// is built on did this, and the page gate never saw it, because it counts a
/// node as named when words sit anywhere beneath it.
///
/// So the rule here is plainer: no node that answers a tap may stand inside
/// another that does.

/// Every tap node that has a tap node above it, by where it stands.
List<String> _nested(WidgetTester tester) {
  final out = <String>[];
  void walk(SemanticsNode node, bool underTap) {
    final data = node.getSemanticsData();
    final tap = data.hasAction(SemanticsAction.tap);
    if (tap && underTap) {
      out.add('"${data.label}" ${node.rect.size}');
    }
    node.visitChildren((child) {
      walk(child, underTap || tap);
      return true;
    });
  }

  walk(
    tester.semantics.find(find.byType(MaterialApp)).owner!.rootSemanticsNode!,
    false,
  );
  return out;
}

void main() {
  final cases = <(String, Widget)>[
    ('a button', Button(onPressed: () {}, child: const Text('Go'))),
    (
      'an icon button',
      Button(
        onPressed: () {},
        icon: const Icon(Icons.add),
        semanticsLabel: 'Add',
      ),
    ),
    (
      'a float button',
      FloatButton(onPressed: () {}, icon: const Icon(Icons.add))
    ),
    (
      'a checkbox',
      Checkbox(onChanged: (_) {}, label: const Text('Remember')),
    ),
    (
      'a radio',
      Radio<String>(
        value: 'a',
        groupValue: 'b',
        onChanged: (_) {},
        child: const Text('Monthly'),
      ),
    ),
    (
      'radios as buttons',
      RadioGroup<String>(
        value: 'a',
        optionType: RadioOptionType.button,
        onChanged: (_) {},
        options: const [
          RadioOption(value: 'a', label: Text('Day')),
          RadioOption(value: 'b', label: Text('Week')),
        ],
      ),
    ),
    (
      'a switch',
      Switch(value: true, semanticsLabel: 'Wi-Fi', onChanged: (_) {}),
    ),
    ('a closable tag', const Tag(closable: true, child: Text('beta'))),
    (
      'a checkable tag',
      CheckableTag(checked: false, onChanged: (_) {}, child: const Text('t')),
    ),
    ('a pagination', Pagination(total: 50, onChanged: (_, __) {})),
    (
      'a segmented control',
      Segmented<String>(
        value: 'a',
        onChanged: (_) {},
        options: const [
          SegmentedOption(value: 'a', label: 'Day'),
          SegmentedOption(value: 'b', label: 'Week'),
        ],
      ),
    ),
    (
      'tabs',
      const SizedBox(
        width: 300,
        child: Tabs(
          items: [
            TabItem(key: 'a', label: Text('A')),
            TabItem(key: 'b', label: Text('B')),
          ],
        ),
      ),
    ),
    (
      'a collapse',
      const SizedBox(
        width: 300,
        child: Collapse(
          items: [
            CollapseItem(key: 'a', label: Text('Head'), content: Text('Body')),
          ],
        ),
      ),
    ),
    (
      'a select',
      SizedBox(
        width: 200,
        child: Select<String>(
          placeholder: 'Fruit',
          options: const [SelectOption(value: 'a', label: Text('Apple'))],
          onChanged: (_) {},
        ),
      ),
    ),
    (
      'a number field',
      const SizedBox(width: 200, child: InputNumber(value: 1)),
    ),
    (
      'a date picker',
      SizedBox(
          width: 200, child: DatePicker(placeholder: 'Day', onChanged: (_) {})),
    ),
    (
      'a slider',
      SizedBox(width: 200, child: Slider(value: 30, onChanged: (_) {})),
    ),
    (
      'clickable steps',
      SizedBox(
        width: 400,
        child: Steps(
          current: 0,
          onChanged: (_) {},
          items: const [StepItem(title: Text('A')), StepItem(title: Text('B'))],
        ),
      ),
    ),
    (
      'an upload',
      SizedBox(
        width: 300,
        child: Upload<String>(
          onPick: () async {},
          items: const [UploadItem(name: 'a.pdf', status: UploadStatus.done)],
          onRemove: (_) {},
          onPreview: (_) {},
          onDownload: (_) {},
        ),
      ),
    ),
    (
      'an upload of cards',
      SizedBox(
        width: 400,
        child: Upload<String>(
          variant: UploadVariant.cards,
          onPick: () async {},
          items: const [UploadItem(name: 'a.pdf', status: UploadStatus.done)],
          onRemove: (_) {},
          onPreview: (_) {},
        ),
      ),
    ),
    (
      'a dropdown trigger',
      const Dropdown<String>(
        menu: [DropdownItem(value: 'a', label: 'A')],
        child: Text('Open'),
      ),
    ),
    (
      'an alert',
      const Alert(message: Text('Saved'), closable: true),
    ),
  ];

  for (final (name, widget) in cases) {
    testWidgets(name, (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: Scaffold(body: Center(child: widget)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(_nested(tester), isEmpty, reason: 'two stops for one control');
      semantics.dispose();
    });
  }
}
