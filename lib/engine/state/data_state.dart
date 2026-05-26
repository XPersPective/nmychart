import 'package:flutter/foundation.dart';
 import '../../models/chart.dart';
import '../../models/chartset_document.dart';
import '../../models/stream_packets.dart';
 

class DataState extends ChangeNotifier {
  final List<dynamic> _baseAxisData = [];
  final Map<String, Map<String, List<dynamic>>> _chartColumns = {};

  List<dynamic> get baseAxisData => _baseAxisData;
  Map<String, Map<String, List<dynamic>>> get chartColumns => _chartColumns;
  int get length => _baseAxisData.length;

  void notify() {
    notifyListeners();
  }

  void applySnapshot(ChartSetDocument document) {
    _baseAxisData.clear();
    _chartColumns.clear();

    _baseAxisData.addAll(document.baseAxisData);

    for (final slot in document.charts) {
      for (final chart in slot) {
        initChartColumns(chart);
      }
    }
    notifyListeners();
  }

  void initChartColumns(Chart chart) {
    final chartId = chart.meta.id;
    final fields = chart.fields;
    final data = chart.data;
    final columns = <String, List<dynamic>>{};

    for (final field in fields) {
      columns[field.id] = <dynamic>[];
    }

    for (final row in data) {
      for (var i = 0; i < fields.length; i++) {
        final value = (i < row.length) ? row[i] : null;
        columns[fields[i].id]!.add(value);
      }
    }
    _chartColumns[chartId] = columns;
  }

  void applyData(DataPacket packet, ChartSetDocument document) {
    bool changed = false;
    switch (packet) {
      case UpdateDataPacket p:
        changed = _handleUpdate(p, document);
      case AppendDataPacket p:
        changed = _handleAppend(p, document);
      case PrependDataPacket p:
        changed = _handlePrepend(p, document);
      case OverwriteDataPacket p:
        changed = _handleOverwrite(p, document);
      case ClearDataPacket _:
        changed = _handleClear();
    }
    if (changed) notifyListeners(); // Sadece degisiklik varsa repaint at
  }

  bool _handleUpdate(UpdateDataPacket packet, ChartSetDocument document) {
    if (_baseAxisData.isEmpty) return false;
    if (packet.baseAxisData != null && packet.baseAxisData!.isNotEmpty) {
      _baseAxisData[_baseAxisData.length - 1] = packet.baseAxisData!.last;
    }
    if (packet.charts != null) {
      _updateChartValues(packet.charts!, document, (column, values) {
        if (column.isNotEmpty) {
          int count = values.length;
          int startIndexCol = column.length - count;
          if (startIndexCol < 0) startIndexCol = 0; // fallback safety
          for (
            var i = 0;
            i < count && (startIndexCol + i) < column.length;
            i++
          ) {
            column[startIndexCol + i] = values[i];
          }
        }
      });
    }
    return true;
  }

  bool _handleAppend(AppendDataPacket packet, ChartSetDocument document) {
    if (packet.baseAxisData != null) {
      _baseAxisData.addAll(packet.baseAxisData!);
    }
    if (packet.charts != null) {
      _updateChartValues(packet.charts!, document, (column, values) {
        column.addAll(values);
      });
    }
    return true;
  }

  bool _handlePrepend(PrependDataPacket packet, ChartSetDocument document) {
    if (packet.baseAxisData != null) {
      _baseAxisData.insertAll(0, packet.baseAxisData!);
    }
    if (packet.charts != null) {
      _updateChartValues(packet.charts!, document, (column, values) {
        column.insertAll(0, values);
      });
    }
    return true;
  }

  bool _handleOverwrite(OverwriteDataPacket packet, ChartSetDocument document) {
    final startIndex = packet.startIndex;
    if (startIndex == 0) {
      if (packet.baseAxisData != null) {
        _baseAxisData.clear();
        _baseAxisData.addAll(packet.baseAxisData!);
      }
      if (packet.charts != null) {
        // Clear all existing chart columns
        for (final entry in _chartColumns.entries) {
          for (final colEntry in entry.value.entries) {
            colEntry.value.clear();
          }
        }
        _updateChartValues(packet.charts!, document, (column, values) {
          column.addAll(values);
        });
      }
      return true;
    }

    if (packet.baseAxisData != null) {
      final realIdx = startIndex < 0
          ? _baseAxisData.length + startIndex
          : startIndex;
      final length = packet.baseAxisData!.length;
      if (realIdx < 0 || realIdx + length > _baseAxisData.length) {
        if (kDebugMode) {
          debugPrint(
            '[DataState] _handleOverwrite: baseAxisData sınır dışı '
            '(realIdx=$realIdx, length=$length, listLength=${_baseAxisData.length})',
          );
        }
        return false;
      }
      _baseAxisData.setRange(realIdx, realIdx + length, packet.baseAxisData!);
    }
    if (packet.charts != null) {
      _updateChartValues(packet.charts!, document, (column, values) {
        final realIdx = startIndex < 0
            ? column.length + startIndex
            : startIndex;
        if (realIdx < 0 || realIdx + values.length > column.length) {
          if (kDebugMode) {
            debugPrint(
              '[DataState] _handleOverwrite: chart column sınır dışı '
              '(realIdx=$realIdx, length=${values.length}, colLength=${column.length})',
            );
          }
          return;
        }
        column.setRange(realIdx, realIdx + values.length, values);
      });
    }
    return true;
  }

  bool _handleClear() {
    if (_baseAxisData.isEmpty && _chartColumns.isEmpty) return false;
    _baseAxisData.clear();
    _chartColumns.clear();
    return true;
  }

  void _updateChartValues(
    Map<String, ChartDataPayload> payload,
    ChartSetDocument document,
    void Function(List<dynamic> column, List<dynamic> values) updater,
  ) {
    for (final entry in payload.entries) {
      final chartId = entry.key;
      final fieldsData = entry.value.fields;
      final columns = _chartColumns[chartId];
      if (columns == null) continue;

      for (final fieldEntry in fieldsData.entries) {
        final col = columns[fieldEntry.key];
        if (col != null) {
          updater(col, fieldEntry.value);
        }
      }
    }
  }
}
