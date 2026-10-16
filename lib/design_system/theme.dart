import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

ThemeData workspaceTheme(Brightness brightness) {
  final builder = AppFlowyDefaultTheme();
  final tokens =
      brightness == Brightness.light ? builder.light() : builder.dark();
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
