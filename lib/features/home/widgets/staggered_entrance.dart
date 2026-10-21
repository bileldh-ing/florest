import 'dart:async';

import 'package:flutter/material.dart';

/// Slides its child in from the right after [delay]. The raw 0→1 animation is
/// handed to [builder] so children can layer their own overshoot on top.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.enabled,
    required this.delay,
    required this.builder,
  });

  final bool enabled;
  final Duration delay;
  final Widget Function(BuildContext context, Animation<double> entrance) builder;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
    value: widget.enabled ? 0 : 1,
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0.4, 0), end: Offset.zero).animate(_curve);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: _slide,
        child: widget.builder(context, _c),
      ),
    );
  }
}
