import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../state/providers.dart';

/// All / Outdoor / Indoor with a count badge above each label.
class FilterTabs extends ConsumerWidget {
  const FilterTabs({super.key, required this.scale, required this.onSelect});

  final double scale;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(filterProvider);
    final counts = ref.watch(filterCountsProvider);
    final s = scale;
    // Transparent: the badges sit half on the green header, half on white.
    return Padding(
      padding: EdgeInsets.fromLTRB(26 * s, 14 * s, 26 * s, 6 * s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final f in PlantFilter.values)
            // Flexible + scaleDown keeps the row intact on narrow phones and
            // with large accessibility text.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: switch (f) {
                  PlantFilter.all => Alignment.bottomLeft,
                  PlantFilter.outdoor => Alignment.bottomCenter,
                  PlantFilter.indoor => Alignment.bottomRight,
                },
                child: _Tab(
                  label: f.label,
                  count: counts[f] ?? 0,
                  active: f == selected,
                  scale: s,
                  onTap: () => onSelect(f.index),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.active,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final badge = 24 * s;
    return Semantics(
      button: true,
      selected: active,
      label: '$label, $count plants',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 2 * s),
                child: AnimatedScale(
                  scale: active ? 1 : 0.88,
                  duration: AppDurations.medium,
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: AppDurations.medium,
                    curve: Curves.easeOutCubic,
                    width: badge,
                    height: badge,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.ink : AppColors.inactiveBadge,
                      shape: BoxShape.circle,
                    ),
                    child: Text('$count', style: AppText.badge(s)),
                  ),
                ),
              ),
              SizedBox(height: 10 * s),
              AnimatedDefaultTextStyle(
                duration: AppDurations.medium,
                curve: Curves.easeOutCubic,
                style: AppText.tab(s).copyWith(
                  color: active ? AppColors.ink : AppColors.inactiveGrey,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
