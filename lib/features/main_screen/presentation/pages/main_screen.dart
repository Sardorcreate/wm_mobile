import 'package:flutter/material.dart';

import 'package:wm_mobile/core/config/app_config.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';
import 'package:wm_mobile/features/main_screen/presentation/widgets/app_nav_bar.dart';
import 'package:wm_mobile/features/main_screen/presentation/widgets/custom_header.dart';
import 'profile/presentation/pages/profile_screen.dart';
import 'scanner/presentation/pages/scanner.dart';
import 'tools/presentation/pages/tools_screen.dart';

/// Tab shell.
///
/// The three destinations are built once, after the token resolves, and then
/// kept alive in an [IndexedStack]. The old version rebuilt the list — and with
/// it a fresh `Uri` for the WebView — on every `setState`, which re-triggered
/// WebView work on each tab change.
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

  bool _tokenResolved = false;
  String? _token;

  /// Built once so the WebView is never handed a new `Uri` instance.
  Uri? _toolsUri;

  late final AnimationController _switchController = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  )..value = 1;

  @override
  void initState() {
    super.initState();
    _buildScreens();
  }

  @override
  void dispose() {
    _switchController.dispose();
    super.dispose();
  }

  Future<void> _buildScreens() async {
    String? token;
    try {
      token = await AuthService.instance.getToken();
    } catch (_) {
      token = null;
    }

    if (!mounted) return;

    setState(() {
      _tokenResolved = true;
      _token = token;
      _toolsUri = AppConfig.toolsUri(token: token);
    });
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
    if (!_tokenResolved) {
      return const Center(
        child: SizedBox(
          height: 32,
          width: 32,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    final enter = CurvedAnimation(
      parent: _switchController,
      curve: AppMotion.emphasized,
    );

    // IndexedStack keeps every tab's state (scroll position, WebView history)
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
            ToolsScreen(initialUri: _toolsUri!, authToken: _token),
            ScannerScreen(isActive: _selectedIndex == 1),
            const ProfileScreen(),
          ],
        ),
      ),
    );
  }
}
