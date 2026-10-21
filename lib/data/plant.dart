import 'package:flutter/foundation.dart';

enum PlantType { indoor, outdoor, both }

@immutable
class Plant {
  const Plant({
    required this.id,
    required this.name,
    required this.type,
    required this.asset,
    required this.description,
    required this.water,
    required this.temperature,
    required this.light,
  });

  final String id;
  final String name;
  final PlantType type;
  final String asset;
  final String description;
  final String water;
  final String temperature;
  final String light;

  String heroTagIn(String scope) => 'plant-$scope-$id';

  @override
  bool operator ==(Object other) => other is Plant && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
