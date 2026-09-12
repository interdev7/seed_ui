import 'package:flutter/widgets.dart';

import '../../icons/icons.dart' show Spinner;
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/size_resolver.dart';

/// Per-component design tokens for [Switch].
///
/// Defaults for every [Switch] under a `ConfigProvider`.
///
/// The widget's own props, not its numbers — those are [SwitchToken].
@immutable
class SwitchDefaults {
  /// Creates a [SwitchDefaults].
  const SwitchDefaults({
    this.size,
    this.disabled,
  });

  /// Which size switches take.
  final ControlSize? size;

  /// Whether switches are barred.
  final bool? disabled;
}

/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(switchToken: SwitchToken(...)))`,
/// or per instance via [Switch.token].
@immutable
class SwitchToken {
  /// Creates a [SwitchToken].
  const SwitchToken({
    this.trackHeight,
    this.trackHeightSM,
    this.trackHeightLG,
    this.trackMinWidth,
    this.trackMinWidthSM,
    this.handleSize,
    this.handleSizeSM,
    this.handleShadow,
    this.colorPrimary,
    this.colorBg,
  });

  /// Height of default switch track (`trackHeight`).
  final double? trackHeight;

  /// Height of small switch track (`trackHeightSM`).
  final double? trackHeightSM;

  /// Height of large switch track (`trackHeightLG`).
  final double? trackHeightLG;

  /// Min width of default switch track (`trackMinWidth`).
  final double? trackMinWidth;

  /// Min width of small switch track (`trackMinWidthSM`).
  final double? trackMinWidthSM;

  /// Size of default switch handle (`handleSize`).
  final double? handleSize;

  /// Size of small switch handle (`handleSizeSM`).
  final double? handleSizeSM;

  /// What the handle casts on the track (`handleShadow`).
  ///
  /// Null takes a shadow worked out from the handle's own size. The kit's
  /// `boxShadowSecondary` — which this used to borrow — is the three-layer
  /// shadow a popover floats on, twenty-eight pixels of blur and eight of
  /// spread around an eighteen-pixel handle: on screen it read as a grey
  /// disc sitting beside the switch rather than as a handle lifted off it.
  final List<BoxShadow>? handleShadow;

  /// Primary active track color (`colorPrimary`).
  final Color? colorPrimary;

  /// Inactive track background color (`colorBg`).
  final Color? colorBg;

  _ResolvedSwitchToken _resolve(Token t) => _ResolvedSwitchToken(
        trackHeight: trackHeight ?? 22,
        trackHeightSM: trackHeightSM ?? 16,
        trackHeightLG: trackHeightLG ?? 28,
        // Null here means "work it out from the height", which is what keeps
        // a switch of any height in proportion. A number overrides that for
        // the preset it belongs to.
        trackMinWidth: trackMinWidth,
        trackMinWidthSM: trackMinWidthSM,
        handleSize: handleSize,
        handleSizeSM: handleSizeSM,
        handleShadow: handleShadow,
        colorPrimary: colorPrimary ?? t.primary.base,
        colorBg: colorBg ?? t.colorTextQuaternary,
      );
}

@immutable
class _ResolvedSwitchToken {
  const _ResolvedSwitchToken({
    required this.trackHeight,
    required this.trackHeightSM,
    required this.trackHeightLG,
    required this.trackMinWidth,
    required this.trackMinWidthSM,
    required this.handleSize,
    required this.handleSizeSM,
    required this.handleShadow,
    required this.colorPrimary,
    required this.colorBg,
  });

  final double trackHeight;
  final double trackHeightSM;
  final double trackHeightLG;
  final double? trackMinWidth;
  final double? trackMinWidthSM;
  final double? handleSize;
  final double? handleSizeSM;
  final List<BoxShadow>? handleShadow;
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
    this.value,
    this.defaultValue,
    this.onChanged,
    this.size,
    this.disabled,
    this.loading = false,
    this.checkedChild,
    this.uncheckedChild,
    this.token,
    this.focusNode,
    this.autofocus = false,
  });

  /// Whether the switch is on. Null leaves the switch to drive itself (see
  /// [defaultValue]).
  final bool? value;

  /// Which way an uncontrolled switch starts. Defaults to off.
  final bool? defaultValue;

  /// Called with the new state when toggled.
  ///
  /// Null on a controlled switch — one given a [value] — makes it inert:
  /// nothing can change the value, so nothing does. An uncontrolled switch
  /// keeps its own state and flips whether or not anybody is listening.
  final ValueChanged<bool>? onChanged;

  /// How tall the track is: a preset, or a height of your own.
  ///
  /// Everything else is worked out from it — the track is twice as long as it
  /// is tall, and the handle sits inside with a gap of a eleventh of that
  /// height at each end — so a switch at any height is the same switch.
  ///
  /// Null takes what [SwitchDefaults.size] says, then what was set for the
  /// subtree, then [SoftSize.middle].
  final ControlSize? size;

  /// Greys the switch out and blocks toggling.
  final bool? disabled;

  /// Shows a spinner on the thumb and blocks toggling — for a setting whose
  /// change is being persisted.
  final bool loading;

  /// Small label shown inside the track when on.
  final Widget? checkedChild;

  /// Small label shown inside the track when off.
  final Widget? uncheckedChild;

  /// Per-instance token overrides.
  final SwitchToken? token;

  /// A focus node of your own, for a switch whose focus you drive yourself.
  ///
  /// Left null the switch keeps one. Either way it takes its turn in the tab
  /// order and answers Space and Enter.
  final FocusNode? focusNode;

  /// Whether the switch takes focus as soon as it is built.
  final bool autofocus;

  @override
  State<Switch> createState() => _SoftSwitchState();
}

class _SoftSwitchState extends State<Switch> {
  /// Whether this control is disabled: its own word, else the one set
  /// for the subtree, else no.
  bool get _disabled =>
      widget.disabled ??
      ConfigProvider.defaultsOf<SwitchDefaults>(context)?.disabled ??
      ConfigProvider.componentDisabledOf(context) ??
      false;

  bool _pressed = false;

  /// Whether the focus should be seen: only where it arrived by keyboard.
  bool _focusVisible = false;

  bool? _internal;

  /// What the switch shows: the value it was handed, else the one it has been
  /// keeping since it was last flipped, else where it started.
  bool get _on => widget.value ?? _internal ?? widget.defaultValue ?? false;

  /// A switch nobody is listening to is inert only while somebody else is
  /// driving it: `onChanged: null` on a controlled switch means the value can
  /// never change, which is Flutter's own reading. An uncontrolled one keeps
  /// its own state and has something to change whether or not it is heard.
  bool get _enabled =>
      !_disabled &&
      !widget.loading &&
      (widget.onChanged != null || widget.value == null);

  /// The size in force: this switch's own, else the one set for switches,
  /// else the one set for the subtree, else the standard preset.
  ControlSize get _size =>
      widget.size ??
      ConfigProvider.defaultsOf<SwitchDefaults>(context)?.size ??
      ConfigProvider.componentSizeOf(context) ??
      SoftSize.middle;

  /// The gap between the handle and the track, as a share of the height.
  ///
  /// A switch is drawn from its track height and nothing else: at the
  /// standard 22 these give back exactly the numbers the design started with
  /// — a 2px gap, an 18px handle, a 44px track — and at any other height the
  /// same switch, only bigger or smaller. The presets used to be drawn from
  /// six separate numbers that were not in proportion to one another: the
  /// small one was 1.75 track-heights long where the standard was 2, so the
  /// two were not the same switch at two sizes.
  static const double _padShare = 1 / 11;

  /// How long the track is, as a share of its height.
  static const double _lengthShare = 2;

  double _height(_ResolvedSwitchToken r) => _size.resolveHeight(
        small: r.trackHeightSM,
        middle: r.trackHeight,
        large: r.trackHeightLG,
      );

  double _pad(_ResolvedSwitchToken r) => _height(r) * _padShare;

  double _width(_ResolvedSwitchToken r) {
    final named = switch (_size) {
      SoftSize.small => r.trackMinWidthSM,
      SoftSize.middle => r.trackMinWidth,
      _ => null,
    };
    // A width of your own is a width, whatever the height says.
    return _size.explicitWidth ?? named ?? _height(r) * _lengthShare;
  }

  double _thumb(_ResolvedSwitchToken r) {
    final named = switch (_size) {
      SoftSize.small => r.handleSizeSM,
      SoftSize.middle => r.handleSize,
      _ => null,
    };
    return named ?? _height(r) - _pad(r) * 2;
  }

  void _toggle() {
    if (!_enabled) return;
    final next = !_on;
    // Kept in step whether or not somebody else is driving this: it is only
    // the fallback for `value`, and a stale one would show through the moment
    // `value` went null again.
    setState(() => _internal = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<SwitchToken>(context) ??
            const SwitchToken())
        ._resolve(token);
    final on = _on;

    final base = on ? r.colorPrimary : r.colorBg;
    final trackColor = _enabled ? base : base.withValues(alpha: base.a * 0.4);
    final thumbSize = _thumb(r);

    return FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: _enabled,
      onShowFocusHighlight: (visible) {
        if (_focusVisible != visible) setState(() => _focusVisible = visible);
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _toggle();
            return null;
          },
        ),
      },
      child: Semantics(
        toggled: _on,
        enabled: _enabled,
        onTap: _enabled ? _toggle : null,
        child: MouseRegion(
          cursor:
              _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel:
                _enabled ? () => setState(() => _pressed = false) : null,
            child: AnimatedContainer(
              duration: token.motionDurationMid,
              curve: token.motionEaseInOut,
              width: _width(r),
              height: _height(r),
              padding: EdgeInsets.all(_pad(r)),
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(_height(r)),
                boxShadow: _focusVisible && _enabled
                    ? [
                        BoxShadow(
                          color: r.colorPrimary.withValues(alpha: 0.12),
                          blurRadius: 0,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  if (widget.checkedChild != null ||
                      widget.uncheckedChild != null)
                    _buildLabel(token, on, thumbSize, _height(r), _pad(r)),
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
                      width: _pressed ? thumbSize + _pad(r) * 2 : thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(thumbSize),
                        boxShadow: r.handleShadow ??
                            [
                              // Sized to the handle, so a switch at any
                              // height is lifted by the same amount rather
                              // than sitting in a fixed puddle.
                              BoxShadow(
                                color: const Color.fromRGBO(0, 0, 0, 0.16),
                                offset: Offset(0, thumbSize * 0.11),
                                blurRadius: thumbSize * 0.22,
                              ),
                            ],
                      ),
                      child: widget.loading
                          ? Center(
                              child: Spinner(
                                size: thumbSize * 0.85,
                                color:
                                    on ? token.primary.base : _offColor(token),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _offColor(Token token) =>
      _pressed ? token.colorTextTertiary : token.colorTextQuaternary;

  Widget _buildLabel(
    Token token,
    bool on,
    double thumbSize,
    double height,
    double pad,
  ) {
    // The label is drawn from the same height as everything else, so it keeps
    // its place in a switch of any size rather than sitting against the edge
    // of a big one and overflowing a small one.
    final scale = height / 22;
    // The active label hugs the side away from the thumb, so it stays visible.
    return Positioned.fill(
      child: Padding(
        // Clear of wherever the thumb is resting.
        padding: EdgeInsetsDirectional.only(
          start: on ? pad * 3 : thumbSize + pad * 2,
          end: on ? thumbSize + pad * 2 : pad * 3,
        ),
        child: Align(
          alignment: on
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: const Color(0xFFFFFFFF),
              fontSize: token.fontSizeSM * scale,
              fontFamily: token.fontFamily,
              fontFamilyFallback: token.fontFamilyFallback,
              decoration: TextDecoration.none,
            ),
            child: IconTheme.merge(
              data: IconThemeData(
                color: const Color(0xFFFFFFFF),
                size: 12 * scale,
              ),
              child: (on ? widget.checkedChild : widget.uncheckedChild) ??
                  const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
