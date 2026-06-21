import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:timecard_table/timecard_row.dart';
import 'package:timecard_table/timecard_title.dart';
import 'package:timecard_table/utils.dart';

enum Month { january, february, march, april, may, june, july, august, september, october, november, december }

class TimecardTable extends StatefulWidget {
  const TimecardTable({super.key, required this.timecardRows, required this.year, required this.month, this.border, this.title});

  final TimecardTitle? title;
  final List<TimecardRow> timecardRows;
  final TableBorder? border; 

  final int year;
  final Month month;

  @override
  State<TimecardTable> createState() => _TimecardTableState();
}

class _TimecardTableState extends State<TimecardTable> {
  // Given a month and year, return the number of days in that month to create the table columns
  late int _daysInMonth;
  @override
  void initState() {
    super.initState();
    _daysInMonth = Utils.getDaysInMonth(widget.year, widget.month.index + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.title != null) widget.title!,
        Table(
          border: widget.border,
          children: [
            TableRow(
              children: [
                const TableCell(child: Text(' ')),
                for (int day = 1; day <= _daysInMonth; day++)
                  TableCell(
                    child: Center(
                      child: Padding(padding: const EdgeInsets.all(2.0), child: Text(day.toString())),
                    ),
                  ),
              ],
            ),
            for (var value in widget.timecardRows)
              TableRow(
                children: [
                  TableCell(child: Text(value.name)),
                  for (int day = 1; day <= _daysInMonth; day++)
                    TableCell(
                      child: Center(
                        child:
                            value.cellWidget ??
                            Padding(padding: const EdgeInsets.all(2.0), child: Text(value.dailyHoursLogged[day]?.toString() ?? '0')),
                      ),
                    ),
                ],
              ),

            // Add a row for the total hours worked for each day
            TableRow(
              children: [
                const TableCell(child: Text('Total Hours')),
                for (int day = 1; day <= _daysInMonth; day++)
                  TableCell(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Text(widget.timecardRows.fold<double>(0, (sum, value) => sum + (value.dailyHoursLogged[day] ?? 0)).toString()),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

@Preview(name: 'TimecardTable')
Widget simpleTimecardTable() {
  return TimecardTable(
    title: const TimecardTitle(child: Text('Timecard Table')),
    timecardRows: [
      TimecardRow('job1', 'Lavoro 1', 'Descrizione del lavoro 1', hoursWorked: {1: 8, 2: 7.5, 3: 8, 4: 6, 5: 7, 123: 8}),
      TimecardRow('job2', 'Lavoro 2', 'Descrizione del lavoro 2', hoursWorked: {1: 4, 2: 5, 3: 6}),
      TimecardRow('job3', 'Lavoro 3', 'Descrizione del lavoro 3', hoursWorked: {1: 2, 2: 3, 3: 4}),
    ],
    month: Month.march,
    year: DateTime.now().year,
    border: TableBorder.all(borderRadius: BorderRadius.circular(5.0)),
  );
}
