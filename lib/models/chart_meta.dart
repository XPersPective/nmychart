import 'enums.dart';

class ChartMeta {
  final String id;
  final String name;
  final String shortName;
  final String description;
  final MetaType type;
  final MetaSubType subType;
  final ChartCategory category;
  final ChartSubCategory subCategory;
  final List<CoordinateSystem> allowedCoordinateSystems;
  final bool requiresOrderedData;
  final ChartPlacement placement;
  final ChartProvider provider;
  final VisibilityType visibility;
  final String author;
  final String version;
  final int createdAt;
  final int updatedAt;

  const ChartMeta({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.type,
    required this.subType,
    required this.category,
    required this.subCategory,
    required this.allowedCoordinateSystems,
    required this.requiresOrderedData,
    required this.placement,
    required this.provider,
    required this.visibility,
    required this.author,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChartMeta.fromJson(Map<String, dynamic> json) {
    return ChartMeta(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String,
      description: json['description'] as String,
      type: MetaType.values.byName(json['type'] as String),
      subType: MetaSubType.values.byName(json['subType'] as String),
      category: ChartCategory.values.byName(json['category'] as String),
      subCategory: ChartSubCategory.values.byName(
        json['subCategory'] as String,
      ),
      allowedCoordinateSystems: (json['allowedCoordinateSystems'] as List)
          .map((e) => CoordinateSystem.values.byName(e as String))
          .toList(),
      requiresOrderedData: json['requiresOrderedData'] as bool,
      placement: ChartPlacement.values.byName(json['placement'] as String),
      provider: ChartProvider.values.byName(json['provider'] as String),
      visibility: VisibilityType.values.byName(json['visibility'] as String),
      author: json['author'] as String,
      version: json['version'] as String,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }
}
