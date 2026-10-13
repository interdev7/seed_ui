import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/popover.dart';
import '../navigation/dropdown.dart' show DropdownPanel;
import 'input.dart';

/// One suggestion of an [AutoComplete].
@immutable
class AutoCompleteOption {
  /// Creates an [AutoCompleteOption].
  const AutoCompleteOption({
    required this.value,
    this.label,
    this.disabled = false,
  });

  /// What goes into the field when the suggestion is chosen, and what typing
  /// is matched against.
  final String value;

  /// What the suggestion shows, in place of [value]: the address with the
  /// district under it, the name with its avatar. Null shows [value], the
  /// part that matches what was typed in bold.
  final Widget? label;

  /// Shows the suggestion greyed out; it cannot be chosen.
  final bool disabled;
}

/// Per-component design tokens for [AutoComplete].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(autoComplete: AutoCompleteToken(...)))`, or per instance
/// via [AutoComplete.token].
@immutable
class AutoCompleteToken {
  /// Creates an [AutoCompleteToken].
  const AutoCompleteToken({
    this.optionActiveBg,
    this.optionColor,
    this.optionPadding,
    this.optionFontSize,
    this.matchWeight,
  });

  /// The wash behind the suggestion the keys or the pointer are on.
  final Color? optionActiveBg;

  /// A suggestion's words.
  final Color? optionColor;

  /// Space inside a suggestion.
  final EdgeInsets? optionPadding;

  /// A suggestion's text size.
  final double? optionFontSize;

  /// The weight of the part of a suggestion that matches what was typed.
  final FontWeight? matchWeight;

  _ResolvedAutoCompleteToken _resolve(Token t) => _ResolvedAutoCompleteToken(
        optionActiveBg: optionActiveBg ?? t.colorFillSecondary,
        optionColor: optionColor ?? t.colorText,
        // As tall as a control: a line of text, with the rest of the
        // control's height shared above and below it.
        optionPadding: optionPadding ??
            EdgeInsets.symmetric(
              horizontal: t.sizeSM,
              vertical: (t.controlHeight - t.controlHeightXS) / 2,
            ),
        optionFontSize: optionFontSize ?? t.fontSize,
        matchWeight: matchWeight ?? t.fontWeightStrong,
      );

  /// This one with [other]'s fields laid over it, one field at a time.
  AutoCompleteToken merge(AutoCompleteToken other) => AutoCompleteToken(
        optionActiveBg: other.optionActiveBg ?? optionActiveBg,
        optionColor: other.optionColor ?? optionColor,
        optionPadding: other.optionPadding ?? optionPadding,
        optionFontSize: other.optionFontSize ?? optionFontSize,
        matchWeight: other.matchWeight ?? matchWeight,
      );
}

@immutable
class _ResolvedAutoCompleteToken {
  const _ResolvedAutoCompleteToken({
    required this.optionActiveBg,
    required this.optionColor,
    required this.optionPadding,
    required this.optionFontSize,
    required this.matchWeight,
  });

  final Color optionActiveBg;
  final Color optionColor;
  final EdgeInsets optionPadding;
  final double optionFontSize;
  final FontWeight matchWeight;
}

/// A text field that offers to finish what is being typed: a city, an e-mail
/// domain, a name from a long list.
///
/// ```dart
/// AutoComplete(
///   placeholder: 'City',
///   options: const [
///     AutoCompleteOption(value: 'Amsterdam'),
///     AutoCompleteOption(value: 'Ankara'),
///     AutoCompleteOption(value: 'Athens'),
///   ],
///   onSelect: (city) => setState(() => this.city = city),
/// )
/// ```
///
/// Unlike a [Select], what is typed is the value: a suggestion only fills it
/// in. The suggestions open under the field as it is typed in, narrowed to
/// those that hold the text; the arrow keys walk them, Enter takes one and
/// Escape puts them away.
class AutoComplete extends StatefulWidget {
  /// Creates an [AutoComplete].
  const AutoComplete({
    super.key,
    required this.options,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.onSelect,
    this.onSearch,
    this.filterOption,
    this.placeholder,
    this.allowClear,
    this.disabled,
    this.status,
    this.size,
    this.notFoundContent,
    this.backfill = false,
    this.defaultActiveFirstOption = true,
    this.listHeight = 256,
    this.autofocus = false,
    this.focusNode,
    this.semanticsLabel,
    this.token,
  });

  /// The suggestions. For suggestions fetched as the reader types, hand over
  /// what came back for [onSearch] and pass a [filterOption] that keeps
  /// everything.
  final List<AutoCompleteOption> options;

  /// The text, held from outside. Null lets the field keep its own, starting
  /// from [defaultValue].
  final String? value;

  /// The text the field starts with, when [value] is null.
  final String? defaultValue;

  /// Called with the text whenever it changes, typed or filled in.
  final ValueChanged<String>? onChanged;

  /// Called with a suggestion's value when it is chosen.
  final ValueChanged<String>? onSelect;

  /// Called with the text as it is typed — not when a suggestion fills it
  /// in — for fetching suggestions to match.
  final ValueChanged<String>? onSearch;

  /// Whether a suggestion is offered for what was typed. Null keeps those
  /// whose value holds the text, whatever its case.
  final bool Function(String input, AutoCompleteOption option)? filterOption;

  /// Shown in the empty field.
  final String? placeholder;

  /// Whether a cross clears the field.
  final bool? allowClear;

  /// Greys the field out.
  final bool? disabled;

  /// Colours the field's border as a warning or an error.
  final InputStatus? status;

  /// How tall the field is, as an [Input].
  final ControlSize? size;

  /// Shown under the field when nothing matches. Null shows nothing — the
  /// suggestions simply do not open.
  final Widget? notFoundContent;

  /// Whether the suggestion the arrow keys reach is written into the field
  /// as they reach it, before Enter takes it.
  final bool backfill;

  /// Whether the first suggestion is already reached when they open, so
  /// Enter takes it without an arrow first. Defaults to yes.
  final bool defaultActiveFirstOption;

  /// The most the suggestions may stand tall before they scroll.
  final double listHeight;

  /// Whether the field takes the focus as it appears.
  final bool autofocus;

  /// The field's focus, for moving it from outside.
  final FocusNode? focusNode;

  /// What a screen reader calls the field.
  final String? semanticsLabel;

  /// Per-instance token overrides.
  final AutoCompleteToken? token;

  @override
  State<AutoComplete> createState() => _AutoCompleteState();
}

class _AutoCompleteState extends State<AutoComplete> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value ?? widget.defaultValue ?? '');
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());
  final _anchor = GlobalKey();
  final PopoverController _popover = PopoverController();
  final ValueNotifier<int> _revision = ValueNotifier(0);
  final ScrollController _scroll = ScrollController();

  bool _open = false;
  int _highlight = -1;

  /// What the reader typed, kept while the keys backfill the field with
  /// suggestions, so the list still answers to the typing.
  String _typed = '';

  /// Set while the field is written to from here rather than typed in.
  bool _filling = false;

  @override
  void initState() {
    super.initState();
    _typed = _controller.text;
    _focus.addListener(_onFocus);
    _controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(AutoComplete old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
    final value = widget.value;
    if (value != null && value != _controller.text) {
      _fill(value);
      _typed = value;
    }
    if (_open) {
      // New suggestions, perhaps fetched for what was typed: the list in the
      // overlay is built once, so it is told to look again.
      _keepHighlight();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _matches.isEmpty && widget.notFoundContent == null
            ? _close()
            : _revision.value++;
      });
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    _controller.dispose();
    _popover.dispose();
    _revision.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<AutoCompleteOption> get _matches {
    final filter = widget.filterOption ??
        (String input, AutoCompleteOption o) =>
            o.value.toLowerCase().contains(input.toLowerCase());
    return [
      for (final o in widget.options)
        if (filter(_typed, o)) o,
    ];
  }

  void _fill(String text) {
    _filling = true;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _filling = false;
  }

  void _onText() {
    if (_filling) {
      widget.onChanged?.call(_controller.text);
      return;
    }
    if (_controller.text == _typed) return;
    _typed = _controller.text;
    widget.onChanged?.call(_typed);
    widget.onSearch?.call(_typed);
    if (_focus.hasFocus) _show(resetHighlight: true);
  }

  void _onFocus() {
    if (!mounted) return;
    _focus.hasFocus ? _show(resetHighlight: true) : _close();
  }

  int _firstEnabled(List<AutoCompleteOption> options,
      {int from = 0, int step = 1}) {
    for (var i = from; i >= 0 && i < options.length; i += step) {
      if (!options[i].disabled) return i;
    }
    return -1;
  }

  void _keepHighlight() {
    final matches = _matches;
    if (_highlight >= matches.length) {
      _highlight =
          widget.defaultActiveFirstOption ? _firstEnabled(matches) : -1;
    }
  }

  void _show({bool resetHighlight = false}) {
    if (widget.disabled ?? false) return;
    final matches = _matches;
    if (resetHighlight) {
      _highlight =
          widget.defaultActiveFirstOption ? _firstEnabled(matches) : -1;
    }
    if (matches.isEmpty && widget.notFoundContent == null) {
      _close();
      return;
    }
    if (_open) {
      _revision.value++;
      return;
    }
    final box = _anchor.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    setState(() => _open = true);
    _popover.open(
      placement: PopoverPlacement.bottomLeft,
      anchorRect: anchor,
      gap: context.softToken.sizeXXS,
      // A tap in the field itself is typing, not a tap away.
      dismissExcludesAnchor: true,
      onDismiss: _close,
      anchorContext: context,
      onScrollDismiss: _close,
      builder: (context) => ValueListenableBuilder<int>(
        valueListenable: _revision,
        builder: (context, _, __) => _panel(context, anchor.width),
      ),
    );
  }

  void _close() {
    if (!_open) return;
    _popover.close();
    if (mounted) setState(() => _open = false);
  }

  void _choose(AutoCompleteOption option) {
    if (option.disabled) return;
    _fill(option.value);
    _typed = option.value;
    widget.onSelect?.call(option.value);
    _close();
  }

  void _move(int step) {
    final matches = _matches;
    if (matches.isEmpty) return;
    var next = _highlight;
    for (var tries = 0; tries < matches.length; tries++) {
      next = (next + step) % matches.length;
      if (next < 0) next += matches.length;
      if (!matches[next].disabled) break;
    }
    setState(() => _highlight = next);
    _revision.value++;
    if (widget.backfill) _fill(matches[next].value);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      if (!_open) {
        _show(resetHighlight: true);
        return KeyEventResult.handled;
      }
      _move(key == LogicalKeyboardKey.arrowDown ? 1 : -1);
      return KeyEventResult.handled;
    }
    if (!_open) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.escape) {
      if (widget.backfill) _fill(_typed);
      _close();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final matches = _matches;
      if (_highlight >= 0 && _highlight < matches.length) {
        _choose(matches[_highlight]);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Widget _panel(BuildContext context, double width) {
    final t = context.softToken;
    final r = (widget.token ??
            ConfigProvider.componentOf<AutoCompleteToken>(context) ??
            const AutoCompleteToken())
        ._resolve(t);
    final matches = _matches;
    final Widget body = matches.isEmpty
        ? Align(heightFactor: 1, child: widget.notFoundContent)
        : ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.listHeight),
            child: ListView.builder(
              controller: _scroll,
              shrinkWrap: true,
              padding: EdgeInsets.all(t.sizeXXS),
              itemCount: matches.length,
              itemBuilder: (context, i) => _OptionRow(
                option: matches[i],
                typed: _typed,
                token: r,
                active: i == _highlight,
                onHover: () {
                  if (_highlight == i || matches[i].disabled) return;
                  setState(() => _highlight = i);
                  _revision.value++;
                },
                onTap: () => _choose(matches[i]),
              ),
            ),
          );
    return SizedBox(
      width: width,
      child: DropdownPanel(minWidth: width, child: body),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      // Watching, not taking: the field inside keeps the focus, and this
      // hears the keys it leaves alone — the arrows, Enter, Escape.
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: KeyedSubtree(
        key: _anchor,
        child: Input(
          controller: _controller,
          focusNode: _focus,
          placeholder: widget.placeholder,
          allowClear: widget.allowClear,
          disabled: widget.disabled,
          status: widget.status,
          size: widget.size,
          autofocus: widget.autofocus,
          semanticsLabel: widget.semanticsLabel,
          autocorrect: false,
        ),
      ),
    );
  }
}

/// One suggestion: its words, the matching part in bold.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.typed,
    required this.token,
    required this.active,
    required this.onHover,
    required this.onTap,
  });

  final AutoCompleteOption option;
  final String typed;
  final _ResolvedAutoCompleteToken token;
  final bool active;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.softToken;
    final r = token;
    final color = option.disabled ? t.colorTextQuaternary : r.optionColor;
    final style = TextStyle(
      color: color,
      fontSize: r.optionFontSize,
      fontWeight: t.fontWeight,
      fontFamily: t.fontFamily,
      fontFamilyFallback: t.fontFamilyFallback,
      decoration: TextDecoration.none,
    );

    Widget words() {
      final value = option.value;
      final at =
          typed.isEmpty ? -1 : value.toLowerCase().indexOf(typed.toLowerCase());
      if (at < 0) return Text(value, style: style);
      return Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(text: value.substring(0, at)),
            TextSpan(
              text: value.substring(at, at + typed.length),
              style: TextStyle(fontWeight: r.matchWeight),
            ),
            TextSpan(text: value.substring(at + typed.length)),
          ],
        ),
      );
    }

    final lit = active && !option.disabled;
    return Semantics(
      button: true,
      enabled: !option.disabled,
      selected: lit,
      onTap: option.disabled ? null : onTap,
      child: MouseRegion(
        cursor: option.disabled
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => onHover(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: option.disabled ? null : onTap,
          child: Container(
            padding: r.optionPadding,
            decoration: BoxDecoration(
              // The wash's own colour made clear at rest, never a clear
              // black: nothing between the two passes through grey.
              color: lit
                  ? r.optionActiveBg
                  : r.optionActiveBg.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(t.borderRadiusSM),
            ),
            child: DefaultTextStyle.merge(
              style: style,
              child: option.label ?? words(),
            ),
          ),
        ),
      ),
    );
  }
}
