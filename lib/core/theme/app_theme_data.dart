import 'package:flutter/material.dart';

enum PawTheme {
  forest,
  ocean,
  blossom,
  amber,
  midnight,
  lavender,
}

class PawThemeData {
  final PawTheme id;
  final String name;
  final String emoji;
  final Color primary;
  final Color primaryLight;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textMuted;
  final Brightness brightness;

  const PawThemeData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primary,
    required this.primaryLight,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textMuted,
    this.brightness = Brightness.light,
  });

  static const alertAmber = Color(0xFFE8A838);
  static const alertRed = Color(0xFFD95F52);
  static const successGreen = Color(0xFF4CAF82);

  static const all = <PawTheme, PawThemeData>{
    PawTheme.forest: PawThemeData(
      id: PawTheme.forest,
      name: 'Forest',
      emoji: '🌿',
      primary: Color(0xFF3D7A5F),
      primaryLight: Color(0xFFA8C5B5),
      background: Color(0xFFFAF6F1),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF1E2D2B),
      textMuted: Color(0xFF8A9A96),
    ),
    PawTheme.ocean: PawThemeData(
      id: PawTheme.ocean,
      name: 'Ocean',
      emoji: '🌊',
      primary: Color(0xFF2B6CB0),
      primaryLight: Color(0xFFBEE3F8),
      background: Color(0xFFF0F7FF),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF1A2F45),
      textMuted: Color(0xFF718096),
    ),
    PawTheme.blossom: PawThemeData(
      id: PawTheme.blossom,
      name: 'Blossom',
      emoji: '🌸',
      primary: Color(0xFFB85C84),
      primaryLight: Color(0xFFF5C6DA),
      background: Color(0xFFFFF7F9),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF3D1A26),
      textMuted: Color(0xFFA07080),
    ),
    PawTheme.amber: PawThemeData(
      id: PawTheme.amber,
      name: 'Amber',
      emoji: '🍊',
      primary: Color(0xFFC2680A),
      primaryLight: Color(0xFFFDDCAB),
      background: Color(0xFFFFFBF4),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF2D1A05),
      textMuted: Color(0xFF9A7850),
    ),
    PawTheme.midnight: PawThemeData(
      id: PawTheme.midnight,
      name: 'Midnight',
      emoji: '🌙',
      primary: Color(0xFF4CAF82),
      primaryLight: Color(0xFF1E4D38),
      background: Color(0xFF0F1612),
      surface: Color(0xFF1C2820),
      textPrimary: Color(0xFFE8F5EE),
      textMuted: Color(0xFF6B8C7A),
      brightness: Brightness.dark,
    ),
    PawTheme.lavender: PawThemeData(
      id: PawTheme.lavender,
      name: 'Lavender',
      emoji: '🪻',
      primary: Color(0xFF6B5EA8),
      primaryLight: Color(0xFFD6CEFF),
      background: Color(0xFFF8F6FF),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF1F1640),
      textMuted: Color(0xFF8878B5),
    ),
  };
}
