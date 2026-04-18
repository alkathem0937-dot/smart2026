import 'package:flutter/material.dart';

/// نظام التباعد والأبعاد الموحد
/// Consistent spacing, radii, and sizing for a polished UI
class AppSpacing {
  AppSpacing._();

  // ── Spacing scale ──────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // ── Border radii ───────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusFull = 999;

  // ── Card elevation ─────────────────────────────────────────
  static const double elevationNone = 0;
  static const double elevationSm = 2;
  static const double elevationMd = 4;
  static const double elevationLg = 8;
  static const double elevationXl = 16;

  // ── Icon sizes ─────────────────────────────────────────────
  static const double iconSm = 18;
  static const double iconMd = 22;
  static const double iconLg = 26;
  static const double iconXl = 32;

  // ── Button heights ─────────────────────────────────────────
  static const double buttonSm = 40;
  static const double buttonMd = 48;
  static const double buttonLg = 56;

  // ── Page padding ───────────────────────────────────────────
  static const EdgeInsets pagePadding = EdgeInsets.all(base);
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: base);
  static const EdgeInsets cardPadding = EdgeInsets.all(base);
  static const EdgeInsets cardPaddingSm = EdgeInsets.all(md);
}

/// نظام الظلال الحديث
/// Modern shadow system for depth and hierarchy
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get sm => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get md => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get lg => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get xl => [
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> colored(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.25),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get darkSm => [
    BoxShadow(
      color: Colors.black.withOpacity(0.20),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get darkMd => [
    BoxShadow(
      color: Colors.black.withOpacity(0.30),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
