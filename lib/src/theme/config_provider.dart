import 'package:flutter/widgets.dart';

import 'components_config.dart';
import 'design_token.dart';

export 'components_config.dart';

/// A resolved theme for the kit.
///
/// Build one from seed values and hand it to a [ConfigProvider]:
///
/// ```dart
/// ThemeData(
///   token: SeedToken(colorPrimary: Color(0xFFEB2F96)),
///   components: ComponentsConfig(
///     avatar: AvatarToken(shape: AvatarShape.square),
///   ),
/// )
/// ```
@immutable
class ThemeData {
  /// Derives a theme from [token], or from the defaults when omitted.
  ThemeData({
    SeedToken? token,
    bool dark = false,
    this.components = const ComponentsConfig(),
  }) : token = Token.derive(token ?? const SeedToken(), dark: dark);

  /// Wraps an already-derived token set.
  const ThemeData.raw(this.token, {this.components = const ComponentsConfig()});

  /// The resolved values components read.
  final Token token;

  /// Per-component token overrides.
  final ComponentsConfig components;

  /// The default light theme.
  static ThemeData get light => ThemeData();

  /// The default dark theme.
  static ThemeData get dark => ThemeData(dark: true);
}

/// Supplies a [ThemeData] to the widgets below it.
///
/// Wrap your application once:
///
/// ```dart
/// ConfigProvider(
///   theme: ThemeData(token: SeedToken(colorPrimary: Colors.red)),
///   child: MaterialApp(...),
/// )
/// ```
class ConfigProvider extends InheritedWidget {
  /// Creates a [ConfigProvider].
  ConfigProvider({
    super.key,
    ThemeData? theme,
    this.renderEmpty,
    this.components = const [],
    required super.child,
  }) : theme = theme ?? ThemeData();

  /// The theme handed to every widget below this point.
  final ThemeData theme;

  /// Global default for the "no data" placeholder. When null, components fall back to a default
  /// `Empty`. A per-component override (such as a `Select`'s `notFoundContent`)
  /// still wins over this.
  final WidgetBuilder? renderEmpty;

  /// Legacy or additional per-component token overrides.
  final List<Object> components;

  /// The nearest theme, falling back to the defaults when no provider is found.
  static ThemeData of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ConfigProvider>();
    return provider?.theme ?? _fallback;
  }

  /// The nearest configured empty-state builder, or null when none is set.
  static WidgetBuilder? renderEmptyOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ConfigProvider>()?.renderEmpty;

  /// The nearest component token of type [T] supplied via [theme.components] or [components], or null.
  static T? componentOf<T>(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ConfigProvider>();
    if (provider == null) return null;

    final fromConfig = provider.theme.components.of<T>();
    if (fromConfig != null) return fromConfig;

    for (final c in provider.components) {
      if (c is T) return c as T;
    }
    return null;
  }

  /// Components must render even when the app never installed a provider,
  /// so an unconfigured tree silently gets the default theme.
  static final ThemeData _fallback = ThemeData();

  @override
  bool updateShouldNotify(ConfigProvider oldWidget) =>
      oldWidget.theme != theme ||
      oldWidget.renderEmpty != renderEmpty ||
      !identical(oldWidget.components, components);
}

/// Shorthand for reading theme values: `context.softToken.colorPrimary`.
extension ThemeContext on BuildContext {
  /// The nearest theme's tokens.
  ///
  /// Reading this registers a dependency, so the widget rebuilds when the
  /// theme changes.
  Token get softToken => ConfigProvider.of(this).token;
}
