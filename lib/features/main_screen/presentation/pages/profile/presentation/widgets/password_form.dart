import 'package:flutter/material.dart';

import 'package:wm_mobile/core/feedback/app_snack_bar.dart';
import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';
import 'package:wm_mobile/core/widgets/app_text_field.dart';
import 'package:wm_mobile/core/widgets/gradient_button.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';

/// Change-password form, with a live strength meter.
class PasswordForm extends StatefulWidget {
  const PasswordForm({super.key});

  @override
  State<PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController
      ..removeListener(_onPasswordChanged)
      ..dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() => setState(() {});

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      await AuthService.instance.changePassword(_passwordController.text);
      if (!mounted) return;

      _passwordController.clear();
      _confirmController.clear();
      _formKey.currentState?.reset();
      AppSnackBar.success(context, "Parol muvaffaqiyatli o'zgartirildi");
    } on AuthException catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            controller: _passwordController,
            hint: 'Yangi parol',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Yangi parolni kiriting';
              }
              if (value.length < 6) {
                return "Parol kamida 6 ta belgidan iborat bo'lishi kerak";
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _StrengthMeter(password: _passwordController.text),
          const SizedBox(height: 14),
          AppTextField(
            controller: _confirmController,
            hint: 'Parolni tasdiqlang',
            icon: Icons.lock_person_outlined,
            obscure: _obscureConfirm,
            onToggleObscure: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Parolni tasdiqlang';
              if (value != _passwordController.text) {
                return 'Parollar mos kelmadi';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Saqlash',
            icon: Icons.check_rounded,
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Four-segment strength bar. Purely advisory — the form still only *requires*
/// the six-character minimum the backend enforces.
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.password});

  final String password;

  /// 0 (empty) to 4 (strong).
  int get _score {
    if (password.isEmpty) return 0;
    var score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      score++;
    }
    return score;
  }

  static const List<String> _labels = [
    '',
    'Zaif',
    "O'rtacha",
    'Yaxshi',
    'Kuchli',
  ];

  Color get _color => switch (_score) {
    <= 1 => AppColors.danger,
    2 => AppColors.warning,
    3 => AppColors.accent,
    _ => AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    final score = _score;

    return AnimatedOpacity(
      opacity: password.isEmpty ? 0 : 1,
      duration: AppMotion.medium,
      child: Row(
        children: [
          for (var i = 1; i <= 4; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: AppMotion.medium,
                curve: AppMotion.standard,
                height: 4,
                decoration: BoxDecoration(
                  color: i <= score ? _color : AppColors.glass(0.14),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            if (i < 4) const SizedBox(width: 6),
          ],
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(
              _labels[score],
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
