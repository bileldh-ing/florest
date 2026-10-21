import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/plant.dart';
import '../../../widgets/care_icon_chip.dart';
import '../../../widgets/plant_image.dart';

/// Quick-peek care info shown on long press.
class CareSheet extends StatelessWidget {
  const CareSheet({super.key, required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.all(12 * s),
        padding: EdgeInsets.fromLTRB(22 * s, 12 * s, 22 * s, 22 * s),
        decoration: BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.circular(AppRadii.card * s),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40 * s,
                height: 4 * s,
                decoration: BoxDecoration(
                  color: AppColors.iconOutline,
                  borderRadius: BorderRadius.circular(2 * s),
                ),
              ),
            ),
            SizedBox(height: 16 * s),
            Row(
              children: [
                PlantImage(asset: plant.asset, size: 64 * s),
                SizedBox(width: 16 * s),
                Expanded(
                  child: Text(plant.name,
                      style: AppText.cardTitle(s).copyWith(fontSize: 22 * s)),
                ),
              ],
            ),
            SizedBox(height: 18 * s),
            _CareRow(kind: CareKind.water, value: plant.water, scale: s),
            _CareRow(
                kind: CareKind.temperature, value: plant.temperature, scale: s),
            _CareRow(kind: CareKind.light, value: plant.light, scale: s),
          ],
        ),
      ),
    );
  }
}

class _CareRow extends StatelessWidget {
  const _CareRow(
      {required this.kind, required this.value, required this.scale});

  final CareKind kind;
  final String value;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * s),
      child: Row(
        children: [
          CareIconChip(kind: kind, size: 40 * s),
          SizedBox(width: 14 * s),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kind.label, style: AppText.sheetLabel(s)),
              Text(value,
                  style: AppText.cardTitle(s).copyWith(fontSize: 16 * s)),
            ],
          ),
        ],
      ),
    );
  }
}
