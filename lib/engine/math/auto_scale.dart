import '../state/data_state.dart';
import '../state/viewport_state.dart';
import '../../../models/chart.dart';
import '../../../models/dimensions.dart';
import '../../../models/plot.dart';
import '../../../models/guide.dart';
import '../../../models/input.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AUTO SCALE — affectsScale mekanizması
// ─────────────────────────────────────────────────────────────────────────────
//
// Roadmap §5.1:
//   visibleMin = MIN_VALUE
//   visibleMax = MAX_VALUE
//
//   for (plot in charts[slot]):
//     if (plot.visible && plot.affectsScale):
//       for (i in viewport.startIndex .. endIndex):
//         visibleMin = min(visibleMin, store[chartId][plot.valueField][i])
//         visibleMax = max(visibleMax, store[chartId][plot.valueField][i])
//
//   for (guide in chart.guides):
//     if (guide.visible && guide.affectsScale):
//       guideValue = resolveInputValue(guide.value)
//       visibleMin = min(visibleMin, guideValue)
//       visibleMax = max(visibleMax, guideValue)
// ─────────────────────────────────────────────────────────────────────────────

class AutoScaleResult {
  final double min;
  final double max;

  const AutoScaleResult({required this.min, required this.max});
}

class AutoScaleCalculator {
  AutoScaleResult calculateForSlot({
    required List<Chart> charts,
    required DataState store,
    required ViewportState viewport,
    Dimensions? dimensions,
  }) {
    double overallMin = double.infinity;
    double overallMax = double.negativeInfinity;

    for (final chart in charts) {
      final res = calculate(
        chart: chart,
        store: store,
        viewport: viewport,
        dimensions: dimensions,
        applyPadding: false,
      );
      if (res.min < overallMin) overallMin = res.min;
      if (res.max > overallMax) overallMax = res.max;
    }

    if (overallMin == double.infinity || overallMax == double.negativeInfinity) {
      return const AutoScaleResult(min: 0, max: 1);
    }

    if (overallMin == overallMax) {
      overallMin -= 1.0;
      overallMax += 1.0;
    }

    final range = overallMax - overallMin;
    final padding = range * 0.05;
    return AutoScaleResult(min: overallMin - padding, max: overallMax + padding);
  }

  /// affectsScale mekanizmasına göre görünür min/max hesapla
  AutoScaleResult calculate({
    required Chart chart,
    required DataState store,
    required ViewportState viewport,
    Dimensions? dimensions,
    bool applyPadding = true,
  }) {
    double visMin = double.infinity;
    double visMax = double.negativeInfinity;

    final chartId = chart.meta.id;
    final columns = store.chartColumns[chartId];
    if (columns == null) return const AutoScaleResult(min: 0, max: 1);

    int startIdx = viewport.startIndex.floor();
    if (startIdx < 0) startIdx = 0;
    final int endIdx = (viewport.startIndex + viewport.visibleCount).ceil();

    double? fixedMin;
    double? fixedMax;

    if (dimensions != null && chart.plots.isNotEmpty) {
      final axisId = chart.plots.first.axis;
      final axisConfig = dimensions.valuesAxis
          .cast<ValueAxis?>()
          .firstWhere((a) => a?.id == axisId, orElse: () => null);
      if (axisConfig is LinearValueAxis && !axisConfig.autoScale) {
        fixedMin = axisConfig.min;
        fixedMax = axisConfig.max;
      }
    }

    if (fixedMin != null && fixedMax != null) {
      if (!applyPadding) return AutoScaleResult(min: fixedMin, max: fixedMax);
      final range = fixedMax - fixedMin;
      final padding = range * 0.05;
      return AutoScaleResult(min: fixedMin - padding, max: fixedMax + padding);
    }

    // ── PLOT'LAR ──
    for (final plot in chart.plots) {
      if (!plot.visible || !plot.affectsScale) continue;

      final fieldIds = _getPlotValueFields(plot);
      for (final fieldId in fieldIds) {
        final column = columns[fieldId];
        if (column == null) continue;

        for (var i = startIdx; i <= endIdx && i < column.length; i++) {
          if (column[i] == null) continue;
          final val = (column[i] as num).toDouble();
          if (val < visMin) visMin = val;
          if (val > visMax) visMax = val;
        }
      }
    }

    // ── GUIDE'LAR ──
    for (final guide in chart.guides) {
      if (!guide.visible || !guide.affectsScale) continue;

      switch (guide) {
        case LineGuide g:
          final value = _resolveInputValue(g.value, chart.inputs);
          if (value != null) {
            if (value < visMin) visMin = value;
            if (value > visMax) visMax = value;
          }
        case BandGuide g:
          final upper = _resolveInputValue(g.upper, chart.inputs);
          final lower = _resolveInputValue(g.lower, chart.inputs);
          if (upper != null) {
            if (upper < visMin) visMin = upper;
            if (upper > visMax) visMax = upper;
          }
          if (lower != null) {
            if (lower < visMin) visMin = lower;
            if (lower > visMax) visMax = lower;
          }
      }
    }

    if (!applyPadding) {
       return AutoScaleResult(min: visMin, max: visMax);
    }

    // Eğer hiç veri yoksa güvenli değerler
    if (visMin == double.infinity || visMax == double.negativeInfinity) {
      return const AutoScaleResult(min: 0, max: 1);
    }

    // Min == Max ise padding ekle
    if (visMin == visMax) {
      visMin -= 1.0;
      visMax += 1.0;
    }

    // %5 padding
    final range = visMax - visMin;
    final padding = range * 0.05;
    return AutoScaleResult(min: visMin - padding, max: visMax + padding);
  }

  /// Plot tipine göre değer field'larını döndür
  List<String> _getPlotValueFields(Plot plot) {
    return switch (plot) {
      LinePlot p => [p.value],
      AreaPlot p => [p.value],
      BarPlot p => [p.value],
      CandlestickPlot p => [p.open, p.high, p.low, p.close],
      BandPlot p => [p.upper, p.lower],
    };
  }

  /// Input referansından değer çöz
  /// Guide.value bir input id'si veya doğrudan sayı olabilir
  double? _resolveInputValue(String valueRef, List<Input> inputs) {
    // Doğrudan sayı denemesi
    final directValue = double.tryParse(valueRef);
    if (directValue != null) return directValue;

    // Input referansı
    for (final input in inputs) {
      if (input.id == valueRef) {
        return switch (input) {
          IntegerInput i => i.value.toDouble(),
          DoubleInput d => d.value,
          _ => null,
        };
      }
    }

    return null;
  }
}
