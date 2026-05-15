import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wm_mobile/common/widgets/common_widgets.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/device_details/presentation/pages/web_view_screen.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/scanner/presentation/widgets/permission_request_widget.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/scanner/presentation/widgets/scanned_text_widget.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/scanner/presentation/widgets/scanner_error_widget.dart';
import 'package:wm_mobile/utils/url_validator.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final MobileScannerController _scannerController;
  bool _hasHandledCurrentScan = false;
  bool _isCameraPermissionGranted = false;
  String? permissionErrorMessage;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    requestCameraPermission();
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

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    _updatePermissionState(status);
  }

  void _updatePermissionState(PermissionStatus status) {
    if (status.isGranted) {
      setState(() {
        _isCameraPermissionGranted = true;
        permissionErrorMessage = null;
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _isCameraPermissionGranted = false;
        permissionErrorMessage =
        'Camera access is permanently denied. Enable it in system settings.';
      });
    } else {
      setState(() {
        _isCameraPermissionGranted = false;
        permissionErrorMessage =
        'Camera permission is required to scan QR codes.';
      });
    }
  }

  Future<void> _openAppSettingsAndRecheckPermission() async {
    await openAppSettings();
    if (!mounted) return;
    await requestCameraPermission();
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
          title: "Qurilma ma'lumotlari",
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
      builder: (context) => ScannedTextDialog(text: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "QR kod skanerlash",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent, // let gradient show
        flexibleSpace: Container(
          decoration: CommonWidgets.buildBackgroundDecoration(),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isCameraPermissionGranted
          ? _buildScannerView()
          : _buildPermissionRequest(),
    );
  }

  Widget _buildScannerView() {
    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraPreview(),
          _buildScannerOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return MobileScanner(
      controller: _scannerController,
      onDetect: _onDetect,
      errorBuilder: (context, error) => ScannerErrorWidget(error: error),
    );
  }

  Widget _buildScannerOverlay() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: CommonWidgets.buildBackgroundDecoration(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                "Kamerani QR kodga to'g'irlang",
                style: const TextStyle(
                  color: Colors.white, // white text for contrast
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return PermissionRequestWidget(
      message: permissionErrorMessage,
      onRequestPermission: requestCameraPermission,
      onOpenSettings: _shouldShowSettingsButton()
          ? _openAppSettingsAndRecheckPermission
          : null,
    );
  }

  bool _shouldShowSettingsButton() {
    return permissionErrorMessage != null &&
        permissionErrorMessage!.contains('settings');
  }
}