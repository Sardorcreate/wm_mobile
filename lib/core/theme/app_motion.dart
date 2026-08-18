import 'package:flutter/animation.dart';

/// Shared motion vocabulary. Durations and curves used to be re-invented per
/// widget (200ms here, 350ms there); pulling them together is what makes the
/// transitions feel like one app rather than several.
abstract final class AppMotion {
  // ── Durations ─────────────────────────────────────────────────────────────
  /// Micro-feedback: press states, icon swaps.
  static const Duration fast = Duration(milliseconds: 160);

  /// The default for anything the user directly triggered.
  static const Duration medium = Duration(milliseconds: 300);

  /// Page transitions and entrance animations.
  static const Duration slow = Duration(milliseconds: 460);

  /// Splash and other "hero" moments.
  static const Duration hero = Duration(milliseconds: 1100);

  /// Ambient loops (drifting orbs, scan line) — never blocks the user.
  static const Duration ambient = Duration(seconds: 12);

  // ── Curves ────────────────────────────────────────────────────────────────
  /// Material 3 emphasized-decelerate. Fast out of the gate, soft landing.
  static const Curve emphasized = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Emphasized-accelerate, for things leaving the screen.
  static const Curve exit = Cubic(0.3, 0.0, 0.8, 0.15);

  static const Curve standard = Curves.easeOutCubic;

  /// A gentle overshoot — enough to feel alive, not enough to feel bouncy.
  static const Curve overshoot = Cubic(0.2, 1.25, 0.4, 1.0);

  /// Base stagger between siblings in an entrance sequence.
  static const Duration stagger = Duration(milliseconds: 70);
}
