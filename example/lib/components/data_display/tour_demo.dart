import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class TourDemo extends StatefulWidget {
  const TourDemo({super.key});

  @override
  State<TourDemo> createState() => _TourDemoState();
}

class _TourDemoState extends State<TourDemo> {
  // The toolbar the plain tours point at.
  final GlobalKey _upload = GlobalKey();
  final GlobalKey _save = GlobalKey();
  final GlobalKey _more = GlobalKey();

  // Corners and edges of the playground, plus one target inside a scroller.
  final GlobalKey _topLeft = GlobalKey();
  final GlobalKey _topRight = GlobalKey();
  final GlobalKey _middle = GlobalKey();
  final GlobalKey _bottomLeft = GlobalKey();
  final GlobalKey _bottomRight = GlobalKey();
  final GlobalKey _inScroller = GlobalKey();

  final TourController _basic = TourController();
  final TourController _corners = TourController();
  final TourController _placements = TourController();
  final TourController _rich = TourController();

  // The knobs every tour on this page answers to.
  TourType _type = TourType.normal;
  bool _mask = true;
  bool _arrow = true;
  bool _closable = true;
  bool _dismissible = true;
  bool _disabledInteraction = false;
  double _travel = 300;
  double _gap = 6;

  int _uploads = 0;

  @override
  void dispose() {
    _basic.dispose();
    _corners.dispose();
    _placements.dispose();
    _rich.dispose();
    super.dispose();
  }

  Duration get _duration => Duration(milliseconds: _travel.round());

  /// Every tour here takes the same knobs, so a setting can be felt anywhere.
  Widget _tour(TourController controller, List<TourStep> steps) => Tour(
    controller: controller,
    steps: steps,
    type: _type,
    mask: _mask ? const TourMask() : TourMask.none,
    arrow: _arrow,
    closable: _closable,
    dismissible: _dismissible,
    disabledInteraction: _disabledInteraction,
    gap: TourGap(offset: _gap, radius: _gap / 3),
    duration: _duration,
  );

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Group('Settings — they apply to every tour below', _settings(t)),
            Group('The toolbar the first tour points at', _toolbar(t)),

            Group(
              'Basic',
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Button(
                    variant: ButtonVariant.solid,
                    color: ButtonColor.primary,
                    onPressed: _basic.open,
                    child: const Text('Begin tour'),
                  ),
                  Button(
                    onPressed: () => _basic.open(2),
                    child: const Text('Start at the last step'),
                  ),
                  Button(
                    onPressed: _basic.resume,
                    child: const Text('Resume where it left off'),
                  ),
                ],
              ),
            ),

            // Targets in the corners, at the edges and inside a scroller: the
            // panel has to flip sides and shift to stay on screen, and the
            // spotlight has to follow a target that moves with its scroller.
            Group('A tour of the whole page', _playground(t)),

            // Every placement in turn, against a target in the middle.
            Group('Every placement', _placementButtons(t)),

            // A cover, indicators and buttons of your own.
            Group(
              'A cover, and indicators and actions of your own',
              Button(
                variant: ButtonVariant.solid,
                color: ButtonColor.primary,
                onPressed: _rich.open,
                child: const Text('Begin the rich tour'),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),

        // The tours take no room. They are positioned so they cannot shrink
        // this Stack — an unpositioned zero-size child would, and its
        // positioned siblings would stop answering taps.
        Positioned(
          left: 0,
          top: 0,
          child: Column(
            children: [
              _tour(_basic, _basicSteps),
              _tour(_corners, _cornerSteps),
              _tour(_placements, _placementSteps),
              // The rich tour draws its own indicators and adds to the
              // actions the tour hands it.
              Tour(
                controller: _rich,
                steps: _richSteps(t),
                type: _type,
                mask: _mask ? const TourMask() : TourMask.none,
                arrow: _arrow,
                closable: _closable,
                dismissible: _dismissible,
                disabledInteraction: _disabledInteraction,
                gap: TourGap(offset: _gap, radius: _gap / 3),
                duration: _duration,
                indicatorsBuilder: (context, current, total) => Text(
                  'Step ${current + 1} of $total',
                  style: TextStyle(
                    color: _type == TourType.primary
                        ? const Color(0xE6FFFFFF)
                        : t.colorTextTertiary,
                  ),
                ),
                actionsBuilder: (context, actions, current, total) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Button(
                      size: SoftSize.small,
                      variant: ButtonVariant.text,
                      onPressed: () => message.info('Skipped the rest'),
                      child: const Text('Skip'),
                    ),
                    const SizedBox(width: 8),
                    actions,
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // The knobs
  // ---------------------------------------------------------------------------

  Widget _settings(Token t) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Segmented<TourType>(
            size: SoftSize.small,
            value: _type,
            options: const [
              SegmentedOption(value: TourType.normal, label: 'default'),
              SegmentedOption(value: TourType.primary, label: 'primary'),
            ],
            onChanged: (v) => setState(() => _type = v),
          ),
          Segmented<double>(
            size: SoftSize.small,
            value: _travel,
            options: const [
              SegmentedOption(value: 0, label: 'no motion'),
              SegmentedOption(value: 300, label: '300ms'),
              SegmentedOption(value: 900, label: '900ms'),
              SegmentedOption(value: 2400, label: '2.4s'),
            ],
            onChanged: (v) => setState(() => _travel = v),
          ),
          Segmented<double>(
            size: SoftSize.small,
            value: _gap,
            options: const [
              SegmentedOption(value: 0, label: 'gap 0'),
              SegmentedOption(value: 6, label: 'gap 6'),
              SegmentedOption(value: 16, label: 'gap 16'),
            ],
            onChanged: (v) => setState(() => _gap = v),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _toggle('mask', _mask, (v) => setState(() => _mask = v)),
          _toggle('arrow', _arrow, (v) => setState(() => _arrow = v)),
          _toggle('closable', _closable, (v) => setState(() => _closable = v)),
          _toggle(
            'dismissible',
            _dismissible,
            (v) => setState(() => _dismissible = v),
          ),
          _toggle(
            'disabledInteraction',
            _disabledInteraction,
            (v) => setState(() => _disabledInteraction = v),
          ),
        ],
      ),
    ],
  );

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Switch(size: SwitchSize.small, value: value, onChanged: onChanged),
      const SizedBox(width: 8),
      Text(label),
    ],
  );

  // ---------------------------------------------------------------------------
  // The targets
  // ---------------------------------------------------------------------------

  Widget _toolbar(Token t) => Wrap(
    spacing: 12,
    runSpacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Button(
        key: _upload,
        icon: const Icon(Icons.upload_file),
        onPressed: () => setState(() => _uploads++),
        child: const Text('Upload'),
      ),
      Button(
        key: _save,
        variant: ButtonVariant.solid,
        color: ButtonColor.primary,
        onPressed: () => message.success('Saved'),
        child: const Text('Save'),
      ),
      Button(
        key: _more,
        variant: ButtonVariant.text,
        icon: const Icon(Icons.more_horiz),
        onPressed: () => message.info('More…'),
      ),
      Text(
        _uploads == 0 ? 'nothing uploaded yet' : 'uploaded $_uploads time(s)',
        style: TextStyle(color: t.colorTextTertiary),
      ),
    ],
  );

  Widget _playground(Token t) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        height: 320,
        decoration: BoxDecoration(
          color: t.colorFillQuaternary,
          borderRadius: BorderRadius.circular(t.borderRadiusLG),
        ),
        child: Stack(
          children: [
            Positioned(left: 12, top: 12, child: _dot(t, _topLeft, 'TL')),
            Positioned(right: 12, top: 12, child: _dot(t, _topRight, 'TR')),
            Positioned(
              left: 0,
              right: 0,
              top: 140,
              child: Center(child: _dot(t, _middle, 'centre')),
            ),
            Positioned(left: 12, bottom: 56, child: _dot(t, _bottomLeft, 'BL')),
            Positioned(
              right: 12,
              bottom: 56,
              child: _dot(t, _bottomRight, 'BR'),
            ),
            // A target inside a scroller: the spotlight follows it as the
            // page moves under the tour.
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    for (var i = 0; i < 12; i++) ...[
                      _dot(t, i == 7 ? _inScroller : null, 'card ${i + 1}'),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          Button(
            variant: ButtonVariant.solid,
            color: ButtonColor.primary,
            onPressed: _corners.open,
            child: const Text('Tour the corners'),
          ),
          Text(
            'the page comes to a target below the fold, and the spotlight '
            'follows one scrolled under it',
            style: TextStyle(color: t.colorTextTertiary),
          ),
        ],
      ),
    ],
  );

  Widget _dot(Token t, GlobalKey? key, String label) => Container(
    key: key,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: t.colorBgContainer,
      borderRadius: BorderRadius.circular(t.borderRadius),
      border: Border.all(color: t.colorBorderSecondary),
    ),
    child: Text(label),
  );

  Widget _placementButtons(Token t) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final placement in TourPlacement.values)
        Button(
          size: SoftSize.small,
          onPressed: () {
            setState(() => _placement = placement);
            _placements.open();
          },
          child: Text(placement.name),
        ),
    ],
  );

  TourPlacement _placement = TourPlacement.bottom;

  // ---------------------------------------------------------------------------
  // The steps
  // ---------------------------------------------------------------------------

  List<TourStep> get _basicSteps => [
    TourStep(
      target: _upload,
      title: const Text('Upload a file'),
      description: const Text('Put your files here.'),
      // The hole leaves the target live, so the step can be tried out from
      // inside the tour — and this one will not let you leave until it is.
      nextButton: TourButton(
        label: Text(_uploads == 0 ? 'Press Upload to carry on' : 'Next'),
        disabled: _uploads == 0,
      ),
    ),
    TourStep(
      target: _save,
      title: const Text('Save'),
      description: const Text('Save your changes as you go.'),
    ),
    TourStep(
      target: _more,
      title: const Text('Other actions'),
      description: const Text('Everything else lives behind here.'),
      placement: TourPlacement.rightTop,
      // A button of your own: the tour hands over its action.
      nextButton: TourButton.custom(
        (context, act) => Button(
          size: SoftSize.small,
          shape: ButtonShape.round,
          variant: ButtonVariant.solid,
          color: ButtonColor.primary,
          icon: const Icon(Icons.celebration, size: 16),
          onPressed: act,
          child: const Text('All done'),
        ),
      ),
    ),
  ];

  List<TourStep> get _cornerSteps => [
    const TourStep(
      title: Text('A tour of the page'),
      description: Text(
        'This step points at nothing, so it opens in the middle. The next '
        'ones are in the corners, where the panel has to flip sides to '
        'stay on screen.',
      ),
    ),
    TourStep(
      target: _topLeft,
      title: const Text('Top left'),
      description: const Text('Asked for the left; there is no room.'),
      placement: TourPlacement.left,
    ),
    TourStep(
      target: _topRight,
      title: const Text('Top right'),
      placement: TourPlacement.right,
      description: const Text('Asked for the right; same again.'),
    ),
    TourStep(
      target: _middle,
      title: const Text('The middle'),
      description: const Text(
        'Room on every side, so it gets what it asked for.',
      ),
      placement: TourPlacement.top,
    ),
    TourStep(
      target: _bottomLeft,
      title: const Text('Bottom left'),
      placement: TourPlacement.bottomLeft,
    ),
    TourStep(
      target: _bottomRight,
      title: const Text('Bottom right'),
      placement: TourPlacement.bottomRight,
    ),
    TourStep(
      target: _inScroller,
      title: const Text('Inside a scroller'),
      description: const Text(
        'Scroll the row behind the mask and the spotlight keeps up: the '
        'target is measured every frame.',
      ),
      placement: TourPlacement.top,
    ),
  ];

  List<TourStep> get _placementSteps => [
    TourStep(
      target: _middle,
      placement: _placement,
      title: Text('placement: ${_placement.name}'),
      description: const Text(
        'Where there is no room the panel takes the other side, and where '
        'neither side has room it crosses to the other axis.',
      ),
    ),
  ];

  List<TourStep> _richSteps(Token t) => [
    TourStep(
      target: _middle,
      cover: ClipRRect(
        borderRadius: BorderRadius.circular(t.borderRadius),
        child: Container(
          height: 120,
          color: t.primary.bg,
          alignment: Alignment.center,
          child: Icon(Icons.image, size: 48, color: t.primary.base),
        ),
      ),
      title: const Text('A step with a cover'),
      description: const Text('Pictures and video sit above the heading.'),
      closeIcon: const Icon(Icons.close_fullscreen),
    ),
    TourStep(
      target: _topRight,
      title: const Text('Indicators of your own'),
      description: const Text('Here they read as words rather than dots.'),
    ),
    TourStep(
      target: _bottomLeft,
      title: const Text('And actions of your own'),
      description: const Text(
        'The tour builds its buttons and hands them over; this step puts '
        'something beside them.',
      ),
    ),
  ];
}
