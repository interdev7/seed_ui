import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, Switch, Tooltip, Drawer, Card;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

/// Shows `Upload` driving a real picker.
///
/// `file_picker` is a dependency of this gallery, never of `seed_ui`: opening
/// a file dialog needs platform code, and the kit stays free of plugins so an
/// app can pick with whatever it already uses. `Upload` only draws the state
/// and calls back.
class UploadDemo extends StatefulWidget {
  const UploadDemo({super.key});

  @override
  State<UploadDemo> createState() => _UploadDemoState();
}

class _UploadDemoState extends State<UploadDemo> {
  List<UploadItem<PlatformFile>> _files = [];
  List<UploadItem<String>> _cards = const [
    UploadItem<String>(name: 'beach.jpg', size: 184320, thumbnail: _Swatch(0)),
    UploadItem<String>(name: 'forest.png', size: 262144, thumbnail: _Swatch(1)),
  ];
  final List<UploadItem<String>> _states = const [
    UploadItem<String>(name: 'queued.zip', size: 51200),
    UploadItem<String>(
      name: 'sending.mp4',
      size: 8388608,
      status: UploadStatus.uploading,
      progress: 0.62,
    ),
    UploadItem<String>(
      name: 'delivered.pdf',
      size: 204800,
      status: UploadStatus.done,
    ),
    UploadItem<String>(
      name: 'rejected.exe',
      size: 1048576,
      status: UploadStatus.error,
      error: Text('The server refused this type'),
    ),
  ];

  /// Replaces one file in the list, matched by identity.
  void _replace(UploadItem<PlatformFile> old, UploadItem<PlatformFile> fresh) {
    if (!mounted) return;
    setState(() {
      _files = [
        for (final f in _files)
          if (identical(f, old)) fresh else f,
      ];
    });
  }

  /// Stands in for a real upload: walks the progress up, then settles on
  /// success — or, for one file in four, on a failure worth retrying.
  Future<void> _send(UploadItem<PlatformFile> item) async {
    var current = item.copyWith(status: UploadStatus.uploading, progress: 0);
    _replace(item, current);

    for (var step = 1; step <= 10; step++) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      final next = current.copyWith(progress: step / 10);
      _replace(current, next);
      current = next;
    }

    final failed = current.name.hashCode % 4 == 0;
    _replace(
      current,
      current.copyWith(
        status: failed ? UploadStatus.error : UploadStatus.done,
        progress: 1,
        error: failed ? const Text('Upload timed out') : null,
      ),
    );
  }

  Future<void> _pick() async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) return;

    // `PlatformFile.length()` is asynchronous, so the sizes are gathered
    // before the list is handed to the widget rather than during its build.
    final added = <UploadItem<PlatformFile>>[
      for (final f in picked)
        UploadItem<PlatformFile>(name: f.name, size: await f.length(), data: f),
    ];
    if (!mounted) return;
    setState(() => _files = [..._files, ...added]);

    for (final item in added) {
      unawaited(_send(item));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Group(
            'Live — picks real files',
            Upload<PlatformFile>(
              items: _files,
              onPick: _pick,
              onRemove: (item) =>
                  setState(() => _files = [..._files]..remove(item)),
              onRetry: _send,
              label: const Text('Choose files'),
              hint: const Text(
                'Anything you like — nothing leaves your machine',
              ),
              emptyState: const Empty(),
            ),
          ),
          Group(
            'Every status',
            Upload<String>(items: _states, onRemove: (_) {}, onRetry: (_) {}),
          ),
          Group(
            'Cards, for images',
            Upload<String>(
              items: _cards,
              variant: UploadVariant.cards,
              maxCount: 5,
              onPick: () async {
                setState(() {
                  _cards = [
                    ..._cards,
                    UploadItem<String>(
                      name: 'added-${_cards.length + 1}.jpg',
                      size: 131072,
                      thumbnail: _Swatch(_cards.length),
                    ),
                  ];
                });
              },
              onRemove: (item) =>
                  setState(() => _cards = [..._cards]..remove(item)),
            ),
          ),
          const Group(
            'Read-only',
            Upload<String>(
              items: [
                UploadItem<String>(name: 'contract.pdf', size: 409600),
                UploadItem<String>(name: 'appendix.docx', size: 81920),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A stand-in for an image preview, so the gallery needs no bundled assets.
class _Swatch extends StatelessWidget {
  const _Swatch(this.seed);

  final int seed;

  @override
  Widget build(BuildContext context) {
    const palette = [
      [Color(0xFF1677FF), Color(0xFF69B1FF)],
      [Color(0xFF52C41A), Color(0xFF95DE64)],
      [Color(0xFFFA8C16), Color(0xFFFFC069)],
      [Color(0xFF722ED1), Color(0xFFB37FEB)],
      [Color(0xFFEB2F96), Color(0xFFFF85C0)],
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: palette[seed % palette.length]),
      ),
    );
  }
}
