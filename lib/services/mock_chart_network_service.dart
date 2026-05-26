import 'dart:async';
import 'dart:math';
import '../models/enums.dart';
import '../models/stream_packets.dart';
import 'chart_network_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MOCK CHART NETWORK SERVICE
// Geliştirme (Development) aşamasında kullanılacak, kendi içinde
// sahte bir sunucu ve sahte veri barındıran simülasyon servisi.
// ─────────────────────────────────────────────────────────────────────────────
class MockChartNetworkService implements ChartNetworkService {
  late StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  Timer? _timer;
  final Random _rand = Random();

  double _lastClose = 42125.5;
  double _lastRsi = 50.0;
  int _lastTime = 1704067200000 + (300 * 3600000);

  double _currentOpen = 42125.5;
  double _currentHigh = 42125.5;
  double _currentLow = 42125.5;

  String _currentSymbol = "BTC/USDT";
  String _currentInterval = "15m";
  final List<double> _historyCloses = [];
  final List<int> _historyTimes = [];
  final List<double> _recentCloses = [];

  // RSI için incremental hesaplama state'i
  double _avgGain = 0.0;
  double _avgLoss = 0.0;

  static final Map<String, Map<String, dynamic>> _activeIndicators = {};

  @override
  Stream<Map<String, dynamic>> get packetStream => _controller.stream;

  // ─────────────────────────────────────────────────────────────────────────
  // YARDIMCI: Gerçek RSI Hesaplama (Wilder Smoothing)
  // ─────────────────────────────────────────────────────────────────────────
  /// Verilen close fiyat listesinden Wilder'ın RSI formülüyle RSI serisi hesaplar.
  /// İlk `period` eleman için ortalama kazanç/kayıp alınır, sonrasında
  /// exponential smoothing uygulanır.
  static List<double> computeRsiSeries(List<double> closes, {int period = 14}) {
    final rsiValues = <double>[];
    if (closes.length < 2) {
      for (int i = 0; i < closes.length; i++) {
        rsiValues.add(50.0);
      }
      return rsiValues;
    }

    // İlk elemanın RSI'ı tanımsız, 50 doldur
    rsiValues.add(50.0);

    // Fark (delta) serisini oluştur
    final deltas = <double>[];
    for (int i = 1; i < closes.length; i++) {
      deltas.add(closes[i] - closes[i - 1]);
    }

    double avgGain = 0.0;
    double avgLoss = 0.0;

    for (int i = 0; i < deltas.length; i++) {
      final d = deltas[i];
      final gain = d > 0 ? d : 0.0;
      final loss = d < 0 ? -d : 0.0;

      if (i < period) {
        // İlk period eleman: basit ortalama
        avgGain += gain;
        avgLoss += loss;

        if (i == period - 1) {
          avgGain /= period;
          avgLoss /= period;
          final rs = avgLoss == 0 ? 100.0 : avgGain / avgLoss;
          final rsi = 100.0 - (100.0 / (1.0 + rs));
          rsiValues.add(rsi.clamp(0.0, 100.0));
        } else {
          rsiValues.add(50.0); // Henüz yeterli veri yok
        }
      } else {
        // Wilder smoothing
        avgGain = (avgGain * (period - 1) + gain) / period;
        avgLoss = (avgLoss * (period - 1) + loss) / period;
        final rs = avgLoss == 0 ? 100.0 : avgGain / avgLoss;
        final rsi = 100.0 - (100.0 / (1.0 + rs));
        rsiValues.add(rsi.clamp(0.0, 100.0));
      }
    }

    return rsiValues;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // YARDIMCI: SMA Hesaplama
  // ─────────────────────────────────────────────────────────────────────────
  static List<double> computeSmaSeries(List<double> closes, {int period = 14}) {
    final smaValues = <double>[];
    for (int i = 0; i < closes.length; i++) {
      if (i < period - 1) {
        // Yeterli veri yok, mevcut close kullan
        double sum = 0.0;
        for (int k = 0; k <= i; k++) {
          sum += closes[k];
        }
        smaValues.add(sum / (i + 1));
      } else {
        double sum = 0.0;
        for (int k = i - period + 1; k <= i; k++) {
          sum += closes[k];
        }
        smaValues.add(sum / period);
      }
    }
    return smaValues;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // YARDIMCI: Interval → milisaniye
  // ─────────────────────────────────────────────────────────────────────────
  static int intervalToMs(String interval) {
    switch (interval) {
      case "15m":
        return 15 * 60 * 1000;
      case "1H":
      case "1h":
        return 60 * 60 * 1000;
      case "4H":
      case "4h":
        return 4 * 60 * 60 * 1000;
      case "1D":
      case "1d":
        return 24 * 60 * 60 * 1000;
      default:
        return 60 * 60 * 1000;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // YARDIMCI: Sembol → başlangıç fiyatı
  // ─────────────────────────────────────────────────────────────────────────
  static double symbolToBasePrice(String symbol) {
    if (symbol == "SOL/USDT") return 145.2;
    if (symbol == "ETH/USDT") return 2250.5;
    if (symbol == "BTC/USDT") return 42125.5;
    return 100.0;
  }

  @override
  Future<void> connect() async {
    // Kapatılmış controller varsa yenisini oluştur
    if (_controller.isClosed) {
      _controller = StreamController<Map<String, dynamic>>.broadcast();
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final snapshot = generateSnapshot(
      symbol: _currentSymbol,
      interval: _currentInterval,
      outCloses: _historyCloses,
      outTimes: _historyTimes,
    );
    _controller.add(snapshot);

    _syncStateFromHistory();
    _startFakeDataStream();
  }

  /// _historyCloses ve _historyTimes'dan sonraki canlı akış için state'i senkronize eder.
  void _syncStateFromHistory() {
    _recentCloses.clear();
    for (int i = max(0, _historyCloses.length - 14);
        i < _historyCloses.length;
        i++) {
      _recentCloses.add(_historyCloses[i]);
    }
    _lastClose =
        _historyCloses.isNotEmpty ? _historyCloses.last : symbolToBasePrice(_currentSymbol);
    _lastTime =
        _historyTimes.isNotEmpty ? _historyTimes.last : 1704067200000;

    _currentOpen = _lastClose;
    _currentHigh = _lastClose;
    _currentLow = _lastClose;

    // RSI incremental state'i: son 15 close'dan hesapla
    if (_historyCloses.length >= 15) {
      final tail = _historyCloses.sublist(_historyCloses.length - 15);
      final rsiSeries = computeRsiSeries(tail, period: 14);
      _lastRsi = rsiSeries.last;
      // avgGain/avgLoss yaklaşık hesapla
      double ag = 0, al = 0;
      for (int i = 1; i < tail.length; i++) {
        final d = tail[i] - tail[i - 1];
        if (d > 0) {
          ag += d;
        } else {
          al += -d;
        }
      }
      _avgGain = ag / 14;
      _avgLoss = al / 14;
    } else {
      _lastRsi = 50.0;
      _avgGain = 0;
      _avgLoss = 0;
    }
  }

  @override
  void disconnect() {
    _timer?.cancel();
    _controller.close();
  }

  @override
  void sendPatch(PatchPacket patch) {
    // Ağ gecikmesi simülasyonu
    Future.delayed(const Duration(milliseconds: 200)).then((_) {
      if (_controller.isClosed) return;

      // 1. Sembol/Interval güncelleme kontrolü ve İndikatör Ekleme Kontrolü
      bool needsReset = false;
      String? newSymbol;
      String? newInterval;

      for (final op in patch.operations) {
        if (op is ChildPatchItem && op.scope == PatchScope.input) {
          if (op.childId == 'symbol') {
            newSymbol = op.value['value'] as String?;
            needsReset = true;
          } else if (op.childId == 'interval') {
            newInterval = op.value['value'] as String?;
            needsReset = true;
          }
        }
      }

      if (newSymbol != null) _currentSymbol = newSymbol;
      if (newInterval != null) _currentInterval = newInterval;

      // İndikatör ekleme durumunda geçmiş veri doldurma
      for (int i = 0; i < patch.operations.length; i++) {
        final op = patch.operations[i];
        if (op is ChartPatchItem &&
            op.op == PatchOperation.add &&
            op.value != null) {
          final value = Map<String, dynamic>.from(op.value!);
          final meta = value['meta'] as Map<String, dynamic>?;
          final String chartId = meta?['id'] ?? '';

          _activeIndicators[chartId] = Map<String, dynamic>.from(value);

          final List<List<dynamic>> chartData = [];
          if (chartId.startsWith('ma')) {
            final sma = computeSmaSeries(_historyCloses, period: 14);
            for (int k = 0; k < _historyTimes.length; k++) {
              chartData.add([_historyTimes[k], sma[k]]);
            }
          } else if (chartId.startsWith('rsi')) {
            final rsi = computeRsiSeries(_historyCloses, period: 14);
            for (int k = 0; k < _historyTimes.length; k++) {
              chartData.add([_historyTimes[k], rsi[k]]);
            }
          }
          value['data'] = chartData;
          patch.operations[i] = ChartPatchItem(
            op: op.op,
            targetId: op.targetId,
            targetSlot: op.targetSlot,
            toIndex: op.toIndex,
            value: value,
          );
        } else if (op is ChartPatchItem && op.op == PatchOperation.remove && op.targetId != null) {
          _activeIndicators.remove(op.targetId);
        }
      }

      // Değişikliği geri fırlatıyoruz (Ping-Pong / Echo)
      _controller.add(patch.toJson());

      if (needsReset) {
        _timer?.cancel();
        // Yeni snapshot üret ve snapshot paketi olarak gönder
        // Bu sayede döküman yapısı (meta, inputs) da güncellenecek
        Future.delayed(const Duration(milliseconds: 100)).then((_) {
          if (_controller.isClosed) return;


          final snapshot = generateSnapshot(
            symbol: _currentSymbol,
            interval: _currentInterval,
            outCloses: _historyCloses,
            outTimes: _historyTimes,
          );

          // Snapshot olarak gönder — PacketRouter döküman yapısını da yenileyecek
          _controller.add(snapshot);

          // State'i senkronize et ve akışa devam et
          _syncStateFromHistory();
          _startFakeDataStream();
        });
      }
    });
  }

  bool _isFetchingHistory = false;

  @override
  void requestHistoricalData() {
    if (_isFetchingHistory || _controller.isClosed) return;
    _isFetchingHistory = true;

    Future.delayed(const Duration(milliseconds: 600)).then((_) {
      if (_controller.isClosed) return;

      final int intervalMs = intervalToMs(_currentInterval);

      // Mevcut serinin ilk fiyatından geriye doğru ters random walk
      final double firstClose =
          _historyCloses.isNotEmpty ? _historyCloses.first : _lastClose;
      int firstTime =
          _historyTimes.isNotEmpty ? _historyTimes.first : _lastTime;

      final Random rand = Random();
      const int count = 50;

      // Geriye doğru close fiyatları üret
      List<double> newCloses = [];
      double c = firstClose;
      for (int i = 0; i < count; i++) {
        // Her adımda ufak bir değişim ekle (ters yönde gittiğimiz için)
        double changePercent = (rand.nextDouble() - 0.5) * 0.005;
        c = c * (1 - changePercent); // Ters yönde yürü
        newCloses.add(c);
      }
      // Listeyi tersine çevir (en eski → en yeni)
      newCloses = newCloses.reversed.toList();

      // Zaman damgaları (geriye doğru)
      int startTime = firstTime - (count * intervalMs);
      List<int> newTimes = [];
      for (int i = 0; i < count; i++) {
        newTimes.add(startTime + i * intervalMs);
      }

      // Birleşik seri: yeni + mevcut (MA ve RSI doğru hesaplansın diye)
      final allCloses = [...newCloses, ..._historyCloses];

      // SMA(14) hesapla — sadece yeni kısım için
      final allSma = computeSmaSeries(allCloses, period: 14);

      // RSI hesapla — sadece yeni kısım için
      final allRsi = computeRsiSeries(allCloses, period: 14);

      // OHLC verisini oluştur
      List<int> baseTime = [];
      List<List<dynamic>> priceData = [];
      List<List<dynamic>> volumeData = [];
      List<List<dynamic>> rsiData = [];

      for (int i = 0; i < count; i++) {
        final close = newCloses[i];
        final open = i > 0 ? newCloses[i - 1] : close * (1 - 0.001);
        double high = max(open, close) * (1 + rand.nextDouble() * 0.002);
        double low = min(open, close) * (1 - rand.nextDouble() * 0.002);
        if (close > high) high = close;
        if (close < low) low = close;

        final smaVal = allSma[i];
        final rsiVal = allRsi[i];

        String signal = "";
        if (i > 10 && rand.nextDouble() > 0.97) {
          signal = rand.nextBool() ? "BUY" : "SELL";
        }

        baseTime.add(newTimes[i]);
        priceData.add([newTimes[i], open, high, low, close, smaVal, signal]);

        double volume = 100 + rand.nextDouble() * 500;
        bool isBull = close >= open;
        volumeData.add([newTimes[i], volume, isBull ? "#089981" : "#F23645"]);

        rsiData.add([newTimes[i], rsiVal]);
      }

      // Geçmiş listeyi güncelle
      _historyTimes.insertAll(0, newTimes);
      _historyCloses.insertAll(0, newCloses);

      // MA verisi — sadece yeni kısıma ait
      final maData = <List<dynamic>>[];
      for (int i = 0; i < count; i++) {
        maData.add([newTimes[i], allSma[i]]);
      }

      // Prepend payload
      final chartsData = {
        "ohlc_001": {
          "f_time": priceData.map((e) => e[0]).toList(),
          "f_open": priceData.map((e) => e[1]).toList(),
          "f_high": priceData.map((e) => e[2]).toList(),
          "f_low": priceData.map((e) => e[3]).toList(),
          "f_close": priceData.map((e) => e[4]).toList(),
          "f_ma": priceData.map((e) => e[5]).toList(),
          "f_sig": priceData.map((e) => e[6]).toList(),
        },
        "ma_001": {
          "f_time": maData.map((e) => e[0]).toList(),
          "f_ma": maData.map((e) => e[1]).toList(),
        },
        "vol_001": {
          "f_time": volumeData.map((e) => e[0]).toList(),
          "f_volume": volumeData.map((e) => e[1]).toList(),
          "f_color": volumeData.map((e) => e[2]).toList(),
        },
        "rsi_001": {
          "f_time": rsiData.map((e) => e[0]).toList(),
          "f_rsi": rsiData.map((e) => e[1]).toList(),
        }
      };

      final packet = {
        "packet": {
          "packetType": "data",
          "docId": "doc_unique_999",
        },
        "payload": {
          "action": "prepend",
          "baseAxisData": baseTime,
          "charts": chartsData,
        },
      };

      _controller.add(packet);
      _isFetchingHistory = false;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SAHTE VERİ AKIŞI
  // ─────────────────────────────────────────────────────────────────────────────
  void _startFakeDataStream() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_controller.isClosed) return;

      final int intervalMs = intervalToMs(_currentInterval);

      bool append = _rand.nextDouble() > 0.8;

      if (append) {
        _lastTime += intervalMs;
        _lastClose = _lastClose +
            (_rand.nextDouble() - 0.5) * (_lastClose * 0.002);
        _currentOpen = _lastClose;
        _currentHigh = _currentOpen;
        _currentLow = _currentOpen;
      }

      double changePercent = (_rand.nextDouble() - 0.5) * 0.002;
      double close = _currentOpen * (1 + changePercent);

      if (close > _currentHigh) _currentHigh = close;
      if (close < _currentLow) _currentLow = close;

      // Volatilite simülasyonu wicks
      if (_rand.nextDouble() > 0.8) {
        _currentHigh += _rand.nextDouble() * (_lastClose * 0.001);
      }
      if (_rand.nextDouble() > 0.8) {
        _currentLow -= _rand.nextDouble() * (_lastClose * 0.001);
      }

      if (append) {
        _recentCloses.add(close);
        if (_recentCloses.length > 14) {
          _recentCloses.removeAt(0);
        }
        _historyCloses.add(close);
        _historyTimes.add(_lastTime);
      } else {
        if (_recentCloses.isNotEmpty) {
          _recentCloses[_recentCloses.length - 1] = close;
        } else {
          _recentCloses.add(close);
        }
        if (_historyCloses.isNotEmpty) {
          _historyCloses[_historyCloses.length - 1] = close;
        } else {
          _historyCloses.add(close);
        }
        if (_historyTimes.isNotEmpty) {
          _historyTimes[_historyTimes.length - 1] = _lastTime;
        } else {
          _historyTimes.add(_lastTime);
        }
      }

      // SMA(14) hesapla
      double sma14 = close;
      if (_recentCloses.isNotEmpty) {
        double sum = 0.0;
        for (final val in _recentCloses) {
          sum += val;
        }
        sma14 = sum / _recentCloses.length;
      }

      // RSI: incremental Wilder güncelleme
      if (append && _recentCloses.length >= 2) {
        final delta = close - (_recentCloses.length >= 2
            ? _recentCloses[_recentCloses.length - 2]
            : close);
        final gain = delta > 0 ? delta : 0.0;
        final loss = delta < 0 ? -delta : 0.0;
        _avgGain = (_avgGain * 13 + gain) / 14;
        _avgLoss = (_avgLoss * 13 + loss) / 14;
        final rs = _avgLoss == 0 ? 100.0 : _avgGain / _avgLoss;
        _lastRsi = (100.0 - (100.0 / (1.0 + rs))).clamp(0.0, 100.0);
      }

      double volume = 100 + _rand.nextDouble() * 500;
      bool isBull = close >= _currentOpen;

      final packet = {
        "packet": {
          "packetType": "data",
          "docId": "doc_unique_999",
        },
        "payload": {
          "action": append ? "append" : "update",
          "baseAxisData": [_lastTime],
          "charts": {
            "ohlc_001": {
              "f_time": [_lastTime],
              "f_open": [_currentOpen],
              "f_high": [_currentHigh],
              "f_low": [_currentLow],
              "f_close": [close],
            },
            "vol_001": {
              "f_time": [_lastTime],
              "f_volume": [volume],
              "f_color": [isBull ? "#089981" : "#F23645"],
            },
            if (_activeIndicators.containsKey('ma_001'))
              "ma_001": {
                "f_time": [_lastTime],
                "f_ma": [sma14],
              },
            if (_activeIndicators.containsKey('rsi_001'))
              "rsi_001": {
                "f_time": [_lastTime],
                "f_rsi": [_lastRsi],
              },
          },
        },
      };

      _controller.add(packet);

      if (append) {
        _lastClose = close;
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SAHTE SNAPSHOT VERİSİ
  // ─────────────────────────────────────────────────────────────────────────────
  /// Sahte snapshot verisi üretir. Test amaçlı dışarıdan da erişilebilir.
  static Map<String, dynamic> generateSnapshot({
    String symbol = "BTC/USDT",
    String interval = "15m",
    List<double>? outCloses,
    List<int>? outTimes,
  }) {
    final Random rand = Random(42);
    List<int> baseTime = [];
    List<double> closes = [];
    List<List<dynamic>> priceData = [];
    List<List<dynamic>> volumeData = [];

    int currentTime = 1704067200000;
    final int intervalMs = intervalToMs(interval);

    double close = symbolToBasePrice(symbol);

    if (outCloses != null) outCloses.clear();
    if (outTimes != null) outTimes.clear();

    for (int i = 0; i < 300; i++) {
      baseTime.add(currentTime);
      if (outTimes != null) outTimes.add(currentTime);

      double changePercent = (rand.nextDouble() - 0.5) * 0.005;
      double open = close;
      double high = open * (1 + rand.nextDouble() * 0.003);
      double low = open * (1 - rand.nextDouble() * 0.003);
      close = open * (1 + changePercent);

      if (close > high) high = close;
      if (close < low) low = close;

      closes.add(close);
      if (outCloses != null) outCloses.add(close);

      String signal = "";
      if (i > 10) {
        if (rand.nextDouble() > 0.97) {
          signal = "BUY";
        } else if (rand.nextDouble() > 0.97) {
          signal = "SELL";
        }
      }

      // MA ve RSI placeholder olarak ekliyoruz, sonra hesaplayacağız
      priceData.add([currentTime, open, high, low, close, 0.0, signal]);

      double volume = 100 + rand.nextDouble() * 500;
      bool isBull = close >= open;
      volumeData.add([currentTime, volume, isBull ? "#089981" : "#F23645"]);

      currentTime += intervalMs;
    }

    // SMA(14) hesapla
    final sma = computeSmaSeries(closes, period: 14);
    // RSI hesapla (gerçek Wilder formülü)
    final rsi = computeRsiSeries(closes, period: 14);

    // priceData'ya gerçek MA değerlerini yerleştir
    for (int i = 0; i < priceData.length; i++) {
      priceData[i][5] = sma[i];
    }

    // MA chart verisi
    final List<List<dynamic>> maData = [];
    for (int i = 0; i < closes.length; i++) {
      maData.add([baseTime[i], sma[i]]);
    }

    // RSI chart verisi
    final List<List<dynamic>> rsiData = [];
    for (int i = 0; i < closes.length; i++) {
      rsiData.add([baseTime[i], rsi[i]]);
    }

    final snapshot = {
      "meta": {
        "id": "doc_unique_999",
        "packetType": "snapshot",
        "type": "financial",
        "subType": "trading",
        "coordinateSystem": "cartesian",
        "schemaVersion": "1.0.0",
        "revision": 1,
        "updatedAt": 1707829200000,
      },
      "layout": {
        "type": "vertical",
        "resizable": true,
        "separatorSize": 4,
        "slots": [
          {"index": 0, "weight": 4.0, "minSize": 200},
          {"index": 1, "weight": 1.0, "minSize": 80},
          {"index": 2, "weight": 1.5, "minSize": 100},
        ],
      },
      "visualSettings": {
        "theme": "dark",
        "crosshair": {
          "mode": "visible",
          "style": "dashed",
          "color": "#888888",
          "showLabels": true,
        },
        "legend": {"position": "topLeft", "orientation": "horizontal"},
        "tooltip": {"position": "topLeft", "orientation": "horizontal"},
      },
      "dimensions": {
        "baseAxis": {
          "id": "axis_time",
          "axis": "x",
          "type": "time",
          "title": "Tarih",
          "isSorted": true,
          "isEquidistant": true,
          "gapPolicy": "skip",
          "timezone": "UTC",
          "timezoneDisplayMode": "source",
          "grid": {
            "visible": true,
            "color": "#2B3139",
            "style": "dashed",
            "width": 1.0,
          },
        },
        "valuesAxis": [
          {
            "id": "axis_price",
            "axis": "y",
            "type": "linear",
            "title": "Fiyat (USDT)",
            "autoScale": true,
            "grid": {
              "visible": true,
              "color": "#2B3139",
              "style": "dashed",
              "width": 1.0,
            },
          },
          {
            "id": "axis_volume",
            "axis": "y",
            "type": "linear",
            "title": "Hacim",
            "autoScale": true,
            "grid": {
              "visible": false,
              "color": "#2B3139",
              "style": "solid",
              "width": 1.0,
            },
          },
          {
            "id": "axis_rsi",
            "axis": "y",
            "type": "linear",
            "title": "RSI",
            "autoScale": false,
            "min": 0.0,
            "max": 100.0,
            "grid": {"visible": false},
          },
        ],
      },
      "baseAxisData": baseTime,
      "charts": <List<Map<String, dynamic>>>[
        // --------- SLOT 0: Mum Grafiği ---------
        <Map<String, dynamic>>[
          <String, dynamic>{
            "meta": {
              "id": "ohlc_001",
              "name": symbol == "BTC/USDT"
                  ? "Bitcoin / Tether"
                  : symbol == "ETH/USDT"
                      ? "Ethereum / Tether"
                      : symbol == "SOL/USDT"
                          ? "Solana / Tether"
                          : symbol,
              "shortName": symbol,
              "description": "Financial price chart",
              "type": "financial",
              "subType": "trading",
              "category": "primary",
              "subCategory": "trend",
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
                  "refId": "symbol",
                  "keys": ["value"],
                  "template": "{value}",
                },
                {
                  "id": "item_2",
                  "type": "input",
                  "refId": "interval",
                  "keys": ["value"],
                  "template": "{value}",
                },
                {"id": "item_3", "type": "plot", "refId": "plot_candlestick"},
              ],
            },
            "inputs": [
              {
                "id": "symbol",
                "name": "Symbol",
                "type": "symbol",
                "value": symbol,
                "base": symbol.split('/').first,
                "quote": symbol.split('/').last,
              },
              {
                "id": "interval",
                "name": "Interval",
                "type": "interval",
                "value": interval,
              },
            ],
            "fields": [
              {"id": "f_time", "name": "Time", "type": "dateTime"},
              {"id": "f_open", "name": "Open", "type": "double"},
              {"id": "f_high", "name": "High", "type": "double"},
              {"id": "f_low", "name": "Low", "type": "double"},
              {"id": "f_close", "name": "Close", "type": "double"},
              {"id": "f_ma", "name": "MA 14", "type": "double"},
              {"id": "f_sig", "name": "Signal", "type": "string"},
            ],
            "plots": [
              {
                "id": "plot_candlestick",
                "type": "candlestick",
                "dataForm": "ohlc",
                "axis": "y",
                "visible": true,
                "showLastValue": true,
                "affectsScale": true,
                "open": "f_open",
                "high": "f_high",
                "low": "f_low",
                "close": "f_close",
                "upColor": "#089981",
                "downColor": "#F23645",
              },
            ],
            "data": priceData,
            "guides": [],
            "notations": [
              {
                "id": "not_signals_001",
                "type": "marker",
                "axis": "y",
                "value": "f_sig",
                "anchor": "f_high",
                "visible": true,
                "affectsScale": false,
                "rules": {
                  "BUY": {
                    "text": "BUY",
                    "icon": "arrow_up",
                    "color": "#089981",
                    "position": "below",
                    "offset": 10.0,
                  },
                  "SELL": {
                    "text": "SELL",
                    "icon": "arrow_down",
                    "color": "#F23645",
                    "position": "above",
                    "offset": 10.0,
                  },
                },
              },
            ],
          },
        ],
        // --------- SLOT 1: Hacim ---------
        <Map<String, dynamic>>[
          <String, dynamic>{
            "meta": {
              "id": "vol_001",
              "name": "Volume",
              "shortName": "VOL",
              "description": "Trading volume",
              "type": "financial",
              "subType": "trading",
              "category": "indicator",
              "subCategory": "volume",
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
                {"id": "item_1", "type": "plot", "refId": "plot_volume"},
              ],
            },
            "inputs": [],
            "fields": [
              {"id": "f_time", "name": "Time", "type": "dateTime"},
              {"id": "f_volume", "name": "Volume", "type": "double"},
              {"id": "f_color", "name": "Color", "type": "string"},
            ],
            "plots": [
              {
                "id": "plot_volume",
                "type": "bar",
                "dataForm": "scalar",
                "axis": "y",
                "visible": true,
                "affectsScale": true,
                "value": "f_volume",
                "color": "#888888",
                "upColor": "#089981",
                "downColor": "#F23645",
              },
            ],
            "data": volumeData,
            "guides": [],
            "notations": [],
          },
        ],
      ],
    };

    for (final entry in _activeIndicators.entries) {
      final chartId = entry.key;
      final def = Map<String, dynamic>.from(entry.value);
      final chartData = <List<dynamic>>[];
      if (chartId.startsWith('ma')) {
        for (int i = 0; i < closes.length; i++) {
          chartData.add([baseTime[i], sma[i]]);
        }
        def['data'] = chartData;
        (snapshot["charts"] as List)[0].add(def);
      } else if (chartId.startsWith('rsi')) {
        for (int i = 0; i < closes.length; i++) {
          chartData.add([baseTime[i], rsi[i]]);
        }
        def['data'] = chartData;
        
        final chartsList = snapshot["charts"] as List<List<Map<String, dynamic>>>;
        while (chartsList.length <= 3) {
          chartsList.add(<Map<String, dynamic>>[]);
        }
        chartsList[2].add(def);
      }
    }

    return snapshot;
  }
}
