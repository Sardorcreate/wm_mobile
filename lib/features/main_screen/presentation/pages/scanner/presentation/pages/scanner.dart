import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:wm_mobile/core/feedback/app_snack_bar.dart';
import 'package:wm_mobile/core/navigation/app_routes.dart';
import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/scanner/presentation/widgets/permission_request_widget.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/scanner/presentation/widgets/scanned_text_widget.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/scanner/presentation/widgets/scanner_controls.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/scanner/presentation/widgets/scanner_error_widget.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/scanner/presentation/widgets/scanner_frame.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/web_view/presentation/pages/web_view_screen.dart';
import 'package:wm_mobile/utils/url_validator.dart';

/// QR viewfinder.
///
/// Two behaviours changed beyond the visuals:
///
/// * The camera now stops whenever the tab is hidden or the app is backgrounded
///   ([isActive] + lifecycle observer). It previously stayed live inside the
///   `IndexedStack` for the whole session.
/// * Permission is requested on first *view*, not in `initState`, so opening
///   the app no longer fires a camera prompt before the user has asked to scan.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, this.isActive = true});

  /// Whether this tab is the visible one.
  final bool isActive;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
    autoStart: false,
  );

  bool _permissionGranted = false;
  bool _handlingScan = false;
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) _ensurePermissionAndStart();
  }

  @override
  void didUpdateWidget(ScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;

    if (!widget.isActive) {
      _stop();
    } else if (_permissionGranted) {
      // Already authorised — just resume, don't round-trip the permission
      // plugin every time the user returns to this tab.
      _start();
    } else {
      _ensurePermissionAndStart();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isActive || !_permissionGranted) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _start();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  // ── Camera control ─────────────────────────────────────────────────────────

  void _stop() {
    _controller.stop().catchError((_) {});
  }

  void _start() {
    if (_handlingScan) return;
    _controller.start().catchError((_) {});
  }

  Future<void> _ensurePermissionAndStart() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    setState(() {
      _permissionGranted = status.isGranted;
      _permissionError = switch (status) {
        PermissionStatus.granted => null,
        PermissionStatus.permanentlyDenied =>
          'Kameraga ruxsat butunlay rad etilgan. '
              'Tizim sozlamalaridan yoqing.',
        _ => 'QR kodlarni skanerlash uchun kameraga ruxsat kerak.',
      };
    });

    if (_permissionGranted) _start();
  }

  Future<void> _openSettingsAndRecheck() async {
    await openAppSettings();
    if (!mounted) return;
    await _ensurePermissionAndStart();
  }

  // ── Detection ──────────────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_handlingScan || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final raw = (barcode.displayValue ?? barcode.rawValue)?.trim();

    if (raw == null || raw.isEmpty) {
      AppSnackBar.warning(context, "QR kodni o'qib bo'lmadi. Qayta urining.");
      return;
    }

    _handlingScan = true;
    _stop();

    final url = parseBrowsableUrl(raw);
    if (url != null) {
      _openUrl(url);
    } else {
      _showPlainText(raw);
    }
  }

  Future<void> _openUrl(Uri url) async {
    // The WebView only ever gets the access token, so make sure it's a live one.
    // If the session is over, AuthGuard is already on its way to the login page.
    if (await AuthService.instance.validateSession() == false) return;

    final token = await AuthService.instance.getToken();
    if (!mounted) return;

    await Navigator.of(context).push<void>(
      appRoute<void>(
        WebViewScreen(
          initialUri: url,
          authToken: token,
          title: "Qurilma ma'lumotlari",
        ),
        transition: AppTransition.zoom,
      ),
    );

    _resumeAfterScan();
  }

  Future<void> _showPlainText(String text) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ScannedTextDialog(text: text),
    );
    _resumeAfterScan();
  }

  void _resumeAfterScan() {
    if (!mounted) return;
    _handlingScan = false;
    if (widget.isActive) _start();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_permissionGranted) {
      return PermissionRequestWidget(
        message: _permissionError,
        onRequestPermission: _ensurePermissionAndStart,
        onOpenSettings: _permissionError?.contains('sozlamalar') ?? false
            ? _openSettingsAndRecheck
            : null,
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => ScannerErrorWidget(error: error),
          ),
          const Positioned.fill(child: IgnorePointer(child: ScannerFrame())),
          Positioned(
            left: 0,
            right: 0,
            bottom: 108,
            child: Column(
              children: [
                const _HintText(),
                const SizedBox(height: 18),
                ScannerControls(controller: _controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  const _HintText();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.abyss.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.center_focus_strong_rounded,
            size: 18,
            color: AppColors.accentGlow,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              "Kamerani QR kodga to'g'rilang",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
