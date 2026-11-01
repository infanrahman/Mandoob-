import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary (Vyapar-Style Deep Professional Navy & Royal Blue)
  static const Color primary = Color(0xFF1E3A8A); // Deep Navy Blue
  static const Color primaryLight = Color(0xFF3B82F6); // Blue
  static const Color primaryDark = Color(0xFF0F172A); // Dark Slate

  // Secondary Accents
  static const Color secondary = Color(0xFF0D9488); // Teal
  static const Color accent = Color(0xFFF59E0B); // Amber / Warning

  // Transaction Indicators
  static const Color saleGreen = Color(0xFF10B981); // Emerald Green for Inflow / Sales
  static const Color purchaseBlue = Color(0xFF2563EB); // Royal Blue for Purchases
  static const Color expenseRed = Color(0xFFEF4444); // Crimson for Outflow / Expenses
  static const Color warningOrange = Color(0xFFF97316); // Orange for Low Stock / Expiring

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status Badges
  static const Color badgePaidBg = Color(0xFFDCFCE7);
  static const Color badgePaidText = Color(0xFF15803D);
  static const Color badgeUnpaidBg = Color(0xFFFEE2E2);
  static const Color badgeUnpaidText = Color(0xFFB91C1C);
  static const Color badgePartialBg = Color(0xFFFEF3C7);
  static const Color badgePartialText = Color(0xFFB45309);
}
