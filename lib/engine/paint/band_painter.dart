import 'package:flutter/material.dart';
import '../math/scale_util.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BAND PAINTER — Upper/Lower band çizimi (Bollinger Bands vb.)
// ─────────────────────────────────────────────────────────────────────────────

class BandPainter extends CustomPainter {
  final Scale scale;
  final List<dynamic> upperValues;
  final List<dynamic> lowerValues;
  final Color upperColor;
  final Color lowerColor;
  final Color fillColor;
  final double strokeWidth;
  final bool showLastValue;

  BandPainter({
    required this.scale,
    required this.upperValues,
    required this.lowerValues,
    required this.upperColor,
    required this.lowerColor,
    required this.fillColor,
    this.strokeWidth = 1.5,
    this.showLastValue = false,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (upperValues.isEmpty || lowerValues.isEmpty) return;

    final startIdx = scale.viewport.startIndex.toInt();
    final endIdx = (scale.viewport.startIndex + scale.viewport.visibleCount)
        .toInt();
    final candleW = scale.viewport.candleWidth;

    final upperPath = Path();
    final lowerPath = Path();
    final fillPath = Path();

    final upperPoints = <Offset>[];
    final lowerPoints = <Offset>[];

    for (
      int i = startIdx < 0 ? 0 : startIdx;
      i < endIdx && i < upperValues.length && i < lowerValues.length;
      i++
    ) {
      if (upperValues[i] == null || lowerValues[i] == null) continue;
      final x = scale.indexToPixelX((i.toInt())) + candleW / 2;
      final upperY = scale.valueToPixelY((upperValues[i] as num).toDouble());
      final lowerY = scale.valueToPixelY((lowerValues[i] as num).toDouble());

      upperPoints.add(Offset(x, upperY));
      lowerPoints.add(Offset(x, lowerY));
    }

    if (upperPoints.isEmpty) return;

    // Upper line
    upperPath.moveTo(upperPoints.first.dx, upperPoints.first.dy);
    for (var i = 1; i < upperPoints.length; i++) {
      upperPath.lineTo(upperPoints[i].dx, upperPoints[i].dy);
    }

    // Lower line
    lowerPath.moveTo(lowerPoints.first.dx, lowerPoints.first.dy);
    for (var i = 1; i < lowerPoints.length; i++) {
      lowerPath.lineTo(lowerPoints[i].dx, lowerPoints[i].dy);
    }

    // Fill: upper → lower (ters sıra) → close
    fillPath.moveTo(upperPoints.first.dx, upperPoints.first.dy);
    for (var i = 1; i < upperPoints.length; i++) {
      fillPath.lineTo(upperPoints[i].dx, upperPoints[i].dy);
    }
    for (var i = lowerPoints.length - 1; i >= 0; i--) {
      fillPath.lineTo(lowerPoints[i].dx, lowerPoints[i].dy);
    }
    fillPath.close();

    // Draw fill
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // Draw upper line
    canvas.drawPath(
      upperPath,
      Paint()
        ..color = upperColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    // Draw lower line
    canvas.drawPath(
      lowerPath,
      Paint()
        ..color = lowerColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    if (showLastValue && upperValues.isNotEmpty) {
      double? lastUpper;
      for (int i = upperValues.length - 1; i >= 0; i--) {
        if (upperValues[i] != null) {
          lastUpper = (upperValues[i] as num).toDouble();
          break;
        }
      }
      if (lastUpper != null) {
        final y = scale.valueToPixelY(lastUpper);
        final linePaint = Paint()
          ..color = upperColor.withValues(alpha: 0.4)
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

    if (showLastValue && lowerValues.isNotEmpty) {
      double? lastLower;
      for (int i = lowerValues.length - 1; i >= 0; i--) {
        if (lowerValues[i] != null) {
          lastLower = (lowerValues[i] as num).toDouble();
          break;
        }
      }
      if (lastLower != null) {
        final y = scale.valueToPixelY(lastLower);
        final linePaint = Paint()
          ..color = lowerColor.withValues(alpha: 0.4)
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
  bool shouldRepaint(covariant BandPainter oldDelegate) => true;
}
