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

  testWidgets('summary rows render and compute from data + earlier rows',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        TimecardTable(
          year: 2026,
          month: Month.march,
          timecardRows: rows,
          totals: TimecardTotalsConfig.all,
          summaryRows: [
            TimecardSummaryRow.values(
              key: 'ot',
              label: 'Overtime',
              values: {1: 1, 2: 2},
            ),
            TimecardSummaryRow.computed(
              key: 'combined',
              label: 'Combined',
              compute: (day, scope) =>
                  scope.dataTotal(day) + (scope.value('ot', day) ?? 0),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Overtime'), findsOneWidget);
    expect(find.text('Combined'), findsOneWidget);
    // Day 2: data total 7.5 + 5 = 12.5, plus overtime 2 = 14.5 (unique).
    expect(find.text('14.5'), findsOneWidget);
  });

  testWidgets('a computed row can reference another row total', (tester) async {
    await tester.pumpWidget(
      wrap(
        TimecardTable(
          year: 2026,
          month: Month.march,
          timecardRows: rows,
          totals: TimecardTotalsConfig.all,
          summaryRows: [
            TimecardSummaryRow.values(key: 'ot', label: 'OT', values: {1: 4}),
            TimecardSummaryRow.computed(
              key: 'grand',
              label: 'Grand',
              compute: (day, scope) => scope.dataTotal(day),
              // Grand row-total: data grand (32.5) + overtime total (4) = 36.5.
              rowTotalCompute: (scope) =>
                  (scope.rowTotal('a') ?? 0) +
                  (scope.rowTotal('b') ?? 0) +
                  (scope.rowTotal('ot') ?? 0),
            ),
          ],
        ),
      ),
    );

    // a=23.5, b=9, ot=4 -> 36.5 (unique).
    expect(find.text('36.5'), findsOneWidget);
  });

  testWidgets('markers render and are excluded from totals', (tester) async {
    await tester.pumpWidget(
      wrap(
        TimecardTable(
          year: 2026,
          month: Month.march,
          totals: TimecardTotalsConfig.all,
          timecardRows: [
            TimecardRow(
              key: 'm',
              label: 'Marked',
              values: {1: 8},
              markers: {
                2: const TimecardMarker.icon(Icons.sick, tooltip: 'Illness'),
              },
            ),
          ],
        ),
      ),
    );

    // The marker renders...
    expect(find.byIcon(Icons.sick), findsOneWidget);
    // ...and the only value (8) is the grand total — the marker added nothing.
    expect(find.text('8'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card mode + decorations build without layout errors',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        TimecardTable(
          year: 2026,
          month: Month.march,
          timecardRows: rows,
          totals: TimecardTotalsConfig.all,
          style: const TimecardTableStyle(
            cardMode: true,
            cardSpacing: 6,
            cardRadius: 8,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Project A'), findsOneWidget);
  });

  testWidgets('date-keyed values render and feed totals', (tester) async {
    await tester.pumpWidget(
      wrap(
        TimecardTable(
          year: 2026,
          month: Month.march,
          totals: TimecardTotalsConfig.all,
          timecardRows: [
            TimecardRow(
              key: 'd',
              label: 'Dated',
              // Mixed keying: day 1 by index, March 2 by full date.
              values: {1: 8},
              dateValues: {DateTime(2026, 3, 2): 7.5},
            ),
          ],
        ),
      ),
    );

    // The date-keyed cell renders on its column and the totals sum both
    // (8 + 7.5 = 15.5 appears as the row total and the grand total).
    expect(find.text('7.5'), findsWidgets);
    expect(find.text('15.5'), findsWidgets);
  });

  testWidgets('date keys outside the displayed month are ignored',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        TimecardTable(
          year: 2026,
          month: Month.march,
          totals: TimecardTotalsConfig.all,
          timecardRows: [
            TimecardRow(
              key: 'd',
              label: 'Dated',
              dateValues: {
                DateTime(2026, 3, 1): 8, // shown
                DateTime(2026, 4, 1): 99, // different month -> ignored
              },
            ),
          ],
        ),
      ),
    );

    expect(find.text('99'), findsNothing);
    expect(find.text('8'), findsWidgets); // value + total, no 99 contribution
  });

  testWidgets('data, header and total cells fire tap callbacks',
      (tester) async {
    TimecardCellContext? tappedCell;
    TimecardHeaderContext? tappedHeader;
    TimecardTotalContext? tappedTotal;

    await tester.pumpWidget(
      wrap(
        TimecardTable(
          year: 2026,
          month: Month.march,
          timecardRows: rows,
          totals: TimecardTotalsConfig.all,
          // Restrict to a few days and disable scrolling so the targeted texts
          // are unique and on-screen.
          startDay: 1,
          endDay: 3,
          scrollable: false,
          onCellTap: (c) => tappedCell = c,
          onHeaderTap: (h) => tappedHeader = h,
          onTotalTap: (t) => tappedTotal = t,
        ),
      ),
    );

    // The InkWell overlay intentionally sits above the cell content (it is the
    // full-cell tap target), so the tap lands on it rather than the Text.
    await tester.tap(find.text('7.5'), warnIfMissed: false); // A, day 2
    await tester.pump();
    expect(tappedCell, isNotNull);
    expect(tappedCell!.value, 7.5);
    expect(tappedCell!.day, 2);

    await tester.tap(find.text('23.5'), warnIfMissed: false); // A row total
    await tester.pump();
    expect(tappedTotal, isNotNull);
    expect(tappedTotal!.kind, TimecardTotalKind.row);

    // Header cells are tappable too (the "3" day header is unique here).
    await tester.tap(find.text('3'), warnIfMissed: false);
    await tester.pump();
    expect(tappedHeader, isNotNull);
    expect(tappedHeader!.day, 3);
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

  testWidgets('rebuilding with different keyed rows and column count survives '
      '(flutter/flutter#91068)', (tester) async {
    // June (30 days): two dataset-specific keyed rows plus one keyed row
    // ('shared') that persists across datasets at a different index.
    await tester.pumpWidget(
      wrap(
        TimecardTable(
          year: 2026,
          month: Month.june,
          timecardRows: [
            TimecardRow(key: 'a', label: 'Project A', values: {1: 8}),
            TimecardRow(key: 'b', label: 'Project B', values: {2: 4}),
            TimecardRow(key: 'shared', label: 'Shared', markers: {1: const TimecardMarker.text('N')}),
          ],
          summaryRows: [
            TimecardSummaryRow.values(key: 's1', label: 'Overtime', values: {1: 1}),
            TimecardSummaryRow.values(key: 's2', label: 'Ferie', values: {3: 8}),
          ],
        ),
      ),
    );
    expect(find.text('Project A'), findsOneWidget);

    // July (31 days): fewer rows, the persistent keyed row shifted up, fewer
    // summary rows. Without the structural remount this in-place update trips
    // the Table element assert "!renderObject.attached".
    await tester.pumpWidget(
      wrap(
        TimecardTable(
          year: 2026,
          month: Month.july,
          timecardRows: [
            TimecardRow(key: 'c', label: 'Project C', values: {5: 6}),
            TimecardRow(key: 'shared', label: 'Shared', markers: {2: const TimecardMarker.text('S')}),
          ],
          summaryRows: [
            TimecardSummaryRow.values(key: 's1', label: 'Overtime', values: {5: 1}),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Project C'), findsOneWidget);
    expect(find.text('Project A'), findsNothing);
  });

  testWidgets('non-scrollable day cells fit narrow flexed columns instead of '
      'overflowing', (tester) async {
    const totalWidth = 320.0;
    await tester.pumpWidget(
      wrap(
        Center(
          child: SizedBox(
            width: totalWidth,
            child: TimecardTable(
              year: 2026,
              month: Month.march, // 31 days
              timecardRows: rows,
              totals: TimecardTotalsConfig.all,
              scrollable: false,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    // With 31 flexed day columns plus label and total columns, each day column
    // is well under the natural width of a two-digit header. The painted text
    // must be scaled down to stay inside its column.
    final maxDayColumnWidth = totalWidth / 31;
    final headerRect = tester.getRect(find.text('28'));
    expect(headerRect.width, lessThanOrEqualTo(maxDayColumnWidth));

    // Data-cell values scale the same way.
    final cellRect = tester.getRect(find.text('7.5'));
    expect(cellRect.width, lessThanOrEqualTo(maxDayColumnWidth));
  });
}
