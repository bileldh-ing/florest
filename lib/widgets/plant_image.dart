import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../core/assets.dart';
import '../core/theme.dart';
import 'rotating_plant.dart';

/// A top-down plant cut-out with a soft, static circular shadow beneath it.
///
/// The image fills whatever box it is given (so it works inside Hero
/// shuttles), and is decoded at [size] x devicePixelRatio. [wrapImage] lets
/// callers rotate only the leaves while the shadow stays put.
class PlantImage extends StatelessWidget {
  const PlantImage({
    super.key,
    required this.asset,
    required this.size,
    this.shadow = true,
    this.shadowColor,
    this.wrapImage,
  });

  final String asset;
  final double size;
  final bool shadow;

  /// Defaults to the deep green-black used on green surfaces; pass a lighter
  /// tint for plants sitting on white.
  final Color? shadowColor;
  final Widget Function(Widget image)? wrapImage;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final Widget image = Image(
      image: plantImageProvider(asset, size, dpr),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) =>
          PlaceholderPlant(seed: asset.hashCode),
    );
    final wrap = wrapImage;
    final leaves = wrap != null ? wrap(image) : image;
    final f = (size / 180).clamp(0.4, 1.4);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The shadow is the plant's own silhouette, tinted, blurred and
          // nudged down-left. It never rotates, so it is rasterised once and
          // cached behind its own RepaintBoundary.
          if (shadow)
            Positioned.fill(
              child: RepaintBoundary(
                child: Transform.translate(
                  offset: Offset(-7 * f, 12 * f),
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: 9 * f,
                      sigmaY: 9 * f,
                      tileMode: TileMode.decal,
                    ),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        shadowColor ?? AppColors.plantShadow,
                        BlendMode.srcIn,
                      ),
                      child: image,
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(child: leaves),
        ],
      ),
    );
  }
}

/// Hero shuttle shared by the card image and the detail plant: the plant
/// enlarges while its angle interpolates from 0 to the live idle angle, so
/// the rotation lands exactly where the detail screen's plant already is.
HeroFlightShuttleBuilder plantFlightShuttle(String asset) {
  return (flightContext, animation, direction, fromContext, toContext) {
    final idle = IdleRotation.read(flightContext);
    final size = MediaQuery.sizeOf(flightContext).width * 0.82;
    final both = Listenable.merge([animation, idle]);
    return PlantImage(
      asset: asset,
      size: size,
      wrapImage: (image) => AnimatedBuilder(
        animation: both,
        child: image,
        builder: (context, child) => Transform.rotate(
          angle: idle.value * 2 * math.pi * animation.value,
          child: child,
        ),
      ),
    );
  };
}

/// Procedural fallback: a radial leaf rosette, so the app runs even when an
/// image is missing.
class PlaceholderPlant extends StatelessWidget {
  const PlaceholderPlant({super.key, required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: RepaintBoundary(
        child: CustomPaint(painter: _LeafPainter(seed)),
      ),
    );
  }
}

class _LeafPainter extends CustomPainter {
  _LeafPainter(this.seed);

  final int seed;

  static const Color _dark = Color(0xFF2F5E35);
  static const Color _light = Color(0xFF9BC46A);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final c = size.center(Offset.zero);
    final radius = size.shortestSide / 2 * 0.92;
    final paint = Paint()..isAntiAlias = true;
    const layers = 4;
    for (var layer = 0; layer < layers; layer++) {
      final count = 7 + layer * 2;
      final len = radius * (1 - layer * 0.2);
      final width = len * (0.34 + rnd.nextDouble() * 0.1);
      final offsetAngle = rnd.nextDouble() * math.pi;
      for (var i = 0; i < count; i++) {
        final angle = offsetAngle + i * 2 * math.pi / count;
        paint.color = Color.lerp(
          _dark,
          _light,
          (layer / layers + rnd.nextDouble() * 0.15).clamp(0.0, 1.0),
        )!;
        canvas
          ..save()
          ..translate(c.dx, c.dy)
          ..rotate(angle)
          ..drawOval(
              Rect.fromLTWH(len * 0.05, -width / 2, len * 0.95, width), paint)
          ..restore();
      }
    }
    paint.color = _light;
    canvas.drawCircle(c, radius * 0.08, paint);
  }

  @override
  bool shouldRepaint(_LeafPainter oldDelegate) => oldDelegate.seed != seed;
}
