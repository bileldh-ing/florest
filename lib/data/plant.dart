import 'package:flutter/foundation.dart';

enum PlantType { indoor, outdoor, both }

@immutable
class Plant {
  const Plant({
    required this.id,
    required this.name,
    required this.type,
    required this.priceCents,
    required this.asset,
    required this.description,
    required this.water,
    required this.temperature,
    required this.light,
  });

  final String id;
  final String name;
  final PlantType type;

  /// Price in cents, so totals never pick up floating-point drift.
  final int priceCents;
  final String asset;
  final String description;
  final String water;
  final String temperature;
  final String light;

  String heroTagIn(String scope) => 'plant-$scope-$id';

  String get priceLabel => formatPrice(priceCents);

  @override
  bool operator ==(Object other) => other is Plant && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// `1850` → `$18.50`; whole amounts drop the cents (`$18`).
String formatPrice(int cents) {
  final whole = cents ~/ 100;
  final rest = cents % 100;
  return rest == 0 ? '\$$whole' : '\$$whole.${rest.toString().padLeft(2, '0')}';
}
