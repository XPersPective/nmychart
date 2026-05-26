import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nmychart/nmychart.dart' hide Axis;
import 'package:window_manager/window_manager.dart';
 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      alwaysOnTop: true,
      // center: true,
      title: 'NmyChart Ultimate Demo',
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
    );

    unawaited(
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      }),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NmyChart - v5 PRO Architecture',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF131722),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1c2030),
          elevation: 0,
        ),
      ),
      home: const ChartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late final NmyChartController _chartController;

  @override
  void initState() {
    super.initState();
    _chartController = NmyChartController();
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NmyChart PRO Engine',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          // TradingView Style Unified Toolbar (Scrollable & Overflow-Proof)
          ListenableBuilder(
            listenable: _chartController,
            builder: (context, child) {
              if (!_chartController.hasData) {
                return const SizedBox.shrink();
              }

              final symbolInput = _chartController.inputs
                  .whereType<SymbolInput>()
                  .firstOrNull;
              final intervalInput = _chartController.inputs
                  .whereType<IntervalInput>()
                  .firstOrNull;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF1c2030),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF2B3139), width: 1),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tune,
                        size: 16,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Kontrol Paneli: ',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (symbolInput != null) ...[
                        const Text(
                          'Sembol: ',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        DropdownButton<String>(
                          value:
                              [
                                'BTC/USDT',
                                'ETH/USDT',
                                'SOL/USDT',
                              ].contains(symbolInput.value)
                              ? symbolInput.value
                              : 'BTC/USDT',
                          dropdownColor: const Color(0xFF1c2030),
                          underline: const SizedBox.shrink(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'BTC/USDT',
                              child: Text('BTC/USDT'),
                            ),
                            DropdownMenuItem(
                              value: 'ETH/USDT',
                              child: Text('ETH/USDT'),
                            ),
                            DropdownMenuItem(
                              value: 'SOL/USDT',
                              child: Text('SOL/USDT'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              final parts = val.split('/');
                              final base = parts[0];
                              final quote = parts[1];
                              _chartController.updateInputs([
                                symbolInput.copyWith(
                                  value: val,
                                  base: base,
                                  quote: quote,
                                ),
                              ]);
                            }
                          },
                        ),
                      ],
                      const SizedBox(width: 20),
                      if (intervalInput != null) ...[
                        const Text(
                          'Periyot: ',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        DropdownButton<String>(
                          value:
                              [
                                '15m',
                                '1H',
                                '4H',
                                '1D',
                              ].contains(intervalInput.value)
                              ? intervalInput.value
                              : '1H',
                          dropdownColor: const Color(0xFF1c2030),
                          underline: const SizedBox.shrink(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '15m',
                              child: Text('15 Dakika (15m)'),
                            ),
                            DropdownMenuItem(
                              value: '1H',
                              child: Text('1 Saat (1H)'),
                            ),
                            DropdownMenuItem(
                              value: '4H',
                              child: Text('4 Saat (4H)'),
                            ),
                            DropdownMenuItem(
                              value: '1D',
                              child: Text('1 Gün (1D)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              _chartController.updateInputs([
                                intervalInput.copyWith(value: val),
                              ]);
                            }
                          },
                        ),
                      ],
                      ElevatedButton.icon(
                        onPressed: () {
                          final doc = _chartController.inputs.isNotEmpty
                              ? true
                              : false; // just to check if ready
                          if (doc) {
                            _chartController.setTheme('light');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Tema "light" olarak değiştirildi! (Dark dönmek için kodda değiştirin)',
                                ),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.palette, size: 14),
                        label: const Text('Temayı Değiştir (Light)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        offset: const Offset(0, 36),
                        color: const Color(0xFF1c2030),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: Color(0xFF2B3139)),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2962FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_chart,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'İndikatör Ekle',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onSelected: (value) {
                          _chartController.addIndicator(value);
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'MA',
                                child: Text(
                                  'Moving Average (MA)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'RSI',
                                child: Text(
                                  'Relative Strength Index (RSI)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(child: NmyChart.mock(controller: _chartController)),
        ],
      ),
    );
  }
}
