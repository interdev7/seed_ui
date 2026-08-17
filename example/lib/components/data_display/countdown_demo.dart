import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class CountdownDemo extends StatefulWidget {
  const CountdownDemo({super.key});

  @override
  State<CountdownDemo> createState() => _CountdownDemoState();
}

class _CountdownDemoState extends State<CountdownDemo> {
  /// Restarted by the button, so the finish can be watched more than once.
  DateTime _shortTarget = DateTime.now().add(const Duration(seconds: 10));
  bool _done = false;

  late final DateTime _longTarget = DateTime.now().add(
    const Duration(days: 2, hours: 3, minutes: 4, seconds: 5),
  );
  late final DateTime _startedAt = DateTime.now();

  /// The direction of the live example, and the moment it counts against.
  ///
  /// Each way needs its own: counting up towards something still ahead would
  /// sit at zero until it arrived, which reads as broken rather than clamped.
  CountdownType _liveType = CountdownType.down;
  late DateTime _liveTarget = _longTarget;

  /// The one thing properties cannot express: a count standing still.
  late final CountdownController _driven = CountdownController(
    target: DateTime.now().add(const Duration(minutes: 2)),
  );

  @override
  void dispose() {
    _driven.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Counting down',
          Countdown(target: _longTarget, format: 'D[d] HH:mm:ss'),
        ),
        Group(
          'Counting up, since this page opened',
          Countdown(
            target: _startedAt,
            type: CountdownType.up,
            format: 'HH:mm:ss',
          ),
        ),
        Group(
          'Either way, live',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioGroup(
                value: _liveType,
                optionType: RadioOptionType.button,
                options: const [
                  RadioOption(value: CountdownType.down, label: Text('down')),
                  RadioOption(value: CountdownType.up, label: Text('up')),
                ],
                onChanged: (v) => setState(() {
                  _liveType = v;
                  _liveTarget = v == CountdownType.down
                      ? _longTarget
                      : _startedAt;
                }),
              ),
              const SizedBox(height: 12),
              Countdown(
                key: ValueKey(_liveType),
                target: _liveTarget,
                type: _liveType,
                format: 'D[d] HH:mm:ss',
              ),
              const SizedBox(height: 8),
              Text(
                _liveType == CountdownType.down
                    ? 'Time left until a moment two days out.'
                    : 'Time since this page opened.',
              ),
            ],
          ),
        ),
        Group(
          'Driven by a controller',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Countdown(controller: _driven, format: 'mm:ss'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Rebuilt with the controller so the label follows the state
                  // rather than telling the last story it heard.
                  ListenableBuilder(
                    listenable: _driven,
                    builder: (context, _) => Button(
                      onPressed: () =>
                          _driven.isPaused ? _driven.resume() : _driven.pause(),
                      child: Text(_driven.isPaused ? 'Resume' : 'Pause'),
                    ),
                  ),
                  Button(
                    onPressed: () => _driven.add(const Duration(seconds: 30)),
                    child: const Text('+30s'),
                  ),
                  Button(
                    onPressed: () => _driven.add(const Duration(seconds: -30)),
                    child: const Text('−30s'),
                  ),
                  Button(
                    onPressed: () =>
                        _driven.restart(const Duration(minutes: 2)),
                    child: const Text('Restart'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Pause holds it still; resume gives the pause back rather '
                'than charging for it, so it carries on from the figure it '
                'stopped at.',
              ),
            ],
          ),
        ),
        Group(
          'Formats',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final f in const [
                'HH:mm:ss',
                'D[d] HH:mm:ss',
                'H[h] m[m] s[s]',
                'mm:ss.SSS',
                's',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 160,
                        child: Text(
                          f,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Countdown(
                        target: _longTarget,
                        format: f,
                        token: const CountdownToken(fontSize: 16),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Group(
          'onFinish',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Countdown(
                // A new target is a new count, so the key is the target.
                key: ValueKey(_shortTarget),
                target: _shortTarget,
                format: 'mm:ss',
                onFinish: () => setState(() => _done = true),
              ),
              const SizedBox(height: 8),
              Text(_done ? 'Finished.' : 'Running…'),
              const SizedBox(height: 12),
              Button(
                onPressed: () => setState(() {
                  _done = false;
                  _shortTarget = DateTime.now().add(
                    const Duration(seconds: 10),
                  );
                }),
                child: const Text('Restart (10s)'),
              ),
            ],
          ),
        ),
        Group(
          'Wrapped with a builder',
          Countdown(
            target: _longTarget,
            format: 'HH:mm:ss',
            builder: (context, formatted) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 20),
                const SizedBox(width: 8),
                Text('$formatted left', style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ),
        Group(
          'A target already past',
          Countdown(
            target: DateTime.now().subtract(const Duration(hours: 1)),
            format: 'HH:mm:ss',
          ),
        ),
        Group(
          'On a background of its own',
          // A running target, not a past one: a countdown to a moment already
          // gone is finished, and sits at zero however it is decorated.
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: context.softToken.colorFillSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Countdown(target: _longTarget, format: 'HH:mm:ss'),
            ),
          ),
        ),
      ],
    );
  }
}
