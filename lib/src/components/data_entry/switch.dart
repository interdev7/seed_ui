import 'package:flutter/widgets.dart';

import '../../icons/icons.dart' show Spinner;
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';

/// Size preset for a [Switch].
enum SwitchSize {
  /// The compact track, for dense rows.
  small,

  /// The standard track.
  defaultSize
}

/// Per-component design tokens for [Switch].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [SwitchToken(...)])`, or per instance via [Switch.token].
@immutable
class SwitchToken {
  /// Creates a [SwitchToken].
  const SwitchToken({
    this.trackHeight,
    this.trackHeightSM,
    this.trackMinWidth,
    this.trackMinWidthSM,
    this.handleSize,
    this.handleSizeSM,
    this.colorPrimary,
    this.colorBg,
  });

  /// Height of default switch track (`trackHeight`).
  final double? trackHeight;

  /// Height of small switch track (`trackHeightSM`).
  final double? trackHeightSM;

  /// Min width of default switch track (`trackMinWidth`).
  final double? trackMinWidth;

  /// Min width of small switch track (`trackMinWidthSM`).
  final double? trackMinWidthSM;

  /// Size of default switch handle (`handleSize`).
  final double? handleSize;

  /// Size of small switch handle (`handleSizeSM`).
  final double? handleSizeSM;

  /// Primary active track color (`colorPrimary`).
  final Color? colorPrimary;

  /// Inactive track background color (`colorBg`).
  final Color? colorBg;

  _ResolvedSwitchToken _resolve(Token t) => _ResolvedSwitchToken(
        trackHeight: trackHeight ?? 22,
        trackHeightSM: trackHeightSM ?? 16,
        trackMinWidth: trackMinWidth ?? 44,
        trackMinWidthSM: trackMinWidthSM ?? 28,
        handleSize: handleSize ?? 18,
        handleSizeSM: handleSizeSM ?? 12,
        colorPrimary: colorPrimary ?? t.primary.base,
        colorBg: colorBg ?? t.colorTextQuaternary,
      );
}

@immutable
class _ResolvedSwitchToken {
  const _ResolvedSwitchToken({
    required this.trackHeight,
    required this.trackHeightSM,
    required this.trackMinWidth,
    required this.trackMinWidthSM,
    required this.handleSize,
    required this.handleSizeSM,
    required this.colorPrimary,
    required this.colorBg,
  });

  final double trackHeight;
  final double trackHeightSM;
  final double trackMinWidth;
  final double trackMinWidthSM;
  final double handleSize;
  final double handleSizeSM;
  final Color colorPrimary;
  final Color colorBg;
}

/// A toggle for an immediate on/off setting — flipping it should take effect at
/// once, with no separate save step.
///
/// ```dart
/// Switch(
///   value: _wifiOn,
///   onChanged: (v) => setState(() => _wifiOn = v),
/// )
/// ```
///
/// For a choice confirmed later by a form submit, prefer a checkbox.
class Switch extends StatefulWidget {
  /// Creates a [Switch].
  const Switch({
    super.key,
    required this.value,
    this.onChanged,
    this.size = SwitchSize.defaultSize,
    this.disabled = false,
    this.loading = false,
    this.checkedChild,
    this.uncheckedChild,
    this.token,
  });

  /// Whether the switch is on.
  final bool value;

  /// Called with the new state when toggled. Null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// Which size preset to use.
  final SwitchSize size;

  /// Greys the switch out and blocks toggling.
  final bool disabled;

  /// Shows a spinner on the thumb and blocks toggling — for a setting whose
  /// change is being persisted.
  final bool loading;

  /// Small label shown inside the track when on.
  final Widget? checkedChild;

  /// Small label shown inside the track when off.
  final Widget? uncheckedChild;

  /// Per-instance token overrides.
  final SwitchToken? token;

  @override
  State<Switch> createState() => _SoftSwitchState();
}

class _SoftSwitchState extends State<Switch> {
  bool _pressed = false;

  bool get _enabled =>
      !widget.disabled && !widget.loading && widget.onChanged != null;

  bool get _small => widget.size == SwitchSize.small;

  double _height(_ResolvedSwitchToken r) =>
      _small ? r.trackHeightSM : r.trackHeight;
  double _width(_ResolvedSwitchToken r) =>
      _small ? r.trackMinWidthSM : r.trackMinWidth;
  double _thumb(_ResolvedSwitchToken r) =>
      _small ? r.handleSizeSM : r.handleSize;

  void _toggle() {
    if (_enabled) widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<SwitchToken>(context) ??
            const SwitchToken())
        ._resolve(token);
    final on = widget.value;

    final base = on ? r.colorPrimary : r.colorBg;
    final trackColor = _enabled ? base : base.withValues(alpha: base.a * 0.4);
    final thumbSize = _thumb(r);

    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedContainer(
          duration: token.motionDurationMid,
          curve: token.motionEaseInOut,
          width: _width(r),
          height: _height(r),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(_height(r)),
          ),
          child: Stack(
            children: [
              if (widget.checkedChild != null || widget.uncheckedChild != null)
                _buildLabel(token, on, thumbSize),
              AnimatedAlign(
                duration: token.motionDurationMid,
                curve: token.motionEaseInOut,
                // The thumb rests at the start when off and travels to the
                // end when on — a direction of travel, not a side, so it
                // turns over with the language as Material's own switch does.
                alignment: on
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: AnimatedContainer(
                  duration: token.motionDurationFast,
                  curve: token.motionEaseInOut,
                  // A pressed thumb stretches slightly.
                  width: _pressed ? thumbSize + 4 : thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(thumbSize),
                    boxShadow: token.boxShadowSecondary,
                  ),
                  child: widget.loading
                      ? Center(
                          child: Spinner(
                            size: thumbSize * 0.85,
                            color: on ? token.primary.base : _offColor(token),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _offColor(Token token) =>
      _pressed ? token.colorTextTertiary : token.colorTextQuaternary;

  Widget _buildLabel(Token token, bool on, double thumbSize) {
    // The active label hugs the side away from the thumb, so it stays visible.
    return Positioned.fill(
      child: Padding(
        // Clear of wherever the thumb is resting.
        padding: EdgeInsetsDirectional.only(
          start: on ? 6 : thumbSize + 4,
          end: on ? thumbSize + 4 : 6,
        ),
        child: Align(
          alignment: on
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: const Color(0xFFFFFFFF),
              fontSize: token.fontSizeSM,
              fontFamily: token.fontFamily,
              fontFamilyFallback: token.fontFamilyFallback,
              decoration: TextDecoration.none,
            ),
            child: IconTheme.merge(
              data: const IconThemeData(color: Color(0xFFFFFFFF), size: 12),
              child: (on ? widget.checkedChild : widget.uncheckedChild) ??
                  const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
