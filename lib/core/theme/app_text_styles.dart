/// ============================================================================
/// APP TEXT STYLES
/// ============================================================================
/// 
/// Centralized text styles for consistent typography.
/// 
/// ## Usage
/// ```dart
/// Text('Title', style: AppTextStyles.titleLarge)
/// Text('Body', style: AppTextStyles.body)
/// 
/// // With modifications:
/// Text('Custom', style: AppTextStyles.body.copyWith(color: Colors.red))
/// ```
/// 
/// ## Style Hierarchy
/// - titleLarge (26px): Page titles
/// - titleMedium (20px): Section titles
/// - titleSmall (16px): Card titles
/// - body (14px): Regular content
/// - bodySecondary (14px): Muted content
/// - caption (12px): Small labels
/// - button (15px): Button text
/// ============================================================================

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Private constructor prevents instantiation
  AppTextStyles._();

  /// Default font family
  static const String fontFamily = 'HelveticaNeue';

  // === Title Styles ===

  /// Large title for page headers
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Medium title for sections
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  /// Small title for cards
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // === Body Styles ===

  /// Regular body text
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Secondary/muted body text
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // === Utility Styles ===

  /// Small caption text
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Button text
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
