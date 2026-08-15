import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/src/utils/popover.dart';

/// The genie's geometry, measured rather than eyeballed.
///
/// The effect is a funnel that stands still — narrow at the trigger, opening
/// out a little way along — with the card flowing through it. What is still in
/// the throat is squeezed; what has left it is whole. Every rule below was a
/// fault first.
void main() {
  const box = Size(200, 100);
  const source = Size(200, 100);

  GenieSheet sheetAt(
    double t,
    PopoverSide side, {
    double mouth = 0.5,
    double mouthWidth = 0.25,
  }) =>
      GenieMesh(side: side).build(
        t: t,
        offset: Offset.zero,
        size: box,
        sourceSize: source,
        mouthCross: mouth,
        mouthWidth: mouthWidth,
      );

  /// Row widths, from the card's mouth edge outwards.
  List<double> widthsAt(
    double t, {
    PopoverSide side = PopoverSide.top,
    double mouthWidth = 0.25,
  }) {
    final sheet = sheetAt(t, side, mouthWidth: mouthWidth);
    return [
      for (var row = 0; row * 2 + 1 < sheet.positions.length; row++)
        (sheet.positions[row * 2 + 1].dx - sheet.positions[row * 2].dx).abs(),
    ];
  }

  test('the card grows out of the trigger', () {
    // A card above its trigger comes up from the bottom: its lower edge is at
    // the trigger throughout, and its far edge climbs.
    double mouthEdge(double t) =>
        sheetAt(t, PopoverSide.top).positions.map((p) => p.dy).reduce(math.max);
    double farEdge(double t) =>
        sheetAt(t, PopoverSide.top).positions.map((p) => p.dy).reduce(math.min);

    for (final t in [0.1, 0.4, 0.8]) {
      expect(
        mouthEdge(t),
        closeTo(box.height, 0.001),
        reason: 'the mouth wandered off at $t',
      );
    }
    expect(farEdge(0.1), greaterThan(farEdge(0.4)));
    expect(farEdge(0.4), greaterThan(farEdge(0.8)));
    expect(farEdge(1), closeTo(0, 0.001));
  });

  test('the funnel is narrow at the trigger and opens outwards', () {
    // Mid-flight the card is a wedge the other way up from a lid: pinched
    // where it leaves the trigger, wider where it has got out.
    final widths = widthsAt(0.5);

    for (var i = 1; i < widths.length; i++) {
      expect(
        widths[i],
        greaterThanOrEqualTo(widths[i - 1] - 0.001),
        reason: 'row $i is narrower than the one before it',
      );
    }
    expect(widths.first, lessThan(box.width / 2));
    expect(widths.last, greaterThan(widths.first * 1.5));

    // The leading edge reaches full width late — it is still widening as it
    // arrives. Letting it out early leaves a wide lid with a spike under it.
    expect(widthsAt(0.5).last, lessThan(box.width * 0.85));
    expect(widthsAt(0.85).last, greaterThan(box.width * 0.9));
  });

  test('width follows where a row is, not which row it is', () {
    // The heart of the effect. Take one row of the card and watch it: it is
    // squeezed while it is in the throat and whole once it has left.
    double widthOfRow(double t, int row) {
      final sheet = sheetAt(t, PopoverSide.top);
      return (sheet.positions[row * 2 + 1].dx - sheet.positions[row * 2].dx)
          .abs();
    }

    const row = 8; // a sixth of the way along the card
    expect(widthOfRow(0.2, row), lessThan(box.width / 2));
    expect(widthOfRow(0.6, row), greaterThan(widthOfRow(0.2, row)));
    expect(widthOfRow(1, row), closeTo(box.width, 0.5));
  });

  test('the throat is as wide as the trigger', () {
    // The card is drawn out of the thing that opened it, not out of a slot of
    // some arbitrary size.
    final narrow = widthsAt(0.25, mouthWidth: 0.1).first;
    final wide = widthsAt(0.25, mouthWidth: 0.5).first;

    expect(narrow, closeTo(box.width * 0.1, 4));
    expect(wide, greaterThan(narrow * 2));
  });

  test('the card is never mirrored, whichever way it grows', () {
    for (final side in PopoverSide.values) {
      final vertical = side == PopoverSide.top || side == PopoverSide.bottom;
      for (final t in [0.2, 0.5, 0.8, 0.99]) {
        final sheet = sheetAt(t, side);

        double positionOf(double texAlong) {
          for (var i = 0; i < sheet.texture.length; i++) {
            final v = vertical
                ? sheet.texture[i].dy / source.height
                : sheet.texture[i].dx / source.width;
            if ((v - texAlong).abs() < 0.02) {
              return vertical ? sheet.positions[i].dy : sheet.positions[i].dx;
            }
          }
          fail('no row showing $texAlong of the card');
        }

        expect(
          positionOf(0),
          lessThan(positionOf(1)),
          reason: '$side at $t is upside down',
        );
      }
    }
  });

  test('the sheet fills its box exactly when it arrives', () {
    // Anything else is a jump at the handover from the picture to the widget.
    for (final side in PopoverSide.values) {
      final sheet = sheetAt(1, side);
      final xs = sheet.positions.map((p) => p.dx);
      final ys = sheet.positions.map((p) => p.dy);
      expect(xs.reduce(math.min), closeTo(0, 0.001), reason: '$side');
      expect(xs.reduce(math.max), closeTo(box.width, 0.001), reason: '$side');
      expect(ys.reduce(math.min), closeTo(0, 0.001), reason: '$side');
      expect(ys.reduce(math.max), closeTo(box.height, 0.001), reason: '$side');
    }
  });

  test('the throat sits under the trigger', () {
    // A card off to one side reaches back towards what opened it: the mouth
    // end is at the trigger, the far end centred on the card.
    double mouthCentre(GenieSheet s) =>
        (s.positions[0].dx + s.positions[1].dx) / 2;

    expect(
      mouthCentre(sheetAt(0.35, PopoverSide.top, mouth: 0.5)),
      closeTo(box.width / 2, 1),
    );
    expect(
      mouthCentre(sheetAt(0.35, PopoverSide.top, mouth: 0.1)),
      lessThan(box.width / 3),
    );
  });

  test('the funnel walls are curves, not a straight taper', () {
    final widths = widthsAt(0.6);
    final steps = [
      for (var i = 1; i < widths.length; i++) widths[i] - widths[i - 1],
    ];

    // A straight taper steps evenly; a curve leaves the throat gently and its
    // steps swell to a single peak.
    final peak = steps.indexOf(steps.reduce(math.max));
    expect(
      steps.first,
      lessThan(steps[peak] / 2),
      reason: 'the wall leaves the throat gently',
    );
    expect(peak, greaterThan(0));
    for (var i = 1; i <= peak; i++) {
      expect(
        steps[i],
        greaterThanOrEqualTo(steps[i - 1] - 0.001),
        reason: 'the wall wavers before its peak at $i',
      );
    }
  });

  test('the shadow is there from the first frames, not poured in with the card',
      () {
    // The sheet fades in over the first part of the pour, but its shadow must
    // not: a shadow that arrives along with what casts it reads as a second
    // card fading in. It is up to weight while the card is still faint.
    expect(GenieMesh.shadowWeight(0), 0);
    expect(
      GenieMesh.shadowWeight(0.1),
      greaterThan(0.6),
      reason: 'a tenth of the way in the shadow is barely showing',
    );
    expect(GenieMesh.shadowWeight(0.2), 1);
    expect(GenieMesh.shadowWeight(1), 1);

    // Against the sheet's own fade at the same moment.
    expect(
      GenieMesh.shadowWeight(0.1),
      greaterThan(GenieMesh.smooth(0.1 * 2.5) * 3),
    );
  });

  test('no frame moves the sheet much more than its neighbours', () {
    // The mesh is a shape at a progress; the pace comes from the curve the
    // popover hands it. Sampling raw progress would measure half the motion,
    // so this walks the clock through the genie's default curve.
    const curve = Curves.easeInOutCubic;
    const frames = 25;
    var worst = 0.0;
    var worstAt = 0.0;
    var last = 0.0;

    for (var i = 1; i <= frames; i++) {
      final before =
          sheetAt(curve.transform((i - 1) / frames), PopoverSide.top);
      final after = sheetAt(curve.transform(i / frames), PopoverSide.top);

      var biggest = 0.0;
      for (var v = 0; v < before.positions.length; v++) {
        biggest = math.max(
          biggest,
          (after.positions[v] - before.positions[v]).distance,
        );
      }
      if (biggest > worst) {
        worst = biggest;
        worstAt = i / frames;
      }
      last = biggest;
    }

    expect(worstAt, greaterThan(0.2), reason: 'busiest frame at $worstAt');
    expect(worstAt, lessThan(0.8), reason: 'busiest frame at $worstAt');
    expect(
      last,
      lessThan(worst / 8),
      reason: 'the last frame moved $last against a worst of $worst',
    );
  });
}
