import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'timecard_table.dart';

List<TimecardRow> _sampleRows() => [
  TimecardRow(key: 'job1', label: 'Project Apollo', description: 'Frontend work', values: {1: 8, 2: 7.5, 3: 8, 4: 6, 5: 7, 8: 8, 9: 4}),
  TimecardRow(key: 'job2', label: 'Project Gemini', values: {1: 4, 2: 5, 3: 6, 6: 3, 7: 2}),
  TimecardRow(key: 'job3', label: 'Internal / Admin', values: {1: 2, 2: 3, 4: 4, 10: 5}),
  TimecardRow(
    key: 'special_events',
    label: 'Special Events',
    markers: {
      6: const TimecardMarker.icon(Icons.sick, color: Colors.greenAccent, tooltip: 'Illness'),
      7: const TimecardMarker.icon(Icons.sick, color: Colors.redAccent, tooltip: 'Illness'),

      10: const TimecardMarker.text('H', tooltip: 'Holiday'),
    },
  ),
];

/// Summary rows: a manual overtime row, the per-day worked+overtime, and a
/// grand row that sums both row-totals — each building on the rows above it.
List<TimecardSummaryRow> _summaryRows() => [
  TimecardSummaryRow.values(key: 'overtime', label: 'Overtime', values: {1: 1, 5: 2, 9: 1.5}),
  TimecardSummaryRow.computed(
    key: 'combined',
    label: 'Worked + OT',
    compute: (day, scope) => scope.dataTotal(day) + (scope.value('overtime', day) ?? 0),
  ),
  TimecardSummaryRow.computed(
    key: 'grand',
    label: 'Grand total',
    // Per day it mirrors the combined row; its trailing total sums the two
    // contributing row-totals directly.
    compute: (day, scope) => scope.value('combined', day),
    rowTotalCompute: (scope) => (scope.rowTotal('overtime') ?? 0) + _dataRowsTotal(scope),
  ),
];

/// Sum of the data rows' totals, for the grand summary row.
double _dataRowsTotal(TimecardSummaryScope scope) =>
    (scope.rowTotal('job1') ?? 0) + (scope.rowTotal('job2') ?? 0) + (scope.rowTotal('job3') ?? 0);

@Preview(name: 'Default (day numbers + totals)')
Widget defaultTimecard() {
  return Center(
    child: TimecardTable(
      title: const TimecardTitle(text: 'March 2026', subtitle: 'Hours logged'),
      year: 2026,
      month: Month.march,
      timecardRows: _sampleRows(),
      holidays: const {10: 'Public holiday'},
    ),
  );
}

@Preview(name: 'Inclined weekday matrix + row/grand totals')
Widget inclinedTimecard() {
  return Center(
    child: TimecardTable(
      title: const TimecardTitle(text: 'Inclined headers'),
      year: 2026,
      month: Month.march,
      headerConfig: TimecardHeaderConfig.inclinedWeekdays,
      totals: TimecardTotalsConfig.all,
      timecardRows: _sampleRows(),
    ),
  );
}

@Preview(name: 'Vertical full dates')
Widget verticalDatesTimecard() {
  return Center(
    child: TimecardTable(
      year: 2026,
      month: Month.march,
      headerConfig: TimecardHeaderConfig.verticalDates,
      totals: TimecardTotalsConfig.all,
      timecardRows: _sampleRows(),
    ),
  );
}

@Preview(name: 'Summary rows (overtime + combined + grand)')
Widget summaryRowsTimecard() {
  return Center(
    child: TimecardTable(
      title: const TimecardTitle(text: 'March 2026', subtitle: 'With derived summary rows'),
      year: 2026,
      month: Month.march,
      totals: TimecardTotalsConfig.all,
      timecardRows: _sampleRows(),
      summaryRows: _summaryRows(),
    ),
  );
}

/// Interval bands: two lanes of highlighted day ranges, each span with its own
/// message and color, placed above the data rows.
List<TimecardSpanRow> _spanRows() => [
  const TimecardSpanRow(
    key: 'periods',
    label: 'Periods',
    placement: TimecardSpanPlacement.top,
    spans: [
      TimecardSpan(from: 1, to: 12, label: 'Onboarding & training', icon: Icons.school, background: Color(0xFFB3D4FF)),
      TimecardSpan(from: 14, to: 22, label: 'On site — Milan', icon: Icons.place, background: Color(0xFFFFD9A0)),
      TimecardSpan(from: 25, to: 31, label: 'Remote', background: Color(0xFFC8E6C9)),
    ],
  ),
  TimecardSpanRow(
    key: 'leave',
    label: 'Leave',
    placement: TimecardSpanPlacement.top,
    spans: [
      // Date bounds may start before the displayed month: the band is clipped
      // to the visible range and its clipped edge is drawn square.
      TimecardSpan.dates(from: DateTime(2026, 2, 25), to: DateTime(2026, 3, 4), label: 'Parental leave', background: const Color(0xFFF8BBD0)),
      TimecardSpan.dates(from: DateTime(2026, 3, 18), to: DateTime(2026, 3, 19), label: 'PTO', background: const Color(0xFFE1BEE7)),
    ],
  ),
];

@Preview(name: 'Interval bands (span rows)')
Widget spanRowsTimecard() {
  return Center(
    child: TimecardTable(
      title: const TimecardTitle(text: 'March 2026', subtitle: 'Highlighted day intervals'),
      year: 2026,
      month: Month.march,
      totals: TimecardTotalsConfig.all,
      timecardRows: _sampleRows(),
      spanRows: _spanRows(),
      onSpanTap: (span) => debugPrint('${span.span.label}: ${span.resolved.startDay}-${span.resolved.endDay}'),
    ),
  );
}

@Preview(name: 'Card cells')
Widget cardTimecard() {
  return Center(
    child: TimecardTable(
      title: const TimecardTitle(text: 'Card layout'),
      year: 2026,
      month: Month.march,
      headerConfig: TimecardHeaderConfig.dayAndWeekday,
      totals: TimecardTotalsConfig.all,
      style: TimecardTableStyle(
        cardMode: true,
        cardSpacing: 6,
        cardRadius: 10,
        cardShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      timecardRows: _sampleRows(),
    ),
  );
}

@Preview(name: 'Date-keyed values + clickable cells')
Widget datedClickableTimecard() {
  return Center(
    child: TimecardTable(
      title: const TimecardTitle(text: 'March 2026', subtitle: 'Values keyed by date, tappable cells'),
      year: 2026,
      month: Month.march,
      totals: TimecardTotalsConfig.all,
      // Cells, day headers and totals all respond to taps with a hover
      // highlight, ripple and pointer cursor.
      onCellTap: (cell) => debugPrint('cell ${cell.date} = ${cell.value}'),
      onHeaderTap: (header) => debugPrint('header ${header.date}'),
      onTotalTap: (total) => debugPrint('${total.kind} total = ${total.total}'),
      timecardRows: [
        TimecardRow(
          key: 'job1',
          label: 'Project Apollo',
          // Entries keyed by full DateTime instead of a day index.
          dateValues: {DateTime(2026, 3, 1): 8, DateTime(2026, 3, 2): 7.5, DateTime(2026, 3, 3): 8, DateTime(2026, 3, 4): 6},
        ),
        // Day-index and date keys can be mixed across rows (or within one).
        TimecardRow(key: 'job2', label: 'Project Gemini', values: {1: 4, 2: 5}, dateValues: {DateTime(2026, 3, 3): 6}),
      ],
    ),
  );
}

@Preview(name: 'Averages with custom builders')
Widget customizedTimecard() {
  return Center(
    child: TimecardTable(
      year: 2026,
      month: Month.march,
      headerConfig: TimecardHeaderConfig.dayAndWeekday,
      totals: const TimecardTotalsConfig(
        showRowTotals: true,
        showGrandTotal: true,
        aggregator: TimecardTotalsConfig.average,
        columnTotalLabel: 'Avg',
        rowTotalHeader: 'Avg',
      ),
      style: TimecardTableStyle(dayColumnWidth: 44, evenRowBackground: Colors.blueGrey.withValues(alpha: 0.06)),
      cellBuilder: (context, cell) {
        if (!cell.hasValue) return const Text('—');
        final heavy = cell.value! >= 8;
        return Text(
          cell.value!.toStringAsFixed(0),
          style: TextStyle(fontWeight: heavy ? FontWeight.bold : FontWeight.normal, color: heavy ? Colors.red.shade700 : null),
        );
      },
      timecardRows: _sampleRows(),
    ),
  );
}
