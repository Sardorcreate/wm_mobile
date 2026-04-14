import 'package:flutter/material.dart';
import 'package:wm_mobile/common/functions/helper_functions.dart';

class BuildOptionsRow extends StatelessWidget {
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;
  final BuildContext context;

  const BuildOptionsRow({
    super.key,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: rememberMe,
              onChanged: onRememberMeChanged,
              fillColor: WidgetStateProperty.all(Colors.white),
              checkColor: const Color(0xFF0D47A1),
            ),
            Text("Remember me", style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          ],
        ),
        TextButton(
          onPressed: () => HelperFunctions.showSnackBar('Coming soon!', Colors.orange, context),
          child: const Text("Forgot Password?", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
