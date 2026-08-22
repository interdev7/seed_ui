import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter/widgets.dart';

import '../l10n/seed_localizations.dart';
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
    Key? key,
    ThemeData? theme,
    WidgetBuilder? renderEmpty,
    List<Object> components = const [],
    bool systemOverlayStyle = true,
    SeedLocalizations? locale,
    required Widget child,
  }) : this._(
          key: key,
          theme: theme ?? ThemeData(),
          renderEmpty: renderEmpty,
          components: components,
          systemOverlayStyle: systemOverlayStyle,
          locale: locale,
          child: child,
        );

  ConfigProvider._({
    super.key,
    required this.theme,
    required this.renderEmpty,
    required this.components,
    required this.systemOverlayStyle,
    required this.locale,
    required Widget child,
  }) : super(
          // Declared rather than pushed through `SystemChrome`, so the style
          // belongs to this subtree instead of mutating global state that
          // whatever else is on screen would have to fight.
          child: systemOverlayStyle
              ? AnnotatedRegion<SystemUiOverlayStyle>(
                  value: _overlayStyleFor(theme.token.isDark),
                  child: child,
                )
              : child,
        );

  /// Status-bar icons legible against a theme of this brightness.
  ///
  /// Only the icon brightness is stated: the bar's own colour is left to the
  /// app, so a translucent or coloured status bar is not overridden.
  /// `statusBarIconBrightness` is the Android knob and `statusBarBrightness`
  /// the iOS one, and the two are inverses of each other — iOS names the
  /// brightness of the *background* the icons sit on.
  static SystemUiOverlayStyle _overlayStyleFor(bool isDark) =>
      SystemUiOverlayStyle(
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      );

  /// Whether this provider states a status-bar style matching its theme.
  ///
  /// On by default: a dark theme otherwise leaves the platform's dark status
  /// bar icons on a dark bar, where they cannot be seen. Turn it off if the
  /// app drives the system chrome itself — through `AppBar.systemOverlayStyle`
  /// or its own [AnnotatedRegion].
  final bool systemOverlayStyle;

  /// The words the kit says on its own account, for this subtree.
  ///
  /// Overrides whatever `SeedLocalizations.delegate` resolved, which is what
  /// puts one dialog into another language, or replaces a single word without
  /// forking a whole language. Null leaves the delegate in charge.
  final SeedLocalizations? locale;

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

  /// The component token of type [T] in scope, or null when none is set.
  ///
  /// Searched from the nearest provider outwards rather than stopping at the
  /// first one. Providers nest — a theme switcher, a screen that recolours a
  /// corner — and one that says nothing about a component should leave it as
  /// the provider above it had it, not silently reset it to the defaults.
  /// Stopping at the nearest is what makes a token set once at the top of an
  /// app fail to reach a button two providers down.
  static T? componentOf<T>(BuildContext context) {
    T? found;
    _visitProviders(context, (provider) {
      final fromConfig = provider.theme.components.of<T>();
      if (fromConfig != null) {
        found = fromConfig;
        return false;
      }
      for (final c in provider.components) {
        if (c is T) {
          found = c as T;
          return false;
        }
      }
      return true;
    });
    return found;
  }

  /// Calls [visit] with each provider above [context], nearest first, until it
  /// returns false or they run out.
  ///
  /// Every one visited is depended on, so a change to any of them rebuilds the
  /// widget that asked — including the outer provider that supplied the token
  /// the nearer ones were silent about.
  static void _visitProviders(
    BuildContext context,
    bool Function(ConfigProvider provider) visit,
  ) {
    var carryOn = true;
    context.visitAncestorElements((element) {
      if (element is InheritedElement && element.widget is ConfigProvider) {
        context.dependOnInheritedElement(element);
        carryOn = visit(element.widget as ConfigProvider);
      }
      return carryOn;
    });
  }

  /// Components must render even when the app never installed a provider,
  /// so an unconfigured tree silently gets the default theme.
  static final ThemeData _fallback = ThemeData();

  @override
  bool updateShouldNotify(ConfigProvider oldWidget) =>
      oldWidget.theme != theme ||
      oldWidget.renderEmpty != renderEmpty ||
      oldWidget.locale != locale ||
      !identical(oldWidget.components, components);
}

/// Shorthand for reading theme values: `context.softToken.colorPrimary`.
extension ThemeContext on BuildContext {
  /// The nearest theme's tokens.
  ///
  /// Reading this registers a dependency, so the widget rebuilds when the
  /// theme changes.
  Token get softToken => ConfigProvider.of(this).token;

  /// The words the kit says here.
  ///
  /// The nearest [ConfigProvider.locale] wins, then whatever
  /// `SeedLocalizations.delegate` resolved from the app's locale, then
  /// English. A provider is the more specific of the two, and the only one
  /// that can differ from one subtree to the next.
  SeedLocalizations get seedLocale {
    final provider =
        dependOnInheritedWidgetOfExactType<ConfigProvider>()?.locale;
    return provider ?? SeedLocalizations.of(this);
  }
}
