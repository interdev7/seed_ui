import 'package:flutter/widgets.dart';

/// One run of a rail: the line that joins the markers of a [Timeline] or a
/// [Steps].
///
/// Positions are measured along the rail's own axis from the start of the box,
/// so a caller works in one dimension and lets [RailPainter] place the cross
/// axis.
@immutable
class RailSegment {
  /// Creates a [RailSegment].
  const RailSegment({
    required this.start,
    required this.end,
    required this.color,
    this.dashed = false,
  });

  /// Where the run begins, along the axis.
  final double start;

  /// Where it ends, or [double.infinity] to run to the far edge — the caller
  /// laying a rail behind a stretched box does not know its own extent.
  final double end;

  /// Colour of this run. Two runs of different colours are what lets a stepper
  /// show its progress: travelled in the accent, ahead of you in the split.
  final Color color;

  /// Draws the run as a dashed line.
  final bool dashed;
}

/// Paints the rail behind a row of markers.
///
/// Shared by [Timeline] and [Steps], which draw the same line for different
/// reasons: one joins events, the other measures progress. Everything above
/// this — where the markers sit, what they mean — each component keeps to
/// itself.
class RailPainter extends CustomPainter {
  /// Creates a [RailPainter].
  const RailPainter({
    required this.axis,
    required this.segments,
    required this.thickness,
    this.startInset = 0,
    this.endInset = 0,
    this.dash = 3,
    this.gap = 4,
    this.minLength = 0,
  });

  /// Which way the rail runs.
  final Axis axis;

  /// The runs to draw, in any order.
  final List<RailSegment> segments;

  /// Stroke width of the line.
  final double thickness;

  /// Keeps the rail clear of the box's own ends: a run never starts before
  /// [startInset] nor reaches past [endInset] from the far edge.
  final double startInset;

  /// Clearance kept at the far end of the run, in logical pixels.
  final double endInset;

  /// Length of a dash and of the space after it, for dashed runs.
  final double dash;

  /// Length of the space after each dash, in logical pixels.
  final double gap;

  /// The shortest the drawn line may be before its own gaps give way.
  ///
  /// A rail is a line with room at its ends; squeezed, it is the room that
  /// should go, not the line — a two-pixel stub between two markers reads as a
  /// speck of dirt rather than a connection. Zero keeps the insets whatever
  /// happens.
  final double minLength;

  @override
  void paint(Canvas canvas, Size size) {
    final vertical = axis == Axis.vertical;

    // The rail sits on the centre line of its own box, whichever way it runs —
    // snapped to the pixel grid. A hairline centred on a whole coordinate
    // straddles two rows of pixels and is drawn as two half-strength lines,
    // which reads as a pale line under a paler one rather than one clean line.
    final crossExtent = vertical ? size.width : size.height;
    final near = ((crossExtent - thickness) / 2).roundToDouble();
    final far = near + thickness;

    final extent = vertical ? size.height : size.width;

    // Where the insets would leave less line than [minLength], they give way
    // together, keeping their proportions, down to nothing.
    var start = startInset;
    var end = endInset;
    final budget = extent - minLength;
    if (minLength > 0 && start + end > budget) {
      final total = start + end;
      final room = budget < 0 ? 0.0 : budget;
      final scale = total == 0 ? 0.0 : room / total;
      start *= scale;
      end *= scale;
    }

    final limit = extent - end;

    for (final segment in segments) {
      final from = segment.start < start ? start : segment.start;
      final to = segment.end > limit ? limit : segment.end;
      if (to <= from) continue;

      final paint = Paint()..color = segment.color;

      // Drawn as a rect rather than a stroked line: a rect's edges are where
      // they are asked to be, so the snapping above actually holds.
      void run(double start, double end) => canvas.drawRect(
            vertical
                ? Rect.fromLTRB(near, start, far, end)
                : Rect.fromLTRB(start, near, end, far),
            paint,
          );

      if (!segment.dashed) {
        run(from, to);
        continue;
      }

      var along = from;
      while (along < to) {
        final dashEnd = (along + dash).clamp(from, to);
        run(along, dashEnd);
        along += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(RailPainter old) =>
      old.axis != axis ||
      old.thickness != thickness ||
      old.startInset != startInset ||
      old.endInset != endInset ||
      old.minLength != minLength ||
      old.dash != dash ||
      old.gap != gap ||
      old.segments.length != segments.length ||
      Iterable<int>.generate(segments.length).any(
        (i) =>
            old.segments[i].start != segments[i].start ||
            old.segments[i].end != segments[i].end ||
            old.segments[i].color != segments[i].color ||
            old.segments[i].dashed != segments[i].dashed,
      );
}

/// The gaps a rail keeps at its ends — one per side, per axis.
///
/// A rail is drawn along one axis at a time, so a run down the page uses [top]
/// and [bottom] while one across it uses [left] and [right]. Setting all four
/// lets the same token serve a component in either orientation.
///
/// A null side is not zero: it means "whatever the component's own default is",
/// so `RailInsets.vertical(top: 0)` opens the bottom gap the component would
/// normally use and closes the top one.
///
/// ```dart
/// const RailInsets.all(16)                    // every end, both axes
/// const RailInsets.vertical(top: 8, bottom: 8)
/// const RailInsets.horizontal(left: 0)        // flush on the left only
/// ```
@immutable
class RailInsets {
  /// Sides given one by one; any left out follows the component's default.
  const RailInsets({this.top, this.bottom, this.left, this.right});

  /// The gaps at the ends of a rail running down the page.
  const RailInsets.vertical({this.top, this.bottom})
      : left = null,
        right = null;

  /// The gaps at the ends of a rail running across the page.
  const RailInsets.horizontal({this.left, this.right})
      : top = null,
        bottom = null;

  /// The same gap at every end, whichever way the rail runs.
  const RailInsets.all(double value)
      : top = value,
        bottom = value,
        left = value,
        right = value;

  /// One value per axis.
  const RailInsets.symmetric({double? vertical, double? horizontal})
      : top = vertical,
        bottom = vertical,
        left = horizontal,
        right = horizontal;

  /// No gaps at all: the rail runs flush into whatever it meets.
  static const RailInsets zero = RailInsets.all(0);

  /// Gap at the top end of a vertical rail.
  final double? top;

  /// Gap at the bottom end of a vertical rail.
  final double? bottom;

  /// Gap at the leading end of a horizontal rail.
  final double? left;

  /// Gap at the trailing end of a horizontal rail.
  final double? right;

  /// The gap where the rail starts, given the component's default for the axis.
  double leading(Axis axis, double fallback) =>
      (axis == Axis.horizontal ? left : top) ?? fallback;

  /// The gap where the rail ends.
  double trailing(Axis axis, double fallback) =>
      (axis == Axis.horizontal ? right : bottom) ?? fallback;

  /// Whether either end of an [axis] asks for a gap of its own.
  bool along(Axis axis) =>
      (axis == Axis.horizontal ? left ?? right : top ?? bottom) != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RailInsets &&
          top == other.top &&
          bottom == other.bottom &&
          left == other.left &&
          right == other.right;

  @override
  int get hashCode => Object.hash(top, bottom, left, right);

  @override
  String toString() => 'RailInsets(top: $top, bottom: $bottom, '
      'left: $left, right: $right)';
}
