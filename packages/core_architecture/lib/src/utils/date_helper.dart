import 'package:intl/intl.dart';

class DateHelper {
  static const List<String> dayNames = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  static const List<String> monthNames = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  // ====================
  // TIME FORMAT HELPERS
  // ====================

  /// HH:mm
  static String formatMinutesFromInt(int minutes) {
    final int min = minutes % 60;
    final int hour = minutes ~/ 60;

    return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  /// dd.MM.yyyy  (DATE ONLY)
  static String formatDate(DateTime date) =>
      DateFormat('dd.MM.yyyy').format(date);

  /// HH:mm (SADECE SAAT)
  static String formatTime(DateTime time) =>
      DateFormat('HH:mm').format(time);

  /// dd.MM.yyyy HH:mm  (DATE + TIME)
  static String formatDateTime(DateTime dateTime) =>
      DateFormat('dd.MM.yyyy HH:mm').format(dateTime);

  // ====================
  // GREETING
  // ====================

  static String getGreeting({
    required String morning,
    required String afternoon,
    required String evening,
    required String night,
  }) {
    final int hour = DateTime.now().hour;

    if (hour < 6) return night;
    if (hour < 12) return morning;
    if (hour < 18) return afternoon;
    if (hour < 22) return evening;

    return night;
  }

  // ====================
  // RELATIVE DATE
  // ====================

  static String getRelativeDate(
    DateTime date, {
    required String todayLabel,
    required String yesterdayLabel,
    required String tomorrowLabel,
    required String daysAgoSuffix,
    required String daysLaterSuffix,
  }) {
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(date);

    // Same day
    if (diff.inDays == 0) return todayLabel;

    // One day before
    if (diff.inDays == 1) return yesterdayLabel;

    // One day after
    if (diff.inDays == -1) return tomorrowLabel;

    // Within past 7 days
    if (diff.inDays > 1 && diff.inDays < 7) {
      return '${diff.inDays} $daysAgoSuffix';
    }

    // Within next 7 days
    if (diff.inDays < -1 && diff.inDays > -7) {
      return '${diff.inDays.abs()} $daysLaterSuffix';
    }

    // Otherwise exact date
    return formatDate(date);
  }

  // ====================
  // DAY CHECKS
  // ====================

  static bool isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static bool isTomorrow(DateTime date) =>
      isSameDay(date, DateTime.now().add(const Duration(days: 1)));

  static bool isYesterday(DateTime date) =>
      isSameDay(date, DateTime.now().subtract(const Duration(days: 1)));

  // ====================
  // DAY BOUNDARIES
  // ====================

  static DateTime getStartOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime getEndOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  // ====================
  // MONTH HELPERS
  // ====================

  static List<DateTime> getDaysInMonth(DateTime date) {
    final first = DateTime(date.year, date.month);
    final last = DateTime(date.year, date.month + 1, 0);

    return List.generate(last.day, (i) => first.add(Duration(days: i)));
  }

  static String getDayName(int weekday) =>
      (weekday >= 1 && weekday <= 7) ? dayNames[weekday - 1] : '';

  static String getMonthName(int month) =>
      (month >= 1 && month <= 12) ? monthNames[month - 1] : '';
}
