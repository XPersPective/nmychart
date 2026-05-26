import 'package:flutter/material.dart';
import '../math/scale_util.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BAR PAINTER — Scalar bar/histogram çizimi
// ─────────────────────────────────────────────────────────────────────────────

class BarPainter extends CustomPainter {
  final Scale scale;
  final List<dynamic> values;
  final Color color;
  final List<dynamic>? colorValues;
  final Color? upColor;
  final Color? downColor;
  final bool showLastValue;

  BarPainter({
    required this.scale,
    required this.values,
    required this.color,
    this.colorValues,
    this.upColor,
    this.downColor,
    this.showLastValue = false,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final startIdx = scale.viewport.startIndex.toInt();
    final endIdx = (scale.viewport.startIndex + scale.viewport.visibleCount)
        .toInt();
    final candleW = scale.viewport.candleWidth;
    final barWidth = candleW * 0.7;
    final zeroY = scale.valueToPixelY(0);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (
      int i = startIdx < 0 ? 0 : startIdx;
      i < endIdx && i < values.length;
      i++
    ) {
      if (colorValues != null &&
          i < colorValues!.length &&
          colorValues![i] != null) {
        final colorStr = colorValues![i].toString();
        final defaultColor = _safeParseColor(colorStr);
        if (colorStr.toUpperCase().contains('F236') ||
            colorStr.toUpperCase().contains('EF53') ||
            colorStr.toUpperCase().contains('RED') ||
            defaultColor.r > defaultColor.g) {
          paint.color = downColor ?? defaultColor;
        } else {
          paint.color = upColor ?? defaultColor;
        }
      } else if (upColor != null && downColor != null) {
        if (i > 0 && values[i] != null && values[i - 1] != null) {
          final val = (values[i] as num).toDouble();
          final prevVal = (values[i - 1] as num).toDouble();
          paint.color = val >= prevVal ? upColor! : downColor!;
        } else {
          paint.color = upColor!;
        }
      } else {
        paint.color = color;
      }
      if (values[i] == null) continue;
      final value = (values[i] as num).toDouble();
      final x = scale.indexToPixelX((i.toInt())) + candleW / 2;
      final y = scale.valueToPixelY(value);

      final top = value >= 0 ? y : zeroY;
      final bottom = value >= 0 ? zeroY : y;
      final height = (bottom - top).abs();

      final rect = Rect.fromLTWH(
        x - barWidth / 2,
        top,
        barWidth,
        height < 1 ? 1 : height,
      );

      canvas.drawRect(rect, paint);
    }

    if (showLastValue && values.isNotEmpty) {
      double? lastClose;
      for (int i = values.length - 1; i >= 0; i--) {
        if (values[i] != null) {
          lastClose = (values[i] as num).toDouble();
          break;
        }
      }
      if (lastClose != null) {
        final y = scale.valueToPixelY(lastClose);
        final linePaint = Paint()
          ..color = color.withValues(alpha: 0.4)
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

  static Color _safeParseColor(String colorStr, [Color fallback = const Color(0xFF888888)]) {
    try {
      final hex = colorStr.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  bool shouldRepaint(covariant BarPainter oldDelegate) => true;
}
