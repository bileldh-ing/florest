import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets.dart';
import '../../core/theme.dart';
import '../../data/plant.dart';
import '../../state/providers.dart';
import '../../widgets/bag_button.dart';
import '../../widgets/line_icon.dart';
import '../../widgets/plant_image.dart';
import '../../widgets/rotating_plant.dart';
import '../../widgets/round_icon_button.dart';
import '../../widgets/screen_frame.dart';
import '../search/search_sheet.dart';
import 'widgets/plant_info.dart';
import 'widgets/side_rail.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({
    super.key,
    required this.plants,
    required this.initialIndex,
    required this.heroScope,
  });

  final List<Plant> plants;
  final int initialIndex;

  /// Scope of the Hero tags on the list this screen was opened from.
  final String heroScope;

  static double bigPlantSizeFor(double width) => width * 0.82;
  static double thumbSizeFor(double width) => width * 0.21;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen>
    with TickerProviderStateMixin {
  final GlobalKey _bagKey = GlobalKey();
  final ScrollController _rail = ScrollController();

  late int _index = widget.initialIndex;
  int _direction = 1;

  /// Notch position in item units (spring-animated, fractional mid-glide).
  late final AnimationController _notch = AnimationController.unbounded(
    vsync: this,
    value: widget.initialIndex.toDouble(),
  );

  /// Restarts on every selection change; drives the staggered text.
  late final AnimationController _change = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: 1,
  );
  late final List<Animation<double>> _stagger = [
    for (var i = 0; i < 3; i++)
      CurvedAnimation(
        parent: _change,
        curve: Interval(i * 0.15, 0.6 + i * 0.15, curve: Curves.easeOutCubic),
      ),
  ];

  /// User rotation (radians) layered over the idle spin, with inertia.
  late final AnimationController _spin =
      AnimationController.unbounded(vsync: this);

  /// Pinch zoom 1.0–1.6, springs back to 1.
  late final AnimationController _zoom =
      AnimationController.unbounded(vsync: this, value: 1);

  double _itemH = 1;
  double _railViewport = 1;
  double _railPad = 0;
  bool _didInit = false;

  // Gesture bookkeeping for the big plant.
  double _baseAngle = 0;
  double _baseZoom = 1;
  double _dragAngle = 0;
  Offset _startFocal = Offset.zero;
  Offset _lastFocal = Offset.zero;
  Offset _center = Offset.zero;
  int _maxPointers = 1;
  double _edgeDrag = 0;

  Plant get _plant => widget.plants[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerRail(_index, animate: false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    final w = MediaQuery.sizeOf(context).width;
    for (final p in widget.plants) {
      unawaited(precachePlant(context, p.asset, DetailScreen.thumbSizeFor(w)));
    }
    _precacheAround(_index);
  }

  @override
  void dispose() {
    _rail.dispose();
    _notch.dispose();
    _change.dispose();
    _spin.dispose();
    _zoom.dispose();
    super.dispose();
  }

  void _precacheAround(int i) {
    final big = DetailScreen.bigPlantSizeFor(MediaQuery.sizeOf(context).width);
    for (var j = i - 1; j <= i + 1; j++) {
      if (j >= 0 && j < widget.plants.length) {
        unawaited(precachePlant(context, widget.plants[j].asset, big));
      }
    }
  }

  void _select(int i) {
    if (i < 0 || i >= widget.plants.length || i == _index) return;
    HapticFeedback.selectionClick();
    final reduce = MediaQuery.disableAnimationsOf(context);
    setState(() {
      _direction = i > _index ? 1 : -1;
      _index = i;
    });
    if (reduce) {
      _notch.value = i.toDouble();
      _change.value = 1;
    } else {
      _notch.animateWith(SpringSimulation(
          kSpring, _notch.value, i.toDouble(), _notch.velocity));
      _change.forward(from: 0);
    }
    _centerRail(i, animate: !reduce);
    _precacheAround(i);
    ref.read(selectedPlantProvider.notifier).select(widget.plants[i].id);
  }

  Future<void> _search() async {
    final picked = await showPlantSearch(context);
    if (picked == null || !mounted) return;
    _select(widget.plants.indexOf(picked));
  }

  void _centerRail(int i, {bool animate = true}) {
    if (!_rail.hasClients) return;
    final pos = _rail.position;
    final target = (_railPad + i * _itemH + _itemH / 2 - _railViewport / 2)
        .clamp(pos.minScrollExtent, pos.maxScrollExtent);
    if (animate) {
      _rail.animateTo(target,
          duration: AppDurations.slow, curve: const SpringCurve());
    } else {
      _rail.jumpTo(target);
    }
  }

  // ---- Big plant gestures: drag-rotate with inertia, pinch, vertical swipe.

  void _onScaleStart(ScaleStartDetails d) {
    _spin.stop();
    _zoom.stop();
    _baseAngle = _spin.value;
    _baseZoom = _zoom.value;
    _dragAngle = 0;
    _startFocal = d.localFocalPoint;
    _lastFocal = d.localFocalPoint;
    _maxPointers = d.pointerCount;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    _maxPointers = math.max(_maxPointers, d.pointerCount);
    final now = d.localFocalPoint;
    if (d.pointerCount >= 2) {
      _zoom.value = (_baseZoom * d.scale).clamp(1.0, 1.6);
      _spin.value = _baseAngle + _dragAngle + d.rotation;
    } else {
      final from = _lastFocal - _center;
      final to = now - _center;
      if (from.distance > 12 && to.distance > 12) {
        var delta = to.direction - from.direction;
        if (delta > math.pi) delta -= 2 * math.pi;
        if (delta < -math.pi) delta += 2 * math.pi;
        _dragAngle += delta;
      }
      _spin.value = _baseAngle + _dragAngle;
    }
    _lastFocal = now;
  }

  void _onScaleEnd(ScaleEndDetails d) {
    if (_zoom.value != 1) {
      _zoom.animateWith(SpringSimulation(kSpring, _zoom.value, 1, 0));
    }
    final v = d.velocity.pixelsPerSecond;
    final travel = _lastFocal - _startFocal;
    final isSwipe = _maxPointers == 1 &&
        v.dy.abs() > 700 &&
        v.dy.abs() > v.dx.abs() * 1.8 &&
        travel.dy.abs() > 50;
    if (isSwipe) {
      // Undo the incidental rotation and change plant instead.
      _spin.animateWith(SpringSimulation(kSpring, _spin.value, _baseAngle, 0));
      _select(_index + (v.dy < 0 ? 1 : -1));
      return;
    }
    if (_maxPointers > 1) return;
    final r = _lastFocal - _center;
    final d2 = r.distanceSquared;
    if (d2 < 400) return;
    final omega = (r.dx * v.dy - r.dy * v.dx) / d2; // rad/s
    if (omega.abs() > 0.2) {
      _spin.animateWith(
          FrictionSimulation(0.12, _spin.value, omega.clamp(-12.0, 12.0)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      child: Scaffold(
        backgroundColor: AppColors.green,
        body: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          final s = w / 390;
          final pad = MediaQuery.paddingOf(context);

          final railTop = pad.top + 84 * s;
          final railBottom = h - math.max(pad.bottom + 16 * s, h * 0.07);
          final railW = w * 0.34;
          final chevronH = 72 * s;
          final listH = railBottom - chevronH - railTop;
          _railPad = 14 * s;
          _railViewport = listH;
          _itemH = (listH - 2 * _railPad) / 4;
          final thumb = math.min(DetailScreen.thumbSizeFor(w), _itemH * 0.8);

          final big = DetailScreen.bigPlantSizeFor(w);
          final bigCenter = Offset(w * 0.80, pad.top + h * 0.28);
          _center = Offset(big / 2, big / 2);

          return Stack(
            children: [
              Positioned(
                left: 0,
                top: railTop,
                width: railW,
                height: railBottom - railTop,
                child: SideRail(
                  plants: widget.plants,
                  selected: _index,
                  notch: _notch,
                  controller: _rail,
                  itemExtent: _itemH,
                  padTop: _railPad,
                  listHeight: listH,
                  chevronHeight: chevronH,
                  thumbSize: thumb,
                  scale: s,
                  onSelect: _select,
                ),
              ),
              Positioned(
                left: bigCenter.dx - big / 2,
                top: bigCenter.dy - big / 2,
                width: big,
                height: big,
                child: Semantics(
                  image: true,
                  label:
                      '${_plant.name}. Swipe up or down to browse, drag to rotate, pinch to zoom',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                    onScaleEnd: _onScaleEnd,
                    child: _BigPlant(
                      plant: _plant,
                      heroTag: _plant.heroTagIn(widget.heroScope),
                      size: big,
                      direction: _direction,
                      spin: _spin,
                      zoom: _zoom,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: w * 0.45,
                right: w * 0.07,
                top: h * 0.565,
                child: PlantInfo(plant: _plant, scale: s, stagger: _stagger),
              ),
              Positioned(
                top: pad.top,
                left: 0,
                right: 0,
                height: 72 * s,
                child: _DetailTopBar(
                  scale: s,
                  bagKey: _bagKey,
                  onSearch: _search,
                ),
              ),
              // Swipe right from the left edge to go back.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 20,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) => _edgeDrag = 0,
                  onHorizontalDragUpdate: (d) => _edgeDrag += d.delta.dx,
                  onHorizontalDragEnd: (d) {
                    if (_edgeDrag > 70 || (d.primaryVelocity ?? 0) > 400) {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _BigPlant extends StatelessWidget {
  const _BigPlant({
    required this.plant,
    required this.heroTag,
    required this.size,
    required this.direction,
    required this.spin,
    required this.zoom,
  });

  final Plant plant;
  final String heroTag;
  final double size;
  final int direction;
  final Animation<double> spin;
  final Animation<double> zoom;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: zoom,
      builder: (context, child) =>
          Transform.scale(scale: zoom.value, child: child),
      child: Hero(
        tag: heroTag,
        flightShuttleBuilder: plantFlightShuttle(plant.asset),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 520),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: Offset(0, 0.12 * direction),
              end: Offset.zero,
            ).animate(animation);
            final turns = Tween<double>(begin: -0.06 * direction, end: 0)
                .animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: slide,
                child: RotationTransition(turns: turns, child: child),
              ),
            );
          },
          child: PlantImage(
            key: ValueKey<String>(plant.id),
            asset: plant.asset,
            size: size,
            wrapImage: (image) =>
                RotatingPlant(breathe: true, extraAngle: spin, child: image),
          ),
        ),
      ),
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({
    required this.scale,
    required this.bagKey,
    required this.onSearch,
  });

  final double scale;
  final GlobalKey bagKey;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Padding(
      padding: EdgeInsets.only(left: 14 * s, right: 18 * s),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LineIcon(
                      LineGlyph.back,
                      size: 28 * s,
                      color: AppColors.cream,
                      strokeWidth: 1.8,
                    ),
                    SizedBox(width: 4 * s),
                    Text('Back', style: AppText.back(s)),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          RoundIconButton(
            icon: LineGlyph.search,
            semanticLabel: 'Search plants',
            scale: s,
            onTap: onSearch,
          ),
          SizedBox(width: 4 * s),
          BagButton(anchorKey: bagKey, scale: s),
        ],
      ),
    );
  }
}
