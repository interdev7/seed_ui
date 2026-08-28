import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';

import 'config_provider.dart';
import 'design_token.dart';

/// Hands Material a theme that matches the kit's.
///
/// The kit's theme is not Material's, and the two do not find each other on
/// their own. Anything Material still draws for you keeps reading
/// `MaterialApp.theme` — and the loudest of those is the page transition,
/// which paints its backdrop with `colorScheme.surface`. Left unset that is
/// Material's light default, so under a dark kit theme every navigation
/// flashes white before the page arrives.
extension MaterialThemeFromToken on Token {
  /// A Material theme painted in these tokens.
  ///
  /// It is a bridge for Material's own chrome — transitions, scaffolds, text
  /// selection — not a port of the kit's design language. Components draw
  /// themselves from the tokens directly and pay it no attention.
  ///
  /// ```dart
  /// final kit = ThemeData(dark: isDark);
  ///
  /// ConfigProvider(
  ///   theme: kit,
  ///   child: MaterialApp(theme: kit.materialTheme, home: const Home()),
  /// )
  /// ```
  material.ThemeData get materialTheme {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final base = isDark
        ? const material.ColorScheme.dark()
        : const material.ColorScheme.light();
    return material.ThemeData(
      brightness: brightness,
      colorScheme: base.copyWith(
        brightness: brightness,
        primary: primary.base,
        error: error.base,
        // The one that stops the flash: what a page transition paints behind
        // the page it is revealing.
        surface: colorBgLayout,
        onSurface: colorText,
      ),
      // Material derives the scaffold and canvas backgrounds from the
      // surface above, so naming them again here would be two statements of
      // one fact. The divider it does not derive.
      dividerColor: colorSplit,
    );
  }
}

/// Hands Material a theme that matches this one.
extension MaterialThemeFromThemeData on ThemeData {
  /// A Material theme painted in this theme's tokens.
  ///
  /// The same value as `token.materialTheme`, reached without a
  /// [BuildContext] — which is what lets it be named beside the very
  /// `ConfigProvider` it belongs to, with no [Builder] in between.
  ///
  /// A theme that leaves its brightness to inherit does not know it yet, so
  /// read this from the theme you actually hand to the top-level provider.
  material.ThemeData get materialTheme => token.materialTheme;
}
