import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _wrap(Widget child) => ConfigProvider(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox(width: 420, child: child)),
      ),
    );

const _items = [
  UploadItem<String>(name: 'report.pdf', size: 2048),
  UploadItem<String>(name: 'photo.png', size: 1536),
];

void main() {
  group('The list', () {
    testWidgets('every file is named', (tester) async {
      await tester.pumpWidget(_wrap(const Upload<String>(items: _items)));

      expect(find.text('report.pdf'), findsOneWidget);
      expect(find.text('photo.png'), findsOneWidget);
    });

    testWidgets('sizes read in the shortest sensible unit', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Upload<String>(
            items: [
              UploadItem<String>(name: 'a.txt', size: 842),
              UploadItem<String>(name: 'b.txt', size: 2048),
              UploadItem<String>(name: 'c.txt', size: 3 * 1024 * 1024),
            ],
          ),
        ),
      );

      expect(find.text('842 B'), findsOneWidget);
      expect(find.text('2.0 KB'), findsOneWidget);
      expect(find.text('3.0 MB'), findsOneWidget);
    });

    testWidgets('a file with no size shows none', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Upload<String>(
            items: [UploadItem<String>(name: 'stream.bin')],
          ),
        ),
      );

      expect(find.text('stream.bin'), findsOneWidget);
      expect(find.textContaining(' B'), findsNothing);
    });

    testWidgets('showSize: false drops the size', (tester) async {
      await tester.pumpWidget(
        _wrap(const Upload<String>(items: _items, showSize: false)),
      );

      expect(find.text('2.0 KB'), findsNothing);
    });

    testWidgets('the extension stands in for a missing thumbnail',
        (tester) async {
      await tester.pumpWidget(_wrap(const Upload<String>(items: _items)));

      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('PNG'), findsOneWidget);
    });

    testWidgets('a name with no extension falls back to a placeholder',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Upload<String>(items: [UploadItem<String>(name: 'LICENSE')]),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('a supplied thumbnail wins over the extension', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Upload<String>(
            items: [
              UploadItem<String>(name: 'photo.png', thumbnail: Text('mine')),
            ],
          ),
        ),
      );

      expect(find.text('mine'), findsOneWidget);
      expect(find.text('PNG'), findsNothing);
    });

    testWidgets('thumbnailBuilder covers every file that brought none',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          Upload<String>(
            items: _items,
            thumbnailBuilder: (item) => Text('T:${item.name}'),
          ),
        ),
      );

      expect(find.text('T:report.pdf'), findsOneWidget);
      expect(find.text('T:photo.png'), findsOneWidget);
    });
  });

  group('Status', () {
    testWidgets('an uploading file shows progress, a pending one does not',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Upload<String>(
            items: [
              UploadItem<String>(name: 'a.txt', status: UploadStatus.pending),
              UploadItem<String>(
                name: 'b.txt',
                status: UploadStatus.uploading,
                progress: 0.4,
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(Progress), findsOneWidget);
    });

    testWidgets('a failure explains itself', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Upload<String>(
            items: [
              UploadItem<String>(
                name: 'a.txt',
                status: UploadStatus.error,
                error: Text('Server rejected it'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Server rejected it'), findsOneWidget);
    });

    testWidgets('progress outside 0..1 is rejected', (tester) async {
      expect(
        () => UploadItem<String>(name: 'a.txt', progress: 1.5),
        throwsAssertionError,
      );
    });
  });

  group('Actions', () {
    testWidgets('remove reports the file it belongs to', (tester) async {
      UploadItem<String>? removed;
      await tester.pumpWidget(
        _wrap(
          Upload<String>(items: _items, onRemove: (item) => removed = item),
        ),
      );

      // One remove button per row; the second belongs to the second file.
      await tester.tap(find.byType(CustomPaint).last, warnIfMissed: false);
      await tester.pump();

      expect(removed, isNotNull);
    });

    testWidgets('no onRemove means no remove button', (tester) async {
      await tester.pumpWidget(_wrap(const Upload<String>(items: _items)));
      final withoutHandler = tester.widgetList(find.byType(CustomPaint)).length;

      await tester.pumpWidget(
        _wrap(Upload<String>(items: _items, onRemove: (_) {})),
      );
      final withHandler = tester.widgetList(find.byType(CustomPaint)).length;

      expect(withHandler, greaterThan(withoutHandler));
    });

    testWidgets('retry is offered only to a file that failed', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Upload<String>(
            items: const [
              UploadItem<String>(name: 'ok.txt', status: UploadStatus.done),
              UploadItem<String>(name: 'bad.txt', status: UploadStatus.error),
            ],
            onRetry: (_) {},
          ),
        ),
      );

      // The successful file gets a status tick, the failed one a retry
      // button; neither gets the other's.
      expect(find.byType(StatusIcon), findsOneWidget);
    });

    testWidgets('a tap on a row reports the file', (tester) async {
      UploadItem<String>? tapped;
      await tester.pumpWidget(
        _wrap(
            Upload<String>(items: _items, onPreview: (item) => tapped = item)),
      );

      await tester.tap(find.text('report.pdf'));
      await tester.pump();

      expect(tapped?.name, 'report.pdf');
    });
  });

  group('The trigger', () {
    testWidgets('no onPick leaves a read-only list', (tester) async {
      await tester.pumpWidget(_wrap(const Upload<String>(items: _items)));

      expect(find.text('Choose a file'), findsNothing);
    });

    testWidgets('onPick raises the drop zone and runs on a tap',
        (tester) async {
      var picked = 0;
      await tester.pumpWidget(
        _wrap(
          Upload<String>(
            items: const [],
            onPick: () async => picked++,
          ),
        ),
      );

      expect(find.text('Choose a file'), findsOneWidget);
      await tester.tap(find.text('Choose a file'));
      await tester.pump();

      expect(picked, 1);
    });

    testWidgets('label and hint replace the default prompt', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Upload<String>(
            onPick: () async {},
            label: const Text('Drop a résumé'),
            hint: const Text('PDF, up to 5 MB'),
          ),
        ),
      );

      expect(find.text('Drop a résumé'), findsOneWidget);
      expect(find.text('PDF, up to 5 MB'), findsOneWidget);
      expect(find.text('Choose a file'), findsNothing);
    });

    testWidgets('a custom trigger replaces the whole zone', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Upload<String>(
            onPick: () async {},
            trigger: const Text('Browse…'),
          ),
        ),
      );

      expect(find.text('Browse…'), findsOneWidget);
      expect(find.text('Choose a file'), findsNothing);
    });

    testWidgets('maxCount retires the trigger once the list is full',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          Upload<String>(items: _items, maxCount: 3, onPick: () async {}),
        ),
      );
      expect(find.text('Choose a file'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          Upload<String>(items: _items, maxCount: 2, onPick: () async {}),
        ),
      );
      expect(find.text('Choose a file'), findsNothing);
    });

    testWidgets('disabled stops the trigger answering', (tester) async {
      var picked = 0;
      await tester.pumpWidget(
        _wrap(
          Upload<String>(
            disabled: true,
            onPick: () async => picked++,
          ),
        ),
      );

      await tester.tap(find.text('Choose a file'));
      await tester.pump();

      expect(picked, 0);
    });

    testWidgets('a drag over the zone tints it', (tester) async {
      Color? fillOf(WidgetTester tester) {
        final box = tester
            .widgetList<AnimatedContainer>(
              find.byType(AnimatedContainer),
            )
            .first;
        return (box.decoration! as BoxDecoration).color;
      }

      await tester.pumpWidget(_wrap(Upload<String>(onPick: () async {})));
      final resting = fillOf(tester);

      await tester.pumpWidget(
        _wrap(Upload<String>(onPick: () async {}, dragging: true)),
      );
      await tester.pumpAndSettle();

      expect(fillOf(tester), isNot(resting));
    });
  });

  group('Cards', () {
    testWidgets('every file becomes a tile, with the trigger last',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          Upload<String>(
            items: _items,
            variant: UploadVariant.cards,
            onPick: () async {},
          ),
        ),
      );

      // Tiles show the preview, not the file name — the name would not fit.
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('PNG'), findsOneWidget);
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('the empty state stands in for an empty list', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Upload<String>(
            items: [],
            emptyState: Text('Nothing yet'),
          ),
        ),
      );

      expect(find.text('Nothing yet'), findsOneWidget);
    });
  });

  group('copyWith', () {
    test('replaces only what it is given', () {
      const item = UploadItem<String>(
        name: 'a.txt',
        size: 10,
        data: 'payload',
      );

      final moved = item.copyWith(
        status: UploadStatus.uploading,
        progress: 0.5,
      );

      expect(moved.name, 'a.txt');
      expect(moved.size, 10);
      expect(moved.data, 'payload');
      expect(moved.status, UploadStatus.uploading);
      expect(moved.progress, 0.5);
    });
  });

  group('Variants', () {
    testWidgets('text drops the preview, picture keeps it', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Upload<String>(items: _items, variant: UploadVariant.text),
        ),
      );
      expect(find.text('PDF'), findsNothing);
      expect(find.text('report.pdf'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          const Upload<String>(items: _items, variant: UploadVariant.picture),
        ),
      );
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('circleCards lays tiles out like cards', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Upload<String>(
            items: _items,
            variant: UploadVariant.circleCards,
          ),
        ),
      );

      expect(find.byType(Wrap), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
    });
  });

  group('Identity', () {
    test('key falls back to the name', () {
      const named = UploadItem<String>(name: 'a.txt');
      expect(named.key, 'a.txt');
      const keyed = UploadItem<String>(name: 'a.txt', id: 7);
      expect(keyed.key, 7);
    });

    test('copyWith carries the id', () {
      const item = UploadItem<String>(name: 'a.txt', id: 'x');
      expect(item.copyWith(progress: 0.5).key, 'x');
    });
  });

  group('Download and preview', () {
    testWidgets('onDownload raises a button that reports its file',
        (tester) async {
      UploadItem<String>? got;
      await tester.pumpWidget(
        _wrap(
          Upload<String>(
            items: const [UploadItem<String>(name: 'a.txt')],
            onDownload: (item) => got = item,
          ),
        ),
      );

      await tester.tap(find.byType(CustomPaint).last, warnIfMissed: false);
      await tester.pump();
      expect(got?.name, 'a.txt');
    });

    testWidgets('no onDownload, no button', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Upload<String>(items: [UploadItem<String>(name: 'a.txt')]),
        ),
      );
      final without = tester.widgetList(find.byType(CustomPaint)).length;

      await tester.pumpWidget(
        _wrap(
          Upload<String>(
            items: const [UploadItem<String>(name: 'a.txt')],
            onDownload: (_) {},
          ),
        ),
      );
      expect(
        tester.widgetList(find.byType(CustomPaint)).length,
        greaterThan(without),
      );
    });
  });

  group('itemBuilder', () {
    testWidgets('replaces the row and keeps the handlers', (tester) async {
      UploadItem<String>? removed;
      await tester.pumpWidget(
        _wrap(
          Upload<String>(
            items: const [UploadItem<String>(name: 'a.txt')],
            onRemove: (item) => removed = item,
            itemBuilder: (item, actions) => GestureDetector(
              onTap: actions.remove,
              child: Text('custom ${item.name}'),
            ),
          ),
        ),
      );

      // The built-in row is gone, the replacement is there.
      expect(find.text('custom a.txt'), findsOneWidget);
      expect(find.text('a.txt'), findsNothing);

      // And it can still drive the actions it was handed.
      await tester.tap(find.text('custom a.txt'));
      await tester.pump();
      expect(removed?.name, 'a.txt');
    });

    testWidgets('retry is null for a file that did not fail', (tester) async {
      UploadActions? seen;
      await tester.pumpWidget(
        _wrap(
          Upload<String>(
            items: const [UploadItem<String>(name: 'a.txt')],
            onRetry: (_) {},
            itemBuilder: (item, actions) {
              seen = actions;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(seen!.retry, isNull);
    });
  });
}
