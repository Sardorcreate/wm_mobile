import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/widgets/entrance.dart';
import 'package:wm_mobile/core/widgets/glass_card.dart';
import 'package:wm_mobile/core/widgets/gradient_button.dart';

/// Camera-permission prompt.
///
/// Used to render with the default Material theme — a light-grey icon and body
/// text over the blue gradient, which was close to invisible. It also spoke
/// English while the rest of the app is in Uzbek.
class PermissionRequestWidget extends StatelessWidget {
  const PermissionRequestWidget({
    super.key,
    required this.onRequestPermission,
    this.message,
    this.onOpenSettings,
  });

  final String? message;
  final VoidCallback onRequestPermission;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Entrance(
        child: GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 76,
                width: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.30),
                      AppColors.accent.withValues(alpha: 0.04),
                    ],
                  ),
                  border: Border.all(color: AppColors.glassBorderStrong),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 34,
                  color: AppColors.accentGlow,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Kameraga ruxsat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message ?? "Kameraga ruxsat so'ralmoqda…",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 26),
              GradientButton(
                label: 'Qayta urinish',
                icon: Icons.refresh_rounded,
                onPressed: onRequestPermission,
              ),
              if (onOpenSettings != null) ...[
                const SizedBox(height: 12),
                GradientButton(
                  label: 'Sozlamalarni ochish',
                  icon: Icons.settings_outlined,
                  variant: ButtonVariant.glass,
                  onPressed: onOpenSettings,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
