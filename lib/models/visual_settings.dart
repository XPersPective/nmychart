import 'enums.dart';

class Crosshair {
  final String mode;
  final LineStyle style;
  final String color;
  final bool showLabels;

  const Crosshair({
    required this.mode,
    required this.style,
    required this.color,
    required this.showLabels,
  });

  factory Crosshair.fromJson(Map<String, dynamic> json) {
    return Crosshair(
      mode: json['mode'] as String,
      style: LineStyle.values.byName(json['style'] as String),
      color: json['color'] as String,
      showLabels: json['showLabels'] as bool,
    );
  }
}

class PositionConfig {
  final ContentPosition position;
  final ContentOrientation orientation;

  const PositionConfig({required this.position, required this.orientation});

  factory PositionConfig.fromJson(Map<String, dynamic> json) {
    return PositionConfig(
      position: ContentPosition.values.byName(json['position'] as String),
      orientation: ContentOrientation.values.byName(
        json['orientation'] as String,
      ),
    );
  }
}

class VisualSettings {
  final String theme;
  final Crosshair crosshair;
  final PositionConfig legend;
  final PositionConfig tooltip;

  const VisualSettings({
    required this.theme,
    required this.crosshair,
    required this.legend,
    required this.tooltip,
  });

  factory VisualSettings.fromJson(Map<String, dynamic> json) {
    return VisualSettings(
      theme: json['theme'] as String? ?? 'dark',
      crosshair: Crosshair.fromJson(
        json['crosshair'] as Map<String, dynamic>,
      ),
      legend: PositionConfig.fromJson(json['legend'] as Map<String, dynamic>),
      tooltip: PositionConfig.fromJson(json['tooltip'] as Map<String, dynamic>),
    );
  }
}
