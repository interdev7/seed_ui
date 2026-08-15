import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

/// A trigger that owns the popover's open state.
///
/// [Popover] itself has no trigger: it takes `open` and reports
/// `onOpenChanged`, and the caller decides what opens it — a tap here, hover in
/// [Tooltip], a tap on a field in [Select].
class _PopoverButton extends StatefulWidget {
  const _PopoverButton({
    required this.label,
    required this.content,
    this.placement = PopoverPlacement.top,
    this.gap = 8,
    this.interactive = true,
    this.dismissOnOutsideTap = true,
    this.barrierColor,
    this.small = false,
  });

  final String label;
  final WidgetBuilder content;
  final PopoverPlacement placement;
  final double gap;
  final bool interactive;
  final bool dismissOnOutsideTap;
  final Color? barrierColor;
  final bool small;

  @override
  State<_PopoverButton> createState() => _PopoverButtonState();
}

class _PopoverButtonState extends State<_PopoverButton> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    return PopoverLayer(
      open: _open,
      onOpenChanged: (v) => setState(() => _open = v),
      placement: widget.placement,
      gap: widget.gap,
      interactive: widget.interactive,
      dismissOnOutsideTap: widget.dismissOnOutsideTap,
      barrierColor: widget.barrierColor,
      arrowColor: t.colorBgElevated,
      arrowShadow: t.boxShadowSecondary,
      content: widget.content,
      child: Button(
        size: widget.small ? SoftSize.small : SoftSize.middle,
        variant: _open ? ButtonVariant.solid : ButtonVariant.outlined,
        color: _open ? ButtonColor.primary : ButtonColor.defaultColor,
        onPressed: () => setState(() => _open = !_open),
        child: Text(widget.label),
      ),
    );
  }
}

/// `Popover` is the floating layer the kit's own components stand on —
/// Tooltip, Dropdown, Popconfirm and Select all anchor their content with it.
/// It positions and nothing more: the surface is whatever you pass it.
class PopoverDemo extends StatefulWidget {
  const PopoverDemo({super.key});

  @override
  State<PopoverDemo> createState() => _PopoverDemoState();
}

class _PopoverDemoState extends State<PopoverDemo> {
  PopoverPlacement _placement = PopoverPlacement.top;
  bool _controlled = false;
  bool _interactive = true;
  bool _dismissOnOutsideTap = true;
  double _gap = 8;
  int _likes = 0;
  PopoverAnimation _arrival = PopoverAnimation.genie;
  double _arrivalMs = 0; // 0 stands for "whatever the arrival wants"

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Group(
          'Basic — a card with a title and a body',
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              Popover(
                title: Text('Title'),
                content: Text('Some content here.'),
                child: Button(child: Text('Hover me')),
              ),
              Popover(
                trigger: PopoverTrigger.tap,
                title: Text('Tap to open'),
                content: Text('And tap again to put it away.'),
                child: Button(child: Text('Tap me')),
              ),
              Popover(
                trigger: PopoverTrigger.longPress,
                content: Text('Held down.'),
                child: Button(child: Text('Press and hold')),
              ),
            ],
          ),
        ),

        // What a popover can hold that a tooltip cannot: things to press.
        Group(
          'A card you can act on',
          Align(
            alignment: Alignment.centerLeft,
            child: Popover(
              placement: PopoverPlacement.rightTop,
              title: const Text('Share this page'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Anyone with the link can read it.'),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Button(
                        size: SoftSize.small,
                        variant: ButtonVariant.text,
                        onPressed: () => message.info('Link copied'),
                        child: const Text('Copy link'),
                      ),
                      Button(
                        size: SoftSize.small,
                        variant: ButtonVariant.solid,
                        color: ButtonColor.primary,
                        onPressed: () => setState(() => _likes++),
                        child: Text('Like ($_likes)'),
                      ),
                    ],
                  ),
                ],
              ),
              child: const Button(child: Text('Share')),
            ),
          ),
        ),

        // The macOS genie: the card is rasterised and drawn through a mesh
        // that pours it out of the trigger.
        Group(
          'How it arrives',
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Segmented<PopoverAnimation>(
                size: SoftSize.small,
                value: _arrival,
                options: const [
                  SegmentedOption(
                    value: PopoverAnimation.simple,
                    label: 'simple',
                  ),
                  SegmentedOption(
                    value: PopoverAnimation.genie,
                    label: 'genie',
                  ),
                ],
                onChanged: (v) => setState(() => _arrival = v),
              ),
              Segmented<double>(
                size: SoftSize.small,
                value: _arrivalMs,
                options: const [
                  SegmentedOption(value: 0, label: 'its own pace'),
                  SegmentedOption(value: 250, label: '250ms'),
                  SegmentedOption(value: 900, label: '900ms'),
                  SegmentedOption(value: 1200, label: '1200ms'),
                ],
                onChanged: (v) => setState(() => _arrivalMs = v),
              ),
              Popover(
                key: ValueKey<String>('$_arrival$_arrivalMs'),
                trigger: PopoverTrigger.tap,
                animation: _arrival,
                duration: _arrivalMs == 0
                    ? null
                    : Duration(milliseconds: _arrivalMs.round()),
                placement: PopoverPlacement.top,
                title: const Text('Out of the trigger'),
                content: const Text(
                  'The genie rasterises the card and draws it through a mesh '
                  'that is pinched at the trigger and wide where it has '
                  'arrived. It stops the moment it lands, so this text is a '
                  'widget again.',
                ),
                child: const Button(child: Text('Open')),
              ),
            ],
          ),
        ),

        Group(
          'Coloured, and without a caret',
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              Popover(
                trigger: PopoverTrigger.tap,
                color: t.primary.base,
                token: PopoverToken(
                  titleColor: t.colorBgContainer,
                  contentColor: t.colorBgContainer,
                ),
                title: const Text('In the accent'),
                content: const Text('The caret takes the colour too.'),
                child: const Button(child: Text('Coloured')),
              ),
              const Popover(
                trigger: PopoverTrigger.tap,
                arrow: false,
                content: Text('No caret at all.'),
                child: Button(child: Text('arrow: false')),
              ),
            ],
          ),
        ),

        Group(
          'Placement',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _placements(t),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Popover(
                  key: ValueKey<PopoverPlacement>(_placement),
                  trigger: PopoverTrigger.tap,
                  placement: _placement,
                  title: Text('placement: ${_placement.name}'),
                  content: const Text(
                    'It flips to the other side where there is no room, and '
                    'crosses to the other axis where neither side has any.',
                  ),
                  child: const Button(child: Text('Open here')),
                ),
              ),
            ],
          ),
        ),

        // Below this line is the layer the component stands on.
        // Below this line is the layer the component stands on.
        Group(
          'PopoverLayer — the plumbing underneath',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The component above is a card built on PopoverLayer, which '
                'only positions — Tooltip, Dropdown, Select, Popconfirm and '
                'Tour each give it a surface of their own. Here it carries a '
                'surface of ours.',
                style: TextStyle(color: t.colorTextTertiary),
              ),
              const SizedBox(height: 12),
              _PopoverButton(
                label: 'A surface of our own',
                placement: PopoverPlacement.bottomLeft,
                content: (context) => _bubble(
                  t,
                  const Text('No card, no padding — whatever you pass it.'),
                ),
              ),
            ],
          ),
        ),

        Group(
          'Settings',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('gap'),
                  Segmented<double>(
                    size: SoftSize.small,
                    value: _gap,
                    options: const [
                      SegmentedOption(value: 0, label: '0'),
                      SegmentedOption(value: 8, label: '8 (default)'),
                      SegmentedOption(value: 24, label: '24'),
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
                  _toggle(
                    'interactive',
                    _interactive,
                    (v) => setState(() => _interactive = v),
                  ),
                  _toggle(
                    'dismissOnOutsideTap',
                    _dismissOnOutsideTap,
                    (v) => setState(() => _dismissOnOutsideTap = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: _PopoverButton(
                  label: 'Open with the settings',
                  placement: _placement,
                  gap: _gap,
                  interactive: _interactive,
                  dismissOnOutsideTap: _dismissOnOutsideTap,
                  content: (context) => _bubble(
                    t,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('placement: ${_placement.name}'),
                        Text(
                          _interactive
                              ? 'interactive: taps land here'
                              : 'not interactive: taps fall through',
                          style: TextStyle(color: t.colorTextTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Driven from outside: the popover keeps no state of its own, so the
        // switch is the single source of truth.
        Group(
          'Controlled',
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Switch(
                key: const Key('popoverControlledSwitch'),
                value: _controlled,
                onChanged: (v) => setState(() => _controlled = v),
              ),
              Popover(
                open: _controlled,
                onOpenChange: (v) => setState(() => _controlled = v),
                placement: PopoverPlacement.right,
                content: const Text('Open while the switch is on.'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: t.colorFillQuaternary,
                    borderRadius: BorderRadius.circular(t.borderRadius),
                  ),
                  child: const Text('the anchor'),
                ),
              ),
            ],
          ),
        ),

        // A barrier dims the page and catches the tap that closes it — how a
        // popover reads as modal without being a dialog.
        Group(
          'With a barrier',
          Align(
            alignment: Alignment.centerLeft,
            child: _PopoverButton(
              label: 'Open over a barrier',
              placement: PopoverPlacement.bottomLeft,
              barrierColor: const Color(0x40000000),
              content: (context) => _bubble(
                t,
                const Text('The page behind is dimmed and inert.'),
              ),
            ),
          ),
        ),

        Group(
          'Where the room runs out',
          Text(
            'A popover flips to the other side of its trigger when the side it '
            'asked for has no room, and crosses to the other axis when neither '
            'side has any. Try the placements above against the triggers in the '
            'corners.',
            style: TextStyle(color: t.colorTextTertiary),
          ),
        ),
        _corners(t),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Switch(size: SwitchSize.small, value: value, onChanged: onChanged),
      const SizedBox(width: 8),
      Text(label),
    ],
  );

  Widget _placements(Token t) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final placement in PopoverPlacement.values)
        Button(
          size: SoftSize.small,
          variant: _placement == placement
              ? ButtonVariant.solid
              : ButtonVariant.outlined,
          color: _placement == placement
              ? ButtonColor.primary
              : ButtonColor.defaultColor,
          onPressed: () => setState(() => _placement = placement),
          child: Text(placement.name),
        ),
    ],
  );

  Widget _corners(Token t) => Container(
    height: 220,
    decoration: BoxDecoration(
      color: t.colorFillQuaternary,
      borderRadius: BorderRadius.circular(t.borderRadiusLG),
    ),
    child: Stack(
      children: [
        Positioned(left: 12, top: 12, child: _corner(t, 'top left')),
        Positioned(right: 12, top: 12, child: _corner(t, 'top right')),
        Positioned(left: 12, bottom: 12, child: _corner(t, 'bottom left')),
        Positioned(right: 12, bottom: 12, child: _corner(t, 'bottom right')),
      ],
    ),
  );

  Widget _corner(Token t, String label) => _PopoverButton(
    label: label,
    small: true,
    placement: _placement,
    gap: _gap,
    content: (context) => _bubble(t, Text('$label · ${_placement.name}')),
  );

  /// The surface itself. `Popover` places whatever it is given; the bubble,
  /// its padding, its shadow and its corners are the caller's to choose — the
  /// caret takes the colour you pass so the two read as one shape.
  Widget _bubble(Token t, Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: t.colorBgElevated,
      borderRadius: BorderRadius.circular(t.borderRadius),
      boxShadow: t.boxShadowSecondary,
    ),
    child: DefaultTextStyle(
      style: TextStyle(
        color: t.colorText,
        fontSize: t.fontSize,
        fontFamily: t.fontFamily,
        fontFamilyFallback: t.fontFamilyFallback,
        decoration: TextDecoration.none,
      ),
      child: child,
    ),
  );
}
