import 'package:flutter/material.dart';

import 'package:wm_mobile/core/feedback/app_snack_bar.dart';
import 'package:wm_mobile/core/navigation/app_routes.dart';
import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';
import 'package:wm_mobile/core/widgets/entrance.dart';
import 'package:wm_mobile/core/widgets/gradient_text.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/main_screen.dart';
import 'package:wm_mobile/features/auth/controller/auth_guard.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';
import 'package:wm_mobile/features/auth/presentation/widgets/login_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _prefillSavedLogin();
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Pre-fills the username if the user previously checked remember-me.
  Future<void> _prefillSavedLogin() async {
    final saved = await AuthService.instance.getSavedLogin();
    if (saved == null || !mounted) return;
    _loginController.text = saved;
    setState(() => _rememberMe = true);
  }

  Future<void> _handleLogin() async {
    // Validation moved into the fields themselves, so an empty form now
    // highlights the offending input instead of firing a generic snackbar.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await AuthService.instance.signIn(
        _loginController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.of(context).pushAndRemoveUntil(
        appRoute<void>(
          const AuthGuard(child: MainScreen()),
          transition: AppTransition.fadeThrough,
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.error(context, e.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.error(context, 'Kutilmagan xatolik: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Entrance(child: _WelcomeHeader()),
                    const SizedBox(height: 36),
                    Entrance(
                      delay: AppMotion.stagger * 2,
                      child: LoginCard(
                        formKey: _formKey,
                        loginController: _loginController,
                        passwordController: _passwordController,
                        obscurePassword: _obscurePassword,
                        onToggleObscure: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        rememberMe: _rememberMe,
                        onRememberMeChanged: (value) =>
                            setState(() => _rememberMe = value ?? false),
                        isLoading: _isLoading,
                        onSubmit: _handleLogin,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    Entrance(
                      delay: AppMotion.stagger * 4,
                      child: Center(
                        child: Text(
                          'TuronBank · Omborxona boshqaruvi',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.glass(0.12),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 14,
                color: AppColors.accentGlow,
              ),
              const SizedBox(width: 7),
              Text(
                'Xavfsiz kirish',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const GradientText(
          'Qaytganingiz\nbilan',
          style: TextStyle(
            fontSize: 40,
            height: 1.1,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Davom etish uchun akkauntga kiring',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
