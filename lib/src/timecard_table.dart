import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'timecard_header_config.dart';
import 'timecard_models.dart';
import 'timecard_row.dart';
import 'timecard_span.dart';
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
/// 2. **Value/formatting hooks** — [valueFormatter], [weekendDays], [holidays],
///    [today].
/// 3. **Builders** — [headerBuilder], [cellBuilder], [labelBuilder],
///    [totalBuilder] and [cornerBuilder] let you replace any region's widget
///    entirely while still receiving the resolved context (date, value,
///    weekend/holiday/today flags, totals, ...).
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
    this.spanRows = const <TimecardSpanRow>[],
    this.title,
    this.style,
    this.headerConfig = const TimecardHeaderConfig(),
    this.totals = const TimecardTotalsConfig(),
    this.headerBuilder,
    this.cellBuilder,
    this.labelBuilder,
    this.totalBuilder,
    this.cornerBuilder,
    this.spanBuilder,
    this.valueFormatter,
    this.onCellTap,
    this.onHeaderTap,
    this.onTotalTap,
    this.onSpanTap,
    this.weekendDays = const {DateTime.saturday, DateTime.sunday},
    this.holidays = const <int, String>{},
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

  /// Annotation lanes highlighting day intervals as colored bands.
  ///
  /// Each [TimecardSpanRow] renders one row in which every [TimecardSpan] draws
  /// a continuous bar from its first to its last day, with its message shown
  /// once, centered over the whole interval. Spans hold no numbers and never
  /// affect any total. A row's [TimecardSpanRow.placement] decides whether it
  /// sits directly below the day headers or beneath everything else.
  final List<TimecardSpanRow> spanRows;

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

  /// Replaces a span band's content. Called once per band (not per day cell);
  /// the returned widget is centered over the band's full interval.
  final TimecardSpanBuilder? spanBuilder;

  /// Formats numeric values into cell/total strings. Defaults to a trimmed
  /// number format (`8`, `7.5`, `7.25`).
  final TimecardValueFormatter? valueFormatter;

  /// Called when a data cell is tapped. Setting this also gives data cells a
  /// hover highlight, ripple and pointer cursor.
  final TimecardCellTapCallback? onCellTap;

  /// Called when a day-header cell is tapped. Setting this makes the day
  /// headers interactive (hover / ripple / pointer cursor).
  final TimecardHeaderTapCallback? onHeaderTap;

  /// Called when a total cell (column / row / grand) is tapped. Setting this
  /// makes the totals interactive (hover / ripple / pointer cursor).
  final TimecardTotalTapCallback? onTotalTap;

  /// Called when a span band is tapped. Setting this also gives the band a
  /// hover highlight, ripple and pointer cursor.
  final TimecardSpanTapCallback? onSpanTap;

  /// Weekday numbers (`DateTime.monday`..`DateTime.sunday`) treated as
  /// weekend for highlighting. Defaults to Saturday and Sunday.
  final Set<int> weekendDays;

  /// Holidays of the displayed month as `1-based day -> holiday name`.
  /// Holiday columns get their own tint ([TimecardTableStyle.holidayBackground])
  /// and the name is shown as the day header's tooltip.
  final Map<int, String> holidays;

  /// The date considered "today" for highlighting. Defaults to `DateTime.now()`.
  final DateTime? today;

  /// Whether to wrap the table in a horizontal scroll view (recommended for a
  /// full month). When `false`, the day columns flex to share the available
  /// width instead of using [TimecardTableStyle.dayColumnWidth].
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
    final resolvedSpanRows = <_ResolvedSpanRow>[
      for (var i = 0; i < spanRows.length; i++)
        _ResolvedSpanRow(
          spanRows[i],
          i,
          spanRows[i].resolveSpans(year, month.number,
              firstDay: days.first, lastDay: days.last),
        ),
    ];

    // Table's element cannot survive structural updates (keyed rows added,
    // removed or reordered, column count changed) without tripping the
    // framework assert of flutter/flutter#91068, so any structural change
    // remounts the grid instead of updating it in place.
    final structureKey = ValueKey<int>(
      Object.hashAll([
        days.first,
        days.last,
        showRowTotals,
        showColumnTotals,
        for (final row in timecardRows) row.key,
        for (final summary in summaries) summary.row.key,
        // Placement is part of the structure: moving a span row between the
        // top and bottom sections reorders keyed rows.
        for (final span in resolvedSpanRows) span.row.key,
        for (final span in resolvedSpanRows) span.row.placement,
      ]),
    );

    final table = Table(
      key: structureKey,
      border: _resolveBorder(resolvedStyle),
      defaultVerticalAlignment: TableCellVerticalAlignment.fill,
      // When the table isn't scrollable the day columns flex to share the
      // available width instead of overflowing at their fixed width.
      defaultColumnWidth: scrollable
          ? FixedColumnWidth(resolvedStyle.dayColumnWidth)
          : const FlexColumnWidth(),
      columnWidths: _columnWidths(resolvedStyle, days.length, showRowTotals),
      children: [
        _buildHeaderRow(context, resolvedStyle, days, now, showRowTotals),
        for (final span in resolvedSpanRows)
          if (span.row.placement == TimecardSpanPlacement.top)
            _buildSpanRow(context, resolvedStyle, span, days, showRowTotals),
        for (var i = 0; i < timecardRows.length; i++)
          _buildDataRow(context, resolvedStyle, format, timecardRows[i], i, days, now, showRowTotals),
        if (showColumnTotals)
          _buildTotalsRow(context, resolvedStyle, format, days, now, showRowTotals),
        for (final summary in summaries)
          _buildSummaryRow(context, resolvedStyle, format, summary, days, showRowTotals),
        for (final span in resolvedSpanRows)
          if (span.row.placement == TimecardSpanPlacement.bottom)
            _buildSpanRow(context, resolvedStyle, span, days, showRowTotals),
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
      widths[dayCount + 1] = scrollable
          ? FixedColumnWidth(style.totalColumnWidth ?? style.dayColumnWidth * 1.4)
          : const FlexColumnWidth(1.4);
    }
    return widths;
  }

  bool _isWeekend(DateTime date) => weekendDays.contains(date.weekday);

  /// The full date for a 1-based [day] in the displayed month, used to resolve
  /// date-keyed row values/markers.
  DateTime _dateOf(int day) => DateTime(year, month.number, day);

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
            fit: !scrollable,
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
    final holidayName = holidays[day];
    final ctx = TimecardHeaderContext(
      day: day,
      date: date,
      isWeekend: isWeekend,
      isToday: isToday,
      isHoliday: holidayName != null,
      holidayName: holidayName,
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

    if (holidayName != null && holidayName.isNotEmpty) {
      content = Tooltip(message: holidayName, child: content);
    }

    // Day-header cells are the row-height drivers (middle alignment): they
    // always have content, unlike the corner, so the header keeps its height.
    return _driverCell(
      style: style,
      background: _dayBackground(style, isWeekend, isToday, style.headerBackground,
          isHoliday: ctx.isHoliday),
      decoration: style.headerDecoration,
      padding: style.headerPadding,
      alignment: style.headerAlignment,
      height: height,
      onTap: onHeaderTap == null ? null : () => onHeaderTap!(ctx),
      // Rotated content is wrapped in an OverflowBox (unbounded constraints),
      // which a FittedBox can't size — rotated headers keep their overflow.
      fit: !scrollable && headerConfig.rotationDegrees == 0,
      child: content,
    );
  }

  Widget _defaultHeaderContent(TimecardTableStyle style, TimecardHeaderContext ctx) {
    final headerStyle = ctx.isToday
        ? style.todayHeaderTextStyle ?? style.headerTextStyle
        : style.headerTextStyle;
    if (headerConfig.label == TimecardHeaderLabel.dayAndWeekday) {
      final short =
          (headerConfig.shortWeekdays ?? TimecardUtils.defaultShortWeekdays)[ctx.date.weekday - 1];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${ctx.day}', style: headerStyle),
          Text(short, style: style.weekdayTextStyle),
        ],
      );
    }
    return _text(headerConfig.resolveLabel(ctx), headerStyle, headerConfig);
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
          _buildRowTotalCell(context, style, format, row, days),
      ],
    );
  }

  Widget _buildRowTotalCell(
    BuildContext context,
    TimecardTableStyle style,
    TimecardValueFormatter format,
    TimecardRow row,
    List<int> days,
  ) {
    final ctx = TimecardTotalContext(
      kind: TimecardTotalKind.row,
      total: _rowTotal(row, days),
      row: row,
    );
    return _fillCell(
      style: style,
      background: style.totalBackground,
      decoration: style.totalDecoration,
      padding: style.cellPadding,
      alignment: style.cellAlignment,
      onTap: onTotalTap == null ? null : () => onTotalTap!(ctx),
      fit: !scrollable,
      child: totalBuilder?.call(context, ctx) ??
          _text(format(ctx.total), style.totalTextStyle, null),
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
    final value = row.valueOn(day, date);
    final marker = row.markerOn(day, date);
    final holidayName = holidays[day];
    final ctx = TimecardCellContext(
      row: row,
      rowIndex: rowIndex,
      day: day,
      date: date,
      value: value,
      isWeekend: isWeekend,
      isToday: isToday,
      isHoliday: holidayName != null,
      holidayName: holidayName,
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
                : _text(style.emptyPlaceholder,
                    style.emptyTextStyle ?? style.cellTextStyle, null));

    final background = _dayBackground(
        style, isWeekend, isToday, style.cellBackground ?? stripe,
        isHoliday: ctx.isHoliday);

    return _fillCell(
      style: style,
      background: background,
      decoration: style.cellDecoration,
      padding: style.cellPadding,
      alignment: style.cellAlignment,
      onTap: onCellTap == null ? null : () => onCellTap!(ctx),
      fit: !scrollable,
      child: content,
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
          _buildGrandTotalCell(context, style, format, days),
      ],
    );
  }

  Widget _buildGrandTotalCell(
    BuildContext context,
    TimecardTableStyle style,
    TimecardValueFormatter format,
    List<int> days,
  ) {
    final ctx = TimecardTotalContext(
      kind: TimecardTotalKind.grand,
      total: _grandTotal(days),
    );
    return _fillCell(
      style: style,
      background: style.totalBackground,
      decoration: style.totalDecoration,
      padding: style.cellPadding,
      alignment: style.cellAlignment,
      onTap: onTotalTap == null ? null : () => onTotalTap!(ctx),
      fit: !scrollable,
      child: totalBuilder?.call(context, ctx) ??
          _text(format(ctx.total), style.totalTextStyle, null),
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
    final holidayName = holidays[day];
    final ctx = TimecardTotalContext(
      kind: TimecardTotalKind.column,
      total: total,
      day: day,
      date: date,
      isWeekend: isWeekend,
      isToday: isToday,
      isHoliday: holidayName != null,
      holidayName: holidayName,
    );
    return _fillCell(
      style: style,
      background: _dayBackground(style, isWeekend, isToday, style.totalBackground,
          isHoliday: ctx.isHoliday),
      decoration: style.totalDecoration,
      padding: style.cellPadding,
      alignment: style.cellAlignment,
      onTap: onTotalTap == null ? null : () => onTotalTap!(ctx),
      fit: !scrollable,
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
        if (r.key == key) return r.valueOn(day, _dateOf(day));
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
        for (final day in days) day: row.valueOn(day, scope, _dateOf(day)),
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
            fit: !scrollable,
            child: summary.values[day] == null
                ? _text(style.emptyPlaceholder,
                    row.textStyle ?? style.emptyTextStyle ?? textStyle, null)
                : _text(format(summary.values[day]!), textStyle, null),
          ),
        if (showRowTotals)
          _fillCell(
            style: style,
            background: background,
            decoration: style.totalDecoration,
            padding: style.cellPadding,
            alignment: style.cellAlignment,
            fit: !scrollable,
            child: row.showRowTotal
                ? _text(format(summary.total), textStyle, null)
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Span rows
  // ---------------------------------------------------------------------------

  TableRow _buildSpanRow(
    BuildContext context,
    TimecardTableStyle style,
    _ResolvedSpanRow resolvedRow,
    List<int> days,
    bool showRowTotals,
  ) {
    final row = resolvedRow.row;
    final background = row.background ?? style.spanRowBackground;
    return TableRow(
      key: ValueKey<String>('span_${row.key}'),
      children: [
        _driverCell(
          style: style,
          background: background,
          decoration: style.labelDecoration,
          padding: style.labelPadding,
          alignment: style.labelAlignment,
          height: row.height ?? style.spanRowHeight,
          child: row.leading ??
              _text(row.label, row.textStyle ?? style.labelTextStyle, null),
        ),
        for (final day in days)
          _buildSpanCell(context, style, resolvedRow, day),
        if (showRowTotals)
          _fillCell(
            style: style,
            background: background,
            padding: style.cellPadding,
            alignment: style.cellAlignment,
            child: const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildSpanCell(
    BuildContext context,
    TimecardTableStyle style,
    _ResolvedSpanRow resolvedRow,
    int day,
  ) {
    final row = resolvedRow.row;
    final background = row.background ?? style.spanRowBackground;
    // The first declared span wins an overlap; use separate span rows for
    // intervals that need to be visible at the same time.
    ResolvedTimecardSpan? hit;
    for (final resolved in resolvedRow.spans) {
      if (resolved.covers(day)) {
        hit = resolved;
        break;
      }
    }
    if (hit == null) {
      return _fillCell(
        style: style,
        background: background,
        padding: EdgeInsets.zero,
        alignment: style.cellAlignment,
        child: const SizedBox.shrink(),
      );
    }

    final ctx = TimecardSpanContext(
      row: row,
      rowIndex: resolvedRow.index,
      resolved: hit,
      day: day,
      date: _dateOf(day),
    );
    Widget band = _spanBand(context, style, ctx);
    final tooltip = hit.span.tooltip ?? hit.span.label;
    if (tooltip != null && tooltip.isNotEmpty) {
      band = Tooltip(message: tooltip, child: band);
    }
    return _fillCell(
      style: style,
      background: background,
      padding: EdgeInsets.zero,
      alignment: style.cellAlignment,
      onTap: onSpanTap == null ? null : () => onSpanTap!(ctx),
      // The band's message deliberately overflows this cell (see
      // [_spanBandContent]), so the tap overlay must not clip it.
      clipContent: false,
      child: band,
    );
  }

  /// One day's segment of a band. Adjacent segments share the same fill and
  /// only the interval's outer corners are rounded, so the run reads as a
  /// single bar; the message is drawn by the *last* segment (see
  /// [_spanBandContent]).
  Widget _spanBand(
    BuildContext context,
    TimecardTableStyle style,
    TimecardSpanContext ctx,
  ) {
    final span = ctx.span;
    final resolved = ctx.resolved;
    final radius = span.radius ?? style.spanRadius;
    // A clipped edge stays square to signal the interval continues outside the
    // displayed range.
    final leftRadius =
        ctx.day == resolved.startDay && !resolved.clippedStart ? radius : 0.0;
    final rightRadius =
        ctx.day == resolved.endDay && !resolved.clippedEnd ? radius : 0.0;
    return Padding(
      padding: ctx.row.inset ?? style.spanInset,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: span.background ?? style.spanBackground,
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(leftRadius),
            right: Radius.circular(rightRadius),
          ),
        ),
        child: ctx.day == resolved.endDay
            ? _spanBandContent(context, style, ctx)
            : null,
      ),
    );
  }

  /// The band's message, laid out across the *whole* interval.
  ///
  /// Table cells are painted left to right, so content overflowing to the right
  /// would be covered by the following cells' own backgrounds. The message is
  /// therefore anchored on the band's last segment and spread leftwards over
  /// the segments already painted: it is given the interval's full width
  /// (segment width * length) and shifted back by half of the extra width, so
  /// it ends up centered on the interval regardless of how many days it covers.
  ///
  /// This only works while nothing between the cell and the content clips: any
  /// wrapper added inside a span cell must keep [Clip.none] (which is why
  /// [_buildSpanCell] passes `clipContent: false` to [_fillCell]).
  Widget _spanBandContent(
    BuildContext context,
    TimecardTableStyle style,
    TimecardSpanContext ctx,
  ) {
    final content =
        spanBuilder?.call(context, ctx) ?? _defaultSpanContent(style, ctx);
    final length = ctx.resolved.length;
    if (length == 1) return content;
    return LayoutBuilder(
      builder: (context, constraints) {
        final segment = constraints.maxWidth;
        if (!segment.isFinite) return content;
        final width = segment * length;
        return Transform.translate(
          offset: Offset(-segment * (length - 1) / 2, 0),
          child: OverflowBox(
            minWidth: width,
            maxWidth: width,
            alignment: Alignment.center,
            child: content,
          ),
        );
      },
    );
  }

  Widget _defaultSpanContent(TimecardTableStyle style, TimecardSpanContext ctx) {
    final span = ctx.span;
    if (span.child != null) return span.child!;
    final textStyle = span.textStyle ?? style.spanTextStyle;
    final label = span.label;
    final hasLabel = label != null && label.isNotEmpty;
    if (span.icon == null && !hasLabel) return const SizedBox.shrink();
    return Padding(
      padding: style.spanLabelPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (span.icon != null)
            Padding(
              padding: EdgeInsets.only(right: hasLabel ? 4 : 0),
              child: Icon(
                span.icon,
                size: 14,
                color: span.iconColor ?? textStyle?.color,
              ),
            ),
          if (hasLabel)
            Flexible(
              child: Text(
                label,
                style: textStyle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Aggregation
  // ---------------------------------------------------------------------------

  double _columnTotal(int day) {
    final date = _dateOf(day);
    final values = <double>[];
    for (final row in timecardRows) {
      final v = row.valueOn(day, date);
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
      final v = row.valueOn(day, _dateOf(day));
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
        final v = row.valueOn(day, _dateOf(day));
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
    Color? fallback, {
    bool isHoliday = false,
  }) {
    if (isToday && style.todayBackground != null) return style.todayBackground;
    if (isHoliday && style.holidayBackground != null) return style.holidayBackground;
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
    VoidCallback? onTap,
    bool fit = false,
  }) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: _tappable(
        style,
        onTap,
        _cellContainer(
          style: style,
          background: background,
          decoration: decoration,
          padding: padding,
          alignment: alignment,
          height: height,
          fit: fit,
          child: child,
        ),
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
    VoidCallback? onTap,
    bool fit = false,
    bool clipContent = true,
  }) {
    return _tappable(
      style,
      onTap,
      _cellContainer(
        style: style,
        background: background,
        decoration: decoration,
        padding: padding,
        alignment: alignment,
        height: height,
        fit: fit,
        child: child,
      ),
      clipContent: clipContent,
    );
  }

  /// Overlays a transparent [InkWell] on top of [cell] so a tap target gets a
  /// hover highlight, ripple and pointer cursor — painted *above* the cell's
  /// opaque background (a plain InkWell behind it would be hidden). Returns
  /// [cell] unchanged when [onTap] is `null`.
  ///
  /// The overlay [Stack] clips to the cell by default; [clipContent] `false`
  /// keeps content that is meant to overflow the cell visible (span bands).
  Widget _tappable(
    TimecardTableStyle style,
    VoidCallback? onTap,
    Widget cell, {
    bool clipContent = true,
  }) {
    if (onTap == null) return cell;
    final radius = style.cardMode
        ? BorderRadius.circular(style.cardRadius ?? 8)
        : style.borderRadius;
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: clipContent ? Clip.hardEdge : Clip.none,
      children: [
        cell,
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              hoverColor: style.hoverColor,
              splashColor: style.splashColor,
              borderRadius: radius,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a cell's container, resolving the per-region [decoration] and the
  /// [TimecardTableStyle.cardMode] spacing/rounding against the background tint.
  ///
  /// With [fit] the content (padding included) is scaled down to the cell's
  /// width instead of overflowing — used by the day/total cells when the table
  /// isn't scrollable, where the flexed columns can get narrower than the
  /// content's natural single-line width on small screens.
  Widget _cellContainer({
    required TimecardTableStyle style,
    required Color? background,
    required BoxDecoration? decoration,
    required EdgeInsetsGeometry padding,
    required AlignmentGeometry alignment,
    required double? height,
    required Widget child,
    bool fit = false,
  }) {
    var effectivePadding = padding;
    if (fit) {
      child = FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(padding: padding, child: child),
      );
      effectivePadding = EdgeInsets.zero;
    }
    // Fast path: a plain color fill (no decoration, not a card).
    if (decoration == null && !style.cardMode) {
      return Container(
        height: height,
        color: background,
        padding: effectivePadding,
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
      padding: effectivePadding,
      alignment: alignment,
      child: child,
    );
  }
}

/// One [TimecardSpanRow] with its spans clipped to the visible day window.
@immutable
class _ResolvedSpanRow {
  const _ResolvedSpanRow(this.row, this.index, this.spans);

  final TimecardSpanRow row;
  final int index;
  final List<ResolvedTimecardSpan> spans;
}

/// One [TimecardSummaryRow] resolved to its per-day values and trailing total.
@immutable
class _EvaluatedSummary {
  const _EvaluatedSummary(this.row, this.values, this.total);

  final TimecardSummaryRow row;
  final Map<int, double?> values;
  final double total;
}
