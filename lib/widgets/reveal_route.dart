import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Page route whose page grows out of [center] (global tap point) as a
/// circular reveal, and shrinks back into it on pop. Hero flights run above
/// the clip, so the plant flies freely.
class RevealRoute<T> extends PageRouteBuilder<T> {
  RevealRoute({required this.center, required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 560),
          reverseTransitionDuration: const Duration(milliseconds: 460),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return AnimatedBuilder(
              animation: curved,
              child: child,
              builder: (context, child) {
                final done = curved.value >= 1;
                return ClipPath(
                  clipper:
                      done ? null : _CircleRevealClipper(center, curved.value),
                  clipBehavior: done ? Clip.none : Clip.antiAlias,
                  child: child,
                );
              },
            );
          },
        );

  final Offset center;
}

class _CircleRevealClipper extends CustomClipper<Path> {
  _CircleRevealClipper(this.center, this.fraction);

  final Offset center;
  final double fraction;

  @override
  Path getClip(Size size) {
    var maxR = 0.0;
    for (final corner in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      maxR = math.max(maxR, (corner - center).distance);
    }
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: maxR * fraction));
  }

  @override
  bool shouldReclip(_CircleRevealClipper oldClipper) =>
      oldClipper.fraction != fraction || oldClipper.center != center;
}
