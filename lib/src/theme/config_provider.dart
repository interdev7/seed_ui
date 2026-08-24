import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter/widgets.dart';

import '../components/data_display/empty.dart';
import '../l10n/seed_localizations.dart';
import 'components_config.dart';
import 'design_token.dart';

export 'components_config.dart';

/// Which component is asking for the "no data" placeholder.
///
/// Handed to [ConfigProvider.emptyBuilder] so one builder can answer for the
/// whole app and still tell a dropdown apart from a page-sized list — the two
/// want very different placeholders, and without the slot a global builder has
/// to give them the same one.
enum EmptySlot {
  /// A [Select] whose dropdown has no options left to show.
  select,

  /// A [Listy] with no rows.
  listy,
}

/// Builds the "no data" placeholder for [slot].
typedef EmptyBuilder = Widget Function(BuildContext context, EmptySlot slot);

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
///
/// A theme inside another theme inherits what it does not mention. Say only
/// `components` and the colours above it stay; say only a seed colour and the
/// brightness above it stays. What a nested theme states, it states — and only
/// that. See [ConfigProvider] for the whole picture.
@immutable
class ThemeData {
  /// Derives a theme from [token], or from the defaults when omitted.
  ///
  /// Both [token] and [dark] are unset by default, and unset means *inherit*:
  /// a theme handed to a nested [ConfigProvider] takes the seed, the
  /// brightness, or both from the theme above it.
  ThemeData({
    SeedToken? token,
    bool? dark,
    this.components = const ComponentsConfig(),
  })  : _seed = token,
        _dark = dark,
        _readyMade = false,
        token = Token.derive(token ?? const SeedToken(), dark: dark ?? false);

  /// Wraps an already-derived token set.
  ///
  /// The token is taken as final: a theme built this way never re-derives
  /// itself from the theme above it, though its [components] still merge.
  const ThemeData.raw(this.token, {this.components = const ComponentsConfig()})
      : _seed = null,
        _dark = null,
        _readyMade = true;

  const ThemeData._merged({
    required this.token,
    required this.components,
    required SeedToken? seed,
    required bool? dark,
    required bool readyMade,
  })  : _seed = seed,
        _dark = dark,
        _readyMade = readyMade;

  /// The resolved values components read.
  final Token token;

  /// Per-component token overrides.
  final ComponentsConfig components;

  /// The seed this theme was derived from, or null when it was left to inherit
  /// (or handed over ready-made).
  final SeedToken? _seed;

  /// The brightness asked for, or null when it was left to inherit.
  final bool? _dark;

  /// Whether [token] was handed over already derived, by [ThemeData.raw].
  final bool _readyMade;

  /// The default light theme.
  static ThemeData get light => ThemeData(dark: false);

  /// The default dark theme.
  ///
  /// Stated brightness, inherited palette: nested inside a themed provider this
  /// turns the lights out without discarding the colours above it.
  static ThemeData get dark => ThemeData(dark: true);

  /// This theme laid over [parent] — the inheritance a nested [ConfigProvider]
  /// performs.
  ///
  /// The tokens come from whichever of the two actually spoke: a ready-made
  /// token wins outright, silence on both counts keeps the parent's tokens
  /// whole, and a half-stated theme is re-derived from the parent's other half.
  /// Components merge slot by slot, this theme winning where the two overlap.
  ThemeData _inherit(ThemeData parent) {
    final Token merged;
    if (_readyMade) {
      merged = token;
    } else if (_seed == null && _dark == null) {
      merged = parent.token;
    } else if (_seed == null && parent._seed != null) {
      // Only the brightness was flipped: keep the palette it was flipped on.
      merged = Token.derive(parent._seed, dark: _dark!);
    } else if (_dark == null) {
      // Only a palette was named: keep the brightness it lands in.
      merged = Token.derive(_seed!, dark: parent.token.isDark);
    } else {
      merged = token;
    }
    return ThemeData._merged(
      token: merged,
      components: parent.components.merge(components),
      seed: _seed ?? parent._seed,
      dark: _dark ?? parent._dark,
      readyMade: _readyMade,
    );
  }
}

/// Everything a [ConfigProvider] settles for the widgets below it, after
/// inheriting from the provider above.
@immutable
class _Config {
  const _Config({
    required this.theme,
    this.emptyBuilder,
    this.locale,
    this.componentSize,
    this.componentDisabled,
  });

  final ThemeData theme;
  final EmptyBuilder? emptyBuilder;
  final SeedLocalizations? locale;
  final SoftSize? componentSize;
  final bool? componentDisabled;
}

/// Carries the resolved [_Config] down the tree.
class _ConfigScope extends InheritedWidget {
  const _ConfigScope({required this.config, required super.child});

  final _Config config;

  // The config is rebuilt only when something it is made of changed, so
  // identity is the whole comparison — and a provider rebuilding for reasons
  // of its own does not wake every widget under it.
  @override
  bool updateShouldNotify(_ConfigScope old) => !identical(old.config, config);
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
///
/// Providers nest, and a nested one **inherits**: it changes what it names and
/// leaves the rest as the provider above it had it. So a screen that wants
/// rounder buttons says only that, and keeps the app's palette, its language
/// and its empty state:
///
/// ```dart
/// ConfigProvider(
///   theme: ThemeData(
///     components: ComponentsConfig(button: ButtonToken(borderRadius: 16)),
///   ),
///   child: ...,
/// )
/// ```
class ConfigProvider extends StatefulWidget {
  /// Creates a [ConfigProvider].
  const ConfigProvider({
    super.key,
    this.theme,
    this.emptyBuilder,
    this.systemOverlayStyle = true,
    this.locale,
    this.componentSize,
    this.componentDisabled,
    required this.child,
  });

  /// The theme for this subtree. Null inherits the one above unchanged.
  final ThemeData? theme;

  /// Global default for the "no data" placeholder.
  ///
  /// Called with the [EmptySlot] that wants one, so a single builder can serve
  /// the whole app and still answer differently for a dropdown and a list:
  ///
  /// ```dart
  /// emptyBuilder: (context, slot) => switch (slot) {
  ///   EmptySlot.select => const Text('Nothing matches'),
  ///   EmptySlot.listy => const Empty(description: Text('No records yet')),
  /// },
  /// ```
  ///
  /// Null inherits the one above; a per-component override (a [Select]'s
  /// `notFoundContent`, a [Listy]'s `emptyContent`) still wins over both.
  final EmptyBuilder? emptyBuilder;

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
  /// forking a whole language. Null inherits the words above.
  final SeedLocalizations? locale;

  /// The size every component below takes unless it names its own.
  ///
  /// One word for a whole screen: a dense table view sets `SoftSize.small` and
  /// every button, input and select in it follows. What a widget states for
  /// itself still wins. Null inherits the size above; nothing anywhere leaves
  /// each component on `SoftSize.middle`.
  final SoftSize? componentSize;

  /// Whether every control below is disabled unless it says otherwise.
  ///
  /// A form that goes read-only while it saves is one flag here rather than a
  /// `disabled:` threaded through every field. A widget that names its own
  /// still wins, so a control can stay live in a disabled subtree.
  ///
  /// Only controls follow it — the things a person operates. A per-item
  /// `disabled` (a [SelectOption], a [TreeNode], one [TabItem]) is about that
  /// item, not about the screen, and is left alone.
  final bool? componentDisabled;

  /// The subtree this configuration applies to.
  final Widget child;

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

  /// The nearest theme, falling back to the defaults when no provider is found.
  static ThemeData of(BuildContext context) => _configOf(context).theme;

  /// The nearest configured empty-state builder, or null when none is set.
  ///
  /// Most callers want [emptyFor], which falls back to the kit's own
  /// placeholder rather than handing back a null to deal with.
  static EmptyBuilder? emptyBuilderOf(BuildContext context) =>
      _configOf(context).emptyBuilder;

  /// The ambient size in scope, or null when nothing set one.
  ///
  /// Components resolve their own first:
  /// `widget.size ?? ConfigProvider.componentSizeOf(context) ?? SoftSize.middle`.
  static SoftSize? componentSizeOf(BuildContext context) =>
      _configOf(context).componentSize;

  /// Whether controls in scope are disabled from above, or null when nothing
  /// said either way.
  static bool? componentDisabledOf(BuildContext context) =>
      _configOf(context).componentDisabled;

  /// The placeholder [slot] should show when it has nothing.
  ///
  /// The configured [emptyBuilder] if there is one, and the kit's [Empty]
  /// otherwise — so a component never has to spell out that fallback itself.
  static Widget emptyFor(BuildContext context, EmptySlot slot) =>
      emptyBuilderOf(context)?.call(context, slot) ?? const Empty();

  /// The component token of type [T] in scope, or null when none is set.
  ///
  /// One lookup is enough however deep the providers nest: each of them has
  /// already merged what it inherited, so the nearest config carries a token
  /// set at the top of the app just as surely as one set next door.
  static T? componentOf<T>(BuildContext context) =>
      _configOf(context).theme.components.of<T>();

  /// The resolved configuration in scope, or the defaults.
  ///
  /// Reading it registers a dependency, so a widget follows the provider it
  /// read from.
  static _Config _configOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ConfigScope>()?.config ??
      _fallback;

  /// Components must render even when the app never installed a provider,
  /// so an unconfigured tree silently gets the default theme.
  static final _Config _fallback = _Config(theme: ThemeData());

  @override
  State<ConfigProvider> createState() => _ConfigProviderState();
}

class _ConfigProviderState extends State<ConfigProvider> {
  /// What this provider hands down — its own settings over its parent's.
  late _Config _config;

  /// The parent's config as of the last resolve, so a widget change can be
  /// merged again without asking the tree a second time.
  _Config? _parent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parent =
        context.dependOnInheritedWidgetOfExactType<_ConfigScope>()?.config;
    _resolve();
  }

  @override
  void didUpdateWidget(ConfigProvider old) {
    super.didUpdateWidget(old);
    if (!identical(old.theme, widget.theme) ||
        old.emptyBuilder != widget.emptyBuilder ||
        old.locale != widget.locale ||
        old.componentSize != widget.componentSize ||
        old.componentDisabled != widget.componentDisabled) {
      _resolve();
    }
  }

  void _resolve() {
    final parent = _parent;
    final theme = widget.theme;
    _config = _Config(
      theme: theme == null
          ? (parent?.theme ?? ConfigProvider._fallback.theme)
          : (parent == null ? theme : theme._inherit(parent.theme)),
      emptyBuilder: widget.emptyBuilder ?? parent?.emptyBuilder,
      locale: widget.locale ?? parent?.locale,
      componentSize: widget.componentSize ?? parent?.componentSize,
      componentDisabled: widget.componentDisabled ?? parent?.componentDisabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    var child = widget.child;
    if (widget.systemOverlayStyle) {
      // Declared rather than pushed through `SystemChrome`, so the style
      // belongs to this subtree instead of mutating global state that
      // whatever else is on screen would have to fight.
      child = AnnotatedRegion<SystemUiOverlayStyle>(
        value: ConfigProvider._overlayStyleFor(_config.theme.token.isDark),
        child: child,
      );
    }
    return _ConfigScope(config: _config, child: child);
  }
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
  /// The nearest [ConfigProvider.locale] wins — inherited from further up when
  /// the nearer providers were silent — then whatever
  /// `SeedLocalizations.delegate` resolved from the app's locale, then English.
  SeedLocalizations get seedLocale =>
      ConfigProvider._configOf(this).locale ?? SeedLocalizations.of(this);
}
