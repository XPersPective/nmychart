import 'package:flutter/foundation.dart';
import '../../models/chartset_document.dart';
import '../../models/chartset_document_meta.dart';
import '../../models/stream_packets.dart';
import '../math/patch_engine.dart';

class ChartSetDocumentState extends ChangeNotifier {
  ChartSetDocument? _document;
  final PatchEngine _patchEngine = PatchEngine();

  ChartSetDocument? get document => _document;
  bool get hasData => _document != null;

  void applySnapshot(ChartSetDocument newDocument) {
    _document = newDocument;
    notifyListeners();
  }

  void applyPatch(PatchPacket packet) {
    if (_document == null) return;
    try {
      var newDoc = _patchEngine.apply(_document!, packet);
      if (packet.revision != null) {
        newDoc = ChartSetDocument(
          meta: ChartSetDocumentMeta(
            id: newDoc.meta.id,
            packetType: newDoc.meta.packetType,
            type: newDoc.meta.type,
            subType: newDoc.meta.subType,
            coordinateSystem: newDoc.meta.coordinateSystem,
            schemaVersion: newDoc.meta.schemaVersion,
            revision: packet.revision!,
            updatedAt: newDoc.meta.updatedAt,
          ),
          layout: newDoc.layout,
          visualSettings: newDoc.visualSettings,
          dimensions: newDoc.dimensions,
          baseAxisData: newDoc.baseAxisData,
          charts: newDoc.charts,
        );
      }
      _document = newDoc;
      notifyListeners();
    } catch (e) {
      debugPrint('Patch err: $e');
    }
  }
}
