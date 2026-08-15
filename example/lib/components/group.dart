import 'package:flutter/widgets.dart';
import 'package:seed_ui/seed_ui.dart';

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
          DefaultTextStyle(
            style: TextStyle(
              fontSize: token.fontSize,
              color: token.colorText,
              fontFamily: token.fontFamily,
              fontFamilyFallback: token.fontFamilyFallback,
              decoration: TextDecoration.none,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
