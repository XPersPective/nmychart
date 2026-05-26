import 'chart_meta.dart';
import 'legend.dart';
import 'input.dart';
import 'field.dart';
import 'plot.dart';
import 'guide.dart';
import 'notation.dart';

class Chart {
  final ChartMeta meta;
  final ChartLegend legend;
  final List<Input> inputs;
  final List<Field> fields;
  final List<Plot> plots;
  final List<List<dynamic>> data;
  final List<Guide> guides;
  final List<Notation> notations;

  const Chart({
    required this.meta,
    required this.legend,
    required this.inputs,
    required this.fields,
    required this.plots,
    required this.data,
    required this.guides,
    required this.notations,
  });

  factory Chart.fromJson(Map<String, dynamic> json) {
    return Chart(
      meta: ChartMeta.fromJson(json['meta'] as Map<String, dynamic>),
      legend: ChartLegend.fromJson(
        json['legend'] as Map<String, dynamic>,
      ),
      inputs: ((json['inputs'] as List?) ?? [])
          .map((e) => Input.fromJson(e as Map<String, dynamic>))
          .toList(),
      fields: ((json['fields'] as List?) ?? [])
          .map((e) => Field.fromJson(e as Map<String, dynamic>))
          .toList(),
      plots: ((json['plots'] as List?) ?? [])
          .map((e) => Plot.fromJson(e as Map<String, dynamic>))
          .toList(),
      data:
          (json['data'] as List?)
              ?.map((e) => (e as List).toList())
              .toList() ??
          [],
      guides: ((json['guides'] as List?) ?? [])
          .map((e) => Guide.fromJson(e as Map<String, dynamic>))
          .toList(),
      notations: ((json['notations'] as List?) ?? [])
          .map((e) => Notation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
