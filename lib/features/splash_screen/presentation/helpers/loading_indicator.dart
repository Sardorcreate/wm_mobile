import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 3),
      builder: (context, value, _) => SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          value: value,
          strokeWidth: 2,
          valueColor: const AlwaysStoppedAnimation(Colors.white),
          backgroundColor: Colors.white24,
        ),
      ),
    );
  }
}