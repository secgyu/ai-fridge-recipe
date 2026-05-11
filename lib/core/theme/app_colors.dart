import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Brand
  static const Color primary = Color(0xFFFF5A1F);
  static const Color primarySoft = Color(0xFFFFE9DF);

  // Surface
  static const Color background = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF9FAFB);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Line
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderStrong = Color(0xFFD1D5DB);
  /// 리스트 내부 구분선용. border보다 옅음.
  static const Color divider = Color(0xFFF2F4F6);

  // Status
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);

  // Effects
  static const Color shadow = Color(0x14000000); // 8% black
}
