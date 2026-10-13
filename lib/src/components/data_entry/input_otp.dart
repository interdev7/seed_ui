import 'package:flutter/material.dart' show AdaptiveTextSelectionToolbar;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/size_resolver.dart';
import 'input.dart' show InputStatus;

/// Which characters an [InputOtp] takes.
enum InputOtpCharacters {
  /// `0`–`9`, with a keypad of digits on a phone.
  digits,

  /// Letters and digits; letters are kept as typed.
  alphanumeric,

  /// Anything but whitespace.
  any,
}

/// Per-component design tokens for [InputOtp].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(inputOtp: InputOtpToken(...)))`, or per instance via
/// [InputOtp.token].
@immutable
class InputOtpToken {
  /// Creates an [InputOtpToken].
  const InputOtpToken({
    this.gap,
    this.cellWidth,
    this.colorBorder,
    this.activeBorderColor,
    this.hoverBorderColor,
    this.cellBg,
    this.disabledCellBg,
    this.colorText,
    this.caretColor,
    this.borderRadius,
    this.fontSize,
  });

  /// Space between two cells.
  final double? gap;

  /// How wide a cell is. Null makes it as wide as it is tall.
  final double? cellWidth;

  /// A cell's border at rest.
  final Color? colorBorder;

  /// The border of the cell the next character goes into.
  final Color? activeBorderColor;

  /// A cell's border under the pointer.
  final Color? hoverBorderColor;

  /// A cell's fill.
  final Color? cellBg;

  /// A cell's fill while the field is disabled.
  final Color? disabledCellBg;

  /// The characters.
  final Color? colorText;

  /// The caret that blinks in an empty cell.
  final Color? caretColor;

  /// A cell's corners.
  final double? borderRadius;

  /// The characters' size for a middle field; small and large step one size
  /// down and up from it.
  final double? fontSize;

  _ResolvedInputOtpToken _resolve(Token t) => _ResolvedInputOtpToken(
        gap: gap ?? t.sizeXS,
        cellWidth: cellWidth,
        colorBorder: colorBorder ?? t.colorBorder,
        activeBorderColor: activeBorderColor ?? t.primary.base,
        hoverBorderColor: hoverBorderColor ?? t.primary.borderHover,
        cellBg: cellBg ?? t.colorBgContainer,
        disabledCellBg: disabledCellBg ?? t.colorFillTertiary,
        colorText: colorText ?? t.colorText,
        caretColor: caretColor ?? t.primary.base,
        borderRadius: borderRadius ?? t.borderRadius,
        fontSize: fontSize ?? t.fontSizeLG,
      );

  /// This one with [other]'s fields laid over it, one field at a time.
  InputOtpToken merge(InputOtpToken other) => InputOtpToken(
        gap: other.gap ?? gap,
        cellWidth: other.cellWidth ?? cellWidth,
        colorBorder: other.colorBorder ?? colorBorder,
        activeBorderColor: other.activeBorderColor ?? activeBorderColor,
        hoverBorderColor: other.hoverBorderColor ?? hoverBorderColor,
        cellBg: other.cellBg ?? cellBg,
        disabledCellBg: other.disabledCellBg ?? disabledCellBg,
        colorText: other.colorText ?? colorText,
        caretColor: other.caretColor ?? caretColor,
        borderRadius: other.borderRadius ?? borderRadius,
        fontSize: other.fontSize ?? fontSize,
      );
}

@immutable
class _ResolvedInputOtpToken {
  const _ResolvedInputOtpToken({
    required this.gap,
    required this.cellWidth,
    required this.colorBorder,
    required this.activeBorderColor,
    required this.hoverBorderColor,
    required this.cellBg,
    required this.disabledCellBg,
    required this.colorText,
    required this.caretColor,
    required this.borderRadius,
    required this.fontSize,
  });

  final double gap;
  final double? cellWidth;
  final Color colorBorder;
  final Color activeBorderColor;
  final Color hoverBorderColor;
  final Color cellBg;
  final Color disabledCellBg;
  final Color colorText;
  final Color caretColor;
  final double borderRadius;
  final double fontSize;
}

/// A code typed one character to a cell: the six digits a text message or an
/// authenticator app hands over.
///
/// ```dart
/// InputOtp(
///   length: 6,
///   semanticsLabel: 'Verification code',
///   onCompleted: (code) => verify(code),
/// )
/// ```
///
/// One field stands behind the cells, so a whole code pasted at once lands in
/// all of them, a phone offers the code from its messages, and Backspace walks
/// back. A tap on a cell puts the cursor there, and what is typed replaces
/// the character in it.
class InputOtp extends StatefulWidget {
  /// Creates an [InputOtp].
  const InputOtp({
    super.key,
    this.length = 6,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.onCompleted,
    this.characters = InputOtpCharacters.digits,
    this.mask,
    this.separator,
    this.size,
    this.status,
    this.disabled = false,
    this.autofocus = false,
    this.focusNode,
    this.semanticsLabel,
    this.token,
  }) : assert(length > 0, 'an InputOtp needs at least one cell');

  /// How many cells.
  final int length;

  /// The code, held from outside. Null lets the field keep its own, starting
  /// from [defaultValue].
  final String? value;

  /// The code the field starts with, when [value] is null.
  final String? defaultValue;

  /// Called with the code whenever it changes.
  final ValueChanged<String>? onChanged;

  /// Called with the code once every cell is filled.
  final ValueChanged<String>? onCompleted;

  /// Which characters the field takes; the rest are dropped, typed or
  /// pasted. Defaults to [InputOtpCharacters.digits].
  final InputOtpCharacters characters;

  /// Drawn in each filled cell in place of its character — `'•'` for a code
  /// that should not be read over a shoulder. A screen reader is not told
  /// the characters either.
  final String? mask;

  /// Drawn after the cell at the given index, before the next one: a dash
  /// in the middle of a six-digit code. Null between two cells draws
  /// nothing there.
  final Widget? Function(int index)? separator;

  /// How tall the cells are: [SoftSize.small], [SoftSize.middle] (the
  /// default), [SoftSize.large], or a measurement of your own.
  final ControlSize? size;

  /// Colours every cell's border as a warning or an error.
  final InputStatus? status;

  /// Greys the field out and takes no input.
  final bool disabled;

  /// Whether the field takes the focus as it appears.
  final bool autofocus;

  /// The field's focus, for moving it from outside.
  final FocusNode? focusNode;

  /// What a screen reader calls the field: "Verification code".
  final String? semanticsLabel;

  /// Per-instance token overrides.
  final InputOtpToken? token;

  @override
  State<InputOtp> createState() => _InputOtpState();
}

class _InputOtpState extends State<InputOtp>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller =
      TextEditingController(text: _clean(widget.value ?? widget.defaultValue));
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());
  final _editable = GlobalKey<EditableTextState>();
  late final AnimationController _blink;
  bool _hovered = false;

  String get _text => _controller.text;

  @override
  void initState() {
    super.initState();
    // Made here rather than on first use: a field never focused would make
    // it first in dispose, when a ticker may no longer be asked for.
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _focus.addListener(_onFocus);
    _controller.addListener(_onEdit);
  }

  @override
  void didUpdateWidget(InputOtp old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
    final value = widget.value;
    if (value != null && _clean(value) != _text) {
      final next = _clean(value);
      _controller.value = TextEditingValue(
        text: next,
        selection: _cursorAt(next, next.length),
      );
    }
    if (old.length != widget.length && _text.length > widget.length) {
      _controller.text = _text.substring(0, widget.length);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    _controller.dispose();
    _blink.dispose();
    super.dispose();
  }

  /// [raw] with only the characters the field takes, and no more of them
  /// than it has cells.
  String _clean(String? raw) {
    if (raw == null) return '';
    final kept = raw.characters.where(_accepts).join();
    return kept.characters.take(widget.length).toString();
  }

  bool _accepts(String c) => switch (widget.characters) {
        InputOtpCharacters.digits => RegExp(r'^[0-9]$').hasMatch(c),
        InputOtpCharacters.alphanumeric =>
          RegExp(r'^[\p{L}\p{N}]$', unicode: true).hasMatch(c),
        InputOtpCharacters.any => c.trim().isNotEmpty,
      };

  /// The cursor standing at cell [index]: on the character there, so what
  /// is typed next replaces it, or after the last one.
  TextSelection _cursorAt(String text, int index) {
    final at = index.clamp(0, text.length);
    return at < text.length
        ? TextSelection(baseOffset: at, extentOffset: at + 1)
        : TextSelection.collapsed(offset: at);
  }

  /// The cell the next character goes into.
  int get _active {
    final selection = _controller.selection;
    if (!selection.isValid) return _text.length.clamp(0, widget.length - 1);
    return selection.start.clamp(0, widget.length - 1);
  }

  String _last = '';

  void _onEdit() {
    final text = _text;
    if (text == _last) {
      setState(() {});
      return;
    }
    _last = text;
    _restartBlink();
    widget.onChanged?.call(text);
    if (text.length == widget.length) widget.onCompleted?.call(text);
    setState(() {});
  }

  void _onFocus() {
    if (!mounted) return;
    _restartBlink();
    setState(() {});
  }

  /// Whether the platform asks for less motion, read where reading the
  /// context is safe: the focus can go as the field is being taken down,
  /// and its context may not be asked anything then.
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  void _restartBlink() {
    if (_focus.hasFocus && !_still) {
      _blink
        ..value = 0
        ..repeat();
    } else {
      _blink
        ..stop()
        ..value = 0;
    }
  }

  void _tapCell(int index) {
    if (widget.disabled) return;
    _focus.requestFocus();
    _controller.selection = _cursorAt(_text, index);
    // The keyboard may have been put away with the focus still here.
    _editable.currentState?.requestKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<InputOtpToken>(context) ??
            const InputOtpToken())
        ._resolve(t);
    final size = widget.size ??
        ConfigProvider.componentSizeOf(context) ??
        SoftSize.middle;
    final height = size.resolveHeight(
      small: t.controlHeightSM,
      middle: t.controlHeight,
      large: t.controlHeightLG,
    );
    final preset = size.nearestPreset(
      small: t.controlHeightSM,
      middle: t.controlHeight,
      large: t.controlHeightLG,
    );
    final fontSize = switch (preset) {
      SoftSize.small => r.fontSize - (t.fontSizeLG - t.fontSize),
      SoftSize.middle => r.fontSize,
      SoftSize.large => r.fontSize + (t.fontSizeLG - t.fontSize),
    };
    final width = r.cellWidth ?? height;
    final focused = _focus.hasFocus && !widget.disabled;
    final style = TextStyle(
      color: r.colorText,
      fontSize: fontSize,
      fontFamily: t.fontFamily,
      fontFamilyFallback: t.fontFamilyFallback,
      height: 1,
      decoration: TextDecoration.none,
    );

    Color border(bool active) {
      if (widget.disabled) return r.colorBorder;
      final status = switch (widget.status) {
        InputStatus.error => t.error,
        InputStatus.warning => t.warning,
        null => null,
      };
      if (status != null) return active ? status.hover : status.base;
      if (active) return r.activeBorderColor;
      if (_hovered) return r.hoverBorderColor;
      return r.colorBorder;
    }

    Color ring() => switch (widget.status) {
          InputStatus.error => t.error.base,
          InputStatus.warning => t.warning.base,
          null => r.activeBorderColor,
        }
            .withValues(alpha: 0.12);

    Widget cell(int i) {
      final char = i < _text.length ? _text.characters.elementAt(i) : null;
      final active = focused && i == _active;
      final shown = char == null ? null : (widget.mask ?? char);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _tapCell(i),
        onLongPress: widget.disabled
            ? null
            : () => _editable.currentState?.showToolbar(),
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.disabled ? r.disabledCellBg : r.cellBg,
            borderRadius: BorderRadius.circular(r.borderRadius),
            border: Border.all(color: border(active), width: t.lineWidth),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: ring(),
                      blurRadius: 0,
                      spreadRadius: t.focusRingWidth,
                    ),
                  ]
                : null,
          ),
          child: shown != null
              ? Text(shown, style: style)
              : active
                  ? FadeTransition(
                      // On for the first half of each beat, off for the
                      // second, as a text cursor blinks.
                      opacity: _blink.drive(
                        TweenSequence([
                          TweenSequenceItem(
                              tween: ConstantTween(1.0), weight: 1),
                          TweenSequenceItem(
                              tween: ConstantTween(0.0), weight: 1),
                        ]),
                      ),
                      child: Container(
                        width: t.lineWidth,
                        height: fontSize,
                        color: r.caretColor,
                      ),
                    )
                  : null,
        ),
      );
    }

    final cells = <Widget>[];
    for (var i = 0; i < widget.length; i++) {
      if (i > 0) cells.add(SizedBox(width: r.gap));
      cells.add(cell(i));
      final sep = i < widget.length - 1 ? widget.separator?.call(i) : null;
      if (sep != null) {
        cells
          ..add(SizedBox(width: r.gap))
          // Dressed as the cells' characters, whatever stands around the
          // field: a bare Text otherwise took the page's style, or none.
          ..add(
            ExcludeSemantics(
              child: DefaultTextStyle(style: style, child: sep),
            ),
          );
      }
    }

    // The one field that does the typing, under the cells and out of sight.
    // A screen reader meets it, as the field it is; the cells say nothing.
    final field = Opacity(
      opacity: 0,
      alwaysIncludeSemantics: true,
      child: Semantics(
        label: widget.semanticsLabel,
        child: EditableText(
          key: _editable,
          controller: _controller,
          focusNode: _focus,
          readOnly: widget.disabled,
          autofocus: widget.autofocus,
          obscureText: widget.mask != null,
          style: style,
          cursorColor: const Color(0x00000000),
          backgroundCursorColor: const Color(0x00000000),
          showCursor: false,
          keyboardType: widget.characters == InputOtpCharacters.digits
              ? TextInputType.number
              : TextInputType.visiblePassword,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [_OtpFormatter(clean: _clean)],
          // A long press on a cell offers the platform's own menu — Paste,
          // for a code copied from somewhere else.
          contextMenuBuilder: (context, state) =>
              AdaptiveTextSelectionToolbar.editableText(
            editableTextState: state,
          ),
          rendererIgnoresPointer: true,
        ),
      ),
    );

    return MouseRegion(
      cursor:
          widget.disabled ? SystemMouseCursors.basic : SystemMouseCursors.text,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        children: [
          Positioned.fill(child: field),
          ExcludeSemantics(
            // A tap between two cells, or on a separator, lands on the row:
            // the cursor goes after the last character, where typing would
            // carry on.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _tapCell(_text.length),
              child: Row(mainAxisSize: MainAxisSize.min, children: cells),
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps the field to the characters it takes and the cells it has, and
/// leaves the cursor on the next character, so typing goes on replacing.
class _OtpFormatter extends TextInputFormatter {
  _OtpFormatter({required this.clean});

  final String Function(String raw) clean;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = clean(newValue.text);
    // How far the cursor got, counted in the characters that were kept.
    final typed = newValue.selection.isValid
        ? clean(newValue.text.substring(0, newValue.selection.extentOffset))
            .length
        : text.length;
    final at = typed.clamp(0, text.length);
    return TextEditingValue(
      text: text,
      selection: at < text.length
          ? TextSelection(baseOffset: at, extentOffset: at + 1)
          : TextSelection.collapsed(offset: at),
    );
  }
}
