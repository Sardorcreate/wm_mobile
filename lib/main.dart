import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wm_mobile/features/splash_screen/presentation/pages/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(WMApp());
}

class WMApp extends StatelessWidget {
  const WMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Warehouse Management',
      home: SplashScreen(),
    );
  }
}
