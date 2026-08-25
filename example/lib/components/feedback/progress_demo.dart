import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class ProgressDemo extends StatefulWidget {
  const ProgressDemo({super.key});

  @override
  State<ProgressDemo> createState() => _ProgressDemoState();
}

class _ProgressDemoState extends State<ProgressDemo> {
  double _percent = 0.6;

  void _increase() {
    setState(() {
      _percent = (((_percent + 0.1) * 10).round() / 10).clamp(0.0, 1.0);
    });
  }

  void _decrease() {
    setState(() {
      _percent = (((_percent - 0.1) * 10).round() / 10).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Line Progress (LTR & RTL support)
        Group(
          'Line Progress Bar (LTR & RTL)',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 320, child: Progress(percent: _percent)),
              const SizedBox(height: 12),
              SizedBox(
                width: 320,
                child: Progress(
                  percent: _percent,
                  direction: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 320,
                child: Progress(percent: _percent, status: StatusType.warning),
              ),
              const SizedBox(height: 12),
              const SizedBox(width: 320, child: Progress(percent: 1.0)),
            ],
          ),
        ),

        // 2. Circular & Dashboard Progress (gapDegree & gapPlacement)
        Group(
          'Circular & Dashboard (gapPlacement & gapDegree)',
          Wrap(
            spacing: 24,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Progress(type: ProgressType.circle, percent: _percent),
              const Progress(
                type: ProgressType.circle,
                percent: 1.0,
                status: StatusType.success,
              ),
              Progress(
                type: ProgressType.dashboard,
                percent: _percent,
                gapPlacement: GapPlacement.bottom,
              ),
              Progress(
                type: ProgressType.dashboard,
                percent: _percent,
                gapPlacement: GapPlacement.top,
              ),
              Progress(
                type: ProgressType.dashboard,
                percent: _percent,
                gapPlacement: GapPlacement.left,
              ),
              Progress(
                type: ProgressType.dashboard,
                percent: _percent,
                gapPlacement: GapPlacement.right,
                gapDegree: 120,
                gradient: const SweepGradient(
                  colors: [Color(0xFF108EE9), Color(0xFF87D068)],
                ),
              ),
              Progress(
                type: ProgressType.dashboard,
                percent: _percent,
                gapPlacement: GapPlacement.right,
                gapDegree: 180,
                gradient: const SweepGradient(
                  colors: [Color(0xFF108EE9), Color(0xFF87D068)],
                ),
              ),
            ],
          ),
        ),

        // 3. A child in the middle (child)
        Group(
          'A child in place of the label (child)',
          Wrap(
            spacing: 24,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // An icon instead of the percentage.
              Progress(
                type: ProgressType.circle,
                percent: _percent,
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: 36,
                  color: context.softToken.primary.base,
                ),
              ),
              // Anything at all: here the count the ring is measuring.
              Progress(
                type: ProgressType.circle,
                percent: _percent,
                strokeWidth: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(_percent * 24).round()}',
                      style: TextStyle(
                        fontSize: 28,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        color: context.softToken.colorText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'of 24 files',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.softToken.colorTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // A dashboard ring around an avatar.
              Progress(
                type: ProgressType.dashboard,
                percent: _percent,
                size: const ControlSize.fixed(96),
                strokeWidth: 6,
                child: const Avatar(
                  size: ControlSize.fixed(56),
                  child: Text('AS'),
                ),
              ),
              // On a bar the child stands where the label would.
              SizedBox(
                width: 300,
                child: Progress(
                  percent: _percent,
                  child: Tag(
                    color: _percent >= 1
                        ? TagColor.success
                        : TagColor.processing,
                    child: Text(_percent >= 1 ? 'done' : 'uploading'),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Gradient Progress
        Group(
          'Gradient Progress',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: Progress(
                  percent: _percent,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF4D4F), Color(0xFFFFD700)],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 320,
                child: Progress(
                  percent: _percent,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF108EE9), Color(0xFF87D068)],
                  ),
                ),
              ),
            ],
          ),
        ),

        Group(
          'Dynamic Controls',
          Wrap(
            spacing: 12,
            children: [
              Button(icon: const Icon(Icons.remove), onPressed: _decrease),
              Button(icon: const Icon(Icons.add), onPressed: _increase),
            ],
          ),
        ),

        // 4. Step-style Progress & Custom Colors
        Group(
          'Step Progress & Custom Colors',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: Progress(
                  percent: _percent,
                  steps: const ProgressSteps(3),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 320,
                child: Progress(
                  percent: _percent,
                  steps: const ProgressSteps(5),
                ),
              ),
              const SizedBox(height: 12),
              Progress(
                percent: _percent,
                steps: const ProgressSteps(5),
                status: StatusType.success,
                strokeColor: const [
                  Color(0xFF52C41A),
                  Color(0xFF52C41A),
                  Color(0xFF52C41A),
                  Color(0xFF52C41A),
                  Color(0xFF52C41A),
                ],
                size: const ControlSize.raw(4, 16),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 320,
                child: Progress(
                  percent: 0.6,
                  steps: ProgressSteps(5),
                  strokeColor: [
                    Color(0xFF52C41A),
                    Color(0xFF52C41A),
                    Color(0xFFFF4D4F),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Progress(
                percent: _percent,
                steps: const ProgressSteps(3),
                size: const ControlSize.raw(20, 30),
              ),
            ],
          ),
        ),

        // 4. Step Progress Bar (gradually & immediately fill)
        Group(
          'Step Progress Bar (gradually & immediately)',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: Progress(
                  percent: _percent,
                  steps: const ProgressSteps(
                    5,
                    fill: ProgressStepFill.gradually,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 320,
                child: Progress(
                  percent: _percent,
                  steps: const ProgressSteps(
                    5,
                    fill: ProgressStepFill.immediately,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Progress(
                percent: _percent,
                steps: const ProgressSteps(3),
                size: const ControlSize.raw(20, 30),
              ),
            ],
          ),
        ),

        // 5. Square Line Cap (strokeLinecap: StrokeCap.butt)
        Group(
          'Square Line Cap (strokeLinecap: StrokeCap.butt)',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: Progress(
                  percent: _percent,
                  strokeLinecap: StrokeCap.butt,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                children: [
                  Progress(
                    type: ProgressType.circle,
                    percent: _percent,
                    strokeLinecap: StrokeCap.butt,
                  ),
                  Progress(
                    type: ProgressType.dashboard,
                    percent: _percent,
                    strokeLinecap: StrokeCap.butt,
                  ),
                ],
              ),
            ],
          ),
        ),

        // 6. Custom Formatter
        Group(
          'Custom Formatter',
          SizedBox(
            width: 250,
            child: Progress(
              percent: _percent,
              format: (p) => Text('${(p * 10).round()} / 10 Tasks'),
            ),
          ),
        ),

        // 7. Info Position (percentPosition)
        Group(
          'Info Position (percentPosition)',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: Progress(
                  percent: _percent,
                  percentPosition: const PercentPosition.inner(
                    align: PercentInfoAlign.center,
                  ),
                  strokeWidth: 20,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: Progress(
                  percent: _percent,
                  percentPosition: const PercentPosition.inner(
                    align: PercentInfoAlign.start,
                  ),
                  strokeWidth: 20,
                  color: const Color(0xFFB7EB8F),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: Progress(
                  percent: _percent,
                  percentPosition: const PercentPosition.inner(
                    align: PercentInfoAlign.end,
                  ),
                  strokeWidth: 20,
                  color: const Color(0xFF001342),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: Progress(
                  percent: _percent,
                  percentPosition: const PercentPosition.inner(
                    align: PercentInfoAlign.follow,
                  ),
                  strokeWidth: 20,
                  color: const Color(0xFF1677FF),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 300,
                child: Progress(
                  percent: _percent,
                  percentPosition: const PercentPosition.outer(
                    align: PercentInfoAlign.start,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: Progress(
                  percent: _percent,
                  percentPosition: const PercentPosition.outer(
                    align: PercentInfoAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: Progress(
                  percent: _percent,
                  percentPosition: const PercentPosition.outer(
                    align: PercentInfoAlign.follow,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 8. Range Colors
        Group(
          'Range Colors',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: Progress(
                  percent: _percent,
                  rangeColors: const {
                    ProgressRange(0.0, to: 0.3): Color(0xFFFF4D4F),
                    ProgressRange(0.3, to: 0.7): Color(0xFFFFA940),
                    ProgressRange(0.7): Color(0xFF52C41A),
                  },
                ),
              ),
              const SizedBox(height: 12),
              Progress(
                type: ProgressType.circle,
                percent: _percent,
                rangeColors: const {
                  ProgressRange(0.0): Color(0xFFFF4D4F),
                  ProgressRange(0.3, to: 0.7): Color(0xFFFFA940),
                  ProgressRange(0.7): Color(0xFF52C41A),
                },
              ),
            ],
          ),
        ),
        Group(
          'Dynamic Controls',
          Wrap(
            spacing: 12,
            children: [
              Button(icon: const Icon(Icons.remove), onPressed: _decrease),
              Button(icon: const Icon(Icons.add), onPressed: _increase),
            ],
          ),
        ),
        // 9. Circle & Dashboard Steps
        Group(
          'Circle & Dashboard Steps',
          Wrap(
            spacing: 24,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Progress(
                type: ProgressType.circle,
                percent: _percent,
                steps: const ProgressSteps(5),
              ),
              Progress(
                type: ProgressType.circle,
                percent: _percent,
                steps: const ProgressSteps(30),
              ),
              Progress(
                type: ProgressType.dashboard,
                percent: _percent,
                steps: const ProgressSteps(8),
              ),
              // Wide / Thick Circle Steps
              Progress(
                type: ProgressType.circle,
                percent: _percent,
                steps: const ProgressSteps(6),
                strokeWidth: 14,
                size: const ControlSize.fixed(140),
              ),
              Progress(
                type: ProgressType.circle,
                percent: _percent,
                steps: const ProgressSteps(5),
                strokeWidth: 16,
                size: const ControlSize.fixed(140),
                strokeColor: const [
                  Color(0xFF1677FF),
                  Color(0xFF52C41A),
                  Color(0xFFFAAD14),
                  Color(0xFFFF4D4F),
                  Color(0xFF722ED1),
                ],
              ),
              Progress(
                type: ProgressType.dashboard,
                percent: _percent,
                steps: const ProgressSteps(10),
                strokeWidth: 18,
                size: const ControlSize.fixed(140),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1677FF), Color(0xFF52C41A)],
                ),
              ),
              Progress(
                type: ProgressType.dashboard,
                percent: _percent,
                steps: const ProgressSteps(10),
                strokeWidth: 18,
                size: const ControlSize.fixed(140),
                rangeColors: const {
                  ProgressRange(0.0, to: 0.3): Color(0xFFFF4D4F),
                  ProgressRange(0.3, to: 0.7): Color(0xFFFFA940),
                  ProgressRange(0.7): Color(0xFF52C41A),
                },
              ),
              Progress(
                type: ProgressType.circle,
                percent: _percent,
                steps: const ProgressSteps(5, gap: 7),
                strokeWidth: 20,
                size: const ControlSize.fixed(140),
              ),
            ],
          ),
        ),

        // 10. Per-Step Corner Radius (stepRadius)
        Group(
          'Per-Step Corner Radius (stepRadius)',
          SizedBox(
            width: 320,
            child: Progress(
              percent: _percent,
              steps: ProgressSteps(
                5,
                gap: 6,
                // Named by reading order, not by side: `isFirst` is a place
                // in the run, and the first step is on the right when the bar
                // reads that way.
                stepRadius: (isFirst, percent) {
                  if (isFirst == true) {
                    return const ProgressBorderRadius.horizontalDirectional(
                      start: 8,
                    );
                  }
                  if (isFirst == false) {
                    return const ProgressBorderRadius.horizontalDirectional(
                      end: 8,
                    );
                  }
                  return ProgressBorderRadius.zero;
                },
              ),
              strokeWidth: 16,
            ),
          ),
        ),

        // 10. Custom Border Radius (Line)
        Group(
          'Custom Border Radius (Line)',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: Progress(
                  percent: _percent,
                  strokeWidth: 14,
                  borderRadius: const ProgressBorderRadius.all(4),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: Progress(
                  percent: _percent,
                  strokeWidth: 14,
                  // The end the bar grows from, which follows the reading
                  // direction. Name the corners outright with the plain
                  // constructor when a side is what is meant.
                  borderRadius: const ProgressBorderRadius.directional(
                    topStart: 10,
                    bottomStart: 10,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: Progress(
                  percent: _percent,
                  steps: ProgressSteps(
                    5,
                    gap: 6,
                    onStepChange: (step, total) {
                      message.info('Step $step of $total reached');
                    },
                  ),
                  strokeWidth: 14,
                  borderRadius: const ProgressBorderRadius.all(4),
                  onProgressChange: (percent) {
                    debugPrint("Progress changed $percent");
                  },
                  onDone: () {
                    message.success('Progress completed!');
                  },
                ),
              ),
            ],
          ),
        ),

        // 10. Interactive Controls
        Group(
          'Dynamic Controls',
          Wrap(
            spacing: 12,
            children: [
              Button(icon: const Icon(Icons.remove), onPressed: _decrease),
              Button(icon: const Icon(Icons.add), onPressed: _increase),
            ],
          ),
        ),
      ],
    );
  }
}
