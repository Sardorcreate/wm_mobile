import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';

/// Dims everything outside the scan window, draws corner brackets, and sweeps a
/// laser line across the cutout.
///
/// The previous overlay was a text card at the bottom of the screen with no
/// indication of *where* to aim, which is the one thing a QR viewfinder has to
/// communicate.
class ScannerFrame extends StatefulWidget {
  const ScannerFrame({super.key, this.windowSize = 250});

  final double windowSize;

  @override
  State<ScannerFrame> createState() => ScannerFrameState();
}

class ScannerFrameState extends State<ScannerFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _FramePainter(
            windowSize: widget.windowSize,
            sweep: Curves.easeInOut.transform(_controller.value),
          ),
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter({required this.windowSize, required this.sweep});

  final double windowSize;

  /// 0..1 position of the scan line within the window.
  final double sweep;

  static const double _cornerLength = 34;
  static const double _cornerRadius = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final side = windowSize.clamp(160.0, size.shortestSide * 0.78);
    final window = Rect.fromCenter(
      // Sits slightly above centre so the hint text below stays clear of it.
      center: Offset(size.width / 2, size.height * 0.44),
      width: side,
      height: side,
    );
    final rrect = RRect.fromRectAndRadius(
      window,
      const Radius.circular(_cornerRadius),
    );

    _paintScrim(canvas, size, rrect);
    _paintScanLine(canvas, window);
    _paintCorners(canvas, window);
  }

  /// Darkens the frame except for the scan window.
  void _paintScrim(Canvas canvas, Size size, RRect window) {
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(window),
    );
    canvas.drawPath(
      scrim,
      Paint()..color = AppColors.abyss.withValues(alpha: 0.55),
    );
  }

  void _paintScanLine(Canvas canvas, Rect window) {
    final y = window.top + window.height * sweep;
    final lineRect = Rect.fromLTWH(window.left, y - 26, window.width, 52);

    // A soft glow trailing the line reads better than a hairline on a noisy
    // camera feed.
    canvas.drawRect(
      lineRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.accent.withValues(alpha: 0),
            AppColors.accent.withValues(alpha: 0.26),
            AppColors.accent.withValues(alpha: 0),
          ],
        ).createShader(lineRect),
    );

    canvas.drawLine(
      Offset(window.left + 10, y),
      Offset(window.right - 10, y),
      Paint()
        ..strokeWidth = 2
        ..shader = LinearGradient(
          colors: [
            AppColors.accentGlow.withValues(alpha: 0),
            AppColors.accentGlow,
            AppColors.accentGlow.withValues(alpha: 0),
          ],
        ).createShader(lineRect),
    );
  }

  void _paintCorners(Canvas canvas, Rect w) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;

    const r = _cornerRadius;
    const l = _cornerLength;
    final path = Path()
      // Top-left
      ..moveTo(w.left, w.top + r + l)
      ..lineTo(w.left, w.top + r)
      ..arcToPoint(Offset(w.left + r, w.top), radius: const Radius.circular(r))
      ..lineTo(w.left + r + l, w.top)
      // Top-right
      ..moveTo(w.right - r - l, w.top)
      ..lineTo(w.right - r, w.top)
      ..arcToPoint(Offset(w.right, w.top + r), radius: const Radius.circular(r))
      ..lineTo(w.right, w.top + r + l)
      // Bottom-right
      ..moveTo(w.right, w.bottom - r - l)
      ..lineTo(w.right, w.bottom - r)
      ..arcToPoint(
        Offset(w.right - r, w.bottom),
        radius: const Radius.circular(r),
      )
      ..lineTo(w.right - r - l, w.bottom)
      // Bottom-left
      ..moveTo(w.left + r + l, w.bottom)
      ..lineTo(w.left + r, w.bottom)
      ..arcToPoint(
        Offset(w.left, w.bottom - r),
        radius: const Radius.circular(r),
      )
      ..lineTo(w.left, w.bottom - r - l);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) =>
      oldDelegate.sweep != sweep || oldDelegate.windowSize != windowSize;
}
