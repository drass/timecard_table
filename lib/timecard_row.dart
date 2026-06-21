import 'package:flutter/material.dart';

class TimecardRow {
  final String key;
  final String name;
  final String description;
  final Map<int, double> dailyHoursLogged = {};  // Key: day of the month, Value: hours
  final Widget? cellWidget;

  TimecardRow(this.key, this.name, this.description, {Map<int, double>? hoursWorked, this.cellWidget}) {
    if (hoursWorked != null) {
      dailyHoursLogged.addAll(hoursWorked);
    }
  }
}