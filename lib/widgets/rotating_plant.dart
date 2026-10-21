import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Owns the single AnimationController (1 turn / 60 s) behind every idle
/// plant rotation. Stops when the OS asks for reduced motion.
class IdleRotationScope extends StatefulWidget {
  const IdleRotationScope({super.key, required this.child});

  final Widget child;

  @override
  State<IdleRotationScope> createState() => _IdleRotationScopeState();
}

class _IdleRotationScopeState extends State<IdleRotationScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _IdleRotationInherited(animation: _controller, child: widget.child);
}

class _IdleRotationInherited extends InheritedWidget {
  const _IdleRotationInherited({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_IdleRotationInherited oldWidget) =>
      animation != oldWidget.animation;
}

abstract final class IdleRotation {
  /// The shared 0→1 (one turn) animation.
  static Animation<double> of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_IdleRotationInherited>()
          ?.animation ??
      kAlwaysCompleteAnimation;

  /// Same as [of] without registering a dependency (for callbacks).
  static Animation<double> read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_IdleRotationInherited>()?.animation ??
      kAlwaysCompleteAnimation;
}

/// Rotates [child] with the shared idle clock, plus an optional user-driven
/// angle (radians). Optionally "breathes" 1.00 → 1.02.
class RotatingPlant extends StatelessWidget {
  const RotatingPlant({
    super.key,
    required this.child,
    this.breathe = false,
    this.extraAngle,
  });

  final Widget child;
  final bool breathe;
  final ValueListenable<double>? extraAngle;

  @override
  Widget build(BuildContext context) {
    final idle = IdleRotation.of(context);
    final extra = extraAngle;
    final listenable = extra == null ? idle : Listenable.merge([idle, extra]);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: listenable,
        child: child,
        builder: (context, child) {
          final t = idle.value;
          final angle = t * 2 * math.pi + (extra?.value ?? 0);
          final scale =
              breathe ? 1.01 + 0.01 * math.sin(t * 2 * math.pi * 15) : 1.0;
          return Transform.scale(
            scale: scale,
            child: Transform.rotate(angle: angle, child: child),
          );
        },
      ),
    );
  }
}
