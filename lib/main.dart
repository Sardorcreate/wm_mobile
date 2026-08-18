import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/animated_background.dart';
import 'features/splash_screen/presentation/pages/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const WMApp());
}

class WMApp extends StatelessWidget {
  const WMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Warehouse Management',
      theme: AppTheme.dark,
      // The gradient backdrop lives *outside* the Navigator: one animation
      // controller for the whole app instead of one per screen, and the
      // background no longer cross-fades with itself during page transitions.
      builder: (context, child) =>
          AnimatedBackground(child: child ?? const SizedBox.shrink()),
      home: const SplashScreen(),
    );
  }
}
