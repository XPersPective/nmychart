import 'package:flutter/material.dart';
import '../math/scale_util.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class LastValueLabel {
  final double value;
  final Color color;
  const LastValueLabel({required this.value, required this.color});
}

class AxisPainter extends CustomPainter {
  final Scale scale;
  final bool isLastSlot;
  final List<dynamic>? baseAxisData;
  final String timezone;
  final List<LastValueLabel> lastValues;

  AxisPainter({
    required this.scale,
    this.isLastSlot = false,
    this.baseAxisData,
    this.timezone = 'UTC',
    this.lastValues = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = const TextStyle(color: Color(0xFF787B86), fontSize: 11);

    final tickPaint = Paint()
      ..color = const Color(0xFF363C4E)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw solid vertical Y-axis line
    canvas.drawLine(
      Offset(scale.chartWidth, 0),
      Offset(scale.chartWidth, scale.chartHeight),
      tickPaint,
    );

    // Draw solid horizontal X-axis line if isLastSlot is true
    if (isLastSlot) {
      canvas.drawLine(
        Offset(0, scale.chartHeight),
        Offset(scale.chartWidth, scale.chartHeight),
        tickPaint,
      );
    }

    final yDivisions = (math.max(1, scale.chartHeight) / 50).floor().clamp(1, 50);
    for (int i = 0; i <= yDivisions; i++) {
      final double y = (scale.chartHeight / yDivisions) * i;
      final double val = scale.pixelYToValue(y);

      // Draw Y-axis tick
      canvas.drawLine(
        Offset(scale.chartWidth - 4, y),
        Offset(scale.chartWidth, y),
        tickPaint,
      );

      String textVal = val >= 1000
          ? val.toStringAsFixed(1)
          : val.toStringAsFixed(3);
      final tp = TextPainter(
        text: TextSpan(text: textVal, style: textStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      // Draw in right margin
      tp.paint(canvas, Offset(scale.chartWidth + 8, y - tp.height / 2));
    }

    // Draw Last Values
    for (final label in lastValues) {
      final double y = scale.valueToPixelY(label.value);
      if (y < 0 || y > scale.chartHeight) continue;

      // Draw dashed horizontal line across the chart width
      final linePaint = Paint()
        ..color = label.color.withValues(alpha: 0.4)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      const dashWidth = 4.0;
      const dashSpace = 4.0;
      double startX = 0.0;
      while (startX < scale.chartWidth) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(math.min(startX + dashWidth, scale.chartWidth), y),
          linePaint,
        );
        startX += dashWidth + dashSpace;
      }

      String textVal = label.value >= 1000
          ? label.value.toStringAsFixed(1)
          : label.value.toStringAsFixed(3);
          
      final tp = TextPainter(
        text: TextSpan(
          text: textVal,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          scale.chartWidth,
          y - tp.height / 2 - 2,
          tp.width + 12,
          tp.height + 4,
        ),
        const Radius.circular(2),
      );

      final bgPaint = Paint()..color = label.color;
      canvas.drawRRect(rRect, bgPaint);
      
      tp.paint(canvas, Offset(scale.chartWidth + 6, y - tp.height / 2));
    }

    // Draw X-axis values on the bottom if last slot
    if (isLastSlot && baseAxisData != null) {
      final xDivisions = 6;
      for (int i = 0; i <= xDivisions; i++) {
        final double x = (scale.chartWidth / xDivisions) * i;
        
        // Draw X-axis tick
        canvas.drawLine(
          Offset(x, scale.chartHeight),
          Offset(x, scale.chartHeight + 4),
          tickPaint,
        );

        final int index = scale.pixelXToIndex(x);

        String? dateStr;
        if (index >= 0 && index < baseAxisData!.length) {
          final timestamp = baseAxisData![index];
          final ts = (timestamp is int) ? timestamp : (timestamp is num) ? timestamp.toInt() : 0;
          DateTime date = DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true);
          if (timezone == 'Local') date = date.toLocal();
          dateStr = DateFormat('dd MMM\nHH:mm').format(date);
        } else if (baseAxisData!.length > 1) {
          final d0 = (baseAxisData![0] is int) ? baseAxisData![0] as int : (baseAxisData![0] is num) ? (baseAxisData![0] as num).toInt() : 0;
          final d1 = (baseAxisData![1] is int) ? baseAxisData![1] as int : (baseAxisData![1] is num) ? (baseAxisData![1] as num).toInt() : 0;
          final interval = d1 - d0;

          int estimatedTimestamp = 0;
          if (index < 0) {
            estimatedTimestamp = d0 + (index * interval);
          } else {
            final lastD = (baseAxisData!.last is int) ? baseAxisData!.last as int : (baseAxisData!.last is num) ? (baseAxisData!.last as num).toInt() : 0;
            estimatedTimestamp =
                lastD + ((index - (baseAxisData!.length - 1)) * interval);
          }
          DateTime date = DateTime.fromMillisecondsSinceEpoch(estimatedTimestamp, isUtc: true);
          if (timezone == 'Local') date = date.toLocal();
          dateStr = DateFormat('dd MMM\nHH:mm').format(date);
        }

        if (dateStr != null) {
          final tp = TextPainter(
            text: TextSpan(text: dateStr, style: textStyle),
            textAlign: TextAlign.center,
            textDirection: ui.TextDirection.ltr,
          )..layout();

          // Draw at the bottom margin, giving a bit more space
          tp.paint(canvas, Offset(x - tp.width / 2, scale.chartHeight + 2));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant AxisPainter oldDelegate) {
    return scale.visibleMin != oldDelegate.scale.visibleMin ||
        scale.visibleMax != oldDelegate.scale.visibleMax ||
        scale.viewport.startIndex != oldDelegate.scale.viewport.startIndex ||
        baseAxisData?.length != oldDelegate.baseAxisData?.length ||
        timezone != oldDelegate.timezone ||
        lastValues.length != oldDelegate.lastValues.length;
  }
}
