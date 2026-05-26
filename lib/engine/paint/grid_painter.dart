import 'package:flutter/material.dart';
import '../math/scale_util.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GRID PAINTER — Arka plan ızgara çizgileri
// ─────────────────────────────────────────────────────────────────────────────
//
// Roadmap §3.4: CustomPaint(GridPainter) ← Nadir güncellenir
// ─────────────────────────────────────────────────────────────────────────────

class GridPainter extends CustomPainter {
  final Scale scale;
  final Color color;
  final double strokeWidth;
  final bool showHorizontal;
  final bool showVertical;
  final int horizontalDivisions;
  final int verticalDivisions;

  GridPainter({
    required this.scale,
    this.color = const Color(0xFF1E222D),
    this.strokeWidth = 1.0,
    this.showHorizontal = true,
    this.showVertical = true,
    this.horizontalDivisions = 5,
    this.verticalDivisions = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Yatay çizgiler (değer ekseni)
    if (showHorizontal) {
      for (var i = 0; i <= horizontalDivisions; i++) {
        final y = (scale.chartHeight / horizontalDivisions) * i;
        canvas.drawLine(Offset(0, y), Offset(scale.chartWidth, y), paint);
      }
    }

    // Dikey çizgiler (zaman ekseni)
    if (showVertical) {
      for (var i = 0; i <= verticalDivisions; i++) {
        final x = (scale.chartWidth / verticalDivisions) * i;
        canvas.drawLine(Offset(x, 0), Offset(x, scale.chartHeight), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return scale.visibleMin != oldDelegate.scale.visibleMin ||
        scale.visibleMax != oldDelegate.scale.visibleMax ||
        color != oldDelegate.color;
  }
}
