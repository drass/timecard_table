/// Internal helpers used across the package.
///
/// Everything here is static and dependency-free so the package stays light
/// (no `intl` dependency). Locale specific strings can always be overridden
/// through [TimecardHeaderConfig].
library;

/// The twelve months of the year.
///
/// The enum index matches the zero-based position, so the calendar month
/// number is `Month.value.index + 1`.
enum Month {
  january,
  february,
  march,
  april,
  may,
  june,
  july,
  august,
  september,
  october,
  november,
  december,
}

extension MonthX on Month {
  /// The 1-based calendar number (january == 1, december == 12).
  int get number => index + 1;

  /// Builds a [Month] from a 1-based calendar number.
  static Month fromNumber(int number) => Month.values[number - 1];
}

/// Pure, dependency-free utilities for date math and value formatting.
class TimecardUtils {
  const TimecardUtils._();

  /// Default English short weekday names indexed by `DateTime.weekday - 1`
  /// (Monday == 0 ... Sunday == 6).
  static const List<String> defaultShortWeekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Default English long weekday names indexed by `DateTime.weekday - 1`.
  static const List<String> defaultLongWeekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Default English month names indexed by `month - 1`.
  static const List<String> defaultMonthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Number of days in [month] of [year], honouring leap years.
  static int daysInMonth(int year, int month) {
    final firstOfMonth = DateTime(year, month, 1);
    final firstOfNext = month < 12
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);
    return firstOfNext.difference(firstOfMonth).inDays;
  }

  /// Formats a numeric value, dropping a trailing `.0` and trimming any
  /// trailing zeros after rounding to [maxDecimals] decimal places.
  ///
  /// `8.0 -> "8"`, `7.5 -> "7.5"`, `7.25 -> "7.25"`.
  static String formatNumber(double value, {int maxDecimals = 2}) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    var text = value.toStringAsFixed(maxDecimals);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    return text;
  }

  /// Left-pads an integer with zeroes to [width] characters.
  static String pad(int value, [int width = 2]) =>
      value.toString().padLeft(width, '0');

  /// Whether two dates fall on the same calendar day.
  static bool isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Normalizes [date] to a time-stripped key (midnight, same calendar day) so
  /// date-keyed maps look up consistently regardless of the original time.
  static DateTime dateKey(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
