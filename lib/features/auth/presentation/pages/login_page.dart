import 'package:flutter/material.dart';
import 'package:wm_mobile/common/functions/helper_functions.dart';
import 'package:wm_mobile/common/widgets/app_bar_widget.dart';
import 'package:wm_mobile/common/widgets/common_widgets.dart';
import 'package:wm_mobile/features/auth/presentation/widgets/build_welcome_text.dart';
import 'package:wm_mobile/features/auth/presentation/widgets/login_form.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/main_screen.dart';
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

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen()));

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
                    AppBarWidget(title: "Kirish", showBackButton: false,),
                    const SizedBox(height: 40),
                    BuildWelcomeText(fade: fade, text1: "Qaytganingiz bilan", text2: "Akkauntga kiring"),
                    const SizedBox(height: 50),
                    LoginForm(
                      fade: fade,
                      slide: slide,
                      loginController: _loginController,
                      passwordController: _passwordController,
                      visiblePassword: () => setState(() => isPasswordVisible = !isPasswordVisible),
                      remember: (value) => setState(() => rememberMe = value ?? false),
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