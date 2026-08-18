import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_gradients.dart';
import 'package:wm_mobile/core/web/authed_web_view.dart';

/// Full-screen browser for content opened from a scanned QR code.
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({
    super.key,
    required this.initialUri,
    this.title,
    this.authToken,
  });

  final Uri initialUri;
  final String? title;
  final String? authToken;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final GlobalKey<AuthedWebViewState> _webViewKey =
      GlobalKey<AuthedWebViewState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Orqaga',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title ?? widget.initialUri.host,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.initialUri.host,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yangilash',
            onPressed: () => _webViewKey.currentState?.reload(),
          ),
          const SizedBox(width: 4),
        ],
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.background),
        ),
      ),
      body: AuthedWebView(
        key: _webViewKey,
        initialUri: widget.initialUri,
        authToken: widget.authToken,
        handleBackNavigation: true,
      ),
    );
  }
}
