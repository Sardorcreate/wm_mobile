import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';
import 'package:wm_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/gestures.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({
    super.key,
    required this.initialUri,
    this.authToken,
  });

  final Uri initialUri;
  final String? authToken;

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _setupWebView();
  }

  Future<void> _setupWebView() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(Colors.transparent);

    await _controller.addJavaScriptChannel(
      'FlutterAuthChannel',
      onMessageReceived: (JavaScriptMessage message) {
        if (message.message == 'session_expired') {
          _handleImmediateLogout();
        }
      },
    );

    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) async => await _injectAuthViaJS(),
        onPageFinished: (String url) => setState(() => _loading = false),
        onWebResourceError: (WebResourceError error) {
          setState(() {
            _loading = false;
            _errorMessage = "Sahifani yuklashda xatolik yuz berdi (${error.errorCode})";
          });
        },
      ),
    );

    await _controller.loadRequest(widget.initialUri);
  }

  void _handleImmediateLogout() async {
    await AuthService.instance.clearAuth();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  Future<void> _injectAuthViaJS() async {
    if (widget.authToken == null) return;

    final jsCode = '''
      (function() {
        const baseHost = '${widget.initialUri.host}';
        const basePort = '${widget.initialUri.port}' ? ':' + '${widget.initialUri.port}' : '';
        const protocol = '${widget.initialUri.scheme}://';
        const prodBaseUrl = protocol + baseHost + basePort;
    
        window.AUTH_TOKEN = '${widget.authToken}';
        window.API_BASE_URL = prodBaseUrl;
        
        const cookieFlags = '; path=/; max-age=2592000; SameSite=Lax';
        document.cookie = 'auth_token=${widget.authToken}' + cookieFlags;
        document.cookie = 'token=${widget.authToken}' + cookieFlags;
        
        try {
          localStorage.setItem('auth_token', '${widget.authToken}');
          localStorage.setItem('token', '${widget.authToken}');
        } catch(e) {}
      })();
    ''';

    await _controller.runJavaScript(jsCode);
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _errorMessage = null;
    });
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              if (await _controller.canGoBack()) {
                await _controller.goBack();
              } else {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: Positioned.fill(
              child: WebViewWidget(
                controller: _controller,
                gestureRecognizers: {
                  Factory<VerticalDragGestureRecognizer>(
                        () => VerticalDragGestureRecognizer(),
                  ),
                },
              ),
            ),
          ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.white70),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _handleRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Qayta urinish'),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton.small(
              onPressed: _handleRefresh,
              backgroundColor: const Color(0xFF0D47A1),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
        ],
      )
    );
  }
}