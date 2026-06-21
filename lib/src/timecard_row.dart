import 'package:flutter/widgets.dart';

/// A single logical row in a [TimecardTable].
///
/// A row models one tracked entity (a job, project, employee, task, ...) and
/// the numeric value recorded against each day of the displayed month.
///
/// Values are stored as a sparse `day -> value` map: only the days that have
/// an entry need to be present. Days without an entry are treated as "no
/// value" (rendered through [TimecardTableStyle.emptyPlaceholder] and ignored
/// by aggregations).
@immutable
class TimecardRow {
  /// Creates a row.
  ///
  /// [key] is a stable identifier used for equality and as the widget key,
  /// [label] is the human readable name shown in the leading column.
  TimecardRow({
    required this.key,
    required this.label,
    this.description,
    Map<int, double>? values,
    this.leading,
    this.color,
    this.metadata,
  }) : values = Map<int, double>.unmodifiable(values ?? const <int, double>{});

  /// Stable identifier for this row.
  final String key;

  /// Human readable name displayed in the leading (label) column.
  final String label;

  /// Optional longer description (e.g. for tooltips or custom label builders).
  final String? description;

  /// Sparse map of `day of month (1-based) -> value`.
  final Map<int, double> values;

  /// Optional fully custom widget rendered in the leading column instead of
  /// the default label. Takes precedence over [label] when the default label
  /// builder is used.
  final Widget? leading;

  /// Optional accent color a custom builder (or the default styling) may use
  /// to tint this row.
  final Color? color;

  /// Arbitrary user payload, handy inside custom cell / label builders.
  final Object? metadata;

  /// The value recorded for [day] (1-based), or `null` when absent.
  double? valueOn(int day) => values[day];

  /// Sum of every recorded value in this row.
  double get total =>
      values.values.fold<double>(0, (sum, value) => sum + value);

  /// Returns a copy with the provided overrides applied.
  TimecardRow copyWith({
    String? key,
    String? label,
    String? description,
    Map<int, double>? values,
    Widget? leading,
    Color? color,
    Object? metadata,
  }) {
    return TimecardRow(
      key: key ?? this.key,
      label: label ?? this.label,
      description: description ?? this.description,
      values: values ?? this.values,
      leading: leading ?? this.leading,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TimecardRow && other.key == key);

  @override
  int get hashCode => key.hashCode;
}
