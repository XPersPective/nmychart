import 'package:flutter/material.dart';
import '../math/scale_util.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AREA PAINTER — Scalar area plot çizimi (line + fill)
// ─────────────────────────────────────────────────────────────────────────────

class AreaPainter extends CustomPainter {
  final Scale scale;
  final List<dynamic> values;
  final Color color;
  final double strokeWidth;
  final bool showLastValue;

  AreaPainter({
    required this.scale,
    required this.values,
    required this.color,
    this.strokeWidth = 2.0,
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

    // Line path
    final linePath = Path();
    // Fill path (line + bottom close)
    final fillPath = Path();

    bool first = true;
    double firstX = 0;
    double lastX = 0;

    for (
      int i = startIdx < 0 ? 0 : startIdx;
      i < endIdx && i < values.length;
      i++
    ) {
      if (values[i] == null) continue;
      final value = (values[i] as num).toDouble();
      final x = scale.indexToPixelX((i.toInt())) + candleW / 2;
      final y = scale.valueToPixelY(value);

      if (first) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
        firstX = x;
        first = false;
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      lastX = x;
    }

    // No points were drawn — nothing to fill or stroke
    if (first) return;

    // Fill path: alt kenardan kapat
    fillPath.lineTo(lastX, size.height);
    fillPath.lineTo(firstX, size.height);
    fillPath.close();

    // Yarı saydam fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Üst çizgi
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    if (showLastValue && values.isNotEmpty) {
      double? lastVal;
      for (int i = values.length - 1; i >= 0; i--) {
        if (values[i] != null) {
          lastVal = (values[i] as num).toDouble();
          break;
        }
      }
      if (lastVal != null) {
        final y = scale.valueToPixelY(lastVal);
        final valLinePaint = Paint()
          ..color = color.withValues(alpha: 0.4)
          ..strokeWidth = 0.3
          ..style = PaintingStyle.stroke;
        const dashWidth = 3.0;
        const dashSpace = 5.0;
        double startX = 0.0;
        while (startX < scale.chartWidth) {
          canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), valLinePaint);
          startX += dashWidth + dashSpace;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant AreaPainter oldDelegate) => true;
}
