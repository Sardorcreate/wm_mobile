import 'package:flutter/material.dart';

/// The app palette. The three blues are the established brand ramp and must not
/// change — everything else is derived from or layered on top of them.
abstract final class AppColors {
  // ── Brand ramp (unchanged) ────────────────────────────────────────────────
  static const Color indigo = Color(0xFF1A237E);
  static const Color blue = Color(0xFF0D47A1);
  static const Color azure = Color(0xFF01579B);

  /// Deepest shade, used for scrims and the bottom of long gradients.
  static const Color abyss = Color(0xFF11185C);

  // ── Accents (highlights only — never a surface fill) ──────────────────────
  static const Color accent = Color(0xFF4FC3F7);
  static const Color accentGlow = Color(0xFF80D8FF);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2ECC71);
  static const Color danger = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFB74D);

  // ── Frosted-surface helpers ───────────────────────────────────────────────
  /// Translucent white, the base of every glass surface in the app.
  static Color glass(double opacity) => Colors.white.withValues(alpha: opacity);

  static Color get glassBorder => Colors.white.withValues(alpha: 0.18);
  static Color get glassBorderStrong => Colors.white.withValues(alpha: 0.30);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static Color get textSecondary => Colors.white.withValues(alpha: 0.72);
  static Color get textTertiary => Colors.white.withValues(alpha: 0.52);
}
