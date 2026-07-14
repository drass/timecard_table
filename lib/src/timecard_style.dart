import 'package:flutter/material.dart';

/// Visual styling for a [TimecardTable].
///
/// Every property is optional; anything left `null` falls back to a sensible
/// value derived from the ambient [Theme] at build time. Use [copyWith] to
/// tweak a base style, or [TimecardTableStyle.fromTheme] for a theme-aligned
/// starting point.
@immutable
class TimecardTableStyle {
  const TimecardTableStyle({
    this.headerTextStyle,
    this.weekdayTextStyle,
    this.cellTextStyle,
    this.labelTextStyle,
    this.totalTextStyle,
    this.cornerTextStyle,
    this.emptyTextStyle,
    this.todayHeaderTextStyle,
    this.headerBackground,
    this.labelBackground,
    this.totalBackground,
    this.weekendBackground,
    this.todayBackground,
    this.cellBackground,
    this.evenRowBackground,
    this.oddRowBackground,
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.cellAlignment = Alignment.center,
    this.labelAlignment = Alignment.centerLeft,
    this.headerAlignment = Alignment.center,
    this.dayColumnWidth = 48,
    this.labelColumnWidth,
    this.totalColumnWidth,
    this.headerHeight,
    this.border,
    this.borderRadius,
    this.emptyPlaceholder = '·',
    this.cellDecoration,
    this.headerDecoration,
    this.totalDecoration,
    this.labelDecoration,
    this.cardMode = false,
    this.cardSpacing = 4,
    this.cardRadius,
    this.cardShadow,
    this.hoverColor,
    this.splashColor,
  });

  /// Builds a style whose defaults are aligned with [theme]/[ColorScheme].
  ///
  /// The defaults follow dense-data-table practice: a quiet grid (full-strength
  /// horizontal dividers, hairline vertical ones), tabular figures so digits
  /// align across rows, a muted header, an emphasized totals region and a
  /// dimmed placeholder for empty cells.
  factory TimecardTableStyle.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    const tabularFigures = [FontFeature.tabularFigures()];
    return TimecardTableStyle(
      headerTextStyle: text.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
        fontFeatures: tabularFigures,
      ),
      weekdayTextStyle: text.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
        letterSpacing: 0.4,
      ),
      cellTextStyle: text.bodyMedium?.copyWith(fontFeatures: tabularFigures),
      labelTextStyle: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      totalTextStyle: text.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontFeatures: tabularFigures,
      ),
      cornerTextStyle: text.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
      emptyTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
      ),
      todayHeaderTextStyle: text.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.primary,
        fontFeatures: tabularFigures,
      ),
      headerBackground: scheme.surfaceContainerLow,
      labelBackground: scheme.surfaceContainerLow,
      totalBackground: scheme.surfaceContainerHigh,
      weekendBackground: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      todayBackground: scheme.primary.withValues(alpha: 0.1),
      border: TableBorder(
        top: BorderSide(color: scheme.outlineVariant),
        right: BorderSide(color: scheme.outlineVariant),
        bottom: BorderSide(color: scheme.outlineVariant),
        left: BorderSide(color: scheme.outlineVariant),
        horizontalInside:
            BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        verticalInside: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      hoverColor: scheme.primary.withValues(alpha: 0.06),
      splashColor: scheme.primary.withValues(alpha: 0.12),
    );
  }

  /// Text style for the day header labels.
  final TextStyle? headerTextStyle;

  /// Text style for the secondary weekday line in [TimecardHeaderLabel.dayAndWeekday].
  final TextStyle? weekdayTextStyle;

  /// Text style for ordinary data cells.
  final TextStyle? cellTextStyle;

  /// Text style for the leading row labels.
  final TextStyle? labelTextStyle;

  /// Text style for total cells.
  final TextStyle? totalTextStyle;

  /// Text style for the top-left corner cell.
  final TextStyle? cornerTextStyle;

  /// Text style for the [emptyPlaceholder] shown in cells without a value.
  /// Falls back to [cellTextStyle] when `null`; the theme default dims it so
  /// recorded values stand out from empty days.
  final TextStyle? emptyTextStyle;

  /// Text style for today's day-header label, replacing [headerTextStyle]
  /// for that column. Falls back to [headerTextStyle] when `null`.
  final TextStyle? todayHeaderTextStyle;

  /// Background for the header row.
  final Color? headerBackground;

  /// Background for the leading label column.
  final Color? labelBackground;

  /// Background for total cells.
  final Color? totalBackground;

  /// Background tint applied to weekend columns (header + cells).
  final Color? weekendBackground;

  /// Background tint applied to today's column (header + cells).
  final Color? todayBackground;

  /// Background for ordinary data cells (lowest priority).
  final Color? cellBackground;

  /// Optional zebra-striping background for even data rows.
  final Color? evenRowBackground;

  /// Optional zebra-striping background for odd data rows.
  final Color? oddRowBackground;

  /// Padding inside data cells.
  final EdgeInsetsGeometry cellPadding;

  /// Padding inside header cells.
  final EdgeInsetsGeometry headerPadding;

  /// Padding inside leading label cells.
  final EdgeInsetsGeometry labelPadding;

  /// Alignment of content within data cells.
  final AlignmentGeometry cellAlignment;

  /// Alignment of content within leading label cells.
  final AlignmentGeometry labelAlignment;

  /// Alignment of content within header cells.
  final AlignmentGeometry headerAlignment;

  /// Fixed width for each day column.
  final double dayColumnWidth;

  /// Fixed width for the leading label column. When `null` the column sizes to
  /// its content (intrinsic width).
  final double? labelColumnWidth;

  /// Fixed width for the trailing total column. Defaults to [dayColumnWidth]
  /// (scaled up a little) when `null`.
  final double? totalColumnWidth;

  /// Explicit height for the header row. When `null` it is intrinsic for
  /// non-rotated headers and defaults to a taller value when the header is
  /// rotated (see [TimecardHeaderConfig.rotationDegrees]).
  final double? headerHeight;

  /// Table border. When `null`, no border is drawn.
  final TableBorder? border;

  /// Rounds the outer corners of the table border.
  final BorderRadius? borderRadius;

  /// Text used for cells that have no recorded value.
  final String emptyPlaceholder;

  /// Decoration applied to data cells (border, radius, gradient, shadow). The
  /// resolved background tint is used as the decoration's color, so weekend /
  /// today / stripe highlighting still takes precedence over a flat fill.
  final BoxDecoration? cellDecoration;

  /// Decoration applied to header cells. See [cellDecoration].
  final BoxDecoration? headerDecoration;

  /// Decoration applied to total cells (column / row / grand). See [cellDecoration].
  final BoxDecoration? totalDecoration;

  /// Decoration applied to leading label cells. See [cellDecoration].
  final BoxDecoration? labelDecoration;

  /// When `true`, every cell renders as a separated, rounded "card": the shared
  /// table grid border is dropped, each cell is inset by [cardSpacing] and gets
  /// rounded corners ([cardRadius]) plus an optional [cardShadow].
  final bool cardMode;

  /// Gap between cards in [cardMode]. Half of this is applied as the margin on
  /// each side of every cell, so adjacent cells are separated by the full value.
  final double cardSpacing;

  /// Corner radius for cards in [cardMode]. Defaults to `8` when `null`.
  final double? cardRadius;

  /// Drop shadow for cards in [cardMode]. When `null`, cards are flat.
  final List<BoxShadow>? cardShadow;

  /// Hover highlight color for tappable cells (when a tap callback is set).
  final Color? hoverColor;

  /// Tap ripple color for tappable cells (when a tap callback is set).
  final Color? splashColor;

  /// Returns a copy of this style with the given fields replaced.
  TimecardTableStyle copyWith({
    TextStyle? headerTextStyle,
    TextStyle? weekdayTextStyle,
    TextStyle? cellTextStyle,
    TextStyle? labelTextStyle,
    TextStyle? totalTextStyle,
    TextStyle? cornerTextStyle,
    TextStyle? emptyTextStyle,
    TextStyle? todayHeaderTextStyle,
    Color? headerBackground,
    Color? labelBackground,
    Color? totalBackground,
    Color? weekendBackground,
    Color? todayBackground,
    Color? cellBackground,
    Color? evenRowBackground,
    Color? oddRowBackground,
    EdgeInsetsGeometry? cellPadding,
    EdgeInsetsGeometry? headerPadding,
    EdgeInsetsGeometry? labelPadding,
    AlignmentGeometry? cellAlignment,
    AlignmentGeometry? labelAlignment,
    AlignmentGeometry? headerAlignment,
    double? dayColumnWidth,
    double? labelColumnWidth,
    double? totalColumnWidth,
    double? headerHeight,
    TableBorder? border,
    BorderRadius? borderRadius,
    String? emptyPlaceholder,
    BoxDecoration? cellDecoration,
    BoxDecoration? headerDecoration,
    BoxDecoration? totalDecoration,
    BoxDecoration? labelDecoration,
    bool? cardMode,
    double? cardSpacing,
    double? cardRadius,
    List<BoxShadow>? cardShadow,
    Color? hoverColor,
    Color? splashColor,
  }) {
    return TimecardTableStyle(
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      weekdayTextStyle: weekdayTextStyle ?? this.weekdayTextStyle,
      cellTextStyle: cellTextStyle ?? this.cellTextStyle,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      totalTextStyle: totalTextStyle ?? this.totalTextStyle,
      cornerTextStyle: cornerTextStyle ?? this.cornerTextStyle,
      emptyTextStyle: emptyTextStyle ?? this.emptyTextStyle,
      todayHeaderTextStyle: todayHeaderTextStyle ?? this.todayHeaderTextStyle,
      headerBackground: headerBackground ?? this.headerBackground,
      labelBackground: labelBackground ?? this.labelBackground,
      totalBackground: totalBackground ?? this.totalBackground,
      weekendBackground: weekendBackground ?? this.weekendBackground,
      todayBackground: todayBackground ?? this.todayBackground,
      cellBackground: cellBackground ?? this.cellBackground,
      evenRowBackground: evenRowBackground ?? this.evenRowBackground,
      oddRowBackground: oddRowBackground ?? this.oddRowBackground,
      cellPadding: cellPadding ?? this.cellPadding,
      headerPadding: headerPadding ?? this.headerPadding,
      labelPadding: labelPadding ?? this.labelPadding,
      cellAlignment: cellAlignment ?? this.cellAlignment,
      labelAlignment: labelAlignment ?? this.labelAlignment,
      headerAlignment: headerAlignment ?? this.headerAlignment,
      dayColumnWidth: dayColumnWidth ?? this.dayColumnWidth,
      labelColumnWidth: labelColumnWidth ?? this.labelColumnWidth,
      totalColumnWidth: totalColumnWidth ?? this.totalColumnWidth,
      headerHeight: headerHeight ?? this.headerHeight,
      border: border ?? this.border,
      borderRadius: borderRadius ?? this.borderRadius,
      emptyPlaceholder: emptyPlaceholder ?? this.emptyPlaceholder,
      cellDecoration: cellDecoration ?? this.cellDecoration,
      headerDecoration: headerDecoration ?? this.headerDecoration,
      totalDecoration: totalDecoration ?? this.totalDecoration,
      labelDecoration: labelDecoration ?? this.labelDecoration,
      cardMode: cardMode ?? this.cardMode,
      cardSpacing: cardSpacing ?? this.cardSpacing,
      cardRadius: cardRadius ?? this.cardRadius,
      cardShadow: cardShadow ?? this.cardShadow,
      hoverColor: hoverColor ?? this.hoverColor,
      splashColor: splashColor ?? this.splashColor,
    );
  }

  /// Merges this style on top of [base], preferring this style's non-null
  /// values. Useful to layer a theme-derived base with user overrides.
  TimecardTableStyle mergeOnto(TimecardTableStyle base) {
    return base.copyWith(
      headerTextStyle: headerTextStyle,
      weekdayTextStyle: weekdayTextStyle,
      cellTextStyle: cellTextStyle,
      labelTextStyle: labelTextStyle,
      totalTextStyle: totalTextStyle,
      cornerTextStyle: cornerTextStyle,
      emptyTextStyle: emptyTextStyle,
      todayHeaderTextStyle: todayHeaderTextStyle,
      headerBackground: headerBackground,
      labelBackground: labelBackground,
      totalBackground: totalBackground,
      weekendBackground: weekendBackground,
      todayBackground: todayBackground,
      cellBackground: cellBackground,
      evenRowBackground: evenRowBackground,
      oddRowBackground: oddRowBackground,
      cellPadding: cellPadding,
      headerPadding: headerPadding,
      labelPadding: labelPadding,
      cellAlignment: cellAlignment,
      labelAlignment: labelAlignment,
      headerAlignment: headerAlignment,
      dayColumnWidth: dayColumnWidth,
      labelColumnWidth: labelColumnWidth,
      totalColumnWidth: totalColumnWidth,
      headerHeight: headerHeight,
      border: border,
      borderRadius: borderRadius,
      emptyPlaceholder: emptyPlaceholder,
      cellDecoration: cellDecoration,
      headerDecoration: headerDecoration,
      totalDecoration: totalDecoration,
      labelDecoration: labelDecoration,
      cardMode: cardMode,
      cardSpacing: cardSpacing,
      cardRadius: cardRadius,
      cardShadow: cardShadow,
      hoverColor: hoverColor,
      splashColor: splashColor,
    );
  }
}
