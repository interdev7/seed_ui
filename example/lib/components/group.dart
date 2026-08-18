import 'package:flutter/widgets.dart';
import 'package:seed_ui/seed_ui.dart';

/// Marks that a [Group] is already drawing a surface further up, so the ones
/// inside it only label their content.
class _InGroup extends InheritedWidget {
  const _InGroup({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InGroup>() != null;

  @override
  bool updateShouldNotify(_InGroup old) => false;
}

/// A labelled block within a component demo page.
class Group extends StatelessWidget {
  const Group(this.label, this.child, {super.key});

  /// The block's heading. A plain [String] is wrapped in a styled [Text];
  /// pass a [Widget] for anything richer.
  final Object label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    // Several components stand on the layout colour by design — a Segmented's
    // track is that colour, as it is in Ant Design — and a page painted the
    // same hides them. So the block gets a container surface of its own.
    //
    // Only the outermost, though: demos nest groups to caption their parts,
    // and a card inside a card would spend its padding twice over, which is
    // enough to crush a row of segments into wrapping.
    final nested = _InGroup.of(context);

    final body = DefaultTextStyle(
      style: TextStyle(
        fontSize: token.fontSize,
        color: token.colorText,
        fontFamily: token.fontFamily,
        fontFamilyFallback: token.fontFamilyFallback,
        decoration: TextDecoration.none,
      ),
      child: child,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: token.sizeLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: token.sizeSM),
            child: label is Widget
                ? label as Widget
                : Text(
                    '$label',
                    style: TextStyle(
                      fontSize: token.fontSize,
                      color: token.colorTextSecondary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
          ),
          if (nested)
            body
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(token.sizeLG),
              decoration: BoxDecoration(
                color: token.colorBgContainer,
                borderRadius: BorderRadius.circular(token.borderRadiusLG),
                border: Border.all(color: token.colorBorderSecondary),
              ),
              child: _InGroup(child: body),
            ),
        ],
      ),
    );
  }
}
