// hf_v3/lib/common/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Define custom colors as static constants for easy access throughout the app
  static const Color primaryBlue = Color(0xFFA7C7E7); // Azul Sereno
  static const Color accentGreen = Color(0xFFC8E6C9); // Verde Esperanza
  static const Color warmCream = Color(0xFFFFF8E1); // Crema Cálido
  static const Color accentPink = Color(0xFFF8BBD0); // Rosa Suave
  static const Color accentYellow = Color(0xFFFFF9C4); // Amarillo Sol Suave
  static const Color lightGrey = Color(0xFFB0BEC5); // Gris Claro
  static const Color darkText = Color(0xFF37474F); // Texto Principal
  static const Color secondaryText = Color(0xFF607D8B); // Texto Secundario

  // Getter for the light theme data
  static ThemeData get lightTheme {
    return ThemeData(
      // General colors
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        onPrimary: darkText,
        secondary: accentGreen, // Using accent green for secondary actions
        onSecondary: darkText,
        tertiary: accentPink, // Using accent pink as a tertiary color
        onTertiary: darkText,
        surface: warmCream, // Background color for surfaces like cards, dialogs
        onSurface: darkText, // Text color on surface
        error: Colors.red.shade700, // Standard error color
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: warmCream, // Default background for Scaffold
      // Typography - Using Material's default fonts but with custom colors
      // Note: Custom fonts like 'Inter' or 'Nunito Sans' would require
      // adding font files to assets and configuring in pubspec.yaml.
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: darkText),
        displayMedium: TextStyle(color: darkText),
        displaySmall: TextStyle(color: darkText),
        headlineLarge: TextStyle(color: darkText),
        headlineMedium: TextStyle(color: darkText),
        headlineSmall: TextStyle(color: darkText),
        titleLarge: TextStyle(color: darkText),
        titleMedium: TextStyle(color: darkText),
        titleSmall: TextStyle(color: darkText),
        bodyLarge: TextStyle(color: darkText),
        bodyMedium: TextStyle(color: darkText),
        bodySmall: TextStyle(color: secondaryText), // Secondary text color
        labelLarge: TextStyle(color: darkText),
        labelMedium: TextStyle(color: secondaryText),
        labelSmall: TextStyle(color: secondaryText),
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: darkText, // Color for icons and text on AppBar
        elevation: 0, // No shadow for a flatter look
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue, // Primary button color
          foregroundColor: darkText, // Text color on button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // Rounded corners
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          elevation: 2, // Subtle shadow
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryText, // Text button color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0), // Rounded corners
          ),
          textStyle: const TextStyle(fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // Input field theme (TextFormField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warmCream, // Background color for input fields
        labelStyle: const TextStyle(color: secondaryText),
        hintStyle: const TextStyle(color: lightGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12.0,
          ), // Rounded corners for input fields
          borderSide: const BorderSide(color: lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(
            color: primaryBlue,
            width: 2.0,
          ), // Highlight on focus
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: warmCream,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            12.0,
          ), // Rounded corners for cards
        ),
        shadowColor: lightGrey.withAlpha((255 * 0.5).round()), // Subtle shadow
      ),

      // Floating Action Button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentGreen, // Accent color for FAB
        foregroundColor: darkText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // More rounded
        ),
        elevation: 4,
      ),

      // Bottom Navigation Bar theme (placeholder for future implementation)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: warmCream, // Background color for the bar
        selectedItemColor: primaryBlue, // Color for selected icon/label
        unselectedItemColor: secondaryText, // Color for unselected icon/label
        type:
            BottomNavigationBarType.fixed, // Ensures labels are always visible
        elevation: 8, // Subtle shadow
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      // Example usage of accentYellow for a specific theme property
      indicatorColor: accentYellow,
    );
  }
}
