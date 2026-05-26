import 'enums.dart';

class Field {
  final String id;
  final String name;
  final FieldType type; //

  const Field({required this.id, required this.name, required this.type});

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'] as String,
      name: json['name'] as String,
      type: FieldType.values.byName(json['type'] as String),
    );
  }
}
