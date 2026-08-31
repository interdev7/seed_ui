import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    hide
        Badge,
        ThemeData,
        Checkbox,
        Radio,
        RadioGroup,
        Switch,
        Tooltip,
        Drawer,
        Slider;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

/// What each item reports through `onItemTap`. An enum, so the `switch` that
/// handles them is exhaustive and a forgotten case will not compile.
enum FabAction { edit, share, copy, bin }

class FloatButtonDemo extends StatefulWidget {
  const FloatButtonDemo({super.key});

  @override
  State<FloatButtonDemo> createState() => _FloatButtonDemoState();
}

class _FloatButtonDemoState extends State<FloatButtonDemo> {
  static const _actions = <FloatButtonItem<FabAction>>[
    FloatButtonItem(
      value: FabAction.edit,
      label: 'Edit',
      icon: Icon(Icons.edit),
    ),
    FloatButtonItem(
      value: FabAction.share,
      label: 'Share',
      icon: Icon(Icons.share),
    ),
    FloatButtonItem(
      value: FabAction.copy,
      label: 'Copy',
      icon: Icon(Icons.copy),
    ),
    FloatButtonItem(
      value: FabAction.bin,
      label: 'Delete',
      icon: Icon(Icons.delete),
      // An item may differ from its group.
      color: ButtonColor.danger,
    ),
  ];

  static const _layouts = <(String, FloatButtonLayout)>[
    ('vertical', FloatButtonLayout.vertical()),
    ('horizontal', FloatButtonLayout.horizontal()),
    ('fan', FloatButtonLayout.fan()),
    ('grid(2)', FloatButtonLayout.grid(2)),
  ];

  final _controller = FloatButtonController();
  String _layout = 'fan';
  double _jitter = 0;
  double? _radius;
  ControlSize _size = SoftSize.middle;
  FloatButtonDirection _direction = FloatButtonDirection.auto;
  int _count = 4;
  Curve _curve = Curves.easeOutBack;
  FloatButtonLabelPlacement _labels = FloatButtonLabelPlacement.auto;
  bool _dismissible = true;
  bool _closeOnSelect = true;
  FabAction? _last;
  int _seed = 7;

  /// The stage's items, padded out past the four named ones so a run long
  /// enough to have nowhere left to go can actually be tried.
  List<FloatButtonItem<FabAction>> get _stageItems => [
    for (var i = 0; i < _count; i++)
      i < _actions.length
          ? _actions[i]
          : FloatButtonItem(
              value: FabAction.values[i % FabAction.values.length],
              label: 'Item ${i + 1}',
              icon: const Icon(Icons.circle_outlined),
            ),
  ];

  FloatButtonLayout get _chosen => _layout == 'fan'
      ? FloatButtonLayout.fan(jitter: _jitter, radius: _radius, seed: _seed)
      : _layouts.firstWhere((e) => e.$1 == _layout).$2;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTap(FabAction? value) {
    debugPrint('$value');
    setState(() => _last = value);
  }

  /// A stage with room for a group to open into, parked bottom right the way
  /// a float button really is.
  Widget _stage(Widget group) => Container(
    height: 260,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0x22000000)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Stack(children: [Positioned(right: 16, bottom: 16, child: group)]),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Group(
          'On its own',
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              FloatButton(icon: const Icon(Icons.search), onPressed: () {}),
              FloatButton(
                icon: const Icon(Icons.person),
                color: ButtonColor.primary,
                onPressed: () {},
              ),
              FloatButton(
                icon: const Icon(Icons.search),
                shape: ButtonShape.defaultShape,
                onPressed: () {},
              ),
              // No badge prop: Badge already wraps.
              Badge(
                count: 5,
                child: FloatButton(
                  icon: const Icon(Icons.mail),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        Group(
          'A label rides outside the button',
          Padding(
            padding: const EdgeInsets.only(left: 96, top: 8, bottom: 8),
            child: Wrap(
              spacing: 96,
              runSpacing: 24,
              children: [
                FloatButton(
                  icon: const Icon(Icons.person),
                  label: const Text('Profile'),
                  onPressed: () {},
                ),
                FloatButton(
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                  labelPlacement: FloatButtonLabelPlacement.right,
                  color: ButtonColor.primary,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
        Group(
          'Layouts',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Segmented<String>(
                size: SoftSize.small,
                value: _layout,
                options: [
                  for (final l in _layouts)
                    SegmentedOption(value: l.$1, label: l.$1),
                ],
                onChanged: (v) => setState(() => _layout = v),
              ),
              const SizedBox(height: 12),
              _stage(
                FloatButtonGroup<FabAction>(
                  layout: _chosen,
                  color: ButtonColor.primary,
                  labelPlacement: _labels,
                  direction: _direction,
                  size: _size,
                  token: FloatButtonToken(curve: _curve),
                  dismissible: _dismissible,
                  closeOnSelect: _closeOnSelect,
                  items: _stageItems,
                  // One hook covers every wrapper, which is why there is no
                  // tooltip prop, and no badge prop either.
                  itemBuilder: (context, item, child) {
                    if (kIsWeb) {
                      return Tooltip(
                        message: Text(item.label ?? ''),
                        child: child,
                      );
                    }
                    return child;
                  },
                  onItemTap: _onItemTap,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text("Seed: $_seed"),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _seed.toDouble(),
                      min: 0,
                      max: 25,
                      step: 1,
                      onChanged: (v) => setState(() => _seed = v.toInt()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Segmented<double>(
                size: SoftSize.small,
                value: _jitter,
                options: const [
                  SegmentedOption(value: 0.0, label: 'jitter: 0'),
                  SegmentedOption(value: 0.5, label: '0.5'),
                  SegmentedOption(value: 1.0, label: '1'),
                ],
                onChanged: (v) => setState(() {
                  _jitter = v;
                  _layout = 'fan';
                }),
              ),
              const SizedBox(height: 8),
              Segmented<double?>(
                size: SoftSize.small,
                value: _radius,
                options: const [
                  SegmentedOption(value: null, label: 'radius: auto'),
                  SegmentedOption(value: 90.0, label: '90'),
                  SegmentedOption(value: 150.0, label: '150'),
                ],
                onChanged: (v) => setState(() {
                  _radius = v;
                  _layout = 'fan';
                }),
              ),
              const SizedBox(height: 8),
              Segmented<Curve>(
                size: SoftSize.small,
                value: _curve,
                options: const [
                  SegmentedOption(value: Curves.linear, label: 'linear'),
                  SegmentedOption(value: Curves.easeOutCubic, label: 'easeOut'),
                  SegmentedOption(
                    value: Curves.easeOutBack,
                    label: 'easeOutBack',
                  ),
                  SegmentedOption(
                    value: Curves.elasticOut,
                    label: 'elasticOut',
                  ),
                  SegmentedOption(value: Curves.bounceOut, label: 'bounceOut'),
                  SegmentedOption(value: Curves.easeInCubic, label: 'easeIn'),
                  SegmentedOption(
                    value: Curves.easeInBack,
                    label: 'easeInBack',
                  ),
                  SegmentedOption(value: Curves.elasticIn, label: 'elasticIn'),
                  SegmentedOption(value: Curves.bounceIn, label: 'bounceIn'),
                  SegmentedOption(value: Curves.easeInOut, label: 'easeInOut'),
                  SegmentedOption(
                    value: Curves.easeInOutBack,
                    label: 'easeInOutBack',
                  ),
                ],
                onChanged: (v) => setState(() => _curve = v),
              ),
              const SizedBox(height: 8),
              // Eight ways round the compass plus auto. `top` is the one four
              // corners could never say, and it is what a centred group wants.
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final d in FloatButtonDirection.values)
                    Button(
                      size: SoftSize.small,
                      variant: _direction == d
                          ? ButtonVariant.solid
                          : ButtonVariant.outlined,
                      color: ButtonColor.primary,
                      onPressed: () => setState(() => _direction = d),
                      child: Text(d.name),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Segmented<int>(
                size: SoftSize.small,
                value: _count,
                options: const [
                  SegmentedOption(value: 2, label: '2 items'),
                  SegmentedOption(value: 4, label: '4 items'),
                  SegmentedOption(value: 6, label: '6 items'),
                  SegmentedOption(value: 8, label: '8 items'),
                  SegmentedOption(value: 10, label: '10 items'),
                  SegmentedOption(value: 12, label: '12 items'),
                ],
                onChanged: (v) => setState(() => _count = v),
              ),
              const SizedBox(height: 8),
              Segmented<ControlSize>(
                size: SoftSize.small,
                value: _size,
                options: const [
                  SegmentedOption(value: SoftSize.small, label: 'small'),
                  SegmentedOption(value: SoftSize.middle, label: 'middle'),
                  SegmentedOption(value: SoftSize.large, label: 'large'),
                  SegmentedOption(
                    value: ControlSize.height(72),
                    label: 'height(72)',
                  ),
                ],
                onChanged: (v) => setState(() => _size = v),
              ),
              const SizedBox(height: 8),
              Segmented<bool>(
                size: SoftSize.small,
                value: _dismissible,
                options: const [
                  SegmentedOption(value: true, label: 'dismissible: true'),
                  SegmentedOption(value: false, label: 'false'),
                ],
                onChanged: (v) => setState(() => _dismissible = v),
              ),
              const SizedBox(height: 8),
              Segmented<bool>(
                size: SoftSize.small,
                value: _closeOnSelect,
                options: const [
                  SegmentedOption(value: true, label: 'closeOnSelect: true'),
                  SegmentedOption(value: false, label: 'false'),
                ],
                onChanged: (v) => setState(() => _closeOnSelect = v),
              ),
              const SizedBox(height: 8),
              Segmented<FloatButtonLabelPlacement>(
                size: SoftSize.small,
                value: _labels,
                options: [
                  for (final p in FloatButtonLabelPlacement.values)
                    SegmentedOption(value: p, label: p.name),
                ],
                onChanged: (v) => setState(() => _labels = v),
              ),
              const SizedBox(height: 8),
              Text(
                'Every control here steers the stage above it. The group reads '
                'its direction off the trigger, so a stage near the top of the '
                'window opens downwards — the rule working, not a fault. '
                'radius: auto stands the items clear of one another; a radius '
                'of your own is taken as given, crowding and all. Raising '
                'jitter sends the items out to different distances along '
                'their spokes, which is what reads as scatter, and the same '
                'seed arranges them the same way every time. The curve shapes '
                'the opening: easeOutBack and elasticOut overshoot and settle, '
                'bounceOut lands twice. Park the stage centrally and pick a '
                'row of 12: with nowhere left to run it folds into rows rather '
                'than sending half the buttons off the screen. The page below '
                'keeps scrolling while the group is open, and a tap outside '
                'spends itself on closing.'
                '${_last == null ? '' : '  Last tapped: ${_last!.name}.'}',
              ),
            ],
          ),
        ),
        Group(
          'Driven by a controller',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  Button(
                    onPressed: _controller.open,
                    child: const Text('Open'),
                  ),
                  Button(
                    onPressed: _controller.close,
                    child: const Text('Close'),
                  ),
                  Button(
                    onPressed: _controller.toggle,
                    child: const Text('Toggle'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _stage(
                FloatButtonGroup<FabAction>(
                  controller: _controller,
                  layout: const FloatButtonLayout.vertical(),
                  items: _actions,
                ),
              ),
            ],
          ),
        ),
        Group(
          'Opened by hovering',
          _stage(
            const FloatButtonGroup<FabAction>(
              trigger: FloatButtonTrigger.hover,
              layout: FloatButtonLayout.horizontal(),
              items: _actions,
            ),
          ),
        ),
      ],
    );
  }
}
