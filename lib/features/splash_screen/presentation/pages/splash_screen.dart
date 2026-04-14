import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wm_mobile/common/widgets/common_widgets.dart';
import 'package:wm_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:wm_mobile/features/splash_screen/presentation/helpers/background_orb.dart';
import 'package:wm_mobile/features/splash_screen/presentation/widgets/splash_screen_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> fade;
  late final Animation<double> scale;
  late final Animation<Offset> slide;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startNavigationTimer();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    slide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  void _startNavigationTimer() {
    // Navigation logic stays encapsulated here
    Timer(
        const Duration(
            seconds: 4),
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            )
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: CommonWidgets.buildBackgroundDecoration(),
        child: Stack(
          children: [
            const BackgroundOrbs(),
            SplashScreenWidgets.buildMainContent(fade, scale, slide),
            SplashScreenWidgets.buildFooter(fade),
          ],
        ),
      ),
    );
  }
}