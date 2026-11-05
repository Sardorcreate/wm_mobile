import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wm_mobile/core/feedback/app_snack_bar.dart';
import 'package:wm_mobile/core/navigation/app_routes.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';
import 'package:wm_mobile/features/auth/presentation/pages/login_page.dart';

/// Wraps any screen that requires a valid auth token.
///
/// - Validates the token immediately on first build.
/// - Re-validates every [checkInterval] (default 5 minutes).
/// - On expiry, navigates to [LoginPage] and clears stored credentials,
///   regardless of which route is currently active. Expiry is reported both by
///   these checks and by any API call that fails to refresh.
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

  final Duration checkInterval;

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> with WidgetsBindingObserver {
  Timer? _timer;
  StreamSubscription<void>? _expiry;
  bool _isChecking = false;
  bool _hasExpired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _expiry = AuthService.instance.onSessionExpired.listen(
      (_) => _handleExpiry(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPeriodicCheck());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _expiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validateNow();
    }
  }

  void _startPeriodicCheck() {
    _validateNow();
    _timer = Timer.periodic(widget.checkInterval, (_) => _validateNow());
  }

  Future<void> _validateNow() async {
    if (_isChecking || !mounted) return;
    _isChecking = true;

    try {
      final result = await AuthService.instance.validateSession();
      if (result == false) await _handleExpiry();
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _handleExpiry() async {
    // A failed check and a failed request can both report the same expiry.
    if (_hasExpired) return;
    _hasExpired = true;

    _timer?.cancel();
    await AuthService.instance.clearAuth();

    if (!mounted) return;

    AppSnackBar.warning(context, 'Sessiya tugadi. Iltimos, qayta kiring.');

    Navigator.of(
      context,
    ).pushAndRemoveUntil(appRoute<void>(const LoginPage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
