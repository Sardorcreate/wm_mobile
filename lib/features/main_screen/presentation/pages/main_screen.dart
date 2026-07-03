import 'package:flutter/material.dart';
import 'package:wm_mobile/features/auth/controller/auth_service.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/profile/presentation/pages/profile_screen.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/scanner/presentation/pages/scanner.dart';
import 'package:wm_mobile/features/main_screen/presentation/pages/tools/presentation/pages/tools_screen.dart';
import 'package:wm_mobile/features/main_screen/presentation/widgets/custom_header.dart';
import 'package:wm_mobile/features/splash_screen/presentation/helpers/background_orb.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  String? _token;
  bool _isLoadingToken = true;

  static const _navItems = [
    _NavItem(icon: Icons.build_rounded,            label: 'Jihozlar'),
    _NavItem(icon: Icons.qr_code_scanner_rounded, label: 'Skaner'),
    _NavItem(icon: Icons.person_rounded,           label: 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedToken();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _animationController
      ..reset()
      ..forward();
  }

  Future<void> _loadSavedToken() async {
    try {
      final savedToken = await AuthService.instance.getToken();
      setState(() {
        _token = savedToken;
        _isLoadingToken = false;
      });
    } catch (e) {
      setState(() => _isLoadingToken = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ToolsScreen(
        initialUri: Uri.parse("http://172.31.20.5:8080/exist.html")
            .replace(queryParameters: {if (_token != null) 'token': _token!}),
        authToken: _token,
      ),
      const ScannerScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0D47A1),
              Color(0xFF01579B),
            ],
          ),
        ),
        child: Stack(
          children: [
            const BackgroundOrbs(),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const CustomHeader(),
                  Expanded(
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: screens,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        items: _navItems,
        onTap: _onNavTap,
      ),
    );
  }
}

// ── Bottom nav ───────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D47A1), Color(0xFF01579B)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  splashColor: Colors.white10,
                  highlightColor: Colors.white10,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            items[i].icon,
                            color: selected
                                ? Colors.white
                                : Colors.white54,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.white54,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          child: Text(items[i].label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}