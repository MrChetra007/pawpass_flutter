import 'package:flutter/material.dart';
import 'app_theme_data.dart';

class AppThemeBuilder {
  static ThemeData build(PawThemeData t) {
    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      colorScheme: ColorScheme(
        brightness: t.brightness,
        primary: t.primary,
        onPrimary: Colors.white,
        secondary: t.primaryLight,
        onSecondary: t.textPrimary,
        surface: t.surface,
        onSurface: t.textPrimary,
        error: PawThemeData.alertRed,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: t.background,
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: t.background,
        foregroundColor: t.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 22,
          color: t.textPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: t.surface,
        selectedItemColor: t.primary,
        unselectedItemColor: t.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.primaryLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.primaryLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: t.primary, width: 2),
        ),
        hintStyle: TextStyle(
          color: t.textMuted,
          fontFamily: 'PlusJakartaSans',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.primary,
          side: BorderSide(color: t.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.primary,
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      fontFamily: 'PlusJakartaSans',
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 40,
          color: t.textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 32,
          color: t.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 28,
          color: t.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 22,
          color: t.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: t.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: t.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 15,
          color: t.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 14,
          color: t.textPrimary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: t.textMuted,
        ),
        labelMedium: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w500,
          fontSize: 11,
          color: t.textMuted,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: t.primaryLight.withValues(alpha: 0.3),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.primaryLight.withValues(alpha: 0.3),
        labelStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 13,
          color: t.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}

extension ThemeExtensions on BuildContext {
  PawThemeData get theme => Theme.of(this).brightness == Brightness.dark
      ? PawThemeData.all[PawTheme.midnight]!
      : PawThemeData.all[PawTheme.forest]!;

  Color get primary => Theme.of(this).colorScheme.primary;
  Color get primaryLight => Theme.of(this).colorScheme.secondary;
  Color get background => Theme.of(this).scaffoldBackgroundColor;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get textPrimary => Theme.of(this).colorScheme.onSurface;
  Color get textMuted => Theme.of(this).textTheme.labelLarge?.color ?? Colors.grey;
}
