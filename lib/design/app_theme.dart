import 'package:flutter/material.dart';
import 'package:mobileprogramming_groupproject_2025/core/theme/app_colors.dart';
import 'package:mobileprogramming_groupproject_2025/core/theme/app_text_styles.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: false,
  scaffoldBackgroundColor: AppColors.background,
  fontFamily: AppTextStyles.fontFamily,

  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.accent,
    onSecondary: Colors.white,
    error: AppColors.error,
    onError: Colors.white,
    background: AppColors.background,
    onBackground: AppColors.textPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
  ),

  textTheme: const TextTheme(
    headlineLarge: AppTextStyles.titleLarge,
    headlineMedium: AppTextStyles.titleMedium,
    headlineSmall: AppTextStyles.titleSmall,
    bodyLarge: AppTextStyles.body,
    bodyMedium: AppTextStyles.bodySecondary,
    bodySmall: AppTextStyles.caption,
    labelLarge: AppTextStyles.button,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: Colors.black,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: 'HelveticaNeue93',
      fontWeight: FontWeight.w900,
      color: Colors.black,
      fontSize: 20,
    ),
  ),

  dividerColor: AppColors.divider,

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
  ),
);
