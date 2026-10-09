import 'package:flutter/widgets.dart';

import '../icons/icons.dart' show CrossPainter;
import '../theme/config_provider.dart';
import 'pressable.dart';

/// The cross that closes a dialog, a drawer, a notification or an alert.
///
/// Four components drew this same cross for themselves, and they had drifted:
/// two were named for a screen reader and two arrived as "button" and nothing
/// more; two could be reached from the keyboard and two could not. One cross
/// means one place to get those right.
///
/// Built on [Pressable], so it is a stop in the tab order, answers `Space` and
/// `Enter`, wears the focus ring, and is called by the kit's own word for
/// close in whatever language the app is in.
class CloseCross extends StatefulWidget {
  /// Creates a [CloseCross].
  const CloseCross({
    super.key,
    required this.onPressed,
    this.wash = true,
    this.semanticsLabel,
  });

  /// How wide and tall the cross's target is — also the room a title leaves
  /// for one standing over its corner.
  static const double extent = 22;

  /// Called when it is pressed, by any means.
  final VoidCallback onPressed;

  /// Whether a hover lays a faint fill behind the cross as well as darkening
  /// it. An alert, which is already tinted, darkens the cross alone.
  final bool wash;

  /// What a screen reader calls it. Defaults to the kit's word for close.
  final String? semanticsLabel;

  @override
  State<CloseCross> createState() => _CloseCrossState();
}

class _CloseCrossState extends State<CloseCross> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    return Pressable(
      onPressed: widget.onPressed,
      semanticsLabel: widget.semanticsLabel ?? context.seedLocale.close,
      radius: token.borderRadiusSM,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        // [Pressable] answers the keyboard and a screen reader; a finger or
        // a pointer is answered here. Out of the semantics tree, or it stands
        // under the named button as a second, wordless one a reader can land
        // on.
        child: GestureDetector(
          onTap: widget.onPressed,
          excludeFromSemantics: true,
          child: Container(
            width: CloseCross.extent,
            height: CloseCross.extent,
            decoration: BoxDecoration(
              color: _hovered && widget.wash ? token.colorFillSecondary : null,
              borderRadius: BorderRadius.circular(token.borderRadiusSM),
            ),
            child: CustomPaint(
              painter: CrossPainter(
                _hovered ? token.colorText : token.colorTextTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where a close button stands in a `Modal` or a notification, and what
/// makes room for it.
///
/// ```dart
/// Modal.open(ModalConfig(closePlacement: ClosePlacement.corner, …));
/// notification.open(NotificationConfig(closePlacement: ClosePlacement.corner, …));
/// ```
enum ClosePlacement {
  /// In a column of its own beside the title and the content, which are both
  /// narrowed by it all the way down. Nothing can ever run under it.
  beside,

  /// In the corner, over the card. The title keeps clear of it; whatever is
  /// below the title runs the card's full width.
  ///
  /// With no title, nothing makes room: content that starts at the top runs
  /// under the cross unless it leaves room itself.
  corner,
}
