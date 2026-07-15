## 0.0.4

* Fix day/total cells overflowing their columns when `scrollable: false` on
  small screens: cell content (padding included) now scales down via a
  `FittedBox` to fit the flexed column width. Rotated headers keep their
  intentional overflow; row labels keep wrapping.
* Add `emptyTextStyle` and `todayHeaderTextStyle` to `TimecardTableStyle`, with
  theme-derived defaults (dimmed placeholder, primary-colored today header),
  and tune the default cell/label paddings.
* Fix a framework assert (flutter/flutter#91068) when rebuilding with keyed
  rows added/removed/reordered or a different column count: structural changes
  now remount the grid instead of updating it in place.

## 0.0.3

* Add **date-keyed values/markers**: `TimecardRow.dateValues` / `dateMarkers`
  (and `TimecardSummaryRow.values`' `dateValues`) let you key entries by full
  `DateTime` instead of a 1-based day index. The two styles can be mixed; a
  matching date entry takes precedence, and dates outside the displayed month
  are ignored.
* Add **clickable headers and totals**: new `onHeaderTap` and `onTotalTap`
  callbacks alongside `onCellTap`. Tappable cells now show a hover highlight,
  ripple and pointer cursor via an overlaid `InkWell`; `TimecardTableStyle`
  gains `hoverColor` / `splashColor`.

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
