import 'package:flutter/material.dart';
import 'package:wm_mobile/features/splash_screen/presentation/helpers/orb.dart';

class BackgroundOrbs extends StatelessWidget {
  const BackgroundOrbs({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Orb(top: -50, right: -50, size: 200, color: Colors.white10),
        Orb(bottom: -80, left: -80, size: 300, color: Colors.white12),
        Orb(top: 200, left: -30, size: 150, color: Colors.cyan.withValues(alpha: 0.05)),
      ],
    );
  }
}