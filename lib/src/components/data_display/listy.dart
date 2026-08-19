import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../icons/icons.dart' show Spinner;
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';

/// Where a [ListyController.scrollTo] target should come to rest.
enum ListyScrollAlign {
  /// Against the leading edge of the viewport.
  top,

  /// Against the trailing edge.
  bottom,

  /// Whichever edge is closer — scrolls the least amount that reveals it.
  auto,
}

/// How far the list has been pulled past its top, handed to
/// [ListyHeader.builder] so a header can react to the drag.
@immutable
class ListyPull {
  /// Creates a [ListyPull].
  const ListyPull({
    required this.extent,
    required this.progress,
    required this.refreshing,
  });

  /// Pixels dragged beyond the top. Zero when the list is not being pulled.
  final double extent;

  /// [extent] against [ListyHeader.triggerExtent], clamped to 0..1. At 1 a
  /// release fires [ListyHeader.onRefresh].
  final double progress;

  /// Whether [ListyHeader.onRefresh] is still running.
  final bool refreshing;

  /// Whether letting go now would trigger the refresh.
  bool get armed => progress >= 1;
}

/// A header above a [Listy]'s rows that can answer to the pull.
///
/// The builder receives the live [ListyPull], so the header is free to be a
/// static bar, a pull-to-refresh indicator, or anything that morphs with the
/// drag — it decides its own height, so it can grow with [ListyPull.extent].
///
/// ```dart
/// ListyHeader(
///   onRefresh: _reload,
///   builder: (context, pull) => SizedBox(
///     height: pull.refreshing ? 56 : pull.extent,
///     child: Center(
///       child: pull.refreshing
///           ? const Spinner(size: 18, color: Color(0xFF1677FF))
///           : Text(pull.armed ? 'Release to refresh' : 'Pull to refresh'),
///     ),
///   ),
/// )
/// ```
@immutable
class ListyHeader {
  /// Creates a [ListyHeader].
  const ListyHeader({
    required this.builder,
    this.onRefresh,
    this.triggerExtent = 72,
    this.pinned = false,
    this.extent,
  })  : assert(triggerExtent > 0, 'triggerExtent must be positive'),
        assert(
          !pinned || extent != null,
          'A pinned header needs an extent — it has to reserve its space.',
        );

  /// Builds the header from the current pull.
  final Widget Function(BuildContext context, ListyPull pull) builder;

  /// Runs when the list is released past [triggerExtent]. Null makes the
  /// header inert to the drag.
  final Future<void> Function()? onRefresh;

  /// How far the list must be pulled to arm the refresh.
  final double triggerExtent;

  /// Whether the header stays put while the rows scroll under it.
  final bool pinned;

  /// Fixed height, required when [pinned].
  final double? extent;
}

/// A scroll target for [ListyController.scrollTo].
///
/// Mirrors the `ListyScrollToConfig`: a pixel offset, an item, or a
/// group header.
@immutable
class ListyScrollTo {
  /// Scrolls to an absolute pixel offset.
  const ListyScrollTo.offset(double this.pixels)
      : itemKey = null,
        groupKey = null,
        align = ListyScrollAlign.top,
        offset = 0;

  /// Scrolls to the item whose [Listy.rowKey] matches [key].
  const ListyScrollTo.item(
    Object key, {
    this.align = ListyScrollAlign.auto,
    this.offset = 0,
  })  : itemKey = key,
        groupKey = null,
        pixels = null;

  /// Scrolls to a group's header.
  const ListyScrollTo.group(
    Object key, {
    this.align = ListyScrollAlign.auto,
    this.offset = 0,
  })  : groupKey = key,
        itemKey = null,
        pixels = null;

  /// Absolute offset, when built with [ListyScrollTo.offset].
  final double? pixels;

  /// Item identity, when built with [ListyScrollTo.item].
  final Object? itemKey;

  /// Group identity, when built with [ListyScrollTo.group].
  final Object? groupKey;

  /// Which edge the target rests against.
  final ListyScrollAlign align;

  /// Extra pixels applied after alignment; negative leaves room above.
  final double offset;
}

/// Drives a [Listy]'s scroll position from outside the widget.
///
/// ```dart
/// final listy = ListyController();
/// ...
/// listy.scrollTo(const ListyScrollTo.item('user-42'));
/// ```
///
/// Attach it through [Listy.controller]. It holds no resources of its own, so
/// there is nothing to dispose.
class ListyController {
  // ignore: strict_raw_type
  _ListyState? _state;

  /// Whether the controller is attached to a mounted [Listy].
  bool get isAttached => _state != null;

  /// Scrolls to [target], animating over [duration].
  ///
  /// A target that is not currently built — the whole point of a long list — is
  /// approached in steps: the list jumps to an estimate, builds the rows there,
  /// and repeats until the target is on screen, then settles it exactly.
  Future<void> scrollTo(
    ListyScrollTo target, {
    Duration duration = Duration.zero,
    Curve curve = Curves.easeInOut,
  }) async {
    assert(
      _state != null,
      'ListyController is not attached to a Listy. Pass it to '
      'Listy(controller: ...) and wait for the first build.',
    );
    await _state?.scrollTo(target, duration: duration, curve: curve);
  }

  // ignore: strict_raw_type
  void _attach(_ListyState state) => _state = state;

  // ignore: strict_raw_type
  void _detach(_ListyState state) {
    if (identical(_state, state)) _state = null;
  }
}

/// Loads more rows as the list nears its end — the "infinite list" pattern,
/// declared rather than wired up by hand.
///
/// ```dart
/// Listy<Post, String>(
///   items: _posts,
///   itemRender: (post, index) => Text(post.title),
///   loadMore: ListyLoadMore(
///     onLoad: _fetchNextPage,
///     loading: _fetching,
///     hasMore: _posts.length < _total,
///   ),
/// )
/// ```
///
/// [onLoad] fires once when the end comes within [threshold] pixels, and not
/// again until [loading] goes back to false or new items arrive — so a slow
/// request is never asked for twice. It also fires when the rows do not fill
/// the viewport at all, which would otherwise leave nothing to scroll.
@immutable
class ListyLoadMore {
  /// Creates a [ListyLoadMore].
  const ListyLoadMore({
    required this.onLoad,
    this.loading = false,
    this.hasMore = true,
    this.threshold = 200,
    this.indicator,
    this.endIndicator,
  }) : assert(threshold >= 0, 'threshold cannot be negative');

  /// Fetches the next page.
  final VoidCallback onLoad;

  /// Whether a fetch is in flight. Blocks further calls and shows [indicator].
  final bool loading;

  /// Whether anything is left to fetch. False stops calling [onLoad] and shows
  /// [endIndicator] instead.
  final bool hasMore;

  /// How close to the end, in pixels, triggers the fetch. `0` waits for the
  /// very end; a viewport-sized value loads a screen ahead.
  final double threshold;

  /// Footer while [loading]. Rendered as given, so it owns its own padding and
  /// alignment. Null shows a centred spinner.
  final Widget? indicator;

  /// Footer once [hasMore] is false, rendered as given like [indicator]. Null
  /// shows a muted "No more items".
  final Widget? endIndicator;
}

/// Overrides for the surfaces [Listy] draws around your content — the
/// semantic slots (`root`, `item`, `groupHeader`), as Flutter decorations.
///
/// Reach for it to restyle the chrome the list owns: the hairline under a row,
/// the hover tint, the wash behind a section header. The content itself belongs
/// to [Listy.itemRender] and [Listy.groupTitle], which is also where per-row
/// differences (striping, a selected row) go — these are one look for all rows.
///
/// ```dart
/// ListyStyles(
///   // Cards instead of hairline-separated rows.
///   item: BoxDecoration(
///     color: token.colorBgContainer,
///     borderRadius: BorderRadius.circular(8),
///     boxShadow: token.boxShadowTertiary,
///   ),
///   itemPadding: const EdgeInsets.all(12),
/// )
/// ```
@immutable
class ListyStyles {
  /// Creates a [ListyStyles].
  const ListyStyles({
    this.root,
    this.item,
    this.itemHovered,
    this.groupHeader,
    this.itemPadding,
    this.groupHeaderPadding,
  });

  /// Behind the whole list.
  final BoxDecoration? root;

  /// A row at rest. Replaces the default hairline separator outright, so an
  /// empty `BoxDecoration()` is how you drop the dividers.
  final BoxDecoration? item;

  /// A row under the pointer. Null tints [item] with `colorFillTertiary`, so
  /// hover feedback survives a custom row look without being spelled out.
  final BoxDecoration? itemHovered;

  /// A section header. Must stay opaque if the header is [Listy.sticky] —
  /// rows scroll underneath it.
  final BoxDecoration? groupHeader;

  /// Row padding, overriding `itemPaddingBlock` / `itemPaddingInline`.
  final EdgeInsets? itemPadding;

  /// Section header padding.
  final EdgeInsets? groupHeaderPadding;
}

/// Per-component design tokens for [Listy] — its own token table.
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [ListyToken(...)])`, or per instance via [Listy.token].
@immutable
class ListyToken {
  /// Creates a [ListyToken].
  const ListyToken({
    this.itemPaddingBlock,
    this.itemPaddingInline,
  });

  /// Vertical padding of a list item (`itemPaddingBlock`).
  final double? itemPaddingBlock;

  /// Horizontal padding of a list item (`itemPaddingInline`).
  final double? itemPaddingInline;

  _ResolvedListyToken _resolve(Token t) => _ResolvedListyToken(
        itemPaddingBlock: itemPaddingBlock ?? t.sizeSM,
        itemPaddingInline: itemPaddingInline ?? t.size,
      );
}

@immutable
class _ResolvedListyToken {
  const _ResolvedListyToken({
    required this.itemPaddingBlock,
    required this.itemPaddingInline,
  });

  final double itemPaddingBlock;
  final double itemPaddingInline;
}

/// A long list that groups its rows into sections with sticky headers — the
/// long list.
///
/// ```dart
/// Listy<User, String>(
///   height: 320,
///   items: users,
///   rowKey: (user) => user.id,
///   itemRender: (user, index) => Text(user.name),
///   sticky: true,
///   groupKey: (user) => user.department,
///   groupTitle: (department, items) => Text('$department (${items.length})'),
/// )
/// ```
///
/// The three type parameters are all inferred — the item from [items], the
/// group key from [groupKey], the row key from [rowKey] — so calls read as
/// plain `Listy(...)`.
///
/// Rows are built lazily as they scroll into view, so there is no `virtual`
/// switch to turn on: a Flutter list is already virtualised. Reach for
/// [controller] to jump to an item, a group or an offset. For a short list of
/// reorderable rows use [SortableList] instead.
class Listy<T, G extends Object, R extends Object> extends StatefulWidget {
  /// Creates a [Listy].
  const Listy({
    super.key,
    required this.items,
    required this.itemRender,
    this.rowKey,
    this.groupKey,
    this.groupTitle,
    this.header,
    this.sticky = false,
    this.height,
    this.controller,
    this.scrollController,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.groupHeaderExtent,
    this.loadMore,
    this.onScroll,
    this.styles,
    this.token,
  }) : assert(
          groupTitle == null || groupKey != null,
          'groupTitle needs a groupKey to build a title for.',
        );

  /// The data source.
  final List<T> items;

  /// Builds a single row.
  final Widget Function(T item, int index) itemRender;

  /// Identity of an item, needed by [ListyScrollTo.item].
  ///
  /// Its own type parameter, separate from the group key's: the two are
  /// unrelated in practice — rows keyed by a string id, sections by an enum or
  /// a date — and sharing one would collapse both to `Object` the moment they
  /// differ.
  final R Function(T item)? rowKey;

  /// The section an item belongs to. Null renders one flat list.
  ///
  /// Items sharing a key land in the same section, in the order the keys first
  /// appear.
  final G Function(T item)? groupKey;

  /// Builds a section's header from its key and the items under it.
  /// Null prints the key itself.
  final Widget Function(G groupKey, List<T> items)? groupTitle;

  /// A header above the rows, optionally answering to the pull.
  final ListyHeader? header;

  /// Whether a group header stays pinned while its section scrolls past.
  final bool sticky;

  /// Height of the scroll container. Null lets the list take the height its
  /// parent gives it — set one, or [shrinkWrap], inside an unbounded parent.
  final double? height;

  /// Imperative scroll control.
  final ListyController? controller;

  /// An external [ScrollController] for the list.
  final ScrollController? scrollController;

  /// Scroll physics for the list.
  final ScrollPhysics? physics;

  /// Sizes the list to its content instead of filling its parent. Loses the
  /// benefit of lazy building, so keep it for short lists.
  final bool shrinkWrap;

  /// Padding around the whole list.
  final EdgeInsets? padding;

  /// Fixed height of a sticky group header. Null derives one from the text
  /// metrics, the way The kit derives its row height from the token set.
  final double? groupHeaderExtent;

  /// Fetches more rows as the end approaches, and renders the footer that goes
  /// with it. Null leaves the list finite.
  final ListyLoadMore? loadMore;

  /// Called with the scroll metrics as the list moves. [loadMore] already
  /// covers paging; reach for this to drive something else off the position.
  final ValueChanged<ScrollMetrics>? onScroll;

  /// Overrides for the row, header and root surfaces.
  final ListyStyles? styles;

  /// Per-instance token overrides.
  final ListyToken? token;

  @override
  State<Listy<T, G, R>> createState() => _ListyState<T, G, R>();
}

/// One entry of the flattened list: either a group header or an item.
@immutable
class _Slot<T, K> {
  const _Slot.header(this.groupKey, this.groupItems)
      : item = null,
        itemIndex = -1;

  const _Slot.item(this.item, this.itemIndex)
      : groupKey = null,
        groupItems = null;

  final K? groupKey;
  final List<T>? groupItems;
  final T? item;
  final int itemIndex;

  bool get isHeader => groupItems != null;
}

class _ListyState<T, K extends Object, R extends Object>
    extends State<Listy<T, K, R>> {
  late ScrollController _scroll = widget.scrollController ?? ScrollController();

  /// Contexts of the currently built slots, keyed by their flat index — the
  /// only rows whose real geometry is known.
  final Map<int, GlobalKey> _slotKeys = {};

  /// The flattened running order, rebuilt whenever the data changes.
  List<_Slot<T, K>> _slots = const [];

  /// Group key -> flat index of its header, for [ListyScrollTo.group].
  final Map<Object, int> _groupIndex = {};

  /// Set between asking for the next page and seeing the result, so a run of
  /// scroll frames cannot ask again for the same page.
  bool _loadRequested = false;

  /// The live pull, watched by the header alone so a drag rebuilds the header
  /// and not every row.
  final ValueNotifier<ListyPull> _pull = ValueNotifier(
    const ListyPull(extent: 0, progress: 0, refreshing: false),
  );
  bool _refreshing = false;

  /// The pull as the finger last left it. Judging the release on this rather
  /// than the live extent survives a bouncing list starting to spring back
  /// before the release is seen — and unlike the furthest point reached, it
  /// still lets a drag back under the trigger call the refresh off.
  double _dragPull = 0;

  /// Item key -> flat index, for [ListyScrollTo.item].
  final Map<R, int> _itemIndex = {};

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _scheduleLoadCheck();
  }

  @override
  void didUpdateWidget(Listy<T, K, R> old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (old.scrollController != widget.scrollController) {
      if (old.scrollController == null) _scroll.dispose();
      _scroll = widget.scrollController ?? ScrollController();
    }
    // The page landed (or the caller changed its mind): let the next one
    // through, and check whether the new rows still fall short of the end.
    if (old.items.length != widget.items.length ||
        old.loadMore?.loading != widget.loadMore?.loading ||
        old.loadMore?.hasMore != widget.loadMore?.hasMore) {
      _loadRequested = false;
      _scheduleLoadCheck();
    }
  }

  // --------------------------------------------------------------------------
  // Paging
  // --------------------------------------------------------------------------

  /// Checks after layout, for the case the rows do not fill the viewport —
  /// there would be nothing to scroll, and so nothing to trigger the fetch.
  void _scheduleLoadCheck() {
    if (widget.loadMore == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _maybeLoadMore(_scroll.position);
    });
  }

  void _maybeLoadMore(ScrollMetrics metrics) {
    final config = widget.loadMore;
    if (config == null ||
        _loadRequested ||
        config.loading ||
        !config.hasMore ||
        !metrics.hasContentDimensions) {
      return;
    }
    if (metrics.extentAfter > config.threshold) return;
    _loadRequested = true;
    config.onLoad();
  }

  @override
  void dispose() {
    _pull.dispose();
    widget.controller?._detach(this);
    if (widget.scrollController == null) _scroll.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Flattening
  // --------------------------------------------------------------------------

  /// Rebuilds the running order and the two lookup maps.
  ///
  /// Groups keep the order their keys first appear in [Listy.items], matching
  /// given, so a pre-sorted source lands in the order you sorted it.
  void _flatten() {
    _slots = [];
    _groupIndex.clear();
    _itemIndex.clear();
    final groupOf = widget.groupKey;

    void addItem(T item, int index) {
      final key = widget.rowKey?.call(item);
      if (key != null) _itemIndex[key] = _slots.length;
      _slots.add(_Slot<T, K>.item(item, index));
    }

    if (groupOf == null) {
      for (var i = 0; i < widget.items.length; i++) {
        addItem(widget.items[i], i);
      }
      return;
    }

    final buckets = <K, List<int>>{};
    for (var i = 0; i < widget.items.length; i++) {
      buckets.putIfAbsent(groupOf(widget.items[i]), () => []).add(i);
    }
    for (final entry in buckets.entries) {
      final members = [for (final i in entry.value) widget.items[i]];
      _groupIndex[entry.key] = _slots.length;
      _slots.add(_Slot<T, K>.header(entry.key, members));
      for (final i in entry.value) {
        addItem(widget.items[i], i);
      }
    }
  }

  // --------------------------------------------------------------------------
  // Pull
  // --------------------------------------------------------------------------

  /// Measures how far past the top the list has been dragged.
  ///
  /// Two physics to satisfy: a bouncing list carries its position past
  /// `minScrollExtent`, while a clamping one stays put and reports the excess
  /// as overscroll instead. Both end up as the same number.
  void _trackPull(ScrollNotification notification) {
    if (widget.header == null) return;

    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) {
        _dragPull = 0;
        _setPull(0);
      }
      return;
    }
    if (notification is OverscrollNotification) {
      // A clamping list reports the drag as overscroll instead of moving:
      // negative pulls the top down, positive gives it back.
      final pullingDown =
          notification.overscroll < 0 && notification.metrics.extentBefore == 0;
      if (notification.dragDetails != null &&
          (pullingDown || _pull.value.extent > 0)) {
        _setPull(_pull.value.extent - notification.overscroll, fromDrag: true);
      }
      return;
    }
    if (notification is ScrollUpdateNotification) {
      final beyond =
          notification.metrics.minScrollExtent - notification.metrics.pixels;
      final fromDrag = notification.dragDetails != null;
      if (beyond > 0) {
        _setPull(beyond, fromDrag: fromDrag);
      } else if (_pull.value.extent > 0) {
        _setPull(
          _pull.value.extent - (notification.scrollDelta ?? 0),
          fromDrag: fromDrag,
        );
      }
      // No drag details means the finger is already up and this update is the
      // spring carrying the list home — that moment is the release. Waiting
      // for ScrollEndNotification would sit through the whole bounce first.
      if (notification.dragDetails == null) _releasePull();
      return;
    }
    if (notification is ScrollEndNotification) {
      _releasePull();
    }
  }

  /// [fromDrag] marks the frames the finger itself produced; only those decide
  /// whether the refresh is armed, so the spring-back cannot disarm it and a
  /// drag back under the trigger still can.
  void _setPull(double extent, {bool fromDrag = false}) {
    final header = widget.header;
    if (header == null) return;
    final clamped = extent < 0 ? 0.0 : extent;
    final next = ListyPull(
      extent: clamped,
      progress: (clamped / header.triggerExtent).clamp(0.0, 1.0),
      refreshing: _refreshing,
    );
    if (fromDrag) _dragPull = clamped;
    if (next.extent != _pull.value.extent ||
        next.refreshing != _pull.value.refreshing) {
      _pull.value = next;
    }
  }

  /// Let go: past the trigger, and with somewhere to report it, run the
  /// refresh; either way the pull collapses.
  Future<void> _releasePull() async {
    final header = widget.header;
    final armed = header != null && _dragPull >= header.triggerExtent;
    _dragPull = 0;
    _setPull(0);
    if (header?.onRefresh == null || !armed || _refreshing) return;

    _refreshing = true;
    _setPull(0);
    try {
      await header.onRefresh!();
    } finally {
      _refreshing = false;
      if (mounted) _setPull(0);
    }
  }

  // --------------------------------------------------------------------------
  // Scrolling
  // --------------------------------------------------------------------------

  Future<void> scrollTo(
    ListyScrollTo target, {
    Duration duration = Duration.zero,
    Curve curve = Curves.easeInOut,
  }) async {
    if (!_scroll.hasClients) return;

    if (target.pixels != null) {
      return _moveTo(target.pixels! + target.offset, duration, curve);
    }

    final key = target.itemKey ?? target.groupKey;
    final index =
        target.itemKey != null ? _itemIndex[key] : _groupIndex[key as Object];
    assert(
      index != null,
      'Listy.scrollTo: no ${target.itemKey != null ? 'item' : 'group'} for key '
      '$key. Item targets need a rowKey.',
    );
    if (index == null) return;

    return duration == Duration.zero
        ? _walkAndJump(index, target)
        : _walkAndGlide(index, target, duration, curve);
  }

  /// Hops straight to the target: each jump builds the rows around the
  /// estimate, which sharpens the next estimate, until the target is built.
  Future<void> _walkAndJump(int index, ListyScrollTo target) async {
    for (var attempt = 0; attempt < _maxWalkSteps; attempt++) {
      final exact = _exactOffsetFor(index, target);
      if (exact != null) return _moveTo(exact, Duration.zero, Curves.linear);

      final estimate = _estimateOffset(index);
      if (estimate == null) return;
      _scroll.jumpTo(estimate);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_scroll.hasClients) return;
    }
  }

  /// Scrolls there as one continuous movement.
  ///
  /// Every frame the list re-aims at the best target it can name: the estimate
  /// while the row is still out of reach, its exact offset once it is built.
  /// That offset is only trustworthy from close by — a viewport measured from
  /// far away misjudges what a pinned header covers — so it keeps being
  /// recomputed as the list closes in, and the animation is redirected
  /// whenever the aim moves enough to matter. The position never teleports and
  /// never stops short.
  Future<void> _walkAndGlide(
    int index,
    ListyScrollTo target,
    Duration duration,
    Curve curve,
  ) async {
    final clock = Stopwatch()..start();
    final deadline = duration + _glideSlack;
    var heading = double.nan;

    while (clock.elapsed < deadline) {
      if (!mounted || !_scroll.hasClients) return;

      final exact = _exactOffsetFor(index, target);
      final aim = exact ?? _estimateOffset(index);
      if (aim == null) return;

      // Arrived: the target is built and we are sitting on its real offset.
      if (exact != null && (_scroll.position.pixels - exact).abs() <= 0.5) {
        return;
      }

      if (heading.isNaN || (aim - heading).abs() > _reaimThreshold) {
        heading = aim;
        final left = duration - clock.elapsed;
        unawaited(
          _scroll.animateTo(
            aim,
            duration: left > _minGlide ? left : _minGlide,
            curve: curve,
          ),
        );
      }
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  /// The settled offset for a target that is currently built, or null while it
  /// is still out of reach.
  double? _exactOffsetFor(int index, ListyScrollTo target) {
    final box = _boxFor(index);
    if (box == null) return null;
    final offset = _revealOffset(box, target.align);
    return offset == null ? null : offset + target.offset;
  }

  /// Caps the hunt so it always terminates, however uneven the rows.
  static const int _maxWalkSteps = 24;

  /// Floor on the time left for the final leg, so arriving never snaps.
  static const Duration _minGlide = Duration(milliseconds: 120);

  /// Grace beyond the requested duration for the last corrections to land,
  /// and the backstop that ends the glide whatever happens.
  static const Duration _glideSlack = Duration(seconds: 1);

  /// How far the estimate must move before the animation is re-aimed.
  static const double _reaimThreshold = 8;

  RenderBox? _boxFor(int index) {
    final context = _slotKeys[index]?.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  /// Exact scroll offset that puts [box] against the requested edge.
  double? _revealOffset(RenderBox box, ListyScrollAlign align) {
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return null;
    final position = _scroll.position;
    // A pinned group header is part of the viewport's own leading edge, so
    // `getOffsetToReveal` already parks the row below it — no allowance of our
    // own, or the row would clear the header twice over.
    final top = viewport.getOffsetToReveal(box, 0).offset;
    final bottom = viewport.getOffsetToReveal(box, 1).offset;
    final target = switch (align) {
      ListyScrollAlign.top => top,
      ListyScrollAlign.bottom => bottom,
      // Least movement that reveals it, and no movement when it already is.
      ListyScrollAlign.auto => position.pixels.clamp(
          bottom < top ? bottom : top,
          bottom < top ? top : bottom,
        ),
    };
    return target.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  /// Rough offset of a slot that has not been built, from the average extent of
  /// the ones that have.
  double? _estimateOffset(int index) {
    var total = 0.0;
    var count = 0;
    for (final entry in _slotKeys.entries) {
      final box = _boxFor(entry.key);
      if (box != null) {
        total += box.size.height;
        count++;
      }
    }
    if (count == 0) return null;
    final average = total / count;
    final position = _scroll.position;
    return (index * average).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  Future<void> _moveTo(double offset, Duration duration, Curve curve) {
    final position = _scroll.position;
    final clamped =
        offset.clamp(position.minScrollExtent, position.maxScrollExtent);
    if (duration == Duration.zero) {
      _scroll.jumpTo(clamped);
      return Future<void>.value();
    }
    return _scroll.animateTo(clamped, duration: duration, curve: curve);
  }

  // --------------------------------------------------------------------------
  // Building
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<ListyToken>(context) ??
            const ListyToken())
        ._resolve(t);

    _flatten();
    _slotKeys.removeWhere((index, _) => index >= _slots.length);

    Widget list = _buildScrollView(t, r);

    if (widget.onScroll != null ||
        widget.loadMore != null ||
        widget.header != null) {
      list = NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0) {
            widget.onScroll?.call(notification.metrics);
            _maybeLoadMore(notification.metrics);
            _trackPull(notification);
          }
          return false;
        },
        child: list,
      );
    }

    list = DefaultTextStyle(
      style: TextStyle(
        color: t.colorText,
        fontSize: t.fontSize,
        fontFamily: t.fontFamily,
        fontFamilyFallback: t.fontFamilyFallback,
        height: t.lineHeight,
        leadingDistribution: TextLeadingDistribution.even,
        decoration: TextDecoration.none,
      ),
      child: list,
    );

    final root = widget.styles?.root;
    if (root != null) list = DecoratedBox(decoration: root, child: list);

    return widget.height == null
        ? list
        : SizedBox(height: widget.height, child: list);
  }

  /// A short list still has to be draggable, or there would be no pull to
  /// answer to.
  ScrollPhysics? get _physics =>
      widget.physics ??
      (widget.header?.onRefresh == null
          ? null
          : const AlwaysScrollableScrollPhysics());

  /// The header, rebuilt on its own as the pull changes.
  Widget _headerWidget() => ValueListenableBuilder<ListyPull>(
        valueListenable: _pull,
        builder: (context, pull, _) => widget.header!.builder(context, pull),
      );

  Widget _buildScrollView(Token t, _ResolvedListyToken r) {
    // Sticky headers need one sliver group per section; everything else is a
    // single lazy list over the flattened order.
    if (widget.header == null && (widget.groupKey == null || !widget.sticky)) {
      final footer = _footer(t, r);
      return ListView.builder(
        controller: _scroll,
        physics: _physics,
        shrinkWrap: widget.shrinkWrap,
        padding: widget.padding ?? EdgeInsets.zero,
        itemCount: _slots.length + (footer == null ? 0 : 1),
        itemBuilder: (context, index) =>
            index == _slots.length ? footer! : _buildSlot(t, r, index),
      );
    }

    final sections = <Widget>[];

    // Without sticky sections the body is one lazy list; with them, a sliver
    // group per section so each header can pin itself.
    if (widget.groupKey == null || !widget.sticky) {
      sections.add(
        SliverList.builder(
          itemCount: _slots.length,
          itemBuilder: (context, index) => _buildSlot(t, r, index),
        ),
      );
      return _assemble(t, r, sections);
    }

    final headerExtent = widget.groupHeaderExtent ??
        (t.fontSize * t.lineHeight + t.sizeXS * 2).roundToDouble();

    var index = 0;
    while (index < _slots.length) {
      final headerIndex = index;
      index++;
      final first = index;
      while (index < _slots.length && !_slots[index].isHeader) {
        index++;
      }
      final count = index - first;
      sections.add(
        SliverMainAxisGroup(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _GroupHeaderDelegate(
                extent: headerExtent,
                child: KeyedSubtree(
                  key: _keyFor(headerIndex),
                  child: _groupHeader(t, r, _slots[headerIndex]),
                ),
              ),
            ),
            SliverList.builder(
              itemCount: count,
              itemBuilder: (context, i) => _buildSlot(t, r, first + i),
            ),
          ],
        ),
      );
    }

    return _assemble(t, r, sections);
  }

  /// Wraps the body slivers with the header, the paging footer and the outer
  /// padding, in that order.
  Widget _assemble(Token t, _ResolvedListyToken r, List<Widget> sections) {
    final footer = _footer(t, r);
    final header = widget.header;

    final slivers = <Widget>[
      if (header != null)
        if (header.pinned)
          SliverPersistentHeader(
            pinned: true,
            delegate: _GroupHeaderDelegate(
              extent: header.extent!,
              child: _headerWidget(),
            ),
          )
        else
          SliverToBoxAdapter(child: _headerWidget()),
      ...sections,
      if (footer != null) SliverToBoxAdapter(child: footer),
    ];

    return CustomScrollView(
      controller: _scroll,
      physics: _physics,
      shrinkWrap: widget.shrinkWrap,
      slivers: [
        if (widget.padding != null)
          SliverPadding(
            padding: widget.padding!,
            sliver: SliverMainAxisGroup(slivers: slivers),
          )
        else
          ...slivers,
      ],
    );
  }

  /// The footer under the last row: a spinner while a page is in flight, the
  /// end marker once there is nothing left, and nothing at all in between.
  Widget? _footer(Token t, _ResolvedListyToken r) {
    final config = widget.loadMore;
    if (config == null) return null;

    // A supplied footer is rendered exactly as given — no padding or centring
    // of ours to fight. Only the built-in ones get the house treatment.
    if (config.loading) {
      return config.indicator ??
          _defaultFooter(
            r,
            Spinner(size: t.fontSizeLG, color: t.colorTextTertiary),
          );
    }
    if (!config.hasMore) {
      return config.endIndicator ??
          _defaultFooter(
            r,
            DefaultTextStyle(
              style: TextStyle(
                color: t.colorTextTertiary,
                fontSize: t.fontSizeSM,
                fontFamily: t.fontFamily,
                fontFamilyFallback: t.fontFamilyFallback,
                decoration: TextDecoration.none,
              ),
              child: Text(context.seedLocale.noMoreItems),
            ),
          );
    }
    return null;
  }

  Widget _defaultFooter(_ResolvedListyToken r, Widget child) => Padding(
        padding: EdgeInsets.symmetric(
          vertical: r.itemPaddingBlock,
          horizontal: r.itemPaddingInline,
        ),
        child: Center(child: child),
      );

  GlobalKey _keyFor(int index) => _slotKeys.putIfAbsent(index, GlobalKey.new);

  Widget _buildSlot(Token t, _ResolvedListyToken r, int index) {
    final slot = _slots[index];
    final styles = widget.styles;

    // Default chrome: a hairline under each row, a tint under the pointer.
    // A supplied `item` replaces it outright, and `itemHovered` falls back to
    // that same look with the tint laid over it.
    final decoration = styles?.item ??
        BoxDecoration(
          border: Border(
            bottom: BorderSide(color: t.colorSplit, width: t.lineWidth),
          ),
        );
    final hovered =
        styles?.itemHovered ?? decoration.copyWith(color: t.colorFillTertiary);

    final child = slot.isHeader
        ? _groupHeader(t, r, slot)
        : _ListyItem(
            token: t,
            padding: styles?.itemPadding ??
                EdgeInsets.symmetric(
                  vertical: r.itemPaddingBlock,
                  horizontal: r.itemPaddingInline,
                ),
            decoration: decoration,
            hoveredDecoration: hovered,
            child: widget.itemRender(slot.item as T, slot.itemIndex),
          );
    return KeyedSubtree(key: _keyFor(index), child: child);
  }

  Widget _groupHeader(Token t, _ResolvedListyToken r, _Slot<T, K> slot) {
    return Container(
      width: double.infinity,
      alignment: AlignmentDirectional.centerStart,
      padding: widget.styles?.groupHeaderPadding ??
          EdgeInsets.symmetric(
            vertical: t.sizeXS,
            horizontal: r.itemPaddingInline,
          ),
      // A tint over an opaque base, as the kit layers colorFillAlter on
      // colorBgContainer — a pinned header must never let the rows scrolling
      // beneath it show through.
      decoration: widget.styles?.groupHeader ??
          BoxDecoration(
            color: Color.alphaBlend(t.colorFillQuaternary, t.colorBgContainer),
          ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: t.colorTextTertiary,
          fontSize: t.fontSize,
          fontFamily: t.fontFamily,
          fontFamilyFallback: t.fontFamilyFallback,
          fontWeight: FontWeight.w600,
          height: t.lineHeight,
          leadingDistribution: TextLeadingDistribution.even,
          decoration: TextDecoration.none,
        ),
        child: widget.groupTitle?.call(slot.groupKey as K, slot.groupItems!) ??
            Text('${slot.groupKey}'),
      ),
    );
  }
}

/// A row: padding, a hairline below it, and a hover tint — any of which
/// [ListyStyles] can replace.
class _ListyItem extends StatefulWidget {
  const _ListyItem({
    required this.token,
    required this.padding,
    required this.decoration,
    required this.hoveredDecoration,
    required this.child,
  });

  final Token token;
  final EdgeInsets padding;
  final BoxDecoration decoration;
  final BoxDecoration hoveredDecoration;
  final Widget child;

  @override
  State<_ListyItem> createState() => _ListyItemState();
}

class _ListyItemState extends State<_ListyItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: t.motionDurationMid,
        curve: t.motionEaseInOut,
        padding: widget.padding,
        decoration: _hovered ? widget.hoveredDecoration : widget.decoration,
        child: widget.child,
      ),
    );
  }
}

class _GroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _GroupHeaderDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      SizedBox(height: extent, child: child);

  @override
  bool shouldRebuild(_GroupHeaderDelegate old) =>
      old.extent != extent || old.child != child;
}
