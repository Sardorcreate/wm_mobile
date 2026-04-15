import 'package:flutter/material.dart';

class BuildWelcomeText extends StatelessWidget {
  final Animation<double> fade;
  final String text1;
  final String text2;

  const BuildWelcomeText({
    super.key,
    required this.fade,
    required this.text1,
    required this.text2,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text1,
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            text2,
            style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
