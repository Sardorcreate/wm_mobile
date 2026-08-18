import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Every gradient in the app lives here so the brand ramp stays consistent.
abstract final class AppGradients {
  /// Primary app background — diagonal so the ramp reads across the whole
  /// screen instead of banding horizontally.
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.indigo, AppColors.blue, AppColors.azure],
    stops: [0.0, 0.55, 1.0],
  );

  /// Same ramp, vertical. Used where the screen is tall and narrow.
  static const LinearGradient backgroundVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.indigo, AppColors.blue, AppColors.azure],
    stops: [0.0, 0.5, 1.0],
  );

  /// Bottom navigation bar — darker than the body so it reads as a plinth.
  static const LinearGradient navBar = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0E3E8A), AppColors.abyss],
  );

  /// Frosted card fill. Pairs with a `BackdropFilter` blur.
  static LinearGradient get glass => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.glass(0.18), AppColors.glass(0.06)],
  );

  /// Highlight sweep for selected states and accent chips.
  static LinearGradient get accentSheen => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentGlow, AppColors.accent],
  );

  /// Light-to-transparent sweep used by the shimmer on the primary button.
  static LinearGradient shimmer(double t) => LinearGradient(
    begin: Alignment(-1.6 + t * 3.2, -0.3),
    end: Alignment(-1.0 + t * 3.2, 0.3),
    colors: [Colors.transparent, AppColors.glass(0.55), Colors.transparent],
  );

  /// Bottom scrim so content never collides with the nav bar.
  static LinearGradient get bottomScrim => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, AppColors.abyss.withValues(alpha: 0.55)],
  );
}
