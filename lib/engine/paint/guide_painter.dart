import 'package:flutter/material.dart';
import '../math/scale_util.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GUIDE PAINTER — Yatay rehber çizgileri ve bantları
// ─────────────────────────────────────────────────────────────────────────────
//
// Roadmap §5.1: guides → affectsScale kontrolü yapılır
// ─────────────────────────────────────────────────────────────────────────────

/// Yatay çizgi rehberi (support/resistance seviyeleri)
class LineGuidePainter extends CustomPainter {
  final Scale scale;
  final double value;
  final Color color;
  final double strokeWidth;
  final bool isDashed;

  LineGuidePainter({
    required this.scale,
    required this.value,
    required this.color,
    this.strokeWidth = 1.5,
    this.isDashed = false,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = scale.valueToPixelY(value);
    if (y < 0 || y > size.height) return; // Görünür alanın dışında

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    if (isDashed) {
      const dashWidth = 8.0;
      const dashSpace = 4.0;
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, y),
          Offset((x + dashWidth).clamp(0, size.width), y),
          paint,
        );
        x += dashWidth + dashSpace;
      }
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant LineGuidePainter oldDelegate) {
    return value != oldDelegate.value || color != oldDelegate.color;
  }
}

/// Yatay bant rehberi (üst-alt arası dolu bölge)
class BandGuidePainter extends CustomPainter {
  final Scale scale;
  final double upperValue;
  final double lowerValue;
  final Color upperColor;
  final Color lowerColor;
  final Color fillColor;

  BandGuidePainter({
    required this.scale,
    required this.upperValue,
    required this.lowerValue,
    required this.upperColor,
    required this.lowerColor,
    required this.fillColor,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final upperY = scale.valueToPixelY(upperValue);
    final lowerY = scale.valueToPixelY(lowerValue);

    // Fill
    final fillRect = Rect.fromLTRB(0, upperY, size.width, lowerY);
    canvas.drawRect(
      fillRect,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // Upper line
    canvas.drawLine(
      Offset(0, upperY),
      Offset(size.width, upperY),
      Paint()
        ..color = upperColor
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // Lower line
    canvas.drawLine(
      Offset(0, lowerY),
      Offset(size.width, lowerY),
      Paint()
        ..color = lowerColor
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant BandGuidePainter oldDelegate) {
    return upperValue != oldDelegate.upperValue ||
        lowerValue != oldDelegate.lowerValue;
  }
}
