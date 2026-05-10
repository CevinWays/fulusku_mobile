import 'package:flutter/material.dart';

/// Palette warna fulusku.
abstract class AppColors {
  // Brand
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF8B85FF);
  static const primaryDark = Color(0xFF4F46E5);

  // Semantic
  static const secondary = Color(0xFF00C896); // income / positive
  static const danger = Color(0xFFFF6B6B); // expense / negative
  static const warning = Color(0xFFFFB347); // near-limit budget
  static const info = Color(0xFF3498DB); // transfer

  // Surface
  static const background = Color(0xFFF8F9FE);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8E8F0);

  // Text
  static const textPrimary = Color(0xFF1A1A2E);
  static const textMuted = Color(0xFF9090B0);

  // Aliases (untuk readability di feature code)
  static const income = secondary;
  static const expense = danger;
  static const transfer = info;

  /// Helper: parse hex string `#RRGGBB` (dari kolom DB) ke Color.
  /// Fallback ke abu-abu jika invalid.
  static Color fromHex(String? hex) {
    if (hex == null || hex.isEmpty) return textMuted;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return textMuted;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return textMuted;
    return Color(0xFF000000 | value);
  }
}
