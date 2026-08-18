import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_gradients.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';

/// The app's signature backdrop: the brand gradient plus slow-drifting light
/// orbs.
///
/// Replaces the old static `BackgroundOrbs` + per-screen gradient `Container`
/// pairs. Every screen now gets an identical, animated shell from one widget.
///
/// The orb layer sits inside a [RepaintBoundary] so the ambient animation never
/// repaints the page content on top of it.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({
    super.key,
    required this.child,
    this.gradient,
    this.animate = true,
  });

  final Widget child;

  /// Defaults to [AppGradients.background].
  final Gradient? gradient;

  /// Set false on screens where the camera or a WebView owns the frame budget.
  final bool animate;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.ambient,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(AnimatedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: widget.gradient ?? AppGradients.background,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) =>
                    CustomPaint(painter: _OrbPainter(_controller.value)),
              ),
            ),
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

/// Paints the drifting orbs directly instead of stacking positioned
/// `Container`s — one painter, one layer, no layout passes.
class _OrbPainter extends CustomPainter {
  _OrbPainter(this.t);

  /// Loop position, 0..1.
  final double t;

  static const List<_Orb> _orbs = [
    _Orb(anchor: Alignment(1.05, -0.95), radius: 0.42, drift: 0.06, phase: 0.0),
    _Orb(anchor: Alignment(-1.1, 1.0), radius: 0.62, drift: 0.05, phase: 0.35),
    _Orb(anchor: Alignment(-0.9, -0.1), radius: 0.34, drift: 0.08, phase: 0.7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final angle = t * 2 * math.pi;

    for (var i = 0; i < _orbs.length; i++) {
      final orb = _orbs[i];
      final localAngle = angle + orb.phase * 2 * math.pi;

      final center =
          orb.anchor.alongSize(size) +
          Offset(
            math.cos(localAngle) * shortest * orb.drift,
            math.sin(localAngle * 0.8) * shortest * orb.drift,
          );

      final radius = shortest * orb.radius;
      // The third orb picks up the cyan accent so the backdrop isn't a flat
      // wash of blue.
      final tint = i == 2
          ? AppColors.accent.withValues(alpha: 0.10)
          : AppColors.glass(i == 0 ? 0.075 : 0.055);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [tint, tint.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) => oldDelegate.t != t;
}

class _Orb {
  const _Orb({
    required this.anchor,
    required this.radius,
    required this.drift,
    required this.phase,
  });

  /// Resting position, in alignment space.
  final Alignment anchor;

  /// Radius as a fraction of the screen's shortest side.
  final double radius;

  /// How far it wanders, as a fraction of the shortest side.
  final double drift;

  /// Offset into the shared loop so the orbs don't move in lockstep.
  final double phase;
}
