import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Green hero block. Driven by the list's scroll offset:
///  * collapse: header shrinks, plant drifts up at half speed and fades,
///    "Top picks" fades/shrinks while a compact title appears in the top bar;
///  * pull-down: header stretches, plant lags behind the text (parallax).
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.height,
    required this.expandedHeight,
    required this.progress,
    required this.stretch,
    required this.scale,
    required this.topInset,
    required this.width,
    required this.enter,
    required this.plant,
    required this.topBar,
  });

  final double height;
  final double expandedHeight;

  /// 0 = expanded, 1 = fully collapsed.
  final double progress;

  /// Overscroll distance when pulling down (>= 0).
  final double stretch;
  final double scale;
  final double topInset;
  final double width;

  /// Entrance animation (0→1) played once on first build.
  final Animation<double> enter;
  final Widget plant;
  final Widget topBar;

  static double plantSizeFor(double width) => width * 0.51;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final w = width;
    final plantSize = plantSizeFor(w);
    final shrink = math.max(0.0, expandedHeight - height);
    final baseTop = topInset + 58 * s;
    final plantTop = baseTop - shrink * 0.5 + stretch * 0.35;
    final plantScale = (1 - progress * 0.25) * (1 + stretch / 900);
    final plantOpacity = (1 - progress * 1.25).clamp(0.0, 1.0);
    final titleOpacity = (1 - progress * 1.6).clamp(0.0, 1.0);
    final titleScale = 1 - progress * 0.4;
    final miniOpacity = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius:
          BorderRadius.only(bottomRight: Radius.circular(AppRadii.header * s)),
      child: SizedBox(
        height: height,
        width: w,
        child: ColoredBox(
          color: AppColors.green,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: plantTop,
                right: w * 0.05,
                width: plantSize,
                height: plantSize,
                child: Opacity(
                  opacity: plantOpacity,
                  child: Transform.scale(
                    scale: plantScale,
                    child: _EnterPlant(enter: enter, child: plant),
                  ),
                ),
              ),
              Positioned(
                left: w * 0.066,
                bottom: 58 * s,
                child: Opacity(
                  opacity: titleOpacity,
                  child: Transform.scale(
                    scale: titleScale,
                    alignment: Alignment.bottomLeft,
                    child: _MaskReveal(
                      enter: enter,
                      child: Semantics(
                        header: true,
                        child: Text('Top\npicks', style: AppText.heroTitle(s)),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: topInset,
                left: 0,
                right: 0,
                height: 72 * s,
                child: IgnorePointer(
                  child: Center(
                    child: Opacity(
                      opacity: miniOpacity,
                      child: Text('Top picks', style: AppText.miniTitle(s)),
                    ),
                  ),
                ),
              ),
              Positioned(
                  top: topInset,
                  left: 0,
                  right: 0,
                  height: 72 * s,
                  child: topBar),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plant scales 0.85→1, rotates -8°→0 and fades in.
class _EnterPlant extends StatelessWidget {
  const _EnterPlant({required this.enter, required this.child});

  final Animation<double> enter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: enter,
      child: child,
      builder: (context, child) {
        final t =
            Curves.easeOutCubic.transform((enter.value / 0.75).clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: Transform.rotate(
            angle: (1 - t) * -8 * math.pi / 180,
            child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
          ),
        );
      },
    );
  }
}

/// Text slides up from behind a clip edge.
class _MaskReveal extends StatelessWidget {
  const _MaskReveal({required this.enter, required this.child});

  final Animation<double> enter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: enter,
        child: child,
        builder: (context, child) {
          final t = Curves.easeOutCubic
              .transform(((enter.value - 0.25) / 0.75).clamp(0.0, 1.0));
          return FractionalTranslation(
              translation: Offset(0, 1 - t), child: child);
        },
      ),
    );
  }
}
