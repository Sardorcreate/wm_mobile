import 'package:flutter/material.dart';

class AnimatedLogo extends StatelessWidget {
  final Animation<double> fade;
  final Animation<double> scale;

  const AnimatedLogo({super.key, required this.fade, required this.scale});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: scale,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Image.asset("assets/images/logo.png", height: 120, width: 120),
        ),
      ),
    );
  }
}