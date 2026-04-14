import 'package:flutter/material.dart';

class Underline extends StatelessWidget {
  const Underline({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 2,
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}