import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
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

  double _radius(Size item, double gap) => radius ?? item.longestSide + gap * 2;

  double _sweep(int count) => sweep ?? math.pi / 2;

  double _angle(int index, int count, Offset away) {
    final base = start ?? math.atan2(away.dy, away.dx);
    if (count < 2) return base;
    final s = _sweep(count);
    return base + s * (index / (count - 1) - 0.5);
  }

  @override
  Offset offsetFor(int index, int count, Size item, Offset away, double gap) {
    var angle = _angle(index, count, away);
    var r = _radius(item, gap);
    if (jitter > 0) {
      // Bounded by half the gap on each axis, so however wild the scatter, two
      // items still cannot meet.
      final room = gap / 2 * jitter;
      angle += _noise(seed, index, 1) * (room / math.max(r, 1));
      r += _noise(seed, index, 2) * room;
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
      away.dy * (row + 1) * (item.height + g),
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
      // The block grows into one quadrant, so every label goes the same way
      // out of it — sideways, where a neighbour is not about to land.
      away.dx < 0
          ? FloatButtonLabelPlacement.left
          : FloatButtonLabelPlacement.right;
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
    this.gap,
    this.labelGap,
    this.labelPadding,
    this.labelBackgroundColor,
    this.labelTextColor,
    this.labelFontSize,
    this.labelBorderRadius,
    this.borderRadius,
    this.shadow,
    this.motionDuration,
  });

  /// Diameter of a round button, height of a square one.
  final double? size;

  /// Space between two items in a group.
  final double? gap;

  /// Space between a button and its label.
  final double? labelGap;

  /// Padding inside a label's chip.
  final EdgeInsetsGeometry? labelPadding;

  /// Fill behind a label.
  final Color? labelBackgroundColor;

  /// Colour of a label's text.
  final Color? labelTextColor;

  /// Size of a label's text.
  final double? labelFontSize;

  /// Corner radius of a label's chip.
  final double? labelBorderRadius;

  /// Corner radius of a square button. A round one is always half its size.
  final double? borderRadius;

  /// The shadow that lifts a float button off the page.
  final List<BoxShadow>? shadow;

  /// How long the group takes to open.
  final Duration? motionDuration;

  _ResolvedFloatButtonToken _resolve(Token t) => _ResolvedFloatButtonToken(
        size: size ?? t.controlHeightLG + t.sizeXS,
        gap: gap ?? t.sizeSM,
        labelGap: labelGap ?? t.sizeXS,
        labelPadding: labelPadding ??
            EdgeInsets.symmetric(horizontal: t.sizeXS, vertical: t.sizeXXS),
        labelBackgroundColor: labelBackgroundColor ?? t.colorBgElevated,
        labelTextColor: labelTextColor ?? t.colorText,
        labelFontSize: labelFontSize ?? t.fontSizeSM,
        labelBorderRadius: labelBorderRadius ?? t.borderRadius,
        borderRadius: borderRadius ?? t.borderRadiusLG,
        shadow: shadow ?? t.boxShadowSecondary,
        motionDuration: motionDuration ?? t.motionDurationMid,
      );
}

@immutable
class _ResolvedFloatButtonToken {
  const _ResolvedFloatButtonToken({
    required this.size,
    required this.gap,
    required this.labelGap,
    required this.labelPadding,
    required this.labelBackgroundColor,
    required this.labelTextColor,
    required this.labelFontSize,
    required this.labelBorderRadius,
    required this.borderRadius,
    required this.shadow,
    required this.motionDuration,
  });

  final double size;
  final double gap;
  final double labelGap;
  final EdgeInsetsGeometry labelPadding;
  final Color labelBackgroundColor;
  final Color labelTextColor;
  final double labelFontSize;
  final double labelBorderRadius;
  final double borderRadius;
  final List<BoxShadow> shadow;
  final Duration motionDuration;
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
    this.layout,
    this.trigger,
    this.labelPlacement,
    this.disabled,
  });

  /// Round or square.
  final ButtonShape? shape;

  /// Which palette float buttons draw from.
  final ButtonColor? color;

  /// How groups spread their items.
  final FloatButtonLayout? layout;

  /// What opens a group.
  final FloatButtonTrigger? trigger;

  /// Which side labels hang on.
  final FloatButtonLabelPlacement? labelPlacement;

  /// Whether float buttons are greyed out and deaf to taps.
  final bool? disabled;

  /// Returns a copy with the given fields replaced.
  FloatButtonDefaults copyWith({
    ButtonShape? shape,
    ButtonColor? color,
    FloatButtonLayout? layout,
    FloatButtonTrigger? trigger,
    FloatButtonLabelPlacement? labelPlacement,
    bool? disabled,
  }) =>
      FloatButtonDefaults(
        shape: shape ?? this.shape,
        color: color ?? this.color,
        layout: layout ?? this.layout,
        trigger: trigger ?? this.trigger,
        labelPlacement: labelPlacement ?? this.labelPlacement,
        disabled: disabled ?? this.disabled,
      );
}

/// What a [FloatButtonGroup] tells the items inside it.
///
/// An inherited widget rather than a look at the child's type, so that a
/// button wrapped in a `Badge` or a `Tooltip` is still an item of the group.
class _FloatItemScope extends InheritedWidget {
  const _FloatItemScope({
    required this.labelPlacement,
    required this.token,
    required this.close,
    required super.child,
  });

  final FloatButtonLabelPlacement labelPlacement;
  final FloatButtonToken? token;
  final VoidCallback close;

  static _FloatItemScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FloatItemScope>();

  @override
  bool updateShouldNotify(_FloatItemScope old) =>
      labelPlacement != old.labelPlacement || token != old.token;
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
    final scope = _FloatItemScope.maybeOf(context);
    final defaults = ConfigProvider.defaultsOf<FloatButtonDefaults>(context);
    final r = (token ??
            scope?.token ??
            ConfigProvider.componentOf<FloatButtonToken>(context) ??
            const FloatButtonToken())
        ._resolve(t);

    final buttonShape = shape ?? defaults?.shape ?? ButtonShape.circle;
    final radius =
        buttonShape == ButtonShape.circle ? r.size / 2 : r.borderRadius;

    // Pinned to one number so the shadow behind the button and the button's
    // own corners cannot disagree.
    final pinned = ButtonToken(
      controlHeight: r.size,
      controlHeightSM: r.size,
      controlHeightLG: r.size,
      borderRadius: radius,
      borderRadiusSM: radius,
      borderRadiusLG: radius,
    );

    final close = scope?.close;
    final handler = onPressed == null
        ? null
        : () {
            onPressed!();
            // A group folds itself away once one of its actions has been
            // taken; leaving it open would hide the result of the very thing
            // just tapped.
            close?.call();
          };

    Widget button = SizedBox(
      width: child == null ? r.size : null,
      height: r.size,
      child: Button(
        shape: buttonShape,
        variant: ButtonVariant.solid,
        color: color ?? defaults?.color ?? ButtonColor.defaultColor,
        disabled: disabled ?? defaults?.disabled,
        icon: icon,
        onPressed: handler,
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
            scope?.labelPlacement ??
            defaults?.labelPlacement ??
            FloatButtonLabelPlacement.left,
        size: r.size,
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
    final chip = Container(
      padding: token.labelPadding,
      decoration: BoxDecoration(
        color: token.labelBackgroundColor,
        borderRadius: BorderRadius.circular(token.labelBorderRadius),
        boxShadow: token.shadow,
      ),
      child: DefaultTextStyle(
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
      ),
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

/// A [FloatButton] that opens into several.
///
/// The trigger renders where you put it. The items are painted into the
/// nearest [Overlay] while the group is open, which is what lets a fan reach
/// past whatever the trigger is sitting in, and lets a label hang off the
/// side without being clipped.
///
/// ```dart
/// FloatButtonGroup(
///   layout: const FloatButtonLayout.fan(),
///   children: [
///     FloatButton(icon: const SearchIcon(), label: const Text('Search')),
///     FloatButton(icon: const UserIcon(), label: const Text('Profile')),
///   ],
/// )
/// ```
///
/// The direction the items travel is read off the trigger's place on screen:
/// a group parked at the bottom right opens up and to the left. Nothing needs
/// to be told twice.
class FloatButtonGroup extends StatefulWidget {
  /// Creates a [FloatButtonGroup].
  const FloatButtonGroup({
    super.key,
    required this.children,
    this.layout,
    this.icon,
    this.color,
    this.shape,
    this.trigger,
    this.open,
    this.onOpenChange,
    this.labelPlacement,
    this.semanticLabel,
    this.token,
  });

  /// The items, in the order they spread.
  ///
  /// A [Widget] rather than a [FloatButton] on purpose: a button wrapped in a
  /// `Badge` or a `Tooltip` is still an item, and the group tells its items
  /// what they need through the tree rather than by inspecting their type.
  final List<Widget> children;

  /// How the items spread. Defaults to a column.
  final FloatButtonLayout? layout;

  /// The mark on the trigger. Defaults to a plus that turns into a cross.
  final Widget? icon;

  /// Which palette the trigger draws from.
  final ButtonColor? color;

  /// Round (the default) or square.
  final ButtonShape? shape;

  /// What opens the group. Defaults to a tap.
  final FloatButtonTrigger? trigger;

  /// Drives the group from outside. Null leaves it to manage itself.
  final bool? open;

  /// Called whenever the group wants to open or close.
  final ValueChanged<bool>? onOpenChange;

  /// Which side the items' labels hang on. Null lets the layout decide.
  final FloatButtonLabelPlacement? labelPlacement;

  /// What a screen reader announces for the trigger.
  final String? semanticLabel;

  /// Per-instance token overrides.
  final FloatButtonToken? token;

  @override
  State<FloatButtonGroup> createState() => _FloatButtonGroupState();
}

class _FloatButtonGroupState extends State<FloatButtonGroup>
    with SingleTickerProviderStateMixin {
  final GlobalKey _triggerKey = GlobalKey();
  AnimationController? _controller;
  OverlayEntry? _entry;
  bool _openSelf = false;

  /// Where the trigger's centre sits in the overlay, and which way is away
  /// from the nearest corner. Read once per opening: a float button is
  /// parked, and asking every frame would cost more than it is worth.
  Offset _origin = Offset.zero;
  Offset _away = const Offset(-1, -1);

  Timer? _hoverClose;
  ScrollPosition? _scrolled;
  VoidCallback? _scrollListener;

  bool get _isOpen => widget.open ?? _openSelf;

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

  FloatButtonDefaults? get _defaults =>
      ConfigProvider.defaultsOf<FloatButtonDefaults>(context);

  FloatButtonLayout get _layout =>
      widget.layout ?? _defaults?.layout ?? const FloatButtonLayout.vertical();

  FloatButtonTrigger get _trigger =>
      widget.trigger ?? _defaults?.trigger ?? FloatButtonTrigger.click;

  @override
  void initState() {
    super.initState();
    if (widget.open ?? false) {
      // Born open. There is no previous state for didUpdateWidget to compare
      // against, so without this the overlay would wait for a tap that the
      // caller has already said is unnecessary.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _apply(true);
      });
    }
  }

  @override
  void didUpdateWidget(FloatButtonGroup old) {
    super.didUpdateWidget(old);
    if (widget.open != null && widget.open != old.open) {
      // didUpdateWidget runs inside a build, and an overlay entry may not be
      // mounted while the framework has the tree locked.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _apply(widget.open!);
      });
    } else if (_entry != null) {
      _entry!.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _cancelClose();
    _unwatchScroll();
    _entry?.remove();
    _entry = null;
    _controller?.dispose();
    super.dispose();
  }

  void _ask(bool next) {
    if (next == _isOpen) return;
    widget.onOpenChange?.call(next);
    // An uncontrolled group answers to itself; a controlled one waits to be
    // told, so that its parent stays the single account of whether it is open.
    if (widget.open == null) {
      setState(() => _openSelf = next);
      _apply(next);
    }
  }

  void _apply(bool next) {
    if (next) {
      _measure();
      _controller ??= AnimationController(
        vsync: this,
        duration: (widget.token ??
                ConfigProvider.componentOf<FloatButtonToken>(context) ??
                const FloatButtonToken())
            ._resolve(context.softToken)
            .motionDuration,
      );
      if (_entry == null) {
        _entry = OverlayEntry(builder: _buildLayer);
        Overlay.of(context).insert(_entry!);
      }
      _watchScroll();
      _controller!.forward();
    } else {
      _unwatchScroll();
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

  /// Folds the group away when the page beneath it scrolls.
  ///
  /// The geometry is read once per opening — a float button is parked, and
  /// asking every frame would cost more than it is worth. Scrolling is the one
  /// thing that invalidates it, and the kit answers it the same way a popover
  /// does: by letting go.
  void _watchScroll() {
    _unwatchScroll();
    final position = Scrollable.maybeOf(context)?.position;
    if (position == null) return;
    _scrolled = position;
    _scrollListener = () => _ask(false);
    position.addListener(_scrollListener!);
  }

  void _unwatchScroll() {
    if (_scrollListener != null) {
      _scrolled?.removeListener(_scrollListener!);
      _scrollListener = null;
      _scrolled = null;
    }
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
    _away = Offset(
      rect.center.dx > screen.width / 2 ? -1 : 1,
      rect.center.dy > screen.height / 2 ? -1 : 1,
    );
  }

  Widget _buildLayer(BuildContext overlayContext) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<FloatButtonToken>(context) ??
            const FloatButtonToken())
        ._resolve(t);
    final layout = _layout;
    final count = widget.children.length;
    final item = Size.square(r.size);

    final asked = widget.labelPlacement ??
        _defaults?.labelPlacement ??
        FloatButtonLabelPlacement.auto;

    final items = <Widget>[
      for (var i = 0; i < count; i++)
        _FloatItemScope(
          labelPlacement: asked == FloatButtonLabelPlacement.auto
              ? layout.labelPlacementFor(i, count, item, _away, r.gap)
              : asked,
          token: widget.token,
          close: () => _ask(false),
          child: _trigger == FloatButtonTrigger.hover
              ? MouseRegion(
                  // The pointer has to cross open ground to reach an item, so
                  // leaving the trigger only *schedules* a close; arriving
                  // anywhere in the group calls it off.
                  onEnter: (_) => _cancelClose(),
                  onExit: (_) => _scheduleClose(),
                  child: widget.children[i],
                )
              : widget.children[i],
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
        curve: t.motionEaseOut,
      ),
      children: items,
    );

    return Stack(
      children: [
        if (_trigger == FloatButtonTrigger.click)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _ask(false),
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
