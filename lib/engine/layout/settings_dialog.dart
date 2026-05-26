import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../models/models.dart';

import '../state/chartset_document_state.dart';
import '../../../services/chart_network_service.dart';

class SettingsDialog extends StatefulWidget {
  final Chart chart;
  final ChartSetDocumentState chartSetDocumentState;
  final ChartNetworkService networkService;

  const SettingsDialog({
    super.key,
    required this.chart,
    required this.chartSetDocumentState,
    required this.networkService,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late Map<String, dynamic> _editableInputs;
  late Map<String, Map<String, dynamic>> _editablePlots;

  @override
  void initState() {
    super.initState();
    _initStates();
  }

  void _initStates() {
    Chart currentChart = widget.chart;
    final doc = widget.chartSetDocumentState.document;
    if (doc != null) {
      for (var slot in doc.charts) {
        for (var c in slot) {
          if (c.meta.id == widget.chart.meta.id) {
            currentChart = c;
            break;
          }
        }
      }
    }

    _editableInputs = {};
    for (var input in currentChart.inputs) {
      _editableInputs[input.id] = input.toJson();
    }

    _editablePlots = {};
    for (var plot in currentChart.plots) {
      final jsonMap = plot.toJson();
      if (plot is BarPlot) {
        jsonMap['upColor'] ??= '#26A69A';
        jsonMap['downColor'] ??= '#EF5350';
      }
      _editablePlots[plot.id] = jsonMap;
    }
  }

  void _resetToDefaults() {
    setState(() {
      final shortName = widget.chart.meta.shortName.toUpperCase();
      
      // Reset inputs
      for (var inputId in _editableInputs.keys) {
        if (inputId == 'in_ma_length' || inputId == 'in_rsi_length') {
          _editableInputs[inputId]['value'] = 14;
        }
      }
      
      // Reset plots
      for (var plotId in _editablePlots.keys) {
        final plotMap = _editablePlots[plotId]!;
        plotMap['visible'] = true;
        plotMap['showLastValue'] = true;
        
        if (shortName.contains('MA')) {
          plotMap['type'] = 'line';
          plotMap['color'] = '#1890FF';
        } else if (shortName.contains('RSI')) {
          plotMap['type'] = 'line';
          plotMap['color'] = '#8C8C8C';
        } else if (shortName.contains('VOL') || shortName.contains('VOLUME')) {
          plotMap['type'] = 'bar';
          plotMap['color'] = '#888888';
          plotMap['upColor'] = '#26A69A';
          plotMap['downColor'] = '#EF5350';
        } else if (plotMap['type'] == 'candlestick' || plotMap['type'] == 'bar' || shortName.contains('/') || shortName.contains('BTC') || shortName.contains('ETH')) {
          plotMap['type'] = 'candlestick';
          plotMap['upColor'] = '#26A69A';
          plotMap['downColor'] = '#EF5350';
          plotMap['wickColor'] = '#737375';
          plotMap['open'] = plotMap['open'] ?? 'f_open';
          plotMap['high'] = plotMap['high'] ?? 'f_high';
          plotMap['low'] = plotMap['low'] ?? 'f_low';
          plotMap['close'] = plotMap['close'] ?? 'f_close';
        }
      }
    });
    _applyChanges();
  }

  void _applyChanges() {
    List<PatchOperationItem> operations = [];

    final currentDocument = widget.chartSetDocumentState.document;
    if (currentDocument == null) return;

    Chart? currentChart;
    for (var slot in currentDocument.charts) {
      for (var c in slot) {
        if (c.meta.id == widget.chart.meta.id) {
          currentChart = c;
          break;
        }
      }
    }
    currentChart ??= widget.chart;

    for (var input in currentChart.inputs) {
      final oldJson = input.toJson();
      final newJson = _editableInputs[input.id];
      if (newJson != null && jsonEncode(oldJson) != jsonEncode(newJson)) {
        operations.add(
          ChildPatchItem(
            scope: PatchScope.input,
            op: PatchOperation.replace,
            targetId: currentChart.meta.id,
            childId: input.id,
            value: newJson,
          ),
        );
      }
    }

    for (var plot in currentChart.plots) {
      final oldJson = plot.toJson();
      final newJson = _editablePlots[plot.id];
      if (newJson != null && jsonEncode(oldJson) != jsonEncode(newJson)) {
        operations.add(
          ChildPatchItem(
            scope: PatchScope.plot,
            op: PatchOperation.replace,
            targetId: currentChart.meta.id,
            childId: plot.id,
            value: newJson,
          ),
        );
      }
    }

    if (operations.isNotEmpty) {
      final patch = PatchPacket(
        docId: currentDocument.meta.id,
        revision: currentDocument.meta.revision,
        operations: operations,
      );

      // 🔥 Lokal state senkronizasyonu: patch'i önce uygulayıp sonra network'e gönder
      widget.chartSetDocumentState.applyPatch(patch);
      widget.networkService.sendPatch(patch);
    }
  }

  Color _colorFromHex(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    } else if (hexCode.length == 8) {
      return Color(int.parse(hexCode, radix: 16));
    }
    return Colors.white;
  }

  String _hexFromColor(Color color) {
    return '#${(color.toARGB32() & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  Widget _buildColorPickerRow(
    String label,
    String plotId,
    String colorKey,
    String defaultHex,
  ) {
    final currentHex = _editablePlots[plotId]?[colorKey] ?? defaultHex;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        GestureDetector(
          onTap: () {
            Color tempColor = _colorFromHex(currentHex);
            showDialog(
              context: context,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    return AlertDialog(
                      title: const Text('Pick a color'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: tempColor,
                          onColorChanged: (c) {
                            tempColor = c;
                            setState(() {
                              _editablePlots[plotId]![colorKey] = _hexFromColor(c);
                            });
                            setDialogState(() {});
                            _applyChanges();
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Got it'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _colorFromHex(currentHex),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white30),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E222D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 400,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${widget.chart.meta.name} Settings",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  if (widget.chart.inputs.isNotEmpty) ...[
                    ..._buildInputs(),
                    const Divider(color: Colors.white24, height: 32),
                  ],
                  if (widget.chart.plots.isNotEmpty) ...[..._buildPlots()],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _resetToDefaults,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text(
                    "Reset",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInputs() {
    return widget.chart.inputs.map((input) {
      final valType = input.type;
      final currentVal = _editableInputs[input.id]?['value'];

      Widget inputField;

      if (valType == InputType.boolean) {
        inputField = Switch(
          value: currentVal == true,
          activeThumbColor: const Color(0xFF2962FF),
          onChanged: (val) {
            setState(() {
              _editableInputs[input.id]?['value'] = val;
            });
            _applyChanges();
          },
        );
      } else if (valType == InputType.integer || valType == InputType.double) {
        inputField = TextFormField(
          initialValue: currentVal?.toString() ?? "0",
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            isDense: true,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2962FF)),
            ),
          ),
          onChanged: (val) {
            if (valType == InputType.integer) {
              _editableInputs[input.id]?['value'] = int.tryParse(val) ?? 0;
            } else {
              _editableInputs[input.id]?['value'] = double.tryParse(val) ?? 0.0;
            }
            _applyChanges();
          },
        );
      } else {
        inputField = TextFormField(
          initialValue: currentVal?.toString() ?? "",
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            isDense: true,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2962FF)),
            ),
          ),
          onChanged: (val) {
            _editableInputs[input.id]?['value'] = val;
            _applyChanges();
          },
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                input.name,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            Expanded(flex: 4, child: inputField),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildPlots() {
    return widget.chart.plots.map((plot) {
      final currentVisible = _editablePlots[plot.id]?['visible'] ?? true;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2B3139),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              title: Text(
                plot.id.replaceAll('plot_', '').toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white54,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Visible",
                            style: TextStyle(color: Colors.white70),
                          ),
                          Switch(
                            value: currentVisible == true,
                            activeThumbColor: const Color(0xFF2962FF),
                            onChanged: (val) {
                              setState(() {
                                _editablePlots[plot.id]?['visible'] = val;
                              });
                              _applyChanges();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Show Last Value",
                            style: TextStyle(color: Colors.white70),
                          ),
                          Switch(
                            value:
                                _editablePlots[plot.id]?['showLastValue'] ==
                                true,
                            activeThumbColor: const Color(0xFF2962FF),
                            onChanged: (val) {
                              setState(() {
                                _editablePlots[plot.id]?['showLastValue'] = val;
                              });
                              _applyChanges();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Plot Type",
                            style: TextStyle(color: Colors.white70),
                          ),
                          DropdownButton<String>(
                            value: _editablePlots[plot.id]?['type'] ?? 'line',
                            dropdownColor: const Color(0xFF2B3139),
                            style: const TextStyle(color: Colors.white),
                            items: plot.dataForm == DataForm.ohlc
                                ? const [
                                    DropdownMenuItem(
                                      value: 'line',
                                      child: Text('Line'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'candlestick',
                                      child: Text('Candles'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'bar',
                                      child: Text('Bar'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'area',
                                      child: Text('Area'),
                                    ),
                                  ]
                                : const [
                                    DropdownMenuItem(
                                      value: 'line',
                                      child: Text('Line'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'bar',
                                      child: Text('Bar'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'area',
                                      child: Text('Area'),
                                    ),
                                  ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _editablePlots[plot.id]!['type'] = val;
                                  if (val == 'line' || val == 'area' || val == 'bar') {
                                    _editablePlots[plot.id]!['value'] ??= 'f_close';
                                    _editablePlots[plot.id]!['color'] ??= '#2962FF';
                                    _editablePlots[plot.id]!['style'] ??= 'solid';
                                    if (val == 'bar') {
                                      _editablePlots[plot.id]!['width'] ??= 0.8;
                                    }
                                  } else if (val == 'candlestick') {
                                    _editablePlots[plot.id]!['open'] ??= 'f_open';
                                    _editablePlots[plot.id]!['high'] ??= 'f_high';
                                    _editablePlots[plot.id]!['low'] ??= 'f_low';
                                    _editablePlots[plot.id]!['close'] ??= 'f_close';
                                    _editablePlots[plot.id]!['upColor'] ??= '#26A69A';
                                    _editablePlots[plot.id]!['downColor'] ??= '#EF5350';
                                    _editablePlots[plot.id]!['wickColor'] ??= '#737375';
                                  }
                                });
                                _applyChanges();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_editablePlots[plot.id]!.containsKey('color') &&
                          _editablePlots[plot.id]?['type'] != 'bar')
                        _buildColorPickerRow(
                          "Color",
                          plot.id,
                          "color",
                          "#FFFFFF",
                        ),
                      if (_editablePlots[plot.id]?['type'] == 'bar' ||
                          _editablePlots[plot.id]?['type'] == 'candlestick')
                        Column(
                          children: [
                            _buildColorPickerRow(
                              "Up Color",
                              plot.id,
                              "upColor",
                              "#26A69A",
                            ),
                            const SizedBox(height: 8),
                            _buildColorPickerRow(
                              "Down Color",
                              plot.id,
                              "downColor",
                              "#EF5350",
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
