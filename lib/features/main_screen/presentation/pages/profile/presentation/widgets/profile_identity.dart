import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';

/// Avatar + username block at the top of the profile tab.
class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({super.key, this.login});

  final String? login;

  String get _initials {
    final name = login?.trim();
    if (name == null || name.isEmpty) return '?';
    return name.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 96,
          width: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.glass(0.28), AppColors.glass(0.08)],
            ),
            border: Border.all(color: AppColors.glassBorderStrong, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.18),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            _initials,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: AppMotion.medium,
          child: Text(
            login ?? 'Foydalanuvchi',
            key: ValueKey<String?>(login),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.45),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_rounded,
                size: 13,
                color: AppColors.success,
              ),
              SizedBox(width: 6),
              Text(
                'Faol sessiya',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
