import 'chartset_document_meta.dart';
import 'layout.dart';
import 'visual_settings.dart';
import 'dimensions.dart';
import 'chart.dart';

/// ChartSetDocument — Snapshot paketi ile oluşan kök model.
/// Tüm config ağacını ve başlangıç verisini barındırır.
class ChartSetDocument {
  final ChartSetDocumentMeta meta;
  final Layout layout;
  final VisualSettings visualSettings;
  final Dimensions dimensions;
  final List<dynamic> baseAxisData;
  final List<List<Chart>> charts;

  const ChartSetDocument({
    required this.meta,
    required this.layout,
    required this.visualSettings,
    required this.dimensions,
    required this.baseAxisData,
    required this.charts,
  });

  factory ChartSetDocument.fromJson(Map<String, dynamic> json) {
    return ChartSetDocument(
      meta: ChartSetDocumentMeta.fromJson(json['meta'] as Map<String, dynamic>),
      layout: Layout.fromJson(json['layout'] as Map<String, dynamic>),
      visualSettings: VisualSettings.fromJson(
        json['visualSettings'] as Map<String, dynamic>,
      ),
      dimensions: Dimensions.fromJson(
        json['dimensions'] as Map<String, dynamic>,
      ),
      baseAxisData: (json['baseAxisData'] as List).toList(),
      charts: (json['charts'] as List)
          .map<List<Chart>>(
            (slot) => (slot as List)
                .map<Chart>(
                  (chart) =>
                      Chart.fromJson(chart as Map<String, dynamic>),
                )
                .toList(),
          )
          .toList(),
    );
  }
}
