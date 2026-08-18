import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';

/// Paints [text] with a gradient instead of a flat colour.
///
/// The [style]'s colour is ignored — the shader replaces it — but the rest of
/// the style (size, weight, spacing) applies as usual.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final Gradient? gradient;
  final TextAlign? textAlign;

  static const Gradient _default = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, AppColors.accentGlow],
  );

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          (gradient ?? _default).createShader(Offset.zero & bounds.size),
      child: Text(
        text,
        textAlign: textAlign,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}
