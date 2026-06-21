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
