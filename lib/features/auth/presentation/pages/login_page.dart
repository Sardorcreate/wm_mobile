import 'package:flutter/material.dart';
import 'package:wm_mobile/common/functions/helper_functions.dart';
import 'package:wm_mobile/common/widgets/app_bar_widget.dart';
import 'package:wm_mobile/common/widgets/common_widgets.dart';
import 'package:wm_mobile/features/auth/controller/auth_guard.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';
import 'package:wm_mobile/features/auth/presentation/widgets/build_welcome_text.dart';
import 'package:wm_mobile/features/auth/presentation/widgets/login_form.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/scanner/presentation/pages/scanner.dart';
import 'package:wm_mobile/features/splash_screen/presentation/helpers/background_orb.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
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
    _prefillSavedLogin();
  }

  void _setupAnimations() {
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    fade = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  /// Pre-fills the username field if the user had previously checked remember-me.
  Future<void> _prefillSavedLogin() async {
    final saved = await AuthService.instance.getSavedLogin();
    if (saved != null && mounted) {
      _loginController.text = saved;
      setState(() => rememberMe = true);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    final username = _loginController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      HelperFunctions.showSnackBar(
        "Iltimos, barcha maydonlarni to'ldiring!",
        Colors.orange,
        context,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // AuthService.login() throws AuthException on any failure.
      final token = await AuthService.instance.login(username, password);

      await AuthService.instance.saveToken(
        token,
        rememberMe: rememberMe,
        login: username,
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      // Short pause so the loading indicator doesn't flash.
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          // Wrap ScannerScreen in AuthGuard so mid-session expiry is handled.
          builder: (_) => const AuthGuard(child: ScannerScreen()),
        ),
            (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      HelperFunctions.showSnackBar(e.message, Colors.red, context);
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      HelperFunctions.showSnackBar('Xatolik yuz berdi', Colors.red, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
                    const AppBarWidget(title: "Kirish", showBackButton: false),
                    const SizedBox(height: 40),
                    BuildWelcomeText(
                      fade: fade,
                      text1: "Qaytganingiz bilan",
                      text2: "Akkauntga kiring",
                    ),
                    const SizedBox(height: 50),
                    LoginForm(
                      fade: fade,
                      slide: slide,
                      loginController: _loginController,
                      passwordController: _passwordController,
                      visiblePassword: () => setState(
                            () => isPasswordVisible = !isPasswordVisible,
                      ),
                      remember: (value) =>
                          setState(() => rememberMe = value ?? false),
                      handleLogin: handleLogin,
                      isPasswordVisible: isPasswordVisible,
                      isLoading: isLoading,
                      rememberMe: rememberMe,
                    ),
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
}