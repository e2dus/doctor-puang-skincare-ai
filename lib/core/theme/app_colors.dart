/// ============================================================================
/// APP COLORS
/// ============================================================================
/// 
/// Centralized color palette for the application.
/// 
/// ## Usage
/// ```dart
/// Container(
///   color: AppColors.primary,
///   child: Text('Hello', style: TextStyle(color: AppColors.textPrimary)),
/// )
/// ```
/// 
/// ## Color Categories
/// - Brand colors: primary, secondary, accent
/// - Background colors: background, surface
/// - Text colors: textPrimary, textSecondary
/// - Utility colors: error, success, warning
/// - Dark theme variants: darkBackground, darkSurface, etc.
/// ============================================================================

import 'package:flutter/material.dart';

class AppColors {
  // Private constructor prevents instantiation
  AppColors._();

  // === Brand Colors ===
  
  /// Primary brand color (blue)
  static const Color primary = Color(0xFF2B7BE4);
  
  /// Soft primary for backgrounds
  static const Color primarySoft = Color(0xFFE6F0FF);
  
  /// Secondary color (alias for primarySoft)
  static const Color secondary = primarySoft;
  
  /// Accent color (green)
  static const Color accent = Color(0xFF00C48C);

  // === Background Colors ===
  
  /// Main background (light gray)
  static const Color background = Color(0xFFF7F8FA);
  
  /// Card/surface background (white)
  static const Color surface = Colors.white;

  // === Dark Theme Colors ===
  
  /// Dark theme background
  static const Color darkBackground = Color(0xFF121212);
  
  /// Dark theme surface
  static const Color darkSurface = Color(0xFF1E1E1E);
  
  /// Dark theme primary
  static const Color darkPrimary = Color(0xFFB68AF2);
  
  /// Dark theme secondary
  static const Color darkSecondary = Color(0xFF7451B6);

  // === Text Colors ===
  
  /// Primary text (dark)
  static const Color textPrimary = Color(0xFF222222);
  
  /// Secondary text (muted)
  static const Color textSecondary = Color(0xFF161616);
  
  /// Link/emphasis text (blue)
  static const Color textBlue = primary;

  // === Utility Colors ===
  
  /// Divider lines
  static const Color divider = Color(0xFFE5E7EB);
  
  /// Error state (red)
  static const Color error = Color(0xFFE53935);
  
  /// Success state (green)
  static const Color success = Color(0xFF4CAF50);
  
  /// Warning state (orange)
  static const Color warning = Color(0xFFFF9800);
  
  /// Shadow color (10% black)
  static const Color shadow = Color(0x1A000000);
}
