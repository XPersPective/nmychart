import 'package:flutter/foundation.dart';
import '../../../models/chart.dart';
import '../state/chartset_document_state.dart';
import '../state/data_state.dart';
import '../state/viewport_state.dart';
import '../../../models/chartset_document.dart';
import '../../../models/stream_packets.dart';
import '../../../models/enums.dart';
import '../nmychart_controller.dart';

class ProtocolException implements Exception {
  final String message;
  const ProtocolException(this.message);

  @override
  String toString() => 'ProtocolException: $message';
}

class PacketRouter {
  final ChartSetDocumentState chartSetDocumentState;
  final DataState dataState;
  final ViewportState viewportState;
  final NmyChartController? controller;

  int _lastRevision = 0;

  PacketRouter({
    required this.chartSetDocumentState,
    required this.dataState,
    required this.viewportState,
    this.controller,
  });

  void route(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>?;
    final packet = json['packet'] as Map<String, dynamic>?;

    late final PacketType type;

    final rawType = (meta != null && meta.containsKey('packetType'))
        ? meta['packetType'] as String
        : (packet != null && packet.containsKey('packetType'))
            ? packet['packetType'] as String
            : json.containsKey('packetType')
                ? json['packetType'] as String
                : null;

    if (rawType == null) {
      throw const ProtocolException('packetType alanı bulunamadı.');
    }

    try {
      type = PacketType.values.byName(rawType);
    } on ArgumentError {
      if (kDebugMode) {
        debugPrint(
          '[PacketRouter] Bilinmeyen packetType: "$rawType", paket atlandı.',
        );
      }
      return;
    }

    if (packet != null && packet.containsKey('revision')) {
      final incomingRevision = packet['revision'] as int;
      if (incomingRevision <= _lastRevision) return; // stale
      if (incomingRevision > _lastRevision + 1) {
        if (kDebugMode) {
          debugPrint(
            '[PacketRouter] Revizyon boşluğu tespit edildi: '
            'beklenen=${_lastRevision + 1}, gelen=$incomingRevision',
          );
        }
      }
      _lastRevision = incomingRevision;
    }

    switch (type) {
      case PacketType.snapshot:
        final document = ChartSetDocument.fromJson(json);
        chartSetDocumentState.applySnapshot(document);
        dataState.applySnapshot(document);
        viewportState.reset();
        viewportState.scrollToEnd(dataState.length);
        break;
      case PacketType.data:
        if (chartSetDocumentState.hasData) {
          final p = DataPacket.fromJson(json);
          final oldLength = dataState.length;
          dataState.applyData(p, chartSetDocumentState.document!);
          final diffCount = dataState.length - oldLength;
          
          if (diffCount > 0) {
            if (p is PrependDataPacket) {
              // Prepend always shifts existing indices, so we must shift the viewport to maintain position
              viewportState.shift(diffCount.toDouble(), dataState.length);
            } else if (p is AppendDataPacket) {
              // Append only shifts viewport if we are already at the end
              if (viewportState.isAtEnd(oldLength)) {
                viewportState.shift(diffCount.toDouble(), dataState.length);
              }
            }
          }
        }
        break;
      case PacketType.patch:
        final p = PatchPacket.fromJson(json);
        chartSetDocumentState.applyPatch(p);
        
        // If a new chart was added, initialize its columns in DataState
        for (final op in p.operations) {
          if (op is ChartPatchItem && op.op == PatchOperation.add && op.value != null) {
            try {
              final chart = Chart.fromJson(op.value!);
              dataState.initChartColumns(chart);
              dataState.notify();
            } catch (e) {
              debugPrint("Error initializing chart data: $e");
            }
          } else if (op is ChartPatchItem && op.op == PatchOperation.remove && op.targetId != null) {
            dataState.chartColumns.remove(op.targetId);
          }
        }
        break;
      case PacketType.busy:
        // Optional overlay logic
        break;
      case PacketType.error:
        final payload = json['payload'] as Map<String, dynamic>?;
        final msg = payload?['message'] ?? 'Error';
        controller?.dispatchError(msg);
        break;
    }
  }
}
