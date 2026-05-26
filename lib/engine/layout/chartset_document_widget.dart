import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../models/layout.dart';
import '../state/chartset_document_state.dart';
import '../state/data_state.dart';
import '../state/viewport_state.dart';
import '../router/packet_router.dart';
import '../../../services/chart_network_service.dart';
import '../nmychart_controller.dart';
import 'slot_widget.dart';
import '../../../models/chartset_document.dart';
import '../../../models/stream_packets.dart';
import '../../../models/dimensions.dart';

class ChartSetDocumentWidget extends StatefulWidget {
  final ChartNetworkService networkService;
  final NmyChartController? controller;
  final Map<String, dynamic>? initialSnapshot;

  const ChartSetDocumentWidget({
    super.key,
    required this.networkService,
    this.controller,
    this.initialSnapshot,
  });

  @override
  State<ChartSetDocumentWidget> createState() => ChartSetDocumentWidgetState();
}

class ChartSetDocumentWidgetState extends State<ChartSetDocumentWidget> {
  late final ChartSetDocumentState chartSetDocumentState;
  late final DataState dataState;
  final Map<int, double> _slotWeights = {};
  late final ViewportState viewportState;
  late final PacketRouter packetRouter;
  late final StreamSubscription<Map<String, dynamic>> _networkSub;

  final GlobalKey _repaintKey = GlobalKey();
  bool _isToolbarHovered = false;

  Future<void> _takeScreenshot() async {
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final now = DateTime.now();
      final timestamp = "${now.year}"
          "${now.month.toString().padLeft(2, '0')}"
          "${now.day.toString().padLeft(2, '0')}_"
          "${now.hour.toString().padLeft(2, '0')}"
          "${now.minute.toString().padLeft(2, '0')}"
          "${now.second.toString().padLeft(2, '0')}";
      final String fileName = "nmychart_screenshot_$timestamp.png";
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: pngBytes,
        mimeType: MimeType.png,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Screenshot saved successfully')),
        );
      }
    } catch (e) {
      debugPrint("Screenshot error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save screenshot: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    chartSetDocumentState = ChartSetDocumentState();
    dataState = DataState();
    viewportState = ViewportState();
    packetRouter = PacketRouter(
      chartSetDocumentState: chartSetDocumentState,
      dataState: dataState,
      viewportState: viewportState,
      controller: widget.controller,
    );

    // Controller'ı bağla
    widget.controller?.bind(chartSetDocumentState, widget.networkService);

    viewportState.addListener(() {
      if (viewportState.startIndex <= viewportState.visibleCount * 0.2) {
        widget.networkService.requestHistoricalData();
      }
    });

    if (widget.initialSnapshot != null) {
      try {
        packetRouter.route(widget.initialSnapshot!);
      } catch (e, stacktrace) {
        if (kDebugMode) {
          debugPrint("ERROR IN PACKET ROUTER INIT: $e");
          debugPrint(stacktrace.toString());
        }
      }
    }

    _networkSub = widget.networkService.packetStream.listen((packet) {
      if (mounted) {
        try {
          packetRouter.route(packet);
        } catch (e, stack) {
          if (kDebugMode) {
            debugPrint("Ağ paketi işlenirken hata oluştu: $e\n$stack");
          }
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChartSetDocumentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.networkService != widget.networkService) {
      oldWidget.controller?.unbind();
      widget.controller?.bind(chartSetDocumentState, widget.networkService);
    }
  }

  @override
  void dispose() {
    widget.controller?.unbind();
    _networkSub.cancel();
    chartSetDocumentState.dispose();
    dataState.dispose();
    viewportState.dispose();
    super.dispose();
  }

  void dispatch(Map<String, dynamic> packet) {
    packetRouter.route(packet);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([chartSetDocumentState, viewportState]),
      builder: (context, child) {
        if (!chartSetDocumentState.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final document = chartSetDocumentState.document!;
        final layout = document.layout;

        return _buildLayout(layout, document);
      },
    );
  }

  Widget _buildLayout(Layout layout, ChartSetDocument document) {
    Widget layoutWidget = const SizedBox.shrink();

    final bool isLight = document.visualSettings.theme == 'light';
    final Color bgColor = isLight ? Colors.white : const Color(0xFF131722);

    if (viewportState.maximizedSlotIndex != null) {
      layoutWidget = Container(
        color: bgColor,
        child: SlotWidget(
          slotIndex: viewportState.maximizedSlotIndex!,
          chartSetDocumentState: chartSetDocumentState,
          dataState: dataState,
          viewportState: viewportState,
          networkService: widget.networkService,
        ),
      );
    } else {
      switch (layout) {
        case VerticalLayout l:
          layoutWidget = LayoutBuilder(
            builder: (context, constraints) {
              final children = <Widget>[];
              for (int i = 0; i < l.slots.length; i++) {
                final s = l.slots[i];
                if (s.index >= document.charts.length) continue;
                if (document.charts[s.index].isEmpty) continue;
                final weight = _slotWeights[s.index] ?? s.weight;
                children.add(
                  Expanded(
                    flex: (weight * 1000).toInt(),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: SlotWidget(
                        slotIndex: s.index,
                        chartSetDocumentState: chartSetDocumentState,
                        dataState: dataState,
                        viewportState: viewportState,
                        networkService: widget.networkService,
                      ),
                    ),
                  ),
                );

                if (i < l.slots.length - 1) {
                  int nextIdx = i + 1;
                  while (nextIdx < l.slots.length &&
                      (l.slots[nextIdx].index >= document.charts.length ||
                          document.charts[l.slots[nextIdx].index].isEmpty)) {
                    nextIdx++;
                  }
                  
                  if (nextIdx < l.slots.length) {
                    final separatorHeight = l.separatorSize > 0
                        ? l.separatorSize
                        : 2.0;

                    int lastVisibleSlot = -1;
                    for (int j = document.charts.length - 1; j >= 0; j--) {
                      if (document.charts[j].isNotEmpty) {
                        lastVisibleSlot = j;
                        break;
                      }
                    }

                    children.add(
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeUpDown,
                      child: GestureDetector(
                        onVerticalDragUpdate: (details) {
                          setState(() {
                            final s1 = l.slots[i];
                            final s2 = l.slots[nextIdx];

                            double totalFlex = 0;
                            for (var slot in l.slots) {
                              if (slot.index < document.charts.length) {
                                totalFlex +=
                                    (_slotWeights[slot.index] ?? slot.weight);
                              }
                            }

                            final w1 = _slotWeights[s1.index] ?? s1.weight;
                            final w2 = _slotWeights[s2.index] ?? s2.weight;
                            final total = w1 + w2;

                            double deltaWeight =
                                (details.delta.dy / constraints.maxHeight) *
                                totalFlex;

                            double minWeight1 = 50.0 / constraints.maxHeight;
                            double minWeight2 = ((nextIdx == lastVisibleSlot) ? 86.0 : 50.0) / constraints.maxHeight;

                            double newW1 = (w1 + deltaWeight).clamp(
                              minWeight1,
                              (total - minWeight2).clamp(minWeight1, double.infinity),
                            );
                            double newW2 = total - newW1;
                            _slotWeights[s1.index] = newW1;
                            _slotWeights[s2.index] = newW2;
                          });
                        },
                        child: Container(
                          height: 6.0,
                          color: Colors.transparent,
                          alignment: Alignment.center,
                          child: Container(
                            height: separatorHeight,
                            color: Colors.blueGrey.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              }
              }
              return Column(children: children);
            },
          );
          break;
        case HorizontalLayout l:
          layoutWidget = Row(
            children: l.slots
                .where((s) => s.index < document.charts.length)
                .map((s) {
                  return Expanded(
                    flex: (s.weight * 100).toInt(),
                    child: SlotWidget(
                      slotIndex: s.index,
                      chartSetDocumentState: chartSetDocumentState,
                      dataState: dataState,
                      viewportState: viewportState,
                      networkService: widget.networkService,
                    ),
                  );
                })
                .toList(),
          );
          break;
        case GridLayout l:
          layoutWidget = GridView.count(
            crossAxisCount: l.columns,
            children: l.slots.map((s) {
              return SlotWidget(
                slotIndex: s.index,
                chartSetDocumentState: chartSetDocumentState,
                dataState: dataState,
                viewportState: viewportState,
                networkService: widget.networkService,
              );
            }).toList(),
          );
          break;
        case SingleLayout l:
          layoutWidget = SlotWidget(
            slotIndex: l.slots.first.index,
            chartSetDocumentState: chartSetDocumentState,
            dataState: dataState,
            viewportState: viewportState,
            networkService: widget.networkService,
          );
          break;
      }
    }

    return ColoredBox(
      color: bgColor,
      child: RepaintBoundary(
        key: _repaintKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: layoutWidget),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0, // Center horizontally
              child: Center(
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isToolbarHovered = true),
                  onExit: (_) => setState(() => _isToolbarHovered = false),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isToolbarHovered ? 1.0 : 0.3,
                    child: Listener(
                      onPointerDown: (_) {},
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {}, // Prevent taps falling through
                        onDoubleTap:
                            () {}, // Prevent double taps falling through
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  viewportState.zoomBy(1.2, dataState.length);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.zoom_out,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  viewportState.zoomBy(0.8, dataState.length);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  viewportState.shift(-10, dataState.length);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  viewportState.shift(10, dataState.length);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: _takeScreenshot,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  viewportState.scrollToEnd(dataState.length);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              width: 60,
              height: 36,
              child: GestureDetector(
                onTap: () {
                  final baseAxis = document.dimensions.baseAxis;
                  final current = baseAxis is TimeBaseAxis
                      ? baseAxis.timezone
                      : 'UTC';
                  final next = current == 'UTC' ? 'Local' : 'UTC';

                  final patch = PatchPacket.fromJson({
                    "packetType": "patch",
                    "docId": document.meta.id,
                    "payload": {
                      "operations": [
                        {
                          "scope": "dimensions",
                          "op": "replace",
                          "childId": "baseAxis",
                          "value": {"timezone": next},
                        },
                      ],
                    },
                  });
                  chartSetDocumentState.applyPatch(patch);
                  widget.networkService.sendPatch(patch);
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Text(
                    document.dimensions.baseAxis is TimeBaseAxis
                        ? (document.dimensions.baseAxis as TimeBaseAxis)
                              .timezone
                        : 'UTC',
                    style: const TextStyle(
                      color: Color(0xFF787B86),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
