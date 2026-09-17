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
        Badge,
        Switch,
        Table,
        ThemeData,
        Tooltip;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

/// Every field of a component's token is a promise: name it, and the
/// component looks different. A field that is declared, documented and then
/// never read keeps the promise on paper only — and the kit has shipped a
/// few of those, found by hand each time.
///
/// Not every field can be proved this way, and the ones that cannot say so
/// here rather than quietly going missing.
///
/// * A handle that only appears under the pointer: the button slides in
///   because the field is hovered, and by then the pointer is already still,
///   so the button's own `MouseRegion` never sees it arrive —
///   `InputNumberToken.handleHoverBg`, `handleHoverColor` and
///   `handleActiveBg`.
/// * Things that are not drawn at all: `TableToken.resizeHandleWidth` is how
///   wide a border is to take hold of, and `PopconfirmToken`'s and
///   `DropdownToken`'s durations and curves are how long something takes
///   rather than what it looks like — `FloatButtonToken.motionDuration` and
///   `curve`, `TourToken.travelDuration` and `travelCurve`.
/// * Floors that only show where something reaches them:
///   `TableToken.columnMinWidth` — every arrangement tried here either had
///   slack to share or was already scrolling.
/// * `PaginationToken.borderRadius` rounds a focus ring and nothing else.
/// * `TableToken.dragShadow` is worn by a column while it is carried, which
///   needs a drag the test framework starts and holds across a rebuild.
/// * `TableToken.resizeLineColor` puts its line in the tree while a border is
///   dragged — the widget is there, and no pixel of the shot changes. That
///   one is worth a look on a device.
/// * `SeedToken.fontFamily` and `fontFamilyFallback`: a test renders with one
///   face whatever is asked for, so the letters come back the same shape.
///
/// This holds the promise to the pixels. Each probe draws the component
/// twice, once plain and once with one field named, and the two pictures
/// have to differ. A field wired to nothing draws the same picture, and the
/// test says which field it was.
class _Probe {
  const _Probe(
    this.field,
    this.build, {
    this.theme,
    this.act,
    this.hover,
    this.hoverAt,
  });

  /// What is being proved, as `TokenType.field`.
  final String field;

  /// The component, drawn plain when `changed` is false and with the one
  /// field named when it is true.
  final Widget Function(bool changed) build;

  /// A theme above the whole app, for the components that have no widget to
  /// hang a token on: a modal, a drawer, a message and a notification are
  /// raised into the navigator's overlay, which sits *above* anything the
  /// page puts around itself — a provider inside the page never reaches them.
  final ComponentsConfig Function(bool changed)? theme;

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

/// Set by an `act` that leaves a pointer down; called once the shot is taken.
Future<void> Function()? _letGo;

Widget _host(Widget child, ComponentsConfig? components) => RepaintBoundary(
      key: _key,
      // Outside the app, not around the component: a panel — a `Select`'s
      // list, a picker's — is drawn in the overlay above the whole app, and
      // a boundary tucked around the field would photograph everything
      // except the thing being proved.
      child: ConfigProvider(
        theme: components == null ? null : ThemeData(components: components),
        child: MaterialApp(
          navigatorKey: UiKit.navigatorKey,
          home: Scaffold(
            body: Center(
              child: Padding(padding: const EdgeInsets.all(8), child: child),
            ),
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
  ComponentsConfig? components,
  Future<void> Function(WidgetTester)? act,
  Finder Function()? hover,
  Offset Function(WidgetTester)? hoverAt,
) async {
  // A blank frame first: the two shots share a test, and what the first one
  // left open — a panel in the overlay, a pointer's idea of what it is over —
  // would otherwise greet the second and send it the other way.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pumpWidget(_host(child, components));
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
  // Anything an `act` is still holding — a finger on a column's border — is
  // let go of now: the two shots share a test, and a pointer left down would
  // still be down when the second one starts.
  await _letGo?.call();
  _letGo = null;
  // Long enough for anything that takes itself away again — a message, a
  // notification — to have gone: a timer still pending when the tree is
  // disposed fails the test, however good the picture was.
  await tester.pump(const Duration(seconds: 6));
  return shot;
}

void main() {
  for (final probe in _probes) {
    testWidgets('${probe.field} changes what is drawn', (tester) async {
      final plain = await _shot(tester, probe.build(false),
          probe.theme?.call(false), probe.act, probe.hover, probe.hoverAt);
      final named = await _shot(tester, probe.build(true),
          probe.theme?.call(true), probe.act, probe.hover, probe.hoverAt);
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

class _Row {
  const _Row(this.name, this.city);
  final String name;
  final String city;
}

const _rows0 = _Row('Ann', 'Bristol');

const _rows = [
  _rows0,
  _Row('Bart', 'Galway'),
  _Row('Chen', 'Chengdu'),
];

const _longRows = [
  _Row('Bartholomew Considine the Younger', 'Kirkcudbrightshire'),
  _Row('Wilhelmina Ashbourne-Whitfield', 'Llanfairpwllgwyngyll'),
];

Widget _table(
  TableToken? token, {
  bool long = false,
  SoftSize? size,
  bool bordered = true,
  List<TableSort>? sort,
  TableSelection<_Row>? selection,
  TableExpandable<_Row>? expandable,
  Widget? footer,
  bool summary = false,
  bool resizable = false,
  bool filterable = false,
  bool pinned = false,
  double width = 420,
}) =>
    SizedBox(
      width: width,
      child: Table<_Row>(
        data: long ? _longRows : _rows,
        bordered: bordered,
        size: size,
        sort: sort,
        selection: selection,
        expandable: expandable,
        footer: footer == null ? null : (_, __) => footer,
        columnsResizable: resizable,
        // A run wider than the room is what holds a column at the edge: with
        // nothing to scroll past, nothing is pinned and no shade is drawn.
        scroll: pinned ? const TableScroll(x: 900, y: 200) : null,
        token: token,
        columns: [
          TableColumn(
            title: const Text('Name'),
            sortable: true,
            // A summary belongs to a column, not to the table.
            summary: summary ? (_, rows) => const Text('In all') : null,
            fixed: pinned ? TableColumnFixed.start : null,
            width: pinned ? 260 : null,
            filters: filterable
                ? const [TableFilter('Ann', 'Ann'), TableFilter('Bart', 'Bart')]
                : null,
            // The menu grows a search box only where the column asks for one.
            filterSearch: filterable,
            value: (r) => r.name,
          ),
          TableColumn(
            title: const Text('City'),
            width: pinned ? 260 : null,
            value: (r) => r.city,
          ),
        ],
      ),
    );

/// The funnel in a column heading: a painter rather than a widget of its
/// own, so it is found by what paints it.
Finder _funnel() => find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString().contains('Funnel'),
    );

/// Drags the rows sideways, which is when a held column has something to
/// cast a shade over: at rest against its own end there is nothing behind it.
Future<void> _scrollAcross(WidgetTester tester) async {
  await tester.drag(find.text('Ann'), const Offset(-160, 0));
  await tester.pumpAndSettle();
}

/// Opens a column's filter menu, which is where the filter fields live.
Future<void> _openFilter(WidgetTester tester) async {
  await tester.tap(_funnel().first);
  await tester.pumpAndSettle();
}

Widget _float(
  FloatButtonToken? token, {
  SoftSize? size,
  Widget? label,
  ButtonShape? shape,
}) =>
    FloatButton(
      icon: const Icon(Icons.add),
      label: label,
      size: size,
      shape: shape,
      onPressed: () {},
      token: token,
    );

Widget _avatar(
  AvatarToken? token, {
  SoftSize? size,
  bool letters = true,
  AvatarShape? shape,
}) =>
    Avatar(
      size: size,
      shape: shape,
      token: token,
      icon: letters ? null : const Icon(Icons.person),
      child: letters ? const Text('AB') : null,
    );

Widget _switchOf(SwitchToken? token, {SoftSize? size, bool on = true}) =>
    Switch(
      value: on,
      size: size,
      onChanged: (_) {},
      token: token,
    );

Widget _radio(RadioToken? token, {bool checked = true}) => Radio<String>(
      value: 'a',
      groupValue: checked ? 'a' : 'b',
      onChanged: (_) {},
      token: token,
      child: const Text('Aaa'),
    );

/// A run of connected buttons. A `RadioGroup` has no token of its own, so
/// these fields are named where the group reads them — the theme above it —
/// and the same provider stands in both shots so the token is the only
/// difference between them.
Widget _radioButtons(RadioToken? token) => ConfigProvider(
      theme: ThemeData(
        components: ComponentsConfig(radio: token ?? const RadioToken()),
      ),
      child: RadioGroup<String>(
        value: 'a',
        optionType: RadioOptionType.button,
        onChanged: (_) {},
        options: const [
          RadioOption(value: 'a', label: Text('Aaa')),
          RadioOption(value: 'b', label: Text('Bbb')),
        ],
      ),
    );

Widget _badge(
  BadgeToken? token, {
  SoftSize? size,
  int? count = 5,
  bool dot = false,
  BadgeStatus? status,
}) =>
    Badge(
      count: count,
      dot: dot,
      status: status,
      text: status == null ? null : const Text('Running'),
      size: size,
      token: token,
      child: status == null ? const SizedBox(width: 40, height: 40) : null,
    );

Widget _ribbon(RibbonToken? token) => Ribbon(
      text: const Text('New'),
      token: token,
      child: const SizedBox(width: 120, height: 60),
    );

Widget _dropdown(DropdownToken? token) => Dropdown<String>(
      open: true,
      token: token,
      menu: const [
        DropdownItem(value: 'a', label: 'Rename'),
        DropdownItem(value: 'b', label: 'Delete'),
      ],
      child: const Text('Menu'),
    );

Widget _popover(PopoverToken? token) => Popover(
      open: true,
      title: const Text('A title'),
      content: const Text('And a line under it.'),
      token: token,
      child: const Text('Anchor'),
    );

Widget _timeline(TimelineToken? token, {TimelineOrientation? orientation}) =>
    SizedBox(
      width: 300,
      child: Timeline(
        token: token,
        orientation: orientation,
        items: const [
          TimelineItem(title: Text('First'), description: Text('one')),
          TimelineItem(title: Text('Second'), description: Text('two')),
        ],
      ),
    );

Widget _datePanel(
  DatePickerToken? token, {
  bool withPresets = false,
  bool withTime = false,
}) =>
    SizedBox(
      width: 320,
      child: DatePicker(
        value: DateTime(2026, 3, 10),
        showTime: withTime,
        presets: withPresets
            ? [DatePreset('Today', DateTime(2026, 3, 10))]
            : const [],
        token: token,
      ),
    );

/// Lights the first menu row the way a keyboard does.
Future<void> _highlightFirstItem(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  await tester.pumpAndSettle();
}

/// Opens a picker's panel, which is where every field of its token is drawn.
Future<void> _openPicker(WidgetTester tester) async {
  await tester.tap(find.byType(DatePicker));
  await tester.pumpAndSettle();
}

Widget _tag(TagToken? token, {TagVariant? variant}) => Tag(
      token: token,
      variant: variant,
      child: const Text('A tag'),
    );

Widget _checkbox(CheckboxToken? token, {bool checked = true}) => Checkbox(
      checked: checked,
      onChanged: (_) {},
      label: const Text('Ticked'),
      token: token,
    );

Widget _empty(EmptyToken? token) => Empty(
      description: const Text('Nothing here'),
      token: token,
    );

Widget _countdown(CountdownToken? token) => Countdown(
      target: DateTime(2030),
      token: token,
    );

Widget _spin(SpinToken? token, {SoftSize? size}) => Spin(
      size: size,
      token: token,
    );

Widget _result(ResultToken? token) => SizedBox(
      width: 320,
      child: Result(
        title: const Text('All done'),
        subtitle: const Text('And a line under it'),
        token: token,
      ),
    );

Widget _pagination(PaginationToken? token) => SizedBox(
      // Room to grow: a pager that overflows draws the same striped edge
      // whatever the token said.
      width: 700,
      child: Pagination(total: 120, current: 2, token: token),
    );

Widget _listy(ListyToken? token) => SizedBox(
      width: 300,
      height: 200,
      child: Listy<String, Object, Object>(
        items: const ['One', 'Two', 'Three'],
        itemRender: (item, i) => Text(item),
        token: token,
      ),
    );

Widget _collapse(CollapseToken? token) => SizedBox(
      width: 320,
      child: Collapse(
        defaultActiveKeys: const ['a'],
        token: token,
        items: const [
          CollapseItem(
            key: 'a',
            label: Text('A panel'),
            content: Text('What is inside it'),
          ),
        ],
      ),
    );

Widget _tree(TreeToken? token, {List<String> selected = const ['a']}) =>
    SizedBox(
      width: 300,
      child: Tree(
        token: token,
        selectedKeys: selected,
        defaultExpandedKeys: const ['a'],
        nodes: const [
          TreeNode(
            key: 'a',
            title: Text('Root'),
            children: [TreeNode(key: 'b', title: Text('Leaf'))],
          ),
        ],
      ),
    );

Widget _sortable(SortableListToken? token) => SizedBox(
      width: 300,
      height: 200,
      child: SortableList(
        onReorder: (_, __) {},
        // The whole row answers, rather than a grip: a test drags where the
        // text is, and the grip is somewhere else.
        showHandle: false,
        token: token,
        children: const [
          SizedBox(key: ValueKey('a'), height: 40, child: Text('One')),
          SizedBox(key: ValueKey('b'), height: 40, child: Text('Two')),
        ],
      ),
    );

/// Picks a row up and keeps hold of it: what a lift is drawn with only
/// exists while something is being carried.
Future<void> _liftRow(WidgetTester tester) async {
  final gesture = await tester.startGesture(tester.getCenter(find.text('One')));
  _letGo = gesture.up;
  // Long enough for a delayed drag to be recognised — a row is picked up by
  // holding it, not by brushing past.
  await tester.pump(const Duration(milliseconds: 800));
  await gesture.moveBy(const Offset(0, 40));
  await tester.pumpAndSettle();
}

Widget _tooltip(TooltipToken? token) => Tooltip(
      message: const Text('A word about it'),
      token: token,
      child: const Text('Anchor'),
    );

/// Rests the pointer on a tooltip's anchor and waits for it to appear.
Future<void> _showTooltip(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  _letGo = mouse.removePointer;
  await tester.pump();
  await mouse.moveTo(tester.getCenter(find.text('Anchor')));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

Widget _alert(
  AlertToken? token, {
  bool described = false,
  bool icon = false,
}) =>
    SizedBox(
      width: 360,
      child: Alert(
        message: const Text('Something happened'),
        description: described ? const Text('And here is what') : null,
        showIcon: icon,
        token: token,
      ),
    );

Widget _popconfirm(PopconfirmToken? token) => Popconfirm(
      title: const Text('Sure?'),
      description: const Text('This cannot be undone'),
      token: token,
      child: const Text('Anchor'),
    );

Widget _timePanel(TimePickerToken? token) => SizedBox(
      width: 260,
      child: TimePicker(
        value: const Duration(hours: 9, minutes: 30),
        token: token,
      ),
    );

/// Opens a time picker's panel, which is where its token is drawn.
Future<void> _openTime(WidgetTester tester) async {
  await tester.tap(find.byType(TimePicker));
  await tester.pumpAndSettle();
}

/// Presses the anchor and lets the panel settle.
Future<void> _pressAnchor(WidgetTester tester) async {
  await tester.tap(find.text('Anchor'));
  await tester.pumpAndSettle();
}

/// A button that raises whatever it is handed. The token for what it raises
/// is named in the probe's `theme`, above the app: a modal, a drawer, a
/// message and a notification are built in the navigator's overlay, which no
/// provider inside the page is above.
Widget _raiseButton(void Function() raise) => Builder(
      builder: (context) => Button(
        onPressed: raise,
        child: const Text('Raise'),
      ),
    );

/// Presses the button and stops while the toast is still on screen: a
/// message and a notification take themselves away after a few seconds, and
/// `pumpAndSettle` runs every timer to the end — including that one.
Future<void> _pressBriefly(WidgetTester tester) async {
  // The stack behind a toast is static and outlives the tree, so what one
  // shot raised is still there for the next one to be refused by. Cleared
  // once the picture has been taken.
  message.destroy();
  notification.destroy();
  await tester.pump();
  _letGo = () async {
    message.destroy();
    notification.destroy();
  };
  await tester.tap(find.text('Raise'));
  await tester.pump();
  // Past the arrival animation, and well short of the few seconds it stays.
  await tester.pump(const Duration(milliseconds: 900));
}

Future<void> _pressRaise(WidgetTester tester) async {
  await tester.tap(find.text('Raise'));
  await tester.pumpAndSettle();
}

/// The one step a tour needs, hung on a key the page can point at.
final _tourTarget = GlobalKey();

Widget _tour(TourToken? token, {TourType type = TourType.normal}) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
            key: _tourTarget,
            width: 120,
            height: 40,
            child: const Text('Here')),
        Tour(
          open: true,
          type: type,
          token: token,
          steps: [
            TourStep(
              target: _tourTarget,
              title: const Text('First stop'),
              description: const Text(
                'What it is for, at enough length that the card has a width '
                'to be held to rather than only its own content.',
              ),
            ),
            // A second stop, so the run of indicators exists at all: one stop
            // has nothing to indicate.
            TourStep(
              target: _tourTarget,
              title: const Text('Second stop'),
              description: const Text('And what that one is for'),
            ),
          ],
        ),
      ],
    );

/// A run too long for its box, which is when the scroll arrows appear.
Widget _narrowSegmented(SegmentedToken? token) => SizedBox(
      width: 140,
      child: Segmented<String>(
        value: 'a',
        options: const [
          SegmentedOption(value: 'a', label: 'The first one'),
          SegmentedOption(value: 'b', label: 'The second one'),
          SegmentedOption(value: 'c', label: 'The third one'),
        ],
        onChanged: (_) {},
        token: token,
      ),
    );

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
  _Probe(
    'TableToken.headerBg',
    (c) => _table(c ? const TableToken(headerBg: _loud) : null),
  ),
  _Probe(
    'TableToken.headerColor',
    (c) => _table(c ? const TableToken(headerColor: _loud) : null),
  ),
  _Probe(
    'TableToken.borderColor',
    (c) => _table(c ? const TableToken(borderColor: _loud) : null),
  ),
  _Probe(
    'TableToken.borderRadius',
    (c) => _table(c ? const TableToken(borderRadius: 0) : null),
  ),
  _Probe(
    'TableToken.fontSize',
    (c) => _table(c ? const TableToken(fontSize: 22) : null),
  ),
  _Probe(
    'TableToken.cellPaddingBlock',
    (c) => _table(c ? const TableToken(cellPaddingBlock: 30) : null),
  ),
  _Probe(
    'TableToken.cellPaddingInline',
    (c) => _table(c ? const TableToken(cellPaddingInline: 40) : null),
  ),
  _Probe(
    'TableToken.cellPaddingBlockSM',
    (c) => _table(
      c ? const TableToken(cellPaddingBlockSM: 30) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'TableToken.cellPaddingInlineSM',
    (c) => _table(
      c ? const TableToken(cellPaddingInlineSM: 40) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'TableToken.cellPaddingBlockLG',
    (c) => _table(
      c ? const TableToken(cellPaddingBlockLG: 30) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'TableToken.cellPaddingInlineLG',
    (c) => _table(
      c ? const TableToken(cellPaddingInlineLG: 40) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'TableToken.rowHoverBg',
    (c) => _table(c ? const TableToken(rowHoverBg: _loud) : null),
    hover: () => find.text('Ann'),
  ),
  _Probe(
    'TableToken.rowSortedBg',
    (c) => _table(
      c ? const TableToken(rowSortedBg: _loud) : null,
      sort: const [TableSort(0, TableSortOrder.ascending)],
    ),
  ),
  _Probe(
    'TableToken.rowSelectedBg',
    (c) => _table(
      c ? const TableToken(rowSelectedBg: _loud) : null,
      selection: const TableSelection<_Row>(selected: [_rows0]),
    ),
  ),
  _Probe(
    'TableToken.rowSelectedHoverBg',
    (c) => _table(
      c ? const TableToken(rowSelectedHoverBg: _loud) : null,
      selection: const TableSelection<_Row>(selected: [_rows0]),
    ),
    hover: () => find.text('Ann'),
  ),
  _Probe(
    'TableToken.selectionColumnWidth',
    (c) => _table(
      c ? const TableToken(selectionColumnWidth: 120) : null,
      selection: const TableSelection<_Row>(selected: [_rows0]),
    ),
  ),
  _Probe(
    'TableToken.footerBg',
    (c) => _table(
      c ? const TableToken(footerBg: _loud) : null,
      footer: const Text('A footer'),
    ),
  ),
  _Probe(
    'TableToken.summaryBg',
    (c) => _table(
      c ? const TableToken(summaryBg: _loud) : null,
      summary: true,
    ),
  ),
  _Probe(
    'TableToken.expandIconSize',
    (c) => _table(
      c ? const TableToken(expandIconSize: 30) : null,
      expandable: TableExpandable<_Row>(
        builder: (_, row, __) => const Text('More'),
      ),
    ),
  ),
  _Probe(
    'TableToken.expandedBg',
    (c) => _table(
      c ? const TableToken(expandedBg: _loud) : null,
      expandable: TableExpandable<_Row>(
        defaultExpanded: const [_rows0],
        builder: (_, row, __) => const Text('More'),
      ),
    ),
  ),
  _Probe(
    'TableToken.indentSize',
    (c) => _table(
      c ? const TableToken(indentSize: 60) : null,
      expandable: TableExpandable<_Row>(
        defaultExpanded: const [_rows0],
        children: (row) =>
            row.name == 'Ann' ? const [_Row('Under', 'Elsewhere')] : const [],
      ),
    ),
  ),
  _Probe(
    'TableToken.headerMarkColor',
    (c) => _table(c ? const TableToken(headerMarkColor: _loud) : null),
  ),
  _Probe(
    'TableToken.headerMarkActiveColor',
    (c) => _table(
      c ? const TableToken(headerMarkActiveColor: _loud) : null,
      sort: const [TableSort(0, TableSortOrder.ascending)],
    ),
  ),
  _Probe(
    'TableToken.sortCaretSize',
    (c) => _table(c ? const TableToken(sortCaretSize: 20) : null),
  ),
  _Probe(
    'TableToken.headerHoverBg',
    (c) => _table(c ? const TableToken(headerHoverBg: _loud) : null),
    hover: () => find.text('Name'),
  ),
  _Probe(
    'TableToken.headerMarkHoverColor',
    (c) => _table(c ? const TableToken(headerMarkHoverColor: _loud) : null),
    hover: () => find.text('Name'),
  ),
  _Probe(
    'TableToken.filterIconSize',
    (c) => _table(
      c ? const TableToken(filterIconSize: 30) : null,
      filterable: true,
    ),
  ),
  _Probe(
    'TableToken.filterHoverBg',
    (c) => _table(
      c ? const TableToken(filterHoverBg: _loud) : null,
      filterable: true,
    ),
    hover: () => _funnel().first,
  ),
  _Probe(
    'TableToken.filterMenuMaxHeight',
    (c) => _table(
      c ? const TableToken(filterMenuMaxHeight: 40) : null,
      filterable: true,
    ),
    act: _openFilter,
  ),
  _Probe(
    'TableToken.filterSearchWidth',
    (c) => _table(
      c ? const TableToken(filterSearchWidth: 320) : null,
      filterable: true,
    ),
    act: _openFilter,
  ),
  _Probe(
    'TableToken.pinnedBg',
    (c) => _table(
      c ? const TableToken(pinnedBg: _loud) : null,
      pinned: true,
      width: 300,
    ),
  ),
  _Probe(
    'TableToken.pinnedShadowColor',
    (c) => _table(
      c ? const TableToken(pinnedShadowColor: _loud) : null,
      pinned: true,
      width: 300,
    ),
    act: _scrollAcross,
  ),
  _Probe(
    'TableToken.pinnedShadowExtent',
    (c) => _table(
      c ? const TableToken(pinnedShadowExtent: 40) : null,
      pinned: true,
      width: 300,
    ),
    act: _scrollAcross,
  ),
  _Probe(
    'FloatButtonToken.size',
    (c) => _float(c ? const FloatButtonToken(size: 90) : null),
  ),
  _Probe(
    'FloatButtonToken.sizeSM',
    (c) => _float(
      c ? const FloatButtonToken(sizeSM: 70) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'FloatButtonToken.sizeLG',
    (c) => _float(
      c ? const FloatButtonToken(sizeLG: 90) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'FloatButtonToken.borderRadius',
    // A round button's corners come from its diameter; only a square one
    // asks the token.
    (c) => _float(
      c ? const FloatButtonToken(borderRadius: 4) : null,
      shape: ButtonShape.defaultShape,
    ),
  ),
  _Probe(
    'FloatButtonToken.shadow',
    (c) => _float(
      c
          ? const FloatButtonToken(
              shadow: [BoxShadow(color: _loud, blurRadius: 10)],
            )
          : null,
    ),
  ),
  _Probe(
    'FloatButtonToken.labelTextColor',
    (c) => _float(
      c ? const FloatButtonToken(labelTextColor: _loud) : null,
      label: const Text('Beside it'),
    ),
  ),
  _Probe(
    'FloatButtonToken.labelFontSize',
    (c) => _float(
      c ? const FloatButtonToken(labelFontSize: 24) : null,
      label: const Text('Beside it'),
    ),
  ),
  _Probe(
    'FloatButtonToken.labelGap',
    (c) => _float(
      c ? const FloatButtonToken(labelGap: 40) : null,
      label: const Text('Beside it'),
    ),
  ),
  _Probe(
    'AvatarToken.containerSize',
    (c) => _avatar(c ? const AvatarToken(containerSize: 72) : null),
  ),
  _Probe(
    'AvatarToken.containerSizeSM',
    (c) => _avatar(
      c ? const AvatarToken(containerSizeSM: 60) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'AvatarToken.containerSizeLG',
    (c) => _avatar(
      c ? const AvatarToken(containerSizeLG: 80) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'AvatarToken.textFontSize',
    // Smaller than the preset, not larger: the initials sit in a FittedBox
    // that scales them *down* to the circle, so two letters already wide
    // enough to touch its sides come out the same size whatever was asked —
    // and how wide "AB" is at 14 differs between the test font on one
    // platform and another. A smaller size is never scaled and always shows.
    (c) => _avatar(c ? const AvatarToken(textFontSize: 6) : null),
  ),
  _Probe(
    'AvatarToken.textFontSizeSM',
    (c) => _avatar(
      c ? const AvatarToken(textFontSizeSM: 6) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'AvatarToken.textFontSizeLG',
    (c) => _avatar(
      c ? const AvatarToken(textFontSizeLG: 8) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'AvatarToken.bg',
    (c) => _avatar(c ? const AvatarToken(bg: _loud) : null),
  ),
  _Probe(
    'AvatarToken.borderRadius',
    // A circle has no corners to round: the radius belongs to the square.
    (c) => _avatar(
      c ? const AvatarToken(borderRadius: 0) : null,
      shape: AvatarShape.square,
    ),
  ),
  _Probe(
    'AvatarToken.colorTextPlaceholder',
    // The mark an avatar falls back to where it was given neither a picture
    // nor words of its own.
    (c) => _avatar(
      c ? const AvatarToken(colorTextPlaceholder: _loud) : null,
      letters: false,
    ),
  ),
  _Probe(
    'AvatarToken.groupBorderColor',
    (c) => AvatarGroup(
      token: c ? const AvatarToken(groupBorderColor: _loud) : null,
      children: const [Avatar(child: Text('A')), Avatar(child: Text('B'))],
    ),
  ),
  _Probe(
    'AvatarToken.groupOverlapping',
    (c) => AvatarGroup(
      token: c ? const AvatarToken(groupOverlapping: 24) : null,
      children: const [Avatar(child: Text('A')), Avatar(child: Text('B'))],
    ),
  ),
  _Probe(
    'SwitchToken.colorPrimary',
    (c) => _switchOf(c ? const SwitchToken(colorPrimary: _loud) : null),
  ),
  _Probe(
    'SwitchToken.colorBg',
    (c) => _switchOf(
      c ? const SwitchToken(colorBg: _loud) : null,
      on: false,
    ),
  ),
  _Probe(
    'SwitchToken.trackHeight',
    (c) => _switchOf(c ? const SwitchToken(trackHeight: 40) : null),
  ),
  _Probe(
    'SwitchToken.trackHeightSM',
    (c) => _switchOf(
      c ? const SwitchToken(trackHeightSM: 32) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'SwitchToken.trackHeightLG',
    (c) => _switchOf(
      c ? const SwitchToken(trackHeightLG: 44) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'SwitchToken.trackMinWidth',
    (c) => _switchOf(c ? const SwitchToken(trackMinWidth: 110) : null),
  ),
  _Probe(
    'SwitchToken.trackMinWidthSM',
    (c) => _switchOf(
      c ? const SwitchToken(trackMinWidthSM: 90) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'SwitchToken.handleSize',
    (c) => _switchOf(c ? const SwitchToken(handleSize: 12) : null),
  ),
  _Probe(
    'SwitchToken.handleSizeSM',
    (c) => _switchOf(
      c ? const SwitchToken(handleSizeSM: 8) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'SwitchToken.handleShadow',
    (c) => _switchOf(
      c
          ? const SwitchToken(
              handleShadow: [BoxShadow(color: _loud, blurRadius: 8)],
            )
          : null,
    ),
  ),
  _Probe(
    'RadioToken.radioSize',
    (c) => _radio(c ? const RadioToken(radioSize: 32) : null),
  ),
  _Probe(
    'RadioToken.dotSize',
    (c) => _radio(c ? const RadioToken(dotSize: 4) : null),
  ),
  _Probe(
    'RadioToken.dotColor',
    (c) => _radio(c ? const RadioToken(dotColor: _loud) : null),
  ),
  _Probe(
    'RadioToken.colorPrimary',
    // A taken radio draws its ring in `dotColor`; the primary colour is what
    // an untaken one answers a pointer with.
    (c) => _radio(
      c ? const RadioToken(colorPrimary: _loud) : null,
      checked: false,
    ),
    hover: () => find.text('Aaa'),
  ),
  _Probe(
    'RadioToken.colorBorder',
    (c) => _radio(
      c ? const RadioToken(colorBorder: _loud) : null,
      checked: false,
    ),
  ),
  _Probe(
    'RadioToken.fontSize',
    (c) => _radio(c ? const RadioToken(fontSize: 24) : null),
  ),
  _Probe(
    'RadioToken.buttonBg',
    (c) => _radioButtons(c ? const RadioToken(buttonBg: _loud) : null),
  ),
  _Probe(
    'RadioToken.buttonCheckedBg',
    (c) => _radioButtons(c ? const RadioToken(buttonCheckedBg: _loud) : null),
  ),
  _Probe(
    'RadioToken.buttonColor',
    (c) => _radioButtons(c ? const RadioToken(buttonColor: _loud) : null),
  ),
  _Probe(
    'BadgeToken.indicatorHeight',
    (c) => _badge(c ? const BadgeToken(indicatorHeight: 32) : null),
  ),
  _Probe(
    'BadgeToken.indicatorHeightSM',
    (c) => _badge(
      c ? const BadgeToken(indicatorHeightSM: 26) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'BadgeToken.fontSize',
    (c) => _badge(c ? const BadgeToken(fontSize: 18) : null),
  ),
  _Probe(
    'BadgeToken.bg',
    (c) => _badge(c ? const BadgeToken(bg: _loud) : null),
  ),
  _Probe(
    'BadgeToken.textColor',
    (c) => _badge(c ? const BadgeToken(textColor: _loud) : null),
  ),
  _Probe(
    'BadgeToken.ringColor',
    (c) => _badge(c ? const BadgeToken(ringColor: _loud) : null),
  ),
  _Probe(
    'BadgeToken.dotSize',
    (c) => _badge(
      c ? const BadgeToken(dotSize: 20) : null,
      count: null,
      dot: true,
    ),
  ),
  _Probe(
    'BadgeToken.statusSize',
    (c) => _badge(
      c ? const BadgeToken(statusSize: 20) : null,
      count: null,
      status: BadgeStatus.processing,
    ),
  ),
  _Probe(
    'RibbonToken.height',
    (c) => _ribbon(c ? const RibbonToken(height: 40) : null),
  ),
  _Probe(
    'RibbonToken.fontSize',
    (c) => _ribbon(c ? const RibbonToken(fontSize: 20) : null),
  ),
  _Probe(
    'RibbonToken.bg',
    (c) => _ribbon(c ? const RibbonToken(bg: _loud) : null),
  ),
  _Probe(
    'RibbonToken.textColor',
    (c) => _ribbon(c ? const RibbonToken(textColor: _loud) : null),
  ),
  _Probe(
    'DropdownToken.menuBg',
    (c) => _dropdown(c ? const DropdownToken(menuBg: _loud) : null),
  ),
  _Probe(
    'DropdownToken.gradient',
    (c) => _dropdown(
      c
          ? const DropdownToken(
              gradient: LinearGradient(colors: [_loud, Color(0xFF00FFAA)]),
            )
          : null,
    ),
  ),
  _Probe(
    'DropdownToken.padding',
    (c) => _dropdown(
      c ? const DropdownToken(padding: EdgeInsets.all(28)) : null,
    ),
  ),
  _Probe(
    'DropdownToken.borderRadius',
    (c) => _dropdown(c ? const DropdownToken(borderRadius: 0) : null),
  ),
  _Probe(
    'DropdownToken.border',
    (c) => _dropdown(
      c
          ? const DropdownToken(border: BorderSide(color: _loud, width: 3))
          : null,
    ),
  ),
  _Probe(
    'DropdownToken.shadow',
    (c) => _dropdown(
      c
          ? const DropdownToken(
              shadow: [BoxShadow(color: _loud, blurRadius: 12)],
            )
          : null,
    ),
  ),
  _Probe(
    'DropdownToken.gap',
    (c) => _dropdown(c ? const DropdownToken(gap: 40) : null),
  ),
  _Probe(
    'DropdownToken.itemHeight',
    (c) => _dropdown(c ? const DropdownToken(itemHeight: 60) : null),
  ),
  _Probe(
    'DropdownToken.itemPadding',
    (c) => _dropdown(
      c ? const DropdownToken(itemPadding: EdgeInsets.all(30)) : null,
    ),
  ),
  _Probe(
    'DropdownToken.itemHoverBg',
    (c) => _dropdown(c ? const DropdownToken(itemHoverBg: _loud) : null),
    // The keyboard rather than the pointer: the same single highlight
    // answers both, and a menu puts a barrier between the page and the
    // pointer that a test's mouse cannot reach past.
    act: _highlightFirstItem,
  ),
  _Probe(
    'PopoverToken.colorBg',
    (c) => _popover(c ? const PopoverToken(colorBg: _loud) : null),
  ),
  _Probe(
    'PopoverToken.titleColor',
    (c) => _popover(c ? const PopoverToken(titleColor: _loud) : null),
  ),
  _Probe(
    'PopoverToken.contentColor',
    (c) => _popover(c ? const PopoverToken(contentColor: _loud) : null),
  ),
  _Probe(
    'PopoverToken.borderRadius',
    (c) => _popover(c ? const PopoverToken(borderRadius: 0) : null),
  ),
  _Probe(
    'PopoverToken.padding',
    (c) => _popover(
      c ? const PopoverToken(padding: EdgeInsets.all(32)) : null,
    ),
  ),
  _Probe(
    'PopoverToken.minWidth',
    (c) => _popover(c ? const PopoverToken(minWidth: 400) : null),
  ),
  _Probe(
    'PopoverToken.maxWidth',
    // Narrow enough to force the line to wrap: a ceiling above what the
    // content asks for changes nothing at all.
    (c) => _popover(c ? const PopoverToken(maxWidth: 120) : null),
  ),
  _Probe(
    'TimelineToken.tailColor',
    (c) => _timeline(c ? const TimelineToken(tailColor: _loud) : null),
  ),
  _Probe(
    'TimelineToken.tailWidth',
    (c) => _timeline(c ? const TimelineToken(tailWidth: 8) : null),
  ),
  _Probe(
    'TimelineToken.dotBg',
    (c) => _timeline(c ? const TimelineToken(dotBg: _loud) : null),
  ),
  _Probe(
    'TimelineToken.dotBorderWidth',
    (c) => _timeline(c ? const TimelineToken(dotBorderWidth: 6) : null),
  ),
  _Probe(
    'TimelineToken.dotSize',
    (c) => _timeline(c ? const TimelineToken(dotSize: 24) : null),
  ),
  _Probe(
    'TimelineToken.railInset',
    (c) => _timeline(
      c ? const TimelineToken(railInset: RailInsets.all(20)) : null,
    ),
  ),
  _Probe(
    'TimelineToken.itemPaddingBottom',
    (c) => _timeline(c ? const TimelineToken(itemPaddingBottom: 60) : null),
  ),
  _Probe(
    'TimelineToken.itemPaddingEnd',
    // The space to the right of an item, which a column of them has no room
    // for: the field belongs to a timeline laid out along a line.
    (c) => _timeline(
      c ? const TimelineToken(itemPaddingEnd: 60) : null,
      orientation: TimelineOrientation.horizontal,
    ),
  ),
  _Probe(
    'DatePickerToken.borderRadius',
    (c) => _datePanel(c ? const DatePickerToken(borderRadius: 0) : null),
    act: _openPicker,
  ),
  _Probe(
    'DatePickerToken.cellWidth',
    (c) => _datePanel(c ? const DatePickerToken(cellWidth: 52) : null),
    act: _openPicker,
  ),
  _Probe(
    'DatePickerToken.cellHeight',
    (c) => _datePanel(c ? const DatePickerToken(cellHeight: 52) : null),
    act: _openPicker,
  ),
  _Probe(
    'DatePickerToken.headerHeight',
    (c) => _datePanel(c ? const DatePickerToken(headerHeight: 80) : null),
    act: _openPicker,
  ),
  _Probe(
    'DatePickerToken.mainAxisSpacing',
    (c) => _datePanel(c ? const DatePickerToken(mainAxisSpacing: 16) : null),
    act: _openPicker,
  ),
  _Probe(
    'DatePickerToken.crossAxisSpacing',
    (c) => _datePanel(c ? const DatePickerToken(crossAxisSpacing: 16) : null),
    act: _openPicker,
  ),
  _Probe(
    'DatePickerToken.presetsWidth',
    (c) => _datePanel(
      c ? const DatePickerToken(presetsWidth: 220) : null,
      withPresets: true,
    ),
    act: _openPicker,
  ),
  _Probe(
    'DatePickerToken.timeColumnWidth',
    (c) => _datePanel(
      c ? const DatePickerToken(timeColumnWidth: 120) : null,
      withTime: true,
    ),
    act: _openPicker,
  ),
  _Probe(
    'TagToken.defaultBg',
    // The fill belongs to the filled variant; an outlined tag stands on
    // nothing at all.
    (c) => _tag(
      c ? const TagToken(defaultBg: _loud) : null,
      variant: TagVariant.filled,
    ),
  ),
  _Probe(
    'TagToken.defaultColor',
    (c) => _tag(c ? const TagToken(defaultColor: _loud) : null),
  ),
  _Probe(
    'TagToken.fontSize',
    (c) => _tag(c ? const TagToken(fontSize: 24) : null),
  ),
  _Probe(
    'TagToken.lineHeight',
    (c) => _tag(c ? const TagToken(lineHeight: 44) : null),
  ),
  _Probe(
    'TagToken.borderRadius',
    (c) => _tag(c ? const TagToken(borderRadius: 0) : null),
  ),
  _Probe(
    'CheckboxToken.boxSize',
    (c) => _checkbox(c ? const CheckboxToken(boxSize: 32) : null),
  ),
  _Probe(
    'CheckboxToken.borderRadius',
    (c) => _checkbox(c ? const CheckboxToken(borderRadius: 0) : null),
  ),
  _Probe(
    'CheckboxToken.colorPrimary',
    (c) => _checkbox(c ? const CheckboxToken(colorPrimary: _loud) : null),
  ),
  _Probe(
    'CheckboxToken.colorBorder',
    (c) => _checkbox(
      c ? const CheckboxToken(colorBorder: _loud) : null,
      checked: false,
    ),
  ),
  _Probe(
    'CheckboxToken.colorBgContainer',
    (c) => _checkbox(
      c ? const CheckboxToken(colorBgContainer: _loud) : null,
      checked: false,
    ),
  ),
  _Probe(
    'CheckboxToken.fontSize',
    (c) => _checkbox(c ? const CheckboxToken(fontSize: 24) : null),
  ),
  _Probe(
    'EmptyToken.imageHeight',
    (c) => _empty(c ? const EmptyToken(imageHeight: 120) : null),
  ),
  _Probe(
    'EmptyToken.colorTextDescription',
    (c) => _empty(c ? const EmptyToken(colorTextDescription: _loud) : null),
  ),
  _Probe(
    'EmptyToken.fontSize',
    (c) => _empty(c ? const EmptyToken(fontSize: 24) : null),
  ),
  _Probe(
    'CountdownToken.fontSize',
    (c) => _countdown(c ? const CountdownToken(fontSize: 40) : null),
  ),
  _Probe(
    'CountdownToken.color',
    (c) => _countdown(c ? const CountdownToken(color: _loud) : null),
  ),
  _Probe(
    'CountdownToken.fontWeight',
    (c) => _countdown(
      c ? const CountdownToken(fontWeight: FontWeight.w900) : null,
    ),
  ),
  _Probe(
    'SpinToken.colorPrimary',
    (c) => _spin(c ? const SpinToken(colorPrimary: _loud) : null),
  ),
  _Probe(
    'SpinToken.dotSize',
    (c) => _spin(c ? const SpinToken(dotSize: 60) : null),
  ),
  _Probe(
    'SpinToken.dotSizeSM',
    (c) => _spin(
      c ? const SpinToken(dotSizeSM: 50) : null,
      size: SoftSize.small,
    ),
  ),
  _Probe(
    'SpinToken.dotSizeLG',
    (c) => _spin(
      c ? const SpinToken(dotSizeLG: 70) : null,
      size: SoftSize.large,
    ),
  ),
  _Probe(
    'ResultToken.titleFontSize',
    (c) => _result(c ? const ResultToken(titleFontSize: 34) : null),
  ),
  _Probe(
    'ResultToken.subtitleFontSize',
    (c) => _result(c ? const ResultToken(subtitleFontSize: 24) : null),
  ),
  _Probe(
    'ResultToken.iconSize',
    (c) => _result(c ? const ResultToken(iconSize: 100) : null),
  ),
  _Probe(
    'ResultToken.padding',
    (c) => _result(
      c ? const ResultToken(padding: EdgeInsets.all(48)) : null,
    ),
  ),
  _Probe(
    'ResultToken.fontWeight',
    (c) => _result(
      c ? const ResultToken(fontWeight: FontWeight.w900) : null,
    ),
  ),
  _Probe(
    'PaginationToken.fontSize',
    (c) => _pagination(c ? const PaginationToken(fontSize: 10) : null),
  ),
  _Probe(
    'PaginationToken.itemActiveColorPrimary',
    (c) => _pagination(
      c ? const PaginationToken(itemActiveColorPrimary: _loud) : null,
    ),
  ),
  _Probe(
    'ListyToken.itemPaddingBlock',
    (c) => _listy(c ? const ListyToken(itemPaddingBlock: 36) : null),
  ),
  _Probe(
    'ListyToken.itemPaddingInline',
    (c) => _listy(c ? const ListyToken(itemPaddingInline: 60) : null),
  ),
  _Probe(
    'CollapseToken.headerBg',
    (c) => _collapse(c ? const CollapseToken(headerBg: _loud) : null),
  ),
  _Probe(
    'CollapseToken.headerPadding',
    (c) => _collapse(
        c ? const CollapseToken(headerPadding: EdgeInsets.all(36)) : null),
  ),
  _Probe(
    'CollapseToken.contentBg',
    (c) => _collapse(c ? const CollapseToken(contentBg: _loud) : null),
  ),
  _Probe(
    'CollapseToken.contentPadding',
    (c) => _collapse(
        c ? const CollapseToken(contentPadding: EdgeInsets.all(40)) : null),
  ),
  _Probe(
    'CollapseToken.borderRadius',
    (c) => _collapse(c ? const CollapseToken(borderRadius: 0) : null),
  ),
  _Probe(
    'TreeToken.titleHeight',
    (c) => _tree(c ? const TreeToken(titleHeight: 56) : null),
  ),
  _Probe(
    'TreeToken.indentSize',
    (c) => _tree(c ? const TreeToken(indentSize: 72) : null),
  ),
  _Probe(
    'TreeToken.borderRadius',
    (c) => _tree(c ? const TreeToken(borderRadius: 0) : null),
  ),
  _Probe(
    'TreeToken.nodeSelectedBg',
    (c) => _tree(c ? const TreeToken(nodeSelectedBg: _loud) : null),
  ),
  _Probe(
    'TreeToken.nodeHoverBg',
    (c) => _tree(
      c ? const TreeToken(nodeHoverBg: _loud) : null,
      selected: const [],
    ),
    hover: () => find.text('Root'),
  ),
  _Probe(
    'SortableListToken.backgroundColor',
    (c) => _sortable(
      c ? const SortableListToken(backgroundColor: _loud) : null,
    ),
    act: _liftRow,
  ),
  _Probe(
    'SortableListToken.liftShadow',
    (c) => _sortable(
      c
          ? const SortableListToken(
              liftShadow: [BoxShadow(color: _loud, blurRadius: 12)],
            )
          : null,
    ),
    act: _liftRow,
  ),
  _Probe(
    'SortableListToken.liftRadius',
    (c) => _sortable(c ? const SortableListToken(liftRadius: 24) : null),
    act: _liftRow,
  ),
  _Probe(
    'TooltipToken.colorBg',
    (c) => _tooltip(c ? const TooltipToken(colorBg: _loud) : null),
    act: _showTooltip,
  ),
  _Probe(
    'TooltipToken.colorText',
    (c) => _tooltip(c ? const TooltipToken(colorText: _loud) : null),
    act: _showTooltip,
  ),
  _Probe(
    'TooltipToken.borderRadius',
    (c) => _tooltip(c ? const TooltipToken(borderRadius: 0) : null),
    act: _showTooltip,
  ),
  _Probe(
    'TooltipToken.padding',
    (c) => _tooltip(
      c ? const TooltipToken(padding: EdgeInsets.all(28)) : null,
    ),
    act: _showTooltip,
  ),
  _Probe(
    'TooltipToken.fontSize',
    (c) => _tooltip(c ? const TooltipToken(fontSize: 24) : null),
    act: _showTooltip,
  ),
  _Probe(
    'AlertToken.padding',
    (c) => _alert(c ? const AlertToken(padding: EdgeInsets.all(36)) : null),
  ),
  _Probe(
    'AlertToken.borderRadius',
    (c) => _alert(c ? const AlertToken(borderRadius: 0) : null),
  ),
  _Probe(
    'AlertToken.fontSize',
    (c) => _alert(c ? const AlertToken(fontSize: 24) : null),
  ),
  _Probe(
    'AlertToken.withDescriptionPadding',
    (c) => _alert(
      c ? const AlertToken(withDescriptionPadding: EdgeInsets.all(36)) : null,
      described: true,
    ),
  ),
  _Probe(
    'AlertToken.withDescriptionIconSize',
    (c) => _alert(
      c ? const AlertToken(withDescriptionIconSize: 44) : null,
      described: true,
      // An alert draws no icon unless asked, and this is that icon's size.
      icon: true,
    ),
  ),
  _Probe(
    'PopconfirmToken.colorBgElevated',
    (c) => _popconfirm(
      c ? const PopconfirmToken(colorBgElevated: _loud) : null,
    ),
    act: _pressAnchor,
  ),
  _Probe(
    'PopconfirmToken.padding',
    (c) => _popconfirm(
      c ? const PopconfirmToken(padding: EdgeInsets.all(36)) : null,
    ),
    act: _pressAnchor,
  ),
  _Probe(
    'PopconfirmToken.borderRadius',
    (c) => _popconfirm(c ? const PopconfirmToken(borderRadius: 0) : null),
    act: _pressAnchor,
  ),
  _Probe(
    'PopconfirmToken.titleFontSize',
    (c) => _popconfirm(
      c ? const PopconfirmToken(titleFontSize: 28) : null,
    ),
    act: _pressAnchor,
  ),
  _Probe(
    'PopconfirmToken.descriptionFontSize',
    (c) => _popconfirm(
      c ? const PopconfirmToken(descriptionFontSize: 24) : null,
    ),
    act: _pressAnchor,
  ),
  _Probe(
    'TimePickerToken.borderRadius',
    (c) => _timePanel(c ? const TimePickerToken(borderRadius: 0) : null),
    act: _openTime,
  ),
  _Probe(
    'TimePickerToken.cellHeight',
    (c) => _timePanel(c ? const TimePickerToken(cellHeight: 48) : null),
    act: _openTime,
  ),
  _Probe(
    'TimePickerToken.columnWidth',
    (c) => _timePanel(c ? const TimePickerToken(columnWidth: 90) : null),
    act: _openTime,
  ),
  _Probe(
    'TimePickerToken.visibleRows',
    (c) => _timePanel(c ? const TimePickerToken(visibleRows: 3) : null),
    act: _openTime,
  ),
  _Probe(
    'TourToken.width',
    // Narrower than the card would otherwise take: a ceiling above what the
    // content asks for changes nothing.
    (c) => _tour(c ? const TourToken(width: 220) : null),
  ),
  _Probe(
    'TourToken.maskColor',
    (c) => _tour(c ? const TourToken(maskColor: _loud) : null),
  ),
  _Probe(
    'TourToken.closeBtnSize',
    (c) => _tour(c ? const TourToken(closeBtnSize: 40) : null),
  ),
  _Probe(
    'TourToken.indicatorSize',
    (c) => _tour(c ? const TourToken(indicatorSize: 20) : null),
  ),
  _Probe(
    'ModalToken.colorBgElevated',
    (c) => _raiseButton(() => Modal.open(const ModalConfig(
          title: Text('A modal'),
          content: Text('With a line in it'),
        ))),
    theme: (c) => ComponentsConfig(
        modal: c ? const ModalToken(colorBgElevated: _loud) : null),
    act: _pressRaise,
  ),
  _Probe(
    'ModalToken.colorBgMask',
    (c) => _raiseButton(() => Modal.open(const ModalConfig(
          title: Text('A modal'),
          content: Text('With a line in it'),
        ))),
    theme: (c) => ComponentsConfig(
        modal: c ? const ModalToken(colorBgMask: _loud) : null),
    act: _pressRaise,
  ),
  _Probe(
    'ModalToken.padding',
    (c) => _raiseButton(() => Modal.open(const ModalConfig(
          title: Text('A modal'),
          content: Text('With a line in it'),
        ))),
    theme: (c) => ComponentsConfig(
        modal: c ? const ModalToken(padding: EdgeInsets.all(48)) : null),
    act: _pressRaise,
  ),
  _Probe(
    'ModalToken.borderRadius',
    (c) => _raiseButton(() => Modal.open(const ModalConfig(
          title: Text('A modal'),
          content: Text('With a line in it'),
        ))),
    theme: (c) =>
        ComponentsConfig(modal: c ? const ModalToken(borderRadius: 0) : null),
    act: _pressRaise,
  ),
  _Probe(
    'ModalToken.titleFontSize',
    (c) => _raiseButton(() => Modal.open(const ModalConfig(
          title: Text('A modal'),
          content: Text('With a line in it'),
        ))),
    theme: (c) =>
        ComponentsConfig(modal: c ? const ModalToken(titleFontSize: 32) : null),
    act: _pressRaise,
  ),
  _Probe(
    'ModalToken.contentFontSize',
    (c) => _raiseButton(() => Modal.open(const ModalConfig(
          title: Text('A modal'),
          content: Text('With a line in it'),
        ))),
    theme: (c) => ComponentsConfig(
        modal: c ? const ModalToken(contentFontSize: 26) : null),
    act: _pressRaise,
  ),
  _Probe(
    'DrawerToken.colorBgElevated',
    (c) => _raiseButton(() => Drawer.open(const DrawerConfig(
          title: Text('A drawer'),
          child: Text('With a line in it'),
        ))),
    theme: (c) => ComponentsConfig(
        drawer: c ? const DrawerToken(colorBgElevated: _loud) : null),
    act: _pressRaise,
  ),
  _Probe(
    'DrawerToken.colorBgMask',
    (c) => _raiseButton(() => Drawer.open(const DrawerConfig(
          title: Text('A drawer'),
          child: Text('With a line in it'),
        ))),
    theme: (c) => ComponentsConfig(
        drawer: c ? const DrawerToken(colorBgMask: _loud) : null),
    act: _pressRaise,
  ),
  _Probe(
    'DrawerToken.padding',
    (c) => _raiseButton(() => Drawer.open(const DrawerConfig(
          title: Text('A drawer'),
          child: Text('With a line in it'),
        ))),
    theme: (c) => ComponentsConfig(
        drawer: c ? const DrawerToken(padding: EdgeInsets.all(48)) : null),
    act: _pressRaise,
  ),
  _Probe(
    'MessageToken.colorBgElevated',
    (c) => _raiseButton(
      () => message.open(
        MessageConfig(
          content: const Text('A word'),
          token: c ? const MessageToken(colorBgElevated: _loud) : null,
        ),
      ),
    ),
    act: _pressBriefly,
  ),
  _Probe(
    'MessageToken.contentColor',
    (c) => _raiseButton(
      () => message.open(
        MessageConfig(
          content: const Text('A word'),
          token: c ? const MessageToken(contentColor: _loud) : null,
        ),
      ),
    ),
    act: _pressBriefly,
  ),
  _Probe(
    'MessageToken.padding',
    (c) => _raiseButton(
      () => message.open(
        MessageConfig(
          content: const Text('A word'),
          token: c ? const MessageToken(padding: EdgeInsets.all(36)) : null,
        ),
      ),
    ),
    act: _pressBriefly,
  ),
  _Probe(
    'MessageToken.borderRadius',
    (c) => _raiseButton(
      () => message.open(
        MessageConfig(
          content: const Text('A word'),
          token: c ? const MessageToken(borderRadius: 0) : null,
        ),
      ),
    ),
    act: _pressBriefly,
  ),
  _Probe(
    'NotificationToken.colorBgElevated',
    (c) => _raiseButton(() => notification.open(const NotificationConfig(
          message: Text('A notice'),
          description: Text('And what it says'),
        ))),
    theme: (c) => ComponentsConfig(
        notification:
            c ? const NotificationToken(colorBgElevated: _loud) : null),
    act: _pressBriefly,
  ),
  _Probe(
    'NotificationToken.padding',
    (c) => _raiseButton(() => notification.open(const NotificationConfig(
          message: Text('A notice'),
          description: Text('And what it says'),
        ))),
    theme: (c) => ComponentsConfig(
        notification:
            c ? const NotificationToken(padding: EdgeInsets.all(40)) : null),
    act: _pressBriefly,
  ),
  _Probe(
    'NotificationToken.borderRadius',
    (c) => _raiseButton(() => notification.open(const NotificationConfig(
          message: Text('A notice'),
          description: Text('And what it says'),
        ))),
    theme: (c) => ComponentsConfig(
        notification: c ? const NotificationToken(borderRadius: 0) : null),
    act: _pressBriefly,
  ),
  _Probe(
    'NotificationToken.titleFontSize',
    (c) => _raiseButton(() => notification.open(const NotificationConfig(
          message: Text('A notice'),
          description: Text('And what it says'),
        ))),
    theme: (c) => ComponentsConfig(
        notification: c ? const NotificationToken(titleFontSize: 30) : null),
    act: _pressBriefly,
  ),
  _Probe(
    'NotificationToken.descriptionFontSize',
    (c) => _raiseButton(() => notification.open(const NotificationConfig(
          message: Text('A notice'),
          description: Text('And what it says'),
        ))),
    theme: (c) => ComponentsConfig(
        notification:
            c ? const NotificationToken(descriptionFontSize: 24) : null),
    act: _pressBriefly,
  ),
  _Probe(
    'NotificationToken.width',
    (c) => _raiseButton(() => notification.open(const NotificationConfig(
          message: Text('A notice'),
          description: Text('And what it says'),
        ))),
    theme: (c) => ComponentsConfig(
        notification: c ? const NotificationToken(width: 500) : null),
    act: _pressBriefly,
  ),
  _Probe(
    'DropdownToken.barrierColor',
    (c) => _dropdown(c ? const DropdownToken(barrierColor: _loud) : null),
  ),
  _Probe(
    'SegmentedToken.arrowBg',
    (c) => _narrowSegmented(c ? const SegmentedToken(arrowBg: _loud) : null),
  ),
  _Probe(
    'SegmentedToken.arrowColor',
    (c) => _narrowSegmented(c ? const SegmentedToken(arrowColor: _loud) : null),
  ),
  _Probe(
    'SegmentedToken.arrowHoverBg',
    (c) =>
        _narrowSegmented(c ? const SegmentedToken(arrowHoverBg: _loud) : null),
    hoverAt: (tester) {
      final box = tester.getRect(find.byType(Segmented<String>));
      return Offset(box.right - 12, box.center.dy);
    },
  ),
  _Probe(
    'SliderToken.markFontSize',
    (c) => _slider(c ? const SliderToken(markFontSize: 22) : null),
  ),
  _Probe(
    'SliderToken.markDisabledColor',
    (c) => SizedBox(
      width: 260,
      child: Slider(
        value: 40,
        // A mark the handle may not rest on is greyed rather than hidden,
        // and this is the grey.
        marks: const [SliderMark(0, 'nil', disabled: true)],
        onChanged: (_) {},
        token: c ? const SliderToken(markDisabledColor: _loud) : null,
      ),
    ),
  ),
  _Probe(
    'SpinToken.colorBgContainer',
    // The wash a spinner lays over what it is covering: without something
    // underneath there is nothing to cover and no wash is drawn.
    (c) => SizedBox(
      width: 200,
      height: 120,
      child: Spin(
        token: c ? const SpinToken(colorBgContainer: _loud) : null,
        child: const Text('Underneath'),
      ),
    ),
  ),
  _Probe(
    'TourToken.primaryPrevBtnBg',
    (c) => _tour(
      c ? const TourToken(primaryPrevBtnBg: _loud) : null,
      type: TourType.primary,
    ),
  ),
  _Probe(
    'PopconfirmToken.barrierColor',
    (c) => _popconfirm(c ? const PopconfirmToken(barrierColor: _loud) : null),
    act: _pressAnchor,
  ),
  _Probe(
    'FloatButtonToken.gap',
    // The space between a group's buttons, which a group of one has none of.
    (c) => FloatButtonGroup(
      open: true,
      token: c ? const FloatButtonToken(gap: 40) : null,
      items: const [
        FloatButtonItem(value: 'a', icon: Icon(Icons.edit)),
        FloatButtonItem(value: 'b', icon: Icon(Icons.share)),
      ],
    ),
  ),
];
