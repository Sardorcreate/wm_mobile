import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget {
  final bool showBackButton;
  final String title;
  final VoidCallback? onBack;

  const AppBarWidget({
    super.key,
    this.showBackButton = true,
    required this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: showBackButton? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            if (showBackButton)
              IconButton(
                onPressed: onBack ?? () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FractionallySizedBox(
          widthFactor: 0.75,
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
