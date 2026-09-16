import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart'
    hide
        Card,
        Checkbox,
        Drawer,
        Form,
        Radio,
        RadioGroup,
        Slider,
        Switch,
        ThemeData,
        Tooltip;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// Every field of a component's token is a promise: name it, and the
/// component looks different. A field that is declared, documented and then
/// never read keeps the promise on paper only — and the kit has shipped a
/// few of those, found by hand each time.
///
/// Not every field can be proved this way. A handle that only appears under
/// the pointer is one: the button slides in because the field is hovered, and
/// by then the pointer is already still, so the button's own `MouseRegion`
/// never sees it arrive. `InputNumberToken.handleHoverBg` is left out for
/// that reason, not because it does nothing.
///
/// This holds the promise to the pixels. Each probe draws the component
/// twice, once plain and once with one field named, and the two pictures
/// have to differ. A field wired to nothing draws the same picture, and the
/// test says which field it was.
class _Probe {
  const _Probe(this.field, this.build, {this.act, this.hover, this.hoverAt});

  /// What is being proved, as `TokenType.field`.
  final String field;

  /// The component, drawn plain when `changed` is false and with the one
  /// field named when it is true.
  final Widget Function(bool changed) build;

  /// What has to happen before the picture is worth taking — a panel opened,
  /// a field focused. Runs before [hover].
  final Future<void> Function(WidgetTester tester)? act;

  /// What the pointer has to rest on. A hover colour is only visible while
  /// something is hovered.
  final Finder Function()? hover;

  /// Where the pointer has to rest, where the centre of the widget is not
  /// the part that answers — a slider's rail has labels under it, and the
  /// middle of the whole control falls between the two.
  final Offset Function(WidgetTester tester)? hoverAt;
}

final _key = GlobalKey();

Widget _host(Widget child) => RepaintBoundary(
      key: _key,
      // Outside the app, not around the component: a panel — a `Select`'s
      // list, a picker's — is drawn in the overlay above the whole app, and
      // a boundary tucked around the field would photograph everything
      // except the thing being proved.
      child: MaterialApp(
        navigatorKey: UiKit.navigatorKey,
        home: Scaffold(
          body: Center(
            child: Padding(padding: const EdgeInsets.all(8), child: child),
          ),
        ),
      ),
    );

/// A picture, as one number.
///
/// The bytes themselves are two megabytes, and comparing two lists that long
/// through a matcher takes minutes — long enough to look like a hang. What is
/// being asked is only whether the two differ.
Future<int> _shot(
  WidgetTester tester,
  Widget child,
  Future<void> Function(WidgetTester)? act,
  Finder Function()? hover,
  Offset Function(WidgetTester)? hoverAt,
) async {
  // A blank frame first: the two shots share a test, and what the first one
  // left open — a panel in the overlay, a pointer's idea of what it is over —
  // would otherwise greet the second and send it the other way.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pumpWidget(_host(child));
  await tester.pump();
  if (act != null) await act(tester);

  // A `MouseRegion` answers a real gesture; a bare pointer event never
  // enters it, and the picture came back the resting one. The pointer is
  // taken away again before the test ends — left in place, the next shot
  // adds a second one and the framework's own tracker asserts.
  TestGesture? mouse;
  if (hover != null || hoverAt != null) {
    mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await tester.pump();
    await mouse.moveTo(
      hover != null ? tester.getCenter(hover()) : hoverAt!(tester),
    );
    await tester.pump();
  }
  // Long enough for every motion the kit has to have finished; not
  // pumpAndSettle, which never returns where something spins forever.
  await tester.pump(const Duration(milliseconds: 600));

  final boundary =
      _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  // Reading pixels back is real work in the engine, and a test's clock is a
  // fake one: awaited against it the future never completes and the test
  // hangs rather than fails.
  final shot = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return Object.hashAll(data!.buffer.asUint32List());
  }))!;
  await mouse?.removePointer();
  await tester.pump();
  return shot;
}

void main() {
  for (final probe in _probes) {
    testWidgets('${probe.field} changes what is drawn', (tester) async {
      final plain = await _shot(
          tester, probe.build(false), probe.act, probe.hover, probe.hoverAt);
      final named = await _shot(
          tester, probe.build(true), probe.act, probe.hover, probe.hoverAt);
      expect(
        named,
        isNot(plain),
        reason: '${probe.field} is declared and documented, and naming it '
            'draws exactly the same picture — the field is read by nothing.',
      );
    });
  }
}

/// A colour nothing in the kit would arrive at on its own, so a difference
/// is this field's doing and not a coincidence.
const _loud = Color(0xFFFF00FF);

const _options = [
  SegmentedOption(value: 'a', label: 'Aaa'),
  SegmentedOption(value: 'b', label: 'Bbb'),
];

Widget _progress(ProgressToken? token,
        {ProgressType type = ProgressType.line}) =>
    SizedBox(
      width: 200,
      child: Progress(percent: 0.4, type: type, token: token),
    );

Widget _segmented(SegmentedToken? token) => Segmented<String>(
      value: 'a',
      options: _options,
      onChanged: (_) {},
      token: token,
    );

Widget _number(InputNumberToken? token, {InputNumberMode? mode}) => SizedBox(
      width: 200,
      child: InputNumber(
        value: 3,
        mode: mode,
        onChanged: (_) {},
        token: token,
      ),
    );

Widget _select(SelectToken? token, {SoftSize? size}) => SizedBox(
      width: 220,
      child: Select<String>(
        value: const ['a'],
        size: size,
        options: const [
          SelectOption(value: 'a', label: Text('Aaa')),
          SelectOption(value: 'b', label: Text('Bbb')),
        ],
        onChanged: (_) {},
        token: token,
      ),
    );

/// Opens a `Select`'s panel the way a person does. `open: true` on its own
/// draws no panel: the kit puts one in the overlay when the field is pressed.
Future<void> _openPanel(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text('Aaa').first);
  await tester.pumpAndSettle();
  expect(find.text('Bbb'), findsOneWidget, reason: 'the panel did not open');
}

Widget _input(InputToken? token, {SoftSize? size, int maxLines = 1}) =>
    SizedBox(
      width: 220,
      child: Input(
        placeholder: 'Type here',
        size: size,
        maxLines: maxLines,
        token: token,
      ),
    );

Widget _button(ButtonToken? token, {SoftSize? size}) => Button(
      size: size,
      onPressed: () {},
      token: token,
      child: const Text('Press'),
    );

/// Puts the caret in the field, which is when a focused field shows what it
/// shows: an accent border, and a ring around it.
Future<void> _focusField(WidgetTester tester) async {
  await tester.tap(find.byType(Input));
  await tester.pumpAndSettle();
}

const _tabs = [
  TabItem(key: 'one', label: Text('One'), content: Text('First')),
  TabItem(key: 'two', label: Text('Two'), content: Text('Second')),
];

Widget _tabsOf(
  TabsToken? token, {
  SoftSize? size,
  TabsType type = TabsType.line,
  TabPosition? position,
}) =>
    SizedBox(
      width: 300,
      height: 160,
      child: Tabs(
        items: _tabs,
        defaultActiveKey: 'one',
        size: size,
        type: type,
        tabPosition: position,
        token: token,
      ),
    );

const _marks = [
  SliderMark(0, 'nil'),
  SliderMark(50, 'half'),
  SliderMark(100, 'all'),
];

Widget _slider(
  SliderToken? token, {
  bool disabled = false,
  bool dots = false,
}) =>
    SizedBox(
      width: 260,
      child: Slider(
        value: 40,
        marks: _marks,
        dots: dots,
        disabled: disabled,
        onChanged: (_) {},
        token: token,
      ),
    );

/// The rail itself: a slider's box includes the labels under it, so its
/// centre is below the rail rather than on it.
Offset _onTheRail(WidgetTester tester) {
  final box = tester.getRect(find.byType(Slider));
  return Offset(box.center.dx, box.top + 10);
}

const _steps = [
  StepItem(title: Text('One'), content: Text('First')),
  StepItem(title: Text('Two'), content: Text('Second')),
  StepItem(title: Text('Three'), content: Text('Third')),
];

Widget _stepsOf(
  StepsToken? token, {
  SoftSize? size,
  StepsType type = StepsType.standard,
  StepsOrientation orientation = StepsOrientation.horizontal,
  double width = 420,
}) =>
    SizedBox(
      // Width only: a run given a height of someone else's choosing spills
      // past it, and what a probe then photographs is the same clipped strip
      // whatever the token said.
      width: width,
      child: Steps(
        items: _steps,
        current: 1,
        size: size,
        type: type,
        orientation: orientation,
        token: token,
      ),
    );

Widget _card(CardToken? token, {SoftSize? size, List<Widget>? actions}) =>
    SizedBox(
      width: 300,
      child: Card(
        title: const Text('A card'),
        extra: const Text('more'),
        size: size,
        actions: actions,
        token: token,
        child: const Text('Something inside it.'),
      ),
    );

Future<void> _noop() async {}

const _uploads = <UploadItem<Object?>>[
  UploadItem(name: 'one.png', size: 2048, status: UploadStatus.done),
  UploadItem(name: 'two.png', size: 4096, status: UploadStatus.done),
];

Widget _upload(
  UploadToken? token, {
  UploadVariant variant = UploadVariant.text,
  bool dragging = false,
}) =>
    SizedBox(
      width: 320,
      child: Upload(
        items: _uploads,
        variant: variant,
        dragging: dragging,
        onPick: _noop,
        token: token,
      ),
    );

/// A form with a field that fails, one that only warns, and a help line —
/// the three things the message colours belong to.
Widget _form(FormToken? token) => SizedBox(
      width: 320,
      child: Form(
        token: token,
        child: const Column(
          children: [
            FormItem<String>(
              name: 'must',
              label: Text('Must'),
              rules: [FormRule.required(message: 'Needed')],
              builder: _field,
            ),
            FormItem<String>(
              name: 'ought',
              label: Text('Ought'),
              rules: [FormRule.required(message: 'Better', warningOnly: true)],
              builder: _field,
            ),
            FormItem<String>(
              name: 'helped',
              label: Text('Helped'),
              help: 'A word about it',
              builder: _field,
            ),
          ],
        ),
      ),
    );

Widget _field(FormFieldHandle<String> field) => Input(
      value: field.value ?? '',
      onChanged: field.didChange,
    );

/// Sends the form, which is when a field that fails says so.
Future<void> _submitForm(WidgetTester tester) async {
  final context = tester.element(find.byType(FormItem<String>).first);
  await Form.controllerOf(context).submit();
  await tester.pumpAndSettle();
}

final _probes = <_Probe>[
  _Probe(
    'ProgressToken.defaultColor',
    (c) => _progress(c ? const ProgressToken(defaultColor: _loud) : null),
  ),
  _Probe(
    'ProgressToken.remainingColor',
    (c) => _progress(c ? const ProgressToken(remainingColor: _loud) : null),
  ),
  _Probe(
    'ProgressToken.lineHeight',
    (c) => _progress(c ? const ProgressToken(lineHeight: 20) : null),
  ),
  _Probe(
    'ProgressToken.circleSize',
    // No width from above: a ring drawn inside a box of someone else's
    // choosing takes that width, and `circleSize` only reserves the height.
    (c) => Progress(
      percent: 0.4,
      type: ProgressType.circle,
      token: c ? const ProgressToken(circleSize: 140) : null,
    ),
  ),
  _Probe(
    'SegmentedToken.trackBg',
    (c) => _segmented(c ? const SegmentedToken(trackBg: _loud) : null),
  ),
  _Probe(
    'SegmentedToken.trackPadding',
    (c) => _segmented(c ? const SegmentedToken(trackPadding: 12) : null),
  ),
  _Probe(
    'SegmentedToken.itemColor',
    (c) => _segmented(c ? const SegmentedToken(itemColor: _loud) : null),
  ),
  _Probe(
    'SegmentedToken.itemSelectedBg',
    (c) => _segmented(c ? const SegmentedToken(itemSelectedBg: _loud) : null),
  ),
  _Probe(
    'SegmentedToken.itemSelectedColor',
    (c) =>
        _segmented(c ? const SegmentedToken(itemSelectedColor: _loud) : null),
  ),
  _Probe(
    'SegmentedToken.borderRadius',
    (c) => _segmented(c ? const SegmentedToken(borderRadius: 0) : null),
  ),
  _Probe(
    'SegmentedToken.itemHoverColor',
    (c) => _segmented(c ? const SegmentedToken(itemHoverColor: _loud) : null),
    hover: () => find.text('Bbb'),
  ),
  _Probe(
    'SegmentedToken.itemHoverBg',
    (c) => _segmented(c ? const SegmentedToken(itemHoverBg: _loud) : null),
    hover: () => find.text('Bbb'),
  ),
  _Probe(
    'SegmentedToken.borderRadiusSM',
    (c) => Segmented<String>(
      value: 'a',
      size: SoftSize.small,
      options: _options,
      onChanged: (_) {},
      token: c ? const SegmentedToken(borderRadiusSM: 0) : null,
    ),
  ),
  _Probe(
    'SegmentedToken.borderRadiusLG',
    (c) => Segmented<String>(
      value: 'a',
      size: SoftSize.large,
      options: _options,
      onChanged: (_) {},
      token: c ? const SegmentedToken(borderRadiusLG: 0) : null,
    ),
  ),
  _Probe(
    'SegmentedToken.thumbShadow',
    (c) => _segmented(
      c
          ? const SegmentedToken(
              thumbShadow: [BoxShadow(color: _loud, blurRadius: 6)],
            )
          : null,
    ),
  ),
  _Probe(
    'InputNumberToken.handleBg',
    (c) => _number(
      c ? const InputNumberToken(handleBg: _loud) : null,
      // A handle's own fill and width belong to the spinner's two buttons.
      mode: InputNumberMode.spinner,
    ),
    hover: () => find.byType(InputNumber),
  ),
  _Probe(
    'InputNumberToken.handleBorderColor',
    (c) => _number(c ? const InputNumberToken(handleBorderColor: _loud) : null),
    hover: () => find.byType(InputNumber),
  ),
  _Probe(
    'InputNumberToken.handleWidth',
    (c) => _number(
      c ? const InputNumberToken(handleWidth: 44) : null,
      // A handle's own fill and width belong to the spinner's two buttons.
      mode: InputNumberMode.spinner,
    ),
    hover: () => find.byType(InputNumber),
  ),
  _Probe(
    'InputNumberToken.controlWidth',
    (c) => _number(c ? const InputNumberToken(controlWidth: 44) : null),
    hover: () => find.byType(InputNumber),
  ),
  _Probe(
    'InputNumberToken.spinnerWidth',
    (c) => _number(
      c ? const InputNumberToken(spinnerWidth: 260) : null,
      mode: InputNumberMode.spinner,
    ),
  ),
  _Probe(
    'SelectToken.selectorBg',
    (c) => _select(c ? const SelectToken(selectorBg: _loud) : null),
    act: _openPanel,
  ),
  _Probe(
    'SelectToken.optionSelectedBg',
    (c) => _select(c ? const SelectToken(optionSelectedBg: _loud) : null),
    act: _openPanel,
  ),
  _Probe(
    'SelectToken.optionPadding',
    (c) => _select(
      c ? const SelectToken(optionPadding: EdgeInsets.all(20)) : null,
    ),
    act: _openPanel,
  ),
  _Probe(
    'SelectToken.optionFontSize',
    (c) => _select(c ? const SelectToken(optionFontSize: 22) : null),
    act: _openPanel,
  ),
  _Probe(
    'SelectToken.borderRadius',
    (c) => _select(c ? const SelectToken(borderRadius: 0) : null),
    act: _openPanel,
  ),
  _Probe(
    'SelectToken.borderRadiusSM',
    (c) => _select(
      c ? const SelectToken(borderRadiusSM: 0) : null,
      size: SoftSize.small,
    ),
    act: _openPanel,
  ),
  _Probe(
    'SelectToken.borderRadiusLG',
    (c) => _select(
      c ? const SelectToken(borderRadiusLG: 0) : null,
      size: SoftSize.large,
    ),
    act: _openPanel,
  ),
  _Probe(
    'SelectToken.optionActiveBg',
    (c) => _select(c ? const SelectToken(optionActiveBg: _loud) : null),
    hover: () => find.text('Bbb'),
    act: _openPanel,
  ),
  _Probe(
    'InputToken.colorBorder',
    (c) => _input(c ? const InputToken(colorBorder: _loud) : null),
  ),
  _Probe(
    'InputToken.colorBgContainer',
    (c) => _input(c ? const InputToken(colorBgContainer: _loud) : null),
  ),
  _Probe(
    'InputToken.colorTextPlaceholder',
    (c) => _input(c ? const InputToken(colorTextPlaceholder: _loud) : null),
  ),
  _Probe(
    'InputToken.paddingInline',
    (c) => _input(c ? const InputToken(paddingInline: 40) : null),
  ),
  _Probe(
    'InputToken.paddingBlock',
    // A field of one line is exactly as tall as the control preset says, so
    // the vertical inset is a textarea's alone.
    (c) => _input(
      c ? const InputToken(paddingBlock: 20) : null,
      maxLines: 3,
    ),
  ),
  _Probe(
    'InputToken.borderRadius',
    (c) => _input(c ? const InputToken(borderRadius: 0) : null),
  ),
  _Probe(
    'InputToken.fontSize',
    (c) => _input(c ? const InputToken(fontSize: 22) : null),
  ),
  _Probe(
    'InputToken.paddingInlineSM',
    (c) => _input(
      c ? const InputToken(paddingInlineSM: 40) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'InputToken.paddingBlockSM',
    (c) => _input(
      c ? const InputToken(paddingBlockSM: 20) : null,
      size: SoftSize.small,
      maxLines: 3,
    ),
  ),
  _Probe(
    'InputToken.borderRadiusSM',
    (c) => _input(
      c ? const InputToken(borderRadiusSM: 0) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'InputToken.fontSizeSM',
    (c) => _input(
      c ? const InputToken(fontSizeSM: 22) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'InputToken.paddingInlineLG',
    (c) => _input(
      c ? const InputToken(paddingInlineLG: 40) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'InputToken.paddingBlockLG',
    (c) => _input(
      c ? const InputToken(paddingBlockLG: 20) : null,
      size: SoftSize.large,
      maxLines: 3,
    ),
  ),
  _Probe(
    'InputToken.borderRadiusLG',
    (c) => _input(
      c ? const InputToken(borderRadiusLG: 0) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'InputToken.fontSizeLG',
    (c) => _input(
      c ? const InputToken(fontSizeLG: 22) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'InputToken.colorText',
    (c) => SizedBox(
      width: 220,
      // Text of its own to colour: a placeholder is the other field.
      child: Input(
        defaultValue: 'Written',
        token: c ? const InputToken(colorText: _loud) : null,
      ),
    ),
  ),
  _Probe(
    'InputToken.hoverBorderColor',
    (c) => _input(c ? const InputToken(hoverBorderColor: _loud) : null),
    hover: () => find.byType(Input),
  ),
  _Probe(
    'InputToken.activeBorderColor',
    (c) => _input(c ? const InputToken(activeBorderColor: _loud) : null),
    act: _focusField,
  ),
  _Probe(
    'InputToken.focusRing',
    (c) => _input(c ? const InputToken(focusRing: _loud) : null),
    act: _focusField,
  ),
  _Probe(
    'ButtonToken.borderRadius',
    (c) => _button(c ? const ButtonToken(borderRadius: 0) : null),
  ),
  _Probe(
    'ButtonToken.controlHeight',
    (c) => _button(c ? const ButtonToken(controlHeight: 60) : null),
  ),
  _Probe(
    'ButtonToken.fontSize',
    (c) => _button(c ? const ButtonToken(fontSize: 24) : null),
  ),
  _Probe(
    'ButtonToken.paddingInline',
    (c) => _button(c ? const ButtonToken(paddingInline: 48) : null),
  ),
  _Probe(
    'ButtonToken.fontWeight',
    (c) => _button(c ? const ButtonToken(fontWeight: FontWeight.w900) : null),
  ),
  _Probe(
    'ButtonToken.shadow',
    (c) => Button(
      variant: ButtonVariant.solid,
      color: ButtonColor.primary,
      onPressed: () {},
      token: c
          ? const ButtonToken(
              shadow: [BoxShadow(color: _loud, blurRadius: 8)],
            )
          : null,
      child: const Text('Press'),
    ),
  ),
  _Probe(
    'ButtonToken.borderRadiusSM',
    (c) => _button(
      c ? const ButtonToken(borderRadiusSM: 0) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'ButtonToken.controlHeightSM',
    (c) => _button(
      c ? const ButtonToken(controlHeightSM: 12) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'ButtonToken.fontSizeSM',
    (c) => _button(
      c ? const ButtonToken(fontSizeSM: 22) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'ButtonToken.paddingInlineSM',
    (c) => _button(
      c ? const ButtonToken(paddingInlineSM: 48) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'ButtonToken.borderRadiusLG',
    (c) => _button(
      c ? const ButtonToken(borderRadiusLG: 0) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'ButtonToken.controlHeightLG',
    (c) => _button(
      c ? const ButtonToken(controlHeightLG: 70) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'ButtonToken.fontSizeLG',
    (c) => _button(
      c ? const ButtonToken(fontSizeLG: 28) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'ButtonToken.paddingInlineLG',
    (c) => _button(
      c ? const ButtonToken(paddingInlineLG: 48) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'TabsToken.inkBarColor',
    (c) => _tabsOf(c ? const TabsToken(inkBarColor: _loud) : null),
  ),
  _Probe(
    'TabsToken.itemColor',
    (c) => _tabsOf(c ? const TabsToken(itemColor: _loud) : null),
  ),
  _Probe(
    'TabsToken.itemSelectedColor',
    (c) => _tabsOf(c ? const TabsToken(itemSelectedColor: _loud) : null),
  ),
  _Probe(
    'TabsToken.itemHoverColor',
    (c) => _tabsOf(c ? const TabsToken(itemHoverColor: _loud) : null),
    hover: () => find.text('Two'),
  ),
  _Probe(
    'TabsToken.titleFontSize',
    (c) => _tabsOf(c ? const TabsToken(titleFontSize: 24) : null),
  ),
  _Probe(
    'TabsToken.titleFontSizeSM',
    (c) => _tabsOf(
      c ? const TabsToken(titleFontSizeSM: 24) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'TabsToken.titleFontSizeLG',
    (c) => _tabsOf(
      c ? const TabsToken(titleFontSizeLG: 24) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'TabsToken.fontWeightActive',
    (c) =>
        _tabsOf(c ? const TabsToken(fontWeightActive: FontWeight.w900) : null),
  ),
  _Probe(
    'TabsToken.horizontalItemGutter',
    (c) => _tabsOf(c ? const TabsToken(horizontalItemGutter: 48) : null),
  ),
  _Probe(
    'TabsToken.horizontalItemPadding',
    (c) => _tabsOf(
      c
          ? const TabsToken(
              horizontalItemPadding: EdgeInsets.symmetric(horizontal: 30),
            )
          : null,
    ),
  ),
  _Probe(
    'TabsToken.horizontalItemPaddingSM',
    (c) => _tabsOf(
      c
          ? const TabsToken(
              horizontalItemPaddingSM: EdgeInsets.symmetric(horizontal: 30),
            )
          : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'TabsToken.horizontalItemPaddingLG',
    (c) => _tabsOf(
      c
          ? const TabsToken(
              horizontalItemPaddingLG: EdgeInsets.symmetric(horizontal: 30),
            )
          : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'TabsToken.verticalItemPadding',
    (c) => _tabsOf(
      c
          ? const TabsToken(
              verticalItemPadding: EdgeInsets.symmetric(vertical: 24),
            )
          : null,
      position: TabPosition.left,
    ),
  ),
  _Probe(
    'TabsToken.cardBg',
    (c) => _tabsOf(
      c ? const TabsToken(cardBg: _loud) : null,
      type: TabsType.card,
    ),
  ),
  _Probe(
    'TabsToken.cardGutter',
    (c) => _tabsOf(
      c ? const TabsToken(cardGutter: 24) : null,
      type: TabsType.card,
    ),
  ),
  _Probe(
    'TabsToken.cardPadding',
    (c) => _tabsOf(
      c ? const TabsToken(cardPadding: EdgeInsets.all(24)) : null,
      type: TabsType.card,
    ),
  ),
  _Probe(
    'TabsToken.cardPaddingSM',
    (c) => _tabsOf(
      c ? const TabsToken(cardPaddingSM: EdgeInsets.all(24)) : null,
      type: TabsType.card,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'TabsToken.cardPaddingLG',
    (c) => _tabsOf(
      c ? const TabsToken(cardPaddingLG: EdgeInsets.all(24)) : null,
      type: TabsType.card,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'SliderToken.railSize',
    (c) => _slider(c ? const SliderToken(railSize: 16) : null),
  ),
  _Probe(
    'SliderToken.railBg',
    (c) => _slider(c ? const SliderToken(railBg: _loud) : null),
  ),
  _Probe(
    'SliderToken.trackBg',
    (c) => _slider(c ? const SliderToken(trackBg: _loud) : null),
  ),
  _Probe(
    'SliderToken.handleSize',
    (c) => _slider(c ? const SliderToken(handleSize: 28) : null),
  ),
  _Probe(
    'SliderToken.handleColor',
    (c) => _slider(c ? const SliderToken(handleColor: _loud) : null),
  ),
  _Probe(
    'SliderToken.handleLineWidth',
    (c) => _slider(c ? const SliderToken(handleLineWidth: 8) : null),
  ),
  _Probe(
    'SliderToken.markColor',
    (c) => _slider(c ? const SliderToken(markColor: _loud) : null),
  ),
  _Probe(
    'SliderToken.dotSize',
    (c) => _slider(c ? const SliderToken(dotSize: 20) : null, dots: true),
  ),
  _Probe(
    'SliderToken.dotBorderColor',
    (c) => _slider(
      c ? const SliderToken(dotBorderColor: _loud) : null,
      dots: true,
    ),
  ),
  _Probe(
    'SliderToken.dotActiveBorderColor',
    (c) => _slider(
      c ? const SliderToken(dotActiveBorderColor: _loud) : null,
      dots: true,
    ),
  ),
  _Probe(
    'SliderToken.handleColorDisabled',
    (c) => _slider(
      c ? const SliderToken(handleColorDisabled: _loud) : null,
      disabled: true,
    ),
  ),
  _Probe(
    'SliderToken.trackBgDisabled',
    (c) => _slider(
      c ? const SliderToken(trackBgDisabled: _loud) : null,
      disabled: true,
    ),
  ),
  _Probe(
    'SliderToken.railHoverBg',
    (c) => _slider(c ? const SliderToken(railHoverBg: _loud) : null),
    hoverAt: _onTheRail,
  ),
  _Probe(
    'SliderToken.trackHoverBg',
    (c) => _slider(c ? const SliderToken(trackHoverBg: _loud) : null),
    hoverAt: _onTheRail,
  ),
  _Probe(
    'SliderToken.handleSizeHover',
    (c) => _slider(c ? const SliderToken(handleSizeHover: 30) : null),
    hoverAt: _onTheRail,
  ),
  _Probe(
    'SliderToken.handleLineWidthHover',
    (c) => _slider(c ? const SliderToken(handleLineWidthHover: 9) : null),
    hoverAt: _onTheRail,
  ),
  _Probe(
    'SliderToken.handleActiveColor',
    (c) => _slider(c ? const SliderToken(handleActiveColor: _loud) : null),
    hoverAt: _onTheRail,
  ),
  _Probe(
    'StepsToken.iconSize',
    (c) => _stepsOf(c ? const StepsToken(iconSize: 44) : null),
  ),
  _Probe(
    'StepsToken.iconSizeSM',
    (c) => _stepsOf(
      c ? const StepsToken(iconSizeSM: 40) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'StepsToken.iconSizeLG',
    (c) => _stepsOf(
      c ? const StepsToken(iconSizeLG: 52) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'StepsToken.railThickness',
    (c) => _stepsOf(c ? const StepsToken(railThickness: 8) : null),
  ),
  _Probe(
    'StepsToken.itemGap',
    (c) => _stepsOf(c ? const StepsToken(itemGap: 40) : null),
  ),
  _Probe(
    'StepsToken.railInset',
    (c) => _stepsOf(
      c ? const StepsToken(railInset: RailInsets.all(24)) : null,
    ),
  ),
  _Probe(
    'StepsToken.railLength',
    (c) => _stepsOf(
      c ? const StepsToken(railLength: 12) : null,
      // Room to stay on one line: squeezed, the run stacks each step instead
      // and the fields that share a line out have nothing to share.
      width: 900,
    ),
  ),
  _Probe(
    'StepsToken.railMinLength',
    (c) => _stepsOf(c ? const StepsToken(railMinLength: 120) : null),
  ),
  _Probe(
    'StepsToken.contentMaxWidth',
    (c) => _stepsOf(
      c ? const StepsToken(contentMaxWidth: 60) : null,
      // Room to stay on one line: squeezed, the run stacks each step instead
      // and the fields that share a line out have nothing to share.
      width: 900,
    ),
  ),
  _Probe(
    'StepsToken.itemWidth',
    (c) => _stepsOf(
      c ? const StepsToken(itemWidth: 90) : null,
      type: StepsType.navigation,
    ),
  ),
  _Probe(
    'StepsToken.itemMinWidth',
    (c) => _stepsOf(
      // Wide enough that the three steps no longer fit the room and each is
      // drawn at the floor instead of its share — named lower, the floor is
      // real but invisible: the run simply keeps sharing as it did.
      c ? const StepsToken(itemMinWidth: 400) : null,
      width: 900,
    ),
  ),
  _Probe(
    'StepsToken.itemHeight',
    (c) => _stepsOf(
      c ? const StepsToken(itemHeight: 120) : null,
      type: StepsType.navigation,
    ),
  ),
  _Probe(
    'StepsToken.dotSize',
    (c) => _stepsOf(
      c ? const StepsToken(dotSize: 24) : null,
      type: StepsType.dot,
    ),
  ),
  _Probe(
    'StepsToken.dotCurrentSize',
    (c) => _stepsOf(
      c ? const StepsToken(dotCurrentSize: 26) : null,
      type: StepsType.dot,
    ),
  ),
  _Probe(
    'StepsToken.panelPadding',
    (c) => _stepsOf(
      c ? const StepsToken(panelPadding: EdgeInsets.all(28)) : null,
      type: StepsType.panel,
    ),
  ),
  _Probe(
    'StepsToken.panelRadius',
    (c) => _stepsOf(
      c ? const StepsToken(panelRadius: 0) : null,
      type: StepsType.panel,
    ),
  ),
  _Probe(
    'StepsToken.panelArrowWidth',
    (c) => _stepsOf(
      c ? const StepsToken(panelArrowWidth: 36) : null,
      type: StepsType.panel,
    ),
  ),
  _Probe(
    'StepsToken.panelMinWidth',
    (c) => _stepsOf(
      c ? const StepsToken(panelMinWidth: 260) : null,
      type: StepsType.panel,
    ),
  ),
  _Probe(
    'StepsToken.panelWidth',
    (c) => _stepsOf(
      c ? const StepsToken(panelWidth: 260) : null,
      type: StepsType.panel,
    ),
  ),
  _Probe(
    'StepsToken.panelHeight',
    (c) => _stepsOf(
      c ? const StepsToken(panelHeight: 120) : null,
      type: StepsType.panel,
    ),
  ),
  _Probe(
    'StepsToken.arrowColor',
    // The chevron between blocks belongs to the navigation run alone.
    (c) => _stepsOf(
      c ? const StepsToken(arrowColor: _loud) : null,
      type: StepsType.navigation,
    ),
  ),
  _Probe(
    'CardToken.headerBg',
    (c) => _card(c ? const CardToken(headerBg: _loud) : null),
  ),
  _Probe(
    'CardToken.headerFontSize',
    (c) => _card(c ? const CardToken(headerFontSize: 28) : null),
  ),
  _Probe(
    'CardToken.headerFontSizeSM',
    (c) => _card(
      c ? const CardToken(headerFontSizeSM: 28) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'CardToken.headerHeight',
    (c) => _card(c ? const CardToken(headerHeight: 90) : null),
  ),
  _Probe(
    'CardToken.headerHeightSM',
    (c) => _card(
      c ? const CardToken(headerHeightSM: 90) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'CardToken.headerPadding',
    (c) => _card(c ? const CardToken(headerPadding: 44) : null),
  ),
  _Probe(
    'CardToken.headerPaddingSM',
    (c) => _card(
      c ? const CardToken(headerPaddingSM: 44) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'CardToken.bodyPadding',
    (c) => _card(c ? const CardToken(bodyPadding: EdgeInsets.all(44)) : null),
  ),
  _Probe(
    'CardToken.bodyPaddingSM',
    (c) => _card(
      c ? const CardToken(bodyPaddingSM: EdgeInsets.all(44)) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'CardToken.borderRadius',
    (c) => _card(c ? const CardToken(borderRadius: 0) : null),
  ),
  _Probe(
    'CardToken.extraColor',
    (c) => _card(c ? const CardToken(extraColor: _loud) : null),
  ),
  _Probe(
    'CardToken.actionsBg',
    (c) => _card(
      c ? const CardToken(actionsBg: _loud) : null,
      actions: const [Icon(Icons.edit), Icon(Icons.share)],
    ),
  ),
  _Probe(
    'CardToken.actionsLiMargin',
    (c) => _card(
      c ? const CardToken(actionsLiMargin: 28) : null,
      actions: const [Icon(Icons.edit), Icon(Icons.share)],
    ),
  ),
  _Probe(
    'UploadToken.gap',
    (c) => _upload(c ? const UploadToken(gap: 28) : null),
  ),
  _Probe(
    'UploadToken.itemRadius',
    // The corner of a row's fill, which is only drawn under the pointer, and
    // of a preview, which is drawn always: the second is the plainer proof.
    (c) => _upload(
      c ? const UploadToken(itemRadius: 26) : null,
      variant: UploadVariant.picture,
    ),
  ),
  _Probe(
    'UploadToken.itemHoverBg',
    (c) => _upload(c ? const UploadToken(itemHoverBg: _loud) : null),
    hover: () => find.text('one.png'),
  ),
  _Probe(
    'UploadToken.thumbnailSize',
    (c) => _upload(
      c ? const UploadToken(thumbnailSize: 64) : null,
      variant: UploadVariant.picture,
    ),
  ),
  _Probe(
    'UploadToken.cardSize',
    (c) => _upload(
      c ? const UploadToken(cardSize: 140) : null,
      variant: UploadVariant.cards,
    ),
  ),
  _Probe(
    'UploadToken.dropzoneBg',
    (c) => _upload(c ? const UploadToken(dropzoneBg: _loud) : null),
  ),
  _Probe(
    'UploadToken.dropzoneBorderColor',
    (c) => _upload(c ? const UploadToken(dropzoneBorderColor: _loud) : null),
  ),
  _Probe(
    'UploadToken.dropzoneRadius',
    (c) => _upload(c ? const UploadToken(dropzoneRadius: 0) : null),
  ),
  _Probe(
    'UploadToken.dropzonePadding',
    (c) => _upload(
      c ? const UploadToken(dropzonePadding: EdgeInsets.all(48)) : null,
    ),
  ),
  _Probe(
    'UploadToken.dropzoneActiveBg',
    (c) => _upload(
      c ? const UploadToken(dropzoneActiveBg: _loud) : null,
      dragging: true,
    ),
  ),
  _Probe(
    'UploadToken.dropzoneActiveBorderColor',
    (c) => _upload(
      c ? const UploadToken(dropzoneActiveBorderColor: _loud) : null,
      dragging: true,
    ),
  ),
  _Probe(
    'FormToken.labelColor',
    (c) => _form(c ? const FormToken(labelColor: _loud) : null),
  ),
  _Probe(
    'FormToken.labelFontSize',
    (c) => _form(c ? const FormToken(labelFontSize: 24) : null),
  ),
  _Probe(
    'FormToken.labelGap',
    (c) => _form(c ? const FormToken(labelGap: 28) : null),
  ),
  _Probe(
    'FormToken.itemGap',
    (c) => _form(c ? const FormToken(itemGap: 44) : null),
  ),
  _Probe(
    'FormToken.extraColor',
    (c) => _form(c ? const FormToken(extraColor: _loud) : null),
  ),
  _Probe(
    'FormToken.messageFontSize',
    (c) => _form(c ? const FormToken(messageFontSize: 22) : null),
  ),
  _Probe(
    'FormToken.messageGap',
    (c) => _form(c ? const FormToken(messageGap: 28) : null),
  ),
  _Probe(
    'FormToken.errorColor',
    (c) => _form(c ? const FormToken(errorColor: _loud) : null),
    act: _submitForm,
  ),
  _Probe(
    'FormToken.warningColor',
    (c) => _form(c ? const FormToken(warningColor: _loud) : null),
    act: _submitForm,
  ),
];
