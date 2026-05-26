import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'services/chart_network_service.dart';
import 'services/real_chart_network_service.dart';
import 'services/static_chart_network_service.dart';
import 'services/mock_chart_network_service.dart';
import 'engine/nmychart_controller.dart';

// ─── EXPORTS ───────────────────────────────────────────────────────────────
// Bu dosya paketin ana giriş noktasıdır. Kullanıcıların sadece bu dosyayı
// import etmesi yeterlidir.

// Servisler
export 'services/chart_network_service.dart';
export 'services/real_chart_network_service.dart';
export 'services/static_chart_network_service.dart';
export 'services/mock_chart_network_service.dart';

// Engine
export 'engine/nmychart_controller.dart';
// Note: ChartSetDocumentWidget is internal now, wrapped by NmyChart.
import 'engine/layout/chartset_document_widget.dart';

// Modeller
export 'models/models.dart';

// ─── NMYCHART FACADE WIDGET ──────────────────────────────────────────────────

/// NmyChart Grafik Motorunun ana giriş (entry-point) widget'ı.
///
/// Motorun dış dünyadan yalıtılmış ve esnek kullanılmasını sağlayan yapıdır.
/// En çok kullanılan senaryolar için isimlendirilmiş kurucular (named constructors) sunar.
class NmyChart extends StatefulWidget {
  final ChartNetworkService networkService;
  final NmyChartController? controller;
  
  /// İçeride yaratılan servisin bağlantı ömrünün (connect/disconnect)
  /// motor tarafından yönetilip yönetilmeyeceğini belirler.
  final bool _ownsService;

  /// KENDİ AĞ SERVİSİNİ GETİR:
  /// Kendi yazdığınız veya harici olarak yönettiğiniz bir [ChartNetworkService]
  /// implementasyonunu kullanmak için bu kurucuyu çağırın.
  /// Not: Bu kullanımda [connect] ve [disconnect] çağrıları sizin sorumluluğunuzdadır.
  const NmyChart.custom({
    super.key,
    required this.networkService,
    this.controller,
  }) : _ownsService = false;

  /// GERÇEK SUNUCU:
  /// Verilen WebSocket [url] adresi üzerinden sunucuya bağlanır.
  /// Servis yaratımı, bağlantı başlatma ve kapatma işlemleri motor tarafından otomatik yönetilir.
  NmyChart.real({
    super.key,
    required String url,
    this.controller,
  })  : networkService = RealChartNetworkService(url: url),
        _ownsService = true;

  /// STATİK / ÇEVRİMDIŞI VERİ:
  /// Sabit bir JSON [snapshot] verisi ile grafiği başlatır. İnternet bağlantısı gerektirmez.
  /// Servis yönetimi motor tarafından otomatik yönetilir.
  NmyChart.staticData({
    super.key,
    required Map<String, dynamic> snapshot,
    this.controller,
  })  : networkService = StaticChartNetworkService(snapshot: snapshot),
        _ownsService = true;

  /// MOCK / TEST VERİSİ:
  /// Rastgele üretilen sahte borsa verileriyle uygulamayı test etmek içindir.
  /// Servis yönetimi motor tarafından otomatik yönetilir.
  NmyChart.mock({
    super.key,
    this.controller,
  })  : networkService = MockChartNetworkService(),
        _ownsService = true;

  @override
  State<NmyChart> createState() => _NmyChartState();
}

class _NmyChartState extends State<NmyChart> {
  StreamSubscription<String>? _errorSub;

  @override
  void initState() {
    super.initState();
    // Eğer servisi biz (NmyChart) yarattıysak, bağlantıyı da biz başlatıyoruz.
    if (widget._ownsService) {
      widget.networkService.connect().catchError((e) {
        if (kDebugMode) {
          debugPrint('[NmyChart] Network connection error: $e');
        }
      });
    }

    _errorSub = widget.controller?.errors.listen((msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    });
  }

  @override
  void dispose() {
    // Eğer servisi biz yarattıysak, kapatırken temizliğini de biz yapıyoruz.
    if (widget._ownsService) {
      widget.networkService.disconnect();
    }
    _errorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Temel çizim motoruna gerekli parametreleri pasla
    return ChartSetDocumentWidget(
      networkService: widget.networkService,
      controller: widget.controller,
    );
  }
}
