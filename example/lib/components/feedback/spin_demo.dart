import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:seed_ui/seed_ui.dart';
import '../group.dart';

class SpinDemo extends StatefulWidget {
  const SpinDemo({super.key});

  @override
  State<SpinDemo> createState() => _SpinDemoState();
}

class _SpinDemoState extends State<SpinDemo> {
  bool _spinning = true;
  bool _delaySpinning = false;
  bool _fullscreenSpinning = false;

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Basic Standalone Spin
          const Group('Basic Standalone Spin', Spin()),
          const SizedBox(height: 24),

          // 2. Sizes
          const Group(
            'Sizes (Small, Middle, Large)',
            Row(
              children: [
                Spin(size: SoftSize.small),
                SizedBox(width: 24),
                Spin(size: SoftSize.middle),
                SizedBox(width: 24),
                Spin(size: SoftSize.large),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Spin inside a Container / Wrapped Child
          Group(
            'Container Loading Overlay (child)',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Loading State: '),
                    Switch(
                      value: _spinning,
                      onChanged: (v) => setState(() => _spinning = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 400,
                  child: Spin(
                    spinning: _spinning,
                    tip: const Text('Loading content...'),
                    child: Card(
                      title: const Text("Example Card Title"),
                      actions: [
                        Button(
                          child: const Text("View More"),
                          onPressed: () {},
                        ),
                        Button(child: const Text("Cancel"), onPressed: () {}),
                        Button(
                          color: ButtonColor.danger,
                          variant: ButtonVariant.solid,
                          child: const Text("Delete"),
                          onPressed: () {},
                        ),
                      ],
                      child: const Text(
                        "Example Card Content. This is a card component wrapped inside a spin component.",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Custom Tip & Custom Colors
          const Group(
            'Custom Description & Colors',
            Row(
              children: [
                Spin(tip: Text('Loading...'), color: Color(0xFF52C41A)),
                SizedBox(width: 48),
                Spin(
                  size: SoftSize.large,
                  tip: Text('Processing payment...'),
                  color: Color(0xFF722ED1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. Custom Indicator Widget
          const Group(
            'Custom Indicator Widget',
            Spin(
              indicator: Icon(Icons.sync, color: Color(0xFF1677FF)),
              tip: Text('Synchronizing...'),
            ),
          ),
          const SizedBox(height: 24),

          // 6. Delay Loading (Prevent Flicker)
          Group(
            'Delay Loading (Prevent Flicker)',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Button(
                      onPressed: () {
                        setState(() => _delaySpinning = !_delaySpinning);
                      },
                      child: Text(
                        _delaySpinning ? 'Stop' : 'Start (500ms Delay)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Spin(
                  spinning: _delaySpinning,
                  delay: const Duration(milliseconds: 500),
                  tip: const Text('Delayed indicator'),
                  child: const Card(
                    child: Text(
                      "Content appears immediately, spin delays 500ms",
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 7. Exact Circular Progress
          const Group(
            'Percent Progress Circle',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Spin(percent: 20),
                    SizedBox(width: 24),
                    Spin(percent: 50, tip: Text('50%')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 8. Custom Position (SpinPosition)
          Group(
            'Custom Position (SpinPosition)',
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 16) / 2;
                final size = cardWidth > 0 ? cardWidth : 140.0;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Spin(
                      spinning: true,
                      size: SoftSize.small,
                      position: SpinPosition.topLeft,
                      tip: const Text('Top Left'),
                      child: Container(
                        width: size,
                        height: 140,
                        color: token.colorBgContainer,
                        padding: const EdgeInsets.all(8),
                        child: const Text('Content'),
                      ),
                    ),
                    Spin(
                      spinning: true,
                      size: SoftSize.small,
                      position: SpinPosition.topCenter,
                      tip: const Text('Top Center'),
                      child: Container(
                        width: size,
                        height: 140,
                        color: token.colorBgContainer,
                        padding: const EdgeInsets.all(8),
                        child: const Text('Content'),
                      ),
                    ),
                    Spin(
                      spinning: true,
                      size: SoftSize.small,
                      position: SpinPosition.topRight,
                      tip: const Text('Top Right'),
                      child: Container(
                        width: size,
                        height: 140,
                        color: token.colorBgContainer,
                        padding: const EdgeInsets.all(8),
                        child: const Text('Content'),
                      ),
                    ),
                    Spin(
                      spinning: true,
                      size: SoftSize.small,
                      position: SpinPosition.centerRight,
                      tip: const Text('Center Right'),
                      child: Container(
                        width: size,
                        height: 140,
                        color: token.colorBgContainer,
                        padding: const EdgeInsets.all(8),
                        child: const Text('Content'),
                      ),
                    ),
                    Spin(
                      spinning: true,
                      size: SoftSize.small,
                      position: SpinPosition.bottomRight,
                      tip: const Text('Bottom Right'),
                      child: Container(
                        width: size,
                        height: 140,
                        color: token.colorBgContainer,
                        padding: const EdgeInsets.all(8),
                        child: const Text('Content'),
                      ),
                    ),
                    Spin(
                      spinning: true,
                      size: SoftSize.small,
                      position: SpinPosition.bottomCenter,
                      tip: const Text('Bottom Center'),
                      child: Container(
                        width: size,
                        height: 140,
                        color: token.colorBgContainer,
                        padding: const EdgeInsets.all(8),
                        child: const Text('Content'),
                      ),
                    ),
                    Spin(
                      spinning: true,
                      size: SoftSize.small,
                      position: SpinPosition.bottomLeft,
                      tip: const Text('Bottom Left'),
                      child: Container(
                        width: size,
                        height: 140,
                        color: token.colorBgContainer,
                        padding: const EdgeInsets.all(8),
                        child: const Text('Content'),
                      ),
                    ),
                    Spin(
                      spinning: true,
                      size: SoftSize.small,
                      position: SpinPosition.centerLeft,
                      tip: const Text('Center Left'),
                      child: Container(
                        width: size,
                        height: 140,
                        color: token.colorBgContainer,
                        padding: const EdgeInsets.all(8),
                        child: const Text('Content'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 8. Fullscreen Spin Overlay
          Group(
            'Fullscreen Spin Overlay',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Button(
                  variant: ButtonVariant.solid,
                  color: ButtonColor.primary,
                  onPressed: () {
                    setState(() => _fullscreenSpinning = true);
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted) {
                        setState(() => _fullscreenSpinning = false);
                      }
                    });
                  },
                  child: const Text('Show Fullscreen Spin (3s)'),
                ),
                if (_fullscreenSpinning)
                  Spin(
                    fullscreen: true,
                    spinning: _fullscreenSpinning,
                    tip: const Text('Loading application resources...'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
