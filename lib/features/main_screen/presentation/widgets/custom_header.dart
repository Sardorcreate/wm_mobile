import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';
import 'package:wm_mobile/core/widgets/gradient_text.dart';

/// Shell header. Shows the time-of-day greeting on the home tab and the
/// destination name elsewhere, cross-fading between the two.
///
/// The scanner and profile tabs used to render their own `AppBar` *underneath*
/// this header, stacking two titles on top of each other.
class CustomHeader extends StatelessWidget {
  const CustomHeader({
    super.key,
    required this.title,
    this.showGreeting = false,
  });

  final String title;
  final bool showGreeting;

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Xayrli tong!';
    if (hour >= 11 && hour < 17) return 'Xayrli kun!';
    if (hour >= 17 && hour < 22) return 'Xayrli kech!';
    return 'Xayrli tun!';
  }

  @override
  Widget build(BuildContext context) {
    final headline = showGreeting ? _greeting() : title;
    final subtitle = showGreeting ? 'Omborxona boshqaruvi' : 'TuronBank';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _StatusPill(),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: AppMotion.medium,
                  switchInCurve: AppMotion.emphasized,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.35),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey<String>(headline),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GradientText(
                        headline,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _Monogram(),
        ],
      ),
    );
  }
}

/// "Online" chip with a slowly breathing indicator dot.
class _StatusPill extends StatefulWidget {
  const _StatusPill();

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.glass(0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_controller.value);
                return Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(
                          alpha: 0.25 + 0.45 * t,
                        ),
                        blurRadius: 4 + 6 * t,
                        spreadRadius: 1 * t,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'Online',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.glass(0.24), AppColors.glass(0.08)],
        ),
        border: Border.all(color: AppColors.glassBorderStrong),
      ),
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Image(
          image: AssetImage('assets/images/logo.png'),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
