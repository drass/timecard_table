import 'package:flutter/widgets.dart';

import 'timecard_marker.dart';
import 'utils.dart';

/// A single logical row in a [TimecardTable].
///
/// A row models one tracked entity (a job, project, employee, task, ...) and
/// the numeric value recorded against each day of the displayed month.
///
/// Values are stored as a sparse `day -> value` map: only the days that have
/// an entry need to be present. Days without an entry are treated as "no
/// value" (rendered through [TimecardTableStyle.emptyPlaceholder] and ignored
/// by aggregations).
///
/// Entries can also be keyed by [DateTime] via [dateValues] / [dateMarkers]
/// when that is more convenient than a 1-based day index. Date keys are
/// matched against the column's full date (their time component is ignored),
/// so only entries whose calendar day falls inside the displayed month are
/// shown. When both a day-indexed and a date-keyed entry resolve to the same
/// column, the date-keyed entry wins.
@immutable
class TimecardRow {
  /// Creates a row.
  ///
  /// [key] is a stable identifier used for equality and as the widget key,
  /// [label] is the human readable name shown in the leading column.
  ///
  /// Provide values keyed by 1-based day of month via [values], and/or keyed by
  /// full [DateTime] via [dateValues]; the same applies to [markers] /
  /// [dateMarkers]. The two keying styles can be mixed freely.
  TimecardRow({
    required this.key,
    required this.label,
    this.description,
    Map<int, double>? values,
    Map<int, TimecardMarker>? markers,
    Map<DateTime, double>? dateValues,
    Map<DateTime, TimecardMarker>? dateMarkers,
    this.leading,
    this.color,
    this.metadata,
  })  : values = Map<int, double>.unmodifiable(values ?? const <int, double>{}),
        markers = Map<int, TimecardMarker>.unmodifiable(
          markers ?? const <int, TimecardMarker>{},
        ),
        dateValues = Map<DateTime, double>.unmodifiable(<DateTime, double>{
          if (dateValues != null)
            for (final e in dateValues.entries)
              TimecardUtils.dateKey(e.key): e.value,
        }),
        dateMarkers =
            Map<DateTime, TimecardMarker>.unmodifiable(<DateTime, TimecardMarker>{
          if (dateMarkers != null)
            for (final e in dateMarkers.entries)
              TimecardUtils.dateKey(e.key): e.value,
        });

  /// Stable identifier for this row.
  final String key;

  /// Human readable name displayed in the leading (label) column.
  final String label;

  /// Optional longer description (e.g. for tooltips or custom label builders).
  final String? description;

  /// Sparse map of `day of month (1-based) -> value`.
  final Map<int, double> values;

  /// Sparse map of `day of month (1-based) -> marker`.
  ///
  /// Markers are illustrative event annotations (illness, holiday, ...) and are
  /// never included in any aggregation — only [values] feed totals. A day may
  /// have a value, a marker, or both; see [TimecardTable] for how the default
  /// renderer resolves the two.
  final Map<int, TimecardMarker> markers;

  /// Sparse map of `date -> value`, an alternative to [values] keyed by full
  /// [DateTime]. Keys are normalized to their calendar day (time stripped).
  final Map<DateTime, double> dateValues;

  /// Sparse map of `date -> marker`, the date-keyed counterpart to [markers].
  final Map<DateTime, TimecardMarker> dateMarkers;

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
  ///
  /// When [date] is supplied, a matching [dateValues] entry takes precedence
  /// over the day-indexed [values] entry.
  double? valueOn(int day, [DateTime? date]) {
    if (date != null) {
      final dated = dateValues[TimecardUtils.dateKey(date)];
      if (dated != null) return dated;
    }
    return values[day];
  }

  /// The marker recorded for [day] (1-based), or `null` when absent.
  ///
  /// When [date] is supplied, a matching [dateMarkers] entry takes precedence
  /// over the day-indexed [markers] entry.
  TimecardMarker? markerOn(int day, [DateTime? date]) {
    if (date != null) {
      final dated = dateMarkers[TimecardUtils.dateKey(date)];
      if (dated != null) return dated;
    }
    return markers[day];
  }

  /// Sum of every recorded value in this row, across both [values] and
  /// [dateValues]. Assumes the two maps do not record the same calendar day.
  double get total =>
      values.values.fold<double>(0, (sum, value) => sum + value) +
      dateValues.values.fold<double>(0, (sum, value) => sum + value);

  /// Returns a copy with the provided overrides applied.
  TimecardRow copyWith({
    String? key,
    String? label,
    String? description,
    Map<int, double>? values,
    Map<int, TimecardMarker>? markers,
    Map<DateTime, double>? dateValues,
    Map<DateTime, TimecardMarker>? dateMarkers,
    Widget? leading,
    Color? color,
    Object? metadata,
  }) {
    return TimecardRow(
      key: key ?? this.key,
      label: label ?? this.label,
      description: description ?? this.description,
      values: values ?? this.values,
      markers: markers ?? this.markers,
      dateValues: dateValues ?? this.dateValues,
      dateMarkers: dateMarkers ?? this.dateMarkers,
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
