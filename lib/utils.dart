class Utils {
  static int getDaysInMonth(int year, int month) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final firstDayOfNextMonth = (month < 12) ? DateTime(year, month + 1, 1) : DateTime(year + 1, 1, 1);
    return firstDayOfNextMonth.difference(firstDayOfMonth).inDays;
  }
}