import 'dart:async';
import '../models/stream_packets.dart';

/// Tüm ağ servislerinin uyması gereken soyut (abstract) kurallar.
///
/// Uygulamalar:
/// - [MockChartNetworkService] → Geliştirme ortamı (mock_chart_network_service.dart)
/// - [RealChartNetworkService] → Üretim ortamı (real_chart_network_service.dart)
abstract class ChartNetworkService {
  /// Sunucudan gelen (Snapshot, Patch, Data) paketlerini dinlediğimiz kanal
  Stream<Map<String, dynamic>> get packetStream;

  /// Sunucuya bağlanır
  Future<void> connect();

  /// Sunucu bağlantısını keser
  void disconnect();

  /// Arayüzden sunucuya bir değişiklik (Patch) gönderir
  void sendPatch(PatchPacket patch);

  /// Geçmiş veriyi talep eder (Infinite Scroll / Pagination)
  void requestHistoricalData();
}
