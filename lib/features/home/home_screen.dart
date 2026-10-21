import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets.dart';
import '../../core/theme.dart';
import '../../data/plant.dart';
import '../../state/providers.dart';
import '../../widgets/bag_button.dart';
import '../../widgets/fly_to_bag.dart';
import '../../widgets/line_icon.dart';
import '../../widgets/plant_image.dart';
import '../../widgets/reveal_route.dart';
import '../../widgets/rotating_plant.dart';
import '../../widgets/round_icon_button.dart';
import '../../widgets/screen_frame.dart';
import '../detail/detail_screen.dart';
import '../search/search_sheet.dart';
import 'widgets/care_sheet.dart';
import 'widgets/filter_tabs.dart';
import 'widgets/hero_header.dart';
import 'widgets/plant_card.dart';
import 'widgets/staggered_entrance.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _bagKey = GlobalKey();

  /// Scroll offset of the visible list; drives the header only.
  final ValueNotifier<double> _offset = ValueNotifier<double>(0);
  final PageController _pages = PageController();
  final List<int> _generations = List<int>.filled(PlantFilter.values.length, 0);
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  int _page = 0;
  double _collapseRange = 1;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
    } else {
      _enter.forward();
    }
    final w = MediaQuery.sizeOf(context).width;
    final s = w / 390;
    unawaited(precachePlant(
        context, AppAssets.heroPlant, HeroHeader.plantSizeFor(w)));
    for (final p in ref.read(plantsProvider)) {
      unawaited(precachePlant(context, p.asset, PlantCard.imageSizeFor(s)));
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _offset.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _onListScroll(int index, double pixels) {
    if (index != _page) return;
    // Never mark the header dirty in the middle of a layout pass.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && index == _page) _offset.value = pixels;
      });
    } else {
      _offset.value = pixels;
    }
  }

  void _onPageChanged(int i) {
    HapticFeedback.selectionClick();
    setState(() {
      _page = i;
      _generations[i]++; // re-stagger the list we land on
    });
    _offset.value = math.min(_offset.value, _collapseRange);
    ref.read(filterProvider.notifier).select(PlantFilter.values[i]);
  }

  void _selectTab(int i) {
    if (i == _page) return;
    _pages.animateToPage(i,
        duration: AppDurations.slow, curve: Curves.easeOutCubic);
  }

  Future<void> _addToBag(Plant plant, Rect from) async {
    if (!MediaQuery.disableAnimationsOf(context)) {
      await flyToBag(
          context: context, asset: plant.asset, from: from, target: _bagKey);
    }
    if (!mounted) return;
    ref.read(bagProvider.notifier).add(plant.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${plant.name} added to bag'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => ref.read(bagProvider.notifier).undoAdd(plant.id),
        ),
      ));
  }

  Future<void> _openDetail(Plant plant, Offset tapGlobal) async {
    final filter = PlantFilter.values[_page];
    final list = ref.read(filteredPlantsProvider(filter));
    final index = math.max(0, list.indexOf(plant));
    ref.read(selectedPlantProvider.notifier).select(plant.id);
    final width = MediaQuery.sizeOf(context).width;
    await precachePlant(
            context, plant.asset, DetailScreen.bigPlantSizeFor(width))
        .timeout(const Duration(milliseconds: 150), onTimeout: () {});
    if (!mounted) return;
    await Navigator.of(context).push(RevealRoute<void>(
      center: tapGlobal,
      builder: (_) => DetailScreen(
        plants: list,
        initialIndex: index,
        heroScope: filter.name,
      ),
    ));
  }

  /// Search covers every plant, so the detail screen opens on the full list.
  Future<void> _search() async {
    final picked = await showPlantSearch(context);
    if (picked == null || !mounted) return;
    final all = ref.read(plantsProvider);
    ref.read(selectedPlantProvider.notifier).select(picked.id);
    final size = MediaQuery.sizeOf(context);
    await Navigator.of(context).push(RevealRoute<void>(
      center: Offset(size.width - 80, 80),
      builder: (_) => DetailScreen(
        plants: all,
        initialIndex: math.max(0, all.indexOf(picked)),
        heroScope: 'search',
      ),
    ));
  }

  void _showCare(Plant plant) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x55000000),
      builder: (_) => CareSheet(plant: plant),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            final s = w / 390;
            final pad = MediaQuery.paddingOf(context);
            final expanded = h * 0.48;
            final collapsed = pad.top + 72 * s;
            final tabsH = 96 * s;
            // The count badges straddle the header's bottom edge, as in the mock.
            final tabsLift = 40 * s;
            _collapseRange = math.max(1.0, expanded - collapsed);
            final range = _collapseRange;

            // Built once per layout, reused by every scroll frame.
            final heroPlant = PlantImage(
              asset: AppAssets.heroPlant,
              size: HeroHeader.plantSizeFor(w),
              wrapImage: (image) => RotatingPlant(child: image),
            );
            final topBar = _HomeTopBar(
              scale: s,
              bagKey: _bagKey,
              onSearch: _search,
            );
            final tabs = FilterTabs(scale: s, onSelect: _selectTab);

            return Stack(
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _pages,
                    onPageChanged: _onPageChanged,
                    itemCount: PlantFilter.values.length,
                    itemBuilder: (context, i) => _PlantListPage(
                      key: ValueKey<int>(i),
                      index: i,
                      filter: PlantFilter.values[i],
                      generation: _generations[i],
                      topPadding: expanded + tabsH - tabsLift,
                      bottomPadding: pad.bottom + 32 * s,
                      scale: s,
                      initialOffset: math.min(_offset.value, range),
                      onScrolled: _onListScroll,
                      onOpen: _openDetail,
                      onAdd: _addToBag,
                      onLongPress: _showCare,
                    ),
                  ),
                ),
                ValueListenableBuilder<double>(
                  valueListenable: _offset,
                  builder: (context, o, _) {
                    final height = math.max(collapsed, expanded - o);
                    return Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: height + tabsH - tabsLift,
                      child: Stack(
                        children: [
                          // White backing so cards scroll *under* the tabs.
                          Positioned(
                            top: height - tabsLift,
                            left: 0,
                            right: 0,
                            height: tabsH,
                            child: const ColoredBox(color: AppColors.white),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: height,
                            child: HeroHeader(
                              height: height,
                              expandedHeight: expanded,
                              progress: (o / range).clamp(0.0, 1.0),
                              stretch: math.max(0.0, -o),
                              scale: s,
                              topInset: pad.top,
                              width: w,
                              enter: _enter,
                              plant: heroPlant,
                              topBar: topBar,
                            ),
                          ),
                          Positioned(
                            top: height - tabsLift,
                            left: 0,
                            right: 0,
                            height: tabsH,
                            child: tabs,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
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
      padding: EdgeInsets.only(left: 26 * s, right: 18 * s),
      child: Row(
        children: [
          Semantics(
              header: true, child: Text('florest', style: AppText.wordmark(s))),
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

class _PlantListPage extends ConsumerStatefulWidget {
  const _PlantListPage({
    super.key,
    required this.index,
    required this.filter,
    required this.generation,
    required this.topPadding,
    required this.bottomPadding,
    required this.scale,
    required this.initialOffset,
    required this.onScrolled,
    required this.onOpen,
    required this.onAdd,
    required this.onLongPress,
  });

  final int index;
  final PlantFilter filter;
  final int generation;
  final double topPadding;
  final double bottomPadding;
  final double scale;
  final double initialOffset;
  final void Function(int index, double pixels) onScrolled;
  final Future<void> Function(Plant plant, Offset tap) onOpen;
  final Future<void> Function(Plant plant, Rect from) onAdd;
  final void Function(Plant plant) onLongPress;

  @override
  ConsumerState<_PlantListPage> createState() => _PlantListPageState();
}

class _PlantListPageState extends ConsumerState<_PlantListPage> {
  late final ScrollController _controller =
      ScrollController(initialScrollOffset: widget.initialOffset);
  bool _stagger = true;
  Timer? _staggerTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_report);
    _armStagger();
  }

  @override
  void didUpdateWidget(_PlantListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generation != widget.generation) _armStagger();
  }

  void _armStagger() {
    _stagger = true;
    _staggerTimer?.cancel();
    _staggerTimer =
        Timer(const Duration(milliseconds: 1100), () => _stagger = false);
  }

  void _report() => widget.onScrolled(widget.index, _controller.offset);

  @override
  void dispose() {
    _staggerTimer?.cancel();
    _controller
      ..removeListener(_report)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plants = ref.watch(filteredPlantsProvider(widget.filter));
    final s = widget.scale;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final scope = widget.filter.name;

    return ListView.builder(
      controller: _controller,
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding:
          EdgeInsets.only(top: widget.topPadding, bottom: widget.bottomPadding),
      itemExtent: PlantCard.extentFor(s),
      addAutomaticKeepAlives: false,
      itemCount: plants.length,
      itemBuilder: (context, i) {
        final plant = plants[i];
        return StaggeredEntrance(
          key: ValueKey<String>('${widget.generation}-${plant.id}'),
          enabled: _stagger && !reduce && i < 8,
          delay: Duration(milliseconds: 60 * i),
          builder: (context, entrance) => PlantCard(
            plant: plant,
            heroTag: plant.heroTagIn(scope),
            scale: s,
            entrance: entrance,
            onOpen: (tap) => widget.onOpen(plant, tap),
            onAdd: (rect) => widget.onAdd(plant, rect),
            onLongPress: () => widget.onLongPress(plant),
          ),
        );
      },
    );
  }
}
