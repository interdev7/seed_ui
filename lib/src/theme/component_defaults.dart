import 'package:flutter/foundation.dart';

import '../components/data_display/empty.dart';
import '../components/data_display/tag.dart';
import '../components/data_entry/input.dart';
import '../components/data_entry/select.dart';
import '../components/general/button.dart';

/// Default props for components under a `ConfigProvider`.
///
/// The second half of configuring a component, beside `ThemeData.components`.
/// That one carries **tokens** — the numbers and colours a component draws
/// with. This one carries the component's **own props**, applied wherever a
/// widget does not name one for itself.
///
/// ```dart
/// ConfigProvider(
///   theme: ThemeData(
///     // how a button is drawn
///     components: ComponentsConfig(button: ButtonToken(borderRadius: 16)),
///   ),
///   // what a button is, unless it says otherwise
///   defaults: ComponentDefaults(
///     button: ButtonDefaults(shape: ButtonShape.round),
///   ),
///   child: ...,
/// )
/// ```
///
/// A widget's own prop always wins, and these are inherited like the rest of
/// the configuration: a nested provider silent about a component leaves it as
/// the provider above had it.
@immutable
class ComponentDefaults {
  /// Creates a [ComponentDefaults].
  const ComponentDefaults({
    this.button,
    this.empty,
    this.input,
    this.select,
    this.tag,
  });

  /// Applied to every [Button] under this provider.
  final ButtonDefaults? button;

  /// Applied to every [Empty] under this provider.
  final EmptyDefaults? empty;

  /// Applied to every [Input] under this provider.
  final InputDefaults? input;

  /// Applied to every [Select] under this provider.
  final SelectDefaults? select;

  /// Applied to every [Tag] under this provider.
  final TagDefaults? tag;

  /// This set with [other] laid over it: every slot [other] names wins, the
  /// rest are kept.
  ComponentDefaults merge(ComponentDefaults other) => ComponentDefaults(
        button: other.button ?? button,
        empty: other.empty ?? empty,
        input: other.input ?? input,
        select: other.select ?? select,
        tag: other.tag ?? tag,
      );

  /// Fast lookup for a specific defaults type [T].
  T? of<T>() {
    if (T == ButtonDefaults && button != null) return button as T;
    if (T == EmptyDefaults && empty != null) return empty as T;
    if (T == InputDefaults && input != null) return input as T;
    if (T == SelectDefaults && select != null) return select as T;
    if (T == TagDefaults && tag != null) return tag as T;
    return null;
  }
}
