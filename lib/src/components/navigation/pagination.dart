import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme/config_provider.dart';
import '../../theme/design_token.dart';
import '../data_entry/input.dart';
import '../data_entry/input_number.dart';
import '../data_entry/select.dart';
import '../general/button.dart';

/// Turns on [Pagination]'s compact "simple" mode.
/// Pass a `PaginationSimple()` to enable it,
/// with [readOnly] to show the page as text instead of an editable input.
@immutable
class PaginationSimple {
  /// Creates a [PaginationSimple].
  const PaginationSimple({this.readOnly = false});

  /// Whether the current-page field is read-only rather than editable.
  final bool readOnly;
}

/// One rendered slot in the pager: a numbered [page], or an ellipsis that jumps
/// [forward] (or back) when tapped.
class _PagerEntry {
  const _PagerEntry.page(this.page) : forward = null;
  const _PagerEntry.jump(bool this.forward) : page = null;

  final int? page;
  final bool? forward;

  bool get isEllipsis => page == null;
}

/// Per-component design tokens for [Pagination].
///
/// Every field is an override; a null one falls back to the value derived from
/// the global theme. Supply one globally through `ConfigProvider(components:
/// [PaginationToken(...)])`, or per instance via [Pagination.token].
@immutable
class PaginationToken {
  /// Creates a [PaginationToken].
  const PaginationToken({
    this.itemBg,
    this.itemActiveBg,
    this.itemActiveColorPrimary,
    this.fontSize,
    this.borderRadius,
  });

  /// Page item background color.
  final Color? itemBg;

  /// Active page item background color.
  final Color? itemActiveBg;

  /// Active page item primary / border color.
  final Color? itemActiveColorPrimary;

  /// Label font size.
  final double? fontSize;

  /// Corner radius.
  final double? borderRadius;

  _ResolvedPaginationToken _resolve(Token t) => _ResolvedPaginationToken(
        itemBg: itemBg ?? t.colorBgContainer,
        itemActiveBg: itemActiveBg ?? t.colorBgContainer,
        itemActiveColorPrimary: itemActiveColorPrimary ?? t.primary.base,
        fontSize: fontSize ?? t.fontSize,
        borderRadius: borderRadius ?? t.borderRadius,
      );
}

@immutable
class _ResolvedPaginationToken {
  const _ResolvedPaginationToken({
    required this.itemBg,
    required this.itemActiveBg,
    required this.itemActiveColorPrimary,
    required this.fontSize,
    required this.borderRadius,
  });

  final Color itemBg;
  final Color itemActiveBg;
  final Color itemActiveColorPrimary;
  final double fontSize;
  final double borderRadius;
}

/// A pager for splitting a long list across pages.
///
/// ```dart
/// Pagination(
///   current: _page,
///   total: 235,
///   pageSize: 10,
///   onChange: (page, size) => setState(() => _page = page),
/// )
/// ```
///
/// Drive it controlled with [current] + [onChange], or uncontrolled with
/// [defaultCurrent]. Turn on [showSizeChanger] for a page-size selector,
/// [showQuickJumper] to jump to a page, and [showTotal] for a summary.
class Pagination extends StatefulWidget {
  /// Creates a [Pagination].
  const Pagination({
    super.key,
    required this.total,
    this.current,
    this.defaultCurrent = 1,
    this.pageSize,
    this.defaultPageSize = 10,
    this.onChange,
    this.showSizeChanger = false,
    this.pageSizeOptions = const [10, 20, 50, 100],
    this.onShowSizeChange,
    this.showQuickJumper = false,
    this.showTotal,
    this.simple,
    this.size = SoftSize.middle,
    this.disabled = false,
    this.hideOnSinglePage = false,
    this.showLessItems = false,
    this.align = MainAxisAlignment.start,
    this.token,
  });

  /// The total number of items to paginate.
  final int total;

  /// The current page (1-based). Null makes the pager uncontrolled.
  final int? current;

  /// Initial page for an uncontrolled pager.
  final int defaultCurrent;

  /// Items per page. Null makes the page size uncontrolled.
  final int? pageSize;

  /// Initial page size for an uncontrolled pager.
  final int defaultPageSize;

  /// Called with the new `(page, pageSize)` when either changes.
  final void Function(int page, int pageSize)? onChange;

  /// Shows a selector for the page size.
  final bool showSizeChanger;

  /// The page sizes offered by the size changer.
  final List<int> pageSizeOptions;

  /// Called with the new `(page, pageSize)` when the size changes.
  final void Function(int page, int pageSize)? onShowSizeChange;

  /// Shows an input to jump straight to a page.
  final bool showQuickJumper;

  /// Builds a summary such as "1-10 of 235 items". Given the total and the
  /// `[from, to]` range of the current page.
  final Widget Function(int total, int from, int to)? showTotal;

  /// Non-null turns on the compact "simple" mode: just the arrows and a
  /// "current / total" field. See [PaginationSimple.readOnly].
  final PaginationSimple? simple;

  /// Which height preset to use.
  final SoftSize size;

  /// Greys the whole pager out and blocks interaction.
  final bool disabled;

  /// Renders nothing when there is only a single page.
  final bool hideOnSinglePage;

  /// Shows fewer page numbers around the current one.
  final bool showLessItems;

  /// How the row is aligned within its width.
  final MainAxisAlignment align;

  /// Per-instance token overrides.
  final PaginationToken? token;

  @override
  State<Pagination> createState() => _PaginationState();
}

class _PaginationState extends State<Pagination> {
  int? _current;
  int? _pageSize;

  int get _page => widget.current ?? _current ?? widget.defaultCurrent;
  int get _size => widget.pageSize ?? _pageSize ?? widget.defaultPageSize;

  int get _pageCount => (widget.total / _size).ceil().clamp(1, 1 << 31);

  bool get _enabled => !widget.disabled;
  bool get _simpleMode => widget.simple != null;

  void _goTo(int page) {
    final next = page.clamp(1, _pageCount);
    if (next == _page) return;
    if (widget.current == null) setState(() => _current = next);
    widget.onChange?.call(next, _size);
  }

  void _changeSize(int size) {
    // Keep the first item of the current view visible after resizing.
    final firstItem = (_page - 1) * _size;
    final nextPage = (firstItem ~/ size) + 1;
    if (widget.pageSize == null) setState(() => _pageSize = size);
    if (widget.current == null) setState(() => _current = nextPage);
    widget.onShowSizeChange?.call(nextPage, size);
    widget.onChange?.call(nextPage, size);
  }

  double _controlHeight(Token t) => switch (widget.size) {
        SoftSize.small => t.controlHeightSM,
        SoftSize.middle => t.controlHeight,
        SoftSize.large => t.controlHeightLG,
      };

  double _fontSize(Token t) => switch (widget.size) {
        SoftSize.small => t.fontSizeSM,
        SoftSize.middle => t.fontSize,
        SoftSize.large => t.fontSizeLG,
      };

  /// The page buttons and ellipsis jumps to show. First and last page are
  /// always present; near an edge up to five consecutive pages show, otherwise
  /// just the current page and its neighbours, with an ellipsis on each side.
  List<_PagerEntry> _entries() {
    final last = _pageCount;
    final near = widget.showLessItems ? 3 : 4; // "near an edge" threshold
    final out = <_PagerEntry>[];
    void page(int p) => out.add(_PagerEntry.page(p));
    void jump(bool forward) => out.add(_PagerEntry.jump(forward));

    if (last <= near + 3) {
      for (var p = 1; p <= last; p++) {
        page(p);
      }
    } else if (_page <= near) {
      // Near the start: 1 … near+1, ellipsis, last.
      for (var p = 1; p <= near + 1; p++) {
        page(p);
      }
      jump(true);
      page(last);
    } else if (_page >= last - (near - 1)) {
      // Near the end: 1, ellipsis, last-near … last.
      page(1);
      jump(false);
      for (var p = last - near; p <= last; p++) {
        page(p);
      }
    } else {
      // Middle: 1, ellipsis, current-1 current current+1, ellipsis, last.
      page(1);
      jump(false);
      page(_page - 1);
      page(_page);
      page(_page + 1);
      jump(true);
      page(last);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final pt = (widget.token ??
            ConfigProvider.componentOf<PaginationToken>(context) ??
            const PaginationToken())
        ._resolve(token);
    if (widget.hideOnSinglePage && _pageCount <= 1) {
      return const SizedBox.shrink();
    }
    final height = _controlHeight(token);
    final fontSize = _fontSize(token);

    // The pager itself — arrows and page numbers — is one atomic Row, so its
    // pieces never wrap individually. The total, size changer and jumper are
    // separate Wrap children, so only whole blocks flow onto a second line.
    final gap = SizedBox(width: token.sizeXXS);
    final pager = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Arrow(
          size: widget.size,
          token: token,
          direction: _ArrowDir.prev,
          enabled: _enabled && _page > 1,
          onTap: () => _goTo(_page - 1),
        ),
        gap,
        if (_simpleMode) ...[
          _simpleBody(token, fontSize, height),
          gap,
        ] else
          for (final w in _numbers(token, pt, fontSize, height)) ...[w, gap],
        _Arrow(
          size: widget.size,
          token: token,
          direction: _ArrowDir.next,
          enabled: _enabled && _page < _pageCount,
          onTap: () => _goTo(_page + 1),
        ),
      ],
    );

    final children = <Widget>[
      if (widget.showTotal != null) _total(token, fontSize),
      // The run of pages is atomic on purpose, so it cannot be given less room
      // than it needs — a narrow screen, or figures wider than the Latin ones
      // it was measured against, and it simply overflowed. It scrolls instead,
      // the way a long row of segments does. IntrinsicWidth asks the row how
      // wide it wants to be and then honours the incoming constraint: room
      // enough and the viewport is exactly the row, with nothing to scroll, so
      // the common case is unchanged.
      IntrinsicWidth(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: pager,
        ),
      ),
      if (widget.showSizeChanger) _sizeChanger(token),
      if (widget.showQuickJumper && !_simpleMode)
        _quickJumper(token, fontSize, height),
    ];

    return Wrap(
      spacing: token.sizeSM,
      runSpacing: token.sizeXS,
      alignment: switch (widget.align) {
        MainAxisAlignment.center => WrapAlignment.center,
        MainAxisAlignment.end => WrapAlignment.end,
        MainAxisAlignment.spaceBetween => WrapAlignment.spaceBetween,
        MainAxisAlignment.spaceAround => WrapAlignment.spaceAround,
        MainAxisAlignment.spaceEvenly => WrapAlignment.spaceEvenly,
        _ => WrapAlignment.start,
      },
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  Widget _total(Token token, double fontSize) {
    final from = widget.total == 0 ? 0 : (_page - 1) * _size + 1;
    final to = (_page * _size).clamp(0, widget.total);
    return DefaultTextStyle.merge(
      style: TextStyle(
        color: token.colorText,
        fontSize: fontSize,
        fontFamily: token.fontFamily,
        fontFamilyFallback: token.fontFamilyFallback,
        decoration: TextDecoration.none,
      ),
      child: widget.showTotal!(widget.total, from, to),
    );
  }

  List<Widget> _numbers(
    Token token,
    _ResolvedPaginationToken pt,
    double fontSize,
    double height,
  ) {
    return [
      for (final entry in _entries())
        if (entry.isEllipsis)
          _Ellipsis(
            token: token,
            height: height,
            enabled: _enabled,
            // Jump five pages toward the gap.
            onTap: () => _goTo(entry.forward! ? _page + 5 : _page - 5),
            forward: entry.forward!,
          )
        else
          _PageItem(
            token: token,
            paginationToken: pt,
            height: height,
            size: widget.size,
            fontSize: fontSize,
            label: context.seedLocale.figures('${entry.page}'),
            active: entry.page == _page,
            enabled: _enabled,
            onTap: () => _goTo(entry.page!),
          ),
    ];
  }

  Widget _simpleBody(Token token, double fontSize, double height) {
    final readOnly = widget.simple?.readOnly ?? false;
    final width = height + token.sizeMD;

    final inputWidget = kIsWeb
        ? InputNumber(
            key: ValueKey(_page),
            size: widget.size,
            defaultValue: _page,
            disabled: !_enabled || readOnly,
            onSubmitted: (v) {
              final n = int.tryParse(v.trim());
              if (n != null) _goTo(n);
            },
          )
        : Input(
            key: ValueKey(_page),
            size: widget.size,
            defaultValue: context.seedLocale.figures('$_page'),
            disabled: !_enabled || readOnly,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _MaxValueFormatter(_pageCount),
            ],
            onSubmitted: (v) {
              final n = int.tryParse(v.trim());
              if (n != null) _goTo(n);
            },
          );

    // Read-only shows the page in a compact, non-editable counter box — a
    // custom widget rather than a disabled Input, so the digit sits centred
    // without a text field's asymmetric insets.
    final Widget field = readOnly
        ? Text(
            context.seedLocale.figures('$_page'),
            style: TextStyle(
              color: token.colorText,
              fontSize: fontSize,
              decoration: TextDecoration.none,
            ),
          )
        : SizedBox(
            // No fixed height — the Input sizes itself and centres its text.
            width: width * (kIsWeb ? 1.1 : 1.0),
            child: inputWidget,
          );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        field,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: token.sizeXS),
          child: Text(
            '/',
            style: TextStyle(
              color: token.colorText,
              fontSize: fontSize,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        Text(
          context.seedLocale.figures('$_pageCount'),
          style: TextStyle(
            color: token.colorText,
            fontSize: fontSize,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _sizeChanger(Token token) {
    return SizedBox(
      width: 110,
      child: Select<int>(
        value: [_size],
        size: widget.size,
        disabled: !_enabled,
        options: [
          for (final s in widget.pageSizeOptions)
            SelectOption(
              value: s,
              filterText: '${context.seedLocale.figures('$s')} '
                  '${context.seedLocale.perPage}',
            ),
        ],
        onChanged: (v) {
          if (v.isNotEmpty) _changeSize(v.first);
        },
      ),
    );
  }

  Widget _quickJumper(Token token, double fontSize, double height) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Go to',
          style: TextStyle(
            color: token.colorText,
            fontSize: fontSize,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(width: token.sizeXS),
        SizedBox(
          width: height + token.sizeXL,
          child: Input(
            size: widget.size,
            disabled: !_enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _MaxValueFormatter(_pageCount),
            ],
            onSubmitted: (v) {
              final n = int.tryParse(v.trim());
              if (n != null) _goTo(n);
            },
          ),
        ),
      ],
    );
  }
}

/// Rejects an edit whose number exceeds [max] (keeps the previous value), so a
/// page field can never hold a page beyond the last.
class _MaxValueFormatter extends TextInputFormatter {
  _MaxValueFormatter(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final n = int.tryParse(newValue.text);
    if (n == null || n > max) return oldValue;
    return newValue;
  }
}

enum _ArrowDir { prev, next }

/// A borderless prev/next chevron — no box, like the pager arrows.
class _Arrow extends StatefulWidget {
  const _Arrow({
    required this.token,
    required this.direction,
    required this.enabled,
    required this.onTap,
    this.size = SoftSize.middle,
  });

  final Token token;
  final SoftSize size;
  final _ArrowDir direction;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_Arrow> createState() => _ArrowState();
}

class _ArrowState extends State<_Arrow> {
  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    final size = switch (widget.size) {
      SoftSize.small => t.sizeSM,
      SoftSize.middle => t.sizeMD,
      SoftSize.large => t.sizeLG,
    };
    return Button(
      disabled: !widget.enabled,
      size: widget.size,
      variant: ButtonVariant.text,
      icon: CustomPaint(
        size: Size(size * 0.65, size * 0.65),
        painter: _ChevronPainter(
          widget.enabled ? t.colorText : t.colorTextQuaternary,
          widget.direction == _ArrowDir.next,
        ),
      ),

      // Icon(
      //   widget.direction == _ArrowDir.next ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_left,
      //   size: size,
      // ),
      onPressed: widget.onTap,
    );
  }
}

/// A single numbered page button.
class _PageItem extends StatefulWidget {
  const _PageItem({
    required this.token,
    required this.paginationToken,
    required this.height,
    required this.fontSize,
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
    required this.size,
  });

  final Token token;
  final _ResolvedPaginationToken paginationToken;
  final double height;
  final double fontSize;
  final String label;
  final bool active;
  final bool enabled;
  final SoftSize size;
  final VoidCallback onTap;

  @override
  State<_PageItem> createState() => _PageItemState();
}

class _PageItemState extends State<_PageItem> {
  final bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    final pt = widget.paginationToken;
    final Color color;
    if (!widget.enabled) {
      color = t.colorTextQuaternary;
    } else if (widget.active) {
      color = _hovered ? t.primary.hover : pt.itemActiveColorPrimary;
    } else if (_hovered) {
      color = t.primary.hover;
    } else {
      color = t.colorText;
    }
    return Button(
      disabled: !widget.enabled,
      size: widget.size,
      variant: widget.active ? ButtonVariant.outlined : ButtonVariant.text,
      onPressed: widget.enabled ? widget.onTap : null,
      icon: Text(
        widget.label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: widget.fontSize,
          fontWeight: widget.active ? FontWeight.w600 : FontWeight.w400,
          fontFamily: t.fontFamily,
          fontFamilyFallback: t.fontFamilyFallback,
          height: 1.0,
          leadingDistribution: TextLeadingDistribution.even,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

/// An ellipsis that turns into a double-chevron jump on hover.
class _Ellipsis extends StatefulWidget {
  const _Ellipsis({
    required this.token,
    required this.height,
    required this.enabled,
    required this.onTap,
    required this.forward,
  });

  final Token token;
  final double height;
  final bool enabled;
  final VoidCallback onTap;
  final bool forward;

  @override
  State<_Ellipsis> createState() => _EllipsisState();
}

class _EllipsisState extends State<_Ellipsis> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.token;
    return MouseRegion(
      cursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: SizedBox(
          width: widget.height,
          height: widget.height,
          child: Center(
            child: _hovered && widget.enabled
                ? CustomPaint(
                    size: const Size(14, 10),
                    painter:
                        _DoubleChevronPainter(t.primary.base, widget.forward),
                  )
                : CustomPaint(
                    size: const Size(16, 16),
                    painter: _DotsPainter(t.colorTextTertiary),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color, this.forward);

  final Color color;
  final bool forward;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    final path = forward
        ? (Path()
          ..moveTo(w * 0.35, h * 0.15)
          ..lineTo(w * 0.7, h * 0.5)
          ..lineTo(w * 0.35, h * 0.85))
        : (Path()
          ..moveTo(w * 0.65, h * 0.15)
          ..lineTo(w * 0.3, h * 0.5)
          ..lineTo(w * 0.65, h * 0.85));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChevronPainter old) =>
      old.color != color || old.forward != forward;
}

class _DoubleChevronPainter extends CustomPainter {
  _DoubleChevronPainter(this.color, this.forward);

  final Color color;
  final bool forward;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final h = size.height;
    void chevron(double cx) {
      final path = forward
          ? (Path()
            ..moveTo(cx - 2, h * 0.2)
            ..lineTo(cx + 2, h * 0.5)
            ..lineTo(cx - 2, h * 0.8))
          : (Path()
            ..moveTo(cx + 2, h * 0.2)
            ..lineTo(cx - 2, h * 0.5)
            ..lineTo(cx + 2, h * 0.8));
      canvas.drawPath(path, paint);
    }

    chevron(size.width * 0.35);
    chevron(size.width * 0.62);
  }

  @override
  bool shouldRepaint(_DoubleChevronPainter old) =>
      old.color != color || old.forward != forward;
}

/// Three horizontal dots, vertically centred — the resting ellipsis glyph.
class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cy = size.height / 2;
    final cx = size.width / 2;
    const r = 1.1;
    const gap = 5.0; // dot spacing, a touch wider than before
    for (final dx in [-gap, 0.0, gap]) {
      canvas.drawCircle(Offset(cx + dx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}
