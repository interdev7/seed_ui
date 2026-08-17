import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../feedback/message.dart' show StatusType;
import '../feedback/progress.dart';

/// Where a single file stands.
enum UploadStatus {
  /// Chosen but not sent yet.
  pending,

  /// On its way, with [UploadItem.progress] telling how far.
  uploading,

  /// Sent successfully.
  done,

  /// Failed. [UploadItem.error] says why.
  error,
}

/// How the chosen files are laid out.
enum UploadVariant {
  /// A vertical list of rows: name, size and progress, with no preview.
  text,

  /// A vertical list of rows carrying a square preview beside the name.
  picture,

  /// A grid of square tiles, with the trigger as the last one. Suits images.
  cards,

  /// [cards] with round tiles — avatars, and anything else that reads better
  /// as a circle.
  circleCards,
}

/// One file in an [Upload].
///
/// The kit never reads a file's bytes — picking and sending are the app's
/// business. This carries only what has to be drawn, plus [data] for whatever
/// object the app is really tracking.
@immutable
class UploadItem<T> {
  /// Creates an [UploadItem].
  const UploadItem({
    required this.name,
    this.id,
    this.size,
    this.status = UploadStatus.pending,
    this.progress = 0,
    this.error,
    this.thumbnail,
    this.data,
  }) : assert(
          progress >= 0 && progress <= 1,
          'progress must be between 0 and 1',
        );

  /// Identifies this file across rebuilds.
  ///
  /// The callbacks hand back the item they belong to, and a list is usually
  /// rebuilt — with a new [progress], a new [status] — between a tap and the
  /// handler running. Matching on identity breaks the moment [copyWith] makes
  /// a new object, so give each file an id and match on that.
  ///
  /// Null falls back to [name], which is enough while names are unique.
  final Object? id;

  /// What [id] resolves to: the explicit one, or the name.
  Object get key => id ?? name;

  /// The file's name, shown in the row and used for the extension glyph.
  ///
  /// Plain text rather than a widget: the component shortens it from the
  /// middle when there is not enough room, which it could not do to a widget.
  final String name;

  /// Size in bytes. Null hides the size, for a source that does not know it.
  final int? size;

  /// Where this file stands.
  final UploadStatus status;

  /// How far along, from 0 to 1. Only drawn while [status] is
  /// [UploadStatus.uploading].
  final double progress;

  /// Why it failed, shown under the name. Only drawn for
  /// [UploadStatus.error].
  final Widget? error;

  /// Preview for this file, replacing the default extension glyph.
  final Widget? thumbnail;

  /// The app's own object for this file — whatever its picker returned.
  final T? data;

  /// A copy with the given fields replaced.
  ///
  /// A field left out keeps its current value; passing null does not clear
  /// one.
  UploadItem<T> copyWith({
    String? name,
    Object? id,
    int? size,
    UploadStatus? status,
    double? progress,
    Widget? error,
    Widget? thumbnail,
    T? data,
  }) =>
      UploadItem<T>(
        name: name ?? this.name,
        id: id ?? this.id,
        size: size ?? this.size,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        error: error ?? this.error,
        thumbnail: thumbnail ?? this.thumbnail,
        data: data ?? this.data,
      );
}

/// Per-component design tokens for [Upload].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [UploadToken(...)])`, or per instance via [Upload.token].
@immutable
class UploadToken {
  /// Creates an [UploadToken].
  const UploadToken({
    this.dropzoneBorderColor,
    this.dropzoneActiveBorderColor,
    this.dropzoneBg,
    this.dropzoneActiveBg,
    this.dropzoneRadius,
    this.dropzonePadding,
    this.itemRadius,
    this.itemHoverBg,
    this.thumbnailSize,
    this.cardSize,
    this.gap,
  });

  /// Dashed outline of the drop zone at rest (`dropzoneBorderColor`).
  final Color? dropzoneBorderColor;

  /// Dashed outline while a drag hovers it (`dropzoneActiveBorderColor`).
  final Color? dropzoneActiveBorderColor;

  /// Drop-zone fill at rest (`dropzoneBg`).
  final Color? dropzoneBg;

  /// Drop-zone fill while a drag hovers it (`dropzoneActiveBg`).
  final Color? dropzoneActiveBg;

  /// Corner radius of the drop zone and of the card tiles (`dropzoneRadius`).
  final double? dropzoneRadius;

  /// Padding inside the drop zone (`dropzonePadding`).
  final EdgeInsets? dropzonePadding;

  /// Corner radius of a list row (`itemRadius`).
  final double? itemRadius;

  /// Row background while the pointer is over it (`itemHoverBg`).
  final Color? itemHoverBg;

  /// Side of the thumbnail in a list row (`thumbnailSize`).
  final double? thumbnailSize;

  /// Side of a tile in [UploadVariant.cards] (`cardSize`).
  final double? cardSize;

  /// Space between rows, and between tiles (`gap`).
  final double? gap;

  _ResolvedUploadToken _resolve(Token t) => _ResolvedUploadToken(
        dropzoneBorderColor: dropzoneBorderColor ?? t.colorBorder,
        dropzoneActiveBorderColor: dropzoneActiveBorderColor ?? t.primary.base,
        dropzoneBg: dropzoneBg ?? t.colorFillQuaternary,
        dropzoneActiveBg: dropzoneActiveBg ?? t.primary.bg,
        dropzoneRadius: dropzoneRadius ?? t.borderRadiusLG,
        dropzonePadding: dropzonePadding ?? EdgeInsets.all(t.sizeLG),
        itemRadius: itemRadius ?? t.borderRadiusSM,
        itemHoverBg: itemHoverBg ?? t.colorFillQuaternary,
        thumbnailSize: thumbnailSize ?? 40,
        cardSize: cardSize ?? 104,
        gap: gap ?? t.sizeXS,
      );
}

@immutable
class _ResolvedUploadToken {
  const _ResolvedUploadToken({
    required this.dropzoneBorderColor,
    required this.dropzoneActiveBorderColor,
    required this.dropzoneBg,
    required this.dropzoneActiveBg,
    required this.dropzoneRadius,
    required this.dropzonePadding,
    required this.itemRadius,
    required this.itemHoverBg,
    required this.thumbnailSize,
    required this.cardSize,
    required this.gap,
  });

  final Color dropzoneBorderColor;
  final Color dropzoneActiveBorderColor;
  final Color dropzoneBg;
  final Color dropzoneActiveBg;
  final double dropzoneRadius;
  final EdgeInsets dropzonePadding;
  final double itemRadius;
  final Color itemHoverBg;
  final double thumbnailSize;
  final double cardSize;
  final double gap;
}

/// The handlers a row or tile would have wired up, handed to
/// [Upload.itemBuilder] so a replacement can keep them.
///
/// A null one means the [Upload] was not given that callback, or the file is
/// in no state to use it — retry is offered only to a file that failed.
@immutable
class UploadActions {
  /// Creates an [UploadActions].
  const UploadActions({this.remove, this.retry, this.preview, this.download});

  /// Reports this file's remove button.
  final VoidCallback? remove;

  /// Reports this file's retry button.
  final VoidCallback? retry;

  /// Reports a tap on the file, or on its preview button.
  final VoidCallback? preview;

  /// Reports this file's download button.
  final VoidCallback? download;
}

/// A file list with a picker trigger, progress per file, and retry and remove
/// actions.
///
/// **The kit does not pick or send files.** Opening a file dialog needs
/// platform code, and posting bytes is the app's concern, so `Upload` draws
/// the state and calls back — leaving the package free of plugin
/// dependencies, and leaving you free to pick with whatever you already use.
///
/// ```dart
/// Upload<PlatformFile>(
///   items: _items,
///   onPick: () async {
///     final picked = await FilePicker.platform.pickFiles(allowMultiple: true);
///     if (picked != null) _add(picked.files);
///   },
///   onRemove: (item) => setState(() => _items.remove(item)),
///   onRetry: _send,
/// )
/// ```
///
/// The list is yours: rebuild it with new [UploadItem.progress] and
/// [UploadItem.status] as your upload runs, and the rows follow.
///
/// ## Drag and drop
///
/// The dashed target is drawn here, but the operating system's drag events
/// are not Flutter's to give. Wire them with whichever package you prefer and
/// pass the result through [dragging]:
///
/// ```dart
/// DropTarget(
///   onDragEntered: (_) => setState(() => _dragging = true),
///   onDragExited: (_) => setState(() => _dragging = false),
///   onDragDone: (detail) => _add(detail.files),
///   child: Upload(items: _items, dragging: _dragging, onPick: _pick),
/// )
/// ```
class Upload<T> extends StatelessWidget {
  /// Creates an [Upload].
  const Upload({
    super.key,
    this.items = const [],
    this.variant = UploadVariant.picture,
    this.onPick,
    this.onRemove,
    this.onRetry,
    this.onPreview,
    this.onDownload,
    this.itemBuilder,
    this.dragging = false,
    this.disabled = false,
    this.maxCount,
    this.trigger,
    this.label,
    this.hint,
    this.thumbnailBuilder,
    this.showRemove = true,
    this.showRetry = true,
    this.showSize = true,
    this.emptyState,
    this.token,
  });

  /// The files to draw, in order. The app owns this list.
  final List<UploadItem<T>> items;

  /// Rows or tiles.
  final UploadVariant variant;

  /// Called when the trigger is used. Open your picker here and add whatever
  /// it returns to [items].
  ///
  /// Null hides the trigger, leaving a read-only list.
  final Future<void> Function()? onPick;

  /// Called when a file's remove button is used.
  ///
  /// Only a notification: the app owns [items] and does the removing, so
  /// there is nothing here to veto. Raise a confirmation inside the handler
  /// and drop the file only if it is accepted.
  ///
  /// Null hides the button, whatever [showRemove] says.
  final void Function(UploadItem<T> item)? onRemove;

  /// Called when a failed file's retry button is used.
  ///
  /// Null hides the button, whatever [showRetry] says.
  final void Function(UploadItem<T> item)? onRetry;

  /// Called when a file's row or tile is tapped, and by its preview button.
  final void Function(UploadItem<T> item)? onPreview;

  /// Called when a file's download button is used.
  ///
  /// Null hides the button. Fetching the bytes is the app's business, as
  /// ever.
  final void Function(UploadItem<T> item)? onDownload;

  /// Replaces a whole row or tile.
  ///
  /// The kit still decides where files sit and how the trigger behaves; this
  /// only takes over what one file looks like. `actions` carries the handlers
  /// the built-in row would have wired up, so a replacement can keep them
  /// without reaching back into [items].
  final Widget Function(UploadItem<T> item, UploadActions actions)? itemBuilder;

  /// Whether a drag is currently over the drop zone.
  ///
  /// The kit cannot observe the operating system's drag events, so the app
  /// sets this from whichever drag-and-drop package it uses.
  final bool dragging;

  /// Greys the trigger out and stops it answering.
  final bool disabled;

  /// The most files to accept. Once [items] reaches it the trigger goes away.
  ///
  /// Null accepts any number. Nothing is enforced beyond hiding the trigger —
  /// the list is the app's.
  final int? maxCount;

  /// Replaces the whole trigger: the drop zone, or the last tile in
  /// [UploadVariant.cards].
  final Widget? trigger;

  /// The trigger's headline. Null uses a default line of prompt text.
  final Widget? label;

  /// A dimmer second line under [label] — accepted formats, size limits.
  final Widget? hint;

  /// Builds the preview for a file, in place of the default extension glyph.
  ///
  /// [UploadItem.thumbnail] wins over this for an individual file.
  final Widget Function(UploadItem<T> item)? thumbnailBuilder;

  /// Whether files carry a remove button. Ignored when [onRemove] is null.
  final bool showRemove;

  /// Whether failed files carry a retry button. Ignored when [onRetry] is
  /// null.
  final bool showRetry;

  /// Whether a file's size is drawn beside its name.
  final bool showSize;

  /// Shown in place of the list while [items] is empty.
  ///
  /// Null draws nothing, leaving the trigger on its own.
  final Widget? emptyState;

  /// Per-instance token overrides.
  final UploadToken? token;

  /// Whether the trigger has room left to accept more files.
  bool get _accepting =>
      onPick != null && (maxCount == null || items.length < maxCount!);

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (token ??
            ConfigProvider.componentOf<UploadToken>(context) ??
            const UploadToken())
        ._resolve(t);

    return switch (variant) {
      UploadVariant.cards || UploadVariant.circleCards => _cards(context, t, r),
      UploadVariant.text || UploadVariant.picture => _list(context, t, r),
    };
  }

  /// The handlers for [item], with the ones it cannot use left null.
  UploadActions _actionsFor(UploadItem<T> item) => UploadActions(
        remove: showRemove && onRemove != null ? () => onRemove!(item) : null,
        retry: showRetry && onRetry != null && item.status == UploadStatus.error
            ? () => onRetry!(item)
            : null,
        preview: onPreview == null ? null : () => onPreview!(item),
        download: onDownload == null ? null : () => onDownload!(item),
      );

  Widget _list(BuildContext context, Token t, _ResolvedUploadToken r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_accepting) _dropzone(context, t, r),
        if (items.isEmpty && emptyState != null) ...[
          if (_accepting) SizedBox(height: r.gap),
          emptyState!,
        ],
        for (final item in items) ...[
          SizedBox(height: r.gap),
          itemBuilder?.call(item, _actionsFor(item)) ??
              _UploadRow<T>(
                item: item,
                token: t,
                style: r,
                showSize: showSize,
                // `text` names the file and nothing else; `picture` gives it
                // a preview beside the name.
                thumbnail: variant == UploadVariant.picture
                    ? _thumbnailFor(item, t, r)
                    : null,
                actions: _actionsFor(item),
              ),
        ],
      ],
    );
  }

  Widget _cards(BuildContext context, Token t, _ResolvedUploadToken r) {
    return Wrap(
      spacing: r.gap,
      runSpacing: r.gap,
      children: [
        for (final item in items)
          itemBuilder?.call(item, _actionsFor(item)) ??
              _UploadCard<T>(
                item: item,
                token: t,
                style: r,
                round: variant == UploadVariant.circleCards,
                thumbnail: _thumbnailFor(item, t, r),
                actions: _actionsFor(item),
              ),
        if (_accepting)
          SizedBox(
            width: r.cardSize,
            height: r.cardSize,
            child: _dropzone(
              context,
              t,
              r,
              compact: true,
              round: variant == UploadVariant.circleCards,
            ),
          ),
      ],
    );
  }

  Widget _thumbnailFor(
    UploadItem<T> item,
    Token t,
    _ResolvedUploadToken r,
  ) =>
      item.thumbnail ??
      thumbnailBuilder?.call(item) ??
      _ExtensionGlyph(name: item.name, token: t);

  Widget _dropzone(
    BuildContext context,
    Token t,
    _ResolvedUploadToken r, {
    bool compact = false,
    bool round = false,
  }) {
    return _Dropzone(
      token: t,
      style: r,
      dragging: dragging,
      disabled: disabled,
      compact: compact,
      round: round,
      onTap: disabled ? null : onPick,
      label: label,
      hint: hint,
      trigger: trigger,
    );
  }
}

// --------------------------------------------------------------------------
// Internals
// --------------------------------------------------------------------------

/// Renders bytes as the shortest sensible unit: `842 B`, `12.4 KB`, `3.1 MB`.
String _formatSize(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  // Bytes are whole; everything above reads better with one decimal.
  final text = unit == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}

/// The trigger: a dashed area that answers a tap and lights up under a drag.
class _Dropzone extends StatefulWidget {
  const _Dropzone({
    required this.token,
    required this.style,
    required this.dragging,
    required this.disabled,
    required this.compact,
    required this.round,
    required this.onTap,
    required this.label,
    required this.hint,
    required this.trigger,
  });

  final Token token;
  final _ResolvedUploadToken style;
  final bool dragging;
  final bool disabled;
  final bool compact;

  /// Draws the zone as a circle, to sit among round tiles.
  final bool round;

  final Future<void> Function()? onTap;
  final Widget? label;
  final Widget? hint;
  final Widget? trigger;

  @override
  State<_Dropzone> createState() => _DropzoneState();
}

class _DropzoneState extends State<_Dropzone> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    final r = widget.style;
    // A drag reads as a stronger signal than a hover, so it wins the accent.
    final active = widget.dragging || _hovered;
    final accent = widget.dragging
        ? r.dropzoneActiveBorderColor
        : (active ? t.primary.borderHover : r.dropzoneBorderColor);

    final content = widget.trigger ??
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: Size.square(widget.compact ? 20 : 28),
              painter: _PlusPainter(
                widget.disabled ? t.colorTextQuaternary : accent,
              ),
            ),
            if (!widget.compact) ...[
              SizedBox(height: t.sizeXS),
              DefaultTextStyle(
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.disabled ? t.colorTextQuaternary : t.colorText,
                  fontSize: t.fontSize,
                  fontFamily: t.fontFamily,
                  fontFamilyFallback: t.fontFamilyFallback,
                  decoration: TextDecoration.none,
                ),
                child: widget.label ?? const Text('Choose a file'),
              ),
              if (widget.hint != null) ...[
                SizedBox(height: t.sizeXXS),
                DefaultTextStyle(
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.colorTextTertiary,
                    fontSize: t.fontSizeSM,
                    fontFamily: t.fontFamily,
                    fontFamilyFallback: t.fontFamilyFallback,
                    height: t.lineHeight,
                    decoration: TextDecoration.none,
                  ),
                  child: widget.hint!,
                ),
              ],
            ],
          ],
        );

    return MouseRegion(
      cursor:
          widget.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap == null ? null : () => widget.onTap!(),
        child: AnimatedContainer(
          duration: t.motionDurationMid,
          curve: t.motionEaseInOut,
          padding: widget.compact ? EdgeInsets.zero : r.dropzonePadding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.dragging ? r.dropzoneActiveBg : r.dropzoneBg,
            shape: widget.round ? BoxShape.circle : BoxShape.rectangle,
            borderRadius:
                widget.round ? null : BorderRadius.circular(r.dropzoneRadius),
          ),
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: widget.disabled ? t.colorBorderSecondary : accent,
              radius: BorderRadius.circular(
                widget.round ? r.cardSize : r.dropzoneRadius,
              ),
              strokeWidth: t.lineWidth,
            ),
            child: Padding(
              padding: EdgeInsets.all(widget.compact ? t.sizeXS : 0),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// One file as a row: thumbnail, name and size, progress, actions.
class _UploadRow<T> extends StatefulWidget {
  const _UploadRow({
    required this.item,
    required this.token,
    required this.style,
    required this.showSize,
    required this.thumbnail,
    required this.actions,
  });

  final UploadItem<T> item;
  final Token token;
  final _ResolvedUploadToken style;
  final bool showSize;
  final Widget? thumbnail;
  final UploadActions actions;

  @override
  State<_UploadRow<T>> createState() => _UploadRowState<T>();
}

class _UploadRowState<T> extends State<_UploadRow<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    final r = widget.style;
    final item = widget.item;
    final failed = item.status == UploadStatus.error;

    return MouseRegion(
      cursor: widget.actions.preview == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.actions.preview,
        child: Container(
          padding: EdgeInsets.all(t.sizeXS),
          decoration: BoxDecoration(
            color: _hovered ? r.itemHoverBg : null,
            borderRadius: BorderRadius.circular(r.itemRadius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.thumbnail != null) ...[
                SizedBox(
                  width: r.thumbnailSize,
                  height: r.thumbnailSize,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(r.itemRadius),
                    child: widget.thumbnail,
                  ),
                ),
                SizedBox(width: t.sizeXS),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: failed ? t.error.base : t.colorText,
                              fontSize: t.fontSize,
                              fontFamily: t.fontFamily,
                              fontFamilyFallback: t.fontFamilyFallback,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        if (widget.showSize && item.size != null) ...[
                          SizedBox(width: t.sizeXS),
                          Text(
                            _formatSize(item.size!),
                            style: TextStyle(
                              color: t.colorTextTertiary,
                              fontSize: t.fontSizeSM,
                              fontFamily: t.fontFamily,
                              fontFamilyFallback: t.fontFamilyFallback,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.status == UploadStatus.uploading) ...[
                      SizedBox(height: t.sizeXXS),
                      Progress(
                        percent: item.progress,
                        showInfo: false,
                        strokeWidth: 4,
                      ),
                    ],
                    if (failed && item.error != null) ...[
                      SizedBox(height: t.sizeXXS),
                      DefaultTextStyle(
                        style: TextStyle(
                          color: t.error.base,
                          fontSize: t.fontSizeSM,
                          fontFamily: t.fontFamily,
                          fontFamilyFallback: t.fontFamilyFallback,
                          height: t.lineHeight,
                          decoration: TextDecoration.none,
                        ),
                        child: item.error!,
                      ),
                    ],
                  ],
                ),
              ),
              if (item.status == UploadStatus.done) ...[
                SizedBox(width: t.sizeXS),
                StatusIcon(type: StatusType.success, token: t),
              ],
              if (widget.actions.download != null) ...[
                SizedBox(width: t.sizeXS),
                _IconButton(
                  token: t,
                  onTap: widget.actions.download!,
                  painter: _DownloadPainter(t.colorTextTertiary),
                ),
              ],
              if (widget.actions.retry != null) ...[
                SizedBox(width: t.sizeXS),
                _IconButton(
                  token: t,
                  onTap: widget.actions.retry!,
                  painter: _RetryPainter(t.colorTextTertiary),
                ),
              ],
              if (widget.actions.remove != null) ...[
                SizedBox(width: t.sizeXXS),
                _IconButton(
                  token: t,
                  onTap: widget.actions.remove!,
                  painter: CrossPainter(t.colorTextTertiary, inset: 5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One file as a square tile, for [UploadVariant.cards].
class _UploadCard<T> extends StatefulWidget {
  const _UploadCard({
    required this.item,
    required this.token,
    required this.style,
    required this.round,
    required this.thumbnail,
    required this.actions,
  });

  final UploadItem<T> item;
  final Token token;
  final _ResolvedUploadToken style;

  /// Draws the tile as a circle.
  final bool round;

  final Widget thumbnail;
  final UploadActions actions;

  @override
  State<_UploadCard<T>> createState() => _UploadCardState<T>();
}

class _UploadCardState<T> extends State<_UploadCard<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    final r = widget.style;
    final item = widget.item;
    final radius = BorderRadius.circular(
      widget.round ? r.cardSize : r.dropzoneRadius,
    );

    return MouseRegion(
      cursor: widget.actions.preview == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.actions.preview,
        child: SizedBox(
          width: r.cardSize,
          height: r.cardSize,
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: r.dropzoneBg, child: widget.thumbnail),
                if (item.status == UploadStatus.uploading)
                  ColoredBox(
                    color: t.colorBgMask,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: t.sizeSM),
                        child: Progress(
                          percent: item.progress,
                          showInfo: false,
                          strokeWidth: 4,
                        ),
                      ),
                    ),
                  ),
                if (item.status == UploadStatus.error)
                  ColoredBox(
                    color: t.error.base.withValues(alpha: 0.16),
                    child: Center(
                      child: StatusIcon(type: StatusType.error, token: t),
                    ),
                  ),
                // The actions only surface on hover, so a wall of tiles stays
                // readable as pictures rather than as a grid of buttons.
                if (_hovered &&
                    (widget.actions.remove != null ||
                        widget.actions.retry != null))
                  Positioned(
                    top: t.sizeXXS,
                    right: t.sizeXXS,
                    child: Row(
                      children: [
                        if (widget.actions.retry != null)
                          _IconButton(
                            token: t,
                            onTap: widget.actions.retry!,
                            painter: _RetryPainter(_onMask),
                            background: t.colorBgMask,
                          ),
                        if (widget.actions.remove != null) ...[
                          SizedBox(width: t.sizeXXS),
                          _IconButton(
                            token: t,
                            onTap: widget.actions.remove!,
                            painter: CrossPainter(_onMask, inset: 5),
                            background: t.colorBgMask,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glyph colour for the actions that sit on a card's dark hover mask.
///
/// Not a theme token: the mask is dark in either scheme, so the glyph on it
/// is white regardless of whether the app is light or dark.
const Color _onMask = Color(0xFFFFFFFF);

/// A small square tap target wrapping a painter.
class _IconButton extends StatefulWidget {
  const _IconButton({
    required this.token,
    required this.onTap,
    required this.painter,
    this.background,
  });

  final Token token;
  final VoidCallback onTap;
  final CustomPainter painter;
  final Color? background;

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color:
                widget.background ?? (_hovered ? t.colorFillSecondary : null),
            borderRadius: BorderRadius.circular(t.borderRadiusSM),
          ),
          child: CustomPaint(painter: widget.painter),
        ),
      ),
    );
  }
}

/// The fallback preview: the file's extension on a tinted square.
class _ExtensionGlyph extends StatelessWidget {
  const _ExtensionGlyph({required this.name, required this.token});

  final String name;
  final Token token;

  /// The extension without its dot, upper-cased and capped so a long one does
  /// not overflow the square. Empty when the name carries none.
  String get _extension {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    final ext = name.substring(dot + 1).toUpperCase();
    return ext.length > 4 ? ext.substring(0, 4) : ext;
  }

  @override
  Widget build(BuildContext context) {
    final ext = _extension;
    return ColoredBox(
      color: token.colorFillQuaternary,
      child: Center(
        child: Text(
          ext.isEmpty ? '?' : ext,
          maxLines: 1,
          style: TextStyle(
            color: token.colorTextTertiary,
            fontSize: token.fontSizeSM,
            fontWeight: FontWeight.w600,
            fontFamily: token.fontFamily,
            fontFamilyFallback: token.fontFamilyFallback,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

/// A plus sign, sized to its paint box.
class _PlusPainter extends CustomPainter {
  _PlusPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(1.4, size.width * 0.07)
      ..strokeCap = StrokeCap.round;
    final c = size.center(Offset.zero);
    final r = size.width * 0.3;
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), paint);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), paint);
  }

  @override
  bool shouldRepaint(_PlusPainter old) => old.color != color;
}

/// A downward arrow onto a baseline — download.
class _DownloadPainter extends CustomPainter {
  _DownloadPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final c = size.center(Offset.zero);
    final h = size.height * 0.3;
    canvas.drawLine(
        Offset(c.dx, c.dy - h), Offset(c.dx, c.dy + h * 0.4), paint);
    canvas.drawLine(
      Offset(c.dx - h * 0.5, c.dy - h * 0.1),
      Offset(c.dx, c.dy + h * 0.4),
      paint,
    );
    canvas.drawLine(
      Offset(c.dx + h * 0.5, c.dy - h * 0.1),
      Offset(c.dx, c.dy + h * 0.4),
      paint,
    );
    canvas.drawLine(
      Offset(c.dx - h * 0.7, c.dy + h),
      Offset(c.dx + h * 0.7, c.dy + h),
      paint,
    );
  }

  @override
  bool shouldRepaint(_DownloadPainter old) => old.color != color;
}

/// A circular arrow — retry.
class _RetryPainter extends CustomPainter {
  _RetryPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final c = size.center(Offset.zero);
    final radius = size.width * 0.28;
    // An arc left open at the top right, with an arrowhead closing it, so the
    // glyph reads as a loop rather than a full circle.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: radius),
      -0.6,
      5.2,
      false,
      paint,
    );
    final tip = Offset(c.dx + radius, c.dy - radius * 0.55);
    canvas.drawLine(tip, tip.translate(-radius * 0.5, 0.2), paint);
    canvas.drawLine(tip, tip.translate(0.2, radius * 0.5), paint);
  }

  @override
  bool shouldRepaint(_RetryPainter old) => old.color != color;
}
