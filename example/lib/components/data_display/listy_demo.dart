import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer, Card;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class ListyDemo extends StatefulWidget {
  const ListyDemo({super.key});

  @override
  State<ListyDemo> createState() => _ListyDemoState();
}

const Map<String, IconData> _roleIcons = {
  'Design': Icons.brush_outlined,
  'Engineering': Icons.code,
  'Support': Icons.support_agent,
  'Sales': Icons.trending_up,
};

class _Contact {
  const _Contact(this.id, this.name, this.role);
  final String id;
  final String name;
  final String role;

  String get initial => name[0].toUpperCase();
}

class _ListyDemoState extends State<ListyDemo> {
  final ListyController _controller = ListyController();

  // 200 rows: still far more than fits, so only a handful is ever built.
  late final List<_Contact> _contacts = List.generate(200, (i) {
    const names = [
      'Ada',
      'Boris',
      'Clara',
      'Dmitri',
      'Elena',
      'Fyodor',
      'Galina',
      'Hugo',
      'Irina',
      'Jakob',
      'Ksenia',
      'Lev',
    ];
    const roles = ['Design', 'Engineering', 'Support', 'Sales'];
    final name = '${names[i % names.length]} #${i + 1}';
    return _Contact('id-$i', name, roles[i % roles.length]);
  });

  // Infinite loading: a page at a time out of the same source.
  final List<_Contact> _page = [];
  bool _loading = false;
  double _threshold = 120;
  bool _customFooter = false;

  // Pull-to-refresh: the header decides what it looks like at every stage.
  late List<_Contact> _feed = _contacts.take(30).toList();
  int _refreshes = 0;
  String _lastRefresh = 'never';

  // Customisation: row density through tokens, surfaces through styles.
  double _density = 12;
  String _skin = 'default';

  @override
  void initState() {
    super.initState();
    _page.addAll(_contacts.take(12));
  }

  Future<void> _refresh() async {
    // Stand-in for a real fetch: takes its time, then hands back new rows.
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _refreshes++;
      _lastRefresh =
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';
      // Visibly different rows, so a refresh is not a no-op on screen.
      _feed = (_refreshes.isOdd ? _contacts.reversed : _contacts)
          .take(30)
          .toList();
    });
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _page.addAll(_contacts.skip(_page.length).take(12));
      _loading = false;
    });
  }

  /// The two non-default looks the demo offers.
  ListyStyles _listySkin(Token t) => _skin == 'plain'
      ? ListyStyles(
          // An empty decoration drops the hairline the list draws by default.
          item: const BoxDecoration(),
          groupHeader: BoxDecoration(color: t.colorBgContainer),
        )
      : ListyStyles(
          root: BoxDecoration(color: t.colorBgLayout),
          item: BoxDecoration(
            color: t.colorBgContainer,
            borderRadius: BorderRadius.circular(t.borderRadiusLG),
            border: Border.all(color: t.colorBorderSecondary),
          ),
          itemHovered: BoxDecoration(
            color: t.colorBgContainer,
            borderRadius: BorderRadius.circular(t.borderRadiusLG),
            border: Border.all(color: t.primary.border),
            boxShadow: t.boxShadowSecondary,
          ),
          itemPadding: const EdgeInsets.all(12),
          groupHeader: BoxDecoration(color: t.colorBgLayout),
        );

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;

    Widget row(_Contact c) => Row(
      children: [
        Avatar(child: Text(c.initial)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.name),
              Text(
                c.role,
                style: TextStyle(
                  fontSize: t.fontSizeSM,
                  color: t.colorTextSecondary,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: t.colorTextTertiary),
      ],
    );

    Widget framed(Widget child) => Container(
      decoration: BoxDecoration(
        border: Border.all(color: t.colorBorderSecondary),
        borderRadius: BorderRadius.circular(t.borderRadiusLG),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Basic — 200 rows, built lazily',
          framed(
            Listy(
              height: 260,
              items: _contacts,
              rowKey: (c) => c.id,
              itemRender: (c, index) => row(c),
            ),
          ),
        ),

        Group(
          'Grouping with sticky headers',
          framed(
            Listy(
              height: 280,
              sticky: true,
              items: _contacts,
              rowKey: (c) => c.id,
              groupKey: (c) => c.role,
              groupTitle: (role, items) => Text('$role · ${items.length}'),
              itemRender: (c, index) => Text(c.name),
            ),
          ),
        ),

        // The controller reaches rows that were never built: the list hops
        // towards them, building as it goes, then settles exactly.
        Group(
          'Scroll control',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Button(
                    onPressed: () => _controller.scrollTo(
                      // `top` parks the row at the top of the viewport —
                      // just under the pinned group header.
                      const ListyScrollTo.item(
                        'id-150',
                        align: ListyScrollAlign.top,
                      ),
                      duration: const Duration(milliseconds: 300),
                    ),
                    child: const Text('To item #151'),
                  ),
                  Button(
                    onPressed: () => _controller.scrollTo(
                      const ListyScrollTo.group(
                        'Support',
                        align: ListyScrollAlign.top,
                      ),
                      duration: const Duration(milliseconds: 450),
                    ),
                    child: const Text('To “Support”'),
                  ),
                  Button(
                    onPressed: () => _controller.scrollTo(
                      const ListyScrollTo.offset(0),
                      duration: const Duration(milliseconds: 300),
                    ),
                    child: const Text('To top'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              framed(
                Listy(
                  height: 280,
                  sticky: true,
                  controller: _controller,
                  items: _contacts,
                  rowKey: (c) => c.id,
                  groupKey: (c) => c.role,
                  groupTitle: (role, items) => Text(role),
                  itemRender: (c, index) => Text(c.name),
                ),
              ),
            ],
          ),
        ),

        // Paging is declared, not wired: Listy watches the distance to the
        // end and calls onLoad once per page.
        Group(
          'Infinite loading',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Load when within'),
                  Segmented<double>(
                    size: SoftSize.small,
                    value: _threshold,
                    options: const [
                      SegmentedOption(value: 0, label: 'the very end'),
                      SegmentedOption(value: 120, label: '120px'),
                      SegmentedOption(value: 600, label: '600px'),
                    ],
                    onChanged: (v) => setState(() => _threshold = v),
                  ),
                  Tag(
                    color: TagColor.processing,
                    child: Text('${_page.length} / ${_contacts.length}'),
                  ),
                  Button(
                    size: SoftSize.small,
                    onPressed: () => setState(() {
                      _page
                        ..clear()
                        ..addAll(_contacts.take(12));
                    }),
                    child: const Text('Reset'),
                  ),
                  Switch(
                    value: _customFooter,
                    onChanged: (v) => setState(() => _customFooter = v),
                  ),
                  const Text('Custom footer'),
                ],
              ),
              const SizedBox(height: 12),
              framed(
                Listy(
                  height: 260,
                  items: _page,
                  rowKey: (c) => c.id,
                  loadMore: ListyLoadMore(
                    onLoad: _loadMore,
                    loading: _loading,
                    hasMore: _page.length < _contacts.length,
                    threshold: _threshold,
                    // Null falls back to a centred spinner and a muted
                    // "No more items"; a supplied footer is drawn as-is.
                    indicator: _customFooter
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            color: t.primary.bg,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Spinner(size: 14, color: t.primary.base),
                                const SizedBox(width: 8),
                                Text(
                                  'Fetching the next 12…',
                                  style: TextStyle(color: t.primary.text),
                                ),
                              ],
                            ),
                          )
                        : null,
                    endIndicator: _customFooter
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            color: t.success.bg,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: t.success.base,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'All ${_contacts.length} contacts loaded',
                                  style: TextStyle(color: t.success.text),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                  itemRender: (c, index) => Text(c.name),
                ),
              ),
            ],
          ),
        ),

        // The header is a widget built from the live pull, so it can be a
        // static bar, a refresh indicator, or morph with the drag.
        Group(
          'Header & pull to refresh',
          framed(
            Listy(
              height: 280,
              items: _feed,
              rowKey: (c) => c.id,
              header: ListyHeader(
                triggerExtent: 72,
                onRefresh: _refresh,
                builder: (context, pull) {
                  if (pull.refreshing) {
                    return Container(
                      height: 52,
                      color: t.primary.bg,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Spinner(size: 16, color: t.primary.base),
                          const SizedBox(width: 8),
                          Text(
                            'Refreshing…',
                            style: TextStyle(color: t.primary.text),
                          ),
                        ],
                      ),
                    );
                  }
                  if (pull.extent == 0) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      color: t.colorFillQuaternary,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Refreshed $_refreshes times · last at '
                              '$_lastRefresh',
                            ),
                          ),
                          Text(
                            'pull to refresh ↓',
                            style: TextStyle(
                              color: t.colorTextTertiary,
                              fontSize: t.fontSizeSM,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  // While dragging the header grows with the finger and the
                  // arrow flips over once the pull is armed.
                  return SizedBox(
                    height: pull.extent.clamp(0, 96),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.rotate(
                            angle: pull.progress * 3.14159,
                            child: Icon(
                              Icons.arrow_downward,
                              size: 16,
                              color: pull.armed
                                  ? t.primary.base
                                  : t.colorTextTertiary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            pull.armed ? 'Release to refresh' : 'Keep pulling',
                            style: TextStyle(
                              color: pull.armed
                                  ? t.primary.text
                                  : t.colorTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              itemRender: (c, index) => Text(c.name),
            ),
          ),
        ),

        // Everything the list draws around your rows is yours to change:
        // spacing through tokens, a pinned toolbar through the header, and
        // section headers through groupTitle.
        Group(
          'Customisation',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Row density'),
                  Segmented<double>(
                    size: SoftSize.small,
                    value: _density,
                    options: const [
                      SegmentedOption(value: 6, label: 'compact'),
                      SegmentedOption(value: 12, label: 'default'),
                      SegmentedOption(value: 20, label: 'roomy'),
                    ],
                    onChanged: (v) => setState(() => _density = v),
                  ),
                  const Text('Surfaces'),
                  Segmented<String>(
                    size: SoftSize.small,
                    value: _skin,
                    options: const [
                      SegmentedOption(value: 'default', label: 'default'),
                      SegmentedOption(value: 'plain', label: 'no dividers'),
                      SegmentedOption(value: 'cards', label: 'cards'),
                    ],
                    onChanged: (v) => setState(() => _skin = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              framed(
                // Tokens set on a ConfigProvider reach every Listy in the
                // subtree; a `token` on the widget itself would win over this.
                ConfigProvider(
                  components: [
                    ListyToken(
                      itemPaddingBlock: _density,
                      itemPaddingInline: 16,
                    ),
                  ],
                  child: Listy(
                    height: 320,
                    sticky: true,
                    items: _contacts.take(60).toList(),
                    rowKey: (c) => c.id,
                    // `styles` restyles the chrome the list owns — the row
                    // hairline, the hover tint, the section header wash.
                    styles: _skin == 'default' ? null : _listySkin(t),
                    // A pinned header is a toolbar: it needs a fixed extent
                    // because it has to reserve its space up front.
                    header: ListyHeader(
                      pinned: true,
                      extent: 44,
                      builder: (context, pull) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        color: t.colorBgContainer,
                        child: Row(
                          children: [
                            Icon(
                              Icons.contacts_outlined,
                              size: 16,
                              color: t.colorTextSecondary,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Team directory')),
                            const Tag(
                              color: TagColor.processing,
                              child: Text('60'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    groupHeaderExtent: 40,
                    groupKey: (c) => c.role,
                    groupTitle: (role, items) => Row(
                      children: [
                        Icon(_roleIcons[role], size: 14, color: t.primary.base),
                        const SizedBox(width: 8),
                        Expanded(child: Text(role.toUpperCase())),
                        Text(
                          '${items.length}',
                          style: TextStyle(color: t.colorTextTertiary),
                        ),
                      ],
                    ),
                    itemRender: (c, index) => row(c),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
