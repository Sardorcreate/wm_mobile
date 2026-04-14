import 'package:flutter/material.dart';
import 'package:wm_mobile/features/splash_screen/presentation/helpers/underline.dart';

class AnimatedTitle extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;

  const AnimatedTitle({super.key, required this.fade, required this.slide});

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: fade,
        child: const Column(
          children: [
            Text(
              "TuronBank",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8),
            Underline(),
            SizedBox(height: 8),
            Text(
              "Omborxona boshqaruvi",
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}