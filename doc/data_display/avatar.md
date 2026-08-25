# Avatar

Avatars can be used to represent people or objects. It supports images, Icons, or letters.

```dart
Avatar(
  icon: const Icon(Icons.person),
  size: SoftSize.large,
  shape: AvatarShape.circle,
)
```

### Avatar Properties
- `size`: A `ControlSize` — either a preset (`SoftSize.small`, `middle`,
  `large`) or a diameter of your own (`ControlSize.fixed(64)`). One slot for
  both: a diameter is the whole story for a circle, so there is nothing a
  preset carries that a number leaves unsaid. Follows `AvatarDefaults.size`,
  then `ConfigProvider.componentSize`, else `middle`.
- `shape`: `AvatarShape.circle` or `AvatarShape.square`.
- `image`: An `ImageProvider` to display an image avatar.
- `icon`: A `Widget` (typically an `Icon`) to display an icon avatar.
- `child`: A `Widget` (typically a `Text`) to display a text avatar.
- `backgroundColor`: Custom background color.
- `foregroundColor`: Custom text or icon color.
- `gap`: The minimum gap between text and the avatar's edges (default is `4`).
- `errorBuilder`: A custom widget builder that is displayed if the image fails to load.

## Content Types

An Avatar can render different types of content:
- **Image**: Provide an `ImageProvider` to `image`.
- **Icon**: Pass a widget like `Icon(Icons.person)` to `icon`.
- **String/Text**: Pass a `Text('U')` to `child`. The text scales automatically to fit within the avatar.

## AvatarGroup

To display a list of avatars, use the `AvatarGroup` component. It applies a stacking overlapping effect, and limits the number of visible avatars by folding the rest into a `+N` avatar.

```dart
AvatarGroup(
  maxCount: 2,
  maxPopoverPlacement: PopoverPlacement.bottom,
  children: [
    Avatar(child: Text('A')),
    Avatar(child: Text('B')),
    Avatar(child: Text('C')), // Hidden inside +1 popover
  ],
)
```

### AvatarGroup Popover
When the number of avatars exceeds `maxCount`, a `+N` avatar appears. Hovering over it reveals the hidden avatars in a Dropdown popover (enabled by default).

You can configure the popover using:
- `showPopover`: Controls whether the popover appears at all.
- `maxPopoverPlacement`: Where the popover anchors relative to the `+N` avatar.
- `maxPopoverTrigger`: Which gestures open the popover (e.g., `DropdownTrigger.hover`, `DropdownTrigger.click`).
- `maxPopoverArrow`: Whether to draw an arrow pointing to the `+N` avatar.
- `maxPopoverToken`: Token overrides specific to the dropdown popover.
- `popupRender`: A custom widget builder that receives the default popup content (the group of hidden avatars) and lets you wrap or modify it.
- `maxStyle`: A custom builder for the `+N` avatar widget itself.

## Handling Image Errors

If an `Avatar`'s `image` fails to load, it will automatically fallback to rendering the `icon` or `child` if provided, or a generic placeholder. You can provide a custom `errorBuilder` to render a specific fallback widget on error.

```dart
Avatar(
  image: NetworkImage('https://invalid.url'),
  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
)
```

## Other properties

- `gradient` — a background gradient replacing the flat `backgroundColor`.
- `border` — an outline around the avatar; `AvatarGroup` injects one to
  separate overlapping avatars.

## Design tokens

`AvatarToken` overrides this component's own tokens. Every field is an override; an
unset one falls back to the value derived from the global theme.

```dart
Avatar(
  // …
  token: const AvatarToken(),
);

// …or for every Avatar in a subtree:
ConfigProvider(
  components: const [AvatarToken()],
  child: MaterialApp(...),
);
```

A per-instance `token` wins over the `ConfigProvider` one.
