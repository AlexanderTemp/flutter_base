import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

// Instancias únicas: AppFlowyThemeData no implementa ==, así que crear una nueva
// en cada build notifica a todos los dependientes de AppFlowyTheme.
final _appFlowyLight = AppFlowyDefaultTheme().light();
final _appFlowyDark = AppFlowyDefaultTheme().dark();

/// Tokens AppFlowy del brillo indicado, siempre la misma instancia.
AppFlowyThemeData appFlowyTheme(Brightness brightness) =>
    brightness == Brightness.dark ? _appFlowyDark : _appFlowyLight;

// ColorScheme.fromSeed calcula paletas tonales; se construye una vez por brillo.
final workspaceLightTheme = _workspaceTheme(Brightness.light);
final workspaceDarkTheme = _workspaceTheme(Brightness.dark);

ThemeData _workspaceTheme(Brightness brightness) {
  final tokens = appFlowyTheme(brightness);
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: tokens.backgroundColorScheme.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: tokens.fillColorScheme.themeThick,
      brightness: brightness,
      primary: tokens.fillColorScheme.themeThick,
      onPrimary: tokens.textColorScheme.onFill,
      surface: tokens.surfaceColorScheme.primary,
      onSurface: tokens.textColorScheme.primary,
      error: tokens.fillColorScheme.errorThick,
      onError: tokens.textColorScheme.onFill,
    ),
    textTheme: TextTheme(
      bodyMedium:
          tokens.textStyle.body.standard(color: tokens.textColorScheme.primary),
      bodySmall: tokens.textStyle.caption
          .standard(color: tokens.textColorScheme.secondary),
    ),
    dividerColor: tokens.borderColorScheme.primary,
    inputDecorationTheme: const InputDecorationTheme(filled: false),
    splashFactory: NoSplash.splashFactory,
  );
}
