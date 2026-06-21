## 0.0.2

* Add **derived summary rows** (`TimecardTable.summaryRows` /
  `TimecardSummaryRow`): extra rows beneath the data plus totals that can build
  on the data total and other rows/totals via `TimecardSummaryScope`.
* Add **event markers** (`TimecardRow.markers` / `TimecardMarker`): icon, text
  or widget annotations that are illustrative only and excluded from all totals.
  Exposed on `TimecardCellContext` (`marker`, `hasMarker`).
* Add per-region `BoxDecoration`s (`cellDecoration`, `headerDecoration`,
  `totalDecoration`, `labelDecoration`) and a spaced, rounded **card mode**
  (`cardMode`, `cardSpacing`, `cardRadius`, `cardShadow`) to
  `TimecardTableStyle`.
* Fix the header row collapsing/clipping when the corner cell was empty (e.g.
  the day-numbers preset) — day-header cells now drive the row height.
* Fix rotated headers (e.g. vertical full dates) truncating long labels: content
  now measures at its natural width before rotating.

## 0.0.1

* Initial release.
* Month-based summarization table (`TimecardTable`) with one column per day and
  one row per `TimecardRow`.
* Built-in per-day, per-row and grand totals with a pluggable aggregator
  (`TimecardTotalsConfig`: sum / average / max / custom).
* Configurable day headers (`TimecardHeaderConfig`): day number, weekday
  short/long, day + weekday, full date, or custom — with arbitrary rotation
  (inclined / vertical) presets.
* Deep theming via `TimecardTableStyle` (colors, text styles, paddings, column
  widths, borders, weekend/today highlights, zebra striping).
* Per-region builders: `headerBuilder`, `cellBuilder`, `labelBuilder`,
  `totalBuilder`, `cornerBuilder`.
* Cell tap callbacks, horizontal scrolling, day-range subsets, theme-aligned
  defaults, no third-party runtime dependencies.
