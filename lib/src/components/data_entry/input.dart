import 'package:flutter/cupertino.dart'
    show cupertinoTextSelectionHandleControls;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart' show materialTextSelectionHandleControls;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';

/// A validation status that recolours a [Input]'s border.
enum InputStatus {
  /// An amber border — the value is questionable but accepted.
  warning,

  /// A red border — the value is not valid.
  error
}

/// Arguments passed to [CountConfig.formatter] when rendering a custom
/// character counter.
@immutable
class CountArgs {
  /// Creates a [CountArgs].
  const CountArgs({
    required this.value,
    required this.count,
    this.maxLength,
  });

  /// The current text.
  final String value;

  /// The counted length of [value] (per the configured strategy).
  final int count;

  /// The soft maximum, if one is set.
  final int? maxLength;
}

/// Character-count behaviour for a [Input]. Unlike [Input.maxLength]
/// (a hard cap enforced while typing), [max] is a *soft* limit: exceeding it
/// marks the field with a warning but does not truncate — unless
/// [exceedFormatter] is given.
@immutable
class CountConfig {
  /// Creates a [CountConfig].
  const CountConfig({
    this.max,
    this.strategy,
    this.show = false,
    this.formatter,
    this.exceedFormatter,
  });

  /// The soft maximum character count. Exceeding it warns but keeps the text.
  final int? max;

  /// Custom counting. The default counts UTF-16 code units; pass
  /// `(t) => t.characters.length` to count graphemes so an emoji counts as one.
  final int Function(String value)? strategy;

  /// Whether to render the counter beside the field.
  final bool show;

  /// Custom counter widget, overriding the default `count / max` text.
  final Widget Function(CountArgs args)? formatter;

  /// Clips the value when it exceeds [max]. Without it the field is not
  /// truncated, only warned. Runs as an input formatter while typing.
  final String Function(String value, int max)? exceedFormatter;

  /// The counted length of [value] under this config's strategy.
  int count(String value) => (strategy ?? (s) => s.length)(value);
}

/// Search-box behaviour for a [Input]: a trailing button (or icon) that
/// reports the value through [onSearch].
@immutable
class SearchConfig {
  /// Creates a [SearchConfig].
  const SearchConfig({
    this.enterButton = false,
    this.enterButtonLabel,
    this.loading = false,
    this.onSearch,
    this.searchIcon,
  });

  /// With no [enterButtonLabel]: `false` renders a plain search icon inside the
  /// field, `true` renders a primary search button on the right.
  final bool enterButton;

  /// A custom label for the attached primary button (implies a button).
  final Widget? enterButtonLabel;

  /// Shows a spinner on the search control while a search runs.
  final bool loading;

  /// Called with the value when the user clicks search or presses Enter.
  final ValueChanged<String>? onSearch;

  /// Replaces the default magnifier glyph.
  final Widget? searchIcon;

  bool get _attached => enterButton || enterButtonLabel != null;
}

/// Password behaviour for a [Input]: masks the text and, by default, offers
/// a reveal toggle.
@immutable
class PasswordConfig {
  /// Creates a [PasswordConfig].
  const PasswordConfig({
    this.visibilityToggle = true,
    this.iconRender,
    this.onVisibleChange,
  });

  /// Whether the reveal toggle is shown.
  final bool visibilityToggle;

  /// Custom toggle glyph. `visible` is whether the text is currently revealed.
  final Widget Function(bool visible)? iconRender;

  /// Called when the password's visibility toggles. `visible` is the new state.
  final ValueChanged<bool>? onVisibleChange;
}

/// Per-component design tokens for [Input].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(input: InputToken(...)))`,
/// or per instance via [Input.token].
@immutable
class InputToken {
  /// Creates an [InputToken].
  const InputToken({
    this.colorBorder,
    this.activeBorderColor,
    this.hoverBorderColor,
    this.colorBgContainer,
    this.colorText,
    this.colorTextPlaceholder,
    this.paddingInline,
    this.paddingInlineSM,
    this.paddingInlineLG,
    this.paddingBlock,
    this.paddingBlockSM,
    this.paddingBlockLG,
    this.borderRadius,
    this.borderRadiusSM,
    this.borderRadiusLG,
    this.fontSize,
    this.fontSizeSM,
    this.fontSizeLG,
  });

  /// Default border color (`colorBorder`).
  final Color? colorBorder;

  /// Border color when focused (`activeBorderColor`).
  final Color? activeBorderColor;

  /// Border color when hovered (`hoverBorderColor`).
  final Color? hoverBorderColor;

  /// Input background color (`colorBgContainer`).
  final Color? colorBgContainer;

  /// Input text color (`colorText`).
  final Color? colorText;

  /// Placeholder text color (`colorTextPlaceholder`).
  final Color? colorTextPlaceholder;

  /// Horizontal padding for middle size (`paddingInline`).
  final double? paddingInline;

  /// Horizontal padding for small size (`paddingInlineSM`).
  final double? paddingInlineSM;

  /// Horizontal padding for large size (`paddingInlineLG`).
  final double? paddingInlineLG;

  /// Vertical padding for middle size (`paddingBlock`).
  final double? paddingBlock;

  /// Vertical padding for small size (`paddingBlockSM`).
  final double? paddingBlockSM;

  /// Vertical padding for large size (`paddingBlockLG`).
  final double? paddingBlockLG;

  /// Corner radius for middle size (`borderRadius`).
  final double? borderRadius;

  /// Corner radius for small size (`borderRadiusSM`).
  final double? borderRadiusSM;

  /// Corner radius for large size (`borderRadiusLG`).
  final double? borderRadiusLG;

  /// Font size for middle size (`fontSize`).
  final double? fontSize;

  /// Font size for small size (`fontSizeSM`).
  final double? fontSizeSM;

  /// Font size for large size (`fontSizeLG`).
  final double? fontSizeLG;

  _ResolvedInputToken _resolve(Token t) => _ResolvedInputToken(
        colorBorder: colorBorder ?? t.colorBorder,
        activeBorderColor: activeBorderColor ?? t.primary.base,
        hoverBorderColor: hoverBorderColor ?? t.primary.borderHover,
        colorBgContainer: colorBgContainer ?? t.colorBgContainer,
        colorText: colorText ?? t.colorText,
        colorTextPlaceholder: colorTextPlaceholder ?? t.colorTextTertiary,
        paddingInline: paddingInline ?? t.sizeSM,
        paddingInlineSM: paddingInlineSM ?? t.sizeXS,
        paddingInlineLG: paddingInlineLG ?? t.size,
        paddingBlock: paddingBlock ?? 4,
        paddingBlockSM: paddingBlockSM ?? 1,
        paddingBlockLG: paddingBlockLG ?? 7,
        borderRadius: borderRadius ?? t.borderRadius,
        borderRadiusSM: borderRadiusSM ?? t.borderRadiusSM,
        borderRadiusLG: borderRadiusLG ?? t.borderRadiusLG,
        fontSize: fontSize ?? t.fontSize,
        fontSizeSM: fontSizeSM ?? t.fontSizeSM,
        fontSizeLG: fontSizeLG ?? t.fontSizeLG,
      );
}

@immutable
class _ResolvedInputToken {
  const _ResolvedInputToken({
    required this.colorBorder,
    required this.activeBorderColor,
    required this.hoverBorderColor,
    required this.colorBgContainer,
    required this.colorText,
    required this.colorTextPlaceholder,
    required this.paddingInline,
    required this.paddingInlineSM,
    required this.paddingInlineLG,
    required this.paddingBlock,
    required this.paddingBlockSM,
    required this.paddingBlockLG,
    required this.borderRadius,
    required this.borderRadiusSM,
    required this.borderRadiusLG,
    required this.fontSize,
    required this.fontSizeSM,
    required this.fontSizeLG,
  });

  final Color colorBorder;
  final Color activeBorderColor;
  final Color hoverBorderColor;
  final Color colorBgContainer;
  final Color colorText;
  final Color colorTextPlaceholder;
  final double paddingInline;
  final double paddingInlineSM;
  final double paddingInlineLG;
  final double paddingBlock;
  final double paddingBlockSM;
  final double paddingBlockLG;
  final double borderRadius;
  final double borderRadiusSM;
  final double borderRadiusLG;
  final double fontSize;
  final double fontSizeSM;
  final double fontSizeLG;
}

/// A single- or multi-line text field with the kit's styling: a bordered box
/// that brightens to the primary colour on focus, with optional affixes and a
/// clear button.
///
/// ```dart
/// Input(
///   placeholder: 'Username',
///   prefix: Icon(Icons.person_outline),
///   allowClear: true,
///   onChanged: (v) => setState(() => _name = v),
/// )
/// ```
///
/// Pass a [controller] to read or set the value, or leave it null and rely on
/// [onChanged] (with an optional [defaultValue] for the initial text). Use
/// [password] for a password field, [maxLines] above one for a text area,
/// [count] to show a character counter, or [search] for a search box.
class Input extends StatefulWidget {
  /// Creates an [Input].
  const Input({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.defaultValue,
    this.onChanged,
    this.onSubmitted,
    this.disabled,
    this.readOnly = false,
    this.allowClear = false,
    this.autofocus = false,
    this.prefix,
    this.suffix,
    this.suffixFlush = false,
    this.prefixFlush = false,
    this.size,
    this.status,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.count,
    this.search,
    this.password,
    this.token,
  });

  /// Controls the text. When null the field manages its own controller and
  /// reports changes through [onChanged].
  final TextEditingController? controller;

  /// An external focus node. When null the field owns one.
  final FocusNode? focusNode;

  /// Grey hint shown while the field is empty.
  final String? placeholder;

  /// Initial text for the field's own controller. Ignored when [controller] is
  /// supplied — set the controller's text instead.
  final String? defaultValue;

  /// Called on every edit.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits (e.g. presses enter on a single-line field).
  final ValueChanged<String>? onSubmitted;

  /// Greys the field out and blocks editing and focus.
  final bool? disabled;

  /// Shows the value but blocks editing. Unlike [disabled] it keeps normal
  /// colours and stays focusable and selectable.
  final bool readOnly;

  /// Shows a clear button while the field is non-empty and focused.
  final bool allowClear;

  /// Focuses the field when it first appears.
  final bool autofocus;

  /// Widget shown inside the border, before the text.
  final Widget? prefix;

  /// Widget shown inside the border, after the text (before the clear button).
  final Widget? suffix;

  /// Renders [suffix] flush against the inner right border — no leading gap, no
  /// secondary tint, no right padding — for full-height affixes such as an
  /// [InputNumber] spinner.
  final bool suffixFlush;

  /// The leading counterpart of [suffixFlush]: renders [prefix] flush against
  /// the inner left border, for a full-height affix such as an
  /// [InputNumberMode.spinner] minus button.
  final bool prefixFlush;

  /// Which height preset to use.
  final SoftSize? size;

  /// A validation status that recolours the border. Null is the normal state.
  final InputStatus? status;

  /// Maximum lines before scrolling. 1 is a single-line field; a higher value
  /// (or null) makes a text area.
  final int? maxLines;

  /// Minimum lines for a text area.
  final int? minLines;

  /// Hard cap on the number of characters, enforced while typing. For a soft,
  /// warn-only limit use [count]'s `max` instead.
  final int? maxLength;

  /// Horizontal alignment of the text and placeholder.
  final TextAlign textAlign;

  /// The soft-keyboard layout to request. Null lets the field pick one.
  final TextInputType? keyboardType;

  /// What the keyboard's action key does — send, next, done.
  final TextInputAction? textInputAction;

  /// Formatters applied to every edit, in order.
  final List<TextInputFormatter>? inputFormatters;

  /// Character-count display and soft-limit behaviour.
  final CountConfig? count;

  /// Turns the field into a search box with a trailing search control.
  final SearchConfig? search;

  /// Turns the field into a password field with masking and a reveal toggle.
  final PasswordConfig? password;

  /// Per-instance token overrides.
  final InputToken? token;

  @override
  State<Input> createState() => _SoftInputState();
}

class _SoftInputState extends State<Input> {
  /// Whether this control is disabled: its own word, else the one set
  /// for the subtree, else no.
  bool get _disabled =>
      widget.disabled ?? ConfigProvider.componentDisabledOf(context) ?? false;

  /// The size in force: this widget's own, else the one set for the
  /// subtree, else the standard preset.
  SoftSize get _size =>
      widget.size ?? ConfigProvider.componentSizeOf(context) ?? SoftSize.middle;

  TextEditingController? _ownController;
  TextEditingController get _controller =>
      widget.controller ??
      (_ownController ??= TextEditingController(text: widget.defaultValue));

  FocusNode? _ownFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  bool _focused = false;
  bool _hovered = false;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(Input old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocusNode)?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
    }
    if (old.controller != widget.controller) {
      (old.controller ?? _ownController)?.removeListener(_onTextChange);
      _controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChange);
    _ownController?.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  void _onTextChange() {
    // The placeholder, clear button and counter all depend on the current
    // text, so rebuild when any of them is in use.
    if ((widget.placeholder != null ||
            widget.allowClear ||
            widget.count?.show == true) &&
        mounted) {
      setState(() {});
    }
  }

  bool get _enabled => !_disabled;

  bool get _obscure => widget.password != null && _obscured;

  double _height(Token token) => switch (_size) {
        SoftSize.small => token.controlHeightSM,
        SoftSize.middle => token.controlHeight,
        SoftSize.large => token.controlHeightLG,
      };

  double _fontSize(_ResolvedInputToken r) => switch (_size) {
        SoftSize.small => r.fontSizeSM,
        SoftSize.middle => r.fontSize,
        SoftSize.large => r.fontSizeLG,
      };

  /// Whether the soft [count] limit is currently exceeded.
  bool get _countExceeded {
    final c = widget.count;
    if (c?.max == null) return false;
    return c!.count(_controller.text) > c.max!;
  }

  Color _borderColor(Token token) {
    if (!_enabled) return token.colorBorder;
    if (widget.status == InputStatus.error) {
      return _focused ? token.error.hover : token.error.base;
    }
    if (widget.status == InputStatus.warning || _countExceeded) {
      return _focused ? token.warning.hover : token.warning.base;
    }
    if (_focused) return token.primary.hover;
    if (_hovered) return token.primary.base;
    return token.colorBorder;
  }

  Color? _focusRing(Token token) {
    if (!_focused || !_enabled) return null;
    final group = switch (widget.status) {
      InputStatus.error => token.error,
      InputStatus.warning => token.warning,
      _ => _countExceeded ? token.warning : token.primary,
    };
    // A soft halo echoing the border colour, like the focus glow.
    return group.base.withValues(alpha: 0.12);
  }

  bool get _multiline => widget.maxLines == null || widget.maxLines! > 1;

  void _triggerSearch() => widget.search?.onSearch?.call(_controller.text);

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<InputToken>(context) ??
            const InputToken())
        ._resolve(token);
    final fontSize = _fontSize(r);
    final showClear =
        widget.allowClear && _enabled && _controller.text.isNotEmpty;
    final search = widget.search;
    final password = widget.password;
    final showReveal = password != null && password.visibilityToggle;

    final textStyle = TextStyle(
      color: _enabled ? token.colorText : token.colorTextQuaternary,
      fontSize: fontSize,
      fontFamily: token.fontFamily,
      fontFamilyFallback: token.fontFamilyFallback,
      height: _multiline ? 1.5 : 1.0,
      // Distribute the line-box leading evenly so a single line sits centred.
      leadingDistribution: TextLeadingDistribution.even,
    );

    final field = EditableText(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: widget.readOnly || !_enabled,
      obscureText: _obscure,
      autofocus: widget.autofocus,
      style: textStyle,
      textAlign: widget.textAlign,
      strutStyle: StrutStyle.fromTextStyle(textStyle, forceStrutHeight: true),
      cursorColor: token.primary.base,
      backgroundCursorColor: token.colorTextQuaternary,
      selectionColor: token.primary.base.withValues(alpha: 0.2),
      selectionControls: _selectionControls(),
      maxLines: _obscure ? 1 : widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType ??
          (_multiline ? TextInputType.multiline : TextInputType.text),
      textInputAction: widget.textInputAction,
      inputFormatters: [
        if (widget.maxLength != null)
          LengthLimitingTextInputFormatter(widget.maxLength),
        if (widget.count?.exceedFormatter != null)
          _ExceedFormatter(widget.count!),
        ...?widget.inputFormatters,
      ],
      onChanged: widget.onChanged,
      onSubmitted: (v) {
        widget.onSubmitted?.call(v);
        _triggerSearch();
      },
      cursorWidth: 1.5,
      cursorRadius: const Radius.circular(1),
      rendererIgnoresPointer: true,
      enableInteractiveSelection: _enabled,
    );

    // Where the placeholder sits, to match where the typed text will.
    //
    // `left` and `right` are the two the caller asked for by side and stay
    // physical; `start`, `end` and `justify` name a reading end, and follow
    // the direction. Mapping start onto the left is what kept the placeholder
    // on the wrong side of a mirrored field while the text itself moved.
    final y = _multiline ? -1.0 : 0.0;
    final AlignmentGeometry placeholderAlign = switch (widget.textAlign) {
      TextAlign.center => AlignmentDirectional(0, y),
      TextAlign.left => Alignment(-1, y),
      TextAlign.right => Alignment(1, y),
      TextAlign.end => AlignmentDirectional(1, y),
      _ => AlignmentDirectional(-1, y),
    };

    // The placeholder sits behind the field and shows through while empty.
    final withPlaceholder = Stack(
      children: [
        if (widget.placeholder != null && _controller.text.isEmpty)
          Positioned.fill(
            child: Align(
              alignment: placeholderAlign,
              child: IgnorePointer(
                child: Text(
                  widget.placeholder!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: widget.textAlign,
                  style: textStyle.copyWith(color: token.colorTextTertiary),
                ),
              ),
            ),
          ),
        _multiline
            ? field
            : Align(alignment: AlignmentDirectional.centerStart, child: field),
      ],
    );

    // Needed before the content row: an attached search button squares off the
    // right edge, and a flush affix must be clipped to whatever corner wins.
    final attached = search != null && search._attached;

    final content = Row(
      crossAxisAlignment:
          _multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        if (widget.prefix != null && widget.prefixFlush)
          // Flush affix on the leading side; clipped to the box's own corner
          // for the same reason as a flush suffix.
          ClipRRect(
            // The prefix sits at the start of the field, so it takes the
            // start corners — the right-hand ones when the field reads that
            // way.
            borderRadius: BorderRadiusDirectional.only(
              topStart: _innerRadius(token, r),
              bottomStart: _innerRadius(token, r),
            ),
            child: widget.prefix!,
          )
        else if (widget.prefix != null) ...[
          _affix(token, fontSize, widget.prefix!),
          SizedBox(width: token.sizeXS),
        ],
        Expanded(child: withPlaceholder),
        if (showClear) ...[
          SizedBox(width: token.sizeXS),
          _ClearButton(token: token, onTap: _clear),
        ],
        if (widget.count?.show == true) ...[
          SizedBox(width: token.sizeXS),
          _counter(token),
        ],
        if (showReveal) ...[
          SizedBox(width: token.sizeXS),
          _RevealButton(
            token: token,
            obscured: _obscured,
            iconRender: password.iconRender,
            onTap: () {
              setState(() => _obscured = !_obscured);
              password.onVisibleChange?.call(!_obscured);
            },
          ),
        ],
        // A plain (non-attached) search box shows a magnifier in the affix row.
        if (search != null && !search._attached) ...[
          SizedBox(width: token.sizeXS),
          SearchIconButton(
            token: token,
            loading: search.loading,
            icon: search.searchIcon,
            onTap: _enabled ? _triggerSearch : null,
          ),
        ],
        if (widget.suffix != null && widget.suffixFlush)
          // Flush affix: no gap or tint, and the box drops its right padding.
          // It reaches the box's own edge, so it has to be clipped to the same
          // corner — a square hover or pressed fill would otherwise spill past
          // the rounded top-right and bottom-right, outside the border.
          ClipRRect(
            // …and the suffix the end corners, unless something is attached
            // beyond it, where the two must meet square.
            borderRadius: BorderRadiusDirectional.only(
              topEnd: attached ? Radius.zero : _innerRadius(token, r),
              bottomEnd: attached ? Radius.zero : _innerRadius(token, r),
            ),
            child: widget.suffix!,
          )
        else if (widget.suffix != null) ...[
          SizedBox(width: token.sizeXS),
          _affix(token, fontSize, widget.suffix!),
        ],
      ],
    );

    final box = _box(token, r, content, flatRight: attached);

    if (!attached) return box;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: box),
        _SearchButton(
          token: token,
          height: _height(token),
          fontSize: fontSize,
          loading: search.loading,
          label: search.enterButtonLabel,
          icon: search.searchIcon,
          onTap: _enabled ? _triggerSearch : null,
        ),
      ],
    );
  }

  double _paddingInline(_ResolvedInputToken r) => switch (_size) {
        SoftSize.small => r.paddingInlineSM,
        SoftSize.middle => r.paddingInline,
        SoftSize.large => r.paddingInlineLG,
      };

  double _paddingBlock(_ResolvedInputToken r) => switch (_size) {
        SoftSize.small => r.paddingBlockSM,
        SoftSize.middle => r.paddingBlock,
        SoftSize.large => r.paddingBlockLG,
      };

  double _radiusVal(_ResolvedInputToken r) => switch (_size) {
        SoftSize.small => r.borderRadiusSM,
        SoftSize.middle => r.borderRadius,
        SoftSize.large => r.borderRadiusLG,
      };

  /// The corner an affix sitting *inside* the border has to follow: the box's
  /// own radius less the border it sits within.
  Radius _innerRadius(Token token, _ResolvedInputToken r) => Radius.circular(
        (_radiusVal(r) - token.lineWidth).clamp(0.0, double.infinity),
      );

  Widget _box(
    Token token,
    _ResolvedInputToken r,
    Widget content, {
    bool flatRight = false,
  }) {
    final radius = Radius.circular(_radiusVal(r));
    final ring = _focusRing(token);
    final inlinePad = _paddingInline(r);
    final blockPad = _paddingBlock(r);
    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.text : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled ? () => _focusNode.requestFocus() : null,
        child: AnimatedContainer(
          duration: token.motionDurationMid,
          curve: token.motionEaseInOut,
          constraints: BoxConstraints(
            minHeight: _multiline ? _height(token) : 0,
          ),
          height: _multiline ? null : _height(token),
          // Start and end rather than left and right: the inset belongs to
          // the prefix's side and the suffix's side, which swap over when the
          // field reads the other way.
          padding: EdgeInsetsDirectional.fromSTEB(
            widget.prefixFlush ? 0 : inlinePad,
            _multiline ? blockPad : 0,
            widget.suffixFlush ? 0 : inlinePad,
            _multiline ? blockPad : 0,
          ),
          decoration: BoxDecoration(
            color: _enabled ? r.colorBgContainer : token.colorFillTertiary,
            // Square where an addon is joined on, rounded at the free end.
            borderRadius: BorderRadiusDirectional.only(
              topStart: radius,
              bottomStart: radius,
              topEnd: flatRight ? Radius.zero : radius,
              bottomEnd: flatRight ? Radius.zero : radius,
            ),
            border: Border.all(
              color: _borderColor(token),
              width: token.lineWidth,
            ),
            boxShadow: ring == null
                ? null
                : [BoxShadow(color: ring, blurRadius: 0, spreadRadius: 3)],
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _counter(Token token) {
    final config = widget.count!;
    final count = config.count(_controller.text);
    if (config.formatter != null) {
      return config.formatter!(
        CountArgs(
          value: _controller.text,
          count: count,
          maxLength: config.max,
        ),
      );
    }
    final text = config.max == null ? '$count' : '$count / ${config.max}';
    return Text(
      text,
      style: TextStyle(
        color: _countExceeded ? token.warning.base : token.colorTextTertiary,
        fontSize: token.fontSizeSM,
        fontFamily: token.fontFamily,
        fontFamilyFallback: token.fontFamilyFallback,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget _affix(Token token, double fontSize, Widget child) {
    return IconTheme.merge(
      data: IconThemeData(color: token.colorTextTertiary, size: fontSize),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: token.colorTextTertiary),
        child: child,
      ),
    );
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    _focusNode.requestFocus();
  }

  TextSelectionControls _selectionControls() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return cupertinoTextSelectionHandleControls;
      default:
        return materialTextSelectionHandleControls;
    }
  }
}

class _ExceedFormatter extends TextInputFormatter {
  _ExceedFormatter(this.config);

  final CountConfig config;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final max = config.max;
    final formatter = config.exceedFormatter;
    if (max == null || formatter == null) return newValue;
    if (config.count(newValue.text) <= max) return newValue;
    final clipped = formatter(newValue.text, max);
    return TextEditingValue(
      text: clipped,
      selection: TextSelection.collapsed(offset: clipped.length),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.token, required this.onTap});

  final Token token;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          size: const Size.square(16),
          painter: ClearIconPainter(token.colorTextTertiary),
        ),
      ),
    );
  }
}

class _RevealButton extends StatelessWidget {
  const _RevealButton({
    required this.token,
    required this.obscured,
    required this.onTap,
    this.iconRender,
  });

  final Token token;
  final bool obscured;
  final VoidCallback onTap;
  final Widget Function(bool visible)? iconRender;

  @override
  Widget build(BuildContext context) {
    final custom = iconRender?.call(!obscured);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: custom ??
            CustomPaint(
              size: const Size.square(18),
              painter: _EyePainter(token.colorTextTertiary, obscured: obscured),
            ),
      ),
    );
  }
}

class _EyePainter extends CustomPainter {
  _EyePainter(this.color, {required this.obscured});

  final Color color;
  final bool obscured;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    // Almond outline.
    final path = Path()
      ..moveTo(w * 0.1, h * 0.5)
      ..quadraticBezierTo(w * 0.5, h * 0.15, w * 0.9, h * 0.5)
      ..quadraticBezierTo(w * 0.5, h * 0.85, w * 0.1, h * 0.5)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.13, paint);
    if (obscured) {
      // A slash to signal "hidden".
      canvas.drawLine(
        Offset(w * 0.2, h * 0.2),
        Offset(w * 0.8, h * 0.8),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EyePainter old) =>
      old.color != color || old.obscured != obscured;
}

/// A magnifier glyph shown inside a plain (non-attached) search box.
class SearchIconButton extends StatelessWidget {
  /// Creates a [SearchIconButton].
  const SearchIconButton({
    super.key,
    required this.token,
    required this.loading,
    required this.onTap,
    this.icon,
  });

  /// The resolved theme the button's colours are read from.
  final Token token;

  /// Whether to show a spinner in place of the glyph.
  final bool loading;

  /// Called when the button is pressed.
  final VoidCallback? onTap;

  /// Replaces the default glyph.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final glyph = loading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CustomPaint(
              painter: _SpinnerPainter(token.colorTextTertiary),
            ),
          )
        : icon ??
            CustomPaint(
              size: const Size.square(16),
              painter: _MagnifierPainter(token.colorTextTertiary),
            );
    return MouseRegion(
      cursor:
          onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: glyph),
    );
  }
}

/// The attached primary search button on the right of a search box.
class _SearchButton extends StatefulWidget {
  const _SearchButton({
    required this.token,
    required this.height,
    required this.fontSize,
    required this.loading,
    required this.onTap,
    this.label,
    this.icon,
  });

  final Token token;
  final double height;
  final double fontSize;
  final bool loading;
  final VoidCallback? onTap;
  final Widget? label;
  final Widget? icon;

  @override
  State<_SearchButton> createState() => _SearchButtonState();
}

class _SearchButtonState extends State<_SearchButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final token = widget.token;
    final enabled = widget.onTap != null;
    final fill = !enabled
        ? token.colorFillTertiary
        : _hovered
            ? token.primary.hover
            : token.primary.base;
    final fg = enabled ? const Color(0xFFFFFFFF) : token.colorTextQuaternary;
    final radius = Radius.circular(token.borderRadius);

    final glyph = widget.loading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CustomPaint(painter: _SpinnerPainter(fg)),
          )
        : widget.icon ??
            CustomPaint(
              size: const Size.square(16),
              painter: _MagnifierPainter(fg),
            );

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: token.motionDurationFast,
          height: widget.height,
          padding: EdgeInsets.symmetric(horizontal: token.sizeMD),
          decoration: BoxDecoration(
            color: fill,
            // The addon caps the far end of the field.
            borderRadius: BorderRadiusDirectional.only(
              topEnd: radius,
              bottomEnd: radius,
            ),
          ),
          alignment: Alignment.center,
          child: widget.label == null
              ? glyph
              : DefaultTextStyle.merge(
                  style: TextStyle(
                    color: fg,
                    fontSize: widget.fontSize,
                    fontFamily: token.fontFamily,
                    fontFamilyFallback: token.fontFamilyFallback,
                    decoration: TextDecoration.none,
                  ),
                  child: widget.label!,
                ),
        ),
      ),
    );
  }
}

class _MagnifierPainter extends CustomPainter {
  _MagnifierPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    final c = Offset(w * 0.42, h * 0.42);
    canvas.drawCircle(c, w * 0.28, paint);
    canvas.drawLine(
      Offset(w * 0.64, h * 0.64),
      Offset(w * 0.9, h * 0.9),
      paint,
    );
  }

  @override
  bool shouldRepaint(_MagnifierPainter old) => old.color != color;
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final rect = Offset.zero & size;
    canvas.drawArc(rect.deflate(1), 0, 4.2, false, paint);
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) => old.color != color;
}
