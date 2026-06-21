import 'package:flutter/material.dart';

/// A simple, optional caption rendered above the table.
///
/// Pass either [child] for full control, or [text] for a themed default.
/// Trailing actions (filters, month navigation, ...) go in [actions].
class TimecardTitle extends StatelessWidget {
  const TimecardTitle({
    super.key,
    this.child,
    this.text,
    this.subtitle,
    this.actions = const <Widget>[],
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.textStyle,
    this.subtitleStyle,
  }) : assert(
         child != null || text != null,
         'Provide either a child or text for TimecardTitle.',
       );

  /// Fully custom title content. Takes precedence over [text]/[subtitle].
  final Widget? child;

  /// Primary title text used when [child] is null.
  final String? text;

  /// Optional secondary line beneath [text].
  final String? subtitle;

  /// Widgets aligned to the trailing edge of the title row.
  final List<Widget> actions;

  /// Padding around the title.
  final EdgeInsetsGeometry padding;

  /// Style override for [text].
  final TextStyle? textStyle;

  /// Style override for [subtitle].
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content =
        child ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text!,
              style: textStyle ?? theme.textTheme.titleMedium,
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style:
                    subtitleStyle ??
                    theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        );

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: content),
          ...actions,
        ],
      ),
    );
  }
}
