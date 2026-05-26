import 'package:flutter/material.dart';
import '../../models/notation.dart';
import '../math/scale_util.dart';

class NotationPainter extends CustomPainter {
  final Scale scale;
  final List<dynamic> signalValues;
  final List<dynamic> anchorValues;
  final Notation config;

  NotationPainter({
    required this.scale,
    required this.signalValues,
    required this.anchorValues,
    required this.config,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (signalValues.isEmpty || anchorValues.isEmpty) return;

    final startIdx = scale.viewport.startIndex.toInt();
    final endIdx = (scale.viewport.startIndex + scale.viewport.visibleCount)
        .toInt();
    final candleW = scale.viewport.candleWidth;

    for (
      int i = startIdx < 0 ? 0 : startIdx;
      i < endIdx && i < signalValues.length && i < anchorValues.length;
      i++
    ) {
      final signal = signalValues[i]?.toString();
      if (signal == null || signal.isEmpty) continue;

      final rule = config.rules[signal];
      if (rule == null || anchorValues[i] == null) continue;

      final anchorVal = (anchorValues[i] as num).toDouble();
      final x = scale.indexToPixelX(i) + candleW / 2;
      double y = scale.valueToPixelY(anchorVal);

      bool isAbove = rule.position.name == 'above';
      if (isAbove) {
        y -= rule.offset;
      } else if (rule.position.name == 'below') {
        y += rule.offset;
      }

      final color = _parseColor(rule.color, defaultColor: Colors.white);

      // draw icon/text below each other
      final textPainter = TextPainter(
        text: TextSpan(
          text: rule.text,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      double drawY = isAbove ? y - textPainter.height : y;
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, drawY));
    }
  }

  Color _parseColor(String? colorStr, {Color defaultColor = Colors.white}) {
    if (colorStr == null) return defaultColor;
    try {
      if (colorStr.startsWith('#')) {
        String hex = colorStr.substring(1);
        if (hex.length == 6) hex = 'FF$hex';
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return defaultColor;
  }

  @override
  bool shouldRepaint(covariant NotationPainter oldDelegate) => true;
}
