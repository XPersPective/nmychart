import 'enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STREAM PACKET (Base)
// ─────────────────────────────────────────────────────────────────────────────
sealed class StreamPacket {
  final PacketType packetType;
  final String docId;
  final int? revision; // Snapshot için zorunlu, diğerleri için opsiyonel

  const StreamPacket({
    required this.packetType,
    required this.docId,
    this.revision,
  });

  factory StreamPacket.fromJson(Map<String, dynamic> json) {
    final typeStr = json['packetType'] as String;
    final type = PacketType.values.byName(typeStr);

    return switch (type) {
      PacketType.data => DataPacket.fromJson(json),
      PacketType.patch => PatchPacket.fromJson(json),
      PacketType.snapshot => throw UnimplementedError(
        'Snapshot ayrı parse edilmeli',
      ), // Genelde ChartSetDocument kullanılır
      PacketType.error => ErrorPacket.fromJson(json),
      PacketType.busy => BusyPacket.fromJson(json),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA PACKETS (Sealed Hierarchy)
// ─────────────────────────────────────────────────────────────────────────────
class ChartDataPayload {
  final Map<String, List<dynamic>> fields;

  const ChartDataPayload({required this.fields});

  factory ChartDataPayload.fromJson(Map<String, dynamic> json) {
    final fields = <String, List<dynamic>>{};
    for (final entry in json.entries) {
      if (entry.value is List) {
        fields[entry.key] = (entry.value as List).toList();
      }
    }
    return ChartDataPayload(fields: fields);
  }
}

sealed class DataPacket extends StreamPacket {
  final DataAction action;

  const DataPacket({required super.docId, super.revision, required this.action})
    : super(packetType: PacketType.data);

  factory DataPacket.fromJson(Map<String, dynamic> json) {
    // Action'ı güvenli şekilde al (PacketRouter kök veya payload'dan birleştirmiş olabilir)
    // Ancak json flatten edilmiş varsayılır (PacketRouter tarafından).
    final payload = json['payload'] as Map<String, dynamic>?;
    final actionStr = (json['action'] ?? payload?['action']) as String;
    final action = DataAction.values.byName(actionStr);

    return switch (action) {
      DataAction.update => UpdateDataPacket.fromJson(json),
      DataAction.append => AppendDataPacket.fromJson(json),
      DataAction.prepend => PrependDataPacket.fromJson(json),
      DataAction.overwrite => OverwriteDataPacket.fromJson(json),
      DataAction.clear => ClearDataPacket.fromJson(json),
    };
  }
}

class UpdateDataPacket extends DataPacket {
  final List<dynamic>? baseAxisData;
  final Map<String, ChartDataPayload>? charts;

  const UpdateDataPacket({
    required super.docId,
    super.revision,
    this.baseAxisData,
    this.charts,
  }) : super(action: DataAction.update);

  factory UpdateDataPacket.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? json;

    return UpdateDataPacket(
      docId: (json['docId'] ?? '') as String,
      revision: json['revision'] as int?,
      baseAxisData: (payload['baseAxisData'] as List?)?.toList(),
      charts: (payload['charts'] as Map?)?.cast<String, dynamic>().map(
        (k, v) => MapEntry(k, ChartDataPayload.fromJson(Map<String, dynamic>.from(v as Map))),
      ),
    );
  }
}

class AppendDataPacket extends DataPacket {
  final List<dynamic>? baseAxisData;
  final Map<String, ChartDataPayload>? charts;

  const AppendDataPacket({
    required super.docId,
    super.revision,
    this.baseAxisData,
    this.charts,
  }) : super(action: DataAction.append);

  factory AppendDataPacket.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? json;

    return AppendDataPacket(
      docId: (json['docId'] ?? '') as String,
      revision: json['revision'] as int?,
      baseAxisData: (payload['baseAxisData'] as List?)?.toList(),
      charts: (payload['charts'] as Map?)?.cast<String, dynamic>().map(
        (k, v) => MapEntry(k, ChartDataPayload.fromJson(Map<String, dynamic>.from(v as Map))),
      ),
    );
  }
}

class PrependDataPacket extends DataPacket {
  final List<dynamic>? baseAxisData;
  final Map<String, ChartDataPayload>? charts;

  const PrependDataPacket({
    required super.docId,
    super.revision,
    this.baseAxisData,
    this.charts,
  }) : super(action: DataAction.prepend);

  factory PrependDataPacket.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? json;

    return PrependDataPacket(
      docId: (json['docId'] ?? '') as String,
      revision: json['revision'] as int?,
      baseAxisData: (payload['baseAxisData'] as List?)?.toList(),
      charts: (payload['charts'] as Map?)?.cast<String, dynamic>().map(
        (k, v) => MapEntry(k, ChartDataPayload.fromJson(Map<String, dynamic>.from(v as Map))),
      ),
    );
  }
}

class OverwriteDataPacket extends DataPacket {
  final int startIndex;
  final List<dynamic>? baseAxisData;
  final Map<String, ChartDataPayload>? charts;

  const OverwriteDataPacket({
    required super.docId,
    super.revision,
    required this.startIndex,
    this.baseAxisData,
    this.charts,
  }) : super(action: DataAction.overwrite);

  factory OverwriteDataPacket.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? json;

    return OverwriteDataPacket(
      docId: (json['docId'] ?? '') as String,
      revision: json['revision'] as int?,
      startIndex: payload['startIndex'] as int? ?? 0,
      baseAxisData: (payload['baseAxisData'] as List?)?.toList(),
      charts: (payload['charts'] as Map?)?.cast<String, dynamic>().map(
        (k, v) => MapEntry(k, ChartDataPayload.fromJson(Map<String, dynamic>.from(v as Map))),
      ),
    );
  }
}

class ClearDataPacket extends DataPacket {
  const ClearDataPacket({required super.docId, super.revision})
    : super(action: DataAction.clear);

  factory ClearDataPacket.fromJson(Map<String, dynamic> json) {
    return ClearDataPacket(
      docId: (json['docId'] ?? '') as String,
      revision: json['revision'] as int?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PATCH PACKETS & OPERATIONS (Sealed Hierarchy)
// ─────────────────────────────────────────────────────────────────────────────

class PatchPacket extends StreamPacket {
  final List<PatchOperationItem> operations;

  const PatchPacket({
    required super.docId,
    super.revision,
    required this.operations,
  }) : super(packetType: PacketType.patch);

  factory PatchPacket.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? json;
    final packetInfo = json['packet'] as Map<String, dynamic>? ?? json;

    return PatchPacket(
      docId: (packetInfo['docId'] ?? json['docId'] ?? '') as String,
      revision: packetInfo['revision'] as int? ?? json['revision'] as int?,
      operations: (payload['operations'] as List)
          .map((e) => PatchOperationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'packet': {
      'packetType': packetType.name,
      'docId': docId,
      if (revision != null) 'revision': revision,
    },
    'payload': {'operations': operations.map((e) => e.toJson()).toList()},
  };
}

sealed class PatchOperationItem {
  final PatchScope scope;
  final PatchOperation op;

  const PatchOperationItem({required this.scope, required this.op});

  factory PatchOperationItem.fromJson(Map<String, dynamic> json) {
    final scope = PatchScope.values.byName(json['scope'] as String);

    return switch (scope) {
      PatchScope.root => RootPatchItem.fromJson(json),
      PatchScope.chart => ChartPatchItem.fromJson(json),
      PatchScope.plot => ChildPatchItem.fromJson(json, PatchScope.plot),
      PatchScope.input => ChildPatchItem.fromJson(json, PatchScope.input),
      PatchScope.dimensions => DimensionsPatchItem.fromJson(json),
    };
  }

  Map<String, dynamic> toJson();
}

class RootPatchItem extends PatchOperationItem {
  final String path;
  final dynamic value;

  const RootPatchItem({required this.path, required this.value})
    : super(scope: PatchScope.root, op: PatchOperation.replace);

  factory RootPatchItem.fromJson(Map<String, dynamic> json) {
    return RootPatchItem(path: json['path'] as String, value: json['value']);
  }

  @override
  Map<String, dynamic> toJson() => {
    'scope': scope.name,
    'op': op.name,
    'path': path,
    'value': value,
  };
}

class ChartPatchItem extends PatchOperationItem {
  final String? targetId;
  final Map<String, dynamic>? value;
  final int? targetSlot;
  final int? toIndex;

  const ChartPatchItem({
    required super.op,
    this.targetId,
    this.value,
    this.targetSlot,
    this.toIndex,
  }) : super(scope: PatchScope.chart);

  factory ChartPatchItem.fromJson(Map<String, dynamic> json) {
    return ChartPatchItem(
      op: PatchOperation.values.byName(json['op'] as String),
      targetId: json['targetId'] as String?,
      value: json['value'] as Map<String, dynamic>?,
      targetSlot: json['targetSlot'] as int?,
      toIndex: json['toIndex'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'scope': scope.name,
    'op': op.name,
    if (targetId != null) 'targetId': targetId,
    if (value != null) 'value': value,
    if (targetSlot != null) 'targetSlot': targetSlot,
    if (toIndex != null) 'toIndex': toIndex,
  };
}

class ChildPatchItem extends PatchOperationItem {
  final String targetId;
  final String? childId;
  final dynamic value;

  const ChildPatchItem({
    required super.scope,
    required super.op,
    required this.targetId,
    this.childId,
    this.value,
  });

  factory ChildPatchItem.fromJson(Map<String, dynamic> json, PatchScope scope) {
    return ChildPatchItem(
      scope: scope,
      op: PatchOperation.values.byName(json['op'] as String),
      targetId: json['targetId'] as String,
      childId: json['childId'] as String?,
      value: json['value'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'scope': scope.name,
    'op': op.name,
    'targetId': targetId,
    if (childId != null) 'childId': childId,
    if (value != null) 'value': value,
  };
}

class DimensionsPatchItem extends PatchOperationItem {
  final String? childId;
  final dynamic value;

  const DimensionsPatchItem({required super.op, this.childId, this.value})
    : super(scope: PatchScope.dimensions);

  factory DimensionsPatchItem.fromJson(Map<String, dynamic> json) {
    return DimensionsPatchItem(
      op: PatchOperation.values.byName(json['op'] as String),
      childId: json['childId'] as String?,
      value: json['value'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'scope': scope.name,
    'op': op.name,
    if (childId != null) 'childId': childId,
    if (value != null) 'value': value,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// OTHER PACKETS
// ─────────────────────────────────────────────────────────────────────────────

class ErrorPacket extends StreamPacket {
  final int code;
  final String message;
  final ErrorSeverity severity;

  const ErrorPacket({
    required super.docId,
    required this.code,
    required this.message,
    this.severity = ErrorSeverity.critical,
  }) : super(packetType: PacketType.error);

  factory ErrorPacket.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? json;
    return ErrorPacket(
      docId: (json['docId'] ?? '') as String,
      code: payload['code'] as int,
      message: payload['message'] as String,
      severity: payload['severity'] != null
          ? ErrorSeverity.values.byName(payload['severity'] as String)
          : ErrorSeverity.critical,
    );
  }
}

class BusyPacket extends StreamPacket {
  final String? message;
  final double? progress;

  const BusyPacket({required super.docId, this.message, this.progress})
    : super(packetType: PacketType.busy);

  factory BusyPacket.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? json;
    return BusyPacket(
      docId: (json['docId'] ?? '') as String,
      message: payload['message'] as String?,
      progress: (payload['progress'] as num?)?.toDouble(),
    );
  }
}
