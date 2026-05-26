import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'settings_dialog.dart';
import '../../../models/models.dart';
import '../../../services/chart_network_service.dart';
import '../state/chartset_document_state.dart';
import '../state/data_state.dart';
import '../state/viewport_state.dart';
import '../paint/grid_painter.dart';
import '../paint/crosshair_painter.dart';
import '../paint/area_painter.dart';
import '../paint/band_painter.dart';
import '../paint/bar_painter.dart';
import '../paint/candlestick_painter.dart';
import '../paint/line_painter.dart';
import '../paint/guide_painter.dart';
import '../paint/notation_painter.dart';
import '../paint/axis_painter.dart';
import '../math/auto_scale.dart';
import '../math/scale_util.dart';

Color _parseColor(String? hexString, {Color defaultColor = Colors.grey}) {
  if (hexString == null) return defaultColor;
  final buffer = StringBuffer();
  final hex = hexString.replaceAll('#', '');
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex);
  return Color(int.parse(buffer.toString(), radix: 16));
}

double _safeGetDouble(List<dynamic>? list, int index) {
  if (list == null || index < 0 || index >= list.length) return 0.0;
  final val = list[index];
  if (val == null) return 0.0;
  return (val as num).toDouble();
}

double? _resolveInputValue(String ref, List<Input> inputs) {
  final d = double.tryParse(ref);
  if (d != null) return d;
  for (final i in inputs) {
    if (i.id == ref) {
      if (i is DoubleInput) return i.value;
      if (i is IntegerInput) return i.value.toDouble();
    }
  }
  return null;
}

class SlotWidget extends StatefulWidget {
  final int slotIndex;
  final ChartSetDocumentState chartSetDocumentState;
  final DataState dataState;
  final ViewportState viewportState;
  final ChartNetworkService networkService;

  const SlotWidget({
    super.key,
    required this.slotIndex,
    required this.chartSetDocumentState,
    required this.dataState,
    required this.viewportState,
    required this.networkService,
  });

  @override
  State<SlotWidget> createState() => _SlotWidgetState();
}

class _SlotWidgetState extends State<SlotWidget> {
  final ValueNotifier<Offset?> _crosshairNotifier = ValueNotifier<Offset?>(
    null,
  );
  bool _legendExpanded = true;

  /// Mevcut slot'un kullanılabilir genişliğini tutar
  double _lastAvailableWidth = 0.0;

  /// Helper: Slot genişliğini döndür (testing ve debugging için)
  double get availableWidth => _lastAvailableWidth;

  @override
  void dispose() {
    _crosshairNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
            return const SizedBox.shrink();
          }

          final document = widget.chartSetDocumentState.document;
          if (document == null) return const SizedBox.shrink();

          int lastVisibleSlot = -1;
          for (int i = document.charts.length - 1; i >= 0; i--) {
            if (document.charts[i].isNotEmpty) {
              lastVisibleSlot = i;
              break;
            }
          }

          final isMaximized =
              widget.viewportState.maximizedSlotIndex == widget.slotIndex;
          final isLastSlot = isMaximized || widget.slotIndex == lastVisibleSlot;
          final double rightMargin = 60.0;
          final double bottomMargin = isLastSlot ? 36.0 : 0.0;

          final availableWidth = (constraints.maxWidth - rightMargin).clamp(
            0.0,
            double.infinity,
          );
          final availableHeight = (constraints.maxHeight - bottomMargin).clamp(
            0.0,
            double.infinity,
          );
          _lastAvailableWidth = availableWidth;

          widget.viewportState.updateScreenSize(
            availableWidth,
            widget.dataState.length,
          );

          return MouseRegion(
            onHover: (event) {
              _crosshairNotifier.value = event.localPosition;
              widget.viewportState.updateCrosshair(event.localPosition.dx);
            },
            onExit: (event) {
              _crosshairNotifier.value = null;
              widget.viewportState.updateCrosshair(null);
            },
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  double factor = pointerSignal.scrollDelta.dy < 0 ? 1.1 : 0.9;
                  widget.viewportState.zoom(
                    factor,
                    pointerSignal.localPosition.dx,
                    availableWidth,
                    widget.dataState.length,
                  );
                }
              },
              child: GestureDetector(
                onDoubleTap: () {
                  widget.viewportState.toggleMaximize(widget.slotIndex);
                },
                onScaleUpdate: (details) {
                  if (details.scale != 1.0) {
                    widget.viewportState.zoom(
                      details.scale,
                      details.localFocalPoint.dx,
                      availableWidth,
                      widget.dataState.length,
                    );
                  }
                  if (details.focalPointDelta.dx != 0.0) {
                    widget.viewportState.pan(
                      details.focalPointDelta.dx,
                      widget.dataState.length,
                    );
                  }
                },
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Grid Layer
                      RepaintBoundary(
                        child: ListenableBuilder(
                          listenable: widget.chartSetDocumentState,
                          builder: (context, child) {
                            final document =
                                widget.chartSetDocumentState.document!;
                            if (widget.slotIndex >= document.charts.length) {
                              return const SizedBox.shrink();
                            }
                            final charts = document.charts[widget.slotIndex];
                            if (charts.isEmpty) return const SizedBox.shrink();
                            return CustomPaint(
                              painter: GridPainter(
                                scale: Scale(
                                  viewport: widget.viewportState,
                                  chartWidth: availableWidth,
                                  chartHeight: availableHeight,
                                  visibleMin: 0,
                                  visibleMax: 1,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // 2. Data Layer
                      RepaintBoundary(
                        child: ListenableBuilder(
                          listenable: Listenable.merge([
                            widget.dataState,
                            widget.chartSetDocumentState,
                            widget.viewportState,
                          ]),
                          builder: (context, child) {
                            final document =
                                widget.chartSetDocumentState.document!;
                            if (widget.slotIndex >= document.charts.length) {
                              return const SizedBox.shrink();
                            }
                            final charts = document.charts[widget.slotIndex];
                            if (charts.isEmpty) return const SizedBox.shrink();

                            List<Widget> plotPainters = [];
                            List<Widget> axisPainters = [];

                            final scaleResult = AutoScaleCalculator()
                                .calculateForSlot(
                                  charts: charts,
                                  store: widget.dataState,
                                  viewport: widget.viewportState,
                                  dimensions: document.dimensions,
                                );

                            final manualScale = widget.viewportState
                                .getManualYScale(widget.slotIndex);

                            final scale = Scale(
                              viewport: widget.viewportState,
                              chartWidth: availableWidth,
                              chartHeight: availableHeight,
                              visibleMin: manualScale?.min ?? scaleResult.min,
                              visibleMax: manualScale?.max ?? scaleResult.max,
                            );

                            for (final chart in charts) {
                              final columns =
                                  widget.dataState.chartColumns[chart
                                      .meta
                                      .id] ??
                                  {};

                              // Guides
                              for (final guide in chart.guides) {
                                if (!guide.visible) continue;
                                if (guide is LineGuide) {
                                  final val = _resolveInputValue(
                                    guide.value,
                                    chart.inputs,
                                  );
                                  if (val != null) {
                                    plotPainters.add(
                                      CustomPaint(
                                        painter: LineGuidePainter(
                                          scale: scale,
                                          value: val,
                                          color: _parseColor(guide.color),
                                          isDashed:
                                              guide.style.name == "dashed",
                                        ),
                                      ),
                                    );
                                  }
                                } else if (guide is BandGuide) {
                                  final up = _resolveInputValue(
                                    guide.upper,
                                    chart.inputs,
                                  );
                                  final low = _resolveInputValue(
                                    guide.lower,
                                    chart.inputs,
                                  );
                                  if (up != null && low != null) {
                                    plotPainters.add(
                                      CustomPaint(
                                        painter: BandGuidePainter(
                                          scale: scale,
                                          upperValue: up,
                                          lowerValue: low,
                                          upperColor: _parseColor(
                                            guide.upperColor,
                                          ),
                                          lowerColor: _parseColor(
                                            guide.lowerColor,
                                          ),
                                          fillColor: _parseColor(
                                            guide.fillColor,
                                          ).withValues(alpha: 0.1),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }

                              // Plots
                              for (final plot in chart.plots) {
                                if (!plot.visible) continue;
                                final painter = _createPainter(
                                  plot,
                                  columns,
                                  scale,
                                );
                                if (painter != null) {
                                  plotPainters.add(
                                    CustomPaint(painter: painter),
                                  );
                                }
                              }

                              // Notations
                              for (final notation in chart.notations) {
                                if (!notation.visible) continue;
                                if (notation.type.name == "marker") {
                                  final signalVals =
                                      columns[notation.value] ?? [];
                                  final anchorVals =
                                      columns[notation.anchor] ?? [];
                                  plotPainters.add(
                                    CustomPaint(
                                      painter: NotationPainter(
                                        scale: scale,
                                        signalValues: signalVals,
                                        anchorValues: anchorVals,
                                        config: notation,
                                      ),
                                    ),
                                  );
                                }
                              }
                            }

                            List<LastValueLabel> lastValuesList = [];
                            for (final chart in charts) {
                              final columns =
                                  widget.dataState.chartColumns[chart
                                      .meta
                                      .id] ??
                                  {};
                              for (final plot in chart.plots) {
                                if (!plot.visible || !plot.showLastValue) {
                                  continue;
                                }

                                if (plot is CandlestickPlot) {
                                  final closeCol = columns[plot.close];
                                  final openCol = columns[plot.open];
                                  if (closeCol != null &&
                                      openCol != null &&
                                      closeCol.isNotEmpty &&
                                      openCol.isNotEmpty) {
                                    final lastClose = closeCol.last;
                                    final lastOpen = openCol.last;
                                    if (lastClose != null && lastOpen != null) {
                                      final val = (lastClose as num).toDouble();
                                      final colorHex =
                                          val >= (lastOpen as num).toDouble()
                                          ? plot.upColor
                                          : plot.downColor;
                                      lastValuesList.add(
                                        LastValueLabel(
                                          value: val,
                                          color: _parseColor(colorHex),
                                        ),
                                      );
                                    }
                                  }
                                } else if (plot is LinePlot) {
                                  final valCol = columns[plot.value];
                                  if (valCol != null && valCol.isNotEmpty) {
                                    final lastVal = valCol.last;
                                    if (lastVal != null) {
                                      final val = (lastVal as num).toDouble();
                                      lastValuesList.add(
                                        LastValueLabel(
                                          value: val,
                                          color: _parseColor(plot.color),
                                        ),
                                      );
                                    }
                                  }
                                } else if (plot is BarPlot) {
                                  final valCol = columns[plot.value];
                                  if (valCol != null && valCol.isNotEmpty) {
                                    final lastVal = valCol.last;
                                    if (lastVal != null) {
                                      final val = (lastVal as num).toDouble();
                                      lastValuesList.add(
                                        LastValueLabel(
                                          value: val,
                                          color: _parseColor(plot.color),
                                        ),
                                      );
                                    }
                                  }
                                }
                              }
                            }

                            final baseAxis = document.dimensions.baseAxis;
                            final tz = baseAxis is TimeBaseAxis
                                ? baseAxis.timezone
                                : 'UTC';

                            axisPainters.add(
                              CustomPaint(
                                painter: AxisPainter(
                                  scale: scale,
                                  isLastSlot: isLastSlot,
                                  baseAxisData: widget.dataState.baseAxisData,
                                  lastValues: lastValuesList,
                                  timezone: tz,
                                ),
                              ),
                            );

                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  width: availableWidth,
                                  height: availableHeight,
                                  child: ClipRect(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: plotPainters,
                                    ),
                                  ),
                                ),
                                ...axisPainters,
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  width: 60,
                                  height: availableHeight,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onVerticalDragUpdate: (details) {
                                      final currentMin = scale.visibleMin;
                                      final currentMax = scale.visibleMax;
                                      final range = currentMax - currentMin;
                                      final factor =
                                          1.0 + (details.delta.dy / 100);
                                      final newRange = range * factor;
                                      final center = currentMin + range / 2;
                                      widget.viewportState.setManualYScale(
                                        widget.slotIndex,
                                        center - newRange / 2,
                                        center + newRange / 2,
                                      );
                                    },
                                    onDoubleTap: () {
                                      widget.viewportState.clearManualYScale(
                                        widget.slotIndex,
                                      );
                                    },
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // 3. Interaction Layer (Crosshair)
                      RepaintBoundary(
                        child: ValueListenableBuilder<Offset?>(
                          valueListenable: _crosshairNotifier,
                          builder: (context, pos, child) {
                            return ListenableBuilder(
                              listenable: widget.viewportState,
                              builder: (context, _) {
                                final document =
                                    widget.chartSetDocumentState.document;
                                if (document == null) {
                                  return const SizedBox.shrink();
                                }
                                if (widget.slotIndex >=
                                    document.charts.length) {
                                  return const SizedBox.shrink();
                                }
                                final charts =
                                    document.charts[widget.slotIndex];
                                if (charts.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                final scaleResult = AutoScaleCalculator()
                                    .calculateForSlot(
                                      charts: charts,
                                      store: widget.dataState,
                                      viewport: widget.viewportState,
                                      dimensions: document.dimensions,
                                    );

                                final manualScale = widget.viewportState
                                    .getManualYScale(widget.slotIndex);

                                final scale = Scale(
                                  viewport: widget.viewportState,
                                  chartWidth: availableWidth,
                                  chartHeight: availableHeight,
                                  visibleMin:
                                      manualScale?.min ?? scaleResult.min,
                                  visibleMax:
                                      manualScale?.max ?? scaleResult.max,
                                );

                                final baseAxisData = widget
                                    .chartSetDocumentState
                                    .document
                                    ?.baseAxisData;

                                return CustomPaint(
                                  painter: CrosshairPainter(
                                    scale: scale,
                                    posX: widget.viewportState.crosshairX,
                                    posY: pos?.dy,
                                    color: Colors.grey,
                                    showLabels: true,
                                    baseAxisData: isLastSlot
                                        ? baseAxisData
                                        : null,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // 4. Legend Layer (TradingView style UI Overlay)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: ListenableBuilder(
                          listenable: Listenable.merge([
                            widget.chartSetDocumentState,
                            widget.viewportState,
                            widget.dataState,
                          ]),
                          builder: (context, _) {
                            final document =
                                widget.chartSetDocumentState.document;
                            if (document == null ||
                                widget.slotIndex >= document.charts.length) {
                              return const SizedBox.shrink();
                            }
                            final charts = document.charts[widget.slotIndex];
                            if (charts.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final scaleResult = AutoScaleCalculator()
                                .calculateForSlot(
                                  charts: charts,
                                  store: widget.dataState,
                                  viewport: widget.viewportState,
                                  dimensions: document.dimensions,
                                );

                            final manualScale = widget.viewportState
                                .getManualYScale(widget.slotIndex);
                            final scale = Scale(
                              viewport: widget.viewportState,
                              chartWidth: availableWidth,
                              chartHeight: availableHeight,
                              visibleMin: manualScale?.min ?? scaleResult.min,
                              visibleMax: manualScale?.max ?? scaleResult.max,
                            );

                            int index = 0;
                            if (widget.viewportState.crosshairX != null) {
                              index = scale.pixelXToIndex(
                                widget.viewportState.crosshairX!,
                              );
                              if (widget.dataState.baseAxisData.isNotEmpty) {
                                index = index.clamp(
                                  0,
                                  widget.dataState.baseAxisData.length - 1,
                                );
                              }
                            } else {
                              index = widget.dataState.baseAxisData.isNotEmpty
                                  ? widget.dataState.baseAxisData.length - 1
                                  : 0;
                            }

                            List<Widget> legendRows = [];

                            // Main chart title for collapsed state
                            String mainChartTitle = "";

                            for (int i = 0; i < charts.length; i++) {
                              final chart = charts[i];
                              final columns =
                                  widget.dataState.chartColumns[chart
                                      .meta
                                      .id] ??
                                  {};
                              List<Widget> valuesWidgets = [];
                              List<String> inputParams = [];

                              if (chart.legend.visible) {
                                for (var item in chart.legend.items) {
                                  if (item is InputLegendItem) {
                                    final inputInfo = chart.inputs
                                        .cast<Input?>()
                                        .firstWhere(
                                          (i) => i?.id == item.refId,
                                          orElse: () => null,
                                        );
                                    if (inputInfo != null) {
                                      var valStr = inputInfo
                                          .toJson()['value']
                                          .toString();
                                      if (valStr.isNotEmpty &&
                                          item.refId != 'symbol') {
                                        inputParams.add(valStr);
                                      }
                                    }
                                  } else if (item is PlotLegendItem) {
                                    final p = chart.plots
                                        .cast<Plot?>()
                                        .firstWhere(
                                          (chartPlot) =>
                                              chartPlot?.id == item.refId,
                                          orElse: () => null,
                                        );
                                    if (p != null) {
                                      Widget? valStrWidget;
                                      if (p is CandlestickPlot) {
                                        final o = _safeGetDouble(
                                          columns[p.open],
                                          index,
                                        );
                                        final h = _safeGetDouble(
                                          columns[p.high],
                                          index,
                                        );
                                        final l = _safeGetDouble(
                                          columns[p.low],
                                          index,
                                        );
                                        final c = _safeGetDouble(
                                          columns[p.close],
                                          index,
                                        );
                                        final diff = c - o;
                                        final pct = o != 0
                                            ? (diff / o) * 100
                                            : 0.0;
                                        final sign = diff >= 0 ? '+' : '';
                                        final diffColor = diff >= 0
                                            ? const Color(0xFF26A69A)
                                            : const Color(0xFFEF5350);
                                        valStrWidget = RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text:
                                                    "O:${o.toStringAsFixed(2)}  H:${h.toStringAsFixed(2)}  L:${l.toStringAsFixed(2)}  C:${c.toStringAsFixed(2)}   ",
                                                style: TextStyle(
                                                  color: p.visible
                                                      ? Colors.white70
                                                      : Colors.white30,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w300,
                                                  fontFeatures: const [
                                                    FontFeature.tabularFigures(),
                                                  ],
                                                ),
                                              ),
                                              if (p.visible)
                                                TextSpan(
                                                  text:
                                                      "$sign${diff.toStringAsFixed(2)} ($sign${pct.toStringAsFixed(2)}%)",
                                                  style: TextStyle(
                                                    color: diffColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w300,
                                                    fontFeatures: const [
                                                      FontFeature.tabularFigures(),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      } else if (p is LinePlot) {
                                        final val = _safeGetDouble(
                                          columns[p.value],
                                          index,
                                        );
                                        valStrWidget = Text(
                                          val.toStringAsFixed(2),
                                          style: TextStyle(
                                            color: p.visible
                                                ? _parseColor(
                                                    p.color,
                                                    defaultColor: Colors.blue,
                                                  )
                                                : Colors.white30,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w300,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        );
                                      } else if (p is BarPlot) {
                                        final val = _safeGetDouble(
                                          columns[p.value],
                                          index,
                                        );
                                        valStrWidget = Text(
                                          val.toStringAsFixed(2),
                                          style: TextStyle(
                                            color: p.visible
                                                ? _parseColor(
                                                    p.color,
                                                    defaultColor: Colors.grey,
                                                  )
                                                : Colors.white30,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w300,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        );
                                      }

                                      if (valStrWidget != null) {
                                        valuesWidgets.add(valStrWidget);
                                      }
                                    }
                                  }
                                }
                              }

                              final anyPlotVisible = chart.plots.any(
                                (p) => p.visible,
                              );
                              final paramsStr = inputParams.isNotEmpty
                                  ? " ${inputParams.join(', ')}"
                                  : "";
                              final chartTitle =
                                  "${chart.meta.shortName}$paramsStr";

                              if (i == 0) {
                                mainChartTitle = chartTitle;
                              }

                              final titleRow = Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: chart.meta.shortName,
                                          style: TextStyle(
                                            color: anyPlotVisible
                                                ? Colors.white
                                                : Colors.white30,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                        TextSpan(
                                          text: paramsStr,
                                          style: TextStyle(
                                            color: anyPlotVisible
                                                ? Colors.white70
                                                : Colors.white30,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      try {
                                        final operations = chart.plots.map((p) {
                                          final jsonVal = p.toJson();
                                          jsonVal['visible'] = !anyPlotVisible;
                                          return ChildPatchItem(
                                            scope: PatchScope.plot,
                                            op: PatchOperation.replace,
                                            targetId: chart.meta.id,
                                            childId: p.id,
                                            value: jsonVal,
                                          );
                                        }).toList();

                                        final patch = PatchPacket(
                                          docId: document.meta.id,
                                          revision: document.meta.revision,
                                          operations: operations,
                                        );
                                        widget.chartSetDocumentState.applyPatch(
                                          patch,
                                        );
                                        widget.networkService.sendPatch(patch);
                                      } catch (e) {
                                        debugPrint("Toggle visibility err: $e");
                                      }
                                    },
                                    child: Icon(
                                      anyPlotVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      size: 14,
                                      color: anyPlotVisible
                                          ? Colors.white70
                                          : Colors.white30,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => SettingsDialog(
                                          chart: chart,
                                          chartSetDocumentState:
                                              widget.chartSetDocumentState,
                                          networkService: widget.networkService,
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.settings,
                                      size: 13,
                                      color: anyPlotVisible
                                          ? Colors.white70
                                          : Colors.white30,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      try {
                                        final patch = PatchPacket(
                                          docId: document.meta.id,
                                          revision: document.meta.revision,
                                          operations: [
                                            ChartPatchItem(
                                              op: PatchOperation.remove,
                                              targetId: chart.meta.id,
                                            ),
                                          ],
                                        );
                                        widget.chartSetDocumentState.applyPatch(
                                          patch,
                                        );
                                        widget.networkService.sendPatch(patch);
                                      } catch (e) {
                                        debugPrint("Remove chart err: $e");
                                      }
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 13,
                                      color: anyPlotVisible
                                          ? Colors.white70
                                          : Colors.white30,
                                    ),
                                  ),
                                ],
                              );

                              legendRows.add(
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      titleRow,
                                      if (anyPlotVisible &&
                                          valuesWidgets.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4.0,
                                            top: 2.0,
                                          ),
                                          child: Wrap(
                                            spacing: 12,
                                            runSpacing: 2,
                                            children: valuesWidgets,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              color: Colors.transparent,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _legendExpanded = !_legendExpanded;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: 2.0,
                                        right: 4.0,
                                      ),
                                      child: Icon(
                                        _legendExpanded
                                            ? Icons.keyboard_arrow_down
                                            : Icons.keyboard_arrow_right,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  if (!_legendExpanded)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1.0),
                                      child: Text(
                                        mainChartTitle,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ),
                                  if (_legendExpanded)
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: legendRows,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e, stack) {
      return Center(
        child: Text(
          'ERROR: $e\n$stack',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }

  CustomPainter? _createPainter(
    dynamic plot,
    Map<String, List<dynamic>> columns,
    Scale scale,
  ) {
    if (plot is CandlestickPlot) {
      return CandlestickPainter(
        scale: scale,
        openValues: columns[plot.open] ?? [],
        highValues: columns[plot.high] ?? [],
        lowValues: columns[plot.low] ?? [],
        closeValues: columns[plot.close] ?? [],
        upColor: _parseColor(plot.upColor, defaultColor: Colors.green),
        downColor: _parseColor(plot.downColor, defaultColor: Colors.red),
      );
    } else if (plot is LinePlot) {
      return LinePainter(
        scale: scale,
        values: columns[plot.value] ?? [],
        color: _parseColor(plot.color),
      );
    } else if (plot is AreaPlot) {
      return AreaPainter(
        scale: scale,
        values: columns[plot.value] ?? [],
        color: _parseColor(plot.color),
      );
    } else if (plot is BandPlot) {
      return BandPainter(
        scale: scale,
        upperValues: columns[plot.upper] ?? [],
        lowerValues: columns[plot.lower] ?? [],
        upperColor: _parseColor(plot.upperColor),
        lowerColor: _parseColor(plot.lowerColor),
        fillColor: _parseColor(plot.fillColor).withValues(alpha: 0.2),
      );
    } else if (plot is BarPlot) {
      return BarPainter(
        scale: scale,
        values: columns[plot.value] ?? [],
        color: _parseColor(plot.color),
        upColor: plot.upColor != null ? _parseColor(plot.upColor) : null,
        downColor: plot.downColor != null ? _parseColor(plot.downColor) : null,
        colorValues: columns.entries
            .where((e) => e.key.contains('color'))
            .firstOrNull
            ?.value,
      );
    }
    return null;
  }
}
