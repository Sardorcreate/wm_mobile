import 'package:flutter/material.dart';

import 'package:wm_mobile/core/navigation/app_routes.dart';
import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/web/authed_web_view.dart';
import 'package:wm_mobile/core/widgets/press_scale.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';
import 'package:wm_mobile/features/auth/presentation/pages/login_page.dart';

/// The "Jihozlar" tab: the web console, embedded.
///
/// All the WebView plumbing now lives in [AuthedWebView]; this screen is just
/// the tab's chrome and its logout policy.
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key, required this.initialUri, this.authToken});

  final Uri initialUri;
  final String? authToken;

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final GlobalKey<AuthedWebViewState> _webViewKey =
      GlobalKey<AuthedWebViewState>();

  Future<void> _handleSessionExpired() async {
    await AuthService.instance.clearAuth();
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushAndRemoveUntil(appRoute<void>(const LoginPage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Rounded top corners let the gradient shell frame the web content
        // instead of the page running edge to edge under the header.
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: AuthedWebView(
              key: _webViewKey,
              initialUri: widget.initialUri,
              authToken: widget.authToken,
              onSessionExpired: _handleSessionExpired,
              handleBackNavigation: true,
            ),
          ),
        ),
        Positioned(
          right: 18,
          bottom: 104,
          child: _RefreshButton(
            onTap: () => _webViewKey.currentState?.reload(),
          ),
        ),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      scale: 0.9,
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.blue, AppColors.indigo],
          ),
          border: Border.all(color: AppColors.glassBorderStrong),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.refresh_rounded,
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }
}
