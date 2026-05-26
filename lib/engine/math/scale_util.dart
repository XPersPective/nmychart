import '../state/viewport_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCALE — Koordinat Dönüşüm Matematiği
// ─────────────────────────────────────────────────────────────────────────────
//
// Roadmap §5.2:
//   X Ekseni (index → pixel):
//     pixelX = (dataIndex - viewport.startIndex) * candleWidth
//
//   Y Ekseni (value → pixel):
//     pixelY = chartHeight - ((value - visibleMin) / (visibleMax - visibleMin)) * chartHeight
//
//   Ters Dönüşüm (Crosshair — pixel → value):
//     dataIndex = floor(pixelX / candleWidth) + viewport.startIndex
//     value     = visibleMax - (pixelY / chartHeight) * (visibleMax - visibleMin)
// ─────────────────────────────────────────────────────────────────────────────

class Scale {
  final ViewportState viewport;
  final double chartWidth;
  final double chartHeight;
  final double visibleMin;
  final double visibleMax;

  const Scale({
    required this.viewport,
    required this.chartWidth,
    required this.chartHeight,
    required this.visibleMin,
    required this.visibleMax,
  });

  double get _candleWidth => viewport.candleWidth;

  double get _valueRange => visibleMax - visibleMin;

  // ──────────── İLERİ DÖNÜŞÜM (data → pixel) ────────────

  /// X: dataIndex → pixelX
  ///
  /// Roadmap §5.2: pixelX = (dataIndex - viewport.startIndex) * candleWidth
  double indexToPixelX(int dataIndex) {
    return (dataIndex - viewport.startIndex) * _candleWidth;
  }

  /// Y: value → pixelY
  ///
  /// Roadmap §5.2: pixelY = chartHeight - ((value - visibleMin) / (visibleMax - visibleMin)) * chartHeight
  double valueToPixelY(double value) {
    if (_valueRange == 0) return chartHeight / 2;
    return chartHeight - ((value - visibleMin) / _valueRange) * chartHeight;
  }

  // ──────────── TERS DÖNÜŞÜM (pixel → data) ────────────

  /// X: pixelX → dataIndex
  ///
  /// Roadmap §5.2: dataIndex = floor(pixelX / candleWidth) + viewport.startIndex
  int pixelXToIndex(double pixelX) {
    if (_candleWidth <= 0) return viewport.startIndex.toInt();
    return (pixelX / _candleWidth).floor() + viewport.startIndex.toInt();
  }

  /// Y: pixelY → value
  ///
  /// Roadmap §5.2: value = visibleMax - (pixelY / chartHeight) * (visibleMax - visibleMin)
  double pixelYToValue(double pixelY) {
    if (chartHeight <= 0) return visibleMin;
    return visibleMax - (pixelY / chartHeight) * _valueRange;
  }
}
