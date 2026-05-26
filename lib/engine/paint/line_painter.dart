import 'package:flutter/material.dart';
import '../math/scale_util.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LINE PAINTER — Scalar line plot çizimi
// ─────────────────────────────────────────────────────────────────────────────
//
// Roadmap §3.4: CustomPaint(DataPainters...) ← HOT sinyalleri dinler
//   repaint: _dataNotifier (Listenable, sadece repaint)
// ─────────────────────────────────────────────────────────────────────────────

class LinePainter extends CustomPainter {
  final Scale scale;
  final List<dynamic> values;
  final Color color;
  final double strokeWidth;
  final bool isDashed;
  final bool showLastValue;

  LinePainter({
    required this.scale,
    required this.values,
    required this.color,
    this.strokeWidth = 2.0,
    this.isDashed = false,
    this.showLastValue = false,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final startIdx = scale.viewport.startIndex.toInt();
    final endIdx = (scale.viewport.startIndex + scale.viewport.visibleCount)
        .toInt();

    bool first = true;
    for (
      int i = startIdx < 0 ? 0 : startIdx;
      i < endIdx && i < values.length;
      i++
    ) {
      if (values[i] == null) continue;
      final value = (values[i] as num).toDouble();
      final x =
          scale.indexToPixelX((i.toInt())) + scale.viewport.candleWidth / 2;
      final y = scale.valueToPixelY(value);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    if (isDashed) {
      _drawDashedPath(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }

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

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        final extracted = metric.extractPath(distance, end);
        canvas.drawPath(extracted, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant LinePainter oldDelegate) => true;
}
