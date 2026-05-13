class DateHelpers {
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static int daysLeftInMonth(DateTime date) {
    final lastDay = DateTime(date.year, date.month + 1, 0).day;
    return (lastDay - date.day + 1).clamp(1, 31);
  }
}
