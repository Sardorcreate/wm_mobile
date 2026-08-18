import 'package:flutter/material.dart';

import 'package:wm_mobile/core/theme/app_motion.dart';

/// Fades and lifts its child into place once, [delay] after first build.
///
/// Screens previously threaded `Animation` objects (`fade`, `slide`) down
/// through three widget layers just to animate an entrance.
/// This makes an entrance a local concern: wrap and go.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.slow,
    this.offset = const Offset(0, 0.14),
    this.curve = AppMotion.emphasized,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Starting offset, as a fraction of the child's own size.
  final Offset offset;
  final Curve curve;

  /// Convenience for lists: staggers item [index] by [AppMotion.stagger].
  factory Entrance.staggered({
    Key? key,
    required int index,
    required Widget child,
    Duration base = Duration.zero,
    Offset offset = const Offset(0, 0.14),
  }) {
    return Entrance(
      key: key,
      delay: base + AppMotion.stagger * index,
      offset: offset,
      child: child,
    );
  }

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: widget.offset,
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
