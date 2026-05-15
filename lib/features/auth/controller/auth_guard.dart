import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';
import 'package:wm_mobile/features/auth/presentation/pages/login_page.dart';

/// Wraps any screen that requires a valid auth token.
///
/// - Validates the token immediately on first build.
/// - Re-validates every [checkInterval] (default 5 minutes).
/// - On expiry (server returns 401/403), navigates to [LoginPage] and clears
///   stored credentials, regardless of which route is currently active.
///
/// Network failures (no connectivity, timeout) are ignored — the user stays
/// logged in and the next timer tick will retry.
///
/// Usage:
/// ```dart
/// Navigator.of(context).pushAndRemoveUntil(
///   MaterialPageRoute(builder: (_) => const AuthGuard(child: ScannerScreen())),
///   (route) => false,
/// );
/// ```
class AuthGuard extends StatefulWidget {
  const AuthGuard({
    super.key,
    required this.child,
    this.checkInterval = const Duration(minutes: 5),
  });

  final Widget child;

  /// How often to re-validate the token in the background.
  final Duration checkInterval;

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> with WidgetsBindingObserver {
  Timer? _timer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // First check shortly after the screen mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPeriodicCheck());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-validate when the app comes back to the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validateNow();
    }
  }

  void _startPeriodicCheck() {
    _validateNow(); // immediate check
    _timer = Timer.periodic(widget.checkInterval, (_) => _validateNow());
  }

  Future<void> _validateNow() async {
    if (_isChecking || !mounted) return;
    _isChecking = true;

    try {
      final token = await AuthService.instance.getToken();
      if (token == null) {
        _handleExpiry();
        return;
      }

      final result = await AuthService.instance.validateToken(token);
      // null  → network problem, skip
      // true  → still valid, do nothing
      // false → expired, redirect
      if (result == false) _handleExpiry();
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _handleExpiry() async {
    _timer?.cancel();
    await AuthService.instance.clearAuth();

    if (!mounted) return;

    // Show a brief snackbar so the user knows why they were redirected.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sessiya tugadi. Iltimos, qayta kiring.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}