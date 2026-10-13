import 'dart:ui' show Tristate;

import 'package:flutter/material.dart'
    hide
        ThemeData,
        Checkbox,
        Radio,
        RadioGroup,
        Switch,
        Tooltip,
        Drawer,
        Divider;
import 'package:flutter/services.dart' show LogicalKeyboardKey, SystemChannels;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => ConfigProvider(
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: Scaffold(
          body: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    );

const _blue = Color(0xFF1677FF);

/// A panel that keeps what it is told, and remembers every word.
class _Held extends StatefulWidget {
  const _Held({
    super.key,
    this.start = _blue,
    this.changed,
    this.done,
    this.disabledAlpha,
    this.allowClear = false,
    this.presets,
  });

  final Color? start;
  final List<Color?>? changed;
  final List<Color?>? done;
  final bool? disabledAlpha;
  final bool allowClear;
  final List<ColorPreset>? presets;

  @override
  State<_Held> createState() => _HeldState();
}

class _HeldState extends State<_Held> {
  late Color? _c = widget.start;

  @override
  Widget build(BuildContext context) => ColorPickerPanel(
        value: _c,
        disabledAlpha: widget.disabledAlpha,
        allowClear: widget.allowClear,
        presets: widget.presets,
        onChanged: (c) {
          widget.changed?.add(c);
          setState(() => _c = c);
        },
        onChangeComplete: widget.done?.add,
      );
}

Finder _area() => find.bySemanticsLabel('Saturation and brightness');
Finder _strip(String label) => find.bySemanticsLabel(label);

void main() {
  testWidgets('the square picks saturation along it, brightness up it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final changed = <Color?>[];
    final done = <Color?>[];
    await tester.pumpWidget(_host(_Held(changed: changed, done: done)));
    final box = tester.getRect(_area());
    await tester.tapAt(box.topLeft + const Offset(1, 1));
    await tester.pump();
    final white = HSVColor.fromColor(changed.last!);
    expect(white.saturation, closeTo(0, 0.02));
    expect(white.value, closeTo(1, 0.02));
    expect(done, isNotEmpty, reason: 'a tap is a change done');

    await tester.dragFrom(
        box.center, Offset(box.width / 2 - 1, box.height / 2 - 1));
    await tester.pump();
    final dark = HSVColor.fromColor(changed.last!);
    expect(dark.saturation, closeTo(1, 0.02));
    expect(dark.value, closeTo(0, 0.02));
    handle.dispose();
  });

  testWidgets('the hue strip turns the hue; a grey keeps it', (tester) async {
    final handle = tester.ensureSemantics();
    final changed = <Color?>[];
    await tester.pumpWidget(_host(_Held(changed: changed)));
    final strip = tester.getRect(_strip('Hue'));
    await tester.tapAt(strip.centerLeft + const Offset(2, 0));
    await tester.pump();
    expect(HSVColor.fromColor(changed.last!).hue, closeTo(0, 3));

    // Down to grey, then the strip's handle should not jump back to red.
    final area = tester.getRect(_area());
    await tester.tapAt(area.centerLeft + const Offset(1, 0));
    await tester.pump();
    await tester.tapAt(strip.center);
    await tester.pump();
    final node = tester.getSemantics(_strip('Hue'));
    expect(node.value, '180°');
    handle.dispose();
  });

  testWidgets('a grey handed in from outside keeps the hue it stood at', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    Widget panel(Color c) => _host(ColorPickerPanel(value: c));
    await tester.pumpWidget(panel(_blue));
    final before = tester.getSemantics(_strip('Hue')).value;
    await tester.pumpWidget(panel(const Color(0xFF808080)));
    expect(
      tester.getSemantics(_strip('Hue')).value,
      before,
      reason: 'a grey has no hue of its own to give the strip',
    );
    handle.dispose();
  });

  testWidgets('the opacity strip, and none of it with disabledAlpha', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final changed = <Color?>[];
    await tester.pumpWidget(_host(_Held(changed: changed)));
    final strip = tester.getRect(_strip('Opacity').first);
    await tester.tapAt(strip.centerLeft + const Offset(2, 0));
    await tester.pump();
    expect(changed.last!.a, closeTo(0, 0.02));

    await tester.pumpWidget(
      _host(const _Held(key: ValueKey('opaque'), disabledAlpha: true)),
    );
    expect(_strip('Opacity'), findsNothing);
    handle.dispose();
  });

  testWidgets('the keys move the handles a step', (tester) async {
    final changed = <Color?>[];
    await tester.pumpWidget(
      _host(_Held(
          start: const HSVColor.fromAHSV(1, 200, 0.5, 0.5).toColor(),
          changed: changed)),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab); // the square
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(HSVColor.fromColor(changed.last!).saturation, closeTo(0.51, 0.005));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(HSVColor.fromColor(changed.last!).value, closeTo(0.51, 0.005));
  });

  testWidgets('a hex typed in is taken, keeping the opacity', (tester) async {
    final changed = <Color?>[];
    await tester.pumpWidget(
      _host(_Held(start: const Color(0x801677FF), changed: changed)),
    );
    final hex = find.descendant(
      of: find.byType(Input),
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(hex.first).controller.text,
      '1677FF',
    );
    await tester.enterText(hex.first, 'ff0000');
    await tester.pump();
    expect(changed.last!.toARGB32(), 0x80FF0000);
  });

  testWidgets('RGB and HSB write it out, and take it typed', (tester) async {
    final changed = <Color?>[];
    await tester.pumpWidget(_host(_Held(changed: changed)));
    await tester.tap(find.text('RGB'));
    await tester.pumpAndSettle();
    String field(int i) => tester
        .widget<EditableText>(
          find
              .descendant(
                of: find.byType(InputNumber),
                matching: find.byType(EditableText),
              )
              .at(i),
        )
        .controller
        .text;
    expect([field(0), field(1), field(2)], ['22', '119', '255']);
    await tester.enterText(
      find
          .descendant(
            of: find.byType(InputNumber),
            matching: find.byType(EditableText),
          )
          .first,
      '255',
    );
    // A number field takes what was typed once it is confirmed.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect((changed.last!.r * 255).round(), 255);

    await tester.tap(find.text('HSB'));
    await tester.pumpAndSettle();
    expect(find.byType(InputNumber), findsNWidgets(4), reason: 'H, S, B, A');
  });

  testWidgets('a ready colour is taken at once, and marked', (tester) async {
    final handle = tester.ensureSemantics();
    final done = <Color?>[];
    await tester.pumpWidget(
      _host(
        _Held(
          done: done,
          presets: const [
            ColorPreset(label: 'Brand', colors: [Color(0xFFF5222D), _blue]),
          ],
        ),
      ),
    );
    expect(find.text('Brand'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('#1677FF'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    await tester.tap(find.bySemanticsLabel('#F5222D'));
    await tester.pump();
    expect(done.last, const Color(0xFFF5222D));
    handle.dispose();
  });

  testWidgets('allowClear offers no colour at all', (tester) async {
    final handle = tester.ensureSemantics();
    final changed = <Color?>[];
    await tester.pumpWidget(_host(_Held(changed: changed, allowClear: true)));
    await tester.tap(find.bySemanticsLabel('No colour'));
    await tester.pump();
    expect(changed.last, isNull);
    handle.dispose();
  });

  group('canCopy', () {
    /// What was put on the clipboard, newest last.
    List<String> clipboard(WidgetTester tester) {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      return copied;
    }

    testWidgets('unasked, there is nothing to copy with', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const ColorPickerPanel(value: _blue)));
      expect(find.bySemanticsLabel('Copy'), findsNothing);
      handle.dispose();
    });

    testWidgets('copies the colour as it is written, and says so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final copied = clipboard(tester);
      await tester.pumpWidget(
        _host(const ColorPickerPanel(value: _blue, canCopy: true)),
      );
      await tester.tap(find.bySemanticsLabel('Copy'));
      await tester.pump();
      expect(copied, ['#1677FF']);
      expect(find.bySemanticsLabel('Copied'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.bySemanticsLabel('Copy'), findsOneWidget,
          reason: 'back, to copy again');

      await tester.tap(find.text('RGB'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Copy'));
      await tester.pump();
      expect(copied.last, 'rgb(22, 119, 255)');
      await tester.pump(const Duration(seconds: 2));
      handle.dispose();
    });

    testWidgets('a see-through colour keeps its opacity on the clipboard', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final copied = clipboard(tester);
      await tester.pumpWidget(
        _host(
          const ColorPickerPanel(
            value: Color(0x801677FF),
            canCopy: true,
            format: ColorFormat.hsb,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Copy'));
      await tester.pump();
      expect(copied.last, 'hsba(215, 91%, 100%, 0.5)');
      await tester.pump(const Duration(seconds: 2));
      handle.dispose();
    });

    testWidgets('a subtree can ask for it; no colour has none to copy', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      Widget panel(Color? c) => ConfigProvider(
            defaults: const ComponentDefaults(
              colorPicker: ColorPickerDefaults(canCopy: true),
            ),
            child: _host(ColorPickerPanel(value: c)),
          );
      await tester.pumpWidget(panel(_blue));
      expect(find.bySemanticsLabel('Copy'), findsOneWidget);
      await tester.pumpWidget(panel(null));
      expect(find.bySemanticsLabel('Copy'), findsNothing);
      handle.dispose();
    });
  });

  group('the field', () {
    testWidgets('a tap opens the panel, a tap away shuts it', (tester) async {
      await tester.pumpWidget(
        _host(const ColorPicker(defaultValue: _blue, showText: true)),
      );
      expect(find.text('#1677FF'), findsOneWidget);
      expect(find.byType(ColorPickerPanel), findsNothing);
      await tester.tap(find.byType(ColorPicker));
      await tester.pumpAndSettle();
      expect(find.byType(ColorPickerPanel), findsOneWidget);
      await tester.tapAt(const Offset(700, 560));
      await tester.pumpAndSettle();
      expect(find.byType(ColorPickerPanel), findsNothing);
    });

    testWidgets('what the panel picks, the field shows and reports', (
      tester,
    ) async {
      final changed = <Color?>[];
      await tester.pumpWidget(
        _host(
          ColorPicker(
            defaultValue: _blue,
            showText: true,
            presets: const [
              ColorPreset(label: 'Brand', colors: [Color(0xFF52C41A)]),
            ],
            onChanged: changed.add,
          ),
        ),
      );
      await tester.tap(find.byType(ColorPicker));
      await tester.pumpAndSettle();
      final handle = tester.ensureSemantics();
      await tester.tap(find.bySemanticsLabel('#52C41A'));
      await tester.pumpAndSettle();
      expect(changed, [const Color(0xFF52C41A)]);
      expect(find.text('#52C41A'), findsWidgets);
      handle.dispose();
    });

    testWidgets('no colour is said in words', (tester) async {
      await tester.pumpWidget(_host(const ColorPicker(showText: true)));
      expect(find.text('No colour'), findsOneWidget);
    });

    testWidgets('disabled, it does not open', (tester) async {
      await tester.pumpWidget(
        _host(const ColorPicker(defaultValue: _blue, disabled: true)),
      );
      await tester.tap(find.byType(ColorPicker));
      await tester.pumpAndSettle();
      expect(find.byType(ColorPickerPanel), findsNothing);
    });

    testWidgets('a reader hears a button with the colour as its value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const ColorPicker(
              defaultValue: _blue, semanticsLabel: 'Brand colour'),
        ),
      );
      final node = tester.getSemantics(find.byType(ColorPicker));
      expect(node.label, 'Brand colour');
      expect(node.value, '#1677FF');
      handle.dispose();
    });
  });
}
