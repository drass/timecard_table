# timecard_table

A fully customizable, month-based summarization table for Flutter.

It lays out **one column per day of a month** and **one row per tracked entity**
(jobs, projects, employees, tasks…), then **summarizes** the recorded values
into per-day, per-row and/or grand totals. Every region can be restyled or
replaced with your own widgets, and the day headers can be rendered as numbers,
weekday names, or full dates — upright, **inclined**, or vertical.

## Features

- 📅 Month-aware grid (leap years handled) with optional day-range subsets.
- ➕ Built-in **summarization**: per-day totals row, per-row totals column,
  grand total — with a pluggable aggregator (sum / average / max / custom).
- 🧮 **Derived summary rows** (`summaryRows`): add extra rows beneath the data
  (e.g. overtime) and totals that build on other rows/totals — even on each
  other (overtime → worked + overtime → grand).
- 🎯 **Interval bands** (`spanRows`): highlight day ranges (`1 → 12 January`)
  as continuous colored bars with a message shown once over the whole
  interval — day- or date-bounded (clipped to the displayed month), tappable,
  above or below the data.
- 🏷️ **Event markers** (`TimecardRow.markers`): place an icon, symbol or widget
  in a cell (illness, holiday…) that is illustrative only and never counted.
- 🔁 **Header label modes**: day number, short/long weekday, day + weekday,
  full date, or a custom resolver — with arbitrary **rotation** (e.g. `-45°`
  inclined or `-90°` vertical) for compact matrix-style headers.
- 🎨 Deep theming via `TimecardTableStyle` (colors, text styles, paddings,
  column widths, borders, weekend/today highlights, zebra striping) — plus
  per-region `BoxDecoration`s and a spaced, rounded **card mode**.
- 🧩 Per-region **builders** (`headerBuilder`, `cellBuilder`, `labelBuilder`,
  `totalBuilder`, `cornerBuilder`, `spanBuilder`) for total control.
- 👆 Cell tap callbacks, horizontal scrolling, theme-aligned defaults.

## Getting started

Add the package to your `pubspec.yaml`, then:

```dart
import 'package:timecard_table/timecard_table.dart';
```

## Usage

```dart
TimecardTable(
  title: const TimecardTitle(text: 'March 2026', subtitle: 'Hours logged'),
  year: 2026,
  month: Month.march,
  timecardRows: [
    TimecardRow(key: 'a', label: 'Project A', values: {1: 8, 2: 7.5, 3: 8}),
    TimecardRow(key: 'b', label: 'Project B', values: {1: 4, 2: 5}),
  ],
)
```

### Inclined weekday matrix with all totals

```dart
TimecardTable(
  year: 2026,
  month: Month.march,
  headerConfig: TimecardHeaderConfig.inclinedWeekdays, // -45° weekday names
  totals: TimecardTotalsConfig.all,                    // row + grand totals
  timecardRows: rows,
)
```

### Custom summarization (average) + custom cells

```dart
TimecardTable(
  year: 2026,
  month: Month.march,
  totals: const TimecardTotalsConfig(
    showRowTotals: true,
    aggregator: TimecardTotalsConfig.average,
    columnTotalLabel: 'Avg',
  ),
  cellBuilder: (context, cell) => Text(
    cell.hasValue ? cell.value!.toStringAsFixed(1) : '—',
    style: TextStyle(
      color: cell.isWeekend ? Colors.grey : null,
      fontWeight: (cell.value ?? 0) >= 8 ? FontWeight.bold : FontWeight.normal,
    ),
  ),
  timecardRows: rows,
)
```

### Derived summary rows (overtime + combined)

```dart
TimecardTable(
  year: 2026,
  month: Month.march,
  totals: TimecardTotalsConfig.all,
  timecardRows: rows,
  summaryRows: [
    // A manually entered extra row.
    TimecardSummaryRow.values(key: 'ot', label: 'Overtime', values: {1: 1, 5: 2}),
    // Derived from the data total + an earlier summary row.
    TimecardSummaryRow.computed(
      key: 'combined',
      label: 'Worked + OT',
      compute: (day, scope) => scope.dataTotal(day) + (scope.value('ot', day) ?? 0),
    ),
  ],
)
```

`TimecardSummaryScope` exposes `dataTotal(day)`, `value(key, day)` and
`rowTotal(key)`; rows evaluate top-to-bottom, so later rows can reference earlier
ones.

### Event markers (illustrative, never counted)

```dart
TimecardRow(
  key: 'a',
  label: 'Project A',
  values: {1: 8, 2: 7.5},
  markers: {
    3: const TimecardMarker.icon(Icons.sick, tooltip: 'Illness'),
    4: const TimecardMarker.text('H', tooltip: 'Holiday'),
  },
)
```

### Highlighted day intervals (span rows)

Add annotation lanes that mark ranges of days — a training period, a stay on
site, leave… Each `TimecardSpan` draws one continuous bar from its first to its
last day, with its message rendered **once, centered over the whole interval**,
so overlapping information stays readable. Spans hold no numbers and never
affect any total.

```dart
TimecardTable(
  year: 2026,
  month: Month.january,
  timecardRows: rows,
  spanRows: [
    TimecardSpanRow(
      key: 'periods',
      label: 'Periods',
      placement: TimecardSpanPlacement.top, // right below the day headers
      spans: [
        TimecardSpan(
          from: 1, to: 12,                  // 1-based days of the month
          label: 'Onboarding & training',
          icon: Icons.school,
          background: Colors.blue.shade100,
        ),
        TimecardSpan(from: 15, to: 20, label: 'On site', background: Colors.orange.shade100),
      ],
    ),
    // Bounds can also be full dates; intervals crossing the month are clipped
    // to the visible range and their clipped edge is drawn square.
    TimecardSpanRow(
      key: 'leave',
      label: 'Leave',
      spans: [
        TimecardSpan.dates(
          from: DateTime(2025, 12, 20),
          to: DateTime(2026, 1, 5),
          label: 'Winter break',
        ),
      ],
    ),
  ],
  onSpanTap: (span) => print('${span.span.label} on ${span.date}'),
)
```

Within one row, the first span covering a day wins — put intervals that overlap
in time on **separate span rows** so both stay visible. Band colors, height,
pill inset and radius come from `TimecardSpan`/`TimecardSpanRow` or, as
defaults, from `TimecardTableStyle` (`spanBackground`, `spanTextStyle`,
`spanRowBackground`, `spanRowHeight`, `spanInset`, `spanRadius`). For perfectly
seamless bars, drop the grid's vertical hairlines
(`border: TableBorder(... verticalInside: BorderSide.none)`), which are painted
above the cells.

### Date-keyed values

Values and markers are normally keyed by 1-based day of month, but you can key
them by full `DateTime` instead (or mix both — a matching date entry wins). Only
dates that fall inside the displayed month are shown.

```dart
TimecardRow(
  key: 'a',
  label: 'Project A',
  values: {1: 8},                        // by day index
  dateValues: {DateTime(2026, 3, 2): 7.5}, // by date
)
```

`TimecardSummaryRow.values` accepts `dateValues` the same way.

### Clickable cells

Set any of `onCellTap`, `onHeaderTap` or `onTotalTap` to make those cells
interactive — each gets a hover highlight, tap ripple and pointer cursor
(`hoverColor` / `splashColor` on `TimecardTableStyle` tune the colors).

```dart
TimecardTable(
  year: 2026,
  month: Month.march,
  timecardRows: rows,
  totals: TimecardTotalsConfig.all,
  onCellTap: (cell) => print('${cell.date}: ${cell.value}'),
  onHeaderTap: (header) => print(header.date),
  onTotalTap: (total) => print('${total.kind}: ${total.total}'),
)
```

### Fully themed style + card cells

```dart
TimecardTable(
  year: 2026,
  month: Month.march,
  style: TimecardTableStyle(
    dayColumnWidth: 40,
    weekendBackground: Colors.orange.withValues(alpha: 0.1),
    evenRowBackground: Colors.blueGrey.withValues(alpha: 0.05),
    border: TableBorder.all(color: Colors.black12),
    borderRadius: BorderRadius.circular(8),
    // Or render each cell as a separated, rounded card:
    cardMode: true,
    cardSpacing: 6,
    cardRadius: 10,
    // Per-region decorations are also available:
    cellDecoration: BoxDecoration(border: Border.all(color: Colors.black12)),
  ),
  timecardRows: rows,
)
```

## Customization map

| Need | Use |
| --- | --- |
| What headers show + rotation | `TimecardHeaderConfig` (or `headerBuilder`) |
| Which totals + how they're computed | `TimecardTotalsConfig` |
| Extra / derived total rows | `summaryRows` (`TimecardSummaryRow`) |
| Highlight a day interval with a message | `spanRows` (`TimecardSpanRow` / `TimecardSpan`) |
| Non-numeric event symbols / icons | `TimecardRow.markers` (`TimecardMarker`) |
| Colors / text / sizes / borders | `TimecardTableStyle` |
| Per-cell decorations / card layout | `TimecardTableStyle` (`cellDecoration`, `cardMode`) |
| Replace a cell / label / total / corner | the matching `*Builder` |
| Number formatting | `valueFormatter` |
| Weekend / today highlighting | `weekendDays`, `today` |
| Show a subset of days | `startDay`, `endDay` |
| Key values by date | `TimecardRow.dateValues` / `dateMarkers` |
| Handle taps (cell / header / total / band) | `onCellTap`, `onHeaderTap`, `onTotalTap`, `onSpanTap` |

See `lib/timecard_table_previews.dart` for runnable Widget Previews of each
configuration.

## Additional information

Contributions and issues are welcome. The package has no third-party runtime
dependencies; locale-specific weekday/date strings can be supplied through
`TimecardHeaderConfig`.
