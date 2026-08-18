import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';

class NavDestination {
  const NavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// A floating frosted nav bar with a selection pill that slides between items.
///
/// Replaces two competing implementations: a private `_BottomNav` inside
/// `main_screen.dart` and an unused `CustomNavbar`/`NavIcon` pair left over
/// from an earlier design.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const double _height = 66;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        0,
        18,
        14 + MediaQuery.viewPaddingOf(context).bottom * 0.4,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: _height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.glass(0.20), AppColors.glass(0.09)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.32),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / destinations.length;

                return Stack(
                  children: [
                    // The pill slides rather than fading in place, so the eye
                    // can follow the selection across the bar.
                    AnimatedPositioned(
                      duration: AppMotion.medium,
                      curve: AppMotion.overshoot,
                      left: itemWidth * selectedIndex,
                      top: 0,
                      bottom: 0,
                      width: itemWidth,
                      child: Center(
                        child: Container(
                          height: _height - 16,
                          width: itemWidth - 16,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.glass(0.26),
                                AppColors.accent.withValues(alpha: 0.16),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(
                              color: AppColors.accentGlow.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < destinations.length; i++)
                          Expanded(
                            child: _NavItem(
                              destination: destinations[i],
                              selected: i == selectedIndex,
                              onTap: () => onTap(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textTertiary;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        splashColor: AppColors.glass(0.08),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1.0,
              duration: AppMotion.medium,
              curve: AppMotion.overshoot,
              child: Icon(destination.icon, size: 22, color: color),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
              child: Text(destination.label),
            ),
          ],
        ),
      ),
    );
  }
}
