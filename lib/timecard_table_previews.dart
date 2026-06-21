import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'timecard_table.dart';

List<TimecardRow> _sampleRows() => [
  TimecardRow(
    key: 'job1',
    label: 'Project Apollo',
    description: 'Frontend work',
    values: {1: 8, 2: 7.5, 3: 8, 4: 6, 5: 7, 8: 8, 9: 4},
  ),
  TimecardRow(
    key: 'job2',
    label: 'Project Gemini',
    values: {1: 4, 2: 5, 3: 6, 6: 3, 7: 2},
  ),
  TimecardRow(
    key: 'job3',
    label: 'Internal / Admin',
    values: {1: 2, 2: 3, 4: 4, 10: 5},
  ),
];

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
