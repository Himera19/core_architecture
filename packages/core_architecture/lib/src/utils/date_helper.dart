import 'package:intl/intl.dart';

/// Date arithmetic and formatting.
///
/// Every name and pattern comes from `intl` for a locale you pass, rather than
/// from a list baked into the package. Until 6.0.0 the day and month names
/// were fixed Turkish and the date pattern fixed `dd.MM.yyyy`, which quietly
/// made the language decision for every app using it — while the rest of this
/// class carefully took its labels as parameters.
///
/// [locale] defaults to `Intl.defaultLocale`, so setting that once in `main()`
/// covers the whole app:
///
/// ```dart
/// Intl.defaultLocale = 'tr_TR';
/// DateHelper.getDayName(1);   // Pazartesi
/// DateHelper.getDayName(1, locale: 'en_US');   // Monday
/// ```
///
/// A locale other than `en` needs its data loaded first — see
/// `initializeDateFormatting` in `package:intl`.
class DateHelper {
  // ====================
  // TIME FORMAT HELPERS
  // ====================

  /// HH:mm
  static String formatMinutesFromInt(int minutes) {
    final int min = minutes % 60;
    final int hour = minutes ~/ 60;

    return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  /// Date only, `dd.MM.yyyy` unless [pattern] says otherwise.
  static String formatDate(
    DateTime date, {
    String pattern = 'dd.MM.yyyy',
    String? locale,
  }) => DateFormat(pattern, locale).format(date);

  /// Time only, `HH:mm` unless [pattern] says otherwise.
  static String formatTime(
    DateTime time, {
    String pattern = 'HH:mm',
    String? locale,
  }) => DateFormat(pattern, locale).format(time);

  /// Date and time, `dd.MM.yyyy HH:mm` unless [pattern] says otherwise.
  static String formatDateTime(
    DateTime dateTime, {
    String pattern = 'dd.MM.yyyy HH:mm',
    String? locale,
  }) => DateFormat(pattern, locale).format(dateTime);

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
    // Calendar days apart, not 24-hour blocks. `now.difference(date).inDays`
    // measures elapsed time: yesterday 23:00 read at 01:00 today is two hours
    // apart, so it reported "today". Comparing midnights is what "yesterday"
    // actually means. The hours/24 rounding absorbs the 23- and 25-hour days
    // that daylight saving produces, which would otherwise shift every label
    // by one for the rest of the day.
    final DateTime today = getStartOfDay(DateTime.now());
    final DateTime target = getStartOfDay(date);
    final int days = (today.difference(target).inHours / 24).round();

    // Same day
    if (days == 0) return todayLabel;

    // One day before
    if (days == 1) return yesterdayLabel;

    // One day after
    if (days == -1) return tomorrowLabel;

    // Within past 7 days
    if (days > 1 && days < 7) {
      return '$days $daysAgoSuffix';
    }

    // Within next 7 days
    if (days < -1 && days > -7) {
      return '${days.abs()} $daysLaterSuffix';
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

  /// The name of [weekday], 1 = Monday through 7 = Sunday, in [locale].
  ///
  /// Empty string for anything outside that range, so a caller can pass a
  /// value straight from `DateTime.weekday` without checking it first.
  static String getDayName(int weekday, {String? locale}) {
    if (weekday < 1 || weekday > 7) return '';

    // 2024-01-01 was a Monday, so adding weekday - 1 lands on the day wanted
    // without needing a table of names.
    final DateTime reference = DateTime(2024, 1, weekday);
    return DateFormat.EEEE(locale).format(reference);
  }

  /// The name of [month], 1 = January through 12 = December, in [locale].
  static String getMonthName(int month, {String? locale}) {
    if (month < 1 || month > 12) return '';
    return DateFormat.MMMM(locale).format(DateTime(2024, month));
  }

  /// Every weekday name, Monday first, in [locale].
  static List<String> dayNames({String? locale}) => [
    for (int weekday = 1; weekday <= 7; weekday++)
      getDayName(weekday, locale: locale),
  ];

  /// Every month name, January first, in [locale].
  static List<String> monthNames({String? locale}) => [
    for (int month = 1; month <= 12; month++)
      getMonthName(month, locale: locale),
  ];
}
