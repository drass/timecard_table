/// A fully customizable, month-based summarization table for Flutter.
///
/// See [TimecardTable] for the main entry point. Customize via
/// [TimecardHeaderConfig] (header label mode + rotation),
/// [TimecardTotalsConfig] (summarization), [TimecardTableStyle] (visuals), or
/// the per-region builders on [TimecardTable].
library;

export 'src/timecard_header_config.dart';
export 'src/timecard_marker.dart';
export 'src/timecard_models.dart';
export 'src/timecard_row.dart';
export 'src/timecard_style.dart';
export 'src/timecard_summary_row.dart';
export 'src/timecard_table.dart';
export 'src/timecard_title.dart';
export 'src/timecard_totals_config.dart';
export 'src/utils.dart' show Month, MonthX, TimecardUtils;
