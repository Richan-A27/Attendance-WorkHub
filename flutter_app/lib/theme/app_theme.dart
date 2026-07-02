import 'package:flutter/material.dart';

class AppTheme {
  static const Color creamBackground = Color(0xFFF7F3EA);
  static const Color softWhite = Color(0xFFFFFCF7);
  static const Color darkGreenSidebar = Color(0xFF10281E);
  static const Color primaryGreen = Color(0xFF1E563B);
  static const Color emerald = Color(0xFF2C7651);
  static const Color sage = Color(0xFFDCE5D7);
  static const Color olive = Color(0xFF728C53);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color goldAccent = accentGold;
  static const Color surfaceWhite = Colors.white;
  static const Color mist = Color(0xFFE7E2D7);
  static const Color ink = Color(0xFF233228);
  static const Color mutedText = Color(0xFF6B756D);

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x120E1B14),
      blurRadius: 28,
      offset: Offset(0, 14),
    ),
  ];

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
        surface: softWhite,
        primary: primaryGreen,
        secondary: accentGold,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base.colorScheme.copyWith(
        surface: softWhite,
        surfaceContainerHighest: const Color(0xFFF0EBE1),
        onSurface: ink,
      ),
      scaffoldBackgroundColor: creamBackground,
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          color: ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          color: ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: ink,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: ink,
          height: 1.45,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: mutedText,
          height: 1.45,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: creamBackground,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
      dividerColor: mist,
      cardTheme: CardThemeData(
        color: softWhite,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE8E0D0)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          side: const BorderSide(color: Color(0xFFDDD4C2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF6F0E4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: const TextStyle(color: Color(0xFF93A093)),
        labelStyle: const TextStyle(color: mutedText),
        prefixIconColor: mutedText,
        suffixIconColor: mutedText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE1D7C5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE1D7C5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryGreen, width: 1.4),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: softWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1ECDF),
        selectedColor: sage,
        disabledColor: mist,
        labelStyle: const TextStyle(
          color: ink,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: Color(0xFFE3D9C8)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: softWhite,
        indicatorColor: sage,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: primaryGreen,
        surface: const Color(0xFF1E1E1E),
        primary: primaryGreen,
        secondary: accentGold,
      ),
    );
  }
}
