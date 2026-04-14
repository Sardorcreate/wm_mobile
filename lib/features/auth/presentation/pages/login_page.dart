import 'package:flutter/material.dart';
import 'package:wm_mobile/common/functions/helper_functions.dart';
import 'package:wm_mobile/common/widgets/common_widgets.dart';
import 'package:wm_mobile/features/auth/presentation/helpers/custom_text_field.dart';
import 'package:wm_mobile/features/auth/presentation/helpers/or_dividers.dart';
import 'package:wm_mobile/features/auth/presentation/helpers/primary_button.dart';
import 'package:wm_mobile/features/auth/presentation/widgets/build_options_row.dart';
import 'package:wm_mobile/features/splash_screen/presentation/helpers/background_orb.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> fade;
  late final Animation<Offset> slide;

  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isLoading = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    fade = CurvedAnimation(parent: controller, curve: Curves.easeOut);
    slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    if (_loginController.text.isEmpty || _passwordController.text.isEmpty) {
      HelperFunctions.showSnackBar(
          "Iltimos, barcha maydonlarni to'ldiring!",
          Colors.orange,
          context);
      return;
    }

    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => isLoading = false);

    HelperFunctions.showSnackBar(
        'Muvaffaqiyatli kirdingiz!',
        Colors.green,
        context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: CommonWidgets.buildBackgroundDecoration(),
        child: SafeArea(
          child: Stack(
            children: [
              const BackgroundOrbs(),
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeaderNav(),
                    const SizedBox(height: 40),
                    _buildWelcomeText(),
                    const SizedBox(height: 50),
                    _buildLoginForm(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderNav() {
    return FadeTransition(
      opacity: fade,
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return FadeTransition(
      opacity: fade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Qaytganingiz bilan",
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "Akkauntingizga kiring",
            style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: fade,
        child: Column(
          children: [
            CustomTextField(
              controller: _loginController,
              hint: "Login",
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _passwordController,
              hint: "Parol",
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              isPasswordVisible: isPasswordVisible,
              onToggleVisibility: () => setState(() => isPasswordVisible = !isPasswordVisible),
            ),
            BuildOptionsRow(
              rememberMe: rememberMe,
              onRememberMeChanged: (value) => setState(() => rememberMe = value ?? false),
              context: context,
            ),
            const SizedBox(height: 30),
            PrimaryButton(
              text: "Kirish",
              isLoading: isLoading,
              onPressed: handleLogin,
            ),
            const SizedBox(height: 24),
            const OrDivider(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}