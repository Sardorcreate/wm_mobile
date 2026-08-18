import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';

/// A soft light that breathes behind its child.
///
/// The logo previously sat on a static `BoxShadow`, which on a dark gradient
/// read as nothing at all.
class PulsingHalo extends StatefulWidget {
  const PulsingHalo({super.key, required this.child});

  final Widget child;

  @override
  State<PulsingHalo> createState() => _PulsingHaloState();
}

class _PulsingHaloState extends State<PulsingHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  late final Animation<double> _pulse = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = _pulse.value;
              return Container(
                width: 210 + 26 * t,
                height: 210 + 26 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentGlow.withValues(alpha: 0.16 + 0.10 * t),
                      AppColors.accent.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(padding: const EdgeInsets.all(20), child: widget.child),
      ],
    );
  }
}
