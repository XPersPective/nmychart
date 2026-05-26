import 'enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SEALED LEGEND ITEM
// ─────────────────────────────────────────────────────────────────────────────

sealed class LegendItem {
  final String id;
  final LegendItemType type;
  final String refId;

  const LegendItem({required this.id, required this.type, required this.refId});

  factory LegendItem.fromJson(Map<String, dynamic> json) {
    final itemType = LegendItemType.values.byName(json['type'] as String);
    return switch (itemType) {
      LegendItemType.input => InputLegendItem.fromJson(json),
      LegendItemType.plot => PlotLegendItem.fromJson(json),
      LegendItemType.notation => NotationLegendItem.fromJson(json),
    };
  }
}

class InputLegendItem extends LegendItem {
  final List<String> keys;
  final String template;

  const InputLegendItem({
    required super.id,
    required super.refId,
    required this.keys,
    required this.template,
  }) : super(type: LegendItemType.input);

  factory InputLegendItem.fromJson(Map<String, dynamic> json) {
    return InputLegendItem(
      id: json['id'] as String,
      refId: json['refId'] as String,
      keys: (json['keys'] as List).cast<String>(),
      template: json['template'] as String,
    );
  }
}

class PlotLegendItem extends LegendItem {
  const PlotLegendItem({required super.id, required super.refId})
    : super(type: LegendItemType.plot);

  factory PlotLegendItem.fromJson(Map<String, dynamic> json) {
    return PlotLegendItem(
      id: json['id'] as String,
      refId: json['refId'] as String,
    );
  }
}

class NotationLegendItem extends LegendItem {
  const NotationLegendItem({required super.id, required super.refId})
    : super(type: LegendItemType.notation);

  factory NotationLegendItem.fromJson(Map<String, dynamic> json) {
    return NotationLegendItem(
      id: json['id'] as String,
      refId: json['refId'] as String,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHART LEGEND CONFIG
// ─────────────────────────────────────────────────────────────────────────────

class ChartLegend {
  final bool visible;
  final List<LegendItem> items;

  const ChartLegend({required this.visible, required this.items});

  factory ChartLegend.fromJson(Map<String, dynamic> json) {
    return ChartLegend(
      visible: json['visible'] as bool,
      items: (json['items'] as List)
          .map((e) => LegendItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
