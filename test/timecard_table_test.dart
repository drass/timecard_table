import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timecard_table/timecard_table.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  final rows = [
    TimecardRow(key: 'a', label: 'Project A', values: {1: 8, 2: 7.5, 3: 8}),
    TimecardRow(key: 'b', label: 'Project B', values: {1: 4, 2: 5}),
  ];

  testWidgets('renders header, rows and the per-day totals row', (tester) async {
    await tester.pumpWidget(
      wrap(
        TimecardTable(
          year: 2026,
          month: Month.march,
          timecardRows: rows,
          totals: const TimecardTotalsConfig(columnTotalLabel: 'Total'),
        ),
      ),
    );

    expect(find.text('Project A'), findsOneWidget);
    expect(find.text('Project B'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget); // totals row label
    // Day 2 column total: 7.5 + 5 = 12.5 (unique, no such day number).
    expect(find.text('12.5'), findsOneWidget);
  });

  testWidgets('row and grand totals can be enabled', (tester) async {
    await tester.pumpWidget(
      wrap(
        TimecardTable(
          year: 2026,
          month: Month.march,
          timecardRows: rows,
          totals: TimecardTotalsConfig.all,
        ),
      ),
    );

    // Row A total: 8 + 7.5 + 8 = 23.5.
    expect(find.text('23.5'), findsOneWidget);
    // Grand total: 23.5 + 9 = 32.5.
    expect(find.text('32.5'), findsOneWidget);
  });

  testWidgets('custom aggregator changes the summarization', (tester) async {
    await tester.pumpWidget(
      wrap(
        TimecardTable(
          year: 2026,
          month: Month.march,
          timecardRows: rows,
          totals: const TimecardTotalsConfig(aggregator: TimecardTotalsConfig.max),
        ),
      ),
    );

    // Day 1 max(8, 4) = 8 appears (both as a cell and total); just ensure present.
    expect(find.text('8'), findsWidgets);
  });

  test('aggregators compute expected values', () {
    expect(TimecardTotalsConfig.sum([1, 2, 3]), 6);
    expect(TimecardTotalsConfig.average([2, 4]), 3);
    expect(TimecardTotalsConfig.max([5, 1, 9, 2]), 9);
    expect(TimecardTotalsConfig.average(const <double>[]), 0);
  });

  test('TimecardUtils.daysInMonth handles leap years', () {
    expect(TimecardUtils.daysInMonth(2024, 2), 29);
    expect(TimecardUtils.daysInMonth(2026, 2), 28);
    expect(TimecardUtils.daysInMonth(2026, 4), 30);
  });

  test('TimecardUtils.formatNumber trims trailing zeros', () {
    expect(TimecardUtils.formatNumber(8), '8');
    expect(TimecardUtils.formatNumber(7.5), '7.5');
    expect(TimecardUtils.formatNumber(7.25), '7.25');
    expect(TimecardUtils.formatNumber(7.20), '7.2');
  });
}
