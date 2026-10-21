import 'dart:math' as math;

import 'package:flutter/widgets.dart';

abstract final class AppAssets {
  static const String plantsDir = 'assets/plants';

  /// Big bushy plant in the home hero block.
  static const String heroPlant = 'assets/plants/boxwood_ball.webp';
}

/// The one provider used for every plant image, so precache keys always match
/// what is painted: decoded at displayed size x devicePixelRatio.
ImageProvider plantImageProvider(String asset, double logicalSize, double dpr) {
  final px = math.max(1, (logicalSize * dpr).round());
  return ResizeImage(AssetImage(asset), width: px);
}

/// Decodes [asset] at [logicalSize] ahead of first paint. Errors are ignored:
/// the widget falls back to a procedural placeholder.
Future<void> precachePlant(
  BuildContext context,
  String asset,
  double logicalSize,
) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return precacheImage(
    plantImageProvider(asset, logicalSize, dpr),
    context,
    onError: (error, stackTrace) {},
  );
}
