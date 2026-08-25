import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _wrap(Widget child) => ConfigProvider(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: child),
      ),
    );

void main() {
  _sizeSlot();
  group('Avatar', () {
    testWidgets('renders an icon properly', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Avatar(icon: Text('I')),
        ),
      );

      expect(find.byType(Avatar), findsOneWidget);
    });

    testWidgets('renders a string properly', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Avatar(child: Text('U')),
        ),
      );

      expect(find.text('U'), findsOneWidget);
    });

    testWidgets('renders an image properly', (tester) async {
      const imgProvider = NetworkImage(
        'https://zos.alipayobjects.com/rmsportal/ODTLcjxAfvqbxHnVXCYX.png',
      );

      await tester.pumpWidget(
        _wrap(
          const Avatar(image: imgProvider),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('applies square shape', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Avatar(shape: AvatarShape.square, child: Text('S')),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(Avatar),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.rectangle);
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('handles group rendering correctly', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AvatarGroup(
            children: [
              Avatar(child: Text('1')),
              Avatar(child: Text('2')),
              Avatar(child: Text('3')),
            ],
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('handles group maxCount properly', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AvatarGroup(
            maxCount: 2,
            children: [
              Avatar(child: Text('1')),
              Avatar(child: Text('2')),
              Avatar(child: Text('3')),
              Avatar(child: Text('4')),
            ],
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.text('3'), findsNothing);
      expect(find.text('4'), findsNothing);
    });
  });
}

void _sizeSlot() {
  group('the size slot takes a preset or a diameter', () {
    testWidgets('a preset follows the theme scale', (tester) async {
      await tester.pumpWidget(
        _wrap(const Avatar(size: SoftSize.large, child: Text('A'))),
      );
      final large = tester.getSize(find.byType(Avatar)).width;

      await tester.pumpWidget(
        _wrap(const Avatar(size: SoftSize.small, child: Text('A'))),
      );
      expect(tester.getSize(find.byType(Avatar)).width, lessThan(large));
    });

    testWidgets('a diameter is taken as given', (tester) async {
      await tester.pumpWidget(
        _wrap(const Avatar(size: ControlSize.fixed(56), child: Text('A'))),
      );
      expect(tester.getSize(find.byType(Avatar)).width, 56);
    });

    testWidgets('initials scale with a named diameter', (tester) async {
      await tester.pumpWidget(
        _wrap(const Avatar(size: ControlSize.fixed(80), child: Text('A'))),
      );
      final style = DefaultTextStyle.of(tester.element(find.text('A'))).style;
      expect(style.fontSize, 40, reason: 'half of 80');
    });
  });
}
