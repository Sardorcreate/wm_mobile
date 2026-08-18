import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';
import 'press_scale.dart';

enum ButtonVariant {
  /// Solid white-to-ice pill on the blue background. The main call to action.
  primary,

  /// Frosted fill. Secondary actions that still belong to the flow.
  glass,

  /// Outlined red. Destructive actions.
  danger,
}

/// The app's single button. Handles loading, press feedback, an optional icon
/// and a slow sheen sweep that keeps the primary CTA from looking like a flat
/// rectangle.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ButtonVariant variant;
  final bool expand;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  bool get _sheenEnabled =>
      widget.variant == ButtonVariant.primary &&
      !widget.isLoading &&
      widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    if (_sheenEnabled) _sheen.repeat();
  }

  @override
  void didUpdateWidget(GradientButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sheenEnabled && !_sheen.isAnimating) {
      _sheen.repeat();
    } else if (!_sheenEnabled && _sheen.isAnimating) {
      _sheen
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  bool get _disabled => widget.isLoading || widget.onPressed == null;

  Color get _foreground => switch (widget.variant) {
    ButtonVariant.primary => AppColors.indigo,
    ButtonVariant.glass => AppColors.textPrimary,
    ButtonVariant.danger => AppColors.danger,
  };

  BoxDecoration get _decoration => switch (widget.variant) {
    ButtonVariant.primary => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFDCEBFB)],
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: AppColors.accentGlow.withValues(alpha: 0.28),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    ButtonVariant.glass => BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.glass(0.22), AppColors.glass(0.10)],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.glassBorderStrong),
    ),
    ButtonVariant.danger => BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.65)),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: _disabled ? null : widget.onPressed,
      child: AnimatedOpacity(
        opacity: _disabled ? 0.72 : 1.0,
        duration: AppMotion.fast,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: _decoration,
            child: Stack(
              children: [
                if (_sheenEnabled)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _sheen,
                          builder: (context, _) =>
                              CustomPaint(painter: _SheenPainter(_sheen.value)),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 17,
                    horizontal: 24,
                  ),
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final content = widget.isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: _foreground,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 19, color: _foreground),
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: _foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          );

    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.emphasized,
      child: SizedBox(
        width: widget.expand ? double.infinity : null,
        child: Center(child: content),
      ),
    );
  }
}

/// A diagonal highlight that sweeps across the button, pausing between passes.
class _SheenPainter extends CustomPainter {
  const _SheenPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Sweep during the first 45% of the loop, rest for the remainder.
    final progress = (t / 0.45).clamp(0.0, 1.0);
    if (progress >= 1.0) return;

    final width = size.width;
    final x = -width * 0.5 + progress * width * 1.8;

    final rect = Rect.fromLTWH(x, 0, width * 0.42, size.height);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0x00FFFFFF), Color(0x66FFFFFF), Color(0x00FFFFFF)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SheenPainter oldDelegate) => oldDelegate.t != t;
}
