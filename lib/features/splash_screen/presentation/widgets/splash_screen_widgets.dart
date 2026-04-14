import 'package:flutter/material.dart';
import 'package:wm_mobile/features/splash_screen/presentation/helpers/animated_logo.dart';
import 'package:wm_mobile/features/splash_screen/presentation/helpers/animated_title.dart';
import 'package:wm_mobile/features/splash_screen/presentation/helpers/loading_indicator.dart';

class SplashScreenWidgets {

  static Widget buildMainContent(Animation<double> fade, Animation<double> scale, Animation<Offset> slide) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedLogo(fade: fade, scale: scale),
          const SizedBox(height: 30),
          AnimatedTitle(fade: fade, slide: slide),
        ],
      ),
    );
  }

  static Widget buildFooter(Animation<double> fade) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: fade,
        child: const Column(
          children: [
            LoadingIndicator(),
            SizedBox(height: 20),
            Text(
              "© Copyright TuronBank 2026. All rights reserved",
              style: TextStyle(fontSize: 12, color: Colors.white54, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}