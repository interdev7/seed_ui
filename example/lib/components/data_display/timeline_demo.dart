import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class TimelineDemo extends StatelessWidget {
  const TimelineDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    final basic = [
      const TimelineItem(content: Text('Create a services site 2015-09-01')),
      const TimelineItem(
        content: Text('Solve initial network problems 2015-09-01'),
      ),
      TimelineItem(
        color: t.error.base,
        content: const Text('Technical testing 2015-09-01'),
      ),
      const TimelineItem(
        content: Text('Network problems being solved 2015-09-01'),
      ),
    ];

    // Horizontal examples.
    final horizontalBasic = [
      const TimelineItem(content: Text('Step 1')),
      const TimelineItem(content: Text('Step 2')),
      TimelineItem(color: t.success.base, content: const Text('Step 3')),
      const TimelineItem(content: Text('Step 4')),
    ];

    final horizontalWithLabels = [
      TimelineItem(
        label: const Text('2024'),
        content: const Text('Planning'),
        color: t.primary.base,
      ),
      TimelineItem(
        label: const Text('2025'),
        content: const Text('Development'),
        color: t.success.base,
      ),
      TimelineItem(
        label: const Text('2026'),
        content: const Text('Launch'),
        color: t.error.base,
      ),
    ];

    final horizontalCustomDots = [
      TimelineItem(
        content: const Text('Start'),
        dot: Icon(Icons.play_circle_fill, color: t.success.base, size: 20),
        color: t.success.base,
      ),
      TimelineItem(
        content: const Text('Progress'),
        dot: Icon(Icons.hourglass_top, color: t.warning.base, size: 20),
        color: t.warning.base,
      ),
      TimelineItem(
        content: const Text('Done'),
        dot: Icon(Icons.check_circle, color: t.success.base, size: 20),
        color: t.success.base,
      ),
    ];

    // Helper widget for the horizontal timeline.
    Widget horizontalTimeline({
      required List<TimelineItem> items,
      TimelineMode mode = TimelineMode.left,
      Widget? pending,
      Widget? pendingDot,
      bool reverse = false,
      TimelineToken? token,
      double? titleSpan,
    }) {
      // No fixed height: the timeline hugs its content (IntrinsicHeight).
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Timeline(
          orientation: TimelineOrientation.horizontal,
          mode: mode,
          items: items,
          pending: pending,
          pendingDot: pendingDot,
          reverse: reverse,
          token: token,
          titleSpan: titleSpan,
        ),
      );
    }

    // A filled bead dot of a given diameter.
    Widget bead(double d) => Container(
      width: d,
      height: d,
      decoration: BoxDecoration(color: t.primary.base, shape: BoxShape.circle),
    );
    // An invisible content spacer: the item's width sets the line length, since
    // the gap between two dots is (widthA + widthB) / 2.
    Widget span(double w) => SizedBox(width: w, height: 0);

    // A label at the top with the box height setting the vertical line length.
    Widget labelSpan(String text, double h) => SizedBox(
      height: h,
      child: Align(alignment: Alignment.topLeft, child: Text(text)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // `railInset` opens a gap between the thread and each dot, turning the
        // line from a connector into a separator; `dotVariant` lets one node
        // break ranks with the run's own variant.
        const Group(
          'Rail inset & a dot of its own',
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Timeline(
                  items: [
                    TimelineItem(title: Text('Joined'), content: Text('flush')),
                    TimelineItem(
                      title: Text('Verified'),
                      dotVariant: TimelineVariant.filled,
                      content: Text('filled dot in an outlined run'),
                    ),
                    TimelineItem(title: Text('Active')),
                  ],
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: Timeline(
                  token: TimelineToken(railInset: RailInsets.all(4)),
                  items: [
                    TimelineItem(
                      title: Text('Joined'),
                      content: Text('inset 4'),
                    ),
                    TimelineItem(
                      title: Text('Verified'),
                      dotVariant: TimelineVariant.filled,
                    ),
                    TimelineItem(title: Text('Active')),
                  ],
                ),
              ),
            ],
          ),
        ),

        // `titleSpan` is the distance from the dot to the content — the same
        // number in either orientation, where it becomes the gap above or
        // below the axis.
        Group(
          'Title span (space between the dot and the content)',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final span in <double?>[null, 32, 72])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        span == null ? 'default (12)' : 'titleSpan: $span',
                        style: TextStyle(color: t.colorTextTertiary),
                      ),
                      const SizedBox(height: 4),
                      Timeline(
                        titleSpan: span,
                        items: const [
                          TimelineItem(
                            label: Text('09:12'),
                            title: Text('Order placed'),
                          ),
                          TimelineItem(
                            label: Text('09:30'),
                            title: Text('Payment confirmed'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              // Horizontally the same number is the gap above and below the
              // axis instead.
              horizontalTimeline(items: horizontalBasic, titleSpan: 40),
            ],
          ),
        ),

        // === VERTICAL EXAMPLES ===
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'VERTICAL TIMELINE',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),

        Group('Basic', Timeline(items: basic)),
        Group(
          'Coloured dots',
          Timeline(
            items: [
              TimelineItem(
                color: t.success.base,
                content: const Text('Create a services site'),
              ),
              TimelineItem(
                color: t.success.base,
                content: const Text('Solve initial network problems'),
              ),
              TimelineItem(
                color: t.error.base,
                content: const Text('Technical testing'),
              ),
              TimelineItem(
                color: t.colorTextQuaternary,
                content: const Text('Cancelled'),
              ),
            ],
          ),
        ),
        Group(
          'Custom dot',
          Timeline(
            items: [
              const TimelineItem(
                content: Text('Create a services site 2015-09-01'),
              ),
              TimelineItem(
                dot: Icon(Icons.check_circle, size: 16, color: t.success.base),
                content: const Text(
                  'Solve initial network problems 2015-09-01',
                ),
              ),
              TimelineItem(
                dot: Icon(Icons.flag, size: 16, color: t.error.base),
                content: const Text('Technical testing 2015-09-01'),
              ),
            ],
          ),
        ),
        Group('Right mode', Timeline(mode: TimelineMode.right, items: basic)),
        Group(
          'Alternate',
          Timeline(mode: TimelineMode.alternate, items: basic),
        ),
        const Group(
          'With labels',
          Timeline(
            items: [
              TimelineItem(
                label: Text('2015-09-01'),
                content: Text('Create a services site'),
              ),
              TimelineItem(
                label: Text('2015-09-01 09:12:11'),
                content: Text('Solve initial network problems'),
              ),
              TimelineItem(
                label: Text('2015-09-01'),
                content: Text('Technical testing'),
              ),
            ],
          ),
        ),
        const Group(
          'Pending',
          Timeline(
            pending: Text('Recording...'),
            items: [
              TimelineItem(content: Text('Create a services site 2015-09-01')),
              TimelineItem(
                content: Text('Solve initial network problems 2015-09-01'),
              ),
            ],
          ),
        ),
        const Group(
          'Reverse (pending on top)',
          Timeline(
            reverse: true,
            pending: Text('Recording...'),
            items: [
              TimelineItem(content: Text('Create a services site 2015-09-01')),
              TimelineItem(
                content: Text('Solve initial network problems 2015-09-01'),
              ),
            ],
          ),
        ),

        Group(
          'Vertical - beads with dashed finish',
          Timeline(
            pending: const Text('Finish'),
            pendingDot: Icon(
              Icons.sports_score,
              size: 18,
              color: t.success.base,
            ),
            items: [
              TimelineItem(dot: bead(14), content: labelSpan('Start', 90)),
              for (var i = 0; i < 5; i++)
                TimelineItem(
                  dot: bead(7),
                  content: labelSpan('Step ${i + 1}', 24),
                ),
              TimelineItem(dot: bead(14), content: labelSpan('Checkpoint', 90)),
            ],
          ),
        ),

        Group(
          'Title + description (Chakra-style content)',
          Timeline(
            items: [
              const TimelineItem(
                title: Text('Order placed'),
                description: Text('2015-09-01 09:12'),
              ),
              TimelineItem(
                color: t.success.base,
                title: const Text('Payment confirmed'),
                description: const Text('Visa •••• 4242'),
              ),
              TimelineItem(
                color: t.warning.base,
                title: const Text('Shipped'),
                description: const Text('Courier picked up the parcel'),
                // Free-form content still sits under the title block.
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: 16,
                      color: t.colorTextTertiary,
                    ),
                    const SizedBox(width: 6),
                    const Text('Tracking: SU-9912-KX'),
                  ],
                ),
              ),
              const TimelineItem(
                title: Text('Delivered'),
                description: Text('Awaiting confirmation'),
                contentOpacity: 0.45,
              ),
            ],
          ),
        ),

        Group(
          'Card in content',
          Timeline(
            items: [
              TimelineItem(
                color: t.success.base,
                title: const Text('Build #1287 passed'),
                description: const Text('2015-09-01 09:12'),
                content: Card(
                  size: SoftSize.small,
                  title: const Text('CI report'),
                  extra: const Tag(
                    color: TagColor.success,
                    child: Text('passed'),
                  ),
                  child: CardMeta(
                    avatar: StatusIcon(type: StatusType.success, token: t),
                    title: const Text('124 tests · 0 failed'),
                    description: const Text('Duration: 1m 48s'),
                  ),
                ),
              ),
              TimelineItem(
                color: t.error.base,
                title: const Text('Deploy failed'),
                description: const Text('2015-09-01 09:30'),
                content: Card(
                  size: SoftSize.small,
                  variant: CardVariant.borderless,
                  title: const Text('staging'),
                  extra: const Tag(color: TagColor.error, child: Text('error')),
                  actions: [
                    Button(
                      size: SoftSize.small,
                      onPressed: () => message.info('Retrying…'),
                      child: const Text('Retry'),
                    ),
                    Button(
                      size: SoftSize.small,
                      variant: ButtonVariant.text,
                      onPressed: () => message.info('Opening logs…'),
                      child: const Text('Logs'),
                    ),
                  ],
                  child: const Text('Health check timed out after 30s.'),
                ),
              ),
              const TimelineItem(
                title: Text('Rolled back'),
                description: Text('Previous revision restored'),
              ),
            ],
          ),
        ),

        const Group('Grouped nodes (expand / collapse)', _GroupedTimeline()),

        const Group(
          'Title + description with labels',
          Timeline(
            mode: TimelineMode.alternate,
            items: [
              TimelineItem(
                label: Text('Q1'),
                title: Text('Planning'),
                description: Text('Scope, budget and team setup'),
              ),
              TimelineItem(
                label: Text('Q2'),
                title: Text('Development'),
                description: Text('Two-week iterations'),
              ),
              TimelineItem(
                label: Text('Q3'),
                title: Text('Launch'),
                description: Text('Public release'),
              ),
            ],
          ),
        ),

        const Group(
          'Per-item style (height, dashed rail, opacity)',
          Timeline(
            items: [
              TimelineItem(content: Text('Create a services site 2015-09-01')),
              TimelineItem(
                content: Text('Solve initial network problems 2015-09-01'),
                height: 100,
                dashed: true,
              ),
              TimelineItem(
                content: Text('...for a long time...'),
                height: 100,
                dashed: true,
                contentOpacity: 0.45,
              ),
              TimelineItem(content: Text('Technical testing 2015-09-01')),
              TimelineItem(
                content: Text('Network problems being solved 2015-09-01'),
              ),
            ],
          ),
        ),

        // === HORIZONTAL EXAMPLES ===
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'HORIZONTAL TIMELINE',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),

        Group('Horizontal - Basic', horizontalTimeline(items: horizontalBasic)),

        Group(
          'Horizontal - per-item style (width, dashed, opacity)',
          horizontalTimeline(
            items: const [
              TimelineItem(content: Text('Start')),
              TimelineItem(content: Text('Build'), width: 140, dashed: true),
              TimelineItem(
                content: Text('…'),
                width: 140,
                dashed: true,
                contentOpacity: 0.45,
              ),
              TimelineItem(content: Text('Test')),
              TimelineItem(content: Text('Ship')),
            ],
          ),
        ),

        Group(
          'Horizontal - beads',
          horizontalTimeline(
            token: const TimelineToken(itemPaddingEnd: 0),
            items: [
              TimelineItem(dot: bead(14), content: span(90)),
              for (var i = 0; i < 5; i++)
                TimelineItem(dot: bead(7), content: span(24)),
              TimelineItem(dot: bead(14), content: span(90)),
            ],
          ),
        ),

        Group(
          'Horizontal - Coloured dots',
          horizontalTimeline(
            items: [
              TimelineItem(
                color: t.success.base,
                content: const Text('Step 1'),
              ),
              TimelineItem(
                color: t.primary.base,
                content: const Text('Step 2'),
              ),
              TimelineItem(color: t.error.base, content: const Text('Step 3')),
              TimelineItem(
                color: t.warning.base,
                content: const Text('Step 4'),
              ),
            ],
          ),
        ),

        Group(
          'Horizontal - With labels',
          horizontalTimeline(
            items: horizontalWithLabels,
            mode: TimelineMode.alternate,
          ),
        ),

        Group(
          'Horizontal - Custom dots',
          horizontalTimeline(items: horizontalCustomDots),
        ),

        Group(
          'Horizontal - Right mode',
          horizontalTimeline(
            mode: TimelineMode.right,
            items: [
              const TimelineItem(content: Text('Step A')),
              TimelineItem(
                content: const Text('Step B'),
                color: t.primary.base,
              ),
              const TimelineItem(content: Text('Step C')),
              const TimelineItem(content: Text('Step D')),
            ],
          ),
        ),

        Group(
          'Horizontal - Alternate',
          horizontalTimeline(
            mode: TimelineMode.alternate,
            items: [
              const TimelineItem(label: Text('Start'), content: Text('Begin')),
              TimelineItem(
                label: const Text('Middle'),
                content: const Text('Process'),
                color: t.primary.base,
              ),
              const TimelineItem(label: Text('End'), content: Text('Finish')),
            ],
          ),
        ),

        Group(
          'Horizontal - With pending',
          horizontalTimeline(
            pending: const Text('Loading...'),
            pendingDot: const Icon(Icons.more_horiz),
            items: [
              const TimelineItem(content: Text('Phase 1'), color: Colors.green),
              const TimelineItem(content: Text('Phase 2'), color: Colors.green),
              const TimelineItem(content: Text('Phase 3')),
            ],
          ),
        ),

        Group(
          'Horizontal - Reverse',
          horizontalTimeline(
            reverse: true,
            pending: const Text('Future'),
            items: [
              const TimelineItem(content: Text('Step 1'), color: Colors.green),
              const TimelineItem(content: Text('Step 2'), color: Colors.green),
              const TimelineItem(content: Text('Step 3'), color: Colors.green),
              const TimelineItem(content: Text('Step 4')),
            ],
          ),
        ),

        Group(
          'Horizontal - Custom token',
          horizontalTimeline(
            token: const TimelineToken(
              tailColor: Colors.blue,
              tailWidth: 3,
              dotSize: 14,
              dotBorderWidth: 3,
              itemPaddingEnd: 32,
            ),
            items: [
              const TimelineItem(
                content: Text('Jan'),
                color: Colors.blue,
                dot: Icon(Icons.star, color: Colors.blue, size: 16),
              ),
              const TimelineItem(content: Text('Feb'), color: Colors.purple),
              const TimelineItem(content: Text('Mar'), color: Colors.orange),
              const TimelineItem(
                content: Text('Apr'),
                color: Colors.green,
                dot: Icon(Icons.celebration, color: Colors.green, size: 16),
              ),
            ],
          ),
        ),

        // A horizontal timeline carrying richer content.
        Group(
          'Horizontal - Complex content',
          horizontalTimeline(
            mode: TimelineMode.alternate,
            items: [
              const TimelineItem(
                label: Text('Q1'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Planning',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Define scope', style: TextStyle(fontSize: 12)),
                    Text('Team setup', style: TextStyle(fontSize: 12)),
                  ],
                ),
                color: Colors.blue,
              ),
              const TimelineItem(
                label: Text('Q2'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Development',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Code review', style: TextStyle(fontSize: 12)),
                    Text('Testing', style: TextStyle(fontSize: 12)),
                  ],
                ),
                color: Colors.orange,
              ),
              const TimelineItem(
                label: Text('Q3'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Launch',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Deployment', style: TextStyle(fontSize: 12)),
                    Text('🎉 Release', style: TextStyle(fontSize: 12)),
                  ],
                ),
                color: Colors.green,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

/// A timeline whose middle nodes are folded into a group, opened and closed
/// from the outside through a [TimelineGroupController].
class _GroupedTimeline extends StatefulWidget {
  const _GroupedTimeline();

  @override
  State<_GroupedTimeline> createState() => _GroupedTimelineState();
}

class _GroupedTimelineState extends State<_GroupedTimeline> {
  final TimelineGroupController _group = TimelineGroupController();

  @override
  void dispose() {
    _group.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The button reads the controller, so its label follows the group even
        // when something else opens or closes it.
        ListenableBuilder(
          listenable: _group,
          builder: (context, _) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Button(
                variant: ButtonVariant.solid,
                color: ButtonColor.primary,
                onPressed: _group.toggle,
                icon: Icon(
                  _group.expanded ? Icons.expand_less : Icons.expand_more,
                ),
                child: Text(
                  _group.expanded ? 'Hide 4 steps' : 'Show 4 more steps',
                ),
              ),
              Button(onPressed: _group.open, child: const Text('open()')),
              Button(onPressed: _group.close, child: const Text('close()')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Timeline(
          items: [
            const TimelineItem(
              title: Text('Pull request opened'),
              description: Text('2015-09-01 08:40'),
            ),
            TimelineGroupItem(
              controller: _group,
              // The first node stays on screen; the rest fold away.
              items: [
                const TimelineItem(
                  title: Text('CI pipeline'),
                  description: Text('4 steps'),
                ),
                TimelineItem(
                  color: t.success.base,
                  dot: StatusIcon(type: StatusType.success, token: t),
                  title: const Text('Lint'),
                  description: const Text('12s'),
                ),
                TimelineItem(
                  color: t.success.base,
                  dot: StatusIcon(type: StatusType.success, token: t),
                  title: const Text('Unit tests'),
                  description: const Text('1m 48s · 124 passed'),
                ),
                TimelineItem(
                  color: t.success.base,
                  dot: StatusIcon(type: StatusType.success, token: t),
                  title: const Text('Build'),
                  description: const Text('2m 05s'),
                ),
                TimelineItem(
                  color: t.warning.base,
                  dot: StatusIcon(type: StatusType.warning, token: t),
                  title: const Text('Bundle size check'),
                  description: const Text('+18 KB over budget'),
                ),
              ],
            ),
            const TimelineItem(
              title: Text('Merged to main'),
              description: Text('2015-09-01 09:02'),
            ),
          ],
        ),
      ],
    );
  }
}
