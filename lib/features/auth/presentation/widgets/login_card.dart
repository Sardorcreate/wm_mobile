import 'package:flutter/material.dart';

import 'package:wm_mobile/core/feedback/app_snack_bar.dart';
import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/widgets/app_text_field.dart';
import 'package:wm_mobile/core/widgets/glass_card.dart';
import 'package:wm_mobile/core/widgets/gradient_button.dart';

/// The login form, on a single frosted surface.
///
/// Replaces the old three-file chain (`login_form` → `build_options_row` +
/// `custom_text_field` + `primary_button`), each of which existed only to hold
/// a few lines of layout.
class LoginCard extends StatelessWidget {
  const LoginCard({
    super.key,
    required this.formKey,
    required this.loginController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController loginController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      child: Form(
        key: formKey,
        child: AutofillGroup(
          child: Column(
            children: [
              AppTextField(
                controller: loginController,
                hint: 'Login',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Loginni kiriting'
                    : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: passwordController,
                hint: 'Parol',
                icon: Icons.lock_outline_rounded,
                obscure: obscurePassword,
                onToggleObscure: onToggleObscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => onSubmit(),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Parolni kiriting'
                    : null,
              ),
              const SizedBox(height: 6),
              _OptionsRow(
                rememberMe: rememberMe,
                onRememberMeChanged: onRememberMeChanged,
              ),
              const SizedBox(height: 18),
              GradientButton(
                label: 'Kirish',
                icon: Icons.arrow_forward_rounded,
                isLoading: isLoading,
                onPressed: onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionsRow extends StatelessWidget {
  const _OptionsRow({
    required this.rememberMe,
    required this.onRememberMeChanged,
  });

  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // The whole label is tappable, not just the 20px checkbox.
        InkWell(
          onTap: () => onRememberMeChanged(!rememberMe),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 22,
                  width: 22,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: onRememberMeChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Meni eslab qol',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: () => AppSnackBar.show(context, 'Tez orada qo\'shiladi'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Parolni unutdingizmi?',
            style: TextStyle(
              color: AppColors.accentGlow,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
