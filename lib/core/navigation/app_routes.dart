import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_motion.dart';

/// Named transition styles for explicit navigation.
///
/// `MaterialPageRoute` was used everywhere, which gave the app the default
/// platform slide even for flows that are conceptually a fade (splash → home)
/// or a zoom (scan → detail).
enum AppTransition {
  /// Cross-fade with a subtle scale. Good for peer-level destinations.
  fadeThrough,

  /// Slides in from the right while the old page drifts left and dims.
  sharedAxis,

  /// Grows from 92%. Good for content opened *from* something on screen.
  zoom,

  /// Rises from the bottom. Good for modal-feeling full screens.
  slideUp,
}

/// Builds a [PageRoute] with one of the app's shared transitions.
Route<T> appRoute<T>(
  Widget page, {
  AppTransition transition = AppTransition.fadeThrough,
  Duration? duration,
  RouteSettings? settings,
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: duration ?? AppMotion.slow,
    reverseTransitionDuration: AppMotion.medium,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final enter = CurvedAnimation(
        parent: animation,
        curve: AppMotion.emphasized,
        reverseCurve: AppMotion.exit,
      );
      final exit = CurvedAnimation(
        parent: secondaryAnimation,
        curve: AppMotion.emphasized,
        reverseCurve: AppMotion.exit,
      );

      switch (transition) {
        case AppTransition.fadeThrough:
          return FadeTransition(
            opacity: enter,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(enter),
              child: child,
            ),
          );

        case AppTransition.sharedAxis:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.22, 0),
              end: Offset.zero,
            ).animate(enter),
            child: FadeTransition(
              opacity: enter,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset.zero,
                  end: const Offset(-0.12, 0),
                ).animate(exit),
                child: child,
              ),
            ),
          );

        case AppTransition.zoom:
          return FadeTransition(
            opacity: enter,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.86, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: AppMotion.overshoot),
              ),
              child: child,
            ),
          );

        case AppTransition.slideUp:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(enter),
            child: FadeTransition(opacity: enter, child: child),
          );
      }
    },
  );
}
