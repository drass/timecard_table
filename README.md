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
- 🔁 **Header label modes**: day number, short/long weekday, day + weekday,
  full date, or a custom resolver — with arbitrary **rotation** (e.g. `-45°`
  inclined or `-90°` vertical) for compact matrix-style headers.
- 🎨 Deep theming via `TimecardTableStyle` (colors, text styles, paddings,
  column widths, borders, weekend/today highlights, zebra striping).
- 🧩 Per-region **builders** (`headerBuilder`, `cellBuilder`, `labelBuilder`,
  `totalBuilder`, `cornerBuilder`) for total control.
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

### Fully themed style

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
  ),
  timecardRows: rows,
)
```

## Customization map

| Need | Use |
| --- | --- |
| What headers show + rotation | `TimecardHeaderConfig` (or `headerBuilder`) |
| Which totals + how they're computed | `TimecardTotalsConfig` |
| Colors / text / sizes / borders | `TimecardTableStyle` |
| Replace a cell / label / total / corner | the matching `*Builder` |
| Number formatting | `valueFormatter` |
| Weekend / today highlighting | `weekendDays`, `today` |
| Show a subset of days | `startDay`, `endDay` |
| Handle taps | `onCellTap` |

See `lib/timecard_table_previews.dart` for runnable Widget Previews of each
configuration.

## Additional information

Contributions and issues are welcome. The package has no third-party runtime
dependencies; locale-specific weekday/date strings can be supplied through
`TimecardHeaderConfig`.
