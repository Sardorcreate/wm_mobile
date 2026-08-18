import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_gradients.dart';

/// A frosted, gradient-filled surface — the app's one card primitive.
///
/// Blur is genuinely expensive, so [blur] can be dialled to 0 to get the same
/// look without a `BackdropFilter` layer (used for list rows, where a dozen
/// blurred layers would cost more than they're worth).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.radius = 24,
    this.blur = 14,
    this.gradient,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final double blur;
  final Gradient? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.glass,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? AppColors.glassBorder),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      surface = Stack(
        children: [
          surface,
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                splashColor: AppColors.glass(0.10),
                highlightColor: AppColors.glass(0.06),
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: blur > 0
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: surface,
              )
            : surface,
      ),
    );
  }
}
