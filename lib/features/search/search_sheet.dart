import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/plant.dart';
import '../../state/providers.dart';
import '../../widgets/line_icon.dart';
import '../../widgets/plant_image.dart';

/// Opens plant search and resolves with the plant the user picked, or null.
Future<Plant?> showPlantSearch(BuildContext context) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<Plant>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66000000),
    builder: (_) => const PlantSearchSheet(),
  );
}

/// Case- and accent-insensitive match on name, type and light needs.
@visibleForTesting
List<Plant> searchPlants(List<Plant> plants, String query) {
  final q = _fold(query.trim());
  if (q.isEmpty) return plants;
  final words = q.split(RegExp(r'\s+'));
  return [
    for (final p in plants)
      if (words.every(
        (w) => _fold('${p.name} ${p.type.name} ${p.light}').contains(w),
      ))
        p,
  ];
}

String _fold(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[àáâä]'), 'a')
    .replaceAll(RegExp('[èéêë]'), 'e')
    .replaceAll(RegExp('[ìíîï]'), 'i')
    .replaceAll(RegExp('[òóôö]'), 'o')
    .replaceAll(RegExp('[ùúûü]'), 'u');

class PlantSearchSheet extends ConsumerStatefulWidget {
  const PlantSearchSheet({super.key});

  @override
  ConsumerState<PlantSearchSheet> createState() => _PlantSearchSheetState();
}

class _PlantSearchSheetState extends ConsumerState<PlantSearchSheet> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final s = mq.size.width / 390;
    final all = ref.watch(plantsProvider);

    return Padding(
      padding: EdgeInsets.only(
        top: mq.padding.top + 48 * s,
        bottom: mq.viewInsets.bottom,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.header * s),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(18 * s, 22 * s, 18 * s, 10 * s),
              child: Container(
                height: 56 * s,
                padding: EdgeInsets.symmetric(horizontal: 16 * s),
                decoration: BoxDecoration(
                  color: AppColors.translucent,
                  borderRadius: BorderRadius.circular(20 * s),
                ),
                child: Row(
                  children: [
                    LineIcon(
                      LineGlyph.search,
                      size: 22 * s,
                      color: AppColors.cream,
                    ),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: TextField(
                        controller: _query,
                        autofocus: true,
                        cursorColor: AppColors.cream,
                        textInputAction: TextInputAction.search,
                        style: AppText.cardTitle(s),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration.collapsed(
                          hintText: 'Search plants, "indoor", "sun"…',
                          hintStyle: AppText.body(s),
                        ),
                      ),
                    ),
                    if (_query.text.isNotEmpty)
                      Semantics(
                        button: true,
                        label: 'Clear search',
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(_query.clear),
                          child: SizedBox.square(
                            dimension: 44 * s,
                            child: Center(
                              child: LineIcon(
                                LineGlyph.close,
                                size: 18 * s,
                                color: AppColors.cream,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(child: _results(searchPlants(all, _query.text), s)),
          ],
        ),
      ),
    );
  }

  Widget _results(List<Plant> results, double s) {
    if (results.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 48 * s),
        child: Text(
          'No plants match "${_query.text.trim()}"',
          textAlign: TextAlign.center,
          style: AppText.body(s),
        ),
      );
    }
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(10 * s, 4 * s, 10 * s, 24 * s),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final p = results[i];
        return Semantics(
          button: true,
          label: '${p.name}, ${p.priceLabel}',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(20 * s),
            onTap: () => Navigator.of(context).pop(p),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * s,
                vertical: 8 * s,
              ),
              child: Row(
                children: [
                  PlantImage(asset: p.asset, size: 56 * s),
                  SizedBox(width: 16 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: AppText.cardTitle(s)),
                        SizedBox(height: 2 * s),
                        Text(
                          '${_typeLabel(p.type)} · ${p.light}',
                          style: AppText.sheetLabel(s),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    p.priceLabel,
                    style: AppText.cardTitle(s).copyWith(fontSize: 16 * s),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _typeLabel(PlantType t) => switch (t) {
      PlantType.indoor => 'Indoor',
      PlantType.outdoor => 'Outdoor',
      PlantType.both => 'Indoor & outdoor',
    };
