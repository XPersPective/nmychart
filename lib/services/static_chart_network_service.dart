import 'dart:async';
import '../models/stream_packets.dart';
import 'chart_network_service.dart';

/// Statik JSON snapshot'lar ile çalışan, sunucusuz (Offline) ağ servisi.
///
/// Girdi değişiklikleri (patch) yapıldığında, sunucu varmış gibi
/// bu değişiklikleri doğrudan geri yansıtarak (echo) yerel etkileşimi simüle eder.
class StaticChartNetworkService implements ChartNetworkService {
  final Map<String, dynamic> snapshot;
  late StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _connected = false;

  StaticChartNetworkService({required this.snapshot});

  @override
  Stream<Map<String, dynamic>> get packetStream => _controller.stream;

  @override
  Future<void> connect() async {
    if (_connected) return;
    _connected = true;

    // Kapatılmış controller varsa yenisini oluştur
    if (_controller.isClosed) {
      _controller = StreamController<Map<String, dynamic>>.broadcast();
    }

    // Dinleyicilerin hazır olması için kısa bir gecikme sonrası snapshot'ı gönder
    await Future.delayed(const Duration(milliseconds: 50));
    if (_connected) {
      _controller.add(snapshot);
    }
  }

  @override
  void disconnect() {
    _controller.close();
    _connected = false;
  }

  @override
  void sendPatch(PatchPacket patch) {
    if (!_connected) return;

    // Sunucu gibi davranarak gönderilen patch paketini doğrudan geri yayınlar.
    // Bu sayede yerel döküman state'i güncellenir.
    _controller.add(patch.toJson());
  }

  @override
  void requestHistoricalData() {
    // Static service does not support pagination
  }
}
