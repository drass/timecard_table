import 'package:flutter/widgets.dart';

import 'timecard_marker.dart';
import 'timecard_row.dart';

/// Aggregates a set of cell values into a single summary number.
///
/// Used for column totals (per day), row totals (per row) and the grand total.
/// Defaults to a plain sum but can be swapped for averages, max, custom
/// weighting, etc.
typedef TimecardAggregator = double Function(Iterable<double> values);

/// Turns a numeric value into the string shown inside a cell or total.
typedef TimecardValueFormatter = String Function(double value);

/// Builds the widget shown in a day header cell.
typedef TimecardHeaderBuilder =
    Widget Function(BuildContext context, TimecardHeaderContext header);

/// Builds the widget shown in a data cell.
typedef TimecardCellBuilder =
    Widget Function(BuildContext context, TimecardCellContext cell);

/// Builds the widget shown in the leading (label) column of a data row.
typedef TimecardLabelBuilder =
    Widget Function(BuildContext context, TimecardRow row, int rowIndex);

/// Builds the widget shown in a totals cell (column / row / grand total).
typedef TimecardTotalBuilder =
    Widget Function(BuildContext context, TimecardTotalContext total);

/// Resolves the text label for a day header when using the built-in renderer.
typedef TimecardHeaderLabelResolver = String Function(TimecardHeaderContext header);

/// Called when a data cell is tapped.
typedef TimecardCellTapCallback = void Function(TimecardCellContext cell);

/// Built-in presets controlling what a day header displays.
///
/// Use [TimecardHeaderLabel.custom] together with
/// [TimecardHeaderConfig.labelResolver] or [TimecardTable.headerBuilder] for
/// anything else.
enum TimecardHeaderLabel {
  /// The day number only, e.g. `1`, `2`, ... `31`.
  dayNumber,

  /// Abbreviated weekday name, e.g. `Mon`.
  weekdayShort,

  /// Full weekday name, e.g. `Monday`.
  weekdayLong,

  /// Day number stacked above its short weekday name, e.g. `1` / `Mon`.
  dayAndWeekday,

  /// The full date formatted by [TimecardHeaderConfig.dateFormatter].
  fullDate,

  /// Resolve the label through [TimecardHeaderConfig.labelResolver].
  custom,
}

/// What kind of total a [TimecardTotalContext] represents.
enum TimecardTotalKind {
  /// Per-day total shown in the bottom totals row.
  column,

  /// Per-row total shown in the trailing totals column.
  row,

  /// The single grand total in the bottom-right corner.
  grand,
}

/// Context passed to header builders / label resolvers for one day column.
@immutable
class TimecardHeaderContext {
  const TimecardHeaderContext({
    required this.day,
    required this.date,
    required this.isWeekend,
    required this.isToday,
  });

  /// 1-based day of the month.
  final int day;

  /// The full date this column represents.
  final DateTime date;

  /// Whether [date] falls on a configured weekend day.
  final bool isWeekend;

  /// Whether [date] is today.
  final bool isToday;
}

/// Context passed to cell builders / tap callbacks for one data cell.
@immutable
class TimecardCellContext {
  const TimecardCellContext({
    required this.row,
    required this.rowIndex,
    required this.day,
    required this.date,
    required this.value,
    required this.isWeekend,
    required this.isToday,
    this.marker,
  });

  /// The row this cell belongs to.
  final TimecardRow row;

  /// Zero-based index of [row] within the table's rows.
  final int rowIndex;

  /// 1-based day of the month for this cell.
  final int day;

  /// The full date this cell represents.
  final DateTime date;

  /// The recorded value, or `null` when the day has no entry.
  final double? value;

  /// Whether [date] falls on a configured weekend day.
  final bool isWeekend;

  /// Whether [date] is today.
  final bool isToday;

  /// The illustrative marker for this day, or `null` when absent. Markers never
  /// contribute to totals.
  final TimecardMarker? marker;

  /// Whether this cell has a recorded value.
  bool get hasValue => value != null;

  /// Whether this cell has an illustrative marker.
  bool get hasMarker => marker != null;
}

/// Context passed to total builders for a column / row / grand total cell.
@immutable
class TimecardTotalContext {
  const TimecardTotalContext({
    required this.kind,
    required this.total,
    this.day,
    this.date,
    this.row,
    this.isWeekend = false,
    this.isToday = false,
  });

  /// Which kind of total this cell shows.
  final TimecardTotalKind kind;

  /// The aggregated value.
  final double total;

  /// 1-based day for [TimecardTotalKind.column] totals, otherwise `null`.
  final int? day;

  /// The date for [TimecardTotalKind.column] totals, otherwise `null`.
  final DateTime? date;

  /// The row for [TimecardTotalKind.row] totals, otherwise `null`.
  final TimecardRow? row;

  /// Whether the related day is a weekend (column totals only).
  final bool isWeekend;

  /// Whether the related day is today (column totals only).
  final bool isToday;
}
