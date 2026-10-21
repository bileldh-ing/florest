import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/plant.dart';
import '../../../widgets/line_icon.dart';
import '../../../widgets/plant_image.dart';
import 'notch_painter.dart';

/// Left white rail: painted outline with the gliding notch, a thumbnail list
/// (driven only by code, so vertical swipes change the selection instead of
/// free-scrolling) and a "more" chevron.
class SideRail extends StatefulWidget {
  const SideRail({
    super.key,
    required this.plants,
    required this.selected,
    required this.notch,
    required this.controller,
    required this.itemExtent,
    required this.padTop,
    required this.listHeight,
    required this.chevronHeight,
    required this.thumbSize,
    required this.scale,
    required this.onSelect,
  });

  final List<Plant> plants;
  final int selected;
  final Animation<double> notch;
  final ScrollController controller;
  final double itemExtent;
  final double padTop;
  final double listHeight;
  final double chevronHeight;
  final double thumbSize;
  final double scale;
  final ValueChanged<int> onSelect;

  @override
  State<SideRail> createState() => _SideRailState();
}

class _SideRailState extends State<SideRail> {
  double _drag = 0;

  void _step(int delta) => widget.onSelect(widget.selected + delta);

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final last = widget.selected >= widget.plants.length - 1;
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: NotchPainter(
                notch: widget.notch,
                scroll: widget.controller,
                itemExtent: widget.itemExtent,
                padTop: widget.padTop,
                inset: 10 * s,
                radius: AppRadii.rail * s,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: widget.listHeight,
          child: GestureDetector(
            onVerticalDragStart: (_) => _drag = 0,
            onVerticalDragUpdate: (d) {
              _drag += d.delta.dy;
              if (_drag.abs() > widget.itemExtent * 0.6) {
                _step(_drag < 0 ? 1 : -1);
                _drag = 0;
              }
            },
            onVerticalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (_drag.abs() > 8 && v.abs() > 350) _step(v < 0 ? 1 : -1);
              _drag = 0;
            },
            child: ClipRect(
              child: ListView.builder(
                controller: widget.controller,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: widget.padTop),
                itemExtent: widget.itemExtent,
                itemCount: widget.plants.length,
                itemBuilder: (context, i) => _RailThumb(
                  plant: widget.plants[i],
                  selected: i == widget.selected,
                  size: widget.thumbSize,
                  onTap: () => widget.onSelect(i),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: widget.chevronHeight,
          child: Semantics(
            button: true,
            label: 'Next plant',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: last ? null : () => _step(1),
              child: Center(
                child: AnimatedOpacity(
                  opacity: last ? 0.25 : 1,
                  duration: AppDurations.fast,
                  child: LineIcon(
                    LineGlyph.chevronDown,
                    size: 34 * s,
                    color: AppColors.ink,
                    strokeWidth: 2.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RailThumb extends StatelessWidget {
  const _RailThumb({
    required this.plant,
    required this.selected,
    required this.size,
    required this.onTap,
  });

  final Plant plant;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: plant.name,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedScale(
            scale: selected ? 1.04 : 0.94,
            duration: AppDurations.medium,
            curve: Curves.easeOutBack,
            child: PlantImage(
              asset: plant.asset,
              size: size,
              shadowColor: selected
                  ? AppColors.plantShadow
                  : AppColors.plantShadowOnWhite,
            ),
          ),
        ),
      ),
    );
  }
}
