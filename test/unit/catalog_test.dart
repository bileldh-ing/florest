import 'package:florest/data/plant.dart';
import 'package:florest/data/plants_repo.dart';
import 'package:florest/features/search/search_sheet.dart';
import 'package:florest/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('catalog', () {
    test('has 16 unique plants with assets and prices', () {
      const plants = PlantsRepo.all;
      expect(plants, hasLength(16));
      expect(plants.map((p) => p.id).toSet(), hasLength(16));
      for (final p in plants) {
        expect(p.asset, 'assets/plants/${p.id}.webp');
        expect(p.priceCents, greaterThan(0));
      }
    });

    test('tab counts are computed from data: 16 / 8 / 4', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(filterCountsProvider), {
        PlantFilter.all: 16,
        PlantFilter.outdoor: 8,
        PlantFilter.indoor: 4,
      });
    });

    test('hero tags are scoped per tab', () {
      final p = PlantsRepo.all.first;
      expect(p.heroTagIn('all'), isNot(p.heroTagIn('outdoor')));
    });
  });

  group('formatPrice', () {
    test('drops zero cents and pads the rest', () {
      expect(formatPrice(1800), r'$18');
      expect(formatPrice(1805), r'$18.05');
      expect(formatPrice(1850), r'$18.50');
      expect(formatPrice(0), r'$0');
    });
  });

  group('search', () {
    const plants = PlantsRepo.all;

    test('empty query returns everything', () {
      expect(searchPlants(plants, '  '), plants);
    });

    test('matches name case-insensitively', () {
      expect(searchPlants(plants, 'ALOE').map((p) => p.id), ['aloe_vera']);
    });

    test('matches type and every word', () {
      final indoor = searchPlants(plants, 'indoor');
      expect(indoor, isNotEmpty);
      expect(indoor.every((p) => p.type == PlantType.indoor), isTrue);
      expect(searchPlants(plants, 'jade crassula').single.id, 'jade_crassula');
    });

    test('no match gives an empty list', () {
      expect(searchPlants(plants, 'cactus-xyz'), isEmpty);
    });
  });
}
