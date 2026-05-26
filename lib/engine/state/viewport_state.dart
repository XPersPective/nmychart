import 'dart:math';
import 'package:flutter/foundation.dart';

class YScale {
  final double min;
  final double max;
  const YScale({required this.min, required this.max});
}

class ViewportState extends ChangeNotifier {
  final Map<int, YScale> _manualYScale = {};

  YScale? getManualYScale(int slotIndex) => _manualYScale[slotIndex];

  void setManualYScale(int slotIndex, double min, double max) {
    _manualYScale[slotIndex] = YScale(min: min, max: max);
    notifyListeners();
  }

  void clearManualYScale(int slotIndex) {
    if (_manualYScale.containsKey(slotIndex)) {
      _manualYScale.remove(slotIndex);
      notifyListeners();
    }
  }
  double _startIndex = 0.0;
  int _visibleCount = 100;
  final int _maxVisibleCount = 1000;
  final int _minVisibleCount = 10;
  double _candleWidth = 5.0; // Ekrana göre hesaplanacak

  double? _crosshairX;

  double get startIndex => _startIndex;
  int get visibleCount => _visibleCount;
  double get candleWidth => _candleWidth;
  double? get crosshairX => _crosshairX;

  int? maximizedSlotIndex;

  void toggleMaximize(int slotIndex) {
    if (maximizedSlotIndex == slotIndex) {
      maximizedSlotIndex = null;
    } else {
      maximizedSlotIndex = slotIndex;
    }
    notifyListeners();
  }

  void zoomBy(double factor, int maxDataLength) {
    final double containerWidth = _candleWidth * _visibleCount;
    if (containerWidth <= 0) return;
    
    // Zoom around the center of the screen
    final double focalPointX = containerWidth / 2;
    final double itemIndexAtFocal = _startIndex + (focalPointX / _candleWidth);
    
    _visibleCount = (_visibleCount / factor).round();
    final int maxAllowed = max(
      min(_maxVisibleCount, maxDataLength),
      _minVisibleCount,
    );
    _visibleCount = _visibleCount.clamp(_minVisibleCount, maxAllowed);
    
    _candleWidth = containerWidth / _visibleCount;
    _startIndex = itemIndexAtFocal - (focalPointX / _candleWidth);
    
    final double minStart = -(_visibleCount * 0.9);
    final double maxStart = maxDataLength.toDouble() - (_visibleCount * 0.1);
    if (_startIndex < minStart) _startIndex = minStart;
    if (_startIndex > maxStart) _startIndex = maxStart;
    
    notifyListeners();
  }

  void panBy(double items, int maxDataLength) {
    _startIndex += items;
    final double minStart = -(_visibleCount * 0.9);
    final double maxStart = maxDataLength.toDouble() - (_visibleCount * 0.1);
    if (_startIndex < minStart) _startIndex = minStart;
    if (_startIndex > maxStart) _startIndex = maxStart;
    notifyListeners();
  }

  void updateCrosshair(double? x) {
    if (_crosshairX != x) {
      _crosshairX = x;
      notifyListeners();
    }
  }

  /// Ekran boyutu değiştiğinde mum genişliğini ve görünür sayıyı günceller.
  ///
  /// **Not:** Bu metot kasıtlı olarak `notifyListeners()` çağırmaz.
  /// `build()` içinde `LayoutBuilder` aracılığıyla çağrıldığı için,
  /// `notifyListeners()` çağırmak sonsuz rebuild döngüsüne yol açar.
  /// Güncellenen `_candleWidth` ve `_visibleCount` değerleri aynı build
  /// geçişinde senkron olarak tüketilir, bu nedenle bildirim gereksizdir.
  void updateScreenSize(double containerWidth, int maxDataLength) {
    if (containerWidth <= 0 || maxDataLength == 0) return;

    // Default count
    if (_visibleCount > maxDataLength) {
      _visibleCount = max(maxDataLength, _minVisibleCount);
    }
    if (_visibleCount < _minVisibleCount) {
      _visibleCount = _minVisibleCount;
    }

    _candleWidth = containerWidth / _visibleCount;
  }

  void pan(double dx, int maxDataLength) {
    final double itemsToScroll = dx / _candleWidth;
    _startIndex -= itemsToScroll;

    final double minStart = -(_visibleCount * 0.9);
    final double maxStart = maxDataLength.toDouble() - (_visibleCount * 0.1);

    if (_startIndex < minStart) _startIndex = minStart;
    if (_startIndex > maxStart) _startIndex = maxStart;
    notifyListeners();
  }

  void zoom(
    double factor,
    double focalPointX,
    double containerWidth,
    int maxDataLength,
  ) {
    _visibleCount = (_visibleCount / factor).round();

    final int maxAllowed = max(
      min(_maxVisibleCount, maxDataLength),
      _minVisibleCount,
    );
    _visibleCount = _visibleCount.clamp(_minVisibleCount, maxAllowed);

    // Focal point logic
    // We want the item under focalPointX to remain under focalPointX.
    final itemsLeftOfFocal = focalPointX / _candleWidth;
    final itemIndexAtFocal = _startIndex + itemsLeftOfFocal;

    _candleWidth = containerWidth / _visibleCount;

    final newItemsLeftOfFocal = focalPointX / _candleWidth;
    _startIndex = itemIndexAtFocal - newItemsLeftOfFocal;

    final double minStart = -(_visibleCount * 0.9);
    final double maxStart = maxDataLength.toDouble() - (_visibleCount * 0.1);

    if (_startIndex < minStart) _startIndex = minStart;
    if (_startIndex > maxStart) _startIndex = maxStart;
    notifyListeners();
  }

  void scrollToStart(int maxDataLength) {
    _startIndex = 0.0;
    notifyListeners();
  }

  void scrollToEnd(int maxDataLength) {
    _startIndex = maxDataLength.toDouble() - _visibleCount * 0.9;
    if (_startIndex < -(_visibleCount * 0.9)) {
      _startIndex = -(_visibleCount * 0.9);
    }
    notifyListeners();
  }

  bool isAtEnd(int maxDataLength) {
    final double maxStart = maxDataLength.toDouble() - (_visibleCount * 0.9);
    return _startIndex >= (maxStart - 1.0); // 1 item tolerance
  }

  void shift(double offset, int maxDataLength) {
    _startIndex += offset;
    final double maxStart = maxDataLength.toDouble() - (_visibleCount * 0.1);
    if (_startIndex > maxStart) _startIndex = maxStart;
    notifyListeners();
  }

  void reset() {
    _startIndex = 0.0;
    _visibleCount = 100;
    notifyListeners();
  }
}
