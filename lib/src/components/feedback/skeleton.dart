import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/size_resolver.dart';
import '../data_display/avatar.dart' show AvatarShape;
import '../general/button.dart' show ButtonShape;

/// Per-component design tokens for [Skeleton] and its blocks.
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(skeleton: SkeletonToken(...)))`, or per instance via a
/// widget's `token`.
@immutable
class SkeletonToken {
  /// Creates a [SkeletonToken].
  const SkeletonToken({
    this.blockColor,
    this.highlightColor,
    this.blockRadius,
    this.titleHeight,
    this.titleGap,
    this.paragraphLineHeight,
    this.paragraphLineGap,
    this.avatarGap,
    this.motionDuration,
  });

  /// The colour of a block at rest.
  final Color? blockColor;

  /// The colour of the light that sweeps across an active block.
  final Color? highlightColor;

  /// The corners of a block that is not round: a title, a line, an image.
  final double? blockRadius;

  /// How tall the title bar is.
  final double? titleHeight;

  /// Space between the title and the first line of the paragraph.
  final double? titleGap;

  /// How tall each line of the paragraph is.
  final double? paragraphLineHeight;

  /// Space between two lines of the paragraph.
  final double? paragraphLineGap;

  /// Space between the avatar and the title and paragraph beside it.
  final double? avatarGap;

  /// How long one sweep of the light takes.
  final Duration? motionDuration;

  _ResolvedSkeletonToken _resolve(Token t) => _ResolvedSkeletonToken(
        blockColor: blockColor ?? t.colorFillSecondary,
        // On a dark page the fills sit close together, and the light needs a
        // wider step to be seen at all.
        highlightColor:
            highlightColor ?? (t.isDark ? t.colorTextQuaternary : t.colorFill),
        blockRadius: blockRadius ?? t.borderRadiusSM,
        titleHeight: titleHeight ?? t.fontSizeLG,
        titleGap: titleGap ?? t.sizeLG,
        paragraphLineHeight: paragraphLineHeight ?? t.fontSizeLG,
        paragraphLineGap: paragraphLineGap ?? t.size,
        avatarGap: avatarGap ?? t.size,
        motionDuration: motionDuration ?? const Duration(milliseconds: 1400),
      );

  /// This one with [other]'s fields laid over it, one field at a time.
  SkeletonToken merge(SkeletonToken other) => SkeletonToken(
        blockColor: other.blockColor ?? blockColor,
        highlightColor: other.highlightColor ?? highlightColor,
        blockRadius: other.blockRadius ?? blockRadius,
        titleHeight: other.titleHeight ?? titleHeight,
        titleGap: other.titleGap ?? titleGap,
        paragraphLineHeight: other.paragraphLineHeight ?? paragraphLineHeight,
        paragraphLineGap: other.paragraphLineGap ?? paragraphLineGap,
        avatarGap: other.avatarGap ?? avatarGap,
        motionDuration: other.motionDuration ?? motionDuration,
      );
}

@immutable
class _ResolvedSkeletonToken {
  const _ResolvedSkeletonToken({
    required this.blockColor,
    required this.highlightColor,
    required this.blockRadius,
    required this.titleHeight,
    required this.titleGap,
    required this.paragraphLineHeight,
    required this.paragraphLineGap,
    required this.avatarGap,
    required this.motionDuration,
  });

  final Color blockColor;
  final Color highlightColor;
  final double blockRadius;
  final double titleHeight;
  final double titleGap;
  final double paragraphLineHeight;
  final double paragraphLineGap;
  final double avatarGap;
  final Duration motionDuration;
}

/// Defaults for every [Skeleton] and skeleton block under a `ConfigProvider`.
@immutable
class SkeletonDefaults {
  /// Creates a [SkeletonDefaults].
  const SkeletonDefaults({this.active, this.round});

  /// Whether a light sweeps across the blocks.
  final bool? active;

  /// Whether a [Skeleton]'s title and lines have round ends.
  final bool? round;

  /// This one with [other]'s fields laid over it, one field at a time.
  SkeletonDefaults merge(SkeletonDefaults other) => SkeletonDefaults(
        active: other.active ?? active,
        round: other.round ?? round,
      );
}

/// The title bar of a [Skeleton].
@immutable
class SkeletonTitle {
  /// Creates a [SkeletonTitle].
  const SkeletonTitle({this.width});

  /// How much of the width the bar takes, from 0 to 1. Null takes 38%, or
  /// half beside an avatar.
  final double? width;
}

/// The lines of a [Skeleton]'s paragraph.
@immutable
class SkeletonParagraph {
  /// Creates a [SkeletonParagraph].
  const SkeletonParagraph({this.rows, this.widths});

  /// How many lines. Null draws three, or two beside an avatar.
  final int? rows;

  /// How much of the width each line takes, from 0 to 1, first line first.
  /// A line with no entry takes the whole width, except that the last of
  /// several stops at 61% — the way the last line of a paragraph does.
  final List<double>? widths;
}

SkeletonToken _tokenOf(BuildContext context, SkeletonToken? token) =>
    token ??
    ConfigProvider.componentOf<SkeletonToken>(context) ??
    const SkeletonToken();

double _controlHeight(BuildContext context, ControlSize? size) {
  final t = context.softToken;
  return (size ?? ConfigProvider.componentSizeOf(context) ?? SoftSize.middle)
      .resolve1D(
    small: t.controlHeightSM,
    middle: t.controlHeight,
    large: t.controlHeightLG,
  );
}

/// Runs one light for every block beneath it.
///
/// Still unless asked, and still where the platform asks for less motion. The
/// sweep repaints the blocks and nothing else: they sit behind their own
/// repaint boundary, and each paints from the shared animation rather than
/// being rebuilt by it.
class _Shimmer extends StatefulWidget {
  const _Shimmer({
    required this.active,
    required this.duration,
    required this.child,
  });

  final bool active;
  final Duration duration;
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Shimmer old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final moving = widget.active && !still;
    if (!moving) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    final controller = _controller ??= AnimationController(vsync: this);
    if (controller.duration != widget.duration || !controller.isAnimating) {
      controller
        ..duration = widget.duration
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        // The width the light crosses: the whole skeleton, so one band moves
        // over every block at once instead of each block running its own.
        child: LayoutBuilder(
          builder: (context, constraints) => _ShimmerScope(
            animation: _controller,
            span: constraints.hasBoundedWidth ? constraints.maxWidth : null,
            child: widget.child,
          ),
        ),
      );
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({
    required this.animation,
    required this.span,
    required super.child,
  });

  /// The light's place, 0 to 1; null while still.
  final Animation<double>? animation;

  /// How wide a stretch the light crosses; null where the skeleton was given
  /// no width, and each block crosses its own.
  final double? span;

  static _ShimmerScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>();

  @override
  bool updateShouldNotify(_ShimmerScope old) =>
      old.animation != animation || old.span != span;
}

/// One grey block, lit by the nearest light if it moves.
class _Block extends StatelessWidget {
  const _Block({
    required this.token,
    required this.radius,
    this.width,
    this.height,
  });

  final _ResolvedSkeletonToken token;
  final double radius;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final scope = _ShimmerScope.maybeOf(context);
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _BlockPainter(
          light: scope?.animation,
          span: scope?.span,
          color: token.blockColor,
          highlight: token.highlightColor,
          radius: radius,
          rtl: Directionality.maybeOf(context) == TextDirection.rtl,
        ),
      ),
    );
  }
}

class _BlockPainter extends CustomPainter {
  _BlockPainter({
    required this.light,
    required this.span,
    required this.color,
    required this.highlight,
    required this.radius,
    required this.rtl,
  }) : super(repaint: light);

  final Animation<double>? light;
  final double? span;
  final Color color;
  final Color highlight;
  final double radius;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final light = this.light;
    // A shader's colours are multiplied by the paint's own alpha, so the
    // paint stays opaque while the gradient carries the colour: a translucent
    // block colour here would scale the gradient down to almost nothing.
    final paint = Paint()
      ..color = light == null ? color : const Color(0xFF000000);
    if (light != null) {
      // Where this block stands in the skeleton: the light is laid out across
      // the skeleton's own box, which is the layer this block is painted
      // into, so the canvas's own shift says how far along it starts.
      final from = canvas.getTransform()[12];
      final across = span ?? size.width;
      // A band half the skeleton wide, entering at one edge and leaving at
      // the other, so some of it is in sight for most of the turn.
      final half = math.max(across / 4, size.height * 4);
      final travel = rtl ? 1 - light.value : light.value;
      final centre = -half + (across + 2 * half) * travel - from;
      paint.shader = LinearGradient(
        colors: [color, highlight, color],
      ).createShader(
        Rect.fromLTRB(centre - half, 0, centre + half, size.height),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BlockPainter old) =>
      old.light != light ||
      old.span != span ||
      old.color != color ||
      old.highlight != highlight ||
      old.radius != radius ||
      old.rtl != rtl;
}

/// A block standing on its own, or inside a [Skeleton].
///
/// Inside one it takes the skeleton's light rather than starting a second,
/// so every block sweeps together; on its own it brings its own light and
/// tells a screen reader it is loading.
class _Standalone extends StatelessWidget {
  const _Standalone({
    required this.active,
    required this.token,
    required this.builder,
  });

  final bool? active;
  final SkeletonToken? token;
  final Widget Function(_ResolvedSkeletonToken) builder;

  @override
  Widget build(BuildContext context) {
    final r = _tokenOf(context, token)._resolve(context.softToken);
    if (_ShimmerScope.maybeOf(context) != null) return builder(r);
    final defaults = ConfigProvider.defaultsOf<SkeletonDefaults>(context);
    return Semantics(
      label: context.seedLocale.loading,
      child: ExcludeSemantics(
        child: _Shimmer(
          active: active ?? defaults?.active ?? false,
          duration: r.motionDuration,
          child: builder(r),
        ),
      ),
    );
  }
}

/// A stand-in for content that is still loading: grey blocks where an avatar,
/// a title and a paragraph will be, with a light sweeping across them.
///
/// ```dart
/// Skeleton(
///   loading: user == null,
///   avatar: const SkeletonAvatar(),
///   child: UserCard(user),
/// )
/// ```
///
/// While [loading] it draws the blocks and a screen reader hears "Loading";
/// once it is not, it shows [child]. For blocks of other shapes, use
/// [SkeletonButton], [SkeletonAvatar], [SkeletonInput], [SkeletonImage] and
/// [SkeletonNode] on their own or in your own layout.
class Skeleton extends StatelessWidget {
  /// Creates a [Skeleton].
  const Skeleton({
    super.key,
    this.loading = true,
    this.active,
    this.avatar,
    this.title = const SkeletonTitle(),
    this.paragraph = const SkeletonParagraph(),
    this.round,
    this.child,
    this.token,
  });

  /// Whether to draw the blocks rather than [child].
  final bool loading;

  /// Whether a light sweeps across the blocks. Defaults to no.
  ///
  /// Where the platform asks for less motion the blocks stay still whatever
  /// this says.
  final bool? active;

  /// An avatar block beside the title and paragraph. Null draws none.
  final SkeletonAvatar? avatar;

  /// The title bar. Null draws none.
  final SkeletonTitle? title;

  /// The paragraph's lines. Null draws none.
  final SkeletonParagraph? paragraph;

  /// Whether the title and lines have round ends. Defaults to no.
  final bool? round;

  /// What to show once [loading] is false.
  final Widget? child;

  /// Per-instance token overrides, for this skeleton and its avatar.
  final SkeletonToken? token;

  @override
  Widget build(BuildContext context) {
    if (!loading) return child ?? const SizedBox.shrink();
    final t = context.softToken;
    final r = _tokenOf(context, token)._resolve(t);
    final defaults = ConfigProvider.defaultsOf<SkeletonDefaults>(context);
    final isRound = round ?? defaults?.round ?? false;
    final avatarBlock = avatar;
    final withAvatar = avatarBlock != null;

    Widget bar(double height, double widthFactor) => FractionallySizedBox(
          // A stand-in for a line of text, so it fills from where the reading
          // would start.
          alignment: AlignmentDirectional.centerStart,
          widthFactor: widthFactor.clamp(0.0, 1.0),
          child: _Block(
            token: r,
            height: height,
            radius: isRound ? height / 2 : r.blockRadius,
          ),
        );

    final title = this.title;
    final paragraph = this.paragraph;
    final rows = paragraph == null ? 0 : paragraph.rows ?? (withAvatar ? 2 : 3);
    final widths = paragraph?.widths ?? const <double>[];
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          bar(r.titleHeight, title.width ?? (withAvatar ? 0.5 : 0.38)),
        if (title != null && rows > 0) SizedBox(height: r.titleGap),
        for (var i = 0; i < rows; i++) ...[
          if (i > 0) SizedBox(height: r.paragraphLineGap),
          bar(
            r.paragraphLineHeight,
            i < widths.length
                ? widths[i]
                : (rows > 1 && i == rows - 1 ? 0.61 : 1),
          ),
        ],
      ],
    );

    final body = avatarBlock == null
        ? text
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatarBlock,
              SizedBox(width: r.avatarGap),
              Expanded(child: text),
            ],
          );

    return Semantics(
      label: context.seedLocale.loading,
      child: ExcludeSemantics(
        child: _Shimmer(
          active: active ?? defaults?.active ?? false,
          duration: r.motionDuration,
          child: body,
        ),
      ),
    );
  }
}

/// A round or square block where an avatar will be.
///
/// On its own, or as [Skeleton.avatar].
class SkeletonAvatar extends StatelessWidget {
  /// Creates a [SkeletonAvatar].
  const SkeletonAvatar({
    super.key,
    this.shape = AvatarShape.circle,
    this.size,
    this.active,
    this.token,
  });

  /// Round or square.
  final AvatarShape shape;

  /// How big: [SoftSize.small], [SoftSize.middle] (the default),
  /// [SoftSize.large], or a measurement of your own.
  final ControlSize? size;

  /// Whether a light sweeps across it. Inside a [Skeleton] it follows the
  /// skeleton's.
  final bool? active;

  /// Per-instance token overrides.
  final SkeletonToken? token;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final side = _controlHeight(context, size);
    return _Standalone(
      active: active,
      token: token,
      builder: (r) => _Block(
        token: r,
        width: side,
        height: side,
        radius: shape == AvatarShape.circle ? side / 2 : t.borderRadiusSM,
      ),
    );
  }
}

/// A block where a button will be.
class SkeletonButton extends StatelessWidget {
  /// Creates a [SkeletonButton].
  const SkeletonButton({
    super.key,
    this.shape = ButtonShape.defaultShape,
    this.size,
    this.block = false,
    this.active,
    this.token,
  });

  /// The button's outline: corners, a pill, or a circle.
  final ButtonShape shape;

  /// How tall, as a button's own sizes. Defaults to [SoftSize.middle].
  final ControlSize? size;

  /// Whether it takes the whole width, as a block button does.
  final bool block;

  /// Whether a light sweeps across it.
  final bool? active;

  /// Per-instance token overrides.
  final SkeletonToken? token;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final height = _controlHeight(context, size);
    final circle = shape == ButtonShape.circle;
    return _Standalone(
      active: active,
      token: token,
      builder: (r) => _Block(
        token: r,
        height: height,
        width: circle ? height : (block ? double.infinity : height * 2),
        radius: switch (shape) {
          ButtonShape.circle || ButtonShape.round => height / 2,
          _ => t.borderRadius,
        },
      ),
    );
  }
}

/// A block where a text field will be.
class SkeletonInput extends StatelessWidget {
  /// Creates a [SkeletonInput].
  const SkeletonInput({
    super.key,
    this.size,
    this.block = false,
    this.active,
    this.token,
  });

  /// How tall, as a field's own sizes. Defaults to [SoftSize.middle].
  final ControlSize? size;

  /// Whether it takes the whole width.
  final bool block;

  /// Whether a light sweeps across it.
  final bool? active;

  /// Per-instance token overrides.
  final SkeletonToken? token;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final height = _controlHeight(context, size);
    return _Standalone(
      active: active,
      token: token,
      builder: (r) => _Block(
        token: r,
        height: height,
        width: block ? double.infinity : height * 5,
        radius: t.borderRadius,
      ),
    );
  }
}

/// A square block where a picture will be.
class SkeletonImage extends StatelessWidget {
  /// Creates a [SkeletonImage].
  const SkeletonImage({
    super.key,
    this.width,
    this.height,
    this.active,
    this.token,
  });

  /// How wide. Null is three control heights.
  final double? width;

  /// How tall. Null is three control heights.
  final double? height;

  /// Whether a light sweeps across it.
  final bool? active;

  /// Per-instance token overrides.
  final SkeletonToken? token;

  @override
  Widget build(BuildContext context) {
    final side = context.softToken.controlHeight * 3;
    return _Standalone(
      active: active,
      token: token,
      builder: (r) => _Block(
        token: r,
        width: width ?? side,
        height: height ?? side,
        radius: r.blockRadius,
      ),
    );
  }
}

/// A block of the size of [child], drawn over it: for a placeholder shaped
/// like nothing above — a chart, a map — or with an icon of your own on it.
class SkeletonNode extends StatelessWidget {
  /// Creates a [SkeletonNode].
  const SkeletonNode({super.key, this.child, this.active, this.token});

  /// What gives the block its size and is drawn on top of it. Null makes a
  /// block of three control heights square.
  final Widget? child;

  /// Whether a light sweeps across it.
  final bool? active;

  /// Per-instance token overrides.
  final SkeletonToken? token;

  @override
  Widget build(BuildContext context) {
    final side = context.softToken.controlHeight * 3;
    return _Standalone(
      active: active,
      token: token,
      builder: (r) => Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: _Block(token: r, radius: r.blockRadius)),
          child ?? SizedBox.square(dimension: side),
        ],
      ),
    );
  }
}
