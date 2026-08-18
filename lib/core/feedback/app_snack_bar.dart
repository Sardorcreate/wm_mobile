import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';

enum SnackKind { info, success, warning, error }

/// Typed, icon-led snackbars.
///
/// Replaces the old `HelperFunctions.showSnackBar(msg, color, context)`, where
/// every call site picked its own colour — the same failure showed up orange in
/// one screen and red in another.
abstract final class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    SnackKind kind = SnackKind.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final (Color accent, IconData icon) = switch (kind) {
      SnackKind.info => (AppColors.accentGlow, Icons.info_rounded),
      SnackKind.success => (AppColors.success, Icons.check_circle_rounded),
      SnackKind.warning => (AppColors.warning, Icons.warning_rounded),
      SnackKind.error => (AppColors.danger, Icons.error_rounded),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.abyss,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: accent.withValues(alpha: 0.55)),
          ),
          content: Row(
            children: [
              Icon(icon, color: accent, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, kind: SnackKind.success);

  static void warning(BuildContext context, String message) =>
      show(context, message, kind: SnackKind.warning);

  static void error(BuildContext context, String message) =>
      show(context, message, kind: SnackKind.error);
}
