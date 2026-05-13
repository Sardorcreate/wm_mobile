import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wm_mobile/common/functions/helper_functions.dart';
import 'package:wm_mobile/common/widgets/app_bar_widget.dart';
import 'package:wm_mobile/common/widgets/common_widgets.dart';
import 'package:wm_mobile/features/auth/presentation/widgets/build_welcome_text.dart';
import 'package:wm_mobile/features/auth/presentation/widgets/login_form.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/scanner/presentation/pages/scanner.dart';
import 'package:wm_mobile/features/splash_screen/presentation/helpers/background_orb.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  Future<void> _saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      if (rememberMe) {
        await prefs.setString('saved_login', _loginController.text);
        await prefs.setBool('remember_me', true);
      }
    } catch (e) {
      // Token save failed, but allow login to continue
    }
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> handleLogin() async {
    if (_loginController.text.isEmpty || _passwordController.text.isEmpty) {
      HelperFunctions.showSnackBar(
        "Iltimos, barcha maydonlarni to'ldiring!",
        Colors.orange,
        context,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.137.51:8080/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': _loginController.text,
          'password': _passwordController.text,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['token']
            ?? data['access_token']
            ?? data['accessToken']
            ?? data['jwt']
            ?? data['authorization'];

        if (token != null && token.isNotEmpty) {
          await _saveAuthToken(token);

          if (!mounted) return;

          setState(() => isLoading = false);
          await Future.delayed(const Duration(milliseconds: 100));

          if (!mounted) return;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
                (route) => false,
          );
        } else {
          if (!mounted) return;
          setState(() => isLoading = false);

          HelperFunctions.showSnackBar(
            'Login muvaffaqiyatli, lekin token topilmadi',
            Colors.orange,
            context,
          );
        }
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);

        String errorMessage = 'Login amalga oshmadi';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message']
              ?? errorData['error']
              ?? errorMessage;
        } catch (_) {
          errorMessage = response.body.isNotEmpty
              ? response.body
              : errorMessage;
        }

        HelperFunctions.showSnackBar(
          errorMessage,
          Colors.red,
          context,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);

      String errorMsg;
      if (e is SocketException) {
        errorMsg = 'Server topilmadi. Tarmoqni tekshiring.';
      } else if (e is TimeoutException) {
        errorMsg = 'Ulanish vaqti tugadi.';
      } else if (e is FormatException) {
        errorMsg = 'Server javobi noto\'g\'ri formatda.';
      } else {
        errorMsg = 'Xatolik yuz berdi';
      }

      HelperFunctions.showSnackBar(
        errorMsg,
        Colors.red,
        context,
      );
    }
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