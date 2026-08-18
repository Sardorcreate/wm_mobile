import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_motion.dart';

/// Shrinks its child while pressed.
///
/// The app's custom surfaces (gradient buttons, nav pills, glass cards) sit
/// outside Material's ink system, so without this they gave no touch feedback
/// at all.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  bool get _active => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (!_active || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _active ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}
