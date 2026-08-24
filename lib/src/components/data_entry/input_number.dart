import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import 'input.dart';

/// Per-component design tokens for [InputNumber].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(inputNumber: InputNumberToken(...)))`,
/// or per instance via [InputNumber.token].
@immutable
class InputNumberToken {
  /// Creates an [InputNumberToken].
  const InputNumberToken({
    this.controlWidth,
    this.spinnerWidth,
    this.handleWidth,
    this.handleBg,
    this.handleActiveBg,
    this.handleHoverBg,
    this.handleHoverColor,
    this.handleBorderColor,
  });

  /// Width of the stepper control column (`handleWidth` / `controlWidth`).
  final double? controlWidth;

  /// How wide a [InputNumberMode.spinner] control is drawn.
  ///
  /// A spinner is a stepper, not a text field: it is as wide as the two
  /// buttons and the number between them, and it does not stretch to whatever
  /// its parent offers. Widen it here if the numbers are long.
  final double? spinnerWidth;

  /// Width of individual handle button (`handleWidth`).
  final double? handleWidth;

  /// Background color of handles (`handleBg`).
  final Color? handleBg;

  /// Active background color of handles (`handleActiveBg`).
  final Color? handleActiveBg;

  /// Hover background color of handles (`handleHoverBg`).
  ///
  /// Transparent by default: The control answers a hover on the chevron itself
  /// rather than with a filled block. Set one only to bring the block back.
  final Color? handleHoverBg;

  /// Chevron colour under the pointer (`handleHoverColor`). Defaults to the
  /// primary accent.
  final Color? handleHoverColor;

  /// Border color between handles (`handleBorderColor`).
  final Color? handleBorderColor;

  _ResolvedInputNumberToken _resolve(Token t) => _ResolvedInputNumberToken(
        controlWidth: controlWidth ?? 22,
        // Two buttons plus room for four digits between them.
        spinnerWidth:
            spinnerWidth ?? (controlWidth ?? 22) * 2 + t.size * 2 + 64,
        handleWidth: handleWidth ?? 22,
        handleBg: handleBg ?? t.colorBgContainer,
        // The kit washes the handle only while it is pressed, and faintly.
        handleActiveBg: handleActiveBg ?? t.colorFillQuaternary,
        handleHoverBg: handleHoverBg ?? const Color(0x00000000),
        handleHoverColor: handleHoverColor ?? t.primary.base,
        handleBorderColor: handleBorderColor ?? t.colorBorderSecondary,
      );
}

@immutable
class _ResolvedInputNumberToken {
  const _ResolvedInputNumberToken({
    required this.controlWidth,
    required this.spinnerWidth,
    required this.handleWidth,
    required this.handleBg,
    required this.handleActiveBg,
    required this.handleHoverBg,
    required this.handleHoverColor,
    required this.handleBorderColor,
  });

  final double controlWidth;
  final double spinnerWidth;
  final double handleWidth;
  final Color handleBg;
  final Color handleActiveBg;
  final Color handleHoverBg;
  final Color handleHoverColor;
  final Color handleBorderColor;
}

/// A numeric input with stepper buttons.
///
/// ```dart
/// InputNumber(
///   value: _qty,
///   min: 0,
///   max: 10,
///   onChanged: (v) => setState(() => _qty = v),
/// )
/// ```
///
/// Drive it controlled with [value] + [onChanged], or uncontrolled with
/// [defaultValue]. The value is clamped to [min]/[max], stepped by [step], and
/// (when [precision] is set) rounded to that many decimals.
class InputNumber extends StatefulWidget {
  /// Creates an [InputNumber].
  const InputNumber({
    super.key,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.precision,
    this.disabled = false,
    this.readOnly = false,
    this.controls = true,
    this.mode = InputNumberMode.handles,
    this.keyboard = true,
    this.size = SoftSize.middle,
    this.status,
    this.placeholder,
    this.prefix,
    this.suffix,
    this.formatter,
    this.onSubmitted,
    this.parser,
    this.focusNode,
    this.token,
  });

  /// Per-instance token overrides.
  final InputNumberToken? token;

  /// The current value. Null makes the field uncontrolled (see [defaultValue]).
  final num? value;

  /// Initial value for an uncontrolled field.
  final num? defaultValue;

  /// Called with the new value (null when the field is emptied).
  final ValueChanged<num?>? onChanged;

  /// Minimum allowed value.
  final num? min;

  /// Maximum allowed value.
  final num? max;

  /// Amount added or removed per step.
  final num step;

  /// Decimal places to round to. Null keeps the value as typed.
  final int? precision;

  /// Greys the field out and blocks interaction.
  final bool disabled;

  /// Shows the value but blocks editing (steppers still work).
  final bool readOnly;

  /// Shows the up/down stepper buttons.
  final bool controls;

  /// Handles at the edge, or a minus/plus pair around a centred value.
  final InputNumberMode mode;

  /// Whether ↑/↓ arrow keys step the value.
  final bool keyboard;

  /// Which height preset to use.
  final SoftSize size;

  /// A validation status that recolours the border.
  final InputStatus? status;

  /// Grey hint shown while the field is empty.
  final String? placeholder;

  /// Widget shown inside the border, before the number.
  final Widget? prefix;

  /// Widget shown after the number (before the steppers).
  final Widget? suffix;

  /// Formats the value for display, e.g. adding a `$` or thousands separators.
  final String Function(num value)? formatter;

  /// Called when the user submits (e.g. presses enter on a single-line field).
  final ValueChanged<String>? onSubmitted;

  /// Parses typed text back into a number, undoing [formatter].
  final num? Function(String text)? parser;

  /// The field's focus node. Null lets it create and own one.
  final FocusNode? focusNode;

  @override
  State<InputNumber> createState() => _InputNumberState();
}

class _InputNumberState extends State<InputNumber> {
  final TextEditingController _controller = TextEditingController();
  FocusNode? _ownFocus;
  FocusNode get _focusNode => widget.focusNode ?? (_ownFocus ??= FocusNode());

  num? _internal;
  num? get _current => widget.value ?? _internal ?? widget.defaultValue;

  bool get _enabled => !widget.disabled;

  bool _hovered = false;
  bool _focused = false;

  // The spinner is hidden at rest and slides in on hover or focus.
  bool get _spinnerVisible => _enabled && (_hovered || _focused);

  @override
  void initState() {
    super.initState();
    _internal = widget.defaultValue;
    _controller.text = _format(_current);
    _focusNode.addListener(_onFocusChange);
    _focusNode.onKeyEvent = _handleKey;
  }

  @override
  void didUpdateWidget(InputNumber old) {
    super.didUpdateWidget(old);
    // Reflect a controlled value change while the field isn't being edited.
    if (widget.value != old.value && !_focusNode.hasFocus) {
      _controller.text = _format(_current);
    }
    if (old.focusNode != widget.focusNode) {
      _focusNode.onKeyEvent = _handleKey;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _ownFocus?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Commit and reformat when focus leaves the field.
    if (!_focusNode.hasFocus) _commit(_controller.text);
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  String _format(num? v) {
    if (v == null) return '';
    if (widget.formatter != null) return widget.formatter!(v);
    if (widget.precision != null) return v.toStringAsFixed(widget.precision!);
    // Trim a redundant ".0" so whole numbers read cleanly.
    if (v == v.roundToDouble()) return v.toInt().toString();
    return '$v';
  }

  num _clamp(num v) {
    var out = v;
    if (widget.min != null && out < widget.min!) out = widget.min!;
    if (widget.max != null && out > widget.max!) out = widget.max!;
    if (widget.precision != null) {
      out = num.parse(out.toStringAsFixed(widget.precision!));
    }
    return out;
  }

  void _emit(num? v) {
    if (widget.value == null) setState(() => _internal = v);
    widget.onChanged?.call(v);
  }

  void _commit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _emit(null);
      _controller.text = '';
      return;
    }
    final parsed =
        widget.parser != null ? widget.parser!(trimmed) : num.tryParse(trimmed);
    if (parsed == null) {
      _controller.text = _format(_current); // revert invalid input
      return;
    }
    final next = _clamp(parsed);
    _emit(next);
    _controller.text = _format(next);
  }

  void _step(int direction) {
    if (!_enabled) return;
    final base = _current ?? widget.min ?? 0;
    final next = _clamp(base + widget.step * direction);
    _emit(next);
    _controller.text = _format(next);
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
  }

  bool get _canStepUp =>
      _enabled &&
      (widget.max == null || (_current ?? widget.min ?? 0) < widget.max!);
  bool get _canStepDown =>
      _enabled &&
      (widget.min == null || (_current ?? widget.max ?? 0) > widget.min!);

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!widget.keyboard || event is KeyUpEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _step(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _step(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<InputNumberToken>(context) ??
            const InputNumberToken())
        ._resolve(token);
    final spinner = widget.controls && widget.mode == InputNumberMode.spinner;

    final field = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Input(
        controller: _controller,
        // Spinner mode centres the value between its two buttons and lets them
        // reach the border on both sides.
        textAlign: spinner ? TextAlign.center : TextAlign.start,
        prefixFlush: spinner,
        focusNode: _focusNode,
        size: widget.size,
        status: widget.status,
        disabled: widget.disabled,
        readOnly: widget.readOnly,
        placeholder: widget.placeholder,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        inputFormatters: [
          // Digits, an optional sign and a single decimal point.
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
        ],
        onSubmitted: (value) {
          widget.onSubmitted?.call(value);
          _commit(value);
        },
        prefix: spinner
            ? _StepButton(
                token: token,
                componentToken: r,
                height: _controlHeight(token),
                direction: _StepDirection.down,
                enabled: _canStepDown,
                onPressed: () => _step(-1),
                trailing: false,
              )
            : widget.prefix,
        suffixFlush: widget.controls,
        suffix: spinner
            ? _StepButton(
                token: token,
                componentToken: r,
                height: _controlHeight(token),
                direction: _StepDirection.up,
                enabled: _canStepUp,
                onPressed: () => _step(1),
                trailing: true,
              )
            : widget.controls
                ? _Spinner(
                    token: token,
                    componentToken: r,
                    height: _controlHeight(token),
                    visible: _spinnerVisible,
                    upEnabled: _canStepUp,
                    downEnabled: _canStepDown,
                    onUp: () => _step(1),
                    onDown: () => _step(-1),
                  )
                : widget.suffix,
      ),
    );

    if (!spinner) return field;

    // A spinner is a stepper, not a text field: it is as wide as its two
    // buttons and the number between them. Align hands its child loose
    // constraints, so a parent that stretches its children — a `Column` with
    // `crossAxisAlignment: stretch`, a wide page — cannot blow it across the
    // screen. `spinnerWidth` on the token is how you widen it.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(width: r.spinnerWidth, child: field),
    );
  }

  double _controlHeight(Token t) => switch (widget.size) {
        SoftSize.small => t.controlHeightSM,
        SoftSize.middle => t.controlHeight,
        SoftSize.large => t.controlHeightLG,
      };
}

/// The vertical up/down spinner shown at the right of an [InputNumber]: two
/// [SpinButton]s split by a 1px divider, with a divider to their left
/// separating them from the number — the InputNumber handlers.
class _Spinner extends StatefulWidget {
  const _Spinner({
    required this.token,
    required this.componentToken,
    required this.height,
    required this.visible,
    required this.upEnabled,
    required this.downEnabled,
    required this.onUp,
    required this.onDown,
  });

  final Token token;
  final _ResolvedInputNumberToken componentToken;
  final double height;
  final bool visible;
  final bool upEnabled;
  final bool downEnabled;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner> {
  // 1 = up hovered, -1 = down hovered, 0 = none.
  int _hovered = 0;

  static const _duration = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    final token = widget.token;
    final r = widget.componentToken;
    // Fit inside the input's border; the two buttons share the height with a
    // single 1px divider and no gap.
    final inner = widget.height - token.lineWidth * 2;
    final base = (inner - token.lineWidth) / 2;
    // The hovered button grows 2px; the other shrinks 2px so the total — and
    // thus the divider — stays put, while each chevron stays centred in its
    // own (animating) button.
    const grow = 3.0;
    final upH = base + (_hovered == 1 ? grow : (_hovered == -1 ? -grow : 0.0));
    final downH =
        base + (_hovered == -1 ? grow : (_hovered == 1 ? -grow : 0.0));

    final hover = r.handleHoverBg;
    final pressed = r.handleActiveBg;
    final icon = token.colorTextTertiary;
    final iconHover = r.handleHoverColor;

    final spinner = Container(
      height: inner,
      width: r.controlWidth,
      decoration: BoxDecoration(
        // The rule divides the field from the handles, so it belongs on the
        // handles' leading edge rather than their left one.
        border: BorderDirectional(
          start: BorderSide(color: r.handleBorderColor, width: token.lineWidth),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpinButton(
            direction: SpinDirection.up,
            enabled: widget.upEnabled,
            height: upH,
            onPressed: widget.onUp,
            onHoverChanged: (h) => setState(() => _hovered = h ? 1 : 0),
            hoverColor: hover,
            pressedColor: pressed,
            iconColor: icon,
            iconHoverColor: iconHover,
            duration: _duration,
          ),
          Container(height: token.lineWidth, color: r.handleBorderColor),
          SpinButton(
            direction: SpinDirection.down,
            enabled: widget.downEnabled,
            height: downH,
            onPressed: widget.onDown,
            onHoverChanged: (h) => setState(() => _hovered = h ? -1 : 0),
            hoverColor: hover,
            pressedColor: pressed,
            iconColor: icon,
            iconHoverColor: iconHover,
            duration: _duration,
          ),
        ],
      ),
    );

    // Hidden at rest; slides in from the right and fades in on hover/focus.
    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedSlide(
        offset: widget.visible ? Offset.zero : const Offset(0.5, 0),
        duration: _duration,
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: widget.visible ? 1 : 0,
          duration: _duration,
          curve: Curves.easeOut,
          child: spinner,
        ),
      ),
    );
  }
}

/// Which end of a spinner a button sits at.
enum _StepDirection { up, down }

/// A full-height minus or plus for [InputNumberMode.spinner].
///
/// Reaches the input's border on its own side and is parted from the value by
/// a single hairline — the arrangement the spinner mode draws.
class _StepButton extends StatefulWidget {
  const _StepButton({
    required this.token,
    required this.componentToken,
    required this.height,
    required this.direction,
    required this.enabled,
    required this.onPressed,
    required this.trailing,
  });

  final Token token;
  final _ResolvedInputNumberToken componentToken;
  final double height;
  final _StepDirection direction;
  final bool enabled;
  final VoidCallback onPressed;

  /// True for the plus at the trailing edge, false for the minus at the lead.
  final bool trailing;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    final r = widget.componentToken;
    final active = widget.enabled;
    final ink = !active
        ? t.colorTextQuaternary
        : (_hovered ? r.handleHoverColor : t.colorTextTertiary);

    return MouseRegion(
      cursor: active ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: t.motionDurationMid,
          curve: t.motionEaseInOut,
          width: r.controlWidth + t.size,
          height: widget.height - t.lineWidth * 2,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _pressed && active ? r.handleActiveBg : null,
            // The rule goes between the handle and the field, whichever side
            // the handle was put on.
            border: BorderDirectional(
              start: widget.trailing
                  ? BorderSide(color: r.handleBorderColor, width: t.lineWidth)
                  : BorderSide.none,
              end: widget.trailing
                  ? BorderSide.none
                  : BorderSide(color: r.handleBorderColor, width: t.lineWidth),
            ),
          ),
          child: CustomPaint(
            size: const Size(12, 12),
            painter: _SignPainter(
              ink,
              plus: widget.direction == _StepDirection.up,
            ),
          ),
        ),
      ),
    );
  }
}

/// A minus, or a plus when [plus] is set.
class _SignPainter extends CustomPainter {
  const _SignPainter(this.color, {required this.plus});

  final Color color;
  final bool plus;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final c = size.center(Offset.zero);
    final arm = size.width / 2;
    canvas.drawLine(Offset(c.dx - arm, c.dy), Offset(c.dx + arm, c.dy), paint);
    if (plus) {
      canvas.drawLine(
        Offset(c.dx, c.dy - arm),
        Offset(c.dx, c.dy + arm),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SignPainter old) =>
      old.color != color || old.plus != plus;
}

/// How an [InputNumber] presents its controls.
enum InputNumberMode {
  /// Stacked up/down handles at the trailing edge (the default).
  handles,

  /// A minus, the value centred between them, and a plus — for a quantity a
  /// thumb has to hit.
  spinner,
}

/// Which way a [SpinButton] steps.
enum SpinDirection {
  /// The handle that increments the value.
  up,

  /// The handle that decrements the value.
  down
}

/// One increment/decrement control of an [InputNumber] spinner: on hover the
/// button grows a little (the parent shrinks its sibling to match) while its
/// chevron stays centred, with a hover/pressed background and no Material
/// ripple or elevation.
class SpinButton extends StatefulWidget {
  /// Creates a [SpinButton].
  const SpinButton({
    super.key,
    required this.direction,
    required this.onPressed,
    required this.hoverColor,
    required this.pressedColor,
    required this.iconColor,
    this.iconHoverColor,
    required this.height,
    this.enabled = true,
    this.width = 20,
    this.onHoverChanged,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeOut,
  });

  /// Whether this is the up or down control.
  final SpinDirection direction;

  /// Tap handler. Combined with [enabled] to decide if the button is active.
  final VoidCallback? onPressed;

  /// Background under the pointer. Transparent by default — a hover shows in
  /// the chevron ([iconHoverColor]) rather than as a filled block.
  final Color hoverColor;

  /// Pressed background colour (slightly darker than [hoverColor]).
  final Color pressedColor;

  /// Chevron colour when active.
  final Color iconColor;

  /// Chevron colour under the pointer. Null keeps [iconColor].
  final Color? iconHoverColor;

  /// Height of the button's hit/paint area. Animated when it changes.
  final double height;

  /// Greys the chevron and blocks interaction when false.
  final bool enabled;

  /// Width of the button.
  final double width;

  /// Called when the pointer enters (true) or leaves (false), so a parent can
  /// resize this button and its sibling.
  final ValueChanged<bool>? onHoverChanged;

  /// Background and height animation duration.
  final Duration duration;

  /// Background and height animation curve.
  final Curve curve;

  @override
  State<SpinButton> createState() => _SpinButtonState();
}

class _SpinButtonState extends State<SpinButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _active => widget.enabled && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final bg = _pressed && _active
        ? widget.pressedColor
        : _hovered && _active
            ? widget.hoverColor
            : const Color(0x00000000);

    return MouseRegion(
      cursor: _active ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) {
        if (_active) {
          setState(() => _hovered = true);
          widget.onHoverChanged?.call(true);
        }
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
          _pressed = false;
        });
        if (_active) {
          widget.onHoverChanged?.call(false);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: _active ? () => setState(() => _pressed = false) : null,
        onTap: _active ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: widget.duration,
          curve: widget.curve,
          width: widget.width,
          height: widget.height,
          // The chevron stays centred as the button height animates.
          alignment: Alignment.center,
          color: bg,
          // The control answers a hover by lighting the chevron up, not by
          // washing the whole handle grey.
          child: CustomPaint(
            size: const Size(12, 12),
            painter: _ChevronPainter(
              !_active
                  ? widget.iconColor.withValues(alpha: 0.4)
                  : (_hovered
                      ? (widget.iconHoverColor ?? widget.iconColor)
                      : widget.iconColor),
              up: widget.direction == SpinDirection.up,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color, {required this.up});

  final Color color;
  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    // A compact chevron centred in the box.
    final path = up
        ? (Path()
          ..moveTo(w * 0.3, h * 0.58)
          ..lineTo(w * 0.5, h * 0.42)
          ..lineTo(w * 0.7, h * 0.58))
        : (Path()
          ..moveTo(w * 0.3, h * 0.42)
          ..lineTo(w * 0.5, h * 0.58)
          ..lineTo(w * 0.7, h * 0.42));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color || old.up != up;
}
