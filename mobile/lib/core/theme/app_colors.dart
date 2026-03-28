import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF1A1B2E);
  static const Color primaryLight = Color(0xFF22233A);
  static const Color surface = Color(0xFF242540);
  static const Color surfaceLight = Color(0xFF2E2F4A);
  static const Color surfaceBorder = Color(0xFF363754);

  static const Color accent = Color(0xFF00D09C);
  static const Color accentLight = Color(0xFF00E4AB);
  static const Color accentDark = Color(0xFF00B386);
  static const Color accentSubtle = Color(0x1A00D09C);

  static const Color expense = Color(0xFFFF6B6B);
  static const Color expenseLight = Color(0xFFFF8A8A);
  static const Color expenseDark = Color(0xFFE55555);
  static const Color expenseSubtle = Color(0x1AFF6B6B);

  static const Color warning = Color(0xFFFFBE0B);
  static const Color info = Color(0xFF5B8DEF);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8EA0);
  static const Color textTertiary = Color(0xFF5A5A6E);
  static const Color textDisabled = Color(0xFF4A4A5E);

  static const Color divider = Color(0xFF2A2B42);
  static const Color shimmerBase = Color(0xFF242540);
  static const Color shimmerHighlight = Color(0xFF2E2F4A);

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, Color(0xFF1E1F38)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFF00B8D4)],
  );

  static const LinearGradient expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [expense, Color(0xFFFF8E53)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1B2E), Color(0xFF141524)],
  );
}
