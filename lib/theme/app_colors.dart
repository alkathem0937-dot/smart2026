import 'package:flutter/material.dart';

/// نظام الألوان الاحترافي - SmartJudi 2025+
/// Premium Color System with carefully curated palettes for Light & Dark modes
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════
  // Brand Identity Colors
  // ═══════════════════════════════════════════════════════════
  static const Color brand = Color(0xFF1B5E3B);         // Deep Emerald
  static const Color brandLight = Color(0xFF2D8B57);     // Emerald
  static const Color brandDark = Color(0xFF0D3B23);      // Darkest Emerald
  static const Color gold = Color(0xFFD4A940);           // Royal Gold
  static const Color goldLight = Color(0xFFE8C667);      // Light Gold
  static const Color goldDark = Color(0xFFB08C2A);       // Deep Gold
  static const Color primary = brand;                    // Alias for backward compatibility

  // ═══════════════════════════════════════════════════════════
  // Light Mode Palette
  // ═══════════════════════════════════════════════════════════
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F2F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF5F7FA);
  static const Color lightDivider = Color(0xFFE8ECF0);
  static const Color lightTextPrimary = Color(0xFF1A2138);
  static const Color lightTextSecondary = Color(0xFF5A6478);
  static const Color lightTextTertiary = Color(0xFF8E95A6);
  static const Color lightIcon = Color(0xFF5A6478);
  static const Color lightBorder = Color(0xFFDDE1E8);
  static const Color lightShadow = Color(0x0A000000);

  // ═══════════════════════════════════════════════════════════
  // Dark Mode Palette
  // ═══════════════════════════════════════════════════════════
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF1A1D27);
  static const Color darkSurfaceVariant = Color(0xFF242837);
  static const Color darkCard = Color(0xFF1E2130);
  static const Color darkCardHover = Color(0xFF262A3A);
  static const Color darkDivider = Color(0xFF2D3245);
  static const Color darkTextPrimary = Color(0xFFF0F1F5);
  static const Color darkTextSecondary = Color(0xFFB0B6C5);
  static const Color darkTextTertiary = Color(0xFF6B7280);
  static const Color darkIcon = Color(0xFF9CA3B0);
  static const Color darkBorder = Color(0xFF2D3245);
  static const Color darkShadow = Color(0x40000000);

  // ═══════════════════════════════════════════════════════════
  // Semantic / Status Colors
  // ═══════════════════════════════════════════════════════════
  static const Color success = Color(0xFF22C55E);
  static const Color successBg = Color(0x1A22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0x1AF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0x1AEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0x1A3B82F6);

  // ═══════════════════════════════════════════════════════════
  // Service Card Colors (Vibrant, modern palette)
  // ═══════════════════════════════════════════════════════════
  static const Color coral = Color(0xFFF43F5E);
  static const Color ocean = Color(0xFF0EA5E9);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color teal = Color(0xFF14B8A6);
  static const Color rose = Color(0xFFEC4899);
  static const Color indigo = Color(0xFF6366F1);
  static const Color emerald = Color(0xFF10B981);

  // ═══════════════════════════════════════════════════════════
  // Gradients
  // ═══════════════════════════════════════════════════════════
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand, Color(0xFF236B45)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandDark, brand, Color(0xFF1E7A4D)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1628), Color(0xFF142240), Color(0xFF1A2D50)],
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient shimmerGradient(bool isDark) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark
        ? [darkCard, darkSurfaceVariant, darkCard]
        : [lightCard, lightSurfaceVariant, lightCard],
  );
}
