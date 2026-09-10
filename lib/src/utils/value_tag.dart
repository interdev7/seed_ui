import 'package:flutter/widgets.dart';

import '../icons/icons.dart';
import '../theme/design_token.dart';

/// One value a control is holding, drawn as a chip with a cross.
///
/// Shared, because a control holding several things shows them the same way
/// wherever it does it: a `Select` in one of its many modes, a picker
/// collecting more than one date. The tag knows nothing about either — it is
/// handed a label and told what happens when its cross is pressed.
class ValueTag extends StatelessWidget {
  /// Creates a tag.
  const ValueTag({
    required this.token,
    required this.fontSize,
    required this.enabled,
    required this.label,
    this.onRemove,
    this.removeIcon,
    super.key,
  });

  /// The theme's numbers and colours.
  final Token token;

  /// The type size of whatever it stands beside.
  final double fontSize;

  /// Whether the control it belongs to may be used.
  final bool enabled;

  /// What it says.
  final Widget label;

  /// Takes this one out. A tag with nowhere to go carries no cross.
  final VoidCallback? onRemove;

  /// Replaces the cross. The mark only — where it sits and what pressing it
  /// does stay the tag's business.
  final Widget? removeIcon;

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
          // Flexible, so a tag squeezed into less room than its words want
          // ellipsises them rather than spilling over its own edge. A line of
          // tags hands out what room there is; the last one to be kept may
          // get less than it asked for.
          Flexible(
            child: DefaultTextStyle.merge(
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontFamily: token.fontFamily,
                fontFamilyFallback: token.fontFamilyFallback,
                decoration: TextDecoration.none,
              ),
              child: label,
            ),
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
                  child: removeIcon ??
                      CustomPaint(
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
