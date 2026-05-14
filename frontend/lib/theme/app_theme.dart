/*
 * app_theme.dart — Named constants for colours, spacing, radii, and font sizes
 *
 * Centralising magic numbers here keeps styling consistent and makes
 * theme-wide changes a one-line edit instead of a grep-and-replace.
 */
import 'package:flutter/material.dart';

/// Semantic brand colours used throughout the app.
class AppColors {
  const AppColors._();

  /// Positive balance / "you are owed" / settlement confirmed.
  static const Color positiveBalance = Color(0xFF059669);

  /// Negative balance / "you owe" / danger state.
  static const Color negativeBalance = Color(0xFFE11D48);

  /// Neutral settlement-confirmed accent (used in the balances tab).
  static const Color settledGreen = Color(0xFF4CAF50);
}

/// Reusable border radii.
class AppRadius {
  const AppRadius._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 16;
  static const double xxl = 20;
  static const double card = 20;
  static const double pill = 24;
}

/// Spacing values (multiples of 4).
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 28;
  static const double pagePad = 20;
}

/// Font sizes used in the app.
class AppTextSize {
  const AppTextSize._();

  static const double caption = 11;
  static const double small = 12;
  static const double body = 13;
  static const double bodyMd = 14;
  static const double bodyLg = 15;
  static const double subtitle = 16;
  static const double title = 18;
  static const double heading = 20;
  static const double display = 24;
  static const double hero = 28;
  static const double amount = 32;
}

/// Reusable icon sizes.
class AppIconSize {
  const AppIconSize._();

  static const double sm = 15;
  static const double md = 18;
  static const double lg = 20;
  static const double xl = 22;
  static const double xxl = 24;
}

/// Shared avatar / icon container dimensions.
class AppAvatarSize {
  const AppAvatarSize._();

  static const double sm = 36;
  static const double md = 40;
  static const double lg = 48;
  static const double xl = 56;
}
