import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Application-wide Material 3 styles.
abstract final class AppTheme {
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _text = Color(0xFF0F172A);

  static const TextTheme _textTheme = TextTheme(
    headlineSmall: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: _text,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: _text,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: _text,
    ),
    bodyLarge: TextStyle(fontSize: 16, color: _text),
    bodyMedium: TextStyle(fontSize: 14, color: _text),
  );

  /// Light theme used by the application.
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
    ).copyWith(
      primary: AppConstants.primaryColor,
      surface: _surface,
      error: AppConstants.exportColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _surface,
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: _surface,
        foregroundColor: _text,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x140F172A),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}
