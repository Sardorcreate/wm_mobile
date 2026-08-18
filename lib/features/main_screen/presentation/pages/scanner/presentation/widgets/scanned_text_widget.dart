import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:wm_mobile/core/feedback/app_snack_bar.dart';
import 'package:wm_mobile/core/theme/app_colors.dart';

/// Shown when a scanned code is plain text rather than a browsable URL.
///
/// Copying was the obvious missing action: the dialog held the only copy of the
/// scanned value and offered no way to get it out.
class ScannedTextDialog extends StatelessWidget {
  const ScannedTextDialog({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.qr_code_2_rounded,
        color: AppColors.accentGlow,
        size: 34,
      ),
      title: const Text('Skanerlangan matn'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: SelectionArea(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.glass(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: SelectableText(
                text,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (!context.mounted) return;
            AppSnackBar.success(context, 'Nusxa olindi');
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Nusxa olish'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Yopish'),
        ),
      ],
    );
  }
}
