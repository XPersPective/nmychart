import 'package:flutter/material.dart';
import '../math/scale_util.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CANDLESTICK PAINTER — OHLC candlestick çizimi
// ─────────────────────────────────────────────────────────────────────────────
//
// Roadmap §6.2 CandlestickPlot:
//   open, high, low, close fields + upColor, downColor
// ─────────────────────────────────────────────────────────────────────────────

class CandlestickPainter extends CustomPainter {
  final Scale scale;
  final List<dynamic> openValues;
  final List<dynamic> highValues;
  final List<dynamic> lowValues;
  final List<dynamic> closeValues;
  final Color upColor;
  final Color downColor;
  final bool showLastValue;

  CandlestickPainter({
    required this.scale,
    required this.openValues,
    required this.highValues,
    required this.lowValues,
    required this.closeValues,
    required this.upColor,
    required this.downColor,
    this.showLastValue = false,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (openValues.isEmpty) return;

    final startIdx = scale.viewport.startIndex.toInt();
    final endIdx = (scale.viewport.startIndex + scale.viewport.visibleCount)
        .toInt();
    final candleW = scale.viewport.candleWidth;

    // Mum genişliği (candle body) — candle aralığının %70'i
    final bodyWidth = candleW * 0.7;
    final wickWidth = 1.0;

    for (
      int i = startIdx < 0 ? 0 : startIdx;
      i < endIdx &&
          i < openValues.length &&
          i < highValues.length &&
          i < lowValues.length &&
          i < closeValues.length;
      i++
    ) {
      if (openValues[i] == null ||
          highValues[i] == null ||
          lowValues[i] == null ||
          closeValues[i] == null) {
        continue;
      }

      final open = (openValues[i] as num).toDouble();
      final high = (highValues[i] as num).toDouble();
      final low = (lowValues[i] as num).toDouble();
      final close = (closeValues[i] as num).toDouble();

      final isUp = close >= open;
      final color = isUp ? upColor : downColor;

      final centerX = scale.indexToPixelX((i.toInt())) + candleW / 2;
      final openY = scale.valueToPixelY(open);
      final highY = scale.valueToPixelY(high);
      final lowY = scale.valueToPixelY(low);
      final closeY = scale.valueToPixelY(close);

      // Fitil (wick/shadow)
      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = wickWidth
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(centerX, highY), Offset(centerX, lowY), wickPaint);

      // Gövde (body)
      final bodyTop = isUp ? closeY : openY;
      final bodyBottom = isUp ? openY : closeY;
      final bodyHeight = (bodyBottom - bodyTop).abs();

      final bodyPaint = Paint()
        ..color = color
        ..style = bodyHeight < 1 ? PaintingStyle.stroke : PaintingStyle.fill;

      final bodyRect = Rect.fromLTWH(
        centerX - bodyWidth / 2,
        bodyTop,
        bodyWidth,
        bodyHeight < 1 ? 1 : bodyHeight,
      );

      canvas.drawRect(bodyRect, bodyPaint);
    }

    if (showLastValue && closeValues.isNotEmpty) {
      double? lastVal;
      Color? lastColor;
      for (int i = closeValues.length - 1; i >= 0; i--) {
        if (closeValues[i] != null && openValues[i] != null) {
          lastVal = (closeValues[i] as num).toDouble();
          final openVal = (openValues[i] as num).toDouble();
          lastColor = lastVal >= openVal ? upColor : downColor;
          break;
        }
      }
      if (lastVal != null) {
        final y = scale.valueToPixelY(lastVal);
        final linePaint = Paint()
          ..color = (lastColor ?? upColor).withValues(alpha: 0.4)
          ..strokeWidth = 0.3
          ..style = PaintingStyle.stroke;
        const dashWidth = 3.0;
        const dashSpace = 5.0;
        double startX = 0.0;
        while (startX < scale.chartWidth) {
          canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), linePaint);
          startX += dashWidth + dashSpace;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CandlestickPainter oldDelegate) => true;
}
