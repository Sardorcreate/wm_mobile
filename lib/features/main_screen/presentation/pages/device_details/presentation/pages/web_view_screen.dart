import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wm_mobile/common/widgets/common_widgets.dart';

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
  late final WebViewController _controller;
  bool _loading = true;
  String? _errorMessage;
  bool _authInjected = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _setupWebView();
  }

  Future<void> _setupWebView() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    if (widget.authToken != null) {
      await _injectAuthViaJS();
      _authInjected = true;
    }

    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) async {
          if (mounted) {
            setState(() {
              _loading = true;
              _errorMessage = null;
            });
          }

          if (widget.authToken != null) {
            await _injectAuthViaJS();
            _authInjected = true;
          }
        },
        onPageFinished: (String url) async {
          if (mounted) {
            setState(() => _loading = false);
          }
        },
        onWebResourceError: (WebResourceError error) {
          if (mounted) {
            setState(() {
              _loading = false;

              if (error.errorCode == 401 || error.errorCode == 403) {
                _errorMessage = error.errorCode == 403
                    ? "Sizda bu sahifaga kirish huquqi yo'q"
                    : "Autentifikatsiya muddati tugagan";
              } else if (error.errorCode == -6) {
                _errorMessage = "HTTP ulanish ruxsat etilmagan";
              } else {
                _errorMessage = error.description.isNotEmpty
                    ? error.description
                    : 'Failed to load page (${error.errorCode}).';
              }
            });
          }
        },
        onNavigationRequest: (NavigationRequest request) {
          _authInjected = false;
          return NavigationDecision.navigate;
        },
      ),
    );

    await _controller.loadRequest(widget.initialUri);
  }

  Future<void> _injectAuthViaJS() async {
    if (widget.authToken == null) return;

    final jsCode = '''
      (function() {
        window.AUTH_TOKEN = '${widget.authToken}';
        window.API_BASE_URL = 'http://${widget.initialUri.host}:8080';
        
        document.cookie = 'auth_token=${widget.authToken}; path=/; max-age=2592000; SameSite=Lax';
        document.cookie = 'token=${widget.authToken}; path=/; max-age=2592000; SameSite=Lax';
        document.cookie = 'session=${widget.authToken}; path=/; max-age=2592000; SameSite=Lax';
        
        try {
          localStorage.setItem('auth_token', '${widget.authToken}');
          localStorage.setItem('token', '${widget.authToken}');
          localStorage.setItem('access_token', '${widget.authToken}');
          sessionStorage.setItem('auth_token', '${widget.authToken}');
        } catch(e) {}
        
        var originalFetch = window.fetch;
        window.fetch = function(url, options) {
          if (!options) {
            options = { method: 'GET', headers: {} };
          }
          if (!options.headers) {
            options.headers = {};
          }
          
          if (typeof url === 'string') {
            if (url.startsWith('/api/') || url.startsWith('/auth/') || url.startsWith('/tools/')) {
              url = 'http://${widget.initialUri.host}:8080' + url;
            } else if (url.includes('localhost') || url.includes('127.0.0.1')) {
              url = url.replace(/localhost|127\\.0\\.0\\.1/g, '${widget.initialUri.host}');
            }
          } else if (url instanceof Request) {
            var originalUrl = url.url;
            if (originalUrl.startsWith('/api/') || originalUrl.startsWith('/auth/') || originalUrl.startsWith('/tools/')) {
              var newUrl = 'http://${widget.initialUri.host}:8080' + originalUrl;
              options.headers = new Headers(url.headers);
              options.headers.set('Authorization', 'Bearer ${widget.authToken}');
              url = new Request(newUrl, options);
              return originalFetch.call(this, url);
            }
          }
          
          try {
            if (options.headers instanceof Headers) {
              options.headers.set('Authorization', 'Bearer ${widget.authToken}');
              options.headers.set('X-Auth-Token', '${widget.authToken}');
            } else {
              options.headers['Authorization'] = 'Bearer ${widget.authToken}';
              options.headers['X-Auth-Token'] = '${widget.authToken}';
            }
          } catch(e) {}
          
          return originalFetch.call(window, url, options);
        };
        
        var XHR = XMLHttpRequest.prototype;
        var originalOpen = XHR.open;
        var originalSend = XHR.send;
        
        XHR.open = function(method, url) {
          this._method = method;
          if (typeof url === 'string') {
            if (url.startsWith('/api/') || url.startsWith('/auth/') || url.startsWith('/tools/')) {
              url = 'http://${widget.initialUri.host}:8080' + url;
            } else if (url.includes('localhost') || url.includes('127.0.0.1')) {
              url = url.replace(/localhost|127\\.0\\.0\\.1/g, '${widget.initialUri.host}');
            }
          }
          this._url = url;
          return originalOpen.apply(this, arguments);
        };
        
        XHR.send = function(body) {
          this.setRequestHeader('Authorization', 'Bearer ${widget.authToken}');
          this.setRequestHeader('X-Auth-Token', '${widget.authToken}');
          return originalSend.call(this, body);
        };
      })();
    ''';

    await _controller.runJavaScript(jsCode);
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        _errorMessage = null;
        _loading = true;
      });
    }
    _authInjected = false;
    await _controller.reload();
  }

  Future<void> _handleAuthError() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.lock_outline, color: Colors.red.shade400, size: 48),
        title: const Text('Kirish taqiqlangan'),
        content: Text(_errorMessage ?? 'Sizda bu kontentni ko\'rish uchun ruxsat yo\'q'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Orqaga'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _reload();
            },
            child: const Text('Qayta urinish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          color: Colors.white,
        ),
        title: Text(
          widget.title ?? widget.initialUri.host,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _reload,
            tooltip: 'Reload',
            color: Colors.white,
          ),
        ],
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: CommonWidgets.buildBackgroundDecoration(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const ColoredBox(
              color: Color(0x66FFFFFF),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (_errorMessage != null)
            Material(
              color: Colors.black54,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        errorIcon,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_errorMessage?.contains('401') == true ||
                              _errorMessage?.contains('403') == true)
                            TextButton(
                              onPressed: _handleAuthError,
                              child: const Text('Batafsil'),
                            ),
                          const SizedBox(width: 16),
                          FilledButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData get errorIcon {
    if (_errorMessage?.contains('401') == true ||
        _errorMessage?.contains('403') == true) {
      return Icons.lock_outline;
    }
    return Icons.error_outline;
  }
}