import 'package:flutter/material.dart';
import '../math/scale_util.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CROSSHAIR PAINTER — Fare/dokunma konumunda çarpraz çizgi + etiketler
// ─────────────────────────────────────────────────────────────────────────────
//
// Roadmap §3.4: InteractionLayer → CustomPaint(CrosshairPainter)
// ─────────────────────────────────────────────────────────────────────────────

class CrosshairPainter extends CustomPainter {
  final Scale scale;
  final double? posX;
  final double? posY;
  final Color color;
  final bool showLabels;
  final List<dynamic>? baseAxisData;

  CrosshairPainter({
    required this.scale,
    this.posX,
    this.posY,
    this.color = const Color(0xFF888888),
    this.showLabels = true,
    this.baseAxisData,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (posX == null && posY == null) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;

    // Yatay çizgi (only if local slot is active)
    if (posY != null && posY! >= 0 && posY! <= scale.chartHeight) {
      double x = 0;
      while (x < scale.chartWidth) {
        canvas.drawLine(
          Offset(x, posY!),
          Offset((x + dashWidth).clamp(0, scale.chartWidth), posY!),
          paint,
        );
        x += dashWidth + dashSpace;
      }
    }

    // Dikey çizgi (global crosshair across all slots)
    if (posX != null && posX! >= 0 && posX! <= scale.chartWidth) {
      double y = 0;
      while (y < scale.chartHeight) {
        canvas.drawLine(
          Offset(posX!, y),
          Offset(posX!, (y + dashWidth).clamp(0, scale.chartHeight)),
          paint,
        );
        y += dashWidth + dashSpace;
      }
    }

    // Etiketler
    if (showLabels) {
      _drawLabels(canvas, size, posX, posY);
    }
  }

  void _drawLabels(Canvas canvas, Size size, double? px, double? py) {
    // Y ekseni etiketi (sağ kenar)
    if (py != null && py >= 0 && py <= scale.chartHeight) {
      final value = scale.pixelYToValue(py);
      final valueText = value.toStringAsFixed(2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: valueText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final labelWidth = textPainter.width + 8;
      final labelHeight = textPainter.height + 4;

      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          scale.chartWidth + 2,
          py - labelHeight / 2,
          labelWidth,
          labelHeight,
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(
        labelRect,
        Paint()
          ..color = const Color(0xFF2B3139)
          ..style = PaintingStyle.fill,
      );

      textPainter.paint(
        canvas,
        Offset(scale.chartWidth + 6, py - textPainter.height / 2),
      );
    }

    // X ekseni etiketi (alt kenar) - Sadece cursor X varsa ve baseAxisData verilmişse
    if (px != null &&
        baseAxisData != null &&
        px >= 0 &&
        px <= scale.chartWidth) {
      final dataIndex = scale.pixelXToIndex(px);
      String indexText = '$dataIndex';
      if (dataIndex >= 0 && dataIndex < baseAxisData!.length) {
        final timestamp = baseAxisData![dataIndex];
        final ts = (timestamp is int) ? timestamp : (timestamp is num) ? timestamp.toInt() : 0;
        final date = DateTime.fromMillisecondsSinceEpoch(
          ts,
        ).toLocal();
        indexText = DateFormat('dd MMM HH:mm').format(date);
      } else if (baseAxisData!.length > 1) {
        final d0 = (baseAxisData![0] is int) ? baseAxisData![0] as int : (baseAxisData![0] is num) ? (baseAxisData![0] as num).toInt() : 0;
        final d1 = (baseAxisData![1] is int) ? baseAxisData![1] as int : (baseAxisData![1] is num) ? (baseAxisData![1] as num).toInt() : 0;
        final interval = d1 - d0;

        int estimatedTimestamp = 0;
        if (dataIndex < 0) {
          estimatedTimestamp = d0 + (dataIndex * interval);
        } else {
          final lastD = (baseAxisData!.last is int) ? baseAxisData!.last as int : (baseAxisData!.last is num) ? (baseAxisData!.last as num).toInt() : 0;
          estimatedTimestamp =
              lastD + ((dataIndex - (baseAxisData!.length - 1)) * interval);
        }
        final date = DateTime.fromMillisecondsSinceEpoch(
          estimatedTimestamp,
        ).toLocal();
        indexText = DateFormat('dd MMM HH:mm').format(date);
      }

      final xTextPainter = TextPainter(
        text: TextSpan(
          text: indexText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final xLabelWidth = xTextPainter.width + 12;
      final xLabelHeight = xTextPainter.height + 6;

      final xLabelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          px - xLabelWidth / 2,
          scale.chartHeight + 2,
          xLabelWidth,
          xLabelHeight,
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(
        xLabelRect,
        Paint()
          ..color = const Color(0xFF2B3139)
          ..style = PaintingStyle.fill,
      );

      xTextPainter.paint(
        canvas,
        Offset(px - xTextPainter.width / 2, scale.chartHeight + 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CrosshairPainter oldDelegate) {
    return posX != oldDelegate.posX || posY != oldDelegate.posY;
  }
}
