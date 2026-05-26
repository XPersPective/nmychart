import 'enums.dart';

class ChartSetDocumentMeta {
  final String id;
  final String packetType;
  final MetaType type;
  final MetaSubType subType;
  final CoordinateSystem coordinateSystem;
  final String schemaVersion;
  final int revision;
  final int updatedAt;

  const ChartSetDocumentMeta({
    required this.id,
    required this.packetType,
    required this.type,
    required this.subType,
    required this.coordinateSystem,
    required this.schemaVersion,
    required this.revision,
    required this.updatedAt,
  });

  factory ChartSetDocumentMeta.fromJson(Map<String, dynamic> json) {
    return ChartSetDocumentMeta(
      id: json['id'] as String,
      packetType: json['packetType'] as String,
      type: MetaType.values.byName(json['type'] as String),
      subType: MetaSubType.values.byName(json['subType'] as String),
      coordinateSystem: CoordinateSystem.values.byName(
        json['coordinateSystem'] as String,
      ),
      schemaVersion: json['schemaVersion'] as String,
      revision: json['revision'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }
}
