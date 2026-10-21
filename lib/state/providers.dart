import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/plant.dart';
import '../data/plants_repo.dart';

enum PlantFilter {
  all('All'),
  outdoor('Outdoor'),
  indoor('Indoor');

  const PlantFilter(this.label);
  final String label;
}

final plantsProvider = Provider<List<Plant>>((ref) => PlantsRepo.all);

final filteredPlantsProvider =
    Provider.family<List<Plant>, PlantFilter>((ref, filter) {
  final all = ref.watch(plantsProvider);
  return switch (filter) {
    PlantFilter.all => all,
    PlantFilter.outdoor =>
      all.where((p) => p.type == PlantType.outdoor).toList(growable: false),
    PlantFilter.indoor =>
      all.where((p) => p.type == PlantType.indoor).toList(growable: false),
  };
});

/// Badge counts, computed from data.
final filterCountsProvider = Provider<Map<PlantFilter, int>>((ref) {
  return {
    for (final f in PlantFilter.values)
      f: ref.watch(filteredPlantsProvider(f)).length,
  };
});

class FilterNotifier extends Notifier<PlantFilter> {
  @override
  PlantFilter build() => PlantFilter.all;

  void select(PlantFilter filter) => state = filter;
}

final filterProvider =
    NotifierProvider<FilterNotifier, PlantFilter>(FilterNotifier.new);

class SelectedPlantNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) => state = id;
}

final selectedPlantProvider =
    NotifierProvider<SelectedPlantNotifier, String?>(SelectedPlantNotifier.new);

/// Bag holds plant ids in the order they were added.
class BagNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void add(String id) => state = [...state, id];

  void undoAdd(String id) {
    final i = state.lastIndexOf(id);
    if (i < 0) return;
    state = [...state]..removeAt(i);
  }
}

final bagProvider =
    NotifierProvider<BagNotifier, List<String>>(BagNotifier.new);

final bagCountProvider = Provider<int>((ref) => ref.watch(bagProvider).length);
