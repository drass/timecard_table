import 'package:flutter/material.dart';

import 'timecard_style.dart';
import 'utils.dart';

/// Builds the content of a span band. Called once per band; the result is
/// centered over the band's whole interval.
typedef TimecardSpanBuilder =
    Widget Function(BuildContext context, TimecardSpanContext span);

/// Called when a span band is tapped.
typedef TimecardSpanTapCallback = void Function(TimecardSpanContext span);

/// Where a [TimecardSpanRow] is inserted in the table.
enum TimecardSpanPlacement {
  /// Directly beneath the day-header row, above the data rows.
  top,

  /// Beneath everything else (data rows, totals row and summary rows).
  bottom,
}

/// A highlighted, closed day interval inside a [TimecardSpanRow].
///
/// A span is purely illustrative — like a [TimecardMarker] it never takes part
/// in any aggregation. It renders as a colored band stretching from its first
/// to its last day, with an optional message drawn once, centered over the
/// whole band, so an interval such as "1 → 12 January: training" reads as a
/// single continuous bar rather than twelve identical cells.
///
/// Bounds can be given as 1-based days of the displayed month ([TimecardSpan.new])
/// or as full dates ([TimecardSpan.dates]). Date bounds may fall outside the
/// displayed month/day window: the band is then clipped to what is visible and
/// the clipped edge is drawn flat (instead of rounded) to signal that the
/// interval continues.
@immutable
class TimecardSpan {
  /// A span covering the 1-based days [from]..[to] of the displayed month
  /// (inclusive). Bounds are normalized, so `from: 12, to: 1` is accepted.
  const TimecardSpan({
    required int from,
    required int to,
    this.label,
    this.background,
    this.textStyle,
    this.icon,
    this.iconColor,
    this.tooltip,
    this.child,
    this.radius,
    this.metadata,
  })  : _fromDay = from,
        _toDay = to,
        _fromDate = null,
        _toDate = null;

  /// A span covering the calendar days [from]..[to] (inclusive, time ignored).
  ///
  /// Bounds outside the displayed month — or outside a [TimecardTable.startDay]
  /// / [TimecardTable.endDay] window — are clipped to the visible range; a span
  /// that does not intersect it at all is skipped.
  const TimecardSpan.dates({
    required DateTime from,
    required DateTime to,
    this.label,
    this.background,
    this.textStyle,
    this.icon,
    this.iconColor,
    this.tooltip,
    this.child,
    this.radius,
    this.metadata,
  })  : _fromDate = from,
        _toDate = to,
        _fromDay = null,
        _toDay = null;

  final int? _fromDay;
  final int? _toDay;
  final DateTime? _fromDate;
  final DateTime? _toDate;

  /// Message drawn once, centered over the whole band. `null` leaves the band
  /// blank (a plain colored bar).
  final String? label;

  /// Band color. Falls back to [TimecardTableStyle.spanBackground].
  final Color? background;

  /// Text style for [label]. Falls back to [TimecardTableStyle.spanTextStyle].
  final TextStyle? textStyle;

  /// Optional icon drawn before [label].
  final IconData? icon;

  /// Tint for [icon]. Defaults to [label]'s color.
  final Color? iconColor;

  /// Optional hover/long-press tooltip. Defaults to [label] when the band is
  /// too narrow to show it in full.
  final String? tooltip;

  /// Fully custom band content, replacing the [icon]/[label] pair.
  final Widget? child;

  /// Corner radius of the band's outer edges. Falls back to
  /// [TimecardTableStyle.spanRadius].
  final double? radius;

  /// Arbitrary user payload, handy in [TimecardSpanTapCallback] / builders.
  final Object? metadata;

  /// Whether this span was declared with date bounds.
  bool get isDateBased => _fromDate != null;

  /// The inclusive start date, when this span was declared with
  /// [TimecardSpan.dates].
  DateTime? get fromDate => _fromDate;

  /// The inclusive end date, when this span was declared with
  /// [TimecardSpan.dates].
  DateTime? get toDate => _toDate;

  /// Resolves this span against the displayed month and the visible day window
  /// `[firstDay, lastDay]`, or returns `null` when it falls entirely outside.
  ResolvedTimecardSpan? resolve(
    int year,
    int month, {
    required int firstDay,
    required int lastDay,
  }) {
    int start;
    int end;
    var clippedStart = false;
    var clippedEnd = false;

    if (_fromDate != null && _toDate != null) {
      final monthStart = DateTime(year, month, firstDay);
      final monthEnd = DateTime(year, month, lastDay);
      var from = TimecardUtils.dateKey(_fromDate);
      var to = TimecardUtils.dateKey(_toDate);
      if (from.isAfter(to)) {
        final swap = from;
        from = to;
        to = swap;
      }
      if (to.isBefore(monthStart) || from.isAfter(monthEnd)) return null;
      clippedStart = from.isBefore(monthStart);
      clippedEnd = to.isAfter(monthEnd);
      start = clippedStart ? firstDay : from.day;
      end = clippedEnd ? lastDay : to.day;
    } else {
      start = _fromDay!;
      end = _toDay!;
      if (start > end) {
        final swap = start;
        start = end;
        end = swap;
      }
      if (end < firstDay || start > lastDay) return null;
      clippedStart = start < firstDay;
      clippedEnd = end > lastDay;
      start = start.clamp(firstDay, lastDay);
      end = end.clamp(firstDay, lastDay);
    }

    return ResolvedTimecardSpan(
      span: this,
      startDay: start,
      endDay: end,
      startDate: DateTime(year, month, start),
      endDate: DateTime(year, month, end),
      clippedStart: clippedStart,
      clippedEnd: clippedEnd,
    );
  }
}

/// A [TimecardSpan] clipped to the table's visible day window.
@immutable
class ResolvedTimecardSpan {
  const ResolvedTimecardSpan({
    required this.span,
    required this.startDay,
    required this.endDay,
    required this.startDate,
    required this.endDate,
    required this.clippedStart,
    required this.clippedEnd,
  });

  /// The span this was resolved from.
  final TimecardSpan span;

  /// First visible 1-based day covered by the band.
  final int startDay;

  /// Last visible 1-based day covered by the band.
  final int endDay;

  /// Date of [startDay].
  final DateTime startDate;

  /// Date of [endDay].
  final DateTime endDate;

  /// Whether the interval starts before the visible window.
  final bool clippedStart;

  /// Whether the interval ends after the visible window.
  final bool clippedEnd;

  /// Number of day columns the band covers.
  int get length => endDay - startDay + 1;

  /// Whether [day] (1-based) falls inside the band.
  bool covers(int day) => day >= startDay && day <= endDay;
}

/// A row that highlights one or more day intervals as colored bands.
///
/// Unlike [TimecardRow] / [TimecardSummaryRow] a span row holds no numbers: it
/// is an annotation lane, so it never contributes to any total and its trailing
/// total cell stays empty. Add as many span rows as you have overlapping
/// intervals — within a single row, the first span covering a day wins.
///
/// ```dart
/// TimecardTable(
///   year: 2026,
///   month: Month.january,
///   timecardRows: rows,
///   spanRows: [
///     TimecardSpanRow(
///       key: 'periods',
///       label: 'Periods',
///       placement: TimecardSpanPlacement.top,
///       spans: [
///         TimecardSpan(from: 1, to: 12, label: 'Training', background: Colors.indigo),
///         TimecardSpan(from: 15, to: 20, label: 'On site', background: Colors.teal),
///       ],
///     ),
///   ],
/// )
/// ```
@immutable
class TimecardSpanRow {
  const TimecardSpanRow({
    required this.key,
    required this.spans,
    this.label = '',
    this.leading,
    this.placement = TimecardSpanPlacement.bottom,
    this.background,
    this.textStyle,
    this.height,
    this.inset,
    this.metadata,
  });

  /// Stable identifier, also used as the row's widget key.
  final String key;

  /// The intervals to highlight. Evaluated in order: on an overlap, the first
  /// span that covers a day is the one drawn.
  final List<TimecardSpan> spans;

  /// Text shown in the leading column.
  final String label;

  /// Optional custom widget for the leading column (replaces [label]).
  final Widget? leading;

  /// Whether the row sits right below the header or beneath everything else.
  final TimecardSpanPlacement placement;

  /// Background of the row's cells *outside* any band. Falls back to
  /// [TimecardTableStyle.spanRowBackground].
  final Color? background;

  /// Text style for the leading [label]. Falls back to
  /// [TimecardTableStyle.labelTextStyle].
  final TextStyle? textStyle;

  /// Row height. Falls back to [TimecardTableStyle.spanRowHeight].
  final double? height;

  /// Inset between a band and its cell, giving the band its "pill" look.
  /// Falls back to [TimecardTableStyle.spanInset].
  final EdgeInsets? inset;

  /// Arbitrary user payload.
  final Object? metadata;

  /// Resolves [spans] against the displayed month, dropping the ones outside
  /// the visible day window.
  List<ResolvedTimecardSpan> resolveSpans(
    int year,
    int month, {
    required int firstDay,
    required int lastDay,
  }) {
    final resolved = <ResolvedTimecardSpan>[];
    for (final span in spans) {
      final r = span.resolve(year, month, firstDay: firstDay, lastDay: lastDay);
      if (r != null) resolved.add(r);
    }
    return resolved;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TimecardSpanRow && other.key == key);

  @override
  int get hashCode => key.hashCode;
}

/// Context passed to span builders / tap callbacks for one band.
@immutable
class TimecardSpanContext {
  const TimecardSpanContext({
    required this.row,
    required this.rowIndex,
    required this.resolved,
    required this.day,
    required this.date,
  });

  /// The span row this band belongs to.
  final TimecardSpanRow row;

  /// Zero-based index of [row] within [TimecardTable.spanRows].
  final int rowIndex;

  /// The band's resolved (clipped) interval.
  final ResolvedTimecardSpan resolved;

  /// The 1-based day of the cell that was tapped / is being built.
  final int day;

  /// The date of [day].
  final DateTime date;

  /// The span being rendered.
  TimecardSpan get span => resolved.span;
}
