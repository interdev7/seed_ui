# Pagination

A pager for splitting a long list across pages.
Prev/next arrows, numbered page buttons with ellipsis gaps, and optional
size-changer, quick-jumper and total summary.

```dart
Pagination(
  current: _page,
  total: 235,
  pageSize: 10,
  onChanged: (page, size) => setState(() => _page = page),
)
```

## Controlled or not

- **Controlled** — pass `current` (and/or `pageSize`) and update from
  `onChanged`.
- **Uncontrolled** — omit them, optionally seed with `defaultCurrent` /
  `defaultPageSize`, and read `onChanged`.

`onChanged` is called with `(page, pageSize)` whenever either changes.

## Page numbers

The pager shows the first and last page always, a window around the current
page, and an ellipsis (`•••`) for the gaps. Hovering an ellipsis turns it into
a double-chevron that jumps five pages. `showLessItems` narrows the window.

## Extras

| Property | Description |
| --- | --- |
| `showSizeChanger` | A [Select](../data_entry/select.md) for the page size (`pageSizeOptions`, default 10/20/50/100) |
| `showQuickJumper` | An input to jump straight to a page |
| `showTotal` | `(total, from, to) => Widget` summary, e.g. "1-10 of 235 items" |
| `simple` | Compact mode: pass a `PaginationSimple()` (with `readOnly` to show the page as text) |
| `size` | `middle` (default) or `small` |
| `disabled` | Greys the whole pager out |
| `hideOnSinglePage` | Render nothing when there is only one page |
| `align` | `MainAxisAlignment` of the row |

```dart
Pagination(
  total: 500,
  showSizeChanger: true,
  showQuickJumper: true,
  showTotal: (total, from, to) => Text('$from-$to of $total'),
)
```

## Testing

The size-changer's dropdown renders into the root navigator's overlay, so a
test app that opens it must install `UiKit.navigatorKey`. See
[testing](../../README.md#testing-against-the-kit).

## Page size changes

`onShowSizeChange` fires with the new `(page, pageSize)` pair whenever the size
selector changes, alongside `pageSizeOptions` which lists the offered sizes.

## From the keyboard

The whole pager is **one stop** in the tab order, not one per page: a run
of fourteen that took fourteen presses to walk past is a run nobody walks past.
Inside it the arrow keys do the moving, `Home` and `End` reach the ends, and a
page that cannot be chosen is stepped over.

Which arrow steps which way follows the run and the reading direction: down a
column it is Up and Down, and along a row that reads right to left the key
pointing left steps *on*, since that is where the next one is. The run stops at
its ends rather than wrapping round, so a held arrow does not cycle for ever.

A halo appears round the pager when the focus arrived by keyboard, and not
when it arrived by a tap. `focusNode` drives the focus yourself; `autofocus`
puts it there as soon as the run is built.

The arrows and the page numbers are the run; the size changer and the jumper
keep stops of their own, being places you type into rather than a run to step
along.

## Design tokens

`PaginationToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
Pagination(
  // …
  token: const PaginationToken(),
);

// …or for every Pagination in a subtree:
ConfigProvider(
  components: const [PaginationToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
