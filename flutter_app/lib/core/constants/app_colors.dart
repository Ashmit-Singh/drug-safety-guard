import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette — Medical green
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color secondary = Color(0xFFA5D6A7);
  static const Color secondaryDark = Color(0xFF81C784);

  // Severity colors
  static const Color warningMild = Color(0xFFFFF176);
  static const Color warningMildBg = Color(0xFFFFF9C4);
  static const Color warningModerate = Color(0xFFFF7043);
  static const Color warningModerateBg = Color(0xFFFFE0B2);
  static const Color warningSevere = Color(0xFFD32F2F);
  static const Color warningSevereBg = Color(0xFFFFCDD2);
  static const Color warningContraindicated = Color(0xFF880E4F);
  static const Color warningContraindicatedBg = Color(0xFFF8BBD0);

  // Alert status
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFFF7043);
  static const Color danger = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);

  // Backgrounds
  static const Color background = Color(0xFFF6F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
  );

  // Severity color getter
  static Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'contraindicated':
        return warningContraindicated;
      case 'severe':
        return warningSevere;
      case 'moderate':
        return warningModerate;
      case 'mild':
        return const Color(0xFFF9A825);
      default:
        return textSecondary;
    }
  }

  static Color severityBgColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'contraindicated':
        return warningContraindicatedBg;
      case 'severe':
        return warningSevereBg;
      case 'moderate':
        return warningModerateBg;
      case 'mild':
        return warningMildBg;
      default:
        return background;
    }
  }
}
