import 'package:flutter/material.dart';

class NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isCenter;

  const NavIcon({
    super.key,
    required this.icon,
    required this.isActive,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(isActive ? 14 : 10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive
            ? LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.15),
          ],
        )
            : null,
        boxShadow: isActive
            ? [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ]
            : null,
      ),
      child: Icon(
        icon,
        size: isCenter ? (isActive ? 34 : 30) : (isActive ? 28 : 24),
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
      ),
    );
  }
}
