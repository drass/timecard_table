import 'package:flutter/material.dart';

import 'timecard_style.dart';

/// A non-numeric, illustrative marker placed in a day cell.
///
/// Markers represent *events* rather than recorded amounts — an illness, a
/// public holiday, a note — and are therefore **never** included in any total.
/// They live in [TimecardRow.markers], a separate map from the numeric
/// [TimecardRow.values], so adding a marker can never change a summary figure.
///
/// Construct one with [TimecardMarker.icon], [TimecardMarker.text] or
/// [TimecardMarker.widget]. An optional [tooltip] wraps the rendered content in
/// a [Tooltip].
@immutable
class TimecardMarker {
  /// An icon marker, e.g. `TimecardMarker.icon(Icons.sick, tooltip: 'Illness')`.
  const TimecardMarker.icon(
    this.icon, {
    this.color,
    this.size,
    this.tooltip,
  })  : text = null,
        textStyle = null,
        child = null;

  /// A short text/symbol marker, e.g. `TimecardMarker.text('🤒')` or
  /// `TimecardMarker.text('H', tooltip: 'Holiday')`.
  const TimecardMarker.text(
    this.text, {
    this.textStyle,
    this.color,
    this.tooltip,
  })  : icon = null,
        size = null,
        child = null;

  /// A fully custom marker widget.
  const TimecardMarker.widget(
    this.child, {
    this.tooltip,
  })  : icon = null,
        text = null,
        textStyle = null,
        color = null,
        size = null;

  /// The icon shown for an [TimecardMarker.icon] marker.
  final IconData? icon;

  /// The text/symbol shown for a [TimecardMarker.text] marker.
  final String? text;

  /// Custom text style for a [TimecardMarker.text] marker.
  final TextStyle? textStyle;

  /// A fully custom widget for a [TimecardMarker.widget] marker.
  final Widget? child;

  /// Tint applied to an icon or text marker.
  final Color? color;

  /// Icon size for an [TimecardMarker.icon] marker.
  final double? size;

  /// Optional hover/long-press tooltip describing the event.
  final String? tooltip;

  /// Builds the marker's widget, styled against the ambient [style].
  Widget build(BuildContext context, TimecardTableStyle style) {
    Widget content;
    if (child != null) {
      content = child!;
    } else if (icon != null) {
      content = Icon(icon, color: color, size: size ?? 18);
    } else {
      content = Text(
        text ?? '',
        textAlign: TextAlign.center,
        style: (textStyle ?? style.cellTextStyle)?.copyWith(color: color) ??
            TextStyle(color: color),
      );
    }
    if (tooltip != null) {
      content = Tooltip(message: tooltip!, child: content);
    }
    return content;
  }
}
