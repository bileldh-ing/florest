import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/plant.dart';
import '../../state/providers.dart';
import '../../widgets/line_icon.dart';
import '../../widgets/plant_image.dart';

/// Opens the bag as a draggable bottom sheet.
Future<void> showBagSheet(BuildContext context) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66000000),
    builder: (_) => const BagSheet(),
  );
}

/// The bag: one row per plant with a quantity stepper, swipe to remove,
/// a live subtotal and a checkout button.
class BagSheet extends ConsumerWidget {
  const BagSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(bagLinesProvider);
    final total = ref.watch(bagTotalCentsProvider);
    final count = ref.watch(bagCountProvider);
    final mq = MediaQuery.of(context);
    final s = mq.size.width / 390;

    return Padding(
      padding: EdgeInsets.only(top: mq.padding.top + 48 * s),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.header * s),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 12 * s),
              Center(
                child: Container(
                  width: 40 * s,
                  height: 4 * s,
                  decoration: BoxDecoration(
                    color: AppColors.inactiveGrey,
                    borderRadius: BorderRadius.circular(2 * s),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(26 * s, 18 * s, 18 * s, 8 * s),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Your bag',
                        style: AppText.detailTitle(s)
                            .copyWith(color: AppColors.ink),
                      ),
                    ),
                    SizedBox(width: 10 * s),
                    Padding(
                      padding: EdgeInsets.only(bottom: 5 * s),
                      child: Text(
                        '$count ${count == 1 ? 'plant' : 'plants'}',
                        style: AppText.tab(s).copyWith(
                          fontSize: 15 * s,
                          color: AppColors.inactiveGrey,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (lines.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          ref.read(bagProvider.notifier).clear();
                        },
                        child: Text(
                          'Clear',
                          style:
                              AppText.back(s).copyWith(color: AppColors.green),
                        ),
                      ),
                  ],
                ),
              ),
              Flexible(
                child: AnimatedSize(
                  duration: AppDurations.medium,
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: lines.isEmpty
                      ? _EmptyBag(scale: s)
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(vertical: 4 * s),
                          itemCount: lines.length,
                          itemBuilder: (context, i) => _BagRow(
                            key: ValueKey<String>(lines[i].plant.id),
                            line: lines[i],
                            scale: s,
                          ),
                        ),
                ),
              ),
              if (lines.isNotEmpty) _CheckoutBar(totalCents: total, scale: s),
            ],
          ),
        ),
      ),
    );
  }
}

class _BagRow extends ConsumerWidget {
  const _BagRow({super.key, required this.line, required this.scale});

  final BagLine line;
  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = scale;
    final plant = line.plant;
    final bag = ref.read(bagProvider.notifier);

    return Dismissible(
      key: ValueKey<String>('bag-${plant.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        bag.removeAll(plant.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 28 * s),
        color: const Color(0xFFF3EFE0),
        child: LineIcon(LineGlyph.close, size: 22 * s, color: AppColors.ink),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 8 * s),
        child: Row(
          children: [
            Container(
              width: 76 * s,
              height: 76 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(22 * s),
              ),
              child: PlantImage(asset: plant.asset, size: 62 * s),
            ),
            SizedBox(width: 16 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle(s).copyWith(color: AppColors.ink),
                  ),
                  SizedBox(height: 4 * s),
                  Text(
                    plant.priceLabel,
                    style: AppText.body(s).copyWith(
                      color: AppColors.inactiveGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _Stepper(
              quantity: line.quantity,
              scale: s,
              label: plant.name,
              onMinus: () {
                HapticFeedback.selectionClick();
                bag.removeOne(plant.id);
              },
              onPlus: () {
                HapticFeedback.selectionClick();
                bag.add(plant.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.quantity,
    required this.scale,
    required this.label,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final double scale;
  final String label;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    Widget button(LineGlyph glyph, String semantic, VoidCallback onTap) {
      return Semantics(
        button: true,
        label: semantic,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox.square(
            dimension: 44 * s,
            child: Center(
              child: LineIcon(
                glyph,
                size: 18 * s,
                color: AppColors.ink,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFE0),
        borderRadius: BorderRadius.circular(16 * s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(LineGlyph.minus, 'Remove one $label', onMinus),
          AnimatedSwitcher(
            duration: AppDurations.fast,
            transitionBuilder: (child, a) =>
                ScaleTransition(scale: a, child: child),
            child: SizedBox(
              key: ValueKey<int>(quantity),
              width: 18 * s,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: AppText.cardTitle(s).copyWith(
                  color: AppColors.ink,
                  fontSize: 16 * s,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          button(LineGlyph.plus, 'Add one $label', onPlus),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.totalCents, required this.scale});

  final int totalCents;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Padding(
      padding: EdgeInsets.fromLTRB(18 * s, 12 * s, 18 * s, 18 * s),
      child: Semantics(
        button: true,
        label: 'Checkout, total ${formatPrice(totalCents)}',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Demo checkout: no payment is taken'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            height: 64 * s,
            padding: EdgeInsets.symmetric(horizontal: 24 * s),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(22 * s),
            ),
            child: Row(
              children: [
                Text(
                  'Checkout',
                  style: AppText.cardTitle(s).copyWith(fontSize: 19 * s),
                ),
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: totalCents.toDouble()),
                  duration: AppDurations.medium,
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    formatPrice(v.round()),
                    style: AppText.cardTitle(s).copyWith(
                      fontSize: 19 * s,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBag extends StatelessWidget {
  const _EmptyBag({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Padding(
      padding: EdgeInsets.fromLTRB(26 * s, 28 * s, 26 * s, 40 * s),
      child: Column(
        children: [
          Container(
            width: 84 * s,
            height: 84 * s,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
            child:
                LineIcon(LineGlyph.bag, size: 36 * s, color: AppColors.cream),
          ),
          SizedBox(height: 18 * s),
          Text(
            'Your bag is empty',
            style: AppText.cardTitle(s).copyWith(color: AppColors.ink),
          ),
          SizedBox(height: 6 * s),
          Text(
            'Tap + on any plant to add it.',
            textAlign: TextAlign.center,
            style: AppText.body(s).copyWith(color: AppColors.inactiveGrey),
          ),
        ],
      ),
    );
  }
}
