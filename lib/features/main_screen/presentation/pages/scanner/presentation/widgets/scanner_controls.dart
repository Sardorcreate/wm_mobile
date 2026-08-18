import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';
import 'package:wm_mobile/core/widgets/press_scale.dart';

/// Torch and camera-flip controls.
///
/// The scanner previously exposed neither, which made it unusable in a dim
/// warehouse aisle — the most likely place someone is scanning a QR code.
class ScannerControls extends StatelessWidget {
  const ScannerControls({super.key, required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, _) {
        final torchAvailable = state.torchState != TorchState.unavailable;
        final torchOn = state.torchState == TorchState.on;
        final canSwitch = (state.availableCameras ?? 0) > 1;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (torchAvailable)
              _ControlButton(
                icon: torchOn
                    ? Icons.flashlight_on_rounded
                    : Icons.flashlight_off_rounded,
                label: torchOn ? "Chiroq yoniq" : "Chiroq",
                active: torchOn,
                onTap: () => controller.toggleTorch(),
              ),
            if (torchAvailable && canSwitch) const SizedBox(width: 14),
            if (canSwitch)
              _ControlButton(
                icon: Icons.cameraswitch_rounded,
                label: 'Kamera',
                active: false,
                onTap: () => controller.switchCamera(),
              ),
          ],
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.22)
              : AppColors.abyss.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active
                ? AppColors.accentGlow.withValues(alpha: 0.75)
                : AppColors.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? AppColors.accentGlow : AppColors.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.accentGlow : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
