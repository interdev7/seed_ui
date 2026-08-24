# Tag

A small label for categorising or marking content.

```dart
Tag(color: TagColor.success, child: const Text('Done'))
```

## Colour × variant

A tag's look is a **colour** crossed with a **variant**.

Use a `TagColor` preset — `defaultColor`, `primary`, `success`, `processing`,
`warning`, `error` — or name any colour in the same slot, `TagColor(...)` or
`TagColor.fromString('#722ed1')` (expanded into a palette, like
the named preset colours).

`TagVariant` chooses the fill:

| `TagVariant` | Look |
| --- | --- |
| `outlined` (default) | Transparent fill with a coloured outline |
| `filled` | Tinted fill, no border |
| `solid` | Solid colour fill with white text |

```dart
Tag(color: TagColor.error, child: const Text('error'))
Tag(color: const TagColor(Color(0xFF722ED1)), variant: TagVariant.filled, child: const Text('purple'))
Tag(color: TagColor.fromString('#fa541c'), variant: TagVariant.solid, child: const Text('solid'))
Tag(gradient: LinearGradient(colors: [Color(0xFF87D068), Color(0xFF108EE9)]), child: const Text('gradient'))
```

Every variant is the same height (a transparent border reserves the outline's
space), so tags line up whether or not they carry a border.

## Icon

`icon` adds a leading glyph.

```dart
Tag(color: TagColor.success, icon: const Icon(Icons.check_circle), child: const Text('Done'))
```

## Closable

`closable: true` shows a close button; handle removal in `onClose`. Replace the
glyph with `closeIcon`.

```dart
Tag(closable: true, onClose: () => remove(tag), child: Text(tag))
```

## CheckableTag

A toggleable tag, useful as a filter chip.
It has no colours of its own: unchecked is a faint fill, checked is the primary
colour.

```dart
CheckableTag(
  checked: _on,
  onChanged: (v) => setState(() => _on = v),
  child: const Text('Movies'),
)
```

A null `onChanged` disables the tag. Unchecked tags carry no resting fill (only
a faint one on hover), like a text button; checked is the primary colour.

## CheckableTagGroup

Manage a set of checkable tags together with `CheckableTagGroup`:

```dart
CheckableTagGroup<String>(
  multiple: true,
  value: _picked,
  options: const [
    CheckableTagOption(value: 'movies', label: Text('Movies')),
    CheckableTagOption(value: 'books', label: Text('Books')),
  ],
  onChanged: (v) => setState(() => _picked = v),
)
```

| Property | Description |
| --- | --- |
| `options` | The `CheckableTagOption`s: `value`, `label`, `disabled` |
| `value` / `defaultValue` | Checked values — controlled / uncontrolled |
| `onChanged` | Called with the full new selection |
| `multiple` | Allow several checked at once (default false — checking one unchecks the rest) |
| `disabled` | Grey the whole group out |

The value is a `List<T>` in every mode; single-select simply holds at most one.

## Design tokens

`TagToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
Tag(
  // …
  token: const TagToken(),
);

// …or for every Tag in a subtree:
ConfigProvider(
  components: const [TagToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
