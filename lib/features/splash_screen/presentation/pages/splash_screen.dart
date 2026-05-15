import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wm_mobile/common/widgets/common_widgets.dart';
import 'package:wm_mobile/features/auth/controller/auth_guard.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';
import 'package:wm_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/scanner/presentation/pages/scanner.dart';
import 'package:wm_mobile/features/splash_screen/presentation/helpers/background_orb.dart';
import 'package:wm_mobile/features/splash_screen/presentation/widgets/splash_screen_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> fade;
  late final Animation<double> scale;
  late final Animation<Offset> slide;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthAndNavigate();
  }

  // ── Animations ─────────────────────────────────────────────────────────────
  // Unchanged from your original.

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

  // ── Auth check ─────────────────────────────────────────────────────────────

  Future<void> _checkAuthAndNavigate() async {
    // Run the minimum display time and the auth check in parallel so we never
    // wait longer than necessary. The splash shows for at least 4 seconds
    // regardless of how fast the network responds (matching your original timer).
    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 4)),
      AuthService.instance.shouldAutoLogin(),
    ]);

    final autoLogin = results[1] as bool;

    if (!mounted) return;

    if (autoLogin) {
      // Valid remembered session → go straight to scanner.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AuthGuard(child: ScannerScreen()),
        ),
      );
    } else {
      // No session, rememberMe off, or token expired → show login.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  // Identical to your original — same widgets, same layout.

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