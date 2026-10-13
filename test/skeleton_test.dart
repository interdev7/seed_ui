import 'package:flutter/material.dart'
    hide
        ThemeData,
        Checkbox,
        Radio,
        RadioGroup,
        Switch,
        Tooltip,
        Drawer,
        Divider;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(
  Widget child, {
  ComponentDefaults? defaults,
  bool still = false,
}) =>
    ConfigProvider(
      defaults: defaults,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: still),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 400, child: child),
            ),
          ),
        ),
      ),
    );

/// Every grey block a skeleton drew, top to bottom.
List<Rect> _blocks(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .where((p) => p.painter.runtimeType.toString() == '_BlockPainter')
    .map((p) => tester.getRect(find.byWidget(p)))
    .toList();

void main() {
  testWidgets('loaded, it is the child and nothing else', (tester) async {
    await tester.pumpWidget(
      _host(const Skeleton(loading: false, child: Text('Ready'))),
    );
    expect(find.text('Ready'), findsOneWidget);
    expect(_blocks(tester), isEmpty);
  });

  group('a skeleton', () {
    testWidgets('is a title and three lines, the last one short', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const Skeleton()));
      final blocks = _blocks(tester);
      expect(blocks, hasLength(4));
      expect(blocks[0].width, closeTo(400 * 0.38, 0.5));
      expect(blocks[0].height, 16);
      expect(blocks[1].top - blocks[0].bottom, 24, reason: 'titleGap');
      expect(blocks[1].width, 400);
      expect(blocks[2].top - blocks[1].bottom, 16, reason: 'paragraphLineGap');
      expect(blocks[3].width, closeTo(400 * 0.61, 0.5));
    });

    testWidgets('beside an avatar: a wider title and two lines', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Skeleton(avatar: SkeletonAvatar())),
      );
      final blocks = _blocks(tester);
      expect(blocks, hasLength(4));
      final avatar = blocks.first;
      expect(avatar.size, const Size(32, 32));
      const text = 400 - 32 - 16;
      expect(blocks[1].left - avatar.right, 16, reason: 'avatarGap');
      expect(blocks[1].width, closeTo(text * 0.5, 0.5));
      expect(blocks[3].width, closeTo(text * 0.61, 0.5));
    });

    testWidgets('takes rows and widths, and leaves out what is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Skeleton(
            title: null,
            paragraph: SkeletonParagraph(rows: 2, widths: [0.5, 0.25]),
          ),
        ),
      );
      final blocks = _blocks(tester);
      expect(blocks.map((b) => b.width), [200, 100]);
    });

    testWidgets('a reader hears "Loading" once, not once a block', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const Skeleton(avatar: SkeletonAvatar())),
      );
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      handle.dispose();
    });
  });

  group('the light', () {
    testWidgets('still unless asked', (tester) async {
      await tester.pumpWidget(_host(const Skeleton()));
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('asked, it sweeps; a block alone sweeps too', (tester) async {
      for (final widget in const <Widget>[
        Skeleton(active: true),
        SkeletonButton(active: true),
      ]) {
        await tester.pumpWidget(_host(widget));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.binding.transientCallbackCount, greaterThan(0),
            reason: '$widget');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('lit, a block keeps its colour where the light is not', (
      tester,
    ) async {
      // A shader's colours are multiplied by the paint's alpha: painted with
      // the block's translucent colour, the moving blocks faded to almost
      // nothing and the light with them.
      Future<int> pixel(bool active) async {
        final key = GlobalKey();
        await tester.pumpWidget(
          _host(
            RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: const Color(0xFFFFFFFF),
                child: Skeleton(active: active, paragraph: null),
              ),
            ),
          ),
        );
        // The very start of a turn: the band is still off to the side.
        await tester.pump(const Duration(milliseconds: 1));
        late int value;
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData();
          const x = 300 * 0.38 ~/ 1 - 4, y = 8;
          value = bytes!.getUint8((y * image.width + x) * 4);
        });
        await tester.pumpWidget(const SizedBox());
        return value;
      }

      final still = await pixel(false);
      expect(still, lessThan(250), reason: 'a block is drawn at all');
      expect(await pixel(true), closeTo(still, 1));
    });

    testWidgets('a subtree can ask for it', (tester) async {
      await tester.pumpWidget(
        _host(
          const Skeleton(),
          defaults: const ComponentDefaults(
            skeleton: SkeletonDefaults(active: true),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('where motion is turned down, it stays still', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const Skeleton(active: true), still: true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('blocks', () {
    Future<Size> sizeOf(WidgetTester tester, Widget block) async {
      await tester.pumpWidget(
        _host(Align(alignment: Alignment.topLeft, child: block)),
      );
      return _blocks(tester).single.size;
    }

    testWidgets('take the sizes of what they stand in for', (tester) async {
      expect(await sizeOf(tester, const SkeletonButton()), const Size(64, 32));
      expect(
        await sizeOf(tester, const SkeletonButton(shape: ButtonShape.circle)),
        const Size(32, 32),
      );
      expect(
        await sizeOf(tester, const SkeletonButton(size: SoftSize.small)),
        const Size(48, 24),
      );
      expect(await sizeOf(tester, const SkeletonInput()), const Size(160, 32));
      expect(
        await sizeOf(tester, const SkeletonAvatar(size: SoftSize.large)),
        const Size(40, 40),
      );
      expect(await sizeOf(tester, const SkeletonImage()), const Size(96, 96));
      expect(
        await sizeOf(
          tester,
          const SkeletonNode(child: SizedBox(width: 120, height: 60)),
        ),
        const Size(120, 60),
      );
    });

    testWidgets('block takes the width', (tester) async {
      await tester.pumpWidget(
        _host(const SkeletonInput(block: true)),
      );
      expect(_blocks(tester).single.width, 400);
    });

    testWidgets('alone, each says it is loading', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const SkeletonImage()));
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      handle.dispose();
    });
  });
}
