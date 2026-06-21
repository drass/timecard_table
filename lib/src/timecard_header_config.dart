import 'package:flutter/widgets.dart';

import 'timecard_models.dart';
import 'utils.dart';

/// Controls how the day-header row is rendered.
///
/// This drives the built-in header renderer. For total control supply a
/// [TimecardTable.headerBuilder] instead — this config is then ignored except
/// for [rotationDegrees] and [height], which still wrap your builder so
/// rotated custom headers reserve the right amount of vertical space.
@immutable
class TimecardHeaderConfig {
  const TimecardHeaderConfig({
    this.label = TimecardHeaderLabel.dayNumber,
    this.rotationDegrees = 0,
    this.height,
    this.shortWeekdays,
    this.longWeekdays,
    this.dateFormatter,
    this.labelResolver,
    this.maxLines,
    this.softWrap = false,
    this.overflow = TextOverflow.visible,
  }) : assert(
         label != TimecardHeaderLabel.custom || labelResolver != null,
         'TimecardHeaderLabel.custom requires a labelResolver.',
       );

  /// A common preset: day numbers, written upright. `1 2 3 ...`.
  static const TimecardHeaderConfig dayNumbers = TimecardHeaderConfig();

  /// Weekday names rotated 45° — the classic "inclined header" matrix look.
  static const TimecardHeaderConfig inclinedWeekdays = TimecardHeaderConfig(
    label: TimecardHeaderLabel.weekdayShort,
    rotationDegrees: -45,
    height: 64,
  );

  /// Full dates rotated to vertical so long labels fit narrow columns.
  static const TimecardHeaderConfig verticalDates = TimecardHeaderConfig(
    label: TimecardHeaderLabel.fullDate,
    rotationDegrees: -90,
    height: 96,
  );

  /// Day number with its short weekday name stacked underneath.
  static const TimecardHeaderConfig dayAndWeekday = TimecardHeaderConfig(
    label: TimecardHeaderLabel.dayAndWeekday,
    height: 52,
  );

  /// Which built-in label to display.
  final TimecardHeaderLabel label;

  /// Rotation applied to header content, in degrees. Negative values incline
  /// the text up to the right (the common spreadsheet look); `-90` is vertical.
  final double rotationDegrees;

  /// Explicit header row height. When `null`, defaults to intrinsic for
  /// upright headers and a rotation-aware fallback when [rotationDegrees] != 0.
  final double? height;

  /// Custom short weekday names indexed by `DateTime.weekday - 1`
  /// (Monday-first). Defaults to English abbreviations.
  final List<String>? shortWeekdays;

  /// Custom long weekday names indexed by `DateTime.weekday - 1`.
  /// Defaults to English names.
  final List<String>? longWeekdays;

  /// Formats the date for [TimecardHeaderLabel.fullDate]. Defaults to
  /// `dd/MM/yyyy`.
  final String Function(DateTime date)? dateFormatter;

  /// Resolver used when [label] is [TimecardHeaderLabel.custom].
  final TimecardHeaderLabelResolver? labelResolver;

  /// Optional max lines for the header text.
  final int? maxLines;

  /// Whether header text should wrap. Defaults to `false` (single line).
  final bool softWrap;

  /// Overflow behaviour for header text.
  final TextOverflow overflow;

  /// Resolves the display string for [header] using the active [label] mode.
  String resolveLabel(TimecardHeaderContext header) {
    final short = shortWeekdays ?? TimecardUtils.defaultShortWeekdays;
    final long = longWeekdays ?? TimecardUtils.defaultLongWeekdays;
    final weekdayIndex = header.date.weekday - 1;
    switch (label) {
      case TimecardHeaderLabel.dayNumber:
        return header.day.toString();
      case TimecardHeaderLabel.weekdayShort:
        return short[weekdayIndex];
      case TimecardHeaderLabel.weekdayLong:
        return long[weekdayIndex];
      case TimecardHeaderLabel.dayAndWeekday:
        return '${header.day}\n${short[weekdayIndex]}';
      case TimecardHeaderLabel.fullDate:
        final fmt = dateFormatter ?? _defaultDateFormatter;
        return fmt(header.date);
      case TimecardHeaderLabel.custom:
        return labelResolver!(header);
    }
  }

  static String _defaultDateFormatter(DateTime date) =>
      '${TimecardUtils.pad(date.day)}/${TimecardUtils.pad(date.month)}/${date.year}';

  /// The effective header height, accounting for rotation defaults.
  double? resolveHeight() {
    if (height != null) return height;
    if (rotationDegrees == 0) return null;
    final magnitude = rotationDegrees.abs();
    if (magnitude >= 80) return 96;
    if (magnitude >= 30) return 64;
    return 48;
  }

  TimecardHeaderConfig copyWith({
    TimecardHeaderLabel? label,
    double? rotationDegrees,
    double? height,
    List<String>? shortWeekdays,
    List<String>? longWeekdays,
    String Function(DateTime date)? dateFormatter,
    TimecardHeaderLabelResolver? labelResolver,
    int? maxLines,
    bool? softWrap,
    TextOverflow? overflow,
  }) {
    return TimecardHeaderConfig(
      label: label ?? this.label,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      height: height ?? this.height,
      shortWeekdays: shortWeekdays ?? this.shortWeekdays,
      longWeekdays: longWeekdays ?? this.longWeekdays,
      dateFormatter: dateFormatter ?? this.dateFormatter,
      labelResolver: labelResolver ?? this.labelResolver,
      maxLines: maxLines ?? this.maxLines,
      softWrap: softWrap ?? this.softWrap,
      overflow: overflow ?? this.overflow,
    );
  }
}
