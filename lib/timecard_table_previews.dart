import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'timecard_table.dart';

List<TimecardRow> _sampleRows() => [
  TimecardRow(
    key: 'job1',
    label: 'Project Apollo',
    description: 'Frontend work',
    values: {1: 8, 2: 7.5, 3: 8, 4: 6, 5: 7, 8: 8, 9: 4},
    // Illustrative event markers — excluded from every total.
    markers: {
      6: const TimecardMarker.icon(Icons.sick, color: Colors.redAccent, tooltip: 'Illness'),
      7: const TimecardMarker.icon(Icons.sick, color: Colors.redAccent, tooltip: 'Illness'),
    },
  ),
  TimecardRow(
    key: 'job2',
    label: 'Project Gemini',
    values: {1: 4, 2: 5, 3: 6, 6: 3, 7: 2},
    markers: {
      10: const TimecardMarker.text('H', tooltip: 'Holiday'),
    },
  ),
  TimecardRow(
    key: 'job3',
    label: 'Internal / Admin',
    values: {1: 2, 2: 3, 4: 4, 10: 5},
  ),
];

/// Summary rows: a manual overtime row, the per-day worked+overtime, and a
/// grand row that sums both row-totals — each building on the rows above it.
List<TimecardSummaryRow> _summaryRows() => [
  TimecardSummaryRow.values(
    key: 'overtime',
    label: 'Overtime',
    values: {1: 1, 5: 2, 9: 1.5},
  ),
  TimecardSummaryRow.computed(
    key: 'combined',
    label: 'Worked + OT',
    compute: (day, scope) =>
        scope.dataTotal(day) + (scope.value('overtime', day) ?? 0),
  ),
  TimecardSummaryRow.computed(
    key: 'grand',
    label: 'Grand total',
    // Per day it mirrors the combined row; its trailing total sums the two
    // contributing row-totals directly.
    compute: (day, scope) => scope.value('combined', day),
    rowTotalCompute: (scope) =>
        (scope.rowTotal('overtime') ?? 0) + _dataRowsTotal(scope),
  ),
];

/// Sum of the data rows' totals, for the grand summary row.
double _dataRowsTotal(TimecardSummaryScope scope) =>
    (scope.rowTotal('job1') ?? 0) +
    (scope.rowTotal('job2') ?? 0) +
    (scope.rowTotal('job3') ?? 0);

@Preview(name: 'Default (day numbers + totals)')
Widget defaultTimecard() {
  return Center(
    child: TimecardTable(
      title: const TimecardTitle(text: 'March 2026', subtitle: 'Hours logged'),
      year: 2026,
      month: Month.march,
      timecardRows: _sampleRows(),
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
      title: const TimecardTitle(
        text: 'March 2026',
        subtitle: 'With derived summary rows',
      ),
      year: 2026,
      month: Month.march,
      totals: TimecardTotalsConfig.all,
      timecardRows: _sampleRows(),
      summaryRows: _summaryRows(),
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
        cardShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      timecardRows: _sampleRows(),
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
      style: TimecardTableStyle(
        dayColumnWidth: 44,
        evenRowBackground: Colors.blueGrey.withValues(alpha: 0.06),
      ),
      cellBuilder: (context, cell) {
        if (!cell.hasValue) return const Text('—');
        final heavy = cell.value! >= 8;
        return Text(
          cell.value!.toStringAsFixed(0),
          style: TextStyle(
            fontWeight: heavy ? FontWeight.bold : FontWeight.normal,
            color: heavy ? Colors.red.shade700 : null,
          ),
        );
      },
      timecardRows: _sampleRows(),
    ),
  );
}
