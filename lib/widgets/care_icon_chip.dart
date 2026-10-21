import 'package:flutter/material.dart';

import '../core/theme.dart';

enum CareKind {
  water(Icons.water_drop_outlined, 'Water'),
  temperature(Icons.thermostat_outlined, 'Temperature'),
  light(Icons.wb_sunny_outlined, 'Light');

  const CareKind(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Outlined rounded-square chip (36x36, radius 12 at baseline).
class CareIconChip extends StatelessWidget {
  const CareIconChip({super.key, required this.kind, this.size = 36});

  final CareKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: kind.label,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.chip * size / 36),
          border: Border.all(color: AppColors.iconOutline, width: 1.3),
        ),
        child: Icon(kind.icon, size: size * 0.44, color: AppColors.cream),
      ),
    );
  }
}

/// The water / temperature / light trio.
class CareChipsRow extends StatelessWidget {
  const CareChipsRow({super.key, this.size = 36, this.gap = 8});

  final double size;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CareIconChip(kind: CareKind.water, size: size),
        SizedBox(width: gap),
        CareIconChip(kind: CareKind.temperature, size: size),
        SizedBox(width: gap),
        CareIconChip(kind: CareKind.light, size: size),
      ],
    );
  }
}
