import 'package:flutter/widgets.dart';

import 'utils.dart';

/// Resolves a single cell of a [TimecardSummaryRow.computed] row.
///
/// Return `null` to leave the day blank. The [scope] gives read access to the
/// data totals and to any row (data or *earlier* summary row) so derived rows
/// can build on one another.
typedef TimecardSummaryCompute =
    double? Function(int day, TimecardSummaryScope scope);

/// Resolves the trailing row-total of a [TimecardSummaryRow.computed] row.
typedef TimecardSummaryTotalCompute =
    double Function(TimecardSummaryScope scope);

/// Read-only view passed to summary-row computations.
///
/// Summary rows are evaluated top-to-bottom, so a [TimecardSummaryRow.computed]
/// row can reference the per-day data total, any individual row's value, and any
/// row total — including those of summary rows declared above it. This is what
/// makes chains such as `worked + overtime` then `grand = that + something`
/// possible.
class TimecardSummaryScope {
  /// Wires the scope to the table's resolved data. Used internally by
  /// `TimecardTable`; you only ever *read* from a scope inside a compute
  /// callback.
  const TimecardSummaryScope(this._dataTotal, this._value, this._rowTotal);

  final double Function(int day) _dataTotal;
  final double? Function(String key, int day) _value;
  final double? Function(String key) _rowTotal;

  /// The aggregated total of all *data* rows for [day] — the same figure shown
  /// in the auto column-totals row.
  double dataTotal(int day) => _dataTotal(day);

  /// The value of the row identified by [key] on [day], or `null` when absent.
  ///
  /// [key] may be a [TimecardRow.key] or the key of a summary row declared
  /// above the current one. Treats a missing entry as `null` (use `?? 0` to sum).
  double? value(String key, int day) => _value(key, day);

  /// The trailing row-total of the row identified by [key], or `null` when the
  /// key is unknown.
  double? rowTotal(String key) => _rowTotal(key);
}

/// An extra row rendered beneath the data (and the auto totals row).
///
/// Use [TimecardSummaryRow.values] for a row of explicit per-day numbers (e.g. a
/// manually entered "overtime" row) or [TimecardSummaryRow.computed] for a row
/// derived from other rows via a [TimecardSummaryCompute] callback (e.g.
/// `worked + overtime`). Either way the row can show its own trailing row-total.
@immutable
class TimecardSummaryRow {
  const TimecardSummaryRow._({
    required this.key,
    required this.label,
    this.values,
    this.dateValues,
    this.compute,
    this.rowTotalCompute,
    this.showRowTotal = true,
    this.leading,
    this.background,
    this.textStyle,
  });

  /// A summary row backed by explicit per-day values.
  ///
  /// Values can be keyed by 1-based day of month via [values] and/or by full
  /// [DateTime] via [dateValues]; a matching date entry takes precedence.
  factory TimecardSummaryRow.values({
    required String key,
    required String label,
    Map<int, double>? values,
    Map<DateTime, double>? dateValues,
    bool showRowTotal = true,
    Widget? leading,
    Color? background,
    TextStyle? textStyle,
  }) {
    return TimecardSummaryRow._(
      key: key,
      label: label,
      values: Map<int, double>.unmodifiable(values ?? const <int, double>{}),
      dateValues: Map<DateTime, double>.unmodifiable(<DateTime, double>{
        if (dateValues != null)
          for (final e in dateValues.entries)
            TimecardUtils.dateKey(e.key): e.value,
      }),
      showRowTotal: showRowTotal,
      leading: leading,
      background: background,
      textStyle: textStyle,
    );
  }

  /// A summary row whose cells are derived from other rows via [compute].
  ///
  /// By default the trailing row-total is the aggregation of the computed
  /// per-day values; supply [rowTotalCompute] to override it (e.g. to sum other
  /// row totals directly).
  factory TimecardSummaryRow.computed({
    required String key,
    required String label,
    required TimecardSummaryCompute compute,
    TimecardSummaryTotalCompute? rowTotalCompute,
    bool showRowTotal = true,
    Widget? leading,
    Color? background,
    TextStyle? textStyle,
  }) {
    return TimecardSummaryRow._(
      key: key,
      label: label,
      compute: compute,
      rowTotalCompute: rowTotalCompute,
      showRowTotal: showRowTotal,
      leading: leading,
      background: background,
      textStyle: textStyle,
    );
  }

  /// Stable identifier; also the key other rows reference via
  /// [TimecardSummaryScope.value] / [TimecardSummaryScope.rowTotal].
  final String key;

  /// Text shown in the leading column.
  final String label;

  /// Explicit per-day values for a [TimecardSummaryRow.values] row.
  final Map<int, double>? values;

  /// Explicit date-keyed values for a [TimecardSummaryRow.values] row. Keys are
  /// normalized to their calendar day (time stripped).
  final Map<DateTime, double>? dateValues;

  /// Per-day computation for a [TimecardSummaryRow.computed] row.
  final TimecardSummaryCompute? compute;

  /// Optional override for the trailing row-total of a computed row.
  final TimecardSummaryTotalCompute? rowTotalCompute;

  /// Whether to render this row's trailing total cell (when the table shows the
  /// row-totals column).
  final bool showRowTotal;

  /// Optional custom widget for the leading column (replaces [label]).
  final Widget? leading;

  /// Optional background tint override for this row.
  final Color? background;

  /// Optional text style override for this row's cells.
  final TextStyle? textStyle;

  /// The value for [day], resolved against [scope]. `null` leaves the cell blank.
  ///
  /// When [date] is supplied, a matching [dateValues] entry takes precedence
  /// over the day-indexed [values] entry. Ignored for computed rows.
  double? valueOn(int day, TimecardSummaryScope scope, [DateTime? date]) {
    if (compute != null) return compute!(day, scope);
    if (date != null) {
      final dated = dateValues?[TimecardUtils.dateKey(date)];
      if (dated != null) return dated;
    }
    return values?[day];
  }
}
