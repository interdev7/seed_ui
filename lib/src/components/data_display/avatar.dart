import 'package:flutter/widgets.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/popover.dart' show PopoverPlacement;
import '../navigation/dropdown.dart';

/// The shape of an [Avatar].
enum AvatarShape {
  /// A round avatar — the default.
  circle,

  /// A rounded-rectangle avatar.
  square,
}

/// Token overrides for [Avatar].
@immutable
class AvatarToken {
  /// Creates an [AvatarToken].
  const AvatarToken({
    this.containerSize,
    this.containerSizeSM,
    this.containerSizeLG,
    this.textFontSize,
    this.textFontSizeSM,
    this.textFontSizeLG,
    this.colorTextPlaceholder,
    this.groupBorderColor,
    this.groupOverlapping,
    this.groupSpace,
    this.borderRadius,
  });

  /// Base container size (middle).
  final double? containerSize;

  /// Small container size.
  final double? containerSizeSM;

  /// Large container size.
  final double? containerSizeLG;

  /// Base text font size.
  final double? textFontSize;

  /// Small text font size.
  final double? textFontSizeSM;

  /// Large text font size.
  final double? textFontSizeLG;

  /// Text and icon color.
  final Color? colorTextPlaceholder;

  /// Border color when inside a group.
  final Color? groupBorderColor;

  /// Overlap distance in a group.
  final double? groupOverlapping;

  /// Spacing in a group (when overlapping is disabled/negative).
  final double? groupSpace;

  /// Border radius for square avatars.
  final double? borderRadius;

  _ResolvedAvatarToken _resolve(Token t) => _ResolvedAvatarToken(
        containerSize: containerSize ?? 32,
        containerSizeSM: containerSizeSM ?? 24,
        containerSizeLG: containerSizeLG ?? 40,
        textFontSize: textFontSize ?? 14,
        textFontSizeSM: textFontSizeSM ?? 14,
        textFontSizeLG: textFontSizeLG ?? 24,
        colorTextPlaceholder: colorTextPlaceholder ?? const Color(0xFFFFFFFF),
        groupBorderColor: groupBorderColor ?? t.colorBgContainer,
        groupOverlapping: groupOverlapping ?? -8,
        groupSpace: groupSpace ?? 3,
        borderRadius: borderRadius ?? t.borderRadius,
        colorFillTertiary:
            t.colorFillTertiary, // as background color placeholder
        fontFamily: t.fontFamily,
        fontFamilyFallback: t.fontFamilyFallback,
      );
}

@immutable
class _ResolvedAvatarToken {
  const _ResolvedAvatarToken({
    required this.containerSize,
    required this.containerSizeSM,
    required this.containerSizeLG,
    required this.textFontSize,
    required this.textFontSizeSM,
    required this.textFontSizeLG,
    required this.colorTextPlaceholder,
    required this.groupBorderColor,
    required this.groupOverlapping,
    required this.groupSpace,
    required this.borderRadius,
    required this.colorFillTertiary,
    required this.fontFamily,
    required this.fontFamilyFallback,
  });

  final double containerSize;
  final double containerSizeSM;
  final double containerSizeLG;
  final double textFontSize;
  final double textFontSizeSM;
  final double textFontSizeLG;
  final Color colorTextPlaceholder;
  final Color groupBorderColor;
  final double groupOverlapping;
  final double groupSpace;
  final double borderRadius;
  final Color colorFillTertiary;
  final String? fontFamily;
  final List<String>? fontFamilyFallback;
}

class _GroupContext extends InheritedWidget {
  const _GroupContext({
    required this.size,
    required this.shape,
    required this.token,
    required this.border,
    required super.child,
  });

  final SoftSize? size;
  final AvatarShape? shape;
  final _ResolvedAvatarToken token;
  final Border? border;

  static _GroupContext? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_GroupContext>();
  }

  @override
  bool updateShouldNotify(_GroupContext oldWidget) =>
      size != oldWidget.size ||
      shape != oldWidget.shape ||
      token != oldWidget.token ||
      border != oldWidget.border;
}

/// A component for representing users or objects.
class Avatar extends StatelessWidget {
  /// Creates an [Avatar].
  const Avatar({
    super.key,
    this.size = SoftSize.middle,
    this.customSize,
    this.shape = AvatarShape.circle,
    this.image,
    this.icon,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.gap = 4,
    this.errorBuilder,
    this.gradient,
    this.token,
    this.border,
  });

  /// Custom background gradient override.
  final Gradient? gradient;

  /// The size preset. Ignored if [customSize] is provided.
  final SoftSize size;

  /// Custom diameter/width/height in logical pixels.
  final double? customSize;

  /// The shape of the avatar.
  final AvatarShape shape;

  /// An image to display.
  final ImageProvider? image;

  /// An icon to display.
  final Widget? icon;

  /// A text/child to display. Usually a short string.
  final Widget? child;

  /// Custom background color.
  final Color? backgroundColor;

  /// Custom foreground color (for icon or text).
  final Color? foregroundColor;

  /// The gap between text and the edges of the avatar.
  final double gap;

  /// Called if the [image] fails to load.
  final Widget Function(
    BuildContext context,
    Token? token,
    Object error,
    StackTrace? stackTrace,
  )? errorBuilder;

  /// Token overrides.
  final AvatarToken? token;

  /// Used by [AvatarGroup] to inject a border.
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final group = _GroupContext.maybeOf(context);
    final rt = group?.token ??
        (token ??
                ConfigProvider.componentOf<AvatarToken>(context) ??
                const AvatarToken())
            ._resolve(t);

    final resolvedSize = group?.size ?? size;
    final resolvedShape = group?.shape ?? shape;

    final dimension = customSize ??
        switch (resolvedSize) {
          SoftSize.small => rt.containerSizeSM,
          SoftSize.middle => rt.containerSize,
          SoftSize.large => rt.containerSizeLG,
        };

    final fontSize = customSize != null
        ? (customSize! / 2).roundToDouble()
        : switch (resolvedSize) {
            SoftSize.small => rt.textFontSizeSM,
            SoftSize.middle => rt.textFontSize,
            SoftSize.large => rt.textFontSizeLG,
          };

    final bg = backgroundColor ??
        (image == null ? const Color(0xFFCCCCCC) : const Color(0x00000000));
    final fg = foregroundColor ?? rt.colorTextPlaceholder;

    final boxShape = resolvedShape == AvatarShape.circle
        ? BoxShape.circle
        : BoxShape.rectangle;
    final borderRadius = resolvedShape == AvatarShape.square
        ? BorderRadius.circular(rt.borderRadius)
        : null;

    Widget content;
    if (image != null) {
      content = Image(
        image: image!,
        fit: BoxFit.cover,
        width: dimension,
        height: dimension,
        errorBuilder: (context, error, stackTrace) {
          if (errorBuilder != null) {
            return errorBuilder!(context, t, error, stackTrace);
          }
          return Container(
            color: backgroundColor ?? const Color(0xFFCCCCCC),
            alignment: Alignment.center,
            child: _buildFallback(rt, fg, fontSize),
          );
        },
      );
    } else if (icon != null) {
      content = IconTheme.merge(
        data: IconThemeData(color: fg, size: fontSize),
        child: icon!,
      );
    } else if (child != null) {
      content = DefaultTextStyle.merge(
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontFamily: rt.fontFamily,
          fontFamilyFallback: rt.fontFamilyFallback,
          height: 1.0,
          leadingDistribution: TextLeadingDistribution.even,
          decoration: TextDecoration.none,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gap),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: child!,
          ),
        ),
      );
    } else {
      content = const SizedBox.shrink();
    }

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: gradient == null ? bg : null,
        gradient: gradient,
        shape: boxShape,
        borderRadius: borderRadius,
        border: border ?? group?.border,
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  Widget _buildFallback(_ResolvedAvatarToken rt, Color fg, double fontSize) {
    if (icon != null) {
      return IconTheme.merge(
        data: IconThemeData(color: fg, size: fontSize),
        child: icon!,
      );
    }
    if (child != null) {
      return DefaultTextStyle.merge(
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontFamily: rt.fontFamily,
          fontFamilyFallback: rt.fontFamilyFallback,
          height: 1.0,
          leadingDistribution: TextLeadingDistribution.even,
          decoration: TextDecoration.none,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gap),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: child!,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// A group of [Avatar] components that can overlap.
class AvatarGroup extends StatelessWidget {
  /// Creates an [AvatarGroup].
  const AvatarGroup({
    super.key,
    required this.children,
    this.maxCount,
    this.size = SoftSize.middle,
    this.shape,
    this.maxStyle,
    this.maxPopoverPlacement = PopoverPlacement.top,
    this.maxPopoverTrigger = const [DropdownTrigger.hover],
    this.maxPopoverArrow = true,
    this.showPopover = true,
    this.popupRender,
    this.maxPopoverToken,
    this.token,
  });

  /// The avatars to display.
  final List<Widget> children;

  /// The maximum number of avatars to display. If the number of children exceeds
  /// this, an extra avatar showing `+N` is added.
  final int? maxCount;

  /// The size of the avatars in the group.
  final SoftSize size;

  /// The shape of the avatars in the group.
  final AvatarShape? shape;

  /// Customizer for the `+N` avatar.
  final Widget Function(int overflowCount)? maxStyle;

  /// Placement of the popover that appears when hovering the `+N` avatar.
  final PopoverPlacement maxPopoverPlacement;

  /// Which gestures open the popover for the `+N` avatar.
  final List<DropdownTrigger> maxPopoverTrigger;

  /// Whether to draw a caret pointing at the `+N` avatar.
  final bool maxPopoverArrow;

  /// Per-instance token overrides for the `+N` popover.
  final DropdownToken? maxPopoverToken;

  /// Whether to show the popover when hovering the `+N` avatar.
  final bool showPopover;

  /// A fully custom popup body builder. Receives the built AvatarGroup of hidden avatars.
  final Widget Function(BuildContext context, Widget menu)? popupRender;

  /// Custom token overrides for the group.
  final AvatarToken? token;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final rt = (token ??
            ConfigProvider.componentOf<AvatarToken>(context) ??
            const AvatarToken())
        ._resolve(t);

    final showMax = maxCount != null && children.length > maxCount!;
    final renderCount = showMax ? maxCount! : children.length;
    final overflowCount = children.length - renderCount;

    final items = children.take(renderCount).toList();

    if (showMax) {
      final hiddenAvatars = children.skip(renderCount).toList();

      Widget maxChild;
      if (maxStyle != null) {
        maxChild = maxStyle!(overflowCount);
      } else {
        maxChild = Avatar(
          backgroundColor: Color.alphaBlend(
            t.colorFillSecondary,
            rt.groupBorderColor,
          ),
          foregroundColor: t.colorText,
          child: Text('+$overflowCount'),
        );
      }

      if (showPopover) {
        Widget popoverContent(BuildContext context) {
          final group = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: AvatarGroup(
              size: size,
              shape: shape,
              token: token,
              children: hiddenAvatars,
            ),
          );
          return popupRender != null ? popupRender!(context, group) : group;
        }

        items.add(
          Dropdown(
            arrow: maxPopoverArrow,
            placement: maxPopoverPlacement,
            trigger: maxPopoverTrigger,
            token: maxPopoverToken,
            content: (context, _) => DropdownPanel(
              token: maxPopoverToken,
              child: popoverContent(context),
            ),
            child: maxChild,
          ),
        );
      } else {
        items.add(maxChild);
      }
    }

    final overlap = rt.groupOverlapping < 0 ? -rt.groupOverlapping : 0.0;
    final spacing = rt.groupOverlapping >= 0 ? rt.groupOverlapping : 0.0;

    final border = Border.all(
      color: rt.groupBorderColor,
      width: 2.0, // Default group border width
      strokeAlign: BorderSide.strokeAlignOutside,
    );

    final dimension = switch (size) {
      SoftSize.small => rt.containerSizeSM,
      SoftSize.middle => rt.containerSize,
      SoftSize.large => rt.containerSizeLG,
    };

    return _GroupContext(
      size: size,
      shape: shape,
      token: rt,
      border: border,
      child: _OverlappingRow(
        overlap: overlap,
        spacing: spacing,
        dimension: dimension,
        children: items,
      ),
    );
  }
}

class _OverlappingRow extends StatelessWidget {
  const _OverlappingRow({
    required this.overlap,
    required this.spacing,
    required this.dimension,
    required this.children,
  });

  final double overlap;
  final double spacing;
  final double dimension;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (overlap <= 0) {
      return Wrap(
        spacing: spacing,
        children: children,
      );
    }

    return _OverlapRow(
      overlap: overlap,
      dimension: dimension,
      children: children,
    );
  }
}

class _OverlapRow extends StatelessWidget {
  const _OverlapRow({
    required this.overlap,
    required this.dimension,
    required this.children,
  });

  final double overlap;
  final double dimension;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final widthFactor = (dimension - overlap) / dimension;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final isLast = index == children.length - 1;

        return Align(
          alignment: Alignment.centerLeft,
          widthFactor: isLast ? 1.0 : widthFactor,
          heightFactor: 1.0,
          child: entry.value,
        );
      }).toList(),
    );
  }
}
