import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, KeyEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/size_resolver.dart';
import 'button.dart';

/// Which side of a [FloatButton] its label hangs on.
///
/// [auto] is not a fifth side but a rule, and the rule differs by layout: a
/// label beside a column goes out sideways, a label beside a row goes above,
/// and a label on a fan goes outward along the item's own spoke. See
/// [FloatButtonLayout.labelPlacementFor].
enum FloatButtonLabelPlacement {
  /// Worked out from the layout and from where the group sits on screen.
  auto,

  /// Above the button.
  top,

  /// Below the button.
  bottom,

  /// To the left of the button.
  left,

  /// To the right of the button.
  right,
}

/// What opens a [FloatButtonGroup].
enum FloatButtonTrigger {
  /// A tap on the trigger toggles the group.
  click,

  /// The group opens while the pointer is over it.
  hover,
}

/// Where item `index` of `count` goes, measured from the trigger's centre.
///
/// The signature is deliberately free of sizes and screen geometry: a caller
/// writing one of these knows what it wants, and anything it needs to know
/// about the group it can close over.
typedef FloatButtonPlacer = Offset Function(int index, int count);

/// How a [FloatButtonGroup] spreads its items when it opens.
///
/// A sealed type rather than an enum because the variants do not all carry the
/// same data: a fan has a radius, a sweep and an angle to aim, while a column
/// has none of that. An enum would have to hang those numbers on the group,
/// where they would be silently meaningless for three variants out of five.
///
/// ```dart
/// FloatButtonGroup(
///   layout: const FloatButtonLayout.fan(jitter: 0.2),
///   children: [...],
/// )
/// ```
sealed class FloatButtonLayout {
  const FloatButtonLayout._();

  /// A column. Opens upwards from a group in the lower half of the screen,
  /// downwards from one in the upper half.
  const factory FloatButtonLayout.vertical({double? gap}) =
      FloatButtonLine.vertical;

  /// A row, opening away from the nearer side edge.
  const factory FloatButtonLayout.horizontal({double? gap}) =
      FloatButtonLine.horizontal;

  /// An arc swept around the trigger.
  const factory FloatButtonLayout.fan({
    double? radius,
    double? sweep,
    double? start,
    double jitter,
    int seed,
  }) = FloatButtonFan;

  /// A block of [columns] columns, filling the quadrant away from the corner.
  const factory FloatButtonLayout.grid(int columns, {double? gap}) =
      FloatButtonGrid;

  /// Positions of your own.
  const factory FloatButtonLayout.custom(FloatButtonPlacer place) =
      FloatButtonCustom;

  /// Where item [index] of [count] sits when the group is fully open,
  /// measured from the trigger's centre.
  ///
  /// [item] is the size every item shares — a group sizes its items alike, so
  /// this is one size and not a list. [away] is the unit direction pointing
  /// off the nearest corner of the screen: `(-1, -1)` for a group parked at
  /// the bottom right.
  Offset offsetFor(int index, int count, Size item, Offset away, double gap);

  /// Which side item [index]'s label hangs on under
  /// [FloatButtonLabelPlacement.auto].
  ///
  /// A label may not sit where the next item is about to land, which is why
  /// this is not simply "outward" everywhere: along a column the items are
  /// stacked vertically, so the labels go out sideways instead.
  FloatButtonLabelPlacement labelPlacementFor(
    int index,
    int count,
    Size item,
    Offset away,
    double gap,
  );

  /// Snaps a direction to the side it points at most.
  static FloatButtonLabelPlacement _side(Offset d) => d.dx.abs() >= d.dy.abs()
      ? (d.dx < 0
          ? FloatButtonLabelPlacement.left
          : FloatButtonLabelPlacement.right)
      : (d.dy < 0
          ? FloatButtonLabelPlacement.top
          : FloatButtonLabelPlacement.bottom);
}

/// A straight run of items — [FloatButtonLayout.vertical] or
/// [FloatButtonLayout.horizontal].
///
/// One class for both, because a run is a run: only the axis differs, and
/// splitting it in two would mean writing the same arithmetic twice.
class FloatButtonLine extends FloatButtonLayout {
  /// A column.
  const FloatButtonLine.vertical({this.gap})
      : axis = Axis.vertical,
        super._();

  /// A row.
  const FloatButtonLine.horizontal({this.gap})
      : axis = Axis.horizontal,
        super._();

  /// The axis the run travels along.
  final Axis axis;

  /// Space between items. Null takes the token's.
  final double? gap;

  @override
  Offset offsetFor(int index, int count, Size item, Offset away, double gap) {
    final step =
        (axis == Axis.vertical ? item.height : item.width) + (this.gap ?? gap);
    final travel = step * (index + 1);
    return axis == Axis.vertical
        ? Offset(0, away.dy * travel)
        : Offset(away.dx * travel, 0);
  }

  @override
  FloatButtonLabelPlacement labelPlacementFor(
    int index,
    int count,
    Size item,
    Offset away,
    double gap,
  ) =>
      // Perpendicular to the run: a label above an item in a column would sit
      // on the item above it.
      axis == Axis.vertical
          ? (away.dx < 0
              ? FloatButtonLabelPlacement.left
              : FloatButtonLabelPlacement.right)
          : (away.dy < 0
              ? FloatButtonLabelPlacement.top
              : FloatButtonLabelPlacement.bottom);
}

/// An arc of items swept around the trigger — [FloatButtonLayout.fan].
class FloatButtonFan extends FloatButtonLayout {
  /// Creates a fan.
  const FloatButtonFan({
    this.radius,
    this.sweep,
    this.start,
    this.jitter = 0,
    this.seed = 0,
  })  : assert(jitter >= 0 && jitter <= 1, 'jitter runs from 0 to 1'),
        super._();

  /// Distance from the trigger's centre to each item's centre. Null derives
  /// one from the item size and the gap.
  final double? radius;

  /// How wide the arc opens, in radians. Defaults to a quarter turn, which is
  /// the room a group parked in a corner actually has.
  final double? sweep;

  /// The angle the arc is centred on, in radians, clockwise from three
  /// o'clock. Null aims it away from the nearest corner.
  final double? start;

  /// How far items may stray from their exact place on the arc, from 0 (a
  /// drawn arc) to 1.
  ///
  /// The stray is bounded by half the gap, so items cannot collide however
  /// high this goes, and it is derived from [seed] rather than drawn fresh,
  /// so a group opens the same way twice. A menu whose buttons landed
  /// somewhere new on every open would defeat the muscle memory that makes
  /// a menu worth having — and would take its tests with it.
  final double jitter;

  /// Chooses which scatter [jitter] produces.
  final int seed;

  double _sweep() => sweep ?? math.pi / 2;

  /// The angle between two neighbouring spokes.
  double _step(int count) => count < 2 ? 0 : _sweep() / (count - 1);

  /// Where the items sit before any scatter.
  double _radius(int count, Size item, double gap) {
    if (radius != null) return radius!;
    final clear = item.longestSide + gap;
    final step = _step(count);
    // Far enough out that the chord between neighbours is a whole item plus a
    // gap: the more items share a sweep, the further out they must go.
    final needed = step == 0 ? clear : clear / (2 * math.sin(step / 2));
    return math.max(item.longestSide + gap * 2, needed);
  }

  /// The closest an item may come to the trigger.
  ///
  /// The distance from a point at radius r to its neighbour's spoke is
  /// `r·sin(step)`, so any item at or beyond this radius clears every other
  /// spoke whatever the items on them are doing. That is what lets the scatter
  /// run along the spokes freely: it cannot produce a collision, however far
  /// two items happen to differ.
  double _floor(int count, Size item) {
    final step = _step(count);
    if (step <= 0) return 0;
    // A twentieth of an item of daylight, so "clear" is visibly clear.
    return item.longestSide * 1.05 / math.sin(math.min(step, math.pi / 2));
  }

  double _angle(int index, int count, Offset away) {
    final base = start ?? math.atan2(away.dy, away.dx);
    if (count < 2) return base;
    return base + _sweep() * (index / (count - 1) - 0.5);
  }

  @override
  Offset offsetFor(int index, int count, Size item, Offset away, double gap) {
    final angle = _angle(index, count, away);
    var r = _radius(count, item, gap);
    if (jitter > 0) {
      // Along the spokes rather than across them. Items standing at visibly
      // different distances is what reads as scatter — nudging them sideways
      // by a few degrees does not — and a spoke is the one direction an item
      // can travel without ever nearing its neighbours.
      final reach = jitter * (item.longestSide + gap) * 1.5;
      r = math.max(
        _floor(count, item),
        r + _noise(seed, index, 2) * reach,
      );
    }
    return Offset(math.cos(angle) * r, math.sin(angle) * r);
  }

  @override
  FloatButtonLabelPlacement labelPlacementFor(
    int index,
    int count,
    Size item,
    Offset away,
    double gap,
  ) =>
      // Outward along the item's own spoke, so the labels fan out with the
      // buttons instead of all piling up on one side.
      FloatButtonLayout._side(offsetFor(index, count, item, away, gap));
}

/// A rectangular block of items — [FloatButtonLayout.grid].
class FloatButtonGrid extends FloatButtonLayout {
  /// Creates a grid [columns] wide.
  const FloatButtonGrid(this.columns, {this.gap})
      : assert(columns > 0, 'a grid needs at least one column'),
        super._();

  /// How many items stand side by side before the next row starts.
  final int columns;

  /// Space between items. Null takes the token's.
  final double? gap;

  @override
  Offset offsetFor(int index, int count, Size item, Offset away, double gap) {
    final g = this.gap ?? gap;
    final col = index % columns;
    final row = index ~/ columns;
    return Offset(
      away.dx * (col + 1) * (item.width + g),
      // Rows stand a gap further apart than columns do, because a caption
      // hangs under each item and has to go somewhere.
      away.dy * (row + 1) * (item.height + g * 2),
    );
  }

  @override
  FloatButtonLabelPlacement labelPlacementFor(
    int index,
    int count,
    Size item,
    Offset away,
    double gap,
  ) =>
      // Under the item, in the room [offsetFor] leaves between rows. Sideways
      // would put a caption straight through the item in the next column.
      FloatButtonLabelPlacement.bottom;
}

/// Positions supplied by the caller — [FloatButtonLayout.custom].
class FloatButtonCustom extends FloatButtonLayout {
  /// Creates a custom layout.
  const FloatButtonCustom(this.place) : super._();

  /// Where each item goes, measured from the trigger's centre.
  final FloatButtonPlacer place;

  @override
  Offset offsetFor(int index, int count, Size item, Offset away, double gap) =>
      place(index, count);

  @override
  FloatButtonLabelPlacement labelPlacementFor(
    int index,
    int count,
    Size item,
    Offset away,
    double gap,
  ) =>
      FloatButtonLayout._side(place(index, count));
}

/// Deterministic noise in -1..1 from a seed, an index and a salt.
///
/// A hash rather than a [math.Random]: the same three numbers must give the
/// same answer on every frame, in every process and in every test run, and a
/// generator would have to be rewound to promise that.
double _noise(int seed, int index, int salt) {
  var h = seed * 374761393 + index * 668265263 + salt * 2246822519;
  h = (h ^ (h >> 13)) * 1274126177;
  h = (h ^ (h >> 16)) & 0x7FFFFFFF;
  return (h % 20001) / 10000 - 1;
}

/// Per-component design tokens for [FloatButton] and [FloatButtonGroup].
///
/// Every field is an override; a null one falls back to a value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(floatButton: FloatButtonToken(...)))`, or per instance via
/// [FloatButton.token].
@immutable
class FloatButtonToken {
  /// Creates a [FloatButtonToken].
  const FloatButtonToken({
    this.size,
    this.sizeSM,
    this.sizeLG,
    this.gap,
    this.labelGap,
    this.labelTextColor,
    this.labelFontSize,
    this.borderRadius,
    this.shadow,
    this.motionDuration,
    this.curve,
  });

  /// Diameter of a round button, height of a square one — the standard
  /// preset, and what a button takes when it is given no size at all.
  final double? size;

  /// The compact preset.
  final double? sizeSM;

  /// The roomy preset.
  final double? sizeLG;

  /// Space between two items in a group.
  final double? gap;

  /// Space between a button and its label.
  final double? labelGap;

  /// Colour of a label's text.
  final Color? labelTextColor;

  /// Size of a label's text.
  final double? labelFontSize;

  /// Corner radius of a square button. A round one is always half its size.
  final double? borderRadius;

  /// The shadow that lifts a float button off the page.
  final List<BoxShadow>? shadow;

  /// How long the group takes to open.
  final Duration? motionDuration;

  /// The shape of the opening — how the items accelerate along their way.
  final Curve? curve;

  _ResolvedFloatButtonToken _resolve(Token t) => _ResolvedFloatButtonToken(
        size: size ?? t.controlHeightLG + t.sizeXS,
        sizeSM: sizeSM ?? t.controlHeight + t.sizeXS,
        sizeLG: sizeLG ?? t.controlHeightLG + t.size,
        gap: gap ?? t.sizeSM,
        labelGap: labelGap ?? t.sizeXXS,
        labelTextColor: labelTextColor ?? t.colorText,
        labelFontSize: labelFontSize ?? t.fontSizeSM,
        borderRadius: borderRadius ?? t.borderRadiusLG,
        shadow: shadow ?? t.boxShadowSecondary,
        motionDuration: motionDuration ?? t.motionDurationMid,
        curve: curve ?? t.motionEaseOut,
      );
}

@immutable
class _ResolvedFloatButtonToken {
  const _ResolvedFloatButtonToken({
    required this.size,
    required this.sizeSM,
    required this.sizeLG,
    required this.gap,
    required this.labelGap,
    required this.labelTextColor,
    required this.labelFontSize,
    required this.borderRadius,
    required this.shadow,
    required this.motionDuration,
    required this.curve,
  });

  final double size;
  final double sizeSM;
  final double sizeLG;
  final double gap;
  final double labelGap;
  final Color labelTextColor;
  final double labelFontSize;
  final double borderRadius;
  final List<BoxShadow> shadow;
  final Duration motionDuration;
  final Curve curve;
}

/// Defaults for every [FloatButton] and [FloatButtonGroup] under a
/// `ConfigProvider`.
///
/// Not tokens — those are numbers and colours, and live in
/// [FloatButtonToken]. These are the component's own props, applied wherever
/// an instance does not name one for itself.
@immutable
class FloatButtonDefaults {
  /// Creates a [FloatButtonDefaults].
  const FloatButtonDefaults({
    this.shape,
    this.color,
    this.size,
    this.layout,
    this.trigger,
    this.labelPlacement,
    this.disabled,
    this.dismissible,
    this.closeOnSelect,
  });

  /// Round or square.
  final ButtonShape? shape;

  /// Which palette float buttons draw from.
  final ButtonColor? color;

  /// How big they are — a preset, or a measurement of your own.
  final ControlSize? size;

  /// How groups spread their items.
  final FloatButtonLayout? layout;

  /// What opens a group.
  final FloatButtonTrigger? trigger;

  /// Which side labels hang on.
  final FloatButtonLabelPlacement? labelPlacement;

  /// Whether float buttons are greyed out and deaf to taps.
  final bool? disabled;

  /// Whether a tap on open ground closes a group.
  final bool? dismissible;

  /// Whether tapping an item closes its group.
  final bool? closeOnSelect;

  /// Returns a copy with the given fields replaced.
  FloatButtonDefaults copyWith({
    ButtonShape? shape,
    ButtonColor? color,
    ControlSize? size,
    FloatButtonLayout? layout,
    FloatButtonTrigger? trigger,
    FloatButtonLabelPlacement? labelPlacement,
    bool? disabled,
    bool? dismissible,
    bool? closeOnSelect,
  }) =>
      FloatButtonDefaults(
        shape: shape ?? this.shape,
        color: color ?? this.color,
        size: size ?? this.size,
        layout: layout ?? this.layout,
        trigger: trigger ?? this.trigger,
        labelPlacement: labelPlacement ?? this.labelPlacement,
        disabled: disabled ?? this.disabled,
        dismissible: dismissible ?? this.dismissible,
        closeOnSelect: closeOnSelect ?? this.closeOnSelect,
      );
}

/// A button that floats above the page — the round action button that sits in
/// a corner, alone or at the head of a [FloatButtonGroup].
///
/// It is a [Button] underneath, with its control height pinned and a shadow
/// behind it. That is deliberate: a float button is a button that floats, and
/// growing a second set of fills, hover states and press states beside the
/// first would be two of everything to keep in step.
///
/// ```dart
/// FloatButton(
///   icon: const SearchIcon(),
///   color: ButtonColor.primary,
///   onPressed: _search,
/// )
/// ```
///
/// It renders where you put it — in a [Stack], a `Positioned`, or a
/// `Scaffold.floatingActionButton` slot. Only a group's expansion goes into
/// the overlay, and only while it is open.
class FloatButton extends StatelessWidget {
  /// Creates a [FloatButton].
  const FloatButton({
    super.key,
    this.child,
    this.icon,
    this.label,
    this.onPressed,
    this.color,
    this.shape,
    this.size,
    this.disabled,
    this.labelPlacement,
    this.semanticLabel,
    this.token,
  });

  /// Content of your own, in place of [icon].
  final Widget? child;

  /// The mark on the button.
  final Widget? icon;

  /// A caption hung outside the button, on the side [labelPlacement] names.
  ///
  /// It rides outside the button's own box, so it neither shrinks the mark
  /// nor widens the circle.
  final Widget? label;

  /// Called when the button is tapped. A null handler disables the button.
  final VoidCallback? onPressed;

  /// Which palette the button draws from.
  final ButtonColor? color;

  /// Round (the default) or square.
  final ButtonShape? shape;

  /// How big the button is: a preset from the token's scale, or a measurement
  /// of your own. A circle's height is its diameter, so
  /// `ControlSize.height(64)` reads true here.
  final ControlSize? size;

  /// Greys the button out and blocks taps.
  final bool? disabled;

  /// Which side [label] hangs on. Null asks the group, which works it out
  /// from its layout; a button standing alone falls back to the left.
  final FloatButtonLabelPlacement? labelPlacement;

  /// What a screen reader announces. Falls back to nothing, so give one to
  /// any button whose mark is an icon alone.
  final String? semanticLabel;

  /// Per-instance token overrides.
  final FloatButtonToken? token;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final defaults = ConfigProvider.defaultsOf<FloatButtonDefaults>(context);
    final r = (token ??
            ConfigProvider.componentOf<FloatButtonToken>(context) ??
            const FloatButtonToken())
        ._resolve(t);

    final buttonShape = shape ?? defaults?.shape ?? ButtonShape.circle;
    final diameter =
        (size ?? defaults?.size ?? ConfigProvider.componentSizeOf(context))
                ?.resolve1D(small: r.sizeSM, middle: r.size, large: r.sizeLG) ??
            r.size;
    final radius =
        buttonShape == ButtonShape.circle ? diameter / 2 : r.borderRadius;

    // Pinned to one number so the shadow behind the button and the button's
    // own corners cannot disagree.
    final pinned = ButtonToken(
      controlHeight: diameter,
      controlHeightSM: diameter,
      controlHeightLG: diameter,
      borderRadius: radius,
      borderRadiusSM: radius,
      borderRadiusLG: radius,
    );

    Widget button = SizedBox(
      width: child == null ? diameter : null,
      height: diameter,
      child: Button(
        shape: buttonShape,
        variant: ButtonVariant.solid,
        color: color ?? defaults?.color ?? ButtonColor.defaultColor,
        disabled: disabled ?? defaults?.disabled,
        icon: icon,
        onPressed: onPressed,
        token: pinned,
        child: child,
      ),
    );

    button = DecoratedBox(
      // Behind the button, not around it: a shadow drawn on top would darken
      // the fill it is meant to lift.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: r.shadow,
      ),
      child: button,
    );

    if (label != null) {
      button = _Labelled(
        placement: labelPlacement ??
            defaults?.labelPlacement ??
            FloatButtonLabelPlacement.left,
        size: diameter,
        token: r,
        themeToken: t,
        label: label!,
        child: button,
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: button,
    );
  }
}

/// A button with its caption hung outside its own box.
class _Labelled extends StatelessWidget {
  const _Labelled({
    required this.placement,
    required this.size,
    required this.token,
    required this.themeToken,
    required this.label,
    required this.child,
  });

  final FloatButtonLabelPlacement placement;
  final double size;
  final _ResolvedFloatButtonToken token;
  final Token themeToken;
  final Widget label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The kit dresses the text and stops there. A caption that needs a plate
    // behind it to stay legible is a caption wrapped in one by its caller —
    // which is the whole point of [FloatButton.label] being a widget.
    final chip = DefaultTextStyle(
      style: TextStyle(
        color: token.labelTextColor,
        fontSize: token.labelFontSize,
        fontFamily: themeToken.fontFamily,
        fontFamilyFallback: themeToken.fontFamilyFallback,
        fontWeight: themeToken.fontWeight,
        decoration: TextDecoration.none,
        height: 1,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      maxLines: 1,
      softWrap: false,
      child: label,
    );

    // The chip is aligned to the edge it should leave from and then pushed
    // clear of the button. An OverflowBox is what lets it measure itself
    // freely: the box it sits in is the button's, and a caption is nearly
    // always wider than that.
    final (Alignment from, Offset by) = switch (placement) {
      FloatButtonLabelPlacement.left || FloatButtonLabelPlacement.auto => (
          Alignment.centerRight,
          Offset(-(size + token.labelGap), 0)
        ),
      FloatButtonLabelPlacement.right => (
          Alignment.centerLeft,
          Offset(size + token.labelGap, 0),
        ),
      FloatButtonLabelPlacement.top => (
          Alignment.bottomCenter,
          Offset(0, -(size + token.labelGap)),
        ),
      FloatButtonLabelPlacement.bottom => (
          Alignment.topCenter,
          Offset(0, size + token.labelGap),
        ),
    };

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Transform.translate(
              offset: by,
              child: OverflowBox(
                alignment: from,
                // The minimums matter as much as the maximums here. Left
                // unset they are inherited from the box this fills — the
                // button's — and a caption shorter than the button would be
                // stretched out to it, padding the text away from the button
                // it names and giving it a footprint that overlaps the item
                // next door.
                minWidth: 0,
                minHeight: 0,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: chip,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One action inside a [FloatButtonGroup].
///
/// Data, not a widget. The group has to size and place its items to lay them
/// out at all, and a plain object is also the safer home for something held
/// outside a build — a widget kept in a field can close over a context that
/// has since gone stale.
///
/// [T] is whatever you use to tell one action from another. An enum makes the
/// `switch` in [FloatButtonGroup.onItemTap] exhaustive, so a forgotten case is
/// a compile error rather than a silent nothing.
@immutable
class FloatButtonItem<T> {
  /// Creates a [FloatButtonItem].
  const FloatButtonItem({
    this.key,
    this.value,
    this.label,
    this.icon,
    this.child,
    this.color,
    this.disabled,
    this.onTap,
  });

  /// A key fastened to this item in the widget tree.
  ///
  /// This is the tree's kind of identity, not the group's: a `GlobalKey` here
  /// lets a `Tour` step aim at the item. Note that items exist only while the
  /// group is open, so a tour has to open the group before it can point at
  /// one — [FloatButtonController] is how.
  final Key? key;

  /// What this item reports through [FloatButtonGroup.onItemTap].
  final T? value;

  /// The caption hung beside the button.
  ///
  /// A string rather than a widget: an item is data. Wrap the whole item
  /// through [FloatButtonGroup.itemBuilder] when it needs to be more.
  final String? label;

  /// The mark on the button.
  final Widget? icon;

  /// Content of your own, in place of [icon].
  final Widget? child;

  /// Which palette this item draws from, where it differs from the group's —
  /// a destructive action asking to be red among neutral ones.
  final ButtonColor? color;

  /// Greys this item out and blocks taps.
  final bool? disabled;

  /// Called when this item is tapped. [FloatButtonGroup.onItemTap] fires too.
  final VoidCallback? onTap;
}

/// Wraps one built item, e.g. to put it in a `Tooltip` or a `Badge`.
///
/// The [child] is the finished float button; return it inside whatever you
/// like. A wrapper that changes the item's size is worth knowing about: the
/// layout spaces items by the size in the token, so something much larger will
/// crowd its neighbours.
typedef FloatButtonItemBuilder<T> = Widget Function(
  BuildContext context,
  FloatButtonItem<T> item,
  Widget child,
);

/// Opens and closes a [FloatButtonGroup] from outside the build.
///
/// Reach for this when the group has to answer to something that is not a
/// widget — a tour step that needs the items on screen before it can point at
/// one, or a business event that should put the menu away.
///
/// ```dart
/// final fab = FloatButtonController();
/// ...
/// FloatButtonGroup(controller: fab, items: items)
/// ...
/// fab.open();
/// ```
///
/// A group takes either this or [FloatButtonGroup.open], never both: two
/// owners of one truth is a bug that surfaces late.
class FloatButtonController extends ChangeNotifier {
  /// Creates a [FloatButtonController].
  FloatButtonController({bool open = false}) : _open = open;

  bool _open;

  /// Whether the group is open.
  bool get isOpen => _open;

  /// Spreads the items.
  void open() {
    if (_open) return;
    _open = true;
    notifyListeners();
  }

  /// Folds them away.
  void close() {
    if (!_open) return;
    _open = false;
    notifyListeners();
  }

  /// Opens a closed group, closes an open one.
  void toggle() => _open ? close() : open();
}

/// A [FloatButton] that opens into several.
///
/// The trigger renders where you put it. The items are painted into the
/// nearest [Overlay] while the group is open, which is what lets a fan reach
/// past whatever the trigger is sitting in, and lets a label hang off the
/// side without being clipped.
///
/// ```dart
/// FloatButtonGroup<UserAction>(
///   layout: const FloatButtonLayout.fan(),
///   items: const [
///     FloatButtonItem(value: UserAction.upload, label: 'Upload'),
///     FloatButtonItem(value: UserAction.remove, label: 'Delete'),
///   ],
///   onItemTap: (value) => handle(value),
/// )
/// ```
///
/// The direction the items travel is read off the trigger's place on screen:
/// a group parked at the bottom right opens up and to the left. Nothing needs
/// to be told twice.
class FloatButtonGroup<T> extends StatefulWidget {
  /// Creates a [FloatButtonGroup].
  const FloatButtonGroup({
    super.key,
    required this.items,
    this.layout,
    this.icon,
    this.color,
    this.shape,
    this.size,
    this.trigger,
    this.controller,
    this.open,
    this.onOpenChange,
    this.onItemTap,
    this.itemBuilder,
    this.dismissible,
    this.closeOnSelect,
    this.labelPlacement,
    this.semanticLabel,
    this.token,
  }) : assert(
          controller == null || open == null,
          'Give a FloatButtonGroup a controller or an open flag, not both: '
          'two owners of one truth disagree sooner or later.',
        );

  /// The actions, in the order they spread.
  final List<FloatButtonItem<T>> items;

  /// How the items spread. Defaults to a column.
  final FloatButtonLayout? layout;

  /// The mark on the trigger. Defaults to a plus that turns into a cross.
  final Widget? icon;

  /// Which palette the trigger and its items draw from. An item may differ.
  final ButtonColor? color;

  /// Round (the default) or square, for the whole group.
  final ButtonShape? shape;

  /// How big the trigger and its items are. A group sizes them alike, which
  /// is what lets it space them.
  final ControlSize? size;

  /// What opens the group. Defaults to a tap.
  final FloatButtonTrigger? trigger;

  /// Drives the group from outside the build. Excludes [open].
  final FloatButtonController? controller;

  /// Drives the group from the widget tree. Excludes [controller].
  final bool? open;

  /// Called whenever the group wants to open or close.
  final ValueChanged<bool>? onOpenChange;

  /// Called with the tapped item's [FloatButtonItem.value].
  final ValueChanged<T?>? onItemTap;

  /// Wraps each built item — a `Tooltip`, a `Badge`, anything.
  final FloatButtonItemBuilder<T>? itemBuilder;

  /// Whether a tap on open ground closes the group. Defaults to yes.
  ///
  /// Escape closes it either way. A menu with no way out from the keyboard is
  /// a trap, and no setting should be able to make one.
  final bool? dismissible;

  /// Whether tapping an item closes the group. Defaults to yes.
  final bool? closeOnSelect;

  /// Which side the items' labels hang on. Null lets the layout decide.
  final FloatButtonLabelPlacement? labelPlacement;

  /// What a screen reader announces for the trigger.
  final String? semanticLabel;

  /// Per-instance token overrides.
  final FloatButtonToken? token;

  @override
  State<FloatButtonGroup<T>> createState() => _FloatButtonGroupState<T>();
}

class _FloatButtonGroupState<T> extends State<FloatButtonGroup<T>>
    with SingleTickerProviderStateMixin {
  final GlobalKey _triggerKey = GlobalKey();
  AnimationController? _controller;
  OverlayEntry? _entry;
  bool _openSelf = false;
  Timer? _hoverClose;
  ScrollPosition? _scrolled;
  VoidCallback? _scrollListener;
  bool _remeasuring = false;

  /// Where the trigger's centre sits in the overlay, and which way is away
  /// from the nearest corner.
  Offset _origin = Offset.zero;
  Offset _away = const Offset(-1, -1);

  bool get _isOpen => widget.controller?.isOpen ?? widget.open ?? _openSelf;

  /// Whether the group settles its own state, or reports and waits.
  bool get _governed => widget.controller != null || widget.open != null;

  FloatButtonDefaults? get _defaults =>
      ConfigProvider.defaultsOf<FloatButtonDefaults>(context);

  FloatButtonLayout get _layout =>
      widget.layout ?? _defaults?.layout ?? const FloatButtonLayout.vertical();

  FloatButtonTrigger get _trigger =>
      widget.trigger ?? _defaults?.trigger ?? FloatButtonTrigger.click;

  bool get _dismissible => widget.dismissible ?? _defaults?.dismissible ?? true;

  bool get _closeOnSelect =>
      widget.closeOnSelect ?? _defaults?.closeOnSelect ?? true;

  void _cancelClose() {
    _hoverClose?.cancel();
    _hoverClose = null;
  }

  void _scheduleClose() {
    _cancelClose();
    _hoverClose = Timer(const Duration(milliseconds: 120), () {
      if (mounted) _ask(false);
    });
  }

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_obeyController);
    if (_isOpen) {
      // Born open. There is no previous state for didUpdateWidget to compare
      // against, so without this the overlay would wait for a tap that the
      // caller has already said is unnecessary.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _apply(true);
      });
    }
  }

  @override
  void didUpdateWidget(FloatButtonGroup<T> old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      old.controller?.removeListener(_obeyController);
      widget.controller?.addListener(_obeyController);
    }
    if (widget.open != null && widget.open != old.open) {
      // didUpdateWidget runs inside a build, and an overlay entry may not be
      // mounted while the framework has the tree locked.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _apply(widget.open!);
      });
    } else if (_entry != null) {
      // Deferred for the same reason the line above is: didUpdateWidget runs
      // inside a build, and an overlay entry may not be marked dirty while
      // the framework has the tree locked. A page that rebuilds under an open
      // group — reporting which item was tapped, say — comes through here.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _entry?.markNeedsBuild();
      });
    }
  }

  void _obeyController() {
    if (!mounted) return;
    setState(() {});
    _apply(widget.controller!.isOpen);
  }

  @override
  void dispose() {
    _cancelClose();
    _unwatchScroll();
    HardwareKeyboard.instance.removeHandler(_onKey);
    widget.controller?.removeListener(_obeyController);
    _entry?.remove();
    _entry = null;
    _controller?.dispose();
    super.dispose();
  }

  void _ask(bool next) {
    if (next == _isOpen) return;
    widget.onOpenChange?.call(next);
    if (widget.controller != null) {
      next ? widget.controller!.open() : widget.controller!.close();
      return;
    }
    // A group with an owner reports and waits, so that the owner stays the
    // single account of whether it is open.
    if (_governed) return;
    setState(() => _openSelf = next);
    _apply(next);
  }

  void _apply(bool next) {
    if (next) {
      _measure();
      _controller ??= AnimationController(
        vsync: this,
        duration: _resolved().motionDuration,
      );
      if (_entry == null) {
        _entry = OverlayEntry(builder: _buildLayer);
        Overlay.of(context).insert(_entry!);
      }
      _watchScroll();
      HardwareKeyboard.instance.addHandler(_onKey);
      _controller!.forward();
    } else {
      _unwatchScroll();
      HardwareKeyboard.instance.removeHandler(_onKey);
      _controller?.reverse().whenComplete(() {
        if (!mounted) return;
        // A second opening may have overtaken this closing.
        if (_controller?.value == 0) {
          _entry?.remove();
          _entry = null;
        }
      });
    }
  }

  _ResolvedFloatButtonToken _resolved() => (widget.token ??
          ConfigProvider.componentOf<FloatButtonToken>(context) ??
          const FloatButtonToken())
      ._resolve(context.softToken);

  /// The size every item shares — what the layout spaces them by.
  double _itemSize(_ResolvedFloatButtonToken r) =>
      (widget.size ??
              _defaults?.size ??
              ConfigProvider.componentSizeOf(context))
          ?.resolve1D(small: r.sizeSM, middle: r.size, large: r.sizeLG) ??
      r.size;

  /// Closes the group on Escape, whatever [FloatButtonGroup.dismissible] says.
  ///
  /// Read straight off the keyboard rather than through a focus node: the
  /// layer lives in an overlay and never takes focus from the route that owns
  /// it, so a `Focus` here would hear nothing. A menu with no way out from the
  /// keyboard is a trap, and no setting may make one.
  bool _onKey(KeyEvent event) {
    if (!_isOpen ||
        event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    _ask(false);
    return true;
  }

  /// Follows the page when it scrolls under an open group.
  ///
  /// The geometry is read once per opening, so something has to answer a
  /// scroll. Closing would be the cheap answer, and it is the wrong one: a
  /// group told `dismissible: false` may not close itself. So it re-aims.
  void _watchScroll() {
    _unwatchScroll();
    final position = Scrollable.maybeOf(context)?.position;
    if (position == null) return;
    _scrolled = position;
    _scrollListener = () {
      if (_entry == null || _remeasuring) return;
      // A scroll notification arrives before the frame it belongs to has been
      // laid out, so measuring here would read the position the trigger is
      // leaving rather than the one it is going to. Wait for the frame.
      _remeasuring = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _remeasuring = false;
        if (!mounted || _entry == null) return;
        _measure();
        _entry!.markNeedsBuild();
      });
    };
    position.addListener(_scrollListener!);
  }

  void _unwatchScroll() {
    if (_scrollListener != null) {
      _scrolled?.removeListener(_scrollListener!);
      _scrollListener = null;
      _scrolled = null;
    }
  }

  /// How far the open items reach from the trigger, on each axis.
  ///
  /// Measured with a direction of `(1, 1)`, since every layout mirrors its
  /// offsets about the trigger and only the sign changes.
  Offset _reach(FloatButtonLayout layout, int count, Size item, double gap) {
    var dx = 0.0;
    var dy = 0.0;
    for (var i = 0; i < count; i++) {
      final at = layout.offsetFor(i, count, item, const Offset(1, 1), gap);
      dx = math.max(dx, at.dx.abs());
      dy = math.max(dy, at.dy.abs());
    }
    return Offset(dx + item.width / 2, dy + item.height / 2);
  }

  void _measure() {
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlayBox == null || !box.hasSize) return;
    final rect =
        box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
    final screen = overlayBox.size;
    _origin = rect.center;

    final r = _resolved();
    final need = _reach(
      _layout,
      widget.items.length,
      Size.square(_itemSize(r)),
      r.gap,
    );

    // Up and to the left, which is where a button parked in the usual corner
    // has to go — but only where the items actually fit. Half of the screen is
    // the wrong question: a group a third of the way down has plenty of room
    // above it and no reason to open away from the reach it needs.
    _away = Offset(
      rect.left >= need.dx || rect.left >= screen.width - rect.right ? -1 : 1,
      rect.top >= need.dy || rect.top >= screen.height - rect.bottom ? -1 : 1,
    );
  }

  void _tapped(FloatButtonItem<T> item) {
    item.onTap?.call();
    widget.onItemTap?.call(item.value);
    // A group folds itself away once one of its actions has been taken;
    // leaving it open would hide the result of the very thing just tapped.
    if (_closeOnSelect) _ask(false);
  }

  Widget _buildItem(
    FloatButtonItem<T> item,
    FloatButtonLabelPlacement placement,
  ) {
    Widget built = FloatButton(
      icon: item.icon,
      size: widget.size,
      label: item.label == null ? null : Text(item.label!),
      labelPlacement: placement,
      color: item.color ?? widget.color,
      shape: widget.shape,
      disabled: item.disabled,
      semanticLabel: item.label,
      token: widget.token,
      onPressed: () => _tapped(item),
      child: item.child,
    );
    if (widget.itemBuilder != null) {
      built = widget.itemBuilder!(context, item, built);
    }
    // Outermost, so a Tour aiming at this key sees the whole item.
    return item.key == null ? built : KeyedSubtree(key: item.key, child: built);
  }

  Widget _buildLayer(BuildContext overlayContext) {
    final r = _resolved();
    final layout = _layout;
    final count = widget.items.length;
    final item = Size.square(_itemSize(r));
    final asked = widget.labelPlacement ??
        _defaults?.labelPlacement ??
        FloatButtonLabelPlacement.auto;

    final children = <Widget>[
      for (var i = 0; i < count; i++)
        Builder(
          builder: (_) {
            final built = _buildItem(
              widget.items[i],
              asked == FloatButtonLabelPlacement.auto
                  ? layout.labelPlacementFor(i, count, item, _away, r.gap)
                  : asked,
            );
            return _trigger == FloatButtonTrigger.hover
                ? MouseRegion(
                    // The pointer has to cross open ground to reach an item,
                    // so leaving the trigger only *schedules* a close;
                    // arriving anywhere in the group calls it off.
                    onEnter: (_) => _cancelClose(),
                    onExit: (_) => _scheduleClose(),
                    child: built,
                  )
                : built;
          },
        ),
    ];

    final flow = Flow(
      clipBehavior: Clip.none,
      delegate: _FloatFlowDelegate(
        progress: _controller!,
        layout: layout,
        origin: _origin,
        away: _away,
        item: item,
        gap: r.gap,
        curve: r.curve,
      ),
      children: children,
    );

    return Stack(
      children: [
        if (_trigger == FloatButtonTrigger.click && _dismissible)
          Positioned.fill(
            // Translucent, so the page underneath keeps working while the
            // group is open: it still scrolls, and its buttons still answer.
            // An opaque sheet would put the page out of reach for as long as
            // the menu is up, which is not a trade a float button may make.
            // The items are above this in the stack, so a tap on one reaches
            // the item and never gets here.
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _ask(false),
            ),
          ),
        Positioned.fill(child: flow),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final trigger = FloatButton(
      key: _triggerKey,
      color: widget.color,
      shape: widget.shape,
      size: widget.size,
      token: widget.token,
      semanticLabel: widget.semanticLabel,
      onPressed: () => _ask(!_isOpen),
      icon: widget.icon ??
          Builder(
            // Inside the button, so IconTheme carries the foreground the
            // button settled on. A plus turned an eighth of a turn is a
            // cross, which saves carrying a second icon for the open state.
            builder: (context) {
              final theme = IconTheme.of(context);
              final size = theme.size ?? 16;
              return AnimatedBuilder(
                animation: _controller ?? kAlwaysDismissedAnimation,
                builder: (_, __) => Transform.rotate(
                  angle: (_controller?.value ?? 0) * math.pi / 4,
                  child: CustomPaint(
                    size: Size.square(size),
                    painter:
                        PlusPainter(theme.color ?? const Color(0xFF000000)),
                  ),
                ),
              );
            },
          ),
    );

    if (_trigger == FloatButtonTrigger.hover) {
      return MouseRegion(
        onEnter: (_) {
          _cancelClose();
          _ask(true);
        },
        onExit: (_) => _scheduleClose(),
        child: trigger,
      );
    }
    return trigger;
  }
}

/// Places the items of an open group.
///
/// Positions live here rather than in the widget tree because [Flow] settles
/// them during paint: a frame of the opening animation moves every item
/// without laying anything out again.
class _FloatFlowDelegate extends FlowDelegate {
  _FloatFlowDelegate({
    required this.progress,
    required this.layout,
    required this.origin,
    required this.away,
    required this.item,
    required this.gap,
    required this.curve,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final FloatButtonLayout layout;
  final Offset origin;
  final Offset away;
  final Size item;
  final double gap;
  final Curve curve;

  /// How much of the run is spent staggering the items in.
  static const double _stagger = 0.35;

  double _progressFor(int index, int count) {
    if (count < 2) return curve.transform(progress.value.clamp(0, 1));
    final start = _stagger * index / (count - 1);
    final t = ((progress.value - start) / (1 - _stagger)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      // The flow fills the overlay, and its own constraints would make every
      // item the size of the screen.
      BoxConstraints.loose(constraints.biggest);

  @override
  void paintChildren(FlowPaintingContext context) {
    final count = context.childCount;
    for (var i = 0; i < count; i++) {
      final t = _progressFor(i, count);
      final target = layout.offsetFor(i, count, item, away, gap);
      final at = origin + target * t;
      final size = context.getChildSize(i) ?? item;
      // Items grow out of the trigger rather than appearing at full size.
      final scale = 0.4 + 0.6 * t;
      final transform = Matrix4.identity()
        ..translateByDouble(at.dx, at.dy, 0, 1)
        ..scaleByDouble(scale, scale, 1, 1)
        ..translateByDouble(-size.width / 2, -size.height / 2, 0, 1);
      context.paintChild(i, transform: transform, opacity: t);
    }
  }

  @override
  bool shouldRelayout(_FloatFlowDelegate old) => item != old.item;

  @override
  bool shouldRepaint(_FloatFlowDelegate old) =>
      layout != old.layout ||
      origin != old.origin ||
      away != old.away ||
      gap != old.gap ||
      curve != old.curve ||
      progress != old.progress;
}
