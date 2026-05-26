import '../../../models/chartset_document.dart';
import '../../../models/chart.dart';
import '../../../models/stream_packets.dart';
import '../../../models/enums.dart';

// Import all cons for root implementations
import '../../../models/chartset_document_meta.dart';
import '../../../models/layout.dart';
import '../../../models/visual_settings.dart';
import '../../../models/dimensions.dart';
import '../../../models/plot.dart';
import '../../../models/input.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PATCH ENGINE — WARM hat operasyonları
// ─────────────────────────────────────────────────────────────────────────────
class PatchException implements Exception {
  final String message;
  const PatchException(this.message);

  @override
  String toString() => 'PatchException: $message';
}

class PatchEngine {
  /// Patch operasyonlarını uygula, yeni ChartSetDocument döndür
  ChartSetDocument apply(ChartSetDocument document, PatchPacket packet) {
    var currentDocument = document;

    for (final operation in packet.operations) {
      currentDocument = switch (operation) {
        RootPatchItem item => _applyRootPatch(currentDocument, item),
        ChartPatchItem item => _applyChartPatch(currentDocument, item),
        ChildPatchItem item => _applyChildPatch(currentDocument, item),
        DimensionsPatchItem item => _applyDimensionsPatch(currentDocument, item),
      };
    }

    return currentDocument;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ROOT SCOPE
  // ─────────────────────────────────────────────────────────────────────────────
  ChartSetDocument _applyRootPatch(ChartSetDocument document, RootPatchItem item) {
    // Op is always replace for RootPatchItem
    final path = item.path;
    final value = item.value as Map<String, dynamic>;

    if (path == 'meta') {
      return ChartSetDocument(
        meta: ChartSetDocumentMeta.fromJson(value),
        layout: document.layout,
        visualSettings: document.visualSettings,
        dimensions: document.dimensions,
        baseAxisData: document.baseAxisData,
        charts: document.charts,
      );
    } else if (path == 'layout') {
      return ChartSetDocument(
        meta: document.meta,
        layout: Layout.fromJson(value),
        visualSettings: document.visualSettings,
        dimensions: document.dimensions,
        baseAxisData: document.baseAxisData,
        charts: document.charts,
      );
    } else if (path == 'visualSettings') {
      return ChartSetDocument(
        meta: document.meta,
        layout: document.layout,
        visualSettings: VisualSettings.fromJson(value),
        dimensions: document.dimensions,
        baseAxisData: document.baseAxisData,
        charts: document.charts,
      );
    } else if (path == 'dimensions') {
      return ChartSetDocument(
        meta: document.meta,
        layout: document.layout,
        visualSettings: document.visualSettings,
        dimensions: Dimensions.fromJson(value),
        baseAxisData: document.baseAxisData,
        charts: document.charts,
      );
    }

    throw PatchException('Root scope için geçersiz path: $path');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CHART SCOPE
  // ─────────────────────────────────────────────────────────────────────────────
  ChartSetDocument _applyChartPatch(ChartSetDocument document, ChartPatchItem item) {
    final targetId = item.targetId;
    if (targetId == null && item.op != PatchOperation.add) {
      // Add işleminde targetId olmayabilir?
      // Aslında ChartPatchItem.targetId opsiyonel ama add harici işlemlerde gerekli.
      // Add işleminde eğer 'replace' gibi davranıyorsa targetSlot veya ID gerekir.
      // Add işleminde ID, value içinde gelir.
    }
    // Ancak ChartPatchItem'da targetId nullable.

    // Add işlemi için targetId kullanmıyoruz, targetSlot kullanıyoruz.
    // Diğerleri için targetId şart.
    if (item.op != PatchOperation.add && targetId == null) {
      throw PatchException(
        'Chart scope add harici işlemler için "targetId" alanı zorunludur',
      );
    }

    return switch (item.op) {
      PatchOperation.replace => _replaceInChart(document, item),
      PatchOperation.add => _addChart(document, item),
      PatchOperation.remove => _removeChart(document, targetId!),
      PatchOperation.move => _moveChart(document, item),
    };
  }

  ChartSetDocument _replaceInChart(ChartSetDocument document, ChartPatchItem item) {
    final targetId = item.targetId!;
    final value = item.value;

    if (value == null) {
      throw PatchException('Replace işlemi için value gereklidir');
    }

    // Yeni chart oluştur
    final newChart = Chart.fromJson(value);
    if (newChart.meta.id != targetId) {
      throw PatchException(
        'Chart ID değişimi ("replace") desteklenmez (Target: $targetId, New: ${newChart.meta.id})',
      );
    }

    // Chart listesini güncelle
    final newCharts = document.charts.map((slot) {
      return slot.map((chart) {
        if (chart.meta.id == targetId) {
          return newChart;
        }
        return chart;
      }).toList();
    }).toList();

    return _copyWithDocument(document, charts: newCharts);
  }

  ChartSetDocument _addChart(ChartSetDocument document, ChartPatchItem item) {
    final targetSlot = item.targetSlot ?? 0;
    final value = item.value;

    if (value == null) throw PatchException('Add işlemi için value gereklidir');

    final newChart = Chart.fromJson(value);

    // Mevcut slotları kopyala
    final newCharts = [
      for (final slot in document.charts) [...slot],
    ];

    // Hedef slot yoksa gerekli sayıda boş slot oluştur
    while (newCharts.length <= targetSlot) {
      newCharts.add([]);
    }

    // Chart'ı hedef slota ekle
    newCharts[targetSlot].add(newChart);

    return _copyWithDocument(document, charts: newCharts);
  }

  ChartSetDocument _removeChart(ChartSetDocument document, String targetId) {
    final newCharts = document.charts
        .map((slot) => slot.where((c) => c.meta.id != targetId).toList())
        .toList();
    return _copyWithDocument(document, charts: newCharts);
  }

  ChartSetDocument _moveChart(ChartSetDocument document, ChartPatchItem item) {
    final targetId = item.targetId!;
    final toIndex = item.toIndex;
    final targetSlot = item.targetSlot;

    if (toIndex == null) {
      throw PatchException('Move işlemi için "toIndex" gereklidir');
    }

    // Chart'ı ve bulunduğu slotu bul
    Chart? chartToMove;
    int fromSlotIndex = -1;

    for (var i = 0; i < document.charts.length; i++) {
      final found = document.charts[i].where((c) => c.meta.id == targetId);
      if (found.isNotEmpty) {
        chartToMove = found.first;
        fromSlotIndex = i;
        break;
      }
    }

    if (chartToMove == null) {
      throw PatchException('Taşınacak chart bulunamadı: $targetId');
    }

    // 1. Chart'ı eski yerinden çıkar
    var newCharts = document.charts
        .map((slot) => [...slot])
        .toList(); // Deep copy list structure
    newCharts[fromSlotIndex].removeWhere((c) => c.meta.id == targetId);

    // 2. Yeni yere ekle
    final destSlotIndex = targetSlot ?? fromSlotIndex;

    // Slot yetersizse genişlet
    while (newCharts.length <= destSlotIndex) {
      newCharts.add([]);
    }

    // Index kontrolü
    final destSlot = newCharts[destSlotIndex];
    final safeIndex = toIndex.clamp(0, destSlot.length);
    newCharts[destSlotIndex].insert(safeIndex, chartToMove);

    return _copyWithDocument(document, charts: newCharts);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CHILD SCOPE (PLOT / INPUT)
  // ─────────────────────────────────────────────────────────────────────────────
  ChartSetDocument _applyChildPatch(ChartSetDocument document, ChildPatchItem item) {
    // ChildPatchItem içinde targetId non-nullable.
    // childId nullable
    final targetId = item.targetId;
    final childId = item.childId;
    final op = item.op;
    final scope = item.scope;

    // Eğer remove değilse childId opsiyonel olabilir (add durumunda genelde childId yeni ID'dir ama value içinde gelir)
    if (op != PatchOperation.add && childId == null) {
      throw PatchException(
        '${scope.name} scope remove/replace/move için "childId" gerektirir',
      );
    }

    final newCharts = document.charts.map((slot) {
      return slot.map((chart) {
        if (chart.meta.id != targetId) {
          return chart;
        }

        // Hedef chart bulundu, kopyalayarak güncelle
        return _updateChartChildren(chart, item);
      }).toList();
    }).toList();

    return _copyWithDocument(document, charts: newCharts);
  }

  Chart _updateChartChildren(Chart chart, ChildPatchItem item) {
    final op = item.op;
    final value = item.value;
    final scope = item.scope;

    // PLOT OPERASYONLARI
    if (scope == PatchScope.plot) {
      var plots = [...chart.plots];

      if (op == PatchOperation.add) {
        final newPlot = Plot.fromJson(value as Map<String, dynamic>);
        plots.add(newPlot);
      } else if (op == PatchOperation.remove) {
        plots.removeWhere((p) => p.id == item.childId);
      } else if (op == PatchOperation.replace) {
        final index = plots.indexWhere((p) => p.id == item.childId);
        if (index != -1) {
          final existingJson = plots[index].toJson();
          final mergedJson = _deepMerge(existingJson, value as Map<String, dynamic>);
          final newPlot = Plot.fromJson(mergedJson);
          plots[index] = newPlot;
        }
      }

      // Yeni Chart (manuel copyWith)
      return Chart(
        meta: chart.meta,
        legend: chart.legend,
        inputs: chart.inputs,
        fields: chart.fields,
        plots: plots, // Güncellenmiş liste
        data: chart.data,
        guides: chart.guides,
        notations: chart.notations,
      );
    }
    // INPUT OPERASYONLARI
    else if (scope == PatchScope.input) {
      var inputs = [...chart.inputs];

      if (op == PatchOperation.add) {
        final newInput = Input.fromJson(value as Map<String, dynamic>);
        inputs.add(newInput);
      } else if (op == PatchOperation.remove) {
        inputs.removeWhere((i) => i.id == item.childId);
      } else if (op == PatchOperation.replace) {
        final index = inputs.indexWhere((i) => i.id == item.childId);
        if (index != -1) {
          final existingJson = inputs[index].toJson();
          final mergedJson = _deepMerge(existingJson, value as Map<String, dynamic>);
          final newInput = Input.fromJson(mergedJson);
          inputs[index] = newInput;
        }
      }

      return Chart(
        meta: chart.meta,
        legend: chart.legend,
        inputs: inputs, // Güncellenmiş liste
        fields: chart.fields,
        plots: chart.plots,
        data: chart.data,
        guides: chart.guides,
        notations: chart.notations,
      );
    }

    return chart;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DIMENSIONS SCOPE
  // ─────────────────────────────────────────────────────────────────────────────
  ChartSetDocument _applyDimensionsPatch(
    ChartSetDocument document,
    DimensionsPatchItem item,
  ) {
    if (item.op == PatchOperation.replace && item.childId == 'baseAxis') {
      final baseAxis = document.dimensions.baseAxis;
      if (baseAxis is TimeBaseAxis) {
        final valMap = item.value as Map<String, dynamic>;
        final newTimezone = valMap['timezone'] as String;
        final newBaseAxis = TimeBaseAxis(
          id: baseAxis.id,
          axis: baseAxis.axis,
          title: baseAxis.title,
          grid: baseAxis.grid,
          isSorted: baseAxis.isSorted,
          isEquidistant: baseAxis.isEquidistant,
          gapPolicy: baseAxis.gapPolicy,
          timezone: newTimezone,
          timezoneDisplayMode: baseAxis.timezoneDisplayMode,
        );
        final newDimensions = Dimensions(
          baseAxis: newBaseAxis,
          valuesAxis: document.dimensions.valuesAxis,
        );
        return _copyWithDocument(document, dimensions: newDimensions);
      }
    }
    return document;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────────
  Map<String, dynamic> _deepMerge(Map<String, dynamic> target, Map<String, dynamic> source) {
    final result = Map<String, dynamic>.from(target);
    for (final key in source.keys) {
      if (source[key] is Map<String, dynamic> && result[key] is Map<String, dynamic>) {
        result[key] = _deepMerge(
          result[key] as Map<String, dynamic>,
          source[key] as Map<String, dynamic>,
        );
      } else {
        result[key] = source[key];
      }
    }
    return result;
  }

  ChartSetDocument _copyWithDocument(
    ChartSetDocument document, {
    ChartSetDocumentMeta? meta,
    Layout? layout,
    VisualSettings? visualSettings,
    Dimensions? dimensions,
    List<dynamic>? baseAxisData,
    List<List<Chart>>? charts,
  }) {
    return ChartSetDocument(
      meta: meta ?? document.meta,
      layout: layout ?? document.layout,
      visualSettings: visualSettings ?? document.visualSettings,
      dimensions: dimensions ?? document.dimensions,
      baseAxisData: baseAxisData ?? document.baseAxisData,
      charts: charts ?? document.charts,
    );
  }
}
