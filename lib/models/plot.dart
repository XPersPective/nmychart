import 'enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SEALED PLOT CONFIG — 5 alt tip
// ─────────────────────────────────────────────────────────────────────────────

sealed class Plot {
  final String id;
  final PlotType type;
  final DataForm dataForm;
  final String axis; // String ID (örn: "axis_price"), Enum değil
  final bool visible;
  final bool affectsScale;
  final bool showLastValue;

  const Plot({
    required this.id,
    required this.type,
    required this.dataForm,
    required this.axis,
    required this.visible,
    required this.affectsScale,
    required this.showLastValue,
  });

  Map<String, dynamic> toJson();

  factory Plot.fromJson(Map<String, dynamic> json) {
    // type string olarak gelir
    final plotType = PlotType.values.byName(json['type'] as String);
    return switch (plotType) {
      PlotType.line => LinePlot.fromJson(json),
      PlotType.area => AreaPlot.fromJson(json),
      PlotType.candlestick => CandlestickPlot.fromJson(json),
      PlotType.bar => BarPlot.fromJson(json),
      PlotType.band => BandPlot.fromJson(json),
    };
  }
}

class LinePlot extends Plot {
  final String value;
  final String color;
  final LineStyle style;

  const LinePlot({
    required super.id,
    required super.axis,
    required super.visible,
    required super.affectsScale,
    required super.showLastValue,
    required super.dataForm,
    required this.value,
    required this.color,
    required this.style,
  }) : super(type: PlotType.line);

  factory LinePlot.fromJson(Map<String, dynamic> json) {
    return LinePlot(
      id: json['id'] as String,
      axis: json['axis'] as String,
      visible: json['visible'] as bool,
      affectsScale: json['affectsScale'] as bool,
      showLastValue: json['showLastValue'] as bool? ?? false,
      dataForm: json.containsKey('dataForm')
          ? DataForm.values.byName(json['dataForm'] as String)
          : DataForm.scalar,
      value: json['value'] as String,
      color: json['color'] as String,
      style: LineStyle.values.byName(json['style'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'dataForm': dataForm.name,
    'axis': axis,
    'visible': visible,
    'affectsScale': affectsScale,
    'showLastValue': showLastValue,
    'value': value,
    'color': color,
    'style': style.name,
  };
}

class AreaPlot extends Plot {
  final String value;
  final String color;
  final LineStyle style;

  const AreaPlot({
    required super.id,
    required super.axis,
    required super.visible,
    required super.affectsScale,
    required super.showLastValue,
    required super.dataForm,
    required this.value,
    required this.color,
    required this.style,
  }) : super(type: PlotType.area);

  factory AreaPlot.fromJson(Map<String, dynamic> json) {
    return AreaPlot(
      id: json['id'] as String,
      axis: json['axis'] as String,
      visible: json['visible'] as bool,
      affectsScale: json['affectsScale'] as bool,
      showLastValue: json['showLastValue'] as bool? ?? false,
      dataForm: json.containsKey('dataForm')
          ? DataForm.values.byName(json['dataForm'] as String)
          : DataForm.scalar,
      value: json['value'] as String,
      color: json['color'] as String,
      style: LineStyle.values.byName(json['style'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'dataForm': dataForm.name,
    'axis': axis,
    'visible': visible,
    'affectsScale': affectsScale,
    'showLastValue': showLastValue,
    'value': value,
    'color': color,
    'style': style.name,
  };
}

class CandlestickPlot extends Plot {
  final String open;
  final String high;
  final String low;
  final String close;
  final String upColor;
  final String downColor;
  final String wickColor; // Eklendi

  const CandlestickPlot({
    required super.id,
    required super.axis,
    required super.visible,
    required super.affectsScale,
    required super.showLastValue,
    required super.dataForm,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.upColor,
    required this.downColor,
    required this.wickColor,
  }) : super(type: PlotType.candlestick);

  factory CandlestickPlot.fromJson(Map<String, dynamic> json) {
    return CandlestickPlot(
      id: json['id'] as String,
      axis: json['axis'] as String,
      visible: json['visible'] as bool,
      affectsScale: json['affectsScale'] as bool,
      showLastValue: json['showLastValue'] as bool? ?? false,
      dataForm: json.containsKey('dataForm')
          ? DataForm.values.byName(json['dataForm'] as String)
          : DataForm.ohlc,
      open: json['open'] as String,
      high: json['high'] as String,
      low: json['low'] as String,
      close: json['close'] as String,
      upColor: json['upColor'] as String,
      downColor: json['downColor'] as String,
      wickColor: (json['wickColor'] ?? '#888888') as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'dataForm': dataForm.name,
    'axis': axis,
    'visible': visible,
    'affectsScale': affectsScale,
    'showLastValue': showLastValue,
    'open': open,
    'high': high,
    'low': low,
    'close': close,
    'upColor': upColor,
    'downColor': downColor,
    'wickColor': wickColor,
  };
}

class BarPlot extends Plot {
  final String value;
  final String color;
  final double width; // Eklendi
  final String? upColor; // Eklendi
  final String? downColor; // Eklendi

  const BarPlot({
    required super.id,
    required super.axis,
    required super.visible,
    required super.affectsScale,
    required super.showLastValue,
    required super.dataForm,
    required this.value,
    required this.color,
    required this.width,
    this.upColor,
    this.downColor,
  }) : super(type: PlotType.bar);

  factory BarPlot.fromJson(Map<String, dynamic> json) {
    return BarPlot(
      id: json['id'] as String,
      axis: json['axis'] as String,
      visible: json['visible'] as bool,
      affectsScale: json['affectsScale'] as bool,
      showLastValue: json['showLastValue'] as bool? ?? false,
      dataForm: json.containsKey('dataForm')
          ? DataForm.values.byName(json['dataForm'] as String)
          : DataForm.scalar,
      value: json['value'] as String,
      color: json['color'] as String,
      width: (json['width'] as num?)?.toDouble() ?? 0.8, // Default 0.8
      upColor: json['upColor'] as String?,
      downColor: json['downColor'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'dataForm': dataForm.name,
    'axis': axis,
    'visible': visible,
    'affectsScale': affectsScale,
    'showLastValue': showLastValue,
    'value': value,
    'color': color,
    'width': width,
    if (upColor != null) 'upColor': upColor,
    if (downColor != null) 'downColor': downColor,
  };
}

class BandPlot extends Plot {
  final String upper;
  final String lower;
  final String upperColor;
  final String lowerColor;
  final String fillColor;
  final LineStyle style;

  const BandPlot({
    required super.id,
    required super.axis,
    required super.visible,
    required super.affectsScale,
    required super.showLastValue,
    required super.dataForm,
    required this.upper,
    required this.lower,
    required this.upperColor,
    required this.lowerColor,
    required this.fillColor,
    required this.style,
  }) : super(type: PlotType.band);

  factory BandPlot.fromJson(Map<String, dynamic> json) {
    return BandPlot(
      id: json['id'] as String,
      axis: json['axis'] as String,
      visible: json['visible'] as bool,
      affectsScale: json['affectsScale'] as bool,
      showLastValue: json['showLastValue'] as bool? ?? false,
      dataForm: json.containsKey('dataForm')
          ? DataForm.values.byName(json['dataForm'] as String)
          : DataForm.band,
      upper: json['upper'] as String,
      lower: json['lower'] as String,
      upperColor: json['upperColor'] as String,
      lowerColor: json['lowerColor'] as String,
      fillColor: json['fillColor'] as String,
      style: LineStyle.values.byName(json['style'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'dataForm': dataForm.name,
    'axis': axis,
    'visible': visible,
    'affectsScale': affectsScale,
    'showLastValue': showLastValue,
    'upper': upper,
    'lower': lower,
    'upperColor': upperColor,
    'lowerColor': lowerColor,
    'fillColor': fillColor,
    'style': style.name,
  };
}
