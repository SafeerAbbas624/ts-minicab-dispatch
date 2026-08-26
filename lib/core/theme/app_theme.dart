import 'package:flutter/material.dart';

/// Shared rounded-corner language applied across both themes below — bigger
/// radii than Material 3's own defaults so cards/buttons/chips/inputs read
/// as more deliberately designed than the stock look, on both the driver
/// and admin panels (and the web build, which shares this same theme).
const _cardRadius = 16.0;
const _buttonRadius = 14.0;
const _inputRadius = 12.0;

RoundedRectangleBorder _buttonShape() =>
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius));

const _buttonPadding = EdgeInsets.symmetric(vertical: 14, horizontal: 24);

class AppTheme {
  static ThemeData light = _apply(ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B5FFF)),
    appBarTheme: const AppBarTheme(centerTitle: false),
  ));

  static ThemeData dark = _apply(ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B5FFF),
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(centerTitle: false),
  ));

  static ThemeData _apply(ThemeData base) {
    return base.copyWith(
      cardTheme: base.cardTheme.copyWith(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: _buttonShape(), padding: _buttonPadding),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: _buttonShape(), padding: _buttonPadding),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: _buttonShape(), padding: _buttonPadding),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(_inputRadius)),
      ),
    );
  }
}
