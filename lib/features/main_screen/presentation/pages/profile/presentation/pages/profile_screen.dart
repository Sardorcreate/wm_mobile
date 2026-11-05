import 'package:flutter/material.dart';

import 'package:wm_mobile/core/navigation/app_routes.dart';
import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';
import 'package:wm_mobile/core/widgets/entrance.dart';
import 'package:wm_mobile/core/widgets/glass_card.dart';
import 'package:wm_mobile/core/widgets/gradient_button.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';
import 'package:wm_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/profile/presentation/widgets/password_form.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/profile/presentation/widgets/profile_identity.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _login;

  @override
  void initState() {
    super.initState();
    _loadLogin();
  }

  /// The screen used to show a hardcoded "Foydalanuvchi" label even though the
  /// username is already stored locally.
  Future<void> _loadLogin() async {
    final login = await AuthService.instance.getSavedLogin();
    if (mounted) setState(() => _login = login);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.logout_rounded,
          color: AppColors.danger,
          size: 32,
        ),
        title: const Text('Chiqishni tasdiqlang'),
        content: const Text(
          "Akkauntdan chiqmoqchimisiz? Qayta kirish uchun login va parol "
          "kerak bo'ladi.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger.withValues(alpha: 0.20),
              foregroundColor: AppColors.danger,
            ),
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await AuthService.instance.signOut();
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushAndRemoveUntil(appRoute<void>(const LoginPage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Entrance(child: ProfileIdentity(login: _login)),
        const SizedBox(height: 28),
        Entrance(
          delay: AppMotion.stagger * 2,
          child: const _SectionLabel(
            icon: Icons.lock_reset_rounded,
            text: "Parolni o'zgartirish",
          ),
        ),
        const SizedBox(height: 12),
        Entrance(
          delay: AppMotion.stagger * 3,
          child: const GlassCard(child: PasswordForm()),
        ),
        const SizedBox(height: 28),
        Entrance(
          delay: AppMotion.stagger * 4,
          child: GradientButton(
            label: 'Chiqish',
            icon: Icons.logout_rounded,
            variant: ButtonVariant.danger,
            onPressed: _confirmLogout,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accentGlow),
        const SizedBox(width: 9),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
