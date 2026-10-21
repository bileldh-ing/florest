import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../features/bag/bag_sheet.dart';
import '../state/providers.dart';
import 'line_icon.dart';
import 'round_icon_button.dart';

/// Translucent bag button with a count badge that bumps (elastic) whenever
/// the bag grows. [anchorKey] marks the fly-to-bag target.
class BagButton extends ConsumerStatefulWidget {
  const BagButton({super.key, required this.anchorKey, this.scale = 1});

  final GlobalKey anchorKey;
  final double scale;

  @override
  ConsumerState<BagButton> createState() => _BagButtonState();
}

class _BagButtonState extends ConsumerState<BagButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: 1,
  );

  late final Animation<double> _badgeScale = Tween<double>(begin: 1.7, end: 1)
      .animate(CurvedAnimation(parent: _bump, curve: Curves.elasticOut));

  late final Animation<double> _iconScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1.12), weight: 25),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.12, end: 1)
          .chain(CurveTween(curve: Curves.elasticOut)),
      weight: 75,
    ),
  ]).animate(_bump);

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(bagCountProvider, (previous, next) {
      if (next > (previous ?? 0)) _bump.forward(from: 0);
    });
    final count = ref.watch(bagCountProvider);
    final s = widget.scale;

    return ScaleTransition(
      scale: _iconScale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RoundIconButton(
            key: widget.anchorKey,
            icon: LineGlyph.bag,
            semanticLabel: 'Bag, $count items',
            filled: true,
            scale: s,
            onTap: () => showBagSheet(context),
          ),
          if (count > 0)
            Positioned(
              right: 2 * s,
              top: 2 * s,
              child: IgnorePointer(
                child: ScaleTransition(
                  scale: _badgeScale,
                  child: Container(
                    height: 18 * s,
                    constraints: BoxConstraints(minWidth: 18 * s),
                    padding: EdgeInsets.symmetric(horizontal: 5 * s),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(9 * s),
                    ),
                    child: Text('$count', style: AppText.bagBadge(s)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
