# Listy

A long list that groups its rows into sections with sticky headers.
Rows are built lazily as they scroll into view, and the scroll
position can be driven from outside.

```dart
Listy(
  height: 320,
  items: users,
  rowKey: (user) => user.id,
  itemRender: (user, index) => Text(user.name),
)
```

All three type arguments are inferred: the item from `items`, the row key from
`rowKey`, the group key from `groupKey`. Write `Listy(...)` and the closures
come out typed — `rowKey: (user) => user.id` is a `String Function(User)`, not
`Object Function(User)`.

The two keys carry their own type parameters on purpose. They are unrelated in
practice — rows keyed by a string id, sections by an enum or a date — and one
shared parameter would collapse both to `Object` the moment they differ, taking
the typing of `groupTitle`'s key with it.

Reach for it when a list is long enough that mounting every row would cost, or
when it needs grouped sections. For a short list of drag-to-reorder rows use
[SortableList](sortable_list.md).

## Anatomy

| Property            | Type                                     | Default  | Description                                        |
| ------------------- | ---------------------------------------- | -------- | -------------------------------------------------- |
| `items`             | `List<T>`                                | required | The data source                                    |
| `itemRender`        | `Widget Function(T item, int index)`     | required | Builds a single row                                |
| `rowKey`            | `R Function(T item)?`                    | `null`   | Item identity, needed by `ListyScrollTo.item`      |
| `groupKey`          | `K Function(T item)?`                    | `null`   | The section an item belongs to                     |
| `groupTitle`        | `Widget Function(K key, List<T> items)?` | `null`   | Builds a section header; null prints the key       |
| `header`            | `ListyHeader?`                           | `null`   | Header above the rows, optionally pull-aware       |
| `sticky`            | `bool`                                   | `false`  | Pins a group header while its section scrolls past |
| `height`            | `double?`                                | `null`   | Height of the scroll container                     |
| `controller`        | `ListyController?`                       | `null`   | Imperative scroll control                          |
| `scrollController`  | `ScrollController?`                      | `null`   | An external scroll controller                      |
| `physics`           | `ScrollPhysics?`                         | `null`   | Scroll physics                                     |
| `shrinkWrap`        | `bool`                                   | `false`  | Size to content instead of filling the parent      |
| `padding`           | `EdgeInsets?`                            | `null`   | Padding around the whole list                      |
| `groupHeaderExtent` | `double?`                                | `null`   | Fixed height of a sticky header                    |
| `loadMore`          | `ListyLoadMore?`                         | `null`   | Fetches more rows as the end approaches            |
| `onScroll`          | `ValueChanged<ScrollMetrics>?`           | `null`   | Fires as the list moves                            |
| `styles`            | `ListyStyles?`                           | `null`   | Overrides the row, header and root surfaces        |
| `token`             | `ListyToken?`                            | `null`   | Per-instance token overrides                       |

## No `virtual` switch

Web list components typically take a `virtual` flag (plus an `itemHeight`) to
render only the rows in view. Flutter's lists already do that: `Listy` builds on
`ListView.builder` / `SliverList.builder`, so rows are created as they approach
the viewport and disposed as they leave it, at any row height. There is nothing
to turn on — and no fixed row height to declare.

Give the list a bounded height for that to pay off: either `height`, or a parent
that constrains it. `shrinkWrap: true` sizes the list to its content and builds
every row, so keep it for short lists.

## Grouping

`groupKey` maps each item to a section; `groupTitle` renders that section's
header. Sections come out in the order their keys first appear in `items`, so a
pre-sorted source lands in the order you sorted it.

```dart
Listy(
  height: 320,
  sticky: true,
  items: users,
  rowKey: (user) => user.id,
  groupKey: (user) => user.department,
  groupTitle: (department, items) => Text('$department · ${items.length}'),
  itemRender: (user, index) => Text(user.name),
)
```

The two are separate parameters rather than one config object on purpose:
nesting a generic object inside the call defeats Dart's type inference, and you
would be back to spelling out `Listy<User, Department, String>`. `groupTitle` is optional —
without it the key itself is printed.

`sticky: true` pins each header until the next section pushes it away. A pinned
header needs a fixed height, derived from the text metrics unless you set
`groupHeaderExtent`.

## Header and pull to refresh

`header` puts a widget above the rows and hands it the live pull, so it can be
a static bar, a refresh indicator, or something that morphs with the drag. The
header sets its own height — grow it with `pull.extent` and it follows the
finger.

```dart
Listy(
  items: _feed,
  rowKey: (item) => item.id,
  header: ListyHeader(
    triggerExtent: 72,
    onRefresh: _reload,
    builder: (context, pull) {
      if (pull.refreshing) return const _RefreshingBar();
      if (pull.extent == 0) return const _IdleBar();
      return SizedBox(
        height: pull.extent,
        child: Center(
          child: Text(pull.armed ? 'Release to refresh' : 'Keep pulling'),
        ),
      );
    },
  ),
  itemRender: (item, index) => Text(item.title),
)
```

| Property        | Type                                       | Default  | Description                                     |
| --------------- | ------------------------------------------ | -------- | ----------------------------------------------- |
| `builder`       | `Widget Function(BuildContext, ListyPull)` | required | Builds the header                               |
| `onRefresh`     | `Future<void> Function()?`                 | `null`   | Runs when released past the trigger             |
| `triggerExtent` | `double`                                   | `72`     | How far to pull before the refresh arms         |
| `pinned`        | `bool`                                     | `false`  | Header stays put while the rows scroll under it |
| `extent`        | `double?`                                  | `null`   | Fixed height, required when `pinned`            |

`ListyPull` carries `extent` (pixels dragged past the top), `progress`
(`extent / triggerExtent`, clamped to 0..1), `armed` (`progress == 1` — letting
go now refreshes) and `refreshing` (the callback is still running).

`onRefresh` runs the moment the finger lifts, not when the list finishes
springing back — the loading state shows up right away rather than a beat later.
Whether it fires is judged on where the _drag_ left the pull, so a bouncing list
already snapping home does not disarm it, and dragging back under the trigger
before letting go calls it off.

Both physics are handled: a bouncing list carries its position past the top, a
clamping one reports the excess as overscroll, and either way the header sees
the same number. With `onRefresh` set the list stays draggable even when the
rows do not fill it, so a short list can still be pulled.

## Scroll control

`ListyController` jumps to an offset, an item, or a group header. It holds no
resources, so there is nothing to dispose.

```dart
final listy = ListyController();

Button(
  onPressed: () => listy.scrollTo(
    const ListyScrollTo.item('user-42'),
    duration: const Duration(milliseconds: 300),
  ),
  child: const Text('Find user 42'),
);

Listy(controller: listy, /* … */);
```

| Target                                      | Meaning                         |
| ------------------------------------------- | ------------------------------- |
| `ListyScrollTo.offset(pixels)`              | An absolute pixel offset        |
| `ListyScrollTo.item(key, align:, offset:)`  | The item whose `rowKey` matches |
| `ListyScrollTo.group(key, align:, offset:)` | A group header                  |

`align` is a `ListyScrollAlign`: `top`, `bottom`, or `auto` (the default — the
least scrolling that reveals the target, and none if it already is visible).
Reach for `top` when the target should park at the top of the viewport rather
than merely come into view. `offset` adds pixels after alignment; a negative one
leaves room above.

With `sticky: true`, `top` parks the row flush under the pinned group header
rather than beneath it: a pinned header counts as part of the viewport's leading
edge, so the row's own box starts exactly where the header's ends. A group
target is that header itself, and goes to the very top.

A target far down the list has never been built, so its position is not known.
The controller finds it by estimating from the rows it _has_ measured, letting
that region build, and refining — until the target itself is on screen, then
settling on its exact offset. Rows of wildly uneven height take a few more
rounds; the hunt is capped so it always terminates.

`duration` decides how that reads on screen:

- **`Duration.zero`** (the default) hops straight there — the fastest way to
  reach a distant row.
- **Anything longer** makes it one continuous scroll. The list re-aims every
  frame — at the estimate while the row is out of reach, at its exact offset
  once it is built and close enough to measure honestly — and redirects the
  animation whenever the aim moves. The position never teleports, and it lands
  on the same offset a jump would.

```dart
listy.scrollTo(
  const ListyScrollTo.group('Support', align: ListyScrollAlign.top),
  duration: const Duration(milliseconds: 450),
);
```

Item targets need `rowKey`; without one there is nothing to match against, and
the call asserts in debug mode.

## Infinite loading

`loadMore` declares the paging rule instead of wiring it up by hand: how close
to the end counts as "near", whether a fetch is in flight, and whether anything
is left.

```dart
Listy(
  height: 280,
  items: _posts,
  rowKey: (post) => post.id,
  loadMore: ListyLoadMore(
    onLoad: _fetchNextPage,
    loading: _fetching,
    hasMore: _posts.length < _total,
    threshold: 120,
  ),
  itemRender: (post, index) => Text(post.title),
)
```

| Property       | Type           | Default  | Description                                               |
| -------------- | -------------- | -------- | --------------------------------------------------------- |
| `onLoad`       | `VoidCallback` | required | Fetches the next page                                     |
| `loading`      | `bool`         | `false`  | A fetch is in flight                                      |
| `hasMore`      | `bool`         | `true`   | Something is left to fetch                                |
| `threshold`    | `double`       | `200`    | How close to the end, in pixels, triggers the fetch       |
| `indicator`    | `Widget?`      | `null`   | Footer while loading; null shows a centred spinner        |
| `endIndicator` | `Widget?`      | `null`   | Footer once exhausted; null shows a muted "No more items" |

`onLoad` fires **once** per page: not again until `loading` returns to false or
new items arrive, so a slow request is never asked for twice and you need no
re-entry guard of your own. It stops entirely once `hasMore` is false.

It also fires when the rows do not fill the viewport — a first page shorter than
the list leaves nothing to scroll, and so would never trigger anything.

`threshold` is the whole tuning knob: `0` waits for the very last pixel, a
viewport-sized value keeps a screen of rows ahead of the user.

The footer under the last row follows the same state — a spinner while loading,
the end marker once exhausted, nothing in between. Both are replaceable, and a
supplied footer is rendered exactly as given: it owns its padding, background
and alignment, with nothing of the list's wrapped around it.

```dart
ListyLoadMore(
  onLoad: _fetchNextPage,
  loading: _fetching,
  hasMore: _hasMore,
  indicator: Container(
    padding: const EdgeInsets.all(12),
    color: token.primary.bg,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Spinner(size: 14, color: token.primary.base),
        const SizedBox(width: 8),
        const Text('Fetching the next page…'),
      ],
    ),
  ),
  endIndicator: const Center(
    child: Padding(
      padding: EdgeInsets.all(12),
      child: Text('That is everything'),
    ),
  ),
)
```

For anything else driven by scroll position, `onScroll` still reports the raw
`ScrollMetrics`.

## Restyling the surfaces

`styles` replaces the chrome the list draws around your content — the
semantic `styles` (`root`, `item`, `groupHeader`), as Flutter decorations.

| Property | Type | Description |
| --- | --- | --- |
| `root` | `BoxDecoration?` | Behind the whole list |
| `item` | `BoxDecoration?` | A row at rest; replaces the default hairline outright |
| `itemHovered` | `BoxDecoration?` | A row under the pointer; null tints `item` |
| `groupHeader` | `BoxDecoration?` | A section header |
| `itemPadding` | `EdgeInsets?` | Row padding, overriding the tokens |
| `groupHeaderPadding` | `EdgeInsets?` | Section header padding |

Dropping the dividers is an empty decoration — `item` is a replacement, not a
merge:

```dart
styles: const ListyStyles(item: BoxDecoration()),
```

Rows as cards:

```dart
styles: ListyStyles(
  root: BoxDecoration(color: token.colorBgLayout),
  item: BoxDecoration(
    color: token.colorBgContainer,
    borderRadius: BorderRadius.circular(token.borderRadiusLG),
    border: Border.all(color: token.colorBorderSecondary),
  ),
  itemHovered: BoxDecoration(
    color: token.colorBgContainer,
    borderRadius: BorderRadius.circular(token.borderRadiusLG),
    border: Border.all(color: token.primary.border),
    boxShadow: token.boxShadowSecondary,
  ),
  itemPadding: const EdgeInsets.all(12),
  groupHeader: BoxDecoration(color: token.colorBgLayout),
)
```

Leave `itemHovered` unset and hover feedback survives a custom row look: the
list tints whatever `item` you gave with `colorFillTertiary`.

Two things `styles` deliberately does not do. It is one look for **all** rows —
striping, a selected row or any per-row difference belongs in `itemRender`,
which owns the row's content. And a `groupHeader` under `sticky: true` must stay
opaque, or the rows scrolling beneath will show through it.

## Design tokens

`ListyToken` carries the list token table: `itemPaddingBlock` and
`itemPaddingInline`, the vertical and horizontal padding of a row. Every field
is an override; an unset one falls back to the global theme (`sizeSM` and
`size`).

Row hairlines use `colorSplit`, the hover tint `colorFillTertiary` and group
headers a `colorFillQuaternary` wash over `colorBgContainer`, so they follow the
theme without extra configuration.

```dart
Listy(
  // …
  token: const ListyToken(itemPaddingBlock: 16, itemPaddingInline: 20),
);

// …or for every Listy in a subtree:
ConfigProvider(
  components: const [ListyToken(itemPaddingBlock: 16)],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one — handy for a single
denser list inside an app that sets its own defaults.

## Putting it together

Row spacing comes from the tokens, the toolbar from a pinned `header`, and the
section headings from `groupTitle` — they compose freely:

```dart
ConfigProvider(
  components: [ListyToken(itemPaddingBlock: density, itemPaddingInline: 16)],
  child: Listy(
    height: 320,
    sticky: true,
    items: contacts,
    rowKey: (c) => c.id,
    header: ListyHeader(
      pinned: true,
      extent: 44,
      builder: (context, pull) => const _Toolbar(),
    ),
    groupHeaderExtent: 40,
    groupKey: (c) => c.role,
    groupTitle: (role, items) => Row(
      children: [
        Icon(iconFor(role), size: 14),
        const SizedBox(width: 8),
        Expanded(child: Text(role.toUpperCase())),
        Text('${items.length}'),
      ],
    ),
    itemRender: (c, index) => ContactRow(c),
  ),
)
```

A pinned header and sticky sections stack: the toolbar holds the top, and each
section header pins right under it as its rows scroll past.
