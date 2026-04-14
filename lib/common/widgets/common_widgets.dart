import 'package:flutter/material.dart';

class CommonWidgets {

  static BoxDecoration buildBackgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFF01579B)],
      ),
    );
  }
}