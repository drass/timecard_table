import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'timecard_header_config.dart';
import 'timecard_models.dart';
import 'timecard_row.dart';
import 'timecard_style.dart';
import 'timecard_summary_row.dart';
import 'timecard_title.dart';
import 'timecard_totals_config.dart';
import 'utils.dart';

/// A fully customizable, month-based summarization table.
///
/// At its core the widget lays out one column per day of a month and one row
/// per [TimecardRow], then summarises the recorded values into per-day,
/// per-row and/or grand totals.
///
/// Customization happens at three levels, from least to most effort:
///
/// 1. **Config objects** — [TimecardHeaderConfig] (label mode + rotation),
///    [TimecardTotalsConfig] (what to summarise and how) and
///    [TimecardTableStyle] (every color, text style, padding and size).
/// 2. **Value/formatting hooks** — [valueFormatter], [weekendDays], [today].
/// 3. **Builders** — [headerBuilder], [cellBuilder], [labelBuilder],
///    [totalBuilder] and [cornerBuilder] let you replace any region's widget
///    entirely while still receiving the resolved context (date, value,
///    weekend/today flags, totals, ...).
///
/// Example — an "inclined matrix" of weekday headers with row totals:
///
/// ```dart
/// TimecardTable(
///   year: 2026,
///   month: Month.march,
///   headerConfig: TimecardHeaderConfig.inclinedWeekdays,
///   totals: TimecardTotalsConfig.all,
///   timecardRows: [
///     TimecardRow(key: 'a', label: 'Project A', values: {1: 8, 2: 7.5}),
///     TimecardRow(key: 'b', label: 'Project B', values: {1: 4, 3: 6}),
///   ],
/// )
/// ```
class TimecardTable extends StatelessWidget {
  const TimecardTable({
    super.key,
    required this.timecardRows,
    required this.year,
    required this.month,
    this.summaryRows = const <TimecardSummaryRow>[],
    this.title,
    this.style,
    this.headerConfig = const TimecardHeaderConfig(),
    this.totals = const TimecardTotalsConfig(),
    this.headerBuilder,
    this.cellBuilder,
    this.labelBuilder,
    this.totalBuilder,
    this.cornerBuilder,
    this.valueFormatter,
    this.onCellTap,
    this.weekendDays = const {DateTime.saturday, DateTime.sunday},
    this.today,
    this.scrollable = true,
    this.scrollController,
    this.startDay,
    this.endDay,
  });

  /// The data rows to display and summarise.
  final List<TimecardRow> timecardRows;

  /// Extra rows rendered beneath the data and the auto totals row.
  ///
  /// Each [TimecardSummaryRow] holds either explicit per-day values or a
  /// computation derived from other rows. They are evaluated top-to-bottom, so a
  /// computed row can build on the rows above it (e.g. an `overtime` row, then a
  /// `worked + overtime` row, then a grand total of both).
  final List<TimecardSummaryRow> summaryRows;

  /// The calendar year of the displayed month.
  final int year;

  /// The displayed month.
  final Month month;

  /// Optional caption rendered above the table.
  final TimecardTitle? title;

  /// Styling overrides. Anything unset falls back to a theme-derived default.
  final TimecardTableStyle? style;

  /// Controls the day-header row (label mode, rotation, locale strings).
  final TimecardHeaderConfig headerConfig;

  /// Controls summarization (which totals, and the aggregation function).
  final TimecardTotalsConfig totals;

  /// Replaces the default day-header content. Wrapped with the configured
  /// rotation/height so rotated custom headers still reserve space.
  final TimecardHeaderBuilder? headerBuilder;

  /// Replaces the default data-cell content.
  final TimecardCellBuilder? cellBuilder;

  /// Replaces the default leading row-label content.
  final TimecardLabelBuilder? labelBuilder;

  /// Replaces the default totals-cell content (column / row / grand).
  final TimecardTotalBuilder? totalBuilder;

  /// Replaces the top-left corner cell content.
  final WidgetBuilder? cornerBuilder;

  /// Formats numeric values into cell/total strings. Defaults to a trimmed
  /// number format (`8`, `7.5`, `7.25`).
  final TimecardValueFormatter? valueFormatter;

  /// Called when a data cell is tapped.
  final TimecardCellTapCallback? onCellTap;

  /// Weekday numbers (`DateTime.monday`..`DateTime.sunday`) treated as
  /// weekend for highlighting. Defaults to Saturday and Sunday.
  final Set<int> weekendDays;

  /// The date considered "today" for highlighting. Defaults to `DateTime.now()`.
  final DateTime? today;

  /// Whether to wrap the table in a horizontal scroll view (recommended for a
  /// full month). When `false`, the table tries to fit the available width.
  final bool scrollable;

  /// Optional controller for the horizontal scroll view.
  final ScrollController? scrollController;

  /// First day (1-based) to display. Defaults to `1`. Lets you render a subset
  /// of the month (e.g. a single week / pay period).
  final int? startDay;

  /// Last day (1-based) to display. Defaults to the last day of the month.
  final int? endDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedStyle = style == null
        ? TimecardTableStyle.fromTheme(theme)
        : style!.mergeOnto(TimecardTableStyle.fromTheme(theme));
    final format = valueFormatter ?? TimecardUtils.formatNumber;
    final now = today ?? DateTime.now();

    final daysInMonth = TimecardUtils.daysInMonth(year, month.number);
    final first = (startDay ?? 1).clamp(1, daysInMonth);
    final last = (endDay ?? daysInMonth).clamp(first, daysInMonth);
    final days = <int>[for (var d = first; d <= last; d++) d];

    final showRowTotals = totals.showRowTotals;
    final showColumnTotals =
        totals.showColumnTotals || totals.showGrandTotal;

    final summaries = _evaluateSummaries(days);

    final table = Table(
      border: _resolveBorder(resolvedStyle),
      defaultVerticalAlignment: TableCellVerticalAlignment.fill,
      defaultColumnWidth: FixedColumnWidth(resolvedStyle.dayColumnWidth),
      columnWidths: _columnWidths(resolvedStyle, days.length, showRowTotals),
      children: [
        _buildHeaderRow(context, resolvedStyle, days, now, showRowTotals),
        for (var i = 0; i < timecardRows.length; i++)
          _buildDataRow(context, resolvedStyle, format, timecardRows[i], i, days, now, showRowTotals),
        if (showColumnTotals)
          _buildTotalsRow(context, resolvedStyle, format, days, now, showRowTotals),
        for (final summary in summaries)
          _buildSummaryRow(context, resolvedStyle, format, summary, days, showRowTotals),
      ],
    );

    Widget result = table;
    if (resolvedStyle.borderRadius != null && !resolvedStyle.cardMode) {
      result = ClipRRect(borderRadius: resolvedStyle.borderRadius!, child: result);
    }
    if (scrollable) {
      result = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: scrollController,
        child: result,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ?title,
        result,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Layout helpers
  // ---------------------------------------------------------------------------

  TableBorder? _resolveBorder(TimecardTableStyle style) {
    // Card mode draws each cell as a separate tile, so the shared grid border
    // is dropped entirely.
    if (style.cardMode) return null;
    final border = style.border;
    if (border == null) return null;
    if (style.borderRadius == null) return border;
    return TableBorder(
      top: border.top,
      right: border.right,
      bottom: border.bottom,
      left: border.left,
      horizontalInside: border.horizontalInside,
      verticalInside: border.verticalInside,
      borderRadius: style.borderRadius!,
    );
  }

  Map<int, TableColumnWidth> _columnWidths(
    TimecardTableStyle style,
    int dayCount,
    bool showRowTotals,
  ) {
    final widths = <int, TableColumnWidth>{
      0: style.labelColumnWidth != null
          ? FixedColumnWidth(style.labelColumnWidth!)
          : const IntrinsicColumnWidth(),
    };
    if (showRowTotals) {
      widths[dayCount + 1] = FixedColumnWidth(
        style.totalColumnWidth ?? style.dayColumnWidth * 1.4,
      );
    }
    return widths;
  }

  bool _isWeekend(DateTime date) => weekendDays.contains(date.weekday);

  // ---------------------------------------------------------------------------
  // Header row
  // ---------------------------------------------------------------------------

  TableRow _buildHeaderRow(
    BuildContext context,
    TimecardTableStyle style,
    List<int> days,
    DateTime now,
    bool showRowTotals,
  ) {
    final height = headerConfig.resolveHeight();
    return TableRow(
      children: [
        // Corner is a fill cell: the day-header cells below drive the row
        // height (they always have content), so an empty corner no longer
        // collapses the header. See _buildHeaderCell.
        _fillCell(
          style: style,
          background: style.labelBackground,
          decoration: style.labelDecoration,
          padding: style.headerPadding,
          alignment: style.labelAlignment,
          height: height,
          child: cornerBuilder?.call(context) ?? const SizedBox.shrink(),
        ),
        for (final day in days)
          _buildHeaderCell(context, style, day, now, height),
        if (showRowTotals)
          _fillCell(
            style: style,
            background: style.totalBackground,
            decoration: style.totalDecoration,
            padding: style.headerPadding,
            alignment: style.headerAlignment,
            child: _text(totals.rowTotalHeader, style.cornerTextStyle, headerConfig),
          ),
      ],
    );
  }

  Widget _buildHeaderCell(
    BuildContext context,
    TimecardTableStyle style,
    int day,
    DateTime now,
    double? height,
  ) {
    final date = DateTime(year, month.number, day);
    final isWeekend = _isWeekend(date);
    final isToday = TimecardUtils.isSameDate(date, now);
    final ctx = TimecardHeaderContext(
      day: day,
      date: date,
      isWeekend: isWeekend,
      isToday: isToday,
    );

    Widget content;
    if (headerBuilder != null) {
      content = headerBuilder!(context, ctx);
    } else {
      content = _defaultHeaderContent(style, ctx);
    }
    if (headerConfig.rotationDegrees != 0) {
      // Let the content lay out at its natural (single-line) size *before*
      // rotating: Transform.rotate doesn't affect layout, so without this the
      // text would first wrap/clip to the narrow column width and only then
      // rotate — truncating long labels like a full date's year.
      content = OverflowBox(
        minWidth: 0,
        maxWidth: double.infinity,
        minHeight: 0,
        maxHeight: double.infinity,
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: headerConfig.rotationDegrees * math.pi / 180,
          child: content,
        ),
      );
    }

    // Day-header cells are the row-height drivers (middle alignment): they
    // always have content, unlike the corner, so the header keeps its height.
    return _driverCell(
      style: style,
      background: _dayBackground(style, isWeekend, isToday, style.headerBackground),
      decoration: style.headerDecoration,
      padding: style.headerPadding,
      alignment: style.headerAlignment,
      height: height,
      child: content,
    );
  }

  Widget _defaultHeaderContent(TimecardTableStyle style, TimecardHeaderContext ctx) {
    if (headerConfig.label == TimecardHeaderLabel.dayAndWeekday) {
      final short =
          (headerConfig.shortWeekdays ?? TimecardUtils.defaultShortWeekdays)[ctx.date.weekday - 1];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${ctx.day}', style: style.headerTextStyle),
          Text(short, style: style.weekdayTextStyle),
        ],
      );
    }
    return _text(headerConfig.resolveLabel(ctx), style.headerTextStyle, headerConfig);
  }

  // ---------------------------------------------------------------------------
  // Data rows
  // ---------------------------------------------------------------------------

  TableRow _buildDataRow(
    BuildContext context,
    TimecardTableStyle style,
    TimecardValueFormatter format,
    TimecardRow row,
    int rowIndex,
    List<int> days,
    DateTime now,
    bool showRowTotals,
  ) {
    final stripe = rowIndex.isEven ? style.evenRowBackground : style.oddRowBackground;
    return TableRow(
      key: ValueKey<String>(row.key),
      children: [
        _driverCell(
          style: style,
          background: style.labelBackground ?? stripe,
          decoration: style.labelDecoration,
          padding: style.labelPadding,
          alignment: style.labelAlignment,
          child: labelBuilder?.call(context, row, rowIndex) ??
              row.leading ??
              _text(row.label, style.labelTextStyle, null, maxLines: 2),
        ),
        for (final day in days)
          _buildDataCell(context, style, format, row, rowIndex, day, now, stripe),
        if (showRowTotals)
          _fillCell(
            style: style,
            background: style.totalBackground,
            decoration: style.totalDecoration,
            padding: style.cellPadding,
            alignment: style.cellAlignment,
            child: totalBuilder?.call(
                  context,
                  TimecardTotalContext(
                    kind: TimecardTotalKind.row,
                    total: _rowTotal(row, days),
                    row: row,
                  ),
                ) ??
                _text(format(_rowTotal(row, days)), style.totalTextStyle, null),
          ),
      ],
    );
  }

  Widget _buildDataCell(
    BuildContext context,
    TimecardTableStyle style,
    TimecardValueFormatter format,
    TimecardRow row,
    int rowIndex,
    int day,
    DateTime now,
    Color? stripe,
  ) {
    final date = DateTime(year, month.number, day);
    final isWeekend = _isWeekend(date);
    final isToday = TimecardUtils.isSameDate(date, now);
    final value = row.valueOn(day);
    final marker = row.markerOn(day);
    final ctx = TimecardCellContext(
      row: row,
      rowIndex: rowIndex,
      day: day,
      date: date,
      value: value,
      isWeekend: isWeekend,
      isToday: isToday,
      marker: marker,
    );

    // Resolution for the built-in renderer: a recorded value wins; otherwise an
    // illustrative marker; otherwise the empty placeholder. Markers never feed
    // totals.
    final content = cellBuilder?.call(context, ctx) ??
        (value != null
            ? _text(format(value), style.cellTextStyle, null)
            : marker != null
                ? marker.build(context, style)
                : _text(style.emptyPlaceholder, style.cellTextStyle, null));

    final background =
        _dayBackground(style, isWeekend, isToday, style.cellBackground ?? stripe);

    final cell = _fillCell(
      style: style,
      background: background,
      decoration: style.cellDecoration,
      padding: style.cellPadding,
      alignment: style.cellAlignment,
      child: content,
    );

    if (onCellTap == null) return cell;
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.fill,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onCellTap!(ctx),
        child: cell,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Totals row
  // ---------------------------------------------------------------------------

  TableRow _buildTotalsRow(
    BuildContext context,
    TimecardTableStyle style,
    TimecardValueFormatter format,
    List<int> days,
    DateTime now,
    bool showRowTotals,
  ) {
    return TableRow(
      children: [
        _driverCell(
          style: style,
          background: style.totalBackground,
          decoration: style.totalDecoration,
          padding: style.labelPadding,
          alignment: style.labelAlignment,
          child: _text(totals.columnTotalLabel, style.totalTextStyle, null),
        ),
        for (final day in days)
          _buildColumnTotalCell(context, style, format, day, now),
        if (showRowTotals)
          _fillCell(
            style: style,
            background: style.totalBackground,
            decoration: style.totalDecoration,
            padding: style.cellPadding,
            alignment: style.cellAlignment,
            child: totalBuilder?.call(
                  context,
                  TimecardTotalContext(
                    kind: TimecardTotalKind.grand,
                    total: _grandTotal(days),
                  ),
                ) ??
                _text(format(_grandTotal(days)), style.totalTextStyle, null),
          ),
      ],
    );
  }

  Widget _buildColumnTotalCell(
    BuildContext context,
    TimecardTableStyle style,
    TimecardValueFormatter format,
    int day,
    DateTime now,
  ) {
    final date = DateTime(year, month.number, day);
    final isWeekend = _isWeekend(date);
    final isToday = TimecardUtils.isSameDate(date, now);
    final total = _columnTotal(day);
    final ctx = TimecardTotalContext(
      kind: TimecardTotalKind.column,
      total: total,
      day: day,
      date: date,
      isWeekend: isWeekend,
      isToday: isToday,
    );
    return _fillCell(
      style: style,
      background: _dayBackground(style, isWeekend, isToday, style.totalBackground),
      decoration: style.totalDecoration,
      padding: style.cellPadding,
      alignment: style.cellAlignment,
      child: totalBuilder?.call(context, ctx) ??
          _text(format(total), style.totalTextStyle, null),
    );
  }

  // ---------------------------------------------------------------------------
  // Summary rows
  // ---------------------------------------------------------------------------

  /// Evaluates [summaryRows] top-to-bottom so later rows can reference earlier
  /// ones (and the data rows / data totals) through a [TimecardSummaryScope].
  List<_EvaluatedSummary> _evaluateSummaries(List<int> days) {
    final evaluated = <_EvaluatedSummary>[];
    final byKey = <String, _EvaluatedSummary>{};

    double? resolveValue(String key, int day) {
      for (final r in timecardRows) {
        if (r.key == key) return r.valueOn(day);
      }
      return byKey[key]?.values[day];
    }

    double? resolveRowTotal(String key) {
      for (final r in timecardRows) {
        if (r.key == key) return _rowTotal(r, days);
      }
      return byKey[key]?.total;
    }

    final scope = TimecardSummaryScope(_columnTotal, resolveValue, resolveRowTotal);

    for (final row in summaryRows) {
      final values = <int, double?>{
        for (final day in days) day: row.valueOn(day, scope),
      };
      final double total = row.rowTotalCompute != null
          ? row.rowTotalCompute!(scope)
          : totals.aggregator(values.values.whereType<double>());
      final e = _EvaluatedSummary(row, values, total);
      evaluated.add(e);
      byKey[row.key] = e;
    }
    return evaluated;
  }

  TableRow _buildSummaryRow(
    BuildContext context,
    TimecardTableStyle style,
    TimecardValueFormatter format,
    _EvaluatedSummary summary,
    List<int> days,
    bool showRowTotals,
  ) {
    final row = summary.row;
    final background = row.background ?? style.totalBackground;
    final textStyle = row.textStyle ?? style.totalTextStyle;
    return TableRow(
      key: ValueKey<String>('summary_${row.key}'),
      children: [
        _driverCell(
          style: style,
          background: background,
          decoration: style.totalDecoration,
          padding: style.labelPadding,
          alignment: style.labelAlignment,
          child: row.leading ?? _text(row.label, textStyle, null, maxLines: 2),
        ),
        for (final day in days)
          _fillCell(
            style: style,
            background: background,
            decoration: style.totalDecoration,
            padding: style.cellPadding,
            alignment: style.cellAlignment,
            child: _text(
              summary.values[day] == null
                  ? style.emptyPlaceholder
                  : format(summary.values[day]!),
              textStyle,
              null,
            ),
          ),
        if (showRowTotals)
          _fillCell(
            style: style,
            background: background,
            decoration: style.totalDecoration,
            padding: style.cellPadding,
            alignment: style.cellAlignment,
            child: row.showRowTotal
                ? _text(format(summary.total), textStyle, null)
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Aggregation
  // ---------------------------------------------------------------------------

  double _columnTotal(int day) {
    final values = <double>[];
    for (final row in timecardRows) {
      final v = row.valueOn(day);
      if (v != null) {
        values.add(v);
      } else if (totals.includeEmptyAsZero) {
        values.add(0);
      }
    }
    return totals.aggregator(values);
  }

  double _rowTotal(TimecardRow row, List<int> days) {
    final values = <double>[];
    for (final day in days) {
      final v = row.valueOn(day);
      if (v != null) {
        values.add(v);
      } else if (totals.includeEmptyAsZero) {
        values.add(0);
      }
    }
    return totals.aggregator(values);
  }

  double _grandTotal(List<int> days) {
    final values = <double>[];
    for (final row in timecardRows) {
      for (final day in days) {
        final v = row.valueOn(day);
        if (v != null) {
          values.add(v);
        } else if (totals.includeEmptyAsZero) {
          values.add(0);
        }
      }
    }
    return totals.aggregator(values);
  }

  // ---------------------------------------------------------------------------
  // Small widget builders
  // ---------------------------------------------------------------------------

  Color? _dayBackground(
    TimecardTableStyle style,
    bool isWeekend,
    bool isToday,
    Color? fallback,
  ) {
    if (isToday && style.todayBackground != null) return style.todayBackground;
    if (isWeekend && style.weekendBackground != null) return style.weekendBackground;
    return fallback;
  }

  Widget _text(
    String text,
    TextStyle? textStyle,
    TimecardHeaderConfig? header, {
    int? maxLines,
  }) {
    return Text(
      text,
      style: textStyle,
      textAlign: TextAlign.center,
      maxLines: maxLines ?? header?.maxLines,
      softWrap: header?.softWrap ?? (maxLines != null),
      overflow: header?.overflow ?? TextOverflow.clip,
    );
  }

  /// A cell that determines its row's height (non-fill, middle aligned).
  Widget _driverCell({
    required TimecardTableStyle style,
    required Widget child,
    required Color? background,
    required EdgeInsetsGeometry padding,
    required AlignmentGeometry alignment,
    BoxDecoration? decoration,
    double? height,
  }) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: _cellContainer(
        style: style,
        background: background,
        decoration: decoration,
        padding: padding,
        alignment: alignment,
        height: height,
        child: child,
      ),
    );
  }

  /// A cell that stretches to its row's height (inherits the table default
  /// fill alignment), so column tints cover the full height.
  Widget _fillCell({
    required TimecardTableStyle style,
    required Widget child,
    required Color? background,
    required EdgeInsetsGeometry padding,
    required AlignmentGeometry alignment,
    BoxDecoration? decoration,
    double? height,
  }) {
    return _cellContainer(
      style: style,
      background: background,
      decoration: decoration,
      padding: padding,
      alignment: alignment,
      height: height,
      child: child,
    );
  }

  /// Builds a cell's container, resolving the per-region [decoration] and the
  /// [TimecardTableStyle.cardMode] spacing/rounding against the background tint.
  Widget _cellContainer({
    required TimecardTableStyle style,
    required Color? background,
    required BoxDecoration? decoration,
    required EdgeInsetsGeometry padding,
    required AlignmentGeometry alignment,
    required double? height,
    required Widget child,
  }) {
    // Fast path: a plain color fill (no decoration, not a card).
    if (decoration == null && !style.cardMode) {
      return Container(
        height: height,
        color: background,
        padding: padding,
        alignment: alignment,
        child: child,
      );
    }
    final base = decoration ?? const BoxDecoration();
    final resolved = base.copyWith(
      // The resolved background tint wins so weekend/today/stripe highlighting
      // is preserved on top of a region decoration.
      color: background ?? base.color,
      borderRadius: style.cardMode
          ? BorderRadius.circular(style.cardRadius ?? 8)
          : base.borderRadius,
      boxShadow: style.cardMode ? (style.cardShadow ?? base.boxShadow) : base.boxShadow,
    );
    return Container(
      height: height,
      margin: style.cardMode ? EdgeInsets.all(style.cardSpacing / 2) : null,
      decoration: resolved,
      padding: padding,
      alignment: alignment,
      child: child,
    );
  }
}

/// One [TimecardSummaryRow] resolved to its per-day values and trailing total.
@immutable
class _EvaluatedSummary {
  const _EvaluatedSummary(this.row, this.values, this.total);

  final TimecardSummaryRow row;
  final Map<int, double?> values;
  final double total;
}
