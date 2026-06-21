import 'package:flutter/widgets.dart';

import 'timecard_models.dart';

/// Configures the summarization the table performs and which totals it shows.
///
/// The table is, first and foremost, a summarization tool: by default it adds
/// a per-day totals row at the bottom. Enable [showRowTotals] for a per-row
/// total column and [showGrandTotal] for the single bottom-right figure.
///
/// All three are computed with [aggregator] (a plain sum by default). The
/// grand total is computed from the raw values so it stays consistent even
/// with non-additive aggregators (e.g. average).
@immutable
class TimecardTotalsConfig {
  const TimecardTotalsConfig({
    this.showColumnTotals = true,
    this.showRowTotals = false,
    this.showGrandTotal = false,
    this.aggregator = sum,
    this.columnTotalLabel = 'Total',
    this.rowTotalHeader = 'Total',
    this.includeEmptyAsZero = false,
  });

  /// Convenience: nothing summarised, just the raw grid.
  static const TimecardTotalsConfig none = TimecardTotalsConfig(
    showColumnTotals: false,
  );

  /// Convenience: per-day, per-row and grand totals all on.
  static const TimecardTotalsConfig all = TimecardTotalsConfig(
    showRowTotals: true,
    showGrandTotal: true,
  );

  /// Whether to render the per-day totals row beneath the data.
  final bool showColumnTotals;

  /// Whether to render the per-row totals column to the right of the data.
  final bool showRowTotals;

  /// Whether to render the grand total in the bottom-right corner. Implies a
  /// totals row and column being present for placement.
  final bool showGrandTotal;

  /// How a set of values is reduced to one summary number.
  final TimecardAggregator aggregator;

  /// Label shown in the leading column of the totals row.
  final String columnTotalLabel;

  /// Header shown atop the totals column.
  final String rowTotalHeader;

  /// When `true`, days without an entry contribute `0` to the aggregation
  /// instead of being skipped. Affects averages / counts, not plain sums.
  final bool includeEmptyAsZero;

  /// Default aggregator: the arithmetic sum.
  static double sum(Iterable<double> values) =>
      values.fold<double>(0, (acc, v) => acc + v);

  /// Helper aggregator: arithmetic mean (0 for an empty input).
  static double average(Iterable<double> values) {
    if (values.isEmpty) return 0;
    return sum(values) / values.length;
  }

  /// Helper aggregator: the maximum value (0 for an empty input).
  static double max(Iterable<double> values) =>
      values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);

  TimecardTotalsConfig copyWith({
    bool? showColumnTotals,
    bool? showRowTotals,
    bool? showGrandTotal,
    TimecardAggregator? aggregator,
    String? columnTotalLabel,
    String? rowTotalHeader,
    bool? includeEmptyAsZero,
  }) {
    return TimecardTotalsConfig(
      showColumnTotals: showColumnTotals ?? this.showColumnTotals,
      showRowTotals: showRowTotals ?? this.showRowTotals,
      showGrandTotal: showGrandTotal ?? this.showGrandTotal,
      aggregator: aggregator ?? this.aggregator,
      columnTotalLabel: columnTotalLabel ?? this.columnTotalLabel,
      rowTotalHeader: rowTotalHeader ?? this.rowTotalHeader,
      includeEmptyAsZero: includeEmptyAsZero ?? this.includeEmptyAsZero,
    );
  }
}
