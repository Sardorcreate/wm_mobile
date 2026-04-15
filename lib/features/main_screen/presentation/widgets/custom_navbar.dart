import 'package:flutter/material.dart';
import 'package:wm_mobile/features/main_screen/presentation/widgets/nav_icon.dart';

class CustomNavbar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const CustomNavbar({
    super.key,
    required this.selectedIndex,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 14,
          unselectedFontSize: 13,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withValues(alpha: 0.6),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          items: [
            BottomNavigationBarItem(
              icon: NavIcon(icon: Icons.perm_device_info_rounded, isActive: false),
              activeIcon: NavIcon(icon: Icons.perm_device_info_rounded, isActive: true),
              label: "Qurilma ma'lumoti",
            ),
            BottomNavigationBarItem(
              icon: NavIcon(icon: Icons.qr_code_scanner_rounded, isActive: false, isCenter: true),
              activeIcon: NavIcon(icon: Icons.qr_code_scanner_rounded, isActive: true, isCenter: true),
              label: "Skaner",
            ),
            BottomNavigationBarItem(
              icon: NavIcon(icon: Icons.settings_rounded, isActive: false),
              activeIcon: NavIcon(icon: Icons.settings_rounded, isActive: true),
              label: "Sozlamalar",
            ),
          ],
        ),
      ),
    );
  }
}
