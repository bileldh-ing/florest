import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/plant.dart';
import '../../../widgets/care_icon_chip.dart';
import '../../../widgets/plant_image.dart';
import 'add_button.dart';

/// Green card offset to the right; the plant overlaps the card's left edge.
class PlantCard extends StatefulWidget {
  const PlantCard({
    super.key,
    required this.plant,
    required this.heroTag,
    required this.scale,
    required this.entrance,
    required this.onOpen,
    required this.onAdd,
    required this.onLongPress,
  });

  /// Row extent (card + gap) for ListView.itemExtent.
  static double extentFor(double s) => 168 * s;
  static double imageSizeFor(double s) => 88 * s;

  final Plant plant;

  /// Unique per tab so two tabs never share a Hero tag.
  final String heroTag;
  final double scale;
  final Animation<double> entrance;
  final ValueChanged<Offset> onOpen;
  final Future<void> Function(Rect imageRect) onAdd;
  final VoidCallback onLongPress;

  @override
  State<PlantCard> createState() => _PlantCardState();
}

class _PlantCardState extends State<PlantCard> {
  final GlobalKey _imageKey = GlobalKey();

  Rect _imageRect() {
    final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Rect.zero;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final plant = widget.plant;
    final cardH = 150 * s;
    final cardLeft = 66 * s;
    final img = PlantCard.imageSizeFor(s);
    final pop = widget.entrance.drive(
      Tween<double>(begin: 0.4, end: 1)
          .chain(CurveTween(curve: const Interval(0.3, 1, curve: Curves.easeOutBack))),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 18 * s),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: cardLeft,
            right: 0,
            top: 0,
            height: cardH,
            child: Semantics(
              button: true,
              label: '${plant.name}. Double tap for details, long press for care info',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => widget.onOpen(d.globalPosition),
                onLongPress: widget.onLongPress,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius:
                        BorderRadius.horizontal(left: Radius.circular(AppRadii.card * s)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(left: img * 0.5 + 20 * s, right: 22 * s),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plant.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.cardTitle(s),
                              ),
                              SizedBox(height: 12 * s),
                              CareChipsRow(size: 34 * s, gap: 8 * s),
                            ],
                          ),
                        ),
                        SizedBox(width: 10 * s),
                        AddButton(
                          size: 62 * s,
                          onAdd: () => widget.onAdd(_imageRect()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: cardLeft - img * 0.5 + 4 * s,
            top: (cardH - img) / 2,
            width: img,
            height: img,
            child: GestureDetector(
              onTapUp: (d) => widget.onOpen(d.globalPosition),
              onLongPress: widget.onLongPress,
              child: ScaleTransition(
                scale: pop,
                child: Hero(
                  tag: widget.heroTag,
                  flightShuttleBuilder: plantFlightShuttle(plant.asset),
                  child: PlantImage(key: _imageKey, asset: plant.asset, size: img),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
