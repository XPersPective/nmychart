import 'enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SLOT TİPLERİ
// ─────────────────────────────────────────────────────────────────────────────

/// Vertical, Horizontal ve Single layout'lar için ağırlıklı slot.
class WeightedSlot {
  final int index;
  final double weight;
  final double minSize;

  const WeightedSlot({
    required this.index,
    required this.weight,
    required this.minSize,
  });

  factory WeightedSlot.fromJson(Map<String, dynamic> json) {
    return WeightedSlot(
      index: json['index'] as int,
      weight: (json['weight'] as num).toDouble(),
      minSize: (json['minSize'] as num).toDouble(),
    );
  }
}

/// Grid layout için pozisyonlanmış slot.
class GridSlot {
  final int index;
  final int col;
  final int row;
  final int colSpan;
  final int rowSpan;

  const GridSlot({
    required this.index,
    required this.col,
    required this.row,
    required this.colSpan,
    required this.rowSpan,
  });

  factory GridSlot.fromJson(Map<String, dynamic> json) {
    return GridSlot(
      index: json['index'] as int,
      col: json['col'] as int,
      row: json['row'] as int,
      colSpan: json['colSpan'] as int,
      rowSpan: json['rowSpan'] as int,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEALED LAYOUT CONFIG
// ─────────────────────────────────────────────────────────────────────────────

sealed class Layout {
  final LayoutType type;

  const Layout({required this.type});

  factory Layout.fromJson(Map<String, dynamic> json) {
    final layoutType = LayoutType.values.byName(json['type'] as String);
    return switch (layoutType) {
      LayoutType.vertical => VerticalLayout.fromJson(json),
      LayoutType.horizontal => HorizontalLayout.fromJson(json),
      LayoutType.grid => GridLayout.fromJson(json),
      LayoutType.single => SingleLayout.fromJson(json),
    };
  }
}

class VerticalLayout extends Layout {
  final bool resizable;
  final double separatorSize;
  final List<WeightedSlot> slots;

  const VerticalLayout({
    required this.resizable,
    required this.separatorSize,
    required this.slots,
  }) : super(type: LayoutType.vertical);

  factory VerticalLayout.fromJson(Map<String, dynamic> json) {
    return VerticalLayout(
      resizable: json['resizable'] as bool,
      separatorSize: (json['separatorSize'] as num).toDouble(),
      slots: (json['slots'] as List)
          .map((e) => WeightedSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HorizontalLayout extends Layout {
  final bool resizable;
  final double separatorSize;
  final List<WeightedSlot> slots;

  const HorizontalLayout({
    required this.resizable,
    required this.separatorSize,
    required this.slots,
  }) : super(type: LayoutType.horizontal);

  factory HorizontalLayout.fromJson(Map<String, dynamic> json) {
    return HorizontalLayout(
      resizable: json['resizable'] as bool,
      separatorSize: (json['separatorSize'] as num).toDouble(),
      slots: (json['slots'] as List)
          .map((e) => WeightedSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GridLayout extends Layout {
  final int columns;
  final int rows;
  final double gap;
  final List<GridSlot> slots;

  const GridLayout({
    required this.columns,
    required this.rows,
    required this.gap,
    required this.slots,
  }) : super(type: LayoutType.grid);

  factory GridLayout.fromJson(Map<String, dynamic> json) {
    return GridLayout(
      columns: json['columns'] as int,
      rows: json['rows'] as int,
      gap: (json['gap'] as num).toDouble(),
      slots: (json['slots'] as List)
          .map((e) => GridSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SingleLayout extends Layout {
  final double padding;
  final List<WeightedSlot> slots;

  const SingleLayout({required this.padding, required this.slots})
    : super(type: LayoutType.single);

  factory SingleLayout.fromJson(Map<String, dynamic> json) {
    return SingleLayout(
      padding: (json['padding'] as num).toDouble(),
      slots: (json['slots'] as List)
          .map((e) => WeightedSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
