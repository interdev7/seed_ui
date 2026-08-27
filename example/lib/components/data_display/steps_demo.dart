import 'package:flutter/material.dart'
    hide
        ThemeData,
        Checkbox,
        Radio,
        RadioGroup,
        Switch,
        Tooltip,
        Drawer,
        Card,
        Step;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class StepsDemo extends StatefulWidget {
  const StepsDemo({super.key});

  @override
  State<StepsDemo> createState() => _StepsDemoState();
}

class _StepsDemoState extends State<StepsDemo> {
  // A wizard driven from the outside: the buttons below move the run.
  final StepsController _wizard = StepsController();

  int _clickable = 1;
  StepsVariant _variant = StepsVariant.filled;
  double _percent = 0.6;
  double _railInset = 16;
  double _panelMinWidth = 160;
  int _long = 3;
  double _maxCount = -1;
  ControlSize _navSize = SoftSize.middle;
  double _navWidth = 0; // 0 stands for "as wide as the text"
  double _panelWidth = 0; // 0 stands for "as wide as the longest text"
  double _panelHeight = 0;
  ControlSize _size = SoftSize.middle;
  double _railLength = 0; // 0 stands for "let the titles decide"

  @override
  void dispose() {
    _wizard.dispose();
    super.dispose();
  }

  /// Short titles, so the rails keep room to give: see the rail-inset group.
  static const _spacious = [
    StepItem(title: Text('One')),
    StepItem(title: Text('Two')),
    StepItem(title: Text('Three')),
    StepItem(title: Text('Four')),
  ];

  static const _checkout = [
    StepItem(title: Text('Cart'), content: Text('3 items · \$4200')),
    StepItem(title: Text('Delivery'), content: Text('Pick a date')),
    StepItem(title: Text('Payment'), content: Text('Card or on delivery')),
    StepItem(title: Text('Done')),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Group('Basic', Steps(current: 1, items: _checkout)),

        // The controller is the wizard case: the run shows where you are, the
        // buttons move it.
        Group(
          'Controller — a wizard',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Steps(controller: _wizard, items: _checkout),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: _wizard,
                builder: (context, _) => Row(
                  children: [
                    Button(
                      onPressed: _wizard.current == 0 ? null : _wizard.previous,
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      variant: ButtonVariant.solid,
                      color: ButtonColor.primary,
                      onPressed: _wizard.current == _checkout.length - 1
                          ? null
                          : _wizard.next,
                      child: const Text('Next'),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'step ${_wizard.current + 1} of ${_checkout.length}',
                      style: TextStyle(color: t.colorTextTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Group(
          'Clickable',
          Steps(
            current: _clickable,
            onChange: (i) => setState(() => _clickable = i),
            items: const [
              StepItem(title: Text('One'), content: Text('Tap me')),
              StepItem(title: Text('Two'), content: Text('Or me')),
              StepItem(
                title: Text('Three'),
                content: Text('Not me'),
                disabled: true,
              ),
            ],
          ),
        ),

        const Group(
          'Vertical',
          Steps(
            orientation: StepsOrientation.vertical,
            current: 1,
            items: _checkout,
          ),
        ),

        const Group(
          'Status & per-item override',
          Steps(
            current: 2,
            status: StepStatus.error,
            items: [
              StepItem(title: Text('Uploaded')),
              StepItem(title: Text('Scanned')),
              StepItem(title: Text('Published'), content: Text('Rejected')),
              StepItem(title: Text('Live')),
            ],
          ),
        ),

        // `percent` rings the current marker — for a step that is itself
        // measurable, such as an upload.
        Group(
          'Progress ring on the current step — ${(_percent * 100).round()}%',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The ring goes round the current marker, so it belongs to the
              // numbered types — `percent` is limited the same way.
              Steps(current: 1, percent: _percent, items: _checkout),
              const SizedBox(height: 12),
              Steps(
                orientation: StepsOrientation.vertical,
                current: 1,
                percent: _percent,
                items: _checkout,
              ),
              const SizedBox(height: 12),
              // The ring is the kit's own Progress, so a template restyles it
              // — here a dashboard ring in the warning colour.
              Steps(
                current: 1,
                percent: _percent,
                progress: Progress(
                  percent: 0,
                  type: ProgressType.dashboard,
                  color: t.warning.base,
                  strokeWidth: 4,
                ),
                items: _checkout,
              ),
              const SizedBox(height: 12),
              Segmented<double>(
                size: SoftSize.small,
                value: _percent,
                options: const [
                  SegmentedOption(value: 0.2, label: '20%'),
                  SegmentedOption(value: 0.6, label: '60%'),
                  SegmentedOption(value: 0.9, label: '90%'),
                ],
                onChanged: (v) => setState(() => _percent = v),
              ),
            ],
          ),
        ),

        const Group(
          'Dots',
          Steps(type: StepsType.dot, current: 1, items: _checkout),
        ),

        // How far the rail keeps from the markers — and, in a horizontal run,
        // from the text it starts after.
        Group(
          'Rail inset',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Segmented<double>(
                size: SoftSize.small,
                value: _railInset,
                options: const [
                  SegmentedOption(value: 0, label: 'flush'),
                  SegmentedOption(value: 8, label: '8'),
                  SegmentedOption(value: 16, label: '16 (default)'),
                  SegmentedOption(value: 32, label: '32'),
                ],
                onChanged: (v) => setState(() => _railInset = v),
              ),
              const SizedBox(height: 12),
              // Short titles on purpose. The rail is the give in the layout,
              // and it has a floor it will not go below; a run whose steps
              // already fill the width leaves every rail sitting on that floor,
              // where a bigger inset has no room left to take and the line
              // stops changing. The checkout run above is exactly that case.
              Steps(
                current: 1,
                items: _spacious,
                token: StepsToken(railInset: RailInsets.all(_railInset)),
              ),
              const SizedBox(height: 8),
              Text(
                'The same run with the long checkout titles: its rails are '
                'already at their shortest, so the inset has nothing left to '
                'take and only the roomiest line still moves.',
                style: TextStyle(color: t.colorTextTertiary),
              ),
              const SizedBox(height: 8),
              Steps(
                current: 1,
                items: _checkout,
                token: StepsToken(railInset: RailInsets.all(_railInset)),
              ),
              const SizedBox(height: 12),
              Steps(
                orientation: StepsOrientation.vertical,
                current: 1,
                items: _spacious,
                token: StepsToken(railInset: RailInsets.all(_railInset)),
              ),
            ],
          ),
        ),

        const Group(
          'Inline — the dot run in miniature: rails kept, content dropped',
          Steps(type: StepsType.inline, current: 1, items: _checkout),
        ),

        Group(
          'Navigation',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Steps(
                type: StepsType.navigation,
                current: _clickable,
                onChange: (i) => setState(() => _clickable = i),
                items: const [
                  StepItem(title: Text('Details'), subTitle: Text('00:02')),
                  StepItem(title: Text('Review'), subTitle: Text('00:05')),
                  StepItem(title: Text('Publish')),
                ],
              ),
              const SizedBox(height: 12),
              // Blocks take their size from their text; name a width or a
              // height and that is taken instead, and `size` scales the whole
              // block — marker, type and padding.
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Segmented<ControlSize>(
                    size: SoftSize.small,
                    value: _navSize,
                    options: const [
                      SegmentedOption(value: SoftSize.small, label: 'small'),
                      SegmentedOption(value: SoftSize.middle, label: 'middle'),
                      SegmentedOption(value: SoftSize.large, label: 'large'),
                    ],
                    onChanged: (v) => setState(() => _navSize = v),
                  ),
                  Segmented<double>(
                    size: SoftSize.small,
                    value: _navWidth,
                    options: const [
                      SegmentedOption(value: 0, label: 'by text'),
                      SegmentedOption(value: 140, label: 'width 140'),
                      SegmentedOption(value: 220, label: 'width 220'),
                    ],
                    onChanged: (v) => setState(() => _navWidth = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Steps(
                type: StepsType.navigation,
                size: _navSize,
                current: _clickable,
                onChange: (i) => setState(() => _clickable = i),
                token: StepsToken(itemWidth: _navWidth == 0 ? null : _navWidth),
                items: const [
                  StepItem(title: Text('Details'), subTitle: Text('00:02')),
                  StepItem(title: Text('Review'), subTitle: Text('00:05')),
                  StepItem(title: Text('Publish')),
                ],
              ),
              const SizedBox(height: 12),
              // Squeezed below what its blocks need, the run scrolls rather
              // than crushing them — drag it sideways.
              Text(
                'the same run at 280 px',
                style: TextStyle(color: t.colorTextTertiary),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 280,
                  child: Steps(
                    type: StepsType.navigation,
                    current: _clickable,
                    onChange: (i) => setState(() => _clickable = i),
                    items: const [
                      StepItem(title: Text('Details'), subTitle: Text('00:02')),
                      StepItem(title: Text('Review'), subTitle: Text('00:05')),
                      StepItem(title: Text('Publish')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Arrow-shaped panels, coloured by status: the step in play is solid,
        // a failed one is tinted red, the ones ahead stay grey. The kit
        // strokes each panel *and* the arrow between them, doubling the seams;
        // here the strip is painted in one pass, so each line is drawn once.
        Group(
          'Panels',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Segmented<StepsVariant>(
                size: SoftSize.small,
                value: _variant,
                options: const [
                  SegmentedOption(value: StepsVariant.filled, label: 'filled'),
                  SegmentedOption(
                    value: StepsVariant.outlined,
                    label: 'outlined',
                  ),
                ],
                onChanged: (v) => setState(() => _variant = v),
              ),
              const SizedBox(height: 12),
              Steps(
                type: StepsType.panel,
                variant: _variant,
                current: _clickable,
                onChange: (i) => setState(() => _clickable = i),
                items: _checkout,
              ),
              const SizedBox(height: 12),
              // With a failed step, so the per-status colours show.
              Steps(
                type: StepsType.panel,
                variant: _variant,
                current: 1,
                items: const [
                  StepItem(
                    title: Text('Step 1'),
                    subTitle: Text('00:00'),
                    content: Text('This is a content.'),
                  ),
                  StepItem(
                    title: Text('Step 2'),
                    content: Text('This is a content.'),
                    status: StepStatus.error,
                  ),
                  StepItem(
                    title: Text('Step 3'),
                    content: Text('This is a content.'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // The floor on a panel's width. Given the room the panels share
              // it; squeezed below the floor the strip scrolls instead of
              // crushing them.
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Panel width floor'),
                  Segmented<double>(
                    size: SoftSize.small,
                    value: _panelMinWidth,
                    options: const [
                      SegmentedOption(value: 100, label: '100'),
                      SegmentedOption(value: 160, label: '160 (default)'),
                      SegmentedOption(value: 260, label: '260'),
                    ],
                    onChanged: (v) => setState(() => _panelMinWidth = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Short panels in a narrow box, which is the only place a floor
              // can be seen at all: a panel is never narrower than its own
              // text, so a run whose content already asks for more than the
              // floor ignores it entirely. Squeezed below it the strip
              // scrolls rather than crushing the panels.
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 300,
                  child: Steps(
                    type: StepsType.panel,
                    variant: _variant,
                    current: _clickable,
                    onChange: (i) => setState(() => _clickable = i),
                    items: const [
                      StepItem(title: Text('One')),
                      StepItem(title: Text('Two')),
                      StepItem(title: Text('Three')),
                    ],
                    token: StepsToken(panelMinWidth: _panelMinWidth),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The checkout run at the same setting: its panels carry enough '
                'text to be wider than every floor offered, so the setting has '
                'nothing to raise and the strip does not move.',
                style: TextStyle(color: t.colorTextTertiary),
              ),
              const SizedBox(height: 8),
              Steps(
                type: StepsType.panel,
                variant: _variant,
                current: _clickable,
                onChange: (i) => setState(() => _clickable = i),
                items: _checkout,
                token: StepsToken(panelMinWidth: _panelMinWidth),
              ),
              const SizedBox(height: 16),
              // Panels take their size from the longest title/content, so a
              // strip is as wide as it needs to be and no wider. Name a width
              // or a height and that is taken instead.
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Panel size'),
                  Segmented<double>(
                    size: SoftSize.small,
                    value: _panelWidth,
                    options: const [
                      SegmentedOption(value: 0, label: 'by content'),
                      SegmentedOption(value: 120, label: 'width 120'),
                      SegmentedOption(value: 240, label: 'width 240'),
                    ],
                    onChanged: (v) => setState(() => _panelWidth = v),
                  ),
                  Segmented<double>(
                    size: SoftSize.small,
                    value: _panelHeight,
                    options: const [
                      SegmentedOption(value: 0, label: 'auto height'),
                      SegmentedOption(value: 96, label: 'height 96'),
                      SegmentedOption(value: 160, label: 'height 160'),
                    ],
                    onChanged: (v) => setState(() => _panelHeight = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Steps(
                type: StepsType.panel,
                variant: _variant,
                current: _clickable,
                onChange: (i) => setState(() => _clickable = i),
                items: _checkout,
                token: StepsToken(
                  panelWidth: _panelWidth == 0 ? null : _panelWidth,
                  panelHeight: _panelHeight == 0 ? null : _panelHeight,
                ),
              ),
              const SizedBox(height: 16),
              // `size` reaches the panels too: smaller type, tighter padding,
              // a smaller corner radius, a shorter arrow and a lower width
              // floor — the small panel run.
              Steps(
                type: StepsType.panel,
                variant: _variant,
                size: SoftSize.small,
                current: _clickable,
                onChange: (i) => setState(() => _clickable = i),
                items: _checkout,
              ),
              const SizedBox(height: 16),
              // Vertical panels: the same shape turned a quarter, each
              // pointing down into the next.
              Steps(
                type: StepsType.panel,
                variant: _variant,
                orientation: StepsOrientation.vertical,
                current: _clickable,
                onChange: (i) => setState(() => _clickable = i),
                items: _checkout,
              ),
            ],
          ),
        ),

        // A run too long for the space folds: the first step, the last, the
        // one in play and its neighbours stay, and each hidden stretch becomes
        // a single ellipsis marker — `maxCount`.
        Group(
          'Max count — folding a long run',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Segmented<double>(
                size: SoftSize.small,
                value: _maxCount,
                options: const [
                  SegmentedOption(value: -1, label: 'fold to fit'),
                  SegmentedOption(value: 0, label: 'off'),
                  SegmentedOption(value: 3, label: '3'),
                  SegmentedOption(value: 5, label: '5'),
                  SegmentedOption(value: 7, label: '7'),
                ],
                onChanged: (v) => setState(() => _maxCount = v),
              ),
              const SizedBox(height: 12),
              Steps(
                maxCount: _maxCount <= 0 ? null : _maxCount.toInt(),
                overflow: _maxCount < 0
                    ? StepsOverflow.fold
                    : StepsOverflow.scroll,
                current: _long,
                responsive: false,
                onChange: (i) => setState(() => _long = i),
                items: [
                  for (var i = 1; i <= 9; i++)
                    StepItem(
                      title: Text('Step $i'),
                      // A failure in the folded part still shows: the ellipsis
                      // standing for it turns red.
                      status: i == 5 ? StepStatus.error : null,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _maxCount < 0
                    ? 'step ${_long + 1} of 9 — folds to whatever fits; '
                          'narrow the window to watch it'
                    : 'step ${_long + 1} of 9 — taps report the real index',
                style: TextStyle(color: t.colorTextTertiary),
              ),
              const SizedBox(height: 12),
              Steps(
                type: StepsType.dot,
                maxCount: _maxCount <= 0 ? null : _maxCount.toInt(),
                overflow: _maxCount < 0
                    ? StepsOverflow.fold
                    : StepsOverflow.scroll,
                current: _long,
                responsive: false,
                onChange: (i) => setState(() => _long = i),
                items: [
                  for (var i = 1; i <= 9; i++) StepItem(title: Text('$i')),
                ],
              ),
            ],
          ),
        ),

        // `size` is the whole run's scale, not the dots': it sets the marker's
        // diameter and the type beside it. A preset picks one of three; a
        // number sets the diameter outright and the type follows it.
        Group(
          'Size',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Segmented<ControlSize>(
                size: SoftSize.small,
                value: _size,
                options: const [
                  SegmentedOption(value: SoftSize.small, label: 'small'),
                  SegmentedOption(value: SoftSize.middle, label: 'middle'),
                  SegmentedOption(value: SoftSize.large, label: 'large'),
                  SegmentedOption(
                    value: ControlSize.height(52),
                    label: 'height(52)',
                  ),
                ],
                onChanged: (v) => setState(() => _size = v),
              ),
              const SizedBox(height: 12),
              Steps(size: _size, current: 1, items: _checkout),
            ],
          ),
        ),

        // The rail's own length, not its gaps. Left alone it is the give in
        // the layout; fixed, the steps size to their text and the run scrolls.
        Group(
          'Rail length',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Segmented<double>(
                size: SoftSize.small,
                value: _railLength,
                options: const [
                  SegmentedOption(value: 0, label: 'free'),
                  SegmentedOption(value: 40, label: '40'),
                  SegmentedOption(value: 120, label: '120'),
                  SegmentedOption(value: 240, label: '240'),
                ],
                onChanged: (v) => setState(() => _railLength = v),
              ),
              const SizedBox(height: 12),
              Steps(
                current: 1,
                items: _checkout,
                size: _size,
                responsive: false,
                token: StepsToken(
                  railInset: const RailInsets.all(4),
                  railLength: _railLength == 0 ? null : _railLength,
                ),
              ),
              const SizedBox(height: 12),
              Steps(
                orientation: StepsOrientation.vertical,
                current: 1,
                items: _checkout,
                token: StepsToken(
                  railLength: _railLength == 0 ? null : _railLength,
                ),
              ),
            ],
          ),
        ),

        const Group(
          'Custom icons & small size',
          Steps(
            size: SoftSize.small,
            responsive: false,
            current: 1,
            token: StepsToken(railInset: RailInsets.all(3)),
            items: [
              StepItem(title: Text('Account'), icon: Icon(Icons.person)),
              StepItem(title: Text('Card'), icon: Icon(Icons.credit_card)),
              StepItem(title: Text('Ship'), icon: Icon(Icons.local_shipping)),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
