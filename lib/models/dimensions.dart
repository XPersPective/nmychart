import 'enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// YARDIMCI MODELLER
// ─────────────────────────────────────────────────────────────────────────────

class Grid {
  final bool visible;
  final String color;
  final LineStyle style;
  final double width;

  const Grid({
    required this.visible,
    required this.color,
    required this.style,
    required this.width,
  });

  factory Grid.fromJson(Map<String, dynamic> json) {
    return Grid(
      visible: json['visible'] as bool,
      color: (json['color'] as String?) ?? '#333333',
      style: json['style'] != null
          ? LineStyle.values.byName(json['style'] as String)
          : LineStyle.solid,
      width: (json['width'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class Format {
  final String type;
  final int precision;

  const Format({required this.type, required this.precision});

  factory Format.fromJson(Map<String, dynamic> json) {
    return Format(
      type: json['type'] as String,
      precision: json['precision'] as int,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEALED BASE AXIS CONFIG
// ─────────────────────────────────────────────────────────────────────────────

sealed class BaseAxis {
  final String id;
  final Axis axis;
  final BaseAxisType type;
  final String title;
  final Grid? grid;

  const BaseAxis({
    required this.id,
    required this.axis,
    required this.type,
    required this.title,
    this.grid,
  });

  factory BaseAxis.fromJson(Map<String, dynamic> json) {
    final axisType = BaseAxisType.values.byName(json['type'] as String);
    return switch (axisType) {
      BaseAxisType.time => TimeBaseAxis.fromJson(json),
      BaseAxisType.category => CategoryBaseAxis.fromJson(json),
      BaseAxisType.linear => LinearBaseAxis.fromJson(json),
    };
  }
}

class TimeBaseAxis extends BaseAxis {
  final bool isSorted;
  final bool isEquidistant;
  final GapPolicy gapPolicy;
  final String timezone;
  final TimezoneDisplayMode timezoneDisplayMode;

  const TimeBaseAxis({
    required super.id,
    required super.axis,
    required super.title,
    super.grid,
    required this.isSorted,
    required this.isEquidistant,
    required this.gapPolicy,
    required this.timezone,
    required this.timezoneDisplayMode,
  }) : super(type: BaseAxisType.time);

  factory TimeBaseAxis.fromJson(Map<String, dynamic> json) {
    return TimeBaseAxis(
      id: json['id'] as String,
      axis: Axis.values.byName(json['axis'] as String),
      title: json['title'] as String,
      grid: json['grid'] != null
          ? Grid.fromJson(json['grid'] as Map<String, dynamic>)
          : null,
      isSorted: json['isSorted'] as bool,
      isEquidistant: json['isEquidistant'] as bool,
      gapPolicy: GapPolicy.values.byName(json['gapPolicy'] as String),
      timezone: json['timezone'] as String,
      timezoneDisplayMode: TimezoneDisplayMode.values.byName(
        json['timezoneDisplayMode'] as String,
      ),
    );
  }
}

class CategoryBaseAxis extends BaseAxis {
  final double gapRatio;
  final double groupGapRatio;

  const CategoryBaseAxis({
    required super.id,
    required super.axis,
    required super.title,
    super.grid,
    required this.gapRatio,
    required this.groupGapRatio,
  }) : super(type: BaseAxisType.category);

  factory CategoryBaseAxis.fromJson(Map<String, dynamic> json) {
    return CategoryBaseAxis(
      id: json['id'] as String,
      axis: Axis.values.byName(json['axis'] as String),
      title: json['title'] as String,
      grid: json['grid'] != null
          ? Grid.fromJson(json['grid'] as Map<String, dynamic>)
          : null,
      gapRatio: (json['gapRatio'] as num).toDouble(),
      groupGapRatio: (json['groupGapRatio'] as num).toDouble(),
    );
  }
}

class LinearBaseAxis extends BaseAxis {
  final bool isSorted;
  final double min;
  final double max;
  final double step;

  const LinearBaseAxis({
    required super.id,
    required super.axis,
    required super.title,
    super.grid,
    required this.isSorted,
    required this.min,
    required this.max,
    required this.step,
  }) : super(type: BaseAxisType.linear);

  factory LinearBaseAxis.fromJson(Map<String, dynamic> json) {
    return LinearBaseAxis(
      id: json['id'] as String,
      axis: Axis.values.byName(json['axis'] as String),
      title: json['title'] as String,
      grid: json['grid'] != null
          ? Grid.fromJson(json['grid'] as Map<String, dynamic>)
          : null,
      isSorted: json['isSorted'] as bool,
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
      step: (json['step'] as num).toDouble(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEALED VALUE AXIS CONFIG
// ─────────────────────────────────────────────────────────────────────────────

sealed class ValueAxis {
  final String id;
  final Axis axis;
  final ValueAxisType type;
  final String title;
  final Grid? grid;

  const ValueAxis({
    required this.id,
    required this.axis,
    required this.type,
    required this.title,
    this.grid,
  });

  factory ValueAxis.fromJson(Map<String, dynamic> json) {
    final axisType = ValueAxisType.values.byName(json['type'] as String);
    return switch (axisType) {
      ValueAxisType.linear => LinearValueAxis.fromJson(json),
    };
  }
}

class LinearValueAxis extends ValueAxis {
  final bool autoScale;
  final double? min;
  final double? max;

  const LinearValueAxis({
    required super.id,
    required super.axis,
    required super.title,
    super.grid,
    required this.autoScale,
    this.min,
    this.max,
  }) : super(type: ValueAxisType.linear);

  factory LinearValueAxis.fromJson(Map<String, dynamic> json) {
    return LinearValueAxis(
      id: json['id'] as String,
      axis: Axis.values.byName(json['axis'] as String),
      title: json['title'] as String,
      grid: json['grid'] != null
          ? Grid.fromJson(json['grid'] as Map<String, dynamic>)
          : null,
      autoScale: json['autoScale'] as bool,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
    );
  }
}

// NOT: LogValueAxis ve PercentageValueAxis enum'da yorum satırında.
// Enum aktif edildiğinde buraya eklenecek.
// LogValueAxis → base: int, autoScale: bool, treatZeroAs: double?, format: Format
// PercentageValueAxis → min: double, max: double, format: Format

// ─────────────────────────────────────────────────────────────────────────────
// DIMENSION CONFIG (wrapper)
// ─────────────────────────────────────────────────────────────────────────────

class Dimensions {
  final BaseAxis baseAxis;
  final List<ValueAxis> valuesAxis;

  const Dimensions({required this.baseAxis, required this.valuesAxis});

  factory Dimensions.fromJson(Map<String, dynamic> json) {
    return Dimensions(
      baseAxis: BaseAxis.fromJson(
        json['baseAxis'] as Map<String, dynamic>,
      ),
      valuesAxis: (json['valuesAxis'] as List)
          .map((e) => ValueAxis.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
