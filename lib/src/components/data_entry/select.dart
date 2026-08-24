import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../icons/icons.dart';
import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../../utils/popover.dart';
import '../navigation/dropdown.dart' show DropdownPanel;

/// How a [Select] behaves: pick one value, several, or freely create new ones.
enum SelectMode {
  /// Choose a single value; picking one closes the dropdown.
  single,

  /// Choose several values, shown as removable tags; the dropdown stays open.
  multiple,

  /// Like [multiple], but the user can also type a value that is not in the
  /// options to create it on the fly. Intended for `Select<String>`.
  tags,
}

/// A validation status that recolours a [Select]'s border.
enum SelectStatus {
  /// An amber border — the choice is questionable but accepted.
  warning,

  /// A red border — the choice is not valid.
  error
}

/// The box style of a [Select], variants.
enum SelectVariant {
  /// A bordered box — the default.
  outlined,

  /// A tinted box with no border.
  filled,

  /// Neither border nor fill; only the text and the arrow.
  borderless
}

/// One choice in a [Select].
@immutable
class SelectOption<T> {
  /// Creates a [SelectOption].
  const SelectOption({
    required this.value,
    this.label,
    this.filterText,
    this.disabled = false,
  });

  /// The value reported through the selection when this option is chosen.
  final T value;

  /// The display widget. Falls back to `Text('$value')` (or [filterText]).
  final Widget? label;

  /// Plain text used for the default search filter and, when [label] is null,
  /// for display. Falls back to `'$value'`.
  final String? filterText;

  /// Greys the option out and blocks selecting it.
  final bool disabled;

  String get _text => filterText ?? '$value';
  Widget get _display => label ?? Text(_text);
}

/// Search behaviour for a [Select] — the `showSearch` object form.
/// Passing one to [Select.search] enables filtering by typing.
@immutable
class SelectSearch<T> {
  /// Creates a [SelectSearch].
  const SelectSearch({
    this.filterOption,
    this.filterSort,
    this.onSearch,
    this.autoClearSearchValue = true,
  });

  /// Custom filter predicate. Defaults to a case-insensitive substring match on
  /// each option's text.
  final bool Function(String input, SelectOption<T> option)? filterOption;

  /// Orders the (filtered) options, e.g. alphabetically. Applied even with an
  /// empty query.
  final int Function(SelectOption<T> a, SelectOption<T> b)? filterSort;

  /// Called with the search text on every keystroke.
  final ValueChanged<String>? onSearch;

  /// Whether the query clears after picking a value (multiple/tags modes).
  final bool autoClearSearchValue;
}

/// Per-component design tokens for [Select].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ThemeData(components:
/// ComponentsConfig(select: SelectToken(...)))`,
/// or per instance via [Select.token].
@immutable
class SelectToken {
  /// Creates a [SelectToken].
  const SelectToken({
    this.optionSelectedBg,
    this.optionActiveBg,
    this.optionPadding,
    this.optionFontSize,
    this.selectorBg,
    this.clearBg,
    this.borderRadius,
    this.borderRadiusSM,
    this.borderRadiusLG,
  });

  /// Selected option background (`optionSelectedBg`).
  final Color? optionSelectedBg;

  /// Hovered/focused option background (`optionActiveBg`).
  final Color? optionActiveBg;

  /// Padding for options in dropdown (`optionPadding`).
  final EdgeInsets? optionPadding;

  /// Font size for options in dropdown (`optionFontSize`).
  final double? optionFontSize;

  /// Trigger selector background (`selectorBg`).
  final Color? selectorBg;

  /// Clear button background (`clearBg`).
  final Color? clearBg;

  /// Corner radius for standard select (`borderRadius`).
  final double? borderRadius;

  /// Corner radius for small select (`borderRadiusSM`).
  final double? borderRadiusSM;

  /// Corner radius for large select (`borderRadiusLG`).
  final double? borderRadiusLG;

  _ResolvedSelectToken _resolve(Token t) => _ResolvedSelectToken(
        optionSelectedBg: optionSelectedBg ?? t.primary.bg,
        optionActiveBg: optionActiveBg ?? t.colorFillSecondary,
        optionPadding: optionPadding ??
            EdgeInsets.symmetric(horizontal: t.sizeSM, vertical: 5),
        optionFontSize: optionFontSize ?? t.fontSize,
        selectorBg: selectorBg ?? t.colorBgContainer,
        clearBg: clearBg ?? t.colorBgContainer,
        borderRadius: borderRadius ?? t.borderRadius,
        borderRadiusSM: borderRadiusSM ?? t.borderRadiusSM,
        borderRadiusLG: borderRadiusLG ?? t.borderRadiusLG,
      );
}

@immutable
class _ResolvedSelectToken {
  const _ResolvedSelectToken({
    required this.optionSelectedBg,
    required this.optionActiveBg,
    required this.optionPadding,
    required this.optionFontSize,
    required this.selectorBg,
    required this.clearBg,
    required this.borderRadius,
    required this.borderRadiusSM,
    required this.borderRadiusLG,
  });

  final Color optionSelectedBg;
  final Color optionActiveBg;
  final EdgeInsets optionPadding;
  final double optionFontSize;
  final Color selectorBg;
  final Color clearBg;
  final double borderRadius;
  final double borderRadiusSM;
  final double borderRadiusLG;
}

/// A dropdown for choosing one or more values from a list.
///
/// The value is always a `List<T>` — a single-select simply holds at most one
/// element. Drive it controlled with [value] + [onChanged], or uncontrolled
/// with [defaultValue].
///
/// ```dart
/// Select<String>(
///   value: _picked,
///   placeholder: 'Pick a fruit',
///   options: const [
///     SelectOption(value: 'apple', filterText: 'Apple'),
///     SelectOption(value: 'banana', filterText: 'Banana'),
///   ],
///   onChanged: (v) => setState(() => _picked = v),
/// )
/// ```
///
/// Set [mode] for multi-select or free tagging, [showSearch] to filter by
/// typing, and [allowClear] for a clear button.
class Select<T> extends StatefulWidget {
  /// Creates a [Select].
  const Select({
    super.key,
    this.value,
    this.defaultValue,
    this.onChanged,
    required this.options,
    this.mode = SelectMode.single,
    this.placeholder,
    this.disabled = false,
    this.loading = false,
    this.allowClear = false,
    this.showSearch = false,
    this.search,
    this.filterOption,
    this.onSearch,
    this.size = SoftSize.middle,
    this.status,
    this.variant = SelectVariant.outlined,
    this.open,
    this.onOpenChange,
    this.maxTagCount,
    this.maxTagCountResponsive = false,
    this.listHeight = 256,
    this.popupMatchSelectWidth = true,
    this.notFoundContent,
    this.suffixIcon,
    this.menuItemSelectedIcon,
    this.optionRender,
    this.itemRender,
    this.focusNode,
    this.token,
  });

  /// Per-instance token overrides.
  final SelectToken? token;

  /// The current selection. Null makes the field uncontrolled (see
  /// [defaultValue]).
  final List<T>? value;

  /// Initial selection for an uncontrolled field.
  final List<T>? defaultValue;

  /// Called with the full new selection whenever it changes.
  final ValueChanged<List<T>>? onChanged;

  /// The choices, in order.
  final List<SelectOption<T>> options;

  /// Single, multiple or free-tagging behaviour.
  final SelectMode mode;

  /// Grey hint shown while nothing is selected.
  final String? placeholder;

  /// Greys the field out and blocks interaction.
  final bool disabled;

  /// Shows a spinner in place of the arrow and a loading row in the dropdown.
  final bool loading;

  /// Shows a clear button while there is a selection.
  final bool allowClear;

  /// Lets the user filter the options by typing.
  final bool showSearch;

  /// Search configuration (filter, sort, onSearch) — the `showSearch`
  /// object. Non-null also enables search, like [showSearch].
  final SelectSearch<T>? search;

  /// Custom filter predicate. Defaults to a case-insensitive substring match
  /// against each option's text. Superseded by [search]'s `filterOption`.
  final bool Function(String input, SelectOption<T> option)? filterOption;

  /// Called with the search text on every keystroke.
  final ValueChanged<String>? onSearch;

  /// Which height preset to use.
  final SoftSize size;

  /// A validation status that recolours the border.
  final SelectStatus? status;

  /// The box style.
  final SelectVariant variant;

  /// Drives dropdown visibility externally. Null lets the field manage it.
  final bool? open;

  /// Notified when the dropdown wants to open or close.
  final ValueChanged<bool>? onOpenChange;

  /// Collapses tags past this count into a "+N" chip (multiple/tags modes).
  /// Ignored when [maxTagCountResponsive] is set.
  final int? maxTagCount;

  /// Keeps the tags on a single line, collapsing whatever does not fit into a
  /// "+N" chip.
  final bool maxTagCountResponsive;

  /// Maximum height of the dropdown list before it scrolls.
  final double listHeight;

  /// Whether the dropdown matches the trigger's width. When false it sizes to
  /// its content, never narrower than the trigger.
  final bool popupMatchSelectWidth;

  /// Shown in the dropdown when no option matches. Defaults to "No data".
  final Widget? notFoundContent;

  /// Replaces the trailing arrow glyph.
  final Widget? suffixIcon;

  /// Replaces the tick drawn beside a selected option.
  final Widget? menuItemSelectedIcon;

  /// Custom builder for an option row in the dropdown. `selected` reflects the
  /// current state.
  final Widget Function(SelectOption<T> option, bool selected)? optionRender;

  /// Custom builder for a selected item shown in the box — the single label or
  /// each multiple/tags chip's content. Falls back to the option's label.
  final Widget Function(SelectOption<T> option)? itemRender;

  /// An external focus node for the field.
  final FocusNode? focusNode;

  @override
  State<Select<T>> createState() => _SelectState<T>();
}

class _SelectState<T> extends State<Select<T>> {
  final PopoverController _popover = PopoverController();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  /// Notifies the (overlay) dropdown to rebuild without reinserting it.
  final ValueNotifier<int> _dropdownRevision = ValueNotifier<int>(0);

  FocusNode? _ownFocus;
  FocusNode get _focusNode => widget.focusNode ?? (_ownFocus ??= FocusNode());

  List<T>? _internal;
  List<T> get _current =>
      widget.value ?? _internal ?? widget.defaultValue ?? const [];

  bool _open = false;
  bool _hovered = false;
  bool _focused = false;
  int _highlight = -1;

  bool get _multi => widget.mode != SelectMode.single;
  bool get _enabled => !widget.disabled;

  @override
  void initState() {
    super.initState();
    _internal =
        widget.defaultValue == null ? null : List<T>.of(widget.defaultValue!);
    _popover.onClosed = () {
      if (mounted) setState(() {}); // repaint arrow
    };
    _focusNode.addListener(_onFocusChange);
    _focusNode.onKeyEvent = _handleKey;
  }

  @override
  void didUpdateWidget(Select<T> old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
      _focusNode.onKeyEvent = _handleKey;
    }
    if (widget.open != null && widget.open != _open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.open! ? _openDropdown() : _closeDropdown();
      });
    }
    // A controlled value arrives a frame after selection, so refresh the
    // (overlay) dropdown here — otherwise the newly selected row is not marked
    // until the next unrelated repaint. Deferred, since notifying the overlay's
    // ValueListenableBuilder during this build is illegal.
    if (_open && !identical(old.value, widget.value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _dropdownRevision.value++;
      });
    }
  }

  @override
  void dispose() {
    _popover.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _dropdownRevision.dispose();
    _focusNode.removeListener(_onFocusChange);
    _ownFocus?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  void _refresh() {
    if (mounted) setState(() {});
    _dropdownRevision.value++;
  }

  // --- filtering ---

  /// Whether the user can filter the options by typing.
  bool get _searchable =>
      widget.showSearch ||
      widget.search != null ||
      widget.mode == SelectMode.tags;

  List<SelectOption<T>> get _visibleOptions {
    final search = widget.search;
    final sort = search?.filterSort;
    // Sorting applies even with no query.
    final base =
        sort == null ? widget.options : (List.of(widget.options)..sort(sort));

    final q = _searchCtrl.text;
    if (!_searchable || q.isEmpty) return base;
    final predicate = search?.filterOption ??
        widget.filterOption ??
        (input, option) =>
            option._text.toLowerCase().contains(input.toLowerCase());
    return [
      for (final o in base)
        if (predicate(q, o)) o,
    ];
  }

  SelectOption<T>? _optionFor(T value) {
    for (final o in widget.options) {
      if (o.value == value) return o;
    }
    return null;
  }

  /// The widget shown for a selected [value] in the box — [itemRender] if set,
  /// else the option's own display (synthesising one for created tags).
  Widget _displayFor(T value) {
    final option = _optionFor(value) ?? SelectOption<T>(value: value);
    return widget.itemRender?.call(option) ?? option._display;
  }

  // --- open / close ---

  void _requestOpen(bool next) {
    if (widget.onOpenChange != null) {
      widget.onOpenChange!(next);
      if (widget.open == null) next ? _openDropdown() : _closeDropdown();
    } else {
      next ? _openDropdown() : _closeDropdown();
    }
  }

  void _openDropdown() {
    if (_open || !_enabled) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    setState(() {
      _open = true;
      _highlight = _firstEnabled(_visibleOptions);
    });
    final token = context.softToken;
    _popover.open(
      placement: PopoverPlacement.bottomLeft,
      anchorRect: anchor,
      gap: token.sizeXXS,
      onDismiss: () => _requestOpen(false),
      // Keep the box interactive while open, so removing a tag isn't swallowed
      // by the outside-tap barrier.
      dismissExcludesAnchor: true,
      anchorContext: context,
      onScrollDismiss: () => _requestOpen(false),
      builder: (context) => ListenableBuilder(
        listenable: _dropdownRevision,
        builder: (context, _) => _Dropdown<T>(
          width: widget.popupMatchSelectWidth ? anchor.width : null,
          minWidth: anchor.width,
          state: this,
        ),
      ),
    );
  }

  void _closeDropdown() {
    if (!_open) return;
    setState(() => _open = false);
    _popover.close();
    if (_searchCtrl.text.isNotEmpty) {
      _searchCtrl.clear();
      _notifySearch('');
    }
  }

  int _firstEnabled(List<SelectOption<T>> options) {
    for (var i = 0; i < options.length; i++) {
      if (!options[i].disabled) return i;
    }
    return -1;
  }

  // --- selection ---

  void _emit(List<T> next) {
    if (widget.value == null) _internal = next;
    widget.onChanged?.call(next);
  }

  void _choose(T value) {
    if (widget.mode == SelectMode.single) {
      _emit([value]);
      _closeDropdown();
      _focusNode.unfocus();
    } else {
      final next = List<T>.of(_current);
      next.contains(value) ? next.remove(value) : next.add(value);
      _emit(next);
      final autoClear = widget.search?.autoClearSearchValue ?? true;
      if (autoClear && _searchCtrl.text.isNotEmpty) {
        _searchCtrl.clear();
        _notifySearch('');
      }
    }
    _refresh();
  }

  void _remove(T value) {
    final next = List<T>.of(_current)..remove(value);
    _emit(next);
    _refresh();
  }

  void _clearAll() {
    _emit(const []);
    _refresh();
  }

  void _notifySearch(String text) {
    widget.search?.onSearch?.call(text);
    widget.onSearch?.call(text);
  }

  void _onSearchChanged(String text) {
    _notifySearch(text);
    setState(() => _highlight = _firstEnabled(_visibleOptions));
    _dropdownRevision.value++;
  }

  /// Moves the highlight to a hovered row, so the keyboard highlight and the
  /// pointer never light up two rows at once.
  void _setHighlight(int i) {
    if (_highlight == i) return;
    _highlight = i;
    _dropdownRevision.value++;
  }

  void _submitHighlighted() {
    final options = _visibleOptions;
    if (_highlight >= 0 && _highlight < options.length) {
      final o = options[_highlight];
      if (!o.disabled) _choose(o.value);
    } else if (widget.mode == SelectMode.tags) {
      _createTag(_searchCtrl.text);
    }
  }

  void _createTag(String text) {
    if (text.isEmpty) return;
    if (text is! T) return; // tags are only meaningful for Select<String>
    final v = text as T;
    if (!_current.contains(v)) {
      _emit(List<T>.of(_current)..add(v));
    }
    _searchCtrl.clear();
    _notifySearch('');
    _refresh();
  }

  // --- keyboard ---

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (_open) {
        _requestOpen(false);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      if (!_open) {
        _requestOpen(true);
      } else {
        _moveHighlight(key == LogicalKeyboardKey.arrowDown ? 1 : -1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter) {
      if (_open) {
        _submitHighlighted();
      } else {
        _requestOpen(true);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace &&
        _multi &&
        _searchCtrl.text.isEmpty &&
        _current.isNotEmpty) {
      _remove(_current.last);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveHighlight(int delta) {
    final options = _visibleOptions;
    if (options.isEmpty) return;
    var i = _highlight;
    for (var steps = 0; steps < options.length; steps++) {
      i = (i + delta) % options.length;
      if (i < 0) i += options.length;
      if (!options[i].disabled) break;
    }
    setState(() => _highlight = i);
    _dropdownRevision.value++;
    _scrollHighlightIntoView(i, options.length);
  }

  void _scrollHighlightIntoView(int index, int count) {
    if (!_scrollCtrl.hasClients) return;
    final rowHeight = context.softToken.controlHeight;
    final target = index * rowHeight;
    final viewTop = _scrollCtrl.offset;
    final viewBottom = viewTop + _scrollCtrl.position.viewportDimension;
    if (target < viewTop) {
      _scrollCtrl.jumpTo(target);
    } else if (target + rowHeight > viewBottom) {
      _scrollCtrl
          .jumpTo(target + rowHeight - _scrollCtrl.position.viewportDimension);
    }
  }

  // --- sizing ---

  double _height(Token t) => switch (widget.size) {
        SoftSize.small => t.controlHeightSM,
        SoftSize.middle => t.controlHeight,
        SoftSize.large => t.controlHeightLG,
      };

  double _fontSize(Token t) =>
      widget.size == SoftSize.large ? t.fontSizeLG : t.fontSize;

  Color _borderColor(Token t) {
    if (!_enabled) return t.colorBorder;
    if (widget.status == SelectStatus.error) {
      return _focused || _open ? t.error.hover : t.error.base;
    }
    if (widget.status == SelectStatus.warning) {
      return _focused || _open ? t.warning.hover : t.warning.base;
    }
    if (_focused || _open) return t.primary.hover;
    if (_hovered) return t.primary.base;
    return t.colorBorder;
  }

  /// Keeps the open dropdown anchored as the box changes height (e.g. tags
  /// wrapping to a new line), so it never overlaps the grown trigger.
  void _syncAnchor() {
    if (!_open) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_open) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        _popover.reposition(box.localToGlobal(Offset.zero) & box.size);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final fontSize = _fontSize(token);
    final values = _current;
    final hasValue = values.isNotEmpty;
    final searching = _searchable;
    _syncAnchor();
    final showClear =
        widget.allowClear && _enabled && hasValue && (_hovered || _open);

    final bordered = widget.variant != SelectVariant.borderless;
    final Color fill;
    if (!_enabled) {
      fill = token.colorFillTertiary;
    } else if (widget.variant == SelectVariant.filled) {
      fill = _hovered || _open || _focused
          ? token.colorFillSecondary
          : token.colorFillTertiary;
    } else if (widget.variant == SelectVariant.borderless) {
      fill = const Color(0x00000000);
    } else {
      fill = token.colorBgContainer;
    }

    final textStyle = TextStyle(
      color: _enabled ? token.colorText : token.colorTextQuaternary,
      fontSize: fontSize,
      fontFamily: token.fontFamily,
      fontFamilyFallback: token.fontFamilyFallback,
      height: 1.0,
      decoration: TextDecoration.none,
    );

    // The typed-search field. Present whenever the mode can search; otherwise a
    // zero-width focus sink so keyboard navigation still works.
    final searchField = EditableText(
      controller: _searchCtrl,
      focusNode: _focusNode,
      readOnly: !searching || !_enabled,
      showCursor: searching,
      style: textStyle,
      strutStyle: StrutStyle.fromTextStyle(textStyle, forceStrutHeight: true),
      cursorColor: token.primary.base,
      backgroundCursorColor: token.colorTextQuaternary,
      cursorWidth: 1.5,
      maxLines: 1,
      keyboardType: TextInputType.text,
      onChanged: _onSearchChanged,
      onSubmitted: (_) => _submitHighlighted(),
      rendererIgnoresPointer: true,
      enableInteractiveSelection: searching,
    );

    // What sits in the value area: placeholder, single label, or tags.
    Widget valueArea;
    // While open, a searchable single select reads like a focused text input:
    // the caret shows, the current value is a faint hint behind it, and typing
    // replaces the hint with the query.
    final typing = _open && searching;
    final showQuery = typing && _searchCtrl.text.isNotEmpty;
    if (_multi) {
      valueArea = _buildTags(token, fontSize, searchField, searching);
    } else {
      final label = hasValue ? _displayFor(values.first) : null;
      final hintColor = typing ? token.colorTextTertiary : textStyle.color;
      valueArea = Stack(
        clipBehavior: Clip.none,
        // The value and its placeholder start where the language starts.
        alignment: AlignmentDirectional.centerStart,
        children: [
          // Always non-positioned, so the Stack takes its height from here even
          // while the (positioned) search field is showing. Hidden once the
          // user starts typing a query.
          Opacity(
            opacity: showQuery ? 0 : 1,
            child: hasValue
                ? DefaultTextStyle.merge(
                    style: textStyle.copyWith(color: hintColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: IconTheme.merge(
                      data: IconThemeData(color: hintColor, size: fontSize),
                      child: label ?? const SizedBox.shrink(),
                    ),
                  )
                : Text(
                    widget.placeholder ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle.copyWith(color: token.colorTextTertiary),
                  ),
          ),
          // The search field is always mounted (it owns the focus node that
          // drives keyboard navigation); it shows its caret while open so the
          // control reads like an input the user can type into immediately.
          Positioned.fill(
            child: Opacity(
              opacity: typing ? 1 : 0,
              child: IgnorePointer(ignoring: !typing, child: searchField),
            ),
          ),
        ],
      );
    }

    final Widget suffix;
    if (widget.loading) {
      suffix = Spinner(size: fontSize, color: token.colorTextTertiary);
    } else if (showClear) {
      suffix = _ClearButton(token: token, onTap: _clearAll);
    } else if (widget.suffixIcon != null) {
      suffix = widget.suffixIcon!;
    } else if (widget.showSearch && _open) {
      // A searchable, open select shows a magnifier rather than the arrow.
      suffix = SearchIcon(color: token.colorTextTertiary);
    } else {
      suffix = _Arrow(color: token.colorTextTertiary, open: _open);
    }

    final leftPadding =
        _multi && _current.isNotEmpty ? token.sizeXXS : token.sizeXS;

    final box = AnimatedContainer(
      duration: token.motionDurationFast,
      curve: token.motionEaseInOut,
      constraints: BoxConstraints(minHeight: _height(token)),
      // Horizontal padding is kept close to the vertical breathing room, so
      // the text isn't pushed in further from the edge than from top and
      // bottom. Directional: the wider inset belongs where the content starts
      // and the narrower where the arrow sits, and swapping them is what a
      // mirrored layout did with a physical pair.
      padding: EdgeInsetsDirectional.only(
        start: leftPadding,
        end: token.sizeSM,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(token.borderRadius),
        border: bordered
            ? Border.all(color: _borderColor(token), width: token.lineWidth)
            : null,
        boxShadow: (_focused || _open) && _enabled && bordered
            ? [
                BoxShadow(
                  color: (widget.status == SelectStatus.error
                          ? token.error
                          : widget.status == SelectStatus.warning
                              ? token.warning
                              : token.primary)
                      .base
                      .withValues(alpha: 0.12),
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: valueArea),
          SizedBox(width: token.sizeXS),
          SizedBox(
            width: fontSize,
            height: _height(token),
            child: Center(child: suffix),
          ),
        ],
      ),
    );

    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled
            ? () {
                _focusNode.requestFocus();
                _requestOpen(!_open);
              }
            : null,
        child: box,
      ),
    );
  }

  Widget _buildTags(
    Token token,
    double fontSize,
    Widget searchField,
    bool searching,
  ) {
    final values = _current;

    _Tag tagFor(T v) => _Tag(
          token: token,
          fontSize: fontSize,
          enabled: _enabled,
          label: _displayFor(v),
          onRemove: _enabled ? () => _remove(v) : null,
        );

    _Tag overflowChip(int n) => _Tag(
          token: token,
          fontSize: fontSize,
          enabled: _enabled,
          label: Text('+ $n ...'),
        );

    // The inline field must size to its content, not stretch to the row width —
    // otherwise it always claims a full line and pushes the tags (and the
    // caret) onto an empty next line. widthFactor:1 shrinks the Align to its
    // child, and IntrinsicWidth gives the caret field a content-based width.
    final hasTags = values.isNotEmpty;
    final showPlaceholder =
        values.isEmpty && _searchCtrl.text.isEmpty && !_open;
    final Widget fieldChild = showPlaceholder
        ? Text(
            widget.placeholder ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: token.colorTextTertiary,
              fontSize: fontSize,
              fontFamily: token.fontFamily,
              fontFamilyFallback: token.fontFamilyFallback,
              decoration: TextDecoration.none,
            ),
          )
        : IntrinsicWidth(
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: hasTags ? 16 : 60),
              child: searchField,
            ),
          );
    final field = SizedBox(
      height: token.controlHeightSM,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        child: fieldChild,
      ),
    );

    // Responsive: everything on one line, overflow collapsed into a "+N" chip.
    // No vertical padding — the box's minHeight centres a single line, so the
    // height only grows when tags genuinely wrap.
    if (widget.maxTagCountResponsive) {
      return _ResponsiveTagLine(
        spacing: token.sizeXXS,
        overflowBuilder: overflowChip,
        field: field,
        tags: [for (final v in values) tagFor(v)],
      );
    }

    // Numeric cap, or no cap: a wrapping, multi-line row of chips.
    final max = widget.maxTagCount;
    final shown =
        max != null && values.length > max ? values.take(max).toList() : values;
    final overflow = values.length - shown.length;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: token.sizeXXS / 2),
      child: Wrap(
        spacing: token.sizeXXS,
        runSpacing: token.sizeXXS,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final v in shown) tagFor(v),
          if (overflow > 0) overflowChip(overflow),
          field,
        ],
      ),
    );
  }
}

/// Lays tag chips (plus a trailing search field) on a single line, collapsing
/// any chips that do not fit into a trailing "+N" chip — the responsive tag
/// mode. The overflow count is resolved during layout, so the chip's label
/// updates on the following frame (like a popover's caret).
class _ResponsiveTagLine extends StatefulWidget {
  const _ResponsiveTagLine({
    required this.tags,
    required this.field,
    required this.overflowBuilder,
    required this.spacing,
  });

  final List<Widget> tags;
  final Widget field;
  final Widget Function(int hidden) overflowBuilder;
  final double spacing;

  @override
  State<_ResponsiveTagLine> createState() => _ResponsiveTagLineState();
}

class _ResponsiveTagLineState extends State<_ResponsiveTagLine> {
  final ValueNotifier<int> _hidden = ValueNotifier<int>(0);

  @override
  void dispose() {
    _hidden.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _hidden,
      builder: (context, hidden, _) {
        return _TagLineLayout(
          spacing: widget.spacing,
          onHidden: (n) {
            if (_hidden.value != n) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _hidden.value = n;
              });
            }
          },
          children: [
            ...widget.tags,
            // The overflow chip is present but zero-opacity when nothing is
            // hidden, so its measured width can be reserved during layout.
            Offstage(
              offstage: hidden == 0,
              child: widget.overflowBuilder(hidden),
            ),
            widget.field,
          ],
        );
      },
    );
  }
}

class _TagLineLayout extends MultiChildRenderObjectWidget {
  const _TagLineLayout({
    required super.children,
    required this.spacing,
    required this.onHidden,
  });

  final double spacing;
  final ValueChanged<int> onHidden;

  @override
  _RenderTagLine createRenderObject(BuildContext context) =>
      _RenderTagLine(spacing: spacing, onHidden: onHidden);

  @override
  void updateRenderObject(BuildContext context, _RenderTagLine renderObject) {
    renderObject
      ..spacing = spacing
      ..onHidden = onHidden;
  }
}

class _TagLineParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderTagLine extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TagLineParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TagLineParentData> {
  _RenderTagLine({required double spacing, required ValueChanged<int> onHidden})
      : _spacing = spacing,
        _onHidden = onHidden;

  double _spacing;
  set spacing(double v) {
    if (_spacing != v) {
      _spacing = v;
      markNeedsLayout();
    }
  }

  ValueChanged<int> _onHidden;
  set onHidden(ValueChanged<int> v) => _onHidden = v;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TagLineParentData) {
      child.parentData = _TagLineParentData();
    }
  }

  // The children painted this layout: the visible tags, then (if anything is
  // hidden) the overflow chip, then the field. Hidden tags are left out so they
  // do not paint stacked at the origin.
  final List<RenderBox> _painted = [];

  @override
  void performLayout() {
    _painted.clear();
    // Children: [tag0..tagN-1, overflowChip, field]. The last two are special.
    final all = getChildrenAsList();
    final maxWidth = constraints.maxWidth;
    if (all.length < 2) {
      size = constraints.smallest;
      return;
    }
    final field = all.removeLast();
    final overflow = all.removeLast();
    final tags = all;

    final loose = BoxConstraints.loose(Size(maxWidth, constraints.maxHeight));
    for (final c in [...tags, overflow, field]) {
      c.layout(loose, parentUsesSize: true);
    }
    final overflowW = overflow.size.width;
    final fieldW = field.size.width;

    // Greedily keep tags that fit, reserving room for the field and — once we
    // know something must hide — the overflow chip.
    var x = 0.0;
    var visible = 0;
    for (var i = 0; i < tags.length; i++) {
      final w = tags[i].size.width;
      final isLast = i == tags.length - 1;
      final reserve = fieldW + (isLast ? 0 : overflowW + _spacing);
      if (x + w + _spacing + reserve <= maxWidth || i == 0) {
        x += w + _spacing;
        visible++;
      } else {
        break;
      }
    }
    final hidden = tags.length - visible;

    double height = field.size.height;
    for (final c in tags) {
      height = height > c.size.height ? height : c.size.height;
    }

    var cursor = 0.0;
    void place(RenderBox c) {
      (c.parentData as _TagLineParentData).offset =
          Offset(cursor, (height - c.size.height) / 2);
      cursor += c.size.width + _spacing;
      _painted.add(c);
    }

    for (var i = 0; i < visible; i++) {
      place(tags[i]);
    }
    if (hidden > 0) place(overflow);
    place(field);

    size = constraints.constrain(Size(maxWidth, height));
    _onHidden(hidden);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in _painted) {
      final pd = child.parentData as _TagLineParentData;
      context.paintChild(child, offset + pd.offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // Only the painted children are interactive; iterate front-to-back.
    for (final child in _painted.reversed) {
      final pd = child.parentData as _TagLineParentData;
      final hit = result.addWithPaintOffset(
        offset: pd.offset,
        position: position,
        hitTest: (r, transformed) => child.hitTest(r, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}

/// The floating options list.
class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.width,
    required this.minWidth,
    required this.state,
  });

  final double? width;
  final double minWidth;
  final _SelectState<T> state;

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final options = state._visibleOptions;
    final values = state._current;

    // In tags mode, offer to create the typed value — but only when it isn't
    // already an option or selected, so existing options still filter and show.
    final query = state._searchCtrl.text;
    final exists =
        options.any((o) => o._text.toLowerCase() == query.toLowerCase()) ||
            values.map((v) => '$v').contains(query);
    final showCreate =
        state.widget.mode == SelectMode.tags && query.isNotEmpty && !exists;

    Widget body;
    if (state.widget.loading) {
      body = Padding(
        padding: EdgeInsets.all(token.size),
        // heightFactor keeps the panel from expanding to the whole viewport.
        child: Align(
          heightFactor: 1,
          child: Spinner(size: token.fontSizeLG, color: token.primary.base),
        ),
      );
    } else if (options.isEmpty && !showCreate) {
      // notFoundContent wins; else the app-wide emptyBuilder for this slot,
      // which falls back to a default Empty. heightFactor keeps the panel from
      // filling the viewport.
      final empty = state.widget.notFoundContent ??
          ConfigProvider.emptyFor(context, EmptySlot.select);
      body = Align(heightFactor: 1, child: empty);
    } else {
      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: state.widget.listHeight),
        child: ListView.builder(
          controller: state._scrollCtrl,
          shrinkWrap: true,
          padding: EdgeInsets.all(token.sizeXXS),
          itemCount: options.length + (showCreate ? 1 : 0),
          itemBuilder: (context, i) {
            // The create row (tags mode) sits after the filtered options.
            if (showCreate && i == options.length) {
              return _OptionRow<String>(
                option:
                    SelectOption(value: query, label: Text('Create "$query"')),
                selected: false,
                highlighted: options.isEmpty,
                token: token,
                fontSize: state._fontSize(token),
                onTap: () => state._createTag(query),
              );
            }
            final o = options[i];
            return _OptionRow<T>(
              option: o,
              selected: values.contains(o.value),
              // The selected tick appears only in multi-select — a single
              // select marks its choice by highlight alone.
              showCheck: state._multi,
              highlighted: i == state._highlight,
              token: token,
              fontSize: state._fontSize(token),
              selectedIcon: state.widget.menuItemSelectedIcon,
              custom: state.widget.optionRender,
              onHover: o.disabled ? null : () => state._setHighlight(i),
              onTap: o.disabled ? null : () => state._choose(o.value),
            );
          },
        ),
      );
    }

    // No Align/expanding wrapper here: the popover layout delegate positions
    // this box, so it must size to its own content, not to the viewport. The
    // elevated surface is the same [DropdownPanel] the Dropdown menu uses.
    return SizedBox(
      width: width,
      child: DropdownPanel(minWidth: minWidth, child: body),
    );
  }
}

class _OptionRow<T> extends StatefulWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.highlighted,
    required this.token,
    required this.fontSize,
    required this.onTap,
    this.showCheck = true,
    this.onHover,
    this.selectedIcon,
    this.custom,
  });

  final SelectOption<T> option;
  final bool selected;
  final bool showCheck;
  final bool highlighted;
  final Token token;
  final double fontSize;
  final VoidCallback? onTap;
  final VoidCallback? onHover;
  final Widget? selectedIcon;
  final Widget Function(SelectOption<T> option, bool selected)? custom;

  @override
  State<_OptionRow<T>> createState() => _OptionRowState<T>();
}

class _OptionRowState<T> extends State<_OptionRow<T>> {
  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    final r = (ConfigProvider.componentOf<SelectToken>(context) ??
            const SelectToken())
        ._resolve(t);
    final disabled = widget.option.disabled;
    // A single, shared highlight (driven by both keyboard and pointer) — never
    // two rows lit at once.
    final active = widget.highlighted;
    final bg = widget.selected
        ? r.optionSelectedBg
        : active && !disabled
            ? r.optionActiveBg
            : const Color(0x00000000);
    final color = disabled
        ? t.colorTextQuaternary
        : widget.selected
            ? t.colorText
            : t.colorText;

    final content = widget.custom != null
        ? widget.custom!(widget.option, widget.selected)
        : Row(
            children: [
              Expanded(
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: color,
                    fontSize: widget.fontSize,
                    fontWeight:
                        widget.selected ? FontWeight.w600 : FontWeight.w400,
                    fontFamily: t.fontFamily,
                    fontFamilyFallback: t.fontFamilyFallback,
                    decoration: TextDecoration.none,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(color: color, size: widget.fontSize),
                    child: widget.option._display,
                  ),
                ),
              ),
              if (widget.selected && widget.showCheck) ...[
                SizedBox(width: t.sizeXS),
                widget.selectedIcon ??
                    SizedBox(
                      width: widget.fontSize,
                      height: widget.fontSize,
                      child: CustomPaint(
                        painter: CheckPainter(
                          color: t.primary.base,
                          strokeWidth: 1.6,
                        ),
                      ),
                    ),
              ],
            ],
          );

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => widget.onHover?.call(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: t.motionDurationFast,
          height: t.controlHeight,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: r.optionPadding,
          // An option's label reads from the leading edge of its row.
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(t.borderRadiusSM),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// A removable tag chip in a multiple/tags select.
class _Tag extends StatelessWidget {
  const _Tag({
    required this.token,
    required this.fontSize,
    required this.enabled,
    required this.label,
    this.onRemove,
  });

  final Token token;
  final double fontSize;
  final bool enabled;
  final Widget label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? token.colorText : token.colorTextQuaternary;
    return Container(
      height: token.controlHeightSM,
      // The label's own inset, and a narrower one where the remove button
      // sits — which end that is depends on the reading direction.
      padding: EdgeInsetsDirectional.only(
        start: token.sizeXS,
        end: onRemove == null ? token.sizeXS : token.sizeXXS,
      ),
      decoration: BoxDecoration(
        color: token.colorFillSecondary,
        borderRadius: BorderRadius.circular(token.borderRadiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DefaultTextStyle.merge(
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontFamily: token.fontFamily,
              fontFamilyFallback: token.fontFamilyFallback,
              decoration: TextDecoration.none,
            ),
            child: label,
          ),
          if (onRemove != null) ...[
            SizedBox(width: token.sizeXXS),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onRemove,
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CustomPaint(
                    painter: CrossPainter(
                      token.colorTextTertiary,
                      strokeWidth: 1.1,
                      inset: 4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The clear-all (×) button.
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

/// A filled disc with a cross inside — the select's clear button.
class ClearIconPainter extends CustomPainter {
  /// Creates a [ClearIconPainter].
  ClearIconPainter(this.color);

  /// The fill colour of the disc.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    canvas.drawCircle(Offset(r, r), r, Paint()..color = color);
    final stroke = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.34),
      Offset(size.width * 0.66, size.height * 0.66),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.66, size.height * 0.34),
      Offset(size.width * 0.34, size.height * 0.66),
      stroke,
    );
  }

  @override
  bool shouldRepaint(ClearIconPainter old) => old.color != color;
}

/// The trailing chevron, rotating when the dropdown opens.
class _Arrow extends StatelessWidget {
  const _Arrow({required this.color, required this.open});

  final Color color;
  final bool open;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: open ? 0.5 : 0,
      duration: const Duration(milliseconds: 200),
      child: CustomPaint(
        size: const Size(12, 8),
        painter: _ChevronPainter(color),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.1, size.height * 0.25)
        ..lineTo(size.width * 0.5, size.height * 0.75)
        ..lineTo(size.width * 0.9, size.height * 0.25),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

/// The magnifier shown in a searchable select while it is open.
class SearchIcon extends StatelessWidget {
  /// Creates a [SearchIcon].
  const SearchIcon({super.key, required this.color});

  /// The stroke colour of the glass.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(14),
      painter: _MagnifierPainter(color),
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
    canvas.drawCircle(Offset(w * 0.42, h * 0.42), w * 0.28, paint);
    canvas.drawLine(
      Offset(w * 0.64, h * 0.64),
      Offset(w * 0.9, h * 0.9),
      paint,
    );
  }

  @override
  bool shouldRepaint(_MagnifierPainter old) => old.color != color;
}
