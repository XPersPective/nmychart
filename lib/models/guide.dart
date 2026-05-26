import 'enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SEALED GUIDE CONFIG — 2 alt tip
// ─────────────────────────────────────────────────────────────────────────────

sealed class Guide {
  final String id;
  final GuideType type;
  final String axis;
  final bool visible;
  final bool affectsScale;

  const Guide({
    required this.id,
    required this.type,
    required this.axis,
    required this.visible,
    required this.affectsScale,
  });

  factory Guide.fromJson(Map<String, dynamic> json) {
    final guideType = GuideType.values.byName(json['type'] as String);
    return switch (guideType) {
      GuideType.line => LineGuide.fromJson(json),
      GuideType.band => BandGuide.fromJson(json),
    };
  }
}

class LineGuide extends Guide {
  final String value;
  final String color;
  final LineStyle style;

  const LineGuide({
    required super.id,
    required super.axis,
    required super.visible,
    required super.affectsScale,
    required this.value,
    required this.color,
    required this.style,
  }) : super(type: GuideType.line);

  factory LineGuide.fromJson(Map<String, dynamic> json) {
    return LineGuide(
      id: json['id'] as String,
      axis: json['axis'] as String,
      visible: json['visible'] as bool,
      affectsScale: json['affectsScale'] as bool,
      value: json['value'] as String,
      color: json['color'] as String,
      style: LineStyle.values.byName(json['style'] as String),
    );
  }
}

class BandGuide extends Guide {
  final String upper;
  final String lower;
  final String upperColor;
  final String lowerColor;
  final String fillColor;

  const BandGuide({
    required super.id,
    required super.axis,
    required super.visible,
    required super.affectsScale,
    required this.upper,
    required this.lower,
    required this.upperColor,
    required this.lowerColor,
    required this.fillColor,
  }) : super(type: GuideType.band);

  factory BandGuide.fromJson(Map<String, dynamic> json) {
    return BandGuide(
      id: json['id'] as String,
      axis: json['axis'] as String,
      visible: json['visible'] as bool,
      affectsScale: json['affectsScale'] as bool,
      upper: json['upper'] as String,
      lower: json['lower'] as String,
      upperColor: json['upperColor'] as String,
      lowerColor: json['lowerColor'] as String,
      fillColor: json['fillColor'] as String,
    );
  }
}
