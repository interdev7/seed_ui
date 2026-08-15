# Pagination

A pager for splitting a long list across pages.
Prev/next arrows, numbered page buttons with ellipsis gaps, and optional
size-changer, quick-jumper and total summary.

```dart
Pagination(
  current: _page,
  total: 235,
  pageSize: 10,
  onChange: (page, size) => setState(() => _page = page),
)
```

## Controlled or not

- **Controlled** — pass `current` (and/or `pageSize`) and update from
  `onChange`.
- **Uncontrolled** — omit them, optionally seed with `defaultCurrent` /
  `defaultPageSize`, and read `onChange`.

`onChange` is called with `(page, pageSize)` whenever either changes.

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
