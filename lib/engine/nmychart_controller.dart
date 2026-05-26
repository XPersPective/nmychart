import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/input.dart';
import '../models/stream_packets.dart';
import '../models/enums.dart';
import '../services/chart_network_service.dart';
import 'state/chartset_document_state.dart';

/// Host App ile NmyChart grafik motoru arasında girdi (input)
/// alışverişini ve güncellemelerini yöneten Controller sınıfı.
class NmyChartController extends ChangeNotifier {
  ChartSetDocumentState? _documentState;
  ChartNetworkService? _networkService;

  List<Input> _inputs = [];

  final _errorController = StreamController<String>.broadcast();
  Stream<String> get errors => _errorController.stream;
  void dispatchError(String msg) => _errorController.add(msg);

  /// Grafik dökümanındaki tüm güncel girdiler.
  List<Input> get inputs => _inputs;

  /// Grafik motorunun veriye sahip olup olmadığı.
  bool get hasData => _documentState?.hasData ?? false;

  /// Dahili olarak döküman state'ine ve ağ servisine bağlanır.
  /// Bu metot NmyChart widget'ı tarafından otomatik olarak çağrılır.
  void bind(
    ChartSetDocumentState documentState,
    ChartNetworkService networkService,
  ) {
    // Eski bağı temizle
    unbind();

    _documentState = documentState;
    _networkService = networkService;

    _documentState?.addListener(_onDocumentChanged);

    // İlk senkronizasyonu build fazı dışına ertele.
    // bind() genellikle initState içinde çağrıldığından, doğrudan
    // notifyListeners() çağırmak "setState() called during build" hatasına
    // yol açar. scheduleMicrotask bu çağrıyı güvenli bir zamana erteler.
    scheduleMicrotask(_onDocumentChanged);
  }

  @override
  void dispose() {
    unbind();
    _errorController.close();
    super.dispose();
  }

  /// Dahili bağı çözer.
  void unbind() {
    _documentState?.removeListener(_onDocumentChanged);
    _documentState = null;
    _networkService = null;
  }

  /// Girdileri günceller. Verilen girdiler mevcut girdilerle eşleştirilip
  /// bir PatchPacket oluşturulur ve sunucuya/ağ servisine gönderilir.
  void updateInputs(List<Input> updatedInputs) {
    final doc = _documentState?.document;
    final network = _networkService;

    if (doc == null || network == null) {
      if (kDebugMode) {
        debugPrint(
          '[NmyChartController] Girdi güncellemesi başarısız: State veya ağ servisi bağlı değil.',
        );
      }
      return;
    }

    final operations = <PatchOperationItem>[];

    for (final updatedInput in updatedInputs) {
      String? targetChartId;

      // Güncellenen girdinin hangi grafik paneline ait olduğunu bul
      for (final slot in doc.charts) {
        for (final chart in slot) {
          if (chart.inputs.any((i) => i.id == updatedInput.id)) {
            targetChartId = chart.meta.id;
            break;
          }
        }
        if (targetChartId != null) break;
      }

      if (targetChartId == null) {
        if (kDebugMode) {
          debugPrint(
            '[NmyChartController] ID\'si "${updatedInput.id}" olan girdi dökümanda bulunamadı.',
          );
        }
        continue;
      }

      operations.add(
        ChildPatchItem(
          scope: PatchScope.input,
          op: PatchOperation.replace,
          targetId: targetChartId,
          childId: updatedInput.id,
          value: updatedInput.toJson(),
        ),
      );
    }

    if (operations.isNotEmpty) {
      final patchPacket = PatchPacket(
        docId: doc.meta.id,
        revision: doc.meta.revision + 1,
        operations: operations,
      );
      network.sendPatch(patchPacket);
    }
  }

  void _onDocumentChanged() {
    // scheduleMicrotask ile ertelenmiş çağrılarda, bind çözülmüşse güvenle çık.
    if (_documentState == null) return;

    final doc = _documentState?.document;
    if (doc == null) {
      _inputs = const [];
    } else {
      final allInputs = <Input>[];
      for (final slot in doc.charts) {
        for (final chart in slot) {
          allInputs.addAll(chart.inputs);
        }
      }
      _inputs = List.unmodifiable(allInputs);
    }
    notifyListeners();
  }

  /// Grafikteki sembolü (ör. "BTC/USDT") değiştirir.
  void setSymbol(String symbol) {
    try {
      final symbolInput = _inputs.whereType<SymbolInput>().first;
      final updatedInput = symbolInput.copyWith(
        value: symbol,
        base: symbol.split('/').first,
        quote: symbol.split('/').last,
      );
      updateInputs([updatedInput]);
    } catch (e) {
      if (kDebugMode) debugPrint('[NmyChartController] setSymbol failed: $e');
    }
  }

  /// Grafikteki periyodu (ör. "1H", "1D") değiştirir.
  void setInterval(String interval) {
    try {
      final intervalInput = _inputs.whereType<IntervalInput>().first;
      final updatedInput = intervalInput.copyWith(value: interval);
      updateInputs([updatedInput]);
    } catch (e) {
      if (kDebugMode) debugPrint('[NmyChartController] setInterval failed: $e');
    }
  }

  void setTheme(String themeMode) {
    try {
      final doc = _documentState?.document;
      final network = _networkService;
      if (doc == null || network == null) return;

      final newVisualSettings = {
        "theme": themeMode,
        "crosshair": {
          "mode": doc.visualSettings.crosshair.mode,
          "style": doc.visualSettings.crosshair.style.name,
          "color": doc.visualSettings.crosshair.color,
          "showLabels": doc.visualSettings.crosshair.showLabels,
        },
        "legend": {
          "position": doc.visualSettings.legend.position.name,
          "orientation": doc.visualSettings.legend.orientation.name,
        },
        "tooltip": {
          "position": doc.visualSettings.tooltip.position.name,
          "orientation": doc.visualSettings.tooltip.orientation.name,
        },
      };

      final patchPacket = PatchPacket(
        docId: doc.meta.id,
        revision: doc.meta.revision + 1,
        operations: [
          RootPatchItem(path: 'visualSettings', value: newVisualSettings),
        ],
      );
      network.sendPatch(patchPacket);
    } catch (e) {
      if (kDebugMode) debugPrint('[NmyChartController] setTheme failed: $e');
    }
  }

  /// Grafiğe yeni bir indikatör ekler (örn: "MA" veya "RSI").
  void addIndicator(String type) {
    final doc = _documentState?.document;
    final network = _networkService;

    if (doc == null || network == null) {
      if (kDebugMode) {
        debugPrint(
          '[NmyChartController] İndikatör ekleme başarısız: State veya ağ servisi bağlı değil.',
        );
      }
      return;
    }

    final String normalizedType = type.toUpperCase();
    late final Map<String, dynamic> newChartJson;
    final String targetChartId =
        normalizedType.contains('RSI') ? 'rsi_001' : 'ma_001';

    if (normalizedType.contains('MA')) {
      newChartJson = {
        "meta": {
          "id": "ma_001",
          "name": "Moving Average",
          "shortName": "MA",
          "description": "Simple Moving Average",
          "type": "financial",
          "subType": "trading",
          "category": "indicator",
          "subCategory": "trend",
          "allowedCoordinateSystems": ["cartesian"],
          "requiresOrderedData": true,
          "placement": "overlay",
          "provider": "system",
          "visibility": "public",
          "author": "anonymous",
          "version": "1.0.0",
          "createdAt": 1676985600000,
          "updatedAt": 1676998700000,
        },
        "legend": {
          "visible": true,
          "items": [
            {
              "id": "item_1",
              "type": "input",
              "refId": "in_ma_length",
              "keys": ["value"],
              "template": "MA {value}",
            },
            {"id": "item_2", "type": "plot", "refId": "plot_ma"},
          ],
        },
        "inputs": [
          {
            "id": "in_ma_length",
            "name": "Length",
            "type": "integer",
            "value": 14,
          },
        ],
        "fields": [
          {"id": "f_time", "name": "Time", "type": "dateTime"},
          {"id": "f_ma", "name": "MA 14", "type": "double"},
        ],
        "plots": [
          {
            "id": "plot_ma",
            "type": "line",
            "dataForm": "scalar",
            "axis": "y",
            "visible": true,
            "showLastValue": true,
            "affectsScale": true,
            "value": "f_ma",
            "color": "#1890FF",
            "style": "solid",
          },
        ],
        "data": [],
        "guides": [],
        "notations": [],
      };
    } else if (normalizedType.contains('RSI')) {
      newChartJson = {
        "meta": {
          "id": "rsi_001",
          "name": "Relative Strength Index",
          "shortName": "RSI",
          "description": "RSI Indicator",
          "type": "financial",
          "subType": "trading",
          "category": "indicator",
          "subCategory": "oscillator",
          "allowedCoordinateSystems": ["cartesian"],
          "requiresOrderedData": true,
          "placement": "separate",
          "provider": "system",
          "visibility": "public",
          "author": "anonymous",
          "version": "1.0.0",
          "createdAt": 1676985600000,
          "updatedAt": 1676998700000,
        },
        "legend": {
          "visible": true,
          "items": [
            {
              "id": "item_1",
              "type": "input",
              "refId": "in_rsi_length",
              "keys": ["value"],
              "template": "{value}",
            },
            {
              "id": "item_2",
              "type": "input",
              "refId": "in_rsi_lower",
              "keys": ["value"],
              "template": "{value}",
            },
            {
              "id": "item_3",
              "type": "input",
              "refId": "in_rsi_upper",
              "keys": ["value"],
              "template": "{value}",
            },
            {"id": "item_4", "type": "plot", "refId": "plot_rsi"},
          ],
        },
        "inputs": [
          {
            "id": "in_rsi_length",
            "name": "RSI Length",
            "type": "integer",
            "value": 14,
          },
          {
            "id": "in_rsi_lower",
            "name": "Lower Bound",
            "type": "double",
            "value": 30.0,
          },
          {
            "id": "in_rsi_upper",
            "name": "Upper Bound",
            "type": "double",
            "value": 70.0,
          },
        ],
        "fields": [
          {"id": "f_time", "name": "Time", "type": "dateTime"},
          {"id": "f_rsi", "name": "RSI", "type": "double"},
        ],
        "plots": [
          {
            "id": "plot_rsi",
            "type": "line",
            "dataForm": "scalar",
            "axis": "y",
            "visible": true,
            "showLastValue": true,
            "affectsScale": true,
            "value": "f_rsi",
            "color": "#9C27B0",
            "style": "solid",
          },
        ],
        "data": [],
        "guides": [
          {
            "id": "guide_rsi_upper",
            "type": "line",
            "axis": "y",
            "visible": true,
            "affectsScale": false,
            "value": "in_rsi_upper",
            "color": "#888888",
            "style": "dashed",
          },
          {
            "id": "guide_rsi_lower",
            "type": "line",
            "axis": "y",
            "visible": true,
            "affectsScale": false,
            "value": "in_rsi_lower",
            "color": "#888888",
            "style": "dashed",
          },
          {
            "id": "guide_rsi_band",
            "type": "band",
            "axis": "y",
            "visible": true,
            "affectsScale": false,
            "upper": "in_rsi_upper",
            "lower": "in_rsi_lower",
            "upperColor": "#888888",
            "lowerColor": "#888888",
            "fillColor": "#9C27B01A",
          },
        ],
        "notations": [],
      };
    } else {
      if (kDebugMode) {
        debugPrint('[NmyChartController] Bilinmeyen indikatör türü: $type');
      }
      return;
    }

    final int targetSlot = normalizedType.contains('RSI') ? 2 : 0;

    for (final slot in doc.charts) {
      for (final chart in slot) {
        if (chart.meta.id == targetChartId) {
          if (kDebugMode) {
            debugPrint(
              '[NmyChartController] İndikatör zaten mevcut: $targetChartId',
            );
          }
          return;
        }
      }
    }

    final patchPacket = PatchPacket(
      docId: doc.meta.id,
      revision: doc.meta.revision + 1,
      operations: [
        ChartPatchItem(
          op: PatchOperation.add,
          targetSlot: targetSlot,
          value: newChartJson,
        ),
      ],
    );

    network.sendPatch(patchPacket);
  }
}
