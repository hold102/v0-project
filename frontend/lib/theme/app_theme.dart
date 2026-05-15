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

/// Glassmorphism palette and gradient.
class GlassColors {
  const GlassColors._();

  // Background gradient — defined once, referenced everywhere.
  static const List<Color> bgColors = [
    Color(0xFF0F0C29),
    Color(0xFF302B63),
    Color(0xFF24243E),
  ];
  static const bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: bgColors,
    stops: [0.0, 0.5, 1.0],
  );

  // Glass surface — card background and border.
  static const surface = Color(0x1AFFFFFF);      // 10% white — list tiles
  static const surfaceHeavy = Color(0x26FFFFFF); // 15% white — featured cards
  static const border = Color(0x33FFFFFF);        // 20% white

  // Text on dark gradient.
  static const text = Colors.white;
  static const textMuted = Color(0x99FFFFFF); // 60% white

  // Semantic accents that read well on dark.
  static const positive = Color(0xFF34D399); // emerald green
  static const negative = Color(0xFFFF6B8A); // coral red
  static const settled = Color(0xFF34D399);
}
