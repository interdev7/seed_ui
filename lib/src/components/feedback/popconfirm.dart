import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/popover.dart';
import '../general/button.dart';
import 'message.dart' show StatusType;

/// Per-component design tokens for [Popconfirm].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(popconfirm: PopconfirmToken(...)))`,
/// or per instance via [Popconfirm.token].
@immutable
class PopconfirmToken {
  /// Creates a [PopconfirmToken].
  const PopconfirmToken({
    this.colorBgElevated,
    this.padding,
    this.borderRadius,
    this.titleFontSize,
    this.descriptionFontSize,
    this.barrierColor,
  });

  /// Popover background color (`colorBgElevated`).
  final Color? colorBgElevated;

  /// Popover padding (`padding`).
  final EdgeInsets? padding;

  /// Popover corner radius (`borderRadius`).
  final double? borderRadius;

  /// Title font size (`titleFontSize`).
  final double? titleFontSize;

  /// Description font size (`descriptionFontSize`).
  final double? descriptionFontSize;

  /// Dismiss barrier background color (`barrierColor`).
  final Color? barrierColor;

  _ResolvedPopconfirmToken _resolve(Token t) => _ResolvedPopconfirmToken(
        colorBgElevated: colorBgElevated ?? t.colorBgElevated,
        padding: padding ?? EdgeInsets.all(t.sizeSM),
        borderRadius: borderRadius ?? t.borderRadiusLG,
        titleFontSize: titleFontSize ?? t.fontSize,
        descriptionFontSize: descriptionFontSize ?? t.fontSize,
        barrierColor: barrierColor,
      );
}

@immutable
class _ResolvedPopconfirmToken {
  const _ResolvedPopconfirmToken({
    required this.colorBgElevated,
    required this.padding,
    required this.borderRadius,
    required this.titleFontSize,
    required this.descriptionFontSize,
    this.barrierColor,
  });

  final Color colorBgElevated;
  final EdgeInsets padding;
  final double borderRadius;
  final double titleFontSize;
  final double descriptionFontSize;
  final Color? barrierColor;
}

/// Defaults for every [Popconfirm] under a `ConfigProvider`.
///
/// House style for confirmations: where they sit and what they offer.
@immutable
class PopconfirmDefaults {
  /// Creates a [PopconfirmDefaults].
  const PopconfirmDefaults({this.placement, this.arrow, this.showCancel});

  /// Where the confirmation sits.
  final PopoverPlacement? placement;

  /// Whether it draws a pointer.
  final bool? arrow;

  /// Whether a cancel button is offered.
  final bool? showCancel;
}

/// A lightweight confirmation bubble anchored to its trigger.
///
/// Use it for a low-stakes yes/no — deleting a single row, discarding a
/// draft — where a full [Modal] would be too heavy. Wrap the control that
/// triggers the action:
///
/// ```dart
/// Popconfirm(
///   title: const Text('Delete this item?'),
///   okText: const Text('Delete'),
///   color: ButtonColor.danger,
///   onOk: () => delete(item),
///   child: Button(variant: ButtonVariant.text, child: const Text('Delete')),
/// )
/// ```
///
/// The popover opens on tap and closes on confirm, cancel or an outside tap.
class Popconfirm extends StatefulWidget {
  /// Creates a [Popconfirm].
  const Popconfirm({
    super.key,
    required this.child,
    required this.title,
    this.description,
    this.okText,
    this.cancelText,
    this.onOk,
    this.onCancel,
    this.danger = false,
    this.placement,
    this.arrow,
    this.icon,
    this.showCancel,
    this.disabled = false,
    this.barrierColor,
    this.token,
  });

  /// The trigger. Tapping it opens the confirmation.
  final Widget child;

  /// The question posed to the user.
  ///
  /// Rendered inside a [DefaultTextStyle] carrying the title's size and
  /// weight, so a bare `Text('Delete this item?')` needs no styling.
  final Widget title;

  /// Optional detail shown below the title, in its own dimmer style.
  final Widget? description;

  /// Label of the confirming button.
  /// Null takes the word from the locale in scope.
  final Widget? okText;

  /// Label of the dismissing button.
  /// Null takes the word from the locale in scope.
  final Widget? cancelText;

  /// Called when confirmed.
  ///
  /// Returning a [Future] keeps the confirm button spinning and the popover
  /// open until it settles, so the trigger cannot fire twice.
  final FutureOr<void> Function()? onOk;

  /// Called when cancelled or dismissed by an outside tap.
  final VoidCallback? onCancel;

  /// Recolors the confirming button to the error palette.
  final bool danger;

  /// Which side of the trigger the bubble appears on.
  final PopoverPlacement? placement;

  /// Whether to draw a caret pointing at the trigger.
  final bool? arrow;

  /// Replaces the warning icon. Provide `SizedBox.shrink()` to hide it.
  final Widget? icon;

  /// Whether to show the cancel button.
  final bool? showCancel;

  /// When true, the trigger behaves normally and never opens the bubble.
  final bool disabled;

  /// Background color of the dismiss barrier.
  final Color? barrierColor;

  /// Per-instance token overrides.
  final PopconfirmToken? token;

  @override
  State<Popconfirm> createState() => _SoftPopconfirmState();
}

class _SoftPopconfirmState extends State<Popconfirm> {
  /// The defaults set for this component in the subtree, if any.
  PopconfirmDefaults? get _defaults =>
      ConfigProvider.defaultsOf<PopconfirmDefaults>(context);

  /// This widget's word, then the subtree's, then the kit's.
  PopoverPlacement get _placement =>
      widget.placement ?? _defaults?.placement ?? PopoverPlacement.top;

  /// This widget's word, then the subtree's, then the kit's.
  bool get _arrow => widget.arrow ?? _defaults?.arrow ?? true;

  /// This widget's word, then the subtree's, then the kit's.
  bool get _showCancel => widget.showCancel ?? _defaults?.showCancel ?? true;

  bool _open = false;
  bool _confirming = false;

  void _setOpen(bool value) {
    if (_confirming) return; // don't let an outside tap close mid-confirm
    setState(() => _open = value);
    if (!value) widget.onCancel?.call();
  }

  Future<void> _confirm() async {
    final onOk = widget.onOk;
    if (onOk == null) {
      setState(() => _open = false);
      return;
    }
    setState(() => _confirming = true);
    try {
      await onOk();
      if (mounted) setState(() => _open = false);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<PopconfirmToken>(context) ??
            const PopconfirmToken())
        ._resolve(token);

    return PopoverLayer(
      placement: _placement,
      open: _open,
      onOpenChanged: _setOpen,
      content: _buildBubble,
      // Match the bubble's own surface and shadow so the caret reads as part
      // of it.
      arrowColor: _arrow ? r.colorBgElevated : null,
      arrowShadow: _arrow ? token.boxShadowSecondary : null,
      barrierColor: widget.barrierColor ?? r.barrierColor,
      // A Listener rather than a GestureDetector: the trigger is usually an
      // interactive control (a Button) whose own gesture detector wins the
      // arena, so an outer onTap would never fire. Pointer events reach a
      // Listener regardless, so we open the bubble on release without stealing
      // the trigger's own tap.
      child: Listener(
        onPointerUp: widget.disabled
            ? null
            : (_) {
                if (!_open) _setOpen(true);
              },
        child: widget.child,
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<PopconfirmToken>(context) ??
            const PopconfirmToken())
        ._resolve(token);

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: r.padding,
      decoration: BoxDecoration(
        color: r.colorBgElevated,
        borderRadius: BorderRadius.circular(r.borderRadius),
        boxShadow: token.boxShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.icon ?? StatusIcon(type: StatusType.warning, token: token),
              SizedBox(width: token.sizeXS),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: TextStyle(
                        color: token.colorText,
                        fontSize: r.titleFontSize,
                        fontFamily: token.fontFamily,
                        fontFamilyFallback: token.fontFamilyFallback,
                        fontWeight: token.fontWeightStrong,
                        decoration: TextDecoration.none,
                      ),
                      child: widget.title,
                    ),
                    if (widget.description != null) ...[
                      SizedBox(height: token.sizeXXS),
                      DefaultTextStyle(
                        style: TextStyle(
                          color: token.colorTextSecondary,
                          fontSize: r.descriptionFontSize,
                          fontFamily: token.fontFamily,
                          fontFamilyFallback: token.fontFamilyFallback,
                          height: token.lineHeight,
                          decoration: TextDecoration.none,
                        ),
                        child: widget.description!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: token.sizeSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_showCancel) ...[
                Button(
                  size: SoftSize.small,
                  onPressed: () => _setOpen(false),
                  child: widget.cancelText ?? Text(context.seedLocale.cancel),
                ),
                SizedBox(width: token.sizeXS),
              ],
              Button(
                size: SoftSize.small,
                variant: ButtonVariant.solid,
                color: widget.danger ? ButtonColor.danger : ButtonColor.primary,
                loading: _confirming,
                onPressed: _confirm,
                child: widget.okText ?? Text(context.seedLocale.ok),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
