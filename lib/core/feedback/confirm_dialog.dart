import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';

/// Asks before doing something that can't be taken back. Resolves to true only
/// on an explicit confirmation.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  IconData icon = Icons.help_outline_rounded,
  bool destructive = false,
}) async {
  final accent = destructive ? AppColors.danger : AppColors.accentGlow;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(icon, color: accent, size: 32),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: accent.withValues(alpha: 0.22),
            foregroundColor: accent,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
