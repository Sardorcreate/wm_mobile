import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';
import 'package:wm_mobile/core/widgets/gradient_text.dart';
import 'pulsing_halo.dart';

/// The splash layout, driven entirely by one parent controller through
/// [Interval]s. Previously each element owned its own animation objects that
/// were threaded down as constructor parameters.
class SplashContent extends StatelessWidget {
  const SplashContent({super.key, required this.controller});

  final AnimationController controller;

  Animation<double> _fade(double begin, double end) => CurvedAnimation(
    parent: controller,
    curve: Interval(begin, end, curve: Curves.easeOut),
  );

  Animation<double> _curve(double begin, double end, Curve curve) =>
      CurvedAnimation(
        parent: controller,
        curve: Interval(begin, end, curve: curve),
      );

  @override
  Widget build(BuildContext context) {
    final logoFade = _fade(0.0, 0.45);
    final logoScale = Tween<double>(
      begin: 0.72,
      end: 1.0,
    ).animate(_curve(0.0, 0.6, AppMotion.overshoot));
    final titleFade = _fade(0.30, 0.70);
    final titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(_curve(0.30, 0.80, AppMotion.emphasized));
    final underline = _curve(0.55, 0.95, AppMotion.emphasized);
    final footerFade = _fade(0.60, 1.0);

    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: logoFade,
                child: ScaleTransition(
                  scale: logoScale,
                  child: const PulsingHalo(
                    child: Image(
                      image: AssetImage('assets/images/logo.png'),
                      height: 120,
                      width: 120,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              SlideTransition(
                position: titleSlide,
                child: FadeTransition(
                  opacity: titleFade,
                  child: Column(
                    children: [
                      const GradientText(
                        'TuronBank',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GrowingUnderline(progress: underline),
                      const SizedBox(height: 12),
                      Text(
                        'Omborxona boshqaruvi',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 48,
          child: FadeTransition(
            opacity: footerFade,
            child: Column(
              children: [
                const _IndeterminateBar(),
                const SizedBox(height: 22),
                Text(
                  '© Copyright TuronBank 2026. All rights reserved',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A rule that draws itself out from the centre as the intro plays.
class _GrowingUnderline extends StatelessWidget {
  const _GrowingUnderline({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) => Container(
        width: 20 + 70 * progress.value,
        height: 2.5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            colors: [
              Color(0x00FFFFFF),
              AppColors.accentGlow,
              Color(0x00FFFFFF),
            ],
          ),
        ),
      ),
    );
  }
}

/// A slim looping progress bar. The old splash used a
/// `CircularProgressIndicator` driven by a 3-second tween, which implied a
/// determinate amount of work that the app was not actually tracking.
class _IndeterminateBar extends StatefulWidget {
  const _IndeterminateBar();

  @override
  State<_IndeterminateBar> createState() => _IndeterminateBarState();
}

class _IndeterminateBarState extends State<_IndeterminateBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 3,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: ColoredBox(
            color: AppColors.glass(0.14),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_controller.value);
                return Align(
                  alignment: Alignment(-1.0 + 2.6 * t, 0),
                  child: FractionallySizedBox(
                    widthFactor: 0.4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0x00FFFFFF),
                            Colors.white,
                            Color(0x00FFFFFF),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
