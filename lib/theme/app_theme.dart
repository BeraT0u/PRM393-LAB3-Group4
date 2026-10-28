import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimens.dart';

class AppTheme {
  static ThemeData get warmPaperTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryBlue,
      onPrimary: AppColors.onPrimaryWhite,
      primaryContainer: AppColors.primaryBlueTonal,
      onPrimaryContainer: AppColors.primaryBluePressed,
      secondary: Color(0xFF855300),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFEF3C7),
      onSecondaryContainer: Color(0xFF78350F),
      error: AppColors.dangerBorder,
      onError: Colors.white,
      errorContainer: AppColors.dangerSurface,
      onErrorContainer: AppColors.dangerText,
      surface: AppColors.canvasBg,
      onSurface: AppColors.textPrimary,
      surfaceContainer: AppColors.surfaceCard,
      surfaceContainerLowest: AppColors.surfaceLowest,
      outlineVariant: AppColors.borderStructural,
      outline: Color(0xFF737686),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvasBg,
      textTheme: appTextTheme,
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceCard,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: appTextTheme.headlineMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderStructural, width: 1.0),
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.borderStructural, width: 1.0),
        ),
      ),

      // FilledButton
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.onPrimaryWhite,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          textStyle: appTextTheme.labelLarge,
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: AppColors.borderStructural, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          textStyle: appTextTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: appTextTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.borderStructural, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.borderStructural, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.dangerBorder, width: 1.5),
        ),
      ),

      // NavigationBar (Bottom Bar)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceCard,
        indicatorColor: AppColors.primaryBlueTonal,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return appTextTheme.labelMedium?.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            );
          }
          return appTextTheme.labelMedium?.copyWith(color: AppColors.textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryBlue);
          }
          return const IconThemeData(color: AppColors.textSecondary);
        }),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.borderStructural, width: 1.0),
        ),
        titleTextStyle: appTextTheme.headlineMedium?.copyWith(fontSize: 18),
        contentTextStyle: appTextTheme.bodyMedium,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.borderStructural,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }
}
