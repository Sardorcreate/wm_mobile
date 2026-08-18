import 'package:flutter/material.dart';

import 'package:wm_mobile/core/navigation/app_routes.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';
import 'package:wm_mobile/features/auth/controller/auth_guard.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';
import 'package:wm_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/main_screen.dart';
import 'package:wm_mobile/features/splash_screen/presentation/widgets/splash_content.dart';

/// Brand moment + auth resolution.
///
/// The old version always waited a flat 4 seconds. Now it waits for the
/// intro animation to land (~1.8s) and no longer than that if the auth check
/// has already returned — the splash is a floor, not a fixed toll.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _minimumDisplay = Duration(milliseconds: 1800);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.hero,
  )..forward();

  bool _logoPrecached = false;

  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm the image cache here rather than on first paint, so the logo never
    // pops in a frame late.
    if (!_logoPrecached) {
      _logoPrecached = true;
      precacheImage(const AssetImage('assets/images/logo.png'), context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolveDestination() async {
    final results = await Future.wait<Object?>([
      Future<void>.delayed(_minimumDisplay),
      AuthService.instance.shouldAutoLogin(),
    ]);

    if (!mounted) return;

    final autoLogin = results[1]! as bool;

    Navigator.of(context).pushReplacement(
      appRoute<void>(
        autoLogin ? const AuthGuard(child: MainScreen()) : const LoginPage(),
        transition: AppTransition.fadeThrough,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SplashContent(controller: _controller));
  }
}
