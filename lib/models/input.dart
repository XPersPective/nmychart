import 'enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SEALED INPUT CONFIG — 7 alt tip
// ─────────────────────────────────────────────────────────────────────────────

sealed class Input {
  final String id;
  final String name;
  final InputType type;

  const Input({required this.id, required this.name, required this.type});

  factory Input.fromJson(Map<String, dynamic> json) {
    final inputType = InputType.values.byName(json['type'] as String);
    return switch (inputType) {
      InputType.string => StringInput.fromJson(json),
      InputType.symbol => SymbolInput.fromJson(json),
      InputType.interval => IntervalInput.fromJson(json),
      InputType.integer => IntegerInput.fromJson(json),
      InputType.double => DoubleInput.fromJson(json),
      InputType.boolean => BooleanInput.fromJson(json),
      InputType.dateTime => DateTimeInput.fromJson(json),
    };
  }

  Map<String, dynamic> toJson();
}

class StringInput extends Input {
  final String value;

  const StringInput({
    required super.id,
    required super.name,
    required this.value,
  }) : super(type: InputType.string);

  factory StringInput.fromJson(Map<String, dynamic> json) {
    return StringInput(
      id: json['id'] as String,
      name: json['name'] as String,
      value: json['value'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'value': value,
  };

  StringInput copyWith({
    String? id,
    String? name,
    String? value,
  }) {
    return StringInput(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }
}

class SymbolInput extends Input {
  final String value;
  final String base;
  final String quote;

  const SymbolInput({
    required super.id,
    required super.name,
    required this.value,
    required this.base,
    required this.quote,
  }) : super(type: InputType.symbol);

  factory SymbolInput.fromJson(Map<String, dynamic> json) {
    return SymbolInput(
      id: json['id'] as String,
      name: json['name'] as String,
      value: json['value'] as String,
      base: json['base'] as String,
      quote: json['quote'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'value': value,
    'base': base,
    'quote': quote,
  };

  SymbolInput copyWith({
    String? id,
    String? name,
    String? value,
    String? base,
    String? quote,
  }) {
    return SymbolInput(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      base: base ?? this.base,
      quote: quote ?? this.quote,
    );
  }
}

class IntervalInput extends Input {
  final String value;

  const IntervalInput({
    required super.id,
    required super.name,
    required this.value,
  }) : super(type: InputType.interval);

  factory IntervalInput.fromJson(Map<String, dynamic> json) {
    return IntervalInput(
      id: json['id'] as String,
      name: json['name'] as String,
      value: json['value'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'value': value,
  };

  IntervalInput copyWith({
    String? id,
    String? name,
    String? value,
  }) {
    return IntervalInput(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }
}

class IntegerInput extends Input {
  final int value;
  final int? min;
  final int? max;

  const IntegerInput({
    required super.id,
    required super.name,
    required this.value,
    this.min,
    this.max,
  }) : super(type: InputType.integer);

  factory IntegerInput.fromJson(Map<String, dynamic> json) {
    return IntegerInput(
      id: json['id'] as String,
      name: json['name'] as String,
      value: json['value'] as int,
      min: json['min'] as int?,
      max: json['max'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'value': value,
    if (min != null) 'min': min,
    if (max != null) 'max': max,
  };

  IntegerInput copyWith({
    String? id,
    String? name,
    int? value,
    int? min,
    int? max,
  }) {
    return IntegerInput(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }
}

class DoubleInput extends Input {
  final double value;
  final double? min;
  final double? max;

  const DoubleInput({
    required super.id,
    required super.name,
    required this.value,
    this.min,
    this.max,
  }) : super(type: InputType.double);

  factory DoubleInput.fromJson(Map<String, dynamic> json) {
    return DoubleInput(
      id: json['id'] as String,
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'value': value,
    if (min != null) 'min': min,
    if (max != null) 'max': max,
  };

  DoubleInput copyWith({
    String? id,
    String? name,
    double? value,
    double? min,
    double? max,
  }) {
    return DoubleInput(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }
}

class BooleanInput extends Input {
  final bool value;

  const BooleanInput({
    required super.id,
    required super.name,
    required this.value,
  }) : super(type: InputType.boolean);

  factory BooleanInput.fromJson(Map<String, dynamic> json) {
    return BooleanInput(
      id: json['id'] as String,
      name: json['name'] as String,
      value: json['value'] as bool,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'value': value,
  };

  BooleanInput copyWith({
    String? id,
    String? name,
    bool? value,
  }) {
    return BooleanInput(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }
}

class DateTimeInput extends Input {
  final int value; // Unix timestamp milisaniye

  const DateTimeInput({
    required super.id,
    required super.name,
    required this.value,
  }) : super(type: InputType.dateTime);

  factory DateTimeInput.fromJson(Map<String, dynamic> json) {
    return DateTimeInput(
      id: json['id'] as String,
      name: json['name'] as String,
      value: json['value'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'value': value,
  };

  DateTimeInput copyWith({
    String? id,
    String? name,
    int? value,
  }) {
    return DateTimeInput(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }
}
