import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/device_details/presentation/pages/web_view_screen.dart';
import 'package:wm_mobile/utils/url_validator.dart';

/// Full-screen QR scanner using the device camera.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final MobileScannerController _scannerController;
  bool _hasHandledCurrentScan = false;
  bool _isCameraPermissionGranted = false;
  String? _permissionErrorMessage;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    _updatePermissionState(status);
  }

  void _updatePermissionState(PermissionStatus status) {
    if (status.isGranted) {
      setState(() {
        _isCameraPermissionGranted = true;
        _permissionErrorMessage = null;
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _isCameraPermissionGranted = false;
        _permissionErrorMessage =
        'Camera access is permanently denied. Enable it in system settings.';
      });
    } else {
      setState(() {
        _isCameraPermissionGranted = false;
        _permissionErrorMessage =
        'Camera permission is required to scan QR codes.';
      });
    }
  }

  Future<void> _openAppSettingsAndRecheckPermission() async {
    await openAppSettings();
    if (!mounted) return;
    await _requestCameraPermission();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasHandledCurrentScan) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final scannedData = _extractScannedData(barcodes.first);
    if (scannedData == null) {
      _showInvalidBarcodeMessage();
      return;
    }

    final url = parseBrowsableUrl(scannedData);
    if (url != null) {
      _handleUrlResult(url);
    } else {
      _handlePlainTextResult(scannedData);
    }
  }

  String? _extractScannedData(Barcode barcode) {
    final rawValue = barcode.displayValue ?? barcode.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }
    return rawValue.trim();
  }

  void _handleUrlResult(Uri url) async {
    _disableScannerUntilComplete();

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');

    if (!mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => WebViewScreen(
          initialUri: url,
          authToken: authToken,
        ),
      ),
    );

    _reEnableScanner();
  }

  void _handlePlainTextResult(String text) {
    _disableScannerUntilComplete();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _showScannedTextDialog(text);
      _reEnableScanner();
    });
  }

  void _disableScannerUntilComplete() {
    _hasHandledCurrentScan = true;
    _scannerController.stop();
  }

  void _reEnableScanner() {
    if (!mounted) return;
    _hasHandledCurrentScan = false;
    _scannerController.start();
  }

  void _showInvalidBarcodeMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not read QR code data. Try again.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showScannedTextDialog(String text) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => _ScannedTextDialog(text: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR code'),
      ),
      body: _isCameraPermissionGranted
          ? _buildScannerView()
          : _buildPermissionRequest(),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCameraPreview(),
        _buildScannerOverlay(),
      ],
    );
  }

  Widget _buildCameraPreview() {
    return MobileScanner(
      controller: _scannerController,
      onDetect: _onDetect,
      errorBuilder: (context, error) => _ScannerErrorWidget(error: error),
    );
  }

  Widget _buildScannerOverlay() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Point the camera at a QR code',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return _PermissionRequestWidget(
      message: _permissionErrorMessage,
      onRequestPermission: _requestCameraPermission,
      onOpenSettings: _shouldShowSettingsButton()
          ? _openAppSettingsAndRecheckPermission
          : null,
    );
  }

  bool _shouldShowSettingsButton() {
    return _permissionErrorMessage != null &&
        _permissionErrorMessage!.contains('settings');
  }
}

class _ScannedTextDialog extends StatelessWidget {
  const _ScannedTextDialog({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scanned content'),
      content: SelectionArea(
        child: SingleChildScrollView(
          child: Text(text),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ScannerErrorWidget extends StatelessWidget {
  const _ScannerErrorWidget({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final errorMessage = error.errorDetails?.message ?? error.toString();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 48),
            const SizedBox(height: 16),
            Text(
              'Camera error',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRequestWidget extends StatelessWidget {
  const _PermissionRequestWidget({
    required this.onRequestPermission,
    this.message,
    this.onOpenSettings,
  });

  final String? message;
  final VoidCallback onRequestPermission;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              message ?? 'Requesting camera access…',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRequestPermission,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
            if (onOpenSettings != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Open settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}