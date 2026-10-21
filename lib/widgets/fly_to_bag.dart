import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import 'plant_image.dart';

/// Flies a plant thumbnail along a quadratic Bézier arc from [from] (global
/// rect) to the centre of [target]. Completes when it lands.
Future<void> flyToBag({
  required BuildContext context,
  required String asset,
  required Rect from,
  required GlobalKey target,
}) {
  final box = target.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize || from.isEmpty) return Future.value();
  final to = box.localToGlobal(box.size.center(Offset.zero));
  final overlay = Overlay.of(context);
  final completer = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Flyer(
      asset: asset,
      from: from,
      to: to,
      onDone: () {
        entry.remove();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );
  overlay.insert(entry);
  return completer.future;
}

class _Flyer extends StatefulWidget {
  const _Flyer({
    required this.asset,
    required this.from,
    required this.to,
    required this.onDone,
  });

  final String asset;
  final Rect from;
  final Offset to;
  final VoidCallback onDone;

  @override
  State<_Flyer> createState() => _FlyerState();
}

class _FlyerState extends State<_Flyer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p0 = widget.from.center;
    final p2 = widget.to;
    final p1 = Offset((p0.dx + p2.dx) / 2, math.min(p0.dy, p2.dy) - 140);
    final startSize = widget.from.width;
    final image =
        PlantImage(asset: widget.asset, size: startSize, shadow: false);

    return IgnorePointer(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _c,
            child: image,
            builder: (context, child) {
              final t = Curves.easeInOutCubic.transform(_c.value);
              final u = 1 - t;
              final p = p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
              final size = lerpDouble(startSize, 20, t)!;
              return Positioned(
                left: p.dx - size / 2,
                top: p.dy - size / 2,
                width: size,
                height: size,
                child: Transform.rotate(angle: t * math.pi, child: child),
              );
            },
          ),
        ],
      ),
    );
  }
}
