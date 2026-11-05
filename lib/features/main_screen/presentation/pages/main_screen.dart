import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_motion.dart';
import 'package:wm_mobile/features/main_screen/presentation/widgets/app_nav_bar.dart';
import 'package:wm_mobile/features/main_screen/presentation/widgets/custom_header.dart';
import 'profile/presentation/pages/profile_screen.dart';
import 'scanner/presentation/pages/scanner.dart';
import 'tools/presentation/pages/tools_screen.dart';

/// Tab shell. The three destinations are kept alive in an [IndexedStack].
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  static const List<NavDestination> _destinations = [
    NavDestination(icon: Icons.grid_view_rounded, label: 'Jihozlar'),
    NavDestination(icon: Icons.qr_code_scanner_rounded, label: 'Skaner'),
    NavDestination(icon: Icons.person_rounded, label: 'Profil'),
  ];

  int _selectedIndex = 0;

  /// Direction of the last tab change; drives which way content slides in.
  int _direction = 1;

  late final AnimationController _switchController = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  )..value = 1;

  @override
  void dispose() {
    _switchController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _direction = index > _selectedIndex ? 1 : -1;
      _selectedIndex = index;
    });
    _switchController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomHeader(
              title: _destinations[_selectedIndex].label,
              showGreeting: _selectedIndex == 0,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: AppNavBar(
        destinations: _destinations,
        selectedIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildBody() {
    final enter = CurvedAnimation(
      parent: _switchController,
      curve: AppMotion.emphasized,
    );

    // IndexedStack keeps every tab's state (scroll position, search results)
    // while the transition animates only the visible one. The scanner is told
    // when it is off-screen so it can release the camera instead of burning
    // battery behind the other tabs.
    return FadeTransition(
      opacity: enter,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0.05 * _direction, 0),
          end: Offset.zero,
        ).animate(enter),
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            const ToolsScreen(),
            ScannerScreen(isActive: _selectedIndex == 1),
            const ProfileScreen(),
          ],
        ),
      ),
    );
  }
}
