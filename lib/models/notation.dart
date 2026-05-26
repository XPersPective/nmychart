import 'enums.dart';

class NotationRule {
  final String text;
  final String icon;
  final String color;
  final NotationPosition position;
  final double offset;

  const NotationRule({
    required this.text,
    required this.icon,
    required this.color,
    required this.position,
    required this.offset,
  });

  factory NotationRule.fromJson(Map<String, dynamic> json) {
    return NotationRule(
      text: json['text'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      position: NotationPosition.values.byName(json['position'] as String),
      offset: (json['offset'] as num).toDouble(),
    );
  }
}

class Notation {
  final String id;
  final NotationType type;
  final Axis axis;
  final String value;
  final String anchor;
  final bool visible;
  final bool affectsScale;
  final Map<String, NotationRule> rules;

  const Notation({
    required this.id,
    required this.type,
    required this.axis,
    required this.value,
    required this.anchor,
    required this.visible,
    required this.affectsScale,
    required this.rules,
  });

  factory Notation.fromJson(Map<String, dynamic> json) {
    final rulesJson = json['rules'] as Map<String, dynamic>;
    final rules = rulesJson.map(
      (key, value) =>
          MapEntry(key, NotationRule.fromJson(value as Map<String, dynamic>)),
    );

    return Notation(
      id: json['id'] as String,
      type: NotationType.values.byName(json['type'] as String),
      axis: Axis.values.byName(json['axis'] as String),
      value: json['value'] as String,
      anchor: json['anchor'] as String,
      visible: json['visible'] as bool,
      affectsScale: json['affectsScale'] as bool,
      rules: rules,
    );
  }
}
