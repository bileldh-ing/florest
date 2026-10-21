import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/plant.dart';
import '../../../widgets/care_icon_chip.dart';

/// Name, care chips and description. Each line rises in on its own staggered
/// interval of the shared "selection changed" animation.
class PlantInfo extends StatelessWidget {
  const PlantInfo({
    super.key,
    required this.plant,
    required this.scale,
    required this.stagger,
  });

  final Plant plant;
  final double scale;

  /// Three curved animations: title, chips, description.
  final List<Animation<double>> stagger;

  static final Animatable<Offset> _rise =
      Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero);

  Widget _in(Animation<double> a, Widget child) => FadeTransition(
        opacity: a,
        child: SlideTransition(position: a.drive(_rise), child: child),
      );

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _in(
          stagger[0],
          Semantics(
            header: true,
            child: Text(plant.name, maxLines: 2, style: AppText.detailTitle(s)),
          ),
        ),
        SizedBox(height: 18 * s),
        _in(stagger[1], CareChipsRow(size: 38 * s, gap: 10 * s)),
        SizedBox(height: 22 * s),
        _in(
          stagger[2],
          Text(
            plant.description,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(s),
          ),
        ),
      ],
    );
  }
}
