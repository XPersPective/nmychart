import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/stream_packets.dart';
import 'chart_network_service.dart';

/// Gerçek sunucuya WebSocket üzerinden bağlanan üretim (Production) servisi.
///
/// Kullanım (DI ile enjekte edilir):
/// ```dart
/// final networkService = RealChartNetworkService(
///   url: 'ws://192.168.1.100:8080/chart',
/// );
/// // Dependency injection ile sağlayıcıya kaydedin.
/// ```
class RealChartNetworkService implements ChartNetworkService {
  final String url;

  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Yeniden bağlanma denemesi sayacı
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  Timer? _reconnectTimer;
  bool _disposed = false;

  RealChartNetworkService({required this.url});

  @override
  Stream<Map<String, dynamic>> get packetStream => _controller.stream;

  @override
  Future<void> connect() async {
    if (_disposed) return;

    try {
      // Eski bağlantı varsa kapat
      await _channelSub?.cancel();
      _channelSub = null;
      await _channel?.sink.close();

      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri);

      // WebSocket bağlantı onayını bekle
      await _channel!.ready;

      _reconnectAttempts = 0; // Başarılı bağlantı — sayacı sıfırla

      if (kDebugMode) {
        debugPrint('[RealChartNetworkService] Sunucuya bağlandı: $url');
      }

      // Sunucudan gelen mesajları dinle
      _channelSub = _channel!.stream.listen(
        (message) {
          try {
            final json = jsonDecode(message as String) as Map<String, dynamic>;
            _controller.add(json);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[RealChartNetworkService] JSON parse hatası: $e');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            debugPrint('[RealChartNetworkService] WebSocket hatası: $error');
          }
          _tryReconnect();
        },
        onDone: () {
          if (kDebugMode) {
            debugPrint('[RealChartNetworkService] WebSocket bağlantısı kapandı');
          }
          _tryReconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RealChartNetworkService] Bağlantı hatası: $e');
      }
      _tryReconnect();
    }
  }

  @override
  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channelSub?.cancel();
    _channelSub = null;
    _channel?.sink.close();
    _controller.close();

    if (kDebugMode) {
      debugPrint('[RealChartNetworkService] Bağlantı kesildi');
    }
  }

  @override
  void sendPatch(PatchPacket patch) {
    if (_channel == null) {
      if (kDebugMode) {
        debugPrint('[RealChartNetworkService] Bağlantı yok, patch gönderilemedi');
      }
      return;
    }

    try {
      final jsonStr = jsonEncode(patch.toJson());
      _channel!.sink.add(jsonStr);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RealChartNetworkService] Patch gönderim hatası: $e');
      }
    }
  }

  @override
  void requestHistoricalData() {
    // Send historical data request via websocket
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // RECONNECT LOGIC
  // ─────────────────────────────────────────────────────────────────────────────
  void _tryReconnect() {
    if (_disposed) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (kDebugMode) {
        debugPrint(
          '[RealChartNetworkService] Maksimum yeniden bağlanma denemesi aşıldı ($_maxReconnectAttempts)',
        );
      }
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts; // Linear backoff

    if (kDebugMode) {
      debugPrint(
        '[RealChartNetworkService] ${delay.inSeconds}s sonra yeniden bağlanılacak '
        '(Deneme: $_reconnectAttempts/$_maxReconnectAttempts)',
      );
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }
}
