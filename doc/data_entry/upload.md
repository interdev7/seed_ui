# Upload

A file list with a picker trigger, per-file progress, and retry and remove
actions.

**The kit does not pick or send files.** Opening a file dialog needs platform
code — Kotlin, Swift, C++ — and posting bytes is your app's concern. `Upload`
draws the state and calls back, which keeps `seed_ui` free of plugin
dependencies and leaves you free to pick with whatever you already use.

```dart
Upload<PlatformFile>(
  items: _items,
  onPick: _pick,
  onRemove: (item) => setState(() => _items = [..._items]..remove(item)),
  onRetry: _send,
)
```

## Picking

`onPick` runs when the trigger is used. Open your picker there and add what it
returns to `items`. The list is yours: rebuild it with new `progress` and
`status` as the upload runs, and the rows follow.

```dart
Future<void> _pick() async {
  final picked = await FilePicker.pickFiles();
  final added = <UploadItem<PlatformFile>>[
    for (final f in picked)
      UploadItem(name: f.name, size: await f.length(), data: f),
  ];
  setState(() => _items = [..._items, ...added]);
  for (final item in added) {
    unawaited(_send(item));
  }
}
```

`file_picker` is one option; `image_picker`, a camera, a URL field or a paste
handler work just as well. None of them belong to the kit.

Leaving `onPick` null hides the trigger, which turns `Upload` into a read-only
list of attachments.

## Reporting progress

Rebuild the item as the upload moves. `copyWith` keeps everything you do not
name:

```dart
Future<void> _send(UploadItem<PlatformFile> item) async {
  _replace(item, item.copyWith(status: UploadStatus.uploading, progress: 0));
  // …then again on every chunk, and once more on the outcome:
  _replace(current, current.copyWith(status: UploadStatus.done, progress: 1));
}
```

| `UploadStatus` | What is drawn |
| --- | --- |
| `pending` | The name and size alone |
| `uploading` | A progress bar under the name |
| `done` | A green tick at the end of the row |
| `error` | The name in red, `error` beneath it, and a retry button |

`error` is a widget, so it can carry a link to a help page rather than a bare
sentence.

## Drag and drop

The dashed target is drawn here, but the operating system's drag events are
not Flutter's to give — there is no `DropTarget` in the SDK. Wire them with
whichever package you prefer and pass the result through `dragging`:

```dart
DropTarget(
  onDragEntered: (_) => setState(() => _dragging = true),
  onDragExited: (_) => setState(() => _dragging = false),
  onDragDone: (detail) => _add(detail.files),
  child: Upload(items: _items, dragging: _dragging, onPick: _pick),
)
```

While `dragging` is true the zone takes the primary accent and a tinted fill,
so the target reads as live before anything is dropped.

## Variants

`UploadVariant.list` is a column of rows. `UploadVariant.cards` is a grid of
square tiles with the trigger as the last one, which suits images:

```dart
Upload<String>(
  items: _images,
  variant: UploadVariant.cards,
  maxCount: 5,
  onPick: _pick,
  onRemove: _remove,
)
```

Tiles show the preview alone — a file name would not fit — and their actions
surface on hover, so a wall of pictures stays readable as pictures.

## Previews

Without one, a file gets a tinted square carrying its extension: `PDF`, `PNG`,
`?` for a name that has none. Supply your own per file through
`UploadItem.thumbnail`, or for all of them at once through `thumbnailBuilder`;
the per-file one wins.

```dart
Upload<XFile>(
  items: _items,
  thumbnailBuilder: (item) => Image.file(File(item.data!.path), fit: BoxFit.cover),
)
```

## Properties

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<UploadItem<T>>` | `[]` | The files to draw, in order |
| `variant` | `UploadVariant` | `list` | Rows or tiles |
| `onPick` | `Future<void> Function()?` | `null` | Runs on the trigger; null hides it |
| `onRemove` | `void Function(UploadItem<T>)?` | `null` | Null hides the remove button |
| `onRetry` | `void Function(UploadItem<T>)?` | `null` | Offered only to failed files |
| `onTap` | `void Function(UploadItem<T>)?` | `null` | A tap on a row or tile |
| `dragging` | `bool` | `false` | Whether a drag is over the zone |
| `disabled` | `bool` | `false` | Greys the trigger out |
| `maxCount` | `int?` | `null` | Retires the trigger once reached |
| `trigger` | `Widget?` | `null` | Replaces the whole drop zone |
| `label` | `Widget?` | `null` | The trigger's headline |
| `hint` | `Widget?` | `null` | A dimmer second line under `label` |
| `thumbnailBuilder` | `Widget Function(UploadItem<T>)?` | `null` | Preview for every file |
| `showRemove` | `bool` | `true` | Ignored when `onRemove` is null |
| `showRetry` | `bool` | `true` | Ignored when `onRetry` is null |
| `showSize` | `bool` | `true` | Whether the size sits beside the name |
| `emptyState` | `Widget?` | `null` | Stands in for an empty list |
| `token` | `UploadToken?` | `null` | Per-instance token overrides |

### UploadItem

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `String` | required | Shown in the row; drives the extension glyph |
| `size` | `int?` | `null` | Bytes. Null hides the size |
| `status` | `UploadStatus` | `pending` | Where the file stands |
| `progress` | `double` | `0` | 0 to 1, drawn while uploading |
| `error` | `Widget?` | `null` | Why it failed |
| `thumbnail` | `Widget?` | `null` | Preview for this file |
| `data` | `T?` | `null` | Your own object for this file |

`name` is plain text rather than a widget because the component shortens it
when there is not enough room, which it could not do to a widget.

## Tokens

`Upload` has its own token set: `dropzoneBorderColor`,
`dropzoneActiveBorderColor`, `dropzoneBg`, `dropzoneActiveBg`,
`dropzoneRadius`, `dropzonePadding`, `itemRadius`, `itemHoverBg`,
`thumbnailSize`, `cardSize` and `gap`.

Override one instance:

```dart
Upload(items: _items, token: const UploadToken(cardSize: 140))
```

…or every `Upload` under a subtree through `ConfigProvider`:

```dart
ConfigProvider(
  theme: ThemeData(components: ComponentsConfig(
    upload: UploadToken(dropzoneRadius: 4),
  )),
  child: const MyApp(),
)
```
