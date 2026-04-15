import 'package:flutter/material.dart';
import 'package:wm_mobile/features/auth/presentation/helpers/custom_text_field.dart';
import 'package:wm_mobile/features/auth/presentation/helpers/primary_button.dart';
import 'package:wm_mobile/features/auth/presentation/widgets/build_options_row.dart';

class LoginForm extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final TextEditingController loginController;
  final TextEditingController passwordController;
  final VoidCallback? visiblePassword;
  final ValueChanged<bool?> remember;
  final VoidCallback handleLogin;
  final bool isPasswordVisible;
  final bool isLoading;
  final bool rememberMe;


  const LoginForm({
    super.key,
    required this.fade,
    required this.slide,
    required this.loginController,
    required this.passwordController,
    this.visiblePassword,
    required this.remember,
    required this.handleLogin,
    required this.isPasswordVisible,
    required this.isLoading,
    required this.rememberMe,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: fade,
        child: Column(
          children: [
            CustomTextField(
              controller: loginController,
              hint: "Login",
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: passwordController,
              hint: "Parol",
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              isPasswordVisible: isPasswordVisible,
              onToggleVisibility: visiblePassword,
            ),
            BuildOptionsRow(
              rememberMe: rememberMe,
              onRememberMeChanged: remember,
              context: context,
            ),
            const SizedBox(height: 30),
            PrimaryButton(
              text: "Kirish",
              isLoading: isLoading,
              onPressed: handleLogin,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

//() => setState(() => isPasswordVisible = !isPasswordVisible)
//(value) => setState(() => rememberMe = value ?? false)
