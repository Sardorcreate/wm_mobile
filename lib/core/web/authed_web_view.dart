import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';
import 'package:wm_mobile/core/widgets/glass_card.dart';
import 'package:wm_mobile/core/widgets/gradient_button.dart';
import 'package:wm_mobile/core/web/web_auth_bridge.dart';

/// A WebView that carries the app's auth token, reports load progress and
/// renders errors in the app's own visual language.
///
/// The two WebView screens each had their own copy of this — controller setup,
/// token injection, loading flag, error strings, refresh button — and the
/// copies had already diverged in behaviour. This is the single implementation
/// they now share.
class AuthedWebView extends StatefulWidget {
  const AuthedWebView({
    super.key,
    required this.initialUri,
    this.authToken,
    this.onSessionExpired,
    this.handleBackNavigation = false,
  });

  final Uri initialUri;
  final String? authToken;

  /// Called when the page posts `session_expired` on the `FlutterAuthChannel`.
  final VoidCallback? onSessionExpired;

  /// When true, a system back gesture walks the WebView's history before
  /// popping the route.
  final bool handleBackNavigation;

  @override
  State<AuthedWebView> createState() => AuthedWebViewState();
}

class AuthedWebViewState extends State<AuthedWebView> {
  late final WebViewController _controller;

  bool _loading = true;
  double _progress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _setup();
  }

  Future<void> _setup() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(Colors.transparent);

    await _controller.addJavaScriptChannel(
      'FlutterAuthChannel',
      onMessageReceived: (message) {
        if (message.message == 'session_expired') {
          widget.onSessionExpired?.call();
        }
      },
    );

    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress / 100);
        },
        onPageStarted: (_) async {
          if (mounted) {
            setState(() {
              _loading = true;
              _progress = 0;
              _errorMessage = null;
            });
          }
          await _inject();
        },
        onPageFinished: (_) async {
          // Inject again after load: single-page apps often replace the
          // document between `onPageStarted` and first paint.
          await _inject();
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (error) {
          // Sub-resource failures (a missing image, a blocked analytics call)
          // must not blank out a page that otherwise rendered fine.
          if (error.isForMainFrame == false) return;
          if (mounted) {
            setState(() {
              _loading = false;
              _errorMessage = _describe(error);
            });
          }
        },
      ),
    );

    await _controller.loadRequest(widget.initialUri);
  }

  Future<void> _inject() => WebAuthBridge.inject(
    _controller,
    uri: widget.initialUri,
    token: widget.authToken,
  );

  static String _describe(WebResourceError error) => switch (error.errorCode) {
    401 => 'Autentifikatsiya muddati tugagan',
    403 => "Sizda bu sahifaga kirish huquqi yo'q",
    -6 => "Serverga ulanib bo'lmadi",
    -2 => 'Tarmoq mavjud emas',
    _ =>
      error.description.isNotEmpty
          ? error.description
          : 'Sahifani yuklashda xatolik (${error.errorCode})',
  };

  /// Reloads the page and clears any error state.
  Future<void> reload() async {
    if (mounted) {
      setState(() {
        _errorMessage = null;
        _loading = true;
        _progress = 0;
      });
    }
    await _controller.reload();
  }

  /// Steps back through history if possible; returns false when the WebView is
  /// already at its first page.
  Future<bool> goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final view = Stack(
      children: [
        Positioned.fill(
          child: WebViewWidget(
            controller: _controller,
            gestureRecognizers: {
              Factory<VerticalDragGestureRecognizer>(
                VerticalDragGestureRecognizer.new,
              ),
            },
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _LoadingBar(visible: _loading, progress: _progress),
        ),
        if (_errorMessage != null)
          Positioned.fill(
            child: _ErrorPanel(message: _errorMessage!, onRetry: reload),
          ),
      ],
    );

    if (!widget.handleBackNavigation) return view;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (!await goBack()) navigator.pop();
      },
      child: view,
    );
  }
}

/// Determinate top-edge progress bar; fades out once the page settles.
class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.visible, required this.progress});

  final bool visible;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: AppMotion.medium,
      child: SizedBox(
        height: 3,
        child: LinearProgressIndicator(
          value: progress == 0 ? null : progress,
          minHeight: 3,
          backgroundColor: Colors.transparent,
          valueColor: const AlwaysStoppedAnimation(AppColors.accentGlow),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.abyss.withValues(alpha: 0.94),
      child: Center(
        child: GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 68,
                width: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.danger.withValues(alpha: 0.28),
                      AppColors.danger.withValues(alpha: 0.03),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 30,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: 'Qayta urinish',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
